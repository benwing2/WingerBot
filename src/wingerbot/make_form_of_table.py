#!/usr/bin/env python3

import re

from wingerbot import blib, form_of_templates
from wingerbot.blib import msg

parser = blib.create_argparser("Generate table documenting form-of template variants.",
                               no_include_pagefile=True, no_include_stdin=True)
parser.add_argument("--direcfile", help="File containing directives.")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

if not args.direcfile:
    msg('{|class="wikitable"')
    msg(
        "! Template !! Aliases !! Category !! Takes inflection tags !! Initial capital !! Final period !! Supports from=, from2=, ... || Supports p=/POS="
    )
    for template, props in form_of_templates.form_of_templates:
        aliases = props.get("aliases", [])
        withtags = props.get("withtags", False)
        withcap = props.get("withcap", False)
        withdot = props.get("withdot", False)
        withfrom = props.get("withfrom", False)
        withPOS = props.get("withPOS", False)
        cats = props.get("cat", [])
        if type(cats) is not list:
            cats = [cats]

        def dobool(val):
            return val and "'''yes'''" or "no"

        msg("|-")
        msg(
            "| %-80s || %-50s || %-50s || %-9s || %-9s || %-9s || %-9s || %-9s"
            % (
                "[[Template:%s|%s]]" % (template, template),
                ", ".join("[[Template:%s|%s]]" % (alias, alias) for alias in aliases),
                ", ".join("<code><nowiki>LANG %s</nowiki></code>" % cat for cat in cats),
                dobool(withtags),
                dobool(withcap),
                dobool(withdot),
                dobool(withfrom),
                dobool(withPOS),
            )
        )
    msg("|}")
else:
    msg('{|class="wikitable"')
    msg(
        "! Template !! Category !! Takes inflection tags !! Initial capital !! Final period !! Supports from=, from2=, ... || Supports p=/POS="
    )
    for lineno, line in blib.iter_items_from_file(args.direcfile, start, end):
        def linemsg(txt):
            msg("Line %s: %s" % (lineno, txt))
        direcs = line.split(",")
        template = direcs[0]
        withtags = False
        withcap = False
        withdot = False
        withfrom = False
        withPOS = False
        cats = None
        for direc in direcs[1:]:
            if direc == "tags":
                withtags = True
            elif direc == "cap":
                withcap = True
            elif direc == "dot":
                withdot = True
            elif direc == "from":
                withfrom = True
            elif direc == "POS":
                withPOS = True
            elif direc.startswith("cat="):
                cats = re.sub("^cat=", "", direc).split(",")
            else:
                linemsg("WARNING: Unrecognized directive %s" % direc)
                continue

        if cats is None:
            linemsg("WARNING: No categories specified on line: %s" % line)
            continue

        def dobool(val):
            return val and "'''yes'''" or "no"

        msg("|-")
        msg(
            "| %-50s || %-50s || %-9s || %-9s || %-9s || %-9s || %-9s"
            % (
                "[[%s]]" % template,
                ", ".join("<code><nowiki>LANG %s</nowiki></code>" % cat for cat in cats),
                dobool(withtags),
                dobool(withcap),
                dobool(withdot),
                dobool(withfrom),
                dobool(withPOS),
            )
        )
    msg("|}")
