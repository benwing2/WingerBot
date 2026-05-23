#!/usr/bin/env python3

import pywikibot, re, sys, argparse, unicodedata

from wingerbot import blib, lang_utils
from wingerbot.blib import getparam, rmparam, msg, errmsg, site, tname
from collections import defaultdict

# blib.init_fake_langdata()
lang_utils.get_all_lang_data()


def boolean_function_matches(fun, lang):
    if callable(fun):
        return fun(lang)
    elif type(fun) is str:
        raise ValueError("Invalid type (string) for Boolean function or set '%s' when matching '%s'" % (fun, lang))
    else:
        return lang in fun


def default_indentfun(group, lang):
    return lang.endswith(" " + group)


def langname_key(lang):
    return lang_utils.langname_key(lang, prepend_translingual_english=False)


indonesian_malay_rename_map = {
    "Arabic": "Jawi",
    "Roman": "Rumi",
    "Latin": "Rumi",
    "Brunei": "Brunei Malay",
    "Kelantan-Pattani Malay": "Pattani Malay",
    "Indonesia": "Indonesian",
    "Sarawakian": "Sarawak Malay",
    "Singkil": "Alas-Kluet Batak",
}
indonesian_malay_unindent = {
    "Acehnese",
    "Alas-Kluet Batak",
    "Balinese",
    "Banda",
    "Banjarese",
    "Buginese",
    "Ende",
    "Indonesian",
    "Javanese",
    "Madurese",
    "Makasar",
    "Minangkabau",
    "Nias",
    "Sikule",
    "Simeulue",
    "Sundanese",
}
malay_creole_mixed = {
    # all of these are creoles or mixed languages
    "Ambonese Malay",
    "Baba Malay",
    "Cocos Islands Malay",
    "Makassar Malay",
    "Malaccan Creole Malay",
    "North Moluccan Malay",
    "Papuan Malay",
    "Sri Lankan Creole Malay",
}

# Groups of languages handled under a single header, with properties. The key is the top-level header, which is usually
# a language name in its own right. The value is a dictionary of properties, with keys as follows:
# * "indent": Set of language names or a function of one argument, a language, that should return True if an unindented
#   lang of that name should be indented under this header. If unspecified, the default is to recognize any language
#   ending in the header's name.
# * "add_lang": Set of language names or a function of one argument, a language, that should return True if an indented
#   language of this name should have the header language appended to it. For example, under header "Arabic", if
#   `add_lang` contains "Algerian" or is a function that returns True when passed "Algenian", then a language named
#   "Algerian" that's already indented (or newly indented) under header "Arabic" will be converted to "Algerian Arabic".
#   Any occurrence of "Algerian" unindented or under a different header will not be affected.
# * "rename": A dictionary mapping languages to new names. A language with the key that is indented under the specified
#   header will be renamed to the value. Like "add_lang", this will not affected languages that are unindented or
#   indented under a different header.
# * "unindent": Set of language names or a function of one argument, a language, that should return True if the language
#   occurring indented under the header will be unindented (moved to top level).
# * "recognize": Set or language names or a function of one argument, a language, that should return True if a given
#   indented lang is recognized as belonging under this header. Any languages that return True when passed to `indent`,
#   as well as any languages on the right side of the `rename` dictionary or the right side of the virtual dictionary
#   specified by `add_lang` (i.e. any languages consisting of an element in `add_lang` plus the header name) will
#   automatically count, so this function only needs to return True for other languages. A warning will be emitted if
#   an indented language is seen that is not recognized, but no other action will be taken. (This is useful for finding
#   misspellings and non-canonical language names that need fixing up.) If `recognize` is omitted, it is equivalent to a
#   function returning False, i.e. any indented language not recognized by the other methods specified above will result
#   in a warning.
language_groups = {
    "Agta": {
        "add_lang": {
            # WARNING: The following do not form a clade and may come from several different Philippine families, but all are
            # spoken by Negritos.
            "Alabat Island",
            "Camarines Norte",
            "Casiguran Dumagat",
            "Central Cagayan",
            "Dicamay",
            "Dinapigue",
            "Dupaningan",
            "Isarog",
            "Mount Iraya",
            "Mount Iriga",
            "Nagtipunan",
            "Pahanan",
            "Remontado",
            "Umiray Dumaget",
            "Villa Viciosa",
        },
    },
    "Aizi": {
        "add_lang": {"Mobumrin", "Tiagbamrin"},
    },
    "Albanian": {
        "indent": lambda lang: lang.endswith(" Albanian") or lang in {"Arbëresh", "Arvanitika", "Tosk", "Gheg"},
    },
    "Alta": {
        "add_lang": {"Northern", "Southern"},
    },
    "Altai": {
        "add_lang": {"Northern", "Southern"},
    },
    "Amami Ōshima": {
        "add_lang": {"Northern", "Southern"},
    },
    # Ambrym: name of island, not a family; North Ambrym and Southeast Ambrym are in different subfamilies
    "Amuzgo": {
        "add_lang": {"Guerrero", "Ipalapa", "San Pedro Amuzgos"},
    },
    "Apabhramsa": {},
    "Apache": {
        "indent": lambda lang: lang.endswith(" Apache") or lang in {"Jicarilla", "Lipan", "Chiricahua"},  # not Navajo
        "rename": {
            "Chiricahua Apache": "Chiricahua",
            "Jicarilla Apache": "Jicarilla",
            "Lipan Apache": "Lipan",
            "Mescalero": "Chiricahua",
            "Western": "Western Apache",
        },
    },
    "Arabic": {
        "indent": lambda lang: lang.endswith(" Arabic") or lang in {"Hassaniya"},  # not Maltese or Nubi (creole)
        "add_lang": {
            "Algerian",
            "Andalusian",
            "Baharna",
            "Chadian",
            "Cypriot",
            "Dhofari",
            "Egyptian",
            "Gulf",
            "Hassaniya",
            "Hijazi",
            "Iraqi",
            "Juba",
            "Levantine",
            "Libyan",
            "Mesopotamian",
            "Moroccan",
            "Najdi",
            "North Levantine",
            "Omani",
            "South Levantine",
            "Sudanese",
            "Tunisian",
            "Yemeni",
        },
        "rename": {
            "Andalusi Arabic": "Andalusian Arabic",
            "Bahrani Arabic": "Baharna Arabic",
            "Hadrami Arabic": "Yemeni Arabic (Hadrami)",
            "Lebanese": "North Levantine Arabic (Lebanese)",
            "Lebanese Arabic": "North Levantine Arabic (Lebanese)",
            "Levantine, North": "North Levantine Arabic",
            "Levantine, South": "South Levantine Arabic",
            "Morocco": "Moroccan Arabic",
            "Palestine": "South Levantine Arabic (Palestinian)",
            "Palestinian": "South Levantine Arabic (Palestinian)",
            "Palestinian Arabic": "South Levantine Arabic (Palestinian)",
            "San'ani Arabic": "Yemeni Arabic (San'ani)",
            "San'ani Yemeni Arabic": "Yemeni Arabic (San'ani)",
            "Syrian": "North Levantine Arabic (Syrian)",
            "Syrian Arabic": "North Levantine Arabic (Syrian)",
            "Yemen": "Yemeni Arabic",
            "Standard": "Arabic",
        },
        "unindent": {"Arabic"},
    },
    "Aramaic": {
        "indent": lambda lang: lang.endswith(" Aramaic")
        or lang.endswith(" Neo-Aramaic")
        or lang
        in {
            "Mlahsö",
            "Turoyo",
            "Classical Syriac",
            "Hulaulá",
            "Hértevin",
            "Koy Sanjaq Surat",
            "Lishana Deni",
            "Lishanid Noshan",
            "Lishán Didán",
            "Senaya",
            "Classical Mandaic",
            "Mandaic",
        },
        "rename": {
            "Assyrian Neo Aramaic": "Assyrian Neo-Aramaic",
            "Babylonian": "Jewish Babylonian Aramaic",
            "Jewish Babylonian": "Jewish Babylonian Aramaic",
            "Jewish Baylonian Aramaic": "Jewish Babylonian Aramaic",
            # "Palestinian": "Jewish Palestinian Aramaic",
            # "Palestinian Aramaic": "Jewish Palestinian Aramaic",
            # "Syriac": "Classical Syriac", # commented out per Chuck Entz suggestion
            "Syriac, Classical": "Classical Syriac",
            "Classic Syriac": "Classical Syriac",
            "Hebrew": "Hebrew script",
            "Hebrew Script": "Hebrew script",
            "Imperial Aramiac": "Imperial Aramaic",
        },
        "unindent": {"Classical Nahuatl"},
    },
    "Armenian": {
        "add_lang": {"Classical", "Middle", "Old", "Western"},
        "rename": {
            "Modern Armenian": "Armenian",
        },
        "unindent": {"Armenian", "Assyrian Neo-Aramaic", "Egyptian Arabic"},
    },
    "Arrernte": {
        "add_lang": {"Eastern", "Western"},
    },
    "Ashéninka": {
        "indent": lambda lang: (
            lang.endswith(" Ashéninka") or lang.startswith("Ashéninka ") or lang in {"Ajyíninka Apurucayali"}
        ),
        # Pichis Ashéninka, South Ucayali Ashéninka, Ucayali-Yurúa Ashéninka, Ashéninka Pajonal, Ashéninka Perené,
        # Ajyíninka Apurucayali
        "add_lang": {"Pichis", "South Ucayali", "Ucayali-Yurúa"},
    },
    "Asmat": {
        # WARNING: The following, although closely related, don't form a clade without Citak. They represent the languages
        # of the Asmat ethnicity, while Citak is considered a different ethnicity.
        "add_lang": {"Casuarina Coast", "Central", "North", "Yaosakor"},
    },
    "Assamese": {
        "add_lang": {"Early", "Middle", "Central", "Eastern"},
        "rename": {
            "Old Assamese": "Early Assamese",
        },
    },
    "Atta": {
        "add_lang": {"Faire", "Pamplona", "Pudtol"},
    },
    "Avar": {
        "add_lang": {"Old"},
    },
    "Awadhi": {
        "add_lang": {"Old"},
    },
    "Awyu": {
        "add_lang": {"Asue", "Central", "Edera", "Jair", "North", "South"},
    },
    "Ayta": {
        # Tayabas is considered spurious by ISO and should be removed; Sorsogon probably likewise (unattested per
        # Glottolog).
        "add_lang": {"Abenlen", "Ambala", "Bataan", "Mag-Anchi", "Mag-Indi", "Sorsogon", "Tayabas"},
    },
    "Azerbaijani": {
        "rename": {
            "Abjad": "Arabic",
            "Persic": "Arabic",
            "Perso-Arabic": "Arabic",
            "Roman": "Latin",
            "Northern": "North Azerbaijani",
            "Southern": "South Azerbaijani",
        },
        "recognize": {"Cyrillic"},
    },
    "Bai": {
        "add_lang": {"Central", "Northern", "Lama", "Panyi", "Southern"},
    },
    "Baga": {
        # Baga Pokur is Senegambian (Atlantic-Congo) but the others form the Baga clade under Mel (Atlantic-Congo):
        # Baga Kaloum, Baga Koga, Baga Manduri, Baga Sitemu, Baga Sobané
        "indent": lambda lang: lang.startswith("Baga ")
        and lang not in {"Baga Pokur"},
    },
    "Bajau": {
        # FIXME, there is a third language in the clade, Mapun.
        "add_lang": {"Indonesian", "West Coast"},
    },
    # Banda: There are five Banda-Foo languages and four Foo Banda languages but none form a clade and there are several
    #        others not with Banda in their name.
    # Babar: North Babar and Southeast Babar are in different subfamilies and there are several other Babar languages in
    #        each family.
    "Bareli": {
        "add_lang": {"Palya", "Pauri", "Rathwi"},
    },
    "Batak": {
        "add_lang": {"Alas-Kluet", "Angkola", "Dairi", "Karo", "Mandailing", "Simalungun", "Toba"},
    },
    "Belarusian": {
        "rename": {
            "Roman": "Latin",
        },
    },
    "Bengali": {
        "add_lang": {"Middle", "Old"},
    },
    "Berber": {
        "indent": lambda lang: False,
        "unindent": {
            "Central Atlas Tamazight",
            "Kabyle",
            "Tachawit",
            "Tarifit",
            "Tashelhit",
            "Tunisian Berber",
            "Northern Saharan Berber",
        },
    },
    "Bété": {
        # FIXME: Two more languages are needed to form a clade, Godié and Kouya
        "add_lang": {"Daloa", "Gagnoa", "Guiberoua"},
    },
    # Bhil: Dungra Bhil and Sindhi Bhil are not closely related
    "Bhoti": {
        # Spiti Bhoti, Stod Bhoti, Bhoti Kinnauri form a clade with Nyamkat and Tukpa
        "indent": lambda lang: lang.endswith(" Bhoti") or lang.startswith("Bhoti "),
        "add_lang": {"Spiti", "Stod"},
    },
    "Bidayuh": {
        "add_lang": {"Bau", "Biatah", "Bukar-Sadung"},
    },
    "Bikol": {
        # Buhi'non Bikol, Libon Bikol, Miraya Bikol, West Albay Bikol; Bikol Central; Northern Catanduanes Bicolano,
        # Southern Catanduanes Bicolano, Iriga Bicolano.
        "indent": lambda lang: lang.endswith(" Bikol")
        or lang.startswith("Bikol ")
        or lang.endswith(" Bicolano"),
    },
    "Birifor": {
        "add_lang": {"Malba", "Southern"},
    },
    # Bisaya: Sabah Bisaya and Brunei Bisaya are named after locations and ethnic groups; not closely related.
    "Blaan": {
        "add_lang": {"Koronadal", "Sarangani"},
    },
    "Boma": {  # Bantu
        "add_lang": {"North", "South"},
    },
    "Bontoc": {
        "add_lang": {"Central", "Northern", "Southern", "Eastern", "Southwestern"},
    },
    "Bozo": {  # Mande
        "add_lang": {"Hainyaxo", "Jenaama", "Tiemacèwè", "Tiéyaxo"},
    },
    "Bunu": {
        "add_lang": {"Bu-Nao", "Jiongnai", "Wunai", "Younuo"},
    },
    "Breton": {
        "add_lang": {"Middle", "Old"},
    },
    "Bru": {
        # WARNING: The clade seems to also contain Sô, Khua, Northern Katang and Southern Katang.
        "add_lang": {"Eastern", "Western"},
    },
    "Buang": {
        # Note: this is a linkage, not a clade
        "add_lang": {"Mangga", "Mapos"},
    },
    "Bulgarian": {
        "rename": {
            "Cyrillic": "Bulgarian",
            "Old Bulgarian": "Old Church Slavonic",
        },
        "unindent": {"Bulgarian", "Old Church Slavonic", "Cantonese", "Egyptian Arabic", "Mandarin"},
    },
    "Bunu": {
        "add_lang": {"Bu-Nao", "Jiongnai", "Wunai", "Younuo"},
    },
    "Burmese": {
        "add_lang": {"Old"},
    },
    "Buryat": {
        "rename": {
            "Classic": "Old Buryat",
            "Classical": "Old Buryat",
        },
    },
    "Buyang": {
        "indent": lambda lang: lang.endswith(" Buyang") or lang in {"En", "Yerong"},
        "add_lang": {"E'ma", "Langnian"},
    },
    # Bwamu: four languages, Bomu, Buamu, Cwi Bwamu and Láá Láá Bwamu; we group them as the Bwa languages, while Glottolog
    #   calls them the Bwamu languages.
    "Catalan": {
        "indent": lambda lang: lang.endswith(" Catalan") or lang in {"Valencian"},
        "add_lang": {"Old"},
        "unindent": {"Mandarin"},
    },
    "Chakma": {
        "unindent": {"Eastern Cham", "Western Cham"},
    },
    "Cham": {
        # Note: Ai-Cham is unrelated
        "add_lang": {"Eastern", "Western"},
    },
    "Chatino": {
        "add_lang": {
            "Eastern Highland",
            "Nopala",
            "Tataltepec",
            "Teojomulco",
            "Western Highland",
            "Zacatepec",
            "Zenzontepec",
            "San Juan Quiahije",
        },
    },
    # Chehalis: Upper Chehalis and Lower Chehalis are in different subfamilies
    "Chin": {
        "add_lang": {
            "Asho",
            "Bawm",
            "Bualkhaw",
            "Chinbon",
            "Daai",
            "Falam",
            "Kaang",
            "Khumi",
            "Laitu",
            "Mara",
            "Mro",
            "Mün",
            "Ngawn",
            "Senthang",
            "Siyin",
            "Songlai",
            "Sumtu",
            "Tawr",
            "Tedim",
            "Thado",
            "Thaipum",
            "Zotung",
        },
    },
    "Chinantec": {
        "add_lang": {
            "Chiltepec",
            "Comaltepec",
            "Lalana",
            "Lealao",
            "Ojitlán",
            "Ozumacín",
            "Palantla",
            "Quiotepec",
            "Sochiapam",
            "Tepetotutla",
            "Tepinapa",
            "Tlacoatzintepec",
            "Usila",
            "Valle Nacional",
        },
    },
    "Chinese": {
        "indent": lambda lang: lang.endswith(" Chinese")
        or any(
            lang == x or lang.endswith(" " + x)
            for x in [
                "Mandarin",
                "Cantonese",
                "Yue",
                "Dungan",
                "Gan",
                "Hakka",
                "Huizhou",
                "Jin",
                "Min",
                "Min Nan",
                "Wu",
                "Hangzhounese",
                "Ningbonese",
                "Shanghainese",
                "Suzhounese",
                "Wenzhounese",
                "Xiang",
                "Pinghua",
                "Waxiang",
                "Hokkien",
                "Hainanese",
                "Teochew",
                "Shaozhou Tuhua",
                "Sichuanese",
                "Taishanese",
                "Tangwang",
            ]
        )
        or lang in {"Ci"},  # not Wutunhua, a Mandarin-Amdo-Bonan creole
        "add_lang": {"Middle", "Old"},
        "rename": {
            "Madarin": "Mandarin",
            "* Mandarin": "Mandarin",
            "Mandain": "Mandarin",
            "Min Bei": "Northern Min",
            "Min Dong": "Eastern Min",
            # "Min Nan": "Hokkien", Min Nan handled specially because we rename the lang code as well
            "Min Zhong": "Central Min",
            "Puxian": "Puxian Min",
            "Wuu": "Wu",
            "Suzhou dialect": "Suzhounese",
        },
        "unindent": {"German", "Hindi", "Italian", "Japanese", "Jingpo", "Mon", "Yiddish"},
    },
    "Chontal": {
        # Tabasco Chontal is not related to the others
        "indent": lambda lang: lang.endswith(" Chontal") and lang not in {"Tabasco Chontal"},
        "add_lang": {"Lowland Oaxaca", "Highland Oaxaca"},
    },
    "Chorote": {
        "add_lang": {"Iyojwa'ja", "Iyo'wujwa"},
    },
    "Circassian": {
        "add_lang": {"East", "West"},
    },
    "Comorian": {
        "add_lang": {"Maore", "Mwali", "Ndzwani", "Ngazidja"},
    },
    "Coptic": {
        "indent": lambda lang: lang.endswith(" Coptic")
        or lang in {"Akhmimic", "Bohairic", "Fayyumic", "Sahidic", "Lycopolitan", "Oxyrhynchite"},
        "add_lang": {"Akhmimic", "Bohairic", "Fayyumic", "Sahidic", "Lycopolitan", "Oxyrhynchite"},
        "rename": {
            "{{qualifier|Sahidic}}": "Sahidic Coptic",
            "{{q|Bohairic}}": "Bohairic Coptic",
            "Boharic": "Bohairic Coptic",
        },
    },
    "Cornish": {
        "add_lang": {"Middle", "Old"},
    },
    "Cree": {
        # Michif is listed as a Cree variety but it's actually a mixed language.
        "indent": lambda lang: lang.endswith(" Cree") or lang in {"Atikamekw", "Montagnais", "Naskapi"},
        "add_lang": {"Moose", "Northern East", "Plains", "Southern East", "Swampy", "Woods"},
    },
    "Crimean Tatar": {
        "rename": {
            "Roman": "Latin",
        },
    },
    "Cuicatec": {
        "add_lang": {"Tepeuxila", "Teutila"},
    },
    "Czech": {
        "add_lang": {"Old"},
    },
    # "Daju": Three of seven Dajuic languages (the three not forming a clade) end in Daju. According to Glottolog, the
    # hierarchy is Eastern Dajuic (Logorik and Shatt) vs. Western Dajuic, which splits into Dar Daju Daju, Dar Sila Daju,
    # Njalgulgule and Nyala Dajuic (Baygo and Dar Fur Daju).
    "Dani": {
        # forms a clade with Walak and Hupla
        "add_lang": {"Lower Grand Valley", "Mid Grand Valley", "Upper Grand Valley", "Western"},
    },
    "Danish": {
        "indent": lambda lang: lang.endswith(" Danish")
        and lang
        not in {
            # Traveller Danish is a mixed language
            "Traveller Danish"
        },
        "add_lang": {"Old"},
    },
    # Damar: East Damar and West Damar are not closely related.
    "Dida": {
        "indent": lambda lang: lang.endswith(" Dida") or lang in {"Guébie"},
        "add_lang": {"Lakota", "Yocoboué"},
    },
    "Dinka": {
        "add_lang": {"Northeastern", "Northwestern", "South Central", "Southeastern", "Southwestern"},
    },
    "Dogon": {
        "indent": lambda lang: lang.endswith(" Dogon")
        or lang in {"Tommo So", "Ben Tey", "Dogul Dom", "Jamsay", "Bunoge"},
        "add_lang": {
            "Ampari",
            "Ana Tinga",
            "Bankan Tey",
            "Bondum Dom",
            "Donno So",
            "Mombo",
            "Nanga Dama",
            "Tebul Ure",
            "Tene Kan",
            "Tiranige Diga",
            "Tomo Kan",
            "Toro So",
            "Toro Tegu",
            "Yanda",
        },
    },
    "Dusun": {
        "add_lang": {"Central", "Sugut", "Tambunan", "Tempasuk"},
    },
    "Dutch": {
        # Berbice Creole Dutch, Skepi Creole Dutch
        "indent": lambda lang: lang.endswith(" Dutch") and not lang.endswith(" Creole Dutch"),
        "add_lang": {"Jersey", "Middle", "Old"},
        "unindent": {"Berbice Creole Dutch", "Skepi Creole Dutch"},
    },
    "East Cree": {
        "indent": lambda lang: False,
        "unindent": {"Northern East Cree", "Southern East Cree"},
    },
    "Ede": {
        "indent": lambda lang: lang.endswith("Ede Nago") or lang.startswith("Ede ") or lang in {"Ifè"},
    },
    "Efate": {
        "add_lang": {"North", "South"},
    },
    "Egyptian": {
        "indent": lambda lang: lang.endswith(" Egyptian") or lang in {"Demotic"},
        "rename": {
            "(Akhmimic)": "Akhmimic Coptic",
            "Demotic": "Demotic Egyptian",
        },
        "unindent": {
            "Akhmimic",
            "Akhmimic Coptic",
            "Bohairic",
            "Coptic",
            "Fayyumic",
            "Lycopolitan",
            "Old Coptic",
            "Oxyrhynchite",
            "Sahidic",
        },
    },
    "Enets": {
        "add_lang": {"Forest", "Tundra"},
    },
    "English": {
        "indent": lambda lang: False,
        "unindent": {"Middle English", "Old English"},
    },
    "Fali": {
        # Baissa Fali is unrelated
        "indent": {"North Fali", "South Fali"},
        "add_lang": {"North", "South"},
    },
    # Fars: Northwestern Fars is spurious per Glottolog; Southwestern Fars is a collection of disparate dialects.
    "French": {
        # Karipúna Creole French, Réunion Creole French, San Miguel Creole French, formerly Louisiana Creole French
        # (now just Louisiana Creole)
        "indent": lambda lang: lang.endswith(" French") and not lang.endswith(" Creole French"),
        "add_lang": {"Canadian", "Middle", "Old"},
        "rename": {
            "Canada": "Canadian French",
            "Modern": "French",
        },
        "unindent": {"French", "Louisiana Creole", "Louisiana Creole French"},
    },
    "Frisian": {
        "add_lang": {"North", "Old", "Saterland", "West"},
        "rename": {
            "Öömrang": "Amrum",
            "Fering": "Föhr",
            "Fering-Öömrang": "Föhr-Amrum",
            "Helgoland": "Heligoland",
            "Söl'ring": "Sylt",
            "Hallig": "Halligen",
        },
        "recognize": {
            "Amrum",
            "Föhr",
            "Föhr-Amrum",
            "Halligen",
            "Heligoland",
            "Mooring",
            "Sylt",
            "Karrharde",
            "Wiedingharde",
            "Bökingharde",
            "Goesharde",
        },
        "unindent": {"Bokmål", "Nynorsk"},
    },
    "Fula": {
        "rename": {
            "Roman": "Latin",
            "Pular": "Pulaar",
        },
        "recognize": {"Adlam"},
    },
    "Gagauz": {
        "rename": {
            "Roman": "Latin",
        },
    },
    "Garasia": {
        # FIXME: Bhili is needed to complete the clade but it appears only the following two go by "Garasia".
        "add_lang": {"Adiwasi", "Rajput"},
    },
    # Gbaya: Northwest Gbaya, Gbaya-Bozoum and Gbaya-Bossongoa are in the Western Gbaya family with two others;
    #        Southwest Gbaya is in the Southern Gbaya family with two others;
    #        Gbaya-Mbodomo is in the Eastern Gbaya family with six others.
    "Gbe": {
        "add_lang": {
            "Ci",
            "Defi",
            "Maxi",
            "Waci",
            "Weme",
            # under the Phla-Pherá subfamily
            "Eastern Xwla",
            "Gbesi",
            "Kotafon",
            "Saxwe",
            "Tofin",
            "Western Xwla",
            "Xwela",
        },
    },
    "Gelao": {
        "indent": lambda lang: lang.endswith(" Gelao") or lang in {"Qau", "A'ou", "Mulao"},
        "add_lang": {"Green", "Red", "White"},
    },
    "Georgian": {
        "add_lang": {"Old"},
    },
    "German": {
        "indent": lambda lang: (
            lang.endswith(" German")
            and not lang.endswith("Low German")
            and lang
            not in {
                "Colonia Tovar German",
                "Pennsylvania German",
                "Volga German",
                "Zipser German",
            }
            or lang in {"East Franconian", "Rhine Franconian", "Central Franconian", "Bavarian", "Kölsch", "Swabian"}
            # Not Gottscheerisch (descended from Bavarian, spoken in Slovenia and with a Slovenian-based orthography);
            # not Vilamovian (descended from East Central German, spoken in the Silesian Voivodeship of Poland and with a
            #   Polish-based orthography);
            # not Luxembourgish (spoken in Luxembourg)
            # not Yiddish (spoken in Israel and the United States)
            # not Cimbrian (spoken in Trentino and Veneto, Italy)
            # not Hutterisch (spoken in Canada and the United States)
            # not Hunsrik (spoken in Brazil, Argentina, Paraguay)
            # not Mòcheno (spoken in Trentino, Italy)
            # not Yenish (German mixed with Romani and Yiddish)
            # not Sathmar Swabian (spoken in Romania)
            # not Transylvanian Saxon (spoken in Romania)
            # not Colonia Tovar German? (spoken in Venezuela)
            # not Pennsylvania German? (spoken in the United States)
            # not Volga German? (spoken in Russia and Kazakhstan)
            # not Zipser German? (spoken in Slovakia and Romania)
            # yes Walser German? (not a language at Wiktionary but a dialect of Alemannic German)
        ),
        "add_lang": {"Alemannic", "Colonia Tovar", "East Central", "Middle High", "Old High", "Pennsylvania"},
        "rename": {
            "Alemannic": "Alemannic German",
            "Alsace": "Alsatian Alemannic German",
            "Alsatian <small>(Low Alemannic German)</small>": "Alsatian Alemannic German",
            "Alsatian": "Alsatian Alemannic German",
            "Ancient": "Old High German",
            "Bavaria": "Bavarian",
            "Modern German": "German",
            "Silesian": "Silesian East Central German",
            "Silesian German": "Silesian East Central German",
        },
        "unindent": {
            "Luxembourgish",
            "German",
            "Plautdietsch",
            "Colonia Tovar German",
            "Pennsylvania German",
            "Volga German",
            "Zipser German",
            "Low German",
            "German Low German",
            "Northern Kurdish",
            "Cimbrian",
            "Gottscheerish",
            "Hunsrik",
            "Mòcheno",
            "Sathmar Swabian",
        },
    },
    "Ghale": {
        "add_lang": {"Kutang", "Northern", "Southern"},
    },
    "Giziga": {
        "add_lang": {"North", "South"},
    },
    "Grebo": {
        "add_lang": {"Barclayville", "Central", "Gboloo", "Northern", "Southern"},
    },
    "Greek": {
        "indent": lambda lang: lang.endswith(" Greek")
        or lang in {"Kaliarda", "Katharevousa", "Yevanic", "Tsakonian", "Opuntian Locrian", "Ozolian Locrian"},
        "add_lang": {
            "Aeolic",
            "Ancient",
            "Arcadian",
            "Arcadocypriot",
            "Attic",
            "Boeotian",
            "Byzantine",
            "Cappadocian",
            "Classical",
            "Cretan",
            "Cypriot",
            "Doric",
            "Epic",
            "Hellenistic",
            "Ionic",
            "Italiot",
            "Koine",
            "Laconian",
            "Medieval",
            "Mycenaean",
            "Pamphylian",
            "Pontic",
            "Thessalian",
        },
        "rename": {
            "Mycenean Greek": "Mycenaean Greek",
            "Mycenean": "Mycenaean Greek",
            "Griko": "Italiot Greek",
            "Modern": "Greek",
            "Modern Greek": "Greek",
        },
        "unindent": {"Greek"},
    },
    "Guarani": {
        "add_lang": {"Classical", "Eastern Bolivian", "Mbya", "Paraguayan", "Western Bolivian"},
    },
    "Gujarati": {
        "add_lang": {"Middle", "Old"},
    },
    # Gula: Bon Gula and Zan Gula form a clade with Kulaal and maybe Fania, but Gula iself and Tar Gula are unrelated.
    "Gurung": {
        "add_lang": {"Eastern", "Western"},
    },
    "Gutnish": {
        "add_lang": {"Old"},
    },
    "Haida": {
        "add_lang": {"Northern", "Southern"},
    },
    "Hebrew": {
        "add_lang": {"Biblical", "Samaritan"},
        "rename": {
            "Ancient": "Biblical Hebrew",
            "Ancient Hebrew": "Biblical Hebrew",
            "Modern": "Hebrew",
            "Modern Hebrew": "Hebrew",
        },
        "unindent": {"Hebrew"},
    },
    "Hindi": {
        # Fiji Hindi is not Hindi but comes from Eastern Indo-Aryan languages
        "indent": lambda lang: lang.endswith(" Hindi") and lang not in {"Andaman Creole Hindi", "Fiji Hindi"},
        "add_lang": {"Old"},
        "unindent": {"Andaman Creole Hindi", "Fiji Hindi", "Urdu"},
    },
    "Hindko": {
        "add_lang": {"Northern", "Southern"},
    },
    "Hindustani": {
        "indent": lambda lang: False,
        "unindent": {"Hindi", "Urdu"},
    },
    "Hmong": {
        # We include the various Bunu languages as well as Ná-Meo, Pa-Hng and She as being Hmong languages but they are not
        # included in ISO 639-3's hmn Hmong macrolanguage and don't end or start in Hmong, Mong or Miao, so I'm excluding
        # them. ISO 639-3 excludes hmf (Hmong Don), hmv (Hmong Dô) from the China/Laos hmn macro language mostly I think
        # because they're spoken in Vietnam and influenced by Vietnamese and French, but I am including them. The following
        # languages are included (the Bunu languages go under Bunu):
        # cqd – Chuanqiandian Cluster Miao (cover term for Hmong in China)
        # hea – Northern Qiandong Miao
        # hma – Southern Mashan Hmong
        # hmc – Central Huishui Hmong
        # hmd – A-Hmao [Wiktionary]; Large Flowery Miao [Wikipedia]
        # hme – Eastern Huishui Hmong
        # hmf – Hmong Don (Vietnam)
        # hmg – Southwestern Guiyang Hmong
        # hmh – Southwestern Huishui Hmong
        # hmi – Northern Huishui Hmong
        # hmj – Ge
        # hml – Luopohe Hmong
        # hmm – Central Mashan Hmong
        # hmp – Northern Mashan Hmong
        # hmq – Eastern Qiandong Miao
        # hms – Southern Qiandong Miao
        # hmv – Hmong Dô (Vietnam)
        # hmw – Western Mashan Hmong
        # hmy – Southern Guiyang Hmong
        # hmz – Hmong Shua (Sinicized Miao)
        # hnj – Green Hmong [Wiktionary]; Mong Njua/Mong Leng (China, Laos), Blue/Green Hmong (United States) [Wikipedia]
        # hrm – Horned Miao [Wiktionary]; A-Hmo, Horned Miao (China) [Wikipedia]
        # huj – Northern Guiyang Hmong
        # mmr – Western Xiangxi Miao
        # muq – Eastern Xiangxi Miao
        # mww – White Hmong [Wiktionary]; Hmong Daw (China, Laos), White Hmong (United States) [Wikipedia]
        # sfm – Small Flowery Miao
        # Cao Miao is Kam-Sui, not Hmong at all
        "indent": lambda lang: lang.endswith(" Hmong")
        or lang.endswith(" Miao")
        and lang not in {"Cao Miao"}
        or lang.startswith("Hmong ")
        or lang in {"Ge", "A-Hmao"},
        "add_lang": {"Green", "White"},
    },
    "Huitoto": {
        "add_lang": {"Minica", "Murui", "Nüpode"},
    },
    "Hungarian": {
        "add_lang": {"Old"},
        "rename": {
            "Roman": "Latin",
        },
        "unindent": {"Hungarian"},
    },
    "Ifugao": {
        "add_lang": {"Amganad", "Batad", "Mayoyao", "Tuwali"},
    },
    "Ilocano": {
        "rename": {
            "Roman": "Latin",
        },
        "recognize": {"Baybayin"},
    },
    "Indonesian": {
        # Peranakan Indonesian is a creole
        "indent": lambda lang: lang.endswith(" Indonesian") and lang not in {"Peranakan Indonesian"},
        "rename": indonesian_malay_rename_map,
        "unindent": indonesian_malay_unindent | {"Peranakan Indonesian"},
    },
    "Inuktitut": {
        "add_lang": {"Eastern Canadian"},
        "rename": {
            "Roman": "Latin",
            "Nunatsiavummiut": "Inuttitut",
            "Inuttut": "Inuttitut",
            "Syllabics": "Canadian syllabics",
        },
        "unindent": {"Inuinnaqtun", "Inuvialuktun"},
    },
    "Irish": {
        # what about Classical Gaelic?
        "add_lang": {"Middle", "Old", "Primitive"},
        "rename": {"Modern Irish": "Irish"},
        "unindent": {"Irish", "Central Kurdish"},
    },
    "Itneg": {
        "add_lang": {"Banao", "Binongan", "Inlaod", "Maeng", "Masadiit", "Moyadan"},
    },
    "Japanese": {
        "add_lang": {"Old"},
    },
    "Javanese": {
        "add_lang": {"Caribbean", "New Caledonian", "Old"},
        "rename": indonesian_malay_rename_map,
        "recognize": lambda lang: lang in {"Kaili", "Krama", "Ngoko", "Carakan"},
        "unindent": indonesian_malay_unindent,
    },
    "Jino": {
        "add_lang": {"Buyuan", "Youle"},
    },
    "Kadazan": {
        "add_lang": {"Coastal", "Klias River", "Labuk-Kinabatangan"},
    },
    "Kaili": {
        "add_lang": {"Da'a", "Ledo", "Unde"},
    },
    "Kalagan": {
        # plain Kalagan is also a language
        "add_lang": {"Kagan", "Tagakaulu"},
    },
    "Kalapuya": {
        "add_lang": {"Northern", "Southern"},
    },
    "Kalinga": {
        "add_lang": {"Butbut", "Limos", "Lubuagan", "Mabaka Valley", "Madukayang", "Southern", "Tanudan"},
    },
    "Kallahan": {
        # Tinoc is deprecated (merged into kak) and should be removed
        "add_lang": {"Kayapa", "Keley-I", "Tinoc"},
    },
    "Kam": {
        "add_lang": {"Northern", "Southern"},
    },
    "Kannada": {
        "add_lang": {"Middle", "Old"},
    },
    "Karaboro": {  # Karaboro clade under Senufo under Atlantic-Congo
        "add_lang": {"Eastern", "Western"},
    },
    "Karelian": {
        "rename": {
            "Karelian Proper": "Karelian",
            "Livvi-Karelian": "Livvi",
        },
        "unindent": {"Karelian", "Livvi"},
        "recognize": {"Tver Karelian"},
    },
    "Karen": {
        "add_lang": {
            "Brek",
            "Bwe",
            "Geba",
            "Geko",
            "Lahta",
            "Manumanaw",
            "Pa'o",
            "Paku",
            "S'gaw",
            "Yinbaw",
            "Yintale",
            "Zayein",
        },
    },
    "Katu": {
        "add_lang": {"Eastern", "Western"},
    },
    "Kayah": {
        "add_lang": {"Eastern", "Western"},
    },
    "Kayan": {
        # the 6 below + Kayan Mahakam + Bahau
        "indent": lambda lang: lang.endswith(" Bayan") or lang.startswith("Bayan ") or lang in {"Bahau"},
        "add_lang": {"Baram", "Busang", "Kayan River", "Mendalam", "Rejang", "Wahau"},
    },
    # Ke: Hunjara-Kaina Ke and Marti Ke are not at all related.
    "Keres": {
        "add_lang": {"Eastern", "Western"},
    },
    "Kham": {
        "add_lang": {"Eastern Parbate", "Gamale", "Sheshi", "Western Parbate"},
    },
    "Khanty": {
        "add_lang": {"Eastern", "Northern", "Southern"},
    },
    "Khmer": {
        "add_lang": {"Middle", "Northern", "Old"},
        "unindent": {"Central Kurdish", "Northern Kurdish"},
    },
    # Kinnauri: Harijan Kinnauri is Indo-Aryan; Bhoti Kinnauri descends from Old Tibetan; Chitkuli Kinnauri and plain
    #           Kinnauri are Kinnauric languages under West Himalayish under Sino-Tibetan.
    "Kissi": {  # Kissi clade under Mel under Atlantic-Congo
        "add_lang": {"Northern", "Southern"},
    },
    "Kiwai": {
        "add_lang": {"Northeast", "Southern"},
    },
    "Koiari": {
        "add_lang": {"Grass", "Mountain"},
    },
    "Koli": {
        "add_lang": {"Kachi", "Parkari", "Wadiyara"},
    },
    "Komi": {
        "indent": lambda lang: lang.startswith("Komi-") or lang.endswith(" Komi"),
        "add_lang": {"Old"},
    },
    "Konjo": {
        # Not the Konjo Bantu language
        "indent": {"Coastal", "Highland"},
        "add_lang": {"Coastal", "Highland"},
    },
    "Koraga": {
        "add_lang": {"Korra", "Mudu"},
    },
    "Korean": {
        "add_lang": {"Early Modern", "Middle", "Old"},
        "unindent": {"Jeju", "Bokmål", "Northern Kurdish"},
    },
    "Kpelle": {
        # FIXME: Forms a clade with Kono (Guinea) (knu)
        "add_lang": {"Guinea", "Liberia"},
    },
    "Krahn": {
        "add_lang": {"Eastern", "Western"},
    },
    "Krumen": {
        "add_lang": {"Plapo", "Pye", "Tepo"},
    },
    "Kulango": {
        "add_lang": {"Bondoukou", "Bouna"},
    },
    "Kurdish": {
        "indent": lambda lang: lang.endswith(" Kurdish") or lang in {"Laki", "Sorani", "Kurmanji"},
        "add_lang": {"Central", "Northern", "Southern"},
        "rename": {
            "Cnetral Kurdish": "Central Kurdish",
            "Laki Kurdish": "Laki",
            "Sorani": "Central Kurdish",
            "Kurmanji": "Northern Kurdish",
            "Norther Kurdish": "Northern Kurdish",
            "Northern": "Northern Kurdish",
        },
        "unindent": {"Gurani", "Zazaki"},
    },
    # Kurumba: varieties scattered among several families; no clades
    "Kyrgyz": {
        "unindent": {"Sorani"},
        "recognize": {"Arabic", "Cyrillic"},
    },
    "Ladino": {
        "rename": {
            "Hebew": "Hebrew",
            "Hebrew alphabet": "Hebrew",
            "Hebrew script": "Hebrew",
            "Latin alphabet": "Latin",
            "Roman": "Latin",
        },
    },
    "Lalo": {
        "indent": lambda lang: lang.endswith(" Lalo") or lang.endswith(" Lalu"),
        # Eastern Lalu, Western Lalu, Dongshanba Lalo, Xishanba Lalo
    },
    "Latin": {
        "add_lang": {"Classical", "Medieval"},
        "rename": {
            "Modern": "Contemporary Latin",
            "[[Medieval Latin]]": "Medieval Latin",
            "[[Vulgar Latin]]": "Vulgar Latin",
        },
    },
    "Lawa": {
        "add_lang": {"Eastern", "Western"},
    },
    "Lenape": {
        "indent": lambda lang: False,
        "unindent": {"Munsee", "Unami"},
    },
    "Lenca": {
        "add_lang": {"Honduran", "Salvadoran"},
    },
    "Leonese": {
        "add_lang": {"Old"},
    },
    "Limba": {
        "add_lang": {"East", "West-Central"},
    },
    "Lithuanian": {
        "add_lang": {"Old"},
        "recognize": {"Aukštaitian", "Samogitian"},
    },
    "Lobu": {
        # FIXME: These seem to be only part of the Paitanic languages clade (Austronesian).
        "add_lang": {"Lanas", "Tampias"},
    },
    "Lorung": {
        "add_lang": {"Northern", "Southern"},
    },
    "Low German": {
        "indent": lambda lang: lang.endswith(" Low German")
        and lang not in {"Plautdietsch"}
        or lang in {"Dutch Low Saxon"},
        "add_lang": {"East Frisian"},
        "rename": {
            "Dutch Low German": "Dutch Low Saxon",
            "East Frisian Low Saxon": "East Frisian Low German",
            "German Low Saxon": "German Low German",
            "Mennonite Low German": "Plautdietsch",
            "Mennonite Plautdietsch": "Plautdietsch",
            "Plauttdietsch": "Plautdietsch",
            "Plauttdietsch (Mennonite Low German)": "Plautdietsch",
        },
        "unindent": {"Plautdietsch", "Old Saxon"},
    },
    "Luri": {
        "add_lang": {"Northern", "Southern"},
    },
    "Magar": {
        "add_lang": {"Eastern", "Western"},
    },
    "Maidu": {
        # Nisenan is the fourth language forming the Maiduan languages.
        "indent": lambda lang: lang.endswith(" Maidu") or lang in {"Nisenan"},
        "add_lang": {"Northeast", "Northwest", "Valley"},
    },
    # Makian: East Makian and West Makian are unrelated
    "Malay": {
        "indent": lambda lang: lang.endswith(" Malay") and lang not in malay_creole_mixed,
        "add_lang": {
            "Ambonese",
            "Baba",
            "Bacanese",
            "Banda",
            "Berau",
            "Brunei",
            "Bukit",
            "Central",
            "Jambi",
            "Kedah",
            "Larantuka",
            "Negeri Sembilan",
            "Old",
            "Pattani",
            "Sarawak",
            "Terengganu",
        },
        "rename": indonesian_malay_rename_map,
        "unindent": indonesian_malay_unindent | malay_creole_mixed,
    },
    "Mambila": {
        "add_lang": {"Cameroon", "Nigeria"},
    },
    "Mandingo": {
        # Eastern/Western/Kita Maninkakan; Konyaka/Sankaran/Forest Maninka; Mandinka, Mandingo (FIXME: should be a family)
        "indent": lambda lang: lang.endswith(" Maninka") or lang.endswith(" Maninkakan") or lang in {"Mandinka"},
        "unindent": {"Mandingo"},
    },
    "Mandobo": {
        "add_lang": {"Lower", "Upper"},
    },
    "Maninkakan": {
        "add_lang": {"Eastern", "Western"},
    },
    "Manipuri": {
        "add_lang": {"Bishnupriya", "Old"},
    },
    "Manobo": {
        "add_lang": {
            "Agusan",
            "Ata",
            "Cinamiguin",
            "Cotabato",
            "Dibabawon",
            "Ilianen",
            "Matigsalug",
            "Obo",
            "Rajah Kabunsuwan",
            "Sarangani",
            "Western Bukidnon",
        },
    },
    "Mansi": {
        "add_lang": {"Central", "Eastern", "Western", "Northern", "Southern"},
    },
    "Marathi": {
        "add_lang": {"Old"},
    },
    "Mari": {
        "indent": lambda lang: lang.endswith(" Mari") and lang not in {"Austronesian Mari", "Sepik Mari"},
        "add_lang": {"Eastern", "Western"},
        "unindent": {"Austronesian Mari", "Sepik Mari"},
    },
    "Maria": {  # Dravidian
        "add_lang": {"Dandami", "Hill"},
    },
    "Marquesan": {
        "add_lang": {"North", "South"},
    },
    "Masela": {
        "add_lang": {"Central", "East", "West"},
    },
    # Maya: Yucatec Maya and Mopan Maya happen to have Maya in their names but the other 30 don't.
    "Mazahua": {
        "add_lang": {"Central", "Michoacán"},
    },
    "Mazatec": {
        "add_lang": {
            "Chiquihuitlán",
            "Huautla",
            "Ixcatlán",
            "Jalapa de Díaz",
            "Mazatlán",
            "Puebla",
            "San Jerónimo Tecóatl",
        },
    },
    "Median": {
        "add_lang": {"Middle", "Old"},
    },
    "Melanau": {
        "add_lang": {"Central", "Daro-Matu", "Sibu"},
    },
    "Meohang": {
        "add_lang": {"Eastern", "Western"},
    },
    "Me'phaa": {
        "add_lang": {"Acatepec", "Azoyú", "Tlacoapa"},
    },
    "Miwok": {
        "add_lang": {"Bay", "Central Sierra", "Coast", "Lake", "Northern Sierra", "Plains", "Southern Sierra"},
    },
    "Mixe": {
        "add_lang": {
            "Coatlán",
            "Isthmus",
            "Juquila",
            "Mazatlán",
            "North Central",
            "Quetzaltepec",
            "Tlahuitoltepec",
            "Totontepec",
        },
    },
    "Mixtec": {
        "add_lang": {
            "Alacatlatzala",
            "Alcozauca",
            "Amoltepec",
            "Apasco-Apoala",
            "Atatláhuca",
            "Ayutla",
            "Cacaloxtepec",
            "Chayuco",
            "Chazumba",
            "Chigmecatitlán",
            "Coatzospan",
            "Cuyamecalco",
            "Diuxi-Tilantongo",
            "Huitepec",
            "Itundujia",
            "Ixtayutla",
            "Jamiltepec",
            "Juxtlahuaca",
            "Magdalena Peñasco",
            "Metlatónoc",
            "Mitlatongo",
            "Mixtepec",
            "Northern Tlaxiaco",
            "Northwest Oaxaca",
            "Ocotepec",
            "Peñoles",
            "Pinotepa Nacional",
            "San Juan Colorado",
            "San Juan Teita",
            "San Miguel el Grande",
            "San Miguel Piedras",
            "Santa Lucía Monteverde",
            "Santa María Zacatepec",
            "Silacayoapan",
            "Sindihui",
            "Sinicahua",
            "Southeastern Nochixtlán",
            "Southern Puebla",
            "Southwestern Tlaxiaco",
            "Soyaltepec",
            "Tacahua",
            "Tamazola",
            "Teposcolula",
            "Tezoatlán",
            "Tidaá",
            "Tijaltepec",
            "Tlazoyaltepec",
            "Tututepec",
            "Western Juxtlahuaca",
            "Yoloxochitl",
            "Yosondúa",
            "Yucuañe",
            "Yutanduchi",
        },
        "rename": {
            "San Miguel El Grande": "San Miguel el Grande Mixtec",
        },
    },
    "Mnong": {
        # Needs Kraol to form a clade
        "add_lang": {"Central", "Eastern", "Southern"},
    },
    "Mon": {
        "indent": lambda lang: lang.endswith(" Mon")
        and lang
        not in {
            "Biao Mon",
            "Yangum Mon",
        },  # Biao Mon is in the Mien family; Yangum Mon is in the Torricelli family in New Guinea
        "add_lang": {"Middle", "Old", "Thai"},
        "unindent": {"Biao Mon", "Yangum Mon"},
    },
    # Mongol: Middle Mongol and Khamnigan Mongol do not form a clade
    "Mongolian": {
        # not Middle Mongol
        "rename": {
            "Roman": "Latin",
            "Cyrilic": "Cyrillic",
            "Classic": "Classical Mongolian",
            "Classical": "Classical Mongolian",
            "Khamingan Mongolian": "Khamnigan Mongol",
            "Mongolian": "Mongolian script",
        },
        "unindent": {"Khamnigan Mongol"},
    },
    # Monpa: Kalaktang Monpa, Tawang Monpa; not closely related, many other languages needed to form a clade
    "Muji": {
        # forms a clade with Bokha and Phuma
        "add_lang": {"Northern", "Qila", "Southern"},
    },
    "Muria": {
        "add_lang": {"Eastern", "Far Western", "Western"},
    },
    "Murut": {
        "add_lang": {"Keningau", "Selungai", "Sembakang", "Serudung", "Tagal", "Timugon"},
    },
    "Muyu": {
        # appear to form a clade with Yongkom
        "add_lang": {"North", "South"},
    },
    "Naga": {
        "add_lang": {
            # FIXME: WARNING: Naga languages come from several different families under Sino-Tibetan:
            "Chothe",
            "Kharam",
            "Moyon",  # Kuki-Chin:
            "Chokri",
            "Khezha",
            "Mao",
            "Northern Rengma",
            "Pochuri",
            "Poumei",
            "Southern Rengma",  # Angami-Pochuri:
            "Khiamniungan",
            "Konyak",
            "Leinong",
            "Makyan",  # Konyak-Chang
            "Kyan-Karyaw",
            "Lao",
            "Tutsa",  # Tangsa-Nocte
            "Khoibu",
            "Maring",  # Maringic
            "Tangkhul",  # Tangkhulic
            "Inpui",
            "Liangmai",
            "Maram",
            "Mzieme",
            "Puimei",
            "Rongmei",
            "Thangal",
            "Zeme",  # Zeme
        },
    },
    "Nahuatl": {
        "add_lang": {
            "Central",
            "Central Huasteca",
            "Central Puebla",
            "Classical",
            "Coatepec",
            "Cosoleacaque",
            "Eastern Durango",
            "Eastern Huasteca",
            "Guerrero",
            "Highland Puebla",
            "Huaxcaleca",  # "Isthmus",
            "Mecayapan",
            "Michoacán",
            "Morelos",
            "Northern Oaxaca",
            "Northern Puebla",
            "Ometepec",
            "Orizaba",
            "Pajapan",
            "Santa María La Alta",
            "Sierrra Negra",
            "Southeastern Puebla",
            "Tabasco",
            "Temascaltepec",
            "Tetelcingo",
            "Tlamacazapa",
            "Western Durango",
            "Western Huasteca",
            "Zacatlán-Ahuacatlán-Tepetzintla",
        },
        "rename": {
            "Northern Peubla": "Northern Puebla Nahuatl",
        },
    },
    "Ndebele": {
        "add_lang": {"Northern", "Southern"},
    },
    "Nenets": {
        "add_lang": {"Forest", "Tundra"},
    },
    "Newar": {
        "add_lang": {"Classical", "Middle"},
        "rename": {
            "Middle Newari": "Middle Newar",
            "Classical Newari": "Classical Newar",
        },
    },
    "Ngbandi": {
        "add_lang": {"Northern", "Southern"},
    },
    "Nicobarese": {
        # Only forms a clade with Chaura and Teressa
        "add_lang": {"Car", "Central", "Southern"},
    },
    "Nisu": {
        # FIXME: Southwestern Nisu appears spurious.
        "add_lang": {"Eastern", "Northern", "Southern", "Southwestern"},
    },
    "Norwegian": {
        "indent": lambda lang: lang.startswith("Norwegian ")
        or lang.endswith(" Norwegian")
        and lang
        not in {
            # Traveller Norwegian is a mixed language
            "Traveller Norwegian"
        }
        or lang in {"Bokmål", "Bokmal", "Nynorsk"},
        "add_lang": {"Middle"},
        "rename": {
            "Norwegian Bokmål": "Bokmål",
            "Norwegian (Bokmål)": "Bokmål",
            "Norwegian (bokmål)": "Bokmål",
            "Norwegian Bokmal": "Bokmål",
            "Bokmal": "Bokmål",
            "bokmål": "Bokmål",
            "Norwegian Nynorsk": "Nynorsk",
            "Norwegian (Nynorsk)": "Nynorsk",
            "Norwegian (nynorsk)": "Nynorsk",
            "Nynorak": "Nynorsk",
            "Nynorsh": "Nynorsk",
            "nymorsk": "Nynorsk",
            "nynorsk": "Nynorsk",
            "Nynorskl": "Nynorsk",
            "Nynosk": "Nynorsk",
            "Nynrosk": "Nynorsk",
        },
        "unindent": {"Norwegian", "Traveller Norwegian", "Old French", "Old Norse", "Portuguese", "Russian", "Spanish"},
    },
    "Nuaulu": {
        "add_lang": {"North", "South"},
    },
    "Nuni": {
        "add_lang": {"Northern", "Southern"},
    },
    "Occitan": {
        "add_lang": {"Old"},
    },
    "Odia": {
        "add_lang": {"Adivasi", "Middle", "Old"},
    },
    "Ohlone": {
        "add_lang": {"Northern", "Southern"},
    },
    "Ojibwa": {
        "add_lang": {"Central", "Eastern", "Northwestern", "Severn", "Western"},
    },
    "Ojibwe": {
        "rename": {
            "Canadian Syllabics": "Canadian syllabics",
            "Roman": "Latin",
        },
    },
    "Old Church Slavonic": {
        "indent": {"Church Slavonic"},
        "rename": {
            "Cytillic": "Cyrillic",
            "Roman": "Latin",
        },
        "recognize": {"Glagolitic"},
    },
    "Old English": {
        "rename": {
            "Latin": "Old English",
            "Roman": "Old English",
        },
        "unindent": {"Old English", "Middle English"},
        "recognize": {"Runic"},
    },
    "One": {
        "add_lang": {"Inebu", "Kabore", "Kwamtim", "Molmo", "Northern", "Southern"},
    },
    "Ossetian": {
        "add_lang": {"Digor", "Iron"},
        "rename": {
            "Digorian": "Digor Issetian",
            "Ironian": "Iron Issetian",
            "{{qualifier|Digor}}": "Digor Issetian",
            "{{qualifier|Iron}}": "Iron Issetian",
        },
    },
    "Otomi": {
        "add_lang": {
            "Eastern Highland",
            "Estado de México",
            "Ixtenco",
            "Mezquital",
            "Querétaro",
            "Temoaya",
            "Tenango",
            "Texcatepec",
            "Tilapa",
        },
    },
    # Pahari: Kullu Pahari, Mahasu Pahari; form a clade with Harijan Kinnauri, Hinduri and Sirmauri
    "Paharia": {  # Dravidian
        # Mal Paharia is an Indo-Aryan language heavily influenced by the Dravidian Paharia (aka Malto) languages
        "indent": lambda lang: lang.endswith(" Paharia") and lang not in {"Mal Paharia"},
        "add_lang": {"Kumarbhag", "Sawriya"},
    },
    "Palaung": {
        "add_lang": {"Ruching", "Rumai", "Shwe"},
    },
    "Palawano": {
        "add_lang": {"Brooke's Point", "Central", "Southwest"},
    },
    "Pame": {
        "add_lang": {"Central", "Northern", "Southern"},
    },
    "Paraguayan Guarani": {
        "indent": lambda lang: False,
        "rename": {
            "Mbyá": "Mbya Guarani",
        },
        "unindent": {"Mbya Guarani", "Tapieté"},
    },
    "Pashayi": {
        "add_lang": {"Northeast", "Northwest", "Southeast", "Southwest"},
    },
    "Penan": {
        "add_lang": {"Eastern", "Western"},
    },
    "Persian": {
        "indent": lambda lang: lang.endswith(" Persian") or lang in {"Dari", "Hazaragi"},
        "add_lang": {"Classical", "Iranian", "Middle", "Old"},
        "rename": {
            "Dari Persian": "Dari",
            "Iranian Pesian": "Iranian Persian",
        },
        "unindent": {"Tajik"},
    },
    "Phowa": {
        "add_lang": {"Ani", "Hlepho", "Labo"},
    },
    # Picene: North Picene and South Picene are not closely related, if at all, and the former may be a hoax.
    "Polish": {
        "add_lang": {"Old", "Middle"},
    },
    "Pomo": {
        "indent": lambda lang: lang.endswith(" Pomo") or lang in {"Kashaya"},
        "add_lang": {"Central", "Eastern", "Northeastern", "Northern", "Southeastern", "Southern"},
    },
    "Popoloca": {
        "add_lang": {
            "Coyotepec",
            "Mezontla",
            "San Felipe Otlaltepec",
            "San Juan Atzingo",
            "San Luís Temalacayuca",
            "San Marcos Tlalcoyalco",
            "Santa Inés Ahuatempan",
        },
        "unindent": {
            "Highland Popoluca",
            "Amecameca Central Nahuatl",
            "Bokmål",
            "Mandarin",
            "Norwegian Bokmål",
            "Swedish",
        },
    },
    "Popoluca": {
        "add_lang": {"Highland", "Oluta", "Sayula", "Texistepec"},
    },
    "Portuguese": {
        # FIXME: Make sure entries in this section are kosher
        "indent": lambda lang: lang.endswith(" Portuguese")
        and lang not in {"Old Portuguese", "Old Galician Portuguese"},
        "add_lang": {"Brazilian", "European"},
        "rename": {
            "Brazil": "Brazilian Portuguese",
            "European": "European Portuguese",
            "Portugal": "European Portuguese",
            "Iberian": "European Portuguese",
            "{{qualifier|Brazil}}": "Brazilian Portuguese",
            "{{qualifier|Portugal}}": "European Portuguese",
        },
        "unindent": {"Old Galician-Portuguese", "Old Galician Portuguese", "Old Portuguese"},
    },
    "Prakrit": {
        "add_lang": {"Ashokan", "Kamarupi", "Niya"},
        "rename": {
            "Maharashtri Prakrit": "Maharastri Prakrit",
        },
    },
    "Pumi": {
        "add_lang": {"Northern", "Southern"},
    },
    "Punjabi": {
        # FIXME: Make sure it's OK to move "Foo Punjabi" under "Punjabi"; only 3/382 occurrences of Western Panjabi indented
        "indent": lambda lang: lang.endswith(" Punjabi") or lang.endswith(" Panjabi"),
        "add_lang": {"Eastern", "Old", "Western"},
        "rename": {
            "Eastern Panjabi": "Eastern Punjabi",
            "Western Panjabi": "Western Punjabi",
            "shahmukhi": "Shahmukhi",
            "Gurmikhi": "Gurmukhi",
        },
        "unindent": {"Kurmanji"},
    },
    "Pwo": {
        "add_lang": {"Eastern", "Northern", "Phrae", "Western"},
    },
    "Qiang": {
        "add_lang": {"Northern", "Southern"},
    },
    "Quechua": {
        "add_lang": {"Central", "Southern"},
    },
    "Roglai": {
        "add_lang": {"Cacgia", "Northern", "Southern"},
    },
    "Romani": {
        "add_lang": {"Balkan", "Baltic", "Carpathian", "Kalo Finnish", "Sinte", "Vlax", "Welsh"},
    },
    "Russian": {
        # exclude Taimyr Pidgin Russian
        "indent": lambda lang: lang.endswith(" Russsian") and not lang.endswith(" Pidgin Russian"),
        "rename": {
            "Cyrillic": "Russian",
            "Roman": "Latin",
        },
        "unindent": {"Russian", "Old East Slavic", "Northern Selkup", "Southern Selkup"},
    },
    # Salish: Only Montana Salish and Southern Puget Sound Salish, nowhere near each other and only two of many Salish
    # languages.
    "Sama": {
        # FIXME: Balangingi seems needed to fill out a clade with Central and Southern.
        "add_lang": {"Central", "Pangutaran", "Southern"},
    },
    "Samaritan": {
        "indent": lambda lang: False,
        "unindent": {"Samaritan Aramaic", "Samaritan Hebrew"},
    },
    "Sami": {
        "add_lang": {
            "Akkala",
            "Inari",
            "Kemi",
            "Kildin",
            "Lule",
            "Northern",
            "Pite",
            "Skolt",
            "Southern",
            "Ter",
            "Ume",
        },
        "rename": {
            "Kola": "Kildin Sami",
        },
        "unindent": {"Bokmål"},
    },
    "Samo": {
        # FIXME: Confusion with Samo language of New Guinea
        "add_lang": {"Matya", "Maya", "Southern"},
    },
    "Sardinian": {
        "indent": lambda lang: lang.endswith(" Sardinian") or lang in {"Campidanese", "Logudorese", "Nuorese"},
        "rename": {
            "Logudorese Sardinian": "Logudorese",
            "Campidanese Sardinian": "Campidanese",
            "Gallurese Sardinian": "Gallurese",
        },
        "recognize": {"Nuorese"},
        "unindent": {"Gallurese", "Sassarese"},
    },
    "Scots": {
        "add_lang": {"Middle"},
    },
    "Selkup": {
        "add_lang": {"Northern", "Southern"},
    },
    "Senni": {
        # may need other langs to form an Eastern Songhay clade
        "add_lang": {"Humburi", "Koyraboro"},
    },
    "Serbo-Croatian": {
        "rename": {
            "Cryllic": "Cyrillic",
            "Cyrilli": "Cyrillic",
            "Cyrilliс": "Cyrillic",  # with a Cyrillic с
            "Cyrillic script": "Cyrillic",
            "Cyrillic spelling": "Cyrillic",
            "Latin script": "Latin",
            "Latın": "Latin",
            "Roma": "Latin",
            "Roman": "Latin",
            "Roman script": "Latin",
            "Roman spelling": "Latin",
        },
        "recognize": {"Arebica"},
        "unindent": {"Lower Sorbian", "Upper Sorbian"},
    },
    "Slavey": {
        "add_lang": {"North", "South"},
    },
    "Slovak": {
        "add_lang": {"Old"},
    },
    "Sorbian": {
        "add_lang": {"Lower", "Upper"},
        "rename": {
            "High Sorbian": "Upper Sorbian",
            "Low Sorbian": "Lower Sorbian",
        },
    },
    "Sorsogon": {
        "add_lang": {"Masbate", "Waray"},
    },
    "Spanish": {
        "add_lang": {"Old"},
    },
    "Stieng": {
        "add_lang": {"Budeh", "Bulo"},
    },
    "Subanen": {
        # Central/Northern Subanen, Kolibugan/Western Subanon, Lapuyan/Eastern Subanun
        "indent": lambda lang: lang.endswith(" Subanen") or lang.endswith(" Subanon") or lang.endswith(" Subanun"),
        "add_lang": {"Central", "Northern"},
    },
    "Sundanese": {
        "add_lang": {"Old"},
        "rename": indonesian_malay_rename_map,
        "unindent": indonesian_malay_unindent,
    },
    "Swedish": {
        "add_lang": {"Old"},
    },
    "Tagalog": {
        "rename": {
            "Roman": "Latin",
        },
        "recognize": {"Baybayin"},
    },
    # Tagbanwa: Calamian Tagbanwa, Central Tagbanwa and Tagbanwa; don't form a clade
    "Tairora": {
        "add_lang": {"North", "South"},
    },
    "Tamang": {
        "add_lang": {"Eastern Gorkha", "Eastern", "Northwestern", "Southwestern", "Western"},
    },
    "Tamil": {
        "add_lang": {"Old"},
    },
    "Tanana": {  # Athabaskan
        "indent": lambda lang: False,
        "unindent": {"Lower Tanana", "Upper Tanana"},
    },
    # Tanna: North Tanna, Southwest Tanna; needs Kwamera, Lenakel and Whitesands to form a clade
    "Tarahumara": {
        "add_lang": {"Lowland", "Central", "Northern", "Southeastern", "Southwestern"},
    },
    "Tarangan": {
        "add_lang": {"East", "West"},
    },
    "Tatar": {
        "indent": lambda lang: False,
        "unindent": {"Crimean Tatar", "Siberian Tatar"},
        "rename": {
            "Roman": "Latin",
        },
        "recognize": {"Arabic", "Cyrillic", "Kryashen"},
    },
    "Tawbuid": {
        "add_lang": {"Eastern", "Western"},
    },
    # Teke: Ibali Teke, Central Teke, Teke-Fuumu, Teke-Kukuya, Teke-Laali, Teke-Tege, Teke-Tsaayi, Teke-Tyee
    # These are all in the Teke-Mbede languages but scattered throughout, with no clades formable without including
    # several other languages.
    "Telugu": {
        "add_lang": {"Old"},
    },
    "Tepehua": {
        "add_lang": {"Huehuetla", "Pisaflores", "Tlachichilco"},
    },
    "Tepehuan": {
        "add_lang": {"Northern", "Southeastern", "Southwestern"},
    },
    "Thai": {
        "add_lang": {"Northern", "Southern"},
        "unindent": {"Isan"},
    },
    "Tharu": {
        # Sonha, Buksa, Majhi and Musasa seem to be in the clade but are associated with other ethnic groups.
        "add_lang": {"Chitwania", "Dangaura", "Kathoriya", "Kochila", "Rana"},
    },
    "Tibetan": {
        "add_lang": {"Classical", "Old", "Amdo", "Khams"},
    },
    "Tidung": {
        "add_lang": {"Northern", "Southern"},
    },
    "Totonac": {
        "add_lang": {
            "Coyutla",
            "Filomena Mata-Coahuitlán",
            "Highland",
            "Misantla",
            "Papantla",
            "Upper Necaxa",
            "Western",
            "Xicotepec de Juárez",
        },
    },
    "Toussian": {
        # NOTE: Goes under Tusya in Wikipedia
        "add_lang": {"Northern", "Southern"},
    },
    "Triqui": {
        "add_lang": {"Chicahuaxtla", "Copala", "San Martín Itunyoso"},
    },
    "Tujia": {
        "add_lang": {"Northern", "Southern"},
    },
    "Tukang Besi": {
        "indent": lambda lang: lang.startswith("Tukang Besi "),
    },
    "Tunebo": {
        "add_lang": {"Angosturas", "Barro Negro", "Central", "Western"},
    },
    "Turkish": {
        "rename": {
            "Modern": "Turkish",
            "Modern Turkish": "Turkish",
            "Latin": "Turkish",
            "Arabic": "Ottoman Turkish",
            "Ottoman": "Ottoman Turkish",
        },
        "unindent": {"Turkish", "Old Turkic"},
    },
    "Turkmen": {
        "rename": {
            "Roman": "Latin",
        },
        "recognize": {"Cyrillic"},
    },
    "Tutchone": {
        "add_lang": {"Northern", "Southern"},
    },
    "Uyghur": {
        "indent": lambda lang: False,
        # Old Uyghur is NOT the ancestor of modern Uyghur
        "unindent": {"Old Uyghur"},
        "recognize": {"Arabic", "Cyrillic", "Latin"},
    },
    "Uzbek": {
        "rename": {
            "Roman": "Latin",
        },
        "recognize": {"Arabic", "Cyrillic"},
    },
    "Vietnamese": {
        "add_lang": {"Middle"},
    },
    "Watut": {
        "add_lang": {"Middle", "North", "South"},
    },
    "Wee": {
        "indent": {"Wè Western", "Wè Southern"},
    },
    "Welsh": {
        "add_lang": {"Middle", "Old"},
        "rename": {
            "North": "North Wales Welsh",
            "North Wales": "North Wales Welsh",
            "South": "South Wales Welsh",
            "South Wales": "South Wales Welsh",
        },
    },
    "Yali": {
        "add_lang": {"Angguruk", "Ninia", "Pass Valley"},
    },
    # Yau: Finisterre Yau and Torricelli Yau are unrelated.
    "Yokuts": {
        "indent": lambda lang: lang.endswith(" Yokuts") or lang in {"Gashowu", "Palewyami"},
        "add_lang": {
            "Buena Vista",
            "Delta",
            "Gashowu",
            "Kings River",
            "Northern Valley",
            "Palewyami",
            "Southern Valley",
            "Tule-Kaweah",
        },
    },
    # Yugur: Western Yugur is Turkic but East Yugur is Mongolic
    "Yukaghir": {
        "add_lang": {"Northern", "Southern"},
    },
    "Zapotec": {
        "indent": lambda lang: lang.endswith(" Zapotec") or lang in {"Central Mahuatlán Zapoteco"},
        "add_lang": {
            "Amatlán",
            "Ayoquesco",
            "Cajonos",
            "Isthmus",
            "Mitla",
            "Mixtepec",
            "Quioquitani-Quierí",
            "San Juan Guelavía",
            "San Pedro Quiatoni",
            "Santa María Quiegolani",
            "Southern Rincon",
            "Texmelucan",
            "Tilquiapan",
            "Tlacolulita",
            "Xanaguía",
            "Yalálag",
            "Yatee",
            "Yatzachi",
            "Zaniza",
            "Zoogocho",
            "Aloápam",
            "Asunción Mixtepec",
            "Central Mahuatlán",
            "Chichicapan",
            "Choapan",
            "Coatecas Altas",
            "Coatlán",
            "El Alto",
            "Elotepec",
            "Guevea de Humboldt",
            "Lachiguiri",
            "Lachixío",
            "Lapaguía-Guivini",
            "Loxicha",
            "Mazaltepec",
            "Ocotlán",
            "Ozolotepec",
            "Petapa",
            "Quiavicuzas",
            "Rincón",
            "San Agustín Mixtepec",
            "San Baltazar Loxicha",
            "San Pablo Güilá",
            "Santa Catarina Albarradas",
            "Santa Inés Yatzechi",
            "Santiago Xanica",
            "Santo Domingo Albarradas",
            "San Vicente Coatlán",
            "Sierra de Juárez",
            "Southeastern Ixtlán",
            "Tabaa",
            "Tejalapan",
            "Totomachapan",
            "Xadani",
            "Yareni",
            "Yautepec",
        },
        "rename": {
            "Central Mahuatlán Zapoteco": "Central Mahuatlán Zapotec",
        },
    },
    "Zoque": {
        "add_lang": {"Chimalapa", "Copainalá", "Francisco León", "Rayón", "Tabasco"},
    },
}

top_level_rename = {
    "Azeri": "Azerbaijani",
    "Louisiana Creole French": "Louisiana Creole",
    "Low Saxon/Low German": "Low German",
    "Newari": "Newar",
    "Nowegian": "Norwegian",
    "Old Portuguese": "Old Galician-Portuguese",
    "Old Galician Portuguese": "Old Galician-Portuguese",
    "Sámi": "Sami",
    "Serbo-Croat": "Serbo-Croatian",
    "Slovakian": "Slovak",
    "Slovenian": "Slovene",
}

new_language_groups = {}
for group, group_props in language_groups.items():
    rename = group_props.get("rename", {})
    group_props["rename_right_side"] = set(rename.values())
    new_language_groups[group] = group_props
language_groups = new_language_groups

# Keys are languages. The value for a key is a dictionary where keys are the language header the given language is
# indented under, or "" for a non-indented language.
lang_counts = defaultdict(lambda: defaultdict(int))
# Keys are languages. Values are total counts of appearances, indented or not.
total_lang_counts = defaultdict(int)
# Keys are non-indented languages ("headers"). The value for a key is a dictionary where keys are indented languages
# and values are counts.
header_counts = defaultdict(lambda: defaultdict(int))
# Keys are headers. Values are total counts of cases where there's at least one language indented.
total_header_counts = defaultdict(int)
# Keys are headers. The value for a key is a dictionary where keys are the unrecognized indented lang and values are
# counts.
unrecognized_indented_lang_counts = defaultdict(lambda: defaultdict(int))
# Keys are headers. Values are total counts of unrecognized indented languages.
header_with_unrecognized_lang_counts = defaultdict(int)


def process_text_on_page(index, pagename, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagename, txt))

    notes = []

    origtext = text
    new_lines = []
    lines = text.split("\n")
    in_translation_section = False
    langgroup_header = None
    langgroup_header_lineind = None
    translation_lines = None

    def rename_indented_lang(indented_lang, prev_top_level_lang):
        group_props = language_groups[prev_top_level_lang]
        new_indented_lang = None
        add_lang = group_props.get("add_lang", set())
        rename_map = group_props.get("rename", {})
        if boolean_function_matches(add_lang, indented_lang):
            new_indented_lang = indented_lang + " " + prev_top_level_lang
        elif indented_lang in rename_map:
            new_indented_lang = rename_map[indented_lang]
        if new_indented_lang:
            indented_lang = new_indented_lang
        return indented_lang

    # Check if a top-level language needs to be renamed and/or indented. Returns two values: The group to indent under
    # (or None if the language should stay at top level) and the name to use for the language. This function takes care
    # of outputting a message, adding to notes[] and setting need_langgroup_header[] if necessary.
    def need_to_indent_lang(lang, lineind):
        # First check if we need to rename the top-level line (e.g. because it's using an outdated name).
        if lang in top_level_rename:
            new_lang = top_level_rename[lang]
            pagemsg("Renaming top-level variety %s to %s" % (lang, new_lang))
            notes.append(["rename top-level variety ", "%s->%s" % (lang, new_lang), ""])
            lang = new_lang
        # Now check if we need to indent (and possibly rename) the language.
        for group, group_props in language_groups.items():
            indentfun = group_props.get("indent", lambda lang: default_indentfun(group, lang))
            if boolean_function_matches(indentfun, lang):
                new_indented_lang = rename_indented_lang(lang, group)
                if new_indented_lang != lang:
                    pagemsg("Indenting %s variety %s and renaming to %s" % (group, lang, new_indented_lang))
                    notes.append(["indent ", ["%s->" % group, "%s [rename to %s]" % (lang, new_indented_lang), ""], ""])
                    lang = new_indented_lang
                else:
                    pagemsg("Indenting %s variety %s" % (group, lang))
                    notes.append(["indent ", ["%s->" % group, lang, ""], ""])
                # We're indenting an unindented lang under a header. If the header doesn't already exist, it needs to be added.
                # We may not know whether to add the header till after we've processed the whole translation section; at that
                # point, if necessary, we add the header to the end. In all cases, we then sort, which puts the header in the
                # right location.
                if group not in langgroup_header:
                    langgroup_header[group] = ""
                    langgroup_header_lineind[group] = lineind
                return group, lang
        return None, lang

    def add_header_line(lang, after_lang, lineind):
        line = "* " + lang + after_lang
        if lang in language_groups:
            after_lang = after_lang[1:].strip()  # remove initial colon and strip whitespace
            if after_lang:
                after_lang = " " + after_lang
            if lang in langgroup_header:
                if not after_lang:
                    pagemsg(
                        "Already saw header for '%s' with remainder '%s', but new header remainder is empty; not adding"
                        % (lang, langgroup_header[lang])
                    )
                elif langgroup_header[lang]:
                    pagemsg(
                        "WARNING: Already saw header for '%s' with non-empty remainder '%s', and new remainder '%s' is also non-empty; duplicate lines will result"
                        % (lang, langgroup_header[lang], after_lang)
                    )
                    translation_lines.append((lang, [], lineind, line, True))
                else:
                    pagemsg(
                        "Already saw header for '%s' with empty remainder, and new header remainder '%s' is non-empty; replacing"
                        % (lang, after_lang)
                    )
                    langgroup_header[lang] = after_lang
                    langgroup_header_lineind[lang] = lineind
            else:
                langgroup_header[lang] = after_lang
                langgroup_header_lineind[lang] = lineind
        else:
            translation_lines.append((lang, [], lineind, line, True))

    for lineind, line in enumerate(lines):
        origline = line
        if re.search(r"^\{\{(trans-top|checktrans-top|trans-top-see|trans-top-also)[|}]", line):
            if in_translation_section:
                pagemsg("WARNING: Nested translation sections, skipping page, nested opening line follows: %s" % line)
                return
            in_translation_section = True
            langgroup_header = {}
            langgroup_header_lineind = {}
            saw_opening_html_comment = False
            opening_trans_line = line
            opening_lineind = lineind
            # We need to keep track of the previous header (in `prev_top_level_lang`) and the stack of any languages indented under
            # the header (in `prev_indented_langs`), so that when we sort the lines at the end, unrecognized lines follow the
            # preceding line and indented lines end up under the right header(s).
            prev_top_level_lang = ""
            prev_indented_langs = []
            # This is a list of a tuple of (top_level_lang, indented_langs, lineind, line, counts_for_sorting), serving as a
            # sort key, where
            # * `top_level_lang` is the top-level header under which an indented lang is found, or the lang itself if
            #   top-level;
            # * `indented_langs` is a list of nested langs, up to the lang of the line in question;
            # * `lineind` is the line index;
            # * `line` is the new line;
            # * `counts_for_sorting` is a boolean, whether to consider this line when checking to see whether sorting caused
            #   anything to move; this check is only to determine whether to add a changelog note indicating that we sorted
            #   out-of-order lines, not for the actual sort, which uses all lines.
            #
            # When encountering an unrecognized line, `top_level_lang` comes directly from `prev_top_level_lang` and `indented_langs`
            # directly from `prev_indented_langs`.
            translation_lines = []
            orig_translation_lines = []
            # The next four settings are used when we indent or unindent a line. Any lines afterward that were indented
            # underneath the moved line (determined by looking at `move_indented_at_or_above_level`) need to have to have
            # their top-level lang and indented langs set according to `move_indented_top_level_lang` and
            # `move_indented_indented_langs`, and may have to have their indentation level changed according to the change in
            # indentation level of the moved line (taken from `move_indented_offset`). Once we encounter a line below the
            # indentation level of `move_indented_at_or_above_level`, we reset all of the settings below. Note that a value of
            # 0 for `move_indented_at_or_above_level` indicates that no indentation moving needs to happen because it
            # indicates the minimum indentation level at which we need to change the indentation, and we will never be doing
            # this to top-level lines (no indentation).
            move_indented_at_or_above_level = 0
            move_indented_offset = 0
            move_indented_top_level_lang = None
            move_indented_indented_langs = []
            new_lines.append(line)
            is_indented_under_header = False
        elif re.search(r"^\}* *\{\{trans-bottom", line):  # allow for multitrans closing braces before {{trans-bottom}}
            if not in_translation_section:
                pagemsg("WARNING: Found {{trans-bottom}} not in a translation section")
            else:
                if saw_opening_html_comment:
                    pagemsg(
                        "WARNING: Saw full-line HTML comment in section beginning %s, preserving unchanged"
                        % opening_trans_line
                    )
                    new_lines.extend(orig_translation_lines)
                else:
                    for lang in langgroup_header:
                        translation_lines.append(
                            (
                                lang,
                                [],
                                langgroup_header_lineind[lang],
                                "* %s:%s" % (lang, langgroup_header[lang]),
                                False,
                            )
                        )
                    # Because we add the headers at the end, and sort them back into place, the sorted lines will almost always
                    # differ from the original lines. To get a better sense of whether we actually reordered any lines, sort
                    # before adding the new headers and then sort for real after adding the headers.
                    translation_lines_for_sorting = [
                        (langname_key(lang), [langname_key(x) for x in indented_lang], lineind, line)
                        for lang, indented_lang, lineind, line, counts_for_sorting in translation_lines
                        if counts_for_sorting
                    ]
                    new_translation_lines_for_sorting = sorted(translation_lines_for_sorting)
                    if translation_lines_for_sorting != new_translation_lines_for_sorting:
                        pagemsg("Sorting lines under %s" % opening_trans_line)
                        notes.append(
                            [
                                "sort lines under ",
                                re.sub(r"\|.*?\}", "}", re.sub(r"\}\}.*", "}}", opening_trans_line)),
                                "",
                            ]
                        )
                    translation_lines = [
                        (langname_key(lang), [langname_key(x) for x in indented_lang], lineind, line)
                        for lang, indented_lang, lineind, line, counts_for_sorting in translation_lines
                    ]
                    translation_lines = sorted(translation_lines)
                    prev_line = None
                    filtered_lines = []
                    translation_lines.append([("Foo", "Foo"), "", None, None])
                    for next_line in translation_lines:
                        if prev_line:
                            (_, prev_lang), prev_indented_lang, prev_lineind, prev_transline = prev_line
                            (_, next_lang), next_indented_lang, next_lineind, next_transline = next_line
                            if (
                                not prev_indented_lang
                                and not next_indented_lang
                                and "* %s:" % prev_lang == prev_transline
                                and (next_transline is None or next_transline.startswith("* %s:" % next_lang))
                            ):
                                pagemsg("Filtering out superfluous top-level line: %s" % prev_transline)
                                notes.append(["filter out superfluous header for ", prev_lang, ""])
                            else:
                                filtered_lines.append(prev_line)
                        prev_line = next_line
                    translation_lines = filtered_lines
                    for lang, indented_lang, lineind, transline in translation_lines:
                        new_lines.append(transline)
            new_lines.append(line)
            in_translation_section = False
        elif in_translation_section:
            orig_translation_lines.append(origline)
            if saw_opening_html_comment:
                pass  # no further processing
            elif line.startswith("{{multitrans|"):
                translation_lines.append(("", [], lineind, line, True))
            elif (
                line.startswith("}}")
                or line.startswith("<!-- close multitrans")
                or line.startswith("<!-- close {{multitrans")
            ):
                translation_lines.append(("\U0010ffff", [], lineind, line, True))
            else:
                newline = line.replace("\u00a0", " ")
                if newline != line:
                    line = newline
                    pagemsg("Replacing NBSP with regular space")
                    notes.append(["replace NBSP with regular space", "", ""])
                if not line.strip():
                    pagemsg("Skipping blank line")
                    notes.append(["skip blank line", "", ""])
                    continue

                def replace_ttbc(m):
                    langcode = m.group(1)
                    if langcode in lang_utils.languages_by_code:
                        langname = lang_utils.languages_by_code[langcode]["canonicalName"]
                        pagemsg("Replacing {{ttbc|%s}} with %s" % (langcode, langname))
                        notes.append(["replace ", "{{ttbc|%s}}->%s" % (langcode, langname), ""])
                        return langname
                    pagemsg("WARNING: Unrecognized langcode %s in {{ttbc}}: %s" % (langcode, line))
                    return m.group(0)

                line = re.sub(r"\{\{ttbc\|([^{}|=]*)\}\}", replace_ttbc, line)
                langname_regex = r"(?:'Are'are|!Xóõ|\w[^:;{}]*?)"
                m = re.search(r"^([:*]+ *)(%s)(;?)((?: *\{\{.*)?)$" % langname_regex, line)
                if m:
                    init, potential_lang, semicolon, rest = m.groups()
                    if (
                        potential_lang in lang_utils.languages_by_canonical_name
                        or potential_lang in lang_utils.etym_languages_by_canonical_name
                    ):
                        if semicolon:
                            pagemsg("Replacing semicolon with colon after lang %s: %s" % (potential_lang, line))
                        else:
                            pagemsg("Adding missing colon after lang %s: %s" % (potential_lang, line))
                        line = init + potential_lang + ":" + rest
                        if semicolon:
                            notes.append(["replace semicolon with colon after lang ", potential_lang, ""])
                        else:
                            notes.append(["add missing colon after lang ", potential_lang, ""])
                m = re.search(r"^([:*]\*)( *%s: *\{\{.*)$" % langname_regex, line)
                if m:
                    init_star, rest = m.groups()
                    line = "*:" + rest
                    pagemsg("Replacing %s with *: %s" % (init_star, line))
                    notes.append(["replace ", init_star, " with *:"])
                m = re.search(r"^\* *(:*) *(%s) *:(.*)$" % langname_regex, line)
                if m:
                    colons, lang, rest = m.groups()
                    rest = rest.strip()
                    if rest:
                        rest = " " + rest
                    newline = "*%s %s:%s" % (colons, lang, rest)
                    if newline != line:
                        line = newline
                        pagemsg("Fixing spacing issues for lang %s: %s" % (lang, line))
                        notes.append(["fix spacing issues for lang ", lang, ""])
                m = re.search(r"^(\* *(:+) *)([^:]+)(:.*)$", line)
                if m:
                    # We're processing an indented line.
                    init_star, colons, indented_lang, rest = m.groups()
                    # Copy the indentation stack so we don't affect the stack for preceding lines.
                    prev_indented_langs = prev_indented_langs[:]
                    new_indent = len(colons)
                    new_prev_top_level_lang = prev_top_level_lang
                    new_prev_indented_langs = prev_indented_langs
                    maintain_old_prev_langs = False
                    if move_indented_at_or_above_level > 0 and new_indent >= move_indented_at_or_above_level:
                        # We are indented under a line that moved and may have changed indentation; we need to move accordingly and
                        # possibly change indentation, but not permanently set the previous top-level and indented langs so that
                        # once we encounter a non-indented lang, we use the old settings.
                        maintain_old_prev_langs = True
                        new_prev_top_level_lang = move_indented_top_level_lang
                        new_prev_indented_langs = move_indented_indented_langs
                        if move_indented_offset != 0:
                            new_indent += move_indented_offset
                            colons = ":" * new_indent
                            init_star = "*" + colons + " "
                            line = init_star + indented_lang + rest
                            pagemsg("Reindenting line for lang %s: %s" % (indented_lang, line))
                            notes.append(["reindent line for lang ", indented_lang, ""])
                        pagemsg(
                            "Moving line under lang %s: %s"
                            % (" -> ".join([new_prev_top_level_lang] + new_prev_indented_langs), line)
                        )
                    else:
                        # We are not indented under such a line, so reset the flags controlling indentation changing.
                        move_indented_at_or_above_level = 0
                        move_indented_offset = 0
                        move_indented_top_level_lang = None
                        move_indented_indented_langs = []
                    old_indent = len(new_prev_indented_langs)
                    if new_indent > old_indent:
                        if new_indent - old_indent > 1:
                            pagemsg(
                                "WARNING: Saw greater than one increase in nesting, from %s to %s: lineind %s, line: %s"
                                % (old_indent, new_indent, lineind, line)
                            )
                        while new_indent - old_indent:
                            new_prev_indented_langs.append("")
                            old_indent += 1
                    elif new_indent < old_indent:
                        new_prev_indented_langs = new_prev_indented_langs[:new_indent]
                    new_prev_indented_langs[-1] = indented_lang
                    lang_counts[indented_lang][new_prev_top_level_lang] += 1
                    total_lang_counts[indented_lang] += 1
                    header_counts[new_prev_top_level_lang][indented_lang] += 1
                    if not is_indented_under_header:
                        total_header_counts[new_prev_top_level_lang] += 1
                        is_indented_under_header = True
                    if new_prev_top_level_lang in language_groups:
                        group_props = language_groups[new_prev_top_level_lang]
                        add_lang = group_props.get("add_lang", set())
                        rename_map = group_props.get("rename", {})
                        new_indented_lang = rename_indented_lang(indented_lang, new_prev_top_level_lang)
                        if new_indented_lang != indented_lang:
                            pagemsg(
                                "Renaming %s variety %s to %s"
                                % (new_prev_top_level_lang, indented_lang, new_indented_lang)
                            )
                            notes.append(
                                [
                                    "rename ",
                                    [
                                        "%s variety " % new_prev_top_level_lang,
                                        "%s->%s" % (indented_lang, new_indented_lang),
                                        "",
                                    ],
                                    "",
                                ]
                            )
                            indented_lang = new_indented_lang
                            new_prev_indented_langs[-1] = indented_lang
                            line = "%s%s%s" % (init_star, indented_lang, rest)
                        if boolean_function_matches(group_props.get("unindent", set()), indented_lang):
                            pagemsg("Unindenting %s under %s" % (indented_lang, new_prev_top_level_lang))
                            notes.append(["unindent ", ["", indented_lang, " under %s" % new_prev_top_level_lang], ""])
                            if maintain_old_prev_langs:
                                pagemsg(
                                    "WARNING: In the middle of moving indented languages under %s and trying to move %s to top level; resetting status, need to check manually"
                                    % ("->".join([new_prev_top_level_lang] + new_prev_indented_langs), indented_lang)
                                )
                            maintain_old_prev_langs = True
                            # We may need to unindent and then re-indent under a different header, possibly renaming the language in
                            # the process (e.g. in the 2026-01-01 dump there are 6 occurrences of Kurmanji indented under Punjabi;
                            # they need to be unindented, reindented under Kurdish and renamed to Northern Kurdish). The function
                            # need_to_indent_lang() takes care of outputting a message and adding to notes[].
                            #
                            # Make sure to set prev_indented_langs and prev_top_level_lang; we are moving an indented line to top
                            # level and potentially reindenting it elsewhere; if the next line is unrecognized, it should follow.
                            indent_under_group, new_lang_name = need_to_indent_lang(indented_lang, lineind)
                            indented_lang = new_lang_name
                            if indent_under_group:
                                line = "*: " + indented_lang + rest
                                new_prev_top_level_lang = indent_under_group
                                new_prev_indented_langs = [indented_lang]
                                translation_lines.append((indent_under_group, [indented_lang], lineind, line, False))
                                # Any lines indented under the previously indented line may need to have their indentation decreased,
                                # specifically if the previous indentation was greater than 1, because the new indentation is 1.
                                move_indented_offset = -new_indent + 1
                                move_indented_at_or_above_level = new_indent + 1
                                move_indented_top_level_lang = new_prev_top_level_lang
                                # Not clear we need to copy the list but best to do it for safety. (FIXME: Verify if it's needed.)
                                move_indented_indented_langs = new_prev_indented_langs[:]
                            else:
                                # We may be unindenting "Modern Greek", renamed to just "Greek"; it needs to become a header line,
                                # and be handled as such.
                                new_prev_top_level_lang = indented_lang
                                new_prev_indented_langs = []
                                add_header_line(indented_lang, rest, lineind)
                                # Any lines indented under the previously indented line need to have their indentation decreased.
                                move_indented_at_or_above_level = new_indent + 1
                                move_indented_offset = -new_indent
                                move_indented_top_level_lang = new_prev_top_level_lang
                                # Not clear we need to copy the list but best to do it for safety. (FIXME: Verify if it's needed.)
                                move_indented_indented_langs = new_prev_indented_langs[:]
                        else:
                            if args.rename_min and new_prev_top_level_lang == "Chinese" and indented_lang == "Min Nan":
                                pagemsg("Replacing Min Nan with Hokkien and changing code nan->nan-hbl")
                                notes.append(["replace Min Nan with Hokkien and change code nan->nan-hbl", "", ""])
                                indented_lang = "Hokkien"
                                new_prev_indented_langs[-1] = indented_lang
                                parsed = blib.parse_text(rest)
                                changed = False
                                for t in parsed.filter_templates():
                                    tn = tname(t)
                                    if tn in blib.translation_templates:
                                        langcode = getparam(t, "1").strip()
                                        if langcode == "nan":
                                            t.add("1", "nan-hbl")
                                            changed = True
                                if changed:
                                    rest = str(parsed)
                                line = "%s%s%s" % (init_star, indented_lang, rest)
                            else:
                                indentfun = group_props.get(
                                    "indent", lambda lang: default_indentfun(new_prev_top_level_lang, lang)
                                )
                                recognizefun = group_props.get("recognize", set())
                                recognized = (
                                    indented_lang in group_props["rename_right_side"]
                                    or boolean_function_matches(indentfun, indented_lang)
                                    or boolean_function_matches(recognizefun, indented_lang)
                                )
                                if not recognized and indented_lang.endswith(" " + new_prev_top_level_lang):
                                    recognized = boolean_function_matches(
                                        add_lang, indented_lang[: -len(new_prev_top_level_lang) - 1]
                                    )
                                if not recognized:
                                    pagemsg(
                                        "WARNING: Unrecognized indented lang %s under %s"
                                        % (indented_lang, new_prev_top_level_lang)
                                    )
                                    unrecognized_indented_lang_counts[new_prev_top_level_lang][indented_lang] += 1
                                    header_with_unrecognized_lang_counts[new_prev_top_level_lang] += 1
                            translation_lines.append(
                                (new_prev_top_level_lang, new_prev_indented_langs, lineind, line, True)
                            )
                    else:
                        translation_lines.append(
                            (new_prev_top_level_lang, new_prev_indented_langs, lineind, line, True)
                        )
                    if not maintain_old_prev_langs:
                        prev_top_level_lang = new_prev_top_level_lang
                        prev_indented_langs = new_prev_indented_langs
                else:
                    m = re.search(r"^\* *((%s)(:.*))$" % langname_regex, line)
                    if not m:
                        pagemsg("WARNING: Unrecognized line in translation section: %s" % line)
                        if re.search(r"^\s*<!--", line) and lineind > opening_lineind + 1:
                            saw_opening_html_comment = True
                        translation_lines.append((prev_top_level_lang, prev_indented_langs, lineind, line, True))
                    else:
                        # We're processing an unindented (top-level) line.
                        rest, lang, after_lang = m.groups()
                        lang_counts[lang][""] += 1
                        total_lang_counts[lang] += 1
                        is_indented_under_header = False
                        # We're not indented under any header so reset any flags controlling offsetting the indentation.
                        move_indented_at_or_above_level = 0
                        move_indented_offset = 0
                        move_indented_top_level_lang = None
                        move_indented_indented_langs = []
                        # Check if we need to indent and possibly rename the language.
                        indent_under_group, new_lang_name = need_to_indent_lang(lang, lineind)
                        if indent_under_group:
                            lang = new_lang_name
                            line = "*: " + lang + after_lang
                            # Unrecognized lines directly after a top-level line that we indent and move elsewhere should move with
                            # the line, as above.
                            prev_top_level_lang = indent_under_group
                            prev_indented_langs = [lang]
                            # Any lines indented under the newly indented (previously top-level) line need to have their indentation
                            # increased.
                            move_indented_at_or_above_level = 1
                            move_indented_offset = 1
                            move_indented_top_level_lang = prev_top_level_lang
                            # Not clear we need to copy the list but best to do it for safety. (FIXME: Verify if it's needed.)
                            move_indented_indented_langs = prev_indented_langs[:]
                            translation_lines.append((prev_top_level_lang, prev_indented_langs, lineind, line, False))
                        else:
                            if new_lang_name != lang:
                                lang = new_lang_name
                                line = "* " + lang + after_lang
                            prev_top_level_lang = lang
                            prev_indented_langs = []
                            # We handle the header lines of known language groups differently, since we may be indenting lines under
                            # a header that may not (yet?) exist, or moving an indented line like "Modern Greek" to be the header line
                            # ("Greek"). Specifically, rather than adding the line as we encounter it, we keep track of the header
                            # line "remainder" (everything after the colon, if anything) and corresponding line index, and add all the
                            # lines at the end just before sorting.
                            add_header_line(lang, after_lang, lineind)
        else:
            new_lines.append(line)

    if in_translation_section:
        pagemsg("WARNING: Page ended in a translation section, something wrong, skipping")
        return

    text = "\n".join(new_lines)

    if text != origtext and not notes:
        default_changelog = "misc reformatting (usually sorting)"
        notes.append([default_changelog, "", ""])
        pagemsg("WARNING: Adding default changelog '%s'" % default_changelog)

    def group_notes(notes, joiner=", "):
        notes_middles = {}
        uniq_notes = []
        # Preserve ordering of notes but combine similar notes, maintaining the order.
        for before, middle, after in notes:
            key = (before, after)
            if key in notes_middles:
                if middle not in notes_middles[key]:
                    notes_middles[key].append(middle)
            else:
                notes_middles[key] = [middle]
                uniq_notes.append(key)

        def fmt_note(key):
            middles = notes_middles[key]
            if type(middles[0]) is list:
                middles = group_notes(middles, " + " if "->" in middles[0][1] else "/")
            before, after = key
            return "%s%s%s" % (before, joiner.join(middles), after)

        return [fmt_note(key) for key in uniq_notes]

    notes = group_notes(notes)
    notes = "translations: " + "; ".join(blib.group_notes(notes))
    comment_len = len(notes.encode("utf-8"))
    if comment_len > 500:
        pagemsg("WARNING: Comment length %s > 500: %s" % (comment_len, notes))
    return text, notes


parser = blib.create_argparser(
    "Sort and reformat translations, correct misc translation table issues", include_pagefile=True, include_stdin=True
)
parser.add_argument("--rename-min", action="store_true", help="Rename Min Nan to Hokkien and change nan to nan-hbl")
parser.add_argument(
    "--analyze",
    action="store_true",
    help="Analyze existing indented and non-indented language use and output a table at the end.",
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True)

if args.analyze:

    def output_table(key):
        msg("%-40s %5s: %s" % ("Language", "Count", "Count-by-header"))
        msg("---------------------------------------------------------")
        for lang, count in sorted(list(total_lang_counts.items()), key=key):
            by_header = "; ".join(
                "%s (%s)" % (header or "unindented", headercount)
                for header, headercount in sorted(list(lang_counts[lang].items()), key=lambda x: -x[1])
            )
            msg("%-40s %5s: %s" % (lang, count, by_header))

    msg("Sorted by total count:")
    msg("----------------------")
    output_table(lambda x: -x[1])
    msg("")
    msg("Sorted by language, from the end:")
    msg("---------------------------------")
    output_table(lambda x: (x[0][::-1], -x[1]))
    msg("")
    msg("By header:")
    msg("----------")
    msg("%-50s %8s %s" % ("Header", "Indented", "Total"))
    msg("------------------------------------------------------------------")
    for header, indented_dict in sorted(list(header_counts.items()), key=lambda x: -total_header_counts[x[0]]):
        msg("%-50s %8s %5s" % (header, total_header_counts[header], total_lang_counts[header]))
        for lang, langcount in sorted(list(indented_dict.items()), key=lambda x: x[0]):
            msg("%-50s %8s %5s" % ("  * %s" % (lang), langcount, total_lang_counts[lang]))
    msg("")
    msg("Unrecognized indented languages:")
    msg("--------------------------------")
    msg("%-40s %-40s %5s" % ("Header", "Indented", "Total"))
    msg("-" * 87)
    for header, indented_dict in sorted(
        list(unrecognized_indented_lang_counts.items()), key=lambda x: -header_with_unrecognized_lang_counts[x[0]]
    ):
        first = True
        for lang, langcount in sorted(list(indented_dict.items()), key=lambda x: x[0]):
            if first:
                msg("%-40s %-40s %5s" % (header, lang, langcount))
                first = False
            else:
                msg("%-40s %-40s %5s" % ("", lang, langcount))
