#!/usr/bin/env python3

import pywikibot, re

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, msg, site
from wingerbot.latin import lalib


def find_head_comp_sup(pagetitle, pagemsg, errandpagemsg):
    page = pywikibot.Page(site, pagetitle)
    text = blib.safe_page_text(page, errandpagemsg)
    parsed = blib.parse_text(text)
    for t in parsed.filter_templates():
        if tname(t) == "la-adv":
            head = getparam(t, "1")
            comp = getparam(t, "comp") or getparam(t, "2")
            sup = getparam(t, "sup") or getparam(t, "3")
            if not comp or not sup:
                for suff in ["iter", "nter", "ter", "er", "iē", "ē", "im", "ō"]:
                    m = re.search("^(.*?)%s$" % suff, head)
                    if m:
                        stem = m.group(1)
                        if suff == "nter":
                            stem += "nt"
                        default_comp = stem + "ius"
                        default_sup = stem + "issimē"
                        break
                else:
                    pagemsg("WARNING: Didn't recognize ending of adverb headword %s" % head)
                    return head, comp, sup
                comp = comp or default_comp
                sup = sup or default_sup
            return head, comp, sup
    return None, None, None


def process_text_on_page(p):
    p.msg("Processing")

    modsec = blib.find_modifiable_lang_section(p.text, "Latin", p.msg)
    if modsec is None:
        return
    secbody = modsec.secbody

    notes = []

    subsecs = blib.split_text_into_subsections(secbody, p.msg)
    subsections = subsecs.subsections
    for k, header in subsecs.header_list:
        if header == "Adverb":
            parsed = blib.parse_text(subsections[k])
            posdeg = None
            compt = None
            supt = None
            for t in parsed.filter_templates():
                if tname(t) == "comparative of":
                    if compt:
                        p.msg("WARNING: Saw multiple {{comparative of}}: %s and %s" % (str(compt), str(t)))
                    else:
                        compt = t
                        posdeg = blib.remove_links(getparam(t, "1"))
                        if not posdeg:
                            p.msg("WARNING: Didn't see positive degree in {{comparative of}}: %s" % str(t))
                elif tname(t) == "superlative of":
                    if supt:
                        p.msg("WARNING: Saw multiple {{superlative of}}: %s and %s" % (str(supt), str(t)))
                    else:
                        supt = t
                        posdeg = blib.remove_links(getparam(t, "1"))
                        if not posdeg:
                            p.msg("WARNING: Didn't see positive degree in {{superlative of}}: %s" % str(t))
            if compt and supt:
                p.msg("WARNING: Saw both comparative and superlative, skipping: %s and %s" % (str(compt), str(supt)))
                continue
            if not compt and not supt:
                p.msg("WARNING: Didn't see {{comparative of}} or {{superlative of}} in section %s" % k)
                continue
            for t in parsed.filter_templates():
                tn = tname(t)
                if tn in ["la-adv-comp", "la-adv-sup"]:
                    p.msg("Already saw fixed headword: %s" % str(t))
                    break
                if tn == "head":
                    if not getparam(t, "1") == "la":
                        p.msg("WARNING: Saw wrong language in {{head}}: %s" % str(t))
                    else:
                        pos = getparam(t, "2")
                        head = blib.remove_links(getparam(t, "head")) or p.title
                        if pos not in [
                            "adverb",
                            "adverbs",
                            "adverb form",
                            "adverb forms",
                            "adverb comparative form",
                            "adverb comparative forms",
                            "adverb superlative form",
                            "adverb superlative forms",
                        ]:
                            p.msg("WARNING: Unrecognized part of speech '%s': %s" % (pos, str(t)))
                        else:
                            real_head, real_comp, real_sup = find_head_comp_sup(
                                lalib.remove_macrons(posdeg), p.msg, p.errandmsg
                            )
                            if real_head:
                                if lalib.remove_macrons(real_head) != lalib.remove_macrons(posdeg):
                                    p.msg(
                                        "WARNING: Can't replace positive degree %s with %s because they differ when macrons are removed"
                                        % (posdeg, real_head)
                                    )
                                else:
                                    p.msg("Using real positive degree %s instead of %s" % (real_head, posdeg))
                                    inflt = compt or supt
                                    # We continued out of the loop if not compt and not supt
                                    assert inflt is not None
                                    origt = str(inflt)
                                    inflt.add("1", real_head)
                                    p.msg("Replaced %s with %s" % (origt, str(inflt)))
                            if compt:
                                newname = "la-adv-comp"
                                infldeg = "comparative"
                                if real_comp and real_comp != "-":
                                    if lalib.remove_macrons(real_comp) != lalib.remove_macrons(head):
                                        p.msg(
                                            "WARNING: Can't replace comparative degree %s with %s because they differ when macrons are removed"
                                            % (head, real_comp)
                                        )
                                    else:
                                        p.msg("Using real comparative degree %s instead of %s" % (real_comp, head))
                                        head = real_comp
                                else:
                                    p.msg(
                                        "WARNING: Couldn't retrieve real comparative for positive degree %s" % real_head
                                    )
                            else:
                                newname = "la-adv-sup"
                                infldeg = "superlative"
                                if real_sup and real_sup != "-":
                                    if lalib.remove_macrons(real_sup) != lalib.remove_macrons(head):
                                        p.msg(
                                            "WARNING: Can't replace superlative degree %s with %s because they differ when macrons are removed"
                                            % (head, real_sup)
                                        )
                                    else:
                                        p.msg("Using real superlative degree %s instead of %s" % (real_sup, head))
                                        head = real_sup
                                else:
                                    p.msg(
                                        "WARNING: Couldn't retrieve real superlative for positive degree %s" % real_head
                                    )
                            origt = str(t)
                            rmparam(t, "head")
                            rmparam(t, "2")
                            rmparam(t, "1")
                            blib.set_template_name(t, newname)
                            t.add("1", head)
                            p.msg("Replaced %s with %s" % (origt, str(t)))
                            notes.append(
                                "replace {{head|la|...}} with {{%s}} and fix up positive/%s" % (newname, infldeg)
                            )

            subsections[k] = str(parsed)

    return modsec.rebuild(secbody="".join(subsections)), notes


parser = blib.create_argparser(
    "Fix headword of Latin comparative and superlative adverbs", include_pagefile=True, include_stdin=True
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    default_cats=["Latin comparative adverbs", "Latin superlative adverbs"],
)
