#!/usr/bin/env python3

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, errmsg

import re, sys
from wingerbot.slavic.russian import rulib


def process_text_on_page(p):
    props = pagetitle_to_props.get(p.title, None)
    if not props:
        p.msg("WARNING: Can't locate properties for page")
        return
    index, contents, comment = props

    if not contents.endswith("\n"):
        contents += "\n"
    tables = re.split(r"^--+\n", contents, 0, re.M)

    def table_to_template(table_index):
        outlines = []
        outlines.append("{{ru-derived verbs")
        table_lines = tables[table_index].rstrip("\n").split("\n")
        for table_line in table_lines:
            if not table_line.startswith("#"):
                outlines.append("|" + table_line)
        outlines.append("}}")
        return outlines

    def do_process():
        if not p.text:
            p.msg("WARNING: Page doesn't exist")
            return
        else:
            modsec = blib.find_modifiable_lang_section(p.text, "Russian", p.msg, force_final_nls=True)
            if modsec is None:
                return
            secbody = modsec.secbody

            outlines = []
            curtab_index = 0
            lines = secbody.split("\n")
            saw_top = False
            saw_impf = False
            saw_pf = False
            in_table = False
            header = None
            for line in lines:
                m = re.search("^==+(.*?)==+$", line)
                if m:
                    header = m.group(1)
                    outlines.append(line)
                    continue
                if line in ["{{top2}}", "{{der-top}}"] and header == "Derived terms":
                    if saw_top:
                        p.msg("WARNING: Saw {{top2}}/{{der-top}} line twice")
                        return
                    saw_top = True
                    continue
                if line in ["''imperfective''", "''perfective''"]:
                    if header == "Conjugation":
                        outlines.append(line)
                        continue
                    if header != "Derived terms":
                        p.msg(
                            "WARNING: Apparent derived-terms table in header '%s' rather than 'Derived terms'" % header
                        )
                        return
                    if not saw_top:
                        p.msg("WARNING: Saw imperfective/perfective line without {{top2}}/{{der-top}} line")
                        return
                    if line == "''imperfective''":
                        if saw_impf:
                            p.msg("WARNING: Saw imperfective table portion twice")
                            return
                        saw_impf = True
                    else:
                        if saw_pf:
                            p.msg("WARNING: Saw perfective table portion twice")
                            return
                        saw_pf = True
                    in_table = True
                    continue
                elif line in ["{{bottom2}}", "{{bottom}}", "{{der-bottom}}"]:
                    if in_table:
                        if not saw_top or not saw_impf or not saw_pf:
                            p.msg(
                                "WARNING: Didn't see top, imperfective header or perfective header; saw_top=%s, saw_impf=%s, saw_pf=%s"
                                % (saw_top, saw_impf, saw_pf)
                            )
                            return
                        if curtab_index >= len(tables):
                            p.msg(
                                "WARNING: Too many existing manually-formatted tables, saw %s existing table(s) but only %s replacement(s)"
                                % (curtab_index + 1, len(tables))
                            )
                            return
                        outlines.extend(table_to_template(curtab_index))
                        curtab_index += 1
                    saw_top = False
                    saw_impf = False
                    saw_pf = False
                    in_table = False
                elif in_table:
                    continue
                else:
                    outlines.append(line)

            if curtab_index != len(tables):
                p.msg(
                    "WARNING: Wrong number of existing manually-formatted tables, saw %s existing table(s) but %s replacement(s)"
                    % (curtab_index, len(tables))
                )
                return

            return modsec.rebuild(secbody="\n".join(outlines)), comment

    retval = do_process()
    if retval is None:
        for table_index in range(len(tables)):
            msg("------------------ Table #%s -----------------------" % (table_index + 1))
            if len(tables) > 1:
                msg("=====Derived terms=====")
            else:
                msg("====Derived terms====")
            outlines = table_to_template(table_index)
            msg("\n".join(outlines))
    return retval


pagetitle_to_props = {}

if __name__ == "__main__":
    parser = blib.create_argparser(
        "Push new Russian derived-verb tables from infer_ru_derverb_prefixes.py",
    )
    parser.add_argument("--files", help="Comma-separated list of files containing text.")
    parser.add_argument("--direcfile", help="File containing find-regex-style file text.")
    parser.add_argument("--comment", help="Comment to use.", required=True)
    args = parser.parse_args()
    start, end = blib.parse_start_end(args.start, args.end)

    if args.files:
        files = args.files.split(",")
        for index, extfn in enumerate(files):
            lines = list(blib.fetch_items_from_file(extfn))
            pagetitle = re.sub(r"\.der$", "", rulib.recompose(extfn))
            pagetitle_to_props[pagetitle] = (index, "\n".join(lines), args.comment)

    elif args.direcfile:
        lines = open(args.direcfile, "r", encoding="utf-8")
        index_pagetitle_text_comment = blib.yield_text_from_find_regex(lines, args.verbose)
        for _, (index, pagetitle, text, comment) in blib.iter_items(
            index_pagetitle_text_comment, get_name=lambda x: x[1], get_index=lambda x: x[0]
        ):
            if comment:
                comment = "%s; %s" % (comment, args.comment)
            else:
                comment = args.comment
            pagetitle_to_props[pagetitle] = (index, text, comment)

    blib.do_pagefile_cats_refs(
        args, start, end, process_text_on_page, default_pages=list(pagetitle_to_props.keys())
    )
