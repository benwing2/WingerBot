#!/usr/bin/env python3

from wingerbot import blib
from wingerbot.slavic.russian import rulib
from collections import OrderedDict

parser = blib.create_argparser(
    "Output short adjectives in Wiktionary, ordered by frequency.",
)
parser.add_argument("--freq-adjs", help="""Adjectives ordered by frequency, without accents or ё.""", required=True)
parser.add_argument(
    "--wiktionary-short-adjs",
    help="""Adjectives in Wiktionary with short forms, in alphabetical order.
Should be accented and with ё.""",
    required=True,
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

short_adjs = OrderedDict(
    (rulib.make_unstressed_ru(x), True) for x in blib.fetch_items_from_file(args.wiktionary_short_adjs)
)
for lineno, line in blib.iter_items_from_file(args.freq_adjs, start, end):
    if line in short_adjs:
        print(line)
        del short_adjs[line]
for line in short_adjs:
    print(line)
