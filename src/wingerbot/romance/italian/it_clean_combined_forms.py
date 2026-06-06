#!/usr/bin/env python3

import re

from wingerbot import blib
from wingerbot.blib import tname, pname
from wingerbot import infltags

participle_inflections = [
    {"inflection": {"f", "s"}, "name": "feminine singular", "ending": "a", "gender": "f-s"},
    {"inflection": {"m", "p"}, "name": "masculine plural", "ending": "i", "gender": "m-p"},
    {"inflection": {"f", "p"}, "name": "feminine plural", "ending": "e", "gender": "f-p"},
]

participle_form_names_to_properties = {props["name"]: props for props in participle_inflections}
participle_ending_to_properties = {props["ending"]: props for props in participle_inflections}


class BreakException(Exception):
    pass


def process_text_on_page(p):
    notes = []

    modsec = blib.find_modifiable_lang_section(p.text, "Italian", p.msg, force_final_nls=True)
    if modsec is None:
        return
    secbody = modsec.secbody

    def extract_pronouns(form1, form2):
        prons = []
        if form1:
            prons.append(form1)
        if form2.startswith("glie"):
            prons.extend(["glie", form2[4:]])
        else:
            prons.append(form2)
        return prons

    def extract_base(pron1, pron2):
        if pron1:
            prontext = pron1 + pron2
        else:
            prontext = pron2
        m = re.search(r"^(.*)%s$" % prontext, p.title)
        if not m:
            p.msg("WARNING: Page title should end in '%s' but doesn't" % prontext)
            return None
        return m.group(1)

    def fix_compound_of(m):
        origtext = m.group(0)
        m = re.search(r"^# Compound of (.*?)\.*\n$", origtext)
        if not m:
            p.msg("WARNING: Internal error: Can't match line: %s" % origtext)
            return origtext
        text = m.group(1)

        def do_fix_compound_of(text):
            # Convert {{m|it|ci}} to [[ci]]
            text = re.sub(r"\{\{m\|it\|([^{}]*?)\}\}", r"[[\1]]", text)
            # Convert [[ci#Italian|ci]] to [[ci]]
            text = re.sub(r"\[\[[^\[\]|]*?#Italian\|([^\[\]|]*?)\]\]", r"[[\1]]", text)
            m = re.search(
                r"^(?:the )?gerund of '*\[\[([^\[\]|]*?)\]\]'*(?:, '*\[\[([^\[\]|]*?)\]\]'*)? and '*\[\[([^\[\]|]*?)\]\]'*$",
                text,
            )
            if m:
                inf, pron1, pron2 = m.groups()
                prons = extract_pronouns(pron1, pron2)
                base = extract_base(pron1, pron2)
                if not base:
                    return None
                notes.append("templatize Italian gerund compound-of expression")
                if len(prons) == 1 and base.endswith("ando"):
                    return ""
                elif len(prons) == 1:
                    return "|inf=%s" % inf
                elif base.endswith("ando"):
                    return "|%s" % "|".join(prons)
                else:
                    return "|%s|inf=%s" % ("|".join(prons), inf)
            m = re.search(
                r"^imperative(?: \(\[*(tu|noi|voi?|singular|plural|let's|)\]*(?: (?:form|person))?\))? of '*\[\[([^\[\]|]*?)\]\]'*(?:, '*\[\[([^\[\]|]*?)\]\]'*)? and '*\[\[([^\[\]|]*?)\]\]'*$",
                text,
            )
            if m:
                imp_pers, inf, pron1, pron2 = m.groups()
                if not imp_pers:
                    base = extract_base(pron1, pron2)
                    if not base:
                        return None
                    if base.endswith("te"):
                        imp_pers = "voi"
                    else:
                        imp_pers = "tu"
                prons = extract_pronouns(pron1, pron2)
                imp_pers_to_pos = {
                    "tu": "imp2s",
                    "noi": "imp1p",
                    "voi": "imp2p",
                    "vo": "imp2p",
                    "singular": "imp2s",
                    "plural": "imp2p",
                    "let's": "imp1p",
                }
                pos = imp_pers_to_pos[imp_pers]
                notes.append("templatize Italian imperative compound-of expression")
                if len(prons) == 1:
                    return "|pos=%s|inf=%s" % (pos, inf)
                else:
                    return "|%s|pos=%s|inf=%s" % ("|".join(prons), pos, inf)
            m = re.search(
                r"^'*\[\[([^\[\]|]*?)\]\]'*(?:, '*\[\[([^\[\]|]*?)\]\]'*)? and '*\[\[([^\[\]|]*?)\]\]'*$", text
            )
            if m:
                inf, pron1, pron2 = m.groups()
                prons = extract_pronouns(pron1, pron2)
                if inf.endswith("ando"):
                    notes.append("templatize Italian gerund compound-of expression")
                    if len(prons) == 1:
                        return ""
                    else:
                        return "|%s" % "|".join(prons)
                if not inf.endswith("re") and not re.search("r[mtscv]i$", inf):
                    p.msg("WARNING: Unrecognized infinitive %s: %s" % (inf, origtext.strip()))
                    return None
                notes.append("templatize Italian infinitive compound-of expression")
                if len(prons) == 1 and inf.endswith("re"):
                    return ""
                inf_pron_to_pos = {"mi": "inf1s", "ti": "inf2s", "ci": "inf1p", "vi": "inf2p"}
                if re.search("[mtcv]i$", inf):
                    pos = inf_pron_to_pos[inf[-2:]]
                    return "|%s|%s|pos=%s" % (inf, "|".join(prons), pos)
                elif len(prons) == 1 and p.title.endswith(prons[0]):
                    return "|pos=inf|inf=%s" % inf
                elif inf.endswith("re"):
                    return "|%s" % "|".join(prons)
                else:
                    return "|%s|pos=inf|inf=%s" % ("|".join(prons), inf)
            m = re.search(
                r"^(feminine|plural|masculine plural|feminine plural|) *past participle of '*\[\[([^\[\]|]*?)\]\]'*(?:, '*\[\[([^\[\]|]*?)\]\]'*)? and '*\[\[([^\[\]|]*?)\]\]'*$",
                text,
            )
            if m:
                ppform, inf, pron1, pron2 = m.groups()
                prons = extract_pronouns(pron1, pron2)
                ppform_to_pos = {
                    "": "ppms",
                    "feminine": "ppfs",
                    "plural": "ppmp",
                    "masculine plural": "ppmp",
                    "feminine plural": "ppfp",
                }
                pos = ppform_to_pos[ppform]
                notes.append("templatize Italian past participle compound-of expression")
                if len(prons) == 1:
                    return "|pos=%s|inf=%s" % (pos, inf)
                else:
                    return "|%s|pos=%s|inf=%s" % ("|".join(prons), pos, inf)
            p.msg("WARNING: Unrecognized raw compound-of expression: %s" % origtext.strip())
            return None

        retval = do_fix_compound_of(text)
        if retval is None:
            return origtext
        return "# {{it-compound of%s}}\n" % retval

    hacked_secbody = re.sub(r"# \[\[[Cc]ompound\|[Cc]ompound\]\]", "# Compound", secbody)
    hacked_secbody = re.sub(r"# compound", "# Compound", hacked_secbody)
    hacked_secbody = re.sub(
        r"# \{\{(?:non-gloss definition|n-g)\|[Cc]ompound (.*)\}\}", r"# Compound \1", hacked_secbody
    )
    fixed_secbody = re.sub(r"# (Compound of.*?\.*)\n", fix_compound_of, hacked_secbody)
    if "{{it-compound of" in fixed_secbody:
        newsecbody = re.sub(r"\{\{head\|it\|combined forms?\}\}", "{{head|it|verb form}}", fixed_secbody)
        if newsecbody != fixed_secbody:
            notes.append("replace {{head|it|combined form}} with {{head|it|verb form}}")
            fixed_secbody = newsecbody
        secbody = fixed_secbody

    return modsec.rebuild(secbody=secbody), notes


parser = blib.create_argparser(
    "Clean up raw Italian compound-of expressions"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)
