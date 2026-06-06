#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, msg, errandmsg, tname

add_stress = {
    "a": "á",
    "e": "é",
    "i": "í",
    "o": "ó",
    "u": "ú",
}

vowel = "aeiouáéíóúý"
V = "[" + vowel + "]"
C = "[^" + vowel + "]"


def singularize(word):
    if not word.endswith("s") or len(re.sub("[^aeiou]", "", word)) <= 1 or re.search("[áéíóúiu]s$", word):
        # not a plural
        return "[[%s]]" % word
    if re.search(V + "[ns]es$", word):
        if re.search("[áéíóúý]", word) or len(re.sub("[^aeiou]", "", word)) <= 2:
            return "[[%s]]es" % word[:-2]
        # need to add an accent in the singular
        return "[[%s%s%s|%s]]" % (word[:-4], add_stress[word[-4]], word[-3], word)
    if re.search(V + "ces$", word):
        return "[[%sz|%s]]" % (word[:-3], word)
    if re.search(V + "[rld]es$", word):
        return "[[%s]]es" % word[:-2]
    return "[[%s]]s" % word[:-1]


def process_text_on_page_for_generate(p):
    def pagemsg(txt):
        msg("# Page %s %s: %s" % (p.index, p.title, txt))

    if " " not in p.title:
        pagemsg("WARNING: No space in page title")
        return
    if p.title.startswith("no "):
        prefix, verb_rest = p.title.split(" ", 1)
        if " " in verb_rest:
            verb, rest = verb_rest.split(" ", 1)
        else:
            verb = verb_rest
            rest = ""
        prefix = prefix + " "
    else:
        verb, rest = p.title.split(" ", 1)
        prefix = ""
    if verb not in verbs_to_spec:
        pagemsg("WARNING: Unrecognized verb '%s'" % verb)
        return
    linked_rest = " ".join(singularize(x) for x in rest.split(" "))
    spec = verbs_to_spec[verb]
    if spec == "*":
        spec = "<>"
    msg("%s%s%s %s" % (prefix, verb, spec, linked_rest))


def process_text_on_page_for_full_conj(p):
    p.msg("Processing")

    notes = []

    if p.title not in verbs_to_spec:
        p.msg("WARNING: Can't find entry, skipping")
        return

    entry = verbs_to_spec[p.title]
    origentry = entry
    first, rest = p.title.split(" ", 1)
    restwords = rest.split(" ")
    def_link = "%s<> %s" % (first, " ".join("[[%s]]" % word for word in restwords))
    if def_link == entry:
        p.msg("Replacing entry '%s' with a blank entry because it's the default" % entry)
        entry = ""
    elif re.sub("<.*?>", "<>", entry) == def_link:
        newentry = blib.remove_links(entry)
        p.msg("Replacing entry '%s' with entry without links '%s'" % (entry, newentry))
        entry = newentry

    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():
        tn = tname(t)
        origt = str(t)
        if tn == "es-verb":
            if not getparam(t, "attn"):
                p.msg("Didn't see attn=1: %s" % str(t))
                continue
            rmparam(t, "attn")
            if entry:
                t.add("1", entry)
                notes.append("add conjugation '%s' to Spanish verb" % entry)
            else:
                notes.append("add conjugation (default) to Spanish verb")
        if tn == "head" and getparam(t, "1") == "es" and getparam(t, "2") == "verb":
            head = getparam(t, "head")
            if head:
                p.msg(
                    "WARNING: Removing head=%s compared with entry '%s', original entry '%s': %s"
                    % (head, entry, origentry, str(t))
                )
                rmparam(t, "head")
            rmparam(t, "2")
            rmparam(t, "1")
            blib.set_template_name(t, "es-verb")
            if entry:
                t.add("1", entry)
                notes.append("convert {{head|es|verb}} to {{es-verb|%s}}" % entry)
            else:
                notes.append("convert {{head|es|verb}} to {{es-verb}}")
        if origt != str(t):
            p.msg("Replaced %s with %s" % (origt, str(t)))

    return str(parsed), notes


def process_text_on_page_for_single_word(p):
    p.msg("Processing")

    notes = []

    if p.title not in verbs_to_spec:
        p.msg("WARNING: Can't find entry, skipping")
        return
    spec = verbs_to_spec[p.title]

    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():
        tn = tname(t)
        origt = str(t)
        if tn == "es-verb":
            if not getparam(t, "attn"):
                p.msg("Didn't see attn=1: %s" % str(t))
                continue
            rmparam(t, "attn")
            if "<" in spec:
                t.add("1", "%s%s" % (p.title, spec))
                notes.append("add conjugation %s%s to Spanish verb" % (p.title, spec))
            elif spec == "*":
                notes.append("add conjugation (default) to Spanish verb")
            else:
                t.add("pres", spec)
                notes.append("add conjugation pres=%s to Spanish verb" % spec)
        if origt != str(t):
            p.msg("Replaced %s with %s" % (origt, str(t)))

    return str(parsed), notes


parser = blib.create_argparser(
    "Add conjugations to Spanish verbs lacking them"
)
parser.add_argument("--direcfile", help="File of conjugated verbs")
parser.add_argument(
    "--mode",
    choices=["full-conj", "single-word", "generate"],
    help="Operating mode. If 'full-conj', --direcfile contains full conjugations with <>. If 'single-word', --direcfile contains the first word followed by the conjugation of that word.",
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

verbs_to_spec = {}

if args.mode == "full-conj":
    for lineno, line in blib.iter_items_from_file(args.direcfile, start, end):
        verb = blib.remove_links(re.sub("<.*?>", "", line))
        verbs_to_spec[verb] = line
    blib.do_pagefile_cats_refs(
        args,
        start,
        end,
        process_text_on_page_for_full_conj,
        default_pages=list(verbs_to_spec.keys()),
    )
elif args.mode == "generate":
    for lineno, line in blib.iter_items_from_file(args.direcfile):
        if " " not in line:
            errandmsg("Line %s: WARNING: No space in line: %s" % (lineno, line))
            continue
        verb, spec = line.split(" ", 1)
        verbs_to_spec[verb] = spec

    blib.do_pagefile_cats_refs(
        args,
        start,
        end,
        process_text_on_page_for_generate,
        default_pages=list(verbs_to_spec.keys()),
    )
else:
    for lineno, line in blib.iter_items_from_file(args.direcfile, start, end):
        if " " not in line:
            errandmsg("Line %s: WARNING: No space in line: %s" % (lineno, line))
            continue
        verb, spec = line.split(" ", 1)
        def process_line(p):
            verbs_to_spec[verb] = spec
        blib.do_edit(args, lineno, verb, process_line, must_exist=True)

    blib.do_pagefile_cats_refs(
        args,
        start,
        end,
        process_text_on_page_for_single_word,
        default_pages=list(verbs_to_spec.keys()),
    )
