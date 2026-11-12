#!/usr/bin/env python3
"""Generate a documentation inventory from hash-verified official GitHub schemas."""

import argparse
import csv
import gzip
import hashlib
import json
from pathlib import Path
import re


PROJECT = Path(__file__).resolve().parents[2]
METHODS = {"get", "post", "put", "patch", "delete", "head", "options"}
CATEGORIES = {
    "repos": ("CAP-02", "HUB-01"), "git": ("CAP-03", "HUB-01"),
    "commits": ("CAP-03", "HUB-01"), "issues": ("CAP-05", "HUB-03"),
    "reactions": ("CAP-05", "HUB-03"), "pulls": ("CAP-07", "HUB-04"),
    "search": ("CAP-11", "APP-03"), "actions": ("CAP-12", "HUB-07"),
    "checks": ("CAP-12", "HUB-06"), "projects": ("CAP-15", "APP-04"),
    "releases": ("CAP-17", "GIT-04"), "deployments": ("CAP-18", "APP-04"),
    "dependabot": ("CAP-20", "APP-04"), "code-scanning": ("CAP-20", "APP-04"),
    "secret-scanning": ("CAP-20", "APP-04"), "code-security": ("CAP-20", "APP-04"),
    "branches": ("CAP-21", "HUB-06"), "collaborators": ("CAP-21", "APP-04"),
    "deploy-keys": ("CAP-21", "APP-04"), "metrics": ("CAP-22", "APP-04"),
    "packages": ("CAP-23", "APP-04"), "pages": ("CAP-24", "APP-04"),
    "gists": ("CAP-26", "APP-04"), "activity": ("CAP-26", "APP-04"),
    "users": ("CAP-26", "APP-01"), "orgs": ("CAP-27", "APP-04"),
    "teams": ("CAP-27", "APP-04"), "billing": ("CAP-28", "APP-04"),
    "codespaces": ("CAP-29", "APP-04"), "copilot": ("CAP-30", "APP-04"),
    "apps": ("CAP-31", "APP-01"), "interactions": ("CAP-33", "APP-04"),
}


def classify(operation):
    metadata = operation.get("x-github", {})
    category = metadata.get("category", "unknown")
    subcategory = metadata.get("subcategory", "")
    identifier = operation["operationId"]
    if identifier == "users/get-authenticated":
        return "CAP-01", "APP-01"
    if subcategory == "notifications":
        return "CAP-10", "HUB-02"
    if category == "pulls" and ("review" in identifier or "comment" in identifier):
        return "CAP-08", "HUB-05"
    if identifier in {"pulls/merge", "pulls/check-if-merged"}:
        return "CAP-09", "HUB-06"
    if category == "actions" and subcategory in {"artifacts", "cache", "self-hosted-runners"}:
        return "CAP-13", "HUB-07"
    if category == "actions" and subcategory in {"secrets", "variables"}:
        return "CAP-19", "APP-04"
    if category == "repos" and subcategory in {"contents", "git"}:
        return "CAP-03", "HUB-01"
    return CATEGORIES.get(category, ("CAP-34", "APP-04"))


def verified_source(path, pin):
    content = path.read_bytes()
    if path.suffix == ".gz":
        content = gzip.decompress(content)
    if hashlib.sha256(content).hexdigest() != pin["sha256"]:
        raise ValueError(f"Schema hash differs from reviewed pin: {path.name}")
    return content.decode()


def generate(source_directory, output_directory):
    pins = json.loads((PROJECT / "docs/api-sources.json").read_text())
    schema = json.loads(verified_source(source_directory / "openapi.json", pins["rest"]))
    graphql_path = source_directory / "schema.graphql"
    if not graphql_path.exists():
        graphql_path = PROJECT / "docs" / pins["graphql"]["snapshot"]
    graphql = verified_source(graphql_path, pins["graphql"])
    graphql = re.sub(r'""".*?"""', '', graphql, flags=re.S)
    records = []
    for path, methods in sorted(schema["paths"].items()):
        for method, operation in sorted(methods.items()):
            if method not in METHODS:
                continue
            capability, requirement = classify(operation)
            parameters = []
            for parameter in methods.get("parameters", []) + operation.get("parameters", []):
                if "$ref" in parameter:
                    parameter = schema["components"]["parameters"][parameter["$ref"].split("/")[-1]]
                parameters.append(parameter["name"])
            metadata = operation.get("x-github", {})
            records.append({
                "operation_id": operation["operationId"], "capability_candidate": capability,
                "requirement_candidate": requirement, "outcome": operation["summary"],
                "method": method.upper(), "path": path, "api_version": pins["rest_version"],
                "host": "api.github.com; GHES unverified", "effect": "read" if method in {"get", "head", "options"} else "write; review destructive effects",
                "github_app_schema_flag": str(metadata.get("enabledForGitHubApps", "unknown")).lower(),
                "oauth_scopes": "unverified", "fine_grained_permissions": "unverified",
                "role_plan": "unverified", "pagination_parameters": "|".join(p for p in parameters if p in {"page", "per_page", "before", "after", "since"}),
                "limits": "returned rate headers; endpoint limits unverified", "coverage": "unverified",
                "fallback_documentation": operation.get("externalDocs", {}).get("url", "https://docs.github.com/rest"),
                "evidence": "schema only", "owner": "GitHub integration lead",
                "milestone": "audit against API-COVERAGE.md", "verified_on": "",
            })
    output_directory.mkdir(parents=True, exist_ok=True)
    with (output_directory / "rest-operations.csv").open("w", newline="") as output:
        writer = csv.DictWriter(output, fieldnames=list(records[0]), lineterminator="\n")
        writer.writeheader()
        writer.writerows(records)
    graphql_fields = []
    for kind in ("Query", "Mutation"):
        match = re.search(rf"^type {kind}\b[^\n]*\{{\n(.*?)^\}}", graphql, re.M | re.S)
        if match is None:
            raise ValueError(f"Missing GraphQL {kind}")
        fields = re.findall(r"^  ([A-Za-z][A-Za-z0-9_]*)(?:\(|:)", match.group(1), re.M)
        graphql_fields.extend({"root": kind, "field": field, "coverage": "unverified", "capability": "CAP-34; manual triage required"} for field in fields)
    (output_directory / "graphql-operations.json").write_text(json.dumps({
        "schema_sha256": pins["graphql"]["sha256"], "fields": graphql_fields,
    }, indent=2) + "\n")
    identifiers = [row["operation_id"] for row in records]
    if len(set(identifiers)) != len(identifiers):
        raise ValueError("Duplicate REST operation IDs")
    print(json.dumps({"rest_operations": len(records), "graphql_root_fields": len(graphql_fields),
                      "authenticated_verified": 0}, indent=2))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sources", type=Path, default=PROJECT / ".build/m0")
    parser.add_argument("--output", type=Path, default=PROJECT / "docs/evidence")
    arguments = parser.parse_args()
    generate(arguments.sources, arguments.output)
