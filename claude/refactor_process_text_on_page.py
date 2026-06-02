#!/usr/bin/env python3
"""Refactor process_text_on_page(index, pagetitle, text) -> process_text_on_page(p).

Usage:
    python refactor_process_text_on_page.py <directory-or-file> [<directory-or-file> ...]

For each .py file found, transforms process_text_on_page to use the single-argument
ProcessPageParams calling convention.  Handles these signature variants:

  (index, pagetitle, text)   -- standard (430 files)
  (index, pagename, text)    -- pagename variant (33 files)
  (index, pagetitle, pagetext) -- pagetext variant (20 files)

In all cases the function becomes process_text_on_page(p) and:
  - Removes standard inner closures: pagemsg, errandpagemsg, expand_text
  - Replaces pagemsg -> p.msg, errandpagemsg -> p.errandmsg, expand_text -> p.expand_text
  - Replaces pagetitle/pagename -> p.title, initial reads of text/pagetext -> p.text
  - Cleans up unused msg/errandmsg imports (only on import lines, not code)

Non-standard signatures (extra params, different arg order, etc.) are NOT touched.
After running, check the output of check_process_text_on_page.py and handle
remaining issues manually (see REFACTOR_PLAN.md for guidance).
"""

import re
import sys
from pathlib import Path


# Supported signature variants: (title_param, text_param)
SIGNATURE_VARIANTS = [
    # (regex to match def line, title_param_name, text_param_name)
    (r'^def process_text_on_page\(index, pagetitle, text\):', 'pagetitle', 'text'),
    (r'^def process_text_on_page\(index, pagename, text\):', 'pagename', 'text'),
    (r'^def process_text_on_page\(index, pagetitle, pagetext\):', 'pagetitle', 'pagetext'),
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


def find_func_bounds(lines):
    """Return (func_start, func_end, title_param, text_param) or (None, None, None, None)."""
    for i, line in enumerate(lines):
        for pattern, title_param, text_param in SIGNATURE_VARIANTS:
            if re.match(pattern, line):
                func_start = i
                return func_start, find_func_end(lines, func_start), title_param, text_param
    return None, None, None, None


def remove_standard_2line_def(body_lines, def_signature, body_pattern):
    """Remove a 2-line inner function def if its body matches body_pattern.

    Returns (new_lines, was_found).
    def_signature: exact stripped text of the def line, e.g. 'def pagemsg(txt):'
    body_pattern: regex matching the stripped body line
    """
    result = []
    found = False
    i = 0
    while i < len(body_lines):
        line = body_lines[i]
        stripped = line.strip()
        if stripped == def_signature and i + 1 < len(body_lines):
            next_stripped = body_lines[i + 1].strip()
            if re.match(body_pattern, next_stripped):
                found = True
                i += 2
                # Skip a following blank line if present
                if i < len(body_lines) and not body_lines[i].strip():
                    i += 1
                continue
        result.append(line)
        i += 1
    return result, found


def has_text_assignment(body_lines):
    """Return True if `text` appears as an LHS assignment target in the body."""
    for line in body_lines:
        stripped = line.strip()
        # Match: text = ... or text, something = ...
        if re.match(r'text\s*=\s*', stripped) or re.match(r'text\s*,', stripped):
            return True
    return False


def transform_file(fpath, verbose=False):
    """Transform a single file. Returns True if the file was modified."""
    content = fpath.read_text()
    lines = content.split('\n')

    func_start, func_end, title_param, text_param = find_func_bounds(lines)
    if func_start is None:
        return False

    # ── Step 1: Change the signature ──────────────────────────────────────
    lines[func_start] = 'def process_text_on_page(p):'

    body_lines = lines[func_start + 1:func_end]

    # ── Step 2: Remove standard inner function defs ───────────────────────
    # pagemsg body references either pagetitle or pagename depending on variant
    body_lines, _ = remove_standard_2line_def(
        body_lines,
        'def pagemsg(txt):',
        r'msg\("Page %s %s: %s" % \(index, ' + re.escape(title_param) + r', txt\)\)'
    )
    body_lines, had_errandpagemsg = remove_standard_2line_def(
        body_lines,
        'def errandpagemsg(txt):',
        r'errandmsg\("Page %s %s: %s" % \(index, ' + re.escape(title_param) + r', txt\)\)'
    )
    body_lines, had_expand_text = remove_standard_2line_def(
        body_lines,
        'def expand_text(tempcall):',
        r'return blib\.expand_text\(tempcall, ' + re.escape(title_param) + r', pagemsg, args\.verbose\)'
    )

    # ── Step 3: Determine whether the text param is locally reassigned ────
    text_is_reassigned = has_text_assignment(body_lines) if text_param == 'text' else False
    # For pagetext, treat as never reassigned (it's always just read)

    # ── Step 4: Replacements within the function body ────────────────────
    tp = re.escape(text_param)   # text or pagetext
    titlep = re.escape(title_param)  # pagetitle or pagename

    new_body = []
    for line in body_lines:
        # pagemsg (calls AND pass-as-argument) -> p.msg
        line = re.sub(r'\bpagemsg\b', 'p.msg', line)
        # errandpagemsg (calls AND pass-as-argument) -> p.errandmsg
        line = re.sub(r'\berrandpagemsg\b', 'p.errandmsg', line)
        # expand_text (only if it was a local def in this function) -> p.expand_text
        if had_expand_text:
            line = re.sub(r'\bexpand_text\b', 'p.expand_text', line)
        # pagetitle/pagename -> p.title
        line = re.sub(r'\b' + titlep + r'\b', 'p.title', line)

        # text/pagetext -> p.text: replace specific call patterns that read the parameter.
        # We avoid replacing wholesale because:
        #   (a) it may appear in string literals
        #   (b) nested inner functions may have their own `text` parameter
        #   (c) after a `text = ...` assignment it's a local variable
        line = re.sub(r'\bblib\.parse_text\(' + tp + r'\b', 'blib.parse_text(p.text', line)
        line = re.sub(r'\bblib\.find_modifiable_lang_section\(' + tp + r',',
                      'blib.find_modifiable_lang_section(p.text,', line)
        line = re.sub(r'\blalib\.find_heads_and_defns\(' + tp + r',',
                      'lalib.find_heads_and_defns(p.text,', line)
        line = re.sub(r'\bblib\.split_text_into_subsections\(' + tp + r',',
                      'blib.split_text_into_subsections(p.text,', line)
        line = re.sub(r'\borig' + tp + r'\s*=\s*' + tp + r'\b', f'orig{text_param} = p.text', line)
        line = re.sub(r'\bnot in ' + tp + r'\b', 'not in p.text', line)
        line = re.sub(r'\bin ' + tp + r'\b', 'in p.text', line)
        # return text/pagetext (only if it was never locally reassigned)
        if not text_is_reassigned:
            line = re.sub(r'\breturn ' + tp + r'\b', 'return p.text', line)

        new_body.append(line)

    lines[func_start + 1:func_end] = new_body

    # ── Step 5: Clean up unused imports (import lines only) ───────────────
    # IMPORTANT: only touch lines that are `from ... import ...` lines,
    # never code lines (which may contain p.msg, p.errandmsg as substrings).
    new_lines = []
    remaining_body_text = '\n'.join(new_body)

    # Determine whether msg / errandmsg are still used anywhere in the file
    # outside of imports.
    non_import_content = '\n'.join(
        line for line in lines
        if not re.match(r'\s*from\s+\S+\s+import\b', line)
    )

    # msg: remove from import only if no remaining bare msg() call
    msg_still_used = bool(re.search(r'(?<!\w)msg\s*\(', non_import_content))

    # errandmsg: remove from import only if no remaining bare errandmsg() call
    # (p.errandmsg does NOT count as a bare errandmsg call)
    errandmsg_still_used = bool(re.search(r'(?<![\w\.])errandmsg\s*\(', non_import_content))

    for line in lines:
        if re.match(r'\s*from\s+\S+\s+import\b', line):
            if not msg_still_used:
                # Remove ', msg' or 'msg, ' from the import
                line = re.sub(r',\s*\bmsg\b(?!\w)', '', line)
                line = re.sub(r'\bmsg\b(?!\w),\s*', '', line)
            if not errandmsg_still_used:
                line = re.sub(r',\s*\berrandmsg\b(?!\w)', '', line)
                line = re.sub(r'\berrandmsg\b(?!\w),\s*', '', line)
        new_lines.append(line)

    new_content = '\n'.join(new_lines)
    if new_content != content:
        fpath.write_text(new_content)
        if verbose:
            print(f"  Transformed: {fpath}")
        return True
    return False


def process_path(path, verbose=False):
    path = Path(path)
    changed = []
    skipped = []
    if path.is_file():
        files = [path]
    elif path.is_dir():
        files = sorted(path.rglob('*.py'))
    else:
        print(f"ERROR: {path} is not a file or directory", file=sys.stderr)
        return

    for fpath in files:
        if fpath.name == '__init__.py':
            continue
        try:
            if transform_file(fpath, verbose=verbose):
                changed.append(fpath)
            else:
                skipped.append(fpath)
        except Exception as e:
            print(f"ERROR processing {fpath}: {e}", file=sys.stderr)

    print(f"\nTransformed {len(changed)} file(s), skipped {len(skipped)} (no match).")
    if verbose and changed:
        print("Changed files:")
        for f in changed:
            print(f"  {f}")


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    verbose = '--verbose' in sys.argv or '-v' in sys.argv
    paths = [a for a in sys.argv[1:] if not a.startswith('-')]
    for path in paths:
        print(f"\nProcessing: {path}")
        process_path(path, verbose=verbose)
