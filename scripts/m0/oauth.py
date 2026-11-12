#!/usr/bin/env python3
"""Local OAuth feasibility harness. Tokens and the client secret stay in memory."""

import argparse
import base64
import getpass
import hashlib
import hmac
from http.server import BaseHTTPRequestHandler, HTTPServer
import json
import secrets
import sys
import time
from urllib.error import HTTPError
from urllib.parse import parse_qs, urlencode, urlsplit
from urllib.request import build_opener, HTTPRedirectHandler, Request
import webbrowser


CALLBACK = "http://127.0.0.1:49152/oauth/callback"


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, request, file, code, message, headers, new_url):
        return None


def request_json(url, payload=None, token=None, method=None, client_credentials=None):
    headers = {"Accept": "application/json", "User-Agent": "GitWorkspace-M0"}
    if url.startswith("https://api.github.com/"):
        headers["X-GitHub-Api-Version"] = "2026-03-10"
    if token:
        headers["Authorization"] = f"Bearer {token}"
    if client_credentials:
        encoded = base64.b64encode(client_credentials.encode()).decode()
        headers["Authorization"] = f"Basic {encoded}"
    body = None
    if payload is not None:
        headers["Content-Type"] = "application/json"
        body = json.dumps(payload).encode()
    request = Request(url, data=body, headers=headers, method=method)
    try:
        with build_opener(NoRedirect).open(request, timeout=30) as response:
            content = response.read(2_000_000)
            return response.status, json.loads(content) if content else {}
    except HTTPError as error:
        status = error.code
        error.close()
        return status, {}


def authorize(client_id, scopes):
    state = secrets.token_urlsafe(32)
    verifier = secrets.token_urlsafe(48)
    challenge = base64.urlsafe_b64encode(hashlib.sha256(verifier.encode()).digest()).rstrip(b"=").decode()
    result = {}

    class Callback(BaseHTTPRequestHandler):
        def log_message(self, *arguments):
            pass

        def do_GET(self):
            parsed = urlsplit(self.path)
            query = parse_qs(parsed.query)
            valid = (
                parsed.path == "/oauth/callback"
                and self.headers.get("Host") == "127.0.0.1:49152"
                and len(query.get("state", [])) == 1
                and hmac.compare_digest(query["state"][0], state)
                and not result
            )
            if not valid:
                self.send_error(400, "Invalid callback")
                return
            if len(query.get("code", [])) == 1 and "error" not in query:
                result["code"] = query["code"][0]
            elif query.get("error") == ["access_denied"]:
                result["cancelled"] = True
            else:
                self.send_error(400, "Invalid authorization response")
                return
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.send_header("Cache-Control", "no-store")
            self.send_header("Referrer-Policy", "no-referrer")
            self.end_headers()
            self.wfile.write(b"Authorization received. Return to your terminal.")

    url = "https://github.com/login/oauth/authorize?" + urlencode({
        "client_id": client_id, "redirect_uri": CALLBACK, "scope": scopes,
        "state": state, "code_challenge": challenge, "code_challenge_method": "S256",
        "prompt": "select_account",
    })
    with HTTPServer(("127.0.0.1", 49152), Callback) as server:
        server.timeout = 1
        print("Opening GitHub authorization in your browser. Callback expires in five minutes.", flush=True)
        if not webbrowser.open(url):
            raise RuntimeError("Open a browser and retry the harness")
        deadline = time.monotonic() + 300
        while not result and time.monotonic() < deadline:
            server.handle_request()
    if "code" not in result:
        raise RuntimeError("Authorization cancelled or timed out")
    return result["code"], verifier


def run(client_id, scopes):
    if not sys.stdin.isatty():
        raise RuntimeError("Run in an interactive terminal so the secret prompt stays hidden")
    client_secret = getpass.getpass("OAuth client secret (hidden, used only in this local process): ")
    if not client_secret:
        raise RuntimeError("This harness requires the developer-owned client secret")
    code, verifier = authorize(client_id, scopes)
    checks = []
    status, grant = request_json("https://github.com/login/oauth/access_token", {
        "client_id": client_id, "client_secret": client_secret,
        "code": code, "redirect_uri": CALLBACK, "code_verifier": verifier,
    })
    token = grant.get("access_token")
    if status != 200 or not token:
        raise RuntimeError(f"Code exchange failed (HTTP {status}); response body suppressed")
    checks.append({"check": "PKCE code exchange", "status": "passed"})
    try:
        status, user = request_json("https://api.github.com/user", token=token)
        if status != 200 or "id" not in user:
            raise RuntimeError(f"Identity lookup failed (HTTP {status})")
        identity = user["id"]
        checks.append({"check": "authenticated identity", "status": "passed"})
        for name, path in [("repository list", "/user/repos?per_page=1"),
                           ("notification list", "/notifications?per_page=1")]:
            status, _ = request_json("https://api.github.com" + path, token=token)
            checks.append({"check": name, "http_status": status})
        refresh_token = grant.get("refresh_token")
        if refresh_token:
            status, rotated = request_json("https://github.com/login/oauth/access_token", {
                "client_id": client_id, "client_secret": client_secret,
                "grant_type": "refresh_token", "refresh_token": refresh_token,
            })
            if status != 200 or "access_token" not in rotated:
                raise RuntimeError(f"Refresh failed (HTTP {status}); response body suppressed")
            previous_token = token
            token = rotated["access_token"]
            status, refreshed_user = request_json("https://api.github.com/user", token=token)
            passed = (status == 200 and refreshed_user.get("id") == identity
                      and token != previous_token and rotated.get("refresh_token")
                      and rotated["refresh_token"] != refresh_token)
            checks.append({"check": "refresh rotation and identity", "status": "passed" if passed else "failed"})
        else:
            checks.append({"check": "refresh rotation", "status": "not exercised; no refresh token"})
        print(json.dumps({"client_id": client_id, "checks": checks,
                          "granted_scopes": grant.get("scope", ""),
                          "limitations": ["local developer harness", "no signed native callback",
                                          "notification mutations and org restrictions untested",
                                          "two-account isolation and refresh races untested"]}, indent=2))
    finally:
        status, _ = request_json(f"https://api.github.com/applications/{client_id}/token",
                                 {"access_token": token}, method="DELETE",
                                 client_credentials=f"{client_id}:{client_secret}")
        print(json.dumps({"check": "revoke harness token", "http_status": status}), flush=True)
        if status != 204:
            print(f"Revoke authorization in https://github.com/settings/connections/applications/{client_id}")
        else:
            status, _ = request_json("https://api.github.com/user", token=token)
            print(json.dumps({"check": "revoked token rejected", "http_status": status}), flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--client-id", required=True)
    parser.add_argument("--scopes", default="read:user notifications offline_access")
    arguments = parser.parse_args()
    try:
        run(arguments.client_id, arguments.scopes)
    except RuntimeError as error:
        print(str(error))
        raise SystemExit(1)
    except (KeyboardInterrupt, Exception) as error:
        print(f"Harness stopped ({type(error).__name__}). Tokens and response bodies suppressed.")
        raise SystemExit(1)
