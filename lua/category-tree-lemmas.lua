local labels = {}
local raw_categories = {}
local handlers = {}

local category_tree_utilities_module = "Module:category tree/utilities"

-----------------------------------------------------------------------------
--                                                                         --
--                                  LABELS                                 --
--                                                                         --
-----------------------------------------------------------------------------


local diminutive_augmentative_poses = {
	"adjectives",
	"adverbs",
	"determiners",
	"interjections",
	"nouns",
	"numerals",
	"prefixes",
	"proper nouns",
	"pronouns",
	"suffixes",
	"verbs",
}

local verbs_suffixes = {
	"verbs",
	{"suffixes", posdesc = "suffixes that form verbs"},
}

local nouns_suffixes = {
	"nouns",
	{"suffixes", posdesc = "suffixes that form nouns"},
}

-- Used for "{pos}-forming suffixes" and "{pos} inflectional suffixes".
local sgpos_suffix_types = {
	"adjective",
	"adverb",
	"noun",
	"numeral",
	"participle",
	"pronoun",
	"proper noun",
	"verb",
}

local voices = {
	"active",
	"middle",
	"passive",
}

local adpositions = {
	{"prepositions", adposition = "preposition", adpositional = "prepositional", adp_location = "before", obj_prec_foll = "following"},
	{"postpositions", adposition = "postposition", adpositional = "postpositional", adp_location = "after", obj_prec_foll = "preceding"},
}

local countable_uncountable_pos = {
	"nouns",
	"proper nouns",
	{"suffixes", posdesc = "suffixes that form nouns"},
	{"numerals", numeralpos = "other numerals"},
}

labels["lemmas"] = {
	description = "{{{langname}}} [[Wiktionary:Lemmas|lemmas]], categorized by their part of speech.",
	umbrella_parents = "Fundamental",
	parents = {{name = "{{{langcat}}}", raw = true, sort = "  "}},
}

-- See the documentation of add_labels_from_specs() in [[Module:category tree/utilities]] for the format of the
-- following table.
local labels_specs = {
	defaults = {
		posdesc = "{pos}",
		numeralpos = "numerals",
	},
	specs = {
{"action nouns", "nouns denoting action of a verb or verbal root that it is derived from", {"nouns"}},
{"act-related adverbs", "adverbs that indicate the motive or other background information for an action", {"adverbs"}},
{"adjectives", "terms that give attributes to nouns, extending their definitions", {"lemmas"}},
{"adjectivized participles", "participles that are used as adjectives", {"participles", "adjectives"}},
{"adjectivized past participles", "past participles that are used as adjectives", {"past participles", "adjectivized participles", "adjectives"}},
{"adjectivized present participles", "present participles that are used as adjectives", {"present participles", "adjectivized participles", "adjectives"}},
{"adverbial accusatives", "accusative case-forms used as adverbs", {"adverbs"}},
{"adverbs", "terms that modify clauses, sentences and phrases directly", {"lemmas"}},
{"agent nouns", "nouns that denote an agent that performs the action denoted by the verb from which the noun is derived", {"nouns"}},
{"ambipositions", "adpositions that can occur either before or after their objects", {"lemmas"}},
{"ambitransitive verbs", "verbs that may or may not direct actions, occurrences or states to grammatical objects", {"verbs", "transitive verbs", "intransitive verbs"}},
{"animal commands", "words used to communicate with animals", {"interjections"}},
{"articles", "terms that indicate and specify nouns", {"determiners"}},
{"aspect adverbs", "adverbs that express [[w:Grammatical aspect|grammatical aspect]], describing the flow of time in relation to a statement", {"adverbs"}},
{"augmentative {pos}", "{posdesc} that are derived from a base word to convey big size or big intensity", {"{pos}"},
	pos = diminutive_augmentative_poses},
{"attenuative {pos}", "{posdesc} that indicate that an action or event is performed or takes place gently, lightly, partially, perfunctorily or to an otherwise reduced extent", {"{pos}"},
	pos = verbs_suffixes},
{"autobenefactive {pos}", "{posdesc} that indicate that the agent of an action is also its benefactor", {"{pos}"},
	pos = verbs_suffixes},
{"automative {pos}", "{posdesc} that indicate actions directed at or a change of state of the grammatical subject", {"{pos}"},
	pos = verbs_suffixes},
{"auxiliary verbs", "verbs that provide additional conjugations for other verbs", {"verbs"}},
{"biaspectual {pos}", "{posdesc} that can be both imperfective and perfective", {"{pos}"},
	pos = verbs_suffixes},
{"causative {pos}", "{posdesc} that express causing actions or states rather than performing or being them directly", {"{pos}"},
	pos = verbs_suffixes},
{"circumpositions", "adpositions that appear on both sides of their objects", {"lemmas"}},
{"classifiers", "terms that classify nouns according to their meanings", {"lemmas"}},
{"collective {pos}", "{posdesc} that indicate groups of related things or beings, without the need of grammatical pluralization", {"{pos}"},
	pos = nouns_suffixes},
{"comparable adjectives", "adjectives that can be inflected to display different degrees of comparison", {"adjectives"}},
{"comparable adverbs", "adverbs that can be inflected to display different degrees of comparison", {"adverbs"}},
{"completive {pos}", "{posdesc} which refer to the completion of an action which has already commenced or which has already been performed upon a subset of the entities which it affects", {"{pos}"},
	pos = verbs_suffixes},
{"conjunctions", "terms that connect words, phrases or clauses together", {"lemmas"}},
{"conjunctive adverbs", "adverbs that connect two independent clauses together", {"adverbs"}},
{"continuative {pos}", "{posdesc} that express continuing action", {"imperfective {pos}", "{pos}"},
	pos = verbs_suffixes},
{"control verbs", "verbs that take multiple arguments, one of which is another verb", {"verbs"},
	additional = "One of the control verb's arguments is syntactically both an argument of the control verb and an argument of the other verb"},
{"cooperative {pos}", "{posdesc} that indicate cooperation", {"{pos}"},
	pos = verbs_suffixes},
{"coordinating conjunctions", "conjunctions that indicate equal syntactic importance between connected items", {"conjunctions"}},
{"copulative verbs", "verbs that may take adjectives as their complement", {"verbs"}},
{"countable {pos}", "{posdesc} that can be quantified directly by {numeralpos}", {"{pos}"},
	pos = countable_uncountable_pos},
{"counters", "terms that combine with numerals to express quantity of nouns", {"lemmas"}},
{"cumulative {pos}", "{posdesc} which indicate that an action or event gradually yields a certain or significant quantity or effect", {"{pos}"},
	pos = verbs_suffixes},
{"degree adverbs", "adverbs that express a particular degree to which the word they modify applies", {"adverbs"}},
{"delimitative {pos}", "{posdesc} which indicate that an action or event is performed or takes place briefly or to an otherwise reduced extent", {"imperfective {pos}", "{pos}"},
	pos = verbs_suffixes},
{"demonstrative adjectives", "adjectives that refer to nouns, comparing them to external references", {"adjectives", {name = "demonstrative pro-forms", sort = "adjectives"}}},
{"demonstrative adverbs", "adverbs that refer to other adverbs, comparing them to external references", {"adverbs", {name = "demonstrative pro-forms", sort = "adverbs"}}},
{"denominal verbs", "verbs that derive from nouns", {"verbs"}}, -- in [[Appendix:Glossary]]; "denominative" more frequent?
{"demonstrative determiners", "determiners that refer to nouns, comparing them to external references", {"determiners", {name = "demonstrative pro-forms", sort = "determiners"}}},
{"demonstrative pronouns", "pronouns that refer to nouns, comparing them to external references", {"pronouns", {name = "demonstrative pro-forms", sort = "pronouns"}}},
{"deponent verbs", "verbs that have active meanings but are not conjugated in the {{w|active voice}}", {"verbs"}},
{"derivational prefixes", "prefixes that are used to create new words", {"prefixes"}},
{"derivational suffixes", "suffixes that are used to create new words", {"suffixes"}},
{"derivative verbs", "verbs that are derived from nouns and adjectives", {"verbs"}},
{"desiderative {pos}", "{posdesc} that indicate a wish to do a specified action", {"{pos}"},
	pos = verbs_suffixes},
{"determinatives", "terms that indicate the general class to which the following logogram belongs", {"lemmas"}},
{"determiners", "terms that narrow down, within the conversational context, the referent of the modified noun", {"lemmas"}},
{"diminutiva tantum", "nouns or noun senses that are mostly or exclusively used in the diminutive form", {"nouns"}},
{"diminutive {pos}", "{posdesc} that are derived from a base word to convey endearment, small size or small intensity", {"{pos}"},
	pos = diminutive_augmentative_poses},
{"discourse particles", "particles that manage the flow and structure of discourse", {"particles"}},
{"distributive {pos}", "{posdesc} which indicate that an action or event involves multiple participants or a large quantity of an uncountable mass", {"imperfective {pos}", "{pos}"},
	additional = "The large quantity involved usually serves as the grammatical subject in the case of intransitive verbs and as the grammatical object in the case of transitive verbs.",
	pos = verbs_suffixes},
{"ditransitive verbs", "verbs that indicate actions, occurrences or states directed to two grammatical objects simultaneously", {"verbs", "transitive verbs"}},
{"dualia tantum", "nouns that are mostly or exclusively used in the dual form", {"nouns"}},
{"duration adverbs", "adverbs that express duration in time, such as (in English) [[always]], [[all night]] and [[ever since]]", {"time adverbs"}},
{"ergative verbs", "[[Appendix:Glossary#ergative|ergative verb]]s: intransitive verbs that become causatives when used transitively", {"verbs", "intransitive verbs", "transitive verbs"}},
{"excessive verbs", "verbs that indicate that an action is performed to an excessive extent", {"verbs"}},
{"enclitics", "clitics that attach to the preceding word", {"clitics"}},
{"focus adverbs", "adverbs that indicate [[w:Focus (linguistics)|focus]] within the sentence", {"adverbs"}},
{"frequency adverbs", "adverbs that express repetition with a certain frequency or interval, such as (in English) [[monthly]], [[continually]] and [[once in a while]]", {"time adverbs"}},
{"frequentative {pos}", "{posdesc} that express repeated action", {"imperfective {pos}", "{pos}"},
	pos = verbs_suffixes},
{"general pronouns", "pronouns that refer to all persons, things, abstract ideas and their characteristics", {"pronouns"}},
{"generational moieties", "moieties that alternate every generation", {"moieties"}},
{"ideophones", "terms that evoke an idea, especially a sensation or impression, with a sound", {"lemmas"}},
{"imperfective {pos}", "{posdesc} that express actions considered as ongoing or continuous, as opposed to completed events", {"{pos}"},
	pos = verbs_suffixes},
{"impersonal verbs", "verbs that do not indicate actions, occurrences or states of any specific grammatical subject", {"verbs"}},
{"inchoative {pos}", "{posdesc} that indicate the beginning of an action or event", {"{pos}"},
	pos = verbs_suffixes},
{"indefinite {pos}", "{pos} that {indef_ref}", {"{pos}", {name = "indefinite pro-forms", sort = "{pos}"}},
	pos = {
		{"adjectives", indef_ref = "refer to unspecified adjectival meanings"},
		{"adverbs", indef_ref = "refer to unspecified adverbial meanings"},
		{"determiners", indef_ref = "designate an unidentified noun"},
		{"pronouns", indef_ref = "refer to unspecified nouns"},
	}},
{"inflectional {sufpos}", "{sufpos} that are used as inflectional {begin_end} in noun, adjective or verb paradigms", {"{sufpos}"},
	sufpos = {{"prefixes", begin_end = "beginnings"}, {"suffixes", begin_end = "endings"}}},
{"intensive {pos}", "{posdesc} which indicate that an action is performed vigorously, enthusiastically, forcefully or to an otherwise enlarged extent", {"{pos}"},
	pos = verbs_suffixes},
{"interjections", "terms that express emotions, sounds, etc. as exclamations", {"lemmas"}},
{"interrogative {pos}", "{pos} that indicate questions", {"{pos}", {name = "interrogative pro-forms", sort = "{pos}"}},
	pos = {"adjectives", "adverbs", "determiners", "particles", "pronouns"}},
{"intransitive verbs", "verbs that don't require any grammatical objects", {"verbs"}},
{"iterative {pos}", "{posdesc} that express the repetition of an event", {"imperfective {pos}", "{pos}"},
	pos = verbs_suffixes},
{"location adverbs", "adverbs that indicate location", {"adverbs"}},
{"manner adverbs", "adverbs that indicate the manner, way or style in which an action is performed", {"adverbs"}},
{"modal adverbs", "adverbs that express [[w:Linguistic modality|linguistic modality]], indicating the mood or attitude of the speaker with respect to what is being said", {"sentence adverbs"}},
{"modal particles", "particles that reflect the mood or attitude of the speaker, without changing the basic meaning of the sentence", {"particles"}},
{"modal verbs", "verbs that indicate [[grammatical mood]]", {"auxiliary verbs"}},
{"moieties", "pairs of abstract categories separating people and the environment", {"lemmas"}},
{"momentane {pos}", "{posdesc} that express a sudden and brief action", {"perfective {pos}", "{pos}"},
	pos = verbs_suffixes},
{"movement adverbs", "adverbs that express movement in space, such as (in English) [[hither]], [[that way]], [[down]] and [[eastwards]]", {"location adverbs"},
	additional = "Compare [[:Category:{{{langname}}} position adverbs]].",
	umbrella = {additional = "Compare [[:Category:Position adverbs by language]]."}},
{"multiword terms", "lemmas that are a combination of multiple words, including [[WT:CFI#Idiomaticity|idiomatic]] combinations", {"lemmas"}},
{"negative verbs", "verbs that indicate the lack of an action", {"verbs"}},
{"negative particles", "particles that indicate negation", {"particles"}},
{"negative pronouns", "pronouns that refer to negative or non-existent references", {"pronouns"}},
{"negative determiners", "determiners that indicate negation", {"determiners"}},
{"nominalized {pos}", "{pos} that are used as nouns", {"nouns", "{pos}"},
	pos = {"adjectives", "present participles"}},
{"non-constituents", "terms that are not grammatical [[constituent#Noun|constituents]], and therefore need to be combined with additional terms to form a complete phrase", {"phrases"}},
{"noun prefixes", "prefixes attached to a noun that display its noun class", {"prefixes"}},
{"nouns", "terms that indicate people, beings, things, places, phenomena, qualities or ideas", {"lemmas"}},
{"nouns by classifier", "nouns organized by the classifier they are used with", {{name = "nouns", sort = "classifier"}},
	breadcrumb = "by classifier"},
{"numerals", "terms that quantify nouns", {"lemmas"}},
{"object pronouns", "pronouns that refer to grammatical objects", {"pronouns"}},
{"particles", "terms that do not belong to any of the inflected grammatical word classes, often lacking their own grammatical functions and forming other parts of speech or expressing the relationship between clauses", {"lemmas"}},
{"pejorative suffixes", "suffixes that [[belittle]] (lessen in value)", {"suffixes"}},
{"perfective {pos}", "{posdesc} that express actions considered as completed events, as opposed to ongoing or continuous", {"{pos}"},
	pos = verbs_suffixes},
{"personal pronouns", "pronouns that are used as substitutes for known nouns", {"pronouns"}},
{"phrasal verbs", "verbs accompanied by particles, such as prepositions and adverbs", {"verbs", "phrases"}},
{"pluralia tantum", "nouns that are mostly or exclusively used in the plural form", {"nouns"}},
{"point-in-time adverbs", "adverbs that reference a specific point in time, e.g. {{m|en|yesterday}}, {{m+|es|anoche||last night}} or {{m+|hu|egykor||at one o'clock}}", {"time adverbs"}},
{"position adverbs", "adverbs that express position in space, such as (in English) [[here]], [[next door]], [[cater-corner]] and [[on deck]]", {"location adverbs"},
	additional = "Compare [[:Category:{{{langname}}} movement adverbs]].",
	umbrella = {additional = "Compare [[:Category:Movement adverbs by language]].",}},
{"possessable nouns", "nouns that can have their possession indicated directly by possessive pronouns", {"nouns"},
	umbrella = {description = "Categories with nouns that can have their possession indicated directly by possessive pronouns and, in some languages, be transformed into adjectives."}},
{"possessional adjectives", "adjectives that indicate that a noun is in possession of something", {"adjectives"}},
{"possessive {pos}", "{pos} that indicate ownership", {"{pos}"},
	pos = {"adjectives", "clitics", "determiners", "pronouns"}},
{"predicatives", "elements of the predicate that supplement the subject or object of a sentence via the verb", {"lemmas"}},
{"prenouns", "prefixes of various kinds that are attached to nouns", {"prefixes"}},
{"preverbs", "prefixes of various kinds that are attached to verbs", {"prefixes"}},
{"privative verbs", "verbs that indicate that the grammatical object is deprived of something or that something is removed from the object", {"verbs"}},
{"pronominal adverbs", "adverbs that are formed by combining a pronoun with a preposition", {"adverbs", "prepositions", "pronouns"}},
{"pronouns", "terms that refer to and substitute nouns", {"lemmas"}},
{"proper nouns", "nouns that indicate individual entities, such as names of persons, places or organizations", {"nouns"}},
{"raising verbs", "verbs that, in a matrix or main clause, take an argument from an embedded or subordinate clause", {"verbs"},
	additional = "In other words, a raising verb appears with a syntactic argument that is not its semantic argument, but is rather the semantic argument of an embedded predicate."},
{"reciprocal pronouns", "pronouns that refer back to a plural subject and express an action done in two or more directions", {"pronouns", "personal pronouns"}},
{"reciprocal verbs", "verbs that indicate actions, occurrences or states directed from multiple subjects to each other", {"verbs"}},
{"reflexive pronouns", "pronouns that refer back to the subject", {"pronouns", "personal pronouns"}},
{"reflexive verbs", "verbs that indicate actions, occurrences or states directed from the grammatical subjects to themselves", {"verbs"}},
{"relational adjectives", "adjectives that stand in place of a noun when modifying another noun", {"adjectives"}},
{"relational nouns", "nouns used to indicate a relation between other two nouns by means of possession", {"nouns"}},
{"relative {pos}", "{pos} used to indicate [[relative clause]]s", {"{pos}", {name = "relative pro-forms", sort = "{pos}"}},
	pos = {"adjectives", "adverbs", "determiners", "pronouns"}},
{"relatives", "terms that give attributes to nouns, acting grammatically as relative clauses", {"lemmas"}},
{"repetitive {pos}", "{posdesc} that indicate actions or events which are performed or occur again, anew or differently", {"{pos}"},
	pos = verbs_suffixes},
{"resultative {pos}", "{posdesc} that indicate a result of some action", {"{pos}"},
	pos = verbs_suffixes},
{"reversative {pos}", "{posdesc} that indicate that the reversal or undoing of an action, event or state", {"{pos}"},
	pos = verbs_suffixes},
{"saturative {pos}", "{posdesc} which indicate that an action is performed to the point of saturation or satisfaction", {"{pos}"},
	pos = verbs_suffixes},
{"semelfactive {pos}", "{posdesc} that are punctual (instantaneous, momentive), perfective (treated as a unitary whole with no explicit internal temporal structure), and telic (having a boundary out of which the activity cannot be said to have taken place or continue)", {"{pos}"},
	pos = verbs_suffixes},
{"sentence adverbs", "adverbs that modify an entire clause or sentence", {"adverbs"}},
{"sequence adverbs", "conjunctive adverbs that express sequence in space or time", {"conjunctive adverbs"}},
{"singulative nouns", "nouns that indicate a single item of a group of related things or beings", {"nouns"}},
{"singularia tantum", "nouns that are mostly or exclusively used in the singular form", {"nouns"}},
{"solitary pronouns", "pronouns that refer to specific people in particular and sets them apart from anyone else", {"pronouns", "personal pronouns"}},
{"stative {pos}", "{posdesc} that define a state with no or insignificant internal dynamics", {"{pos}"},
	pos = verbs_suffixes},
{"subordinating conjunctions", "conjunctions that indicate relations of syntactic dependence between connected items", {"conjunctions"}},
{"subject pronouns", "pronouns that refer to grammatical subjects", {"pronouns"}},
{"splitting verbs", "bisyllabic verbs that obligatorily split around a direct object or pronoun", {"verbs"}},
{"terminative {pos}", "{posdesc} that indicate that an action or event ceases", {"{pos}"},
	pos = verbs_suffixes},
{"time adverbs", "adverbs that indicate time, expressing either [[duration]], [[frequency]] or a [[point]] in [[time]]", {"adverbs"}},
{"transformative {pos}", "{posdesc} that indicate a change of state or nature, in the subject for intransitive verbs and in the object for transitive verbs", {"{pos}"},
	pos = verbs_suffixes},
{"transitive verbs", "verbs that indicate actions, occurrences or states directed to one or more grammatical objects", {"verbs"}},
{"tritransitive verbs", "verbs that indicate actions, occurrences or states directed to three grammatical objects simultaneously", {"verbs", "transitive verbs"}},
{"uncomparable adjectives", "adjectives that are not inflected to display different degrees of comparison", {"adjectives"}},
{"uncomparable adverbs", "adverbs that are not inflected to display different degrees of comparison", {"adverbs"}},
{"uncountable {pos}", "{posdesc} that cannot be quantified directly by {numeralpos}", {"{pos}"},
	pos = countable_uncountable_pos},
{"unpossessable nouns", "nouns that cannot have their possession indicated directly by possessive pronouns", {"nouns"},
	umbrella = {description = "Categories with nouns that cannot have their possession indicated directly by possessive pronouns or, in some languages, be transformed into adjectives"}},
{"verbal nouns", "nouns morphologically related to a verb and similar to it in meaning", {"nouns"}},
{"verbal adjectives", "adjectives describing the condition or state resulting from the action of the corresponding verb", {"adjectives"}},
{"verbs", "terms that indicate actions, occurrences or states", {"lemmas"}},
{"verbs of movement", "verbs that indicate physical movement of the grammatical subject across a trajectory, with a starting point and an endpoint", {"verbs"}},

-- Morphemes and types of morphemes. We segregate them because their descriptions are unusual if that they usually don't
-- begin with {{{langname}}}, so we want to make sure we maintain consistency.
{"morphemes", "word-elements used to form full words", {"lemmas"}},
{"affixes", "Morphemes attached to existing {{{langname}}} words", {"morphemes"}},
{"circumfixes", "Affixes attached to both the beginning and the end of {{{langname}}} words, functioning together as single units", {"morphemes"}},
{"clitics", "morphemes that function as independent words, but are always attached to another word", {"morphemes"}},
{"combining forms", "Forms of {{{langname}}} words that do not occur independently, but are used when joined with other words", {"morphemes"}},
{"infixes", "Affixes inserted inside {{{langname}}} words", {"morphemes"}},
{"interfixes", "Affixes used to join two {{{langname}}} words or morphemes together", {"morphemes"}},
{"prefixes", "Affixes attached to the beginning of {{{langname}}} words", {"morphemes"}},
{"simulfixes", "Affixes replacing positions in {{{langname}}} words", {"morphemes"}},
{"stems", "Morphemes from which {{{langname}}} words are formed", {"morphemes"}},
{"suffixes", "Affixes attached to the end of {{{langname}}} words", {"morphemes"}},
{"transfixes", "Discontinuous affixes inserted within {{{langname}}} word roots", {"morphemes"}},

-- Verbs of a specified voice
{"{voice} verbs", "verbs that are predominantly used in the {{w|{voice} voice}}", {"verbs"},
	voice = voices},
{"{voice}-only verbs", "verbs that can only be used in the {{w|{voice} voice}}", {"{voice} verbs", "verbs"},
	voice = voices},

-- Adpositions
{"phrasal {adpositions}", "{adpositions} formed with combinations of other terms", {"{adpositions}", "phrases"},
	adpositions = adpositions},
{"{adpositional} phrases", "phrases headed by a {adposition}", {"phrases", "{adpositions}"},
	adpositions = adpositions},
{"{adpositions}", "adpositions that are placed {adp_location} their objects", {"lemmas"},
	adpositions = adpositions},
{"{adpositions} governing the {case}", "{adpositions} that cause the {obj_prec_foll} noun to be in the {case} case", {"{adpositions}"},
	breadcrumb = "{case}",
	case = {"ablative", "accusative", "dative", "genitive", "instrumental", "locative", "nominative", "prepositional", "vocative"},
	adpositions = adpositions},

-- {degree}-only {pos} (e.g. "comparative-only adverbs")
{"{degree}-only {pos}",  "{pos} that are only used in the {degree} degree", {"{pos}"},
	degree = {"comparative", "superlative", "elative", "exaggerated", "excessive", "equative"},
	pos = {"adjectives", "adverbs", "determiners", "pronouns"}},

-- {pos}-forming suffixes, {pos} inflectional suffixes
{"{sgpos}-forming suffixes", "suffixes that are used to derive {sgpos}s from other words", {"derivational suffixes"},
	sgpos = sgpos_suffix_types},
{"{sgpos} inflectional suffixes", "suffixes that are used to construct {sgpos} inflections", {"inflectional suffixes"},
	sgpos = sgpos_suffix_types},

-- Genders and moieties
{"{gender} equivalent {pos}", "{posdesc} that refer to {gender} beings with the same characteristics as the base {pos}", {"{pos} with other-gender equivalents"},
	gender = {"male", "female", "neuter"}, pos = nouns_suffixes},
{"{pos} with other-gender equivalents", "{posdesc} that refer to gendered concepts (e.g. [[actor]] vs. [[actress]], [[king]] vs. [[queen]]) and have corresponding other-gender equivalent terms", {"{pos}"},
	pos = nouns_suffixes},
{"{lineal} moieties", "moieties inherited from an individual's {parent}", {"moieties"},
	lineal = {{"matrilineal", parent = "mother"}, {"patrilineal", parent = "father"}}},

}}

-- Add labels from the above specs.
require(category_tree_utilities_module).add_labels_from_specs(labels, labels_specs)

-- Add breadcrumb by chopping off the parent (or the parent's parent, etc.) from the end of the label, if possible.
-- Add 'umbrella_parents' key if not already present.
require(category_tree_utilities_module).finalize_labels(labels, {
	default_umbrella_parents = "Lemmas subcategories by language"
})


-----------------------------------------------------------------------------
--                                                                         --
--                              RAW CATEGORIES                             --
--                                                                         --
-----------------------------------------------------------------------------


raw_categories["Lemmas subcategories by language"] = {
	description = "Umbrella categories covering topics related to lemmas.",
	additional = "{{{umbrella_meta_msg}}}",
	parents = {
		"Umbrella metacategories",
		{name = "lemmas", is_label = true, sort = " "},
	},
}



-----------------------------------------------------------------------------
--                                                                         --
--                                 HANDLERS                                --
--                                                                         --
-----------------------------------------------------------------------------

-- Handler for e.g. [[:Category:English phrasal verbs formed with "aback"]].
table.insert(handlers, function(data)
	local particle = data.label:match("^phrasal verbs formed with \"(.-)\"$")
	if particle then
		local tagged_text = require("Module:script utilities").tag_text(particle, data.lang, nil, "term")
		local link = require("Module:links").full_link({ term = particle, lang = data.lang }, "term")

		return {
			description = "{{{langname}}} {{w|phrasal verb}}s formed with the adverb or preposition " .. link .. ".",
			displaytitle = '{{{langname}}} phrasal verbs formed with "' .. particle .. '"',
			breadcrumb = tagged_text,
			parents = {{ name = "phrasal verbs", sort = particle }},
			umbrella = false,
		}
	end
end)


return {LABELS = labels, RAW_CATEGORIES = raw_categories, HANDLERS = handlers}
