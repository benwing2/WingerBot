#!/usr/bin/env python3
"""WARNING: This script is out of date. We now use [[Module:number list/data/ru]] to contain all Russian number data
rather than generate it manually per page like this. But the examples in the text are still useful."""

import re

from wingerbot import blib
from wingerbot.blib import msg
from wingerbot.slavic.russian import rulib

ordinals = {
    1: "пе́рвый",
    2: "второ́й",
    3: "тре́тий",
    4: "четвёртый",
    5: "пя́тый",
    6: "шесто́й",
    7: "седьмо́й",
    8: "восьмо́й",
    9: "девя́тый",
}

cardinal_ten_decls = {
    # order is nom, gen, dat, acc, ins, pre
    20: ["два́дцать", "двадцати́", "двадцати́", "два́дцать", "двадцатью́", "двадцати́"],
    30: ["три́дцать", "тридцати́", "тридцати́", "три́дцать", "тридцатью́", "тридцати́"],
    40: ["со́рок", "сорока́", "сорока́", "со́рок", "сорока́", "сорока́"],
    50: ["пятьдеся́т", "пяти́десяти", "пяти́десяти", "пятьдеся́т", "пятью́десятью", "пяти́десяти"],
    60: ["шестьдеся́т", "шести́десяти", "шести́десяти", "шестьдеся́т", "шестью́десятью", "шести́десяти"],
    70: ["се́мьдесят", "семи́десяти", "семи́десяти", "се́мьдесят", "семью́десятью", "семи́десяти"],
    80: [
        "во́семьдесят",
        "восьми́десяти",
        "восьми́десяти",
        "во́семьдесят",
        ["восемью́десятью", "восьмью́десятью"],
        "восьми́десяти",
    ],
    90: ["девяно́сто", "девяно́ста", "девяно́ста", "девяно́сто", "девяно́ста", "девяно́ста"],
}

cardinal_one_decls = {
    # order is nom_m, nom_f, gen, dat, ins, pre
    2: ["два́", "две́", "дву́х", "дву́м", "двумя́", "дву́х"],
    3: ["три́", "три́", "трёх", "трём", "тремя́", "трёх"],
    4: ["четы́ре", "четы́ре", "четырёх", "четырём", "четырьмя́", "четырёх"],
    5: ["пя́ть", "пя́ть", "пяти́", "пяти́", "пятью́", "пяти́"],
    6: ["ше́сть", "ше́сть", "шести́", "шести́", "шестью́", "шести́"],
    7: ["се́мь", "се́мь", "семи́", "семи́", "семью́", "семи́"],
    8: ["во́семь", "во́семь", "восьми́", "восьми́", ["восемью́", "восьмью́"], "восьми́"],
    9: ["де́вять", "де́вять", "девяти́", "девяти́", "девятью́", "девяти́"],
}

cardinal_tens = {num: decl[0] for num, decl in cardinal_ten_decls.items()}
cardinal_tens[100] = "сто́"

cardinal_ones = {
    0: "",
    1: "оди́н",
    2: "два́",
    3: "три́",
    4: "четы́ре",
    5: "пя́ть",
    6: "ше́сть",
    7: "се́мь",
    8: "во́семь",
    9: "де́вять",
}

english_cardinals = {
    1: "one",
    2: "two",
    3: "three",
    4: "four",
    5: "five",
    6: "six",
    7: "seven",
    8: "eight",
    9: "nine",
    20: "twenty",
    30: "thirty",
    40: "forty",
    50: "fifty",
    60: "sixty",
    70: "seventy",
    80: "eighty",
    90: "ninety",
}


def combine(tens, ones):
    if type(tens) is not list:
        tens = [tens]
    if type(ones) is not list:
        ones = [ones]
    vals = []
    # The first clause below ensures that we get only two entries for the
    # instrumental of 88 (во́семьдесят во́семь) instead of four. The second
    # clause typically applies when one of the two words has a single
    # possibility and the other has two.
    if len(tens) == len(ones):
        for ten, one in zip(tens, ones):
            if one:
                vals.append("%s %s" % (ten, one))
            else:
                vals.append(ten)
    else:
        for ten in tens:
            for one in ones:
                if one:
                    vals.append("%s %s" % (ten, one))
                else:
                    vals.append(ten)
    return ",".join(vals)


def ru_num(num):
    tens = (num / 10) * 10
    ones = num % 10
    return combine(cardinal_tens[tens], cardinal_ones[ones])


def en_num(num):
    tens = (num / 10) * 10
    ones = num % 10
    return "%s-%s" % (english_cardinals[tens], english_cardinals[ones])


def generate_decl(num):
    tens = (num / 10) * 10
    tnom, tgen, tdat, tacc, tins, tpre = cardinal_ten_decls[tens]
    ones = num % 10
    if ones == 1:
        return """{{ru-adj-table
|nom_m=%s
|nom_n=%s
|nom_f=%s
|nom_p=%s
|gen_m=%s
|gen_f=%s
|gen_p=%s
|dat_m=%s
|dat_f=%s
|dat_p=%s
|acc_m_an=%s
|acc_f=%s
|acc_p_an=%s
|ins_m=%s
|ins_f=%s
|ins_p=%s
|pre_m=%s
|pre_f=%s
|pre_p=%s
}}""" % (
            combine(tnom, "оди́н"),
            combine(tnom, "одно́"),
            combine(tnom, "одна́"),
            combine(tnom, "одни́"),
            combine(tgen, "одного́"),
            combine(tgen, "одно́й"),
            combine(tgen, "одни́х"),
            combine(tdat, "одному́"),
            combine(tdat, "одно́й"),
            combine(tdat, "одни́м"),
            combine(tacc, "одного́"),
            combine(tacc, "одну́"),
            combine(tacc, "одни́х"),
            combine(tins, "одни́м"),
            combine(tins, ["одно́й", "одно́ю"]),
            combine(tins, "одни́ми"),
            combine(tpre, "одно́м"),
            combine(tpre, "одно́й"),
            combine(tpre, "одни́х"),
        )
    elif ones == 2:
        return """{{ru-decl-adj|-|manual|nom_mp=%s|nom_fp=%s|gen_p=%s|dat_p=%s|ins_p=%s|pre_p=%s|special=cdva}}""" % (
            combine(tnom, "два́"),
            combine(tnom, "две́"),
            combine(tgen, "дву́х"),
            combine(tdat, "дву́м"),
            combine(tins, "двумя́"),
            combine(tpre, "дву́х"),
        )
    elif ones == 3:
        return """{{ru-decl-noun-unc
|%s
|%s
|%s
|%s
|%s
|%s
}}""" % (
            combine(tnom, "три́"),
            combine(tgen, "трёх"),
            combine(tdat, "трём"),
            combine(tacc, "три́"),
            combine(tins, "тремя́"),
            combine(tpre, "трёх"),
        )
    elif ones == 4:
        return """{{ru-decl-noun-unc
|%s
|%s
|%s
|%s
|%s
|%s
}}""" % (
            combine(tnom, "четы́ре"),
            combine(tgen, "четырёх"),
            combine(tdat, "четырём"),
            combine(tacc, "четы́ре"),
            combine(tins, "четырьмя́"),
            combine(tpre, "четырёх"),
        )
    elif ones == 5:
        return """{{ru-decl-noun-unc
|%s
|%s
|%s
|%s
|%s
|%s
}}""" % (
            combine(tnom, "пя́ть"),
            combine(tgen, "пяти́"),
            combine(tdat, "пяти́"),
            combine(tacc, "пя́ть"),
            combine(tins, "пятью́"),
            combine(tpre, "пяти́"),
        )
    elif ones == 6:
        return """{{ru-decl-noun-unc
|%s
|%s
|%s
|%s
|%s
|%s
}}""" % (
            combine(tnom, "ше́сть"),
            combine(tgen, "шести́"),
            combine(tdat, "шести́"),
            combine(tacc, "ше́сть"),
            combine(tins, "шестью́"),
            combine(tpre, "шести́"),
        )
    elif ones == 7:
        return """{{ru-decl-noun-unc
|%s
|%s
|%s
|%s
|%s
|%s
}}""" % (
            combine(tnom, "се́мь"),
            combine(tgen, "семи́"),
            combine(tdat, "семи́"),
            combine(tacc, "се́мь"),
            combine(tins, "семью́"),
            combine(tpre, "семи́"),
        )
    elif ones == 8:
        return """{{ru-decl-noun-unc
|%s
|%s
|%s
|%s
|%s
|%s
}}""" % (
            combine(tnom, "во́семь"),
            combine(tgen, "восьми́"),
            combine(tdat, "восьми́"),
            combine(tacc, "во́семь"),
            combine(tins, ["восемью́", "восьмью́"]),
            combine(tpre, "восьми́"),
        )
    elif ones == 9:
        return """{{ru-decl-noun-unc
|%s
|%s
|%s
|%s
|%s
|%s
}}""" % (
            combine(tnom, "де́вять"),
            combine(tgen, "девяти́"),
            combine(tdat, "девяти́"),
            combine(tacc, "де́вять"),
            combine(tins, "девятью́"),
            combine(tpre, "девяти́"),
        )


def generate_pron(num):
    tens = (num / 10) * 10
    ones = num % 10
    ones_pron = cardinal_ones[ones]
    if ones == 4:
        ones_pron = "четы́ре|pos=num"
    if tens in [20, 30, 40, 90]:
        return "* {{ru-IPA|%s %s}}" % (cardinal_tens[tens], ones_pron)
    if tens == 50:
        return """* {{ru-IPA|пятьдеся́т %s|gem=opt}}
* {{i|colloquial or fast speech}} {{ru-IPA|phon=пееся́т %s}}""" % (
            ones_pron,
            ones_pron,
        )
    if tens == 60:
        return """* {{ru-IPA|шестьдеся́т %s}}
* {{i|colloquial or fast speech}} {{ru-IPA|phon=шееся́т %s}}""" % (
            ones_pron,
            ones_pron,
        )
    if tens == 70:
        return """* {{ru-IPA|се́мьдесят %s}}
* {{ru-IPA|phon=се́мдесят %s}}""" % (
            ones_pron,
            ones_pron,
        )
    if tens == 80:
        return """* {{ru-IPA|во́семьдесят %s}}
* {{ru-IPA|phon=во́семдесят %s}}""" % (
            ones_pron,
            ones_pron,
        )
    raise ValueError("Unrecognized tens: %s" % tens)


def generate_usage(num):
    tens = (num / 10) * 10
    tnom, tgen, tdat, tacc, tins, tpre = cardinal_ten_decls[tens]
    if type(tins) is list:
        tins = "/".join(tins)
    ones = num % 10

    if ones == 1:
        return """* '''{tnom} оди́н''' governs the singular of the noun in the appropriate case, exactly as if it were an adjective.
:* {{{{uxi|ru|[[здесь|Здесь]] '''{tnom} оди́н''' [[ру́сский]] [[ма́льчик]].|Here are '''{eng}''' Russian boys.}}}}
:* {{{{uxi|ru|[[здесь|Здесь]] '''{tnom} одна́''' [[большой|больша́я]] [[кни́га]].|Here are '''{eng}''' large books.}}}}
:* {{{{uxi|ru|[[здесь|Здесь]] '''{tnom} одно́''' [[маленький|ма́ленькое]] [[окно́]].|Here are '''{eng}''' small windows.}}}}
:* {{{{uxi|ru|[[я|Я]] [[видеть|ви́жу]] '''{tacc} одного́''' [[русский|ру́сского]] [[мальчик|ма́льчика]].|I see '''{eng}''' Russian boys.}}}}
:* {{{{uxi|ru|[[я|Я]] [[видеть|ви́жу]] '''{tacc} одну́''' [[большой|большу́ю]] [[книга|кни́гу]].|I see '''{eng}''' large books.}}}}
:* {{{{uxi|ru|[[я|Я]] [[видеть|ви́жу]] '''{tacc} одно́''' [[маленький|ма́ленькое]] [[окно́]].|I see '''{eng}''' small windows.}}}}
:* {{{{uxi|ru|[[учи́тель]] '''{tgen} одно́й''' [[русский|ру́сской]] [[де́вушка|де́вушки]]|the teacher of the '''{eng}''' Russian girls}}}}
:* {{{{uxi|ru|[[с]] '''{tins} одни́м''' [[русский|ру́сским]] [[мальчик|ма́льчиком]]|with '''{eng}''' Russian boys}}}}
:* {{{{uxi|ru|[[говорить|Говорю́]] [[о]] '''{tpre} одно́м''' [[русский|ру́сском]] [[мальчик|ма́льчике]].|I am speaking about '''{eng}''' Russian boys.}}}}
* With pluralia tantum nouns, the plural forms of '''{tnom} оди́н''' are used.
:* {{{{uxi|ru|[[здесь|Здесь]] '''{tnom} одни́''' [[большой|больши́е]] [[но́жницы]].|Here are '''{eng}''' large scissors.}}}}
:* {{{{uxi|ru|[[я|Я]] [[видеть|ви́жу]] '''{tacc} одни́''' [[большой|больши́е]] [[но́жницы]].|I see '''{eng}''' large scissors.}}}}
:* {{{{uxi|ru|[[владе́лец]] '''{tgen} одни́х''' [[большой|больши́х]] [[ножницы|но́жниц]]|the owner of the '''{eng}''' large scissors}}}}
:* {{{{uxi|ru|[[с]] '''{tins} одни́ми''' [[большой|больши́ми]] [[ножницы|но́жницами]]|with '''{eng}''' large scissors}}}}
:* {{{{uxi|ru|[[говорить|Говорю́]] [[о]] '''{tpre} одни́х''' [[большой|больши́х]] [[ножницы|но́жницах]].|I am speaking about '''{eng}''' large scissors.}}}}""".format(
            tnom=tnom, tgen=tgen, tdat=tdat, tacc=tacc, tins=tins, tpre=tpre, eng=en_num(num)
        )
    onom_m, onom_f, ogen, odat, oins, opre = cardinal_one_decls[ones]
    if type(oins) is list:
        oins = "/".join(oins)

    if ones in [2, 3, 4]:
        return """* '''{tnom} {onom_m}''' in the nominative and accusative case governs the genitive singular of the noun, although modifying adjectives are in the genitive plural (or alternatively and preferably, for feminine nouns, in the nominative plural). Unlike with bare {{{{m|ru|{onom_m}}}}}, there is no animate/inanimate distinction.
:* {{{{uxi|ru|[[здесь|Здесь]] '''{tnom} {onom_m}''' [[русский|ру́сских]] [[мальчик|ма́льчика]].|Here are '''{eng}''' Russian boys.}}}}
:* {{{{uxi|ru|[[здесь|Здесь]] '''{tnom} {onom_f}''' [[большой|больши́е]]/[[большой|больши́х]] [[книга|кни́ги]].|Here are '''{eng}''' large books.}}}}
:* {{{{uxi|ru|[[я|Я]] [[видеть|ви́жу]] '''{tacc} {onom_m}''' [[русский|ру́сских]] [[мальчик|ма́льчика]].|I see '''{eng}''' Russian boys.}}}}
:* {{{{uxi|ru|[[я|Я]] [[видеть|ви́жу]] '''{tacc} {onom_f}''' [[большой|больши́е]]/[[большой|больши́х]] [[книга|кни́ги]].|I see '''{eng}''' large books.}}}}
* '''{tnom} {onom_m}''' in other cases governs the appropriate plural case of the noun, with adjectives agreeing appropriately.
:* {{{{uxi|ru|[[учи́тель]] '''{tgen} {ogen}''' [[русский|ру́сских]] [[мальчик|ма́льчиков]]|the teacher of the '''{eng}''' Russian boys}}}}
:* {{{{uxi|ru|[[с]] '''{tins} {oins}''' [[русский|ру́сскими]] [[мальчик|ма́льчиками]]|with '''{eng}''' Russian boys}}}}
:* {{{{uxi|ru|[[говорить|Говорю́]] [[о]] '''{tpre} {opre}''' [[русский|ру́сских]] [[мальчик|ма́льчиках]].|I am speaking about '''{eng}''' Russian boys.}}}}""".format(
            tnom=tnom,
            tgen=tgen,
            tdat=tdat,
            tacc=tacc,
            tins=tins,
            tpre=tpre,
            onom_m=onom_m,
            onom_f=onom_f,
            ogen=ogen,
            odat=odat,
            oins=oins,
            opre=opre,
            eng=en_num(num),
        )
    if ones in [5, 6, 7, 8, 9]:
        return """* '''{tnom} {onom_m}''' in the nominative and accusative case governs the genitive plural of the noun. There is no animate/inanimate distinction.
:* {{{{uxi|ru|[[здесь|Здесь]] '''{tnom} {onom_m}''' [[русский|ру́сских]] [[мальчик|ма́льчиков]].|Here are '''{eng}''' Russian boys.}}}}
:* {{{{uxi|ru|[[здесь|Здесь]] '''{tnom} {onom_f}''' [[большой|больши́х]] [[книга|кни́г]].|Here are '''{eng}''' large books.}}}}
:* {{{{uxi|ru|[[я|Я]] [[видеть|ви́жу]] '''{tacc} {onom_m}''' [[русский|ру́сских]] [[мальчик|ма́льчиков]].|I see '''{eng}''' Russian boys.}}}}
:* {{{{uxi|ru|[[я|Я]] [[видеть|ви́жу]] '''{tacc} {onom_f}''' [[большой|больши́х]] [[книга|кни́г]].|I see '''{eng}''' large books.}}}}
* '''{tnom} {onom_m}''' in other cases governs the appropriate plural case of the noun.
:* {{{{uxi|ru|[[учи́тель]] '''{tgen} {ogen}''' [[русский|ру́сских]] [[мальчик|ма́льчиков]]|the teacher of the '''{eng}''' Russian boys}}}}
:* {{{{uxi|ru|[[с]] '''{tins} {oins}''' [[русский|ру́сскими]] [[мальчик|ма́льчиками]]|with '''{eng}''' Russian boys}}}}
:* {{{{uxi|ru|[[говорить|Говорю́]] [[о]] '''{tpre} {opre}''' [[русский|ру́сских]] [[мальчик|ма́льчиках]].|I am speaking about '''{eng}''' Russian boys.}}}}""".format(
            tnom=tnom,
            tgen=tgen,
            tdat=tdat,
            tacc=tacc,
            tins=tins,
            tpre=tpre,
            onom_m=onom_m,
            onom_f=onom_f,
            ogen=ogen,
            odat=odat,
            oins=oins,
            opre=opre,
            eng=en_num(num),
        )
    raise ValueError("Unknown ones: %s" % ones)


def generate_page(num):
    prevnum = num - 1
    nextnum = num + 1
    tens = (num / 10) * 10
    ones = num % 10
    return """==Russian==
{{cardinalbox|ru|%s|%s|%s|%s|%s|ord=%s|alt=%s}}

===Pronunciation===
%s

===Numeral===
{{head|ru|numeral|head=[[%s]] [[%s]]}}

# [[%s]] (%s)

====Usage notes====
%s

====Declension====
%s

====Coordinate terms====
{{ru-cardinals}}

{{cln|ru|cardinal numbers}}

""" % (
        prevnum,
        num,
        nextnum,
        ru_num(prevnum),
        ru_num(nextnum),
        "%s %s" % (cardinal_tens[tens], ordinals[ones]),
        ru_num(num),
        generate_pron(num),
        cardinal_tens[tens],
        cardinal_ones[ones],
        en_num(num),
        num,
        generate_usage(num),
        generate_decl(num),
    )


def process_text_on_page(p):
    comment = None
    notes = []

    num = lemmas_to_numbers.get(p.title, None)
    if num is None:
        p.msg("WARNING: Page title doesn't look like a numeral, skipping")
        return
    lemma = ru_num(num)
    newtext = generate_page(num)

    # Pass None for p.msg to suppress warning on lang section not found.
    modsec = blib.find_modifiable_lang_section(p.text, "Russian", None, force_final_nls=True)
    if modsec is None:
        return blib.add_new_l2_section(p.text, p.msg, "Russian", newtext)
    secbody = modsec.secbody
    if args.overwrite_page:
        if "==Etymology 1==" in secbody and not args.overwrite_etymologies:
            p.errandmsg("WARNING: Found ==Etymology 1== in page text, not overwriting, skipping form")
            return
        else:
            p.msg("WARNING: Overwriting entire Russian section")
            notes.append("create Russian section for numeral %s (%s), overwriting section" % (lemma, num))
            stripped_secbody = secbody.rstrip("\n")
            stripped_newtext = newtext.rstrip("\n")
            if stripped_secbody == stripped_newtext:
                p.msg("No change in p.text")
            elif args.verbose:
                p.msg("Replacing <%s> with <%s>" % (stripped_secbody, stripped_newtext))
            return modsec.rebuild(secbody=newtext), notes
    else:
        p.errandmsg("WARNING: Not overwriting existing Russian section")
        return

parser = blib.create_argparser("Save Russian numbers to Wiktionary", include_pagefile=True, include_stdin=True)
parser.add_argument("--offline", help="Operate offline, outputting text of new pages", action="store_true")
parser.add_argument(
    "--overwrite-page",
    action="store_true",
    help="""If specified, overwrite the entire existing page of inflections.
Won't do this if it finds "Etymology N", unless --overwrite-etymologies is
given. WARNING: Be careful!""",
)
parser.add_argument(
    "--overwrite-etymologies",
    action="store_true",
    help="""If specified and --overwrite-page, overwrite the entire existing
page of inflections even if "Etymology N". WARNING: Be careful!""",
)
parser.add_argument("--numerals", help="""Comma-separated and/or hyphen-separated list of numerals to process.""")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)


def iter_numerals():
    for ten in sorted(cardinal_tens.keys())[:-1]:  # Skip 100
        for one in sorted(cardinal_ones.keys())[1:]:  # Skip 0
            yield ten + one


def iter_specified_numerals(spec):
    for singlespec in re.split(",", spec):
        if "-" in singlespec:
            fro, to = re.split("-", singlespec)
            for num in range(int(fro), int(to) + 1):
                yield num
        else:
            yield int(singlespec)


if args.numerals:
    pages = iter_specified_numerals(args.numerals)
else:
    pages = iter_numerals()

if args.offline:
    for index, current in blib.iter_items(pages, start, end, get_name=lambda x: str(x)):
        print("========== Text for #%s: ==========" % current)
        print("")
        print(generate_page(current))
        print("")
else:
    lemmas_to_numbers = {rulib.remove_accents(ru_num(num)): num for num in iter_numerals()}
    blib.do_pagefile_cats_refs(
        args, start, end, process_text_on_page, new=True, default_pages=list(lemmas_to_numbers.values())
    )
