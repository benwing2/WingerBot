#!/usr/bin/env python3

import pywikibot, re, sys, argparse, json
from collections import defaultdict

from wingerbot import blib, lang_utils
from wingerbot.blib import getparam, rmparam, msg, site, tname, pname
from wingerbot.remove_redundant_sc import check_script_agrees

from dataclasses import dataclass, field

## FIXME:
# 1. Handle non-canonical names esp. Bokmål and Nynorsk. [DONE]
# 2. If name is an etym variety of the lang code (e.g. Digor Ossetian vs. os), convert to etym code. [DONE]
# 3. Check that a translation template doesn't occur inside of a qualifier.
# 4. Handle partially convertible lines; convert to multiple {{t}} templates, combining as much as possible. [DONE]
# 5. Handle mismatches between name and code as much as possible according to map in lang_utils.py. [DONE]
# 6. If name can't be matched to code, leave it and use {{t-}}. [DONE]
# 7. Check for occurring inside of {{multitrans}} and use {{tt}} and {{tt-}}. [DONE]
# 8. Warn if {{tt}} seen outside of multitrans. [DONE]
# 9. Fix script name-to-code generation to prefer non-hyphenated script codes. [DONE]
# 10. Handle different separators: slash, semicolon, 'or'. [DONE]
# 11. Special-case script names: Carakan/Jawi/Rumi (= Javanese/Arabic/Latin) for Javanese and Malay, Cyrillic (= Old Cyrillic)
#     for Old Church Slavonic, 'Mongolian script' for Mongolian.
# 12. If bare header without anything following, leave alone. [DONE]
# 13. Remove final comma (if present) from line before processing. [DONE]
# 14. Support t= in translation templates if not already present.
# 15. Support nested translation templates inside of e.g. {{n-g|...}}, as in 'used to'.
# 16. Support HTML comments in lang codes.
# 17. Handle {{t-egy}}.

lang_utils.init_fake_lang_data()
lang_utils.load_all_lang_data("langdata.json")
lang_data = lang_utils.get_lang_data()
etym_lang_data = lang_utils.get_etym_lang_data()
family_data = lang_utils.get_family_data()
script_data = lang_utils.get_script_data()


@dataclass
class TranslationTemplate:
    entry: str
    entry_parts: list[tuple] = field(default_factory=list)
    left_qualifiers: list[str] = field(default_factory=list)
    right_qualifiers: list[str] = field(default_factory=list)
    left_labels: list[str] = field(default_factory=list)
    right_labels: list[str] = field(default_factory=list)
    references: list[str] = field(default_factory=list)
    glosses: list[str] = field(default_factory=list)


class Qualifier:
    qualifiers: list[str]
    saw_embedded_translation_template: bool


etym_language_to_parent = lang_utils.get_etym_language_to_parent()

seen_converted_quals = defaultdict(lambda: defaultdict(int))
seen_converted_qual_count = defaultdict(int)

char_to_escape_seq = {
    "%": "%25",
    "|": "%7C",
    "{": "%7B",
    "}": "%7D",
    "=": "%3D",
    "&": "%26",
}


def bot_url_encode(val):
    return re.sub("[%|{}=&]", lambda m: char_to_escape_seq[m.group(0)], val)


def escape_inline_val(val):
    # If < or > in the value, check if they are balanced. If not, escape them all (safest thing to do).
    if "<" in val or ">" in val:
        try:
            segments = blib.parse_balanced_segment_run(val, "<", ">")
        except blib.ParseException:
            return val.replace("<", "&lt;").replace(">", "&gt;")
    return val


def escape_template_delimiters(val, pagemsg):
    # Escape = and | occurring in raw text that will become a template parameter. This should exclude:
    # (1) Raw links, where [[foo=bar|baz=bat]] in a param doesn't cause issues.
    # (2) Template calls, where {{foo=bar|baz=bat}} in a param doesn't cause issues.
    # (3) <ref>...</ref>, where = and | occurring either in parameters inside the tags or in the text between the tags
    #     doesn't cause issues.
    # (4) <ref .../>, where = and | occurring inside the tag doesn't cause issues.
    # Note that = and | inside of other HTML tags such as <span> *does* cause issues; e.g.
    # {{col|de|<span class="foo">bar</span>}} causes an error as '<span class' tries to get interpreted as a parameter
    # name. This is a bit strange because {{col|de|{{l|de|bar}}}} doesn't cause problems even though {{l|de|bar}}
    # generates HTML of the form '<span class="Latn" lang="de">[[:bar#German|bar]]</span>'.
    try:
        run = blib.parse_multi_delimiter_balanced_segment_run(
            val,
            [
                (r"\[\[", r"\]\]"),
                (r"\{\{", r"\}\}"),
                ("(?:<ref>|<ref [^<>]*[^/]>)", "</ref>"),
                ("<ref ", "/>"),
            ],
        )
    except blib.ParseException:
        # FIXME: Do something better in this case. Ideally we should make parse_multi_delimiter_balanced_segment_run()
        # have an `ignore_mismatch` flag.
        if "=" in val or "|" in val:
            pagemsg(
                "WARNING: Mismatched delimiters and found = or | in raw line to be templated, may lead to error: %s"
                % val
            )
        return val
    for j, segment in enumerate(run):
        if j % 2 == 0:
            run[j] = segment.replace("=", "{{=}}").replace("|", "{{!}}")
    return "".join(run)


def make_inline_modifier(key, val, pagemsg):
    return "<%s:%s>" % (
        key,
        escape_inline_val(escape_template_delimiters(val, pagemsg)),
    )


def lookup_langname(langname, prefer="lang"):
    if langname.endswith(" script"):
        langname = re.sub(" script$", "", langname)
        if langname in script_data.scripts_by_canonical_name:
            return script_data.scripts_by_canonical_name[langname]["code"], "script"
        return None, None
    if prefer == "script" and langname in script_data.scripts_by_canonical_name:
        return script_data.scripts_by_canonical_name[langname]["code"], "script"
    if prefer == "family" and langname in family_data.families_by_canonical_name:
        return family_data.families_by_canonical_name[langname]["code"], "family"
    if langname in lang_data.languages_by_canonical_name:
        return lang_data.languages_by_canonical_name[langname]["code"], "lang"
    elif langname in etym_lang_data.etym_languages_by_canonical_name:
        return etym_lang_data.etym_languages_by_canonical_name[langname]["code"], "etymlang"
    elif langname in family_data.families_by_canonical_name:
        return family_data.families_by_canonical_name[langname]["code"], "family"
    elif langname in script_data.scripts_by_canonical_name:
        return script_data.scripts_by_canonical_name[langname]["code"], "script"
    else:
        return None, None


def text_has_translation_template(txt):
    return re.search(
        r"\{\{ *(%s) *\|" % "|".join(re.escape(x) for x in blib.translation_templates),
        txt,
    )


# Convert a line/row from {{col*}} or from in between {{col-top}}/{{col-bottom}} etc. `line_non_templated` is True if
# the row came from between {{col-top}}/{{col-bottom}}, False if it came from an argument to {{col*}}. Return two
# values, a list of the links and any notes to add to the changelog message. If an error occurred during parsing, the
# first value is a string to display in place of a list. If the line doesn't begin with a raw or templated link, None
# is returned in place of the elements, indicating that the row should be left as-is.
#
# `langcode` is the langcode of the outer template being processed (e.g. {{col*}}), or the langcode of the section we're
# in, and `langname` is the corresponding language name. `pagemsg` is a function of one argument to display a warning or
# other message.
def convert_one_line(init_star, init_langname, rest, pagemsg, expand_text, in_multitrans):
    def make_inline_mod(key, val):
        return make_inline_modifier(key, val, pagemsg)

    quals_on_line = []
    # Letter or letters to add after the "t" during testing to distinguish new templates from old ones, so we can search
    # for any instances of unconverted templates. During production set to an empty string.
    distinguishing_new_insert = "q"
    multitrans_prefix = "t" if in_multitrans else ""
    if rest.endswith(","):
        rest = re.sub(r"\s*,$", "", rest)
    line = init_star + init_langname + rest
    if init_langname:
        if text_has_translation_template(init_langname):
            pagemsg("WARNING: Initial langname '%s' has translation template" % init_langname)
            init_langname = convert_one_line("", "", init_langname, pagemsg, expand_text, in_multitrans)
            line = init_star + init_langname + rest
        if rest == ":":
            rest = ""
        elif rest.startswith(":"):
            rest = rest[1:].strip()
    if rest:
        if init_langname:
            init_langname_code, init_langname_type = lookup_langname(
                init_langname, prefer="script" if init_star.startswith("*:") else "lang"
            )
            if not init_langname_code and init_langname in lang_utils.non_canonical_to_canonical_names:
                canonical_langname = lang_utils.non_canonical_to_canonical_names[init_langname]
                pagemsg("Mapping non-canonical name %s to canonical %s" % (init_langname, canonical_langname))
                init_langname = canonical_langname
                init_langname_code, init_langname_type = lookup_langname(
                    init_langname,
                    prefer="script" if init_star.startswith("*:") else "lang",
                )
                if not init_langname_code:
                    pagemsg(
                        "WARNING: INTERNAL ERROR: Canonical name %s in non_canonical_to_canonical_names isn't a valid language"
                        % init_langname
                    )
            if not init_langname_code:
                pagemsg("WARNING: Unrecognized initial langname %s" % init_langname)
        else:
            init_langname_code = None
            init_langname_type = None

        # Parts of the line as we build it up, not including any initial language name or preceding init_star argument.
        # We only append to this list once we're sure that the appended string is going into the final line.
        line_parts = []

        init_langname_prefix = None
        template_langcode = None
        template_langcode_suffix = ""
        template_tempname = "t" + distinguishing_new_insert + "-"
        # An "entry" is a single translation in a translation template, which is a single parameter possibly with inline
        # modifiers. This corresponds to an old-style {{t}}, {{t+}} or similar template. When we encounter an old-style
        # translation template, we set `entry` to the translation and any inline parameters taken from the template, but
        # we can't yet "close out" the template (append it as a parameter of a new-style translation template) because
        # there may be right labels, right qualifiers and/or references following that we want to incorporate if possible.
        #
        # We also want to incorporate left labels, qualifiers and such into a following old-style translation template,
        # but we don't know whether this is possible until we encounter such a template. Thus, we store the left qualifiers
        # and labels into lists below, but also build up the raw strings corresponding to these labels and qualifiers into
        # seen_raw_parts_before_translation[], so if we encounter an unknown template or an entry separator, we can output
        # the unprocessed text directly.
        entry = None
        left_qualifiers = []
        right_qualifiers = []
        left_labels = []
        right_labels = []
        entry_references = []
        # FIXME, we probably don't need this as non-local.
        entry_parts = []

        # See above. As we process left qualifiers and labels, we build up the corresponding raw strings in case we don't
        # encounter an old-style translation template that we can convert into an entry with left qualifier and label
        # inline modifiers. As soon as we encounter such a template, we reset this to an empty list, and don't track the
        # raw strings corresponding to right qualifiers, labels and references, since we know they will go into an entry.
        seen_raw_parts_before_translation = []
        # We need to store the first whitespace after an entry, in case we immediately encounter after that another entry
        # or an unrecognized template; otherwise we will wrongly eat the whitespace. Whenever we call append_template() to
        # close out and output any existing translations, after doing that we output anything stored in this variable, so
        # that the whitespace will appear before the following translation or unrecognized template. If we encounter a
        # right qualifier or other right part of an entry, we blank out this variable, as the whitespace forms part of the
        # qualifier.
        seen_raw_parts_after_translation = []

        # This is the list of processed entries (see above), each entry correponding to an old-style translation template
        # and all sharing the same langcode in `template_langcode`. There may be entry separators (semicolon, slash or
        # the raw string "~or") between entries, but not at the beginning or end.
        entries = []
        # An "entry separator", as mentioned above, is a semicolon, slash or "~or" raw value that goes in place of an entry
        # parameter in a new-style {{t}} or {{t-}} template. Entry separators only go *between* non-separators. If an entry
        # separator would go at the beginning or end, it is output raw, so we need to track this separator (both in its
        # param form and raw form) separately from seen_raw_parts_before_translation(), and only add it to the entry
        # parameters of a new-style {{t}}/{{t-}} template when the next entry is added. At this point we can set the
        # parameters to None. If we come across an old-style template that can't be appended into the current new-style
        # template (typically because the language code is different or because there is no old-style tempate to add to
        # (e.g. the previous value between commas was not an old-style translation template)), we first close out the
        # preceding old-style template (if any), add it to line_parts[], then output the raw entry separator to line_parts[]
        # and reset it to None.
        entry_separator = None
        raw_entry_separator = None

        def append_entry():
            nonlocal entry, left_labels, right_labels, left_qualifiers, right_qualifiers, entry_references, entry_parts
            nonlocal entry_separator, raw_entry_separator, seen_raw_parts_before_translation
            if entry is not None:
                if entry_separator is not None:
                    if not entries:
                        pagemsg(
                            "WARNING: INTERNAL ERROR: Attempting to append entry separator '%s' when no entries precede, entry='%s'"
                            % entry_separator,
                            entry,
                        )
                    entries.append(entry_separator)
                    entry_separator = None
                # entry_separator can be None (if it was a comma), but raw_entry_separator a string containing the comma
                raw_entry_separator = None
                if left_labels:
                    entry_parts.append(("l", ",".join(left_labels)))
                if right_labels:
                    entry_parts.append(("ll", ",".join(right_labels)))
                if left_qualifiers:
                    entry_parts.append(("q", ", ".join(left_qualifiers)))
                if right_qualifiers:
                    entry_parts.append(("qq", ", ".join(right_qualifiers)))
                if entry_references:
                    entry_parts.append(("ref", " !!! ".join(entry_references)))
                entries.append(entry + "".join("<%s:%s>" % (mod, escape_inline_val(val)) for mod, val in entry_parts))
                entry = None
                left_labels = []
                right_labels = []
                left_qualifiers = []
                right_qualifiers = []
                entry_references = []
                entry_parts = []
                seen_raw_parts_before_translation = []

        def append_template():
            nonlocal entries, seen_raw_parts_before_translation, entry_separator, raw_entry_separator, init_langname_prefix
            nonlocal seen_raw_parts_after_translation
            append_entry()
            if seen_raw_parts_before_translation:
                line_parts.extend(seen_raw_parts_before_translation)
            seen_raw_parts_before_translation = []
            if entries:
                line_parts.append(
                    "{{%s%s|%s%s|%s}}"
                    % (
                        multitrans_prefix,
                        template_tempname,
                        template_langcode,
                        template_langcode_suffix,
                        "|".join(entries),
                    )
                )
                entries = []
            if raw_entry_separator is not None:
                line_parts.append(raw_entry_separator)
                raw_entry_separator = None
                entry_separator = None
            if init_langname_prefix is None:
                init_langname_prefix = init_langname + ": " if init_langname else ""
            if seen_raw_parts_after_translation:
                line_parts.extend(seen_raw_parts_after_translation)
                seen_raw_parts_after_translation = []

        try:
            segments = blib.parse_multi_delimiter_balanced_segment_run(
                rest,
                [
                    (r"\(''", r"''\)"),
                    (r"\{\{", r"\}\}"),
                    ("(?:<ref>|<ref [^<>]*[^/]>)", "</ref>"),
                    ("<ref ", "/>"),
                ],
            )
        except blib.ParseException as e:
            # FIXME: Do something better in this case. Ideally we should make parse_multi_delimiter_balanced_segment_run()
            # have an `ignore_mismatch` flag.
            pagemsg("WARNING: Error parsing line using full delimiters, falling back to double braces only: %s" % e)
            try:
                segments = blib.parse_multi_delimiter_balanced_segment_run(rest, [(r"\{\{", r"\}\}")])
            except blib.ParseException as e:
                pagemsg("WARNING: Error parsing line using double braces only: %s" % e)
                return line

        alternating_runs = blib.split_alternating_runs(segments, r"(\s*[,;/]\s*|\s+or\s+)")

        # We used to implement conversion in an entirely left-to-right fashion but there were too many edge cases to worry
        # about. Instead we work bottom-up in multiple passes:
        # 1. Parse old translation templates and convert to a representation from which the new templates can be
        #    generated. We don't directly generate new templates at this stage because we may need to incorporate
        #    qualifiers, labels, references and/or glosses from nearby templates.
        # 2. For each template we parsed, look for adjoining qualifiers, labels, references and/or glosses and incorporate
        #    them. In the process, check for nested translation templates and make sure not to incorporate them; instead,
        #    call ourselves recursively to completely process (from start to finish) and convert the contents of the
        #    parameter(s) containing such templates. Output a warning about this.
        # 3. Check for any other unprocessed template containing nested translation templates, handle them similarly to
        #    step (2), and output a warning.
        # 4. Look for parsed templates that are separated by a recognized separator (comma, semicolon, slash, "or") and
        #    merge into a single new-style template. Output warnings for other separators.
        for i, alternating_run in enumerate(alternating_runs):
            if i % 2 == 1:
                alternating_run = "".join(alternating_run)
                if not entries:
                    if entry is not None:
                        pagemsg(
                            "WARNING: INTERNAL ERROR: Processing separator at position i=%s, j=%s and no entries but entry is '%s' rather than None; alternating_run='%s'"
                            % (i, j, entry, alternating_run)
                        )
                        append_template()
                    line_parts.append(alternating_run)
                else:
                    stripped_alternating_run = alternating_run.strip()
                    if entry_separator is not None:
                        pagemsg(
                            "WARNING: INTERNAL ERROR: Processing separator at position i=%s, j=%s and existing entry_separator='%s'; alternating_run='%s'"
                            % (i, j, entry_separator, alternating_run)
                        )
                    if stripped_alternating_run in [";", "/"]:
                        entry_separator = stripped_alternating_run
                    elif stripped_alternating_run == "or":
                        entry_separator = "~or"
                    else:
                        entry_separator = None
                        if stripped_alternating_run != ",":
                            pagemsg(
                                "WARNING: INTERNAL ERROR: Saw unrecognized alternating run delimiter '%s'"
                                % alternating_run
                            )
                    raw_entry_separator = alternating_run
                continue
            for j, segment in enumerate(alternating_run):
                if j % 2 == 0:
                    if segment.strip():
                        pagemsg(
                            "WARNING: Saw raw text '%s' between translations at position i=%s, j=%s, not sure how to handle"
                            % (segment, i, j)
                        )
                        append_template()
                        line_parts.append(segment)
                    else:
                        if entry is not None:
                            seen_raw_parts_after_translation.append(segment)
                        else:
                            seen_raw_parts_before_translation.append(segment)
                elif re.search(r"^\(", segment):
                    if text_has_translation_template(segment):
                        pagemsg(
                            "WARNING: Raw parenthesized expression %s at position i=%s, j=%s has embedded translation template"
                            % (segment, i, j)
                        )
                        append_template()
                        line_parts.append(
                            "("
                            + convert_one_line(
                                "",
                                "",
                                segment[1:-1],
                                pagemsg,
                                expand_text,
                                in_multitrans,
                            )
                            + ")"
                        )
                    else:
                        pagemsg(
                            "Converting raw parenthesized expression %s at position i=%s, j=%s into qualifier"
                            % (segment, i, j)
                        )
                        segment = segment[1:-1]
                        if segment.startswith("''") and segment.endswith("''"):
                            segment = segment[2:-2]
                        if entry is not None:
                            right_qualifiers.append(segment)
                            seen_raw_parts_after_translation = []
                        else:
                            left_qualifiers.append(segment)
                            seen_raw_parts_before_translation.append(segment)
                        quals_on_line.append(segment)
                elif re.search("^<ref", segment):
                    pagemsg("WARNING: Reference, can't handle yet: %s" % segment)
                    # FIXME
                elif re.search(
                    r"^\{\{ *(%s) *\|" % "|".join(re.escape(x) for x in blib.qualifier_templates),
                    segment,
                ):
                    qt = list(blib.parse_text(segment).filter_templates())[0]
                    quals = blib.fetch_param_chain(qt, "1")
                    processed_quals = []
                    saw_embedded_translation_template = False
                    for k, qual in enumerate(quals):
                        if text_has_translation_template(qual):
                            pagemsg(
                                "WARNING: Param %s= of qualifier template %s at position i=%s, j=%s has embedded translation template"
                                % (k + 1, segment, i, j)
                            )
                            processed_quals.append(convert_one_line("", "", qual, pagemsg, expand_text, in_multitrans))
                            saw_embedded_translation_template = True
                        else:
                            processed_quals.append(qual)
                    alternating_run[j] = Qualifier(
                        qualifiers=processed_quals,
                        saw_embedded_translation_template=saw_embedded_translation_template,
                    )
                    # if saw_embedded_translation_template:
                    #  append_template()
                    #  line_parts.append("{{q|%s}}" % "|".join(processed_quals))
                    # elif entry is not None:
                    #  right_qualifiers.extend(processed_quals)
                    #  seen_raw_parts_after_translation = []
                    #  quals_on_line.extend(processed_quals)
                    # else:
                    #  left_qualifiers.extend(processed_quals)
                    #  quals_on_line.extend(processed_quals)
                    #  seen_raw_parts_before_translation.append(segment)
                elif re.search(
                    r"^\{\{ *(%s) *\|" % "|".join(re.escape(x) for x in blib.translation_templates),
                    segment,
                ):
                    # if entry is not None:
                    #  pagemsg("WARNING: Saw two translation templates not delimiter-separated")
                    #  if seen_raw_parts_before_translation and "".join(seen_raw_parts_before_translation).strip():
                    #    pagemsg("WARNING: INTERNAL ERROR: Saw two translation templates not delimiter-separated and not separated by whitespace, but %s at position i=%s, j=%s" % (
                    #      seen_raw_parts_before_translation, i, j - 1))
                    #  append_template()
                    tt = list(blib.parse_text(segment).filter_templates())[0]
                    tn = tname(tt)

                    def getp(param):
                        return getparam(tt, param)

                    entry = "?" if tn == "t-needed" else getp("2")
                    genders = blib.fetch_param_chain(tt, "3")
                    entry_parts = []
                    if tn in ["t+", "tt+", "t+check", "tt+check"]:
                        entry += "<+>"
                    if tn in ["t-check", "t+check", "tt-check", "tt+check"]:
                        entry += "<check>"
                    if tn.startswith("tt"):
                        if not in_multitrans:
                            pagemsg("WARNING: Apparent multitrans template outside of multitrans section")
                    if genders:
                        entry_parts.append(("g", ",".join(genders)))
                    for param in ["alt", "id", "sc", "t", "tr", "ts", "lit"]:
                        val = getp(param)
                        if val:
                            entry_parts.append((param, val))
                    val = getp("l")
                    if val:
                        left_labels.append(val)
                    val = getp("ll")
                    if val:
                        right_labels.append(val)
                    val = getp("q")
                    if val:
                        left_qualifiers.append(val)
                    val = getp("qq")
                    if val:
                        right_qualifiers.append(val)
                    val = getp("ref")
                    if val:
                        entry_references.append(val)

                    langcode = getp("1")
                    if langcode in lang_data.languages_by_code:
                        langcode_langname = lang_data.languages_by_code[langcode]["canonicalName"]
                        langcode_type = "lang"
                    elif langcode in etym_lang_data.etym_languages_by_code:
                        langcode_langname = etym_lang_data.etym_languages_by_code[langcode]["canonicalName"]
                        langcode_type = "etymlang"
                    elif langcode in family_data.families_by_code:
                        langcode_langname = family_data.families_by_code[langcode]["canonicalName"]
                        langcode_type = "family"
                    else:
                        langcode_langname = None
                        langcode_type = None
                        pagemsg("WARNING: Unrecognized language code %s" % langcode)
                    matched_init_langname = None
                    if init_langname and langcode_langname and langcode_langname != init_langname:
                        if init_langname_code in etym_language_to_parent and (
                            langcode == etym_language_to_parent[init_langname_code]
                        ):
                            pagemsg(
                                "Replacing parent langcode %s with etym langcode %s for langname %s"
                                % (langcode, init_langname_code, init_langname)
                            )
                            langcode = init_langname_code
                            matched_init_langname = True
                        elif (
                            init_langname,
                            langcode,
                        ) in lang_utils.langcode_langname_to_correct_langcode:
                            new_langcode = lang_utils.langcode_langname_to_correct_langcode[(init_langname, langcode)]
                            pagemsg(
                                "WARNING: Mismatch between explicit language name %s (%s code %s) and %s code %s (language name %s), correcting to code %s, please check"
                                % (
                                    init_langname,
                                    init_langname_type,
                                    init_langname_code,
                                    langcode_type,
                                    langcode,
                                    langcode_langname,
                                    new_langcode,
                                )
                            )
                            langcode = new_langcode
                            matched_init_langname = True
                        elif init_langname_type == "script":
                            val_to_check = getp("alt") or getp("2")
                            if not val_to_check:
                                pagemsg(
                                    "WARNING: Saw script code %s in place of language for lang code %s and no value in translation template to check script of"
                                    % (init_langname_code, langcode)
                                )
                                matched_init_langname = False
                            else:
                                agrees = check_script_agrees(
                                    val_to_check,
                                    langcode,
                                    init_langname_code,
                                    pagemsg,
                                    expand_text,
                                    None,
                                    "converting explicit langname to :sc",
                                )
                                if agrees:
                                    template_langcode_suffix = ":sc"
                                    matched_init_langname = True
                                else:
                                    matched_init_langname = False
                        else:
                            if init_langname_type:
                                pagemsg(
                                    "WARNING: Mismatch between explicit language name %s (%s code %s) and %s code %s (language name %s)"
                                    % (
                                        init_langname,
                                        init_langname_type,
                                        init_langname_code,
                                        langcode_type,
                                        langcode,
                                        langcode_langname,
                                    )
                                )
                            matched_init_langname = False
                    elif not init_langname_code:
                        matched_init_langname = True
                    elif langcode_langname and langcode_langname == init_langname:
                        matched_init_langname = True
                    else:
                        matched_init_langname = False
                    if init_langname_prefix is None:
                        if matched_init_langname and init_langname:
                            template_tempname = "t" + distinguishing_new_insert
                        init_langname_prefix = (
                            "" if matched_init_langname else init_langname + ": " if init_langname else ""
                        )

                    if template_langcode and template_langcode != langcode:
                        pagemsg(
                            "WARNING: Saw two different langcodes %s and %s in translation line"
                            % (template_langcode, langcode)
                        )
                        append_template()
                    template_langcode = langcode

                else:
                    pagemsg("WARNING: Unrecognized template, can't handle yet: %s" % segment)
                    append_template()
                    if text_has_translation_template(segment):
                        if not segment.startswith("{{"):
                            pagemsg(
                                "WARNING: INTERNAL ERROR: Non-template %s at position i=%s, j=%s where template expected"
                                % (segment, i, j)
                            )
                        else:
                            parsed = blib.parse_text(segment)
                            templates = list(parsed.filter_templates())
                            if not templates:
                                pagemsg(
                                    "WARNING: Something strange, couldn't parse a template from segment %s at position i=%s, j=%s"
                                    % (segment, i, j)
                                )
                            else:
                                tt = templates[0]
                                for param in tt.params:
                                    pv = str(param.value)
                                    if text_has_translation_template(pv):
                                        pn = pname(param)
                                        pagemsg(
                                            "Converting nested translation template(s) in parameter %s=%s in segment %s at position i=%s, j=%s"
                                            % (pn, pv, segment, i, j)
                                        )
                                        newpv = convert_one_line(
                                            "",
                                            "",
                                            pv,
                                            pagemsg,
                                            expand_text,
                                            in_multitrans,
                                        )
                                        pagemsg(
                                            "Converted parameter %s=%s in segment %s at position i=%s, j=%s to %s"
                                            % (pn, pv, segment, i, j, newpv)
                                        )
                                        param.value = newpv
                            segment = str(parsed)
                    line_parts.append(segment)
            if entry is None:
                pagemsg("WARNING: Didn't see translation template between delimiters")
            else:
                append_entry()

        append_template()

        for qual in quals_on_line:
            seen_converted_quals[qual][template_langcode or "UNKNOWN"] += 1
            seen_converted_qual_count[qual] += 1
        return "%s%s%s" % (
            init_star or "",
            init_langname_prefix or "",
            "".join(line_parts),
        )
    else:
        return line


# Convert a line/row from {{col*}} or from in between {{col-top}}/{{col-bottom}} etc. `line_non_templated` is True if
# the row came from between {{col-top}}/{{col-bottom}}, False if it came from an argument to {{col*}}. Return two
# values, a list of the links and any notes to add to the changelog message. If an error occurred during parsing, the
# first value is a string to display in place of a list. If the line doesn't begin with a raw or templated link, None
# is returned in place of the elements, indicating that the row should be left as-is.
#
# `langcode` is the langcode of the outer template being processed (e.g. {{col*}}), or the langcode of the section we're
# in, and `langname` is the corresponding language name. `pagemsg` is a function of one argument to display a warning or
# other message.
def convert_one_line_old(init_star, init_langname, rest, pagemsg, expand_text, in_multitrans):
    def make_inline_mod(key, val):
        return make_inline_modifier(key, val, pagemsg)

    quals_on_line = []
    # Letter or letters to add after the "t" during testing to distinguish new templates from old ones, so we can search
    # for any instances of unconverted templates. During production set to an empty string.
    distinguishing_new_insert = "q"
    multitrans_prefix = "t" if in_multitrans else ""
    if rest.endswith(","):
        rest = re.sub(r"\s*,$", "", rest)
    line = init_star + init_langname + rest
    if init_langname:
        if text_has_translation_template(init_langname):
            pagemsg("WARNING: Initial langname '%s' has translation template" % init_langname)
            init_langname = convert_one_line("", "", init_langname, pagemsg, expand_text, in_multitrans)
            line = init_star + init_langname + rest
        if rest == ":":
            rest = ""
        elif rest.startswith(":"):
            rest = rest[1:].strip()
    if rest:
        if init_langname:
            init_langname_code, init_langname_type = lookup_langname(
                init_langname, prefer="script" if init_star.startswith("*:") else "lang"
            )
            if not init_langname_code and init_langname in lang_utils.non_canonical_to_canonical_names:
                canonical_langname = lang_utils.non_canonical_to_canonical_names[init_langname]
                pagemsg("Mapping non-canonical name %s to canonical %s" % (init_langname, canonical_langname))
                init_langname = canonical_langname
                init_langname_code, init_langname_type = lookup_langname(
                    init_langname,
                    prefer="script" if init_star.startswith("*:") else "lang",
                )
                if not init_langname_code:
                    pagemsg(
                        "WARNING: INTERNAL ERROR: Canonical name %s in non_canonical_to_canonical_names isn't a valid language"
                        % init_langname
                    )
            if not init_langname_code:
                pagemsg("WARNING: Unrecognized initial langname %s" % init_langname)
        else:
            init_langname_code = None
            init_langname_type = None

        # Parts of the line as we build it up, not including any initial language name or preceding init_star argument.
        # We only append to this list once we're sure that the appended string is going into the final line.
        line_parts = []

        init_langname_prefix = None
        template_langcode = None
        template_langcode_suffix = ""
        template_tempname = "t" + distinguishing_new_insert + "-"
        # An "entry" is a single translation in a translation template, which is a single parameter possibly with inline
        # modifiers. This corresponds to an old-style {{t}}, {{t+}} or similar template. When we encounter an old-style
        # translation template, we set `entry` to the translation and any inline parameters taken from the template, but
        # we can't yet "close out" the template (append it as a parameter of a new-style translation template) because
        # there may be right labels, right qualifiers and/or references following that we want to incorporate if possible.
        #
        # We also want to incorporate left labels, qualifiers and such into a following old-style translation template,
        # but we don't know whether this is possible until we encounter such a template. Thus, we store the left qualifiers
        # and labels into lists below, but also build up the raw strings corresponding to these labels and qualifiers into
        # seen_raw_parts_before_translation[], so if we encounter an unknown template or an entry separator, we can output
        # the unprocessed text directly.
        entry = None
        left_qualifiers = []
        right_qualifiers = []
        left_labels = []
        right_labels = []
        entry_references = []
        # FIXME, we probably don't need this as non-local.
        entry_parts = []

        # See above. As we process left qualifiers and labels, we build up the corresponding raw strings in case we don't
        # encounter an old-style translation template that we can convert into an entry with left qualifier and label
        # inline modifiers. As soon as we encounter such a template, we reset this to an empty list, and don't track the
        # raw strings corresponding to right qualifiers, labels and references, since we know they will go into an entry.
        seen_raw_parts_before_translation = []
        # We need to store the first whitespace after an entry, in case we immediately encounter after that another entry
        # or an unrecognized template; otherwise we will wrongly eat the whitespace. Whenever we call append_template() to
        # close out and output any existing translations, after doing that we output anything stored in this variable, so
        # that the whitespace will appear before the following translation or unrecognized template. If we encounter a
        # right qualifier or other right part of an entry, we blank out this variable, as the whitespace forms part of the
        # qualifier.
        seen_raw_parts_after_translation = []

        # This is the list of processed entries (see above), each entry correponding to an old-style translation template
        # and all sharing the same langcode in `template_langcode`. There may be entry separators (semicolon, slash or
        # the raw string "~or") between entries, but not at the beginning or end.
        entries = []
        # An "entry separator", as mentioned above, is a semicolon, slash or "~or" raw value that goes in place of an entry
        # parameter in a new-style {{t}} or {{t-}} template. Entry separators only go *between* non-separators. If an entry
        # separator would go at the beginning or end, it is output raw, so we need to track this separator (both in its
        # param form and raw form) separately from seen_raw_parts_before_translation(), and only add it to the entry
        # parameters of a new-style {{t}}/{{t-}} template when the next entry is added. At this point we can set the
        # parameters to None. If we come across an old-style template that can't be appended into the current new-style
        # template (typically because the language code is different or because there is no old-style tempate to add to
        # (e.g. the previous value between commas was not an old-style translation template)), we first close out the
        # preceding old-style template (if any), add it to line_parts[], then output the raw entry separator to line_parts[]
        # and reset it to None.
        entry_separator = None
        raw_entry_separator = None

        def append_entry():
            nonlocal entry, left_labels, right_labels, left_qualifiers, right_qualifiers, entry_references, entry_parts
            nonlocal entry_separator, raw_entry_separator, seen_raw_parts_before_translation
            if entry is not None:
                if entry_separator is not None:
                    if not entries:
                        pagemsg(
                            "WARNING: INTERNAL ERROR: Attempting to append entry separator '%s' when no entries precede, entry='%s'"
                            % entry_separator,
                            entry,
                        )
                    entries.append(entry_separator)
                    entry_separator = None
                # entry_separator can be None (if it was a comma), but raw_entry_separator a string containing the comma
                raw_entry_separator = None
                if left_labels:
                    entry_parts.append(("l", ",".join(left_labels)))
                if right_labels:
                    entry_parts.append(("ll", ",".join(right_labels)))
                if left_qualifiers:
                    entry_parts.append(("q", ", ".join(left_qualifiers)))
                if right_qualifiers:
                    entry_parts.append(("qq", ", ".join(right_qualifiers)))
                if entry_references:
                    entry_parts.append(("ref", " !!! ".join(entry_references)))
                entries.append(entry + "".join("<%s:%s>" % (mod, escape_inline_val(val)) for mod, val in entry_parts))
                entry = None
                left_labels = []
                right_labels = []
                left_qualifiers = []
                right_qualifiers = []
                entry_references = []
                entry_parts = []
                seen_raw_parts_before_translation = []

        def append_template():
            nonlocal entries, seen_raw_parts_before_translation, entry_separator, raw_entry_separator, init_langname_prefix
            nonlocal seen_raw_parts_after_translation
            append_entry()
            if seen_raw_parts_before_translation:
                line_parts.extend(seen_raw_parts_before_translation)
            seen_raw_parts_before_translation = []
            if entries:
                line_parts.append(
                    "{{%s%s|%s%s|%s}}"
                    % (
                        multitrans_prefix,
                        template_tempname,
                        template_langcode,
                        template_langcode_suffix,
                        "|".join(entries),
                    )
                )
                entries = []
            if raw_entry_separator is not None:
                line_parts.append(raw_entry_separator)
                raw_entry_separator = None
                entry_separator = None
            if init_langname_prefix is None:
                init_langname_prefix = init_langname + ": " if init_langname else ""
            if seen_raw_parts_after_translation:
                line_parts.extend(seen_raw_parts_after_translation)
                seen_raw_parts_after_translation = []

        try:
            segments = blib.parse_multi_delimiter_balanced_segment_run(
                rest,
                [
                    (r"\(''", r"''\)"),
                    (r"\{\{", r"\}\}"),
                    ("(?:<ref>|<ref [^<>]*[^/]>)", "</ref>"),
                    ("<ref ", "/>"),
                ],
            )
        except blib.ParseException as e:
            # FIXME: Do something better in this case. Ideally we should make parse_multi_delimiter_balanced_segment_run()
            # have an `ignore_mismatch` flag.
            pagemsg("WARNING: Error parsing line using full delimiters, falling back to double braces only: %s" % e)
            try:
                segments = blib.parse_multi_delimiter_balanced_segment_run(rest, [(r"\{\{", r"\}\}")])
            except blib.ParseException as e:
                pagemsg("WARNING: Error parsing line using double braces only: %s" % e)
                return line

        alternating_runs = blib.split_alternating_runs(segments, r"(\s*[,;/]\s*|\s+or\s+)")

        # We used to implement conversion in an entirely left-to-right fashion but there were too many edge cases to worry
        # about. Instead we work bottom-up in multiple passes:
        # 1. Parse old translation templates and convert to a representation from which the new templates can be
        #    generated. We don't directly generate new templates at this stage because we may need to incorporate
        #    qualifiers, labels, references and/or glosses from nearby templates.
        # 2. For each template we parsed, look for adjoining qualifiers, labels, references and/or glosses and incorporate
        #    them. In the process, check for nested translation templates and make sure not to incorporate them; instead,
        #    call ourselves recursively to completely process (from start to finish) and convert the contents of the
        #    parameter(s) containing such templates. Output a warning about this.
        # 3. Check for any other unprocessed template containing nested translation templates, handle them similarly to
        #    step (2), and output a warning.
        # 4. Look for parsed templates that are separated by a recognized separator (comma, semicolon, slash, "or") and
        #    merge into a single new-style template. Output warnings for other separators.
        for i, alternating_run in enumerate(alternating_runs):
            if i % 2 == 1:
                alternating_run = "".join(alternating_run)
                if not entries:
                    if entry is not None:
                        pagemsg(
                            "WARNING: INTERNAL ERROR: Processing separator at position i=%s, j=%s and no entries but entry is '%s' rather than None; alternating_run='%s'"
                            % (i, j, entry, alternating_run)
                        )
                        append_template()
                    line_parts.append(alternating_run)
                else:
                    stripped_alternating_run = alternating_run.strip()
                    if entry_separator is not None:
                        pagemsg(
                            "WARNING: INTERNAL ERROR: Processing separator at position i=%s, j=%s and existing entry_separator='%s'; alternating_run='%s'"
                            % (i, j, entry_separator, alternating_run)
                        )
                    if stripped_alternating_run in [";", "/"]:
                        entry_separator = stripped_alternating_run
                    elif stripped_alternating_run == "or":
                        entry_separator = "~or"
                    else:
                        entry_separator = None
                        if stripped_alternating_run != ",":
                            pagemsg(
                                "WARNING: INTERNAL ERROR: Saw unrecognized alternating run delimiter '%s'"
                                % alternating_run
                            )
                    raw_entry_separator = alternating_run
                continue
            for j, segment in enumerate(alternating_run):
                if j % 2 == 0:
                    if segment.strip():
                        pagemsg(
                            "WARNING: Saw raw text '%s' between translations at position i=%s, j=%s, not sure how to handle"
                            % (segment, i, j)
                        )
                        append_template()
                        line_parts.append(segment)
                    else:
                        if entry is not None:
                            seen_raw_parts_after_translation.append(segment)
                        else:
                            seen_raw_parts_before_translation.append(segment)
                elif re.search(r"^\(", segment):
                    if text_has_translation_template(segment):
                        pagemsg(
                            "WARNING: Raw parenthesized expression %s at position i=%s, j=%s has embedded translation template"
                            % (segment, i, j)
                        )
                        append_template()
                        line_parts.append(
                            "("
                            + convert_one_line(
                                "",
                                "",
                                segment[1:-1],
                                pagemsg,
                                expand_text,
                                in_multitrans,
                            )
                            + ")"
                        )
                    else:
                        pagemsg(
                            "Converting raw parenthesized expression %s at position i=%s, j=%s into qualifier"
                            % (segment, i, j)
                        )
                        segment = segment[1:-1]
                        if segment.startswith("''") and segment.endswith("''"):
                            segment = segment[2:-2]
                        if entry is not None:
                            right_qualifiers.append(segment)
                            seen_raw_parts_after_translation = []
                        else:
                            left_qualifiers.append(segment)
                            seen_raw_parts_before_translation.append(segment)
                        quals_on_line.append(segment)
                elif re.search("^<ref", segment):
                    pagemsg("WARNING: Reference, can't handle yet: %s" % segment)
                    # FIXME
                elif re.search(
                    r"^\{\{ *(%s) *\|" % "|".join(re.escape(x) for x in blib.qualifier_templates),
                    segment,
                ):
                    qt = list(blib.parse_text(segment).filter_templates())[0]
                    quals = blib.fetch_param_chain(qt, "1")
                    processed_quals = []
                    saw_embedded_translation_template = False
                    for k, qual in enumerate(quals):
                        if text_has_translation_template(qual):
                            pagemsg(
                                "WARNING: Param %s= of qualifier template %s at position i=%s, j=%s has embedded translation template"
                                % (k + 1, segment, i, j)
                            )
                            processed_quals.append(convert_one_line("", "", qual, pagemsg, expand_text, in_multitrans))
                            saw_embedded_translation_template = True
                        else:
                            processed_quals.append(qual)
                    alternating_run[j] = Qualifier(
                        qualifiers=processed_quals,
                        saw_embedded_translation_template=saw_embedded_translation_template,
                    )
                    # if saw_embedded_translation_template:
                    #  append_template()
                    #  line_parts.append("{{q|%s}}" % "|".join(processed_quals))
                    # elif entry is not None:
                    #  right_qualifiers.extend(processed_quals)
                    #  seen_raw_parts_after_translation = []
                    #  quals_on_line.extend(processed_quals)
                    # else:
                    #  left_qualifiers.extend(processed_quals)
                    #  quals_on_line.extend(processed_quals)
                    #  seen_raw_parts_before_translation.append(segment)
                elif re.search(
                    r"^\{\{ *(%s) *\|" % "|".join(re.escape(x) for x in blib.translation_templates),
                    segment,
                ):
                    if entry is not None:
                        pagemsg("WARNING: Saw two translation templates not delimiter-separated")
                        if seen_raw_parts_before_translation and "".join(seen_raw_parts_before_translation).strip():
                            pagemsg(
                                "WARNING: INTERNAL ERROR: Saw two translation templates not delimiter-separated and not separated by whitespace, but %s at position i=%s, j=%s"
                                % (seen_raw_parts_before_translation, i, j - 1)
                            )
                        append_template()
                    tt = list(blib.parse_text(segment).filter_templates())[0]
                    tn = tname(tt)

                    def getp(param):
                        return getparam(tt, param)

                    entry = "?" if tn == "t-needed" else getp("2")
                    genders = blib.fetch_param_chain(tt, "3")
                    entry_parts = []
                    if tn in ["t+", "tt+", "t+check", "tt+check"]:
                        entry += "<+>"
                    if tn in ["t-check", "t+check", "tt-check", "tt+check"]:
                        entry += "<check>"
                    if tn.startswith("tt"):
                        if not in_multitrans:
                            pagemsg("WARNING: Apparent multitrans template outside of multitrans section")
                    if genders:
                        entry_parts.append(("g", ",".join(genders)))
                    for param in ["alt", "id", "sc", "t", "tr", "ts", "lit"]:
                        val = getp(param)
                        if val:
                            entry_parts.append((param, val))
                    val = getp("l")
                    if val:
                        left_labels.append(val)
                    val = getp("ll")
                    if val:
                        right_labels.append(val)
                    val = getp("q")
                    if val:
                        left_qualifiers.append(val)
                    val = getp("qq")
                    if val:
                        right_qualifiers.append(val)
                    val = getp("ref")
                    if val:
                        entry_references.append(val)

                    langcode = getp("1")
                    if langcode in lang_data.languages_by_code:
                        langcode_langname = lang_data.languages_by_code[langcode]["canonicalName"]
                        langcode_type = "lang"
                    elif langcode in etym_lang_data.etym_languages_by_code:
                        langcode_langname = etym_lang_data.etym_languages_by_code[langcode]["canonicalName"]
                        langcode_type = "etymlang"
                    elif langcode in family_data.families_by_code:
                        langcode_langname = family_data.families_by_code[langcode]["canonicalName"]
                        langcode_type = "family"
                    else:
                        langcode_langname = None
                        langcode_type = None
                        pagemsg("WARNING: Unrecognized language code %s" % langcode)
                    matched_init_langname = None
                    if init_langname and langcode_langname and langcode_langname != init_langname:
                        if init_langname_code in etym_language_to_parent and (
                            langcode == etym_language_to_parent[init_langname_code]
                        ):
                            pagemsg(
                                "Replacing parent langcode %s with etym langcode %s for langname %s"
                                % (langcode, init_langname_code, init_langname)
                            )
                            langcode = init_langname_code
                            matched_init_langname = True
                        elif (
                            init_langname,
                            langcode,
                        ) in lang_utils.langcode_langname_to_correct_langcode:
                            new_langcode = lang_utils.langcode_langname_to_correct_langcode[(init_langname, langcode)]
                            pagemsg(
                                "WARNING: Mismatch between explicit language name %s (%s code %s) and %s code %s (language name %s), correcting to code %s, please check"
                                % (
                                    init_langname,
                                    init_langname_type,
                                    init_langname_code,
                                    langcode_type,
                                    langcode,
                                    langcode_langname,
                                    new_langcode,
                                )
                            )
                            langcode = new_langcode
                            matched_init_langname = True
                        elif init_langname_type == "script":
                            val_to_check = getp("alt") or getp("2")
                            if not val_to_check:
                                pagemsg(
                                    "WARNING: Saw script code %s in place of language for lang code %s and no value in translation template to check script of"
                                    % (init_langname_code, langcode)
                                )
                                matched_init_langname = False
                            else:
                                agrees = check_script_agrees(
                                    val_to_check,
                                    langcode,
                                    init_langname_code,
                                    pagemsg,
                                    expand_text,
                                    None,
                                    "converting explicit langname to :sc",
                                )
                                if agrees:
                                    template_langcode_suffix = ":sc"
                                    matched_init_langname = True
                                else:
                                    matched_init_langname = False
                        else:
                            if init_langname_type:
                                pagemsg(
                                    "WARNING: Mismatch between explicit language name %s (%s code %s) and %s code %s (language name %s)"
                                    % (
                                        init_langname,
                                        init_langname_type,
                                        init_langname_code,
                                        langcode_type,
                                        langcode,
                                        langcode_langname,
                                    )
                                )
                            matched_init_langname = False
                    elif not init_langname_code:
                        matched_init_langname = True
                    elif langcode_langname and langcode_langname == init_langname:
                        matched_init_langname = True
                    else:
                        matched_init_langname = False
                    if init_langname_prefix is None:
                        if matched_init_langname and init_langname:
                            template_tempname = "t" + distinguishing_new_insert
                        init_langname_prefix = (
                            "" if matched_init_langname else init_langname + ": " if init_langname else ""
                        )

                    if template_langcode and template_langcode != langcode:
                        pagemsg(
                            "WARNING: Saw two different langcodes %s and %s in translation line"
                            % (template_langcode, langcode)
                        )
                        append_template()
                    template_langcode = langcode

                else:
                    pagemsg("WARNING: Unrecognized template, can't handle yet: %s" % segment)
                    append_template()
                    if text_has_translation_template(segment):
                        if not segment.startswith("{{"):
                            pagemsg(
                                "WARNING: INTERNAL ERROR: Non-template %s at position i=%s, j=%s where template expected"
                                % (segment, i, j)
                            )
                        else:
                            parsed = blib.parse_text(segment)
                            templates = list(parsed.filter_templates())
                            if not templates:
                                pagemsg(
                                    "WARNING: Something strange, couldn't parse a template from segment %s at position i=%s, j=%s"
                                    % (segment, i, j)
                                )
                            else:
                                tt = templates[0]
                                for param in tt.params:
                                    pv = str(param.value)
                                    if text_has_translation_template(pv):
                                        pn = pname(param)
                                        pagemsg(
                                            "Converting nested translation template(s) in parameter %s=%s in segment %s at position i=%s, j=%s"
                                            % (pn, pv, segment, i, j)
                                        )
                                        newpv = convert_one_line(
                                            "",
                                            "",
                                            pv,
                                            pagemsg,
                                            p.expand_text,
                                            in_multitrans,
                                        )
                                        pagemsg(
                                            "Converted parameter %s=%s in segment %s at position i=%s, j=%s to %s"
                                            % (pn, pv, segment, i, j, newpv)
                                        )
                                        param.value = newpv
                            segment = str(parsed)
                    line_parts.append(segment)
            if entry is None:
                pagemsg("WARNING: Didn't see translation template between delimiters")
            else:
                append_entry()

        append_template()

        for qual in quals_on_line:
            seen_converted_quals[qual][template_langcode or "UNKNOWN"] += 1
            seen_converted_qual_count[qual] += 1
        return "%s%s%s" % (
            init_star or "",
            init_langname_prefix or "",
            "".join(line_parts),
        )
    else:
        return line


def process_text_on_page(p):
    notes = []

    origtext = p.text
    new_lines = []
    lines = p.text.split("\n")
    in_translation_section = False
    in_translation_box = False
    in_multitrans = False
    subsection_header = None
    translation_lines = None

    for lineno, line in enumerate(lines, start=1):
        origline = line

        def pagemsg(txt):
            p.msg("Line %s: %s: line = <begin> %s <end>" % (lineno, txt, origline))

        def expand_text(tempcall):
            return blib.expand_text(tempcall, p.title, pagemsg, args.verbose)

        m = re.search(r"^==+([^=\n]+)==+[ \t]*$", line)
        if m:
            subsection_header = m.group(1)
            if subsection_header == "Translations":
                in_translation_section = True
            else:
                in_translation_section = False
        if (in_translation_section or in_multitrans) and re.search(r"^\}\}", line):
            if not in_multitrans:
                pagemsg("WARNING: Apparent end of multitrans section not in multitrans")
            in_multitrans = False
        elif re.search(r"\{\{multitrans", line):  # don't get confused by {{multitrans}} in a closing comment
            if not in_translation_section:
                pagemsg(
                    "WARNING: Apparent {{multitrans}} start outside of ==Translations==, in ==%s==" % subsection_header
                )
            if in_multitrans:
                pagemsg("WARNING: Apparent nested multitrans section")
            in_multitrans = True
        if re.search(r"^\{\{(trans-top|checktrans-top|trans-top-see|trans-top-also)[|}]", line):
            if in_translation_box:
                pagemsg("WARNING: Nested translation boxes, skipping page")
                return
            in_translation_box = True
            if not in_translation_section:
                pagemsg("WARNING: Translation box not in ==Translations== section but in ==%s==" % subsection_header)
            new_lines.append(line)
        elif re.search(r"^\}* *\{\{trans-bottom", line):  # allow for multitrans closing braces before {{trans-bottom}}
            if not in_translation_box:
                pagemsg("WARNING: Found {{trans-bottom}} not in a translation box")
            in_translation_box = False
            new_lines.append(line)
        elif in_translation_box:
            m = re.search(r"^(\* *:* *)([^:]+)(:.*)$", line)
            if m:
                init_star, langname, rest = m.groups()
                newline = convert_one_line(init_star, langname, rest, pagemsg, expand_text, in_multitrans)
                if newline != line:
                    notes.append("convert translation line to {{t}}")
                    line = newline
            elif text_has_translation_template(line):
                newline = convert_one_line("", "", line, pagemsg, expand_text, in_multitrans)
                if newline != line:
                    notes.append("convert misformatted translation line to {{t}}")
                    line = newline
            new_lines.append(line)
        else:
            new_lines.append(line)

    if in_translation_box:
        pagemsg("WARNING: Page ended in a translation box, something wrong, skipping")
        return

    return "\n".join(new_lines), notes


#def process_text_on_page(p):
#    def make_inline_mod(key, val):
#        return make_inline_modifier(key, val, p.msg)
#
#    def extract_left_and_right_qualifiers_and_genders(line):
#        left_qual = []
#        right_qual = []
#        right_gloss = []
#        exterior_genders = []
#        line_comment = ""
#
#        m = re.search("^(.*)(<!--.*?-->)$", line)
#        if m:
#            line, line_comment = m.groups()
#            line = line.strip()
#
#        def extract_left_or_right_qualifier_or_gender(line, on_left=True):
#            this_qual = None
#            this_gender = None
#            this_gloss = None
#            # check for left qualifiers specified using a qualifier template
#            if on_left:
#                left_re = ""
#                right_re = " *(.*?)"
#            else:
#                left_re = "(.*?) *"
#                right_re = ""
#            m = None
#            if not m and not on_left:
#                m = re.search(r"^%s\{\{(?:g|g2)\|([^{}=]*)\}\}%s$" % (left_re, right_re), line)
#                if m:
#                    line, this_gender = m.groups()
#                    this_gender = this_gender.replace("|", ",")
#            if not m and not on_left:
#                m = re.search(r"^%s\{\{(?:gloss|gl)\|([^{}=]*)\}\}%s$" % (left_re, right_re), line)
#                if m:
#                    line, this_gloss = m.groups()
#                    this_gloss = this_gloss.replace("|", "; ")
#            if not m:
#                m = re.search(
#                    r"^%s\{\{(?:qualifier|qual|q|qf|i)\|([^{}=]*)\}\}%s$" % (left_re, right_re),
#                    line,
#                )
#                if m:
#                    this_qual, line = m.groups()
#            if not m:
#                # check for qualifier-like ''(...)''
#                m = re.search(r"^%s''\(([^'{}]*)\)''%s$" % (left_re, right_re), line)
#                if m:
#                    this_qual, line = m.groups()
#            if not m:
#                # check for qualifier-like (''...'')
#                m = re.search(r"^%s\(''([^'{}]*)''\)%s$" % (left_re, right_re), line)
#                if m:
#                    this_qual, line = m.groups()
#            if not m:
#                # check for somewhat qualifier-like ''...''
#                m = re.search(r"^%s''([^'{}]*)''%s$" % (left_re, right_re), line)
#                if m:
#                    this_qual, line = m.groups()
#            if not m and not on_left:
#                # check for parenthesized parts of speech on the right
#                m = re.search(
#                    r"^%s\((noun|verb|adjective|adverb)\)%s$" % (left_re, right_re),
#                    line,
#                )
#                if m:
#                    this_qual, line = m.groups()
#            if this_qual is not None and not on_left:
#                this_qual, line = line, this_qual
#            if this_qual is not None:
#                # Split on comma+space and on | (separate params), but not | or comma+space inside of links.
#                # Don't split if the qualifier text begins "literally".
#                if re.search("^'*literally", this_qual):
#                    this_qual = [this_qual]
#                else:
#                    segments = blib.parse_balanced_segment_run(this_qual, "[", "]")
#                    alternating_runs = blib.split_alternating_runs(segments, "(?:\||,\s+)")
#                    this_qual = ["".join(x) for x in alternating_runs]
#            return this_qual, this_gender, this_gloss, line
#
#        while True:
#            this_left_quals, this_left_gender, this_left_gloss, line = extract_left_or_right_qualifier_or_gender(
#                line, on_left=True
#            )
#            if this_left_quals is None:
#                break
#            left_qual.extend(this_left_quals)
#
#        while True:
#            this_right_quals, this_right_gender, this_right_gloss, line = extract_left_or_right_qualifier_or_gender(
#                line, on_left=False
#            )
#            if this_right_quals is None and this_right_gender is None and this_right_gloss is None:
#                break
#            if this_right_quals:
#                right_qual.extend(this_right_quals)
#            if this_right_gender:
#                exterior_genders.append(this_right_gender)
#            if this_right_gloss:
#                right_gloss.append(this_right_gloss)
#
#        return line, left_qual, right_qual, exterior_genders, right_gloss, line_comment
#
#    def construct_line_with_quals(vals, left_qual, right_qual, exterior_genders, right_gloss, line_comment):
#        def convert_quals(quals, is_left, has_pos, has_g):
#            qualparts = []
#            non_converted_quals = []
#            labels = []
#
#            def convert_qual(qual):
#                nonlocal has_pos, has_g
#                gender_map = {
#                    "m": "m",
#                    "m.": "m",
#                    "masc": "m",
#                    "masc.": "m",
#                    "masculine": "m",
#                    "f": "f",
#                    "f.": "f",
#                    "fem": "f",
#                    "fem.": "f",
#                    "feminine": "f",
#                    # "n": "n", existing uses seem to be "noun" not "neuter"
#                    # "n.": "n", existing uses seem to be "noun" not "neuter"
#                    "neut": "n",
#                    "neut.": "n",
#                    "neuter": "n",
#                    "mp": "m-p",
#                    "m.p.": "m-p",
#                    "m.pl.": "m-p",
#                    "m-p": "m-p",
#                    "m p": "m-p",
#                    "m pl": "m-p",
#                    "m. p.": "m-p",
#                    "m. pl.": "m-p",
#                    "masc pl": "m-p",
#                    "masc. pl.": "m-p",
#                    "masculine plural": "m-p",
#                    "fp": "f-p",
#                    "f.p.": "f-p",
#                    "f.pl.": "f-p",
#                    "f-p": "f-p",
#                    "f p": "f-p",
#                    "f pl": "f-p",
#                    "f. p.": "f-p",
#                    "f. pl.": "f-p",
#                    "fem pl": "f-p",
#                    "fem. pl.": "f-p",
#                    "feminine plural": "f-p",
#                    "np": "n-p",
#                    "n.p.": "n-p",
#                    "n.pl.": "n-p",
#                    "n-p": "n-p",
#                    "n p": "n-p",
#                    "n pl": "n-p",
#                    "n. p.": "n-p",
#                    "n. pl.": "n-p",
#                    "neut pl": "n-p",
#                    "neut. pl.": "n-p",
#                    "neuter plural": "f-p",
#                    "pl": "p",
#                    "pl.": "p",
#                    "plural": "p",
#                }
#                label_map = {
#                    "archaic or obsolete": "archaic,or,obsolete",
#                    "Sanskritized, rare": "Sanskritized,rare",
#                    "Sanskritized, Rare": "Sanskritized,rare",
#                    "Sanskritized, literary": "Sanskritized,literary",
#                    "Sanskritized, formal or literary": "Sanskritized,formal,or,literary",
#                    "Persianized, rare": "Persianized,rare",
#                    "chiefly Islam": "chiefly,Islam",
#                    "chiefly Hinduism": "chiefly,Hinduism",
#                    "Mediaeval Latin": "Medieval Latin",
#                    "Med. Lat.": "Medieval Latin",
#                    "Mediaeval": "Medieval",
#                    "BrE": "UK",
#                    "obsolete, rare": "obsolete,rare",
#                    "zoölogy": "zoology",
#                    "South African English": "South Africa",
#                    "place name": "toponym",
#                    "placename": "toponym",
#                    "place": "toponym",
#                    "Colloquial": "colloquial",
#                    "Rare": "rare",
#                    "patronym": "patronymic",
#                    "Diminutives:": "diminutive",
#                    "Endearing forms:": "endearing",
#                    "Pejorative forms:": "pejorative",
#                    "Patronymics:": "patronymic",
#                    "Surnames:": "surname",
#                    "New vocatives:": "new vocative",
#                    "New vocative:": "new vocative",
#                    "factative": "factitive",
#                }
#                pos_map = {
#                    "adj.": "adj",
#                    "adjective and noun": "adjective, noun",
#                    "n.": "n",
#                    "intransitive": "vi",
#                    "transitive": "vt",
#                }
#                m = re.search("^'*literally[:;'\" ]+(.*?)['\"]?$", qual)
#                if m:
#                    qualparts.append(make_inline_mod("lit", m.group(1)))
#                elif qual in label_map:
#                    labels.append(label_map[qual])
#                elif qual in [
#                    "rare",
#                    "uncommon",
#                    "colloquial",
#                    "informal",
#                    "nonstandard",
#                    "non-standard",
#                    "offensive",
#                    "figurative",
#                    "figuratively",
#                    "formal",
#                    "learned",
#                    "impersonal",
#                    "slang",
#                    "vulgar",
#                    "literary",
#                    "historical",
#                    "humble speech",
#                    "jocular",
#                    "euphemistic",
#                    "derogatory",
#                    "expressive",
#                    "vernacular",
#                    "childish",
#                    "abbreviation",
#                    "initialism",
#                    "back-formation",
#                    "clipping",
#                    "blend",
#                    "proverb",
#                    "active",
#                    "passive",
#                    "reflexive",
#                    "mediopassive",
#                    "iterative",
#                    "causative",
#                    "causative-iterative",
#                    "collective",
#                    "dialectal",
#                    "regional",
#                    "poetic",
#                    "uncertain",
#                    "honorific",
#                    "nickname",
#                    "pejorative",
#                    "humorous",
#                    "toponym",
#                    "surname",
#                    "patronymic",
#                    "female patronymic",
#                    "male patronymic",
#                    "former name",
#                    "obsolete",
#                    "archaic",
#                    "dated",
#                    "deprecated",
#                    "diminutive",
#                    "augmentative",
#                    "endearing",
#                    "semelfactive",
#                    "US",
#                    "American",
#                    "North America",
#                    "Canada",
#                    "Canadian",
#                    "UK",
#                    "British",
#                    "Britain",
#                    "British English",
#                    "Australia",
#                    "Australian",
#                    "Ireland",
#                    "Irish",
#                    "New Zealand",
#                    "Indian English",
#                    "AU",
#                    "NZ",
#                    "Anglo-Norman",
#                    "Standard Malay",
#                    "Indonesian",
#                    "Spain",
#                    "Argentina",
#                    "Venezuela",
#                    "Dominican Republic",
#                    "Costa Rica",
#                    "Mexico",
#                    "Puerto Rico",
#                    "Paraguay",
#                    "Uruguay",
#                    "Chile",
#                    "Bolivia",
#                    "Colombia",
#                    "Costa Rica",
#                    "Cuba",
#                    "Panama",
#                    "Nicaragua",
#                    "Ecuador",
#                    "El Salvador",
#                    "Honduras",
#                    "Peru",
#                    "Guatemala",
#                    "Brazil",
#                    "Portugal",
#                    "Belize",
#                    "Puter",
#                    "Sursilvan",
#                    "Sutsilvan",
#                    "Surmiran",
#                    "Vallader",
#                    "Rumantsch Grischun",
#                    "sports",
#                    "medicine",
#                    "law",
#                    "logic",
#                    "shipping",
#                    "theology",
#                    "phonology",
#                    "music",
#                    "grammar",
#                    "religion",
#                    "linguistics",
#                    "geology",
#                    "botany",
#                    "ornithology",
#                    "sociology",
#                    "psychiatry",
#                    "zoology",
#                    "anatomy",
#                    "chemistry",
#                    "architecture",
#                    "phonetics",
#                    "biology",
#                    "astronomy",
#                    "Sanskritized",
#                    "Sanskritised",
#                    "Persianized",
#                    "Persianised",
#                    "Netherlands",
#                    "Late Latin",
#                    "Classical",
#                    "Byzantine",
#                    "Vulgar Latin",
#                    "Medieval Latin",
#                    "New Latin",
#                    "Katharevousa",
#                    "Gheg",
#                    "Standard",
#                    "Tosk",
#                    "Arbërisht",
#                    "Arvanitic",
#                    "East Slavic",
#                    "North Korea",
#                    "South Korea",
#                    "Münsterländisch",
#                    "Kamviri",
#                    "Altmärkisch",
#                    "North Germanic",
#                    "Pulaar",
#                    "Pular",  # two different languages!
#                    "Maasina",
#                    "Adamawa",
#                    "Kuril Ainu",
#                    "Northern Finnic",
#                    "Ecclesiastical",
#                    "Quebec",
#                    "Austria",
#                    "Algherese",
#                ]:
#                    labels.append(qual)
#                elif not has_pos and qual in pos_map:
#                    qualparts.append(make_inline_mod("pos", pos_map[qual]))
#                    has_pos = True
#                elif not has_pos and qual in [
#                    "noun",
#                    "n",
#                    "proper noun",
#                    "adjective",
#                    "adj",
#                    "verb",
#                    "v",
#                    "vb",
#                    "adverb",
#                    "adv",
#                    "preposition",
#                    "prep",
#                    "conjunction",
#                    "conj",
#                    "verbal noun",
#                    "[[vi]]",
#                    "[[vt]]",
#                    "participle",
#                    "adjective, noun",
#                    "agent nouns",
#                    "agent noun",
#                    "[[na]]",
#                    "[[ni]]",
#                    "[[vai]]",
#                    "[[vii]]",
#                    "[[vti]]",
#                    "[[vta]]",
#                    "na",
#                    "ni",
#                    "vai",
#                    "vii",
#                    "vti",
#                    "vta",
#                    "instrumental nouns",
#                    "instrumental noun",
#                    "action noun",
#                    "gerund",
#                ]:
#                    qualparts.append(make_inline_mod("pos", qual.replace("[[", "").replace("]]", "")))
#                    has_pos = True
#                elif not has_g and qual in gender_map:
#                    if is_left:
#                        qualparts.append(make_inline_mod("g", gender_map[qual]))
#                        has_g = True
#                    else:
#                        exterior_genders.append(gender_map[qual])
#                else:
#                    seen_quals[qual] += 1
#                    non_converted_quals.append(qual)
#
#            for qual in quals:
#                convert_qual(qual)
#            if labels:
#                qualparts.append(make_inline_mod("l" if is_left else "ll", ",".join(labels)))
#            if non_converted_quals:
#                qualparts.append(make_inline_mod("q" if is_left else "qq", ", ".join(non_converted_quals)))
#            return "".join(qualparts)
#
#        if left_qual:
#            vals[0] += convert_quals(left_qual, True, "<pos:" in vals[0], "<g:" in vals[0])
#        if right_qual:
#            vals[-1] += convert_quals(right_qual, False, "<pos:" in vals[-1], "<g:" in vals[-1])
#        if exterior_genders:
#            if "<g:" in vals[-1]:
#                p.msg("WARNING: Saw both interior and exterior genders, trying to combine")
#                vals[-1] = re.sub(
#                    "(<g:.*?)>",
#                    r"\1,%s>" % escape_inline_val(",".join(exterior_genders)),
#                    vals[-1],
#                )
#            else:
#                vals[-1] += make_inline_mod("g", ",".join(exterior_genders))
#        if right_gloss:
#            if "<t:" in vals[-1]:
#                p.msg("WARNING: Saw both interior and exterior glosses, trying to combine")
#                vals[-1] = re.sub(
#                    "(<t:.*?)>",
#                    r"\1; %s>" % escape_inline_val("; ".join(right_gloss)),
#                    vals[-1],
#                )
#            else:
#                vals[-1] += make_inline_mod("t", "; ".join(right_gloss))
#        return ",".join(vals) + line_comment
#
#    notes = []
#
#    secs = blib.split_text_into_sections(p.text, p.msg)
#    sections = secs.sections
#    for j, langname in secs.lang_list:
#        if langname not in lang_data.languages_by_canonical_name:
#            p.msg("WARNING: Unknown language name %s, skipping section %s" % (langname, j // 2))
#            continue
#        langcode = lang_data.languages_by_canonical_name[langname]["code"]
#        subsecs = blib.split_text_into_subsections(sections[j], p.msg)
#        for k, header in subsecs.header_list:
#            if args.do_col and re.search(r"\{\{ *col[0-9]* *\|", subsecs.subsections[k]):
#                parsed = blib.parse_text(subsecs.subsections[k])
#                for t in parsed.filter_templates():
#                    tn = tname(t)
#                    if tn in ["col", "col1", "col2", "col3", "col4", "col5", "col6"]:
#                        newparams = []
#                        numrows = 0
#                        numchangedrows = 0
#                        origt = str(t)
#                        tlang = getparam(t, "1").strip()
#                        for param in t.params:
#                            pn = pname(param)
#                            pv = str(param.value)
#                            if pn != "1" and re.search("^[0-9]+$", pn):
#                                numrows += 1
#                                m = re.search(r"(\s*)(.*?)(\s*)$", pv, re.S)
#                                beginspace, maintext, endspace = m.groups()
#                                (
#                                    newmaintext,
#                                    left_qual,
#                                    right_qual,
#                                    exterior_genders,
#                                    right_gloss,
#                                    line_comment,
#                                ) = extract_left_and_right_qualifiers_and_genders(maintext)
#                                newparts, new_notes = convert_one_line(
#                                    newmaintext,
#                                    False,
#                                    langcode,
#                                    langname,
#                                    p.msg,
#                                    p.expand_text,
#                                )
#                                if type(newparts) is str:
#                                    p.msg("WARNING: %s, not changing: %s" % (newparts, pv.strip()))
#                                elif newparts is not None:
#                                    newmaintext = construct_line_with_quals(
#                                        newparts,
#                                        left_qual,
#                                        right_qual,
#                                        exterior_genders,
#                                        right_gloss,
#                                        line_comment,
#                                    )
#                                    newpv = beginspace + newmaintext + endspace
#                                    numchangedrows += 1
#                                    p.msg(
#                                        "Replaced %s=<%s> with <%s> in {{%s|%s}} in ==%s=="
#                                        % (
#                                            pn,
#                                            pv.strip(),
#                                            newpv.strip(),
#                                            tn,
#                                            tlang,
#                                            header,
#                                        )
#                                    )
#                                    pv = newpv
#                                    notes.extend(new_notes)
#                            newparams.append((pn, pv, param.showkey))
#                        del t.params[:]
#                        for pn, pv, showkey in newparams:
#                            t.add(pn, pv, showkey=showkey, preserve_spacing=False)
#                        if origt != str(t):
#                            notes.append(
#                                "optimize %s of %s row%s in {{%s|%s}} in ==%s=="
#                                % (
#                                    numchangedrows,
#                                    numrows,
#                                    "s" if numrows != 1 else "",
#                                    tn,
#                                    tlang,
#                                    header,
#                                )
#                            )
#                subsecs.subsections[k] = str(parsed)
#
#            expected_abbrev = header_to_col_top_abbrev.get(header, None)
#            lines = subsecs.subsections[k].split("\n")
#            newlines = []
#            raw_col_lines = None
#            col_elements = None
#            if args.do_derived_related:
#                if header in ["Derived terms", "Related terms"]:
#                    in_col_top = True
#                    lines.append("\ufff0")  # sentinel line
#                    raw_col_lines = []
#                    for line in lines:
#                        if line.startswith("*"):
#                            raw_col_lines.append(line)
#                        else:
#                            break
#                    total_processable_lines = len(raw_col_lines)
#                    if total_processable_lines < args.min_derived_related_lines:
#                        p.msg(
#                            "Saw only %s element%s in ==%s==, can't convert to {{col}}"
#                            % (
#                                total_processable_lines,
#                                "" if total_processable_lines == 1 else "s",
#                                header,
#                            )
#                        )
#                        in_col_top = False
#                    raw_col_lines = []
#                    col_elements = []
#                else:
#                    in_col_top = False
#            else:
#                in_col_top = False
#            col_top_tn = None
#            new_notes = []
#            cant_convert = False
#            col_top_header = None
#            for line in lines:
#                if in_col_top:
#                    raw_col_lines.append(line)
#                    if args.do_derived_related and not line.startswith("*"):
#                        if len(col_elements) < args.min_derived_related_lines:
#                            p.msg(
#                                "Processed %s element%s out of %s in ==%s== before getting to an unconvertible element"
#                                % (
#                                    len(col_elements),
#                                    "" if len(col_elements) == 1 else "s",
#                                    total_processable_lines,
#                                    header,
#                                )
#                            )
#                            cant_convert = True
#                            newlines.extend(raw_col_lines)
#                            in_col_top = False
#                            continue
#                        elif cant_convert:
#                            newlines.extend(raw_col_lines)
#                            in_col_top = False
#                            continue
#                        else:
#                            no_sort_param = ""
#                            if p.title in no_sort_lists:
#                                for no_sort_lang, no_sort_firstel in no_sort_lists[p.title]:
#                                    if no_sort_lang == langcode:
#                                        if no_sort_firstel == col_elements[0][1:]:
#                                            no_sort_param = "|sort=0"
#                                        else:
#                                            p.msg(
#                                                "WARNING: Found no-sort directive matching langcode '%s' but specified first element '%s' didn't match actual first element '%s'"
#                                                % (
#                                                    langcode,
#                                                    no_sort_firstel,
#                                                    col_elements[0][1:],
#                                                )
#                                            )
#                            newlines.append("{{col|%s%s" % (langcode, no_sort_param))
#                            newlines.extend(col_elements)
#                            newlines.append("}}")
#                            newlines.append(line)
#                            notes.extend(new_notes)
#                            notes.append(
#                                "convert %s raw elements under ==%s== to {{col|%s%s|%s|%s|...}}"
#                                % (
#                                    len(col_elements),
#                                    header,
#                                    langcode,
#                                    no_sort_param,
#                                    col_elements[0][1:],
#                                    col_elements[1][1:],
#                                )
#                            )
#                            in_col_top = False
#                            continue
#                    m = re.search("^\{\{ *((?:col-)?bottom) *\|", line.strip())
#                    if m:
#                        if not cant_convert:
#                            p.msg(
#                                "WARNING: Saw {{%s}} with params, can't convert to {{col}}: %s" % (m.group(1), origline)
#                            )
#                        newlines.extend(raw_col_lines)
#                        in_col_top = False
#                        continue
#                    m = re.search("^\{\{ *((?:col-)?bottom) *\}\}$", line.strip())
#                    if m:
#                        if cant_convert:
#                            newlines.extend(raw_col_lines)
#                            in_col_top = False
#                            continue
#                        if col_top_header and col_top_header != expected_abbrev:
#                            col_top_header = shortcut_to_expansion.get(col_top_header, col_top_header)
#                        else:
#                            col_top_header = ""
#                        col_bottom_tn = m.group(1)
#                        newlines.append(
#                            "{{col|%s%s"
#                            % (
#                                langcode,
#                                "|title=%s" % col_top_header if col_top_header else "",
#                            )
#                        )
#                        newlines.extend(col_elements)
#                        newlines.append("}}")
#                        notes.extend(new_notes)
#                        notes.append(
#                            "convert {{%s}}/{{%s}} to {{col|%s|...}} with %s line%s in ==%s=="
#                            % (
#                                col_top_tn,
#                                col_bottom_tn,
#                                langcode,
#                                len(col_elements),
#                                "" if len(col_elements) == 1 else "s",
#                                header,
#                            )
#                        )
#                        in_col_top = False
#                        continue
#                    if cant_convert:
#                        continue
#                    if not line.startswith("*"):
#                        p.msg("WARNING: Non-bulleted line, can't convert to {{col}} (yet?): %s" % line)
#                        cant_convert = True
#                        continue
#                    if re.search(r"\{\{ *desc *\|", line):
#                        p.msg("WARNING: Line with {{desc}}, can't convert to {{col}}: %s" % line)
#                        cant_convert = True
#                        continue
#                    if re.search(r"\{\{ *desctree *\|", line):
#                        p.msg("WARNING: Line with {{desctree}}, can't convert to {{col}}: %s" % line)
#                        cant_convert = True
#                        continue
#                    m = re.search(r"^(\*+)(.*)$", line)
#                    if not m:
#                        p.msg("WARNING: INTERNAL ERROR: Line doesn't have a term after a single bullet: %s" % line)
#                        cant_convert = True
#                        continue
#                    origline = line
#                    number_of_bullets, line = m.groups()
#                    if re.search("^[:#]", line):
#                        p.msg("WARNING: Saw *: or *# at beginning of line, can't convert to {{col}}: %s" % origline)
#                        cant_convert = True
#                        continue
#                    if len(number_of_bullets) == 1:
#                        bullet_prefix = ""
#                    else:
#                        bullet_prefix = number_of_bullets[1:] + " "
#                    line = line.strip()
#                    bulleted_line = escape_template_delimiters(bullet_prefix + line, p.msg)
#                    if re.search(
#                        r"\{\{ *(ja-l|ja-r|ja-r/args|ryu-l|ryu-r|ryu-r/args|ko-l|zh-l|vi-l|he-l) *\|",
#                        line,
#                    ):
#                        p.msg(
#                            "WARNING: Unable to convert specialized Asian linking template to {{col}} format, inserting raw: %s"
#                            % origline
#                        )
#                        col_elements.append("|%s" % bulleted_line)
#                        continue
#                    if re.search(r"\{\{ *(vern|taxfmt|taxlink) *\|", line):
#                        p.msg(
#                            "WARNING: Unable to convert specialized taxonomy linking template to {{col}} format, inserting raw: %s"
#                            % origline
#                        )
#                        col_elements.append("|%s" % bulleted_line)
#                        continue
#
#                    def handle_parse_error(reason):
#                        nonlocal cant_convert
#                        if re.search(match_link_template_re, line):
#                            p.msg("WARNING: %s and line has templated link, inserting raw: %s" % (reason, origline))
#                            col_elements.append("|%s" % bulleted_line)
#                        else:
#                            p.msg(
#                                "WARNING: %s and no templated link present, can't convert to {{col}}: %s"
#                                % (reason, origline)
#                            )
#                            cant_convert = True
#
#                    (
#                        line,
#                        left_qual,
#                        right_qual,
#                        exterior_genders,
#                        right_gloss,
#                        line_comment,
#                    ) = extract_left_and_right_qualifiers_and_genders(line)
#                    els, this_new_notes = convert_one_line(line, True, langcode, langname, p.msg, p.expand_text)
#                    if type(els) is str:
#                        handle_parse_error(els)
#                    elif els is None:
#                        handle_parse_error("Can't parse links")
#                    else:
#                        newline = "|%s%s" % (
#                            bullet_prefix,
#                            construct_line_with_quals(
#                                els,
#                                left_qual,
#                                right_qual,
#                                exterior_genders,
#                                right_gloss,
#                                line_comment,
#                            ),
#                        )
#                        col_elements.append(newline)
#                        new_notes.extend(this_new_notes)
#
#                else:
#                    m = None
#                    if not m and args.do_col_top:
#                        m = re.search(r"^\{\{(col-top)\|[0-9]+\|([^|=]*)\}\}$", line)
#                        if m:
#                            col_top_tn, col_top_header = m.groups()
#                    if not m and args.do_top:
#                        m = re.search(r"^\{\{(top[0-9])\}\}$", line)
#                        if m:
#                            col_top_tn = m.group(1)
#                            col_top_header = ""
#                    if not m and args.do_top:
#                        m = re.search(r"^\{\{(top[0-9])\|([^{}]*)\}\}$", line)
#                        if m:
#                            col_top_tn, col_top_header = m.groups()
#                            if col_top_header == langcode:
#                                col_top_header = ""
#                            if col_top_header.startswith("title="):
#                                col_top_header = col_top_header[6:]
#                    if m:
#                        in_col_top = True
#                        col_elements = []
#                        new_notes = []
#                        cant_convert = False
#                        raw_col_lines = [line]
#                    else:
#                        newlines.append(line)
#            if in_col_top:
#                p.msg("WARNING: Saw {{col-top}} without closing {{col-bottom}}")
#                newlines.extend(raw_col_lines)
#            subsecs.subsections[k] = "\n".join(x for x in newlines if x != "\ufff0")  # exclude sentinel
#        sections[j] = "".join(subsecs.subsections)
#
#    return "".join(sections), notes

if __name__ == "__main__":
    parser = blib.create_argparser(
        "Convert translation lines to new-syntax {{t}}",
        include_pagefile=True,
        include_stdin=True,
    )
    args = parser.parse_args()
    start, end = blib.parse_start_end(args.start, args.end)

    blib.do_pagefile_cats_refs(args, start, end, process_text_on_page)

    msg("")
    header = "%-50s | %5s | %s" % ("Qualifier", "Count", "By lang")
    msg(header)
    msg("-" * len(header))
    for qual, count in sorted(seen_converted_qual_count.items(), key=lambda x: -x[1]):
        by_lang = ", ".join(
            "%s=%s" % (k, v) for k, v in sorted(seen_converted_quals[qual].items(), key=lambda x: -x[1])
        )
        msg("%-50s | %5s | %s" % (qual, count, by_lang))
