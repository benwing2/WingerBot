#!/usr/bin/env python3

# Add pos= to ru-IPA pronunciations. Also find instances where и/я/ы/а/е̂ has
# been used phonetically in place of е and put back to е.

# FIXME:
#
# 1. (DONE) Go through pages with spaces in them, looking for non-final words
#    with final -и or whatever in place of -е. Fix them.
# 2. (DONE) Remove final ! and ? from page title when looking for final -е.
# 3. (DONE) Recognize prepositions and nnp's
# 4. Handle adding pos=imp to imperatives in -[дт]ься.
# 5. (DONE) Fix handling of adjectival non-lemmas.
# 6. (DONE) Allow control of processing lemmas or non-lemmas.
# 7. (MOSTLY DONE) Proper handling of multiword non-lemmas.

import pywikibot, re

from wingerbot import blib
from wingerbot.blib import getparam, msg, site, tname

from wingerbot.slavic.russian import rulib
from wingerbot.slavic.russian import runounlib

pages_pos = {}


# Split page title or phonetic value into words the same way that ru-pron
# does. Do not include ‿ in the split characters because the module doesn't
# split on that symbol.
def split_words(pagename, capture_delims):
    pagename = re.sub(r"\s*([,–—])\s*", r" \1 ", pagename)
    return re.split("([ -]+)" if capture_delims else "[ -]+", re.sub("[!?]$", "", pagename))


# For the given multiword noun lemma and ru-noun-table declension template,
# figure out whether each word is declined as a noun, adjective or invariable.
def find_noun_word_types_of_decl(lemma, decl_template, pagemsg):

    words = split_words(lemma, False)

    if str(decl_template.name) == "ru-decl-adj":
        per_word_types = []
        for i in range(0, len(words) - 1):
            per_word_types.append("inv")
        per_word_types.append("a")
        return per_word_types

    # Split out the arg sets in the declension and check the
    # lemma of each one, taking care to handle cases where there is no lemma
    # (it would default to the page name).

    per_word_info = runounlib.split_noun_decl_arg_sets(decl_template, pagemsg)

    def get_per_word_info(words, per_word_info):
        per_word_types = []
        for word, arg_sets in zip(words, per_word_info):
            word_types = set()
            for arg_set in arg_sets:
                pagemsg("arg_set: %s" % "|".join(arg_set))
                if len(arg_set) < 3:
                    word_types.add("decln")
                elif "$" in arg_set[2]:
                    word_types.add("inv")
                elif "+" in arg_set[2]:
                    word_types.add("a")
                elif "manual" in arg_set[2]:
                    pagemsg(
                        "WARNING: Found manually-declined noun in lemma %s, skipping: decl = %s"
                        % (lemma, str(decl_template))
                    )
                    return None
                else:
                    word_types.add("decln")
            if len(word_types) > 1:
                pagemsg(
                    "WARNING: Found multiple declension types %s for word %s in lemma %s, skipping: decl = %s"
                    % (",".join(word_types), word, lemma, str(decl_template))
                )
                return None
            per_word_types.append(list(word_types)[0])
        return per_word_types

    if len(words) != len(per_word_info):
        if len(per_word_info) == 1:
            pos = get_per_word_info(lemma, per_word_info)[0]
            per_word_types = []
            for i in range(0, len(words) - 1):
                per_word_types.append("inv")
            per_word_types.append(pos)
            return per_word_types

        pagemsg(
            "WARNING: Lemma %s has %s words but %s words in declension, skipping: decl = %s"
            % (lemma, len(words), len(per_word_info), str(decl_template))
        )
        return None

    return get_per_word_info(words, per_word_info)


# For the given multiword noun lemma (possibly with accents), figure out
# whether each word is declined as a noun, adjective or invariable.
def find_noun_word_types(lemma, pagemsg):
    declpage = pywikibot.Page(site, lemma)

    if not declpage.exists():
        pagemsg("WARNING: Page doesn't exist when looking up declension, skipping")
        return None

    parsed = blib.parse_text(declpage.text)
    decl_templates = []
    for t in parsed.filter_templates():
        tn = tname(t)
        if tn in ["ru-noun-table", "ru-decl-adj"]:
            pagemsg("find_noun_word_types: Found decl template: %s" % str(t))
            decl_templates.append(t)

    if not decl_templates:
        pagemsg("WARNING: Found no decl templates, skipping")
        return None

    per_word_types = find_noun_word_types_of_decl(lemma, decl_templates[0], pagemsg)
    if not per_word_types:
        return None
    for decl in decl_templates[1:]:
        other_per_word_types = find_noun_word_types_of_decl(lemma, decl, pagemsg)
        if not other_per_word_types:
            return None
        if other_per_word_types != per_word_types:
            pagemsg(
                "WARNING: Found word types %s for decl %s, not same as word types %s for decl %s on same page"
                % (",".join(other_per_word_types), str(decl), ",".join(per_word_types), str(decl_templates[0]))
            )
            return None

    seen_poses = set()
    for t in parsed.filter_templates():
        tn = tname(t)
        if tn == "ru-IPA":
            val = getparam(t, "pos")
            if val:
                seen_poses.add(val)
            else:
                seen_poses.add("unknown")

    return per_word_types, seen_poses


def process_text_on_page(p):
    notes = []

    override_pos = pages_pos.get(p.title, None)
    if override_pos:
        del pages_pos[p.title]

    titlewords = split_words(p.title, True)
    saw_e = False
    for word in titlewords:
        if word.endswith("е") and not rulib.is_monosyllabic(word):
            saw_e = True
            break
    if not saw_e:
        p.msg("No possible final unstressed -е in page title, skipping")
        return

    # if (" " in p.title or "-" in p.title) and not override_pos:
    #  p.msg("WARNING: Space or hyphen in page title and probable final unstressed -е, not sure how to handle yet")
    #  return

    modsec = blib.find_modifiable_lang_section(p.text, "Russian", p.msg)
    if modsec is None:
        return
    secbody = modsec.secbody
    subsections = re.split("(^===(?:Etymology|Pronunciation) [0-9]+===\n)", secbody, 0, re.M)
    # If no separate etymology sections, add extra stuff at the beginning
    # to fit the pattern
    if len(subsections) == 1:
        subsections = ["", ""] + subsections

    subsections_with_ru_ipa_to_fix = set()
    subsections_with_ru_ipa = set()
    for k in range(0, len(subsections), 2):
        for t in blib.parse_text(subsections[k]).filter_templates():
            if tname(t) == "ru-IPA":
                subsections_with_ru_ipa.add(k)
                if getparam(t, "pos"):
                    p.msg("Already has pos=, skipping template in section %s: %s" % (k // 2, str(t)))
                else:
                    phon = (getparam(t, "phon") or getparam(t, "1") or p.title).lower()
                    phonwords = split_words(phon, True)
                    if len(phonwords) != len(titlewords):
                        p.msg(
                            "WARNING: #Words (%s) in phon=%s not same as #words (%s) in title"
                            % ((len(phonwords) + 1) // 2, phon, (len(titlewords) + 1) // 2)
                        )
                        for i in range(0, len(phonwords), 2):
                            phonword = phonwords[i]
                            wordno = i // 2 + 1
                            if rulib.is_monosyllabic(phonword):
                                p.msg(
                                    "Skipping monosyllabic pronun %s (#%s) in section %s: %s"
                                    % (phonword, wordno, k // 2, str(t))
                                )
                            elif not phonword.endswith("е"):
                                p.msg(
                                    "Skipping pronun word %s (#%s) in section %s because doesn't end in -е"
                                    % (phonword, wordno, k // 2)
                                )
                            else:
                                p.msg(
                                    "Found template that will be modified due to phonword %s (#%s) in section %s: %s"
                                    % (phonword, wordno, k // 2, str(t))
                                )
                                subsections_with_ru_ipa_to_fix.add(k)
                    else:
                        for i in range(0, len(phonwords), 2):
                            titleword = titlewords[i]
                            phonword = phonwords[i]
                            wordno = i // 2 + 1
                            if rulib.is_monosyllabic(phonword):
                                p.msg(
                                    "Skipping monosyllabic pronun %s (#%s) in section %s: %s"
                                    % (phonword, wordno, k // 2, str(t))
                                )
                            elif not titleword.endswith("е"):
                                p.msg(
                                    "Skipping title word %s (#%s) in section %s because doesn't end in -е"
                                    % (titleword, wordno, k // 2)
                                )
                            elif re.search("([еия]|цы|е̂|[кгхцшжщч]а)" + rulib.DOTABOVE + "?$", phonword):
                                p.msg(
                                    "Found template that will be modified due to phonword %s, titleword %s (#%s) in section %s: %s"
                                    % (phonword, titleword, wordno, k // 2, str(t))
                                )
                                subsections_with_ru_ipa_to_fix.add(k)
                            elif not re.search(
                                "[еэѐ][" + rulib.AC + rulib.GR + rulib.CFLEX + rulib.DUBGR + "]?$", phonword
                            ):
                                p.msg(
                                    "WARNING: ru-IPA pronunciation word %s (#%s) doesn't end in [еэия] or е̂ or hard sibilant + [ыа] when corresponding titleword %s ends in -е, something wrong in section %s: %s"
                                    % (phonword, wordno, titleword, k // 2, str(t))
                                )
                            else:
                                p.msg(
                                    "Pronun word %s (#%s) with final -э or stressed vowel, ignoring in section %s: %s"
                                    % (phonword, wordno, k // 2, str(t))
                                )

    if not subsections_with_ru_ipa:
        p.msg("No ru-IPA on page, skipping page")
        return
    if not subsections_with_ru_ipa_to_fix:
        p.msg("No fixable ru-IPA on page, skipping page")
        return

    # If saw ru-IPA covering multiple etym sections, make sure we don't
    # also have pronuns inside the etym sections, and then treat as one
    # single section for the purposes of finding POS's
    if 0 in subsections_with_ru_ipa:
        if len(subsections_with_ru_ipa) > 1:
            p.msg(
                "WARNING: Saw ru-IPA in section 0 (covering multiple etym or pronun sections) and also inside etym/pronun section(s) %s; skipping page"
                % (",".join(k // 2 for k in subsections_with_ru_ipa if k > 0))
            )
            return
        subsections = ["", "", "".join(subsections)]
        subsections_with_ru_ipa_to_fix = {2}

    for k in subsections_with_ru_ipa_to_fix:
        p.msg("Fixing section %s" % (k // 2))
        parsed = blib.parse_text(subsections[k])

        if override_pos:
            pos = override_pos
        else:
            pos = set()
            is_lemma = set()
            lemma = set()
            saw_acc = False
            saw_noun_form = False
            for t in parsed.filter_templates():

                def getp(param):
                    return getparam(t, param)

                tn = tname(t)
                if tn in ["ru-noun", "ru-proper noun"]:
                    if getparam(t, "2") == "-":
                        p.msg("Found invariable noun: %s" % str(t))
                        pos.add("inv")
                    else:
                        p.msg("Found declined noun: %s" % str(t))
                        pos.add("n")
                    is_lemma.add(True)
                elif tn in ["ru-noun+", "ru-proper noun+"]:
                    for param in t.params:
                        if re.search("^[0-9]+$", str(param.name)) and "+" in str(param.value):
                            p.msg("Found declined adjectival noun, treating as adjective: %s" % str(t))
                            pos.add("a")
                            break
                    else:
                        p.msg("Found declined noun: %s" % str(t))
                        pos.add("n")
                    is_lemma.add(True)
                elif tn == "comparative of" and getp("lang") == "ru":
                    p.msg("Found comparative: %s" % str(t))
                    pos.add("com")
                    is_lemma.add(False)
                elif tn == "ru-adv":
                    p.msg("Found adverb: %s" % str(t))
                    pos.add("adv")
                    is_lemma.add(True)
                elif tn == "ru-adj":
                    p.msg("Found adjective: %s" % str(t))
                    pos.add("a")
                    is_lemma.add(True)
                elif tn == "ru-noun form":
                    p.msg("Found noun form: %s" % str(t))
                    saw_noun_form = True
                    is_lemma.add(False)
                elif tn == "head" and getp("1") == "ru":
                    if getp("2") == "verb form":
                        p.msg("Found verb form: %s" % str(t))
                        pos.add("v")
                        is_lemma.add(False)
                    elif getp("2") in ["adjective form", "participle form"]:
                        p.msg("Found adjective form: %s" % str(t))
                        pos.add("a")
                        is_lemma.add(False)
                    elif getp("2") == "noun form":
                        p.msg("Found noun form: %s" % str(t))
                        saw_noun_form = True
                        is_lemma.add(False)
                    elif getp("2") == "pronoun form":
                        p.msg("Found pronoun form: %s" % str(t))
                        pos.add("pro")
                        is_lemma.add(False)
                    elif getp("2") == "preposition":
                        p.msg("Found preposition: %s" % str(t))
                        pos.add("p")
                        is_lemma.add(True)
                    elif getp("2") == "numeral":
                        p.msg("Found numeral: %s" % str(t))
                        pos.add("num")
                        is_lemma.add(True)
                    elif getp("2") == "pronoun":
                        p.msg("Found pronoun: %s" % str(t))
                        pos.add("pro")
                        is_lemma.add(True)
                elif tn == "inflection of" and getp("lang") == "ru":
                    is_lemma.add(False)
                    lemma.add(rulib.remove_accents(getp("1")))
                    if saw_noun_form:
                        inflection_groups = []
                        inflection_group = []
                        for param in t.params:
                            if param.name in ["1", "2"]:
                                continue
                            val = str(param.value)
                            if val == ";":
                                if inflection_group:
                                    inflection_groups.append(inflection_group)
                                    inflection_group = []
                            else:
                                inflection_group.append(val)
                        if inflection_group:
                            inflection_groups.append(inflection_group)
                        for igroup in inflection_groups:
                            igroup = set(igroup)
                            is_plural = not not ({"p", "plural"} & igroup)
                            if is_plural and ({"nom", "nominative"} & igroup):
                                p.msg("Found nominative plural case inflection: %s" % str(t))
                                pos.add("nnp")
                            elif {"acc", "accusative"} & igroup:
                                # We use "n" for misc cases, but skip accusative for now,
                                # adding "n" later if we haven't seen nnp to avoid problems
                                # below with the check for multiple pos's (nom pl and acc pl
                                # are frequently the same)
                                saw_acc = True
                            elif not is_plural and ({"pre", "prep", "prepositional"} & igroup):
                                p.msg("Found prepositional singular case inflection: %s" % str(t))
                                pos.add("pre")
                            elif not is_plural and ({"dat", "dative"} & igroup):
                                p.msg("Found dative singular case inflection: %s" % str(t))
                                pos.add("dat")
                            elif not is_plural and ({"loc", "locative"} & igroup):
                                p.msg("Found locative singular case inflection: %s" % str(t))
                                pos.add("dat")
                            elif not is_plural and ({"voc", "vocative"} & igroup):
                                p.msg("Found vocative case inflection: %s" % str(t))
                                pos.add("voc")
                            else:
                                pos.add("n")
                elif tn == "prepositional singular of" and getp("lang") == "ru":
                    p.msg("Found prepositional singular case inflection: %s" % str(t))
                    pos.add("pre")
                    is_lemma.add(False)
                    lemma.add(getp("1"))
                elif tn == "dative singular of" and getp("lang") == "ru":
                    p.msg("Found dative singular case inflection: %s" % str(t))
                    pos.add("dat")
                    is_lemma.add(False)
                    lemma.add(getp("1"))
                elif tn == "vocative singular of" and getp("lang") == "ru":
                    p.msg("Found vocative case inflection: %s" % str(t))
                    pos.add("voc")
                    is_lemma.add(False)
                    lemma.add(getp("1"))

            if saw_acc and "nnp" not in pos:
                pos.add("n")
            if "dat" in pos and "pre" in pos:
                p.msg("Removing pos=dat because pos=pre is found")
                pos.remove("dat")
            if "com" in pos:
                if "a" in pos:
                    p.msg("Removing pos=a because pos=com is found")
                    pos.remove("a")
                if "adv" in pos:
                    p.msg("Removing pos=adv because pos=com is found")
                    pos.remove("adv")
            if "a" in pos and "nnp" in pos:
                p.msg("Removing pos=nnp because pos=a is found")
                pos.remove("nnp")
            if not pos:
                p.msg("WARNING: Can't locate any parts of speech, skipping section")
                continue
            if len(pos) > 1:
                p.msg("WARNING: Found multiple parts of speech, skipping section: %s" % ",".join(pos))
                continue
            pos = list(pos)[0]

            # If multiword term or potential adjectival term, can't trust
            # the part of speech coming from the above process
            if " " in p.title or "-" in p.title or re.search("[ыиео]́?е$", p.title):
                if not is_lemma:
                    p.msg("WARNING: Can't determine whether lemma or not, skipping section")
                    continue
                if len(is_lemma) > 1:
                    p.msg("WARNING: Found both lemma and non-lemma parts of speech, skipping section")
                    continue
                is_lemma = list(is_lemma)[0]
                if (" " in p.title or "-" in p.title) and is_lemma:
                    p.msg(
                        "WARNING: Space or hyphen in lemma page title and probable final unstressed -e, not sure how to handle yet, skipping section"
                    )
                    continue
                # If is_lemma, we are a single-word adjective and will be handled
                # correctly by the above code
                if not is_lemma:
                    if not lemma:
                        p.msg("WARNING: Non-lemma form and can't determine lemma, skipping section")
                        continue
                    if len(lemma) > 1:
                        p.msg(
                            "WARNING: Found inflections of multiple lemmas, skipping section: %s"
                            % ",".join(lemma)
                        )
                        continue
                    lemma = list(lemma)[0]
                    retval = find_noun_word_types(lemma, p.msg)
                    if not retval:
                        continue
                    word_types, seen_pos_specs = retval
                    words = split_words(p.title, False)
                    assert len(words) == len(word_types)
                    modified_word_types = []
                    need_to_continue = False
                    # FIXME: Should we be using phonetic version of lemma?
                    for wordno, (word, ty) in enumerate(zip(words, word_types)):
                        if word.endswith("е") and not rulib.is_monosyllabic(word):
                            if ty == "inv":
                                if len(seen_pos_specs) > 1:
                                    p.msg(
                                        "WARNING: In multiword term %s, found word %s ending in -е and marked as invariable and lemma has ambiguous pos= params (%s), not sure what to do, skipping section"
                                        % (p.title, word, ",".join(seen_pos_specs))
                                    )
                                    need_to_continue = True
                                    break
                                elif not seen_pos_specs:
                                    p.msg(
                                        "WARNING: In multiword term %s, found word %s ending in -е and marked as invariable and lemma has no pos= params, not sure what to do, skipping section"
                                        % (p.title, word)
                                    )
                                    need_to_continue = True
                                    break
                                else:
                                    seen_pos_spec = list(seen_pos_specs)[0]
                                    seen_poses = re.split("/", seen_pos_spec)
                                    if len(seen_poses) == 1:
                                        ty = seen_poses[0]
                                    elif len(words) != len(seen_poses):
                                        p.msg(
                                            "WARNING: In multiword term %s, found word %s ending in -е and marked as invariable and lemma param pos=%s has wrong number of parts of speech, not sure what to do, skipping section"
                                            % (p.title, word, seen_pos_spec)
                                        )
                                        need_to_continue = True
                                        break
                                    else:
                                        ty = seen_poses[wordno]
                                        if not ty:
                                            p.msg(
                                                "WARNING: Something wrong with retrieved pos= value from lemma, has blank value"
                                            )
                                            need_to_continue = True
                                            break
                            if ty == "decln":
                                modified_word_types.append(pos)
                            else:
                                modified_word_types.append(ty)
                        else:
                            modified_word_types.append("")
                    if need_to_continue:
                        continue
                    non_blank_distinct_mwt = set(x for x in modified_word_types if x)
                    if len(non_blank_distinct_mwt) == 0:
                        p.msg("WARNING: Something wrong, pos= would end up blank")
                    elif len(non_blank_distinct_mwt) == 1:
                        pos = list(non_blank_distinct_mwt)[0]
                    else:
                        pos = "/".join(modified_word_types)

        # Check whether there's a pronunciation with final -е for a given
        # word. There are some entries that have multiple pronunciations,
        # one with final -е and one with something else, e.g. final -и,
        # and we want to leave those alone with a warning.
        saw_final_e = {}
        for t in parsed.filter_templates():
            if tname(t) == "ru-IPA":
                param = "phon"
                phon = getparam(t, param)
                if not phon:
                    param = "1"
                    phon = getparam(t, "1")
                    if not phon:
                        param = "p.title"
                        phon = p.title
                if getparam(t, "pos"):
                    pass  # Already output msg
                else:
                    phonwords = split_words(phon, True)
                    for i in range(0, len(phonwords), 2):
                        if re.search("е$", phonwords[i]):
                            saw_final_e[i] = True

        # Now modify the templates.
        for t in parsed.filter_templates():
            if tname(t) == "ru-IPA":
                param = "phon"
                phon = getparam(t, param)
                if not phon:
                    param = "1"
                    phon = getparam(t, "1")
                    if not phon:
                        param = "p.title"
                        phon = p.title
                origt = str(t)
                if getparam(t, "pos"):
                    pass  # Already output msg
                else:
                    phonwords = split_words(phon, True)
                    mismatched_phon_title = len(phonwords) != len(titlewords)
                    for i in range(0, len(phonwords), 2):
                        titleword = not mismatched_phon_title and titlewords[i]
                        phonword = phonwords[i]
                        lphonword = phonword.lower()
                        wordno = i // 2 + 1

                        if rulib.is_monosyllabic(phonword):
                            pass  # Already output msg
                        elif mismatched_phon_title:
                            pass  # Can't canonicalize template
                        elif not titleword.endswith("е"):
                            pass  # Already output msg
                        elif re.search("([еия]|цы|е̂|[кгхцшжщч]а)" + rulib.DOTABOVE + "?$", lphonword):
                            # Found a template to modify
                            if re.search("е" + rulib.DOTABOVE + "?$", lphonword):
                                pass  # No need to canonicalize
                            else:
                                if saw_final_e.get(i, False):
                                    p.msg(
                                        "WARNING: Found another pronunciation with final -е, skipping: phon=%s (word #%s)"
                                        % (phonword, wordno)
                                    )
                                    continue
                                if re.search("и" + rulib.DOTABOVE + "?$", lphonword):
                                    p.msg(
                                        "phon=%s (word #%s) ends in -и, will modify to -е in section %s: %s"
                                        % (phonword, wordno, k // 2, str(t))
                                    )
                                    notes.append("unstressed -и -> -е")
                                elif re.search("е̂$", lphonword):
                                    # Make this a warning because we're not sure this is correct
                                    p.msg(
                                        "WARNING: phon=%s (word #%s) ends in -е̂, will modify to -е in section %s: %s"
                                        % (phonword, wordno, k // 2, str(t))
                                    )
                                    notes.append("-е̂ -> -е")
                                elif re.search("я" + rulib.DOTABOVE + "?$", lphonword):
                                    p.msg(
                                        "phon=%s (word #%s) ends in -я, will modify to -е in section %s: %s"
                                        % (phonword, wordno, k // 2, str(t))
                                    )
                                    notes.append("unstressed -я -> -е")
                                elif re.search("цы" + rulib.DOTABOVE + "?$", lphonword):
                                    p.msg(
                                        "phon=%s (word #%s) ends in ц + -ы, will modify to -е in section %s: %s"
                                        % (phonword, wordno, k // 2, str(t))
                                    )
                                    notes.append("unstressed -ы after ц -> -е")
                                elif re.search("[кгхцшжщч]а" + rulib.DOTABOVE + "?$", lphonword):
                                    p.msg(
                                        "phon=%s (word #%s) ends in unpaired cons + -а, will modify to -е in section %s: %s"
                                        % (phonword, wordno, k // 2, str(t))
                                    )
                                    notes.append("unstressed -а after unpaired cons -> -е")
                                else:
                                    assert False, (
                                        "Something wrong, strange ending, logic not correct: section %s, phon=%s (word #%s)"
                                        % (k // 2, phonword, wordno)
                                    )
                                newphonword = re.sub("(?:[ияыа]|е̂)(" + rulib.DOTABOVE + "?)$", r"е\1", phonword)
                                newphonword = re.sub(
                                    "(?:[ИЯЫА]|Е̂)(" + rulib.DOTABOVE + "?)$", r"Е\1", newphonword
                                )
                                p.msg(
                                    "Modified phon=%s (word #%s) to %s in section %s: %s"
                                    % (phonword, wordno, newphonword, k // 2, str(t))
                                )
                                phonwords[i] = newphonword
                    newphon = "".join(phonwords)
                    if newphon != phon:
                        assert param != "p.title", (
                            "Something wrong, page title should not have -и or similar that needs modification: section %s, phon=%s, newphon=%s"
                            % (k // 2, phon, newphon)
                        )
                        if pos in ["voc", "inv", "pro"]:
                            p.msg(
                                "WARNING: pos=%s may be unstable or inconsistent in handling final -е, please check change of phon=%s to %s in section %s: %s"
                                % (pos, phon, newphon, k // 2, str(t))
                            )
                        p.msg("Modified phon=%s to %s in section %s: %s" % (phon, newphon, k // 2, str(t)))
                        if pos == "none":
                            p.msg(
                                "WARNING: pos=none, should not occur, not modifying phon=%s to %s in section %s: %s"
                                % (phon, newphon, k // 2, str(t))
                            )
                        else:
                            t.add(param, newphon)

                    if pos == "none":
                        p.msg(
                            "WARNING: pos=none, should not occur, not setting pos= in section %s: %s"
                            % (k // 2, str(t))
                        )
                    else:
                        t.add("pos", pos)
                        notes.append("added pos=%s%s" % (pos, override_pos and " (override)" or ""))
                        p.msg(
                            "Replaced %s with %s in section %s%s"
                            % (origt, str(t), k // 2, override_pos and " (using override)" or "")
                        )
        subsections[k] = str(parsed)
    secbody = "".join(subsections)

    text = modsec.rebuild(secbody=secbody)
    # Sort 'added pos=X' notes before others but otherwise maintain order. We rely on sorted() to be stable.
    notes = sorted(blib.group_notes(notes), key=lambda note: 0 if note.startswith("added pos=") else 1)
    return text, notes


parser = blib.create_argparser(
    "Add pos= to final -е ru-IPA, fix use of phonetic -и/-я", include_pagefile=True, include_stdin=True
)
parser.add_argument(
    "--posfile",
    help="File containing parts of speech for pages, in the form of part of speech, space, page name, one per line",
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

if args.posfile:
    for lineno, line in blib.iter_items_from_file(args.posfile):
        m = re.search(r"^(.*?) (.*)$", line)
        if not m:
            msg("Line %s: WARNING: Can't parse line: %s" % (lineno, line))
        else:
            pos, page = m.groups()
            pages_pos[page] = pos

blib.do_pagefile_cats_refs(
    args,
    start,
    end,
    process_text_on_page,
    default_cats=["Russian lemmas", "Russian non-lemma forms"],
)

for page, pos in pages_pos.items():
    msg("Page 000 %s: WARNING: Override for non-existent page, pos=%s" % (page, pos))
