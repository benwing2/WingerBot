#!/usr/bin/env python3

from wingerbot import lang_utils
import json

lang_outfile = "lang-data.json"
etymlang_outfile = "etymlang-data.json"
family_outfile = "family-data.json"
script_outfile = "script-data.json"

lang_utils.get_all_lang_data()

with open(lang_outfile, "w") as fp:
    for lang in lang_utils.languages:
        fp.write(json.dumps(lang) + "\n")

with open(etymlang_outfile, "w") as fp:
    for lang in lang_utils.etym_languages:
        fp.write(json.dumps(lang) + "\n")

with open(family_outfile, "w") as fp:
    for fam in lang_utils.families:
        fp.write(json.dumps(fam) + "\n")

with open(script_outfile, "w") as fp:
    for scr in lang_utils.scripts:
        fp.write(json.dumps(scr) + "\n")
