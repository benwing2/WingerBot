#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, msg, errandmsg, site, tname, pname

# Value is one of:
# "pl-p-respelling": if page has any {{pl-p}} with respelling
# "pl-p-no-respelling": if page has only {{pl-p}} without respelling
# "no-pl-p": if page does not have {{pl-p}}
pages_with_pl_p = {}

infl_templates = ["inflection of", "infl of"]

pronun_templates = ["IPA", "pl-IPA", "pl-p", "pl-pronunciation"]


def get_pl_p_property(index, pagetitle):
    if pagetitle in pages_with_pl_p:
        return pages_with_pl_p[pagetitle]
    page = pywikibot.Page(site, pagetitle)
    def errandpagemsg(txt):
        errandmsg("Page %s %s: %s" % (index, pagetitle, txt))

    pagetext = blib.safe_page_text(page, errandpagemsg)
    parsed = blib.parse_text(pagetext)
    saw_pl_p = False
    respellings = []
    for t in parsed.filter_templates():
        tn = tname(t)
        if tn in ["pl-p", "pl-pronunciation"]:

            def getp(param):
                return getparam(t, param)

            saw_pl_p = True
            for pno in range(1, 11):
                respelling = getp(str(pno))
                if respelling and respelling not in respellings:
                    respellings.append(respelling)
    if respellings:
        retval = ("pl-p-respelling", respellings)
    elif saw_pl_p:
        retval = ("pl-p-no-respelling", None)
    else:
        retval = ("no-pl-p", None)
    pages_with_pl_p[pagetitle] = retval
    return retval


def process_text_on_page(p):
    notes = []

    modsec = blib.find_modifiable_lang_section(p.text, "Polish", p.msg, force_final_nls=True)
    if modsec is None:
        return
    secbody = modsec.secbody

    subsecs = blib.split_text_into_subsections(secbody, p.msg)
    subsections = subsecs.subsections

    has_etym_sections = "==Etymology 1==" in secbody
    if has_etym_sections:
        # Check if either Pronunciation with pronunciation template above Etymology 1, or every
        # Etymology N section has Pronunciation with pronunciation template.
        saw_etym_1 = False
        cur_etym_header = None
        saw_pron_in_etym = False
        for k, header in subsecs.header_list:
            if header == "Pronunciation":
                secparsed = blib.parse_text(subsections[k])
                for t in secparsed.filter_templates():
                    tn = tname(t)
                    if tn in pronun_templates:
                        if saw_etym_1:
                            saw_pron_in_etym = True
                            break
                        else:
                            p.msg("Already saw pronunciation template above ==Etymology 1==: %s" % str(t))
                            return
                else:  # no break
                    p.msg(
                        "WARNING: Saw ==Pronunciation== section without pronunciation template, along with ==Etymology 1==; can't handle, skipping"
                    )
                    return

            if header == "Etymology 1":
                saw_etym_1 = True
                cur_etym_header = header
            elif re.search("^Etymology [0-9]+$", header):
                if not saw_pron_in_etym:
                    p.msg(
                        "WARNING: No ==Pronunciation== section above ==Etymology N== headers and saw %s without pronunciation template; can't handle, skipping"
                        % cur_etym_header
                    )
                    return
                saw_pron_in_etym = False
                cur_etym_header = header
        if not saw_pron_in_etym:
            # Last Etymology N section didn't have pronunciation template.
            p.msg(
                "WARNING: No ==Pronunciation== section above ==Etymology N== headers and saw %s without pronunciation template; can't handle, skipping"
                % cur_etym_header
            )
            return

    parsed = blib.parse_text(secbody)

    for t in parsed.filter_templates():
        tn = tname(t)
        if tn in pronun_templates:
            p.msg("Already saw pronunciation template: %s" % str(t))
            return

    if not args.ignore_lemma_respelling:
        lemmas = set()
        for t in parsed.filter_templates():
            tn = tname(t)
            if tn in infl_templates:

                def getp(param):
                    return getparam(t, param)

                if getp("1") != "pl":
                    p.msg("WARNING: Wrong language in {{%s}}, skipping: %s" % (tn, str(t)))
                    return
                lemma = getparam(t, "2")
                lemmas.add(lemma)
        if len(lemmas) > 1:
            p.msg("WARNING: Saw inflection of multiple lemmas %s, skipping" % ",".join(lemmas))
            return
        if not lemmas:
            p.msg("WARNING: Didn't see inflection template, skipping")
            return
        lemma = list(lemmas)[0]
        pl_p_prop, pl_p_respellings = get_pl_p_property(p.index, lemma)
        if pl_p_prop == "no-pl-p":
            p.msg("WARNING: Lemma page %s has no {{pl-p}}, not sure what to do, skipping" % lemma)
            return
        elif pl_p_prop == "pl-p-respelling":
            p.msg("WARNING: Lemma page %s has respelling(s) %s, skipping" % (lemma, ",".join(pl_p_respellings)))
            return
        else:
            p.msg("Lemma page %s has {{pl-p}} without respelling, proceeding" % lemma)

    def construct_new_pron_template():
        return "{{pl-p}}", ""

    def insert_into_existing_pron_section(k):
        parsed = blib.parse_text(subsections[k])
        for t in parsed.filter_templates():
            tn = tname(t)
            if tn in pronun_templates:
                p.msg("Already saw pronunciation template: %s" % str(t))
                break
        else:  # no break
            new_pron_template, pron_prefix = construct_new_pron_template()
            # Remove existing rhymes/hyphenation/pl-IPA lines
            for template in ["rhyme|pl", "rhymes|pl", "pl-IPA", "hyph|pl", "hyphenation|pl"]:
                re_template = template.replace("|", r"\|")
                regex = r"^([* ]*\{\{%s(?:\|[^{}]*)*\}\}\n)" % re_template
                m = re.search(regex, subsections[k], re.M)
                if m:
                    p.msg("Removed existing %s" % m.group(1).strip())
                    notes.append("remove existing {{%s}}" % template)
                    subsections[k] = re.sub(regex, "", subsections[k], 0, re.M)
            for template in ["audio|pl"]:
                re_template = template.replace("|", r"\|")
                regex = r"^([* ]*\{\{%s(?:\|[^{}]*)*\}\}\n)" % re_template
                all_audios = re.findall(regex, subsections[k], re.M)
                if len(all_audios) > 1:
                    p.msg(
                        "WARNING: Saw multiple {{audio}} templates, skipping: %s"
                        % ",".join(x.strip() for x in all_audios)
                    )
                    return
                if len(all_audios) == 1:
                    audiot = list(blib.parse_text(all_audios[0].strip()).filter_templates())[0]
                    assert tname(audiot) == "audio"
                    if getparam(audiot, "1") != "pl":
                        p.msg("WARNING: Wrong language in {{audio}}, skipping: %s" % all_audios[0].strip())
                        return
                    audiofile = getparam(audiot, "2")
                    audiogloss = getparam(audiot, "3")
                    for param in audiot.params:
                        pn = pname(param)
                        pv = str(param.value)
                        if pn not in ["1", "2", "3"]:
                            p.msg(
                                "WARNING: Unrecognized param %s=%s in {{audio}}, skipping: %s"
                                % (pn, pv, all_audios[0].strip())
                            )
                            return
                    if audiogloss in ["Audio", "audio"]:
                        audiogloss = ""
                    params = "|a=%s" % audiofile
                    if audiogloss:
                        params += "|ac=%s" % audiogloss
                    new_pron_template = new_pron_template[:-2] + params + new_pron_template[-2:]
                    p.msg("Removed existing %s in order to incorporate into {{pl-p}}" % all_audios[0].strip())
                    notes.append("incorporate existing {{%s}} into {{pl-p}}" % template)
                    subsections[k] = re.sub(regex, "", subsections[k], 0, re.M)
            subsections[k] = pron_prefix + new_pron_template + "\n" + subsections[k]
            notes.append("insert %s into existing Pronunciation section" % new_pron_template)
        return True

    def insert_new_l3_pron_section(k):
        new_pron_template, pron_prefix = construct_new_pron_template()
        subsections[k:k] = ["===Pronunciation===\n", pron_prefix + new_pron_template + "\n\n"]
        notes.append("add top-level Polish pron %s" % new_pron_template)

    for k in range(2, len(subsections), 2):
        if "==Pronunciation==" in subsections[k - 1]:
            if not insert_into_existing_pron_section(k):
                return
            break
    else:  # no break
        k = 2
        while k < len(subsections) and subsecs.headers[k] in ["Alternative forms", "Etymology"]:
            k += 2
        if k - 1 >= len(subsections):
            p.msg("WARNING: No lemma or non-lemma section at top level")
            return
        insert_new_l3_pron_section(k - 1)

    return modsec.rebuild(secbody="".join(subsections)), notes


parser = blib.create_argparser("Add Polish non-lemma pronunciations", include_pagefile=True, include_stdin=True)
parser.add_argument(
    "--ignore-lemma-respelling", action="store_true", help="Add {{pl-p}} to nonlemmas irrespective of lemma respelling."
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_cats=["Polish non-lemma forms"]
)

blib.elapsed_time()
