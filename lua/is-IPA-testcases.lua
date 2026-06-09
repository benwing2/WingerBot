local lang = require("Module:languages").getByCode("is")
local tests = require("Module:UnitTests")
local m_IPA = require("Module:is-IPA")

local gsub = mw.ustring.gsub
local format = mw.ustring.format
local insert = table.insert

local function tag_IPA(IPA)
	return '<span class="IPA">' .. IPA .. '</span>'
end

local function tag_text(text, face)
	return require("Module:script utilities").tag_text(text, lang, sc, face)
end

local function link(term, face)
	return require("Module:links").full_link( { term = term, lang = lang, sc = sc }, face )
end

local function generate_origterm(respelling)
	return gsub(respelling, "[-._():%[%]]", "")
end

function tests:check_output(respelled_term, expected, term, dialect, notes)
	local origterm = term or generate_origterm(respelled_term)
	local notes_list = {}
	if respelled_term ~= origterm then
		insert(notes_list, ("respelled %s"):format(tag_text(respelled_term)))
	end
	if dialect then
		insert(notes_list, ("%s dialect"):format(dialect))
	end
	if notes then
		insert(notes_list, notes)
	end
	local notetext = notes_list[1] and (" (%s)"):format(table.concat(notes_list, ", ")) or ""
	return tests:equals(
		tag_text(link(origterm)) .. notetext,
		m_IPA.toIPA(respelled_term, dialect), 
		expected, 
		{ display = tag_IPA } 
	)
end

local examples = [==[

### Substitutions in the following:

# : -> ː
# I -> ɪ
# Y -> ʏ
# R -> r̥
# L -> l̥
# N -> n̥ 
# [ptkc]h -> \1ʰ


### Simple words (not compound)

þorn	+	ˈθɔrtn̥   thorn
himinn	+	ˈhɪːmɪn  heaven
brúnn	+	ˈprutn̥   brown
steinn	+	ˈsteitn̥  stone
karl	+	ˈkʰartl̥  man
rusl	+	ˈrʏstl̥   trash
býsna	+	ˈpistna  rather
taka	+	ˈtʰaːka  to take
þökk	+	ˈθœhk    thanks (n.)
vopn	+	ˈvɔhpn̥   weapon
brotna	+	ˈprɔhtna  to break (intr.)
sakna	+	ˈsahkna  to miss, long for; to lack
kembt	+	ˈcʰɛm̥t   combed; debugged (supine)
þið     +	ˈθɪːð    you (pl.)
gvuð    guð  ˈkvʏːð   God
byggja	+	ˈpɪca    to build
syngja	+	ˈsiɲca   to sing
munkur	+	ˈmuŋ̊kʏr  monk
öngull	+	ˈœiŋkʏtl̥  fishhook
drengur	+	ˈtreiŋkʏr  boy
svangur	+	ˈsvauŋkʏr  hungry
England	+	ˈeiŋlant   England
segja	+	ˈseija    to say
fluga	+	ˈflʏːɣa   fly (insect)
fljúga	+	ˈfljuːa   to fly
bógur	+	ˈpouːʏr   animal shoulder; bow (of a ship); side
lágur	+	ˈlauːʏr   low
pró(f)a	+	ˈpʰrouː(v)a  to test; to look at
dragt	+	ˈtraxt    pantsuit; skirt suit
september	+	ˈsɛftɛmpɛr  September
október	+	ˈɔxtoupɛr   October
gjalda	+	ˈcalta  to pay
geta	+	ˈcɛːta  to be able
kjósa	+	ˈcʰouːsa  to vote; to choose
keyra	+	ˈcʰeiːra  to drive
kirkja	+	ˈcʰɪr̥ca  church
hlýr	+	ˈl̥iːr  warm
hratt	+	ˈr̥aht  pushed
spara	+	ˈspaːra  to spare; to save (money)
þykja	+	ˈθɪːca  to be considered, to seem
lofa	+	ˈlɔːva  to promise
rós     +   ˈrouːs    rose
vaxa	+	ˈvaksa   to grow
myll:a	+	ˈmɪla  mill
nudda	+	ˈnʏta  to rub
kaþólikki	+	ˈkʰaːθoulɪhcɪ  Catholic
só[f]i	+	ˈsoufɪ   sofa
e[v]st	efst	ˈɛvst  top  -  common but non-normative
ehji    ekki    ˈɛçɪ  not
ry[þ]mi +   ˈrɪθmɪ   rhythm  -   proscribed
vaffla	+	ˈvafla   waffle
rö[v]la   röfla    ˈrœvla  to ramble, to chatter   -   proscribed spelling
kæra	+	ˈcʰaiːra  to accuse; to complain; accusation; complaint
kagi	+	ˈkʰaijɪ   cake (obs.)
[g]æi	+	ˈkaijɪ   dude, guy
dis[k]etta	+	ˈtɪskɛhta   diskette
[K]enía	+	ˈkʰɛːnia   Kenya


### Words with affixes
ráp-s	+	ˈrauːps
lag-s	+	ˈlaxs  (? or ˈlaːxs?)
efld	+	ˈɛl(ˠ)t  strengthened (fem. nom. sg. strong)
eflds	+	ˈɛl(ˠ)ts  strengthened (masc. gen. sg. strong)
rö[v]ls   röfls    ˈrœvls   rambling, chattering (gen. sg.)   -   proscribed spelling
nefndi	+	ˈnɛmtɪ   named (masc. nom. sg. weak)
hafrar	+	ˈhavrar  oats


### Compound words

## First part ends in a vowel
á-fall	+  ˈauːfatl̥   shock, trauma; dew
á-klæði  +  ˈauːkʰlaiːðɪ   upholstery
í-gerð	+  ˈiːcɛrð    abscess
ó-farir  +   ˈoufaːrɪr   misfortunes, faiilures (pl.)
fé-gjarn  +  ˈfjɛːcartn̥   greedy for money; avaricious
bú-staður  +  ˈpuːstaːðʏr   dwelling, abode; cabin
ósköp  +   ˈouskœp    really, quite; heaps, loads    -       informal

## Second part begins with a vowel or an h + vowel
mið-aldir  +  ˈmɪːðaltɪr   Middle Ages
sam-eign   +  ˈsaːmeikn̥   shared asset; communal space
úr-illur   +  ˈuːrɪtlʏr   grumpy; sullen
al-heimur  +  ˈaːlheiːmʏr   universe, cosmos (poetic)
ljós-haf   +  ˈljouːshaːv   sea of light


## First part ends in -p, -t, -k or -s and second part begins with a consonant or cluster (MANY EXCEPTIONS)
tap-rekstur  +  ˈtʰaːprɛkstʏr   loss-making business
kaup-maður   +  ˈkœiːpmaːðʏr   merchant
at-kvæði     +  ˈaːtkʰvaiːðɪ   syllable
mót-læti     +  ˈmouːtlaiːtɪ   adversity; misfortune
bik-svartur  +  ˈpɪːksvar̥tʏr   pitch black
sak-laus     +  ˈsaːklœiːs   innocent
hús-maður    +  ˈhuːsmaːðʏr   farmhand (archaic)
ís-lenskur   +  ˈiːslɛnskʏr   Icelandic


## First part ends in another consonant (resonant, or fricative other than -s) and second part begins with a consonant or cluster
að-ferð      +  ˈaðfɛrð      method          -
af-greiða    +  ˈavkreiːða   to serve; to deal with; to complete, to process      -
af-mæli      +  ˈavmaiːlɪ    birthday        -      [seemingly pronounced with /mː/ in https://enska.arnastofnun.is/en/ord/2617/tungumal/EN]
lag-laus     +  ˈlaɣlœiːs    tone-deaf       -
veg-sama     +  ˈvɛɣsaːma    to praise, to glorify      -
Dal-vík      +  ˈtalviːk     [female given name]        -
kol-svartur  +  ˈkʰɔlsvar̥tʏr  coal black     -
mál-tíð      +  ˈmaultʰiːð    meal; mealtime     -
stór-gerður  +  ˈstourcɛrðʏr  rugged, coarse-hewn (of facial features); coarse, crude     -
vor-koma     +  ˈvɔr̥kʰɔːma    arrival of spring    -      note the devoiced r before written <k> in this case across compound boundaries
frum-legur   +  ˈfrʏmlɛːɣʏr   original, novel      -
vin-semd     +  ˈvɪnsɛmt      friendliness, kindness      -
af-taka      +  ˈaftʰaːka     to refuse; execution (killing)  -     note the devoiced f before written <t> in this case across compound boundaries; [pronounced with /v/ in https://enska.arnastofnun.is/en/ord/2721/tungumal/EN]

## First part ending in /d/ (after /l/ or /n/), drops before /d/ or /t/
sand-dæla    +  ˈsantaiːla    sand pump
sund-tök     +  ˈsʏntʰœːk     swimming strokes (pl.)
hund-tík     +  ˈhʏntʰiːk     female dog, bitch

## First part ending in /d/ (after /l/ or /n/), optionally drops before /s/; "tends to be dropped before /s/, especially in common words"
and-skoti     +  ˈanskɔːti,ˈantskɔːti           devil fiend; fucking (adv.) [pronounced with [tʰ] and short [ɔ] in https://enska.arnastofnun.is/en/ord/3292/tungumal/EN]
hand-sama     +  ˈhansaːma,ˈhantsaːma           to seize; to capture; to arrest
hund-skamma   +  ˈhʏnskama,ˈhʏntskama          to scold severely, to chew out
eld-spýta     +  ˈɛlspiːta,ˈeltspiːta          match (for flame)
kvöld-skóli   +  ˈkʰvœlskoulɪ,ˈkʰvœltskoulɪ    night school

## First part endiing in /d/ (after /l/ or /n/), should not drop before /b/ (except in slopppy/colloquial language)
kvöld-blað     +  ˈkʰvœltplaːð    evening newspaper
hand-börur     +  ˈhantpœːrʏr     hand stretcher (pl.)? handcart?
vald-boð       +  ˈvaltpɔːð       instruction, command

## First part endiing in /ð/, remains voiced even if aspirated consonant follows
## /ð/ tends to drop, especially between consonants (with devoicing of a preceding /r/ before an aspirated stop or voiceless fricative/approximant other than /h/ + vowel), but in fast speech even after a vowel (with lengthening of the vowel)
bið-tími       +   ˈpɪðtʰiːmɪ     wait, waiting time
við-tal        +   ˈvɪðtʰaːl      interview
varð-turn      +   ˈvarð-tʰʏrtn̥   watchtower
að-krepptur    +   ˈað-kʰrɛftʏr   pressed (for time, money); cramped, confined
ráð-kænska     +   ˈrauðcʰainska  resourcefulness, astuteness
við-kvæði      +   ˈvɪðkʰvaiːðɪ   refrain, chorus
að-koma        +   ˈaðkʰɔːma      situation; involvement; driveway
borð-búnaður   +   ˈporðpuːnaðʏr  tableware    -      [/u/ given as short but apparently a typo; compare treggáfaður below with long á]
bragð-betri    +   ˈpraɣðpɛːtrɪ   tastier, more delicious
harð-brjósta   +   ˈharðprjousta  heartless, callous
orð-tak        +   ˈɔrðtʰaːk      expression, idiom
við-tæki       +   ˈvɪðtʰaiːcɪ    radio set; extensive, far-reaching (nom. masc. sg. weak)
verð-myndun    +   ˈvɛrðmɪntʏn    price formation (?)
verð-skulda    +   ˈverðskʏlta    to deserve, to merit

## Names with /ð/ at the end of a compound, which conventionally drops or assimilates
Bárð-dælir     +   ˈpaurðtaiːlɪr   [placename]
Bár-dælir      Bárðdælir   ˈpaurtaiːlɪr    [placename]     -       local pronunciation
Norð-fjörður   +   ˈnɔrðfjœrðʏr    [placename]
Nor-fjörður   Norðfjörður   ˈnɔr̥fjœrðʏr     [placename]     -       local pronunciation
Norð-lendingur  +  ˈnɔrðlɛntiŋkʏr  [placename]
Nor-lendingur  Norðlendingur  ˈnɔrlɛntiŋkʏr   [placename]     -       local pronunciation
Norð-lingar    +   ˈnɔrðliŋkʏr     [placename]
Nor-lingar    Norðlingar   ˈnɔrliŋkʏr      [placename]     -       local pronunciation
Breið-dalur    +   ˈpreiðtaːlʏr    [placename]
Breid[:]alur    Breiðdalur   ˈpreitːalʏr     [placename]     -       local pronunciation [why not long /a/?]
Skrið-dalur    +   ˈskrɪðtaːlʏr    [placename]
Skrid[:]alur    Skriðdalur   ˈskrɪtːalʏr     [placename]     -       local pronunciation [why not long /a/?]

## First part ending in /f/, which becomes [v] before a vowel, voiced sound, unaspirated stop or /h/ + vowel
of-ætlun     +    ˈɔːvaihtlʏn       insurmountable task
af-dalur     +    ˈaftaːlʏr         side valley; isolated valley
raf-geymir   +    ˈravceiːmɪr       accumulator, storage battery
haf-gola     +    ˈhavkɔːla         sea breeze
af-hausa     +    ˈavhœiːsa         to behead
a-fausa     afhausa    ˈaːfœiːsa    to behead      -       with assimilation
líf-láta     +      ˈlivlauːta      to put to death, to execute; execution, murder (gen pl indef)
raf-neisti   +      ˈravneistɪ      electric spark
raf-reiknir  +      ˈravreihknɪr    [electronic] calculator

## First part ending in /f/, which becomes [f] before a voiceless fricative or approximant or aspirated stop

af-hjúpa      +    ˈafçuːpa       to unveil; to reveal
af-hrak       +    ˈafr̥aːk        outcast, pariah
af-kimi       +    ˈafcʰɪːmɪ      nook, corner
af-koma       +    ˈafkʰɔːma      profits, financial situation
af-taka       +    ˈaftʰaːka      to refuse; execution (killing)
raf-tækni     +    ˈraftʰaiːhknɪ  electronics
Rif-tún       +    ˈrɪftʰuːna     [placename]
af-skekktur   +    ˈafscɛxtʏr     remote, isolated, secluded
af-staða      +    ˈafstaːða      position, attitude, stance; location
of-hleðsla    +    ˈɔfl̥ːɛðsla     overload
of-hvörf      +    ˈɔfkʰvœrv      excesses? hyperbole?
of-sjónir     +    ˈɔfsjouːnɪr    hallucination(s)

## First part ending in /f/, before a labial; it becomes [v] or (in everyday speech, but not formal speech) assimilates to the labial

raf-magn      +    ˈravmakn,ˈramːakn[informal]      electricity
af-bera       +    ˈavpɛːra,ˈapːɛra[informal]       to tolerate, to bear
af-bragð      +    ˈavpraɣð,ˈapraɣð[informal]       excellent thing/person
of-boðs-legur  +   ˈɔvpɔðslɛːɣʏr,ˈɔpːɔðslɛːɣʏr[informal]      	tremendous, enormous; terrible, awful
o-boðs-legur  ofboðslegur   ˈɔːpɔðslɛːɣʏr           tremendous, enormous; terrible, awful      -         alternative informal form



## First part ending in soft /g/, which becomes [ɣ] before a vowel, voiced sound, unaspirated stop or /h/ + vowel
## Commonly in fast speech, especially in common words, the [ɣ] is dropped before a consonant and the preceding vowel lengthened; not acceptable in formal speech.

aug-ljós       +   ˈœiɣljouːs     obvious, apparent
dag-blað       +   ˈtaɣplaːð      newspaper
dag-legur      +   ˈtaɣlɛːɣʏr     daily, everyday
dag-mamma      +   ˈtaɣmama       childminder, daycare provider, childcare provider
fag-maður      +   ˈfaɣmaːðʏr     professional, expert
hag-ræða       +   ˈhaɣraiːða     get comfortable; adjust, sort out; economize; adapt, modify
lag-hentur     +   ˈlaɣhɛn̥tʏr     handy, dexterous
leg-bólga      +   ˈleɣpoulka     uterine inflammation
nag-dýr        +   ˈnaɣtiːr       rodent
sog-æðar       +   ˈsɔɣaiːðar     lymphatic vessels
treg-gáfaður   +   ˈtʰrɛɣkauːvaðʏr   slow-witted, dim


## First part ending in soft /g/, which becomes [x] before a voiceless fricative or approximant or aspirated stop (other than /h/ + vowel)
## Alternatively ("also quite common"), pronounced as voiced.
## Not commonly dropped when voiceless even in fast speech (but sometimes when pronounced as voiced).

dag-kaup       +   ˈtaxkʰœiːp,ˈtaɣkʰœiːp           daily wage
dag-peningar   +   ˈtaxpʰɛːniŋkar,ˈtaɣpʰɛːniŋkar   daily allowance, per diem
hag-kerfi      +   ˈhaxcʰɛrvɪ,ˈhaɣcʰɛrvɪ           economic system, economy
log-suða       +   ˈlɔxsʏːða,ˈlɔɣsʏːða             welding
sag-tenntur    +   ˈsaxtʰɛn̥tʏr,ˈsaɣtʰɛn̥tʏr         serrate (of a leaf)
veg-spotti     +   ˈvɛxspɔhtɪ,ˈvɛɣspɔhtɪ           stretch of road? short distance?
veg-tylla      +   ˈvɛxtʰɪtla,ˈvɛɣtʰɪtla           honor, prestige; credit, kudos
víg-hreiður    +   ˈvixr̥eiːðʏr,ˈviɣr̥eiːðʏr         pillbox, fortified bunker


## First part ending in soft /g/, which is dropped after á, ó, ú (as in non-compound words).

lágnætti       +   ˈlauːnaihtɪ        midnight (dated)
skóglendi      +   ˈskouːlɛntɪ        woodland, wooded area
drjúgvirkur    +   ˈtrjuːvɪr̥kʏr       efficient, highly effective


## First part ending in /k/: pre-aspirated in some common compound words

einstakk-lingur    einstaklingur  ˈeinstahkliŋkʏr    individual, person
klakk-laust        klaklaust      ˈkʰlahkœist        safe and sound (also spelled "klakklaust")
líkk-legur         líklegur       ˈlihklɛːɣʏr        likely, probable
lík-legur          +              ˈliːklɛːɣʏr        likely, probable        -        alternative pronunciation

## First part ending in /k/: not pre-aspirated in less common compound words

lak-lega        +    ˈlaːklɛːɣa    poorly, insufficiently, substandardly
lok-leysa       +    ˈlɔːkleiːsa   nonsense, rubbish


## First part ending in /k/: disappears before <g> and <k>

bak-grunnur     +    ˈpaːkrʏnʏr      background
strák-kjáni     +    ˈstrauːcʰauːnɪ  silly/foolish boy, goofy lad
blek-klessa     +    ˈplɛːkʰlɛsa     ink blot
þak-gluggi      +    ˈþaːklʏcɪ       skylight


## mf, mv, ns (also in non-compound words): previous vowel nasalized; in fast and informal speech, the nasal consonant may disappear, leaving only a nasalized vowel

fram-farir      +   ˈfrãmfaːrɪr    advancements, strides
fram-vinda      +   ˈfrãmvɪnta     progress; development
sam-ferða       +   ˈsãmfɛrða      traveling with, accompanying (adj)
um-ferð         +   ˈʏ̃mfɛrð        traffic, congestion; flow; cycle, round
inn-sýn         +   ˈɪ̃nsiːn        insight, perception
van-svefta      +   ˈvãnsvɛfta     sleep-deprived

## <ns>, <nns> in non-compound words:
dansa           +   ˈtãnsa          dance
eins            +   ˈe͠ins           identical; equal
vinnsla         +   ˈvɪ̃nsla         processing (noun)

## <n-b> across a compound boundary informally becomes /mp/, <n-k> informally becomes /ŋkʰ/; in colloquial speech the <n> may drop but this is frowned on in formal speech
eim-búi         einbúi       ˈeimpuːɪ           loner, hermit, recluse                    -              informal
eim-býlis-hús   einbýlishús  ˈeimpiːlɪshuːs 	   detached house, single-family home        -              informal   
imm-bú          innbú        ˈɪmpuː             household goods                           -              informal
ɪmm-bær         Innbær       ˈɪmpaiːr           inner city                                -              informal
innan-sleikjur  +            ˈɪnãnstleiːcʏr     trifles
undam-brögð     undanbrögð   ˈʏntamprœɣð        excuses, pretexts                         -              informal
undaŋ-koma      undankoma    ˈʏntaŋkʰɔːma       escape, way out                           -              informal


## <p> across a compound boundary disappears before <b>, <p>
kaup-bætir      +           ˈkʰœiːpaiːðʏr       added bonus, something coming along "in the bargain"
kaup-binding    +           ˈkʰœiːpɪntiŋk       wage freeze
lop-band        +           ˈlɔːpant            band or ribbon of coarse wool yarn        -               book says [lɔpːand], probably a mistake
upp-bót         +           ˈʏhpouːt            supplement; compensation                  -               book says [ʏhbout], probably a mistake

## <p> across a compound boundary especially in kaup- and upp- informally assimilates to a geminate /fː/ before <f>, witʰ shortening of preceding and following vowels if long; not in formal speecʰ
kaup-fé-lag      +           ˈkʰœiːpfjɛːlaːɣ,kʰœifːjɛlaːɣ[informal]   (merchant) cooperative
kau-fé-lag       kaupfélag   ˈkʰœiːfjɛːlaːɣ                           (merchant) cooperative        -     alternative informal pronunciation
kaup-far         +           ˈkʰœiːpfaːr,kʰœifːar[informal]           merchant ship; trader
kau-far          kaupfar     ˈkʰœiːfaːr                               merchant ship; trader         -     alternative informal pronunciation
upp‿fyrir        +           ˈʏhpfɪːrɪr,ʏfːɪrɪr[informal]             above
upp-fræða        +           ˈʏhpfraiːða,ʏfːraiða[informal]           educate; inform               -     book has [ʏfːraiːða], probably a typo

## <p> across a compound boundary sometimes becomes /f/ before <s> and <t> (with shortening of a preceding vowel if long), across a compound boundary
kaup-sýsla       +           ˈkʰœiːpsistla,kʰœifsistla[informal]      trade, commerce
kaup-tíð         +           ˈkʰœiːptʰiːð,kʰœiftʰiːð[informal]        trading season (historical)
kaup-trygging    +           ˈkʰœiːptʰrɪciŋk,kʰœiftʰrɪciŋk[informal]  guaranteed minimum wage

## <p> across a compound boundary may be aspirated before /m/
kaup-maður       +           ˈkʰœiːpmaːðʏr,kʰœihpmaːðʏr               merchant, trader
kaup-mennska     +           ˈkʰœiːpmɛnska,kʰœihpmɛnska               commerce, business
Kaup-manna-höfn  +           ˈkʰœiːpmanahœpn̥,kʰœihpmanahœpn̥           Copenhagen

## First part of compound ending in <r>, which becomes devoiced before a voiceless fricative or approximant or aspirated stop (other than /h/ + vowel)
## 1. Before <p>, <t>, <k>, <s>:
kór-söngur       +           ˈkʰour̥sœiŋkʏr    choral singing      
kyrr-stæður      +           ˈcʰɪr̥staiːðʏr    stationary, immobile
leir-ker         +           ˈleir̥cʰɛːr       ceramic pot
nær-pils         +           ˈnair̥pʰɪls       slip (woman's garment), petticoat
nær-tækur        +           ˈnair̥tʰaiːkʏr    obvious, evident, at hand
sér-stakur       +           ˈsjɛr̥staːkʏr     particular; specific, distinct; special, unusual; distinctive, exceptional
vor-kuldar       +           ˈvɔr̥kʰʏltar      cold spells in spring
úr-koma          +           ˈur̥kʰɔːma        rainfall, precipitation
## 2. Before <þ>, <hj>, <hl>, <hn> (also presumably <f> but no examples given):
búr-hnífur       +           ˈpur̥n̥iːvʏr       kitchen knife
fer-hjóla        +           ˈfɛr̥çouːla       four-wheeled
var-hluta        +           ˈvar̥l̥ʏːta        cheated of, deprived of
vor-hláka        +           ˈvɔr̥l̥auːka       spring thaw
vor-þing         +           ˈvɔr̥θiŋk         spring parliament, spring session
## 3. Assimilation before <hr>: [note, following vowels shortened after double consonant from assimilation, probably a general rule]
úr-hrak          +           ˈur̥ːak           scum, dregs; scoundrel, wretch
vor-hret         +           ˈvɔr̥ːɛt          cold spell in spring
## 4. <r> at the end of an inflection at the end of the first part of a compound often dropped, especially informally in common words:
efti-sjá         eftirsjá         ˈɛftɪsjauː        regret, sense of loss
efti-tekt        eftirtekt        ˈɛftɪtʰɛxt        attention, heed
hjálpa-gögn      hjálpargögn      ˈçaul̥pakœkn̥       aid, help; (in plural) emergency aid, emergency supplies
Stranda-kirkja   Strandarkirkja   ˈstrantacʰɪr̥ca    Coastal Church (a particular famous Lutheran church)
kopa-stunga      koparstunga      ˈkʰɔːpastuŋka     copperplate
unda-legur       undarlegur       ˈʏntalɛːɣʏr       weird, strange
yfi-læti         yfirlæti         ˈɪːvɪlaiːtɪ       haughtiness; hubris, arrogance

## <s> at the end of the first part of a compound is maintained unless the second part begins with an <s>
ríkis-sjóður     +               ˈriːcɪsjouːðʏr    national treasury, public purse
heims-sýn        +               ˈheimsiːn         worldview; panorama
lands-sam-band   +               ˈlantsampant      national association
lans-sam-band    landssamband    ˈlansampant       national association                            -                reduced pronunciation

geim-steinn  +	ˈceimsteitn̥   meteoroid
loft-steinn  +	ˈlɔftsteitn̥   meteorite
gvuð-spjall  guðspjall  ˈkvʏðspjatl̥   gospel
ski[f]-stjóri  skipstjóri   ˈscɪfstjouːrɪ  captain    [not with /f/ in https://enska.arnastofnun.is/en/ord/36534/tungumal/EN]

]==]

function tests:test_pron()
	local list = {
		{"þorn", "ˈθɔrtn̥" },
		{"himinn", "ˈhɪːmɪn" },
		{"brúnn", "ˈprutn̥" },
		{"steinn", "ˈsteitn̥" },
		{"geim-steinn", "ˈceimsteitn̥" },
		{"loft-steinn", "ˈlɔftsteitn̥" },
		{"karl", "ˈkʰartl̥" },
		{"rusl", "ˈrʏstl̥" },
		{"býsna", "ˈpistna" },
		{"ráp-s", "ˈrauːps" },
		{"taka", "ˈtʰaːka" },
		{"þökk", "ˈθœhk" },
		{"vopn", "ˈvɔhpn̥" },
		{"brotna", "ˈprɔhtna" },
		{"sakna", "ˈsahkna" },
		{"kembt", "ˈcʰɛm̥t" },
		{"þið", "ˈθɪːð" },
		{"gvuð", "ˈkvʏːð", "guð" },
		{"byggja", "ˈpɪca" },
		{"syngja", "ˈsiɲca" },
		{"munkur", "ˈmuŋ̊kʏr" },
		{"öngull", "ˈœiŋkʏtl̥"},
		{"drengur", "ˈtreiŋkʏr" },
		{"svangur", "ˈsvauŋkʏr" },
		{"England", "ˈeiŋlant" },
		{"segja", "ˈseija" },
		{"fluga", "ˈflʏːɣa" },
		{"fljúga", "ˈfljuːa" },
		{"bógur", "ˈpouːʏr" },
		{"lágur", "ˈlauːʏr" },
		{"pró(f)a", "ˈpʰrouː(v)a" },
		{"dags", "ˈtaks" },
		{"dragt", "ˈtraxt" },
		{"gvuð-spjall", "ˈkvʏðspjatl̥", "guðspjall" },
		{"september", "ˈsɛftɛmpɛr" },
		{"október", "ˈɔxtoupɛr" },
		{"gjalda", "ˈcalta" },
		{"geta", "ˈcɛːta" },
		{"kjósa", "ˈcʰouːsa" },
		{"keyra", "ˈcʰeiːra" },
		{"kirkja", "ˈcʰɪr̥ca" },
		{"hlýr", "ˈl̥iːr" },
		{"hratt", "ˈr̥aht" },
		{"spara", "ˈspaːra" },
		{"þykja", "ˈθɪːca" },
		{"lofa", "ˈlɔːva" },
		{"rós", "ˈrouːs" },
		{"vaxa", "ˈvaksa" },
		{"myll:a", "ˈmɪla" },
		{"nudda", "ˈnʏta" },
		{"kaþólikki", "ˈkʰaːθoulɪhcɪ" },
		{"só[f]i", "ˈsoufɪ" },
		{"e[v]st", "ˈɛvst", "efst", nil, "common but non-normative" },
		{"lag-s", "ˈlaːxs" },
		{"ehji", "ˈɛçɪ", "ekki" },
		{"ski[f]s-stjóri", "ˈscɪfsstjourɪ", "skipsstjóri" },
		{"ry[þ]mi", "ˈrɪθmɪ", nil, nil, "proscribed" },
		{"vaffla", "ˈvafla" },
		{"efld", "ˈɛl(ˠ)t" },
		{"eflds", "ˈɛl(ˠ)ts" },
		{"rö[v]la", "ˈrœvla", "röfla" },
		{"rö[v]ls", "ˈrœvls", "röfls" },
		{"nefndi", "ˈnɛmtɪ" },
		{"hafrar", "ˈhavrar" },
		{"kæra", "ˈcʰaiːra" },
		{"kagi", "ˈkʰaijɪ" },
		{"[g]æi", "ˈkaijɪ" },
		{"dis[k]etta", "ˈtɪskɛhta" },
		{"[K]enía", "ˈkʰɛːnia" },
	}
	self:iterate(list, "check_output")
end

--[[
			Additions take this form –
		{ "entry name", "IPA" },
		{ "", "" },
			or, if you are generating IPA from a respelling of the term –
		{ "respelling", "IPA", "entry name" }
		{ "", "", "" },
			Make sure to include the comma, or the module will return an error.
]]--

return tests
