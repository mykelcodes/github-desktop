#!/usr/bin/env python3
"""Measure bounded history retrieval and warm status in disposable real-Git fixtures."""

import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time


def benchmark(root, git_path):
    environment = {"PATH": os.environ.get("PATH", "/usr/bin:/bin"), "HOME": str(root),
                   "GIT_CONFIG_NOSYSTEM": "1", "GIT_CONFIG_GLOBAL": "/dev/null",
                   "GIT_TERMINAL_PROMPT": "0", "LC_ALL": "C"}

    def git(*arguments, data=None):
        return subprocess.check_output([git_path, *arguments], cwd=root, env=environment,
                                       input=data, stderr=subprocess.PIPE)

    git("init", "--initial-branch=main")
    git("config", "user.name", "M0 Fixture")
    git("config", "user.email", "fixture@example.invalid")
    git("config", "gc.auto", "0")
    git("config", "maintenance.auto", "false")
    stream = bytearray()
    for number in range(100_000):
        message = f"commit {number}\n"
        stream.extend((f"commit refs/heads/main\nmark :{number + 1}\n"
                       f"committer M0 <fixture@example.invalid> {1_700_000_000 + number} +0000\n"
                       f"data {len(message)}\n{message}\n").encode())
    git("fast-import", "--quiet", data=bytes(stream))
    if git("rev-list", "--count", "HEAD").strip() != b"100000":
        raise RuntimeError("History fixture commit count differs")
    for number in range(10_000):
        (root / f"file-{number:05d}.txt").write_text(f"fixture {number}\n")
    git("add", ".")
    git("commit", "--amend", "--no-edit")
    results = []
    for name, command in [("first 200 commits from 100000", ["log", "--max-count=200", "--format=%H%x00%s"]),
                          ("warm status 10000 files", ["status", "--porcelain=v2", "-z"])]:
        git(*command)
        samples = []
        for _ in range(20):
            start = time.perf_counter()
            output = git(*command)
            samples.append((time.perf_counter() - start) * 1000)
        if name.startswith("first") and len(output.splitlines()) != 200:
            raise RuntimeError("Bounded history page differs")
        if name.startswith("warm") and output:
            raise RuntimeError("Status fixture is dirty")
        ordered = sorted(samples)
        results.append({"case": name, "trials": len(samples), "p50_ms": ordered[9],
                        "p95_ms": ordered[18], "max_ms": ordered[-1]})
    return {"git": git("--version").decode().strip(), "commits": 100_000, "files": 10_000,
            "results": results, "limitations": ["warm filesystem cache", "linear synthetic history",
                                                "UI rendering measured separately"]}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--git", default=shutil.which("git"))
    arguments = parser.parse_args()
    with tempfile.TemporaryDirectory(prefix="gitworkspace-m0-perf-") as directory:
        report = benchmark(Path(directory), arguments.git)
    print(json.dumps(report, indent=2))
