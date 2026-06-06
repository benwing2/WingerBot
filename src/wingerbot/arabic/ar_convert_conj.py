#!/usr/bin/env python3

import re, json
from dataclasses import dataclass, field

from wingerbot import blib
from wingerbot.blib import getparam, getrmparam, tname, pname

vowel_to_diacritic = {
    "a": "\u064e",
    "i": "\u0650",
    "u": "\u064f",
    "-": "-",
}

ar_verb_template = "ar-verb/old"
ar_conj_template = "ar-conj/old"


@dataclass
class ArConjProperties:
    vform: str
    weakness: str | None = None
    rad1: str | None = None
    rad2: str | None = None
    rad3: str | None = None
    rad4: str | None = None
    past_vowel: str | None = None
    nonpast_vowel: str | None = None
    vns: list[str] | None = None
    vn_ids: list[str] | None = None
    passive: str | None = None
    variant: str | None = None
    noimp: bool = False
    intrans: bool = False


def extract_ar_verb_conj_properties(t, pagemsg):
    def getp(param):
        return getparam(t, param)

    vform = getp("1")
    if not vform:
        pagemsg("WARNING: No verb form specified: %s" % str(t))
        return None
    m = re.search("^(.+)-(.+)$", vform)
    if m:
        vform, weakness = m.groups()
    else:
        weakness = None
    props = ArConjProperties(vform, weakness)
    if vform == "I":
        props.past_vowel = getp("2") or None
        props.nonpast_vowel = getp("3") or None
        firstrad_ind = 4
    else:
        firstrad_ind = 2
    props.rad1 = getp(str(firstrad_ind)) or getp("I") or None
    props.rad2 = getp(str(firstrad_ind + 1)) or getp("II") or None
    props.rad3 = getp(str(firstrad_ind + 2)) or getp("III") or None
    if vform.endswith("q"):
        props.rad4 = getp(str(firstrad_ind + 3)) or getp("IV") or None
    vn = getp("vn")
    if vn:
        props.vns = re.split("[,،]", vn)
    else:
        props.vns = []
    props.vn_ids = [None] * len(props.vns)
    for i in range(0, len(props.vns)):
        props.vn_ids[i] = getp("vn-id%s" % (i + 1)) or None
    props.passive = getp("passive") or None
    props.variant = getp("variant") or None
    props.noimp = not not getp("noimp")
    props.intrans = not not getp("intrans")
    for param in t.params:
        pn = pname(param)
        if not re.search("^vn-id[0-9]+$", pn) and pn not in [
            "1",
            "2",
            "3",
            "4",
            "5",
            "6",
            "vn",
            "passive",
            "variant",
            "noimp",
            "intrans",
            "I",
            "II",
            "III",
            "IV",
        ]:
            pagemsg("WARNING: Unrecognized parameter %s=%s: %s" % (pn, str(param.value), str(t)))
            return None
    return props


def process_text_on_page(p):
    notes = []

    modsec = blib.find_modifiable_lang_section(p.text, "Arabic", p.msg, force_final_nls=True)
    if modsec is None:
        return
    secbody = modsec.secbody

    subsecs = blib.split_text_into_subsections(secbody, p.msg)
    subsections = subsecs.subsections

    parsed_by_subsections = {}
    headts = None
    headts_formatted_subsection_header = None
    saw_headt = False

    def subsection_header_and_num(k):
        return subsections[k - 1].strip() if k > 0 else "FIRST SUBSECTION", k // 2

    def format_subsection_header_and_num(k):
        return "%s (#%s)" % subsection_header_and_num(k)

    for k in range(0, len(subsections), 2):
        parsed = blib.parse_text(subsections[k])
        parsed_by_subsections[k] = parsed
        this_headts = []
        this_conjts = []
        for t in parsed.filter_templates():
            tn = tname(t)
            origt = str(t)

            def getp(param):
                return getparam(t, param)

            if tn == ar_verb_template:
                this_headts.append(t)
            elif tn == ar_conj_template:
                this_conjts.append(t)
        if this_headts and this_conjts:
            p.msg(
                "WARNING: Saw both {{%s}} and {{%s}} templates in the same subsection %s"
                % (ar_verb_template, ar_conj_template, format_subsection_header_and_num(k))
            )
            continue
        if this_headts:
            if headts:
                p.msg(
                    "WARNING: Saw successive {{%s}} templates without corresponding {{%s}} template(s) in subsection %s and %s"
                    % (
                        ar_verb_template,
                        ar_conj_template,
                        headts_formatted_subsection_header,
                        format_subsection_header_and_num(k),
                    )
                )
            headts = this_headts
            headts_formatted_subsection_header = format_subsection_header_and_num(k)
        elif this_conjts:
            if not headts:
                p.msg(
                    "WARNING: Saw {{%s}} template(s) without corresponding {{%s}} template(s) in subsection %s"
                    % (ar_conj_template, ar_verb_template, format_subsection_header_and_num(k))
                )
                continue
            if len(headts) != len(this_conjts):
                p.msg(
                    "WARNING: Saw %s {{%s}} template(s) in subsection %s but %s corresponding {{%s}} template(s) in subsection %s, can't handle"
                    % (
                        len(headts),
                        ar_verb_template,
                        headts_formatted_subsection_header,
                        len(this_conjts),
                        ar_conj_template,
                        format_subsection_header_and_num(k),
                    )
                )
                heads = None
                continue
            for headt, conjt in zip(headts, this_conjts):
                headt_props = extract_ar_verb_conj_properties(headt, p.msg)
                conjt_props = extract_ar_verb_conj_properties(conjt, p.msg)
                if headt_props is None or conjt_props is None:
                    continue
                if headt_props.passive is None:
                    headt_props.passive = conjt_props.passive
                if not headt_props.vns:
                    headt_props.vns = conjt_props.vns
                    headt_props.vn_ids = conjt_props.vn_ids
                headt_props.intrans = headt_props.intrans or conjt_props.intrans
                headt_props.noimp = headt_props.noimp or conjt_props.noimp
                for radprop in ["rad1", "rad2", "rad3", "rad4"]:
                    if getattr(conjt_props, radprop) is None:
                        setattr(conjt_props, radprop, getattr(headt_props, radprop))
                    elif getattr(headt_props, radprop) is None:
                        setattr(headt_props, radprop, getattr(conjt_props, radprop))
                propvals = [
                    "vform",
                    "weakness",
                    "rad1",
                    "rad2",
                    "rad3",
                    "rad4",
                    "past_vowel",
                    "nonpast_vowel",
                    "vns",
                    "vn_ids",
                    "passive",
                    "variant",
                    "noimp",
                    "intrans",
                ]
                for propval in propvals:
                    headval = getattr(headt_props, propval)
                    conjval = getattr(conjt_props, propval)
                    if headval != conjval:
                        p.msg(
                            "WARNING: Headword template %s differs from conjugation template %s in property %s (headword %s, conjugation %s)"
                            % (str(headt), str(conjt), propval, headval, conjval)
                        )
                        break
                else:  # no break
                    vform = conjt_props.vform
                    rad1 = conjt_props.rad1
                    rad2 = conjt_props.rad2
                    rad3 = conjt_props.rad3
                    rad4 = conjt_props.rad4
                    passive = None
                    passive_uncertain = False
                    past_vowels = (conjt_props.past_vowel or "-").split(",")
                    nonpast_vowels = (conjt_props.nonpast_vowel or "-").split(",")
                    explicit_weakness = conjt_props.weakness

                    tempspec = "headt=%s, conjt=%s" % (str(headt), str(conjt))
                    # Warn on intrans
                    if conjt_props.intrans:
                        p.msg("WARNING: Saw intrans=1, not carrying over: %s" % tempspec)

                    # Parse passive value
                    if conjt_props.passive:
                        passive = conjt_props.passive
                        if passive.endswith("?"):
                            passive_uncertain = True
                            passive = passive[:-1]
                        if passive == "impers":
                            passive = "ipass"
                        elif passive == "only":
                            passive = "onlypass"
                        elif passive == "only-impers":
                            passive = "onlypass-impers"
                        elif passive.lower() in ["y", "yes", "t", "true", "1", "on"]:
                            passive = "pass"
                        elif passive.lower() in ["n", "no", "f", "false", "0", "off"]:
                            passive = "nopass"
                        else:
                            p.msg("WARNING: Unparsable value for passive '%s': %s" % (conjt_props.passive, tempspec))
                            continue

                    # Check whether past/non-past vowels are redundant.
                    if vform != "I":
                        if past_vowels != ["-"] or nonpast_vowels != ["-"]:
                            p.msg("WARNING: Past/non-vowel vowels specified for non-form I? Template: %s" % tempspec)
                            continue
                    elif passive in ["onlypass", "onlypass-impers"]:
                        if past_vowels != ["-"] or nonpast_vowels != ["-"]:
                            p.msg("Past/non-vowel vowels specified but verb is passive-only, removing: %s" % tempspec)
                            past_vowels = ["-"]
                            nonpast_vowels = ["-"]
                    elif re.search("[اىي]$", p.title):
                        if p.title.endswith("ا"):
                            expected_past = ["a"]
                            expected_nonpast = ["u"]
                        elif p.title.endswith("ى"):
                            expected_past = ["a"]
                            expected_nonpast = ["i"]
                        else:
                            expected_past = ["i"]
                            expected_nonpast = ["a"]
                        if past_vowels == expected_past and nonpast_vowels == expected_nonpast:
                            p.msg(
                                "Past/non-vowel vowels specified but same as default for form-I final-weak verb, removing: %s"
                                % tempspec
                            )
                            past_vowels = ["-"]
                            nonpast_vowels = ["-"]

                    # Sort out different defaults for assimilated vs. sound in form I
                    if vform == "I" and p.title.startswith("و"):
                        if len(past_vowels) > 1 or len(nonpast_vowels) > 1:
                            p.msg(
                                "WARNING: Multiple past or non-past vowels in form-I verb starting with و, need to sort out manually: %s"
                                % tempspec
                            )
                            continue
                        if (
                            past_vowels == ["i"]
                            and nonpast_vowels == ["a"]
                            or past_vowels == ["u"]
                            and nonpast_vowels == ["u"]
                        ):
                            final_weak = re.search("[اىي]$", p.title)
                            if (
                                final_weak
                                and explicit_weakness == "final-weak"
                                or not final_weak
                                and explicit_weakness == "sound"
                            ):
                                p.msg(
                                    "Saw form-I و-initial verb with past~non-past vowels of i~a or u~u, removing explicit weakness '%s': %s"
                                    % (explicit_weakness, tempspec)
                                )
                                explicit_weakness = None
                            else:
                                p.msg(
                                    "WARNING: Saw form-I و-initial verb with past~non-past vowels of i~a or u~u and without explicit weakness 'sound', need to check manually: %s"
                                    % tempspec
                                )
                                continue

                    # Verify explicitly specified radicals are OK and remove ones that are redundant.
                    if rad1 or rad2 or rad3 or rad4 or explicit_weakness:
                        rad1_required = False
                        rad2_required = False
                        rad3_required = False
                        rad4_required = False
                        must_continue = False
                        for past_vowel in past_vowels:
                            for nonpast_vowel in nonpast_vowels:
                                if past_vowel not in vowel_to_diacritic:
                                    p.msg("WARNING: Bad past vowel '%s': %s" % (past_vowel, tempspec))
                                    must_continue = True
                                    break
                                past_vowel = vowel_to_diacritic[past_vowel]
                                if nonpast_vowel not in vowel_to_diacritic:
                                    p.msg("WARNING: Bad non-past vowel '%s': %s" % (nonpast_vowel, tempspec))
                                    must_continue = True
                                    break
                                nonpast_vowel = vowel_to_diacritic[nonpast_vowel]
                                tempcall = (
                                    "{{#invoke:User:Benwing2/ar-verb|infer_radicals_json|headword=%s|vform=%s|passive=%s|past_vowel=%s|nonpast_vowel=%s|is_reduced=%s}}"
                                    % (p.title, conjt_props.vform, passive or "", past_vowel, nonpast_vowel, "")
                                )
                                ret = p.expand_text(tempcall)
                                if not ret:
                                    must_continue = True
                                    break
                                ret = json.loads(ret)

                                def convert_radical(rad):
                                    if type(rad) is str:
                                        return [rad]
                                    elif type(rad) is list:
                                        return rad
                                    else:
                                        assert type(rad) is dict
                                        retval = []
                                        for i in range(1, 10):
                                            if str(i) in rad:
                                                retval.append(rad[str(i)])
                                            else:
                                                break
                                        return retval

                                def check_rad_redundant(rad, radprop, rad_required):
                                    if not rad:
                                        return rad_required
                                    if radprop not in ret:
                                        p.msg(
                                            "WARNING: Something wrong, radical property '%s' not in returned %s for template call %s for template %s"
                                            % (radprop, ret, tempcall, tempspec)
                                        )
                                        return None
                                    radlist = convert_radical(ret[radprop])
                                    if rad not in radlist:
                                        p.msg(
                                            "WARNING: Radical %s is %s but inferred as one of %s: %s"
                                            % (radprop, rad, radlist, tempspec)
                                        )
                                        return None
                                    if len(radlist) > 1:
                                        return True
                                    return rad_required

                                rad1_required = check_rad_redundant(rad1, "rad1", rad1_required)
                                rad2_required = check_rad_redundant(rad2, "rad2", rad2_required)
                                rad3_required = check_rad_redundant(rad3, "rad3", rad3_required)
                                rad4_required = check_rad_redundant(rad4, "rad4", rad4_required)
                                if (
                                    rad1_required is None
                                    or rad2_required is None
                                    or rad3_required is None
                                    or rad4_required is None
                                ):
                                    must_continue = True
                                    break
                            if must_continue:
                                break
                        if must_continue:
                            continue
                        if not rad1_required:
                            rad1 = None
                        if not rad2_required:
                            rad2 = None
                        if not rad3_required:
                            rad3 = None
                        if not rad4_required:
                            rad4 = None

                        # Make sure explicit weakness is OK
                        inferred_weakness = ret["weakness"]
                        if explicit_weakness:
                            if inferred_weakness == explicit_weakness:
                                p.msg("Removing redundant explicit weakness %s: %s" % (explicit_weakness, tempspec))
                                explicit_weakness = None
                            elif vform == "I" and (
                                explicit_weakness == "sound"
                                and inferred_weakness == "assimilated"
                                or explicit_weakness == "assimilated"
                                and inferred_weakness == "sound"
                                or explicit_weakness == "final-weak"
                                and inferred_weakness == "assimilated+final-weak"
                                or explicit_weakness == "assimilated+final-weak"
                                and inferred_weakness == "final-weak"
                            ):
                                pass
                            else:
                                p.msg(
                                    "WARNING: Explicit weakness %s incompatible with inferred weakness %s: %s"
                                    % (explicit_weakness, inferred_weakness, tempspec)
                                )
                                continue

                    if past_vowels == ["-"] and nonpast_vowels == ["-"]:
                        vowel_spec = ""
                    else:
                        vowel_spec = "/%s~%s" % (",".join(past_vowels), ",".join(nonpast_vowels))
                    vform_spec = "%s-%s" % (vform, explicit_weakness) if explicit_weakness else vform
                    indicators = []
                    if rad1:
                        indicators.append("I:%s" % rad1)
                    if rad2:
                        indicators.append("II:%s" % rad2)
                    if rad3:
                        indicators.append("III:%s" % rad3)
                    if rad4:
                        indicators.append("IV:%s" % rad4)
                    if passive:
                        indicators.append("%s%s" % (passive, "?" if passive_uncertain else ""))
                    if conjt_props.variant:
                        indicators.append("var:%s" % conjt_props.variant)
                    if conjt_props.noimp:
                        indicators.append("noimp")
                    if conjt_props.vns:
                        if vform != "I":
                            p.msg("Explicit verbal noun for non-form-I, might need removing: %s" % tempspec)
                            allspec = "%s%s%s%s" % (
                                vform_spec,
                                vowel_spec,
                                "." if indicators else "",
                                ".".join(indicators),
                            )
                            formscall = "{{User:Benwing2/ar-conj|%s|json=1|pagename=%s}}" % (allspec, p.title)
                            ret = p.expand_text(formscall)
                            if not ret:
                                continue
                            ret = json.loads(ret)
                            auto_vns = [x["form"] for x in ret["forms"]["vn"]]
                            if set(auto_vns) == set(conjt_props.vns):
                                if vform == "III":
                                    p.msg(
                                        "Using <vn:+> for explicit but redundant form-III verbal nouns to signal that alternative verbal noun not present"
                                    )
                                    indicators.append("vn:+")
                                else:
                                    p.msg(
                                        "Removing redundant non-form-I verbal noun(s) %s: %s"
                                        % (",".join(conjt_props.vns), tempspec)
                                    )
                            else:
                                vnspecs = []
                                if "vn2" in ret["forms"]:
                                    vn2 = [x["form"] for x in ret["forms"]["vn2"]]
                                else:
                                    vn2 = []
                                for vn, vnid in zip(conjt_props.vns, conjt_props.vn_ids):
                                    if [vn] == auto_vns:
                                        vn = "+"
                                    elif [vn] == vn2:
                                        vn = "++"
                                    if vnid:
                                        vnspecs.append("%s<id:%s>" % (vn, vnid))
                                    else:
                                        vnspecs.append(vn)
                                vn_indicator = "vn:%s" % ",".join(vnspecs)
                                indicators.append(vn_indicator)
                                p.msg(
                                    "WARNING: Explicit non-redundant verbal noun(s) for non-form-I not same as auto-generated %s, needs checking, would use VN indicator <%s>: %s"
                                    % (",".join(auto_vns), vn_indicator, tempspec)
                                )
                        else:
                            vnspecs = []
                            for vn, vnid in zip(conjt_props.vns, conjt_props.vn_ids):
                                if vnid:
                                    vnspecs.append("%s<id:%s>" % (vn, vnid))
                                else:
                                    vnspecs.append(vn)
                            indicators.append("vn:%s" % ",".join(vnspecs))
                    allspec = "%s%s%s%s" % (vform_spec, vowel_spec, "." if indicators else "", ".".join(indicators))
                    origheadt = str(headt)
                    origconjt = str(conjt)
                    del headt.params[:]
                    del conjt.params[:]
                    blib.set_template_name(headt, "ar-verb")
                    headt.add("1", allspec)
                    blib.set_template_name(conjt, "ar-conj")
                    conjt.add("1", allspec)
                    p.msg(
                        "Convert headword template %s to %s and conjugation template %s to %s"
                        % (origheadt, str(headt), origconjt, str(conjt))
                    )
                    notes.append(
                        "convert {{%s}} and {{%s}} for form %s to new-format {{ar-verb}}/{{ar-conj}}"
                        % (ar_verb_template, ar_conj_template, vform)
                    )
            headts = None

    secbody_parts = []
    for k in range(len(subsections)):
        if k % 2 == 0:
            secbody_parts.append(str(parsed_by_subsections[k]))
        else:
            secbody_parts.append(subsections[k])
    return modsec.rebuild(secbody="".join(secbody_parts)), notes


parser = blib.create_argparser(
    "Convert Arabic verb headword and conj templates to new form"
)
args = parser.parse_args()
start, end = blib.parse_start_end(args.start, args.end)

blib.do_pagefile_cats_refs(args, start, end, process_text_on_page, default_cats=["Arabic verbs"])
