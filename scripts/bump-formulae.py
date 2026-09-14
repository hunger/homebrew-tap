#!/usr/bin/env python3
"""Bump the formulae in this tap to the newest upstream version.

For every formula that is outdated:
  1. rewrite the old version to the new one in every `url "..."` line
     and in the `version "..."` line if present,
  2. download every URL and refresh the following `sha256 "..."` line,
  3. run `brew style`, `brew audit --strict`, `brew install` and `brew test`,
  4. revert the file if any step fails.

A formula opts into a different update mode with a magic comment:

  # bump: fixed-url
      The URLs point at a moving tag (e.g. a `nightly` release) and never
      change; only `version` and the checksums are refreshed. The new version
      comes from `brew livecheck`, so the formula needs a livecheck block.

  # bump: git-commit <GitHub commits API URL>
      The URL pins a commit tarball. The API is queried for the branch head;
      the 40-hex commit in the URL is replaced, `version` is set to the
      commit's UTC time as YYYY.MM.DD.HHMM, and the checksum is refreshed.

Bottling (opt-in per formula with `# bottle: <tag>`, used with --bottle):
  the verification install is done with --build-bottle, `brew bottle` writes
  the bottle tarball into bottles/ and the bottle block is merged into the
  formula with the given --bottle-root-url. bottles/releases.json lists the
  GitHub release tag and files the caller must upload before pushing.
  A stale bottle block is dropped whenever a formula is bumped.

Exit status: 0 if everything succeeded, 2 if at least one formula failed
(successful bumps are kept on disk either way).

Usage: bump-formulae.py [--tap OWNER/NAME] [--no-verify] [--bottle --bottle-root-url URL]
                        [--force NAME]... [FORMULA...]
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from re import Pattern

URL_RE = re.compile(r'^(\s*url\s+")([^"]+)(".*)$')
SHA_RE = re.compile(r'^(\s*sha256\s+")([0-9a-f]{64})(".*)$')
VERSION_RE = re.compile(r'^(\s*version\s+")([^"]+)(".*)$')
MODE_RE = re.compile(
    r"^\s*#\s*bump:\s*(fixed-url|git-commit)(?:\s+(\S+))?\s*$", re.MULTILINE
)
COMMIT_RE: Pattern[str] = re.compile(r"[0-9a-f]{40}")
LIVECHECK_START_RE = re.compile(r"^(\s*)livecheck do\s*$")
BOTTLE_START_RE = re.compile(r"^(\s*)bottle do\s*$")
BOTTLE_MARK_RE = re.compile(r"^\s*#\s*bottle:\s*(\S+)", re.MULTILINE)

REPO_ROOT = Path(__file__).resolve().parent.parent
FORMULA_DIR = REPO_ROOT / "Formula"
BOTTLE_DIR = REPO_ROOT / "bottles"

ENV = {
    **os.environ,
    "HOMEBREW_NO_AUTO_UPDATE": "1",
    "HOMEBREW_NO_ENV_HINTS": "1",
    "HOMEBREW_NO_INSTALL_CLEANUP": "1",
}


def brew(
    *args: str, check: bool = True, capture: bool = False
) -> subprocess.CompletedProcess:
    return subprocess.run(
        ["brew", *args], env=ENV, check=check, text=True, capture_output=capture
    )


def livecheck(tap: str, names: list[str]) -> list[dict]:
    targets = [f"{tap}/{n}" for n in names] if names else ["--tap", tap]
    # livecheck exits non-zero when any single formula errors but still emits JSON for all.
    proc = brew("livecheck", "--json", "--quiet", *targets, check=False, capture=True)
    try:
        return json.loads(proc.stdout or "[]")
    except json.JSONDecodeError:
        raise RuntimeError(
            f"brew livecheck failed (exit {proc.returncode}): {proc.stderr.strip()}"
        ) from None


def http_get(url: str) -> urllib.request.Request:
    headers = {"User-Agent": "homebrew-tap-bump/1.0"}
    token = os.environ.get("HOMEBREW_GITHUB_API_TOKEN") or os.environ.get(
        "GITHUB_TOKEN"
    )
    if token and url.startswith("https://api.github.com/"):
        headers["Authorization"] = f"Bearer {token}"
    return urllib.request.Request(url, headers=headers)


def detect_mode(text: str) -> tuple[str, str | None]:
    """Return (mode, argument) from the `# bump:` comment; default mode is 'version'."""
    if m := MODE_RE.search(text):
        return m.group(1), m.group(2)
    return "version", None


def branch_head(api_url: str) -> tuple[str, str]:
    """Return (commit sha, version) for a GitHub commits API URL."""
    with urllib.request.urlopen(http_get(api_url), timeout=60) as resp:
        data = json.load(resp)
    sha = data["sha"]
    date = data["commit"]["committer"]["date"]  # e.g. 2026-07-23T16:03:37Z (UTC)
    m = re.match(r"(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})", date)
    if not m:
        raise RuntimeError(f"unexpected commit date {date!r}")
    return sha, f"{m[1]}.{m[2]}.{m[3]}.{m[4]}{m[5]}"


def current_version(text: str) -> str | None:
    for line in text.splitlines():
        if m := VERSION_RE.match(line):
            return m.group(2)
    return None


def resolve_url(url: str, version: str) -> str:
    """Resolve a formula url to a concrete download URL.

    `#{version}` is interpolated like Homebrew does; other Ruby expressions
    (e.g. `#{os.name}`) are left for Homebrew and cannot be resolved here.
    """
    for m in re.finditer(r"#\{(.+?)\}", url):
        if m.group(1) != "version":
            raise RuntimeError(f"url contains unresolvable Ruby expression: {url}")
    return url.replace("#{version}", version)


def sha256_of_url(url: str, version: str) -> str:
    req = http_get(resolve_url(url, version))
    h = hashlib.sha256()
    with urllib.request.urlopen(req, timeout=120) as resp:
        while chunk := resp.read(1 << 20):
            h.update(chunk)
    return h.hexdigest()


def rewrite(
    path: Path, old: str, new: str, mode: str = "version", new_commit: str | None = None
) -> str:
    """Return the formula text bumped from `old` to `new`.

    mode "version":    substitute old -> new inside every url; urls may use
                       `#{version}` interpolation instead of the literal version.
    mode "fixed-url":  leave urls alone, refresh checksums only.
    mode "git-commit": replace the 40-hex commit in every url with new_commit.
    """
    lines = path.read_text().splitlines(keepends=True)
    out: list[str] = []
    pending_url: tuple[str, str] | None = None  # (url, version)
    urls_changed = 0
    livecheck_indent: str | None = (
        None  # inside `livecheck do ... end`: its url is not a download
    )
    bottle_indent: str | None = (
        None  # inside `bottle do ... end`: stale after a bump, drop it
    )
    drop_blank = False

    for line in lines:
        if livecheck_indent is not None:
            if line.rstrip("\n") == f"{livecheck_indent}end":
                livecheck_indent = None
            out.append(line)
            continue
        if bottle_indent is not None:
            if line.rstrip("\n") == f"{bottle_indent}end":
                bottle_indent = None
                drop_blank = True  # also drop the blank line that followed the block
            continue
        if drop_blank:
            drop_blank = False
            if line.strip() == "":
                continue
        if m := BOTTLE_START_RE.match(line):
            bottle_indent = m.group(1)
            continue
        if m := LIVECHECK_START_RE.match(line):
            livecheck_indent = m.group(1)
        elif m := VERSION_RE.match(line):
            if m.group(2) != old:
                raise RuntimeError(
                    f"version line says {m.group(2)!r}, expected {old!r}"
                )
            line = f"{m.group(1)}{new}{m.group(3)}\n"
        elif m := URL_RE.match(line):
            url = m.group(2)
            if mode == "fixed-url":
                new_url = url
            elif mode == "git-commit":
                assert new_commit is not None
                if not COMMIT_RE.search(url):
                    raise RuntimeError(f"url does not contain a 40-hex commit: {url}")
                new_url = COMMIT_RE.sub(new_commit, url)
            else:
                if old in url:
                    new_url = url.replace(old, new)
                elif "#{version}" in url:
                    # The version lives in the `version` line; the url interpolates it.
                    new_url = url
                else:
                    raise RuntimeError(
                        f"url contains neither {old!r} nor '#{{version}}': {url}"
                    )
            urls_changed += 1
            pending_url = (new_url, new)
            if new_url != url:
                print(f"    url was {line.rstrip()}")
                print(f"    now is {m.group(1)}{new_url}{m.group(3)}")
            line = f"{m.group(1)}{new_url}{m.group(3)}\n"
        elif m := SHA_RE.match(line):
            if pending_url is None:
                raise RuntimeError("sha256 line without a preceding url line")
            print(f"    fetching {resolve_url(*pending_url)}")
            digest = sha256_of_url(*pending_url)
            pending_url = None
            line = f"{m.group(1)}{digest}{m.group(3)}\n"
        out.append(line)

    if pending_url is not None:
        raise RuntimeError(
            f"url without a following sha256 line: {resolve_url(*pending_url)}"
        )
    if urls_changed == 0:
        raise RuntimeError("no url lines found")
    return "".join(out)


def verify(tap: str, name: str, build_bottle: bool = False) -> None:
    rel = str((FORMULA_DIR / f"{name}.rb").relative_to(REPO_ROOT))
    full = f"{tap}/{name}"
    brew("style", rel)
    brew("audit", "--strict", full)
    if build_bottle:
        # `brew bottle` refuses kegs that were not installed with --build-bottle.
        brew("uninstall", "--force", full, check=False)
        brew("install", "--build-bottle", full)
    else:
        brew("reinstall", full)
    brew("test", full)


def bottle(tap: str, name: str, root_url: str) -> dict:
    """Bottle the installed keg, merge the bottle block into the formula.

    Returns {"tag": <release tag>, "files": [<paths to upload>]}.
    """
    full = f"{tap}/{name}"
    rel = str((FORMULA_DIR / f"{name}.rb").relative_to(REPO_ROOT))
    info = json.loads(brew("info", "--json=v2", full, capture=True).stdout)["formulae"][
        0
    ]
    version = info["versions"]["stable"]
    release_tag = f"{name}-{version}"
    BOTTLE_DIR.mkdir(exist_ok=True)
    for old in BOTTLE_DIR.glob(f"{name}-*"):
        old.unlink()
    subprocess.run(
        ["brew", "bottle", "--json", f"--root-url={root_url}/{release_tag}", full],
        cwd=BOTTLE_DIR,
        env=ENV,
        check=True,
        text=True,
    )
    json_files = sorted(BOTTLE_DIR.glob(f"{name}--*.bottle*.json"))
    if not json_files:
        raise RuntimeError("brew bottle produced no JSON")
    brew("bottle", "--merge", "--write", "--no-commit", *map(str, json_files))
    brew("style", rel)
    files: list[str] = []
    for jf in json_files:
        data = json.load(jf.open())
        for tag_info in data[full]["bottle"]["tags"].values():
            src = BOTTLE_DIR / tag_info["local_filename"]
            dst = BOTTLE_DIR / tag_info["filename"]  # the name the root_url expects
            if src.exists() and src != dst:
                src.rename(dst)
            files.append(str(dst))
            print(f"    bottled {dst.name}")
    return {"tag": release_tag, "files": files}


def update_readme_table(names: list[tuple[str, str]]) -> None:
    """Update the 'Version' and 'Last Updated' columns in README.md for each
    bumped formula, then re-sort rows by newest timestamp first.

    `names` is a list of (formula name, new version) tuples."""
    readme = REPO_ROOT / "README.md"
    if not readme.exists():
        return
    lines = readme.read_text().splitlines(keepends=True)

    header_idx = None
    for i, line in enumerate(lines):
        if "| Last Updated" in line:
            header_idx = i
            break
    if header_idx is None:
        return

    data_start = header_idx + 2  # skip separator row
    data_end = data_start
    while data_end < len(lines) and lines[data_end].strip().startswith("|"):
        data_end += 1

    timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    version_by_name = dict(names)

    rows: list[tuple[str, str]] = []
    for i in range(data_start, data_end):
        line = lines[i].rstrip("\n")
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        m = re.search(r"\[`(.+?)`\]", cells[0])
        formula_name = m.group(1) if m else None
        if formula_name in version_by_name:
            cells[1] = version_by_name[formula_name]
            cells[2] = timestamp
            line = "| " + " | ".join(cells) + " |"
        ts = cells[2]
        rows.append((ts, line))

    rows.sort(key=lambda r: r[0], reverse=True)
    lines[data_start:data_end] = [r[1] + "\n" for r in rows]
    readme.write_text("".join(lines))


def main() -> int:
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    ap.add_argument("--tap", default="hunger/tap")
    ap.add_argument(
        "--no-verify", action="store_true", help="skip style/audit/install/test"
    )
    ap.add_argument(
        "--bottle",
        action="store_true",
        help="build bottles for formulae marked `# bottle:` (implies verification)",
    )
    ap.add_argument(
        "--bottle-root-url",
        default=None,
        help="e.g. https://github.com/OWNER/homebrew-tap/releases/download",
    )
    ap.add_argument(
        "--force",
        action="append",
        default=[],
        metavar="NAME",
        help="verify (and bottle) NAME even if it is current; repeatable",
    )
    ap.add_argument("formulae", nargs="*")
    args = ap.parse_args()
    if args.bottle and not args.bottle_root_url:
        ap.error("--bottle needs --bottle-root-url")
    if args.bottle and args.no_verify:
        ap.error("--bottle and --no-verify are mutually exclusive")

    results = livecheck(args.tap, sorted(set(args.formulae) | set(args.force)))
    print("livecheck response:")
    print(json.dumps(results, indent=2))
    updated: list[tuple[str, str, str]] = []
    failed: list[tuple[str, str]] = []
    releases: list[dict] = []

    for r in results:
        name = r["formula"]
        if "error" in r:
            print(f"[decision] {name}: input error={r['error']!r} -> FAIL (livecheck)")
            failed.append((name, f"livecheck: {r['error']}"))
            continue
        path = FORMULA_DIR / f"{name}.rb"
        original = path.read_text()
        mode, mode_arg = detect_mode(original)
        print(f"[decision] {name}: input version={r.get('version')!r} mode={mode!r}")
        new_commit: str | None = None
        try:
            if mode == "git-commit":
                if not mode_arg:
                    raise RuntimeError("'# bump: git-commit' needs a commits API URL")
                # Take version and commit from one API response so they always agree.
                new_commit, new = branch_head(mode_arg)
                old = current_version(original) or r["version"]["current"]
            else:
                v = r["version"]
                old, new = v["current"], v["latest"]
                if not v.get("outdated"):
                    new = old
        except Exception as exc:  # noqa: BLE001
            failed.append((name, f"lookup: {exc}"))
            print(
                f"[decision] {name}: lookup failed ({exc!r}) -> FAIL", file=sys.stderr
            )
            print(f"{name}: FAILED lookup: {exc}", file=sys.stderr)
            continue
        forced = name in args.force
        if new == old and not forced:
            print(
                f"[decision] {name}: old={old!r} new={new!r} outdated={r['version'].get('outdated')!r}"
                f" forced={forced} -> SKIP (current)"
            )
            continue
        wants_bottle = args.bottle and BOTTLE_MARK_RE.search(original) is not None
        if new == old:
            print(
                f"[decision] {name}: old={old!r} new={new!r} forced={forced}"
                f" -> RE-VERIFY (re-bottle={wants_bottle})"
            )
        else:
            print(
                f"[decision] {name}: old={old!r} new={new!r} mode={mode!r}"
                f" new_commit={new_commit!r} -> BUMP (re-bottle={wants_bottle})"
            )
        try:
            if new != old:
                print(f"[update] {name}: rewriting formula file")
                path.write_text(rewrite(path, old, new, mode, new_commit))
            if not args.no_verify:
                print(
                    f"[verify] {name}: brew style/audit/install/test (build_bottle={wants_bottle})"
                )
                verify(args.tap, name, build_bottle=wants_bottle)
            else:
                print(f"[verify] {name}: skipped (--no-verify)")
            if wants_bottle:
                print(
                    f"[bottle] {name}: building bottle (root_url={args.bottle_root_url!r})"
                )
                releases.append(bottle(args.tap, name, args.bottle_root_url))
        except Exception as exc:  # noqa: BLE001 - report and keep going
            path.write_text(original)
            failed.append((name, f"{old} -> {new}: {exc}"))
            print(
                f"[decision] {name}: step failed ({exc!r}) -> REVERT + FAIL",
                file=sys.stderr,
            )
            print(f"{name}: FAILED, reverted: {exc}", file=sys.stderr)
            continue
        updated.append(
            (
                name,
                old,
                new
                if new != old
                else f"{new} (rebottled)"
                if wants_bottle
                else f"{new} (re-verified)",
            )
        )

    if updated:
        update_readme_table([(name, new) for name, old, new in updated])

    if releases:
        BOTTLE_DIR.mkdir(exist_ok=True)
        (BOTTLE_DIR / "releases.json").write_text(json.dumps(releases, indent=2) + "\n")

    summary = []
    if updated:
        summary.append(
            "## Updated\n" + "\n".join(f"- {n}: {o} -> {w}" for n, o, w in updated)
        )
    if failed:
        summary.append(
            "## Failed (left unchanged)\n" + "\n".join(f"- {n}: {e}" for n, e in failed)
        )
    if not updated and not failed:
        summary.append("All formulae are current.")
    text = "\n\n".join(summary)
    print("\n" + text)
    if step_summary := os.environ.get("GITHUB_STEP_SUMMARY"):
        with Path(step_summary).open("a") as f:
            f.write(text + "\n")
    if gh_out := os.environ.get("GITHUB_OUTPUT"):
        with Path(gh_out).open("a") as f:
            f.write(
                "updated=" + " ".join(f"{n} {o}->{w}" for n, o, w in updated) + "\n"
            )
    return 2 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
