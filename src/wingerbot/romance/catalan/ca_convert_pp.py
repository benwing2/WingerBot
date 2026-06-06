#!/usr/bin/env python3


from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname
from wingerbot.romance.catalan.ca_convert_adj_noun import make_feminine, make_plural

old_template = "ca-pp-old"


def process_text_on_page(p):
    notes = []

    if old_template not in p.text:
        return

    p.msg("Processing")

    parsed = blib.parse_text(p.text)

    lemma = p.title

    for t in parsed.filter_templates():
        tn = tname(t)

        def getp(param):
            return getparam(t, param)

        if tn == old_template:
            origt = str(t)
            must_continue = False
            for param in t.params:
                pn = pname(param)
                pv = str(param.value)
                if pn not in ["1", "f", "feminine", "mpl", "mp", "masculine plural", "fpl", "fp", "feminine plural"]:
                    p.msg("WARNING: Saw unrecognized param %s=%s: %s" % (pn, pv, str(t)))
                    must_continue = True
                    break
            if must_continue:
                continue
            f = getp("f") or getp("feminine")
            mpl = getp("mpl") or getp("mp") or getp("masculine plural")
            fpl = getp("fpl") or getp("fp") or getp("feminine plural")
            p1 = getp("1")
            if p1 and (f or mpl or fpl):
                p.msg("WARNING: Saw both 1= and f=/mpl=/fpl=, skipping: %s" % str(t))
                continue
            if not p1 and not (f and mpl and fpl):
                p.msg("WARNING: Some of f=/mpl=/fpl= missing, skipping: %s" % str(t))
                continue
            if f.endswith("ssa") or f.endswith("na"):
                p.msg("WARNING: Feminine %s ends in -ssa or -na, can't handle yet: %s" % str(t))
                continue
            if p1:
                pass
            else:
                deff = make_feminine(lemma)
                defmpl = make_plural(lemma, "m")
                deffpl = make_plural(f, "m")
                if deff == f:
                    f = None
                if [mpl] != defmpl:
                    p.msg(
                        "WARNING: Masculine plural %s not same as default masculine plural %s, can't handle yet: %s"
                        % (mpl, ",".join(defmpl), str(t))
                    )
                    continue
                if [fpl] != deffpl:
                    p.msg(
                        "WARNING: Feminine plural %s not same as default feminine plural %s, can't handle yet: %s"
                        % (fpl, ",".join(deffpl), str(t))
                    )
                    continue
            del t.params[:]
            if f:
                t.add("1", f)
            blib.set_template_name(t, "ca-pp")
            notes.append("convert {{%s}} to new form" % old_template)
            if origt != str(t):
                p.msg("Replaced %s with %s" % (origt, str(t)))

    return str(parsed), notes


parser = blib.create_argparser(
    "Convert {{%s}} templates to new format" % old_template
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_refs=["Template:%s" % old_template]
)
