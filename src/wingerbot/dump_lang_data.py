#!/usr/bin/env python3

from wingerbot import lang_utils
import json

lang_outfile = "lang-data.json"
etymlang_outfile = "etymlang-data.json"
family_outfile = "family-data.json"
script_outfile = "script-data.json"

lang_data = lang_utils.get_lang_data()
etym_lang_data = lang_utils.get_etym_lang_data()
family_data = lang_utils.get_family_data()
script_data = lang_utils.get_script_data()

with open(lang_outfile, "w") as fp:
    for lang in lang_data.languages:
        fp.write(json.dumps(lang) + "\n")

with open(etymlang_outfile, "w") as fp:
    for lang in etym_lang_data.etym_languages:
        fp.write(json.dumps(lang) + "\n")

with open(family_outfile, "w") as fp:
    for fam in family_data.families:
        fp.write(json.dumps(fam) + "\n")

with open(script_outfile, "w") as fp:
    for scr in script_data.scripts:
        fp.write(json.dumps(scr) + "\n")
