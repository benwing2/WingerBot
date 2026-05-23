#!/usr/bin/env python3

# FIXME: Not necessarily working. Current status unclear.

import pywikibot, re, sys, argparse
from wingerbot import blib
from wingerbot.blib import site, msg, errandmsg
import logging


class PatchLogHandler(logging.Handler):
    def __init__(self):
        logging.Handler.__init__(self, logging.WARN)

    def emit(self, record):
        # print(record)
        logstr = self.format(record)
        print(logstr)


patch_ng_logger = logging.getLogger("patch_ng")
patch_ng_logger.handlers = []
patch_ng_logger.addHandler(PatchLogHandler())


def process_text_on_page(index, pagetitle, text):
    def pagemsg(txt):
        msg("Page %s %s: %s" % (index, pagetitle, txt))

    def errandpagemsg(txt):
        errandmsg("Page %s %s: %s" % (index, pagetitle, txt))

    if pagetitle not in patches_by_file:
        pagemsg("WARNING: Can't find diff for file")
        return

    pagemsg("Processing")
    page = pywikibot.Page(site, pagetitle)
    if not blib.safe_page_exists(page, errandpagemsg):
        pagemsg("WARNING: Page doesn't exist any more")
    else:
        curtext = blib.safe_page_text(page, errandpagemsg, bad_value_ret=None)
        if curtext is None:
            pagemsg("WARNING: Page can't be fetched")
        else:
            if args.input_format == "diff-match-patch":
                from diff_match_patch import diff_match_patch

                dmp = diff_match_patch()
                diff = patches_by_file[pagetitle]
                # diff = re.sub(r"\A--- \n\+\+\+\n", "", diff)
                # diff = re.sub(r"\\ No newline at end of file\n\Z", "", diff)
                patches = dmp.patch_fromText(diff)
                newtext, _ = dmp.patch_apply(patches, curtext)
            else:
                from patch_ng import fromstring, fromfile

                origfile = open("%s/%s" % (args.tmp_dir, pagetitle), "w")
                origfile.write(curtext)
                origfile.close()
                diff = patches_by_file[pagetitle]
                patchfn = "%s/%s.patch" % (args.tmp_dir, pagetitle)
                patchfile = open(patchfn, "w")
                patchfile.write(diff)
                patchfile.close()
                # patch = fromstring(diff)
                patch = fromfile(patchfn)
                patch.apply(root=args.tmp_dir, strip=0, fuzz=False)
                newfile = open("%s/%s" % (args.tmp_dir, pagetitle), "r")
                newtext = "".join(newfile.readlines())
                newfile.close()

            if newtext != curtext:
                return newtext, "Undo bad change(s) by [[User:%s]]" % args.user


parser = blib.create_argparser("Show contributions of a user", include_pagefile=True, include_stdin=True)
parser.add_argument("--user", help="User to do.", required=True)
parser.add_argument("--direcfile", help="File with diffs.", required=True)
parser.add_argument("--input-format", choices=["diff-match-patch", "patch-ng"])
parser.add_argument("--tmp-dir", help="Temporary directory for use with patch-ng")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

patches_by_file = {}
pages_seen = []
for index, pagetitle, diff, comments in blib.yield_text_from_find_regex(
    open(args.direcfile, "r", encoding="utf-8"), args.verbose
):
    pages_seen.append(pagetitle)
    patches_by_file[pagetitle] = diff

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True, default_pages=pages_seen)
