#!/usr/bin/env python3

import pywikibot, re, sys, argparse, unicodedata
from collections import defaultdict

from wingerbot import blib, lang_utils
from wingerbot.blib import getparam, rmparam, tname, msg, site

# FIXME: Declension before Derived terms etc.
# FIXME: Better handling of Alternative Forms


def get_subsection_id(subsections, k, include_equal_signs=False):
    if k == 0:
        return "0"
    if k % 2 == 0:
        k -= 1
    if include_equal_signs:
        subsection_name = subsections[k].strip()
    else:
        m = re.match("^=+(.*?)=+[ \t]*\n", subsections[k])
        subsection_name = m.group(1).strip() if m else "UNKNOWN SECTION NAME"
    return "%s (%s)" % (k // 2 + 1, subsection_name)


def check_for_bad_etym_sections(secbody, pagemsg):
    l3_subsections = re.split(r"(^===[^=\n]+===[ \t]*\n)", secbody, 0, re.M)
    subsections = re.split(r"(^===+[^=\n]+===+[ \t]*\n)", secbody, 0, re.M)
    l3_last_etym_header = len(l3_subsections) - 2

    if len(l3_subsections) < 3:
        pagemsg("WARNING: Something wrong, didn't see three subsections")
        return

    if re.search(r"==\s*Pronunciation 1\s*==", secbody):
        pagemsg("WARNING: Saw Pronunciation 1")
        return

    if re.search(r"==\s*Etymology [0-9]+\s*==", secbody) and not re.search(r"==\s*Etymology 1\s*==", secbody):
        pagemsg("WARNING: Has ==Etymology N== but not ==Etymology 1==")
        return

    if not re.search(r"==\s*Etymology 1\s*==", secbody):
        return

    if not re.search(r"==\s*Etymology 2\s*==", secbody):
        pagemsg("WARNING: Has ==Etymology 1== but not ==Etymology 2==")
        return

    l3_first_etym_header = 1
    while l3_first_etym_header < len(l3_subsections) and re.search(
        r"^===\s*(Alternative forms|Pronunciation)\s*===[ \t]*\n", l3_subsections[l3_first_etym_header]
    ):
        l3_first_etym_header += 2
    if l3_first_etym_header >= len(l3_subsections):
        pagemsg("WARNING: Saw only ==Alternative forms== and/or ==Pronunciation== sections")
        return
    final_section_re = r"^===\s*(References|See also|Derived terms|Related terms|Conjugation|Declension|Inflection|Descendants|Further reading|Anagrams|Mutation)\s*===[ \t]*\n"
    while l3_last_etym_header > 1 and re.search(final_section_re, l3_subsections[l3_last_etym_header]):
        l3_last_etym_header -= 2
    expected_etym_no = 1
    for k in range(l3_first_etym_header, l3_last_etym_header + 2, 2):
        if not re.search(r"===\s*Etymology %s\s*===[ \t]*\n" % expected_etym_no, l3_subsections[k]):
            pagemsg(
                "WARNING: Expected ===Etymology %s=== but saw section %s"
                % (expected_etym_no, get_subsection_id(l3_subsections, k, include_equal_signs=True))
            )
        expected_etym_no += 1


def group_correction_notes(template, notes):
    if len(notes) == 0:
        return ""
    if len(notes) == 1:
        notetext = notes[0]
    elif len(notes) == 2:
        notetext = "%s and %s" % (notes[0], notes[1])
    else:
        notetext = "%s and %s" % (", ".join(notes[0:-1]), notes[-1])
    return template % notetext


def allowed_non_mainspace_pagetitle(pagetitle):
    if pagetitle.startswith("Reconstruction:"):
        return True
    for lang in lang_utils.appendix_only_langnames:
        if pagetitle.startswith("Appendix:%s/" % lang):
            return True
    return False


def check_for_bad_subsections(secbody, pagetitle, pagemsg, langname):
    notes = []

    def append_note(note):
        if langname:
            notes.append("%s: %s" % (langname, note))
        else:
            notes.append(note)

    subsecs = blib.split_text_into_subsections(secbody, pagemsg)
    subsections = subsecs.subsections

    def subsection_id(k, include_equal_signs=False):
        if include_equal_signs:
            return get_subsection_id(subsecs.subsection_headers, k, include_equal_signs=True)
        return get_subsection_id(subsections, k, include_equal_signs=include_equal_signs)

    # Look for Etymology 1 by itself and maybe correct.
    saw_plain_etymology_section = False
    num_numbered_etym_sections = 0
    for k in range(1, len(subsections), 2):
        if re.search(r"==\s*Etymology\s*==", subsections[k]):
            saw_plain_etymology_section = True
        if re.search(r"==\s*Etymology [0-9]+\s*==", subsections[k]):
            num_numbered_etym_sections += 1
    if num_numbered_etym_sections == 1:
        if saw_plain_etymology_section:
            pagemsg("WARNING: Saw ==Etymology== along with a single numbered Etymology section")
        else:
            pagemsg("WARNING: Saw a single numbered Etymology section")
            if args.correct:
                for k in range(1, len(subsections), 2):
                    if re.search(r"==\s*(Etymology [0-9]+)\s*==", subsections[k]):
                        subsec_id = subsection_id(k)
                        subsections[k] = "===Etymology===\n"
                        append_note("corrected isolated section %s to ===Etymology===" % subsec_id)
                        secbody = "".join(subsections)
                        break

    # Correct whitespace.
    correct_whitespace_notes = []
    for k in range(0, len(subsections), 2):
        if not subsections[k].strip():
            newsubseck = "\n"
            if newsubseck != subsections[k]:
                pagemsg("WARNING: Empty section %s does not consist of a single newline" % subsection_id(k))
                if args.correct:
                    subsections[k] = newsubseck
                    correct_whitespace_notes.append("section %s" % subsection_id(k))
        else:
            newsubseck = subsections[k].lstrip()
            if newsubseck != subsections[k]:
                pagemsg("WARNING: Section %s begins with whitespace" % subsection_id(k))
                if args.correct:
                    subsections[k] = newsubseck
                    correct_whitespace_notes.append("section %s" % subsection_id(k))
            if not subsections[k].endswith("\n\n"):
                pagemsg("WARNING: Section %s does not end in two newlines" % subsection_id(k))
                if args.correct:
                    subsections[k] = subsections[k].rstrip() + "\n\n"
                    correct_whitespace_notes.append("section %s" % subsection_id(k))
    if len(correct_whitespace_notes) > 0:
        append_note(group_correction_notes("correct whitespace of %s", correct_whitespace_notes))

    # Do it this way so we get all the warnings when there is more than one.
    dont_indent = False

    subpagetitle = re.sub(".*/", "", pagetitle)
    if lang_utils.matches_chinese_character(subpagetitle):
        pagemsg("WARNING: Page title is a single Chinese character, not changing indentation")
        dont_indent = True

    if re.search(r"==\s*Pronunciation 1\s*==", secbody):
        pagemsg("WARNING: Saw Pronunciation 1, not changing indentation")
        dont_indent = True

    if re.search(r"==\s*Etymology [0-9]+\s*==", secbody) and not re.search(r"==\s*Etymology 1\s*==", secbody):
        pagemsg("WARNING: Has ==Etymology N== but not ==Etymology 1==, not changing indentation")
        dont_indent = True

    if dont_indent:
        return "".join(subsections), notes

    correct_indentation_notes = []
    indentation = {}

    def correct_indentation(k, expected_indentation):
        if args.correct:
            m = re.match("^(=+)(.*?)(=+)[ \t]*\n", subsections[k])
            if m and len(m.group(1)) == len(m.group(3)):
                subsections[k] = ("=" * expected_indentation) + m.group(2) + ("=" * expected_indentation) + "\n"
                indentation[k] = expected_indentation
                correct_indentation_notes.append("section %s to %s" % (subsection_id(k), expected_indentation))

    for k in range(2, len(subsections), 2):
        if re.search("^==", subsections[k], re.M):
            pagemsg(
                "WARNING: Saw badly formatted section header in section %s <%s>"
                % (subsection_id(k), subsections[k].strip())
            )
    for k in range(1, len(subsections), 2):
        if re.search(r"===+[ \t]+\n", subsections[k]):
            pagemsg("WARNING: Space at end of section header in section %s" % subsection_id(k))
            if args.correct:
                subsections[k] = re.sub(r"(===+)[ \t]+(\n)", r"\1\2", subsections[k])
                append_note("remove extraneous space at end of section header in section %s" % subsection_id(k))
        if re.search(r"^===+[ \t]", subsections[k]) or re.search(" ==+[ \t]*\n", subsections[k]):
            pagemsg("WARNING: Space surrounding section name in section header in section %s" % subsection_id(k))
            if args.correct:
                subsections[k] = re.sub(r"^(===+)\s*(.*?)\s*(===+\n)", r"\1\2\3", subsections[k])
                append_note("remove extraneous space surrounding section header name in section %s" % subsection_id(k))
        m = re.match("^(=+).*?(=+)[ \t]*\n", subsections[k])
        indentation[k] = len(m.group(1))
        if indentation[k] != len(m.group(2)):
            pagemsg(
                "WARNING: Mismatched indentation, %s equal signs on left but %s on right in section %s"
                % (indentation[k], len(m.group(2)), subsection_id(k))
            )
    for k in range(1, len(subsections) - 2, 2):
        if re.search(r"=\s*Pronunciation\s*=", subsections[k]) and re.search(r"=\s*Etymology\s*=", subsections[k + 2]):
            pagemsg("WARNING: Pronunciation before Etymology in section %s" % subsection_id(k))
            if args.correct:
                pronheader = subsections[k]
                proncontents = subsections[k + 1]
                subsections[k] = subsections[k + 2]
                subsections[k + 1] = subsections[k + 3]
                subsections[k + 2] = pronheader
                subsections[k + 3] = proncontents
                append_note("switch Pronunciation and Etymology sections")
    for k in range(3, len(subsections), 2):
        if indentation[k] - indentation[k - 2] > 1:
            pagemsg(
                "WARNING: Increase in %s from %s to %s in indentation level from section %s to section %s"
                % (
                    indentation[k] - indentation[k - 2],
                    indentation[k - 2],
                    indentation[k],
                    subsection_id(k - 2),
                    subsection_id(k),
                )
            )
    has_etym_sections = re.search(r"==\s*Etymology 1\s*==", secbody)
    last_etym_header = 0
    if has_etym_sections:
        for k in range(1, len(subsections), 2):
            if re.search(r"=\s*Etymology [0-9]", subsections[k]):
                last_etym_header = k
    pos_since_etym_section = 0
    header_to_reindent_regex = r"=\s*(Synonyms|Antonyms|Hyponyms|Hypernyms|Coordinate terms|Derived terms|Related terms|Descendants|Usage notes|Conjugation|Declension|Inflection|Translations)\s*="
    num_seen_by_header = defaultdict(int)
    num_seen_by_header_since_etym_section = defaultdict(int)
    pos_sections_seen_by_header_since_etym_section = defaultdict(set)
    for k in range(1, len(subsections), 2):
        if re.search(r"=\s*Etymology [0-9]", subsections[k]):
            pos_since_etym_section = 0
            num_seen_by_header_since_etym_section = defaultdict(int)
            pos_sections_seen_by_header_since_etym_section = defaultdict(set)
        if re.search("==" + lang_utils.pos_regex + "==", subsections[k]):
            pos_since_etym_section += 1
        m = re.search(header_to_reindent_regex, subsections[k])
        if m:
            num_seen_by_header_since_etym_section[m.group(1)] += 1
            num_seen_by_header[m.group(1)] += 1
            expected_indentation = 4 + (1 if has_etym_sections else 0)
            if indentation[k] != expected_indentation:
                pagemsg(
                    "WARNING: Expected indentation %s but actually has %s in section %s"
                    % (expected_indentation, indentation[k], subsection_id(k))
                )
                if (
                    pos_since_etym_section > 1
                    and (
                        num_seen_by_header_since_etym_section[m.group(1)] <= 1
                        or pos_since_etym_section in pos_sections_seen_by_header_since_etym_section[m.group(1)]
                    )
                    and expected_indentation > indentation[k]
                ):
                    if args.correct:
                        # We could legitimately have one Declension/Descendants/etc. section corresponding to two or more POS's and
                        # at the same level as the POS's; but presumably not if we've seen another of the same header in the same
                        # etym section in a different POS section. We don't want to correct in a case like this:
                        # ===Etymology 2===
                        #
                        # ====Noun====
                        #
                        # ====Noun====
                        #
                        # ====Derived terms===
                        #
                        # whereas we do want to correct in a case like this:
                        #
                        # ===Etymology 2===
                        #
                        # ====Noun====
                        #
                        # =====Derived terms====
                        #
                        # ====Noun====
                        #
                        # ====Derived terms====
                        #
                        # whereas we don't want to correct in a case like this:
                        #
                        # ===Etymology 2===
                        #
                        # ====Noun====
                        #
                        # =====Derived terms====
                        #
                        # ====Noun====
                        #
                        # =====Derived terms====
                        #
                        # ====Derived terms====
                        #
                        # (All these cases have been observed.)
                        pagemsg(
                            "WARNING: Can't correct section %s header (first such header in etym section) because it has %s POS sections (> 1) in etym section above it and indentation is increasing"
                            % (subsection_id(k), pos_since_etym_section)
                        )
                elif pos_since_etym_section == 0:
                    pagemsg(
                        "WARNING: Saw section %s subheader before any parts of speech in etym section%s"
                        % (subsection_id(k), "; won't correct" if args.correct else "")
                    )
                elif (
                    has_etym_sections
                    and k > last_etym_header
                    and (
                        num_seen_by_header[m.group(1)] <= 1
                        or pos_since_etym_section in pos_sections_seen_by_header_since_etym_section[m.group(1)]
                    )
                    and indentation[k] == 3
                ):
                    # We could legitimately have one L3 Declension/Descendants/etc. section corresponding to two or more POS's in
                    # different etym sections (i.e. covering all etym sections); but presumably not if we've seen another of the
                    # same header in a different POS section (see discussion above).
                    if args.correct:
                        pagemsg(
                            "WARNING: Can't correct L3 section %s header (first such header seen) because there is more than one etym section and it is past the last one"
                            % (subsection_id(k))
                        )
                else:
                    correct_indentation(k, expected_indentation)
            pos_sections_seen_by_header_since_etym_section[m.group(1)].add(pos_since_etym_section)
            if k < len(subsections) - 2 and indentation[k + 2] > indentation[k]:
                pagemsg(
                    "WARNING: nested section %s under section %s"
                    % (subsection_id(k + 2, include_equal_signs=True), subsection_id(k, include_equal_signs=True))
                )
    beginning_of_etym_sections = None
    if has_etym_sections:
        for k in range(1, len(subsections), 2):
            if re.search(r"==\s*Etymology 1\s*==", subsections[k]):
                beginning_of_etym_sections = k
                break
        if not beginning_of_etym_sections:
            pagemsg("WARNING: Something weird, ==Etymology 1== in text but can't find section with this header")
            beginning_of_etym_sections = 1
    else:
        beginning_of_etym_sections = len(subsections)
    expected_pron_indentation = 3
    expected_altform_indentation = 3
    dont_correct_until_etym_header = False
    for k in range(1, len(subsections), 2):
        check_correct = False
        if re.search(r"==\s*Etymology [0-9]+\s*==", subsections[k]):
            expected_pron_indentation = 4
            expected_altform_indentation = 4
            dont_correct_until_etym_header = False
        if dont_correct_until_etym_header:
            continue
        if re.search("==" + lang_utils.pos_regex + "==", subsections[k]):
            if has_etym_sections and k < beginning_of_etym_sections:
                pagemsg(
                    "WARNING: Saw POS header before beginning of multi-etym sections in section %s" % (subsection_id(k))
                )
                dont_correct_until_etym_header = True
            else:
                check_correct = True
            expected_altform_indentation = 5 if has_etym_sections else 4
            expected_indentation = 4 if has_etym_sections else 3
        if re.search(r"==\s*Alternative forms\s*==", subsections[k]):
            expected_indentation = expected_altform_indentation
            check_correct = True
        elif re.search(r"==\s*Pronunciation\s*==", subsections[k]):
            expected_indentation = expected_pron_indentation
            check_correct = True
        if check_correct and expected_indentation != indentation[k]:
            pagemsg(
                "WARNING: Saw level %s but expected %s in section %s"
                % (indentation[k], expected_indentation, subsection_id(k))
            )
            correct_indentation(k, expected_indentation)
    if len(correct_indentation_notes) > 0:
        append_note(group_correction_notes("correct indentation of %s", correct_indentation_notes))
    return "".join(subsections), notes


def process_text_on_page(index, pagetitle, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    if ":" in pagetitle and not allowed_non_mainspace_pagetitle(pagetitle):
        pagemsg("WARNING: Not mainspace, not changing")
        return

    modsec = blib.find_modifiable_lang_section(text, None, pagemsg, force_final_nls=True)
    if modsec is None:
        return
    text = modsec.secbody

    if args.partial_page:
        if re.search("^==[^\n=]*==$", text, re.M):
            pagemsg("WARNING: --partial-page specified but saw an L2 header, skipping")
            return
        check_for_bad_etym_sections(text, pagemsg)
        newtext, notes = check_for_bad_subsections(modsec.secbody, pagetitle, pagemsg, None)
        return modsec.rebuild(secbody=newtext), notes

    notes = []
    # Correct extraneous spaces in L2 headers and prepare for sorting by language.
    secs = blib.split_text_into_sections(text, pagemsg)
    sections = secs.sections
    sections_for_sorting = []
    for j, _ in secs.section_langs:
        # Fetch L2 language name.
        m = re.search("^==([ \t]*)(.*?)([ \t]*)==([ \t]*)\n$", sections[j - 1])
        space1, langname, space2, space3 = m.groups()

        def pagemsg(txt):
            msg("Page %s %s: %s: %s" % (index, pagetitle, langname, txt))

        if space3:
            pagemsg("WARNING: Space at end of L2 header")
        if space1 or space2:
            pagemsg("WARNING: Space surrounding section name in L2 header")
        if space1 or space2 or space3:
            if args.correct:
                sections[j - 1] = "==%s==\n" % langname
                notes.append("%s: remove extraneous space in L2 header" % langname)
        sections_for_sorting.append((langname, sections[j - 1], sections[j]))

    # Sort by language name if needed.
    sorted_sections = sorted(sections_for_sorting, key=lambda sec: lang_utils.langname_key(sec[0]))
    if sorted_sections != sections_for_sorting:
        msg("Page %s %s: %s" % (index, pagetitle, "WARNING: Language sections misordered, reordering"))
        if args.correct:
            newsections = [sections[0]]
            numlangs = len(sorted_sections)
            # Remove stray horizontal rules if found and make sure there are two newlines between language sections.
            for j in range(numlangs):
                langname, header, contents = sorted_sections[j]
                m = re.search(r"\A(.*?)\s*\n--+\Z", contents.rstrip(), re.S)
                divider = "\n\n"
                if not m:
                    # no horizontal rule at end
                    contents = contents.rstrip() + divider
                else:
                    contents = m.group(1) + divider
                newsections.append(header)
                newsections.append(contents)
            sections = newsections
            notes.append("correct misordered language sections")

    # Correct missing or misformatted section divider at end of section.
    # This should have no effect if we re-sorted the language sections.
    for j in range(2, len(sections), 2):
        # Fetch L2 language name.
        m = re.search("^==([ \t]*)(.*?)([ \t]*)==([ \t]*)\n$", sections[j - 1])
        space1, langname, space2, space3 = m.groups()

        def pagemsg(txt):
            msg("Page %s %s: %s: %s" % (index, pagetitle, langname, txt))

        if j < len(sections) - 2:  # no section divider at end of last L2 section
            m = re.search(r"\A(.*?)\s*\n--+\Z", sections[j].rstrip(), re.S)
            if not m:
                newsecj = sections[j].rstrip() + "\n\n"
            else:
                pagemsg("WARNING: Stray horizontal rule at end")
                newsecj = m.group(1) + "\n\n"
            if sections[j] != newsecj:
                pagemsg("WARNING: Misformatted language section divider at end")
                if args.correct:
                    sections[j] = newsecj
                    notes.append("%s: correct misformatted language section divider at end" % langname)

        check_for_bad_etym_sections(sections[j], pagemsg)
        newsection, this_notes = check_for_bad_subsections(sections[j], pagetitle, pagemsg, langname)
        sections[j] = newsection
        notes.extend(this_notes)
    return modsec.rebuild(secbody="".join(sections)), notes


parser = blib.create_argparser("Find misformatted sections of various sorts", include_pagefile=True, include_stdin=True)
parser.add_argument("--correct", action="store_true", help="Correct errors as much as possible.")
parser.add_argument(
    "--partial-page",
    action="store_true",
    help="Input was generated with 'find_regex.py --lang LANG' and has no ==LANG== header.",
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, stdin=True, edit=True)
