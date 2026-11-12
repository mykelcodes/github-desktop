#!/usr/bin/env python3
"""Check a relocated Git/LFS runtime with disposable local transport and signing fixtures."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile


def check(root, runtime):
    git_path = str(runtime / "bin/git")
    environment = {"PATH": f"{runtime / 'bin'}:/usr/bin:/bin:/usr/sbin:/sbin",
                   "HOME": str(root), "GIT_CONFIG_NOSYSTEM": "1", "GIT_CONFIG_GLOBAL": "/dev/null",
                   "GIT_TERMINAL_PROMPT": "0", "LC_ALL": "C"}

    def git(repository, *arguments):
        return subprocess.check_output([git_path, *arguments], cwd=repository,
                                       env=environment, stderr=subprocess.PIPE)

    key = root / "signing-key"
    subprocess.run(["/usr/bin/ssh-keygen", "-q", "-t", "ed25519", "-N", "", "-f", str(key)],
                   check=True, env=environment)
    allowed_signers = root / "allowed-signers"
    allowed_signers.write_text("fixture@example.invalid " + key.with_suffix(".pub").read_text())
    repository = root / "source"
    repository.mkdir()
    git(repository, "init", "--initial-branch=main")
    for name, value in [("user.name", "M0"), ("user.email", "fixture@example.invalid"),
                        ("gc.auto", "0"), ("maintenance.auto", "false"), ("gpg.format", "ssh"),
                        ("user.signingkey", str(key)), ("gpg.ssh.allowedSignersFile", str(allowed_signers))]:
        git(repository, "config", name, value)
    git(repository, "lfs", "install", "--local")
    git(repository, "lfs", "track", "*.bin")
    content = bytes(range(256)) * 4096
    (repository / "asset.bin").write_bytes(content)
    git(repository, "add", ".")
    git(repository, "commit", "-S", "-m", "Signed LFS fixture")
    git(repository, "verify-commit", "HEAD")
    git(repository, "tag", "-s", "fixture", "-m", "Signed tag")
    git(repository, "verify-tag", "fixture")
    pointer = git(repository, "show", "HEAD:asset.bin")
    if hashlib.sha256(content).hexdigest().encode() not in pointer:
        raise RuntimeError("LFS pointer does not match fixture")
    remote = root / "remote.git"
    git(root, "init", "--bare", "--initial-branch=main", str(remote))
    git(repository, "remote", "add", "origin", str(remote))
    git(repository, "push", "-u", "origin", "main", "--tags")
    clone = root / "clone"
    git(root, "clone", str(remote), str(clone))
    git(clone, "lfs", "install", "--local")
    git(clone, "lfs", "pull")
    git(clone, "lfs", "fsck")
    if (clone / "asset.bin").read_bytes() != content:
        raise RuntimeError("LFS checkout differs from source")
    git(clone, "-c", f"gpg.ssh.allowedSignersFile={allowed_signers}", "verify-commit", "HEAD")
    git(clone, "fsck", "--no-dangling")
    return {"git": git(root, "--version").decode().strip(),
            "lfs": git(repository, "lfs", "version").decode().strip(),
            "passed": ["relocated Git executable", "LFS helper discovery", "SSH commit signing",
                       "SSH tag signing", "signature verification", "LFS pointer creation",
                       "local bare-remote push", "clone and LFS content retrieval", "LFS fsck", "Git fsck"],
            "limitations": ["local transport", "ephemeral SSH signing key", "no SSH agent or GPG",
                            "no authenticated HTTPS/SSH remote", "no clean-Mac or notarization proof"]}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--runtime", type=Path, required=True)
    arguments = parser.parse_args()
    with tempfile.TemporaryDirectory(prefix="gitworkspace-runtime-") as directory:
        report = check(Path(directory), arguments.runtime.resolve())
    print(json.dumps(report, indent=2))
