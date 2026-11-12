#!/usr/bin/env python3
"""Exercise interrupted rebase recovery using an isolated, disposable Git repository."""

import argparse
import json
import os
from pathlib import Path
import shlex
import shutil
import signal
import subprocess
import sys
import tempfile
import time


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def experiment(root, git_path):
    repository = root / "repository"
    repository.mkdir()
    require(git_path is not None, "Git is required")
    environment = {
        "PATH": os.environ.get("PATH", "/usr/bin:/bin"),
        "HOME": str(root),
        "GIT_CONFIG_NOSYSTEM": "1",
        "GIT_CONFIG_GLOBAL": "/dev/null",
        "GIT_TERMINAL_PROMPT": "0",
        "GIT_EDITOR": "true",
    }

    def git(*arguments):
        return subprocess.check_output(
            [git_path, *arguments], cwd=repository, env=environment, stderr=subprocess.PIPE
        )

    git("init", "--initial-branch=main")
    git("config", "user.name", "M0 Fixture")
    git("config", "user.email", "fixture@example.invalid")
    git("config", "gc.auto", "0")
    git("config", "maintenance.auto", "false")
    tracked = repository / "tracked.txt"
    tracked.write_text("base\n")
    git("add", ".")
    git("commit", "-m", "base")
    git("switch", "-c", "topic")
    for number in range(2):
        (repository / f"topic-{number}.txt").write_text(f"topic {number}\n")
        git("add", ".")
        git("commit", "-m", f"topic {number}")
    starting_head = git("rev-parse", "HEAD").strip().decode()
    git("switch", "main")
    (repository / "upstream.txt").write_text("upstream\n")
    git("add", ".")
    git("commit", "-m", "upstream")
    git("switch", "topic")
    tracked.write_text("staged\n")
    git("add", "tracked.txt")
    tracked.write_text("staged\nunstaged\n")
    (repository / "untracked.txt").write_text("untracked\n")
    starting_status = git("status", "--porcelain=v1", "-z")
    starting_index = git("diff", "--cached", "--binary")
    starting_worktree = git("diff", "--binary")
    committed_ref = "refs/gitworkspace/checkpoints/m0-head"
    dirty_ref = "refs/gitworkspace/checkpoints/m0-dirty"
    git("update-ref", committed_ref, starting_head)
    git("stash", "push", "--include-untracked", "-m", "M0 dirty checkpoint")
    dirty_sha = git("rev-parse", "refs/stash").strip().decode()
    git("update-ref", dirty_ref, dirty_sha)
    (root / "journal.json").write_text(json.dumps({
        "operation": "rebase", "phase": "checkpointed",
        "head": starting_head, "head_ref": committed_ref, "dirty_ref": dirty_ref,
    }))
    require(not git("status", "--porcelain"), "Checkpoint did not clean the worktree")

    blocker = root / "blocker.py"
    marker = root / "rebase-running"
    blocker.write_text(
        "from pathlib import Path\nimport sys, time\n"
        "marker = Path(sys.argv[1])\n"
        "if not marker.exists():\n"
        "    marker.write_text('first commit replayed')\n"
        "    time.sleep(30)\n"
    )
    exec_command = shlex.join([sys.executable, str(blocker), str(marker)])

    def interrupt_rebase():
        marker.unlink(missing_ok=True)
        with (root / "rebase.log").open("wb") as log:
            process = subprocess.Popen(
                [git_path, "rebase", "--exec", exec_command, "main"],
                cwd=repository, env=environment, stdout=log, stderr=log,
                start_new_session=True,
            )
            try:
                deadline = time.monotonic() + 15
                while not marker.exists() and process.poll() is None and time.monotonic() < deadline:
                    time.sleep(0.02)
                require(marker.exists(), "Rebase failed to reach the interruption point")
                require(git("rev-parse", "HEAD").strip().decode() != starting_head,
                        "Interruption must follow a replayed commit")
            finally:
                if process.poll() is None:
                    os.killpg(process.pid, signal.SIGKILL)
                process.wait(timeout=5)
        require((repository / ".git/rebase-merge").is_dir(), "Interrupted state missing")
        require(b"rebase in progress" in git("status"), "Fresh Git process cannot detect rebase")

    interrupt_rebase()
    git("rebase", "--abort")
    require(git("rev-parse", "HEAD").strip().decode() == starting_head, "Abort changed HEAD")
    git("stash", "apply", "--index", dirty_ref)
    require(git("status", "--porcelain=v1", "-z") == starting_status, "Status recovery differs")
    require(git("diff", "--cached", "--binary") == starting_index, "Staged recovery differs")
    require(git("diff", "--binary") == starting_worktree, "Unstaged recovery differs")
    require((repository / "untracked.txt").read_text() == "untracked\n", "Untracked recovery differs")
    git("stash", "push", "--include-untracked", "-m", "M0 repeat")
    interrupt_rebase()
    git("rebase", "--continue")
    require(not (repository / ".git/rebase-merge").exists(), "Continue left rebase state")
    require(git("rev-list", "--count", "main..HEAD").strip() == b"2", "Replayed history differs")
    git("branch", "recovered", committed_ref)
    require(git("rev-parse", "recovered").strip().decode() == starting_head, "Recovery branch differs")
    git("fsck", "--no-dangling")
    return {
        "experiment": "DISC-03 interrupted rebase", "git": git("--version").decode().strip(),
        "passed": ["SIGKILL after commit replay", "fresh-process state detection", "abort restores HEAD",
                   "staged content restored", "unstaged content restored", "untracked content restored",
                   "continue completes after SIGKILL", "checkpoint restored to new branch", "git fsck"],
        "limitations": ["runtime selected by --git", "synthetic fixture", "no app journal implementation",
                        "no disk-full, lock-contention, or power-loss proof"],
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--git", default=shutil.which("git"))
    arguments = parser.parse_args()
    with tempfile.TemporaryDirectory(prefix="gitworkspace-m0-") as directory:
        print(json.dumps(experiment(Path(directory), arguments.git), indent=2))
