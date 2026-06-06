#!/usr/bin/env python3

import re
from collections import defaultdict
from dataclasses import dataclass

from wingerbot import blib
from wingerbot.blib import getparam, msg, tname, pname


def process_text_on_page(p):
    if not any(template in p.text for template in templates):
        return
    #if not re.search(r"\{\{\s*(%s)" % "|".join(templates), p.text):
    #    return

    if args.verbose and not args.stdin:
        p.msg("Processing")

    parsed = blib.parse_text(p.text)

    paramset = paramspecs and set(paramspecs) or set()

    lines_output = 0
    template_occurrences: list[tuple[str, str]] = []
    template_occurrence_dict: dict[str, list[str]] = defaultdict(list)
    for t in parsed.filter_templates():
        if args.from_to:
            temptext = "<from> %s <to> %s <end>" % (str(t), str(t))
        else:
            temptext = str(t)
        tn = tname(t)
        if tn in templates:
            def output_found(gloss):
                txt = "Found %s: %s" % (gloss, temptext)
                nonlocal lines_output
                if args.find_regex_output:
                    if lines_output == 0:
                        p.msg("-------- begin text --------")
                    msg(txt)
                    lines_output += 1
                elif args.single_line:
                    template_occurrences.append((gloss, temptext))
                elif args.single_line_grouped_tsv:
                    template_occurrence_dict[tn].append(temptext)
                else:
                    p.msg(txt)
                    lines_output += 1

            if not paramspecs and not countparams:
                output_found("%s template" % tn)
            else:
                seen_params = set()
                counted_param_values = counted_param_values_by_template[tn]
                for tparam in t.params:
                    pname = pname(tparam)
                    pvalue = str(tparam.value).strip()
                    seen_params.add(pname)
                    if pname in countparams or "*" in countparams:
                        if pname not in counted_param_values:
                            counted_param_values[pname] = defaultdict(int)
                        if pvalue not in counted_param_values[pname]:
                            output_found("new value %s=%s for %s template" % (pname, pvalue, tn))
                        counted_param_values[pname][pvalue] += 1
                    if args.negate:
                        if ParamSpec(cond="present", param=pname) not in paramset:
                            output_found("%s template with unrecognized param %s=%s" % (tn, pname, pvalue))
                    elif paramspecs:
                        for spec in paramspecs:
                            found = (
                                spec.cond == "eq" and spec.param == pname and spec.value == pvalue
                                or spec.cond == "neq" and spec.param == pname and spec.value != pvalue
                                or spec.cond == "present" and spec.param == pname
                            )
                            if found:
                                output_found("%s template with %s=%s" % (tn, pname, pvalue))
                # Also output occurrences of missing params when !PARAM given
                if paramspecs:
                    for spec in paramspecs:
                        if spec.cond == "notpresent":
                            if not getparam(t, spec.param):
                                output_found("%s template with param %s missing or blank" % (tn, spec.param))
                # Also track occurrences of params in countparams not occurring
                if countparams:
                    for countparam in countparams:
                        if countparam != "*" and countparam not in seen_params:
                            if countparam not in counted_param_values:
                                counted_param_values[countparam] = defaultdict(int)
                            if None not in counted_param_values[countparam]:
                                output_found("new value %s=(unseen) for %s template" % (countparam, tn))
                            counted_param_values[countparam][None] += 1
    if args.single_line:
        if template_occurrences:
            p.msg("Found %s" % "; ".join("%s (%s)" % (temptext, gloss) for gloss, temptext in template_occurrences))
            lines_output += 1
    elif args.single_line_grouped_tsv:
        if template_occurrence_dict:
            parts = []
            parts.append(str(p.index))
            parts.append(p.title)
            for tn in templates:
                parts.append(", ".join(template_occurrence_dict[tn]))
            msg("\t".join(parts))
            lines_output += 1
    if lines_output > 0:
        if args.find_regex_output:
            msg("-------- end text --------")
        if args.verbose:
            p.msg("Output %s lines" % lines_output)


parser = blib.create_argparser("Find templates with specified params")
parser.add_argument("--templates", help="""Comma-separated list of templates to check params of.""")
parser.add_argument(
    "--params",
    help="""Comma-separated list of params to check for.
Normally, will output a template if it has any of the specified parameters.
Can be of the form PARAM=VALUE to only find cases where the parameter has a
specific value, or PARAM!=VALUE to only find cases where the parameter doesn't
have a specific value. If omitted, output all templates.""",
)
parser.add_argument("--count", help="""Comma-separated list of params to count values of. If '*', count all params.""")
parser.add_argument("--negate", help="""Check if any params NOT in '--params' are present.""", action="store_true")
parser.add_argument(
    "--from-to", help="""Output in from-to format for use with push_manual_changes.py.""", action="store_true"
)
parser.add_argument(
    "--single-line",
    help="""Output in single-line format, with all found templates on the same line.""",
    action="store_true",
)
parser.add_argument(
    "--single-line-grouped-tsv",
    help="""Output in single-line format, with all found templates on the same line, grouped.
Templates with a specific name will be grouped together and separated by TAB for easy
processing in a spreadsheet.""",
    action="store_true",
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

templates = re.split(",", args.templates)


@dataclass
class ParamSpec:
    cond: str
    param: str
    value: str | None = None


def process_param(param):
    if "!=" in param:
        parts = param.split("!=")
        if len(parts) != 2:
            raise ValueError("Too many parts in PARAM!=VALUE spec: %s" % param)
        return ParamSpec(cond="neq", param=parts[0], value=parts[1])
    if "=" in param:
        parts = param.split("=")
        if len(parts) != 2:
            raise ValueError("Too many parts in PARAM=VALUE spec: %s" % param)
        return ParamSpec(cond="eq", param=parts[0], value=parts[1])
    if param.startswith("!"):
        return ParamSpec(cond="notpresent", param=param[1:])
    return ParamSpec(cond="present", param=param)


if args.params:
    paramspecs = [process_param(param) for param in re.split(",", args.params)]
else:
    paramspecs = None

if args.negate:
    if not paramspecs:
        raise ValueError("When --negate is given, --params must be given")
    for paramspec in paramspecs:
        if paramspec.cond != "present":
            raise ValueError("When --negate is given, PARAM=VALUE, PARAM!=VALUE, !PARAM specs not currently supported")

countparams = re.split(",", args.count) if args.count else []

counted_param_values_by_template = {template: {} for template in templates}


blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    default_refs=["Template:%s" % template for template in templates],
)

for template in templates:
    counted_param_values = counted_param_values_by_template[template]
    if "*" in countparams:
        countparams = sorted(list(counted_param_values.keys()))
    for countparam in countparams:
        if countparam in counted_param_values:
            msg("For template %s, param %s, saw the following values:" % (template, countparam))
            for pname, count in sorted(counted_param_values[countparam].items(), key=lambda x: -x[1]):
                msg("%s = %s" % ("(unseen)" if pname is None else pname, count))
        else:
            msg("For template %s, param %s never seen" % (template, countparam))
