#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, msg, tname


def _get_head_param(t, pagetitle) -> list[str] | None:
    tn = tname(t)
    if tn in ["ang-adj", "ang-adj-comp", "ang-adj-sup", "ang-adv", "ang-adv-comp", "ang-adv-sup", "ang-verb"]:
        retval = blib.fetch_param_chain(t, "1", "head")
    elif tn in [
        "ang-noun",
        "ang-noun-form",
        "ang-verb-form",
        "ang-adj-form",
        "ang-con",
        "ang-prep",
        "ang-prefix",
        "ang-proper noun",
        "ang-suffix",
    ]:
        retval = blib.fetch_param_chain(t, "head", "head")
    elif tn == "head" and getparam(t, "1") == "ang":
        retval = blib.fetch_param_chain(t, "head", "head")
    else:
        return None
    return retval or [pagetitle]


def process_section(p, sectext):
    parsed = blib.parse_text(sectext)
    heads = None
    for t in parsed.filter_templates():
        newheads = _get_head_param(t, p.title)
        if newheads is not None:
            newheads = [blib.remove_links(x) for x in newheads]
            if heads is not None and heads != newheads:
                p.msg("WARNING: Saw multiple heads %s and %s" % (",".join(heads), ",".join(newheads)))
            heads = newheads
    if heads is None:
        p.msg("WARNING: Couldn't find head")
    saw_pronun = False
    pipe_joined_heads = "|".join(heads) if heads is not None else "<<%s>>" % p.title
    for t in parsed.filter_templates():
        tn = tname(t)
        if tn == "IPA":
            if getparam(t, "1") != "ang":
                p.msg("WARNING: Wrong-language IPA template: %s" % str(t))
                continue
            p.msg("<from> %s <to> {{ang-IPA|%s}} <end>" % (str(t), pipe_joined_heads))
            saw_pronun = True
        elif tn == "ang-IPA":
            p.msg("Saw existing pronunciation: %s" % str(t))
            saw_pronun = True
    if not saw_pronun:
        p.msg(
            "WARNING: Didn't see pronunciation for headword %s <new> {{ang-IPA|%s}} <end>"
            % (",".join(heads) if heads is not None else "NO HEADS", pipe_joined_heads)
        )


def process_text_on_page(p):
    p.msg("Processing")

    modsec = blib.find_modifiable_lang_section(p.text, "Old English", p.msg)
    if modsec is None:
        return
    secbody = modsec.secbody
    if "Etymology 1" in secbody:
        etym_secs = blib.split_text_into_subsections(secbody, p.msg, only_level=3, header_re="Etymology [0-9.]+")
        etym_sections = etym_secs.subsections
        if "=Pronunciation=" in etym_sections[0]:
            process_section(p, secbody)
        else:
            for k, header in etym_secs.header_list:
                process_section(p, etym_sections[k])
    else:
        process_section(p, secbody)


def process_section_for_modification(p, sectext, indent_level, new_pronuns):
    parsed = blib.parse_text(sectext)
    heads = []
    for t in parsed.filter_templates():
        newheads = _get_head_param(t, p.title)
        if newheads:
            newheads = [blib.remove_links(x) for x in newheads]
            for head in newheads:
                if head not in heads:
                    heads.append(head)
    if not heads:
        p.msg("WARNING: Couldn't find head")
        return sectext
    saw_pronun = False
    for t in parsed.filter_templates():
        tn = tname(t)
        if tn == "IPA":
            if getparam(t, "1") != "ang":
                p.msg("WARNING: Wrong-language IPA template: %s" % str(t))
                continue
            saw_pronun = True
        elif tn == "ang-IPA":
            p.msg("Saw existing pronunciation: %s" % str(t))
            saw_pronun = True
    if saw_pronun:
        return sectext
    subsecs = blib.split_text_into_subsections(sectext, p.msg, only_level=indent_level)
    subsections = subsecs.subsections
    for k, header in subsecs.header_list:
        if "=Pronunciation=" in subsections[k]:
            p.msg("WARNING: Already saw pronunciation section without pronunciation in it")
            return sectext
    k = 2
    while k < len(subsections) and subsecs.headers[k] in ["Alternative forms", "Etymology"]:
        k += 2
    if k >= len(subsections):
        p.msg("WARNING: No place to insert pronunciation")
        return sectext
    new_pronun_map = dict(new_pronuns)
    if len(heads) > 1:
        pronuns = []
        for head in heads:
            if head not in new_pronun_map:
                p.msg("WARNING: No pronun found for head %s" % head)
                return sectext
            pronuns.append("* " + new_pronun_map[head].replace("}}", "|ann=1}}"))
        newsec = "%sPronunciation%s\n%s\n\n" % ("=" * indent_level, "=" * indent_level, "\n".join(pronuns))
    else:
        if heads[0] not in new_pronun_map:
            p.msg("WARNING: No pronun found for head %s" % heads[0])
            return sectext
        newsec = "%sPronunciation%s\n* %s\n\n" % ("=" * indent_level, "=" * indent_level, new_pronun_map[heads[0]])
    subsections[k - 1 : k - 1] = [newsec]
    return "".join(subsections)


def process_text_on_page_for_modification(p):
    if p.title not in new_pronuns:
        return

    p.msg("Processing")

    modsec = blib.find_modifiable_lang_section(p.text, "Old English", p.msg)
    if modsec is None:
        return
    secbody = modsec.secbody

    heads = None
    if "Etymology 1" in secbody:
        etym_secs = blib.split_text_into_subsections(secbody, p.msg, only_level=3, header_re="Etymology [0-9]+")
        etym_sections = etym_secs.subsections
        for k, header in etym_secs.header_list:
            parsed = blib.parse_text(etym_sections[k])
            secheads = []
            for t in parsed.filter_templates():
                this_heads = _get_head_param(t, p.title)
                if this_heads:
                    this_heads = [blib.remove_links(x) for x in this_heads]
                    for head in this_heads:
                        if head not in secheads:
                            secheads.append(head)
            if heads is None:
                heads = secheads
            elif set(heads) != set(secheads):
                p.msg(
                    "Saw head(s) %s in one etym section and %s in another, splitting pronuns per etym section"
                    % (",".join(heads), ",".join(secheads))
                )
                for k in range(2, len(etym_sections), 2):
                    etym_sections[k] = process_section_for_modification(
                        p, etym_sections[k], 4, new_pronuns[p.title]
                    )
                return modsec.rebuild(secbody="".join(etym_sections)), "add pronunciation(s) to Old English lemma(s)"
        p.msg("All etym sections have same head(s) %s, creating a single pronun section" % (
            "NO HEADS" if heads is None else ",".join(heads)))
    secbody = process_section_for_modification(p, secbody, 3, new_pronuns[p.title])
    return modsec.rebuild(secbody=secbody), "add pronunciation(s) to Old English lemma(s)"


parser = blib.create_argparser(
    "Find Old English heads and pronuns or fix them"
)
parser.add_argument("--new-pronuns", help="File containing new pronuns.")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

if not args.new_pronuns:
    blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, default_cats=["Old English lemmas"])
else:
    new_pronuns = {}
    bad_pagename = None
    for lineno, line in blib.iter_items_from_file(args.new_pronuns):
        m = re.search(
            "^Page [0-9]+ (.*?): WARNING: Didn't see pronunciation for headword (.*?) <new> (.*?) <end>$", line
        )
        if not m:
            msg("Line %s: WARNING: Unparsable line: %s" % (lineno, line))
            continue
        pagename, headword, new_pronun = m.groups()
        if pagename == bad_pagename:
            continue
        if pagename not in new_pronuns:
            new_pronuns[pagename] = [(headword, new_pronun)]
        else:
            broken = False
            for this_headword, this_new_pronun in new_pronuns[pagename]:
                if this_headword == headword and this_new_pronun != new_pronun:
                    msg(
                        "Line %s: WARNING: Saw multiple pronuns for headword %s: %s and %s"
                        % (lineno, headword, this_new_pronun, new_pronun)
                    )
                    broken = True
                    break
            if broken:
                del new_pronuns[pagename]
                bad_pagename = pagename
            else:
                new_pronuns[pagename].append((headword, new_pronun))

    blib.do_pagefile_cats_refs(
        args, start, end, process_text_on_page_for_modification, default_cats=["Old English lemmas"],
    )
