#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import msg
from wingerbot import lang_utils


def process_text_on_page(index, pagetitle, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    notes = []

    modsec = blib.find_modifiable_lang_section(text, args.langname, pagemsg, force_final_nls=True)
    if modsec is None:
        return
    secbody = modsec.secbody

    subsecs = blib.split_text_into_subsections(secbody, pagemsg)
    subsections = subsecs.subsections

    sect_for_wiki = 0
    seen_lemma_headers = []
    for k, header in subsecs.header_list:
        if re.search(r"^Etymology [0-9]$", header):
            sect_for_wiki = k
            seen_lemma_headers = []
        else:
            lines = subsections[k].strip().split("\n")
            lines = [line for line in lines]
            lines_so_far = []
            for lineind, line in enumerate(lines):
                if re.search(r"^\{\{(wp|wiki|wikipedia|Wikipedia)\|[^{}]*\}\}$", line):
                    if len(seen_lemma_headers) >= 1:
                        pagemsg(
                            "Already saw preceding lemma header(s) %s, not moving wikipedia line %s"
                            % (",".join(seen_lemma_headers), line)
                        )
                        lines_so_far.append(line)
                    else:
                        # Put after any other wikipedia lines.
                        m = re.search(r"\A(.*?)(\n*)\Z", subsections[sect_for_wiki], re.S)
                        assert m  # should always match
                        stripped_sect_for_wiki, sect_for_wiki_endlines = m.groups()
                        sect_for_wiki_lines = stripped_sect_for_wiki.split("\n")
                        for i in range(len(sect_for_wiki_lines)):
                            if not re.search(
                                r"^\{\{(wp|wiki|wikipedia|Wikipedia)\|[^{}]*\}\}$", sect_for_wiki_lines[i]
                            ):
                                break
                        sect_for_wiki_lines[i:i] = [line]
                        subsections[sect_for_wiki] = "\n".join(sect_for_wiki_lines) + sect_for_wiki_endlines
                        subsections[k] = "%s\n\n" % "\n".join(lines_so_far + lines[lineind + 1 :])
                        notes.append("move {{wikipedia}} line to top of etym section")
                else:
                    lines_so_far.append(line)
            if re.search("^" + lang_utils.pos_regex + "$", header):  # Maybe a lemma
                lines = subsections[k].strip().split("\n")
                for lineind, line in enumerate(lines):
                    if re.search(r"\{\{(head\|[^{}]*|[a-z][a-z][a-z]?-[^{}|]*)forms?\b", line):
                        pagemsg(
                            "Saw potential lemma section %s but appears to be a non-lemma form due to line #%s: %s"
                            % (header, lineind + 1, line)
                        )
                        break
                else:  # no break
                    seen_lemma_headers.append(header)

    text = modsec.rebuild(secbody="".join(subsections))
    newtext = re.sub(r"\n\n\n+", "\n\n", text)
    if text != newtext:
        notes.append("convert 3+ newlines to 2 newlines")
    text = newtext
    return text, notes


parser = blib.create_argparser(
    "Move {{wikipedia}} lines to top of etym section", include_pagefile=True, include_stdin=True
)
parser.add_argument("--langname", help="Only do this language name (optional).")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True)
