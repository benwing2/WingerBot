#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, pname, msg


class BreakException(Exception):
    pass


def process_text_on_page(p):
    notes = []

    modsec = blib.find_modifiable_lang_section(p.text, "Galician", p.msg, force_final_nls=True)
    if modsec is None:
        return
    secbody = modsec.secbody

    def verify_lang(t, lang=None):
        lang = lang or getparam(t, "1")
        if lang != "gl":
            p.msg("WARNING: Saw {{%s}} for non-Galician language: %s" % (tname(t), str(t)))
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
        if not re.search("([aeiíoóô]r)$", term):
            p.msg("WARNING: Term %s doesn't look like an infinitive: %s" % (term, str(t)))
            raise BreakException()

    def verify_past_participle_inflection(t, name, ending):
        if not re.search("[dt]%s$" % ending, p.title):
            p.msg(
                "WARNING: Found %s past participle form but page title doesn't have the correct form: %s"
                % (name, str(t))
            )
            raise BreakException()

    try:
        parsed = blib.parse_text(secbody)
        for t in parsed.filter_templates():
            tn = tname(t)

            def getp(param):
                return getparam(t, param)

            if tn in ["inflection of", "infl of", "gl-verb form of"]:
                if tn == "gl-verb form of":
                    check_unrecognized_params(t, "1")
                else:
                    check_unrecognized_params(t, ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"])
                    verify_lang(t)
                if p.title.endswith("a"):
                    name = "feminine singular"
                elif p.title.endswith("os"):
                    name = "masculine plural"
                elif p.title.endswith("as"):
                    name = "feminine plural"
                else:
                    p.msg("WARNING: Unrecognized ending, not -a, -os or -as: %s" % str(t))
                    raise BreakException()
                m = re.search("^(.*)([ao]s?)$", p.title)
                assert m
                base, expected_ending = m.groups()
                pp = base + "o"
                verify_past_participle_inflection(t, name, expected_ending)
                if tn == "gl-verb form of":
                    inf = re.sub("^(.*)<.*?>$", r"\1", getp("1"))
                else:
                    inf = getp("2")
                verify_verb_lemma(t, inf)
                del t.params[:]
                blib.set_template_name(t, "%s of" % name)
                t.add("1", "gl")
                t.add("2", pp)
                notes.append(
                    "convert {{%s%s|INF}} to {{%s of|gl|PP}}" % (tn, "|gl" if tn != "gl-verb form of" else "", name)
                )
            elif tn in [
                "feminine singular past participle of",
                "masculine plural past participle of",
                "feminine plural past participle of",
            ]:
                verify_lang(t)
                check_unrecognized_params(t, ["1", "2", "nocat"])
                name = tn.replace(" past participle of", "")
                if name == "feminine singular":
                    expected_ending = "a"
                elif name == "masculine plural":
                    expected_ending = "os"
                elif name == "feminine plural":
                    expected_ending = "as"
                else:
                    assert False
                pp = re.sub("^([ao]s?)$", "", p.title) + "o"
                verify_past_participle_inflection(t, name, expected_ending)
                verify_verb_lemma(t, getp("2"))
                rmparam(t, "nocat")
                blib.set_template_name(t, "%s of" % name)
                t.add("2", pp)
                notes.append("convert {{%s|gl|INF}} to {{%s of|gl|PP}}" % (tn, name))
        secbody = str(parsed)

    except BreakException:
        # something went wrong, do nothing
        pass

    return modsec.rebuild(secbody=secbody), notes


parser = blib.create_argparser("Clean up Galician past participle forms")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
