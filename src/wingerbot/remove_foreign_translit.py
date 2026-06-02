#!/usr/bin/env python3

# This program removes redundant translit from links and similar templates,
# and also removes redundant sc= values from those same links.

# FIXME: No longer works with removal of blib.process_links(); see fa_canon.py for how to rewrite.

import re

from wingerbot import blib
from wingerbot.blib import msg, getparam, addparam, rmparam

show_template = True

# Map from language codes to list of [LONGLANG, IGNORE_MANUAL_TR], where
# LONGLANG is the canonical name of the language and IGNORE_MANUAL_TR is
# True if manual transliteration is ignored in this language and should
# always be removed.
languages = {
    "cu": ["Old Church Slavonic", False],
    "orv": ["Old East Slavic", False],
    "ru": ["Russian", False],
    "uk": ["Ukrainian", False],
    "be": ["Belarusian", False],
    "bg": ["Bulgarian", False],
    "mk": ["Macedonian", False],
    "sh": ["Serbo-Croatian", False],
}


# Attempt to canonicalize foreign parameter PARAM (which may be a list
# [FROMPARAM, TOPARAM], where FROMPARAM may be "page title") and Latin
# parameter PARAMTR. Return False if PARAM has no value, else list of
# changelog actions.
def canon_param(
    index, pagetitle, template, tlang, param, paramtr, pagemsg, expand_text, include_tempname_in_changelog=False
):
    if isinstance(param, list):
        fromparam, toparam = param
    else:
        fromparam, toparam = (param, param)
    foreign = pagetitle if fromparam == "page title" else getparam(template, fromparam)
    latin = getparam(template, paramtr)
    if not foreign or not latin:
        return False
    autotr = expand_text("{{xlit|%s|%s}}" % (tlang, foreign))
    tn = str(template.name)
    if autotr == latin or languages[tlang][1]:
        oldtempl = "%s" % str(template)
        rmparam(template, paramtr)
        pagemsg("Removing redundant translit for %s.%s (%s)" % (tn, foreign, latin))
        if include_tempname_in_changelog:
            paramtrname = "%s.%s.%s" % (tn, tlang, paramtr)
        else:
            paramtrname = paramtr
        pagemsg("Replaced %s with %s" % (oldtempl, str(template)))
        return ["remove redundant %s=%s" % (paramtrname, latin)]
    else:
        pagemsg("Not removing non-redundant translit for %s.%s (%s); autotr=%s" % (tn, foreign, latin, autotr))
    return False


def combine_adjacent(values):
    combined = []
    for val in values:
        if combined:
            last_val, num = combined[-1]
            if val == last_val:
                combined[-1] = (val, num + 1)
                continue
        combined.append((val, 1))
    return ["%s(x%s)" % (val, num) if num > 1 else val for val, num in combined]


def sort_group_changelogs(actions):
    grouped_actions = {}
    begins = ["split ", "match-canon ", "cross-canon ", "self-canon ", "remove redundant ", "remove ", ""]
    for begin in begins:
        grouped_actions[begin] = []
    actiontype = None
    action = ""
    for action in actions:
        for begin in begins:
            if action.startswith(begin):
                actiontag = action.replace(begin, "", 1)
                grouped_actions[begin].append(actiontag)
                break

    grouped_action_strs = [
        begin + ", ".join(combine_adjacent(grouped_actions[begin]))
        for begin in begins
        if len(grouped_actions[begin]) > 0
    ]
    all_grouped_actions = "; ".join([x for x in grouped_action_strs if x])
    return all_grouped_actions


# Canonicalize foreign and Latin in link-like templates on pages from STARTFROM
# to (but not including) UPTO, either page names or 0-based integers. CATTYPE
# should be 'vocab', 'borrowed', 'translation', 'links', 'pagetext', 'pages',
# an arbitrary category or a list of such items, indicating which pages to
# examine. If CATTYPE is 'pagetext', PAGES_TO_DO should be a list of
# (PAGETITLE, PAGETEXT). If CATTYPE is 'pages', PAGES_TO_DO should be a list
# of page titles, specifying the pages to do. LANG is a list of language codes
# to process templates of. LONGLANG is a canonical language name, as in
# blib.process_links(); this is only used when CATTYPE is 'vocab' or
# 'borrowed'.
def canon_links(cattype, lang, longlang, start, end, pages_to_do=[]):
    def process_param(p, template, tlang, param, paramtr):
        result = canon_param(
            p.index, p.title, template, tlang, param, paramtr, p.msg, p.expand_text, include_tempname_in_changelog=True
        )
        scvalue = getparam(template, "sc")
        if scvalue:
            if isinstance(param, list):
                fromparam, toparam = param
            else:
                fromparam, toparam = (param, param)
            foreign = p.title if fromparam == "page title" else getparam(template, fromparam)
            predicted_script = p.expand_text("{{#invoke:scripts/templates|findBestScript|%s|%s}}" % (foreign, tlang))
            if scvalue == predicted_script:
                tn = str(template.name)
                if show_template and result == False:
                    p.msg("%s.%s.%s: Processing %s" % (tn, tlang, "sc", str(template)))
                p.msg("%s.%s.%s: Removing sc=%s" % (tn, tlang, "sc", scvalue))
                oldtempl = "%s" % str(template)
                template.remove("sc")
                p.msg("Replaced %s with %s" % (oldtempl, str(template)))
                newresult = ["remove %s.%s.sc=%s" % (tn, tlang, scvalue)]
                if result != False:
                    result = result + newresult
                else:
                    result = newresult
        return result

    return blib.process_links(
        lang,
        longlang,
        cattype,
        start,
        end,
        process_param,
        sort_group_changelogs,
        pages_to_do=pages_to_do,
    )


parser = blib.create_argparser("Remove redundant foreign translit and script")
parser.add_argument("--lang", help="""Language to use when --cattype is 'vocab' or 'borrowed'.""")
parser.add_argument(
    "--cattype",
    default="borrowed",
    help="""Categories to examine ('vocab', 'borrowed', 'translation',
'links', 'pagetext', 'pages', an arbitrary category or comma-separated list)""",
)
parser.add_argument(
    "--page-file",
    help="""File containing "pages" to process when --cattype pagetext,
or list of pages when --cattype pages""",
)

args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)
pages_to_do = []
if args.page_file:
    for lineno, line in blib.iter_items_from_file(args.page_file, start, end):
        # FIXME: We don't yet support a cattype list containing 'pages'
        if args.cattype == "pages":
            pages_to_do.append(line)
        else:
            m = re.match(r"^Page [0-9]+ (.*?): [^:]*: Processing (.*?)$", line)
            if not m:
                msg("Line %s: WARNING: Unable to parse line: [%s]" % (lineno, line))
            else:
                pages_to_do.append(m.groups())
longlang = None
if args.lang:
    if args.lang not in languages:
        raise ValueError("Unrecognized language '%s'" % args.lang)
    longlang, this_ignore_manual_tr = languages[args.lang]

canon_links(args.cattype, languages.keys(), longlang, start, end, pages_to_do=pages_to_do)
