#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import pywikibot, re, sys, argparse, time
import difflib
import blib
from blib import site, msg, errandmsg, group_notes, iter_items
from diff_match_patch import diff_match_patch

def process_item(index, item):
  pagetitle = item["title"]

  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagetitle, txt))

  def errandpagemsg(txt):
    errandmsg("Page %s %s: %s" % (index, pagetitle, txt))

  revid = item["revid"]
  old_revid = item["parentid"]
  page = pywikibot.Page(site, pagetitle)
  pagetext = page.getOldVersion(revid)
  if old_revid == 0:
    oldtext = None
    pagemsg("WARNING: File created")
  else:
    oldtext = page.getOldVersion(old_revid)
  if args.output_format == "full":
    def output_beginning(fp):
      fp.write("Page %s %s: -------- begin text --------\n" % (index, pagetitle))
    def output_end(fp):
      fp.write("-------- end text --------\n")
    def output_page(fp, text):
      output_beginning(fp)
      fp.write(text)
      fp.write("\n")
      output_end(fp)
    if not blib.safe_page_exists(page, errandpagemsg):
      pagemsg("WARNING: Page doesn't exist any more")
      curtext = ""
    else:
      curtext = blib.safe_page_text(page, errandpagemsg, bad_value_ret=None)
      if curtext is None:
        pagemsg("WARNING: Page can't be fetched")
        curtext = ""
    if oldtext is None:
      output_page(output_newly_created_user, pagetext)
      output_page(output_newly_created_current, curtext)
    else:
      output_page(output_existing_prev, oldtext)
      output_page(output_existing_user, pagetext)
      output_page(output_existing_current, curtext)
  else:
    pagemsg("-------- begin text --------")
    def get_diff(file1, file2):
      if args.output_format == "diff-match-patch":
        dmp = diff_match_patch()
        patches = dmp.patch_make(file1, file2)
        return dmp.patch_toText(patches)
      else:
        oldlines = file1.splitlines(True)
        newlines = file2.splitlines(True)
        diff = difflib.unified_diff(oldlines, newlines)
        return diff
    if args.reverse:
      diff = get_diff(pagetext, oldtext or "")
    else:
      diff = get_diff(oldtext or "", pagetext)
    if args.output_format == "diff-match-patch":
      sys.stdout.write(diff)
    else:
      dangling_newline = False
      for line in diff:
        line = re.sub(r"\A--- $", "--- a/%s" % pagetitle, line)
        line = re.sub(r"\A\+\+\+ $", "+++ b/%s" % pagetitle, line)
        dangling_newline = not line.endswith('\n')
        sys.stdout.write(line)
        if dangling_newline:
          sys.stdout.write("\n")
      if dangling_newline:
        sys.stdout.write("\\ No newline at end of file\n")
    msg("-------- end text --------")

parser = blib.create_argparser("Show contributions of a user")
parser.add_argument("--user", help="User to do.", required=True)
parser.add_argument("--reverse", help="Reverse the patch.", action="store_true")
parser.add_argument("--output-format", choices=["diff-match-patch", "difflib", "patch-ng", "full"])
parser.add_argument("--output-prefix", help="When '--output-format full' is used, prefix for the three output files")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

if args.output_format == "full":
  if not args.output_prefix:
    raise ValueError("When --output-format=full, --output-prefix must be specified")
  output_newly_created_user = open("%s.new.user.txt" % args.output_prefix, "w")
  output_newly_created_current = open("%s.new.current.txt" % args.output_prefix, "w")
  output_existing_prev = open("%s.existing.prev.txt" % args.output_prefix, "w")
  output_existing_user = open("%s.existing.user.txt" % args.output_prefix, "w")
  output_existing_current = open("%s.existing.current.txt" % args.output_prefix, "w")
for index, item in blib.get_contributions(args.user, start, end):
  process_item(index, item)
if args.output_format == "full":
  output_newly_created_user.close()
  output_newly_created_current.close()
  output_existing_prev.close()
  output_existing_user.close()
  output_existing_current.close()
