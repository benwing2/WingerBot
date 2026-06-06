#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname, msg
from collections import defaultdict

all_quals = defaultdict(int)
stats_by_modifier_type = defaultdict(int)
converted_labels = defaultdict(int)
unconverted_quals = defaultdict(int)

recognized_label_adverbs = {
    "now",
    "mostly",
    "chiefly",
    "all",
    "both",
    "more",
    "less",
    "somewhat",
    "sometimes",
    "also",
    "especially",
    "possibly",
    "otherwise",
    "often",
    "mainly",
    "very",
    "extremely",
}

label_map = {
    "BrE": "UK",
    "U.S.": "US",
    "southern US": "Southern US",
    "UK colloquial": ["UK", "_", "colloquial"],
    "UK dialectal": ["UK", "_", "dialectal"],
    "US colloquial": ["US", "_", "colloquial"],
    "US also": "<<US>> also",
    "common in US": "<<common>> in <<US>>",
    "common in UK": "more <<common>> in <<UK>>",
    "common in  UK": "more <<common>> in <<UK>>",
    "zoölogy": "zoology",
    "South African English": "South Africa",
    "place name": "toponym",
    "placename": "toponym",
    "place": "toponym",
    "Colloquial": "colloquial",
    "Rare": "rare",
    "patronym": "patronymic",
    "Diminutives:": "diminutive",
    "Endearing forms:": "endearing",
    "Pejorative forms:": "pejorative",
    "Patronymics:": "patronymic",
    "Surnames:": "surname",
    "factative": "factitive",
    "commonly": "common",
    "misconstructed": "misconstruction",
    "archaic in most senses": "<<archaic>> in most senses",
    "Internet slang": ["Internet", "_", "slang"],
    "figurative sense": "figurative",
    "{{w|Multicultural London English|MLE}}": "MLE",
    "{{w|Multicultural Toronto English|MTE}}": "MTE",
}

recognized_labels = {
    "rare",
    "uncommon",
    "common",
    "colloquial",
    "informal",
    "nonstandard",
    "non-standard",
    "offensive",
    "figurative",
    "figuratively",
    "formal",
    "learned",
    "impersonal",
    "slang",
    "vulgar",
    "literary",
    "historical",
    "humble speech",
    "jocular",
    "euphemistic",
    "derogatory",
    "expressive",
    "vernacular",
    "childish",
    "abbreviation",
    "initialism",
    "back-formation",
    "clipping",
    "blend",
    "proverb",
    "active",
    "passive",
    "reflexive",
    "mediopassive",
    "iterative",
    "causative",
    "causative-iterative",
    "collective",
    "dialectal",
    "regional",
    "poetic",
    "uncertain",
    "honorific",
    "nickname",
    "pejorative",
    "humorous",
    "eye dialect",
    "proscribed",
    "hypercorrect",
    "official",
    "misconstruction",
    "toponym",
    "surname",
    "patronymic",
    "female patronymic",
    "male patronymic",
    "former name",
    "obsolete",
    "archaic",
    "dated",
    "deprecated",
    "diminutive",
    "augmentative",
    "endearing",
    "semelfactive",
    "US",
    "American",
    "North America",
    "Canada",
    "Canadian",
    "UK",
    "British",
    "Britain",
    "British English",
    "Scotland",
    "Australia",
    "Australian",
    "Ireland",
    "Irish",
    "New Zealand",
    "Indian English",
    "AU",
    "NZ",
    "Commonwealth",
    "Quebec",
    "Geordie",
    "England",
    "sports",
    "medicine",
    "law",
    "logic",
    "shipping",
    "theology",
    "phonology",
    "music",
    "grammar",
    "religion",
    "linguistics",
    "geology",
    "botany",
    "ornithology",
    "sociology",
    "psychiatry",
    "zoology",
    "anatomy",
    "chemistry",
    "architecture",
    "phonetics",
    "biology",
    "astronomy",
    "computing",
    "Internet",
    "baseball",
    "nautical",
    "jewelry",
    "heraldry",
}

pos_map = {
    "adj.": "adj",
    "adjective and noun": "adjective, noun",
    "n.": "n",
    "intransitive": "vi",
    "transitive": "vt",
}

recognized_pos = {
    "noun",
    "n",
    "proper noun",
    "adjective",
    "adj",
    "verb",
    "v",
    "vb",
    "adverb",
    "adv",
    "preposition",
    "prep",
    "conjunction",
    "conj",
    "verbal noun",
    "vi",
    "vt",
    "participle",
    "adjective, noun",
    "agent nouns",
    "agent noun",
    "na",
    "ni",
    "vai",
    "vii",
    "vti",
    "vta",
    "instrumental nouns",
    "instrumental noun",
    "action noun",
    "gerund",
}


def canon_qual(qual):
    if qual in label_map:
        qual = label_map[qual]
        if type(qual) is not list:
            qual = [qual]
        return qual, True
    if qual in recognized_labels:
        return [qual], True
    return [qual], False


def convert_qual_to_inline_modifier(qualtext):
    qualtext = qualtext.strip()
    if qualtext in pos_map:
        return "<pos:%s>" % pos_map[qualtext]
    if qualtext in recognized_pos:
        return "<pos:%s>" % qualtext
    output = []
    saw_label = False
    quals = re.split(" *[,/] *", qualtext)
    for qual in quals:
        qual = qual.strip()
        words = qual.split()
        while len(words) > 1:
            if words[0] in recognized_label_adverbs:
                output.append(words[0])
                words = words[1:]
            else:
                break
        qual = " ".join(words)
        qual = re.sub(r"^\{\{lg\|([^|={}]+)\}\}$", r"\1", qual)
        qual = re.sub(r"^\[\[([^|\[\]=]+)\]\]$", r"\1", qual)
        conjsplit = re.split(" +(and|or) +", qual)
        if len(conjsplit) == 3:
            first, conj, second = conjsplit
            firstcanon, first_saw_label = canon_qual(first)
            saw_label = saw_label or first_saw_label
            output.extend(firstcanon)
            output.append(conj)
            secondcanon, second_saw_label = canon_qual(second)
            saw_label = saw_label or second_saw_label
            output.extend(secondcanon)
        else:
            thiscanon, this_saw_label = canon_qual(qual)
            saw_label = saw_label or this_saw_label
            output.extend(thiscanon)
    if saw_label:
        for label in output:
            converted_labels[label] += 1
        return "<l:%s>" % ",".join(output)
    unconverted_quals[qualtext] += 1
    return "<q:%s>" % qualtext


def process_text_on_page(p):
    notes = []

    parsed = blib.parse_text(p.text)

    if args.check_qual_canon:
        for t in parsed.filter_templates():
            for param in t.params:
                pn = pname(param)
                if "qual" in pn:
                    pv = str(param.value).strip()
                    split_quals = re.split(" *[,/] *", pv)
                    for qual in split_quals:
                        all_quals[qual] += 1
                    inline_mod = convert_qual_to_inline_modifier(pv)
                    m = re.search("^<(.*?):", inline_mod)
                    if not m:
                        p.msg(
                            "WARNING: Internal error: Didn't correctly convert qualifier to inline modifier but saw %s"
                            % inline_mod
                        )
                        continue
                    modtype = m.group(1)
                    stats_by_modifier_type[modtype] += 1
                    p.msg("Converted %s=%s to %s" % (pn, pv, inline_mod))
        return
    for t in parsed.filter_templates():
        tn = tname(t)
        if tn in ["en-noun", "en-proper noun", "en-proper-noun", "en-prop", "en-propn"] and args.do_nouns:

            def getp(param):
                return getparam(t, param).strip()

            origt = str(t)
            for i in range(1, 30):
                pl = getp(str(i))
                if i == 1:
                    qualparam = "plqual"
                    plqual = getp(qualparam)
                    if not plqual:
                        qualparam = "pl1qual"
                        plqual = getp(qualparam)
                else:
                    qualparam = "pl%squal" % i
                    plqual = getp(qualparam)
                if not pl and plqual:
                    p.msg("WARNING: Missing param %s= with qualifier %s=%s" % (i, qualparam, plqual))
                elif plqual:
                    inline_mod = convert_qual_to_inline_modifier(plqual)
                    t.add(str(i), "%s%s" % (pl, inline_mod))
                    rmparam(t, qualparam)
                    notes.append("move {{en-noun}} qualifier in %s= to inline modifier on %s=" % (qualparam, i))
            if args.comma_separate_plurals:
                origt = str(t)
                plurals = []
                named_params = []
                for param in t.params:
                    pn = pname(param)
                    pv = str(param.value)
                    if re.search("^[0-9]+$", pn):
                        plurals.append(pv)
                    else:
                        named_params.append((pn, pv))
                del t.params[:]
                if plurals:
                    t.add("1", ",".join(plurals))
                    for pn, pv in named_params:
                        t.add(pn, pv, preserve_spacing=False)
                if origt != str(t):
                    notes.append("join {{en-noun}} plurals with comma and put at beginning")

        elif tn == "en-verb" and args.do_verbs:

            def getp(param):
                return getparam(t, param).strip()

            origt = str(t)
            formspecs = [
                ("1", "pres_3sg"),
                ("2", "pres_ptc"),
                ("3", "past"),
                ("4", "past_ptc"),
            ]
            if "<" in getp("1"):
                if " " in p.title:
                    par1 = getp("1")
                    origpar1 = par1
                    m = re.search("^(.*?)( .*)$", p.title)
                    first, rest = m.groups()
                    m = re.search("^%s(<.*?>)%s$" % (re.escape(first), re.escape(rest)), par1)
                    if m:
                        p.msg(
                            "Converting multiword {{en-verb}} with angle brackets modifying first word to abbreviated format: 1=%s"
                            % par1
                        )
                        t.add("1", m.group(1))
                        notes.append(
                            "convert multiword {{en-verb}} with angle brackets modifying first word to abbreviated format"
                        )
                        continue
                    m = re.search("^%s(<.*?>)%s$" % (re.escape(first), re.escape(rest)), blib.remove_links(par1))
                    if m:
                        if getp("head"):
                            p.msg(
                                "WARNING: Space in page title and apparent angle-bracket format, has head=%s, skipping, convert manually: %s"
                                % (getp("head"), origpar1)
                            )
                            continue
                        angle_bracket = m.group(1)
                        par1 = re.sub("<.*?>", "", par1)
                        headmods = []
                        must_continue = False
                        for mlink in re.finditer(r"(\[\[.*?\]\])([a-zA-Z]*)", par1):
                            link, linkafter = mlink.groups()
                            link = link[2:-2]
                            if "[" in link or "]" in link:
                                p.msg(
                                    "WARNING: Space in page title and apparent angle-bracket format, embedded brackets in link, skipping, convert manually: %s"
                                    % origpar1
                                )
                                continue
                            linkparts = link.split("|")
                            if len(linkparts) > 2:
                                p.msg(
                                    "WARNING: Space in page title and apparent angle-bracket format, too many parts in link, skipping, convert manually: %s"
                                    % origpar1
                                )
                                continue
                            if len(linkparts) == 1:
                                linkdest = link
                                linkdisp = link
                            else:
                                linkdest, linkdisp = linkparts
                            linkdisp += linkafter
                            if linkdest == linkdisp and " " not in linkdest and "-" not in linkdest:
                                continue
                            if linkdest.endswith("'s"):
                                p.msg(
                                    "WARNING: Space in page title and apparent angle-bracket format, link destination '%s' ends in apostrophe-s, may not match correctly, skipping, convert manually: 1=%s"
                                    % (linkdest, origpar1)
                                )
                                must_continue = True
                                break
                            elif linkdest == linkdisp:
                                headmods.append("%s:~" % linkdest)
                            else:
                                boundary = 0
                                for i in range(min(len(linkdest), len(linkdisp))):
                                    if linkdest[i] == linkdisp[i]:
                                        boundary = i + 1
                                    else:
                                        break
                                if boundary >= 2:
                                    headmods.append(
                                        "%s[%s:%s]" % (linkdest[0:boundary], linkdisp[boundary:], linkdest[boundary:])
                                    )
                                else:
                                    if len(linkdisp) >= 2 and linkdisp in linkdest:
                                        linkdest = linkdest.replace(linkdisp, "~")
                                    headmods.append("%s:%s" % (linkdisp, linkdest))
                        if must_continue:
                            continue
                        origt = str(t)
                        rmparam(t, "head")  # in case it's blank
                        if headmods:
                            headmods = "~" + "; ".join(headmods)
                            t.add("head", headmods, before="1")
                            rmparam(t, "1")
                            t.add("1", angle_bracket, before="head")
                        else:
                            t.add("1", angle_bracket)
                        p.msg(
                            "Replacing multiword verbal expression with single angle-bracket spec after first word %s with %s"
                            % (origt, str(t))
                        )
                        notes.append(
                            "convert multiword {{en-verb}} with angle brackets modifying first word to abbreviated format%s"
                            % " with head modifiers"
                            if headmods
                            else ""
                        )

                        p.msg(
                            "Converting multiword {{en-verb}} with angle brackets modifying first word to abbreviated format: 1=%s"
                            % par1
                        )
                        t.add("1", m.group(1))
                        notes.append(
                            "convert multiword {{en-verb}} with angle brackets modifying first word to abbreviated format"
                        )
                        continue

                    if re.search("^<.*>$", par1):
                        p.msg("Space in page title and likely already-converted angle-bracket format: 1=%s" % par1)
                    else:
                        p.msg(
                            "WARNING: Space in page title and apparent angle-bracket format not convertible automatically, may be manually convertible to abbreviated format: 1=%s"
                            % par1
                        )
                else:
                    p.msg(
                        "Skipping template already with inline modifier or angle-bracket format without space in title: %s"
                        % str(t)
                    )
                for param in t.params:
                    pn = pname(param)
                    if pn not in ["1", "head", "nolink", "nolinkhead"]:
                        p.msg(
                            "WARNING: Saw existing inline modifier or angle-bracket format with other param: %s=%s"
                            % (pn, str(param.value))
                        )
                continue
            misc_named_params = []
            for param in t.params:
                pn = pname(param)
                for formnum, formcont in formspecs:
                    if re.search("^[0-9]+$", pn) or re.search("^%s[0-9]*(_qual)?$" % formcont, pn):
                        break
                else:  # no break
                    misc_named_params.append((pn, str(param.value)))

            numbered_params = []
            for formnum, formcont in formspecs:
                forms = []
                for i in range(1, 30):
                    if i == 1:
                        valparam = formnum
                        val = getp(valparam)
                        if not val:
                            valparam = formcont + "1"
                            val = getp(valparam)
                        qualparam = formcont + "_qual"
                        qual = getp(qualparam)
                        if not qual:
                            qualparam = formcont + "1_qual"
                            qual = getp(qualparam)
                    else:
                        valparam = formcont + str(i)
                        val = getp(valparam)
                        qualparam = formcont + str(i) + "_qual"
                        qual = getp(qualparam)
                    form = val or "+"
                    if form.startswith(p.title):
                        form = "~" + form[len(p.title) :]
                    if qual:
                        inline_mod = convert_qual_to_inline_modifier(qual)
                        form += inline_mod
                    forms.append(form)
                for i in range(len(forms) - 1, 0, -1):  # don't delete first value
                    if forms[i] == "+":
                        del forms[i]
                    else:
                        break
                numbered_params.append(",".join(forms))
            for i in range(len(numbered_params) - 1, -1, -1):
                if numbered_params[i] == "+":
                    del numbered_params[i]
                else:
                    break

            del t.params[:]
            for paramno, paramval in enumerate(numbered_params):
                t.add(str(paramno + 1), paramval)
            for pn, pv in misc_named_params:
                t.add(pn, pv, preserve_spacing=False)
            notes.append("move {{en-verb}} qualifiers to inline modifiers and put named params last")

    return str(parsed), notes


parser = blib.create_argparser(
    "Convert {{en-noun}} and {{en-verb}} to use inline modifiers"
)
parser.add_argument(
    "--check-qual-canon", help="Instead of converting, canonicalize and output qualifiers", action="store_true"
)
parser.add_argument("--do-nouns", help="Convert nouns", action="store_true")
parser.add_argument(
    "--comma-separate-plurals", help="Separate plurals by comma instead of in separate params", action="store_true"
)
parser.add_argument("--do-verbs", help="Convert verbs", action="store_true")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)

if args.check_qual_canon:
    msg("%5s: %s" % ("mod", "count"))
    msg("--------------------------------------")
    for modtype, count in sorted(stats_by_modifier_type.items(), key=lambda x: -x[1]):
        msg("%5s: %s" % (modtype, count))
    msg("")
    msg("%40s: %s" % ("input qualifier", "count"))
    msg("---------------------------------------------------------------------------")
    for qual, count in sorted(all_quals.items(), key=lambda x: -x[1]):
        msg("%40s: %s" % (qual, count))
    msg("")
    msg("%40s: %s" % ("converted labels", "count"))
    msg("---------------------------------------------------------------------------")
    for label, count in sorted(converted_labels.items(), key=lambda x: -x[1]):
        msg("%40s: %s" % (label, count))
    msg("")
    msg("%40s: %s" % ("unconverted qualifiers", "count"))
    msg("---------------------------------------------------------------------------")
    for qual, count in sorted(unconverted_quals.items(), key=lambda x: -x[1]):
        msg("%40s: %s" % (qual, count))
