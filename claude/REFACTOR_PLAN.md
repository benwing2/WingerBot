# Plan: Refactor process_text_on_page to ProcessPageParams convention

## What this refactor does

Changes every `process_text_on_page(index, pagetitle, text)` function to
`process_text_on_page(p)` where `p` is a `blib.ProcessPageParams` object, and:

| Old | New |
|-----|-----|
| `index` | `p.index` |
| `pagetitle` | `p.title` |
| `text` (initial read) | `p.text` |
| `pagemsg(...)` | `p.msg(...)` |
| `errandpagemsg(...)` | `p.errandmsg(...)` |
| `expand_text(...)` | `p.expand_text(...)` |

The inner closure definitions for `pagemsg`, `errandpagemsg`, and `expand_text`
(when they have the standard 2-line form) are removed entirely.

## Scripts

All scripts live in `~/Documents/WingerBot/claude/`.

| Script | Purpose |
|--------|---------|
| `refactor_process_text_on_page.py` | Auto-transforms files |
| `check_process_text_on_page.py` | Reports remaining issues after transformation |

## Status

| Directory | Files | Status | Notes |
|-----------|-------|--------|-------|
| `latin/` | 48 | ✅ DONE | All files refactored manually + scripted |
| `swedish/` | 4 | ✅ DONE | All files refactored manually |
| `slavic/russian/` | 95 | ✅ DONE | 95 files auto-refactored; manual fixes in 18 files |
| `slavic/` (non-russian) | 52 | ✅ DONE | 52 files auto-refactored; manual fixes in 10 files |
| `romance/` | 69 | ✅ DONE | 69 files auto-refactored; manual fixes in 9 files |
| `arabic/` | 17 | ✅ DONE | 17 files auto-refactored; manual fixes in 5 files (ar_canon, ar_convert_headwords_to_default/new_format, ar_count_verb_form_of, ar_fix_bad_23mp); ar_create_inflections skipped (needs manual cleanup) |
| `chinese/` | 12 | ⬜ TODO | |
| `sgconlaw/` | 11 | ⬜ TODO | |
| `german/` | 10 | ⬜ TODO | |
| `english/` | 9 | ⬜ TODO | |
| `indic/` | 8 | ⬜ TODO | |
| `old_english/` | 7 | ⬜ TODO | |
| `japanese/` | 6 | ⬜ TODO | |
| `hungarian/` | 5 | ⬜ TODO | |
| `icelandic/` | 3 | ⬜ TODO | |
| `bantu/` | 3 | ⬜ TODO | |
| `vietnamese/` | 2 | ⬜ TODO | |
| `tagalog/` | 2 | ⬜ TODO | |
| `sanskrit/` | 2 | ⬜ TODO | |
| `hebrew/` | 2 | ⬜ TODO | |
| `yiddish/` | 1 | ⬜ TODO | |
| `veps/` | 1 | ⬜ TODO | |
| `turkish/` | 1 | ⬜ TODO | |
| `translingual/` | 1 | ⬜ TODO | |
| `sicilian/` | 1 | ⬜ TODO | |
| `sakizaya/` | 1 | ⬜ TODO | |
| `proto_indo_european/` | 1 | ⬜ TODO | |
| `proto_germanic/` | 1 | ⬜ TODO | |
| `persian/` | 1 | ⬜ TODO | |
| `mongolian/` | 1 | ⬜ TODO | |
| `middle_english/` | 1 | ⬜ TODO | |
| `luxembourgish/` | 1 | ⬜ TODO | |
| `lojban/` | 1 | ⬜ TODO | |
| `kurdish/` | 1 | ⬜ TODO | |
| `greek/` | 1 | ⬜ TODO | |
| `georgian/` | 1 | ⬜ TODO | |
| `dutch/` | 1 | ⬜ TODO | |
| `armenian/` | 1 | ⬜ TODO | |
| `aromanian/` | 1 | ⬜ TODO | |
| Top-level `*.py` | ~70 | ⬜ TODO | Do last; many small independent files |

## Workflow for each directory

### 1. Run the transformer

```bash
cd ~/Documents/WingerBot
python claude/refactor_process_text_on_page.py src/wingerbot/<SUBDIR>/
```

### 2. Run the checker

```bash
python claude/check_process_text_on_page.py src/wingerbot/<SUBDIR>/
```

Review every reported issue. The issue types and how to handle them:

| Issue type | Meaning | Action |
|------------|---------|--------|
| `LEFTOVER-PAGEMSG-DEF` | Non-standard `pagemsg` inner def wasn't removed | Remove manually, adjust uses |
| `LEFTOVER-ERRANDPAGEMSG-DEF` | Non-standard `errandpagemsg` inner def | Same |
| `LEFTOVER-EXPAND_TEXT-DEF` | Non-standard `expand_text` inner def | Same |
| `CORRUPTED-P.P.` | Import cleanup damaged `p.errandmsg, p.expand_text` → `p.p.expand_text` | Replace `p.p.expand_text` with `p.errandmsg, p.expand_text` (or appropriate args) |
| `BARE-ERRANDMSG-CALL` | `errandmsg(...)` call still in function body | Shouldn't happen; investigate |
| `REMAINING-PAGEMSG` | `pagemsg` identifier still in body | Replace with `p.msg` |
| `REMAINING-ERRANDPAGEMSG` | `errandpagemsg` identifier still in body | Replace with `p.errandmsg` |
| `POSSIBLE-BARE-TEXT` | `text` may need to be `p.text` | Check context; fix if it's reading the page text |
| `POSSIBLE-BARE-INDEX` | `index` may need to be `p.index` | Check context; fix if it's the page index |
| `OLD-CALL` | `process_text_on_page(index, pagetitle, text)` call elsewhere in file | Wrap with `blib.ProcessPageParams(args, index, pagetitle, text, None)` |

### 3. Commit

```bash
git add src/wingerbot/<SUBDIR>/
git commit -m "Refactor process_text_on_page to ProcessPageParams convention in <SUBDIR>"
```

## Common patterns requiring manual fixes

### Non-standard errandpagemsg body

Some files define `errandpagemsg` with extra context (e.g. including a slot/form name):
```python
def errandpagemsg(txt):
    errandmsg("Page %s %s form %s %s: %s" % (index, pagetitle, slot, form, txt))
```
These are NOT removed by the script. You must:
1. Remove the `def errandpagemsg` block manually
2. Replace its usages with a custom lambda or inline the formatting

### `text` reassigned locally

When `process_text_on_page` rebuilds `text` from scratch (e.g. `text = modsec.rebuild(...)`),
the local variable stays as `text`. The script replaces the initial reads of the parameter
(`blib.parse_text(text)`, `blib.find_modifiable_lang_section(text, ...)`, etc.) with `p.text`,
and leaves subsequent uses of the local `text` variable alone.

Verify: make sure the first use of `text` is replaced with `p.text` and the return is
`return text, notes` (using the rebuilt local variable), not `return p.text, notes`.

### Nested inner functions with `text` or `index` parameter

If `process_text_on_page` contains an inner function like `def find_lemmas(text):`,
the script may wrongly replace `blib.parse_text(text)` inside that function with
`blib.parse_text(p.text)`. The checker will flag these; fix them by reverting back
to the original parameter name.

Similarly for `def do_edit_page(index, page):` — the `index` parameter of the inner
function and uses of `index` inside it should NOT become `p.index`.

### `blib.do_edit(index, ...)` at outer level

When `process_text_on_page` calls `blib.do_edit(index, ...)` directly (not via
an inner function), that `index` should become `p.index`. But if there's also an
inner `def handler(index, page):` whose `index` is the `blib.do_edit` callback
argument, the inner usages should stay as `index`.

### Manual calls to `process_text_on_page`

If another function in the same file calls `process_text_on_page(index, pagetitle, text)`,
wrap it:
```python
return process_text_on_page(blib.ProcessPageParams(args, index, pagetitle, text, None))
```
Make sure `args` is accessible in that scope (it's typically a module-level global).

### `expand_text` defined with a non-standard form

Some files define `expand_text` with a different argument name or body.
These are left in place. Convert manually:
- Remove the def
- Replace `expand_text(` with `p.expand_text(`

### Files that import `errandmsg` but don't use it directly

After the refactor, `errandmsg` may appear only as part of `p.errandmsg` (which the
import-cleanup correctly ignores). But a few pre-existing files imported `errandmsg`
without using it at all — these are harmless and can be cleaned up separately.

## Known edge cases encountered in `latin/`

1. **`la_add_pron.py`**: Has a second occurrence of `errandpagemsg`/`expand_text`
   definitions inside `process_text_on_page` (for the multiple-etymology branch), and
   a manual call to `process_text_on_page` inside `process_lemma`. Fixed by:
   - Script removes the standard defs automatically
   - Manual: changed `process_text_on_page(index, pagetitle, text)` →
     `process_text_on_page(blib.ProcessPageParams(args, index, pagetitle, text, None))`

2. **`la_fix_multi_pronun_sections.py`**: Inner `def find_lemmas(text):` had
   `blib.parse_text(p.text)` after auto-transform. Fixed manually by reverting to
   `blib.parse_text(text)`.

3. **`la_correct_noun_vs_pn.py`**: Loop variable `for index, (slot, form) in ...`
   reuses the name `index`. `p.index` is NOT referenced in the body (only the
   loop index is used). No manual fix needed.

4. **`la_correct_wrong_pos_form.py`**, **`la_fix_impers_pass_part.py`**,
   **`la_propagate_comp_sup_adj.py`**: Have inner `def handler(index, page):` or
   `def do_process(index, page):`. The `blib.do_edit(index, ...)` call at the
   outer level was changed to `p.index`; the inner function parameter was left alone.
