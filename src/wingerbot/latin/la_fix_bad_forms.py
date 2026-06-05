#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, tname
from wingerbot.latin import lalib
from wingerbot.latin.lalib import remove_macrons


def process_form(p, lemma, subs):
    notes = []

    parsed = blib.parse_text(p.text)

    for t in parsed.filter_templates():
        origt = str(t)
        tn = tname(t)

        def fix_head(headparam, head, tn):
            for badstem, goodstem in subs:
                if head.startswith(badstem):
                    newhead = goodstem + head[len(badstem) :]
                    t.add(headparam, newhead)
                    notes.append("correct stem %s -> %s in {{%s}}" % (badstem, goodstem, tn))
                    return newhead
            else:
                # no break
                p.msg(
                    "WARNING: Head %s not same as page title and doesn't begin with bad stem %s: %s"
                    % (head, " or ".join(badstem for badstem, goodstem in subs), str(t))
                )
                return False

        # la-suffix-form has its own format, don't handle
        if tn in lalib.la_nonlemma_headword_templates and tn != "la-suffix-form":
            headparam = "head"
            head = getparam(t, headparam)
            if not head:
                headparam = "1"
                head = getparam(t, headparam)
            if remove_macrons(head) != p.title:
                newhead = fix_head(headparam, head, tn)
                if newhead and remove_macrons(newhead) != p.title:
                    p.msg("WARNING: Replacement head %s not same as page title: %s" % (newhead, str(t)))
        elif tn in lalib.la_infl_of_templates:
            langparam = "lang"
            headparam = "1"
            altparam = "2"
            lang = getparam(t, langparam)
            if not lang:
                langparam = "1"
                headparam = "2"
                altparam = "3"
                lang = getparam(t, langparam)
            if lang == "la":
                link = getparam(t, headparam)
                alt = getparam(t, altparam)
                head = alt or link
                if remove_macrons(head) != remove_macrons(lemma):
                    if subs:
                        newhead = fix_head(headparam, head, tn + "|la")
                        if newhead:
                            t.add(altparam, "")
                            if remove_macrons(newhead) != remove_macrons(lemma):
                                p.msg(
                                    "WARNING: Replacement lemma %s not same as lemma %s: %s" % (newhead, lemma, str(t))
                                )
                else:
                    if link != lemma or alt != "":
                        t.add(headparam, lemma)
                        t.add(altparam, "")
                        notes.append("correct lemma and/or move alt text to link text in {{%s|la}}" % tn)
        if origt != str(t):
            p.msg("Replaced %s with %s" % (origt, str(t)))
    return str(parsed), notes


def process_page(p, lemma, pos, subs, infl):
    p.msg("Processing")

    inflargs = lalib.generate_infl_forms(pos, infl, p.errandmsg, p.expand_text)
    if inflargs is None:
        return

    single_forms_to_delete = lalib.flatten_slot_formvals(p.index, lemma, inflargs)

    for _, (slotformind, slotformtitle, slot, formval) in blib.iter_items(single_forms_to_delete, get_name=lambda x: x[3]):
        def handler(p):
            return process_form(p, lemma, subs)

        blib.do_edit(
            args,
            slotformind,
            remove_macrons(formval),
            handler,
            msg_title=slotformtitle,
        )


parser = blib.create_argparser("Fix up bad Latin forms")
parser.add_argument("--declfile", help="File containing pos lemma bad:good,... infl", required=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

for lineindex, line in blib.iter_items_from_file(args.declfile, start, end):
    if "!!!" in line:
        pos, lemma, subs, infl = re.split("!!!", line)
    else:
        pos, lemma, subs, infl = re.split(" ", line, 4)
    subs = [] if subs == "-" else [x.split(":") for x in subs.split(",")]
    process_page(blib.ProcessPageParams(args, lineindex, remove_macrons(lemma), "", msg_title=lemma),
                 lemma, pos, subs, infl)
