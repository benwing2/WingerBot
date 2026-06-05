#!/usr/bin/env python3

from wingerbot import blib
from wingerbot.blib import msg


# process_text_on_page() callback. `index` is the index of the page whose title is `pagetitle`. `curtext` is the
# actual current text of the page. `contents` is the desired text of the page (or of the specific language section if
# --lang-only or --subset-of-langs), and `origcontents` is the previous text of the page (or of the specific language
# section) from which `contents` was derived. We need `origcontents` so we can check to see if the page (or specific
# language section) was changed by someone else in the meantime; if so, we can't save.
def process_text_on_page(p, contents, prev_comment, origcontents):
    def normalize_text(text):
        if text is None:
            return text
        return blib.normalize_text_for_save(text).rstrip("\n")

    if normalize_text(contents) == normalize_text(origcontents):
        p.msg("Skipping contents because no change")
        return
    if args.verbose:
        p.msg("For [[%s]]:" % p.title)
        p.msg("------- begin text --------")
        # Strip final newline because msg() adds one.
        contents_minus_newline = contents
        if contents_minus_newline.endswith("\n"):
            contents_minus_newline = contents_minus_newline[-1]
        msg(contents_minus_newline)
        msg("------- end text --------")
    page_exists = p.text and origcontents is not None
    if not page_exists:
        if args.lang_only or args.subset_of_langs or not args.allow_page_creation:
            p.errandmsg(
                "WARNING: Trying to create page when --lang-only, --subset-of-langs or not --allow-page-creation"
            )
            return
    else:
        if args.lang_only or args.subset_of_langs:
            secs = blib.split_text_into_sections(p.text, p.msg)
            sections = secs.sections
            sections_by_lang = secs.sections_by_lang

            def replace_lang_section(lang, newsectext, origsectext):
                newsectext = blib.normalize_text_for_save(newsectext)
                supposed_cursectext = blib.normalize_text_for_save(origsectext)
                if lang not in sections_by_lang:
                    p.errandmsg("WARNING: Couldn't find %s section, skipping page; showing our changes:" % lang)
                    blib.show_diff(supposed_cursectext, newsectext)
                    return False
                langsec = sections_by_lang[lang]
                cursectext = blib.normalize_text_for_save(sections[langsec])
                # If we're editing the last language of the page, there won't be a newline in the page text but there's always
                # one in the find_regex content, so we have to add one to make the comparisons work. It won't matter if we add
                # an extra newline at the end of the page because it will be stripped by MediaWiki.
                if not cursectext.endswith("\n"):
                    cursectext += "\n"
                if cursectext != supposed_cursectext:
                    if cursectext == newsectext:
                        p.msg("%s section has already been changed to new text, not saving" % lang)
                    else:
                        p.errandmsg(
                            "WARNING: %s text has changed from supposed original text, not saving; showing our changes:"
                            % lang
                        )
                        blib.show_diff(supposed_cursectext, newsectext)
                    return False
                sections[langsec] = newsectext
                return True

            if args.lang_only:
                changed = replace_lang_section(args.lang_only, contents, origcontents)
                if not changed:
                    return
            else:
                origsec = blib.split_text_into_sections(origcontents, p.msg)
                origcontents_sections = origsec.sections
                origcontents_sections_by_lang = origsec.sections_by_lang
                contentssec = blib.split_text_into_sections(contents, p.msg)
                contents_sections = contentssec.sections
                contents_sections_by_lang = contentssec.sections_by_lang
                if origcontents_sections_by_lang != contents_sections_by_lang:
                    p.errandmsg(
                        "WARNING: Languages differ or have been rearranged between original and replacement text, not saving"
                    )
                    return
                for lang, langsec in origcontents_sections_by_lang.items():
                    lang_origcontents = origcontents_sections[langsec]
                    lang_contents = contents_sections[langsec]
                    if lang_origcontents == lang_contents:
                        p.msg("Skipping contents for %s because no change" % lang)
                    elif not replace_lang_section(lang, lang_contents, lang_origcontents):
                        return
            contents = "".join(sections)
        else:
            nfc_curtext = normalize_text(p.text)
            supposed_nfc_curtext = normalize_text(origcontents)
            contents = normalize_text(contents)
            if nfc_curtext != supposed_nfc_curtext:
                if nfc_curtext == contents:
                    p.msg("Page has already been changed to new text, not saving")
                else:
                    p.errandmsg(
                        "WARNING: Text has changed from supposed original text, not saving; showing our changes:"
                    )
                    blib.show_diff(supposed_nfc_curtext, contents)
                return
    if not prev_comment and not args.comment:
        p.errandmsg("WARNING: Trying to save page and neither previous comment not --comment available")
        return
    if not prev_comment:
        comment = args.comment
    elif not args.comment:
        comment = prev_comment
    elif args.comment in prev_comment or args.comment_only_when_no_existing:
        comment = prev_comment
    else:
        comment = "%s; %s" % (prev_comment, args.comment)
    return contents.rstrip("\n"), comment


if __name__ == "__main__":
    parser = blib.create_argparser(
        "Push changes made to find_regex.py output files", include_pagefile=True, include_stdin=True
    )
    parser.add_argument("--direcfile", help="File containing directives.")
    parser.add_argument("--origfile", help="File containing unchanged directives.")
    parser.add_argument("--comment", help="Comment to use (in addition to any existing comment).")
    parser.add_argument(
        "--comment-only-when-no-existing",
        help="Use the comment in --comment only when no existing comment is available.",
        action="store_true",
    )
    parser.add_argument("--lang-only", help="Change applies only to the specified language section.")
    parser.add_argument(
        "--subset-of-langs",
        action="store_true",
        help="find_regex.py output contains a subset of all languages on the page.",
    )
    parser.add_argument("--allow-page-creation", action="store_true", help="Allow page creation.")
    args = parser.parse_args()
    start, end = blib.parse_start_end(args.start, args.end)

    origpages = {}

    if args.origfile:
        origlines = open(args.origfile, "r", encoding="utf-8")
        for index, pagetitle, text, comment in blib.yield_text_from_find_regex(origlines, args.verbose):
            origpages[pagetitle] = text

    lines = open(args.direcfile, "r", encoding="utf-8")

    if blib.args_has_non_default_pages(args):
        newpages = {}
        for index, pagetitle, text, comment in blib.yield_text_from_find_regex(lines, args.verbose):
            newpages[pagetitle] = (text, comment)

        def do_process_text_on_page(p):
            origcontents = origpages.get(p.title, None)
            newtext, comment = newpages.get(p.title, (None, None))
            if not newtext:
                p.msg("Skipping because not found in among new page contents")
                return
            if origcontents == newtext:
                p.msg("Skipping contents because no change")
                return
            return process_text_on_page(p, newtext, comment, origcontents)

        blib.do_pagefile_cats_refs(args, start, end, do_process_text_on_page)

    else:
        index_pagetitle_text_comment = blib.yield_text_from_find_regex(lines, args.verbose)
        for _, (index, pagetitle, newtext, comment) in blib.iter_items(
            index_pagetitle_text_comment, start, end, get_name=lambda x: x[1], get_index=lambda x: x[0]
        ):
            origcontents = origpages.get(pagetitle, None)
            if origcontents == newtext:
                msg("Page %s %s: Skipping contents because no change" % (index, pagetitle))
            else:

                def do_process_page(p):
                    return process_text_on_page(p, newtext, comment, origcontents)

                blib.do_edit(args, index, pagetitle, do_process_page)

        blib.elapsed_time()
