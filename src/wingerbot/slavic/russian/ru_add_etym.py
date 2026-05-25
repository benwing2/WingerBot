#!/usr/bin/env python3

import pywikibot, re
from wingerbot import blib
from wingerbot.blib import site, msg, errmsg, errandmsg, group_notes
from wingerbot.slavic.russian import rulib

# Examples of lines in the --direcfile:
#
# замбийский За́мбия+-и́йский
# зимбабвийский Зимба́бве+tr1=Zimbábvɛ+-и́йский
# индийский И́ндия+-и́йский
# индонезийский Индоне́зия+tr1=Indonɛ́zija,_Indonézija+-и́йский
# валлийский Валлис+alt1=Ва́лл(ис)+t1=[[Wales]]+q1=dated+-и́йский
# каспийский raw:Borrowed from {{affix|ru|Caspius|t1=[[Caspian]]|lang1=la|-и́йский}}.
#
# The format of the directive file is as follows. Each line consists of two fields separated by whitespace, with the following meaning:
# 1. The first field is the term to which the etymology should be added. Accents may be present and will be removed to form the pagename,
#    although they only currently matter when --add-passive-of is given.
# 2. The second field is the etymology, which normally corresponds to an {{affix|ru|...}} template call. + signs are converted to | characters
#    and underscores to spaces. The following special forms are also allowed:
#   a. A hyphen, indicating that the etymology is unknown; a call to {{rfe|ru}} will be added in this case.
#   b. A double hyphen, indicating that no etymology section should be added at all. This is useful e.g. for participles and other non-lemma forms.
#   c. A string of the form acr:FULLEXPR:MEANING, indicating that the term is an acronym of the full expression FULLEXPR, which has the meaning MEANING.
#      For example, acr:МГУ:Московский_государственный_университет would indicate that the term is an acronym of [[Московский государственный университет]],
#      meaning "Moscow State University".
#   d. A string of the form deverb:SOURCETERM, indicating that the term is a deverbal from SOURCETERM. For example, deverb:разгово́р would indicate that the term is a deverbal from [[разговор]].
#   e. A string of the form back:SOURCETERM, indicating that the term is a back-formation from SOURCETERM.
#   f. A string of the form raw:RAW ETYM, specifying the etymology text RAW ETYM directly, without any processing other than ensuring there is a space after commas.
#      Spaces are allowed in the raw etymology text.
#   g. A string of the form LANG:SOURCETERM, indicating that the term is borrowed from SOURCETERM in language LANG (a language code). Such strings can be directly preceded
#      by ? or << to indicate uncertainty or ultimate borrowing, respectively. For example, ?de:Wald would indicate that the term is perhaps borrowed from German Wald,
#      and <<de:Wald would indicate that the term is ultimately borrowed from German Wald.
#   h. A string of the form part[fnp]:X, adj[fnp]:X, or partadj[fnp]:X, where X is a term. This indicates that the term is a participle, adjective, or participle/adjective form
#      of the term X, where fnp indicates whether the term is feminine, neuter, or plural. For example, partf:разгово́рный would indicate that the term is a feminine participle
#     form of разгово́рный, and adjp:разгово́рный would indicate that the term is a plural adjective form of разгово́рный. [NOT CURRENTLY WORKING]
# 3. Lines starting with ! are treated the same as lines not starting with !, except that if an etymology section already exists, it will be overridden with the new etymology
#    instead of leaving the page alone.
# 4. Lines starting with # are treated as comments and ignored.


# Split text on a separator, but not if separator is preceded by a backslash, and remove such backslashes
def do_split(sep, text, maxsplit=0):
    elems = re.split(r"(?<![\\])%s" % sep, text, maxsplit)
    return [re.sub(r"\\(%s)" % sep, r"\1", elem) for elem in elems]


def process_line(index, line, add_passive_of, override_etym, save, verbose):
    def error(text):
        errmsg("ERROR: Processing line: %s" % line)
        errmsg("ERROR: %s" % text)
        assert False

    def check_stress(word):
        word = re.sub(r"|.*", "", word)
        if word.startswith("-") or word.endswith("-"):
            # Allow unstressed prefix (e.g. разо-) and unstressed suffix (e.g. -овать)
            return
        if rulib.needs_accents(word, split_dash=True):
            error("Word %s missing an accent" % word)

    # Skip lines consisting entirely of comments
    if line.startswith("#"):
        return
    if line.startswith("!"):
        override_etym = True
        line = line[1:]
    # If the second element (the etymology) begins with raw:, allow spaces in the remainder to be
    # included as part of the second element.
    els = do_split(r"\s+", line, 1)
    if len(els) != 2:
        error("Expected two fields, saw %s" % len(els))
    if not els[1].startswith("raw:"):
        els = do_split(r"\s+", line)
    # Replace _ with space and \u
    els = [el.replace("_", " ").replace(r"\u", "_") for el in els]
    if len(els) != 2:
        error("Expected two fields, saw %s" % len(els))
    accented_term = els[0]
    term = rulib.remove_accents(accented_term)
    etym = els[1]

    pagetitle = term

    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    def errandpagemsg(txt):
        errandmsg("Page %s %s: %s" % (index, pagetitle, txt))

    # Handle etymology
    adjformtext = ""
    if etym == "?":
        error("Etymology consists of bare question mark")
    elif etym == "-":
        etymtext = "===Etymology===\n{{rfe|ru}}\n\n"
    elif etym == "--":
        etymtext = ""
    elif re.search(r"^(part|adj|partadj)([fnp]):", etym):
        # FIXME! This branch doesn't currently work.
        m = re.search(r"^(part|adj|partadj)([fnp]):(.*)", etym)
        forms = {"f": ["nom|f|s"], "n": ["nom|n|s", "acc|n|s"], "p": ["nom|p", "in|acc|p"]}
        infleclines = ["# {{inflection of|ru|%s||%s}}" % (m.group(3), form) for form in forms[m.group(2)]]
        if m.group(1) in ["adj", "partadj"]:
            adjinfltext = """===Adjective===
{{head|ru|adjective form|head=%s%s}}

%s\n\n""" % (
                headterm,
                trtext,
                "\n".join(infleclines),
            )
        else:
            adjinfltext = ""
        if m.group(1) in ["part", "partadj"]:
            partinfltext = """===Participle===
{{head|ru|participle form|head=%s%s}}

%s\n\n""" % (
                headterm,
                trtext,
                "\n".join(infleclines),
            )
        else:
            partinfltext = ""
        adjformtext = partinfltext + adjinfltext
        etymtext = ""
    else:
        if etym.startswith("acr:"):
            _, fullexpr, meaning = do_split(":", etym)
            etymtext = "{{acronym of|ru|%s||%s}}." % (fullexpr, meaning)
        elif etym.startswith("deverb:"):
            _, sourceterm = do_split(":", etym)
            etymtext = "{{deverbal|ru|%s}}." % sourceterm
        elif etym.startswith("back:"):
            _, sourceterm = do_split(":", etym)
            etymtext = "{{back-form|ru|%s}}" % sourceterm
        elif etym.startswith("raw:"):
            etymtext = re.sub(", *", ", ", re.sub("^raw:", "", etym))
        elif ":" in etym and "+" not in etym:
            nocap = False
            if etym.startswith("?"):
                prefix = "Perhaps "
                etym = re.sub(r"^\?", "", etym)
                nocap = True
            elif etym.startswith("<<"):
                prefix = "Ultimately "
                etym = re.sub(r"^<<", "", etym)
                nocap = True
            else:
                prefix = ""
            m = re.search(r"^([a-zA-Z.-]+):(.*)", etym)
            if not m:
                error("Bad etymology form: %s" % etym)
            etymtext = "%s{{bor+|ru|%s|%s%s}}." % (prefix, m.group(1), m.group(2), "|nocap=1" if nocap else "")
        else:
            prefix = ""
            if etym.startswith("?"):
                prefix = "Perhaps from "
                etym = re.sub(r"^\?", "", etym)
            elif etym.startswith("<<"):
                prefix = "Ultimately from "
                etym = re.sub(r"^<<", "", etym)
            else:
                prefix = "From "
            m = re.search(r"^([a-zA-Z.-]+):(.*)", etym)
            if m:
                langtext = "|lang1=%s" % m.group(1)
                etym = m.group(2)
            else:
                langtext = ""
            etymtext = "%s{{affix|ru|%s%s}}." % (prefix, "|".join(do_split(r"\+", re.sub(", *", ", ", etym))), langtext)
        etymbody = etymtext + "\n\n"
        etymtext = "===Etymology===\n" + etymbody

    if not etymtext:
        pagemsg("No etymology text, skipping")

    # Load page
    page = pywikibot.Page(site, pagetitle)

    if not blib.safe_page_exists(page, errandpagemsg):
        pagemsg("Page doesn't exist, can't add etymology")
        return

    pagemsg("Adding etymology")
    notes = []
    pagetext = str(page.text)

    # Split into sections
    splitsections = re.split("(^==[^=\n]+==\n)", pagetext, 0, re.M)
    # Extract off pagehead and recombine section headers with following text
    pagehead = splitsections[0]
    sections = []
    for i in range(1, len(splitsections)):
        if (i % 2) == 1:
            sections.append("")
        sections[-1] += splitsections[i]

    # Go through each section in turn, looking for existing Russian section
    for i in range(len(sections)):
        m = re.match("^==([^=\n]+)==$", sections[i], re.M)
        if not m:
            pagemsg("Can't find language name in text: [[%s]]" % (sections[i]))
        elif m.group(1) == "Russian":
            if override_etym:
                subsections = re.split("(^===+[^=\n]+===+\n)", sections[i], 0, re.M)

                replaced_etym = False
                for j in range(2, len(subsections), 2):
                    if "==Etymology==" in subsections[j - 1] or "==Etymology 1==" in subsections[j - 1]:
                        subsections[j] = etymbody
                        replaced_etym = True
                        break

                if replaced_etym:
                    sections[i] = "".join(subsections)
                    newtext = "".join(sections)
                    notes.append("replace Etymology section in Russian lemma with manually specified etymology")
                    break

            if "==Etymology==" in sections[i] or "==Etymology 1==" in sections[i]:
                errandpagemsg("WARNING: Already found etymology, skipping")
                return

            subsections = re.split("(^===+[^=\n]+===+\n)", sections[i], 0, re.M)

            insert_before = 1
            if "===Alternative forms===" in subsections[insert_before]:
                insert_before += 2

            subsections[insert_before] = etymtext + subsections[insert_before]
            sections[i] = "".join(subsections)
            if add_passive_of:
                active_term = rulib.remove_monosyllabic_accents(re.sub("с[яь]$", "", accented_term))
                sections[i] = re.sub(r"(^(#.*\n)+)", r"\1# {{passive of|ru|%s}}\n" % active_term, sections[i], 1, re.M)

            newtext = pagehead + "".join(sections)
            notes.append("add (manually specified) Etymology section to Russian lemma")
            break
    else:
        errandpagemsg("WARNING: Can't find Russian section, skipping")
        return

    if newtext != pagetext:
        if verbose:
            pagemsg("Replacing <%s> with <%s>" % (pagetext, newtext))
        assert notes
        comment = "; ".join(group_notes(notes))
        if save:
            blib.safe_page_save(page, comment, errandpagemsg)
        else:
            pagemsg("Would save with comment = %s" % comment)


parser = blib.create_argparser(
    "Add etymologies to Russian pages based on directives", include_pagefile=True, include_stdin=True
)
parser.add_argument("--direcfile", help="File containing directives.")
parser.add_argument("--add-passive-of", action="store_true", help="Add {{passive of|ru|...}} to defn.")
parser.add_argument("--override-etym", action="store_true", help="Automatically override any existing etymologies.")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

for lineno, line in blib.iter_items_from_file(args.direcfile, start, end):
    process_line(lineno, line, args.add_passive_of, args.override_etym, args.save, args.verbose)
