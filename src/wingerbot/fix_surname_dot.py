#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, tname


def process_text_on_page(p):
    if blib.page_should_be_ignored(p.title):
        return

    p.msg("Processing")
    notes = []

    parsed = blib.parse_text(p.text)

    to_add_punct = []

    for t in parsed.filter_templates():
        origt = str(t)
        tn = tname(t)
        if tn == "surname":

            def getp(param):
                return getparam(t, param)

            if t.has("nodot"):
                nodot = getp("nodot")
                if nodot == "2":
                    p.msg("nodot=2 means period, removing nodot= and dot=: %s" % str(t))
                    rmparam(t, "nodot")
                    rmparam(t, "dot")
                    notes.append("remove nodot=2 and overridden dot= in {{%s}}" % tn)
                elif nodot != "1":
                    p.msg("nodot=%s means nothing, removing it: %s" % (nodot, str(t)))
                    rmparam(t, "nodot")
                    notes.append("remove effectless nodot=%s in {{%s}}" % (nodot, tn))
            if t.has("dot") and (not getp("dot") or getp("dot") == "<nowiki/>"):
                p.msg("WARNING: empty dot= in {{surname}} template: %s" % str(t))
                rmparam(t, "dot")
                t.add("nodot", "1")
                notes.append("convert empty dot= to nodot=1 in {{%s}}" % tn)
            dot = getp("dot")
            nodot = getp("nodot")
            if dot and nodot:
                p.msg("WARNING: Something wrong: Saw both dot= and nodot=: %s" % str(t))
                continue
            if dot:
                rmparam(t, "dot")
                t.add("nodot", "1")
                notes.append(
                    "convert dot= in {{%s}} to nodot=1 + explicit final punctuation (will remove nodot=1 later)" % tn
                )
                to_add_punct.append((str(t), dot))
            elif nodot:
                p.msg("Template has nodot=1, leaving alone: %s" % str(t))
            else:
                t.add("nodot", "1")
                notes.append(
                    "convert implicit final period in {{%s}} to nodot=1 + explicit final period (will remove nodot=1 later)"
                    % tn
                )
                to_add_punct.append((str(t), "."))
        if str(t) != origt:
            p.msg("Replace <%s> with <%s>" % (origt, str(t)))

    text = str(parsed)

    for curr_template, punct in to_add_punct:
        repl_template = curr_template + punct
        newtext, did_replace = blib.replace_in_text(text, curr_template, repl_template, p.msg)
        if did_replace:
            newtext = re.sub(re.escape(curr_template) + r"\.([.,])", curr_template + r"\1", newtext)
            if newtext != text:
                if punct == ".":
                    p.msg("Add period to <%s>" % curr_template)
                else:
                    p.msg("Add punct '%s' to <%s>" % (punct, curr_template))
                text = newtext

    return text, notes


parser = blib.create_argparser(
    "Correct use of dot= and nodot= in {{surname}}, and add period where it was formerly automatically added",
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, default_refs=["Template:surname"]
)
