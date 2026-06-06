#!/usr/bin/env python3

from wingerbot import blib
from wingerbot.blib import msg, errandmsg
import re

parser = blib.create_argparser("Generate form-of documentation pages.",
                               no_include_pagefile=True, no_include_stdin=True)
parser.add_argument("--direcfile", help="File containing directives.", required=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

lines = open(args.direcfile, "r", encoding="utf-8")
in_multiline = False

nextpage = 0


def save_template_doc(p, tempname, doc):
    msg("For [[Template:%s]]:" % tempname)
    msg("------- begin text --------")
    msg(doc.rstrip("\n"))
    msg("------- end text --------")
    comment = "Update form-of template documentation"

    return doc, comment


while True:
    try:
        line = next(lines)
    except StopIteration:
        break
    if in_multiline and re.search("^-+ end text -+$", line):
        in_multiline = False
        nextpage += 1
        def do_save_template_doc(p):
            return save_template_doc(p, tempname, "".join(templines))
        blib.do_edit(args, nextpage, "Template:%s/documentation" % tempname, do_save_template_doc)
    elif in_multiline:
        if line.rstrip("\n").endswith(":"):
            errandmsg("WARNING: Possible missing ----- end text -----: %s" % line.rstrip("\n"))
        templines.append(line)
    else:
        line = line.rstrip("\n")
        if line.endswith(":"):
            tempname = line[:-1]
            in_multiline = True
            templines = []
        else:
            m = re.search("^(.*?):(.*)$", line)
            assert m
            tempname = m.group(1)
            tempparams = m.group(2).split(",")
            params = {}
            for tp in tempparams:
                if tp in ["infldoc", "fulldoc", "withcap", "withfrom", "grammar", "decl", "conj"]:
                    params[tp] = True
                else:
                    m = re.search("^(cat|lang|exlang|form|sgdesc|pldesc|shortcut)=(.*)", tp)
                    if m:
                        params[m.group(1)] = m.group(2)
                    else:
                        assert False, "Unrecognized parameter %s" % tp
            if "infldoc" in params:
                doctempname = "form of/infldoc"
            elif "fulldoc" in params:
                doctempname = "form of/fulldoc"
            else:
                assert False, "Neither infldoc nor fulldoc specified"
            paramtext = []
            if "pldesc" in params:
                paramtext.append("|pldesc=%s" % params["pldesc"])
            if "sgdesc" in params:
                paramtext.append("|sgdesc=%s" % params["sgdesc"])
            if "from" in params:
                paramtext.append("|from=%s" % params["from"])
            if "withcap" in params:
                paramtext.append("|withcap=1")
            if "withfrom" in params:
                paramtext.append("|withfrom=1")
            if "cat" in params:
                for index, cat in enumerate(params["cat"].split(";")):
                    paramtext.append("|cat%s=%s" % ("" if index == 0 else str(index + 1), cat))
            if "shortcut" in params:
                for index, cat in enumerate(params["shortcut"].split(";")):
                    paramtext.append("|shortcut%s=%s" % ("" if index == 0 else str(index + 1), cat))
            if "lang" in params:
                paramtext.append("|lang=%s" % params["lang"])
            if "exlang" in params:
                for index, cat in enumerate(params["exlang"].split(";")):
                    paramtext.append("|exlang%s=%s" % ("" if index == 0 else str(index + 1), cat))
            doctemp = "{{%s%s}}" % (doctempname, "".join(paramtext))
            doclines = []
            doclines.append(doctemp)
            doclines.append("<includeonly>")
            doclines.append("[[Category:Form-of templates]]")
            if "conj" in params:
                doclines.append("[[Category:Conjugation form-of templates]]")
            if "decl" in params:
                doclines.append("[[Category:Declension form-of templates]]")
            if "grammar" in params:
                doclines.append("[[Category:Grammar form-of templates]]")
            doclines.append("</includeonly>")
            nextpage += 1
            def do_save_template_doc(p):
                return save_template_doc(p, tempname, "\n".join(doclines) + "\n")
            blib.do_edit(args, nextpage, "Template:%s/documentation" % tempname, do_save_template_doc)
