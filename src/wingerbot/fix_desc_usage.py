#!/usr/bin/env python3

import pywikibot, re, sys, argparse

from wingerbot import blib
from wingerbot.blib import getparam, rmparam, tname, msg, site

from wingerbot import lang_utils

# Comment out to load latest data on-the-fly
lang_utils.load_all_lang_data("langdata.json")

etym_language_to_parent = lang_utils.get_etym_language_to_parent_map()
language_name_to_code = lang_utils.get_language_name_to_code()


def process_text_on_page(index, pagetitle, pagetext):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    if not args.stdin:
        pagemsg("Processing")

    def sub_link(m, langname, link_langcode, link_langcode_remove_accents, origtext, add_sclb):
        linktext = m.group(0)
        link = m.group(1)
        parts = re.split(r"\|", link)
        if len(parts) > 2:
            pagemsg("WARNING: Too many parts in %s, not converting raw link %s: %s" % (link, linktext, origtext))
            return linktext
        page = None
        if len(parts) == 1:
            accented = link
        else:
            page, accented = parts
            page = re.sub("#%s$" % langname, "", page)
        if page:
            if (
                not link_langcode_remove_accents
                and accented == page
                or link_langcode_remove_accents
                and link_langcode_remove_accents(accented) == page
            ):
                page = None
            elif re.search("[#:]", page):
                pagemsg(
                    "WARNING: Found special chars # or : in left side of %s, not converting raw link %s: %s"
                    % (link, linktext, origtext)
                )
                return origtext
            else:
                pagemsg(
                    "WARNING: Page %s doesn't match accented %s in %s, converting to two-part link in raw link %s: %s"
                    % (page, accented, link, linktext, origtext)
                )
        if add_sclb:
            sclb_text = "|sclb=1"
        else:
            sclb_text = ""
        if page:
            return "{{l|%s|%s|%s%s}}" % (link_langcode, page, accented, sclb_text)
        else:
            return "{{l|%s|%s%s}}" % (link_langcode, accented, sclb_text)

    def replace_serbo_croatian_with_desc(m):
        bullets1, spacing1, langname, terms = m.groups()
        origtext = m.group(0)

        if "{{desc|" not in langname:
            if "→" in spacing1:
                spacing1 = re.sub("→ *", "", spacing1)
                langname = "{{desc|sh|-|bor=1}}"
            else:
                langname = "{{desc|sh|-}}"

        def replace_sh_term(m):
            termlink = m.group(1)
            if termlink.startswith("[["):
                termlink = re.sub(
                    r"^\[\[(.*?)\]\]$",
                    lambda m: sub_link(
                        m, "Serbo-Croatian", "sh", lang_utils.sh_remove_accents, origtext, add_sclb=True
                    ),
                    termlink,
                )
            else:
                parsed = blib.parse_text(termlink)
                for t in parsed.filter_templates():
                    if tname(t) in ["l", "m"] and getparam(t, "1") == "sh":
                        rmparam(t, "sc")
                        t.add("sclb", "1")
                        blib.set_template_name(t, "desc")
                termlink = str(parsed)
            return termlink

        terms = re.sub(
            r"(?:Latin|Roman|Cyrillic): *(\[\[[^\[\]\n]*?\]\]|\{\{[lm]\|sh\|[^{}\n]*?\}\})", replace_sh_term, terms
        )

        newtext = "%s%s%s%s" % (bullets1, spacing1, langname, terms)
        pagemsg("Replacing <%s> with <%s>" % (origtext, newtext))
        return newtext

    def replace_with_desc(m):
        bullets, langname, links = m.groups()
        origtext = m.group(0)

        if langname in lang_utils.non_canonical_to_canonical_names:
            new_langname = lang_utils.non_canonical_to_canonical_names[langname]
            pagemsg("Replacing non-canonical or unrecognized %s with %s: %s" % (langname, new_langname, origtext))
            langname = new_langname

        pretext = ""
        if langname in lang_utils.unrecognized_to_canonical_names:
            new_pretext, new_langname = lang_utils.unrecognized_to_canonical_names[langname]
            pretext = new_pretext + " " if new_pretext else ""
            pagemsg(
                "Replacing unrecognized %s with %s%s: %s"
                % (langname, new_langname, ' (with pretext "%s")' % pretext if pretext else "", origtext)
            )
            langname = new_langname

        if langname not in language_name_to_code:
            pagemsg("WARNING: Saw unrecognized lang name <%s>" % langname)
            return origtext
        langcodes, etymcode, isetymcanon = language_name_to_code[langname]

        # Find the language whose canonical name is the given language name.
        potential_langcodes = set()
        for code, iscanon in langcodes:
            if iscanon:
                potential_langcodes.add(code)
        if len(potential_langcodes) > 1:
            pagemsg(
                "WARNING: Language name %s has multiple canonical codes %s, skipping: %s"
                % (langname, ",".join(potential_langcodes), origtext)
            )
            return origtext
        if len(potential_langcodes) == 1 and isetymcanon:
            pagemsg(
                "WARNING: Language name %s has both regular canonical code %s and etym language canonical code %s, skipping: %s"
                % (langname, list(potential_langcodes)[0], etymcode, origtext)
            )
            return origtext
        if len(potential_langcodes) == 1:
            langcode = list(potential_langcodes)[0]
        elif isetymcanon:
            langcode = etymcode
        else:
            pagemsg(
                "WARNING: Language name %s isn't a canonical name of any language, skipping: %s" % (langname, origtext)
            )
            return origtext

        # Find the set of language codes (hopefully at most one) among the
        # templated links.
        seen_langcodes = set()
        for mm in re.finditer(r"\{\{[lm]\|([^{}|\n]*?)\|.*?\}\}", links):
            seen_langcodes.add(mm.group(1))
        if len(seen_langcodes) > 1:
            pagemsg("WARNING: Saw multiple lang codes %s, skipping: %s" % (",".join(seen_langcodes), origtext))
            return origtext

        # If there is one, use it to replace raw links, otherwise use language
        # code of name (or parent language, if it's an etym language).
        if len(seen_langcodes) == 1:
            link_langcode = list(seen_langcodes)[0]
        else:
            link_langcode = etym_language_to_parent.get(langcode, langcode)

        link_langcode_remove_accents = None
        if link_langcode in lang_utils.language_codes_to_properties:
            _, link_langcode_remove_accents, _, _ = lang_utils.language_codes_to_properties[link_langcode]

        # Replace raw links with templated links.
        def replace_raw_link(m):
            linktext = m.group(0)
            if linktext.startswith("["):
                mm = re.search(r"^\[\[([^\[\]\n]*?)\]\]$", linktext)
                if not mm:
                    pagemsg("WARNING: Something wrong, not a raw link: %s: %s" % (linktext, origtext))
                    return linktext
                return sub_link(m, langname, link_langcode, link_langcode_remove_accents, origtext, add_sclb=False)
            return linktext

        # We don't want to replace raw links inside of templates, so we match both templates
        # and raw links and don't change the templates.
        new_links = re.sub(r"\{\{[^{}\n]*?\}\}|\[\[[^\[\]\n]*?\]\]", replace_raw_link, links)
        if new_links != links:
            pagemsg("Replacing raw link <%s> with <%s>" % (links, new_links))
            links = new_links

        # Replace {{m|...}} links with {{l|...}} links.
        new_links = re.sub(r"\{\{m\|(.*?)\}\}", r"{{l|\1}}", links)
        if new_links != links:
            pagemsg("Replacing m-type link <%s> with <%s>" % (links, new_links))
            links = new_links

        # Replace bad language codes in templated links with better ones, based on langname.
        parsed = blib.parse_text(links)
        made_mod = False
        for t in parsed.filter_templates():
            if tname(t) in ["l", "m"]:
                template_langcode = getparam(t, "1")
                if (langname, template_langcode) in lang_utils.langcode_langname_to_correct_langcode:
                    new_langcode = lang_utils.langcode_langname_to_correct_langcode[(langname, template_langcode)]
                    if new_langcode == template_langcode:
                        if template_langcode in lang_utils.languages_by_code:
                            new_langname = lang_utils.languages_by_code[template_langcode]["canonicalName"]
                        elif template_langcode in lang_utils.etym_languages_by_code:
                            pagemsg(
                                "WARNING: Encountered template langcode %s that's an etymology language: %s"
                                % (template_langcode, origtext)
                            )
                            break
                        else:
                            pagemsg(
                                "WARNING: Encountered unrecognized template langcode %s: %s"
                                % (template_langcode, origtext)
                            )
                            break
                        pagemsg(
                            "Replacing language name %s with %s based on template langcode %s in %s: %s"
                            % (langname, new_langname, template_langcode, str(t), origtext)
                        )
                        langname = new_langname
                        langcode = template_langcode
                        break
                    if new_langcode != langcode:
                        pagemsg(
                            "Replacing language code %s with %s based on language name %s and template langcode %s in %s: %s"
                            % (langcode, new_langcode, langname, template_langcode, str(t), origtext)
                        )
                        langcode = new_langcode
                    link_langcode = etym_language_to_parent.get(langcode, langcode)
                    origt = str(t)
                    t.add("1", link_langcode)
                    if langcode == link_langcode:
                        pagemsg(
                            "Replacing langcode %s in template %s with %s based on language name %s, producing %s: %s"
                            % (template_langcode, origt, link_langcode, langname, str(t), origtext)
                        )
                    else:
                        pagemsg(
                            "Replacing langcode %s in template %s with %s based on etymology language name %s with langcode %s, producing %s: %s"
                            % (template_langcode, origt, link_langcode, langname, langcode, str(t), origtext)
                        )
                    made_mod = True
        if made_mod:
            links = str(parsed)

        # Replace leftmost templated link with {{desc}}.

        # (1) Find lang code of leftmost templated link.
        mm = re.search(r"\{\{[lm]\|([^{}|\n]*?)\|.*?\}\}", links)
        if not mm:
            pagemsg("WARNING: Something wrong, no links, skipping: %s" % origtext)
            return origtext
        # (2) Check that it's replaceable by language code of name.
        template_langcode = mm.group(1)
        if not (langcode == template_langcode or etym_language_to_parent.get(langcode, "NONE") == template_langcode):
            pagemsg(
                "WARNING: Language name %s inferred code %s not same as or (if etym lang a child of) template code %s, skipping: %s"
                % (langname, langcode, template_langcode, origtext)
            )
            return origtext
        # (3) Actually replace.
        if "→" in bullets:
            bullets = re.sub("→ *", "", bullets)
            bortext = "|bor=1"
        else:
            bortext = ""
        links = re.sub(r"\{\{[lm]\|[^{}|\n]*?\|(.*?)\}\}", r"{{desc|%s|\1%s}}" % (langcode, bortext), links, 1)
        newtext = "%s%s%s" % (bullets, pretext, links.lstrip())
        pagemsg("Replacing <%s> with <%s>" % (origtext, newtext))
        return newtext

    if args.do_all_sections:
        pagehead = ""
        sections = [pagetext]
    else:
        # Split into (sub)sections
        splitsections = re.split("(^===*[^=\n]+=*==\n)", pagetext, 0, re.M)
        # Extract off pagehead and recombine section headers with following text
        pagehead = splitsections[0]
        sections = []
        for i in range(1, len(splitsections)):
            if (i % 2) == 1:
                sections.append("")
            sections[-1] += splitsections[i]

    # Go through each section in turn, looking for Descendants sections
    for i in range(len(sections)):
        if args.do_all_sections or re.match("^===*Descendants=*==\n", sections[i]):
            text = sections[i]
            text = re.sub(
                r"^(\*+:?)( *(?:→ *)?)(Serbo-Croat(?:ian):|\{\{desc(?:\|.*?)?\|sh(?:\|.*?)?\|-(?:\|.*?)?\}\})((?:\n\1[*:] *(?:Latin|Roman|Cyrillic): *(?:\[\[[^\[\]\n]*?\]\]|\{\{[lm]\|sh\|[^{}\n]*?\}\}))+)",
                replace_serbo_croatian_with_desc,
                text,
                0,
                re.M,
            )
            text = re.sub(
                r"^(\*+ *(?:→ *)?)([A-Z][A-Za-z-]+(?: [A-Za-z-]+)*?):((?: *(?:\{\{[lm]\|[^{}|\n]*?\|[^{}\n]*?\}\}|\[\[[^\[\]\n]*?\]\]),?)+)",
                replace_with_desc,
                text,
                0,
                re.M,
            )
            sections[i] = text

    return pagehead + "".join(sections), "Use {{desc}} for descendants in place of LANG {{l|CODE|...}} or LANG [[LINK]]"


parser = blib.create_argparser(
    "Use {{desc}} for descendants in place of LANG {{l|CODE|...}} or LANG [[LINK]]",
    include_pagefile=True,
    include_stdin=True,
)
parser.add_argument("--do-all-sections", action="store_true", help="Do all sections, not only Descendants sections")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True)
