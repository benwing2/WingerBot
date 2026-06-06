#!/usr/bin/env python3

import pywikibot, re, sys, json

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname, msg
import unicodedata

AC = "\u0301"
GR = "\u0300"

old_template_to_gender = {
    "sa-decl-noun-a-m": "m",
    "sa-decl-noun-ā-f": "f",
    "sa-decl-noun-ā": "f",
    "sa-decl-noun-a-n": "n",
    "sa-decl-noun-i-m": "m",
    "sa-decl-noun-i-f": "f",
    "sa-decl-noun-i-n": "n",
    "sa-decl-noun-u-m": "m",
    "sa-decl-noun-u-f": "f",
    "sa-decl-noun-u-n": "n",
    # "sa-decl-noun-ū": "f", already converted, has mono=
    "sa-decl-noun-ī": "f",  # has mono=
    "sa-decl-noun-ī-f": "f",  # has mono=
    "sa-decl-noun-n-n": "n",
    # "sa-decl-noun-ṛ1": "m", already converted, has r_stem_a=
    # "sa-decl-noun-ās-m": "m", already converted
    # "sa-decl-noun-ās-f": "f", already converted
    # "sa-decl-noun-as-n": "n", already converted
}


def process_text_on_page(p):
    notes = []

    if "sa-noun" not in p.text and "sa-decl-noun" not in p.text:
        return

    p.msg("Processing")

    parsed = blib.parse_text(p.text)

    headt = None
    saw_decl = False

    for t in parsed.filter_templates():
        origt = str(t)
        tn = tname(t)

        if tn == "sa-noun":
            p.msg("Saw headt=%s" % str(t))
            if headt and not saw_decl:
                p.msg("WARNING: Saw two {{sa-noun}} without {{sa-decl-noun}}: %s and %s" % (str(headt), str(t)))
            headt = t
            saw_decl = False
            continue

        if tn in ["sa-decl-noun", "sa-decl"]:
            p.msg("WARNING: Saw raw {{%s}}: %s, headt=%s" % (tn, str(t), headt and str(headt) or None))
            continue

        if tn.startswith("sa-decl-noun-"):
            p.msg("Saw declt=%s" % str(t))
            if not headt:
                p.msg("WARNING: Saw {{%s}} without {{sa-noun}}: %s" % (tn, str(t)))
                continue
            saw_decl = True

            tr = getparam(headt, "tr")
            accented_tr = False
            if not tr:
                tr = p.expand_text("{{xlit|sa|%s}}" % p.title)
                p.msg("WARNING: No translit in %s, using %s from p.title: declt=%s" % (str(headt), tr, str(t)))
            else:
                if "-" in tr:
                    p.msg(
                        "WARNING: Saw translit %s in head with hyphen: headt=%s, declt=%s" % (tr, str(headt), str(t))
                    )
                    tr = tr.replace("-", "")
                decomptr = unicodedata.normalize("NFD", tr).replace("s" + AC, "ś")
                if AC not in decomptr and GR not in decomptr:
                    p.msg(
                        "WARNING: Saw translit %s in head without accent: headt=%s, declt=%s" % (tr, str(headt), str(t))
                    )
                else:
                    accented_tr = True
            genders = blib.fetch_param_chain(headt, "g")
            genders = [g.replace("-p", "").replace("bysense", "") for g in genders]
            genders = [
                g
                for gs in genders
                for g in (["m", "f"] if gs in ["mf", "fm"] else ["m", "n"] if gs in ["mn", "nm"] else [gs])
            ]

            if tn in ["sa-decl-noun-m", "sa-decl-noun-f", "sa-decl-noun-n"]:
                tg = tn[-1]
                if tg not in genders:
                    p.msg(
                        "WARNING: Saw decl gender %s that disagrees with headword gender(s) %s: headt=%s, declt=%s"
                        % (tg, ",".join(genders), str(headt), str(t))
                    )
                    continue

                decltr = getparam(t, "1")
                if not decltr:
                    if not accented_tr:
                        p.msg(
                            "WARNING: No param in {{%s}}, replacing with unaccented tr %s from head or pagename: headt=%s, declt=%s"
                            % (tn, tr, str(headt), str(t))
                        )
                        t.add("1", tr)
                        notes.append("add (unaccented) translit %s to {{%s}}" % (tr, tn))
                    else:
                        p.msg(
                            "WARNING: No param in {{%s}}, replacing with accented tr %s from head: headt=%s, declt=%s"
                            % (tn, tr, str(headt), str(t))
                        )
                        t.add("1", tr)
                        notes.append("add accented translit %s to {{%s}}" % (tr, tn))
                elif re.search("[\u0900-\u097f]", decltr):  # translit is actually Devanagari
                    if not accented_tr:
                        p.msg(
                            "WARNING: Devanagari in {{%s}}, replacing with unaccented tr %s from head or pagename: headt=%s, declt=%s"
                            % (tn, tr, str(headt), str(t))
                        )
                        t.add("1", tr)
                        notes.append("replace Devanagari in {{%s}} with (unaccented) translit %s" % (tr, tn))
                    else:
                        p.msg(
                            "WARNING: Devanagari in {{%s}}, replacing with accented tr %s from head: headt=%s, declt=%s"
                            % (tn, tr, str(headt), str(t))
                        )
                        t.add("1", tr)
                        notes.append("replace Devanagari in {{%s}} with accented translit %s" % (tr, tn))
                else:
                    decompdecltr = unicodedata.normalize("NFD", decltr).replace("s" + AC, "ś")
                    subbed = False
                    if AC not in decompdecltr and GR not in decompdecltr:
                        if accented_tr:
                            p.msg(
                                "WARNING: Saw translit %s in decl without accent, subbing accented tr %s from head: headt=%s, declt=%s"
                                % (decltr, tr, str(headt), str(t))
                            )
                            t.add("1", tr)
                            notes.append(
                                "replace existing translit %s with accented translit %s in {{%s}}" % (decltr, tr, tn)
                            )
                            subbed = True
                        else:
                            p.msg(
                                "WARNING: Saw translit %s in decl without accent and unable to replace with accented tr from head: headt=%s, declt=%s"
                                % (decltr, str(headt), str(t))
                            )
                    if not subbed and "-" in decltr:
                        p.msg(
                            "WARNING: Saw translit %s in decl with hyphen: headt=%s, declt=%s"
                            % (decltr, str(headt), str(t))
                        )
                        notes.append("remove hyphen from existing translit %s in {{%s}}" % (decltr, tn))
                        decltr = decltr.replace("-", "")
                        t.add("1", decltr)
                        subbed = True
                    stripped_decltr = decltr.strip()
                    if "\n" not in decltr and stripped_decltr != decltr:
                        p.msg(
                            "WARNING: Saw translit '%s' in decl with extraneous space: headt=%s, declt=%s"
                            % (decltr, str(headt), str(t))
                        )
                        notes.append("remove extraneous space from existing translit '%s' in {{%s}}" % (decltr, tn))
                        decltr = stripped_decltr
                        t.add("1", decltr)
                        subbed = True
                continue

            if tn in ["sa-decl-noun-ī", "sa-decl-noun-ī-f"] and getparam(t, "mono"):
                p.msg("WARNING: Saw mono=, skipping: headt=%s, declt=%s" % (str(headt), str(t)))
                continue

            if tn in old_template_to_gender:
                must_continue = False
                for param in t.params:
                    pn = pname(param)
                    if pn not in ["1", "2", "3", "4", "n"]:
                        p.msg(
                            "WARNING: Saw unknown param %s=%s in %s: headt=%s"
                            % (pn, str(param.value), str(t), str(headt))
                        )
                        must_continue = True
                        break
                if must_continue:
                    continue

                g = old_template_to_gender[tn]
                if g not in genders:
                    p.msg(
                        "WARNING: Saw decl gender %s that disagrees with headword gender(s) %s: headt=%s, declt=%s"
                        % (g, ",".join(genders), str(headt), str(t))
                    )
                    continue

                blib.set_template_name(t, "sa-decl-noun-%s" % g)
                rmparam(t, "n")
                rmparam(t, "4")
                rmparam(t, "3")
                rmparam(t, "2")
                t.add("1", tr)
                notes.append("convert {{%s}} to {{sa-decl-noun-%s}}" % (tn, g))
            else:
                p.msg("WARNING: Saw unrecognized decl template: %s" % str(t))

        if origt != str(t):
            p.msg("Replaced %s with %s" % (origt, str(t)))

    if headt:
        p.msg("WARNING: Saw {{sa-noun}} without {{sa-decl-noun-*}}: %s" % str(headt))

    return str(parsed), notes


parser = blib.create_argparser(
    "Convert old {{sa-decl-noun-*}} templates to new ones"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_cats=["Sanskrit nouns"]
)
