#!/usr/bin/env python3

import pywikibot, re, sys

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, tname, pname

positive_ending_tags = {
    "en": [
        "str|gen|m//n|s",
        "wk//mix|gen//dat|all-gender|s",
        "str//wk//mix|acc|m|s",
        "str|dat|p",
        "wk//mix|all-case|p",
    ],
    "e": ["str//mix|nom//acc|f|s", "str|nom//acc|p", "wk|nom|all-gender|s", "wk|acc|f//n|s"],
    "er": ["str//mix|nom|m|s", "str|gen//dat|f|s", "str|gen|p"],
    "es": ["str//mix|nom//acc|n|s"],
    "em": ["str|dat|m//n|s"],
}
comparative_ending_tags = {"er" + key: [tag + "|comd" for tag in value] for key, value in positive_ending_tags.items()}
superlative_ending_tags = {"st" + key: [tag + "|supd" for tag in value] for key, value in positive_ending_tags.items()}

tags_to_ending = {"|;|".join(tags): ending for ending, tags in positive_ending_tags.items()}
tags_to_ending.update({"|;|".join(tags): ending for ending, tags in comparative_ending_tags.items()})
tags_to_ending.update({"|;|".join(tags): ending for ending, tags in superlative_ending_tags.items()})


def check_if_lemma_and_ending_match_pagetitle(lemma, ending, pagetitle, allow_umlaut):
    no_explicit = False
    if lemma + ending == pagetitle:
        no_explicit = True
    if not no_explicit and re.search("e[mnlr]$", lemma) and lemma[0:-2] + lemma[-1] + ending == pagetitle:
        # simpel -> simplen
        no_explicit = True
    if not no_explicit and lemma + "e" + ending == pagetitle:
        # flott -> flottesten, barsch -> barschesten, betagt -> betagtesten,
        # herzlos -> herzlosesten, frohgemut -> frohgemutesten,
        # amyloid -> amyloidesten, erdnah -> erdnahesten, and others
        # unpredictably
        no_explicit = True
    if not no_explicit and lemma.endswith("e") and lemma[:-1] + ending == pagetitle:
        # bitweise -> bitweisen
        no_explicit = True
    if not no_explicit and re.search("[^aeiouy][aeiouy][^aeiouy]$", lemma):
        # fit -> fitten, fit -> fittesten
        if lemma + lemma[-1] + ending == pagetitle:
            no_explicit = True
        if not no_explicit and lemma + lemma[-1] + "e" + ending == pagetitle:
            no_explicit = True
    if not no_explicit and allow_umlaut:
        m = re.search("^(.*?)(au|[aou])([^aeiouy]+)$", lemma)
        if m:
            # Umlautable adjectives: nass -> nässeren, gesund -> gesünderen, geraum -> geräumeren
            umlauts = {"a": "ä", "o": "ö", "u": "ü", "au": "äu"}
            umlauted_lemma = m.group(1) + umlauts[m.group(2)] + m.group(3)
            if umlauted_lemma + ending == pagetitle:
                no_explicit = True
            # Add -e in case of nass -> nässesten
            if not no_explicit and umlauted_lemma + "e" + ending == pagetitle:
                no_explicit = True
    return no_explicit


def process_text_on_page(p):
    if not re.search(r"\{\{head\|de\|(adjective (|comparative |superlative )|participle )form", p.text):
        return

    p.msg("Processing")

    notes = []

    modsec = blib.find_modifiable_lang_section(p.text, "German", p.msg)
    if modsec is None:
        return
    secbody = modsec.secbody

    if re.search("== *Etymology 1 *==", secbody):
        p.msg("WARNING: Multiple etymology sections, skipping")
        return

    parsed = blib.parse_text(secbody)

    headt = None
    comparative_of_t = None
    superlative_of_t = None
    inflection_of_t = None
    need_superlative_of_t_lemma = None
    for t in parsed.filter_templates():
        origt = str(t)
        tn = tname(t)

        def do_comparative_superlative_of(pos, existing_t, should_end):
            if getparam(t, "1") != "de":
                p.msg("WARNING: Saw wrong language in {{%s of}}, skipping: %s" % (pos, origt))
                return False
            if existing_t:
                p.msg("WARNING: Saw two {{%s of}} templates, skipping: %s and %s" % (pos, str(existing_t), origt))
                return False
            if not headt:
                p.msg("WARNING: Saw {{%s of}} without head template, skipping: %s" % (pos, origt))
                return False
            if not p.title.endswith(should_end):
                p.msg("WARNING: Incorrect ending for %s, should be -%s, skipping" % (pos, should_end))
                return False
            param2 = getparam(headt, "2")
            if param2 != "%s adjective" % pos:
                headt.add("2", "%s adjective" % pos)
                notes.append("convert {{head|de|%s}} to {{head|de|%s adjective}}" % (param2, pos))
            return t

        if (
            tn == "head"
            and getparam(t, "1") == "de"
            and getparam(t, "2")
            in ["adjective form", "adjective comparative form", "adjective superlative form", "participle form"]
        ):
            if headt:
                p.msg("WARNING: Saw two head templates, skipping: %s and %s" % (str(headt), origt))
                return
            headt = t
        elif tn == "head" and getparam(t, "1") == "de" and getparam(t, "2") == "verb form":
            p.msg("Allowing and ignoring {{head|de|verb form}}: %s" % origt)
        elif tn == "head":
            p.msg("WARNING: Saw unrecognized head template, skipping: %s" % origt)
            return
        elif tn == "comparative of":
            comparative_of_t = do_comparative_superlative_of("comparative", comparative_of_t, "er")
            if not comparative_of_t:
                return
        elif tn == "superlative of":
            superlative_of_t = do_comparative_superlative_of("superlative", superlative_of_t, "sten")
            if not superlative_of_t:
                return
        elif tn == "de-adj form of":
            p.msg("Saw {{de-adj form of}}, assuming already converted: %s" % origt)
            return
        elif tn in ["inflection of", "infl of"]:
            if getparam(t, "1") != "de":
                p.msg("WARNING: Saw wrong language in {{inflection of}}, skipping: %s" % origt)
                return
            if not headt:
                p.msg("WARNING: Saw {{inflection of}} without head template, skipping: %s" % origt)
                return
            if inflection_of_t:
                p.msg("WARNING: Saw {{inflection of}} twice, skipping: %s and %s" % (str(inflection_of_t), origt))
                return
            inflection_of_t = t
            lemma = getparam(t, "2")
            if getparam(t, "3"):
                p.msg("WARNING: Saw alt form in {{inflection of}}, skipping: %s" % origt)
                return
            infl_tags = []
            for param in t.params:
                pn = pname(param)
                pv = str(param.value)
                if not re.search("^[0-9]+$", pn):
                    p.msg(
                        "WARNING: Saw unrecognized param %s=%s in {{inflection of}}, skipping: %s" % (pn, pv, origt)
                    )
                    return
                if int(pn) >= 4:
                    infl_tags.append(pv)
            tags = "|".join(infl_tags)
            if tags not in tags_to_ending:
                p.msg("WARNING: Saw unrecognized tags in {{inflection of}}, skipping: %s" % origt)
                return
            del t.params[:]
            ending = tags_to_ending[tags]
            if ending in ["sten", "esten"]:
                need_superlative_of_t_lemma = lemma
            blib.set_template_name(t, "de-adj form of")
            t.add("1", lemma)

            no_explicit = check_if_lemma_and_ending_match_pagetitle(lemma, ending, p.title, allow_umlaut=True)
            if not no_explicit:
                p.msg("WARNING: Explicit ending %s required for lemma %s" % (ending, lemma))
                t.add("2", ending)
            notes.append("convert {{inflection of|de|...}} to {{de-adj form of}}")
            if "comd" in tags:
                param2 = getparam(headt, "2")
                if param2 != "comparative adjective form":
                    headt.add("2", "comparative adjective form")
                    notes.append("convert {{head|de|%s}} to {{head|de|comparative adjective form}}" % param2)
            elif "supd" in tags:
                param2 = getparam(headt, "2")
                if param2 != "superlative adjective form":
                    headt.add("2", "superlative adjective form")
                    notes.append("convert {{head|de|%s}} to {{head|de|superlative adjective form}}" % param2)

    secbody = str(parsed)

    def add_adj_form_of(secbody, pos, comparative_superlative_t, ending):
        lemma = getparam(comparative_superlative_t, "2")
        if check_if_lemma_and_ending_match_pagetitle(lemma, ending, p.title, allow_umlaut=False):
            form_pos = "superlative adjective form" if pos == "superlative" else "adjective form"
            newsec = """

===Adjective===
{{head|de|%s}}

# {{de-adj form of|%s}}""" % (
                form_pos,
                lemma,
            )
            secbody, replaced = blib.replace_in_text(
                secbody,
                str(comparative_superlative_t),
                str(comparative_superlative_t) + newsec,
                p.msg,
                abort_if_warning=True,
            )
            if not replaced:
                p.msg("WARNING: Couldn't add -%s inflection, skipping: %s" % (ending, str(comparative_of_t)))
                return secbody, False
            notes.append("add {{de-adj form of}} for %s" % pos)
        else:
            p.msg("WARNING: Lemma %s + %s ending %s doesn't match pagetitle" % (lemma, pos, ending))
        return secbody, True

    if comparative_of_t and not inflection_of_t:
        secbody, ok = add_adj_form_of(secbody, "comparative", comparative_of_t, "er")
        if not ok:
            return

    if superlative_of_t and not inflection_of_t:
        secbody, ok = add_adj_form_of(secbody, "superlative", superlative_of_t, "sten")
        if not ok:
            return

    if inflection_of_t and not superlative_of_t and need_superlative_of_t_lemma:
        cursec = """===Adjective===
{{head|de|superlative adjective form}}

# %s""" % str(
            inflection_of_t
        )
        newsec = (
            """===Adjective===
{{head|de|superlative adjective}}

# {{superlative of|de|%s}}

"""
            % need_superlative_of_t_lemma
        )
        secbody, replaced = blib.replace_in_text(secbody, cursec, newsec + cursec, p.msg, abort_if_warning=True)
        if not replaced:
            p.msg("WARNING: Couldn't add {{superlative of}}, skipping: %s" % str(inflection_of_t))
            return
        notes.append("add {{superlative of|de|...}}")

    if not notes:
        p.msg("WARNING: Couldn't convert page")

    return modsec.rebuild(secbody=secbody), notes


parser = blib.create_argparser(
    "Replace {{inflection of}} with {{de-adj form of}} in German adjective forms",
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    default_cats=["German adjective forms", "German adjective comparative forms", "German adjective superlative forms"],
)
