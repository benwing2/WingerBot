local export = {}

--[=[
Each line of the testcase text is either a high-level header beginning with ###, a subheader beginning with ##, a
comment beginning with #, a blank line or an example. Examples consist of three to six fields, deliminated by two or
more spaces. The first field is the respelling; the second field is the actual spelling, or + to derive it from the
respelling; the third field is the expected IPA pronunciation; the optional fourth field is the gloss; the optional
fifth field is the dialect; and the optional sixth field is a comment.

See [[Module:User:Benwing2/run-lua/is-IPA/testcases/driver]] for more detailed information on the format of testcases,
along with information on how to create a new subset of testcases.
]=]

export.testcases = [==[

### Substitutions in the following:

# : -> ː
# I -> ɪ
# Y -> ʏ
# R -> r̥   
# L -> l̥  
# N -> n̥ 
# [ptkc]h -> \1ʰ
# , -> ˌ
# ' -> ˈ
# ˌˈ -> ,ˈ

### Simple words (not compound)

þorn          +        ˈθɔrtn̥                  thorn
himinn        +        ˈhɪːmɪn                 heaven
minn          +        ˈmɪn(ː)                 my; mine
brúnn         +        ˈprutn̥                  brown
steinn        +        ˈsteitn̥                 stone
karl          +        ˈkʰartl̥                 man
rusl          +        ˈrʏstl̥                  trash
býsna         +        ˈpistna                 rather
taka          +        ˈtʰaːka                 to take
þökk          +        ˈθœhk                   thanks (n.)
brotna        +        ˈprɔhtna                to break (intr.)
sakna         +        ˈsahkna                 to miss, long for; to lack
kembt         +        ˈcʰɛm̥t                  combed; debugged (supine)
þið           +        ˈθɪːð                   you (pl.)
gvuð          guð      ˈkvʏːð                  God
byggja        +        ˈpɪca                   to build
syngja        +        ˈsiɲca                  to sing
munkur        +        ˈmuŋ̊kʏr                 monk
öngull        +        ˈœiŋkʏtl̥                fishhook
drengur       +        ˈtreiŋkʏr               boy
svangur       +        ˈsvauŋkʏr               hungry
England       +        ˈeiŋlant                England
segja         +        ˈseija                  to say
fluga         +        ˈflʏːɣa                 fly (insect)
fljúga        +        ˈfljuːa                 to fly
bógur         +        ˈpouːʏr                 animal shoulder; bow (of a ship); side
lágur         +        ˈlauːʏr                 low
pró(f)a       +        ˈpʰrouː(v)a             to test; to look at
dragt         +        ˈtraxt                  pantsuit; skirt suit
september     +        ˈsɛftɛmpɛr              September
október       +        ˈɔxtoupɛr               October
gjalda        +        ˈcalta                  to pay
geta          +        ˈcɛːta                  to be able
kjósa         +        ˈcʰouːsa                to vote; to choose
keyra         +        ˈcʰeiːra                to drive
kirkja        +        ˈcʰɪr̥ca                 church
hlýr          +        ˈl̥iːr                   warm
hratt         +        ˈr̥aht                   pushed
spara         +        ˈspaːra                 to spare; to save (money)
þykja         +        ˈθɪːca                  to be considered, to seem
lofa          +        ˈlɔːva                  to promise
rós           +        ˈrouːs                  rose
vaxa          +        ˈvaksa                  to grow
allur         +        ˈatlʏr                  whole, entire; all; completely
alls          +        ˈals                    all together, in total
fals          +        ˈfals                   falseness, deceit; rebate
falsa         +        ˈfalsa                  to falsify, to forge, to fake
allt          +        ˈal̥t                    everything; (the) whole; all; completely
alt           +        ˈal̥t                    contralto
basalt        +        ˈpaːsal̥t                basalt
ball-skák     +        ˈbatl̥ˌskauːk            billiards
fjalls-brún   +        ˈfjalsˌbruːn            crest, brim (of a mountain)
basl          +        ˈpastl̥                  struggle, grind
basla         +        ˈpastla                 to struggle, to wrestle (with); to toil
myll:a        +        ˈmɪl(ː)a                mill
austan-fjalls  +       ˈœistanˌfjals           in southern Iceland; in eastern Norway
nudda         +        ˈnʏt(ː)a                to rub
breidd        +        ˈpreit(ː)               width; latitude
gribba        +        ˈkrɪp(ː)a               harpy, shrew
gabb          +        ˈkap(ː)                 hoax
flagga        +        ˈflak(ː)a               to fly (a flag); to flaunt
dögg          +        ˈdœk(ː)                 dew
saggi         +        ˈsac(ː)ɪ                damp
byggja        +        ˈpɪc(ː)a                to build; to settle (a land)
hvass         +        ˈkʰvas(ː)               strong; sharp
hvasst        +        ˈkʰvast                 sharply, piercingly
byssa         +        ˈpɪs(ː)a                firearm, gun
þreyttur      +        ˈθreihtʏr               tired; tired (of), fed up
nótt          +        ˈnouht                  night
vatna         +        ˈvahtna                 to water
vatn          +        ˈvahtn̥                  water; lake
stoppa        +        ˈstɔhpa                 to stop
stopp         +        ˈstɔhp                  stop, halt
vopna         +        ˈvɔhpna                 to arm
vopn          +        ˈvɔhpn̥                  weapon
drekka        +        ˈtrɛhka                 to drink
hekla         +        ˈhɛhkla                 to crochet
kaþólikki     +        ˈkʰaːθoulɪhcɪ           Catholic man
frakki        +        ˈfrahcɪ                 raincoat
drykkja       +        ˈtrɪhca                 drinking
voffi         +        ˈvɔf(ː)ɪ                doggie
só[f]i        +        ˈsou:fɪ                 sofa
e[v]st        efst     ˈɛvst                   top                                   -          common but non-normative
ehji          ekki     ˈɛçɪ                    not
ry[þ]mi       +        ˈrɪθmɪ                  rhythm                                -          proscribed
vaffla        +        ˈvafla                  waffle
rö[v]la       röfla    ˈrœvla                  to ramble, to chatter                 -          proscribed spelling
rö[v]ls       röfls    ˈrœvls                  rambling, chattering (gen. sg.)       -          proscribed spelling
kæra          +        ˈcʰaiːra                to accuse; to complain; accusation; complaint
kragi         +        ˈkʰraijɪ                collar
[g]æi         +        ˈkaijɪ                  dude, guy
dis[k]etta    +        ˈtɪskɛhta               diskette
[K]enía       +        ˈkʰɛːnia                Kenya
nefndi        +        ˈnɛmtɪ                  named (masc. nom. sg. weak)
hafrar        +        ˈhavrar                 oats
efld   +   ˈɛl(ˠ)t  strengthened (fem. nom. sg. strong)
eflds   +   ˈɛl(ˠ)ts  strengthened (masc. gen. sg. strong)


### Words with indicated affixes

ráp-s   +   ˈrauːps     roaming, wandering (gen. sg.)
lag-s   +   ˈlaxs       layer; song; form, shape   -          (should pronunciation be [ˈlaːxs]?)


### Compound words

## First part ends in a vowel
á-fall   +  ˈauːˌfatl̥   shock, trauma; dew
á-klæði  +  ˈauːˌkʰlaiːðɪ   upholstery
í-gerð   +  ˈiːˌcɛrð    abscess
ó-farir  +   ˈouːˌfaːrɪr   misfortunes, faiilures (pl.)
fé-gjarn  +  ˈfjɛːˌcartn̥   greedy for money; avaricious
bú-staður  +  ˈpuːˌstaːðʏr   dwelling, abode; cabin
ósköp  +   ˈouskœp    really, quite; heaps, loads    -       informal

## Second part begins with a vowel or an h + vowel
mið-aldir  +  ˈmɪːðˌaltɪr   Middle Ages
sam-eign   +  ˈsaːmˌeikn̥   shared asset; communal space
úr-illur   +  ˈuːrˌɪtlʏr   grumpy; sullen
al-heimur  +  ˈaːlˌheiːmʏr   universe, cosmos (poetic)
ljós-haf   +  ˈljouːsˌhaːv   sea of light

## First part ends in -p, -t, -k or -s and second part begins with a consonant or cluster (MANY EXCEPTIONS)
tap-rekstur  +  ˈtʰaːpˌrɛkstʏr   loss-making business
kaup-maður   +  ˈkœiːpˌmaːðʏr   merchant
at-kvæði     +  ˈaːtˌkʰvaiːðɪ   syllable
mót-læti     +  ˈmouːtˌlaiːtɪ   adversity; misfortune
bik-svartur  +  ˈpɪːkˌsvar̥tʏr   pitch black
sak-laus     +  ˈsaːkˌlœiːs   innocent
hús-maður    +  ˈhuːsˌmaːðʏr   farmhand (archaic)
ís-lenskur   +  ˈiːsˌlɛnskʏr   Icelandic


## First part ends in another consonant (resonant, or fricative other than -s) and second part begins with a consonant or cluster
að-ferð      +  ˈaðˌfɛrð      method          -
af-greiða    +  ˈavˌkreiːða   to serve; to deal with; to complete, to process      -
af-mæli      +  ˈavˌmaiːlɪ    birthday        -      [seemingly pronounced with /mː/ in https://enska.arnastofnun.is/en/ord/2617/tungumal/EN]
lag-laus     +  ˈlaɣˌlœiːs    tone-deaf       -
veg-sama     +  ˈvɛɣˌsaːma    to praise, to glorify      -
Dal-vík      +  ˈtalˌviːk     [female given name]        -
kol-svartur  +  ˈkʰɔlˌsvar̥tʏr  coal black     -
mál-tíð      +  ˈmaulˌtʰiːð    meal; mealtime     -
stór-gerður  +  ˈstourˌcɛrðʏr  rugged, coarse-hewn (of facial features); coarse, crude     -
vor-koma     +  ˈvɔr̥ˌkʰɔːma    arrival of spring    -      note the devoiced r before written <k> in this case across compound boundaries
frum-legur   +  ˈfrʏmˌlɛːɣʏr   original, novel      -
vin-semd     +  ˈvɪnˌsɛmt      friendliness, kindness      -
af-taka      +  ˈavˌtʰaːka     to refuse; execution (killing)  -     devoiced f before written <t> in this case across compound boundaries especially in older speech; [pronounced with /v/ in https://enska.arnastofnun.is/en/ord/2721/tungumal/EN]

## First part ending in /d/ (after /l/ or /n/), drops before /d/ or /t/
sand-dæla    +  ˈsanˌtaiːla    sand pump
sund-tök     +  ˈsʏnˌtʰœːk     swimming strokes (pl.)
hund-tík     +  ˈhʏnˌtʰiːk     female dog, bitch

## First part ending in /d/ (after /l/ or /n/), optionally drops before /s/; "tends to be dropped before /s/, especially in common words"
and-skoti     +  ˈanˌskɔːti,ˈantˌskɔːti           devil fiend; fucking (adv.) [pronounced with [tʰ] and short [ɔ] in https://enska.arnastofnun.is/en/ord/3292/tungumal/EN]
hand-sama     +  ˈhanˌsaːma,ˈhantˌsaːma           to seize; to capture; to arrest
hund-skamma   +  ˈhʏnˌskam(ː)a,ˈhʏntˌskam(ː)a          to scold severely, to chew out
eld-spýta     +  ˈɛlˌspiːta,ˈeltˌspiːta          match (for flame)
kvöld-skóli   +  ˈkʰvœlˌskouːlɪ,ˈkʰvœltˌskouːlɪ    night school

## First part endiing in /d/ (after /l/ or /n/), should not drop before /b/ (except in slopppy/colloquial language)
kvöld-blað     +  ˈkʰvœltˌplaːð    evening newspaper
hand-börur     +  ˈhantˌpœːrʏr     hand stretcher (litter for transporting an injured, sick or dead person)
vald-boð       +  ˈvaltˌpɔːð       instruction, command

## First part endiing in /ð/, remains voiced even if aspirated consonant follows
## /ð/ tends to drop, especially between consonants (with devoicing of a preceding /r/ before an aspirated stop or voiceless fricative/approximant other than /h/ + vowel), but in fast speech even after a vowel (with lengthening of the vowel)
bið-tími       +   ˈpɪðˌtʰiːmɪ     wait, waiting time
við-tal        +   ˈvɪðˌtʰaːl      interview
varð-turn      +   ˈvarðˌtʰʏrtn̥   watchtower
að-krepptur    +   ˈaðˌkʰrɛftʏr   pressed (for time, money); cramped, confined
ráð-kænska     +   ˈrauðˌcʰainska  resourcefulness, astuteness
við-kvæði      +   ˈvɪðˌkʰvaiːðɪ   refrain, chorus
að-koma        +   ˈaðˌkʰɔːma      situation; involvement; driveway
borð-búnaður   +   ˈporðˌpuːnaðʏr  tableware    -      [/u/ given as short but apparently a typo; compare treggáfaður below with long á]
bragð-betri    +   ˈpraɣðˌpɛːtrɪ   tastier, more delicious
harð-brjósta   +   ˈharðˌprjousta  heartless, callous
orð-tak        +   ˈɔrðˌtʰaːk      expression, idiom
við-tæki       +   ˈvɪðˌtʰaiːcɪ    radio set; extensive, far-reaching (nom. masc. sg. weak)
verð-myndun    +   ˈvɛrðˌmɪntʏn    price determination
verð-skulda    +   ˈverðˌskʏlta    to deserve, to merit

## Names with /ð/ at the end of a compound, which conventionally drops or assimilates
Bárð-dælir     +   ˈpaurðˌtaiːlɪr   [placename]
Bár-dælir      Bárðdælir   ˈpaurˌtaiːlɪr    [placename]     -       local pronunciation
Norð-fjörður   +   ˈnɔrðˌfjœrðʏr    [placename]
Nor-fjörður   Norðfjörður   ˈnɔr̥ˌfjœrðʏr     [placename]     -       local pronunciation
Norð-lendingur  +  ˈnɔrðˌlɛntiŋkʏr  [placename]
Nor-lendingur  Norðlendingur  ˈnɔrˌlɛntiŋkʏr   [placename]     -       local pronunciation
Norð-lingar    +   ˈnɔrðˌliŋkʏr     [placename]
Nor-lingar    Norðlingar   ˈnɔrˌliŋkʏr      [placename]     -       local pronunciation
Breið-dalur    +   ˈpreiðˌtaːlʏr    [placename]
Breid[:]alur    Breiðdalur   ˈpreitˌtalʏr     [placename]     -       local pronunciation [it appears vowels are short directly after a geminate]
Skrið-dalur    +   ˈskrɪðˌtaːlʏr    [placename]
Skrid[:]alur    Skriðdalur   ˈskrɪtˌtalʏr     [placename]     -       local pronunciation

## First part ending in /f/, which becomes [v] before a vowel, voiced sound, unaspirated stop or /h/ + vowel
of-ætlun     +    ˈɔːvˌaihtlʏn       insurmountable task
af-dalur     +    ˈafˌtaːlʏr         side valley; isolated valley
raf-geymir   +    ˈravˌceiːmɪr       accumulator, storage battery
haf-gola     +    ˈhavˌkɔːla         sea breeze
af-hausa     +    ˈavˌhœiːsa         to behead
a-fausa     afhausa    ˈaːˌfœiːsa    to behead      -       with assimilation
líf-láta     +      ˈlivˌlauːta      to put to death, to execute; execution, murder (gen pl indef)
raf-neisti   +      ˈravˌneistɪ      electric spark
raf-reiknir  +      ˈravˌreihknɪr    (historical) computer

## First part ending in /f/, which becomes [f] before <s> and in older pronunciation before other voiceless fricatives and approximants and aspirated stops

af-hjúpa      +    ˈavˌçuːpa,ˈafˌçuːpa[older]          to unveil; to reveal
af-hrak       +    ˈavˌr̥aːk,ˈafˌr̥aːk[older]            outcast, pariah
af-kimi       +    ˈavˌcʰɪːmɪ,ˈafˌcʰɪːmɪ[older]        nook, corner
af-koma       +    ˈavˌkʰɔːma,ˈafˌkʰɔːma[older]        profits, financial situation
af-taka       +    ˈavˌtʰaːka,ˈafˌtʰaːka[older]        to refuse; execution (killing)
raf-tækni     +    ˈravˌtʰaihknɪ,ˈrafˌtʰaihknɪ[older]  electronics
Rif-tún       +    ˈrɪvˌtʰuːn,ˈrɪfˌtʰuːn[older]        [placename, a farm in the municipality of Ölfus in South Iceland]
af-skekktur   +    ˈafˌscɛxtʏr                         remote, isolated, secluded
af-staða      +    ˈafˌstaːða                          position, attitude, stance; location
of-hleðsla    +    ˈɔvˌl̥ɛðsla,ˈɔfˌl̥ɛðsla[older]        overload
of-hvörf      +    ˈɔvˌkʰvœrv,ˈɔfˌkʰvœrv[older]        hyperbole; (linguistics) semantic bleaching
of-sjónir     +    ˈɔfˌsjouːnɪr                        hallucinations

## First part ending in /f/, which formerly could become [p] before /l/ or /n/ across a compound boundary (as is normal when not across a boundary); now rare

Hab-liði      Hafliði    ˈhapˌlɪːðɪ                    [placename]                      -          dialectal
líb-legur     líflegur   ˈlipˌlɛːɣʏr                   lively, spirited                 -          dialectal
Stab-nes      Stafnes    ˈstapˌnɛːs                    [placename]                      -          dialectal

## First part ending in /f/, which tends to form a geminate before <f> or <v> (but aff- can sometimes be [avf-]; directly after a geminate, it seems the next vowel must be short
af-fall       +          ˈafˌfatl̥                      outflow; wastewater
af-ferma      +          ˈafˌfɛrma                     to unload
of-veiði      +          ˈɔvˌveiðɪ                     overfishing; overhunting
of-viti       +          ˈɔvˌvɪːtɪ                     genius, prodigy; idiot savant

## First part ending in /f/, before /m/; assimilates informally in common words
af-má         +          ˈavˌmauː                      to wipe, to erase
am-má         afmá       ˈamˌmau                       to wipe, to erase               -          more informal
af-mynda      +          ˈavˌmɪnta                     to distort, to deform
am-mynda      afmynda    ˈamˌmɪnta                     to distort, to deform           -          more informal
af-mæli       +          ˈavˌmaiːlɪ                    birthday, anniversary
am-mæli       afmæli     ˈamˌmailɪ                     birthday, anniversary           -          more informal
a-mæli        afmæli     ˈaːˌmaiːlɪ                    birthday, anniversary           -          alternative pronunciation


## First part ending in /f/, before a labial; it becomes [v] or (in everyday speech, but not formal speech) assimilates to the labial

raf-magn       +   ˈravˌmakn̥,ˈramˌmakn̥[informal]      electricity
af-bera        +   ˈavˌpɛːra,ˈapˌpɛra[informal]       to tolerate, to bear
af-bragð       +   ˈavˌpraɣð,ˈaˌpraɣð[informal]       excellent thing/person
of-boðs-legur  +   ˈɔvˌpɔðsˌlɛːɣʏr,ˈɔpˌpɔðsˌlɛːɣʏr[informal]         tremendous, enormous; terrible, awful
o-boðs-legur  ofboðslegur   ˈɔːˌpɔðsˌlɛːɣʏr           tremendous, enormous; terrible, awful      -         alternative informal form


## First part ending in soft /g/, which becomes [ɣ] before a vowel, voiced sound, unaspirated stop or /h/ + vowel
## Commonly in fast speech, especially in common words, the [ɣ] is dropped before a consonant and the preceding vowel lengthened; not acceptable in formal speech.

aug-ljós       +   ˈœiɣˌljouːs     obvious, apparent
dag-blað       +   ˈtaɣˌplaːð      newspaper
dag-legur      +   ˈtaɣˌlɛːɣʏr     daily, everyday
dag-mamma      +   ˈtaɣˌmam(ː)a      childminder, daycare provider, childcare provider
fag-maður      +   ˈfaɣˌmaːðʏr     professional, expert
hag-ræða       +   ˈhaɣˌraiːða     get comfortable; adjust, sort out; economize; adapt, modify
lag-hentur     +   ˈlaɣˌhɛn̥tʏr     handy, dexterous
leg-bólga      +   ˈleɣˌpoulka     uterine inflammation
nag-dýr        +   ˈnaɣˌtiːr       rodent
sog-æðar       +   ˈsɔːɣˌaiːðar     lymphatic vessels
treg-gáfaður   +   ˈtʰrɛɣˌkauːvaðʏr   slow-witted, dim


## First part ending in soft /g/, which becomes [x] before a voiceless fricative or approximant or aspirated stop (other than /h/ + vowel)
## Alternatively ("also quite common"), pronounced as voiced.
## Not commonly dropped when voiceless even in fast speech (but sometimes when pronounced as voiced).

dag-kaup       +   ˈtaxˌkʰœiːp,ˈtaɣˌkʰœiːp           daily wage
dag-peningar   +   ˈtaxˌpʰɛːniŋkar,ˈtaɣˌpʰɛːniŋkar   daily allowance, per diem
hag-kerfi      +   ˈhaxˌcʰɛrvɪ,ˈhaɣˌcʰɛrvɪ           economic system, economy
log-suða       +   ˈlɔxˌsʏːða,ˈlɔɣˌsʏːða             welding
sag-tenntur    +   ˈsaxˌtʰɛn̥tʏr,ˈsaɣˌtʰɛn̥tʏr         serrate (of a leaf)
veg-spotti     +   ˈvɛxˌspɔhtɪ,ˈvɛɣˌspɔhtɪ           stretch of road, short distance
veg-tylla      +   ˈvɛxˌtʰɪtla,ˈvɛɣˌtʰɪtla           honor, prestige; credit, kudos
víg-hreiður    +   ˈvixˌr̥eiːðʏr,ˈviɣˌr̥eiːðʏr         pillbox, fortified bunker


## First part ending in soft /g/, which is dropped after á, ó, ú (as in non-compound words).

lágnætti       +   ˈlauːˌnaihtɪ        midnight (dated)
skóglendi      +   ˈskouːˌlɛntɪ        woodland, wooded area
drjúgvirkur    +   ˈtrjuːˌvɪr̥kʏr       efficient, highly effective


## First part ending in /k/: pre-aspirated in some common compound words

einstakk-lingur    einstaklingur  ˈeinˌstahkˌliŋkʏr    individual, person
klakk-laust        klaklaust      ˈkʰlahkˌlœist        safe and sound (also spelled "klakklaust")
líkk-legur         líklegur       ˈlihkˌlɛːɣʏr        likely, probable
lík-legur          +              ˈliːkˌlɛːɣʏr        likely, probable        -        alternative pronunciation; note long vowel in first component before <k>

## First part ending in /k/: not pre-aspirated in less common compound words

lak-lega        +    ˈlaːkˌlɛːɣa    poorly, insufficiently, substandardly
lok-leysa       +    ˈlɔːkˌleiːsa   nonsense, rubbish


## First part ending in /k/: disappears before <g> and <k>

bak-grunnur     +    ˈpaːˌkrʏn(ː)ʏr      background
strák-kjáni     +    ˈstrauːˌcʰauːnɪ  silly/foolish boy, goofy lad
blek-klessa     +    ˈplɛːˌkʰlɛs(ː)a     ink blot
þak-gluggi      +    ˈθaːˌklʏc(ː)ɪ       skylight


## mf, mv, ns (also in non-compound words): shows up with frication (e.g. [ṽf], [z̃s]); in fast and informal speech, a nasalized vowel results

fram-farir      +   ˈframˌfaːrɪr    advancements, strides
fram-vinda      +   ˈframˌvɪnta     progress; development
sam-ferða       +   ˈsamˌfɛrða      traveling with, accompanying (adj)
um-ferð         +   ˈʏmˌfɛrð        traffic, congestion; flow; cycle, round
inn-sýn         +   ˈɪnˌsiːn        insight, perception
van-svefta      +   ˈvanˌsvɛfta     sleep-deprived

## <ns>, <nns> in non-compound words:
dansa           +   ˈtansa          to dance
eins            +   ˈeins           identical; equal; identically, equally
vinnsla         +   ˈvɪnsla         processing (noun)

## <n-b> across a compound boundary informally becomes /mp/, <n-k> informally becomes /ŋkʰ/; in colloquial speech the <n> may drop but this is frowned on in formal speech
eim-búi         einbúi       ˈeimˌpuːɪ           loner, hermit, recluse                    -              informal
eim-býlis-hús   einbýlishús  ˈeimˌpiːlɪsˌhuːs       detached house, single-family home        -              informal   
imm-bú          innbú        ˈɪmˌpuː             household goods                           -              informal
ɪmm-bær         Innbær       ˈɪmˌpaiːr           inner city                                -              informal
innan-sleikjur  +            ˈɪn(ː)anˌstleiːcʏr     trifles
undam-brögð     undanbrögð   ˈʏntamˌprœɣð        excuses, pretexts                         -              informal
undaŋ-koma      undankoma    ˈʏntaŋˌkʰɔːma       escape, way out                           -              informal


## <p> across a compound boundary disappears before <b>, <p>
kaup-bætir      +           ˈkʰœiːˌpaiːtʏr       added bonus, something coming along "in the bargain"
kaup-binding    +           ˈkʰœiːˌpɪntiŋk       wage freeze
lop-band        +           ˈlɔːˌpant            band or ribbon of coarse wool yarn        -               book says [lɔpːand], probably a mistake
upp-bót         +           ˈʏhˌpouːt            supplement; compensation                  -               book says [ʏhbout], probably a mistake

## <p> across a compound boundary especially in kaup- and upp- informally assimilates to a geminate /fː/ before <f>, witʰ shortening of preceding and following vowels if long; not in formal speecʰ
kaup-fé-lag      +           ˈkʰœiːpˌfjɛːˌlaːɣ,ˈkʰœifˌfjɛˌlaːɣ[informal]   (merchant) cooperative
kau-fé-lag       kaupfélag   ˈkʰœiːˌfjɛːˌlaːɣ                           (merchant) cooperative        -     alternative informal pronunciation
kaup-far         +           ˈkʰœiːpˌfaːr,ˈkʰœifˌfar[informal]           merchant ship; trader
kau-far          kaupfar     ˈkʰœiːˌfaːr                               merchant ship; trader         -     alternative informal pronunciation
upp‿fyrir        +           ˈʏhpˌfɪːrɪr,ˈʏfˌfɪrɪr[informal]             above
upp-fræða        +           ˈʏhpˌfraiːða,ˈʏfˌfraiða[informal]           educate; inform               -     book has [ʏfːraiːða], probably a typo

## <p> across a compound boundary sometimes becomes /f/ before <s> and <t> (with shortening of a preceding vowel if long), across a compound boundary
kaup-sýsla       +           ˈkʰœiːpˌsistla,ˈkʰœifˌsistla[informal]      trade, commerce
kaup-tíð         +           ˈkʰœiːpˌtʰiːð,ˈkʰœifˌtʰiːð[informal]        trading season (historical)
kaup-trygging    +           ˈkʰœiːpˌtʰrɪc(ː)iŋk,ˈkʰœifˌtʰrɪc(ː)iŋk[informal]  guaranteed minimum wage

## <p> across a compound boundary may be aspirated before /m/
kaup-maður       +           ˈkʰœiːpˌmaːðʏr,ˈkʰœihpˌmaːðʏr               merchant, trader
kaup-mennska     +           ˈkʰœiːpˌmɛnska,ˈkʰœihpˌmɛnska               commerce, business
Kaup-manna-höfn  +           ˈkʰœiːpˌman(ː)aˌhœpn̥,ˈkʰœihpˌman(ː)aˌhœpn̥           Copenhagen

## First part of compound ending in <r>, which becomes devoiced before a voiceless fricative or approximant or aspirated stop (other than /h/ + vowel)
## 1. Before <p>, <t>, <k>, <s>:
kór-söngur       +           ˈkʰour̥ˌsœiŋkʏr    choral singing      
kyrr-stæður      +           ˈcʰɪr̥ˌstaiːðʏr    stationary, immobile
leir-ker         +           ˈleir̥ˌcʰɛːr       ceramic pot
nær-pils         +           ˈnair̥ˌpʰɪls       slip (woman's garment), petticoat
nær-tækur        +           ˈnair̥ˌtʰaiːkʏr    obvious, evident, at hand
sér-stakur       +           ˈsjɛr̥ˌstaːkʏr     particular; specific, distinct; special, unusual; distinctive, exceptional
vor-kuldar       +           ˈvɔr̥ˌkʰʏltar      cold spells in spring
úr-koma          +           ˈur̥ˌkʰɔːma        rainfall, precipitation
## 2. Before <þ>, <hj>, <hl>, <hn> (also presumably <f> but no examples given):
búr-hnífur       +           ˈpur̥ˌn̥iːvʏr       kitchen knife
fer-hjóla        +           ˈfɛr̥ˌçouːla       four-wheeled
var-hluta        +           ˈvar̥ˌl̥ʏːta        cheated of, deprived of
vor-hláka        +           ˈvɔr̥ˌl̥auːka       spring thaw
vor-þing         +           ˈvɔr̥ˌθiŋk         spring parliament, spring session
## 3. Assimilation before <hr>: [note, following vowels shortened after double consonant from assimilation, probably a general rule]
úr-hrak          +           ˈur̥ˌr̥ak           scum, dregs; scoundrel, wretch
vor-hret         +           ˈvɔr̥ˌr̥ɛt          cold spell in spring
## 4. <r> at the end of an inflection at the end of the first part of a compound often dropped, especially informally in common words:
efti-sjá         eftirsjá         ˈɛftɪˌsjauː        regret, sense of loss
efti-tekt        eftirtekt        ˈɛftɪˌtʰɛxt        attention, heed
hjálpa-gögn      hjálpargögn      ˈçaul̥paˌkœkn̥       aid, help; (in plural) emergency aid, emergency supplies
Stranda-kirkja   Strandarkirkja   ˈstrantaˌcʰɪr̥ca    Coastal Church (a particular famous Lutheran church)
kopa-stunga      koparstunga      ˈkʰɔːpaˌstuŋka     copperplate
unda-legur       undarlegur       ˈʏntaˌlɛːɣʏr       weird, strange
yfi-læti         yfirlæti         ˈɪːvɪˌlaiːtɪ       haughtiness; hubris, arrogance

## <s> at the end of the first part of a compound is maintained unless the second part begins with an <s>
ríkis-sjóður     +               ˈriːcɪˌsjouːðʏr    national treasury, public purse
heims-sýn        +               ˈheimˌsiːn         worldview; panorama
lands-sam-band   +               ˈlantˌsamˌpant      national association
lans-sam-band    landssamband    ˈlanˌsamˌpant       national association                            -                reduced pronunciation
minnis-stæður    +               ˈmɪn(ː)ɪˌstaiːðʏr  memorable, unforgettable    
náms-stjóri      +               ˈnaumˌstjouːrɪ     director of studies
Sigurðs-son      +               ˈsɪːɣʏrðˌsɔːn      [patronymic]
Sigurs-son       Sigurðsson      ˈsɪːɣʏr̥ˌsɔːn       [patronymic]                                    -                reduced pronunciation
sveins-stykki    +               ˈsveinˌstɪhcɪ      journeyman's piece [required work of art to finish apprenticeship]
Sveins-son       +               ˈsveinˌsɔːn        [patronymic]
annars‿staðar    +               ˈan(ː)ar̥ˌstaːðar   elsewhere
annas‿staðar     annars staðar   ˈan(ː)aˌstaːðar    elsewhere                                       -                reduced pronunciation
alls‿staðar      +               ˈalˌstaːðar        everywhere
sums‿staðar      +               ˈsʏmˌstaːðar       in some places

## with assimilation involving <s>
pres[:]-ekkja     prestsekkja     ˈpʰrɛsːˌɛhca       priest's widow                                 -                the notation [:] forces a geminate
pre[s]-setur      prestssetur     ˈpʰrɛsˌsɛtʏr       vicarage, parsonage                            -                the notation [s] forces an /s/ even where it would be otherwise dropped; NOTE: immediately before and after a geminate, long vowels are shortened
Vas[:]-dalur     Vatnsdalur      ˈvasːˌtaːlʏr       [placename; Lake Valley, northwest Iceland]
Mýva-sveit       Mývatnssveit    ˈmiːvaˌsveiːt      [placename; (Lake) Mývatn Region, northeast Iceland]

## <t>; in some words at the end of the first component of a compound before <l> or <t> at the beginning of the second component, there is pre-aspiration, as if a non-compound word
á-gætt-lega      ágætlega        ˈauːˌcaihtˌlɛːɣa  well, fine                                     -                 alternative pronunciation
mótt-taka        móttaka         ˈmouhˌtaːka       reception (event, function); reception desk; (in the pl.) reception, welcome        -     alternative pronunciation
rótt-tækur       róttækur        ˈrouhˌtaiːkʏr     radical, extreme                               -                 alternative pronunciation
vitt-leysa       vitleysa        ˈvɪhtˌleiːsa      nonsense, gibberish; mistake, blunder          -                 usual pronunciation
vitt-laus        vitlaus         ˈvɪhtˌlœiːs       stupid, foolish; wrong; crazy                  -                 usual pronunciation
mótt-læti        mótlæti         ˈmouhtˌlaiːtɪ     adversity, misfortune                          East Iceland
útt-norðan       útnorðan        ˈuhtˌnɔrðan       from the northwest                             East Iceland
áht-matur        átmatur         ˈauhtˌmaːtʏr      solid food (as opposed to porridge, etc.)      East Iceland
Grjótt-nes       Grjótnes        ˈkrjouhtˌnɛːs     [placename in the Slétta region]               Northeast Iceland
Vott-múli        Votmúli         ˈvɔhtˌmuːlɪ       [town in Flói]                                 regional

## <t>; normal pronunciation according to the usual rules for compounds; /t/ drops before <t> or <d>
á-gæt-lega       +               ˈauːˌcaiːtˌlɛːɣa  well, fine                                     -                 normal pronunciation; book says ['au:caitlɛ:ɣa] but this may be a mistake
lit-laus         +               ˈlɪːtˌlœiːs       colorless; bland, dull
skraut-legur     +               ˈskrœiːtˌlɛːɣʏr   decorative, ornamental, brilliant
mót-taka         +               ˈmouːˌtʰaːka      reception (event, function); reception desk; (in the pl.) reception, welcome        -      normal pronunciation
rót-tækur        +               ˈrouːˌtʰaiːkʏr    radical, extreme                               -                 normal pronunciation
rit-dómur        +               ˈrɪːˌtouːmʏr      review, critique                               -                 pronounced as [rI:t,tou:mYr] with double articulation (two releases) in https://enska.arnastofnun.is/en/ord/33391/tungumal/EN, although the book proscribes this; note that the website's pronunciation of <þátttaka> does not have double articulation or gemination
þátt-taka        +               ˈθauhˌtʰaːka      participation
eitt-hvað        +               ˈeihtˌkʰvaːð      something
sitt-hvað        +               ˈsɪhtˌkʰvaːð      a few, some
eihkvað          eitthvað        ˈeihkvað          something                                      -                 informal
sihkvað          sitthvað        ˈsɪhkvað          a few, some                                    -                 informal


## misc

geim-steinn        +             ˈceimˌsteitn̥       meteoroid
loft-steinn        +             ˈlɔftˌsteitn̥       meteorite
gvuð-spjall        guðspjall     ˈkvʏðˌspjatl̥       gospel
skif-stjóri        skipstjóri    ˈscɪfˌstjouːrɪ     captain                                        -                 [not with /f/ in https://enska.arnastofnun.is/en/ord/36534/tungumal/EN]
Mel-rakka-slétta   +             ˈmɛlˌrahkaˌstljɛhta  [placename, peninsula in northeast Iceland]  
Raufar-höfn        +             ˈrœiːvarˌhœpn̥       [village in Melrakkaslétta peninsula]
Heim-skauts-gerði  +             ˈheimˌskœitsˌcɛrðɪ   [Arctic Henge, a modern mystical monument near the village of Raufarhöfn]
Hraun-hafnar-tanga-viti    +     ˈr̥œinˌhapnarˌtʰauŋkaˌvɪːtɪ    [Hraunhafnartanga Lighthouse, the northernmost lighthouse in Iceland]
Hraun-hafnar-tanga-viti    +     ˈr̥œinˌhapnarˌtʰauŋkaˌvɪːtʰɪ    [Hraunhafnartanga Lighthouse, the northernmost lighthouse in Iceland]        East Iceland
Eyja-fjalla-jökull         +     ˈeiːjaˌfjatlaˌjœːkʏtl̥    [well-known volcano in southern Iceland]
jökul-hlaup        +             ˈjœːkʏl̥ˌl̥œiːp        [type of glacial outburst flood]
Brenni-steins-alda         +     ˈprɛn(ː)ɪˌsteinsˌalta    [volcano in southern Iceland]
Fljóts-dals-hérað          +     ˈfljoutsˌtalsˌçɛːrað     [former municipality in eastern Iceland]
Akur-eyri          +             ˈaːkʏrˌeiːrɪ          [large town in northern Iceland]
Akur-eyri          +             ˈaːkʰʏrˌeiːrɪ          [large town in northern Iceland]           Northern Iceland
of-fitu-vanda-mál  +             ˈɔfˌfɪːtʏˌvantaˌmauːl    (in the plural) problem of obesity
fjár-afla-maður    +             ˈfjauːrˌavlaˌmaːðʏr      tycoon, magnate
fjár-bú-skapur     +             ˈfjaurˌbuːˌskaːpʏr       sheep raising                 -                          [in https://enska.arnastofnun.is/en/ord/62651/tungumal/EN, however, fjár- is long]
sauð-fjár-bú-skapur      +       ˈsœiðˌfjaurˌbuːskaːpʏr    sheep farming, sheep husbandry
sauð-fjár-veiki-varnir   +       ˈsœiðˌfjaurˌveiːkɪˌvarnɪr   measures to prevent the spread of sheep disease       [in https://enska.arnastofnun.is/en/ord/64828/tungumal/EN, sauð- and veiki- appear long]
sauma-vélar-nál    +             ˈsœiːmaˌvjɛːlar-nauːl     sewing machine needle
fé-lags-mála-ráðu-neyti    +     ˈfjɛːˌlaksˌmauːlaˌrauːðʏˌneiːtɪ         ministry of social affairs
deildar-hjúkrunar-fræðingur  +   ˈteiltar̥ˌçuːkrʏnar̥ˌfraiːðinkʏr         head nurse (lit. "ward registered nurse", more lit. "ward nursing expert")
]==]

return export
