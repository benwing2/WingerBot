#!/usr/bin/env python3

import argparse, pywikibot

parser = argparse.ArgumentParser(description="Upload a Lua file to Wiktionary and run an entry point.")
parser.add_argument("--local-file", help="Local Lua file to upload.", required=True)
parser.add_argument("--remote-prefix", help="Remote prefix to use to isolate uploaded files.",
                    default="User:Benwing2/run-lua/")
parser.add_argument("--remote-name", help="Name to use of remote file.", required=True)
parser.add_argument("--summary", help="Changelog summary.", default="Save uploaded file")
parser.add_argument("--entry-point", help="Function to run.")
parser.add_argument("--arguments", help="Arguments of function to run, separated by a vertical bar.")
parser.add_argument("--template", help="Template to expand.")
parser.add_argument("--pagetitle", help="Default pagetitle when running entry point.")
args = parser.parse_args()

remote_module = args.remote_prefix + args.remote_name
remote_pagename = "Module:" + remote_module
template = args.template
if not template:
    if not args.entry_point:
        raise ValueError("--template or --entry-point must be specified")
    arguments = "|" + args.arguments if args.arguments else ""
    template = "{{#invoke:%s|%s%s}}" % (remote_module, args.entry_point, arguments)
site = pywikibot.Site()
local_contents = open(args.local_file).read()
page = pywikibot.Page(site, remote_pagename)
page.text = local_contents
page.save(summary=args.summary)
pagetitle = args.pagetitle or remote_pagename
print(site.expand_text(template, title=pagetitle))