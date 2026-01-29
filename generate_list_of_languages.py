#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import blib
from blib import msg
from collections import defaultdict

#blib.init_fake_langdata()
blib.getData()

languages = list(blib.languages_byCanonicalName.keys())

def langname_key(lang):
  return blib.langname_key(lang, prepend_translingual_english=False)

langs_by_key = defaultdict(list)

msg("Languages:")
msg("----------")
for x in sorted(languages, key=langname_key):
  key, _ = langname_key(x)
  langs_by_key[key].append(x)
  msg(x)
msg("")
msg("Languages, sorted from the end:")
msg("-------------------------------")
for x in sorted(languages, key=lambda lang: langname_key(lang[::-1])):
  msg(x)
msg("")
msg("Confusable languages:")
msg("---------------------")
for key, langs in langs_by_key.items():
  if len(langs) > 1:
    msg("* %s" % ", ".join("[[:Category:%s language|%s]]" % (lang, lang) for lang in langs))
