#!/usr/bin/env python3
"""Rank repository files for focused defensive security scan passes."""

from __future__ import annotations

import argparse
import os
import re
from dataclasses import dataclass, field
from pathlib import Path


SKIP_DIRS = {
    ".git",
    ".hg",
    ".svn",
    ".next",
    ".nuxt",
    ".turbo",
    ".venv",
    "venv",
    "env",
    "node_modules",
    "dist",
    "build",
    "coverage",
    "target",
    "vendor",
    "__pycache__",
}

TEXT_EXTS = {
    ".c",
    ".cc",
    ".cpp",
    ".cs",
    ".go",
    ".h",
    ".hpp",
    ".java",
    ".js",
    ".jsx",
    ".kt",
    ".mjs",
    ".php",
    ".py",
    ".rb",
    ".rs",
    ".scala",
    ".sh",
    ".sql",
    ".swift",
    ".ts",
    ".tsx",
    ".yaml",
    ".yml",
    ".toml",
    ".json",
    ".xml",
    ".proto",
}

EXT_WEIGHTS = {
    ".c": (25, "native memory-unsafe language"),
    ".cc": (25, "native memory-unsafe language"),
    ".cpp": (25, "native memory-unsafe language"),
    ".h": (18, "native header"),
    ".hpp": (18, "native header"),
    ".rs": (12, "systems language"),
    ".go": (12, "backend/service code"),
    ".java": (10, "backend/service code"),
    ".kt": (10, "backend/service code"),
    ".cs": (10, "backend/service code"),
    ".py": (10, "backend/service code"),
    ".rb": (10, "backend/service code"),
    ".php": (10, "web/backend code"),
    ".js": (8, "application code"),
    ".jsx": (8, "application code"),
    ".ts": (8, "application code"),
    ".tsx": (8, "application code"),
    ".sql": (16, "database logic"),
    ".sh": (14, "shell automation"),
    ".yaml": (8, "configuration"),
    ".yml": (8, "configuration"),
    ".toml": (8, "configuration"),
}

PATH_PATTERNS = [
    (re.compile(r"(^|/)(auth|oauth|sso|session|jwt|token|permission|rbac|acl)s?(/|$)", re.I), 25, "authz/authn path"),
    (re.compile(r"(^|/)(admin|internal|privileged|root)(/|$)", re.I), 18, "privileged path"),
    (re.compile(r"(^|/)(api|route|routes|controller|handler|rpc|graphql|webhook)s?(/|$)", re.I), 18, "external entry point path"),
    (re.compile(r"(^|/)(upload|download|file|files|storage|blob)s?(/|$)", re.I), 18, "file handling path"),
    (re.compile(r"(^|/)(parser|parse|codec|decode|deserialize|unmarshal|proto)s?(/|$)", re.I), 18, "parser/deserializer path"),
    (re.compile(r"(^|/)(crypto|encrypt|decrypt|sign|verify|password|secret|key)s?(/|$)", re.I), 16, "crypto/secret path"),
    (re.compile(r"(^|/)(billing|payment|invoice|checkout|tenant|workspace|organization|org)s?(/|$)", re.I), 14, "business trust boundary"),
    (re.compile(r"(^|/)(Dockerfile|docker-compose|compose|Makefile|Jenkinsfile|\.github/workflows)(/|$)", re.I), 12, "build/CI surface"),
]

CONTENT_PATTERNS = [
    (re.compile(r"\b(eval|exec|Function|setTimeout|setInterval)\s*\(", re.I), 18, "dynamic code execution"),
    (re.compile(r"\b(child_process|subprocess|ProcessBuilder|Runtime\.getRuntime|system|popen|execve|spawn)\b"), 20, "process execution"),
    (re.compile(r"\bSELECT\b.+(\+|%|\bf-?['\"]|\$\{)", re.I | re.S), 16, "possible dynamic SQL"),
    (re.compile(r"\b(fetch|axios|requests|http\.Get|curl|urllib|net/http)\b", re.I), 10, "outbound network call"),
    (re.compile(r"\b(open|readFile|writeFile|createReadStream|send_file|FileInputStream|Path\.of)\b", re.I), 10, "filesystem access"),
    (re.compile(r"\bdeserialize|pickle|yaml\.load|ObjectInputStream|unmarshal|fromJson|JSON\.parse\b", re.I), 16, "deserialization/parsing"),
    (re.compile(r"\bunsafe\b|memcpy|strcpy|strncpy|sprintf|malloc|free|\*mut|\*const", re.I), 20, "memory/unsafe primitive"),
    (re.compile(r"\bTODO\b|\bFIXME\b|\bSECURITY\b|\bXXX\b", re.I), 6, "security-relevant comment marker"),
]


@dataclass
class RankedFile:
    path: Path
    score: int = 0
    reasons: list[str] = field(default_factory=list)

    @property
    def rank(self) -> int:
        if self.score >= 70:
            return 5
        if self.score >= 45:
            return 4
        if self.score >= 25:
            return 3
        if self.score >= 10:
            return 2
        return 1


def is_probably_text(path: Path) -> bool:
    return path.suffix.lower() in TEXT_EXTS or path.name in {"Dockerfile", "Makefile", "Jenkinsfile"}


def iter_files(root: Path, max_bytes: int):
    for current_root, dirs, files in os.walk(root):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS and not d.startswith(".cache")]
        for filename in files:
            path = Path(current_root) / filename
            if not is_probably_text(path):
                continue
            try:
                if path.stat().st_size > max_bytes:
                    continue
            except OSError:
                continue
            yield path


def add_reason(item: RankedFile, points: int, reason: str) -> None:
    item.score += points
    if reason not in item.reasons:
        item.reasons.append(reason)


def rank_file(path: Path, root: Path, max_bytes: int) -> RankedFile:
    rel = path.relative_to(root)
    item = RankedFile(rel)

    ext = path.suffix.lower()
    if ext in EXT_WEIGHTS:
        points, reason = EXT_WEIGHTS[ext]
        add_reason(item, points, reason)

    rel_text = rel.as_posix()
    for pattern, points, reason in PATH_PATTERNS:
        if pattern.search(rel_text):
            add_reason(item, points, reason)

    try:
        text = path.read_text(encoding="utf-8", errors="ignore")[:max_bytes]
    except OSError:
        return item

    line_count = text.count("\n") + 1
    if line_count > 600:
        add_reason(item, 8, "large file")
    if line_count > 1500:
        add_reason(item, 8, "very large file")

    for pattern, points, reason in CONTENT_PATTERNS:
        if pattern.search(text):
            add_reason(item, points, reason)

    return item


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("repo", nargs="?", default=".", help="Repository root to rank")
    parser.add_argument("--top", type=int, default=80, help="Number of files to print")
    parser.add_argument("--max-bytes", type=int, default=250_000, help="Maximum bytes read per file")
    parser.add_argument("--format", choices=["markdown", "tsv"], default="markdown")
    args = parser.parse_args()

    root = Path(args.repo).resolve()
    if not root.exists() or not root.is_dir():
        parser.error(f"repo is not a directory: {root}")

    ranked = [rank_file(path, root, args.max_bytes) for path in iter_files(root, args.max_bytes)]
    ranked.sort(key=lambda item: (-item.rank, -item.score, item.path.as_posix()))

    if args.format == "tsv":
        print("rank\tscore\tpath\treasons")
        for item in ranked[: args.top]:
            print(f"{item.rank}\t{item.score}\t{item.path}\t{'; '.join(item.reasons)}")
    else:
        print("| rank | score | path | reasons |")
        print("| --- | ---: | --- | --- |")
        for item in ranked[: args.top]:
            reasons = "; ".join(item.reasons).replace("|", "\\|")
            print(f"| {item.rank} | {item.score} | `{item.path}` | {reasons} |")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
