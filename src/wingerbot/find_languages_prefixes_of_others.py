#!/usr/bin/env python3

import json
from collections import defaultdict

from wingerbot import blib, lang_utils
from wingerbot.blib import msg

lang_utils.init_fake_lang_data()
#lang_utils.load_all_lang_data("langdata.json")
lang_data = lang_utils.get_lang_data()
etym_lang_data = lang_utils.get_etym_lang_data()

all_langs = sorted(
    [(x, "full") for x in lang_data.languages_by_canonical_name.keys()]
    + [(x, "etym") for x in etym_lang_data.etym_languages_by_canonical_name.keys()]
)
prevs = []
for i in range(len(all_langs)):
    this, typ = all_langs[i]
    last_prefix = 0
    for j in range(len(prevs)):
        last_prefix = j
        if not this.startswith(all_langs[prevs[j]][0] + " "):
            break
    else:
        last_prefix = len(prevs)
    if last_prefix > 0:
        msg("%s (%s) starts with %s" % (this, typ, ", ".join("%s (%s)" % all_langs[x] for x in prevs[0:last_prefix])))
    prevs = prevs[0:last_prefix] + [i]
