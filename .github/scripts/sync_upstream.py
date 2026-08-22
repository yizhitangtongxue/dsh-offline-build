#!/usr/bin/env python3
"""Synchronize pinned DSH versions from the official npm registry."""

from __future__ import annotations

import argparse
import json
import os
import re
import urllib.parse
import urllib.request
from pathlib import Path

REGISTRY = "https://registry.npmjs.org"
PACKAGES = {
    "dsh": "@deepseek-ai/dsh",
    "webui": "@linxin666/dsh-web-ui-all",
}
VERSION_RE = re.compile(r"^[0-9A-Za-z][0-9A-Za-z._+-]*$")


def npm_latest(package: str) -> str:
    encoded = urllib.parse.quote(package, safe="")
    request = urllib.request.Request(
        f"{REGISTRY}/{encoded}",
        headers={"Accept": "application/json", "User-Agent": "dsh-offline-upstream-sync/1"},
    )
    with urllib.request.urlopen(request, timeout=30) as response:
        metadata = json.load(response)
    version = metadata.get("dist-tags", {}).get("latest")
    if not isinstance(version, str) or not VERSION_RE.fullmatch(version):
        raise RuntimeError(f"Invalid latest version for {package!r}: {version!r}")
    return version


def replace_regex(path: Path, pattern: str, replacement: str, expected: int) -> bool:
    original = path.read_text(encoding="utf-8")
    updated, count = re.subn(pattern, replacement, original, flags=re.MULTILINE)
    if count != expected:
        raise RuntimeError(f"Expected {expected} matches in {path}, found {count}")
    if updated == original:
        return False
    path.write_text(updated, encoding="utf-8")
    return True


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--dsh-version", help="Override registry result (for tests)")
    parser.add_argument("--webui-version", help="Override registry result (for tests)")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    root = args.root.resolve()
    version_file = root / ".github/upstream-versions.env"
    runtime_package = root / "payload/runtime-package.json"
    dockerfile = root / "Dockerfile"
    readme = root / "README.md"

    version_text = version_file.read_text(encoding="utf-8")
    current_dsh_match = re.search(r'^DSH_VERSION=([^\s]+)$', version_text, re.MULTILINE)
    current_webui_match = re.search(r'^DSH_WEBUI_VERSION=([^\s]+)$', version_text, re.MULTILINE)
    if not current_dsh_match or not current_webui_match:
        raise RuntimeError("Could not read pinned versions from upstream-versions.env")

    old_dsh = current_dsh_match.group(1)
    old_webui = current_webui_match.group(1)
    new_dsh = args.dsh_version or npm_latest(PACKAGES["dsh"])
    new_webui = args.webui_version or npm_latest(PACKAGES["webui"])
    for version in (new_dsh, new_webui):
        if not VERSION_RE.fullmatch(version):
            raise RuntimeError(f"Invalid version: {version!r}")

    changed = old_dsh != new_dsh or old_webui != new_webui
    changed_files: list[str] = []

    if changed and not args.dry_run:
        version_changed = False
        if old_dsh != new_dsh:
            version_changed |= replace_regex(
                version_file, r'^DSH_VERSION=.*$', f"DSH_VERSION={new_dsh}", 1
            )
        if old_webui != new_webui:
            version_changed |= replace_regex(
                version_file,
                r'^DSH_WEBUI_VERSION=.*$',
                f"DSH_WEBUI_VERSION={new_webui}",
                1,
            )
        if version_changed:
            changed_files.append(str(version_file.relative_to(root)))

        package_data = json.loads(runtime_package.read_text(encoding="utf-8"))
        if package_data["dependencies"][PACKAGES["dsh"]] != new_dsh:
            package_data["dependencies"][PACKAGES["dsh"]] = new_dsh
            runtime_package.write_text(json.dumps(package_data, indent=2) + "\n", encoding="utf-8")
            changed_files.append(str(runtime_package.relative_to(root)))

        docker_changed = False
        if old_dsh != new_dsh:
            docker_changed |= replace_regex(dockerfile, r'^ARG DSH_VERSION=.*$', f"ARG DSH_VERSION={new_dsh}", 2)
        if old_webui != new_webui:
            docker_changed |= replace_regex(dockerfile, r'^ARG DSH_WEBUI_VERSION=.*$', f"ARG DSH_WEBUI_VERSION={new_webui}", 2)
        if docker_changed:
            changed_files.append(str(dockerfile.relative_to(root)))

        readme_text = readme.read_text(encoding="utf-8")
        updated_readme = readme_text.replace(
            f"@deepseek-ai/dsh@{old_dsh}", f"@deepseek-ai/dsh@{new_dsh}"
        ).replace(
            f"@linxin666/dsh-web-ui-all@{old_webui}",
            f"@linxin666/dsh-web-ui-all@{new_webui}",
        )
        if updated_readme != readme_text:
            readme.write_text(updated_readme, encoding="utf-8")
            changed_files.append(str(readme.relative_to(root)))

    result = {
        "changed": changed,
        "old_dsh": old_dsh,
        "new_dsh": new_dsh,
        "old_webui": old_webui,
        "new_webui": new_webui,
        "changed_files": changed_files,
        "dry_run": args.dry_run,
    }
    print(json.dumps(result, ensure_ascii=False, indent=2))

    github_output = os.environ.get("GITHUB_OUTPUT")
    if github_output:
        with open(github_output, "a", encoding="utf-8") as output:
            output.write(f"changed={'true' if changed else 'false'}\n")
            output.write(f"dsh_version={new_dsh}\n")
            output.write(f"webui_version={new_webui}\n")
            output.write(f"old_dsh_version={old_dsh}\n")
            output.write(f"old_webui_version={old_webui}\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
