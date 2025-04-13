#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import pywikibot, re, sys, argparse, time
import difflib
import blib
from blib import site, msg, errandmsg, group_notes, iter_items
from diff_match_patch import diff_match_patch

seen_page_changes = {}
seen_pages = []

def get_diff(file1, file2, pagetitle, reverse=False):
  if reverse:
    tmp = file1
    file1 = file2
    file2 = tmp
  if args.output_format == "diff-match-patch":
    dmp = diff_match_patch()
    patches = dmp.patch_make(file1, file2)
    return dmp.patch_toText(patches)
  else:
    oldlines = file1.splitlines(True)
    newlines = file2.splitlines(True)
    diff = difflib.unified_diff(oldlines, newlines)
    newtext = []
    dangling_newline = False
    for line in diff:
      if args.output_format == "patch-ng":
        line = re.sub(r"\A--- $", "--- a/%s" % pagetitle, line)
        line = re.sub(r"\A\+\+\+ $", "+++ b/%s" % pagetitle, line)
      dangling_newline = not line.endswith("\n")
      newtext.append(line)
      if dangling_newline:
        newtext.append("\n")
    if dangling_newline:
      newtext.append("\\ No newline at end of file\n")
    return "".join(newtext)

def process_item(index, item):
  pagetitle = item["title"]

  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagetitle, txt))

  def errandpagemsg(txt):
    errandmsg("Page %s %s: %s" % (index, pagetitle, txt))

  revid = item["revid"]
  parentid = item["parentid"]
  if pagetitle not in seen_pages:
    seen_pages.append(pagetitle)
    seen_page_changes[pagetitle] = [(revid, parentid, 1)]
  else:
    last_revid, last_parentid, last_numchanges = seen_page_changes[pagetitle][-1]
    if revid == last_parentid:
      seen_page_changes[pagetitle][-1] = (last_revid, parentid, last_numchanges + 1)
    else:
      seen_page_changes[pagetitle].append((revid, parentid, 1))
      if revid == 0 or last_parentid == 0:
        pagemsg("WARNING: Non-contiguous change(s) to page, but unable to fetch in-between diff between rev ID's %s and %s" % (revid, last_parentid))
      else:
        pagemsg("WARNING: Non-contiguous change(s) to page: Diff between revs %s and %s:" % (revid, last_parentid))
        page = pywikibot.Page(site, pagetitle)
        revid_text = page.getOldVersion(revid)
        last_parentid_text = page.getOldVersion(last_parentid)
        diff = get_diff(revid_text, last_parentid_text, pagetitle)
        sys.stdout.write(diff)

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

msg("Fetching contributions ...")
for index, item in blib.get_contributions(args.user, start, end):
  process_item(index, item)

msg("Fetching diffs ...")
for index, pagetitle in blib.iter_items(seen_pages):
  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagetitle, txt))

  def errandpagemsg(txt):
    errandmsg("Page %s %s: %s" % (index, pagetitle, txt))

  changes = seen_page_changes[pagetitle]
  if len(changes) == 1:
    revid, old_revid, numchanges = changes[0]
  else:
    pagemsg("WARNING: %s sets of non-contiguous changes" % (len(changes)))
    revid, _, _ = changes[0]
    _, old_revid, _ = changes[-1]
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
    diff = get_diff(oldtext or "", pagetext, pagetitle, args.reverse)
    sys.stdout.write(diff)
    msg("-------- end text --------")

if args.output_format == "full":
  output_newly_created_user.close()
  output_newly_created_current.close()
  output_existing_prev.close()
  output_existing_user.close()
  output_existing_current.close()
