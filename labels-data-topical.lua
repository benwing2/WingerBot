local labels = {}

-- To sort these, you first have to convert each label section into a single line, and then sort the lines, and undo
-- the single-line conversion. This can be done using Vim commands, something like this:
-- 1. Mark the first line to be changed using `ma`.
-- 2. Go to the last line and use `'a,.s/\n/\\n/g` to convert newlines to \n sequences.
-- 3. Use `'a,.s/\\n\\n/\r/g` to convert sequences of two \n's (marking section divisions) back to newlines.
-- 4. Go to the last line again and use `'a,.!sort -f -d` to sort. The `-f` makes it case-insensitive and the `-d`
--    selects "dictionary order", which is needed to get 'yoga' to sort before 'yoga pose' instead of the other way
--    around.
-- 5. Go to the last line again and use `'a,.s/\\n/\r/g` to convert \n sequences back to newlines.
-- 6. Go to the last line again and use `'a,.s/^labels/\rlabels/` to put an extra newline before each section.

labels["3D printing"] = {
	aliases = {"3D printer", "3D printers"},
	Wiktionary = "3D printing#Noun",
	Wikipedia = true,
	Wikidata = "Q229367",
	topical_categories = true,
}

labels["ABDL"] = {
	Wiktionary = true,
	Wikipedia = true,
	topical_categories = true,
}

labels["Abrahamism"] = {
	Wiktionary = "Abrahamism#Noun",
	topical_categories = true,
}

labels["accounting"] = {
	Wiktionary = "accounting#Noun",
	topical_categories = true,
}

labels["acoustics"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["acting"] = {
	Wiktionary = "acting#Noun",
	topical_categories = true,
}

labels["advertising"] = {
	Wiktionary = "advertising#Noun",
	topical_categories = true,
}

labels["aeronautics"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["aerospace"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["aesthetic"] = {
	aliases = {"aesthetics"},
	Wiktionary = true,
	topical_categories = "Aesthetics",
}

labels["agriculture"] = {
	aliases = {"farming"},
	Wiktionary = true,
	topical_categories = true,
}

labels["Ahmadiyya"] = {
	aliases = {"Ahmadiyyat", "Ahmadi"},
	Wiktionary = true,
	topical_categories = true,
}

labels["aircraft"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["alchemy"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["alcoholic beverages"] = {
	aliases = {"alcohol"},
	display = "[[alcoholic#Adjective|alcoholic]] [[beverage]]s",
	topical_categories = true,
}

labels["alcoholism"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["algebra"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["algebraic geometry"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["algebraic topology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["alternative history"] = {
	aliases = {"alt hist", "alternate history"},
	Wikidata = "Q224989",
	topical_categories = true,
}

labels["alternative medicine"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["alt-right"] = {
	aliases = {"Alt-right", "altright", "Altright"},
	Wiktionary = true,
	topical_categories = true,
}

labels["amateur radio"] = {
	aliases = {"ham radio"},
	Wiktionary = true,
	topical_categories = true,
}

labels["American football"] = {
	Wiktionary = true,
	topical_categories = "Football (American)",
}

labels["amino acid"] = {
	display = "[[biochemistry]]",
	topical_categories = "Amino acids",
}

labels["analytic geometry"] = {
	Wiktionary = true,
	topical_categories = "Geometry",
}

labels["analytical chemistry"] = {
	display = "[[analytical]] [[chemistry]]",
	topical_categories = true,
}

labels["anarchism"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["anatomy"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Ancient Greece"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Ancient Rome"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Anglicanism"] = {
	aliases = {"Anglican", "Anglicanist", "Anglican Church"},
	Wiktionary = true,
	topical_categories = true,
}

labels["animation"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["anime"] = {
	Wiktionary = true,
	topical_categories = "Japanese fiction",
}

labels["anthropology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Arabian god"] = {
	display = "[[Arabian]] [[mythology]]",
	topical_categories = "Arabian deities",
}

labels["arachnology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["archaeological culture"] = {
	aliases = {"archeological culture", "archaeological cultures", "archeological cultures"},
	display = "[[archaeology]]",
	topical_categories = "Archaeological cultures",
}

labels["archaeology"] = {
	aliases = {"archeology"},
	Wiktionary = true,
	topical_categories = true,
}

labels["archery"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["architectural element"] = {
	aliases = {"architectural elements"},
	display = "[[architecture]]",
	topical_categories = "Architectural elements",
}

labels["architecture"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Argentine politics"] = {
	aliases = {"Argentina politics", "Argentinian politics"},
	Wikipedia = "Politics of Argentina",
	topical_categories = true,
}

labels["arithmetic"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Armenian mythology"] = {
	display = "[[Armenian]] [[mythology]]",
	topical_categories = true,
}

labels["art"] = {
	aliases = {"arts"},
	Wiktionary = "art#Noun",
	topical_categories = true,
}

labels["Arthurian legend"] = {
	aliases = {"Arthurian mythology"},
	Wikipedia = true,
	topical_categories = "Arthurian mythology",
}

labels["artificial intelligence"] = {
	aliases = {"AI"},
	Wiktionary = true,
	topical_categories = true,
}

labels["artillery"] = {
	display = "[[weaponry]]",
	topical_categories = true,
}

labels["artistic work"] = {
	display = "[[art#Noun|art]]",
	topical_categories = "Artistic works",
}

labels["asterism"] = {
	display = "[[uranography]]",
	topical_categories = "Asterisms",
}

labels["astrology"] = {
	aliases = {"horoscope", "zodiac"},
	Wiktionary = true,
	topical_categories = true,
}

labels["astronautics"] = {
	aliases = {"rocketry"},
	Wiktionary = true,
	topical_categories = true,
}

labels["astronomy"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["astrophysics"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Asturian mythology"] = {
	display = "[[Asturian]] [[mythology]]",
	topical_categories = true,
}

labels["athletics"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Australian Aboriginal mythology"] = {
	Wikipedia = true,
	topical_categories = true,
}

labels["Australian politics"] = {
	Wikipedia = "Politics of Australia",
	topical_categories = true,
}

labels["Australian rules football"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["autism"] = {
	Wiktionary = true,
	Wikipedia = true,
	topical_categories = true,
}

labels["auto parts"] = {
	display = "[[automotive]]",
	topical_categories = true,
}

labels["automotive"] = {
	aliases = {"automotives"},
	Wiktionary = true,
	topical_categories = true,
}

labels["aviation"] = {
	aliases = {"air transport"},
	Wiktionary = true,
	topical_categories = true,
}

labels["backgammon"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["bacteria"] = {
	display = "[[bacteriology]]",
	topical_categories = true,
}

labels["bacteriology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["badminton"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["baking"] = {
	Wiktionary = "baking#Noun",
	topical_categories = true,
}

labels["ball games"] = {
	aliases = {"ball sports"},
	display = "[[ball game]]s",
	topical_categories = true,
}

labels["ballet"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["ballistics"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Bangladeshi politics"] = {
	Wikipedia = "Politics of Bangladesh",
	topical_categories = true,
}

labels["banking"] = {
	Wiktionary = "banking#Noun",
	topical_categories = true,
}

labels["baseball"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["basketball"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["BDSM"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["beekeeping"] = {
	aliases = {"melittology", "apiology", "apidology"}, -- could potentially be split out
	Wiktionary = true,
	topical_categories = true,
}

labels["beer"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["betting"] = {
	display = "[[gambling#Noun|gambling]]",
	topical_categories = true,
}

labels["biblical"] = {
	aliases = {"Bible", "bible", "Biblical"},
	Wiktionary = "Bible",
	topical_categories = "Bible",
}

labels["biblical character"] = {
	aliases = {"Biblical character", "biblical figure", "Biblical figure"},
	display = "[[Bible|biblical]]",
	topical_categories = "Biblical characters",
}

labels["bibliography"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["bicycle parts"] = {
	aliases = {"bicycle part"},
	display = "[[w:List of bicycle parts|cycling]]",
	topical_categories = true,
}

labels["billiards"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["bingo"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["biochemistry"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["biology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["biotechnology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["birdwatching"] = {
	Wiktionary = "birdwatching#Noun",
	topical_categories = true,
}

labels["blacksmithing"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["blogging"] = {
	Wiktionary = "blogging#Noun",
	topical_categories = "Internet",
}

labels["board games"] = {
	aliases = {"board game"},
	display = "[[board game]]s",
	topical_categories = true,
}

labels["board sports"] = {
	Wiktionary = "boardsport",
	topical_categories = true,
}

labels["bodybuilding"] = {
	Wiktionary = "bodybuilding#Noun",
	topical_categories = true,
}

labels["book of the bible"] = {
	display = "[[Bible|biblical]]",
	topical_categories = "Books of the Bible",
}

labels["bookbinding"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["botany"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["bowling"] = {
	Wiktionary = "bowling#Noun",
	topical_categories = true,
}

labels["bowls"] = {
	aliases = {"lawn bowls", "crown green bowls"},
	Wiktionary = true,
	topical_categories = "Bowls (game)",
}

labels["boxing"] = {
	Wiktionary = "boxing#Noun",
	topical_categories = true,
}

labels["brass instruments"] = {
	aliases = {"brass instrument"},
	display = "[[music]]",
	topical_categories = true,
}

labels["Brazilian politics"] = {
	Wikipedia = "Politics of Brazil",
	topical_categories = true,
}

labels["brewing"] = {
	Wiktionary = "brewing#Noun",
	topical_categories = true,
}

labels["bridge"] = {
	Wiktionary = "bridge#English:_game",
	topical_categories = true,
}

labels["broadcasting"] = {
	Wiktionary = "broadcasting#Noun",
	topical_categories = true,
}

labels["bryology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Buddhism"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Buddhist deity"] = {
	aliases = {"Buddhist goddess", "Buddhist god"},
	display = "[[Buddhism]]",
	topical_categories = "Buddhist deities",
}

labels["bullfighting"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["business"] = {
	aliases = {"professional"},
	Wiktionary = true,
	topical_categories = true,
}

labels["Byzantine Empire"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["calculus"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["calligraphy"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Calvinism"] = {
	aliases = {"Calvinist", "Reformed Christianity", "Calvinist Church", "Reformed Church"},
	Wikipedia = true,
	topical_categories = true,
}

labels["Canadian football"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Canadian politics"] = {
	Wikipedia = "Politics of Canada",
	topical_categories = true,
}

labels["Candomblé"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["canid"] = {
	display = "[[zoology]]",
	topical_categories = "Canids",
}

labels["canoeing"] = {
	Wiktionary = "canoeing#Noun",
	topical_categories = "Water sports",
}

labels["capitalism"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["carbohydrate"] = {
	display = "[[biochemistry]]",
	topical_categories = "Carbohydrates",
}

labels["carboxylic acid"] = {
	display = "[[organic chemistry]]",
	topical_categories = "Carboxylic acids",
}

labels["card games"] = {
	aliases = {"cards", "card game", "playing card"},
	display = "[[card game]]s",
	topical_categories = true,
}

labels["cardiology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["carpentry"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["cartography"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["cartomancy"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["castells"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["category theory"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Catholicism"] = {
	aliases = {"catholicism", "Catholic", "catholic"},
	Wiktionary = true,
	topical_categories = true,
}

labels["caving"] = {
	Wiktionary = "caving#Noun",
	topical_categories = true,
}

labels["cellular automata"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Celtic mythology"] = {
	display = "[[Celtic]] [[mythology]]",
	topical_categories = true,
}

labels["ceramics"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["cheerleading"] = {
	Wiktionary = "cheerleading#Noun",
	topical_categories = true,
}

labels["chemical element"] = {
	display = "[[chemistry]]",
	topical_categories = "Chemical elements",
}

labels["chemical engineering"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["chemistry"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["chess"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["children's games"] = {
	display = "[[children|children's]] [[game]]s",
	topical_categories = true,
}

labels["Chilean politics"] = {
	Wikipedia = "Politics of Chile",
	topical_categories = true,
}

labels["Chinese astronomy"] = {
	display = "[[Chinese]] [[astronomy]]",
	topical_categories = true,
}

labels["Chinese calligraphy"] = {
	display = "[[Chinese]] [[calligraphy]]",
	topical_categories = "Calligraphy",
}

labels["Chinese constellation"] = {
	display = "[[Chinese]] [[astronomy]]",
	topical_categories = "Constellations",
}

labels["Chinese folk religion"] = {
	display = "[[Chinese]] [[folk religion]]",
	topical_categories = "Religion",
}

labels["Chinese linguistics"] = {
	display = "[[Chinese]] [[linguistics]]",
	topical_categories = "Linguistics",
}

labels["Chinese mythology"] = {
	display = "[[Chinese]] [[mythology]]",
	topical_categories = true,
}

labels["Chinese philosophy"] = {
	display = "[[Chinese]] [[philosophy]]",
	topical_categories = true,
}

labels["Chinese phonetics"] = {
	display = "[[Chinese]] [[phonetics]]",
	topical_categories = true,
}

labels["Chinese religion"] = {
	display = "[[Chinese]] [[religion]]",
	topical_categories = "Religion",
}

labels["Chinese star"] = {
	display = "[[Chinese]] [[astronomy]]",
	topical_categories = "Stars",
}

labels["Christianity"] = {
	aliases = {"christianity", "Christian", "christian"},
	Wiktionary = true,
	topical_categories = true,
}

labels["Church of England"] = {
	aliases = {"C of E", "CofE"},
	Wikipedia = true,
	topical_categories = true,
}

labels["Church of the East"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["cinematography"] = {
	aliases = {"filmology"},
	Wiktionary = true,
	topical_categories = true,
}

labels["cladistics"] = {
	Wiktionary = true,
	topical_categories = "Taxonomy",
}

labels["classical mechanics"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Classical music form"] = {
	aliases = {"classical music form"},
	display = "[[music theory]]",
	topical_categories = "Classical music forms",
}

labels["Classical music section"] = {
	aliases = {"classical music section"},
	display = "[[music theory]]",
	topical_categories = "Classical music sections",
}

labels["classical studies"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["climate change"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["climatology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["climbing"] = {
	aliases = {"rock climbing"},
	Wiktionary = "climbing#Noun",
	topical_categories = true,
}

labels["clinical psychology"] = {
	display = "[[clinical]] [[psychology]]",
	topical_categories = true,
}

labels["clothing"] = {
	Wiktionary = "clothing#Noun",
	topical_categories = true,
}

labels["cloud computing"] = {
	Wiktionary = true,
	topical_categories = "Computing",
}

labels["cockfighting"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["coenzyme"] = {
	display = "[[biochemistry]]",
	topical_categories = "Coenzymes",
}

labels["coins"] = { -- Do not merge with "numismatics", as the category is different.
	aliases = {"coin"},
	display = "[[numismatics]]",
	topical_categories = true,
}

labels["collectible card games"] = {
	aliases = {"trading card games", "collectible cards", "trading cards"},
	Wikipedia = true,
	topical_categories = true,
}

labels["combinatorics"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["comedy"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["comics"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["commerce"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["commercial law"] = {
	display = "[[commercial#Adjective|commercial]] [[law]]",
	topical_categories = true,
}

labels["communication"] = {
	aliases = {"communications"},
	Wiktionary = true,
	topical_categories = true,
}

labels["communism"] = {
	aliases = {"Communism"},
	Wiktionary = true,
	topical_categories = true,
}

labels["compilation"] = {
	aliases = {"compiler"},
	display = "[[software]] [[compilation]]",
	topical_categories = true,
}

labels["complex analysis"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["computational linguistics"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["computer chess"] = {
	Wiktionary = true,
	topical_categories = true,
}
	

labels["computer games"] = {
	aliases = {"computer game", "computer gaming"},
	display = "[[computer game]]s",
	topical_categories = "Video games",
}

labels["computer graphics"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["computer hardware"] = {
	display = "[[computer]] [[hardware]]",
	topical_categories = true,
}

labels["computer languages"] = {
	aliases = {"computer language", "programming language"},
	display = "[[computer language]]s",
	topical_categories = true,
}

labels["computer science"] = {
	aliases = {"comp sci", "CompSci", "compsci"},
	Wiktionary = true,
	topical_categories = true,
}

labels["computer security"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["computing"] = {
	aliases = {"computer", "computers"},
	Wiktionary = "computing#Noun",
	topical_categories = true,
}

labels["computing theory"] = {
	aliases = {"comptheory", "computability theory"},
	display = "[[computing#Noun|computing]] [[theory]]",
	topical_categories = "Theory of computing",
}

labels["conchology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Confucianism"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["conlanging"] = {
	aliases = {"constructed languages", "constructed language"},
	Wiktionary = true,
	topical_categories = true,
}

labels["conservatism"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["conspiracy theories"] = {
	aliases = {"conspiracy theory", "conspiracy"},
	Wiktionary = "conspiracy theory#Noun",
	topical_categories = true,
}

labels["constellation"] = {
	display = "[[astronomy]]",
	topical_categories = "Constellations",
}

labels["construction"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["control theory"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["cooking"] = {
	aliases = {"culinary", "cuisine", "cookery", "gastronomy"},
	Wiktionary = "cooking#Noun",
	topical_categories = true,
}

labels["cookware"] = {
	aliases = {"bakeware"},
	display = "[[cooking#Noun|cooking]]",
	topical_categories = "Cookware and bakeware",
}

labels["Coptic Orthodoxy"] = {
	aliases = {"Coptic Orthodox", "Coptic Orthodox Church"},
	Wikipedia = true,
	topical_categories = true,
}

labels["copyright"] = {
	aliases = {"copyright law", "intellectual property", "intellectual property law", "IP law"},
	display = "[[copyright]] [[law]]",
	topical_categories = true,
}

labels["copyright license"] = {
	aliases = {"copyright licenses", "license", "copyright licence", "copyright licences", "licence"},
	display = "[[w:Copyright license|copyright law]]",
	Wikipedia = true,
	topical_categories = "Copyright licenses",
}

labels["cosmetics"] = {
	aliases = {"cosmetology"},
	Wiktionary = true,
	topical_categories = true,
}

labels["cosmology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["creationism"] = {
	aliases = {"baraminology"},
	Wiktionary = "creationism#English",
	topical_categories = true,
}

labels["cribbage"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["cricket"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["crime"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["criminal law"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["criminology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["crochet"] = {
	aliases = {"crocheting"},
	Wiktionary = true,
	topical_categories = true,
}

labels["croquet"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["crosswording"] = {
	aliases = {"crosswords","cruciverbalism","cryptic crosswords", "crossword puzzles"},
	Wiktionary = true,
	topical_categories = true,
}

labels["cryptocurrencies"] = {
	aliases = {"cryptocurrency"},
	Wiktionary = "cryptocurrency",
	topical_categories = "Cryptocurrency",
}

labels["cryptography"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["cryptozoology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["crystallography"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["cultural anthropology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["curling"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["currencies"] = { -- Do not merge with "numismatics", as the category is different.
	aliases = {"currency"},
	display = "[[numismatics]]",
	topical_categories = true,
}

labels["cybernetics"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["cybersecurity"] = {
	Wiktionary = true,
	topical_categories = "Networking",
}

labels["cycle racing"] = {
	Wikipedia = "cycle sport",
	topical_categories = true,
}

labels["cycling"] = {
	aliases = {"bicycling"},
	Wiktionary = "cycling#Noun",
	topical_categories = true,
}

labels["cytology"] = {
	aliases = {"cell biology", "cellular biology"},
	Wiktionary = true,
	topical_categories = true,
}

labels["dance"] = {
	aliases = {"dancing"},
	Wiktionary = "dance#Noun",
	topical_categories = true,
}

labels["dances"] = {
	display = "[[dance#Noun|dance]]",
	topical_categories = true,
}

labels["darts"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["data management"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["data modeling"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["databases"] = {
	aliases = {"database"},
	display = "[[database]]s",
	topical_categories = true,
}

labels["decision theory"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["deltiology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["demography"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["demonym"] = {
	Wiktionary = true,
	topical_categories = "Demonyms",
}

labels["demoscene"] = {
	topical_categories = true,
}

labels["dentistry"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["dermatology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["design"] = {
	Wiktionary = "design#Noun",
	topical_categories = true,
}

labels["dice games"] = {
	aliases = {"dice"},
	display = "[[dice game]]s",
	topical_categories = true,
}

labels["dictation"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["differential geometry"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["diplomacy"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["disc golf"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["disease"] = {
	aliases = {"diseases"},
	display = "[[pathology]]",
	topical_categories = "Diseases",
}

labels["divination"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["diving"] = {
	Wiktionary = "diving#Noun",
	topical_categories = true,
}

labels["dominoes"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["dou dizhu"] = {
	Wikipedia = true,
	topical_categories = true,
}

labels["drama"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["dressage"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["drums"] = {
	aliases = {"drum"},
	display = "[[music]]",
	topical_categories = true,
}

labels["E number"] = {
	display = "[[food]] [[manufacture]]",
	plain_categories = "European food additive numbers",
}

labels["early Christianity"] = {
	aliases = {"early christianity", "Early Christianity", "early Church", "early church", "Early Church", "the early Church", "the early church", "the Early Church"},
	Wikipedia = true,
	topical_categories = true,
}

labels["earth science"] = {
	Wiktionary = true,
	topical_categories = "Earth sciences",
}

labels["Eastern Catholicism"] = {
	aliases = {"Eastern Catholic"},
	Wikipedia = true,
	topical_categories = true,
}

labels["Eastern Christianity"] = {
	aliases = {"Eastern christianity", "Eastern Christian", "Eastern christian", "Eastern Church", "Eastern church"},
	Wikipedia = true,
	topical_categories = true,
}

labels["Eastern Orthodoxy"] = {
	aliases = {"Eastern Orthodox", "Eastern Orthodox Church"},
	Wikipedia = true,
	topical_categories = true,
}

labels["eating disorders"] = {
	aliases = {"eating disorder"},
	display = "[[eating disorder]]s",
	topical_categories = true,
}

labels["ecology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["economics"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["education"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Egyptian god"] = {
	aliases = {"Egyptian goddess", "Egyptian deity"},
	display = "[[Egyptian]] [[mythology]]",
	topical_categories = "Egyptian deities",
}

labels["Egyptian mythology"] = {
	display = "[[Egyptian]] [[mythology]]",
	topical_categories = true,
}

labels["Egyptology"] = {
	Wiktionary = true,
	topical_categories = "Ancient Egypt",
}

labels["electrencephalography"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["electrical engineering"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["electricity"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["electrodynamics"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["electromagnetism"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["electronics"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["element symbol"] = {
	-- Compare "systematic element symbol" and "obsolete element symbol".
	display = "[[chemistry]]",
	plain_categories = "Symbols for chemical elements",
}

labels["embryology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["emergency medicine"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["emergency services"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["endocrinology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["engineering"] = {
	Wiktionary = "engineering#Noun",
	topical_categories = true,
}

labels["enterprise engineering"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["entomology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["enzyme"] = {
	display = "[[biochemistry]]",
	topical_categories = "Enzymes",
}

labels["epidemiology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["epistemology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["equestrianism"] = {
	aliases = {"equestrian", "horses", "horsemanship"},
	Wiktionary = true,
	topical_categories = true,
}

labels["espionage"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["ethics"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["ethnography"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["ethology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["EU politics"] = {
	Wikipedia = "Politics of the European Union",
	topical_categories = true,
}

labels["European folklore"] = {
	display = "[[European]] [[folklore]]",
	topical_categories = true,
}

labels["European politics"] = {
	Wikipedia = "Politics of Europe",
	topical_categories = true,
}

labels["European Union"] = {
	aliases = {"EU"},
	Wiktionary = true,
	topical_categories = true,
}

labels["Evangelicalism"] = {
	aliases = {"Evangelical", "evangelical", "Evangelical Christianity", "Evangelical Christian", "Evangelical Protestantism", "Evangelical Protestant"},
	Wikipedia = true,
	topical_categories = true,
}

labels["evolutionary theory"] = {
	aliases = {"evolutionary biology"},
	Wiktionary = true,
	topical_categories = true,
}

labels["exercise"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["eye color"] = {
	display = "[[eye]] [[color]]",
	topical_categories = "Eye colors",
}

labels["eyewear"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["fairy tale"] = { -- names of fairy tales
	aliases = {"fairytale", "fairy-tale"},
	Wiktionary = true,
	topical_categories = true,
}

labels["fairy tales"] = { -- relating to fairy tales
	aliases = {"fairytales", "fairy-tales"},
	Wiktionary = true,
	topical_categories = true,
}

labels["falconry"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["fantasy"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["farriery"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["fascism"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["fashion"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["fatty acid"] = {
	display = "[[organic chemistry]]",
	topical_categories = "Fatty acids",
}

labels["felid"] = {
	aliases = {"cat"},
	display = "[[zoology]]",
	topical_categories = "Felids",
}

labels["feminism"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["fencing"] = {
	Wiktionary = "fencing#Noun",
	topical_categories = true,
}

labels["feudalism"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["fiction"] = {
	aliases = {"fictional"},
	Wiktionary = true,
	topical_categories = true,
}

labels["fictional character"] = {
	display = "[[fiction]]",
	topical_categories = "Fictional characters",
}

labels["field hockey"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["figure of speech"] = {
	display = "[[rhetoric]]",
	topical_categories = "Figures of speech",
}

labels["figure skating"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["file format"] = {
	Wiktionary = true,
	topical_categories = "File formats",
}

labels["film"] = {
	Wiktionary = "film#Noun",
	topical_categories = true,
}

labels["film genre"] = {
	aliases = {"cinema"},
	display = "[[film#Noun|film]]",
	topical_categories = "Film genres",
}

labels["finance"] = {
	Wiktionary = "finance#Noun",
	topical_categories = true,
}

labels["Finnic mythology"] = {
	aliases = {"Finnish mythology"},
	display = "[[Finnic]] [[mythology]]",
	topical_categories = true,
}

labels["firearms"] = {
	aliases = {"firearm"},
	display = "[[firearm]]s",
	topical_categories = true,
}

labels["firefighting"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["fish"] = {
	display = "[[zoology]]",
	topical_categories = true,
}

labels["fishing"] = {
	aliases = {"angling"},
	Wiktionary = "fishing#Noun",
	topical_categories = true,
}

labels["flamenco"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["fluid dynamics"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["fluid mechanics"] = {
	Wiktionary = true,
	topical_categories = "Mechanics",
}

labels["folklore"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["footwear"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["forestry"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Forteana"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Freemasonry"] = {
	aliases = {"freemasonry"},
	Wiktionary = true,
	topical_categories = true,
}

labels["French politics"] = {
	Wikipedia = "Politics of France",
	topical_categories = true,
}

labels["functional analysis"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["functional group prefix"] = {
	display = "[[organic chemistry]]",
	topical_categories = "Functional group prefixes",
}

labels["functional group suffix"] = {
	display = "[[organic chemistry]]",
	topical_categories = "Functional group suffixes",
}

labels["functional programming"] = {
	Wiktionary = true,
	topical_categories = "Programming",
}

labels["furniture"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["furry fandom"] = {
	aliases = {"furry", "furry community", "fursuit", "kemonā", "kemona", "kemono", "kemonomimi"},
	display = "[[furry#Noun|furry]] [[fandom]]",
	topical_categories = true,
}

labels["fuzzy logic"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Gaelic football"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["galaxy"] = {
	display = "[[astronomy]]",
	topical_categories = "Galaxies",
}

labels["gambling"] = {
	Wiktionary = "gambling#Noun",
	topical_categories = true,
}

labels["game theory"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["games"] = {
	aliases = {"game"},
	Wiktionary = "game#Noun",
	topical_categories = true,
}

labels["gaming"] = {
	Wiktionary = "gaming#Noun",
	topical_categories = true,
}

labels["gender critical"] = {
	aliases = {"gender-critical", "gender critical feminism", "gender-critical feminism", "GC", "GCF", "trans-exclusionary radical feminism", "TERF", "TERFism"},
	Wiktionary = "gender-critical#Adjective",
	Wikipedia = "Gender-critical feminism",
	topical_categories = "Gender-critical feminism",
}

labels["genealogy"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["general semantics"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["genetic disorder"] = {
	display = "[[medical]] [[genetics]]",
	topical_categories = "Genetic disorders",
}

labels["genetics"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["geography"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["geological period"] = {
	Wikipedia = true,
	topical_categories = "Geological periods",
}

labels["geology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["geometry"] = {
	aliases = {"geometric", "geometrical"},
	Wiktionary = true,
	topical_categories = true,
}

labels["geomorphology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["geopolitics"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["German politics"] = {
	Wikipedia = "Politics of Germany",
	topical_categories = true,
}

labels["Germanic paganism"] = {
	aliases = {"Asatru", "Ásatrú", "Germanic neopaganism", "Germanic Paganism", "Heathenry", "heathenry", "Norse neopaganism", "Norse paganism"},
	display = "[[Germanic#Adjective|Germanic]] [[paganism]]",
	topical_categories = true,
}

labels["gerontology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["gladiatorial combat"] = {
	Wikipedia = true,
	topical_categories = true,
}

labels["glassblowing"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Gnosticism"] = {
	aliases = {"gnosticism"},
	Wiktionary = true,
	topical_categories = true,
}

labels["go"] = {
	aliases = {"Go", "game of go", "game of Go"},
	display = "{{l|en|go|id=game}}",
	topical_categories = true,
}

labels["golf"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["government"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["grammar"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["grammatical case"] = {
	display = "[[grammar]]",
	topical_categories = "Grammatical cases",
}

labels["grammatical mood"] = {
	display = "[[grammar]]",
	topical_categories = "Grammatical moods",
}

labels["graph theory"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["graphic design"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["graphical user interface"] = {
	aliases = {"GUI"},
	Wiktionary = true,
	topical_categories = true,
}

labels["Greek god"] = {
	aliases = {"Greek goddess"},
	display = "[[Greek]] [[mythology]]",
	topical_categories = "Greek deities",
}

labels["Greek mythology"] = {
	display = "[[Greek]] [[mythology]]",
	topical_categories = true,
}

labels["Greek Orthodoxy"] = {
	aliases = {"Greek Orthodox", "Greek Orthodox Church"},
	Wikipedia = true,
	topical_categories = true,
}

labels["group theory"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["gun mechanisms"] = {
	aliases = {"firearm mechanism", "firearm mechanisms", "gun mechanism"},
	display = "[[firearm]]s",
	topical_categories = true,
}

labels["gun sports"] = {
	aliases = {"shooting sports"},
	display = "[[gun]] [[sport]]s",
	topical_categories = true,
}

labels["gymnastics"] = {
	Wiktionary = true,
	Wikipedia = true,
	topical_categories = true,
}

labels["gynaecology"] = {
	aliases = {"gynecology"},
	Wiktionary = true,
	topical_categories = true,
}

labels["hair color"] = {
	display = "[[hair]] [[color]]",
	topical_categories = "Hair colors",
}

labels["hairdressing"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["hand games"] = {
	aliases = {"hand game"},
	display = "[[hand]] [[game]]s",
	topical_categories = true,
}

labels["handball"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Hawaiian mythology"] = {
	display = "[[Hawaiian]] [[mythology]]",
	topical_categories = true,
}

labels["headwear"] = {
	display = "[[clothing#Noun|clothing]]",
	topical_categories = true,
}

labels["healthcare"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["helminthology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["hematology"] = {
	aliases = {"haematology"},
	Wiktionary = true,
	topical_categories = true,
}

labels["heraldic charge"] = {
	aliases = {"heraldiccharge"},
	display = "[[heraldry]]",
	topical_categories = "Heraldic charges",
}

labels["heraldry"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["herbalism"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["herpetology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Hindu god"] = {
	display = "[[Hinduism]]",
	topical_categories = "Hindu deities",
}

labels["Hinduism"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Hindutva"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["historical currencies"] = {
	aliases = {"historical currency"},
	display = "[[numismatics]]",
	sense_categories = "historical",
	topical_categories = "Historical currencies",
}

labels["historical linguistics"] = {
	Wiktionary = true,
	topical_categories = "Linguistics",
}

labels["historical period"] = {
	aliases = {"historical periods"},
	display = "[[history]]",
	topical_categories = "Historical periods",
}

labels["historiography"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["history"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["hockey"] = {
	display = "[[field hockey]] or [[ice hockey]]",
	topical_categories = {"Field hockey", "Ice hockey"},
}

labels["homeopathy"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Hong Kong politics"] = {
	aliases = {"HK politics"},
	Wikipedia = "Politics of Hong Kong",
	topical_categories = true,
}

labels["hormone"] = {
	display = "[[biochemistry]]",
	topical_categories = "Hormones",
}

labels["horse color"] = {
	display = "[[horse]] [[color]]",
	topical_categories = "Horse colors",
}

labels["horse racing"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["horticulture"] = {
	aliases = {"gardening"},
	Wiktionary = true,
	topical_categories = true,
}

labels["HTML"] = {
	Wiktionary = "Hypertext Markup Language",
	topical_categories = true,
}

labels["human resources"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["humanities"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["hunting"] = {
	Wiktionary = "hunting#Noun",
	topical_categories = true,
}

labels["hurling"] = {
	Wiktionary = "hurling#Noun",
	topical_categories = true,
}

labels["hydroacoustics"] = {
	Wikipedia = true,
	topical_categories = true,
}

labels["hydrocarbon chain prefix"] = {
	display = "[[organic chemistry]]",
	topical_categories = "Hydrocarbon chain prefixes",
}

labels["hydrocarbon chain suffix"] = {
	display = "[[organic chemistry]]",
	topical_categories = "Hydrocarbon chain suffixes",
}

labels["hydrology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["ice hockey"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["ichthyology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["idol fandom"] = {
	display = "[[idol]] [[fandom]]",
	topical_categories = true,
}

labels["immunochemistry"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["immunology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["import/export"] = {
	display = "[[import#Noun|import]]/[[export#Noun|export]]",
	topical_categories = true,
}

labels["incoterm"] = {
	display = "[[Incoterm]]",
	topical_categories = "Incoterms",
}

labels["Indian politics"] = {
	Wikipedia = "Politics of India",
	topical_categories = true,
}

labels["Indo-European studies"] = {
	aliases = {"indo-european studies"},
	Wiktionary = true,
	topical_categories = true,
}

labels["Indonesian politics"] = {
	aliases = {"Indonesia politics"},
	Wikipedia = "Politics of Indonesia",
	topical_categories = true,
}

labels["information science"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["information technology"] = {
	aliases = {"IT"},
	Wiktionary = true,
	topical_categories = "Computing",
}

labels["information theory"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["inheritance law"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["inorganic chemistry"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["inorganic compound"] = {
	display = "[[inorganic chemistry]]",
	topical_categories = "Inorganic compounds",
}

labels["insurance"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["international law"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["international relations"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["international standards"] = {
	aliases = {"international standard", "ISO", "International Organization for Standardization", "International Organisation for Standardisation"},
	Wikipedia = "International standard",
}

labels["Internet"] = {
	aliases = {"internet", "online"},
	Wiktionary = true,
	topical_categories = true,
}

labels["Iranian mythology"] = {
	display = "[[Iranian]] [[mythology]]",
	topical_categories = true,
}

labels["Irish mythology"] = {
	display = "[[Irish]] [[mythology]]",
	topical_categories = true,
}

labels["Irish politics"] = {
	Wikipedia = "Politics of the Republic of Ireland",
	topical_categories = true,
}

labels["Islam"] = {
	aliases = {"islam", "Islamic", "Muslim"},
	Wikipedia = true,
	topical_categories = true,
}

labels["Islamic finance"] = {
	aliases = {"Islamic banking", "Muslim finance", "Muslim banking", "Sharia-compliant finance"},
	Wikipedia = true,
	topical_categories = true,
}

labels["Islamic law"] = {
	aliases = {"Islamic legal", "Sharia"},
	Wikipedia = true,
	topical_categories = true,
}

labels["isotope"] = {
	display = "[[physics]]",
	topical_categories = "Isotopes",
}

labels["Jainism"] = {
	Wiktionary = true,
	Wikipedia = true,
	topical_categories = true,
}

labels["Japanese fiction"] = {
	-- aliases = {"anime", "manga", "anime and manga", "manga and anime"},
	display = "[[Japanese#Adjective|Japanese]] [[fiction]]",
	Wikipedia = true,
	topical_categories = true,
}

labels["Japanese god"] = {
	display = "[[Japanese#Adjective|Japanese]] [[mythology]]",
	topical_categories = "Japanese deities",
}

labels["Japanese mythology"] = {
	display = "[[Japanese#Adjective|Japanese]] [[mythology]]",
	topical_categories = true,
}

labels["Japanese politics"] = {
	Wikipedia = "Politics of Japan",
	topical_categories = true,
}

labels["Japanese pornography"] = {
	aliases = {"Japanese porn", "hentai", "adult anime", "erotic anime", "ero anime"},
	display = "[[Japanese#Adjective|Japanese]] [[pornography]]",
	Wikipedia = true,
	topical_categories = true,
}

labels["Java programming language"] = {
	aliases = {"JavaPL", "Java PL"},
	Wikipedia = "Java (programming language)",
	topical_categories = true,
}

labels["jazz"] = {
	Wiktionary = "jazz#Noun",
	topical_categories = true,
}

labels["jewelry"] = {
	aliases = {"jewellery"},
	Wiktionary = true,
	topical_categories = true,
}

labels["Jewish law"] = {
	aliases = {"Halacha", "Halachah", "Halakha", "Halakhah", "halacha", "halachah", "halakha", "halakhah", "Jewish Law", "jewish law"},
	display = "[[Jewish]] [[law]]",
	topical_categories = true,
}

labels["journalism"] = {
	Wiktionary = true,
	topical_categories = "Mass media",
}

labels["Judaism"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["judo"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["juggling"] = {
	Wiktionary = "juggling#Noun",
	topical_categories = true,
}

labels["karuta"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["kendo"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["keyboard instruments"] = {
	aliases = {"keyboard instrument"},
	display = "[[music]]",
	topical_categories = true,
}

labels["knitting"] = {
	Wiktionary = "knitting#Noun",
	topical_categories = true,
}

labels["labour"] = {
	aliases = {"labor", "labour movement", "labor movement"},
	Wiktionary = true,
	topical_categories = true,
}

labels["labour law"] = {
	Wiktionary = true,
	topical_categories = "Law",
}

labels["lacrosse"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["landforms"] = {
	display = "[[geography]]",
	topical_categories = true,
}

labels["law"] = {
	aliases = {"legal"},
	Wiktionary = "law#English",
	topical_categories = true,
}

labels["law enforcement"] = {
	aliases = {"police", "policing"},
	Wiktionary = true,
	topical_categories = true,
}

labels["leatherworking"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["leftism"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["letterpress"] = {
	aliases = {"metal type", "metal typesetting"},
	display = "[[letterpress]] [[typography]]",
	topical_categories = "Typography",
}

labels["lexicography"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["LGBTQ"] = {
	aliases = {"LGBT", "LGBT+", "LGBT*", "LGBTQ+", "LGBTQ*", "LGBTQIA", "LGBTQIA+", "LGBTQIA*"},
	Wiktionary = true,
	topical_categories = true,
}

labels["liberalism"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["library science"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["lichenology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["limnology"] = {
	Wiktionary = true,
	topical_categories = "Ecology",
}

labels["linear algebra"] = {
	aliases = {"vector algebra"},
	Wiktionary = true,
	topical_categories = true,
}

labels["linguistic morphology"] = {
	display = "[[linguistic]] [[morphology]]",
	topical_categories = true,
}

labels["linguistics"] = {
	aliases = {"linguistic", "philology"},
	Wiktionary = true,
	topical_categories = true,
}

labels["lipid"] = {
	display = "[[biochemistry]]",
	topical_categories = "Lipids",
}

labels["literature"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["logic"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["logical fallacy"] = {
	display = "[[rhetoric]]",
	topical_categories = "Logical fallacies",
}

labels["logistics"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["luge"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Lutheranism"] = {
	aliases = {"Lutheran", "Lutheranist", "Lutheran Church"},
	Wikipedia = true,
	topical_categories = true,
}

labels["lutherie"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["machine learning"] = {
	aliases = {"ML"},
	Wiktionary = true,
	topical_categories = true,
}

labels["machining"] = {
	Wiktionary = "machining#Noun",
	topical_categories = true,
}

labels["macroeconomics"] = {
	Wiktionary = true,
	topical_categories = "Economics",
}

labels["mahjong"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["malacology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Malaysian politics"] = {
	aliases = {"Malaysia politics"},
	Wikipedia = "Politics of Malaysia",
	topical_categories = true,
}

labels["mammalogy"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["management"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["manga"] = {
	Wiktionary = true,
	topical_categories = "Japanese fiction",
}

labels["manhua"] = {
	Wiktionary = true,
	topical_categories = "Chinese fiction",
}

labels["manhwa"] = {
	Wiktionary = true,
	topical_categories = "Korean fiction",
}

labels["Manichaeism"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["manufacturing"] = {
	Wiktionary = "manufacturing#Noun",
	topical_categories = true,
}

labels["Maoism"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["marching"] = {
	Wiktionary = "marching#Noun",
	topical_categories = true,
}

labels["marine biology"] = {
	aliases = {"coral science"},
	Wiktionary = true,
	topical_categories = true,
}

labels["marketing"] = {
	Wiktionary = "marketing#Noun",
	topical_categories = true,
}

labels["martial arts"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Marxism"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["masonry"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["massage"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["materials science"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["mathematical analysis"] = {
	aliases = {"analysis"},
	Wiktionary = true,
	topical_categories = true,
}

labels["mathematics"] = {
	aliases = {"math", "maths"},
	Wiktionary = true,
	topical_categories = true,
}

labels["measure theory"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["mechanical engineering"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["mechanics"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["media"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["mediaeval folklore"] = {
	aliases = {"medieval folklore"},
	display = "[[mediaeval]] [[folklore]]",
	topical_categories = "European folklore",
}

labels["medical genetics"] = {
	display = "[[medical]] [[genetics]]",
	topical_categories = true,
}

labels["medical sign"] = {
	display = "[[medicine]]",
	topical_categories = "Medical signs and symptoms",
}

labels["medicine"] = {
	aliases = {"medical"},
	Wiktionary = true,
	topical_categories = true,
}

labels["Meitei god"] = {
	display = "[[Meitei]] [[mythology]]",
	topical_categories = "Meitei deities",
}

labels["mental health"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Mesopotamian god"] = {
	display = "[[Mesopotamian]] [[mythology]]",
	topical_categories = "Mesopotamian deities",
}

labels["Mesopotamian mythology"] = {
	display = "[[Mesopotamian]] [[mythology]]",
	topical_categories = true,
}

labels["metadata"] = {
	Wiktionary = true,
	topical_categories = "Data management",
}

labels["metallurgy"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["metalworking"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["metamaterial"] = {
	display = "[[physics]]",
	topical_categories = "Metamaterials",
}

labels["metaphysics"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["meteorology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Methodism"] = {
	aliases = {"Methodist", "methodism", "methodist"},
	Wiktionary = true,
	topical_categories = true,
}

labels["metrology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Mexican politics"] = {
	aliases = {"Mexico politics"},
	Wikipedia = "Politics of Mexico",
	topical_categories = true,
}

labels["microbiology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["microelectronics"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["micronationalism"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["microscopy"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["military"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["military ranks"] = {
	aliases = {"military rank"},
	display = "[[military]]",
	topical_categories = true,
}

labels["military unit"] = {
	display = "[[military]]",
	topical_categories = "Military units",
}

labels["milling"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Minecraft"] = {
	display = "''[[Minecraft]]''",
	topical_categories = true,
}

labels["mineral"] = {
	display = "[[mineralogy]]",
	topical_categories = "Minerals",
}

labels["mineralogy"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["mining"] = {
	Wiktionary = "mining#Noun",
	topical_categories = true,
}

labels["mobile phones"] = {
	aliases = {"cell phone", "cell phones", "mobile phone", "mobile telephony"},
	display = "[[mobile telephone|mobile telephony]]",
	topical_categories = true,
}

labels["molecular biology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["monarchy"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["money"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Mormonism"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["motor racing"] = {
	-- There are other types of racing, but 99% of the time "racing" on its own refers to motorsports.
	aliases = {"motor sport", "motorsport", "motorsports", "racing"},
	Wiktionary = true,
	topical_categories = true,
}

labels["motorcycling"] = {
	aliases = {"motorcycle", "motorcycles", "motorbike"},
	Wiktionary = "motorcycling#Noun",
	topical_categories = "Motorcycles",
}

labels["multiplicity"] = {
	display = "{{l|en|multiplicity|id=multiple personalities}}",
	topical_categories = "Multiplicity (psychology)",
}

labels["muscle"] = {
	display = "[[anatomy]]",
	topical_categories = "Muscles",
}

labels["mushroom"] = {
	aliases = {"mushrooms"},
	display = "[[mycology]]",
	topical_categories = "Mushrooms",
}

labels["music"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["music genre"] = {
	aliases = {"musical genre"},
	display = "[[music]]",
	topical_categories = "Musical genres",
}

labels["music industry"] = {
	Wikipedia = true,
	topical_categories = true,
}

labels["music theory"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["musical articulation"] = {
	display = "[[music theory]]",
	topical_categories = "Musical articulations",
}

labels["musical cadence"] = {
	display = "[[music theory]]",
	topical_categories = "Musical cadences",
}

labels["musical chord"] = {
	display = "[[music theory]]",
	topical_categories = "Musical chords",
}

labels["musical clef"] = {
	display = "[[music theory]]",
	topical_categories = "Musical clefs",
}

labels["musical directive"] = {
	display = "[[music theory]]",
	topical_categories = "Musical directives",
}

labels["musical dynamic"] = {
	display = "[[music theory]]",
	topical_categories = "Musical dynamics",
}

labels["musical instruments"] = {
	aliases = {"musical instrument"},
	display = "[[music]]",
	topical_categories = true,
}

labels["musical interval"] = {
	display = "[[music theory]]",
	topical_categories = "Musical intervals",
}

labels["musical key"] = {
	display = "[[music theory]]",
	topical_categories = "Musical keys",
}

labels["musical mnemonic"] = {
	display = "[[music theory]]",
	topical_categories = "Musical mnemonics",
}

labels["musical mode"] = {
	display = "[[music theory]]",
	topical_categories = "Musical modes",
}

labels["musical note duration"] = {
	display = "[[music theory]]",
	topical_categories = "Musical note durations",
}

labels["musical ornament"] = {
	display = "[[music theory]]",
	topical_categories = "Musical ornaments",
}

labels["musical pitch"] = {
	aliases = {"solfège note", "solfege note"},
	display = "[[music theory]]",
	topical_categories = "Musical pitches",
}

labels["musical rest"] = {
	display = "[[music theory]]",
	topical_categories = "Musical rests",
}

labels["musical scale"] = {
	display = "[[music theory]]",
	topical_categories = "Musical scales",
}

labels["musical symbol"] = {
	display = "[[music theory]]",
	topical_categories = "Musical symbols",
}

labels["musical tempo"] = {
	display = "[[music theory]]",
	topical_categories = "Musical tempos",
}

labels["musical time signature"] = {
	aliases = {"musical meter", "musical metre"},
	display = "[[music theory]]",
	topical_categories = "Musical time signatures and meters",
}

labels["musical voice type"] = {
	aliases = {"musical vocal type", "musical register"},
	display = "[[music theory]]",
	topical_categories = "Musical voices and registers",
}

labels["musician"] = {
	display = "[[music]]",
	topical_categories = "Musicians",
}

labels["musicology"] = {
	Wiktionary = true,
	topical_categories = "Music",
}

labels["mycology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["mysticism"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["mythological creature"] = {
	aliases = {"mythological creatures"},
	display = "[[mythology]]",
	topical_categories = "Mythological creatures",
}

labels["mythology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["named musician"] = {
	display = "[[music]]",
	topical_categories = "Named musicians",
}

labels["nanotechnology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["narratology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["nautical"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Navajo mythology"] = {
	display = "[[Navajo]] [[mythology]]",
	topical_categories = true,
}

labels["navigation"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Nazism"] = { -- see also Neo-Nazism
	aliases = {"nazism", "Nazi", "nazi", "Nazis", "nazis"},
	Wikipedia = true,
	topical_categories = true,
}

labels["nematology"] = {
	Wiktionary = true,
	topical_categories = "Zoology",
}

labels["neo-Nazism"] = { -- Often used to indicate Nazi-used jargon; compare "white supremacist ideology"
	aliases = {"Neo-Nazism", "Neo-nazism", "neo-nazism", "Neo-Nazi", "Neo-nazi", "neo-Nazi", "neo-nazi", "Neo-Nazis", "Neo-nazis", "neo-Nazis", "neo-nazis", "NeoNazism", "Neonazism", "neoNazism", "neonazism", "NeoNazi", "Neonazi", "neoNazi", "neonazi", "NeoNazis", "Neonazis", "neoNazis", "neonazis"},
	Wikipedia = true,
	topical_categories = true,
}

labels["netball"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["networking"] = {
	Wiktionary = "networking#Noun",
	topical_categories = true,
}

labels["neuroanatomy"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["neurology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["neuroscience"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["neurosurgery"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["neurotoxin"] = {
	display = "[[neurotoxicology]]",
	topical_categories = "Neurotoxins",
}

labels["neurotransmitter"] = {
	display = "[[biochemistry]]",
	topical_categories = "Neurotransmitters",
}

labels["New Zealand politics"] = {
	Wikipedia = "Politics of New Zealand",
	topical_categories = true,
}

labels["newspapers"] = {
	display = "[[newspaper]]s",
	topical_categories = true,
}

labels["Norse god"] = {
	aliases = {"Norse goddess", "Norse deity"},
	display = "[[Norse]] [[mythology]]",
	topical_categories = "Norse deities",
}

labels["Norse mythology"] = {
	display = "[[Norse]] [[mythology]]",
	topical_categories = true,
}

labels["nuclear energy"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["nuclear physics"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["number theory"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["numismatics"] = {
	Wiktionary = true,
	topical_categories = "Currency",
}

labels["nutrition"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["object-oriented programming"] = {
	aliases = {"object-oriented", "OOP"},
	Wiktionary = true,
	topical_categories = true,
}

labels["obsolete element symbol"] = {
	display = "[[chemistry]], [[obsolete]]",
	plain_categories = "Obsolete symbols for chemical elements",
}

labels["obstetrics"] = {
	aliases = {"obstetric"},
	Wiktionary = true,
	topical_categories = true,
}

labels["occult"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["oceanography"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Odinani"] = {
	aliases = {"Odinala", "Omenala", "Odinana", "Omenana", "Igbo religion"},
	Wikipedia = true,
	topical_categories = true,
}

labels["oenology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["oil industry"] = {
	aliases = {"oil", "oil drilling", "petroleum industry", "petroleum"},
	Wikipedia = true,
	topical_categories = true,
}

labels["oncology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["online gaming"] = {
	aliases = {"online games", "MMO", "MMORPG"},
	display = "[[online]] [[gaming#Noun|gaming]]",
	topical_categories = "Video games",
}

labels["onomastics"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["opera"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["operating systems"] = {
	display = "[[operating system]]s",
	topical_categories = "Software",
}

labels["ophthalmology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["optics"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["organic chemistry"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["organic compound"] = {
	display = "[[organic chemistry]]",
	topical_categories = "Organic compounds",
}

labels["Oriental Orthodoxy"] = {
	aliases = {"Oriental Orthodox", "Oriental Orthodox Church"},
	Wikipedia = true,
	topical_categories = true,
}

labels["ornithology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["orthodontics"] = {
	Wiktionary = true,
	topical_categories = "Dentistry",
}

labels["orthography"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["paganism"] = {
	aliases = {"pagan", "neopagan", "neopaganism", "neo-pagan", "neo-paganism"},
	Wiktionary = true,
	topical_categories = true,
}

labels["pain"] = {
	display = "[[medicine]]",
	topical_categories = true,
}

labels["paintball"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["painting"] = {
	Wiktionary = "painting#Noun",
	topical_categories = true,
}

labels["Pakistani politics"] = {
	Wikipedia = "Politics of Pakistan",
	topical_categories = true,
}

labels["palaeography"] = {
	aliases = {"paleography"},
	Wiktionary = true,
	topical_categories = true,
}

labels["paleontology"] = {
	aliases = {"palaeontology"},
	Wiktionary = true,
	topical_categories = true,
}

labels["Palestinian politics"] = {
	aliases = {"Palestine politics"},
	Wikipedia = "Politics of the Palestinian National Authority",
	topical_categories = true,
}

labels["palmistry"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["palynology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["papermaking"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["paraphilia"] = {
	aliases = {"paraphilias", "paraphilic", "fetish", "fetishes", "fetishism", "fetishistic", "fetishization", "fetishisation"},
	Wiktionary = "paraphilia#Noun",
	topical_categories = "Paraphilias",
}

labels["parapsychology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["parasitology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["part of speech"] = {
	display = "[[grammar]]",
	topical_categories = "Parts of speech",
}

labels["particle"] = {
	display = "[[particle physics]]",
	topical_categories = "Subatomic particles",
}

labels["particle physics"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["pasteurisation"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["patent law"] = {
	aliases = {"patents"},
	display = "[[patent#Noun|patent]] [[law]]",
	topical_categories = true,
}

labels["pathology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["pensions"] = {
	display = "[[pension]]s",
	topical_categories = true,
}

labels["percussion instruments"] = {
	aliases = {"percussion instrument"},
	display = "[[music]]",
	topical_categories = true,
}

labels["perfumery"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Peruvian politics"] = {
	Wikipedia = "Politics of Peru",
	topical_categories = true,
}

labels["pesäpallo"] = {
	aliases = {"pesapallo"},
	Wiktionary = true,
	topical_categories = true,
}

labels["petrochemistry"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["petrology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["pharmaceutical drug"] = {
	display = "[[pharmacology]]",
	topical_categories = "Pharmaceutical drugs",
}

labels["pharmaceutical effect"] = {
	display = "[[pharmacology]]",
	topical_categories = "Pharmaceutical effects",
}

labels["pharmacology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["pharmacy"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["pharyngology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["philately"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Philippine politics"] = {
	aliases = {"Filipino politics"},
	Wikipedia = "Politics of the Philippines",
	topical_categories = true,
}

labels["Philmont Scout Ranch"] = {
	aliases = {"Philmont"},
	Wikipedia = true,
	topical_categories = true,
}

labels["philosophy"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["phonetics"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["phonology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["photography"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["phrenology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["physical chemistry"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["physics"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["physiology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["phytopathology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["pinball"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["planetology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["plant"] = {
	display = "[[botany]]",
	topical_categories = "Plants",
}

labels["plant disease"] = {
	display = "[[phytopathology]]",
	topical_categories = "Plant diseases",
}

labels["playground games"] = {
	aliases = {"playground game"},
	display = "[[playground]] [[game]]s",
	topical_categories = true,
}

labels["poetry"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["poison"] = {
	display = "[[toxicology]]",
	topical_categories = "Poisons",
}

labels["Pokémon"] = {
	aliases = {"Pokemon"},
	display = "''[[w:Pokémon|Pokémon]]''",
	Wikipedia = true,
	topical_categories = true,
}

labels["poker"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["poker slang"] = {
	display = "[[poker]] [[slang]]",
	topical_categories = "Poker",
}

labels["political science"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["political subdivision"] = {
	display = "[[government]]",
	topical_categories = "Political subdivisions",
}

labels["politics"] = {
	aliases = {"political"},
	Wiktionary = true,
	topical_categories = true,
}

labels["popular music form"] = {
	display = "[[music]]",
	topical_categories = "popular music forms",
}

labels["popular music section"] = {
	display = "[[music]]",
	topical_categories = "popular music sections",
}

labels["pornography"] = {
	aliases = {"porn", "porno", "adult video", "adult videos"},
	Wiktionary = true,
	topical_categories = true,
}

labels["Portuguese folklore"] = {
	display = "[[Portuguese#Adjective|Portuguese]] [[folklore]]",
	topical_categories = "European folklore",
}

labels["Portuguese politics"] = {
	Wikipedia = "Politics of Portugal",
	topical_categories = true,
}

labels["post"] = {
	aliases = {"mail"},
	display = "[[postal]]",
	topical_categories = true,
}

labels["postal abbreviation"] = {
	aliases = {"postal abbr", "postal abbrev"},
	display = "[[postal]]",
	topical_categories = "Postal abbreviations",
}

labels["potential theory"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["pottery"] = {
	Wiktionary = true,
	topical_categories = "Ceramics",
}

labels["pragmatics"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["printing"] = {
	Wiktionary = "printing#Noun",
	topical_categories = true,
}

labels["probability theory"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["professional wrestling"] = {
	aliases = {"pro wrestling"},
	Wiktionary = true,
	topical_categories = true,
}

labels["programming"] = {
	aliases = {"computer programming"},
	Wiktionary = "programming#Noun",
	topical_categories = true,
}

labels["property law"] = {
	aliases = {"land law", "real estate law"},
	Wiktionary = true,
	topical_categories = true,
}

labels["prosody"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["protein"] = {
	aliases = {"proteins"},
	display = "[[biochemistry]]",
	topical_categories = "Proteins",
}

labels["Protestantism"] = {
	aliases = {"protestantism", "Protestant", "protestant"},
	Wiktionary = true,
	topical_categories = true,
}

labels["pseudoscience"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["psychiatry"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["psychoanalysis"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["psychology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["psychotherapy"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["publishing"] = {
	Wiktionary = "publishing#Noun",
	topical_categories = true,
}

labels["pulmonology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["pyrotechnics"] = {
	Wiktionary = true,
	aliases = { "firework", "fireworks" },
	topical_categories = true,
}

labels["QAnon"] = {
	aliases = {"Qanon"},
	Wikipedia = true,
	topical_categories = true,
}

labels["Quakerism"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["quantum computing"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["quantum mechanics"] = {
	aliases = {"quantum physics"},
	Wiktionary = true,
	topical_categories = true,
}

labels["Quimbanda"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["radiation"] = {
	-- TODO: What kind of topic is "radiation"? Is it specific kinds of radiation? That would be a set-type category.
	display = "[[physics]]",
	topical_categories = true,
}

labels["radio"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Raëlism"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["rail transport"] = {
	aliases = {"rail", "railroading", "railroads"},
	Wiktionary = true,
	topical_categories = "Rail transportation",
}

labels["Rastafari"] = {
	aliases = {"Rasta", "rasta", "Rastafarian", "rastafarian", "Rastafarianism"},
	Wiktionary = true,
	topical_categories = true,
}

labels["real estate"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["real tennis"] = {
	Wiktionary = true,
	topical_categories = "Tennis",
}

labels["recreational mathematics"] = {
	Wiktionary = true,
	topical_categories = "Mathematics",
}

labels["Reddit"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["regular expressions"] = {
	aliases = {"regex"},
	display = "[[regular expression]]s",
	topical_categories = true,
}

labels["relativity"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["religion"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["rhetoric"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["rhythmic gymnastics"] = {
	Wiktionary = true,
	Wikipedia = true,
	topical_categories = true,
}

labels["road transport"] = {
	aliases = {"roads"},
	Wikipedia = true,
	topical_categories = true,
}

labels["robotics"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["rock"] = {
	display = "[[petrology]]",
	topical_categories = "Rocks",
}

labels["rock paper scissors"] = {
	topical_categories = true,
}

labels["roleplaying games"] = {
	aliases = {"role playing games", "role-playing games", "RPG", "RPGs"},
	display = "[[roleplaying game]]s",
	topical_categories = "Role-playing games",
}

labels["roller derby"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Roman Catholicism"] = {
	aliases = {"Roman Catholic", "Roman Catholic Church"},
	Wiktionary = true,
	topical_categories = true,
}

labels["Roman Empire"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Roman god"] = {
	aliases = {"Roman goddess"},
	display = "[[Roman]] [[mythology]]",
	topical_categories = "Roman deities",
}

labels["Roman mythology"] = {
	display = "[[Roman]] [[mythology]]",
	topical_categories = true,
}

labels["Roman numerals"] = {
	display = "[[Roman numeral]]s",
	topical_categories = true,
}

labels["roofing"] = {
	Wiktionary = "roofing#Noun",
	topical_categories = true,
}

labels["rosiculture"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["rowing"] = {
	Wiktionary = "rowing#Noun",
	topical_categories = true,
}

labels["Rubik's Cube"] = {
	aliases = {"Rubik's cubes"},
	Wiktionary = "Rubik's cube",
	topical_categories = true,
}

labels["rugby"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["rugby league"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["rugby union"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Russian Orthodoxy"] = {
	aliases = {"Russian Orthodox", "Russian Orthodox Church"},
	Wikipedia = true,
	topical_categories = true,
}

labels["sailing"] = {
	Wiktionary = "sailing#Noun",
	topical_categories = true,
}

labels["schools"] = {
	display = "[[education]]",
	topical_categories = true,
}

labels["science fiction"] = {
	aliases = {"scifi", "sci fi", "sci-fi"},
	Wiktionary = true,
	topical_categories = true,
}

labels["sciences"] = {
	aliases = {"science", "scientific"},
	Wiktionary = true,
	topical_categories = true,
}

labels["Scientology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Scots law"] = {
	-- Note: this is the usual term, not "Scottish law".
	aliases = {"Scottish law", "Scotland law", "Scots Law", "Scottish Law", "Scotland Law"},
	Wikipedia = true,
	topical_categories = true,
}

labels["Scouting"] = {
	aliases = {"scouting"},
	display = "[[scouting]]",
	topical_categories = true,
}

labels["Scrabble"] = {
	display = "''[[Scrabble]]''",
	Wikipedia = true,
	topical_categories = true,
}

labels["scrapbooks"] = {
	display = "[[scrapbook]]s",
	topical_categories = true,
}

labels["sculpture"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["seduction community"] = {
	aliases = {"pickup artist", "pickup artists", "pickup artistry", "pickup community"},
	Wikipedia = true,
	topical_categories = true,
}

labels["seismology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["self-harm"] = {
	aliases = {"selfharm", "self harm", "self-harm community"},
	Wiktionary = true,
	topical_categories = true,
}

labels["semantics"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["semiconductors"] = {
	display = "[[semiconductor]]s",
	topical_categories = true,
}

labels["semiotics"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["SEO"] = {
	Wiktionary = "search engine optimization",
	topical_categories = {"Internet", "Marketing"},
}

labels["set theory"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["sewing"] = {
	Wiktionary = "sewing#Noun",
	topical_categories = true,
}

labels["sex"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["sex position"] = {
	display = "[[sex]]",
	topical_categories = "Sex positions",
}

labels["sexology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["sexuality"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Shaivism"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["shamanism"] = {
	aliases = {"Shamanism"},
	Wiktionary = true,
	topical_categories = true,
}

labels["Shi'ism"] = {
	aliases = {"Shia", "Shi'ite", "Shi'i"},
	display = "[[Shia Islam]]",
	topical_categories = true,
}

labels["Shinto"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["ship parts"] = {
	display = "[[nautical]]",
	topical_categories = "Ship parts",
}

labels["shipping"] = {
	Wiktionary = "shipping#Noun",
	topical_categories = true,
}

labels["shoemaking"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["shogi"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["signal processing"] = {
	Wikipedia = true,
	topical_categories = true,
}

labels["Sikhism"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Singaporean politics"] = {
	Wikipedia = "Politics of Singapore",
	topical_categories = true,
}

labels["singing"] = {
	Wiktionary = "singing#Noun",
	topical_categories = true,
}

labels["skateboarding"] = {
	Wiktionary = "skateboarding#Noun",
	topical_categories = true,
}

labels["skating"] = {
	Wiktionary = "skating#Noun",
	topical_categories = true,
}

labels["skeleton"] = {
	display = "[[anatomy]]",
	topical_categories = true,
}

labels["skiing"] = {
	Wiktionary = "skiing#Noun",
	topical_categories = true,
}

labels["skydiving"] = {
	Wiktionary = "skydiving#Noun",
	topical_categories = true,
}

labels["Slavic god"] = {
	display = "[[Slavic]] [[mythology]]",
	topical_categories = "Slavic deities",
}

labels["Slavic mythology"] = {
	display = "[[Slavic]] [[mythology]]",
	topical_categories = true,
}

labels["smoking"] = {
	Wiktionary = "smoking#Noun",
	topical_categories = true,
}

labels["snooker"] = {
	Wiktionary = "snooker#Noun",
	topical_categories = true,
}

labels["snowboarding"] = {
	Wiktionary = "snowboarding#Noun",
	topical_categories = true,
}

labels["soccer"] = {
	aliases = {"football", "association football"},
	Wiktionary = true,
	topical_categories = "Football (soccer)",
}

labels["social media"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["social sciences"] = {
	aliases = {"social science"},
	display = "[[social science]]s",
	topical_categories = true,
}

labels["socialism"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["sociolinguistics"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["sociology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["softball"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["software"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["software architecture"] = {
	Wiktionary = true,
	topical_categories = {"Software engineering", "Programming"},
}

labels["software engineering"] = {
	aliases = {"software development"},
	Wiktionary = true,
	topical_categories = true,
}

labels["soil science"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["sound"] = {
	Wiktionary = "sound#Noun",
	topical_categories = true,
}

labels["sound engineering"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["South Korean idol fandom"] = {
	display = "[[South Korean]] [[idol]] [[fandom]]",
	topical_categories = true,
}

labels["South Park"] = {
	display = "''[[w:South Park|South Park]]''",
	Wikipedia = true,
	topical_categories = true,
}

labels["Soviet Union"] = {
	aliases = {"USSR"},
	Wiktionary = true,
	topical_categories = true,
}

labels["space flight"] = {
	aliases = {"spaceflight", "space travel"},
	Wiktionary = true,
	topical_categories = "Space",
}

labels["space science"] = {
	aliases = {"space"},
	Wiktionary = true,
	topical_categories = "Space",
}

labels["Spanish politics"] = {
	Wikipedia = "Politics of Spain",
	topical_categories = true,
}

labels["spectroscopy"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["speedrunning"] = {
	aliases = {"speedrun", "speedruns"},
	Wiktionary = true,
	topical_categories = true,
}

labels["spinning"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["spiritualism"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["sports"] = {
	aliases = {"sport"},
	Wiktionary = true,
	topical_categories = true,
}

labels["square dancing"] = {
	aliases = {"square dance"},
	Wiktionary = true,
	topical_categories = true,
}

labels["squash"] = {
	Wikipedia = "Squash (sport)",
	topical_categories = true,
}

labels["standard of identity"] = {
	display = "[[standard of identity|standards of identity]]",
	topical_categories = "Standards of identity",
}

labels["star"] = {
	display = "[[astronomy]]",
	topical_categories = "Stars",
}

labels["Star Wars"] = {
	display = "''[[Star Wars]]''",
	topical_categories = true,
}

labels["statistical mechanics"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["statistics"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["steroid"] = {
	display = "[[biochemistry]]",
	topical_categories = "Steroids",
}

labels["steroid hormone"] = {
	aliases = {"steroid drug"},
	display = "[[biochemistry]], [[steroids]]",
	topical_categories = "Hormones",
}

labels["stock market"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["stock ticker symbol"] = {
	aliases = {"stock symbol"},
	Wiktionary = true,
	topical_categories = "Stock symbols for companies",
}

labels["string instruments"] = {
	aliases = {"string instrument"},
	display = "[[music]]",
	topical_categories = true,
}

labels["subculture"] = {
	Wiktionary = true,
	topical_categories = "Culture",
}

labels["Sufism"] = {
	aliases = {"Sufi Islam"},
	Wikipedia = true,
	topical_categories = true,
}

labels["sugar acid"] = {
	display = "[[organic chemistry]]",
	topical_categories = "Sugar acids",
}

labels["sumo"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["supply chain"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["surface feature"] = {
	display = "[[planetology]]",
	topical_categories = "Planetary nomenclature",
}

labels["surfing"] = {
	Wiktionary = "surfing#Noun",
	topical_categories = true,
}

labels["surgery"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["surveying"] = {
	Wiktionary = "surveying#Noun",
	topical_categories = true,
}

labels["sushi"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["swimming"] = {
	Wiktionary = "swimming#Noun",
	topical_categories = true,
}

labels["Swiss politics"] = {
	Wikipedia = "Politics of Switzerland",
	topical_categories = true,
}

labels["swords"] = {
	display = "[[sword]]s",
	topical_categories = true,
}

labels["symptom"] = {
	display = "[[medicine]]",
	topical_categories = "Medical signs and symptoms",
}

labels["Syriac Orthodoxy"] = {
	aliases = {"Syriac Orthodox", "Syriac Orthodox Church"},
	Wikipedia = true,
	topical_categories = true,
}

labels["systematic element symbol"] = {
	display = "[[chemistry]]",
	plain_categories = "Systematic chemical symbols",
}

labels["systematics"] = {
	Wiktionary = true,
	topical_categories = "Taxonomy",
}

labels["systems engineering"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["systems theory"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["table tennis"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Taoism"] = {
	aliases = {"Daoism"},
	Wiktionary = true,
	topical_categories = true,
}

labels["tarot"] = {
	Wiktionary = true,
	topical_categories = "Cartomancy",
}

labels["taxation"] = {
	aliases = {"tax", "taxes"},
	Wiktionary = true,
	topical_categories = true,
}

labels["taxonomic name"] = {
	display = "[[taxonomy]]",
	topical_categories = "Taxonomic names",
}

labels["taxonomy"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["technology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["telecommunications"] = {
	aliases = {"telecommunication", "telecom"},
	Wiktionary = true,
	topical_categories = true,
}

labels["telegraphy"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["telephony"] = {
	aliases = {"telephone", "telephones"},
	Wiktionary = true,
	topical_categories = true,
}

labels["television"] = {
	aliases = {"TV"},
	Wiktionary = true,
	topical_categories = true,
}

labels["tennis"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["teratology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Tetris"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["textiles"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["theater"] = {
	aliases = {"theatre"},
	Wiktionary = true,
	topical_categories = true,
}

labels["theology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["thermodynamics"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Thracian god"] = {
	aliases = {"Thracian goddess", "Thracian deity"},
	display = "[[w:Thracian religion|Thracian religion]]",
	Wikipedia = "Thracian religion",
	topical_categories = "Thracian deities",
}

labels["Tibetan Buddhism"] = {
	Wiktionary = true,
	topical_categories = "Buddhism",
}

labels["tiddlywinks"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["TikTok aesthetic"] = {
	display = "[[TikTok]] aesthetic",
	topical_categories = "Aesthetics",
}

labels["timber industry"] = {
	aliases = {"timber", "wood industry", "lumber industry", "lumber", "logging"},
	Wikipedia = true,
	topical_categories = true,
}

labels["time"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["tincture"] = {
	display = "[[heraldry]]",
	topical_categories = "Heraldic tinctures",
}

labels["topology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["tort law"] = {
	Wiktionary = true,
	topical_categories = "Law",
}

labels["tourism"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["toxicology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["trading"] = {
	Wiktionary = "trading#Noun",
	topical_categories = true,
}

labels["trading cards"] = {
	display = "[[trading card]]s",
	topical_categories = true,
}

labels["traditional Chinese medicine"] = {
	aliases = {"TCM", "Chinese medicine"},
	Wiktionary = true,
	topical_categories = true,
}

labels["traditional Korean medicine"] = {
	aliases = {"Korean medicine"},
	topical_categories = true,
}

labels["transgender"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["translation studies"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["transport"] = {
	aliases = {"transportation"},
	Wiktionary = true,
	topical_categories = true,
}

labels["traumatology"] = {
	Wiktionary = true,
	topical_categories = "Emergency medicine",
}

labels["travel"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["trigonometric function"] = {
	display = "[[trigonometry]]",
	topical_categories = "Trigonometric functions",
}

labels["trigonometry"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["trust law"] = {
	Wiktionary = true,
	topical_categories = "Law",
}

labels["Tumblr aesthetic"] = {
	display = "[[Tumblr]] aesthetic",
	topical_categories = "Aesthetics",
}

labels["Twitter"] = {
	aliases = {"twitter"},
	Wiktionary = "Twitter#Proper noun",
	topical_categories = true,
}

labels["two-up"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["typography"] = {
	aliases = {"typesetting"},
	Wiktionary = true,
	topical_categories = true,
}

labels["ufology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["UK politics"] = {
	Wikipedia = "Politics of the United Kingdom",
	topical_categories = true,
}

labels["Umbanda"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["underwater diving"] = {
	aliases = {"scuba", "scuba diving"},
	display = "[[underwater]] [[diving#Noun|diving]]",
	topical_categories = true,
}

labels["Unicode"] = {
	aliases = {"Unicode standard"},
	Wikipedia = true,
	topical_categories = true,
}

labels["United Nations"] = {
	aliases = {"UN"},
	display = "[[United Nations|UN]]",
	Wikipedia = true,
	topical_categories = true,
}

labels["urban studies"] = {
	aliases = {"urbanism", "urban planning"},
	Wiktionary = true,
	topical_categories = true,
}

labels["urology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["US politics"] = {
	Wikipedia = "Politics of the United States",
	topical_categories = true,
}

labels["Vaishnavism"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["Valentinianism"] = {
	aliases = {"valentinianism"},
	Wikipedia = true,
	topical_categories = true,
}

labels["Vedic religion"] = {
	aliases = {"Vedic Hinduism", "Ancient Hinduism", "ancient Hinduism", "Vedism", "Vedicism"},
	Wikipedia = "Historical Vedic religion",
	topical_categories = true,
}

labels["vegetable"] = {
	aliases = {"vegetables"},
	Wiktionary = true,
	topical_categories = "Vegetables",
}

labels["vehicles"] = {
	aliases = {"vehicle"},
	display = "[[vehicle]]s",
	topical_categories = true,
}

labels["Venezuelan politics"] = {
	aliases = {"Venezuela politics"},
	Wikipedia = "Politics of Venezuela",
	topical_categories = true,
}

labels["veterinary disease"] = {
	display = "[[veterinary medicine]]",
	topical_categories = "Veterinary diseases",
}

labels["veterinary medicine"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["video compression"] = {
	Wikipedia = true,
	topical_categories = true,
}

labels["video game genre"] = {
	display = "[[video game]]s",
	topical_categories = "Video game genres",
}

labels["video games"] = {
	aliases = {"video game", "video gaming"},
	display = "[[video game]]s",
	topical_categories = true,
}

labels["virology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["virus"] = {
	display = "[[virology]]",
	topical_categories = "Viruses",
}

labels["vitamin"] = {
	display = "[[biochemistry]]",
	topical_categories = "Vitamins",
}

labels["viticulture"] = {
	Wiktionary = true,
	topical_categories = {"Horticulture", "Wine"},
}

labels["volcanology"] = {
	aliases = {"vulcanology"},
	Wiktionary = true,
	topical_categories = true,
}

labels["volleyball"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["voodoo"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["water sports"] = {
	aliases = {"watersport", "watersports", "water sport"},
	Wiktionary = "watersport",
	topical_categories = true,
}

labels["watercraft"] = {
	display = "[[nautical]]",
	topical_categories = true,
}

labels["weaponry"] = {
	aliases = {"weapon", "weapons"},
	Wiktionary = true,
	topical_categories = "Weapons",
}

labels["weather"] = {
	topical_categories = true,
}

labels["weaving"] = {
	Wiktionary = "weaving#Noun",
	topical_categories = true,
}

labels["web design"] = {
	Wiktionary = true,
	topical_categories = true,
	aliases = {"Web design"}
}

labels["web development"] = {
	Wiktionary = true,
	topical_categories = {"Programming", "Web design"},
}

labels["weightlifting"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["white supremacy"] = { -- Often used to indicate Nazi-used jargon; compare "neo-Nazism"
	aliases = {"white nationalism", "white nationalist", "white power", "white racism", "white supremacist ideology", "white supremacism", "white supremacist"},
	Wikipedia = true,
	topical_categories = "White supremacist ideology",
}

labels["Wicca"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["wiki jargon"] = {
	aliases = {"wiki", "wikis"},
	display = "[[wiki]] [[jargon]]",
	topical_categories = "Wiki",
}

labels["Wikimedia jargon"] = {
	aliases = {"WMF", "WMF jargon", "Wiktionary", "Wiktionary jargon", "Wikipedia", "Wikipedia jargon"},
	display = "[[w:Wikimedia Foundation|Wikimedia]] [[jargon]]",
	topical_categories = "Wikimedia",
}

labels["wind instruments"] = {
	aliases = {"wind instrument"},
	display = "[[music]]",
	topical_categories = true,
}

labels["wine"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["winemaking"] = {
	Wiktionary = true,
	topical_categories = "Wine",
}

labels["winter sports"] = {
	display = "[[winter sport]]s",
	topical_categories = true,
}

labels["woodwind instruments"] = {
	aliases = {"woodwind instrument"},
	display = "[[music]]",
	topical_categories = true,
}

labels["woodworking"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["World War I"] = {
	aliases = {"World War 1", "WWI", "WW I", "WW1", "WW 1"},
	Wikipedia = true,
	topical_categories = true,
}

labels["World War II"] = {
	aliases = {"World War 2", "WWII", "WW II", "WW2", "WW 2"},
	Wikipedia = true,
	topical_categories = true,
}

labels["wrestling"] = {
	Wiktionary = "wrestling#Noun",
	topical_categories = true,
}

labels["writing"] = {
	Wiktionary = "writing#Noun",
	topical_categories = true,
}

labels["xiangqi"] = {
	aliases = {"Chinese chess"},
	Wiktionary = true,
	topical_categories = true,
}

labels["Yazidism"] = {
	aliases = {"Yezidism"},
	Wiktionary = true,
	topical_categories = true,
}

labels["yoga"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["yoga pose"] = {
	aliases = {"asana"},
	display = "[[yoga]]",
	topical_categories = "Yoga poses",
}

labels["zodiac constellations"] = {
	display = "[[astronomy]]",
	topical_categories = "Constellations in the zodiac",
}

labels["zoology"] = {
	Wiktionary = true,
	topical_categories = true,
}

labels["zootomy"] = {
	Wiktionary = true,
	topical_categories = "Animal body parts",
}

labels["Zoroastrianism"] = {
	Wiktionary = true,
	topical_categories = true,
}


-- Deprecated/do not use warning (ambiguous, unsuitable etc)

labels["deprecated label"] = {
	aliases = {"emergency", "greekmyth", "industry", "morphology", "musici", "quantum", "vector"},
	display = "<span style=\"color:var(--wikt-palette-red,red);\"><b>deprecated label</b></span>",
	deprecated = true,
}

return require("Module:labels").finalize_data(labels)
