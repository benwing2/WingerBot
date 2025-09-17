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
	breadcrumb_and_sort_key = "theory",
	parents = {"music"},
}

------------------------------------ music theory ------------------------------------

labels["Classical music forms"] = {
	type = "type",
	description = "=[[musical]] [[form]]s (terms referring to sequences of chords, particularly in Classical music)",
	additional = "In English this includes terms such as [[deceptive cadence]], [[plagal cadence]] (also just [[plagal]]), [[demicadence]], [[4-3 suspension]], etc.",
	breadcrumb_and_sort_key = "Classical forms",
	parents = {"music theory"},
}

labels["musical articulations"] = {
	type = "type",
	description = "=[[musical]] [[articulation]]s (terms referring to the manner in which notes are [[attack]]ed)",
	additional = "In English this includes Italian-origin terms such as [[legato]], [[staccato]], [[pizzicato]], [[glissando]], [[arpeggiato]], etc.",
	breadcrumb_and_sort_key = "articulations",
	parents = {"music theory"},
}

labels["musical cadences"] = {
	type = "type",
	description = "=[[musical]] [[cadence]]s (terms referring to sequences of chords, particularly in Classical music)",
	additional = "In English this includes terms such as [[deceptive cadence]], [[plagal cadence]] (also just [[plagal]]), [[demicadence]], [[4-3 suspension]], etc.",
	breadcrumb_and_sort_key = "cadences",
	parents = {"music theory"},
}

labels["musical chords"] = {
	type = "type",
	description = "=[[musical]] [[chord]]s",
	additional = "In English this includes terms such as [[major triad]], [[dominant seventh chord]], [[ninth chord]], [[Neapolitan chord]], etc.",
	breadcrumb_and_sort_key = "chords",
	parents = {"music theory"},
}

labels["musical clefs"] = {
	type = "type",
	description = "=[[musical]] [[clef]]s",
	additional = "In English this includes terms such as [[treble clef]] (or just [[treble]]), [[tenor clef]], [[C-clef]]/[[C clef]], etc.",
	breadcrumb_and_sort_key = "clefs",
	parents = {"music theory"},
}

labels["musical directives"] = {
	type = "type",
	description = "=[[musical]] [[directive]]s (terms referring to the how the [[tempo]] and/or [[dynamics]], i.e. speed and/or volume, are changed)",
	additional = "In English this includes Italian-origin terms indicating tempo changes such as [[accelerando]], [[rallentando]], [[stretto]], etc.; terms indicating dynamic changes such as [[crescendo]], [[diminuendo]], [[smorzando]], etc.; and terms that combine both, such as [[calando]], [[rubato]], [[morendo]], etc.",
	breadcrumb_and_sort_key = "directives",
	parents = {"music theory"},
}

labels["musical dynamics"] = {
	type = "type",
	description = "=[[musical]] [[dynamic]]s (terms referring to the volume at which a piece is played)",
	additional = "In English this includes Italian-origin terms such as [[pianissimo]], [[mezzo piano]], [[forte]], [[fortississimo]], etc.",
	breadcrumb_and_sort_key = "dynamics",
	parents = {"music theory"},
}

labels["musical intervals"] = {
	type = "type",
	description = "=[[musical]] [[interval]]s",
	additional = "In English this includes terms such as [[fourth]], [[fifth]], [[augmented sixth]], [[tritone]], [[octave]], etc.",
	breadcrumb_and_sort_key = "intervals",
	parents = {"music theory"},
}

labels["musical keys"] = {
	type = "type",
	description = "=[[musical]] [[key]]s",
	additional = "These specify scales beginning at a particular note/pitch, such as (in English) [[F-sharp minor]] and [[E-flat major]], and differ from [[:Category:{{{langcode}}}:Musical pitches]], which specify individual notes.",
	breadcrumb_and_sort_key = "keys",
	parents = {"music theory"},
}

labels["musical mnemonics"] = {
	type = "type",
	description = "=[[musical]] [[mnemonic]]s",
	additional = "In English, this includes terms to aid in remembering sequences such as the notes of a given [[clef]], e.g. [[FACE]], [[EGBDF]] ([[every good boy does fine]], [[every good boy deserves fudge]], etc.) and [[ACEG]] ([[all cows eat grass]], [[all cars eat gas]], etc.).",
	breadcrumb_and_sort_key = "mnemonics",
	parents = {"music theory"},
}

labels["musical modes"] = {
	type = "type",
	description = "=[[musical]] [[mode]]s",
	additional = "In English, this includes terms such as [[Ionian]], [[Dorian]], [[Mixolydian]], [[hypolydian]], etc.",
	breadcrumb_and_sort_key = "modes",
	parents = {"music theory"},
}

labels["musical note durations"] = {
	type = "type",
	description = "=[[musical]] [[note]] [[value]]s or [[duration]]s",
	additional = "In English, this includes American terms such as [[half note]] and [[quarter note]] and British terms such as [[quaver]] and [[crotchet]].",
	breadcrumb_and_sort_key = "note durations",
	parents = {"music theory"},
}

-- FIXME: delete this after renaming to 'musical note durations'
labels["musical notes"] = {
	type = "type",
	description = "=[[musical]] [[note]] [[value]]s or [[duration]]s",
	additional = "In English, this includes American terms such as [[half note]] and [[quarter note]] and British terms such as [[quaver]] and [[crotchet]].",
	breadcrumb_and_sort_key = "notes",
	parents = {"music theory"},
}

labels["musical ornaments"] = {
	type = "type",
	description = "=[[musical]] [[ornament]]s",
	additional = "In English, this includes terms such as [[trill]], [[mordent]], [[tremolo]], [[vibrato]], [[arpeggio]], etc.",
	breadcrumb_and_sort_key = "ornaments",
	parents = {"music theory"},
}

labels["musical pitches"] = {
	type = "type",
	description = "=[[musical]] [[pitch]]es",
	additional = "In English, this includes terms such as [[F-sharp]], [[D-flat]] and [[E]] or [[solfège]] notes like [[do]], [[re]], [[mi]].",
	breadcrumb_and_sort_key = "pitches",
	parents = {"music theory"},
}

labels["musical rests"] = {
	type = "type",
	description = "=[[musical]] [[rest]]s",
	additional = "In English, this includes American terms such as [[half rest]] and [[quarter rest]] and British terms such as [[crotchet rest]] and [[breve rest]].",
	breadcrumb_and_sort_key = "rests",
	parents = {"music theory"},
}

labels["musical scales"] = {
	type = "type",
	description = "=[[musical]] [[scale]]s",
	additional = "In English, this includes terms such as [[major scale]] (or just [[major]]), [[harmonic minor scale]], [[pentatonic scale]] (or just [[pentatonic]]), etc.",
	breadcrumb_and_sort_key = "scales",
	parents = {"music theory"},
}

labels["musical tempos"] = {
	type = "type",
	description = "=[[musical]] [[tempo]]s (terms referring to the speed at which a piece is played)",
	additional = "In English this includes Italian-origin terms such as [[lento]], [[adagio]], [[allegro]], [[vivace]], [[prestissimo]], etc.",
	breadcrumb_and_sort_key = "tempos",
	parents = {"music theory"},
}

-- renamed from 'musical meters'
labels["musical time signatures and meters"] = {
	type = "type",
	description = "=[[musical]] [[time signature]]s and [[meter]]s",
	additional = "In English this includes terms such as [[four-four time]], [[three-quarter time]], [[cut time]], [[common time]], [[alla breve]], [[simple quadruple time]], and corresponding symbols such as [[3/4]], [[6/8]], [[2/2]], etc. In [[music theory]] a distinction is made between a [[meter]] such as [[compound duple]] and the corresponding [[time signature]] of [[6/8]], but the two are frequently [[confused]] or [[conceptually]] [[blend]]ed.", 
	breadcrumb_and_sort_key = "time signatures and meters",
	parents = {"music theory"},
}

labels["musical voices and registers"] = {
	type = "type",
	description = "=[[musical]] [[voice]]s and [[register]]s",
	additional = "In English this includes terms for {{w|voice type}}s such as [[soprano]], [[contralto]], [[countertenor]], [[baritone]], [[basso profondo]], etc. as well as terms for {{w|vocal register}}s such as [[modal voice]], [[falsetto]], [[vocal fry]], [[whistle register]], [[head voice]], etc.",
	breadcrumb_and_sort_key = "voices and registers",
	parents = {"music theory", "singing"},
}

------------------------------------ musicians ------------------------------------

labels["musicians"] = {
	type = "type",
	description = "default",
	parents = {"occupations", "music"},
}

labels["Justin Bieber"] = {
	type = "related-to",
	description = "=Canadian singer {{w|Justin Bieber}}",
	parents = {"individuals", "music"},
}

labels["Taylor Swift"] = {
	type = "related-to",
	description = "=American singer-songwriter {{w|Taylor Swift}}",
	parents = {"individuals", "music"},
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

labels["musical instruments"] = {
	type = "set",
	description = "default",
	parents = {"tools", "music"},
}

labels["organ instruments"] = {
	type = "type",
	description = "default",
	parents = {"wind instruments"},
}

labels["percussion instruments"] = {
	type = "set",
	description = "default",
	parents = {"musical instruments"},
}

labels["gongs"] = {
	type = "related-to",
	description = "default",
	parents = {"percussion instruments"},
}

labels["string instruments"] = {
	type = "set",
	description = "{{{langname}}} names of [[string instrument]]s.",
	parents = {"musical instruments"},
}

labels["singing voice synthesis"] = {
	type = "related-to",
	description = "default",
	parents = {"musical instruments", "singing"},
}

labels["wind instruments"] = {
	type = "type",
	description = "default",
	parents = {"musical instruments"},
}

labels["woodwind instruments"] = {
	type = "type",
	description = "default",
	parents = {"wind instruments"},
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
