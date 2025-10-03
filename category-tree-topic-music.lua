local labels = {}

------------------------------------ music base labels ------------------------------------

labels["music"] = {
	type = "related-to",
	description = "default",
	parents = {"art", "sound"},
}

labels["singing"] = {
	type = "related-to",
	description = "default",
	parents = {"music", "talking"},
}

labels["music theory"] = {
	type = "grouping",
	description = "default",
	breadcrumb_and_sort_base = "theory",
	parents = {"music"},
}

------------------------------------ music theory ------------------------------------

labels["Classical music forms"] = {
	type = "type",
	description = "terms for [[form]]s of [[Classical music]] [[piece]]s",
	additional = "In English this includes terms such as [[sonata]], [[symphony]], [[prelude]], [[fugue]], [[toccata]], etc.",
	parents = {"music"},
}

labels["Classical music sections"] = {
	type = "type",
	description = "terms for [[form]]s of [[Classical music]] [[piece]]s",
	additional = "In English this includes terms such as [[sonata]], [[symphony]], [[prelude]], [[fugue]], [[toccata]], etc.",
	parents = {"music"},
}

labels["musical articulations"] = {
	type = "type",
	description = "=[[musical]] [[articulation]]s (terms referring to the manner in which notes are [[attack]]ed)",
	additional = "In English this includes Italian-origin terms such as [[legato]], [[staccato]], [[pizzicato]], [[glissando]], [[arpeggiato]], etc.",
	breadcrumb_and_sort_base = "articulations",
	parents = {"music theory"},
}

labels["musical cadences"] = {
	type = "type",
	description = "=[[musical]] [[cadence]]s (terms referring to sequences of chords, particularly in Classical music)",
	additional = "In English this includes terms such as [[deceptive cadence]], [[plagal cadence]] (also just [[plagal]]), [[demicadence]], [[4-3 suspension]], etc.",
	breadcrumb_and_sort_base = "cadences",
	parents = {"music theory"},
}

labels["musical chords"] = {
	type = "type",
	description = "=[[musical]] [[chord]]s",
	additional = "In English this includes terms such as [[major triad]], [[dominant seventh chord]], [[ninth chord]], [[Neapolitan chord]], etc.",
	breadcrumb_and_sort_base = "chords",
	parents = {"music theory"},
}

labels["musical clefs"] = {
	type = "type",
	description = "=[[musical]] [[clef]]s",
	additional = "In English this includes terms such as [[treble clef]] (or just [[treble]]), [[tenor clef]], [[C-clef]]/[[C clef]], etc.",
	breadcrumb_and_sort_base = "clefs",
	parents = {"music theory"},
}

labels["musical directives"] = {
	type = "type",
	description = "=[[musical]] [[directive]]s (terms referring to the how the [[tempo]] and/or [[dynamics]], i.e. speed and/or volume, are changed)",
	additional = "In English this includes Italian-origin terms indicating tempo changes such as [[accelerando]], [[rallentando]], [[stretto]], etc.; terms indicating dynamic changes such as [[crescendo]], [[diminuendo]], [[smorzando]], etc.; and terms that combine both, such as [[calando]], [[rubato]], [[morendo]], etc.",
	breadcrumb_and_sort_base = "directives",
	parents = {"music theory"},
}

labels["musical dynamics"] = {
	type = "type",
	description = "=[[musical]] [[dynamic]]s (terms referring to the volume at which a piece is played)",
	additional = "In English this includes Italian-origin terms such as [[pianissimo]], [[mezzo piano]], [[forte]], [[fortississimo]], etc.",
	breadcrumb_and_sort_base = "dynamics",
	parents = {"music theory"},
}

labels["musical intervals"] = {
	type = "type",
	description = "=[[musical]] [[interval]]s",
	additional = "In English this includes terms such as [[fourth]], [[fifth]], [[augmented sixth]], [[tritone]], [[octave]], etc.",
	breadcrumb_and_sort_base = "intervals",
	parents = {"music theory"},
}

labels["musical keys"] = {
	type = "type",
	description = "=[[musical]] [[key]]s",
	additional = "These specify scales beginning at a particular note/pitch, such as (in English) [[F-sharp minor]] and [[E-flat major]], and differ from [[:Category:{{{langcode}}}:Musical pitches]], which specify individual notes.",
	breadcrumb_and_sort_base = "keys",
	parents = {"music theory"},
}

labels["musical mnemonics"] = {
	type = "type",
	description = "=[[musical]] [[mnemonic]]s",
	additional = "In English, this includes terms to aid in remembering sequences such as the notes of a given [[clef]], e.g. [[FACE]], [[EGBDF]] ([[every good boy does fine]], [[every good boy deserves fudge]], etc.) and [[ACEG]] ([[all cows eat grass]], [[all cars eat gas]], etc.).",
	breadcrumb_and_sort_base = "mnemonics",
	parents = {"music theory"},
}

labels["musical modes"] = {
	type = "type",
	description = "=[[musical]] [[mode]]s",
	additional = "In English, this includes terms such as [[Ionian]], [[Dorian]], [[Mixolydian]], [[hypolydian]], etc.",
	breadcrumb_and_sort_base = "modes",
	parents = {"music theory"},
}

labels["musical note durations"] = {
	type = "type",
	description = "=[[musical]] [[note]] [[value]]s or [[duration]]s",
	additional = "In English, this includes American terms such as [[half note]] and [[quarter note]] and British terms such as [[quaver]] and [[crotchet]].",
	breadcrumb_and_sort_base = "note durations",
	parents = {"music theory"},
}

-- FIXME: delete this after renaming to 'musical note durations'
labels["musical notes"] = {
	type = "type",
	description = "=[[musical]] [[note]] [[value]]s or [[duration]]s",
	additional = "In English, this includes American terms such as [[half note]] and [[quarter note]] and British terms such as [[quaver]] and [[crotchet]].",
	breadcrumb_and_sort_base = "notes",
	parents = {"music theory"},
}

labels["musical ornaments"] = {
	type = "type",
	description = "=[[musical]] [[ornament]]s",
	additional = "In English, this includes terms such as [[trill]], [[mordent]], [[tremolo]], [[vibrato]], [[arpeggio]], etc.",
	breadcrumb_and_sort_base = "ornaments",
	parents = {"music theory"},
}

labels["musical pitches"] = {
	type = "type",
	description = "=[[musical]] [[pitch]]es",
	additional = "In English, this includes terms such as [[F-sharp]], [[D-flat]] and [[E]] or [[solfège]] notes like [[do]], [[re]], [[mi]].",
	breadcrumb_and_sort_base = "pitches",
	parents = {"music theory"},
}

labels["musical rests"] = {
	type = "type",
	description = "=[[musical]] [[rest]]s",
	additional = "In English, this includes American terms such as [[half rest]] and [[quarter rest]] and British terms such as [[crotchet rest]] and [[breve rest]].",
	breadcrumb_and_sort_base = "rests",
	parents = {"music theory"},
}

labels["musical scales"] = {
	type = "type",
	description = "=[[musical]] [[scale]]s",
	additional = "In English, this includes terms such as [[major scale]] (or just [[major]]), [[harmonic minor scale]], [[pentatonic scale]] (or just [[pentatonic]]), etc.",
	breadcrumb_and_sort_base = "scales",
	parents = {"music theory"},
}

labels["musical tempos"] = {
	type = "type",
	description = "=[[musical]] [[tempo]]s (terms referring to the speed at which a piece is played)",
	additional = "In English this includes Italian-origin terms such as [[lento]], [[adagio]], [[allegro]], [[vivace]], [[prestissimo]], etc.",
	breadcrumb_and_sort_base = "tempos",
	parents = {"music theory"},
}

-- renamed from 'musical meters'
labels["musical time signatures and meters"] = {
	type = "type",
	description = "=[[musical]] [[time signature]]s and [[meter]]s",
	additional = "In English this includes terms such as [[four-four time]], [[three-quarter time]], [[cut time]], [[common time]], [[alla breve]], [[simple quadruple time]], and corresponding symbols such as [[3/4]], [[6/8]], [[2/2]], etc. In [[music theory]] a distinction is made between a [[meter]] such as [[compound duple]] and the corresponding [[time signature]] of [[6/8]], but the two are frequently [[confused]] or [[conceptually]] [[blend]]ed.", 
	breadcrumb_and_sort_base = "time signatures and meters",
	parents = {"music theory"},
}

labels["musical voices and registers"] = {
	type = "type",
	description = "=[[musical]] [[voice]]s and [[register]]s",
	additional = "In English this includes terms for {{w|voice type}}s such as [[soprano]], [[contralto]], [[countertenor]], [[baritone]], [[basso profondo]], etc. as well as terms for {{w|vocal register}}s such as [[modal voice]], [[falsetto]], [[vocal fry]], [[whistle register]], [[head voice]], etc.",
	breadcrumb_and_sort_base = "voices and registers",
	parents = {"music theory", "singing"},
}

------------------------------------ musicians ------------------------------------

labels["musicians"] = {
	type = "subclassed",
	subclasses = "type,name",
	description = "default",
	parents = {"occupations", "music"},
}

labels["Justin Bieber"] = {
	type = "related-to",
	description = "=Canadian singer {{w|Justin Bieber}}",
	parents = {"n:musicians", "individuals"},
}

labels["Taylor Swift"] = {
	type = "related-to",
	description = "=American singer-songwriter {{w|Taylor Swift}}",
	parents = {"n:musicians", "individuals"},
}

labels["the Beatles"] = {
	type = "related-to",
	description = "=the English rock group {{w|the Beatles}}",
	parents = {"n:musicians", "individuals"},
}

------------------------------------ musical genres ------------------------------------

labels["musical genres"] = {
	type = "type",
	description = "default",
	parents = {"music", "genres"},
}

labels["blues music"] = {
	type = "related-to",
	wikidata = 9759,
	description = "default",
	parents = {"musical genres"},
}

labels["jazz"] = {
	type = "related-to",
	description = "default",
	parents = {"musical genres"},
}

labels["opera"] = {
	type = "related-to",
	description = "default",
	parents = {"theater", "musical genres"},
}

------------------------------------ musical instruments ------------------------------------

for _, instrument_spec in ipairs {
	-- Each element is {"TOPIC", "PARENT" [, "BREADCRUMB"]}
	{"musical instruments", "music", "instruments"},
		{"keyboard instruments", "musical instruments"},
			-- FIXME: rename from 'organ instruments'
			{"musical organs", "keyboard instruments", "organs"},
			{"pianos", "keyboard instruments"},
		{"string instruments", "musical instruments"},
			{"bowed string instruments", "string instruments"},
			{"plucked string instruments", "string instruments"},
				{"guitars", "plucked string instruments"},
		{"percussion instruments", "musical instruments"},
			{"drums", "percussion instruments"},
			{"idiophones", "percussion instruments"},
				-- FIXME, the following may be too specific and is suggested for deletion in [[WT:CLTR]]
				{"gongs", "idiophones"},
		{"wind instruments", "musical instruments"},
			{"brass instruments", "wind instruments"},
			{"woodwind instruments", "wind instruments"},
} do
	local topic, parent, breadcrumb = unpack(instrument_spec)
	local container_parents = parent
	if type(container_parents) == "string" then
		container_parents = {container_parents}
	end
	label[topic] = {
		type = "subclassed",
		subclasses = "type,related-to",
		description = "default",
		breadcrumb_and_sort_base = breadcrumb,
		parents = container_parents,
	}
end

labels["singing voice synthesis"] = {
	type = "related-to",
	description = "default",
	parents = {"musical instruments", "singing"},
}

------------------------------------ music misc ------------------------------------

labels["lutherie"] = {
	type = "related-to",
	description = "default",
	parents = {"music", "crafts"},
}

labels["music industry"] = {
	type = "related-to",
	description = "default with the",
	parents = {"industries", "music"},
}

labels["national anthems"] = {
	type = "name",
	description = "default",
	parents = {"artistic works", "music"},
}


return labels
