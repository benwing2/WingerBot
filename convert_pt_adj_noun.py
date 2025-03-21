#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import pywikibot, re, sys, argparse
import romance_utils

import blib
from blib import getparam, rmparam, tname, pname, msg, site

unaccented_vowel = "aeiouà"
accented_vowel = "áéíóúýâêô"
maybe_accented_vowel = "ãõ"
vowel = unaccented_vowel + accented_vowel + maybe_accented_vowel
V = "[" + vowel + "]"
AV = "[" + accented_vowel + "]"
NAV = "[^" + accented_vowel + "]"
C = "[^" + vowel + ".]"
remove_accent = {"á": "a", "é": "e", "í": "i", "ó": "o", "ú": "u", "ý": "y", "â": "a", "ê": "e", "ô": "o"}

prepositions = [
  # a + optional article
  "a ",
  "às? ",
  "aos? ",
  # de + optional article
  "de ",
  "d[oa]s? ",
  # em + optional article
  "em ",
  "n[oa]s? ",
  # por + optional article
  "por ",
  "pel[oa]s? ",
  # others
  "até ",
  "com ",
  "como ",
  "entre ",
  "para ",
  "sem ",
  "sob ",
  "sobre ",
]

TEMPCHAR = "\uFFF1"

def get_old_inflections(ending):
  if ending == "a":
    return "a", "a", "as", "as", "", "", ("dim_a", "")
  if ending == "ca":
    return "ca", "ca", "cas", "cas", "qu", "c", "qu"
  if ending == "e":
    return "e", "e", "es", "es", "", "", ""
  if ending == "l":
    return "l", "l", "is", "is", "l", "l", "l"
  if ending == "m":
    return "m", "m", "ns", "ns", "m", "m", "m"
  if ending == "z":
    return "z", "z", "zes", "zes", "c", "z", "z"
  if ending == "al":
    return "al", "al", "ais", "ais", "al", "al", "al"
  if ending == "ável":
    return "ável", "ável", "áveis", "áveis", "abil", "abil", "abil"
  if ending == "ímico":
    return "ímico", "ímica", "ímicos", "ímicas", "qu", "c", "qu"
  if ending == "ível":
    return "ível", "ível", "íveis", "íveis", "ibil", "ibil", "ibil"
  if ending == "incrível":
    return "incrível", "incrível", "incríveis", "incríveis", "incredibil", "incredibil", "incredibil"
  if ending == "il":
    return "il", "il", "is", "is", "il", "il", "il"
  if ending == "ágico":
    return "ágico", "ágica", "ágicos", "ágicas", "agiqu", "agic", "agiqu"
  if ending == "ágil":
    return "ágil", "ágil", "ágeis", "ágeis", "agil", "agil", "agil"
  if ending == "ão":
    return "ão", "ona", "ões", "onas", "on", "on", "on"
  if ending == "o":
    return "o", "a", "os", "as", "", "", ""
  if ending == "co":
    return "co", "ca", "cos", "cas", "qu", "c", "qu"
  if ending == "co2":
    return "co", "ca", "cos", "cas", ["c", "qu"], "c", "qu"
  if ending == "ógico":
    return "ógico", "ógica", "ógicos", "ógicas", "ogiqu", "ogic", "ogiqu"
  if ending == "ítmico":
    return "ítmico", "ítmica", "ítmicos", "ítmicas", "itmiqu", "itmic", "itmiqu"
  if ending == "áfico":
    return "áfico", "áfica", "áficos", "áficas", "afic", "afic", "afic"
  if ending == "ático":
    return "ático", "ática", "áticos", "áticas", "atic", "atic", "atic"
  if ending == "ático2":
    return "ático", "ática", "áticos", "áticas", ["atic", "atiqu"], "atic", "atic"
  if ending == "ítico":
    return "ítico", "ítica", "íticos", "íticas", "itic", "itic", "itic"
  if ending == "ótico":
    return "ótico", "ótica", "óticos", "óticas", "otic", "otic", "otic"
  if ending == "ástico":
    return "ástico", "ástica", "ásticos", "ásticas", "astiqu", "astic", "astiqu"
  if ending == "ácido":
    return "ácido", "ácida", "ácidos", "ácidas", "acid", "acid", "acid"
  if ending == "tímido":
    return "tímido", "tímida", "tímidos", "tímidas", "timid", "timid", "timid"
  if ending == "ítido":
    return "ítido", "ítida", "ítidos", "ítidas", "itid", "itid", "itid"
  if ending == "go":
    return "go", "ga", "gos", "gas", "gu", "g", "gu"
  if ending == "ério":
    return "ério", "éria", "érios", "érias", ["er", "eri"], ("mf", "erioz", "eriaz"), ("mf", "erioz", "eriaz")
  if ending == "frio":
    return "frio", "fria", "frios", "frias", ["fri", "frigid"], "fri", ["frioz", "fri"]
  if ending == "r":
    return "r", "r", "res", "res", "r", "r", "r"
  if ending == "ar":
    return "ar", "ar", "ares", "ares", "ar", "ar", "ar"
  if ending == "or":
    return "or", "ora", "ores", "oras", "or", "or", "or"
  if ending == "ôr":
    return "ôr", "ôra", "ôres", "ôras", "ôr", "ôr", "ôr"
  if ending == "ês":
    return "ês", "esa", "eses", "esas", "es", "es", "es"
  if ending == "eu":
    return "eu", "eia", "eus", "eias", "euz", "euz", "euz"
  if ending == "ez":
    return "ez", "eza", "ezes", "ezas", "ez", "ez", "ez"
  return None, None, None, None, None, None, None

# Generate a default plural form, which is correct for most regular nouns and adjectives.
def make_plural(form, new_algorithm, special=None):
  retval = romance_utils.handle_multiword(form, special, lambda form: make_plural(form, new_algorithm), prepositions)
  if retval:
    assert len(retval) == 1
    return retval[0]
  if special:
    return None

  formarr = [form]
  def check(fr, to):
    newform = re.sub(fr, to, formarr[0])
    if newform != formarr[0]:
      formarr[0] = newform
      return True
    return False

  # This is ported from the former [[Module:pt-plural]] except that the old code sometimes returned nil (final -ão
  # other than -ção and -são, final consonant other than [lrmzs]), whereas we always return a default plural
  # (all -ão -> ões, all final consonants other than [lrmzs] are left unchanged).
  if not new_algorithm and re.search("([^çs]ão|[^ç]aõ|[^" + vowel + "lrmzs])$", formarr[0]):
    return None
  (
  check("ão$", "ões") or
  check("aõ$", "oens") or
  check("(" + AV + ".*)[ei]l$", r"\1eis") or # final unstressed -el or -il
  check("el$", "éis") or # final stressed -el
  check("il$", "is") or # final stressed -il
  check("(" + AV + ".*)ol$", r"\1ois") or # final unstressed -ol
  check("ol$", "óis") or # final stressed -ol
  check("(" + V + ")l$", r"\1is") or # any other vowel + -l
  check("m$", "ns") or # final -m
  check("([rz])$", r"\1es") or # final -r or -z
  check("(" + V + ")$", r"\1s") or # final vowel
  check("(" + AV + ")s$", lambda m: remove_accent.get(m.group(1), m.group(1)) + "ses") or # final -ês, -ós etc.
  check("^(" + NAV + "*" + C + "[ui]s)$", r"\1es") # final stressed -us or -is after consonant
  )

  return formarr[0]

# Generate a default feminine form.
def make_feminine(form, special=None):
  retval = romance_utils.handle_multiword(form, special, make_feminine, prepositions)
  if retval:
    assert len(retval) == 1
    return retval[0]
  if special:
    return None

  formarr = [form]
  def check(fr, to):
    newform = re.sub(fr, to, formarr[0])
    if newform != formarr[0]:
      formarr[0] = newform
      return True
    return False

  (
  # Exceptions: [[afegão]] (afegã), [[alazão]] (alazã), [[alemão]] (alemã), [[ancião]] (anciã),
  #             [[anglo-saxão]] (anglo-saxã), [[beirão]] (beirã/beiroa), [[bretão]] (bretã), [[cão]] (cã),
  #             [[castelão]] (castelã/castelona[rare]/casteloa[rare]), [[catalão]] (catalã), [[chão]] (chã),
  #             [[cristão]] (cristã), [[fodão]] (fodão since from [[foda]]), [[grão]] (grã), [[lapão]] (lapoa),
  #             [[letão]] (letã), [[meão]] (meã), [[órfão]] (órfã), [[padrão]] (padrão), [[pagão]] (pagã),
  #             [[paleocristão]] (paleocristã), [[parmesão]] (parmesã), [[romão]] (romã), [[são]] (sã),
  #             [[saxão]] (saxã), [[temporão]] (temporã), [[teutão]] (teutona/teutã/teutoa), [[vão]] (vã),
  #             [[varão]] (varoa), [[verde-limão]] (invariable), [[vilão]] (vilã/viloa)
  check("ão$", "ona") or
  check("o$", "a") or
  # [[francês]], [[português]], [[inglês]], [[holandês]] etc.
  check("ês$", "esa") or
  # [[francez]], [[portuguez]], [[inglez]], [[holandez]] (archaic)
  check("ez$", "eza") or
  # adjectives in:
  # * [[-ador]], [[-edor]] ([[amortecedor]], [[comovedor]], etc.), [[-idor]] ([[inibidor]], etc.)
  # * -tor ([[condutor]], [[construtor]], [[coletor]], etc.)
  # * -sor ([[admissor]], [[censor]], [[decisor]], etc.)
  # but not:
  # * [[anterior]]/[[posterior]]/[[inferior]]/[[maior]]/[[pior]]/[[melhor]]
  # * [[bicolor]]/[[incolor]]/[[multicolor]]/etc., [[indolor]], etc.
  check("([dts][oô]r)$", r"\1a") or
  # [[amebeu]], [[aqueu]], [[aquileu]], [[arameu]], [[cananeu]], [[cireneu]], [[egeu]], [[eritreu]],
  # [[europeu]], [[galileu]], [[indo-europeu]]/[[indoeuropeu]], [[macabeu]], [[mandeu]], [[pigmeu]],
  # [[proto-indo-europeu]]
  # Exceptions: [[judeu]] (judia), [[sandeu]] (sandia)
  check("eu$", "eia")
  )

  # note: [[espanhol]] (espanhola), but this is the only case in ''-ol'' (vs. [[bemol]], [[mongol]] with no
  # change in the feminine)
  return formarr[0]

def make_masculine(form, special=None):
  retval = romance_utils.handle_multiword(form, special, make_masculine, prepositions)
  if retval:
    assert len(retval) == 1
    return retval[0]
  if special:
    return None

  formarr = [form]
  def check(fr, to):
    newform = re.sub(fr, to, formarr[0])
    if newform != formarr[0]:
      formarr[0] = newform
      return True
    return False

  (
  check("([dts])ora$", r"\1or") or
  check("a$", "o")
  )

  return formarr[0]

def munge_form_for_ending(form, typ):
  formarr = [form]
  def check(fr, to):
    newform = re.sub(fr, to, formarr[0])
    if newform != formarr[0]:
      formarr[0] = newform
      return True
    return False

  (
  check("ão$", "on") or
  typ != "aug" and check("c[oa]$", "qu") or
  typ != "aug" and check("g[oa]$", "gu") or
  check("[oae]$", "") or
  typ == "sup" and check("z$", "c") or
  # Adverb stems won't have the acute accent but we should handle them correctly regardless.
  check("[áa]vel$", "abil") or
  check("[íi]vel$", "ibil") or
  check("eu$", "euz")
  )

  # Remove accent (-ês, -ário, -ático, etc.) when adding ending.
  return re.sub("(" + AV + ")(.*?)$", lambda m: remove_accent.get(m.group(1), m.group(1)) + m.group(2), formarr[0])

# Generate a default absolute superlative form.
def make_absolute_superlative(form, special=None):
  retval = romance_utils.handle_multiword(form, special, make_absolute_superlative, prepositions)
  if retval:
    assert len(retval) == 1
    return retval[0]
  if special:
    return None

  return munge_form_for_ending(form, "sup") + "íssimo"

# Generate a default adverbial absolute superlative form.
def make_adverbial_absolute_superlative(form, special=None):
  retval = romance_utils.handle_multiword(form, special, make_adverbial_absolute_superlative, prepositions)
  if retval:
    assert len(retval) == 1
    return retval[0]
  if special:
    return None

  return munge_form_for_ending(form, "sup") + "issimamente"

# Generate a default diminutive form.
def make_diminutive(form, special=None):
  retval = romance_utils.handle_multiword(form, special, make_diminutive, prepositions)
  if retval:
    assert len(retval) == 1
    return retval[0]
  if special:
    return None

  return munge_form_for_ending(form, "dim") + "inho"

# Generate a default augmentative form.
def make_augmentative(form, special=None):
  retval = romance_utils.handle_multiword(form, special, make_augmentative, prepositions)
  if retval:
    assert len(retval) == 1
    return retval[0]
  if special:
    return None

  return munge_form_for_ending(form, "aug") + "ão"

def process_text_on_page(index, pagetitle, text):
  global args
  def pagemsg(txt):
    msg("Page %s %s: %s" % (index, pagetitle, txt))

  notes = []

  if "pt-adj" not in text and "pt-noun" not in text:
    return

  if ":" in pagetitle:
    pagemsg("Skipping non-mainspace title")
    return

  pagemsg("Processing")

  parsed = blib.parse_text(text)

  def do_make_plural(form, special=None):
    retval = make_plural(form, "new algorithm", special)
    if retval is None:
      return []
    return [retval]

  adj_headword = None
  adj_infl_templates_to_remove = []

  for t in parsed.filter_templates():
    tn = tname(t)
    def getp(param):
      return getparam(t, param)


    ############# Convert old-style noun headwords

    if tn == "pt-noun" and (args.do_nouns or args.do_old_nouns and getp("old")):
      subnotes = []
      origt = str(t)

      head = getp("head")
      lemma = blib.remove_links(head or pagetitle)

      def replace_lemma_with_hash(term):
        if term.startswith(lemma):
          replaced_term = "#" + term[len(lemma):]
          subnotes.append("replace lemma-containing term '%s' with '%s'" % (term, replaced_term))
          term = replaced_term
        return term

      def warn_when_exiting(txt):
        pagemsg("WARNING: %s: %s" % (txt, str(t)))
        if args.add_old:
          notes.append("add old=1 to {{pt-noun}} where a warning will be issued")
          t.add("old", "1")

      autohead = romance_utils.add_links_to_multiword_term(lemma, splithyph=False)
      if autohead == head:
        pagemsg("Remove redundant head %s" % head)
        subnotes.append("remove redundant head '%s'" % head)
        head = None

      meta = getp("meta")
      unc = getp("unc")

      g = getp("1")
      g2 = getp("g2")
      g_qual = getp("qual_g1")
      g2_qual = getp("qual_g2")

      if not g:
        warn_when_exiting("No gender, can't convert")
        continue

      def convert_g(g):
        if g in ["mf", "m-f"]:
          g = "mfbysense"
        elif g == "morf":
          g = "mf"
        return g

      g = convert_g(g)
      g2 = convert_g(g2)
      if not g_qual and not g2_qual and g == "m" and g2 == "f":
        g = "mf"
        g2 = None

      is_plural = g.endswith("-p") or (g2 and g2.endswith("-p"))

      if is_plural and (not g.endswith("-p") or (g2 and not g2.endswith("-p"))):
        warn_when_exiting("Both singular and plural, can't convert")
        continue

      if not is_plural:
        pl = getp("2") or getp("pl") or getp("plural")
        orig_pl = pl
        if not pl:
          old_defpl = make_plural(lemma, False)
          if old_defpl is None:
            warn_when_exiting("No plurals and can't generate default plural, skipping")
            continue
          pl = old_defpl
        pl_qual = getp("qual_pl")
        pl2 = getp("pl2")
        pl2_qual = getp("qual_pl2")
        pl3 = getp("pl3")
        pl3_qual = getp("qual_pl3")
        if not pl2 and pl3:
          warn_when_exiting("Saw gap in plurals, can't handle, skipping")
          continue
        if not pl2 and pl2_qual:
          warn_when_exiting("No value for pl2= but saw qual_pl2=%s, skipping")
          continue
        if not pl3 and pl3_qual:
          warn_when_exiting("No value for pl3= but saw qual_pl3=%s, skipping")
          continue

        pls = [pl, pl2, pl3]
        pls = [x for x in pls if x]
        orig_pls = [orig_pl, pl2, pl3]
        orig_pls = [x for x in orig_pls if x]
        pls = [lemma + x if x in ["s", "es"] else x for x in pls]
        pl_quals = [pl_qual, pl2_qual, pl3_qual]

        if unc:
          pls = ["-"] + pls
          pl_quals = [""] + pl_quals

        defpl = make_plural(lemma, True)
        if not defpl:
          continue
        pls_with_def = ["+" if pl == defpl else pl for pl in pls]

        actual_special = None
        for special in romance_utils.all_specials:
          special_pl = make_plural(lemma, True, special)
          if special_pl is None:
            continue
          if pls == [special_pl]:
            pagemsg("Found special=%s with special_pl=%s" % (special, special_pl))
            actual_special = special
            break

        if pls_with_def == ["+"]:
          if pl_quals[0]:
            if orig_pls:
              subnotes.append("replace plural '%s' (same as default) with '+' because qualifier '%s' present" %
                  (orig_pls[0], pl_quals[0]))
            else:
              subnotes.append("add plural '+' because qualifier '%s' present" % pl_quals[0])
            pls = pls_with_def
          else:
            if orig_pls:
              subnotes.append("remove redundant plural '%s'" % orig_pls[0])
            pls = []
        elif actual_special:
          if orig_pls:
            subnotes.append("replace plural '%s' with '+%s'" % (orig_pls[0], actual_special))
          else:
            subnotes.append("replace default plural '%s' with '+%s'" % (pls[0], actual_special))
          pls = ["+" + actual_special]
        elif pls_with_def != pls:
          # orig_pls should always have an entry and pls_with_def should have its length > 1
          subnotes.append("replace default plural '%s' with '+'" % defpl)
          pls = pls_with_def

        pls = [replace_lemma_with_hash(pl) for pl in pls]

      def handle_mf(g, g_full, make_mf):
        mf = getp(g)
        mf2 = getp(g + "2")
        mf_qual = getp("qual_" + g)
        mf2_qual = getp("qual_" + g + "2")
        if not mf and mf2:
          warn_when_exiting("Saw gap in %ss, can't handle, skipping" % g_full)
          return None
        if not g and mf_qual:
          warn_when_exiting("No value for %s= but saw qual_%s=%s, skipping" % (g, g, mf_qual))
          return None
        if not mf2 and mf2_qual:
          warn_when_exiting("No value for %s2= but saw qual_%s2=%s, skipping" % (g, g, mf2_qual))
          return None
        mfs = [mf, mf2]
        mfs = [mf for mf in mfs if mf]
        mf_quals = [mf_qual, mf2_qual]

        if not is_plural:
          mfpl = getp(g + "pl")
          mfpl2 = getp(g + "pl2")
          if not mfpl and mfpl2:
            warn_when_exiting("Saw gap in %s plurals, can't handle, skipping" % g_full)
            return None
          if getp("qual_" + g + "pl") or getp("qual_" + g + "pl2"):
            warn_when_exiting("Saw %s plural qualifier, can't handle, skipping" % g_full)
            return None
          mfpls = [mfpl, mfpl2]
          mfpls = [mfpl for mfpl in mfpls if mfpl]

        if mfs:
          defmf = make_mf(lemma)
          if mfs == [defmf]:
            if is_plural or (not mfpls or mfpls == [make_plural(defmf, True)]):
              subnotes.append("replace %s=%s with '+'" % (g, mfs[0]))
              return ["+"], mf_quals, []
          actual_special = None
          for special in romance_utils.all_specials:
            special_mf = make_mf(lemma, special)
            if special_mf is None:
              continue
            if mfs == [special_mf]:
              pagemsg("Found special=%s with special_mf=%s" % (special, special_mf))
              actual_special = special
              break
          if actual_special:
            if is_plural:
              pass
            elif not mfpls:
              pagemsg("WARNING: Explicit %s=%s matches special=%s but no %s plural, allowing" % (
                g, ",".join(mfs), actual_special, g_full))
            else:
              special_mfpl = make_plural(special_mf, True, actual_special)
              if special_mfpl:
                if mfpls == [special_mfpl]:
                  pagemsg("Found %s=%s and special=%s, %spls=%s matches special_%spl" % (
                    g, ",".join(mfs), actual_special, g, ",".join(mfpls), g))
                else:
                  pagemsg("WARNING: for %s=%s and special=%s, %spls=%s doesn't match special_%spl=%s, allowing" % (
                    g, ",".join(mfs), actual_special, g, ",".join(mfpls), g, special_mfpl))
                  actual_special = None
            if actual_special:
              subnotes.append("replace explicit %s '%s' with special indicator '+%s' and remove explicit %s plural" %
                  (g_full, ",".join(mfs), actual_special, g_full))
              mfs = ["+%s" % actual_special]
              mfpls = []
          if not actual_special:
            defmf = make_mf(lemma)
            mfs_with_def = ["+" if x == defmf else x for x in mfs]
            if mfs_with_def != mfs:
              subnotes.append("replace default %s '%s' with '+'" % (g_full, defmf))
              mfs = mfs_with_def
            if not is_plural and mfpls:
              defpl = [make_plural(x, True) for x in mfs]
              ok = False
              if set(defpl) == set(mfpls):
                ok = True
              elif len(defpl) > 1 and set(mfpls) < set(defpl):
                pagemsg("WARNING: for %s=%s, %spl=%s subset of default pl %s, allowing" % (
                  g, ",".join(mfs), g, ",".join(mfpls), ",".join(defpl)))
                ok = True
              if ok:
                pagemsg("Found %s=%s, %spl=%s matches default pl" % (g, ",".join(mfs), g, ",".join(mfpls)))
                subnotes.append("remove redundant explicit %s plural '%s'" % (g_full, ",".join(mfpls)))
                mfpls = []
              else:
                for special in romance_utils.all_specials:
                  defpl = [make_plural(x, True, special) for x in mfs]
                  if set(defpl) == set(mfpls):
                    pagemsg("Found %s=%s, %spl=%s matches special=%s" % (
                      g, ",".join(mfs), g, ",".join(mfpls), special))
                    subnotes.append("replace explicit %s plural '%s' with special indicator '+%s'" %
                        (g_full, ",".join(mfpls), special))
                    mfpls = ["+%s" % special]
        mfs = [replace_lemma_with_hash(mf) for mf in mfs]
        return mfs, mf_quals, mfpls if not is_plural else []

      retval = handle_mf("f", "feminine", make_feminine)
      if retval is None:
        continue
      fs, f_quals, fpls = retval
      retval = handle_mf("m", "masculine", make_masculine)
      if retval is None:
        continue
      ms, m_quals, mpls = retval

      must_continue = False
      for param in t.params:
        pn = pname(param)
        pv = str(param.value)
        if pn not in ["head", "1", "2", "f", "f2", "fpl", "fpl2", "g2", "meta", "pl", "pl2", "pl3", "plural",
            "qual_f", "qual_f2", "qual_g1", "qual_g2", "qual_pl", "qual_pl2", "qual_pl3", "unc",
            "m", "m2", "qual_m", "qual_m2", "old"]:
          warn_when_exiting("Saw unrecognized param %s=%s" % (pn, pv))
          must_continue = True
          break
      if must_continue:
        continue

      if args.add_old:
        realt = t
        t = list(blib.parse_text("{{pt-noun}}").filter_templates())[0]

      del t.params[:]
      t.add("1", g)
      if g_qual:
        t.add("g_qual", g_qual)
      if g2:
        t.add("g2", g2)
      if g2_qual:
        t.add("g2_qual", g2_qual)
      def add_vals_with_quals(vals, quals, prefix, first=None):
        first = first or prefix
        for i, val in enumerate(vals):
          if i == 0:
            param = first
          else:
            param = "%s%s" % (prefix, i + 1)
          t.add(param, val)
          if quals[i]:
            t.add("%s%s_qual" % (prefix, "" if i == 0 else str(i + 1)), quals[i])

      if not is_plural:
        add_vals_with_quals(pls, pl_quals, "pl", "2")
      add_vals_with_quals(fs, f_quals, "f")
      if not is_plural:
        add_vals_with_quals(fpls, [""] * len(fpls), "fpl")
      add_vals_with_quals(ms, m_quals, "m")
      if not is_plural:
        add_vals_with_quals(mpls, [""] * len(mpls), "mpl")

      if meta:
        t.add("meta", "1")

      if head:
        if head == lemma:
          t.add("nolinkhead", "1")
        else:
          t.add("head", head)

      if args.add_old:
        if origt != str(t):
          pagemsg("Replaced %s with %s" % (origt, str(t)))
          notes.append("add old=1 to {{pt-noun}} that will change with new syntax")
          realt.add("old", "1")
        else:
          pagemsg("No changes to %s" % str(realt))

      elif origt != str(t):
        pagemsg("Replaced %s with %s" % (origt, str(t)))
        notes.append("replace {{pt-noun}} with new syntax%s" %
            (" (%s)" % ", ".join(subnotes) if subnotes else ""))
      else:
        pagemsg("No changes to %s" % str(t))


    ############# Convert new-style noun headwords for hyphenated terms

    if tn == "pt-noun" and args.do_new_hyphenated_nouns:
      subnotes = []
      origt = str(t)

      head = getp("head")
      lemma = blib.remove_links(head or pagetitle)
      # Skip term if not hyphenated
      if not re.search(".-.", lemma):
        continue

      genders = blib.fetch_param_chain(t, "g")

      is_plural = any(g.endswith("-p") for g in genders)
      new_pls = None

      if not is_plural:
        pls = blib.fetch_param_chain(t, "2", "pl")
        new_pls = []
        for pl in pls:
          actual_special = None
          for special in romance_utils.all_specials:
            special_pl = make_plural(lemma, True, special)
            if special_pl is None:
              continue
            if pl == special_pl:
              pagemsg("Found special=%s with special_pl=%s" % (special, special_pl))
              actual_special = special
              break

          if actual_special:
            subnotes.append("replace plural '%s' with '+%s'" % (pl, actual_special))
            new_pls.append("+" + actual_special)
          else:
            new_pls.append(pl)

      def handle_mf(g, g_full, make_mf):
        mfs = blib.fetch_param_chain(t, g)

        if not is_plural:
          mfpls = blib.fetch_param_chain(t, g + "pl")

        new_mfs = None
        new_mfpls = None
        if mfs:
          new_mfs = []
          for mf in mfs:
            actual_special = None
            for special in romance_utils.all_specials:
              special_mf = make_mf(lemma, special)
              if special_mf is None:
                continue
              if mf == special_mf:
                pagemsg("Found special=%s with special_mf=%s" % (special, special_mf))
                actual_special = special
                break
            if actual_special:
              subnotes.append("replace %s '%s' with '+%s'" % (g_full, mf, actual_special))
              new_mfs.append("+" + actual_special)
            else:
              new_mfs.append(mf)

          if new_mfs != mfs and len(new_mfs) == 1 and actual_special:
              if is_plural:
                pass
              elif not mfpls:
                pagemsg("WARNING: Explicit %s=%s matches special=%s but no %s plural, allowing" % (
                  g, ",".join(new_mfs), actual_special, g_full))
              elif len(mfpls) > 1:
                pagemsg("WARNING: Explicit %s=%s matches special=%s and multiple %s plurals %s, allowing" % (
                  g, ",".join(new_mfs), actual_special, g_full, ",".join(mfpls)))
              else:
                special_mfpl = make_plural(special_mf, True, actual_special)
                if special_mfpl:
                  if mfpls[0] == special_mfpl:
                    pagemsg("Found %s=%s and special=%s, %spls=%s matches special_%spl" % (
                      g, ",".join(new_mfs), actual_special, g, ",".join(mfpls), g))
                  else:
                    pagemsg("WARNING: for %s=%s and special=%s, %spls=%s doesn't match special_%spl=%s, allowing" % (
                      g, ",".join(new_mfs), actual_special, g, ",".join(mfpls), g, special_mfpl))
                    actual_special = None
              if actual_special:
                subnotes.append("replace explicit %s '%s' with special indicator '+%s' and remove explicit %s plural" %
                    (g_full, ",".join(new_mfs), actual_special, g_full))
                new_mfpls = []
              else:
                new_mfpls = mfpls

        return new_mfs, new_mfpls if not is_plural else []

      retval = handle_mf("f", "feminine", make_feminine)
      if retval is None:
        continue
      fs, fpls = retval
      retval = handle_mf("m", "masculine", make_masculine)
      if retval is None:
        continue
      ms, mpls = retval

      must_continue = False

      if new_pls is not None:
        blib.set_param_chain(t, new_pls, "2", "pl")
      if fs is not None:
        blib.set_param_chain(t, fs, "f")
      if fpls is not None:
        blib.set_param_chain(t, fpls, "fpl")
      if ms is not None:
        blib.set_param_chain(t, ms, "m")
      if mpls is not None:
        blib.set_param_chain(t, mpls, "mpl")

      if origt != str(t):
        pagemsg("Replaced %s with %s" % (origt, str(t)))
        notes.append("replace hyphenated {{pt-noun}} with special indicator(s)%s" %
            (" (%s)" % ", ".join(subnotes) if subnotes else ""))
      else:
        pagemsg("No changes to %s" % str(t))


    ############# Convert old-style adjective headwords

    if tn == "pt-adj" and args.do_adjs:
      origt = str(t)
      if args.add_old:
        if not t.has("old") and not t.has("1") and not t.has("2"):
          # needs old=1
          t.add("old", "1")
          notes.append("add old=1 to old-style Portuguese adjective template not automatically identifiable as such")
          if origt != str(t):
            pagemsg("Replaced %s with %s" % (origt, str(t)))
        continue

      #if not getp("old") and not getp("1") and not getp("2"):
      #  # new-style
      #  continue
      base = getp("1")
      infl_type = getp("2")
      invariable = False
      if base == "-":
        invariable = True
      else:
        if not infl_type:
          lemma = pagetitle
          if not getp("f") and not getp("mpl") and not getp("pl") and not getp("fpl"):
            pagemsg("WARNING: Probable bad template invocation, no parameters: %s" % str(t))
            continue
          f = getp("f") or lemma
          mpl = (getp("mpl") if t.has("mpl") else getp("pl")) or lemma
          fpl = getp("fpl") or mpl
        else:
          _, f, mpl, fpl, _, _, _ = get_old_inflections(infl_type)
          f = base + f
          mpl = base + mpl
          fpl = base + fpl
          if f is None:
            pagemsg("WARNING: Unrecognized inflection type %s: %s" % (infl_type, str(t)))
            continue
          lemma = base + infl_type
          if lemma != pagetitle:
            pagemsg("WARNING: Saw lemma '%s' not equal to page title: %s" % (lemma, str(t)))

        deff = make_feminine(lemma)
        defmpl = do_make_plural(lemma)
        fs = []
        fullfs = []
        fullfs.append(f)
        if f == deff:
          f = "+"
        elif f == lemma:
          f = "#"
        fs.append(f)
        mpls = []
        mpls.append(mpl)
        fullmpls = mpls
        # should really check for subsequence but it never occurs
        if set(mpls) == set(defmpl):
          mpls = ["+"]
        elif set(mpls) < set(defmpl):
          pagemsg("WARNING: mpls=%s subset of defmpl=%s, replacing with default" % (",".join(mpls), ",".join(defmpl)))
          mpls = ["+"]
        mpls = ["#" if x == lemma else x for x in mpls]
        deffpl = [x for f in fullfs for x in do_make_plural(f)]
        fpls = []
        fpls.append(fpl)
        fullfpls = fpls
        # should really check for subsequence but it never occurs
        if set(fpls) == set(deffpl):
          fpls = ["+"]
        elif set(fpls) < set(deffpl):
          pagemsg("WARNING: fpls=%s subset of deffpl=%s, replacing with default" % (",".join(fpls), ",".join(deffpl)))
          fpls = ["+"]
        fpls = ["#" if x == lemma else x for x in fpls]
        actual_special = None
        for special in romance_utils.all_specials:
          deff = make_feminine(lemma, special)
          if deff is None:
            continue
          defmpl = do_make_plural(lemma, special)
          deffpl = do_make_plural(deff, special)
          deff = [deff]
          if fullfs == deff and fullmpls == defmpl and fullfpls == deffpl:
            actual_special = special
            break

      head = getp("head")
      comp = getp("comp")

      must_continue = False
      for param in t.params:
        pn = pname(param)
        pv = str(param.value)
        if pn not in ["head", "1", "2", "f", "mpl", "pl", "fpl", "comp", "old"]:
          pagemsg("WARNING: Saw unrecognized param %s=%s in %s" % (pn, pv, str(t)))
          must_continue = True
          break
      if must_continue:
        continue
      if comp and comp not in ["yes", "no", "both"]:
        pagemsg("WARNING: Saw unrecognized value '%s' for comp=: %s" % (comp, str(t)))
        continue

      del t.params[:]
      if head:
        t.add("head", head)
      if invariable or fullfs == [lemma] and fullmpls == [lemma] and fullfpls == [lemma]:
        t.add("inv", "1")
      else:
        if actual_special:
          t.add("sp", actual_special)
        else:
          if fs != ["+"]:
            blib.set_param_chain(t, fs, "f")

          if mpls == fpls and ("+" not in mpls or defmpl == deffpl):
            # masc and fem pl the same
            if mpls != ["+"]:
              blib.set_param_chain(t, mpls, "pl")
          else:
            if mpls != ["+"]:
              blib.set_param_chain(t, mpls, "mpl")
            if fpls != ["+"]:
              blib.set_param_chain(t, fpls, "fpl")
      if comp:
        t.add("hascomp", comp)

      if origt != str(t):
        pagemsg("Replaced %s with %s" % (origt, str(t)))
        notes.append("convert {{pt-adj}} to new syntax")
      else:
        pagemsg("No changes to %s" % str(t))


    ############# Convert new-style adjective headwords with inflections

    if args.do_new_adjs_with_inflections:
      if tn == "pt-adj":
        if adj_headword:
          pagemsg("Saw adjective headword without intervening inflection; first=%s, second=%s" % (
            str(adj_headword), str(t)))
        adj_headword = t
      if tn == "pt-adj-infl":
        if not adj_headword:
          pagemsg("WARNING: Saw adjective inflection template %s without previous adjective headword" %
            str(t))
          continue
        orig_adj_headword = str(adj_headword)
        head = getparam(adj_headword, "head")
        headword_lemma = blib.remove_links(head or pagetitle)
        infl_base = getp("1")
        infl_type = getp("2")
        infl_lemma = infl_base + (infl_type[:-1] if infl_type in ["co2", "ático2"] else infl_type)
        if infl_lemma != headword_lemma:
          pagemsg("WARNING: Inflection lemma %s not same as headword lemma %s: adj_headword=%s, infl=%s" % (
            infl_lemma, headword_lemma, str(adj_headword), str(t)))
          continue
        has_dim = getp("dim") and getp("dim") != "0"
        has_aug = getp("aug") and getp("aug") != "0"
        _, _, _, _, sups, augs, dims = get_old_inflections(infl_type)
        if type(sups) is not list:
          sups = [sups]
        if type(dims) is not list:
          dims = [dims]
        if type(augs) is not list:
          augs = [augs]

        def add_ending(engtype, stems, ending, f_ending):
          retvals = []
          for stem in stems:
            if type(stem) is tuple:
              if stem[0] == "dim_a":
                _, f_stem = stem
                retval = infl_base + f_stem + f_ending
              else:
                assert stem[0] == "mf"
                _, m_stem, f_stem = stem
                retval = infl_base + m_stem + ending
                pagemsg("WARNING: For %s, separate feminine %s" % (engtype, infl_base + f_stem + f_ending))
            else:
              retval = infl_base + stem + ending
            retvals.append(retval)
          return retvals

        supvals = add_ending("superlative", sups, "íssimo", "íssima")
        defsup = make_absolute_superlative(headword_lemma)
        supvals = ["+abs" if sup == defsup else sup for sup in supvals]
        notes.append("add superlative(s) '%s' to {{pt-adj}}" % ",".join(supvals))
        blib.set_param_chain(adj_headword, supvals, "sup")
        if adj_headword.has("hascomp"):
          hascompval = getparam(adj_headword, "hascomp")
          rmparam(adj_headword, "hascomp")
          notes.append("remove unnecessary hascomp=%s from {{pt-adj}}" % hascompval)

        if has_dim:
          dimvals = add_ending("diminutive", dims, "inho", "inha")
          defdim = make_diminutive(headword_lemma)
          dimvals = ["+" if dim == defdim else dim for dim in dimvals]
          notes.append("add diminutive(s) '%s' to {{pt-adj}}" % ",".join(dimvals))
          blib.set_param_chain(adj_headword, dimvals, "dim")

        if has_aug:
          augvals = add_ending("augmentative", augs, "ão", "ona")
          defaug = make_augmentative(headword_lemma)
          augvals = ["+" if aug == defaug else aug for aug in augvals]
          notes.append("add augmentative(s) '%s' to {{pt-adj}}" % ",".join(augvals))
          blib.set_param_chain(adj_headword, augvals, "aug")

        if orig_adj_headword != str(adj_headword):
          pagemsg("Replaced %s with %s" % (orig_adj_headword, str(adj_headword)))
        else:
          pagemsg("No changes to %s" % str(adj_headword))
        adj_infl_templates_to_remove.append(str(t))

  text = str(parsed)
  for template_to_remove in adj_infl_templates_to_remove:
    text, changed = blib.replace_in_text(text,
        "\n\n==+(Inflection|Declension|Conjugation)==+\n%s" % re.escape(template_to_remove), "", pagemsg, is_re=True)
    if not changed:
      pagemsg("WARNING: Can't remove adjective inflection template %s" % template_to_remove)
    else:
      notes.append("remove old adjective inflection template %s" % template_to_remove)

  return text, notes

parser = blib.create_argparser("Convert {{pt-noun}} or {{pt-adj}} templates to new syntax",
  include_pagefile=True, include_stdin=True)
parser.add_argument("--do-nouns", action="store_true")
parser.add_argument("--do-old-nouns", action="store_true",
    help="Only do nouns with old=1")
parser.add_argument("--do-new-hyphenated-nouns", action="store_true")
parser.add_argument("--do-new-adjs-with-inflections", action="store_true")
parser.add_argument("--do-adjs", action="store_true")
parser.add_argument("--add-old", action="store_true",
    help="Add old=1 to adjectives without old=1 or 1=/2=, or to nouns that will change")
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

if args.do_nouns or args.do_old_nouns or args.do_new_hyphenated_nouns:
  default_refs=["Template:pt-noun"]
else:
  default_refs=["Template:pt-adj"]

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, edit=True, stdin=True,
  default_refs=default_refs)
