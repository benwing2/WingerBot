#!/usr/bin/env python3

# Undo auto-accent changes made by (misnamed) find_russian_need_vowels
# (actually an auto-accent script), when applied to things that may be
# direct quotations; this is approximated by undoing instances of ux, usex,
# and lang. This will affect many things that are usage examples but not
# quotations; we will have to sort this out manually.
import re

from wingerbot import blib
from wingerbot.blib import msg


def undo_ru_auto_accent(direcfile, start, end):
    # FIXME: Script no longer applies and would need fixing up.

    template_removals = []
    for lineno, line in blib.iter_items_from_file(direcfile, start, end):
        m = re.search(r"^Page [0-9]+ (.*?): Replaced (\{\{.*?\}\}) with (\{\{.*?\}\})$", line)
        if not m:
            msg("Line %s: WARNING: Unable to parse line: [%s]" % (lineno, line))
        else:
            template_removals.append(m.groups())

    for index, (pagename, removed_param, template_text) in blib.iter_items(template_removals, get_name=lambda x: x[0]):

        if not re.search(r"^\{\{(ux|usex|ru-ux|lang)\|", orig_template):
            continue

        def undo_one_page_ru_auto_accent(p):
            text = p.text
            if not re.search(r"^#\*:* *%s" % re.escape(repl_template), text, re.M):
                return
            found_orig_template = orig_template in text
            newtext = text.replace(repl_template, orig_template)
            changelog = ""
            if newtext == text:
                if not found_orig_template:
                    p.msg(
                        "WARNING: Unable to locate 'repl' template when undoing Russian auto-accenting: %s"
                        % repl_template
                    )
                else:
                    p.msg("Original template found, taking no action")
            else:
                p.msg("Replaced %s with %s" % (repl_template, orig_template))
                if found_orig_template:
                    p.msg("WARNING: Undid replacement, but original template %s already present!" % orig_template)
                if len(newtext) - len(text) != len(orig_template) - len(repl_template):
                    p.msg(
                        "WARNING: Length mismatch when undoing Russian auto-accenting, may have matched multiple templates: orig=%s, repl=%s"
                        % (orig_template, repl_template)
                    )
                changelog = "Undid auto-accenting (per Wikitiki89) of %s" % (orig_template)
                p.msg("Change log = %s" % changelog)
            return newtext, changelog

        blib.do_edit(args, index, pagename, undo_one_page_ru_auto_accent, must_exist=True)


params = blib.create_argparser(
    "Undo auto-accent changes involving ux, usex and lang templates that look like direct quotes"
)
params.add_argument("--file", help="File containing log file from original auto-accent run", required=True)

args = params.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

undo_ru_auto_accent(args.file, start, end)
