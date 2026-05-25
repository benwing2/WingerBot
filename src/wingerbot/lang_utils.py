#!/usr/bin/env python3

from collections.abc import Callable
import re, json, sys
from collections import defaultdict
import unicodedata
from json.decoder import JSONDecodeError

from wingerbot.blib import site, msg
from wingerbot.slavic.russian import rulib

appendix_only_langnames = [
    "Adûni",
    "Afrihili",
    "Belter Creole",
    "Black Speech",
    "Bolak",
    "Communicationssprache",
    "Dothraki",
    "Eloi",
    "Glosa",
    "Goa'uld",
    "High Valyrian",
    "Interlingue",
    "Interslavic",
    "Klingon",
    "Kotava",
    "Láadan",
    "Lapine",
    "Lingua Franca Nova",
    "Lojban",
    "Mandalorian",
    "Medefaidrin",
    "Mundolinco",
    "Na'vi",
    "Neo",
    "Novial",
    "Noxilo",
    "Quenya",
    "Romanova",
    "Sindarin",
    "Talossan",
    "Toki Pona",
    "Unas",
]

lemma_poses = [
    "Abbreviation",
    "Acronym",
    "Adjectival noun",  # Japanese-specific
    "Adjective",
    "Adnominal",
    "Adposition",
    "Adverb",
    "Affix",
    "Ambiposition",
    "Article",
    "Cardinal number",
    "Circumfix",
    "Circumposition",
    "Classifier",
    "Combined form",
    "Combining form",
    "Confix",
    "Conjunction",
    "Contraction",
    "Converb",
    "Counter",
    "Determiner",
    "Diacritical mark",
    "Gerund",
    "Han character",
    "Han tu",
    "Hanja",
    "Hanzi",
    "Ideophone",
    "Idiom",
    "Infinitive",
    "Infix",
    "Initialism",
    "Interfix",
    "Interjection",
    "Jyutping",
    "Kanji",
    "Kanji reading",
    "Letter",
    "Ligature",
    "Misspelling",
    "Morpheme",
    "Noun",
    "Number",
    "Numeral",
    "Numeral symbol",
    "Particle",
    "Participle",
    "Pinyin",
    "Phrase",
    "Postposition",
    "Postpositional phrase",
    "Predicative",
    "Prefix",
    "Preposition",
    "Prepositional phrase",
    "Preverb",
    "Pronominal adverb",
    "Pronoun",
    "Proper noun",
    "Proverb",
    "Punctuation mark",
    "Relative",
    "Romaji",
    "Romanization",
    "Root",
    "Singulative",
    "Stem",
    "Suffix",
    "Syllable",
    "Symbol",
    "Verb",
]

re_escaped_lemma_poses = [re.escape(k) for k in lemma_poses]
pos_regex = "(%s)" % "|".join(re_escaped_lemma_poses)


langcode_langname_to_correct_langcode = {
    # Don't do the following; they aren't correct.
    # ("Middle Chinese", "zh"): "ltc",
    # ("Old Chinese", "zh"): "och",
    # Don't do the following; it isn't correct.
    # ("Cantonese", "zh"): "yue",
    #
    ("Algerian Arabic", "ar"): "arq",
    # ("Arabic", "xng"):
    # ("Armenian", "xcl"):
    ("Biloxi", "bil"): "bll",
    ("Bulgarian", "be"): "bg",
    ("Armenian", "ar"): "hy",
    ("Aromanian", "ro"): "rup",
    ("Catalan", "en"): "ca",
    # ("Chagatai", "tt"):
    ("Chinese", "cmn"): "cmn",
    # ("Chinese", "xng"):
    ("Classical Syriac", "arc"): "syc",
    ("Cornish", "co"): "kw",
    # ("Crimean Tatar", "krc"):
    # ("Dutch", "dum"):
    ("Dutch", "en"): "nl",
    ("Early Assemese", "as"): "inc-oas",
    ("Egyptian Arabic", "ar"): "arz",
    # ("English", "enm: do by hand?"):
    ("English", "es"): "en",
    ("English", "fr"): "en",
    ("English", "la"): "en",
    ("English", "tl"): "en",
    ("Estonian", "es"): "et",
    # ("Faroese", "is"):
    ("French", "en"): "fr",
    # ("French", "frm"):
    # ("French", "fro"):
    # ("French", "nrf"):
    ("Friulian", "fr"): "fur",
    ("Galician", "es"): "gl",
    ("Galician", "ga"): "gl",
    ("Galician", "pt"): "gl",
    ("German", "fr"): "de",
    # ("German", "gmh"):
    # ("Greek", "grc: do by hand?"):
    ("Gulf Arabic", "ar"): "afb",
    # ("Hebrew", "arc"):
    ("Hijazi Arabic", "ar"): "acw",
    ("Hijazi Arabic", "arz"): "acw",
    ("Hokkien", "cmn"): "nan-hbl",
    # ("Icelandic", "fo "):
    ("Iraqi Arabic", "ar"): "acm",
    ("Iraqi Arabic", "arz"): "acm",
    # ("Irish", "sga"):
    ("Italian", "en"): "it",
    ("Italian", "fr"): "it",
    ("Italian", "la"): "it",
    ("Italian", "pt"): "it",
    ("Kurdish", "ckb"): "ckb",
    ("Latin", "en"): "la",
    # ("Latin", "mul"):
    ("Latvian", "lt"): "lv",
    # ("Livvi", "krl"):
    ("Livvi", "liv"): "olo",
    ("Low German", "nds-de"): "nds-de",
    ("Mamluk-Kipchak", "qwm"): "trk-mmk",
    ("Mandarin", "zh"): "cmn",
    ("Middle Armenian", "hy"): "axm",
    ("Middle Breton", "mbr"): "xbm",
    ("Middle Breton", "mbt"): "xbm",
    ("Middle Dutch", "nl"): "dum",
    # ("Middle English", "ang"):
    ("Middle English", "en"): "enm",
    ("Middle French", "fr"): "frm",
    ("Middle High German", "de"): "gmh",
    # ("Middle Low German", "gmh"):
    ("Middle Low German", "mgl"): "gml",
    ("Middle Welsh", "mlw"): "wlm",
    ("Middle Welsh", "mwl"): "wlm",
    ("Moroccan Arabic", "ar"): "ary",
    ("Moroccan Arabic", "arz"): "ary",
    ("Norman", "fr"): "nrf",
    ("North Levantine Arabic", "acp"): "apc",
    ("North Levantine Arabic", "ar"): "apc",
    ("Norwegian Bokmål", "no"): "nb",
    ("Norwegian Nynorsk", "no"): "nn",
    # ("Norwegian", "da"):
    ("Norwegian", "nb"): "nb",
    ("Norwegian", "nn"): "nn",
    ("Norwegian", "non"): "no",
    # ("Occitan", "ca "):
    ("Old Belarusian", "be"): "zle-obe",
    ("Old Catalan", "ca"): "roa-oca",
    ("Old Danish", "da"): "gmq-oda",
    ("Old French", "fr"): "fro",
    ("Old Galician-Portuguese", "pt"): "roa-opt",
    ("Old Irish", "ga"): "sga",
    ("Old Italian", "ito"): "roa-oit",
    ("Old Latin", "la"): "itc-ola",
    ("Old Norse", "no"): "non",
    ("Old Polish", "pl"): "zlw-opl",
    ("Old Portuguese", "pt"): "roa-opt",
    ("Old Spanish", "es"): "osp",
    ("Old Swedish", "sv"): "gmq-osw",
    ("Old Ukrainian", "uk"): "zle-ouk",
    ("Old Welsh", "wlo"): "owl",
    ("Portuguese", "br"): "pt",
    ("Portuguese", "es"): "pt",
    ("Sardinian", "sn"): "sc",
    ("Scots", "en"): "sco",
    ("Sicilian", "sc"): "scn",
    # ("Silesian", "gmw-ecg (dialect of gmw-ecg)"):
    # ("Solon", "evn"):
    ("South Levantine Arabic", "ar"): "ajp",
    ("Spanish", "fr"): "es",
    ("Spanish", "it"): "es",
    ("Spanish", "pt"): "es",
    ("Sudanese Arabic", "ar"): "apd",
    ("Swabian", "gsw"): "swg",
    # ("Swedish", "gmq-osw"):
    # ("Swedish", "no"):
    ("Swedish", "se"): "sv",
    ("Swedish", "sw"): "sv",
    ("Tagalog", "en"): "tl",
    ("Tunisian Arabic", "ar"): "aeb",
    ("Ukrainian", "ru"): "uk",
    # ("Uyghur", "xng"):
    # ("Wa", "prk"):
    ("Walloon", "wal"): "wa",
    # ("West Frisian", "ofs"):
    ("Yemeni Arabic", "ar"): "ayn",
}

non_canonical_to_canonical_names = {
    "Romansh": "Romansch",
    "Bokmål": "Norwegian Bokmål",
    "Nynorsk": "Norwegian Nynorsk",
    "Azeri": "Azerbaijani",
    "Old Frankish": "Frankish",
    "Cuman": "Kipchak",  # is this correct?
    "Khorezmian": "Khwarezmian",
    "East Frisian": "Saterland Frisian",
    "Uighur": "Uyghur",
    "Meadow Mari": "Eastern Mari",
    "Hill Mari": "Western Mari",
    # Komi: less specific than Komi-Zyrian
    # Croatian: ? map to Serbo-Croatian?
    # Nancowry: more specific than Central Nicobarese
    # Mari: less specific than Eastern Mari
    "Malaccan Creole Portuguese": "Kristang",
    "Modern Greek": "Greek",
    "Oriya": "Odia",
    # Languedocien: more specific than Occitan
    # Gascon: more specific than Occitan
    "Nogay": "Nogai",
    "Kurripako": "Curripaco",
    "Official Aramaic": "Imperial Aramaic",
    "Southern Altay": "Southern Altai",
    "Ludic": "Ludian",
    "Sorani": "Central Kurdish",
    "Sinhala": "Sinhalese",
    "Car": "Car Nicobarese",
    # Serbian: ? map to Serbo-Croatian?
    "Kurmanji": "Northern Kurdish",
    # Chakavian: more specific than Serbo-Croatian
    # Valencian: more specific than Catalan
    # Logudorese Sardinian: more specific than Sardinian
    # Campidanese: more specific than Sardinian
    "Awakatek": "Aguacateca",
    # Auvergnat: more specific than Occitan
    "Yukuna": "Yucuna",
    "West Greenlandic Pidgin": "Greenlandic Pidgin",
    # Walser: more specific than Alemannic German
    # Swiss German: more specific than German
    "Papiamento": "Papiamentu",
    "Low Saxon": "Low German",
    # Kinyarwanda: ? more specific than Rwanda-Rundi?
    # Kajkavian: more specific than Serbo-Croatian
    "Izhorian": "Ingrian",
    # Flemish: ? more specific than Dutch?
    "Belarussian": "Belarusian",
    "Sipakapa": "Sipakapense",
    # Ripuarian: ? more specific than Central Franonian?
    # Nuorese: more specific than Sardinian
    # Moselle Franconian: ? more specific than Central Franconian?
    # Logudorese: more specific than Sardinian
    "Inupiaq": "Inupiak",
    # Frisian: not same as West Frisian
    "Abkhazian": "Abkhaz",
    "Tangkhul": "Tangkhul Naga",
    # Siglitun: ? more specific than Inuktitut?
    "Salako": "Kendayan",
    "Proto-Sami": "Proto-Samic",
    "Poitevin": "Poitevin-Saintongeais",
    "Old Uighur": "Old Uyghur",
    # Nunatsiavummiut: ? more specific than Inuktitut?
    "Khamnigan": "Khamnigan Mongol",
    # Inuinnaqtun: ? more specific than Inkutitut?
    "Ilokano": "Ilocano",
    # "High German": "German",
    # Erzgebirgisch: more specific than East Central German
    # Bontok: not same as Central Bontoc
    "Bikol": "Bikol Central",
    "Balochi": "Baluchi",
    # Amuzgo: not same as Guerrero Amuzgo
    ###
    ### Names formerly unrecognized, now non-canonical
    ###
    "Khalkha": "Khalkha Mongolian",
    "Eastern Yugur": "East Yugur",
    "Orkhon": "Old Turkic",
    "Sgaw": "S'gaw Karen",
    "Faeroese": "Faroese",
}

unrecognized_to_canonical_names = {
    "Written Tibetan": ("Written", "Tibetan"),
    "Written Burmese": ("Written", "Burmese"),
}

languages_by_code = None
languages_by_canonical_name = None
languages_by_alias = None

families_by_code = None
families_by_canonical_name = None

scripts_by_code = None
scripts_by_canonical_name = None

etym_languages_by_code = None
etym_languages_by_canonical_name = None
etym_languages_by_alias = None

wm_languages_by_code = None
wm_languages_by_canonical_name = None

language_aliases_to_canonical = None


def init_fake_langdata():
    global languages_by_canonical_name, languages_by_code, etym_languages_by_canonical_name, etym_languages_by_code
    languages_by_canonical_name = {
        "English": {"code": "en"},
        "Old English": {"code": "ang"},
        "Greek": {"code": "el"},
        "Hungarian": {"code": "hu"},
        "Japanese": {"code": "ja"},
        "Chinese": {"code": "zh"},
        "Spanish": {"code": "es"},
        "French": {"code": "fr"},
        "Portuguese": {"code": "pt"},
        "Latin": {"code": "la"},
        "Norwegian Bokmål": {"code": "nb"},
        "Norwegian Nynorsk": {"code": "nn"},
    }
    languages_by_code = {y["code"]: {"canonicalName": x} for x, y in languages_by_canonical_name.items()}
    etym_languages_by_canonical_name = {}
    etym_languages_by_code = {y["code"]: {"canonicalName": x} for x, y in etym_languages_by_canonical_name.items()}


def get_all_lang_data():
    get_language_data()
    get_family_data()
    get_script_data()
    get_etym_language_data()
    get_alias_data()


def save_all_lang_data(outfile):
    langdata = site.expand_text("{{#invoke:User:MewBot|getLanguageData}}")
    families = site.expand_text("{{#invoke:User:MewBot|getFamilyData}}")
    scripts = site.expand_text("{{#invoke:User:MewBot|getScriptData}}")
    etym_languages = site.expand_text("{{#invoke:User:MewBot|getEtymLanguageData}}")
    aliases = site.expand_text("{{#invoke:User:MewBot|getAliasData}}")
    master = {
        "languages": langdata,
        "families": families,
        "scripts": scripts,
        "etym_languages": etym_languages,
        "aliases": aliases,
    }
    with open(outfile, "w") as fp:
        fp.write(json.dumps(master))


def load_all_lang_data(outfile):
    with open(outfile, "r") as fp:
        master = json_loads(fp.read())
    set_language_data(master["languages"])
    set_family_data(master["families"])
    set_script_data(master["scripts"])
    set_etym_language_data(master["etym_languages"])
    set_alias_data(master["aliases"])


def json_loads(data):
    try:
        return json.loads(data)
    except JSONDecodeError:
        print("JSON decode error processing the following: %s" % data)
        raise


already_fetched_language_data = False


def set_language_data(jsondata):
    global languages_by_code, languages_by_canonical_name, languages_by_alias
    global already_fetched_language_data

    languages = json_loads(jsondata)
    languages_by_code = {}
    languages_by_canonical_name = {}
    languages_by_alias = defaultdict(list)

    for lang in languages:
        languages_by_code[lang["code"]] = lang
        languages_by_canonical_name[lang["canonicalName"]] = lang
        if "aliases" in lang:
            for alias in lang["aliases"]:
                assert type(alias) is str
                languages_by_alias[alias].append(lang)

    already_fetched_language_data = True


def get_language_data():
    if already_fetched_language_data:
        return
    jsondata = site.expand_text("{{#invoke:User:MewBot|getLanguageData}}")
    set_language_data(jsondata)


already_fetched_family_data = False


def set_family_data(familydata):
    global families_by_code, families_by_canonical_name
    global already_fetched_family_data

    families = json_loads(familydata)
    families_by_code = {}
    families_by_canonical_name = {}

    for fam in families:
        families_by_code[fam["code"]] = fam
        families_by_canonical_name[fam["canonicalName"]] = fam
    already_fetched_family_data = True


def get_family_data():
    if already_fetched_family_data:
        return
    familydata = site.expand_text("{{#invoke:User:MewBot|getFamilyData}}")
    set_family_data(familydata)


def set_script_data(scriptdata):
    global scripts_by_code, scripts_by_canonical_name

    scripts = json_loads(scriptdata)
    scripts_by_code = {}
    scripts_by_canonical_name = {}

    for sc in scripts:
        scripts_by_code[sc["code"]] = sc
        canonical_name = sc["canonicalName"]
        if canonical_name in scripts_by_canonical_name:
            newcode = sc["code"]
            curcode = scripts_by_canonical_name[canonical_name]["code"]
            if "-" not in newcode:
                if "-" in curcode:
                    scripts_by_canonical_name[canonical_name] = sc
                else:
                    msg(
                        "WARNING: Both script code '%s' and '%s' have canonical name '%s' and neither has a hyphen"
                        % (curcode, newcode, canonical_name)
                    )
        else:
            scripts_by_canonical_name[canonical_name] = sc


already_fetched_script_data = False


def get_script_data():
    global already_fetched_script_data
    if already_fetched_script_data:
        return
    scriptdata = site.expand_text("{{#invoke:User:MewBot|getScriptData}}")
    set_script_data(scriptdata)
    already_fetched_script_data = True


already_fetched_etym_language_data = False


def set_etym_language_data(etymdata):
    global etym_languages_by_code, etym_languages_by_canonical_name, etym_languages_by_alias
    global already_fetched_etym_language_data

    etym_languages = json_loads(etymdata)
    etym_languages_by_code = {}
    etym_languages_by_canonical_name = {}
    etym_languages_by_alias = defaultdict(list)

    for etyl in etym_languages:
        etym_languages_by_code[etyl["code"]] = etyl
        etym_languages_by_canonical_name[etyl["canonicalName"]] = etyl
        if "aliases" in etyl:
            for alias in etyl["aliases"]:
                assert type(alias) is str
                etym_languages_by_alias[alias].append(etyl)

    already_fetched_etym_language_data = True


def get_etym_language_data():
    if already_fetched_etym_language_data:
        return
    etymdata = site.expand_text("{{#invoke:User:MewBot|getEtymLanguageData}}")
    set_etym_language_data(etymdata)


already_fetched_alias_data = False


def set_alias_data(aliasdata):
    global language_aliases_to_canonical
    global already_fetched_alias_data

    language_aliases_to_canonical = json_loads(aliasdata)
    already_fetched_alias_data = True


def get_alias_data():
    if already_fetched_alias_data:
        return
    aliasdata = site.expand_text("{{#invoke:User:MewBot|getAliasData}}")
    set_alias_data(aliasdata)


# Key for sorting by langname.
def langname_key(langname, prepend_translingual_english=True):
    key = None
    if prepend_translingual_english:
        if langname == "Translingual":
            key = " "
        elif langname == "English":
            # Translingual before English per [[WT:ELE]].
            key = "  "
    if key is None:
        # FIXME! What is the correct rule for handling non-ASCII characters? I notice that e.g. Yámana comes before
        # Yoruba on [[ala]] and elsewhere (hence combining diacritics should be ignored), and 'Are'are comes between Ao and
        # Asturian on [[na]] (hence apostrophes should be ignored), but ǃKung (not with an exclamation point but U+01C3)
        # comes after Zulu (hence non-ASCII letters should not be ignored). For now I've decided to convert to decomposed
        # form and remove apostrophes and all combining diacritics (which are generally in the range U+0300 to U+036F).
        key = re.sub(r"[-\s'\"ʻʼ\u0300-\u036F]", "", unicodedata.normalize("NFD", langname)).lower()
    return (key, langname)


# Compile a map from etym language code to its corresponding full language.
def get_etym_language_to_parent_map():
    get_etym_language_data()
    etym_language_to_parent = {}
    for code, spec in etym_languages_by_code.items():
        if "full" in spec:  # etym-lang families don't have the key "full"
            etym_language_to_parent[code] = spec["full"]
    return etym_language_to_parent


# Compile a map from all language names (including for etym languages) to a tuple
# (LANGCODES, ETYMCODE, ISETYMCANON) where LANGCODES is a list of zero or more
# tuples of (CODE, ISCANON) where CODE is a non-etym lang code and ISCANON is True
# if this language name is the canonical name of that code; ETYMCODE is the best etym
# code associated with this language name or None if no etym codes associated with
# this language name, and ISETYMCANON is True if the language name is the canonical
# name of ETYMCODE. We accumulate the list of all non-etym lang codes because we have
# the non-etym lang code specified already and need to match, but need to adjudicate
# among multiple codes for a given etym language because we have to pick one code to
# use when the language name is encountered.
def get_language_name_to_code():
    get_language_data()
    get_etym_language_data()
    language_name_to_code = {}

    def add_name_with_code(name, code, iscanon, isetym):
        if name in language_name_to_code:
            langcodes, otheretymcode, otherisetymcanon = language_name_to_code[name]
            if not isetym:
                langcodes.append((code, iscanon))
            elif otheretymcode is None:
                language_name_to_code[name] = (langcodes, code, iscanon)
            else:
                if iscanon and not otherisetymcanon:
                    msg(
                        "Preferring new %s over existing %s because their name %s is the canonical name of new %s but not existing %s"
                        % (code, otheretymcode, name, code, otheretymcode)
                    )
                    setnew = True
                elif otherisetymcanon and not iscanon:
                    msg(
                        "Preferring existing %s over new %s because their name %s is the canonical name of existing %s but not new %s"
                        % (otheretymcode, code, name, otheretymcode, code)
                    )
                    setnew = False
                elif re.search("^[a-z][a-z]$", code):
                    msg(
                        "Preferring new %s over existing %s (name %s) because new %s looks like a two-letter regular language code"
                        % (code, otheretymcode, name, code)
                    )
                    setnew = True
                elif re.search("^[a-z][a-z]$", otheretymcode):
                    msg(
                        "Preferring existing %s over new %s (name %s) because existing %s looks like a two-letter regular language code"
                        % (otheretymcode, code, name, otheretymcode)
                    )
                    setnew = False
                elif re.search("^[a-z][a-z][a-z]$", code):
                    msg(
                        "Preferring new %s over existing %s (name %s) because new %s looks like a regular three-letter language code"
                        % (code, otheretymcode, name, code)
                    )
                    setnew = True
                elif re.search("^[a-z][a-z][a-z]$", otheretymcode):
                    msg(
                        "Preferring existing %s over new %s (name %s) because existing %s looks like a regular three-letter language code"
                        % (otheretymcode, code, name, otheretymcode)
                    )
                    setnew = False
                elif "-" in code:
                    msg(
                        "Preferring new %s over existing %s (name %s) because new %s has a hyphen in it"
                        % (code, otheretymcode, name, code)
                    )
                    setnew = True
                elif "-" in otheretymcode:
                    msg(
                        "Preferring existing %s over new %s (name %s) because existing %s has a hyphen in it"
                        % (otheretymcode, code, name, otheretymcode)
                    )
                    setnew = False
                elif "." in code:
                    msg(
                        "Preferring new %s over existing %s (name %s) because new %s has a period in it"
                        % (code, otheretymcode, name, code)
                    )
                    setnew = True
                elif "." in otheretymcode:
                    msg(
                        "Preferring existing %s over new %s (name %s) because existing %s has a period in it"
                        % (otheretymcode, code, name, otheretymcode)
                    )
                    setnew = False
                elif len(code) < len(otheretymcode):
                    msg(
                        "Preferring new %s over existing %s (name %s) because new %s is shorter"
                        % (code, otheretymcode, name, code)
                    )
                    setnew = True
                elif len(otheretymcode) < len(code):
                    msg(
                        "Preferring existing %s over new %s (name %s) because existing %s is shorter"
                        % (otheretymcode, code, name, otheretymcode)
                    )
                    setnew = False
                else:
                    msg(
                        "Preferring new %s over existing %s (name %s) because %s is new"
                        % (code, otheretymcode, name, code)
                    )
                    setnew = True
                if setnew:
                    language_name_to_code[name] = (langcodes, code, iscanon)
        else:
            if isetym:
                language_name_to_code[name] = ([], code, iscanon)
            else:
                language_name_to_code[name] = ([(code, iscanon)], None, None)

    for code, desc in languages_by_code.items():
        add_name_with_code(desc["canonicalName"], code, True, False)
        if "aliases" in desc:
            for alias in desc["aliases"]:
                add_name_with_code(alias, code, False, False)
        # Not safe to add otherNames, which may be varieties, and information will be lost. E.g.
        # Replacing <Jèrriais {{m|nrf|lanchi}}> with <{{cog|nrf|lanchi}}> (BAD).
        # if "otherNames" in desc:
        #  for othername in desc["otherNames"]:
        #    add_name_with_code(othername, code, False, False)
    for code, desc in etym_languages_by_code.items():
        add_name_with_code(desc["canonicalName"], code, True, True)
        if "aliases" in desc:
            for alias in desc["aliases"]:
                add_name_with_code(alias, code, False, True)
        # Not safe to add otherNames, which may be varieties, and information will be lost.
        # if "otherNames" in desc:
        #  for othername in desc["otherNames"]:
        #    add_name_with_code(othername, code, False, True)

    # 2024-10-15: temporary hack for recently renamed language Venetian -> Venetan (still in dump)
    if "Venetan" in language_name_to_code:
        language_name_to_code["Venetian"] = language_name_to_code["Venetan"]

    return language_name_to_code


GRAVE = "\u0300"  # grave =  ̀
ACUTE = "\u0301"  # acute =  ́
CFLEX = "\u0302"  # circumflex =  ̂
TILDE = "\u0303"  # tilde =  ̃
MACRON = "\u0304"  # macron =  ̄
BREVE = "\u0306"  # breve =  ̆
DOTABOVE = "\u0307"  # dot above =  ̇
DIAER = "\u0308"  # diaeresis =  ̈
DOUBLEACUTE = "\u030b"
CARON = "\u030c"  # caron =  ̌
VERTLINEABOVE = "\u030d"
DOUBLEGRAVE = "\u030f"  # double grave
INVBREVE = "\u0311"  # inverse breve
DOTUNDER = "\u0323"  # dot below
DIAERUNDER = "\u0324"
RINGBELOW = "\u0325"  # ring below
CEDILLA = "\u0327"  # cedilla =  ̧
OGONEK = "\u0328"  # ogonek =  ̨
DOUBLEMACRON = "\u033f"
DOTABOVERIGHT = "\u0358"
DOUBLEINVBREVE = "\u0361"  # double inverted breve

zh_combining_accent_re = (
    "["
    + GRAVE
    + ACUTE
    + CFLEX
    + MACRON
    + BREVE
    + DOTABOVE
    + DIAER
    + DOUBLEACUTE
    + CARON
    + VERTLINEABOVE
    + DOUBLEGRAVE
    + DOTUNDER
    + DIAERUNDER
    + DOUBLEMACRON
    + DOTABOVERIGHT
    + "ⁿ]"
)


def hy_remove_accents(text):
    text = re.sub("[՞՜՛՟]", "", text)
    text = re.sub("և", "ե", text)
    text = re.sub("<sup>յ</sup>", "յ", text)
    text = re.sub("<sup>ի</sup>", "ի", text)
    return text


def grc_remove_accents(text):
    text = re.sub("[ᾸᾹ]", "Α", text)
    text = re.sub("[ᾰᾱ]", "α", text)
    text = re.sub("[ῘῙ]", "Ι", text)
    text = re.sub("[ῐῑ]", "ι", text)
    text = re.sub("[ῨῩ]", "Υ", text)
    text = re.sub("[ῠῡ]", "υ", text)
    return text


def bg_remove_accents(text):
    return unicodedata.normalize("NFC", unicodedata.normalize("NFD", text).replace(ACUTE, "").replace(GRAVE, ""))


def mk_remove_accents(text):
    return unicodedata.normalize("NFC", unicodedata.normalize("NFD", text).replace(ACUTE, ""))


def sh_remove_accents(text):
    return unicodedata.normalize(
        "NFC",
        unicodedata.normalize("NFD", text)
        .replace(ACUTE, "")
        .replace(GRAVE, "")
        .replace(DOUBLEGRAVE, "")
        .replace(INVBREVE, "")
        .replace(MACRON, "")
        .replace(TILDE, ""),
    )


def sl_remove_accents(text):
    return unicodedata.normalize(
        "NFC",
        unicodedata.normalize("NFD", text)
        .replace(ACUTE, "")
        .replace(GRAVE, "")
        .replace(MACRON, "")
        .replace(CFLEX, "")
        .replace(DOUBLEGRAVE, "")
        .replace(INVBREVE, "")
        .replace(DOTUNDER, "")
        .replace("ə", "e")
        .replace("ł", "l"),
    )


def la_remove_accents(text):
    return unicodedata.normalize(
        "NFC",
        unicodedata.normalize("NFD", text)
        .replace(MACRON, "")
        .replace(BREVE, "")
        .replace(DIAER, "")
        .replace(DOUBLEINVBREVE, ""),
    )


def lt_remove_accents(text):
    return unicodedata.normalize(
        "NFC", unicodedata.normalize("NFD", text).replace(ACUTE, "").replace(GRAVE, "").replace(TILDE, "")
    )


def phi_remove_accents(text):
    return unicodedata.normalize(
        "NFC", unicodedata.normalize("NFD", text).replace(ACUTE, "").replace(GRAVE, "").replace(CFLEX, "")
    )


def phi_diaer_remove_accents(text):
    return unicodedata.normalize(
        "NFC",
        unicodedata.normalize("NFD", text).replace(ACUTE, "").replace(GRAVE, "").replace(CFLEX, "").replace(DIAER, ""),
    )


def he_remove_accents(text):
    text = re.sub("[\u0591-\u05bd\u05bf-\u05c5\u05c7]", "", text)
    return text


def ar_remove_accents(text):
    text = re.sub("\u0671", "\u0627", text)
    text = re.sub("[\u064b-\u0652\u0670\u0640]", "", text)
    return text


def fa_remove_accents(text):
    text = re.sub("[\u064e-\u0652]", "", text)
    return text


def ur_remove_accents(text):
    text = re.sub("[\u064b-\u0652]", "", text)
    return text


def ie_remove_accents(text):
    return unicodedata.normalize(
        "NFC", unicodedata.normalize("NFD", text).replace(ACUTE, "").replace(GRAVE, "").replace(CFLEX, "")
    )


latin_charset = "\\- '’.,0-9A-Za-z¡-\u036fḀ-ỿ"
cyrillic_charset = "Ѐ-џҊ-ԧꚀ-ꚗ"
# Doesn't work due to surrogate chars.
# glagolitic_charset = "Ⰰ-ⱞ𞀀-𞀪"
arabic_charset = "؀-ۿݐ-ݿࢠ-ࣿﭐ-﷽ﹰ-ﻼ"
hebrew_charset = "\u0590-\u05ff\ufb1d-\ufb4f"
devanagari_charset = "\u0900-\u097f\ua8e0-\ua8fd"
assamese_charset = "\u0981-\u0983\u0985-\u098c\u098f\u0990\u0993-\u09a8\u09aa-\u09af\u09b6-\u09b9\u09bc-\u09c4\u09c7-\u09ce\u09d7\u09a1\u09bc\u09a2\u09bc\u09af\u09bc\u09bc\u09e0-\u09e3\u09e6-\u09f1"
newa_charset = "𑐀-𑑞"
malayalam_charset = "\u0d02-\u0d7f"
sinhalese_charset = "\u0d82-\u0df4"

# Each element is full language name, function to remove accents to normalize
# an entry, character set range(s), and whether to ignore translit (info
# from [[Module:links]], or "latin" if the language uses the Latin script and
# hence has no translit, or "notranslit" if the language doesn't do
# auto-translit)
language_codes_to_properties: dict[str, tuple[str, Callable[[str], str], str, str | bool]] = {
    "af": ("Afrikaans", lambda x: x, latin_charset, "latin"),
    "am": ("Amharic", lambda x: x, "ሀ-᎙ⶀ-ⷞꬁ-ꬮ", False),
    "ar": ("Arabic", ar_remove_accents, arabic_charset, False),
    "as": ("Assamese", lambda x: x, assamese_charset, False),
    "az": ("Azerbaijani", lambda x: x, latin_charset, "latin"),
    "ba": ("Bashkir", lambda x: x, cyrillic_charset, True),
    "bcl": ("Bikol Central", phi_remove_accents, latin_charset, "latin"),
    "be": ("Belarusian", bg_remove_accents, cyrillic_charset, False),
    "bg": ("Bulgarian", bg_remove_accents, cyrillic_charset, False),
    "bn": ("Bengali", lambda x: x, "ঀ-ঃঅ-ঌএঐও-নপ-রললশ-হ়-ৄেৈো-ৎৗড়ঢ়য়়ৠ-ৣ০-৯", False),
    "bo": ("Tibetan", lambda x: x, "ༀ-࿚", True),
    "br": ("Breton", lambda x: x, latin_charset, "latin"),
    "ca": ("Catalan", lambda x: x, latin_charset, "latin"),
    "ce": ("Chechen", lambda x: x.replace(MACRON, ""), cyrillic_charset, True),
    "ceb": ("Cebuano", phi_remove_accents, latin_charset, "latin"),
    "cs": ("Czech", lambda x: x, latin_charset, "latin"),
    #'cu': ("Old Church Slavonic", lambda x:x.replace("\u0484", ""), cyrillic_charset + glagolitic_charset, False),
    "cv": ("Chuvash", lambda x: x, cyrillic_charset, True),
    "cy": ("Welsh", lambda x: x, latin_charset, "latin"),
    "da": ("Danish", lambda x: x, latin_charset, "latin"),
    "de": ("German", lambda x: x, latin_charset, "latin"),
    "dlm": ("Dalmatian", lambda x: x, latin_charset, "latin"),
    "el": ("Greek", lambda x: x, "Ͱ-Ͽ", True),
    "en": ("English", lambda x: x, latin_charset, "latin"),
    "eo": ("Esperanto", lambda x: x, latin_charset, "latin"),
    "es": ("Spanish", lambda x: x, latin_charset, "latin"),
    "et": ("Estonian", lambda x: x, latin_charset, "latin"),
    "eu": ("Basque", lambda x: x, latin_charset, "latin"),
    "fa": ("Persian", fa_remove_accents, arabic_charset, "notranslit"),
    "fi": ("Finnish", lambda x: x.replace("ˣ", ""), latin_charset, "latin"),
    "fo": ("Faroese", lambda x: x, latin_charset, "latin"),
    "fr": ("French", lambda x: x, latin_charset, "latin"),
    "fur": ("Friulian", lambda x: x, latin_charset, "latin"),
    "fy": ("West Frisian", lambda x: x, latin_charset, "latin"),
    "ga": ("Irish", lambda x: x, latin_charset, "latin"),
    "gd": ("Scottish Gaelic", lambda x: x, latin_charset, "latin"),
    "gl": ("Galician", lambda x: x, latin_charset, "latin"),
    "grc": ("Ancient Greek", grc_remove_accents, "ἀ-῾Ͱ-Ͽ", True),
    "gu": ("Gujarati", lambda x: x, "\u0a81-\u0af9", False),
    "gv": ("Manx", lambda x: x, latin_charset, "latin"),
    "he": ("Hebrew", he_remove_accents, hebrew_charset, "notranslit"),
    "hi": ("Hindi", lambda x: x, "\u0900-\u097f\ua8e0-\ua8fd", False),
    "hil": ("Hiligaynon", phi_remove_accents, latin_charset, "latin"),
    "hu": ("Hungarian", lambda x: x, latin_charset, "latin"),
    "hy": ("Armenian", hy_remove_accents, "Ա-֏ﬓ-ﬗ", True),
    "ia": ("Interlingua", lambda x: x, latin_charset, "latin"),
    "id": ("Indonesian", lambda x: x, latin_charset, "latin"),
    "ie": ("Interlingue", ie_remove_accents, latin_charset, "latin"),
    "ilo": ("Ilocano", phi_diaer_remove_accents, latin_charset, "latin"),
    "io": ("Ido", lambda x: x, latin_charset, "latin"),
    "is": ("Icelandic", lambda x: x, latin_charset, "latin"),
    "it": ("Italian", lambda x: x, latin_charset, "latin"),
    "ka": ("Georgian", lambda x: x.replace(CFLEX, ""), "ა-ჿᲐ-Ჿ", True),
    "km": ("Khmer", lambda x: x, "ក-៹᧠-᧿", False),
    "kn": ("Kannada", lambda x: x, "ಀ-ೲ", False),
    "la": ("Latin", la_remove_accents, latin_charset, "latin"),
    "lb": ("Luxembourgish", lambda x: x, latin_charset, "latin"),
    "lmo": ("Lombard", lambda x: x, latin_charset, "latin"),
    "lo": ("Lao", lambda x: x, "ກ-ໟ", False),
    "lt": ("Lithuanian", lt_remove_accents, latin_charset, "latin"),
    # 'lv': ("Latvian", ..., latin_charset, "latin"),
    "mg": ("Malagasy", lambda x: x, latin_charset, "latin"),
    "mk": ("Macedonian", mk_remove_accents, cyrillic_charset, False),
    "ml": ("Malayalam", lambda x: x, malayalam_charset, True),
    "mr": ("Marathi", lambda x: x, devanagari_charset, False),
    "ms": ("Malay", lambda x: x, latin_charset, "latin"),
    "mt": ("Maltese", lambda x: x, latin_charset, "latin"),
    "my": ("Burmese", lambda x: x, "က-႟ꩠ-ꩿꧠ-ꧾ", True),
    "nb": ("Norwegian Bokmål", lambda x: x, latin_charset, "latin"),
    "ne": ("Nepalese", lambda x: x, devanagari_charset + newa_charset, False),
    "nl": ("Dutch", lambda x: x, latin_charset, "latin"),
    "nn": ("Norwegian Nynorsk", lambda x: x, latin_charset, "latin"),
    "no": ("Norwegian", lambda x: x, latin_charset, "latin"),
    "non": ("Old Norse", lambda x: x, latin_charset, "latin"),
    "oc": ("Occitan", lambda x: x, latin_charset, "latin"),
    "or": ("Oriya", lambda x: x, "\u0b01-\u0b77", False),
    "pa": ("Punjabi", lambda x: x, "\u0a01-\u0a75", "notranslit"),
    "pag": ("Pangasinan", phi_diaer_remove_accents, latin_charset, "latin"),
    "pam": ("Kapampangan", phi_remove_accents, latin_charset, "latin"),
    "pl": ("Polish", lambda x: x, latin_charset, "latin"),
    "ps": ("Pashto", lambda x: x, arabic_charset, "notranslit"),
    "pt": ("Portuguese", lambda x: x, latin_charset, "latin"),
    "qu": ("Quechua", lambda x: x, latin_charset, "latin"),
    "rm": ("Romansch", lambda x: x, latin_charset, "latin"),
    "ro": ("Romanian", lambda x: x, latin_charset, "latin"),
    "ru": ("Russian", rulib.remove_accents, cyrillic_charset, False),
    "rup": ("Aromanian", lambda x: x, latin_charset, "latin"),
    "sh": ("Serbo-Croatian", sh_remove_accents, latin_charset + cyrillic_charset, "latin"),
    "si": ("Sinhalese", lambda x: x, sinhalese_charset, True),
    "sk": ("Slovak", lambda x: x, latin_charset, "latin"),
    "sl": ("Slovene", sl_remove_accents, latin_charset, "latin"),
    "sq": ("Albanian", lambda x: x, latin_charset, "latin"),
    "sv": ("Swedish", lambda x: x, latin_charset, "latin"),
    "sw": ("Swahili", lambda x: x, latin_charset, "latin"),
    "ta": ("Tamil", lambda x: x, "\u0b82-\u0bfa", True),
    "te": ("Telugu", lambda x: x, "\u0c00-\u0c7f", True),
    "tg": ("Tajik", lambda x: x.replace(ACUTE, ""), cyrillic_charset, True),
    "th": ("Thai", lambda x: x, "ก-๛", False),
    "tl": ("Tagalog", phi_remove_accents, latin_charset, "latin"),
    "tr": ("Turkish", lambda x: x, latin_charset, "latin"),
    "uk": ("Ukrainian", bg_remove_accents, cyrillic_charset, False),
    "ur": ("Urdu", ur_remove_accents, arabic_charset, "notranslit"),
    "vi": ("Vietnamese", lambda x: x, latin_charset, "latin"),
    "war": ("Waray-Waray", phi_remove_accents, latin_charset, "latin"),
    "yi": ("Yiddish", lambda x: x, hebrew_charset, False),
}

# auto_languages = {}
# for code, desc in languages_by_code.items():
#  canonical_

language_names_to_properties = {
    langname: (langcode, remove_accents, charset, ignore_translit) for langcode, (langname, remove_accents, charset, ignore_translit) in language_codes_to_properties.items()
}


def do_remove_diacritics(text, patterns, remove_diacritics):
    pass


#chinese_low_surrogates = (
#    "["
#    +
#    # The following should be the SIP: U+20000 (D840+DC00) to U+2EBEF (D87A+DFEF): #"𠀀-𮯯"
#    # We include a bit more than needed to get everything.
#    "\ud840-\ud87a"
#    +
#    # The following should be the ExtG: U+30000 (D880+DC00) to U+3134F (D884+DF4F): "𰀀-𱍏"
#    # We include a bit more than needed to get everything.
#    "\ud880-\ud884"
#    + "]"
#)

chinese_misc_ideographic_symbols_and_punctuation = (
    # "𖿢𖿣𖿰𖿱"
    "\U00016fe2\U00016fe3\U00016ff0\U00016ff1"
    # i.e. D81B+DFE2 + D81B+DFE3 + D81B+DFF0 + D81B+DFF1
    # "\uD81B[\uDFE2\uDFE3\uDFF0\uDFF1]"
)

chinese_ranges = (
    "["
    + "\u4e00-\u9fff"  # "一-鿿"
    + "\u3400-\u4dbf"  # "㐀-䶿" # ExtA
    + "\U00020000-\U0002ebef"  # "𠀀-𮯯" # SIP
    + "\U00030000-\U0003134f"  # "𰀀-𱍏" # ExtG
    + "﨎﨏﨑﨓﨔﨟﨡﨣﨤﨧﨨﨩"
    + "\u2e80-\u2eff"  # "⺀-⻿" # Radicals Supplement
    + "\u3000-\u303f"  # "　-〿" # CJK Symbols and Punctuation
    +
    # "𖿢𖿣𖿰𖿱"+ # Ideographic Symbols and Punctuation
    "\u31c0-\u31ef"  # "㇀-㇯" # Strokes
    + "\u337b-\u337f\u32ff"  # "㍻-㍿㋿" # 組文字
    + chinese_misc_ideographic_symbols_and_punctuation
    + "]"
)


def matches_chinese_character(pagetitle):
    return (
        len(pagetitle) == 1
        and re.search("^" + chinese_ranges + "$", pagetitle)
        #    or len(pagetitle) == 2 and re.search("^" + chinese_low_surrogates + "$", pagetitle[0])
        #    or len(pagetitle) == 2 and re.search("^" + chinese_misc_ideographic_symbols_and_punctuation + "$", pagetitle)
    )


# Compile a map from etym language code to its first non-etym-language ancestor.
def old_get_etym_language_to_parent_map():
    etym_language_to_parent = {}
    for code in etym_languages_by_code:
        parent = code
        while parent in etym_languages_by_code:
            parent = etym_languages_by_code[parent]["parent"]
        etym_language_to_parent[code] = parent
    return etym_language_to_parent


def get_family_proto_lang(fam):
    if fam not in families_by_code:
        return None
    protolang = families_by_code[fam].get("protoLanguage", fam + "-pro")
    if protolang not in languages_by_code:
        return None
    return protolang


def get_lang_family(lang):
    if lang not in languages_by_code:
        return None
    fam = languages_by_code[lang].get("family", None)
    if fam and fam in families_by_code:
        return fam
    return None


def get_family_family(fam):
    if fam not in families_by_code:
        return None
    fam = families_by_code[fam].get("family", None)
    if fam and fam in families_by_code:
        return fam
    return None


# Return the direct ancestor(s) of a language. This is the same algorithm used
# in [[Module:languages]].
def get_lang_direct_ancestors(lang):
    if lang not in languages_by_code:
        return set()
    if "ancestors" in languages_by_code[lang]:
        return languages_by_code[lang]["ancestors"]
    fam = get_lang_family(lang)
    protolang = fam and get_family_proto_lang(fam) or None
    # For the case where the current language is the proto-language
    # of its family, we need to step up a level higher right from the start.
    if protolang and protolang == lang:
        fam = get_family_family(fam)
        protolang = fam and get_family_proto_lang(fam) or None
    while not protolang and not (not fam or fam == "qfa-not"):
        fam = get_family_family(fam)
        protolang = fam and get_family_proto_lang(fam) or None
    if protolang:
        return {protolang}
    else:
        return set()


def get_lang_all_ancestors(lang):
    all_ancestors = set()

    def get_all_ancestors(lang):
        direct_ancestors = get_lang_direct_ancestors(lang)
        for ancestor in direct_ancestors:
            all_ancestors.add(ancestor)
            get_all_ancestors(ancestor)

    get_all_ancestors(lang)
    return all_ancestors


def get_language_to_ancestors_map():
    # Compile a map from etym and non-etym language codes to all ancestors.
    language_to_ancestors = defaultdict(set)
    for code in etym_languages_by_code:
        parent = code
        while parent in etym_languages_by_code:
            parent = etym_languages_by_code[parent]["parent"]
            language_to_ancestors[code].add(parent)
        for ancestor in get_lang_all_ancestors(parent):
            language_to_ancestors[code].add(ancestor)
    for code in languages_by_code:
        for ancestor in get_lang_all_ancestors(code):
            language_to_ancestors[code].add(ancestor)

    language_to_ancestors["nb"].add("no")
    language_to_ancestors["nn"].add("no")
    language_to_ancestors["wym"].add("gmw-ecg")
    language_to_ancestors["lb"].add("gmw-cfr")

    # for code in languages_by_code:
    #  msg("For language %s, ancestors=%s" % (code, ",".join(language_to_ancestors[code])))
    # for code in etym_languages_by_code:
    #  msg("For language %s, ancestors=%s" % (code, ",".join(language_to_ancestors[code])))

    return language_to_ancestors


# List of punctuation or spacing characters that are found inside of words.
word_punc = "-־׳״'.·*’་•:"
not_word_punc = "([^" + word_punc + "]+)"


def get_spacing_punctuation():
    punc_chars = "".join("\\" + chr(i) for i in range(sys.maxunicode) if unicodedata.category(chr(i)).startswith("P"))
    return "[" + punc_chars + r"\s]+"
