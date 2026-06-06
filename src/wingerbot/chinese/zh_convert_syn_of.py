#!/usr/bin/env python3

import pywikibot, re, sys, unicodedata

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname, msg


def process_text_on_page(p):
    notes = []

    replacements = []
    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():

        def getp(param):
            return getparam(t, param)

        tn = tname(t)
        repl = None
        if tn in ["zh-synonym of", "zh-synonym", "zh-syn of"]:
            repl = "syn of"
        elif tn in ["zh-alt form", "zh-alt-form"]:
            repl = "alt form"
        if repl:
            term = getp("1")
            nosimp = False
            if term.startswith("*"):
                p.msg("Saw term '%s' starting with an asterisk: %s" % (term, str(t)))
                term = term[1:]
                nosimp = True
            if term.endswith("*"):
                p.msg("Saw term '%s' ending with an asterisk: %s" % (term, str(t)))
                term = term[:-1]
                nosimp = True
            if "<!--" in term or "-->" in term:
                p.msg("WARNING: Saw term '%s' with comment, needs manual handling: %s" % (term, str(t)))
            elif "/" in term:
                p.msg("WARNING: Saw term '%s' with slash, needs manual handling: %s" % (term, str(t)))
            elif "^" in term:
                p.msg("WARNING: Saw term '%s' with circumflex, needs manual handling: %s" % (term, str(t)))
            else:
                tr = getp("tr")
                gloss = getp("2") or getp("t") or getp("gloss")
                nocap = getp("nocap")
                dot = getp("dot")
                must_continue = False
                for param in t.params:
                    ok = False
                    pn = pname(param)
                    if pn not in ["1", "2", "t", "gloss", "tr", "nocap", "dot"]:
                        p.msg("WARNING: Saw unrecognized param %s=%s in %s" % (pn, str(param.value), str(t)))
                        must_continue = True
                        break
                if must_continue:
                    continue
                origt = str(t)
                del t.params[:]
                blib.set_template_name(t, repl)
                if nosimp:
                    term += "//"
                t.add("1", "zh")
                t.add("2", term)
                if tr:
                    t.add("tr", tr)
                if gloss:
                    t.add("t", gloss)
                if nocap:
                    t.add("nocap", nocap)
                replt = str(t)
                if dot:
                    replt += dot
                repltuple = (origt, replt)
                if repltuple not in replacements:
                    replacements.append(repltuple)
                notes.append("convert {{%s}} to {{%s|zh}}" % (tn, tname(t)))

    for origt, replt in replacements:
        text, did_replace = blib.replace_in_text(text, origt, replt, p.msg)
        if not did_replace:
            return

    return text, notes


parser = blib.create_argparser(
    "Convert {{zh-synonym of}}, {{zh-alt form}}, etc. to generic equivalents"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
