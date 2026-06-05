#!/usr/bin/env python3

from dataclasses import dataclass

import pywikibot, re

from wingerbot import blib
from wingerbot.blib import getparam, msg, site, tname, pname
from wingerbot.latin import lalib

skip_pages = []

applied_manual_pronun_mappings = set()

# Used when the automatic headword->pronun mapping fails for non-lemma forms.
# Each tuple is of the form (HEADWORD, SUB) where HEADWORD is a regex and SUB
# is either a single string to substitute in the regex or a list of such
# strings. (In place of a single string can be a four-entry type of
# (SUB, EXTRA_PARAMS, TEXTBEFORE, TEXTAFTER) for cases where there is
# surrounding text such as {{i|romantic meeting}} or {{a|Moscow}} or the need
# to specify |eccl=1 or similar). The entries included are those that won't be
# handled right.
#
# To find new cases to add, look for the message
# "WARNING: Would save and unable to match mapping" and check whether the
# pronunciation that is generated automatically is correct.
manual_pronun_mapping = []


def remove_list_duplicates(l):
    newl = []
    for x in l:
        if x not in newl:
            newl.append(x)
    return newl


def get_first_param(t):
    lang = getparam(t, "lang")
    if lang:
        if lang == "la":
            return "1"
        else:
            return None
    else:
        if getparam(t, "1") == "la":
            return "2"
        else:
            return None


# Get a list of headword pronuns.
def get_headword_pronuns(parsed, pagetitle, pagemsg, expand_text):
    # Get the headword pronunciation(s)
    headword_pronuns = []

    for t in parsed.filter_templates():
        tn = tname(t)
        if tn == "la-letter" or tn == "head" and getparam(t, "1") == "la" and getparam(t, "2") == "letter":
            pagemsg("WARNING: Skipping page with letter headword")
            return None
        if lalib.la_template_is_head(t):
            headword_pronuns.extend(lalib.la_get_headword_from_template(t, pagetitle, pagemsg, expand_text))

    # Canonicalize by removing links and final !, ?
    headword_pronuns = [re.sub("[!?]$", "", blib.remove_links(x)) for x in headword_pronuns]

    # for pronun in headword_pronuns:
    #  if lalib.remove_macrons(pronun) != pagetitle:
    #    pagemsg("WARNING: Headword pronun %s doesn't match page title, skipping" % pronun)
    #    return None

    # Check for acronym/non-syllabic.
    for pronun in headword_pronuns:
        if lalib.is_nonsyllabic(pronun):
            pagemsg("WARNING: Pronunciation is non-syllabic, skipping: %s" % pronun)
            return None
        if re.search("[" + lalib.uppercase + "][" + lalib.combining_accent_str + "]?[" + lalib.uppercase + "]", pronun):
            pagemsg("WARNING: Pronunciation may be an acronym, please check: %s" % pronun)

    headword_pronuns = remove_list_duplicates(headword_pronuns)
    if len(headword_pronuns) < 1:
        pagemsg("WARNING: Can't find headword template")
        return None
    return headword_pronuns


def pronun_matches(hpron, foundpron, pagemsg):
    orighpron = hpron
    origfoundpron = foundpron
    if hpron == foundpron or not foundpron:
        return True
    foundpron = re.sub("['._]", "", foundpron)
    if hpron == foundpron:
        pagemsg(
            "Matching headword pronun %s to found pronun %s after removing apostrophes, periods and underscores from the latter"
            % (orighpron, origfoundpron)
        )
        return True
    foundpron = lalib.remove_non_macron_accents(foundpron)
    hpron = lalib.remove_non_macron_accents(hpron)
    if hpron == foundpron:
        pagemsg(
            "Matching headword pronun %s to found pronun %s after removing non-macron accents (and apostrophes/periods/underscores from the latter)"
            % (orighpron, origfoundpron)
        )
        return True
    foundpron = re.sub("J+", "I", re.sub("j+", "i", foundpron))
    hpron = re.sub("J+", "I", re.sub("j+", "i", hpron))
    if hpron == foundpron:
        pagemsg(
            "Matching headword pronun %s to found pronun %s after converting j/jj to i (and removing non-macron accents and apostrophes/periods/underscores)"
            % (orighpron, origfoundpron)
        )
        return True
    foundpron = re.sub("V", "U", re.sub("v", "u", foundpron))
    hpron = re.sub("V", "U", re.sub("v", "u", hpron))
    if hpron == foundpron:
        pagemsg(
            "Matching headword pronun %s to found pronun %s after converting v to u (and converting j/jj to i, and removing non-macron accents and apostrophes/periods/underscores)"
            % (orighpron, origfoundpron)
        )
        return True
    foundpron = foundpron.lower()
    hpron = hpron.lower()
    if hpron == foundpron:
        pagemsg(
            "Matching headword pronun %s to found pronun %s after lowercasing (and converting v to u and j/jj to i, and removing non-macron accents and apostrophes/periods/underscores)"
            % (orighpron, origfoundpron)
        )
        return True

    return False


@dataclass(frozen=True)
class FoundPronun:
    pron: str
    extra_params: str
    pre: str
    post: str

    def __repr__(self):
        return "%s%s%s%s" % (
            self.pre and "[%s]" % self.pre or "",
            self.pron,
            self.extra_params and "|%s" % self.extra_params or "",
            self.post and "[%s]" % self.post or "",
        )


# Match up the stems of headword pronunciations and found pronunciations.
# On entry, HEADWORD_PRONUNS is a list of pronunciations extracted
# from headwords; FOUND_PRONUNS is a list of FoundPronun objects, each one
# listing a pronunciation from {{la-IPA}} along with remaining params and
# the text before and after the pronunciation on the same line, minus any
# '* ' at the beginning.
#
# If able to do so, return a dictionary of all non-identity matchings, else
# return None. For each headword in the dictionary, the entry is a list of
# tuples of (STEM, FOUNDPRONSTEMS) where STEM is a possible stem of that
# headword and FOUNDPRONSTEMS is a list of the corresponding
# found-pronunciation stems. (Each such stem is actually a FoundPronun object,
# with the extra params coming from the remaining params of the {{la-IPA}}
# template where the pronunciation was found and the pre-text and post-text
# coming from the corresponding text before and after the same {{la-IPA}}
# template.)
#
# We return a list of stem tuples because there may be multiple stems to
# consider for each headword. FOUNDPRONSTEMS is a list because there may be
# multiple such pronunciations per headword stem.
def match_headword_and_found_pronuns(headword_pronuns, found_pronuns, pagemsg, expand_text):
    matches = {}
    if not headword_pronuns:
        pagemsg("WARNING: No headword pronuns, possible error")
        # Error finding headword pronunciations, or something
        return None
    if not found_pronuns:
        pagemsg("WARNING: No found pronuns")
        return None
    # How many headword pronuns? If only one, automatically assign all found
    # pronuns to it.
    distinct_hprons = set(headword_pronuns)
    if len(distinct_hprons) == 1:
        hpron = list(distinct_hprons)[0]
        for foundpron in found_pronuns:
            valtoadd = FoundPronun(foundpron.pron or hpron, foundpron.extra_params, foundpron.pre, foundpron.post)
            if hpron in matches:
                if valtoadd not in matches[hpron]:
                    matches[hpron].append(valtoadd)
            else:
                matches[hpron] = [valtoadd]

    else:
        # Multiple headwords, need to match "the hard way"
        all_match = True
        unmatched_hpron = set()
        hpron_seen = set()
        for hpron in headword_pronuns:
            if hpron in hpron_seen:
                pagemsg("Skipping already-seen headword pronun %s" % hpron)
                continue
            hpron_seen.add(hpron)
            new_found_pronuns = []
            matched = False
            for foundpron in found_pronuns:
                if pronun_matches(hpron, foundpron.pron, pagemsg):
                    valtoadd = FoundPronun(
                        foundpron.pron or hpron, foundpron.extra_params, foundpron.pre, foundpron.post
                    )
                    if hpron in matches:
                        if valtoadd not in matches[hpron]:
                            matches[hpron].append(valtoadd)
                    else:
                        matches[hpron] = [valtoadd]
                    matched = True
                else:
                    new_found_pronuns.append(foundpron)
            found_prons = new_found_pronuns
            if not matched:
                all_match = False
                unmatched_hpron.add(hpron)
        if not all_match:
            pagemsg(
                "WARNING: Unable to match headword pronuns %s against found pronuns %s"
                % (",".join(unmatched_hpron), ",".join(str(x) for x in found_pronuns))
            )
            return None

    # Apply a function to a list of found pronunciations. Don't include results
    # where the return value from the function is logically false.
    def frob_foundprons(foundprons, fun):
        retval = []
        for foundpron in foundprons:
            funval = fun(foundpron.pron)
            if funval:
                retval.append(FoundPronun(funval, foundpron.extra_params, foundpron.pre, foundpron.post))
        return retval

    # Remove the common case where there's only one found pronunciation and it's
    # the same as the head pronunciation (and there's no pre-text or post-text
    # that we need to propagate).
    matches = dict(
        (hpron, foundprons)
        for hpron, foundprons in matches.items()
        if not (
            len(foundprons) == 1 and hpron == foundprons[0].pron and not foundprons[0].pre and not foundprons[0].post
        )
    )
    matches_stems = {}

    for hpron, foundprons in matches.items():
        stems = []

        def append_stem_foundstems(stem, foundpronunstems):
            if stem and foundpronunstems:
                stems.append((stem, foundpronunstems))

        # Check for noun/adjective stem
        nominal_ending_re = "(a|ae|[ou][mns]|ī|is|ēs|e)$"
        append_stem_foundstems(
            re.sub(nominal_ending_re, "", hpron),
            frob_foundprons(foundprons, lambda x: re.sub(nominal_ending_re, "", x)),
        )
        # Also check for -er noun or adjective
        r_stem = re.sub("er$", "", hpron)
        if r_stem != hpron:
            append_stem_foundstems(r_stem, frob_foundprons(foundprons, lambda x: re.sub("er$", "r", x)))
        # Also check for verbal stem; peel off parts that don't occur in all
        # forms of the verb
        verb_ending_re = "([ei]?(ō|or)|[aei]t|[āēiī]tur)$"
        append_stem_foundstems(
            re.sub(verb_ending_re, "", hpron), frob_foundprons(foundprons, lambda x: re.sub(verb_ending_re, "", x))
        )
        # FIXME! Need to do a better job with two-stem nouns/adjectives
        matches_stems[hpron] = stems

    return matches_stems


def get_lemmas_of_form_page(parsed):
    lemmas = set()
    for t in parsed.filter_templates():
        tn = tname(t)
        first_param = None
        if tn in ["inflection of", "comparative of", "superlative of"]:
            first_param = get_first_param(t)
        if first_param:
            lemma = lalib.remove_macrons(blib.remove_links(getparam(t, first_param)))
            lemmas.add(lemma)
    return lemmas


# Cache mapping page titles to a map from headwords to pronunciations
# found on the page.
lemma_headword_to_pronun_mapping_cache = {}


# Look up the lemmas of all inflection-of templates in PARSED (the contents
# of an etym section), and for each such lemma fetch a mapping from
# headword-derived stems to pronunciations as found in the la-IPA templates.
# Return PRONUNMAPPING, a map as described above.
def lookup_pronun_mapping(parsed, orig_pagemsg, orig_errandpagemsg):
    lemmas = get_lemmas_of_form_page(parsed)
    all_pronunmappings = {}
    for lemma in lemmas:
        # Create our own pagemsg() and errandpagemsg() that lists the lemma
        def pagemsg(txt):
            orig_pagemsg("%s: %s" % (lemma, txt))

        def errandpagemsg(txt):
            orig_errandpagemsg("%s: %s" % (lemma, txt))

        # Need to create our own expand_text() with the page title set to the
        # lemma
        def expand_text(t):
            return blib.expand_text(t, lemma, pagemsg, args.verbose)

        if lemma in lemma_headword_to_pronun_mapping_cache:
            cached = True
            pronunmapping = lemma_headword_to_pronun_mapping_cache[lemma]
        else:
            cached = False
            newpage = pywikibot.Page(site, lemma)
            newpagetext = blib.safe_page_text(newpage, errandpagemsg)
            parsed = blib.parse_text(newpagetext)

            # Compute headword->pronun mapping
            headwords = get_headword_pronuns(parsed, lemma, pagemsg, expand_text)
            foundpronuns = []

            # Find the pronunciations but also get pre-text and post-text
            for m in re.finditer(r"^(.*)(\{\{la-IPA(?:\|[^}]*)?\}\})(.*)$", newpagetext, re.M):
                pretext = m.group(1)
                laIPA = m.group(2)
                posttext = m.group(3)
                wholeline = m.group(0)
                if not pretext.startswith("* "):
                    pagemsg("WARNING: la-IPA doesn't start with '* ': %s" % wholeline)
                pretext = re.sub(r"^\*?\s*", "", pretext)  # remove '* ' from beginning
                if pretext or posttext:
                    pagemsg("WARNING: pre-text or post-text with la-IPA: %s" % wholeline)
                laIPA_t = blib.parse_text(laIPA).filter_templates()[0]
                assert str(laIPA_t.name) == "la-IPA"
                foundpronun = getparam(laIPA_t, "1")
                paramstrs = []
                for param in laIPA_t.params:
                    pn = pname(param)
                    if pn != "1":
                        paramstrs.append(str(param))
                extra_params = "|".join(paramstrs)
                foundpronuns.append(FoundPronun(foundpronun, extra_params, pretext, posttext))
            pronunmapping = match_headword_and_found_pronuns(headwords, foundpronuns, pagemsg, expand_text)
            lemma_headword_to_pronun_mapping_cache[lemma] = pronunmapping

        # The output is HEADWORD->(STEMS_AND_PRONUNS),HEADWORD->(STEMS_AND_PRONUNS)...
        # where STEMS_AND_PRONUNS is STEM:PRONUNS,STEM:PRONUNS,...,
        # where PRONUNS is PRONUN/PRONUN/...
        # where PRONUN may be PRON or [PRE]PRON or PRON[POST] or [PRE]PRON[POST]
        pagemsg(
            "For lemma %s, found pronun mapping %s%s"
            % (
                lemma,
                (
                    "None"
                    if pronunmapping is None
                    else (
                        "(empty)"
                        if not pronunmapping
                        else ",".join(
                            "%s->(%s)"
                            % (
                                hpron,
                                ",".join(
                                    "%s:%s" % (stem, "/".join(str(x) for x in foundprons))
                                    for stem, foundprons in stem_foundprons
                                ),
                            )
                            for hpron, stem_foundprons in pronunmapping.items()
                        )
                    )
                ),
                cached and " (cached)" or "",
            )
        )
        if pronunmapping:
            all_pronunmappings.update(pronunmapping)

    return all_pronunmappings


def process_section(section, indentlevel, headword_pronuns, args, pagetitle, pagemsg, errandpagemsg):
    assert indentlevel in [3, 4]
    notes = []

    was_unable_to_match = False

    parsed = blib.parse_text(section)

    pronunmapping = lookup_pronun_mapping(parsed, pagemsg, errandpagemsg)

    pronun_lines = []
    # Figure out how many headword variants there are, and if there is more
    # than one, add |ann=y to each one.
    num_annotations = 0
    annotations_set = set()
    for pronun in headword_pronuns:
        annotations_set.add(pronun)
    matched_hpron = set()
    manually_subbed_pronun = False
    # List of pronunciations to insert into comment message; approximately
    # the same as what goes inside {{la-IPA}}, except we don't include the
    # ann= parameter and we do include the pronunciation even if we leave
    # it out in {{la-IPA}} because it's the same as the page title.
    pronuns_for_comment = []
    for pronun in headword_pronuns:
        orig_pronun = pronun

        def canonicalize_annotation(ann):
            return re.sub("[.'_]", "", ann)

        def append_pronun_line(pronun, extra_params="", pre="", post=""):
            if len(annotations_set) > 1:
                # Need an annotation. Check to see whether |ann=y is possible: The
                # original pronunciation is the same as the new one (but we allow
                # possible differences in DOTBELOW, grave accents, etc. because they
                # will be stripped with |ann=y).
                if canonicalize_annotation(orig_pronun) != canonicalize_annotation(pronun):
                    # Don't include DOTBELOW, grave accents, etc. in the annotation param
                    # or they will be shown to the user.
                    headword_annparam = "|ann=%s" % canonicalize_annotation(orig_pronun)
                else:
                    headword_annparam = "|ann=1"
            else:
                headword_annparam = ""

            pronun_for_comment = str(FoundPronun(pronun, extra_params, pre, post))
            if pronun_for_comment not in pronuns_for_comment:
                pronuns_for_comment.append(pronun_for_comment)

            pronun = "* %s{{la-IPA|%s%s%s}}%s\n" % (
                pre,
                pronun,
                extra_params and "|" + extra_params or "",
                headword_annparam,
                post,
            )
            if pronun not in pronun_lines:
                pronun_lines.append(pronun)

        subbed_pronun = False

        # Check for manual pronunciation mapping
        for regex, subvals in manual_pronun_mapping:
            if re.search(regex, pronun):
                applied_manual_pronun_mappings.add(regex)
                if type(subvals) is not list:
                    subvals = [subvals]
                for subval in subvals:
                    if type(subval) is tuple:
                        subval, extra_params, pre, post = subval
                    else:
                        subval, extra_params, pre, post = (subval, "", "", "")
                    newpronun = re.sub(regex, subval, pronun)
                    pagemsg(
                        "Replacing headword-based pronunciation %s with %s due to manual_pronun_mapping"
                        % (pronun, newpronun)
                    )
                    append_pronun_line(newpronun, extra_params, pre, post)
                subbed_pronun = True
                manually_subbed_pronun = True
                break

        # If there is an automatically-derived headword->pronun mapping (e.g.
        # in case of secondary stress or phon=), try to apply it.
        if not subbed_pronun and pronunmapping:
            for hpron, stem_foundprons in pronunmapping.items():
                outerbreak = False
                for stem, foundpronstems in stem_foundprons:
                    assert stem
                    assert foundpronstems
                    if pronun.startswith(stem):
                        for foundpronstem in foundpronstems:
                            newpronun = re.sub("^" + re.escape(stem), foundpronstem.pron, pronun)
                            if newpronun != pronun:
                                pagemsg("Replacing headword-based pronunciation %s with %s" % (pronun, newpronun))
                            append_pronun_line(
                                newpronun, foundpronstem.extra_params, foundpronstem.pre, foundpronstem.post
                            )
                        subbed_pronun = True
                        matched_hpron.add(hpron)
                        outerbreak = True
                        break
                if outerbreak:
                    break

        # Otherwise use headword pronun unchanged.
        if subbed_pronun:
            pass
        else:
            append_pronun_line(pronun)

    if pronunmapping and not manually_subbed_pronun:
        for hpron, stem_foundprons in pronunmapping.items():
            if hpron not in matched_hpron:
                pagemsg(
                    "WARNING: Unable to match mapping %s->(%s) in non-lemma form(s)"
                    % (
                        hpron,
                        ",".join(
                            "%s:%s" % (stem, "/".join(str(x) for x in foundprons))
                            for stem, foundprons in stem_foundprons
                        ),
                    )
                )
                was_unable_to_match = True

    if re.search(r"[Aa]bbreviation", section) and not re.search("==Abbreviations==", section):
        pagemsg("WARNING: Found the word 'abbreviation', please check")
    if re.search(r"[Aa]cronym", section) and not re.search("==Acronyms==", section):
        pagemsg("WARNING: Found the word 'acronym', please check")
    if re.search(r"[Ii]nitialism", section) and not re.search("==Initialisms==", section):
        pagemsg("WARNING: Found the word 'initialism', please check")

    overrode_existing_pronun = False
    if args.override_pronun:
        pronun_line_re = r"^(\* .*\{\{la-IPA(?:\|([^}]*))?\}\}.*)\n"
        for m in re.finditer(pronun_line_re, section, re.M):
            overrode_existing_pronun = True
            pagemsg("WARNING: Removing pronunciation due to --override-pronun: %s" % m.group(1))
        section = re.sub(pronun_line_re, "", section, 0, re.M)

    foundpronuns = []
    for m in re.finditer(r"(\{\{la-IPA(?:\|([^}]*))?\}\})", section):
        template_text = m.group(1)
        pagemsg("Already found pronunciation template: %s" % template_text)
        template = blib.parse_text(template_text).filter_templates()[0]
        foundpronun = getparam(template, "1") or pagetitle
        foundpronuns.append(foundpronun)
    if foundpronuns:
        joined_foundpronuns = ",".join(foundpronuns)
        joined_headword_pronuns = ",".join(headword_pronuns)
        if len(foundpronuns) < len(headword_pronuns):
            pagemsg(
                "WARNING: Fewer existing pronunciations (%s) than headword-derived pronunciations (%s): existing %s, headword-derived %s"
                % (len(foundpronuns), len(headword_pronuns), joined_foundpronuns, joined_headword_pronuns)
            )
        foundpronuns_no_dot = [x.replace(".", "") for x in foundpronuns]
        foundpronuns_no_dot_or_apostrophe = [x.replace(",", "") for x in foundpronuns_no_dot]
        foundpronuns_no_dot_apostrophe_or_underscore = [x.replace("_", "") for x in foundpronuns_no_dot_or_apostrophe]
        if set(foundpronuns_no_dot_apostrophe_or_underscore) != set(headword_pronuns):
            pagemsg(
                "WARNING: Existing pronunciation template (w/o dot, apostrophe or underscore) has different pronunciation %s from headword-derived pronunciation %s"
                % (joined_foundpronuns, joined_headword_pronuns)
            )
        elif set(foundpronuns_no_dot_or_apostrophe) != set(headword_pronuns):
            pagemsg(
                "WARNING: Existing pronunciation template (w/o dot or apostrophe) has different pronunciation %s from headword-derived pronunciation %s, but only in underscore"
                % (joined_foundpronuns, joined_headword_pronuns)
            )
        elif set(foundpronuns_no_dot) != set(headword_pronuns):
            pagemsg(
                "WARNING: Existing pronunciation template (w/o dot) has different pronunciation %s from headword-derived pronunciation %s, but only in apostrope"
                % (joined_foundpronuns, joined_headword_pronuns)
            )
        elif set(foundpronuns) != set(headword_pronuns):
            pagemsg(
                "WARNING: Existing pronunciation template has different pronunciation %s from headword-derived pronunciation %s, but only in dots"
                % (joined_foundpronuns, joined_headword_pronuns)
            )

        return section, notes, was_unable_to_match

    pronunsection = "%sPronunciation%s\n%s\n" % ("=" * indentlevel, "=" * indentlevel, "".join(pronun_lines))

    origsection = section
    # If pronunciation section already present, insert pronun into it; this
    # could happen when audio but not IPA is present, or when we deleted the
    # pronunciation because of --override-pronun
    if re.search(r"^===+Pronunciation===+$", section, re.M):
        pagemsg("Found pronunciation section without la-IPA")
        section = re.sub(r"^(===+Pronunciation===+)\n", r"\1\n%s" % "".join(pronun_lines), section, 1, re.M)
    else:
        # Otherwise, skip past any ===Etymology=== or ===Alternative forms===
        # sections at the beginning. This requires us to split up the subsections,
        # find the right subsection to insert before, and then rejoin.
        subsecs = blib.split_text_into_subsections(section, pagemsg)
        subsections = subsecs.subsections

        insert_before = 1
        while True:
            if insert_before >= len(subsections):
                pagemsg("WARNING: Malformatted headers, no level-3/4 POS header")
                return
            if subsecs.headers[insert_before + 1] not in ["Alternative forms", "Etymology"]:
                break
            insert_before += 2
        subsections[insert_before] = re.sub(r"(^===)", r"%s\1" % pronunsection, subsections[insert_before], 1, re.M)
        section = "".join(subsections)

    # Make sure there's a blank line before an initial header (even if there
    # wasn't one before).
    section = re.sub("^===", "\n===", section, 1)

    if section == origsection:
        pagemsg("WARNING: Something wrong, couldn't sub in pronunciation section")
        return

    if overrode_existing_pronun:
        notes.append("override pronunciation with %s" % ",".join(pronuns_for_comment))
    else:
        notes.append("add pronunciation %s" % ",".join(pronuns_for_comment))

    return section, notes, was_unable_to_match


def process_text_on_page(p, lemma=None):
    p.msg("Processing")

    if lemma is not None and p.title == lalib.remove_macrons(lemma):
        # We're processing a non-lemma form; skip if the same as the lemma form. Do this check here instead of in the
        # caller so we get consistent pagemsg() format with other non-lemma messages.
        p.msg("Skipping dictionary form")
        return

    for skip_regex in skip_pages:
        if re.search(skip_regex, p.title):
            p.msg("WARNING: Skipping because page in skip_pages matching %s" % skip_regex)
            return

    notes = []

    was_unable_to_match = False
    modsec = blib.find_modifiable_lang_section(p.text, "Latin", p.msg, force_final_nls=True)
    if modsec is None:
        return
    secbody = modsec.secbody
    need_l3_pronun = False
    if "===Pronunciation 1===" in secbody:
        p.msg("WARNING: Found ===Pronunciation 1===, should convert page to multiple etymologies")
        return
    if "===Etymology 1===" in secbody:
        # If multiple etymologies, things are more complicated. We may have to
        # process each section individually. We fetch the headwords from each
        # section to see whether the etymologies should be in split or
        # combined form. If they should be in split form, we remove any
        # combined pronunciation and add pronunciations to each section if
        # not already present. If they should be in combined form, we
        # remove pronunciations from individual sections (PARTLY IMPLEMENTED)
        # and add a combined pronunciation at the top.

        etym_secs = blib.split_text_into_subsections(secbody, p.msg, only_level=3, header_re="Etymology [0-9.]+")
        etym_sections = etym_secs.subsections
        # Make sure there are multiple etymologies, otherwise page is malformed
        p.msg("Found multiple etymologies (%s)" % (len(etym_sections) // 2))
        if len(etym_sections) < 5:
            p.msg("WARNING: Misformatted page with multiple etymologies (too few etymologies, skipping)")
            return

        # Check for misnumbered etymology sections
        # FIXME, this should be a separate script
        for k, header in etym_secs.header_list:
            if header != "Etymology %s" % (k // 2):
                p.msg(
                    "WARNING: Misformatted page with multiple etymologies, expected ===Etymology %s=== but found %s"
                    % (k // 2, header)
                )
                break

        # Check if all per-etym-section headwords are the same
        etymparsed2 = blib.parse_text(etym_sections[2])
        etym_headword_pronuns = {}
        # Fetch the headword pronuns of the ===Etymology 1=== section.
        # We don't check for None here so that an error in an individual
        # section doesn't cause us to bow out entirely; instead, we treat
        # any comparison with None as False so we will always end up with
        # per-section pronunciations.
        etym_headword_pronuns[2] = get_headword_pronuns(etymparsed2, p.title, p.msg, p.expand_text)
        need_per_section_pronuns = False
        for k in range(4, len(etym_sections), 2):
            etymparsed = blib.parse_text(etym_sections[k])
            # Fetch the headword pronuns of the ===Etymology N=== section.
            # We don't check for None here; see above.
            etym_headword_pronuns[k] = get_headword_pronuns(etymparsed, p.title, p.msg, p.expand_text)
            # Treat any comparison with None as False.
            if (
                not etym_headword_pronuns[2]
                or not etym_headword_pronuns[k]
                or set(etym_headword_pronuns[k]) != set(etym_headword_pronuns[2])
            ):
                p.msg(
                    "WARNING: Etym section %s pronuns %s different from etym section 1 pronuns %s"
                    % (
                        k // 2,
                        ",".join(etym_headword_pronuns[k] or ["none"]),
                        ",".join(etym_headword_pronuns[2] or ["none"]),
                    )
                )
                need_per_section_pronuns = True
        numpronunsecs = len(re.findall("^===Pronunciation===$", etym_sections[0], re.M))
        if numpronunsecs > 1:
            p.msg(
                "WARNING: Multiple ===Pronunciation=== sections in preamble to multiple etymologies, needs to be fixed"
            )
            return

        if need_per_section_pronuns:
            p.msg("Multiple etymologies, split pronunciations needed")
        else:
            p.msg("Multiple etymologies, combined pronunciation possible")

        # If need split pronunciations and there's a combined pronunciation,
        # delete it if possible.
        if need_per_section_pronuns and numpronunsecs == 1:
            p.msg(
                "Multiple etymologies, converting combined pronunciation to split pronunciation (deleting combined pronun)"
            )
            # Remove existing pronunciation section; but make sure it's safe
            # to do so (must have nothing but la-IPA templates in it, and the
            # pronunciations in them must match what's expected)
            m = re.search(r"(^===Pronunciation===\n)(.*?)(^==|\Z)", etym_sections[0], re.M | re.S)
            if not m:
                p.msg("WARNING: Can't find ===Pronunciation=== section when it should be there, logic error?")
                return
            if not re.search(r"^(\* \{\{la-IPA(?:\|([^}]*))?\}\}\n)*$", m.group(2)):
                p.msg(
                    "WARNING: Pronunciation section to be removed contains extra stuff (e.g. manual IPA or audio), can't remove: <%s>\n"
                    % (m.group(1) + m.group(2))
                )
                return
            foundpronuns = []
            for m in re.finditer(r"(\{\{la-IPA(?:\|([^}]*))?\}\})", m.group(2)):
                # FIXME, not right, should do what we do above with foundpronuns
                # where we work with the actual parsed template
                foundpronuns.append(m.group(2) or p.title)
            foundpronuns = remove_list_duplicates(foundpronuns)
            if foundpronuns:
                joined_foundpronuns = ",".join(foundpronuns)
                # Combine headword pronuns while preserving order. To do this,
                # we sort by numbered etymology sections and then flatten.
                combined_headword_pronuns = remove_list_duplicates(
                    [y for k, v in sorted(etym_headword_pronuns.items(), key=lambda x: x[0]) for y in (v or [])]
                )
                joined_headword_pronuns = ",".join(combined_headword_pronuns)
                if not (set(foundpronuns) <= set(combined_headword_pronuns)):
                    p.msg(
                        "WARNING: When trying to delete pronunciation section, existing pronunciation %s not subset of headword-derived pronunciation %s, unable to delete"
                        % (joined_foundpronuns, joined_headword_pronuns)
                    )
                    return
            etym_sections[0] = re.sub(
                r"(^===Pronunciation===\n)(.*?)(\Z|^==|^\[\[)", r"\3", etym_sections[0], 1, re.M | re.S
            )
            secbody = "".join(etym_sections)
            notes.append("remove combined pronun section")
            p.msg(
                "Removed pronunciation section because combined pronunciation with multiple etymologies needs to be split"
            )

        # If need combined pronunciations, check for split pronunciations and
        # remove them. As a special case, if there's only one split
        # pronunciation, just move the whole section to the top. We do this
        # so we move audio, homophones, etc. This situation will frequently
        # happen when a script adds a non-lemma form to an existing page
        # without split etymologies, because it wraps everything in an
        # "Etymology 1" section.
        # FIXME: When we move the whole section to the top, it could be
        # incorrect to do so if the la-IPA isn't just the headword, e.g. if
        # it has a strange spelling, or phon= or gem=, etc. We should probably
        # check for this.
        if not need_per_section_pronuns:
            # Check for a single pronunciation section that we can move
            num_secs_with_pronun = 0
            first_sec_with_pronun = 0
            for k in range(2, len(etym_sections), 2):
                if "===Pronunciation===" in etym_sections[k]:
                    num_secs_with_pronun += 1
                    if not first_sec_with_pronun:
                        first_sec_with_pronun = k
            if num_secs_with_pronun == 1:
                # Section ends with another section start, end of text, or a wikilink or category link. (Normally
                # there should always be another section following.)
                m = re.search(
                    r"(^===+Pronunciation===+\n.*?)(\Z|^==|^\[\[)",
                    etym_sections[first_sec_with_pronun],
                    re.M | re.S,
                )
                if not m:
                    p.msg(
                        "WARNING: Can't find ====Pronunciation==== section when it should be there, logic error?"
                    )
                else:
                    # Set indentation of Pronunciation to 3
                    pronunsec = re.sub(r"===+Pronunciation===+", "===Pronunciation===", m.group(1))
                    etym_sections[first_sec_with_pronun] = re.sub(
                        r"^(===+Pronunciation===+\n.*?)(\Z|^==|^\[\[)",
                        r"\2",
                        etym_sections[first_sec_with_pronun],
                        1,
                        re.M | re.S,
                    )
                    etym_sections[0] += pronunsec
                    secbody = "".join(etym_sections)
                    notes.append("move split pronun section to top to make combined")
                    p.msg("Moved split pronun section for ===Etymology %s=== to top" % (k // 2))
            elif num_secs_with_pronun > 1:
                p.msg(
                    "WARNING: need combined pronunciation section, but there are multiple split pronunciation sections, code to delete them not implemented; delete manually)"
                )
                # FIXME: Implement me

        # Now add the per-section or combined pronunciation
        if need_per_section_pronuns:
            for k in range(2, len(etym_sections), 2):
                # Skip processing if pronuns are None.
                if not etym_headword_pronuns[k]:
                    continue
                result = process_section(
                    etym_sections[k],
                    4,
                    etym_headword_pronuns[k],
                    args,
                    p.title,
                    p.msg,
                    p.errandmsg,
                )
                if result is None:
                    continue
                etym_sections[k], etymsection_notes, etymsection_unable_to_match = result
                notes.extend(etymsection_notes)
                was_unable_to_match = was_unable_to_match or etymsection_unable_to_match
            secbody = "".join(etym_sections)
        else:
            need_l3_pronun = True

    else:
        need_l3_pronun = True

    if need_l3_pronun:
        # Get the headword pronunciations for the whole page.
        # NOTE: Perhaps when we've already computed per-section headword
        # pronunciations, as with multiple etymologies, we should combine
        # them rather than checking the whole page. This will make a
        # difference if there are headwords outside of the etymology sections,
        # but that shouldn't happen and is a malformed page if so.
        # NOTE NOTE: If we combine headword pronunciations with multiple
        # etymologies, we need to preserve the order as found on the page.
        headword_pronuns = get_headword_pronuns(blib.parse_text(secbody), p.title, p.msg, p.expand_text)
        # If error, skip page.
        if headword_pronuns is None:
            return

        # Process the section
        result = process_section(
            secbody, 3, headword_pronuns, args, p.title, p.msg, p.errandmsg,
        )
        if result is None:
            return
        secbody, section_notes, section_unable_to_match = result
        notes.extend(section_notes)
        was_unable_to_match = was_unable_to_match or section_unable_to_match

    text = modsec.rebuild(secbody=secbody)
    # Eliminate sequences of 3 or more newlines, which may come from ensuring two trailing newlines in
    # force_final_nls=True. (FIXME: Still true?). Add comment if none, in case of existing page
    # with extra newlines.
    newtext = re.sub(r"\n\n\n+", r"\n\n", text)
    if newtext != text and not notes:
        return newtext, "eliminate sequences of 3 or more newlines"
    text = newtext
    return text, notes


def process_lemma(p, lemma):
    p.msg("Processing")
    parsed = blib.parse_text(p.text)
    for t in parsed.filter_templates():
        tn = tname(t)
        pos = None
        if tn == "la-conj":
            pos = "verb"
        elif tn == "la-ndecl":
            pos = "noun"
        elif tn == "la-adecl":
            pos = "adj"
        if pos:
            inflargs = lalib.generate_infl_forms(pos, str(t), p.errandmsg, p.expand_text)
            if inflargs is None:
                # Error generating forms?
                continue
            for _, (slotformind, slotformtitle, slot, formval) in blib.iter_items(
                lalib.flatten_slot_formvals(p.index, lemma, inflargs), get_name=lambda x: x[3]):
                matches = False
                for spec in args_slots:
                    if spec == slot:
                        matches = True
                        break
                    if lalib.slot_matches_spec(slot, spec):
                        matches = True
                        break
                if matches:
                    def do_process_text_on_page(pp):
                        return process_text_on_page(pp, lemma)
                    blib.do_edit(args, slotformind, lalib.remove_macrons(formval), do_process_text_on_page, must_exist=True,
                                 msg_title=slotformtitle)


parser = blib.create_argparser(
    "Add pronunciation sections to Latin Wiktionary entries", include_pagefile=True, include_stdin=True
)
parser.add_argument(
    "--lemma-file", help="File containing lemmas to process, one per line; non-lemma forms will be done"
)
parser.add_argument("--lemmas", help="List of comma-separated lemmas to process; non-lemma forms will be done")
parser.add_argument("--slots", help="Slots to process in conjunction with --lemmas and --lemma-file.")
parser.add_argument("--override-pronun", action="store_true", help="Override existing pronunciations")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

if args.lemma_file or args.lemmas:
    args_slots = args.slots.split(",")

    if args.lemma_file:
        lemmas = blib.iter_items_from_file(args.lemma_file, start, end)
    else:
        lemmas = blib.iter_items(re.split(",", args.lemmas), start, end)
    for i, lemma in lemmas:
        def do_process_lemma(p):
            return process_lemma(p, lemma)
        blib.do_edit(args, i, lalib.remove_macrons(lemma), do_process_lemma, msg_title=lemma)

else:
    blib.do_pagefile_cats_refs(
        args,
        start,
        end,
        process_text_on_page,
        default_cats=["Latin lemmas", "Latin non-lemma forms"],
    )


def subval_to_string(subval):
    if type(subval) is tuple:
        pron, extra_params, pre, post = subval
        return str(FoundPronun(pron, extra_params, pre, post))
    else:
        return subval


for regex, subvals in manual_pronun_mapping:
    if regex not in applied_manual_pronun_mappings:
        msg(
            "WARNING: Unapplied manual_pronun_mapping %s->%s"
            % (
                regex,
                ",".join(subval_to_string(x) for x in subvals) if type(subvals) is list else subval_to_string(subvals),
            )
        )
