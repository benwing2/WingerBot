#!/usr/bin/env python3

import pywikibot

from wingerbot import blib

parser = blib.create_argparser("Login to site", no_include_pagefile=True, no_include_stdin=True)
args = parser.parse_args()

pywikibot.Site().login()
