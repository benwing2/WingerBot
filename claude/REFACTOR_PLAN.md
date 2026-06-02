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
| `chinese/` | 12 | ✅ DONE | 12 files auto-refactored; manual fixes in 2 files (nan_fix_min_qualifiers: 3 bare index→p.index; zh_remove_redundant_translations: 1 bare text→p.text + 2 bare index→p.index in inner closures) |
| `sgconlaw/` | 25 | ✅ DONE | 25 files auto-refactored; manual fixes in 13 files (bare `text` → `p.text` at start of process_text_on_page; inner closure `text` from m.groups() left alone) |
| `german/` | 10 | ✅ DONE | 10 files auto-refactored; manual fixes in 3 files (de_clean_adj_forms: bare text→p.text; de_convert_adj, de_convert_noun: bare index→p.index in inner closure) |
| `english/` | 9 | ✅ DONE | 9 files auto-refactored; manual fixes in 2 files (en_add_langcode_to_request_templates: bare text→p.text; en_convert_head_verb_to_en_verb: 4-arg signature → 1-arg, drop wrapper do_process_text_on_page) |
| `indic/` | 9 | ✅ DONE | 9 files auto-refactored; no manual fixes needed (bare `text` in templatize file is local variable, correct) |
| `old_english/` | 7 | ✅ DONE | 7 files auto-refactored; manual fixes in 2 files (ang_find_no_infl: 4-arg signature → 2-arg (p, pos) + wrapper; ang_fix_pronun: bare index→p.index in 3 process_section calls) |
| `japanese/` | 6 | ✅ DONE | 6 files auto-refactored; manual fix in 1 file (ja_fix_usex_in_quotes: bare text→p.text) |
| `hungarian/` | 5 | ✅ DONE | 5 files auto-refactored; no manual fixes needed |
| `icelandic/` | 3 | ✅ DONE | 3 files auto-refactored; no manual fixes needed |
| `bantu/` | 3 | ✅ DONE | 3 files auto-refactored; no manual fixes needed |
| `vietnamese/` | 2 | ✅ DONE | 2 files auto-refactored; no manual fixes needed |
| `tagalog/` | 2 | ✅ DONE | 2 files auto-refactored; no manual fixes needed |
| `sanskrit/` | 2 | ✅ DONE | 2 files auto-refactored; manual fix in 1 (sa_clean_cat_templates: added text=p.text) |
| `hebrew/` | 2 | ✅ DONE | 2 files auto-refactored; manual fix in 1 (he_clean_templates: text=p.text, in text, errandmsg->p.errandmsg) |
| `yiddish/` | 1 | ✅ DONE | 1 file auto-refactored; manual fix (first text use -> p.text) |
| `veps/` | 1 | ✅ DONE | 1 file auto-refactored; no manual fixes needed |
| `turkish/` | 1 | ✅ DONE | 1 file auto-refactored; no manual fixes needed |
| `translingual/` | 1 | ✅ DONE | 1 file auto-refactored; manual fix (text -> p.text in split_text_into_sections call) |
| `sicilian/` | 1 | ✅ DONE | 1 file auto-refactored; no manual fixes needed |
| `sakizaya/` | 1 | ✅ DONE | 1 file auto-refactored; no manual fixes needed |
| `proto_indo_european/` | 1 | ✅ DONE | 1 file auto-refactored; no manual fixes needed |
| `proto_germanic/` | 1 | ✅ DONE | 1 file auto-refactored; no manual fixes needed |
| `persian/` | 1 | ✅ DONE | 1 file auto-refactored; manual fixes (bare index->p.index, text->p.text in inner scope; OLD-CALL wrapped with ProcessPageParams) |
| `mongolian/` | 1 | ✅ DONE | 1 file auto-refactored; no manual fixes needed |
| `middle_english/` | 1 | ✅ DONE | 1 file auto-refactored; no manual fixes needed |
| `luxembourgish/` | 1 | ✅ DONE | 1 file auto-refactored; no manual fixes needed |
| `lojban/` | 1 | ✅ DONE | 1 file auto-refactored; no manual fixes needed |
| `kurdish/` | 4 | ✅ DONE | 4 files auto-refactored; manual fixes in 4 (text=p.text or first use->p.text; ku_find_correct_usages: index->p.index, text->p.text) |
| `greek/` | 2 | ✅ DONE | 2 files auto-refactored; manual fix in el_convert_verb_categories (transformer cut short by multiline string literal; second branch: pagemsg->p.msg, pagename->p.title, text->p.text) |
| `georgian/` | 1 | ✅ DONE | 1 file auto-refactored (skipped by transformer due to 4-arg signature); manual full refactor (4-arg->2-arg, pagemsg inner def removed, do_process_text_on_page wrapper updated) |
| `dutch/` | 1 | ✅ DONE | 1 file auto-refactored; no manual fixes needed |
| `armenian/` | 1 | ✅ DONE | no Python files with process_text_on_page |
| `aromanian/` | 1 | ✅ DONE | 1 file auto-refactored; no manual fixes needed |
| Top-level `*.py` [a-d] | ~51 | ✅ DONE | 51 files auto-refactored; manual fixes: add_bg_be_hi_infl/add_rfinfl/add_topic_cats (extra-param sigs→(p,...)); add_dot_to_etydate/place/add_lang_to_accent_qualifier/add_reconstructed/analyze_accent_qualifier/clean_pos_templates/clean_form_of_data_module/convert_alt_forms_data_module/convert_topic_cat_data_module (text=p.text); blib.split_text_into_sections(text→p.text) in 6 files; clean_bad_inflection_tags/compute_form_of_freq (OLD-CALL); convert_translation_to_multi (invalid def p.msg removed; text=p.text); clean_label_module/convert_letter_headwords/copy_femeq_to_masc (bare index→p.index); clean_etym_text/add_bor_to_desc (first text→p.text); clean_lang_form_of (text=p.text before loop) |
| Top-level `*.py` [e-o] | ~56 | ✅ DONE | 40 files auto-refactored; manual fixes: find_col_comma_no_space/find_langs/find_mismatched_comments (text=p.text); find_manual_ipa (index→p.index; local text var left alone); find_misformatted_sections (remove 2 invalid `def p.msg` inner defs, fix bare msg call with index→p.msg call); find_page_existing_translations/find_template_refs (index→p.index); fix_bor_withtext (p.text as re.sub input arg); fix_cite (newtext=p.text); fix_was_wotd (re.sub input arg p.text); list_page_status/merge_rfv_by_month/move_numbered_params_to_named/move_cats (text=p.text); fix_links (p.text in do_section and split_text_into_sections calls); move_auto_cat_lect_to_label_module (index→p.index, text→p.text in helper call); move_etydate_refs (add text=p.text near top); find_regex (4-arg→1-arg p, prev_comment→p.prev_comment, OLD-CALL wrapped with ProcessPageParams); find_template/fix_broken_wikisource_links (do_process_text_on_page wrapper: 3-arg→1-arg p, update inner call with p.index/p.title/p.text) |
| Top-level `*.py` [p-z] | ~88 | ⬜ TODO | Do last; many small independent files |

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
