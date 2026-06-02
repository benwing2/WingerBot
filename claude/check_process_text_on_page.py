#!/usr/bin/env python3
"""Check for remaining issues after refactoring process_text_on_page.

Usage:
    python check_process_text_on_page.py <directory-or-file> [...]

Reports any remaining issues that may need manual attention:
  - Leftover inner pagemsg/errandpagemsg/expand_text definitions
  - Bare `text`, `index`, or `pagetitle` references that weren't auto-converted
  - Corrupted `p.p.` patterns (import-cleanup bug)
  - Manual calls to process_text_on_page with old 3-arg signature
  - Any `pagemsg` or `errandpagemsg` still present in a refactored function
"""

import re
import sys
from pathlib import Path


# Variant signatures that the refactor script does NOT handle automatically
UNHANDLED_SIGNATURES = [
    r'^def process_text_on_page\(index, pagetitle, text, ',   # extra params
    r'^def process_text_on_page\(index, pagetitle, curtext,',
    r'^def process_text_on_page\(index, pagetitle, pagetext, ',
    r'^def process_text_on_page\(index, text, pagetitle\)',   # swapped order
    r'^def process_text_on_page\(index, pagename, text, ',   # pagename + extra
]


def find_func_end(lines, func_start):
    """Find the end of a function body, correctly skipping multiline string literals.

    A naive scan for the first non-indented line fails when the function body
    contains a triple-quoted string whose content starts at column 0 (e.g.
    ``cattext = \"""\\ngroups[...``).  This scanner tracks triple-quote state so
    those content lines are ignored.
    """
    in_triple = None  # None, '"""', or "'''"
    for j in range(func_start + 1, len(lines)):
        line = lines[j]
        was_in_triple = in_triple is not None
        # Update triple-quote state by scanning the line character-by-character.
        i = 0
        while i < len(line):
            if in_triple:
                if line[i:i+3] == in_triple:
                    in_triple = None
                    i += 3
                else:
                    i += 1
            else:
                if line[i] == '#':
                    break  # rest of line is a comment
                if line[i:i+3] in ('"""', "'''"):
                    q = line[i:i+3]
                    close_idx = line.find(q, i + 3)
                    if close_idx != -1:
                        i = close_idx + 3  # triple-quoted string closed on same line
                    else:
                        in_triple = q  # entering a multiline string
                        break
                else:
                    i += 1
        # Only treat this line as the function end if it was NOT inside a
        # multiline string at the start of the line.
        if not was_in_triple and line and not line[0].isspace():
            return j
    return len(lines)


def find_func_bounds_new(lines):
    """Return bounds of the already-refactored process_text_on_page(p) function."""
    func_start = None
    for i, line in enumerate(lines):
        if re.match(r'^def process_text_on_page\(p\):', line):
            func_start = i
            break
    if func_start is None:
        return None, None
    return func_start, find_func_end(lines, func_start)


def check_file(fpath):
    issues = []
    content = fpath.read_text()
    lines = content.split('\n')

    # ── Check 0: unhandled non-standard signature ─────────────────────────
    for i, line in enumerate(lines):
        for pattern in UNHANDLED_SIGNATURES:
            if re.match(pattern, line):
                issues.append((i + 1, 'UNHANDLED-SIGNATURE', line.strip()))

    # ── Check 1: old-style calls to process_text_on_page ─────────────────
    for i, line in enumerate(lines):
        # Only flag actual calls (not def lines, not commented lines)
        stripped = line.strip()
        if (re.search(r'\bprocess_text_on_page\s*\(\s*index\s*,', line)
                and not stripped.startswith('def ')
                and not stripped.startswith('#')):
            issues.append((i + 1, 'OLD-CALL', stripped))

    func_start, func_end = find_func_bounds_new(lines)
    if func_start is None:
        return issues  # file not yet refactored or already clean

    body_lines = lines[func_start + 1:func_end]

    # Track nesting depth of inner function defs to detect nested scopes
    # (We flag issues at all nesting levels for now.)
    for j, line in enumerate(body_lines):
        stripped = line.strip()
        if stripped.startswith('#'):
            continue
        lineno = func_start + 1 + j + 1  # 1-based

        # ── Leftover inner defs ──────────────────────────────────────────
        if re.match(r'def pagemsg\(txt\):', stripped):
            issues.append((lineno, 'LEFTOVER-PAGEMSG-DEF', stripped))
        if re.match(r'def errandpagemsg\(txt\):', stripped):
            issues.append((lineno, 'LEFTOVER-ERRANDPAGEMSG-DEF', stripped))
        if re.match(r'def expand_text\(tempcall\):', stripped):
            issues.append((lineno, 'LEFTOVER-EXPAND_TEXT-DEF', stripped))

        # ── Corrupted p.p. ───────────────────────────────────────────────
        if 'p.p.' in stripped:
            issues.append((lineno, 'CORRUPTED-P.P.', stripped[:80]))

        # ── Bare errandmsg() call (not p.errandmsg) ─────────────────────
        if re.search(r'(?<![\w\.])errandmsg\s*\(', stripped):
            issues.append((lineno, 'BARE-ERRANDMSG-CALL', stripped[:80]))

        # ── Remaining pagemsg / errandpagemsg references ─────────────────
        if re.search(r'\bpagemsg\b', stripped) and 'p.msg' not in stripped:
            issues.append((lineno, 'REMAINING-PAGEMSG', stripped[:80]))
        if re.search(r'\berrandpagemsg\b', stripped) and 'p.errandmsg' not in stripped:
            issues.append((lineno, 'REMAINING-ERRANDPAGEMSG', stripped[:80]))

        # ── Bare `text` that may not have been converted ─────────────────
        # Only flag cases that look like standalone variable use
        # (not inside string literals, not as inner function params)
        if re.search(r'\btext\b', stripped):
            # Skip string literals and def lines
            no_strings = re.sub(r'"[^"]*"|\'[^\']*\'', '""', stripped)
            if re.search(r'\btext\b', no_strings) and not re.match(r'def \w+\(.*\btext\b', stripped):
                # Only flag if it looks like the text variable (not e.g. newtext, pagetext)
                if re.search(r'(?<![a-zA-Z_])text(?![a-zA-Z_0-9])', no_strings):
                    # Filter out known-safe patterns we already handled
                    if not re.search(
                        r'p\.text|blib\.parse_text\(p\.|find_modifiable_lang_section\(p\.|'
                        r'find_heads_and_defns\(p\.|origtext\s*=\s*p\.|split_text_into_subsections\(p\.',
                        stripped
                    ):
                        issues.append((lineno, 'POSSIBLE-BARE-TEXT', stripped[:80]))

        # ── Bare `index` that may be p.index ─────────────────────────────
        if re.search(r'\bindex\b', stripped):
            no_strings = re.sub(r'"[^"]*"|\'[^\']*\'', '""', stripped)
            if re.search(r'\bindex\b', no_strings):
                # Skip common false-positive patterns
                if not re.search(r'p\.index|for\s+\w*index\w*\s+in\b|def\s+\w+\s*\(.*\bindex\b', stripped):
                    issues.append((lineno, 'POSSIBLE-BARE-INDEX', stripped[:80]))

    return issues


def process_path(path, show_clean=False):
    path = Path(path)
    if path.is_file():
        files = [path]
    elif path.is_dir():
        files = sorted(path.rglob('*.py'))
    else:
        print(f"ERROR: {path} is not a file or directory", file=sys.stderr)
        return

    total_issues = 0
    files_with_issues = 0
    for fpath in files:
        if fpath.name == '__init__.py':
            continue
        try:
            issues = check_file(fpath)
            if issues:
                files_with_issues += 1
                total_issues += len(issues)
                print(f"\n{'='*60}")
                print(f"FILE: {fpath}")
                for lineno, kind, text in issues:
                    print(f"  line {lineno:4d}  [{kind}]  {text}")
            elif show_clean:
                print(f"OK: {fpath}")
        except Exception as e:
            print(f"ERROR processing {fpath}: {e}", file=sys.stderr)

    print(f"\n{'='*60}")
    print(f"Total: {total_issues} issue(s) in {files_with_issues} file(s).")


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    show_clean = '--show-clean' in sys.argv
    paths = [a for a in sys.argv[1:] if not a.startswith('-')]
    for path in paths:
        process_path(path, show_clean=show_clean)
