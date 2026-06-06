#!/usr/bin/env python3

import re
import traceback, sys

from wingerbot import blib
from wingerbot.blib import msg, rmparam, getparam, tname, ProcessPageRetval
from wingerbot.lang_utils import AC
from wingerbot.slavic.russian.rulib import (
    velar,
    sib,
    is_stressed,
    is_unstressed,
    is_ending_stressed,
    make_unstressed_once_ru,
    make_ending_stressed_ru,
    is_monosyllabic,
    try_to_stress,
)

decl_templates = ["ru-decl-adj", "ru-adj-old"]

short_adj_cases = ["short_m", "short_f", "short_n", "short_p"]
short_adj_cases_params = [("short_m", "3"), ("short_f", "5"), ("short_n", "4"), ("short_p", "6")]

all_stress_patterns = ["a", "a'", "b", "b'", "c", "c'", "c''"]


def get_forms(result):
    forms = {}
    for formspec in re.split(r"\|", result):
        case, value = re.split(r"=", formspec, 1)
        forms[case] = value
    return forms


def get_case_forms(formval):
    forms = set()
    for form in re.split(",", formval):
        # If there are two stresses, split into two words
        if len(re.sub("[^́]", "", form)) == 2:
            wordleft = re.sub("(.*)́([^́]*)$", r"\1\2", form)  # remove right stress
            wordright = re.sub("^([^́]*)́(.*)", r"\1\2", form)  # remove left stress
            forms.add(try_to_stress(wordleft))
            forms.add(try_to_stress(wordright))
        else:
            forms.add(try_to_stress(form))
    return forms


def compare_results(p, oldt, newt):
    oldt = str(oldt)
    newt = str(newt)

    def decl_to_generate_template(declt):
        if declt.startswith("{{ru-decl-adj"):
            declt = re.sub(r"^\{\{ru-decl-adj", "{{ru-generate-adj-forms", declt)
        elif declt.startswith("{{ru-adj-old"):
            declt = re.sub(r"^\{\{ru-adj-old", "{{ru-generate-adj-forms", declt)
            declt = re.sub(r"\}\}$", "|old=y}}", declt)
        else:
            p.msg("WARNING: Unrecognized template call %s" % declt)
            return None

    oldgent = decl_to_generate_template(oldt)
    newgent = decl_to_generate_template(newt)
    if not oldgent or not newgent:
        return False
    oldresult = p.expand_text(oldgent)
    newresult = p.expand_text(newgent)
    if not oldresult or not newresult:
        return False
    old_forms = get_forms(oldresult)
    new_forms = get_forms(newresult)
    cases = set(old_forms.keys()) | set(new_forms.keys())
    ok = True
    for case in cases:
        oldval = old_forms.get(case, "-")
        newval = new_forms.get(case, "-")
        if oldval and not newval:
            p.msg("WARNING: Missing value %s=%s in new template forms" % (case, oldval))
            ok = False
        elif newval and not oldval:
            p.msg("WARNING: Extra value %s=%s in new template forms" % (case, newval))
            ok = False
        else:
            if get_case_forms(oldval) != get_case_forms(newval):
                p.msg("WARNING: For case %s, old value %s not same as new value %s" % (case, oldval, newval))
                ok = False
    return ok


def trymatch(p, t, declargs):
    orig_template = str(t)
    tn = tname(t)
    new_arg_str = "|".join(declargs)
    if new_arg_str:
        new_arg_str = "|" + new_arg_str
    new_named_params = [
        x
        for x in t.params
        if str(x.name)
        not in [
            "1",
            "2",
            "3",
            "4",
            "5",
            "6",
            "7",
            "8",
            "9",
            "10",
            "11",
            "12",
            "13",
            "14",
            "15",
            "short_m",
            "short_f",
            "short_n",
            "short_p",
        ]
    ]
    new_named_param_str = "|".join(str(x) for x in new_named_params)
    if new_named_param_str:
        new_named_param_str = "|" + new_named_param_str
    new_template = "{{%s%s%s}}" % (tn, new_arg_str, new_named_param_str)
    return compare_results(p, orig_template, new_template)


def detect_stem(stem, decl):
    if decl == "":
        m = re.search("^(.*)([ыио]́?й)$", stem)
        if not m:
            return stem, decl
        stem = m.group(1)
        decl = make_unstressed_once_ru(m.group(2))
        if re.search("[" + velar + sib + "]$", stem):
            decl = "ый"
        return stem, decl
    return stem, decl


def combine_stem(stem, decl):
    if decl == "ий":
        return stem + decl, ""
    if decl == "ый":
        if re.search("[" + velar + sib + "]$", stem):
            decl = "ий"
        return stem + decl, ""
    if decl == "ой":
        return make_unstressed_once_ru(stem) + "о́й", ""
    if decl == "ьий":
        return stem + "ий", "ь"
    return stem, decl


def infer_decl(p, t):
    if args.verbose:
        p.msg("Processing %s" % str(t))

    forms = {}

    # Initialize all cases to blank in case we don't set them again later
    for case, numparam in short_adj_cases_params:
        form = getparam(t, case) or getparam(t, numparam)
        form = form.strip()
        form = blib.remove_links(form)
        forms[case] = form

    def get_form(case):
        if forms[case] == "-":
            return ""
        return forms[case]

    m = get_form("short_m")
    f = get_form("short_f")
    n = get_form("short_n")
    pl = get_form("short_p")

    specials = ["", m]
    explicit_msg = None

    stem = getparam(t, "1")
    decl = getparam(t, "2")
    if not m and not f and not n and not pl:
        p.msg("No short forms, skipping")
        return None
    elif not m and f and n and pl:
        p.msg("Missing short masculine but other short forms present, continuing")
    elif m and not f and not n and not pl:
        p.msg("Found only short m")
        stem, decl = combine_stem(stem, decl)
        declargs = [stem, decl] + ["short_m=%s" % m]
        if trymatch(p, t, declargs):
            return declargs
        else:
            return None
    elif not m or not f or not n or not pl:
        p.msg(
            "WARNING: Some short forms missing, skipping: m=%s, f=%s, n=%s, p=%s"
            % (m or "blank", f or "blank", n or "blank", pl or "blank")
        )
        return None
    if re.search("(^|:)[abc*]", decl):
        p.msg("WARNING: Decl spec %s already has short accent class but short forms present? Skipping ...")
        return None
    if not decl:
        newstem, decl = detect_stem(stem, decl)
        if not decl:
            p.msg("WARNING: Unable to detect stem type for stem=%s" % stem)
            return None
        stem = newstem
    if decl == "short" or decl == "mixed" or decl == "ьий":
        if f or n or pl:
            p.msg(
                "WARNING: Short forms found when not allowed: f=%s, n=%s, p=%s"
                % (f or "blank", n or "blank", pl or "blank")
            )
            return None
        p.msg("Skipping decl type %s, no short forms allowed" % decl)
        return None
    if "," in m:
        p.msg("WARNING: Multiple masculine forms, something wrong: m=%s" % m)
        return None
    f2 = "," in f
    n2 = "," in n
    pl2 = "," in pl

    def get_stressed_form(form, paramname):
        if "," not in form:
            return form
        forms = re.split(r"\s*,\s*", form)
        if len(forms) > 2:
            p.msg("WARNING: More than two forms in %s=%s" % (paramname, form))
            return None
        for frm in forms:
            if not re.search(AC + "$", frm):
                return frm
        p.msg("WARNING: Multiple forms but none stem-stressed: %s=%s" % (paramname, form))
        return forms[0]

    sf = get_stressed_form(f, "f")
    if sf is None:
        return None
    sn = get_stressed_form(n, "n")
    if sn is None:
        return None
    spl = get_stressed_form(pl, "p")
    if spl is None:
        return None
    fend = re.search(AC + "$", f)
    nend = re.search(AC + "$", n)
    plend = re.search(AC + "$", pl)
    mm = re.search("^(.*)[ая]́?$", sf)
    if not mm:
        p.msg("WARNING: Unable to recognize feminine ending: %s" % sf)
        return None
    fstem = mm.group(1)
    mm = re.search("^(.*)[оеё]́?$", sn)
    if not mm:
        p.msg("WARNING: Unable to recognize neuter ending: %s" % sn)
        return None
    nstem = mm.group(1)
    mm = re.search("^(.*)[ыи]́?$", spl)
    if not mm:
        p.msg("WARNING: Unable to recognize plural ending: %s" % spl)
        return None
    plstem = mm.group(1)
    mm = re.search("^(.*?)[ъьй]?$", m)
    assert mm
    mstem = mm.group(1)
    short_stem = stem
    if is_stressed(fstem):
        short_stem = fstem
    elif is_stressed(nstem):
        short_stem = nstem
    elif is_stressed(plstem):
        short_stem = plstem
    else:
        if make_unstressed_once_ru(fstem) == make_unstressed_once_ru(mstem):
            short_stem = mstem
    if is_unstressed(stem):
        stem = make_ending_stressed_ru(stem)
    short_stem = try_to_stress(short_stem)
    if stem == short_stem:
        short_stem = ""
    elif short_stem + "н" == stem and re.search("нн[иы]й$", stem + decl):
        p.msg("Found special (2): short stem %s, long stem %s" % (short_stem, stem))
        specials = ["(2)"]
        short_stem = ""
    else:
        p.msg("WARNING: Found short stem %s different from long stem %s" % (short_stem, stem))
    real_short_stem = short_stem or stem
    if specials != ["(2)"] and mstem != real_short_stem:
        if mstem + "н" == real_short_stem and re.search("нн$", real_short_stem):
            p.msg("Found special (1): short stem %s, masculine stem %s" % (real_short_stem, mstem))
            specials = ["(1)"]
        elif make_unstressed_once_ru(stem) == mstem:
            # Can happen with monosyllabic masculines
            pass
        elif not m:
            p.msg("Missing short masculine singular")
            if real_short_stem.endswith("нн"):
                specials = ["(1)"]
            explicit_msg = "-"
        else:
            p.msg("Masculine short stem %s differs from short stem %s, presumed reducible" % (mstem, real_short_stem))
            if "(1)" in specials or "(2)" in specials:
                p.msg("WARNING: Can't have reducible and special together")
                return None
            specials = ["*", m]
    ff = f2 and "both" or fend and "end" or "stem"
    nn = n2 and "both" or nend and "end" or "stem"
    ppl = pl2 and "both" or plend and "end" or "stem"

    def match(fval, nval, plval):
        return ff == fval and nn == nval and ppl == plval

    stress = (
        match("stem", "stem", "stem")
        and "a"
        or match("both", "stem", "stem")
        and "a'"
        or match("end", "end", "end")
        and "b"
        or match("end", "end", "both")
        and "b'"
        or match("end", "stem", "stem")
        and "c"
        or match("end", "stem", "both")
        and "c'"
        or match("end", "both", "both")
        and "c''"
        or None
    )
    if "*" in specials and not is_monosyllabic(m) and ((stress in ["b", "b'"]) != (not not is_ending_stressed(m))):
        p.msg(
            "WARNING: (De)reducible short masc sg %s has wrong stress for accent pattern %s, setting manual masc sg"
            % (m, stress)
        )
        explicit_msg = m
    if not stress:
        p.msg("WARNING: Unrecognized stress: m=%s f=%s n=%s p=%s" % (m, f, n, pl))
        return None

    stem, decl = combine_stem(stem, decl)
    for special in specials:
        if special not in ["", "*", "(1)", "(2)"]:
            if explicit_msg:
                if special == explicit_msg:
                    pass
                else:
                    p.msg(
                        "WARNING: Something wrong; trying to set explicit short masc sg %s when there's an existing setting %s"
                        % (special, explicit_msg)
                    )
            else:
                explicit_msg = special
            special = ""
        special = stress + special
        declspec = special + (short_stem and (":" + short_stem) or "")
        if decl:
            declspec = decl + ":" + declspec
        declargs = [stem, declspec]
        if explicit_msg:
            declargs.append("short_m=" + explicit_msg)
        if trymatch(t, declargs, p.msg):
            return declargs
    p.msg("WARNING: Unable to infer short accent")
    return None


def _process_text_on_page(p) -> ProcessPageRetval:
    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():
        tn = tname(t)
        if tn in decl_templates:
            orig_template = str(t)
            declargs = infer_decl(t, p.msg)
            if not declargs:
                # At least combine stem and declension, blanking decl when possible.
                stem, decl = combine_stem(getparam(t, "1"), getparam(t, "2"))
                t.add("1", stem)
                t.add("2", decl)
                # Remove any trailing blank arguments.
                for i in range(15, 0, -1):
                    if not getparam(t, str(i)):
                        rmparam(t, str(i))
                    else:
                        break
                new_template = str(t)
                if orig_template != new_template:
                    if not compare_results(p, orig_template, new_template):
                        return None, None
            else:
                for i in range(15, 0, -1):
                    rmparam(t, str(i))
                rmparam(t, "short_m")
                rmparam(t, "short_f")
                rmparam(t, "short_n")
                rmparam(t, "short_p")
                t.name = tn
                i = 1
                for arg in declargs:
                    if "=" in arg:
                        name, value = re.split("=", arg)
                        t.add(name, value)
                    else:
                        t.add(i, arg)
                        i += 1
                new_template = str(t)
            if orig_template != new_template:
                if args.verbose:
                    p.msg("Replacing %s with %s" % (orig_template, new_template))

    return str(parsed), "Convert adj decl to new form and infer short-accent pattern"


def process_text_on_page(p) -> ProcessPageRetval:
    try:
        return _process_text_on_page(p)
    except Exception as e:
        p.msg("WARNING: Got an error: %s" % repr(e))
        traceback.print_exc(file=sys.stdout)


test_templates = [
    """{{ru-decl-adj|высо́к|ий|высо́к|высоко́,высо́ко|высока́|высоки́,высо́ки}}""",
    """{{ru-decl-adj|дли́нн|ый|дли́нен|длинно́|длинна́|длинны́}}""",
    """{{ru-decl-adj|ма́леньк|ий|мал|мало́|мала́|малы́}}""",
    """{{ru-decl-adj|хоро́шеньк|ий}}""",
    """{{ru-decl-adj|хоро́ш|ий|хоро́ш|хорошо́|хороша́|хороши́}}""",
    """{{ru-decl-adj|бе́л|ый|бе́л|бе́ло,бело́|бела́|бе́лы,белы́}}""",
    """{{ru-decl-adj|чёрн|ый|чёрен|черно́|черна́|черны́}}""",
    """{{ru-decl-adj|кра́тк|ий|кра́ток|кра́тко|кратка́|кра́тки}}""",
    """{{ru-decl-adj|промы́шленн|ый|промы́шленен|промы́шленно|промы́шленна|промы́шленны}}""",
    """{{ru-decl-adj|си́н|ий|синь|си́не|синя́|си́ни}}""",
    """{{ru-decl-adj|дорог|ой|до́рог|до́рого|дорога́|до́роги}}""",
    """{{ru-decl-adj|вы́спренний||вы́спрен|вы́спренне|вы́спрення|вы́спренни}}""",
    """{{ru-decl-adj|чёткий||чёток|чётко|четка́,чётка|чётки}}""",
    """{{ru-decl-adj|искушённый||искушён|искушено́|искушена́|искушени́}}""",
    """{{ru-decl-adj|дешёвый||дёшев|дёшево|дешева́|дёшевы}}""",
    # Note: The following will be inferred as b* but will fail because the
    # expected masc sing would be темён. Zaliznyak has a triangle marked by
    # the masc sing.
    """{{ru-decl-adj|тёмный||тёмен|темно́|темна́|темны́}}""",
]


def test_infer():
    for pagetext in test_templates:
        retval = process_text_on_page(blib.ProcessPageParams(args, 1, "test_infer", pagetext))
        if retval is not None:
            newtext, comment = retval
        msg("newtext = %s" % str(newtext))
        msg("comment = %s" % comment)


parser = blib.create_argparser("Convert manual Russian adjective declensions to {{ru-decl-adj}} and infer short accent pattern")
parser.add_argument("--mockup", action="store_true", help="Use mocked-up test code")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)


if args.mockup:
    test_infer()
else:
    blib.do_pagefile_cats_refs(args, start, end, process_text_on_page,
                               default_refs=["Template:%s" % template for template in decl_templates])
