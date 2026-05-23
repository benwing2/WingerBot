#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.arabic import arlib as ar
from wingerbot.blib import getparam, rmparam, tname, pname, msg, site


class BadTranslitException(Exception):
    pass


class ContinueException(Exception):
    pass


def check_tr_ending(tr, expected, replacement):
    if not tr:
        return tr
    if tr.endswith(expected):
        tr = tr[: -len(expected)] + replacement
        return tr
    raise BadTranslitException("WARNING: Translit '%s' doesn't end in '-%s'" % (tr, expected))


def default_feminine(term, tr):
    if term.endswith(ar.AN + ar.AMAQ) or term.endswith(ar.AN + ar.ALIF):
        term = term[:-2] + ar.AAH
        tr = check_tr_ending(tr, "an", "āh")
    elif term.endswith(ar.HAMZA + ar.IN):
        term = term[:-2] + ar.HAMZA_ON_YAA + ar.IYAH
        tr = check_tr_ending(tr, "in", "iya")
    elif term.endswith(ar.IN):
        term = term[:-1] + ar.IYAH
        tr = check_tr_ending(tr, "in", "iya")
    else:
        term += ar.AH
        tr = tr + "a" if tr else tr
    return term, tr


def default_masculine_plural(term, tr):
    if term.endswith(ar.AN + ar.AMAQ) or term.endswith(ar.AN + ar.ALIF):
        term = term[:-2] + ar.AWN
        tr = check_tr_ending(tr, "an", "awn")
    elif term.endswith(ar.HAMZA + ar.IN):
        term = term[:-2] + ar.HAMZA_ON_WAW + ar.UUN
        tr = check_tr_ending(tr, "in", "ūn")
    elif term.endswith(ar.IN):
        term = term[:-1] + ar.UUN
        tr = check_tr_ending(tr, "in", "ūn")
    else:
        term += ar.UUN
        tr = tr + "ūn" if tr else tr
    return term, tr


def default_feminine_plural(term, tr):
    # صَلَاة pl. صَلَوَات and أَدَاة pl. أَدَوَات and similar; but نَوَاة and وَفَاة with a و in them become نَوَيَات and وَفَيَات;
    # and longer terms like مُبَارَاة and كُمَّثْرَاة invariably form their plural in -يَات.
    m = re.search("^([^و]" + ar.A + "[^و])" + ar.AAH + "$", term)
    if m:
        term = m.group(1) + ar.A + ar.W + ar.AAT
        tr = check_tr_ending(tr, "āh", "awāt")
        return term, tr
    if term.endswith(ar.AAH):
        term = term[:-3] + ar.AYAAT
        tr = check_tr_ending(tr, "āh", "ayāt")
    elif term.endswith(ar.AN + ar.AMAQ) or term.endswith(ar.AN + ar.ALIF):
        term = term[:-2] + ar.AYAAT
        tr = check_tr_ending(tr, "an", "ayāt")
    elif term.endswith(ar.HAMZA + ar.IN):
        term = term[:-2] + ar.HAMZA_ON_YAA + ar.IYAAT
        tr = check_tr_ending(tr, "in", "iyāt")
    elif term.endswith(ar.IN):
        term = term[:-1] + ar.IYAAT
        tr = check_tr_ending(tr, "in", "iyāt")
    elif term.endswith(ar.AH):
        term = term[:-2] + ar.AAT
        tr = check_tr_ending(tr, "a", "āt")
    else:
        term += ar.AAT
        tr = tr + "āt" if tr else tr
    return term, tr


def default_masculine_dual(term, tr):
    if term.endswith(ar.AN + ar.AMAQ) or term.endswith(ar.AN + ar.ALIF):
        term = term[:-2] + ar.AYAAN
        tr = check_tr_ending(tr, "an", "ayān")
    elif term.endswith(ar.HAMZA + ar.IN):
        term = term[:-2] + ar.HAMZA_ON_YAA + ar.IYAAN
        tr = check_tr_ending(tr, "in", "iyān")
    elif term.endswith(ar.IN):
        term = term[:-1] + ar.IYAAN
        tr = check_tr_ending(tr, "in", "iyān")
    else:
        term += ar.AAN
        tr = tr + "ān" if tr else tr
    return term, tr


def default_feminine_dual(term, tr):
    if term.endswith(ar.AN + ar.AMAQ) or term.endswith(ar.AN + ar.ALIF):
        term = term[:-2] + ar.AATAAN
        tr = check_tr_ending(tr, "an", "ātān")
    elif term.endswith(ar.HAMZA + ar.IN):
        term = term[:-2] + ar.HAMZA_ON_YAA + ar.IY + ar.ATAAN
        tr = check_tr_ending(tr, "in", "iyatān")
    elif term.endswith(ar.IN):
        term = term[:-1] + ar.IY + ar.ATAAN
        tr = check_tr_ending(tr, "in", "iyatān")
    else:
        term += ar.ATAAN
        tr = tr + "atān" if tr else tr
    return term, tr


def default_masculine(term, tr):
    if term.endswith(ar.Y + ar.AAH):
        # tall alif substitutes for alif maqṣūra after a yāʔ
        term = term[:-3] + ar.AN + ar.ALIF
        tr = check_tr_ending(tr, "āh", "an")
    elif term.endswith(ar.AAH):
        term = term[:-3] + ar.AN + ar.AMAQ
        tr = check_tr_ending(tr, "āh", "an")
    elif term.endswith(ar.ALIF + ar.HAMZA_ON_YAA + ar.IYAH):
        # handle the common case of final-weak feminine active participle with preceding hamza;
        # the hamza-on-yāʔ always converts back to hamza on the line when preceded by ā (alif) but
        # may not otherwise, so we just leave it alone in that case
        term = term[:-5] + ar.HAMZA + ar.IN
        tr = check_tr_ending(tr, "iya", "in")
    elif term.endswith(ar.IYAH):
        term = term[:-4] + ar.IN
        tr = check_tr_ending(tr, "iya", "in")
    elif term.endswith(ar.AH):
        term = term[:-2]
        tr = check_tr_ending(tr, "a", "")
    return term, tr


def default_common_plural(term, tr):
    # Common plural has no default currently but we still want to replace ~ if possible.
    return None, None


def canonicalize_form(term, tr):
    if term.endswith(ar.AAN + ar.I):
        term = term[:-1]
        tr = check_tr_ending(tr, "i", "")
    elif term.endswith(ar.UUN + ar.A):
        term = term[:-1]
        tr = check_tr_ending(tr, "a", "")
    elif term.endswith(ar.AWN + ar.A):
        term = term[:-1]
        tr = check_tr_ending(tr, "a", "")
    elif term.endswith(ar.AAT + ar.UN):
        term = term[:-1]
        tr = check_tr_ending(tr, "un", "")
    elif (
        term.endswith(ar.TAM)
        and not term.endswith(ar.AH)
        and not term.endswith(ar.ALIF + ar.TAM)
        and not term.endswith(ar.AMAD + ar.TAM)
    ):
        term = term[:-1] + ar.AH
    elif term.endswith(ar.ALIF + ar.TAM) and not term.endswith(ar.AAH):
        term = term[:-2] + ar.AAH
    return term, tr


def parse_term_with_tr(termspec):
    # split on comma but not inside of <...>
    segs = blib.parse_balanced_segment_run(termspec, "<", ">")
    term = segs[0]
    tr = None
    other_mods = []
    for k in range(2, len(segs), 2):
        if segs[k]:
            raise BadTranslitException("WARNING: Junk at position %s=%s in %s" % (k, segs[k], termspec))
    for k in range(1, len(segs), 2):
        seg = segs[k]
        if seg.startswith("<tr:"):
            if tr is not None:
                raise BadTranslitException(
                    "WARNING: Saw <tr:...> twice at position %s=%s in %s" % (k, segs[k], termspec)
                )
            tr = seg[4:-1]
        else:
            other_mods.append(seg)
    return term, tr, "".join(other_mods)


def make_term_tr(term, tr, other_mods):
    if tr:
        return "%s<tr:%s>%s" % (term, tr, other_mods)
    else:
        return term + other_mods


def process_text_on_page(index, pagetitle, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    notes = []

    parsed = blib.parse_text(ar.reorder_shadda(text))

    noun_templates = {
        "ar-noun",
        "ar-proper noun",
        "ar-prop",
        "ar-coll-noun",
        "ar-sing-noun",
        "ar-noun-nisba",
        "ar-noun-sound",
        # ar-numeral uses noun inflections and ar-pron(oun) uses a subset of noun inflections
        "ar-numeral",
        "ar-pron",
        "ar-pronoun",
    }
    noun_inflections = [
        ("d", "dual", lambda g: default_feminine_dual if g == "f" else default_masculine_dual),
        (
            "pl",
            "plural",
            lambda g: (
                default_feminine_plural
                if g == "f"
                else [("+", default_masculine_plural), ("+f", default_feminine_plural)]
            ),
        ),
        ("f", "feminine", lambda g: default_feminine),
        ("m", "masculine", lambda g: default_masculine),
        ("sing", "singulative", lambda g: default_feminine),
        ("coll", "collective", lambda g: default_masculine),
        ("pauc", "paucal", lambda g: default_feminine_plural),
    ]
    adj_templates = {
        "ar-adj",
        "ar-act-participle",
        "ar-pass-participle",
    }
    adj_inflections = [
        ("f", "feminine", default_feminine),
        ("d", "masculine dual", default_masculine_dual),
        ("fd", "feminine dual", default_feminine_dual),
        ("pl", "masculine plural", default_masculine_plural),
        ("fpl", "feminine plural", default_feminine_plural),
        ("cpl", "common plural", default_common_plural),
    ]

    for t in parsed.filter_templates():
        try:
            tn = tname(t)

            def getp(param):
                return getparam(t, param).strip()

            if tn in noun_templates:
                inflections = noun_inflections
                genders = getp("2")
                if not genders:
                    if tn in ["ar-coll-noun", "ar-noun-nisba", "ar-noun-sound"]:
                        genders = "m"
                    elif tn == "ar-sing-noun":
                        genders = "f"
                if genders not in ["f", "m"]:
                    pagemsg("WARNING: Gender 2=%s not f or m, skipping: %s" % (genders, str(t)))
                    continue
            elif tn in adj_templates:
                inflections = adj_inflections
                genders = None
            else:
                ar_head_pos = None
                if tn in ["ar-noun-pl", "ar-noun-dual", "ar-noun-form"]:
                    ar_head_pos = "nounf"
                elif tn in ["ar-adj-pl", "ar-adj-fem", "ar-adj-dual", "ar-adj-form"]:
                    ar_head_pos = "adjf"
                if ar_head_pos:
                    head = getp("1")
                    gender = getp("2")
                    t.add("1", ar_head_pos)
                    t.add("2", head)
                    if gender:
                        t.add("3", gender)
                    blib.set_template_name(t, "ar-head")
                    pagemsg("Convert {{%s}} to {{ar-head|%s}}" % (tn, ar_head_pos))
                    notes.append("convert {{%s}} to {{ar-head|%s}}" % (tn, ar_head_pos))
                continue
            origt = str(t)
            orighead = getp("1")
            # split on comma but not inside of <...>
            headsegs = blib.parse_balanced_segment_run(orighead, "<", ">")
            split_headsegs = blib.split_alternating_runs(headsegs, ",")
            heads = ["".join(run) for run in split_headsegs]
            parsed_heads = []
            for head in heads:
                headterm, headtr, headother = parse_term_with_tr(head)
                if headterm is None:
                    pagemsg("WARNING: Couldn't parse term and translit in head=%s: %s" % (head, str(t)))
                    raise ContinueException()
                parsed_heads.append((headterm, headtr, headother))
            for inflspec in inflections:
                field, desc, default_fns = inflspec
                if genders:
                    default_fns = default_fns(genders)
                if callable(default_fns):
                    default_fns = [("+", default_fns)]
                for plus_symbol, default_fn in default_fns:
                    val = getp(field)
                    if val:
                        # split on comma but not inside of <...>
                        segs = blib.parse_balanced_segment_run(val, "<", ">")
                        split_segs = blib.split_alternating_runs(segs, ",")
                        segs = ["".join(run) for run in split_segs]
                        newsegs = []
                        defaults = []
                        for headterm, headtr, headother in parsed_heads:
                            defterm, deftr = default_fn(headterm, headtr)
                            defaults.append((defterm, deftr))
                        if len(defaults) == 1:
                            def_segterm, def_segtr = defaults[0]
                            headterm, headtr, headother = parsed_heads[0]
                            headspec = make_term_tr(headterm, headtr, headother)
                            for seg in segs:
                                segterm, segtr, segother = parse_term_with_tr(seg)
                                if segterm is None:
                                    pagemsg(
                                        "WARNING: Couldn't parse term and translit in %s=%s: %s" % (field, seg, str(t))
                                    )
                                    raise ContinueException()
                                canon_segterm, canon_segtr = canonicalize_form(segterm, segtr)
                                canonseg = make_term_tr(canon_segterm, canon_segtr, segother)
                                if canon_segterm != segterm or canon_segtr != segtr:
                                    pagemsg("Canonicalized %s=%s to %s: %s" % (field, seg, canonseg, str(t)))
                                if def_segterm == canon_segterm and def_segtr == canon_segtr:
                                    pagemsg("Replaced %s=%s with %s: %s" % (field, canonseg, plus_symbol, str(t)))
                                    newsegs.append(plus_symbol + segother)
                                    notes.append(
                                        "replace %s=%s with %s%s in {{%s}}" % (field, seg, plus_symbol, segother, tn)
                                    )
                                elif seg == headspec:
                                    pagemsg("Replaced %s=%s with ~, standing for the head: %s" % (field, seg, str(t)))
                                    newsegs.append("~")
                                    notes.append("replace %s=%s with ~ in {{%s}}" % (field, seg, tn))
                                elif canon_segterm != segterm or canon_segtr != segtr:
                                    notes.append("canonicalize %s=%s to %s in {{%s}}" % (field, seg, canonseg, tn))
                                    newsegs.append(canonseg)
                                else:
                                    newsegs.append(seg)
                        else:
                            canon_segs = []
                            orig_segs = []
                            for seg in segs:
                                segterm, segtr, segother = parse_term_with_tr(seg)
                                if segterm is None:
                                    pagemsg(
                                        "WARNING: Couldn't parse term and translit in %s=%s: %s" % (field, seg, str(t))
                                    )
                                    raise ContinueException()
                                canon_segterm, canon_segtr = canonicalize_form(segterm, segtr)
                                canon_segs.append((canon_segterm, canon_segtr))
                                orig_segs.append((segterm, segtr, segother))
                                canonseg = make_term_tr(canon_segterm, canon_segtr, segother)
                                if canon_segterm != segterm or canon_segtr != segtr:
                                    pagemsg("Canonicalized %s=%s to %s: %s" % (field, seg, canonseg, str(t)))
                            if set(defaults) <= set(canon_segs):
                                saw_plus = False
                                for (canon_segterm, canon_segtr), (segterm, segtr, segother) in zip(
                                    canon_segs, orig_segs
                                ):
                                    seg = make_term_tr(segterm, segtr, segother)
                                    canonseg = make_term_tr(canon_segterm, canon_segtr, segother)
                                    if (canon_segterm, canon_segtr) in defaults:
                                        if not saw_plus:
                                            pagemsg(
                                                "Replaced %s=%s with %s: %s" % (field, canonseg, plus_symbol, str(t))
                                            )
                                            newsegs.append(plus_symbol + segother)
                                            notes.append(
                                                "replace %s=%s with %s%s in {{%s}}"
                                                % (field, seg, plus_symbol, segother, tn)
                                            )
                                            saw_plus = True
                                    elif canon_segterm != segterm or canon_segtr != segtr:
                                        notes.append("canonicalize %s=%s to %s in {{%s}}" % (field, seg, canonseg, tn))
                                        newsegs.append(canonseg)
                                    else:
                                        newsegs.append(seg)
                            elif set(parsed_heads) <= set(orig_segs):
                                saw_tilde = False
                                for (canon_segterm, canon_segtr), (segterm, segtr, segother) in zip(
                                    canon_segs, orig_segs
                                ):
                                    seg = make_term_tr(segterm, segtr, segother)
                                    canonseg = make_term_tr(canon_segterm, canon_segtr, segother)
                                    if (segterm, segtr, segother) in parsed_heads:
                                        if not saw_tilde:
                                            pagemsg("Replaced %s=%s with ~: %s" % (field, seg, str(t)))
                                            newsegs.append("~")
                                            notes.append("replace %s=%s with ~ in {{%s}}" % (field, seg, tn))
                                            saw_tilde = True
                                    elif canon_segterm != segterm or canon_segtr != segtr:
                                        notes.append("canonicalize %s=%s to %s in {{%s}}" % (field, seg, canonseg, tn))
                                        newsegs.append(canonseg)
                                    else:
                                        newsegs.append(seg)
                            else:
                                for (canon_segterm, canon_segtr), (segterm, segtr, segother) in zip(
                                    canon_segs, orig_segs
                                ):
                                    seg = make_term_tr(segterm, segtr, segother)
                                    canonseg = make_term_tr(canon_segterm, canon_segtr, segother)
                                    if canon_segterm != segterm or canon_segtr != segtr:
                                        notes.append("canonicalize %s=%s to %s in {{%s}}" % (field, seg, canonseg, tn))
                                        newsegs.append(canonseg)
                                    else:
                                        newsegs.append(seg)
                        t.add(field, ",".join(newsegs))

            if tn == "ar-adj":
                f = getp("f")
                pl = getp("pl")
                fpl = getp("fpl")
                if f == "+" or pl == "+" or fpl == "+":
                    if pl and fpl:
                        origt = str(t)
                        if f == "+":
                            rmparam(t, "f")
                        if pl == "+":
                            rmparam(t, "pl")
                        if fpl == "+":
                            rmparam(t, "fpl")
                        blib.set_template_name(t, "ar-adj+")
                        pagemsg("Replace %s with auto-defaulting %s" % (origt, str(t)))
                        notes.append("replace {{ar-adj}} with auto-defaulting {{ar-adj+}}, removing defaulted values")
                    elif not fpl:
                        if pl:
                            pagemsg(
                                "NOTE: Would replace {{ar-adj}} with auto-defaulting {{ar-adj+}} but feminine plural is missing: %s"
                                % str(t)
                            )
                        else:
                            pagemsg(
                                "NOTE: Would replace {{ar-adj}} with auto-defaulting {{ar-adj+}} but masculine and feminine plural are missing: %s"
                                % str(t)
                            )

            if tn in ["ar-noun-nisba", "ar-noun-sound"]:
                subnotes = []
                gender = getp("2")
                if not gender:
                    param_after_1 = blib.find_following_param(t, "1")
                    t.add("2", "m", before=param_after_1)
                    subnotes.append("add 2=m")
                if getp("pl") == "+":
                    rmparam(t, "pl")
                    subnotes.append("remove redundant plural")
                if getp("f") == "+":
                    rmparam(t, "f")
                    subnotes.append("remove redundant feminine")
                blib.set_template_name(t, "ar-noun+")
                subnote_text = "; " + ", ".join(subnotes) if subnotes else ""
                pagemsg("Convert {{%s}} to {{ar-noun+}}%s" % (tn, subnote_text))
                notes.append("convert {{%s}} to {{ar-noun+}}%s" % (tn, subnote_text))

            if (
                tn == "ar-noun"
                and getp("pl")
                and (genders == "m" and getp("f") == "+" or genders == "f" and getp("m") == "+")
            ):
                subnotes = []
                if getp("pl") == "+":
                    rmparam(t, "pl")
                    subnotes.append("remove redundant plural")
                if genders == "m" and getp("f") == "+":
                    rmparam(t, "f")
                    subnotes.append("remove redundant feminine")
                if genders == "f" and getp("m") == "+":
                    rmparam(t, "m")
                    subnotes.append("remove redundant masculine")
                blib.set_template_name(t, "ar-noun+")
                subnote_text = "; " + ", ".join(subnotes) if subnotes else ""
                pagemsg("Convert {{ar-noun}} to {{ar-noun+}}%s" % subnote_text)
                notes.append("convert {{ar-noun}} to {{ar-noun+}}%s" % subnote_text)

            if getp("d") == "+":
                pagemsg("Removing redundant d=+: %s" % str(t))
                rmparam(t, "d")
                notes.append("remove redundant d=+")
            if getp("fd") == "+":
                pagemsg("Removing redundant fd=+: %s" % str(t))
                rmparam(t, "fd")
                notes.append("remove redundant fd=+")

        except BadTranslitException as e:
            pagemsg("%s: %s" % (str(e), str(t)))
            continue
        except ContinueException as ce:
            continue

    return ar.undo_reorder_shadda(str(parsed)), notes


parser = blib.create_argparser(
    "Convert Arabic headwords to use + for default", include_pagefile=True, include_stdin=True
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True)
