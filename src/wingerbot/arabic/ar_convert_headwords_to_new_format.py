#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.arabic import arlib as ar
from wingerbot.blib import getparam, tname, pname


def default_construct_state(term):
    if term.endswith(ar.HAMZA + ar.IN):
        return term[:-2] + ar.HAMZA_ON_YAA + ar.II
    if term.endswith(ar.IN):
        return term[:-1] + ar.II
    elif term.endswith(ar.AN + ar.AMAQ):
        return term[:-2] + ar.A + ar.AMAQ
    elif term.endswith(ar.AN + ar.ALIF):
        return term[:-2] + ar.AA
    else:
        return term


def convert_inflection(t, pref, pagemsg, fetch_nominal_inflections=False, no_join=False, heads=None):
    def getp(param):
        return getparam(t, param).strip()

    outvals = []
    vals = blib.fetch_param_chain_allow_holes(t, pref)
    consvals = None
    if fetch_nominal_inflections:
        consvals = convert_inflection(t, pref + "cons", pagemsg, no_join=True)
        num_consvals = len(consvals)
        num_vals = len(vals)
        if num_consvals > 0 and num_consvals != num_vals:
            pagemsg(
                "WARNING: Saw %s value%s for %s= but %s value%s for %scons=, can't handle: %s"
                % (
                    num_vals,
                    "s" if num_vals > 1 else "",
                    pref,
                    num_consvals,
                    "s" if num_consvals > 1 else "",
                    pref,
                    str(t),
                )
            )
            return None
        for i, consval in enumerate(consvals):
            paramind = "" if i == 0 else str(i + 1)
            if consval is not None and "<" in consval:
                pagemsg("WARNING: Saw tr=/g=/g2= modifier of %scons%s=, can't handle: %s" % (paramind, pref, str(t)))
                return None
            if vals[i] is None:
                pagemsg(
                    "WARNING: No value for %s%s= but saw %scons%s=, skipping: %s"
                    % (pref, paramind, pref, paramind, str(t))
                )
                return None
            defcons = default_construct_state(vals[i])
            if defcons == consval:
                pagemsg(
                    "Construct value %scons%s=%s is the default for value %s%s=%s, removing: %s"
                    % (pref, paramind, consval, pref, paramind, vals[i], str(t))
                )
                consvals[i] = None
        # Inflections besides the construct state are rare enough and used strangely enough that we can just handle them manually.
        for suf, desc in [("obl", "oblique"), ("inf", "informal"), ("def", "definite")]:
            inflvals = convert_inflection(t, pref + suf, pagemsg, no_join=True)
            if inflvals:
                pagemsg(
                    "WARNING: Saw %s value%s for %s%s=, can't handle, skipping: %s"
                    % (len(inflvals), "s" if len(inflvals) > 1 else "", pref, suf, str(t))
                )
                return None

    for i, val in enumerate(vals, start=1):
        paramind = "" if i == 1 else str(i)
        indexed_pref = pref + paramind
        tr = getp(indexed_pref + "tr")
        g = getp(indexed_pref + "g")
        g2 = getp(indexed_pref + "g2")
        if val is None:
            if tr or g or g2:
                pagemsg(
                    "WARNING: No value for %s= but saw %str=, %sg= or %sg2=, skipping: %s"
                    % (indexed_pref, indexed_pref, indexed_pref, indexed_pref, str(t))
                )
                return None
        else:  # val not None
            if g2 and not g:
                pagemsg("WARNING: Saw %sg2= but not %sg=, skipping: %s" % (indexed_pref, indexed_pref, str(t)))
                return None
            if tr:
                val += "<tr:%s>" % tr
            if g or g2:
                genders = []
                if g:
                    genders.append(g)
                if g2:
                    genders.append(g2)
                val += "<g:%s>" % ",".join(genders)
            if not tr and not g and not g2 and pref == "cons":
                # Construct state for head; see if we can default or remove it.
                if heads and len(heads) == 1 and "<" not in heads[0]:
                    defcons = default_construct_state(heads[0])
                    if defcons == val:
                        pagemsg(
                            "Head construct value cons%s=%s is the default for value head %s, replacing with '+': %s"
                            % (paramind, val, heads[0], str(t))
                        )
                        val = "+"
            if consvals and consvals[i - 1]:
                val += "<cons:%s>" % consvals[i - 1]
            outvals.append(val)
    if outvals == ["+"]:  # head constructs specified but are defaulted
        pagemsg("Head construct values are all defaulted, removing: %s" % str(t))
        return [] if no_join else ""
    return outvals if no_join else ",".join(outvals)


def convert_head_tr_gender(t, pagemsg):
    def getp(param):
        return getparam(t, param).strip()

    outheads = []
    heads = blib.fetch_param_chain(t, "1", "head", holes="disallow")
    trs = blib.fetch_param_chain_allow_holes(t, "tr")
    genders = blib.fetch_param_chain(t, "2", "g", holes="close")
    if heads and len(trs) > len(heads):
        pagemsg(
            "WARNING: Saw %s translit%s but only %s head%s, skipping: %s"
            % (len(trs), "s" if len(trs) > 1 else "", len(heads), "s" if len(heads) > 1 else "", str(t))
        )
        return None, None
    if not heads:
        heads = ["?"] * max(1, len(trs))
    if len(heads) > len(trs):
        trs += [None] * (len(heads) - len(trs))
    outheads = []
    for head, tr in zip(heads, trs):
        if tr:
            head += "<tr:%s>" % tr
        outheads.append(head)
    return outheads, genders


def process_text_on_page(p):
    notes = []

    parsed = blib.parse_text(ar.reorder_shadda(p.text))

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
        ("cons", "construct state", True),
        ("def", "definite state", True),
        ("obl", "oblique", True),
        ("inf", "informal", True),
        ("d", "dual"),
        ("pl", "plural"),
        ("pauc", "paucal"),
        ("f", "feminine"),
        ("m", "masculine"),
        # The following only with ar-coll-noun but it doesn't matter
        ("sing", "singulative"),
        # The following only with ar-sing-noun but it doesn't matter
        ("coll", "collective"),
    ]
    adj_templates = {
        "ar-adj",
        "ar-adjective",
        "ar-adj-sound",
        "ar-adj-in",
        "ar-adj-an",
        "ar-nisba",
        "ar-act-participle",
        "ar-pass-participle",
    }
    adj_inflections = [
        ("cons", "construct state", True),
        ("def", "definite state", True),
        ("obl", "oblique", True),
        ("inf", "informal", True),
        ("f", "feminine"),
        ("d", "masculine dual"),
        ("fd", "feminine dual"),
        ("cpl", "common plural"),
        ("pl", "masculine plural"),
        ("fpl", "feminine plural"),
        # The following not with participles but it doesn't matter
        ("el", "elative"),
    ]
    noun_pl_templates = {
        "ar-noun-pl",
    }
    noun_pl_inflections = [
        ("cons", "construct state", True),
    ]
    head_gender_only_templates = {
        "ar-adj-dual",
        "ar-adj-fem",
        "ar-adj-masc",
        "ar-adj-pl",
        "ar-adv",
        "ar-adverb",
        "ar-con",
        "ar-interj",
        "ar-noun-dual",
        "ar-noun-form",
        "ar-noun-pl",
        "ar-particle",
        "ar-prep",
        "ar-preposition",
    }
    head_gender_only_inflections = []

    for t in parsed.filter_templates():
        tn = tname(t)
        if tn in noun_templates:
            inflections = noun_inflections
        elif tn in adj_templates:
            inflections = adj_inflections
        elif tn in noun_pl_templates:
            inflections = noun_inflections
        elif tn in head_gender_only_templates:
            inflections = head_gender_only_inflections
        else:
            continue

        def getp(param):
            return getparam(t, param).strip()

        origt = str(t)
        possible_inflection_prefs = []
        for inflspec in inflections:
            if len(inflspec) == 3:
                inflpref, desc, nosubinfl = inflspec
            else:
                inflpref, desc = inflspec
                nosubinfl = False
            possible_inflection_prefs.append(inflpref)
            if not nosubinfl:
                for subinfl in ["cons", "def", "obl", "inf"]:
                    possible_inflection_prefs.append(inflpref + subinfl)
        if possible_inflection_prefs:
            possible_inflection_pref_re = "^(%s)[0-9]*(tr|g|g2)?$" % "|".join(possible_inflection_prefs)
        else:
            possible_inflection_pref_re = None
        must_continue = False
        for param in t.params:
            pn = pname(param)
            if (
                pn not in ["1", "2"]
                and not re.search("^(head|g)[0-9]+$", pn)
                and not re.search("^tr[0-9]*$", pn)
                and (not possible_inflection_pref_re or not re.search(possible_inflection_pref_re, pn))
            ):
                p.msg("WARNING: Unrecognized parameter %s=%s, skipping: %s" % (pn, str(param.value), str(t)))
                must_continue = True
                break
        if must_continue:
            continue
        heads, genders = convert_head_tr_gender(t, p.msg)
        if heads is None:
            continue
        outinfls = []
        for inflspec in inflections:
            if len(inflspec) == 3:
                inflpref, desc, nosubinfl = inflspec
            else:
                inflpref, desc = inflspec
                nosubinfl = False
            converted_infl = convert_inflection(
                t, inflpref, p.msg, fetch_nominal_inflections=not nosubinfl, heads=heads
            )
            if converted_infl is None:
                must_continue = True
                break
            if converted_infl:
                outinfls.append((inflpref, converted_infl))
        if must_continue:
            continue
        del t.params[:]
        t.add("1", ",".join(heads))
        if genders:
            t.add("2", ",".join(genders))
        for inflpref, outinfl in outinfls:
            t.add(inflpref, outinfl)
        if origt != str(t):
            notes.append("Arabic headwords: join multiple items with commas and use inline modifiers for translit/etc.")

    return ar.undo_reorder_shadda(str(parsed)), notes


parser = blib.create_argparser(
    "Convert Arabic headwords to use comma-separated items and inline modifiers",
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
