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
lag-s	+	ˈlaːxs
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
fé-gjarn  +  ˈfjɛ:cartn̥   greedy for money; avaricious
bú-staður  +  ˈpu:sta:ðʏr   dwelling, abode; cabin
ósköp  +   ˈouskœp    really, quite; heaps, loads    -       informal

## Second part begins with a vowel or an h + vowel
mið-aldir  +  ˈmɪ:ðaltɪr   Middle Ages
sam-eign   +  ˈsa:meikn̥   shared asset; communal space
úr-illur   +  ˈu:rɪtlʏr   grumpy; sullen
al-heimur  +  ˈa:lhei:mʏr   universe, cosmos (poetic)
ljós-haf   +  ˈljou:sha:v   sea of light


## First part ends in -p, -t, -k or -s and second part begins with a consonant or cluster (MANY EXCEPTɪONS)
tap-rekstur  +  ˈtʰa:prɛkstʏr   loss-making business
kaup-maður   +  ˈkœi:pma:ðʏr   merchant
at-kvæði     +  ˈa:tkʰvai:ðɪ   syllable
mót-læti     +  ˈmou:tlai:tɪ   adversity; misfortune
bik-svartur  +  ˈpɪ:ksvar̥tʏr   pitch black
sak-laus     +  ˈsa:klœi:s   innocent
hús-maður    +  ˈhu:sma:ðʏr   farmhand (archaic)
ís-lenskur   +  ˈi:slɛnskʏr   Icelandic


## First part ends in another consonant (resonant, or fricative other than -s) and second part begins with a consonant or cluster
að-ferð      +  ˈaðfɛrð      method          -
af-greiða    +  ˈavkrei:ða   to serve; to deal with; to complete, to process      -
af-mæli      +  ˈavmai:lɪ    birthday        -      [seemingly pronounced with /mː/ in https://enska.arnastofnun.is/en/ord/2617/tungumal/EN]
lag-laus     +  ˈlaɣlœi:s    tone-deaf       -
veg-sama     +  ˈvɛɣsa:ma    to praise, to glorify      -
Dal-vík      +  ˈtalvi:k     [female given name]        -
kol-svartur  +  ˈkʰɔlsvar̥tʏr  coal black     -
mál-tíð      +  ˈmaultʰi:ð    meal; mealtime     -
stór-gerður  +  ˈstourcɛrðʏr  rugged, coarse-hewn (of facial features); coarse, crude     -
vor-koma     +  ˈvɔr̥kʰɔ:ma    arrival of spring    -      note the devoiced r before written <k> in this case across compound boundaries
frum-legur   +  ˈfrʏmlɛ:ɣʏr   original, novel      -
vin-semd     +  ˈvɪnsɛmt      friendliness, kindness      -
af-taka      +  ˈaftʰa:ka     to refuse; execution (killing)  -     note the devoiced f before written <t> in this case across compound boundaries; [pronounced with /v/ in https://enska.arnastofnun.is/en/ord/2721/tungumal/EN]

## First part ending in /d/ (after /l/ or /n/), drops before /d/ or /t/
sand-dæla    +  ˈsantai:la    sand pump
sund-tök     +  ˈsʏntʰœ:k     swimming strokes (pl.)
hund-tík     +  ˈhʏntʰi:k     female dog, bitch

## First part ending in /d/ (after /l/ or /n/), optionally drops before /s/; "tends to be dropped before /s/, especially in common words"
and-skoti     +  ˈanskɔ:ti,ˈantskɔ:ti           devil fiend; fucking (adv.) [pronounced with [tʰ] and short [ɔ] in https://enska.arnastofnun.is/en/ord/3292/tungumal/EN]
hand-sama     +  ˈhansa:ma,ˈhantsa:ma           to seize; to capture; to arrest
hund-skamma   +  ˈhʏnskama,ˈhʏntskama          to scold severely, to chew out
eld-spýta     +  ˈɛlspi:ta,ˈeltspi:ta          match (for flame)
kvöld-skóli   +  ˈkʰvœlskoulɪ,ˈkʰvœltskoulɪ    night school

## First part endiing in /d/ (after /l/ or /n/), should not drop before /b/ (except in slopppy/colloquial language)
kvöld-blað     +  ˈkʰvœltpla:ð    evening newspaper
hand-börur     +  ˈhantpœ:rʏr     hand stretcher (pl.)? handcart?
vald-boð       +  ˈvaltpɔ:ð       instruction, command

## First part endiing in /ð/, remains voiced even if aspirated consonant follows
## /ð/ tends to drop, especially between consonants (with devoicing of a preceding /r/ before an aspirated stop or voiceless fricative/approximant other than /h/ + vowel), but in fast speech even after a vowel (with lengthening of the vowel)
bið-tími       +   ˈpɪðtʰi:mɪ     wait, waiting time
við-tal        +   ˈvɪðtʰa:l      interview
varð-turn      +   ˈvarð-tʰʏrtn̥   watchtower
að-krepptur    +   ˈað-kʰrɛftʏr   pressed (for time, money); cramped, confined
ráð-kænska     +   ˈrauðcʰainska  resourcefulness, astuteness
við-kvæði      +   ˈvɪðkʰvai:ðɪ   refrain, chorus
að-koma        +   ˈaðkʰɔ:ma      situation; involvement; driveway
borð-búnaður   +   ˈporðpu:naðʏr  tableware    -      [/u/ given as short but apparently a typo; compare treggáfaður below with long á]
bragð-betri    +   ˈpraɣðpɛ:trɪ   tastier, more delicious
harð-brjósta   +   ˈharðprjousta  heartless, callous
orð-tak        +   ˈɔrðtʰa:k      expression, idiom
við-tæki       +   ˈvɪðtʰai:cɪ    radio set; extensive, far-reaching (nom. masc. sg. weak)
verð-myndun    +   ˈvɛrðmɪntʏn    price formation (?)
verð-skulda    +   ˈverðskʏlta    to deserve, to merit

## Names with /ð/ at the end of a compound, which conventionally drops or assimilates
Bárð-dælir     +   ˈpaurðtai:lɪr   [placename]
Bár-dælir      Bárðdælir   ˈpaurtai:lɪr    [placename]     -       local pronunciation
Norð-fjörður   +   ˈnɔrðfjœrðʏr    [placename]
Nor-fjörður   Norðfjörður   ˈnɔr̥fjœrðʏr     [placename]     -       local pronunciation
Norð-lendingur  +  ˈnɔrðlɛntiŋkʏr  [placename]
Nor-lendingur  Norðlendingur  ˈnɔrlɛntiŋkʏr   [placename]     -       local pronunciation
Norð-lingar    +   ˈnɔrðliŋkʏr     [placename]
Nor-lingar    Norðlingar   ˈnɔrliŋkʏr      [placename]     -       local pronunciation
Breið-dalur    +   ˈpreiðta:lʏr    [placename]
Breid[:]alur    Breiðdalur   ˈpreit:alʏr     [placename]     -       local pronunciation [why not long /a/?]
Skrið-dalur    +   ˈskrɪðta:lʏr    [placename]
Skrid[:]alur    Skriðdalur   ˈskrɪt:alʏr     [placename]     -       local pronunciation [why not long /a/?]

## First part ending in /f/, which becomes [v] before a vowel, voiced sound, unaspirated stop or /h/ + vowel
of-ætlun     +    ˈɔ:vaihtlʏn       insurmountable task
af-dalur     +    ˈafta:lʏr         side valley; isolated valley
raf-geymir   +    ˈravcei:mɪr       accumulator, storage battery
haf-gola     +    ˈhavkɔ:la         sea breeze
af-hausa     +    ˈavhœi:sa         to behead
a-fausa     afhausa    ˈa:fœi:sa    to behead      -       with assimilation
líf-láta     +      ˈlivlau:ta      to put to death, to execute; execution, murder (gen pl indef)
raf-neisti   +      ˈravneistɪ      electric spark
raf-reiknir  +      ˈravreihknɪr    [electronic] calculator

## First part ending in /f/, which becomes [f] before a voiceless fricative or approximant or aspirated stop

af-hjúpa      +    ˈafçu:pa       to unveil; to reveal
af-hrak       +    ˈafr̥a:k        outcast, pariah
af-kimi       +    ˈafcʰɪ:mɪ      nook, corner
af-koma       +    ˈafkʰɔ:ma      profits, financial situation
af-taka       +    ˈaftʰa:ka      to refuse; execution (killing)
raf-tækni     +    ˈraftʰai:hknɪ  electronics
Rif-tún       +    ˈrɪftʰu:na     [placename]
af-skekktur   +    ˈafscɛxtʏr     remote, isolated, secluded
af-staða      +    ˈafsta:ða      position, attitude, stance; location
of-hleðsla    +    ˈɔfl̥:ɛðsla     overload
of-hvörf      +    ˈɔfkʰvœrv      excesses? hyperbole?
of-sjónir     +    ˈɔfsjou:nɪr    hallucination(s)

## First part ending in /f/, before a labial; it becomes [v] or (in everyday speech, but not formal speech) assimilates to the labial

raf-magn      +    ˈravmakn,ˈram:akn[informal]      electricity
af-bera       +    ˈavpɛ:ra,ˈap:ɛra[informal]       to tolerate, to bear
af-bragð      +    ˈavpraɣð,ˈapraɣð[informal]       excellent thing/person
of-boðs-legur  +   ˈɔvpɔðslɛ:ɣʏr,ˈɔp:ɔðslɛ:ɣʏr[informal]      	tremendous, enormous; terrible, awful
o-boðs-legur  ofboðslegur   ˈɔ:pɔðslɛ:ɣʏr           tremendous, enormous; terrible, awful      -         alternative informal form



## First part ending in soft /g/, which becomes [ɣ] before a vowel, voiced sound, unaspirated stop or /h/ + vowel
## Commonly in fast speech, especially in common words, the [ɣ] is dropped before a consonant and the preceding vowel lengthened; not acceptable in formal speech.

aug-ljós       +   ˈœiɣljou:s     obvious, apparent
dag-blað       +   ˈtaɣpla:ð      newspaper
dag-legur      +   ˈtaɣlɛ:ɣʏr     daily, everyday
dag-mamma      +   ˈtaɣmama       childminder, daycare provider, childcare provider
fag-maður      +   ˈfaɣma:ðʏr     professional, expert
hag-ræða       +   ˈhaɣrai:ða     get comfortable; adjust, sort out; economize; adapt, modify
lag-hentur     +   ˈlaɣhɛn̥tʏr     handy, dexterous
leg-bólga      +   ˈleɣpoulka     uterine inflammation
nag-dýr        +   ˈnaɣti:r       rodent
sog-æðar       +   ˈsɔɣai:ðar     lymphatic vessels
treg-gáfaður   +   ˈtʰrɛɣkau:vaðʏr   slow-witted, dim


## First part ending in soft /g/, which becomes [x] before a voiceless fricative or approximant or aspirated stop (other than /h/ + vowel)
## Alternatively ("also quite common"), pronounced as voiced.
## Not commonly dropped when voiceless even in fast speech (but sometimes when pronounced as voiced).

dag-kaup       +   ˈtaxkʰœi:p,ˈtaɣkʰœi:p           daily wage
dag-peningar   +   ˈtaxpʰɛ:niŋkar,ˈtaɣpʰɛ:niŋkar   daily allowance, per diem
hag-kerfi      +   ˈhaxcʰɛrvɪ,ˈhaɣcʰɛrvɪ           economic system, economy
log-suða       +   ˈlɔxsʏ:ða,ˈlɔɣsʏ:ða             welding
sag-tenntur    +   ˈsaxtʰɛn̥tʏr,ˈsaɣtʰɛn̥tʏr         serrate (of a leaf)
veg-spotti     +   ˈvɛxspɔhtɪ,ˈvɛɣspɔhtɪ           stretch of road? short distance?
veg-tylla      +   ˈvɛxtʰɪtla,ˈvɛɣtʰɪtla           honor, prestige; credit, kudos
víg-hreiður    +   ˈvixr̥ei:ðʏr,ˈviɣr̥ei:ðʏr         pillbox, fortified bunker


## First part ending in soft /g/, which is dropped after á, ó, ú (as in non-compound words).

lágnætti       +   ˈlau:naihtɪ        midnight (dated)
skóglendi      +   ˈskou:lɛntɪ        woodland, wooded area
drjúgvirkur    +   ˈtrju:vɪr̥kʏr       efficient, highly effective


## First part ending in /k/: pre-aspirated in some common compound words

einstakk-lingur    einstaklingur  ˈeinstahkliŋkʏr    individual, person
klakk-laust        klaklaust      ˈkʰlahkœist        safe and sound (also spelled "klakklaust")
líkk-legur         líklegur       ˈlihklɛ:ɣʏr        likely, probable
lík-legur          +              ˈli:klɛ:ɣʏr        likely, probable        -        alternative pronunciation

## First part ending in /k/: not pre-aspirated in less common compound words

lak-lega        +    ˈla:klɛ:ɣa    poorly, insufficiently, substandardly
lok-leysa       +    ˈlɔ:klei:sa   nonsense, rubbish


## First part ending in /k/: disappears before <g> and <k>

bak-grunnur     +    ˈpa:krʏnʏr      background
strák-kjáni     +    ˈstrau:cʰau:nɪ  silly/foolish boy, goofy lad
blek-klessa     +    ˈplɛ:kʰlɛsa     ink blot
þak-gluggi      +    ˈþa:klʏcɪ       skylight


## mf, mv, ns (also in non-compound words): previous vowel nasalized; in fast and informal speech, the nasal consonant may disappear, leaving only a nasalized vowel

fram-farir      +   ˈfrãmfa:rɪr    advancements, strides
fram-vinda      +   ˈfrãmvɪnta     progress; development
sam-ferða       +   ˈsãmfɛrða      traveling with, accompanying (adj)
um-ferð         +   ˈʏ̃mfɛrð        traffic, congestion; flow; cycle, round
inn-sýn         +   ˈɪ̃nsi:n        insight, perception
van-svefta      +   ˈvãnsvɛfta     sleep-deprived

## <ns>, <nns> in non-compound words:
dansa           +   tãnsa          dance
eins            +   e͠ins           identical; equal
vinnsla         +   vɪ̃nsla         processing (noun)

## <n-b> across a compound boundary informally becomes /mp/, <n-k> informally becomes /ŋkʰ/; in colloquial speech the <n> may drop but this is frowned on in formal speech
eim-búi         einbúi       eimpu:I           loner, hermit, recluse                    -              informal
eim-býlis-hús   einbýlishús  eimpi:lIshu:s 	   detached house, single-family home        -              informal   
imm-bú          innbú        Impu:             household goods                           -              informal
Imm-bær         Innbær       Impai:r           inner city                                -              informal
innan-sleikjur  +            Inãnstlei:cYr     trifles
undam-brögð     undanbrögð   Yntamprœɣð        excuses, pretexts                         -              informal
undaŋ-koma      undankoma    Yntaŋkhɔ:ma       escape, way out                           -              informal


## <p> across a compound boundary disappears before <b>, <p>
kaup-bætir      +           khœi:pai:ðYr       added bonus, something coming along "in the bargain"
kaup-binding    +           khœi:pIntiŋk       wage freeze
lop-band        +           lɔ:pant            band or ribbon of coarse wool yarn        -               book says [lɔp:and], probably a mistake
upp-bót         +           Yhpou:t            supplement; compensation                  -               book says [Yhbout], probably a mistake

## <p> across a compound boundary especially in kaup- and upp- informally assimilates to a geminate /f:/ before <f>, with shortening of preceding and following vowels if long; not in formal speech
kaup-fé-lag      +           khœi:pfjɛ:la:ɣ,khœif:jɛla:ɣ[informal]   (merchant) cooperative
kau-fé-lag       kaupfélag   khœi:fjɛ:la:ɣ                           (merchant) cooperative        -     alternative informal pronunciation
kaup-far         +           khœi:pfa:r,khœif:ar[informal]           merchant ship; trader
kau-far          kaupfar     khœi:fa:r                               merchant ship; trader         -     alternative informal pronunciation
upp‿fyrir        +           YhpfI:rIr,Yf:IrIr[informal]             above
upp-fræða        +           Yhpfrai:ða,Yf:raiða[informal]           educate; inform               -     book has [Yf:rai:ða], probably a typo

## <p> across a compound boundary sometimes becomes /f/ before <s> and <t> (with shortening of a preceding vowel if long), across a compound boundary
kaup-sýsla       +           khœi:psistla,khœifsistla[informal]      trade, commerce
kaup-tíð         +           khœi:pthi:ð,khœifthi:ð[informal]        trading season (historical)
kaup-trygging    +           khœi:pthrIciŋk,khœifthrIciŋk[informal]  guaranteed minimum wage

## <p> across a compound boundary may be aspirated before /m/
kaup-maður       +           khœi:pma:ðYr,khœihpma:ðYr               merchant, trader
kaup-mennska     +           khœi:pmɛnska,khœihpmɛnska               commerce, business
Kaup-manna-höfn  +           khœi:pmanahœpn̥,khœihpmanahœpn̥           Copenhagen

## First part of compound ending in <r>, which becomes devoiced before a voiceless fricative or approximant or aspirated stop (other than /h/ + vowel)
## 1. Before <p>, <t>, <k>, <s>:
kór-söngur       +           khouRsœiŋkYr        
kyrr-stæður      +           chIRstai:ðYr
leir-ker         +           leiRchɛ:r
nær-pils         +           naiRphIls
nær-tækur        +           naiRthai:kYr
sér-stakur       +           sjɛRsta:kYr
vor-kuldar       +           vɔRkhYltar
úr-koma          +           uRkhɔ:ma
## 2. Before <þ>, <hj>, <hl>, <hn> (also presumably <f> but no examples given):
búr-hnífur       +           puRNi:vYr
fer-hjóla        +           fɛRçou:la
var-hluta        +           vaRLY:ta
vor-hláka        +           vɔRLau:ka
vor-þing         +           vɔRθiŋk
## 3. Assimilation before <hr>: [note, following vowels shortened after double consonant from assimilation, probably a general rule]
úr-hrak          +           uR:ak
vor-hret         +           vɔR:ɛt
## 4. <r> at the end of an inflection at the end of the first part of a compound often dropped, especially informally in common words:
efti-sjá         eftirsjá         ɛftIsjau:
efti-tekt        eftirtekt        ɛftIthɛxt
hjálpa-gögn      hjálpargögn      çauLpakœkN
Stranda-kirkja   Strandarkirkja   strantachIRca
kopa-stunga      koparstunga      khɔ:pastuŋka
unda-legur       undarlegur       Yntalɛ:ɣYr
yfi-læti         yfirlæti         I:vIlai:tI


geim-steinn  +	ˈceimsteitn̥   meteoroid
loft-steinn  +	ˈlɔftsteitn̥   meteorite
gvuð-spjall  guðspjall  ˈkvʏðspjatl̥   gospel
ski[f]-stjóri  skipstjóri   ˈscɪfstjou:rɪ  captain    [not with /f/ in https://enska.arnastofnun.is/en/ord/36534/tungumal/EN]

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
