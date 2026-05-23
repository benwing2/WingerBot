#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname, msg, errandmsg, site

verb_cache = {}


def process_text_on_page(index, pagetitle, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    def errandpagemsg(txt):
        errandmsg("Page %s %s: %s" % (index, pagetitle, txt))

    def verb_is_italian(inf):
        if inf in verb_cache:
            return verb_cache[inf]
        page = pywikibot.Page(site, inf)
        pagetext = blib.safe_page_text(page, errandpagemsg)
        if re.search(r"\{\{it-verb(-rfc)?\|", pagetext):
            pagemsg("[[%s]] is an Italian verb" % inf)
            retval = True
        elif pagetext and re.search(r"==\s*Italian\s*==", pagetext):
            pagemsg("[[%s]] has an Italian section but is not a verb" % inf)
            retval = False
        elif pagetext:
            pagemsg("[[%s]] exists but does not have an Italian section" % inf)
            retval = False
        else:
            pagemsg("[[%s]] does not exist" % inf)
            retval = False
        verb_cache[inf] = retval
        return retval

    notes = []

    pagemsg("Processing")

    parsed = blib.parse_text(text)

    m = re.search("^(.*(?:r|ndo))([mtsvc]i)$", pagetitle)
    if not m:
        pagemsg("Page isn't gerund or infinitive + clitic, can't handle")
        return
    page_base, clitic = m.groups()

    for t in parsed.filter_templates():
        tn = tname(t)

        def getp(param):
            return getparam(t, param)

        doit = False
        if tn in ["inflection of", "infl of"] and getp("1") == "it":
            inf = getp("2")
            alt = getp("3")
            forms = blib.fetch_param_chain(t, "4")
            if alt:
                pagemsg("Has 3=, can't handle: %s" % str(t))
                continue
            if not inf.endswith("rsi"):
                pagemsg("Infinitive %s in 2= doesn't end in -rsi, can't handle: %s" % (inf, str(t)))
                continue
            if not re.search("^[12]/[sp]/(ger|gerund|inf)$", "/".join(forms)):
                pagemsg("Forms not [12]/[sp]/(ger|gerund|inf), can't handle: %s" % str(t))
                continue
            doit = True
        elif tn in ["gerund of"] and getp("1") == "it":
            inf = getp("2")
            doit = True
        if doit:
            inf = inf[:-2] + "e"
            if page_base.endswith("ndo"):
                if inf.endswith("are") and inf[:-2] + "ndo" == page_base:
                    if verb_is_italian(inf):
                        origt = str(t)
                        del t.params[:]
                        blib.set_template_name(t, "it-compound of")
                        pagemsg("Converting %s to %s" % (origt, str(t)))
                        notes.append(
                            "convert {{inflection of}} wrongly indicated as a reflexive gerund to {{it-compound of}}"
                        )
                    else:
                        pagemsg("Base infinitive %s doesn't exist, not converting: %s" % (inf, str(t)))
                    continue
                if (
                    page_base.endswith("ducendo")
                    and inf.endswith("ure")
                    or page_base.endswith("ponendo")
                    and inf.endswith("ore")
                    or page_base.endswith("aendo")
                    and inf.endswith("are")
                ):
                    inf = inf[:-2] + "rre"
                if not page_base.endswith("ando") and not page_base.endswith("endo"):
                    pagemsg("WARNING: Strange gerund %s, skipping: %s" % (page_base, str(t)))
                    continue
                if page_base[:-4] + "ere" != inf and page_base[:-4] + "ire" != inf:
                    pagemsg(
                        "WARNING: Apparent irregular infinitive %s for gerund %s, verify: %s" % (inf, page_base, str(t))
                    )
                if verb_is_italian(inf):
                    origt = str(t)
                    del t.params[:]
                    blib.set_template_name(t, "it-compound of")
                    t.add("inf", inf)
                    pagemsg("Converting %s to %s" % (origt, str(t)))
                    notes.append(
                        "convert {{inflection of}} wrongly indicated as a reflexive gerund to {{it-compound of}}"
                    )
                else:
                    pagemsg("Base infinitive %s doesn't exist, not converting: %s" % (inf, str(t)))
            else:
                need_explicit_inf = False
                if inf.endswith("trare"):
                    trare_exists = verb_is_italian(inf)
                    trarre_inf = inf[:-1] + "re"
                    trarre_exists = verb_is_italian(trarre_inf)
                    if trare_exists and not trarre_exists:
                        pagemsg("Infinitive %s but not %s exists, no need for inf=: %s" % (inf, trarre_inf, str(t)))
                    elif trarre_exists and not trare_exists:
                        pagemsg("Infinitive %s but not %s exists, need explicit inf=: %s" % (trarre_inf, inf, str(t)))
                        need_explicit_inf = True
                        inf = trarre_inf
                    elif trare_exists and trarre_exists:
                        pagemsg(
                            "WARNING: Both infinitive %s and %s exist, can't handle: %s" % (inf, trarre_inf, str(t))
                        )
                        continue
                    else:
                        pagemsg("Neither infinitive %s nor %s exist, not converting: %s" % (inf, trarre_inf, str(t)))
                        continue
                if not need_explicit_inf and re.search("[aeiou]re$", inf) and inf[:-1] == page_base:
                    if re.search("[ou]re$", inf):
                        inf = inf[:-1] + "re"
                    if verb_is_italian(inf):
                        origt = str(t)
                        del t.params[:]
                        blib.set_template_name(t, "it-compound of")
                        pagemsg("Converting %s to %s" % (origt, str(t)))
                        notes.append(
                            "convert {{inflection of}} wrongly indicated as a reflexive infinitive to {{it-compound of}}"
                        )
                    else:
                        pagemsg("Base infinitive %s doesn't exist, not converting: %s" % (inf, str(t)))
                    continue
                if page_base + "e" != inf:
                    pagemsg(
                        "WARNING: Apparent irregular infinitive %s for page base infinitive %s, verify: %s"
                        % (inf, page_base, str(t))
                    )
                if verb_is_italian(inf):
                    origt = str(t)
                    del t.params[:]
                    blib.set_template_name(t, "it-compound of")
                    t.add("inf", inf)
                    pagemsg("Converting %s to %s" % (origt, str(t)))
                    notes.append(
                        "convert {{inflection of}} wrongly indicated as a reflexive gerund to {{it-compound of}}"
                    )
                else:
                    pagemsg("Base infinitive %s doesn't exist, not converting: %s" % (inf, str(t)))
            continue

    return str(parsed), notes


parser = blib.create_argparser(
    "Convert {{inflection of}} for reflexive gerunds/infinitives to {{it-compound of}}",
    include_pagefile=True,
    include_stdin=True,
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True)
