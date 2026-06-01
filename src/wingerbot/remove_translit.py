#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import msg, getparam, tname

templates_changed = {}
template_params_removed = {}
langs_with_override_translit = [
    ("hy", "Armenian"),
    ("xcl", "Old Armenian"),
    ("axm", "Middle Armenian"),
    ("ka", "Georgian"),
    ("el", "Greek"),
    ("grc", "Ancient Greek"),
    #  ("ab", "Abkhaz"),
    #  ("abq", "Abaza"),
    #  ("ady", "Adyghe"),
    #  ("av", "Avar"),
    #  ("ba", "Bashkir"),
    #  ("bo", "Tibetan"),
    #  ("bua", "Buryat"),
    #  ("ce", "Chechen"),
    #  "chm":"Eastern Mari":
    #  ("cv", "Chuvash"),
    #  ("dar", "Dargwa"),
    #  ("dv", "Dhivehi"),
    #  ("dz", "Dzongkha"),
    #  ("inh", "Ingush"),
    #  ("iu", "Inuktitut"),
    #  ("kk", "Kazakh"),
    #  ("kbd", "Kabardian"),
    #  ("kca", "Khanty"),
    #  ("kjh", "Khakas"),
    #  ("kn", "Kannada"),
    #  ("koi", "Komi-Permyak"),
    #  ("kpv", "Komi-Zyrian"),
    #  ("ky", "Kyrgyz"),
    ##  ("kv", ""), # Apparently was Komi
    #  ("lo", "Lao"),
    #  ("lbe", "Lak"),
    #  ("lez", "Lezgi"),
    #  ("lzz", "Laz"),
    #  ("mdf", "Moksha"),
    #  ("ml", "Malayalam"),
    #  ("mn", "Mongolian"),
    #  ("my", "Burmese"),
    #  ("myv", "Erzya"),
    #  ("oge", "Old Georgian"),
    #  ("os", "Ossetian"),
    #  ("sah", "Yakut"),
    #  ("si", "Sinhalese"),
    #  ("sva", "Svan"),
    #  ("ta", "Tamil"),
    #  ("tab", "Tabasaran"),
    #  ("te", "Telugu"),
    #  ("tg", "Tajik"),
    #  ("tt", "Tatar"),
    #  ("tyv", "Tuvan"),
    #  ("ug", "Uyghur"),
    #  ("udi", "Udi"),
    #  ("udm", "Udmurt"),
    #  ("xal", "Kalmyk"),
    #  ("xmf", "Mingrelian"),
]
langs_with_override_translit_map = dict(langs_with_override_translit)

remove_tr_langs = [x for x, y in langs_with_override_translit]


def has_non_western_chars(val):
    # Some Greek translits contain the following chars mixed in with
    # the Latin chars, so ignore them. Note that these are all
    # consonants and pretty much all real Greek words will have vowels
    # in them, so this is unlikely to lead to missing actual Greek
    # text.
    checkval = re.sub("[χφθβγδ]", "", val)
    return re.search("[\u0370-\u1cff\u1f00-\u1fff\u2c00-\u2c5f\u2c80-\ua6ff\ua800-\uab2f\uab70-\ufeff]", checkval)


# Remove redundant translits on one page.
def process_text_on_page(index, pagetitle, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    # Hack for grc pages where we don't want to remove the translit
    if "Ͷ" in pagetitle or "ͷ" in pagetitle:
        pagemsg("Page has Ͷ or ͷ in it, not doing")
        return

    params_removed = []
    parsed = blib.parse_text(text)
    for t in parsed.filter_templates():
        tn = tname(t)

        def getp(param):
            return getparam(t, param)

        def doparam(param, value=None):
            val = getp(param)
            if value is None:
                matches_value = not not val
            else:
                matches_value = val == value
            if matches_value:
                is_grc = tn.startswith("grc-") or getp("lang") == "grc" or getp("1") == "grc"
                has_nwc = has_non_western_chars(val)
                if val == "-":
                    pagemsg("Not removing %s=-: %s" % (param, str(t)))
                elif has_nwc and not param.startswith("tr"):
                    pagemsg(
                        "WARNING: Value %s=%s has non-Western chars in it, not removing: %s" % (param, val, str(t))
                    )
                # We don't need to do accented chars because they are normalized into
                # char with macron + combining accent; the only combined macro/accent
                # single chars are ḗ and ṓ
                elif is_grc and re.search(r"[āīūĀĪŪ]", val):
                    pagemsg(
                        "WARNING: grc and value %s=%s has long a/i/u in it, not removing: %s" % (param, val, str(t))
                    )
                elif is_grc and re.search(r"[ăĭŭĂĬŬ]", val):
                    pagemsg(
                        "WARNING: grc and value %s=%s has a/i/u with breve in it, not removing: %s"
                        % (param, val, str(t))
                    )
                else:
                    if has_nwc:
                        pagemsg(
                            "NOTE: Value %s=%s has non-Western chars but removing anyway because starts with 'tr': %s"
                            % (param, val, str(t))
                        )
                    pagemsg("Removed %s=%s: %s" % (param, val, str(t)))
                    if value is None:
                        tempparam = "%s.%s" % (tn, param)
                    else:
                        tempparam = "%s.%s=%s" % (tn, param, value)
                    params_removed.append(tempparam)
                    t.remove(param)
                    templates_changed[tn] = templates_changed.get(tn, 0) + 1
                    template_params_removed[tempparam] = template_params_removed.get(tempparam, 0) + 1

        def remove_even(upto=10):
            for i in range(2, upto, 2):
                doparam(str(i))

        def remove_odd(upto=9):
            for i in range(1, upto, 2):
                doparam(str(i))

        # (Old) Armenian declension templates
        if re.match("^xcl-noun-.*pl", tn) and tn not in [
            "xcl-noun-ն-pl",
            "xcl-noun-ն-2-pl",
            "xcl-noun-ն-3-pl",
            "xcl-noun-ո-ա-pl",
        ]:
            remove_even()
        elif tn.startswith("xcl-noun-collnum"):
            remove_even()
        elif tn in ["xcl-noun-հայր", "xcl-noun-տէր", "xcl-noun-այր", "xcl-noun-կին"]:
            remove_even()
        else:
            for start_template in ["hy-noun-", "xcl-noun-"]:
                if tn.startswith(start_template):
                    remove_odd()
        if tn in ["xcl-noun", "xcl-adj"]:
            doparam("1")
        # (Old) Armenian headword templates
        #
        # Note: The following still use the tr= parameter, but pass it to
        # {{head}}, which presumably ignores it:
        #
        # hy-particle, hy-personal_pronoun, hy-phrase, hy-postp, hy-postp-form,
        # hy-prefix, hy-proper-noun-form, hy-suffix
        #
        # xcl-adj, xcl-adj-form, xcl-adv, xcl-con, xcl-interj, xcl-noun-form,
        # xcl-numeral, xcl-particle, xcl-postp, xcl-prefix, xcl-prep, xcl-pron,
        # xcl-pron-form, xcl-proper_noun, xcl-proper-noun-form, xcl-root,
        # xcl-suffix, xcl-verb, xcl-verb-form
        if tn in [
            "hy-adj",
            "hy-adv",
            "hy-con",
            "hy-interj",
            # "hy-letter", param 1 is Armenian
            "hy-noun",
            "hy-noun-form",
            "hy-numeral",
            "hy-particle",
            "hy-personal_pronoun",
            "hy-personal pronoun",
            "hy-phrase",
            "hy-postp",
            "hy-postp-form",
            "hy-prefix",
            "hy-prep",
            "hy-pronoun",
            "hy-proper_noun",
            "hy-proper noun",
            "hy-proper-noun-form",
            "hy-proverb",
            "hy-suffix",
            "hy-verb",
            "hy-verb-form",
            # Declension templates; no xcl-decl-verb
            "hy-decl-verb",
            # Old Armenian
            # "xcl-adj" uses param 3 and 4
            "xcl-adj-form",
            "xcl-adv",
            "xcl-con",
            "xcl-interj",
            # xcl-noun uses param 3 and 4
            "xcl-noun-form",
            "xcl-numeral",
            "xcl-particle",
            "xcl-postp",
            "xcl-prefix",
            "xcl-prep",
            "xcl-pron",
            "xcl-pron-form",
            "xcl-proper_noun",
            "xcl-proper-noun-form",
            "xcl-root",
            "xcl-suffix",
            "xcl-verb",
            "xcl-verb-form",
        ]:
            remove_odd()
        # Armenian conjugation templates
        if tn.startswith("hy-conj"):
            remove_even()
        if tn.startswith("xcl-conj"):
            remove_odd()
        # Middle Armenian headword templates handled further below.
        # NOTE: axm-adj, axm-adv, axm-interj, axm-noun, axm-prefix, axm-suffix,
        # axm-verb still use the tr= parameter, but pass it to {{head}}, which
        # presumably ignores it.
        #
        # Georgian headword templates handled further below.
        # NOTE: ka-adj, ka-adv, ka-pron, ka-proper noun, ka-verb still use the
        # tr= parameter, but pass it to {{head}}, which presumably ignores it.
        #
        # Old Georgian headword templates handled further below.
        # NOTE: oge-noun and perhaps others still use the tr= parameter, but
        # pass it to {{head}}, which presumably ignores it.
        #
        # FIXME: ka-decl-noun. All even-numbered parameters (up through at least
        # 36) are translits, but are still used in the template.
        # if tn == "ka-decl-noun":
        #  remove_even(upto=38)
        #
        # Ancient Greek templates with numbered translit params
        if tn in ["grc-noun-con"]:
            doparam("5")
        if tn in ["grc-proper noun", "grc-noun"]:
            doparam("4")
        if tn in ["grc-adj-1&2", "grc-adj-1&3", "grc-part-1&3"]:
            doparam("3")
        if tn in ["grc-adj-2nd", "grc-adj-3rd", "grc-adj-2&3"]:
            doparam("2")
        if tn in ["grc-num"]:
            doparam("1")
        #
        # Handle any template beginning with hy-, xcl-, ka-, el-, grc-, etc.
        # that has a tr parameter. But don't do el-p, which uses the tr param.
        for lang in remove_tr_langs:
            if tn.startswith(lang + "-") and tn not in ["el-p"]:
                doparam("tr")
        # Suffix/prefix/affix
        if (
            tn in ["suffix", "suffix2", "prefix", "confix", "affix", "circumfix", "infix", "compound"]
            and getp("lang") in remove_tr_langs
        ):
            # Don't just do cases up through where there's a numbered param
            # because there may be holes.
            for i in range(1, 11):
                doparam("tr" + str(i))
        if (  # (tn in blib.translation_templates or tn in ["l", "m", "link", "mention", "head", "ux"]) and
            getp("1") in remove_tr_langs
        ):
            if tn == "head" and not args.do_head:
                pagemsg("Not removing tr= from {{head|...}}: %s" % str(t))
            else:
                doparam("tr")
        if getp("lang") in remove_tr_langs and tn != "borrowing":  # tn in ["term", "usex"] and
            doparam("tr")
        # Remove sc=Armn from (Old) Armenian, sc=Grek from Greek
        for langs, script in [
            (["hy", "xcl", "axm"], "Armn"),
            (["ka"], "Geor"),
            (["el"], "Grek"),
            (["grc"], "polytonic"),
            (["grc"], "Grek"),
        ]:
            if getp("1") in langs or getp("lang") in langs and tn != "borrowing":
                doparam("sc", script)

    reduced_pr = []
    for pr in params_removed:
        if reduced_pr:
            last_pr, num = reduced_pr[-1]
            if pr == last_pr:
                reduced_pr[-1] = (pr, num + 1)
                continue
        reduced_pr.append((pr, 1))
    pr_msg = ", ".join("%s(x%s)" % (pr, num) if num > 1 else pr for pr, num in reduced_pr)

    changelog = ""
    if pr_msg:
        changelog = "Remove translit/sc (%s)" % pr_msg
        pagemsg("Change log = %s" % changelog)
    return str(parsed), changelog


parser = blib.create_argparser("Remove translit, sc= from hy, xcl, ka, el, grc templates", include_pagefile=True, include_stdin=True)
parser.add_argument("--langs", default="all", help="Languages to do, a comma-separated list or 'all'")
parser.add_argument("--do-head", action="store_true", help="""Remove tr= in {{head|..}}""")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

langs = args.langs.split(",") if args.langs != "all" else remove_tr_langs
blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True,
                           default_cats=[cat for lang in langs for cat in [
                                "Terms with redundant transliterations/" + lang,
                                "Terms with manual transliterations different from the automated ones/" + lang,
                            ]])

msg("Templates processed:")
for template, count in sorted(templates_changed.items(), key=lambda x: -x[1]):
    msg("  %s = %s" % (template, count))
msg("Template params removed:")
for tpar, count in sorted(template_params_removed.items(), key=lambda x: -x[1]):
    msg("  %s = %s" % (tpar, count))
