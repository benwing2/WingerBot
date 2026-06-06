#!/usr/bin/env python3

import re, sys

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname, msg


class BreakException(Exception):
    pass


def process_text_on_page(p):
    notes = []

    modsec = blib.find_modifiable_lang_section(p.text, "Catalan", p.msg, force_final_nls=True)
    if modsec is None:
        return
    secbody = modsec.secbody

    def verify_lang(t, lang=None):
        lang = lang or getparam(t, "1")
        if lang != "ca":
            p.msg("WARNING: Saw {{%s}} for non-Catalan language: %s" % (tname(t), str(t)))
            raise BreakException()

    def check_unrecognized_params(t, allowed_params, no_break=False):
        for param in t.params:
            pn = pname(param)
            pv = str(param.value)
            if pn not in allowed_params:
                p.msg("WARNING: Saw unrecognized param %s=%s: %s" % (pn, pv, str(t)))
                if not no_break:
                    raise BreakException()
                else:
                    return False
        return True

    def verify_verb_lemma(t, term):
        if not re.search("([aeiïu]r(-se)?|re('s)?)$", term):
            p.msg("WARNING: Term %s doesn't look like an infinitive: %s" % (term, str(t)))
            raise BreakException()

    try:
        parsed = blib.parse_text(secbody)
        for t in parsed.filter_templates():
            tn = tname(t)

            def getp(param):
                return getparam(t, param)

            if tn in ["inflection of", "infl of", "ca-verb form of"]:
                if tn == "ca-verb form of":
                    check_unrecognized_params(t, "1")
                else:
                    check_unrecognized_params(t, ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"])
                    verify_lang(t)
                if p.title.endswith("a"):
                    name = "feminine singular"
                elif p.title.endswith("es"):
                    name = "feminine plural"
                elif re.search("([ot]s)$", p.title):
                    name = "masculine plural"
                else:
                    p.msg("WARNING: Unrecognized ending, not -a, -es or -os/-ts: %s" % str(t))
                    raise BreakException()
                m = re.search("^(.*)(a|[eot]s)$", p.title)
                assert m
                base, expected_ending = m.groups()
                if expected_ending == "ts":
                    expected_ending = "s"
                    base += "t"
                if re.search(".(c|m|pr|p|t)es$", base):
                    base = base[:-2] + "ès"
                elif re.search(".(cl)os$", base):
                    base = base[:-2] + "òs"
                elif re.search(".(f)os$", base):
                    base = base[:-2] + "ós"
                elif base.endswith("s"):
                    p.msg("WARNING: Unhandled past participle ending in -s: %s" % str(t))
                    raise BreakException()
                pp = re.sub("d$", "t", base)
                if tn == "ca-verb form of":
                    inf = re.sub("^(.*)<.*?>$", r"\1", getp("1"))
                else:
                    inf = getp("2")
                verify_verb_lemma(t, inf)
                del t.params[:]
                blib.set_template_name(t, "%s of" % name)
                t.add("1", "ca")
                t.add("2", pp)
                notes.append(
                    "convert {{%s%s|INF}} to {{%s of|ca|PP}}" % (tn, "|ca" if tn != "ca-verb form of" else "", name)
                )
        secbody = str(parsed)

    except BreakException:
        # something went wrong, do nothing
        pass

    return modsec.rebuild(secbody=secbody), notes


parser = blib.create_argparser("Clean up Catalan past participle forms")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
