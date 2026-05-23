#!/usr/bin/env python3

from wingerbot import blib
from wingerbot.blib import msg
import sys
from wingerbot.latin import lalib

parser = blib.create_argparser("Remove Latin macrons from input", no_beginning_line=True)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

for index, line in blib.iter_items(sys.stdin, start, end):
  line = line.strip()
  msg(lalib.remove_macrons(line))
