#!/usr/bin/env python3

import pywikibot, re, itertools
from dataclasses import dataclass
from mwparserfromhell.nodes import Template

from wingerbot import blib
from wingerbot.blib import getparam, msg, errandmsg, site, tname
from wingerbot.latin import lalib, la_clean_long_vowels

heads_and_defns_cache = {}
infl_forms_cache = {}
get_headword_from_template_cache = {}
expand_text_cache = {}


@dataclass
class LookupInflectionResult:
    found_heads: list[str]
    found_inflsets: list[dict[str, str]]

    def props(self):
        return self.found_heads, self.found_inflsets

# Look up the inflection(s) of LEMMA (without macrons), of part of speech POS,
# which uses a head template in EXPECTED_HEADTEMPS and an inflection template
# in EXPECTED_INFLTEMPS. Return a list of tuples (FOUND_HEADS, FOUND_INFLSETS)
# where FOUND_HEADS is a list of all the actual heads found in the head
# template (usually only one) and FOUND_INFLSETS is a list of the sets of
# inflections associated with the head template (there will be multiple sets
# if there are multiple inflection templates underneath a given head
# template). Each "inflection set" is actually a dictionary mapping slot
# names to forms (each form value in the map needs to be split on commas in
# case there are multiple forms for the slot).
def lookup_inflection(lemma_no_macrons, pos, expected_headtemps, expected_infltemps, orig_pagemsg, orig_errandpagemsg) -> list[LookupInflectionResult] | None:
    lemma_pagetitle = lemma_no_macrons
    if lemma_pagetitle.startswith("*"):
        lemma_pagetitle = "Reconstruction:Latin/" + lemma_pagetitle[1:]

    def pagemsg(txt):
        orig_pagemsg("%s: %s" % (lemma_no_macrons, txt))
    def errandpagemsg(txt):
        orig_errandpagemsg("%s: %s" % (lemma_no_macrons, txt))
    def expand_text(tempcall):
        cache_key = (tempcall, lemma_pagetitle)
        if cache_key in expand_text_cache:
            retval = expand_text_cache[cache_key]
            if args.verbose:
                pagemsg("Found (%s, %s)=%s in expand_text_cache" % (tempcall, lemma_pagetitle, retval))
            return retval
        if args.verbose:
            pagemsg("Couldn't find (%s, %s) in expand_text_cache" % (tempcall, lemma_pagetitle))
        result = blib.expand_text(tempcall, lemma_pagetitle, pagemsg, args.verbose)
        expand_text_cache[cache_key] = result
        return result

    if lemma_pagetitle in heads_and_defns_cache:
        if args.verbose:
            pagemsg("Found %s in heads_and_defns_cache" % lemma_pagetitle)
        retval = heads_and_defns_cache[lemma_pagetitle]
    else:
        if args.verbose:
            pagemsg("Couldn't find %s in heads_and_defns_cache" % lemma_pagetitle)
        page = pywikibot.Page(site, lemma_pagetitle)
        if not blib.safe_page_exists(page, errandpagemsg):
            pagemsg("WARNING: Lemma %s doesn't exist" % lemma_no_macrons)
            heads_and_defns_cache[lemma_pagetitle] = "nonexistent"
            return None

        text = blib.safe_page_text(page, errandpagemsg)
        heads_and_defns = lalib.find_heads_and_defns(text, pagemsg)
        heads_and_defns_cache[lemma_pagetitle] = heads_and_defns

    if retval == "nonexistent":
        pagemsg("WARNING: Lemma %s doesn't exist (cached)" % lemma_no_macrons)
        return None
    if heads_and_defns is None:
        return None

    headwords = heads_and_defns.headwords

    matched_head = False

    inflargs_sets: list[LookupInflectionResult] = []

    seen_heads = []
    seen_infltns = []
    for headword in headwords:
        ht = headword.head_template
        tn = tname(ht)
        heads = lalib.la_get_headword_from_template(ht, lemma_pagetitle, pagemsg, expand_text)
        for head in heads:
            if head not in seen_heads:
                seen_heads.append(head)
        for inflt in headword.infl_templates:
            infltn = tname(inflt)
            if infltn not in seen_infltns:
                seen_infltns.append(infltn)
        if tn in expected_headtemps:
            for head in heads:
                head_no_links = blib.remove_links(head)
                if lalib.remove_macrons(head_no_links) == lemma_no_macrons:
                    break
            else:
                # no break
                continue
            this_inflargs: list[dict[str, str]] = []
            for inflt in headword.infl_templates:
                infltn = tname(inflt)
                if infltn not in expected_infltemps:
                    pagemsg(
                        "WARNING: Saw bad declension template for %s, expected one of {{%s}}: %s"
                        % (pos, ",".join("{{%s}}" % temp for temp in expected_infltemps), str(inflt))
                    )
                    continue

                originflt = str(inflt)
                inflargs = lalib.generate_infl_forms(pos, originflt, errandpagemsg, expand_text)
                if inflargs is None:
                    continue
                this_inflargs.append(inflargs)
                matched_head = True
            inflargs_sets.append(LookupInflectionResult(heads, this_inflargs))
    if not matched_head:
        pagemsg(
            "WARNING: Couldn't find any matching heads, even allowing macron differences (seen heads %s, seen infl template names %s)"
            % (",".join(seen_heads), ",".join(seen_infltns))
        )
        return None
    return inflargs_sets


def process_text_on_page(p):
    if p.title.startswith("Reconstruction:Latin/"):
        p.title = re.sub("^Reconstruction:Latin/", "*", p.title)

    notes = []

    if not args.stdin:
        p.msg("Processing")

    # Greatly speed things up when --stdin by ignoring non-Latin pages
    if "==Latin==" not in p.text:
        return

    heads_and_defns = lalib.find_heads_and_defns(p.text, p.msg)
    if heads_and_defns is None:
        return
    modsec = heads_and_defns.modsec
    parsed_subsections = heads_and_defns.parsed_subsections
    headwords = heads_and_defns.headwords

    for headword in headwords:
        ht = headword.head_template
        tn = tname(ht)

        if tn == "la-noun-form" or tn == "head" and getparam(ht, "1") == "la" and getparam(ht, "2") == "noun form":
            pos = "noun"
            tag_set_groups = lalib.noun_tag_groups
            possible_slots = lalib.la_noun_decl_overrides
            expected_headtemps = ["la-noun"]
            expected_infltemps = ["la-ndecl"]
        elif (
            tn == "la-proper noun-form"
            or tn == "head"
            and getparam(ht, "1") == "la"
            and getparam(ht, "2") == "proper noun form"
        ):
            pos = "pn"
            tag_set_groups = lalib.noun_tag_groups
            possible_slots = lalib.la_noun_decl_overrides
            expected_headtemps = ["la-proper noun"]
            expected_infltemps = ["la-ndecl"]
        # elif tn == "la-pronoun-form" or tn == "head" and getparam(ht, "1") == "la" and getparam(ht, "2") == "pronoun form":
        #  pos = "pronoun"
        #  tag_set_groups = lalib.adj_tag_groups
        #  possible_slots = lalib.la_adj_decl_overrides
        #  expected_headtemp = ???
        elif tn == "la-verb-form" or tn == "head" and getparam(ht, "1") == "la" and getparam(ht, "2") == "verb form":
            pos = "verb"
            tag_set_groups = lalib.verb_tag_groups
            possible_slots = lalib.la_verb_overrides
            expected_headtemps = ["la-verb"]
            expected_infltemps = ["la-conj"]
        elif (
            tn == "la-adj-form" or tn == "head" and getparam(ht, "1") == "la" and getparam(ht, "2") == "adjective form"
        ):
            pos = "adj"
            tag_set_groups = lalib.adj_tag_groups
            possible_slots = lalib.la_adj_decl_overrides
            expected_headtemps = ["la-adj", "la-adj-comp", "la-adj-sup"]
            expected_infltemps = ["la-adecl"]
        elif (
            tn == "la-part-form"
            or tn == "head"
            and getparam(ht, "1") == "la"
            and getparam(ht, "2") == "participle form"
        ):
            pos = "part"
            tag_set_groups = lalib.adj_tag_groups
            possible_slots = lalib.la_adj_decl_overrides
            expected_headtemps = ["la-part"]
            expected_infltemps = ["la-adecl"]
        # elif tn == "la-suffix-form" or tn == "head" and getparam(ht, "1") == "la" and getparam(ht, "2") == "suffix form":
        #  pos = "suffix"
        elif tn == "la-num-form" or tn == "head" and getparam(ht, "1") == "la" and getparam(ht, "2") == "numeral form":
            pos = "numadj"
            tag_set_groups = lalib.adj_tag_groups
            possible_slots = lalib.la_adj_decl_overrides
            expected_headtemps = ["la-num-adj"]
            expected_infltemps = ["la-adecl"]
        else:
            continue

        #
        # We have the following:
        #
        # 1. The non-lemma headword, with one or (potentially but unlikely) more
        #    than one headword form.
        # 2. Under the headword, multiple {{inflection of}} templates, each of
        #    which specifies a single lemma under which the non-lemma form
        #    belongs, and one or more corresponding tag sets.
        # 3. The lemma page corresponding to the lemma specified in an
        #    {{inflection of}} template may have one or more lemmas of the right
        #    part of speech. Each lemma specifies one or (potentially but
        #    unlikely) more than one lemma form. Some, all or none of the lemmas
        #    might match the lemma specified in the {{inflection of}} template
        #    in macrons (i.e. there's an exact match between the lemma in the
        #    {{inflection of}} template and one of the actual lemma forms of a
        #    lemma on the page).
        # 4. Under each lemma on the lemma page is one or more inflection
        #    templates specifying the inflections of the lemma. Each inflection
        #    template specifies the non-lemma form(s) (potentially more than one)
        #    for each slot.
        #
        # When looking up a given {{inflection of}} template, the ideal case is
        # that the specified lemma matches one of the actual lemmas, and all
        # corresponding specified non-lemma forms match the corresponding actual
        # non-lemma form(s) for all tag sets. (If there are multiple specified
        # non-lemma forms, they may match across inflection templates if there's
        # more than one, e.g. the first matches the first inflecion template and
        # the second matches the second inflection template.)
        #
        # What if there are mismatches?
        #
        # 1. If the specified non-lemma forms are a subset of the actual
        #    non-lemma forms for a given {{inflection of}} template and lemma,
        #    this is still considered a match but we make a note of it (not a
        #    warning).
        # 2. If a single {{inflection of}} template has multiple tag sets in it
        #    and and for some but not all tag sets the specified non-lemma forms
        #    match, we consider this a match but issue a warning. (In the future,
        #    we might consider removing the bad tag sets, conditioned on a
        #    separate command-line flag.)
        # 3. If the specified lemma of a given {{inflection of}} template
        #    doesn't match any actual lemmas, we look at all actual lemmas that
        #    match except for macrons and see if, for any of them, the specified
        #    non-lemma forms match the actual non-lemma forms per (1) and (2).
        #    If so, we gather the set of lemma forms for all such lemmas. If
        #    there's only one, we can update the specified lemma in the
        #    {{inflection of}} template (and issue a warning). If there are
        #    multiple, we issue a warning and don't update the specified lemma.
        # 4. We first loop through all {{inflection of}} templates for the given
        #    specified non-lemma forms and check for matches according to
        #    (1), (2) and (3). If some but not all templates match, we issue
        #    a warning and we're done with this non-lemma headword.
        # 5. If there are no matches per (4), we look for the set of actual forms
        #    that match all tag sets of all {{inflection of}} templates when
        #    ignoring macron differences. If there is such a non-empty set,
        #    we can update the specified non-lemma forms in the non-lemma
        #    headword (and issue a warning). When doing so, we may need to
        #    update the corresponding pronunciation template(s), according to
        #    logic still to be determined (FIXME), but similar to or identical to
        #    existing logic in la_clean_long_vowels.py.
        # 6. If there are no matches per (5), we first look at the possible
        #    assignments of actual lemmas to each possible {{inflection of}}
        #    template (ignoring macron differences). If there's only one such
        #    assignment (i.e. each {{inflection of}} template can be assigned to
        #    only one actual lemma), then for that assignment, we find the
        #    actual forms that match the non-lemma pagename except in macrons and
        #    are common among all the sets of inflections, and update the
        #    specified non-lemma forms in the non-lemma headword using those
        #    forms (and issue a warning). When doing so, we may need to update
        #    the corresponding pronunciation template(s) as in (5). If there are
        #    no forms in common, issue a warning and do nothing.
        # 7. If there are multiple assignments of actual lemmas to
        #    {{inflection of}} templates, we loop over all possible assignments.
        #    For each assignment, we find the set of actual common non-lemma
        #    forms as in (6). If there is more than one assignment with a
        #    non-empty set of actual common non-lemma forms, or no assignment,
        #    we issue a warning and do nothing. Otherwise, we update the
        #    specified non-lemma forms in the non-lemma headword (and
        #    corresponding pronunciation template(s)) as in (6).

        headword_forms = lalib.la_get_headword_from_template(ht, p.title, p.msg)
        matching_headword_forms = []
        for headword_form in headword_forms:
            if "[" in headword_form or "|" in headword_form:
                p.msg("WARNING: Bracket or pipe symbol in non-lemma headword form, should not happen: %s" % str(ht))
                headword_form = blib.remove_links(headword_form)
            if lalib.remove_macrons(headword_form) != p.title:
                p.msg("WARNING: Bad headword form %s, doesn't match page title: %s" % (headword_form, str(ht)))
            elif headword_form in matching_headword_forms:
                p.msg("WARNING: Duplicate headword form %s: %s" % (headword_form, str(ht)))
            else:
                matching_headword_forms.append(headword_form)
        headword_forms = matching_headword_forms

        for stage in [1, 2, 3]:
            def stagemsg(txt):
                p.msg("Stage %s: %s" % (stage, txt))
            def errandstagemsg(txt):
                p.errandmsg("Stage %s: %s" % (stage, txt))

            @dataclass
            class InflOfTemplatesAndPropertiesResult:
                t: Template
                lemma_param: str
                lemma: str
                inflargs_sets: list[LookupInflectionResult]
                tag_sets: list[list[str]]

                def props(self):
                    return self.t, self.lemma_param, self.lemma, self.inflargs_sets, self.tag_sets

            def yield_infl_of_templates_and_properties():
                for t in headword.infl_of_templates:
                    lang = getparam(t, "lang")
                    if lang:
                        lemma_param = 1
                    else:
                        lang = getparam(t, "1")
                        lemma_param = 2
                    if lang != "la":
                        errandstagemsg(
                            "WARNING: In Latin section, found {{inflection of}} for different language %s: %s"
                            % (lang, str(t))
                        )
                        continue
                    lemma = getparam(t, str(lemma_param))
                    if "[" in lemma or "|" in lemma:
                        stagemsg("WARNING: Link in lemma %s, skipping: %s" % (lemma, str(t)))
                        continue
                    inflargs_sets = lookup_inflection(
                        lalib.remove_macrons(lemma),
                        pos,
                        expected_headtemps,
                        expected_infltemps,
                        stagemsg,
                        errandstagemsg,
                    )
                    if inflargs_sets is None:
                        stagemsg("WARNING: Lemma %s doesn't exist or has no %s heads" % (lemma, pos))
                        continue

                    # fetch tags
                    tags = []
                    for param in t.params:
                        pname = str(param.name).strip()
                        pval = str(param.value).strip()
                        if re.search("^[0-9]+$", pname):
                            if int(pname) >= lemma_param + 2:
                                if pval:
                                    tags.append(pval)
                    # split tags into tag sets (which may be multipart) and further
                    # split any multipart tag sets into component tag sets
                    tag_sets = [
                        tag_set
                        for maybe_multipart_tag_set in lalib.split_tags_into_tag_sets(tags)
                        for tag_set in lalib.split_multipart_tag_set(maybe_multipart_tag_set)
                    ]
                    yield InflOfTemplatesAndPropertiesResult(t, str(lemma_param), lemma, inflargs_sets, tag_sets)

            @dataclass
            class MergeFormsForSlotResult:
                all_valid_forms: list[str]
                all_valid_forms_with_syncopated: list[str]
                all_matchable_forms: list[str]
                all_matchable_forms_with_syncopated: list[str]

                def props(self):
                    return self.all_valid_forms, self.all_valid_forms_with_syncopated, self.all_matchable_forms, self.all_matchable_forms_with_syncopated

            def merge_forms_for_slot(slot: str, this_inflargs: list[dict[str, str]]) -> MergeFormsForSlotResult:
                # Merge the forms of all inflection templates under the given
                # lemma headword
                all_valid_forms = []
                all_valid_forms_with_syncopated = []
                for inflargs in this_inflargs:
                    if slot not in inflargs:
                        continue
                    forms = inflargs[slot].split(",")
                    valid_forms = [form for form in forms if "[" not in form and "|" not in form]
                    for form in valid_forms:
                        if form not in all_valid_forms:
                            all_valid_forms.append(form)
                        if form not in all_valid_forms_with_syncopated:
                            all_valid_forms_with_syncopated.append(form)
                        if pos == "verb" and re.search("v[eiē]", form):
                            syncopated_form = re.sub("^(.*)v[eiē]", r"\1", form)
                            if syncopated_form not in all_valid_forms_with_syncopated:
                                all_valid_forms_with_syncopated.append(syncopated_form)
                all_matchable_forms = [form for form in all_valid_forms if lalib.remove_macrons(form) == p.title]
                all_matchable_forms_with_syncopated = [
                    form for form in all_valid_forms_with_syncopated if lalib.remove_macrons(form) == p.title
                ]
                return MergeFormsForSlotResult(
                    all_valid_forms,
                    all_valid_forms_with_syncopated,
                    all_matchable_forms,
                    all_matchable_forms_with_syncopated,
                )

            if stage == 1:
                matched_infl_of_templates = False
                for infl_of_templates_result in yield_infl_of_templates_and_properties():
                    t, lemma_param, lemma, inflargs_sets, tag_sets = infl_of_templates_result.props()

                    def check_for_tag_set_match(tag_set, allow_lemma_mismatch):
                        slot = lalib.tag_set_to_slot(tag_set, tag_set_groups, stagemsg)
                        if slot is None:
                            # Already issued warning
                            return []
                        if slot not in possible_slots:
                            stagemsg("WARNING: Unrecognized slot %s from tag set: %s" % (slot, str(t)))
                            return []
                        saw_slot_in_inflargs = False
                        matching_actual_lemmas = []
                        for lookup_inflection_result in inflargs_sets:
                            actual_lemmas, this_inflargs = lookup_inflection_result.props()
                            saw_matching_lemma = False
                            for actual_lemma in actual_lemmas:
                                actual_lemma = blib.remove_links(actual_lemma)
                                if (
                                    lalib.remove_macrons(lemma) == lalib.remove_macrons(actual_lemma)
                                    if allow_lemma_mismatch
                                    else lemma == actual_lemma
                                ):
                                    saw_matching_lemma = True
                            if not saw_matching_lemma:
                                continue

                            merge_result = merge_forms_for_slot(slot, this_inflargs)
                            (
                                all_valid_forms,
                                all_valid_forms_with_syncopated,
                                all_matchable_forms,
                                all_matchable_forms_with_syncopated,
                            ) = merge_result.props()

                            matched_form = False
                            if set(headword_forms) == set(all_matchable_forms):
                                stagemsg(
                                    "Matched headword form(s) %s exactly (slot %s, lemma %s, all valid slot forms(s) %s)"
                                    % (",".join(headword_forms), slot, lemma, ",".join(all_valid_forms))
                                )
                                matched_form = True
                            elif set(headword_forms) <= set(all_matchable_forms):
                                stagemsg(
                                    "Matched headword form(s) %s as subset of all matchable slot form(s) %s (slot %s, lemma %s, all valid slot forms(s) %s)"
                                    % (
                                        ",".join(headword_forms),
                                        ",".join(all_matchable_forms),
                                        slot,
                                        lemma,
                                        ",".join(all_valid_forms),
                                    )
                                )
                                matched_form = True
                            elif set(headword_forms) == set(all_matchable_forms_with_syncopated):
                                stagemsg(
                                    "Matched syncopated headword form(s) %s exactly (slot %s, lemma %s, all valid slot forms(s) + syncopation %s)"
                                    % (",".join(headword_forms), slot, lemma, ",".join(all_valid_forms_with_syncopated))
                                )
                                matched_form = True
                            elif set(headword_forms) <= set(all_matchable_forms_with_syncopated):
                                stagemsg(
                                    "Matched syncopated headword form(s) %s as subset of all matchable slot form(s) + syncopation %s (slot %s, lemma %s, all valid slot forms(s) + syncopation %s)"
                                    % (
                                        ",".join(headword_forms),
                                        ",".join(all_matchable_forms_with_syncopated),
                                        slot,
                                        lemma,
                                        ",".join(all_valid_forms_with_syncopated),
                                    )
                                )
                                matched_form = True
                            if matched_form:
                                for actual_lemma in actual_lemmas:
                                    if actual_lemma not in matching_actual_lemmas:
                                        matching_actual_lemmas.append(actual_lemma)

                        if not matching_actual_lemmas:
                            if not saw_slot_in_inflargs:
                                if "pasv" in slot:
                                    stagemsg(
                                        "WARNING: For headword forms %s, didn't see passive slot %s in inflections of lemma %s, probably need to delete passive forms of verb"
                                        % (",".join(headword_forms), slot, lemma)
                                    )
                                else:
                                    stagemsg(
                                        "WARNING: For headword forms %s, didn't see slot %s in inflections of lemma %s"
                                        % (",".join(headword_forms), slot, lemma)
                                    )

                        return matching_actual_lemmas

                    saw_matching_lemma = False
                    for lookup_inflection_result in inflargs_sets:
                        actual_lemmas, this_inflargs = lookup_inflection_result.props()
                        if lemma in [blib.remove_links(x) for x in actual_lemmas]:
                            saw_matching_lemma = True
                            break

                    if saw_matching_lemma:
                        tag_set_matches = []
                        tag_set_mismatches = []
                        for tag_set in tag_sets:
                            matching_lemmas = check_for_tag_set_match(tag_set, allow_lemma_mismatch=False)
                            if matching_lemmas:
                                tag_set_matches.append(tag_set)
                            else:
                                tag_set_mismatches.append(tag_set)
                        if len(tag_set_matches) > 0:
                            matched_infl_of_templates = True
                            if len(tag_set_mismatches) > 0:
                                stagemsg(
                                    "WARNING: Matched tag sets %s but not %s, counting as a match: %s"
                                    % (
                                        ",".join("|".join(tag_set) for tag_set in tag_set_matches),
                                        ",".join("|".join(tag_set) for tag_set in tag_set_mismatches),
                                        str(t),
                                    )
                                )
                        else:
                            stagemsg("WARNING: Couldn't match any tag sets: %s" % str(t))

                    else:
                        stagemsg(
                            "WARNING: Couldn't match lemma %s among potential lemmas %s, trying without lemma matches: %s"
                            % (
                                lemma,
                                ",".join(
                                    actual_lemma
                                    for lookup_inflection_result in inflargs_sets
                                    for actual_lemma in lookup_inflection_result.found_heads
                                ),
                                str(t),
                            )
                        )
                        tag_set_matches = []
                        tag_set_mismatches = []
                        all_matching_lemmas = []
                        for tag_set in tag_sets:
                            matching_lemmas = check_for_tag_set_match(tag_set, allow_lemma_mismatch=True)
                            if matching_lemmas:
                                tag_set_matches.append(tag_set)
                                for matching_lemma in matching_lemmas:
                                    if matching_lemma not in all_matching_lemmas:
                                        all_matching_lemmas.append(matching_lemma)
                            else:
                                tag_set_mismatches.append(tag_set)
                        if len(tag_set_matches) > 0:
                            matched_infl_of_templates = True
                            if len(all_matching_lemmas) == 1:
                                notes.append(
                                    "fix macrons in lemma of '%s' (stage 1): %s -> %s"
                                    % (tname(t), lemma, all_matching_lemmas[0])
                                )
                                if len(tag_set_mismatches) > 0:
                                    stagemsg(
                                        "WARNING: Fixing macrons in lemma %s -> %s despite only some tag sets %s but not %s matching, counting as a match: %s"
                                        % (
                                            lemma,
                                            all_matching_lemmas[0],
                                            ",".join("|".join(tag_set) for tag_set in tag_set_matches),
                                            ",".join("|".join(tag_set) for tag_set in tag_set_mismatches),
                                            str(t),
                                        )
                                    )
                                else:
                                    stagemsg(
                                        "WARNING: Fixing macrons in lemma %s -> %s; all tag sets match: %s"
                                        % (lemma, all_matching_lemmas[0], str(t))
                                    )
                                origt = str(t)
                                t.add(str(lemma_param), all_matching_lemmas[0])
                                stagemsg("Replaced %s with %s" % (origt, str(t)))
                            else:
                                if len(tag_set_mismatches) > 0:
                                    stagemsg(
                                        "WARNING: Multiple possible lemmas %s match some tag sets %s but not %s, counting as a match but not updating lemma %s: %s"
                                        % (
                                            ",".join(all_matching_lemmas),
                                            ",".join("|".join(tag_set) for tag_set in tag_set_matches),
                                            ",".join("|".join(tag_set) for tag_set in tag_set_mismatches),
                                            lemma,
                                            str(t),
                                        )
                                    )
                                else:
                                    stagemsg(
                                        "WARNING: Multiple possible lemmas %s match tag sets, with all tag sets matching, counting as a match but not updating lemma %s: %s"
                                        % (",".join(all_matching_lemmas), lemma, str(t))
                                    )
                        else:
                            stagemsg(
                                "WARNING: Couldn't match any tag sets even when allowing macron mismatches with lemma %s: %s"
                                % (lemma, str(t))
                            )

                if matched_infl_of_templates:
                    break

            elif stage == 2:
                common_forms = None
                no_common_forms = False
                for infl_of_templates_result in yield_infl_of_templates_and_properties():
                    t, lemma_param, lemma, inflargs_sets, tag_sets = infl_of_templates_result.props()
                    for tag_set in tag_sets:
                        slot = lalib.tag_set_to_slot(tag_set, tag_set_groups, stagemsg)
                        if slot is None or slot not in possible_slots:
                            # Already issued warning
                            no_common_forms = True
                            break
                        this_tag_set_matching_forms = []
                        combined_this_inflargs = []
                        for lookup_inflection_result in inflargs_sets:
                            actual_lemmas, this_inflargs = lookup_inflection_result.props()
                            for actual_lemma in actual_lemmas:
                                actual_lemma = blib.remove_links(actual_lemma)
                                if lemma == actual_lemma:
                                    combined_this_inflargs.extend(this_inflargs)
                                    break
                        if not combined_this_inflargs:
                            continue
                        merge_result = merge_forms_for_slot(slot, combined_this_inflargs)
                        for form in merge_result.all_matchable_forms:
                            if form not in this_tag_set_matching_forms:
                                this_tag_set_matching_forms.append(form)
                        if common_forms is None:
                            common_forms = this_tag_set_matching_forms
                            if len(common_forms) == 0:
                                no_common_forms = True
                                break
                        else:
                            new_common_forms = []
                            for form in common_forms:
                                if form in this_tag_set_matching_forms:
                                    new_common_forms.append(form)
                            common_forms = new_common_forms
                            if len(common_forms) == 0:
                                no_common_forms = True
                                break
                    if no_common_forms:
                        break
                if no_common_forms or common_forms is None:
                    stagemsg(
                        "WARNING: No forms match p.title %s across all {{inflection of}} tags and tag sets, not changing headword form(s) but trying again allowing macron differences in lemmas: %s"
                        % (p.title, str(ht))
                    )
                else:
                    notes.append(
                        "fix macrons in forms of '%s' (stage 2): %s -> %s"
                        % (tname(ht), ",".join(headword_forms), ",".join(common_forms))
                    )
                    oright = str(ht)
                    if tname(ht) == "head":
                        blib.set_param_chain(ht, common_forms, "head", "head")
                    else:
                        blib.set_param_chain(ht, common_forms, "1", "head")
                    stagemsg("Replaced %s with %s" % (oright, str(ht)))
                    if len(common_forms) > 1:
                        stagemsg(
                            "WARNING: FIXME: No support yet for pronunciation for multiple headword forms %s"
                            % ",".join(common_forms)
                        )
                    else:
                        assert len(common_forms) == 1
                        la_clean_long_vowels.process_pronun_templates(
                            headword.pronun_section,
                            common_forms[0],
                            stagemsg,
                            notes,
                            "fix macrons in pronun of '%%s' (stage 2): %s -> %s"
                            % (",".join(headword_forms), ",".join(common_forms)),
                            lemma,
                        )
                    break

            else:
                assert stage == 3
                multiple_assignments = False
                infl_of_assignments = []
                for infl_of_templates_result in yield_infl_of_templates_and_properties():
                    t, lemma_param, lemma, inflargs_sets, tag_sets = infl_of_templates_result.props()
                    matching_lemmas = []
                    for lookup_inflection_result in inflargs_sets:
                        actual_lemmas, this_inflargs = lookup_inflection_result.props()
                        for actual_lemma in actual_lemmas:
                            actual_lemma = blib.remove_links(actual_lemma)
                            if lalib.remove_macrons(lemma) == lalib.remove_macrons(actual_lemma):
                                if actual_lemma not in matching_lemmas:
                                    matching_lemmas.append(actual_lemma)
                    if len(matching_lemmas) > 1:
                        stagemsg(
                            "WARNING: Multiple actual lemmas %s match {{inflection of}} lemma %s, hence multiple assignments, doing things the hard way: %s"
                            % (",".join(matching_lemmas), lemma, str(t))
                        )
                        multiple_assignments = True
                    infl_of_assignments.append(matching_lemmas)

                cur_assignment = None
                cur_common_forms = None
                for assignment in itertools.product(*infl_of_assignments):
                    common_forms = None
                    no_common_forms = False
                    for actual_lemma, infl_of_templates_result in zip(
                        assignment, yield_infl_of_templates_and_properties()
                    ):
                        t, lemma_param, lemma, inflargs_sets, tag_sets = infl_of_templates_result.props()
                        for tag_set in tag_sets:
                            slot = lalib.tag_set_to_slot(tag_set, tag_set_groups, stagemsg)
                            if slot is None or slot not in possible_slots:
                                # Already issued warning
                                no_common_forms = True
                                break
                            this_tag_set_matching_forms = []
                            combined_this_inflargs = []
                            for lookup_inflection_result in inflargs_sets:
                                actual_lemmas, this_inflargs = lookup_inflection_result.props()
                                if actual_lemma in actual_lemmas:
                                    combined_this_inflargs.extend(this_inflargs)
                                merge_result = merge_forms_for_slot(slot, combined_this_inflargs)
                                for form in merge_result.all_matchable_forms:
                                    if form not in this_tag_set_matching_forms:
                                        this_tag_set_matching_forms.append(form)
                            if common_forms is None:
                                common_forms = this_tag_set_matching_forms
                                if len(common_forms) == 0:
                                    no_common_forms = True
                                    break
                            else:
                                new_common_forms = []
                                for form in common_forms:
                                    if form in this_tag_set_matching_forms:
                                        new_common_forms.append(form)
                                common_forms = new_common_forms
                                if len(common_forms) == 0:
                                    no_common_forms = True
                                    break
                        if no_common_forms:
                            break
                    if not no_common_forms and common_forms is not None:
                        if cur_assignment is not None:
                            # We set cur_assignment and cur_common_forms together
                            assert cur_common_forms is not None
                            stagemsg(
                                "WARNING: Multiple assignments of lemmas have common forms, at least %s -> %s and %s -> %s, not changing: %s"
                                % (
                                    ",".join(cur_assignment),
                                    ",".join(cur_common_forms),
                                    ",".join(assignment),
                                    ",".join(common_forms),
                                    str(ht),
                                )
                            )
                        else:
                            cur_assignment = assignment
                            cur_common_forms = common_forms
                if cur_assignment is None:
                    stagemsg(
                        "WARNING: No forms match p.title %s across all {{inflection of}} tags and tag sets when allowing macron differences in lemmas, not changing headword form(s): %s"
                        % (p.title, str(ht))
                    )
                else:
                    # We set cur_assignment and cur_common_forms together
                    assert cur_common_forms is not None
                    for actual_lemma, infl_of_templates_result in zip(
                        cur_assignment, yield_infl_of_templates_and_properties()
                    ):
                        t, lemma_param, lemma, inflargs_sets, tag_sets = infl_of_templates_result.props()
                        notes.append(
                            "fix macrons in lemma of '%s' (stage 3): %s -> %s" % (tname(t), lemma, actual_lemma)
                        )
                        stagemsg(
                            "WARNING: found common forms %s, updating lemma %s to %s: %s"
                            % (",".join(cur_common_forms), lemma, actual_lemma, str(t))
                        )
                        origt = str(t)
                        t.add(str(lemma_param), actual_lemma)
                        stagemsg("Replaced %s with %s" % (origt, str(t)))
                    notes.append(
                        "fix macrons in forms of '%s' (stage 3): %s -> %s"
                        % (tname(ht), ",".join(headword_forms), ",".join(cur_common_forms))
                    )
                    oright = str(ht)
                    if tname(ht) == "head":
                        blib.set_param_chain(ht, cur_common_forms, "head", "head")
                    else:
                        blib.set_param_chain(ht, cur_common_forms, "1", "head")
                    stagemsg("Replaced %s with %s" % (oright, str(ht)))
                    if len(cur_common_forms) > 1:
                        stagemsg(
                            "WARNING: FIXME: No support yet for pronunciation for multiple headword forms %s"
                            % ",".join(cur_common_forms)
                        )
                    else:
                        assert len(cur_common_forms) == 1
                        la_clean_long_vowels.process_pronun_templates(
                            headword.pronun_section,
                            cur_common_forms[0],
                            stagemsg,
                            notes,
                            "fix macrons in pronun of '%%s' (stage 3): %s -> %s"
                            % (",".join(headword_forms), ",".join(cur_common_forms)),
                            lemma,
                        )
                    break

    secbody = "".join(str(x) for x in parsed_subsections)
    return modsec.rebuild(secbody=secbody), notes


parser = blib.create_argparser(
    "Check for Latin forms that don't match headword", include_pagefile=True, include_stdin=True
)
parser.add_argument("--fix-macrons", help="Correct macron differences.", action="store_true")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(
    args, start, end, process_text_on_page, new=True, default_cats=["Latin non-lemma forms"],
)
