#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.slavic.russian import rulib


def process_decl(p, decl, forms):
    p.msg("Processing")

    if decl.startswith("{{ru-conj|"):
        tempcall = re.sub(r"^\{\{ru-conj", "{{ru-generate-verb-forms", decl)
    elif decl.startswith("{{ru-noun-table"):
        tempcall = re.sub(r"^\{\{ru-noun-table", "{{ru-generate-noun-args", decl)
    else:
        p.msg("WARNING: Unrecognized decl template, skipping: %s" % decl)
        return

    result = p.expand_text(tempcall)
    if not result:
        p.msg("WARNING: Error generating forms, skipping")
        return
    inflargs = blib.split_generate_args(result)

    for formind, form in enumerate(forms, start=1):
        if form in inflargs:
            for formpagename in re.split(",", inflargs[form]):
                formpagename = re.sub("//.*$", "", formpagename)
                pp = blib.create_process_page_params(
                    args, "%s.%s" % (p.index, formind), rulib.remove_accents(formpagename),
                    must_exist="WARNING: Form page doesn't exist, skipping", msg_title="%s: %s" % (p.title, formpagename))
                if pp is None:
                    continue
                assert pp.page is not None  # guaranteed by create_process_page_params
                if pp.title == p.title:
                    pp.msg("WARNING: Attempt to delete dictionary form, skipping")
                    continue
                secs = blib.split_text_into_sections(pp.text, pp.msg)
                langs_seen = set(lang for _, lang in secs.lang_list)
                if "Russian" not in langs_seen:
                    pp.msg("WARNING: Didn't see Russian section, skipping")
                    continue
                if len(langs_seen) > 1:
                    non_russian_langs = langs_seen - {"Russian"}
                    pp.msg("WARNING: Found entry for non-Russian language(s) %s, skipping form" % ",".join(non_russian_langs))
                    continue
                if "Etymology 1" in pp.text:
                    pp.msg("WARNING: Found 'Etymology 1', skipping form")
                    continue
                comment = "Delete erroneously created form of %s" % p.title
                if args.save:
                    pp.page.delete(comment)
                else:
                    pp.msg("Would delete page %s with comment=%s" % (pp.title, comment))


parser = blib.create_argparser(
    "Delete erroneously created Russian noun or verb forms given the inflection templates that led to those forms being created",
    no_include_pagefile=True, no_include_stdin=True,
)
parser.add_argument("--direcfile", help="File containing inflection templates to expand to get forms.", required=True)
parser.add_argument("--forms", help="Form codes of forms to delete.", required=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

if args.forms == "all-verb":
    forms = [
        "pres_1sg",
        "pres_2sg",
        "pres_3sg",
        "pres_1pl",
        "pres_2pl",
        "pres_3pl",
        "futr_1sg",
        "futr_2sg",
        "futr_3sg",
        "futr_1pl",
        "futr_2pl",
        "futr_3pl",
        "impr_sg",
        "impr_pl",
        "past_m",
        "past_f",
        "past_n",
        "past_pl",
        "past_m_short",
        "past_f_short",
        "past_n_short",
        "past_pl_short",
    ]
elif args.forms == "pres":
    forms = ["pres_1sg", "pres_2sg", "pres_3sg", "pres_1pl", "pres_2pl", "pres_3pl"]
elif args.forms == "futr":
    forms = ["futr_1sg", "futr_2sg", "futr_3sg", "futr_1pl", "futr_2pl", "futr_3pl"]
elif args.forms == "impr":
    forms = ["impr_sg", "impr_pl"]
elif args.forms == "past":
    forms = ["past_m", "past_f", "past_n", "past_pl", "past_m_short", "past_f_short", "past_n_short", "past_pl_short"]
elif args.forms == "all-noun":
    forms = [
        "nom_sg",
        "gen_sg",
        "dat_sg",
        "acc_sg",
        "acc_sg_an",
        "acc_sg_in",
        "ins_sg",
        "pre_sg",
        "nom_pl",
        "gen_pl",
        "dat_pl",
        "acc_pl",
        "acc_pl_an",
        "acc_pl_in",
        "ins_pl",
        "pre_pl",
    ]
elif args.forms == "sg":
    forms = ["nom_sg", "gen_sg", "dat_sg", "acc_sg", "acc_sg_an", "acc_sg_in", "ins_sg", "pre_sg"]
elif args.forms == "pl":
    forms = ["nom_pl", "gen_pl", "dat_pl", "acc_pl", "acc_pl_an", "acc_pl_in", "ins_pl", "pre_pl"]
else:
    forms = blib.split_arg(args.forms)
for lineno, line in blib.iter_items_from_file(args.direcfile, start, end):
    if "!!!" in line:
        declpage, decl = re.split("!!!", line)
    else:
        declpage, decl = re.split(" ", line, 1)
    def do_process_decl(p):
        return process_decl(p, decl, forms)
    blib.do_edit(args, lineno, declpage, do_process_decl)
