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
himinn        +        ˈhɪːmɪn(ː)              heaven
minn          +        ˈmɪn(ː)                 my; mine
brúnn         +        ˈprutn̥                  brown
rúnn:aður     +        ˈrun(ː)aðʏr             rounded
hinn:a        +        ˈhɪn(ː)a                of the; of those (gen pl.)
brúnn:a       +        ˈprun(ː)a               of the eyebrows (def gen pl.)
steinn        +        ˈsteitn̥                 stone
karl          +        ˈkʰartl̥                 man
rusl          +        ˈrʏstl̥                  trash
býsna         +        ˈpistna                 rather
taka          +        ˈtʰaːka                 to take
þökk          +        ˈθœhk                   thanks (n.)
brotna        +        ˈprɔhtna                to break (intr.)
sakna         +        ˈsahkna                 to miss, long for; to lack
kembt         +        ˈcʰɛm̥t                  combed; debugged (supine)
þið           +        ˈθɪːð                   you all (pl.)
gvuð          guð      ˈkvʏːð                  God
fluga         +        ˈflʏːɣa                 fly (insect)
dragt         +        ˈtraxt                  pantsuit; skirt suit
september     +        ˈsɛftɛmpɛr              September
október       +        ˈɔxtoupɛr               October
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
ball-skák     +        ˈpatl̥ˌskauːk            billiards
fjalls-brún   +        ˈfjalsˌpruːn            crest, brim (of a mountain)
basl          +        ˈpastl̥                  struggle, grind
basla         +        ˈpastla                 to struggle, to wrestle (with); to toil
myll:a        +        ˈmɪl(ː)a                mill
austan-fjalls  +       ˈœistanˌfjals           in southern Iceland; in eastern Norway
nudda         +        ˈnʏt(ː)a                to rub
breidd        +        ˈpreit(ː)               width; latitude
gribba        +        ˈkrɪp(ː)a               harpy, shrew
gabb          +        ˈkap(ː)                 hoax
flagga        +        ˈflak(ː)a               to fly (a flag); to flaunt
dögg          +        ˈtœk(ː)                 dew
saggi         +        ˈsac(ː)ɪ                damp
byggja        +        ˈpɪc(ː)a                to build; to settle (a land)
geta          +        ˈcɛːta                  to be able
gjalda        +        ˈcalta                  to pay
segja         +        ˈseija                  to say
hanga         +        ˈhauŋka                 to hang
öngull        +        ˈœiŋkʏtl̥                fishhook
drengur       +        ˈtreiŋkʏr               boy
svangur       +        ˈsvauŋkʏr               hungry
syngja        +        ˈsiɲca                  to sing
engill        +        ˈeiɲcɪtl̥                angel
England       +        ˈeiŋlant                England
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
kjósa         +        ˈcʰouːsa                to vote; to choose
keyra         +        ˈcʰeiːra                to drive
kirkja        +        ˈcʰɪr̥ca                 church
munkur        +        ˈmuŋ̊kʏr                 monk
þanki         +        ˈθauɲ̊cɪ                 thought
þenkja        +        ˈθeiɲ̊ca                 to think (dated)
voffi         +        ˈvɔf(ː)ɪ                doggie
só[f]i        +        ˈsouːfɪ                 sofa
evst          efst     ˈɛvst                   top                                    -          common but non-normative
ĕ[ç]i         ekki     ˈɛçɪ                    not
ryþmi         +        ˈrɪθmɪ                  rhythm                                 -          proscribed
vaffla        +        ˈvapla                  waffle
rövla         röfla    ˈrœvla                  to ramble, to chatter                  -          proscribed spelling
rövls         röfls    ˈrœvls                  of rambling, of chattering (gen. sg.)  -          proscribed spelling
kæra          +        ˈcʰaiːra                to accuse; to complain; accusation; complaint
kragi         +        ˈkʰraijɪ                collar
disk_etta     +        ˈtɪskɛhta               diskette
hafrar        +        ˈhavrar                 oats
efld          +        ˈɛ(v)lt                 strengthened (fem. nom. sg. strong)
eflds         +        ˈɛ(v)lts                of (someone/something) strengthened (masc. gen. sg. strong)
frăm          +        ˈfram                   forth
ŭm            +        ˈʏm                     around

### Dialectal differences
hrópa         +        ˈr̥ouːpa                 to shout 
hrópa         +        ˈr̥ouːpʰa                to shout                                north
hrópa         +        ˈr̥ouːpʰa                to shout                                northeast
amaba         +        ˈaːmapa                 amoeba
amaba         +        ˈaːmapa                 amoeba                                  north
amaba         +        ˈaːmapa                 amoeba                                  northeast
stoppa        +        ˈstɔhpa                 to stop                                 north
stoppa        +        ˈstɔhpa                 to stop                                 northeast
gribba        +        ˈkrɪp(ː)a               harpy, shrew                            north
gribba        +        ˈkrɪp(ː)a               harpy, shrew                            northeast
vitur         +        ˈvɪːtʏr                 wise
vitur         +        ˈvɪːtʰʏr                wise                                    north
vitur         +        ˈvɪːtʰʏr                wise                                    northeast
Kanada        +        ˈkʰaːnata               Canada
Kanada        +        ˈkʰaːnata               Canada                                  north
Kanada        +        ˈkʰaːnata               Canada                                  northeast
þreyttur      +        ˈθreihtʏr               tired; tired (of), fed up               north
þreyttur      +        ˈθreihtʏr               tired; tired (of), fed up               northeast
nudda         +        ˈnʏt(ː)a                to rub                                  north
nudda         +        ˈnʏt(ː)a                to rub                                  northeast
þekja         +        ˈθɛːca                  to cover
þekja         +        ˈθɛːcʰa                 to cover                                north
þekja         +        ˈθɛːcʰa                 to cover                                northeast
drykkja       +        ˈtrɪhca                 drinking                                north
drykkja       +        ˈtrɪhca                 drinking                                northeast
byggja        +        ˈpɪc(ː)a                to build; to settle (a land)            north
byggja        +        ˈpɪc(ː)a                to build; to settle (a land)            northeast
veikur        +        ˈveiːkʏr                ill
veikur        +        ˈveiːkʰʏr               ill                                     north
veikur        +        ˈveiːkʰʏr               ill                                     northeast
drekka        +        ˈtrɛhka                 to drink                                north
drekka        +        ˈtrɛhka                 to drink                                northeast
flagga        +        ˈflak(ː)a               to fly (a flag); to flaunt              north
flagga        +        ˈflak(ː)a               to fly (a flag); to flaunt              northeast
hempa         +        ˈhɛm̥pa                  robe
hempa         +        ˈhɛm̥pa                  robe                                    north
hempa         +        ˈhɛmpʰa                 robe                                    northeast
kemba         +        ˈcʰɛmpa                 to comb; to card (wool)
kemba         +        ˈcʰɛmpa                 to comb; to card (wool)                 north
kemba         +        ˈcʰɛmpa                 to comb; to card (wool)                 northeast
heimta        +        ˈheim̥ta                 to demand
heimta        +        ˈheim̥ta                 to demand                               north
heimta        +        ˈheimtʰa                to demand                               northeast
ræmdur        +        ˈraimtʏr                reputed
ræmdur        +        ˈraimtʏr                reputed                                 north
ræmdur        +        ˈraimtʏr                reputed                                 northeast
aumka         +        ˈœim̥ka                  to pity
aumka         +        ˈœim̥ka                  to pity                                 north
aumka         +        ˈœimkʰa                 to pity                                 northeast
vanta         +        ˈvan̥ta                  to need
vanta         +        ˈvan̥ta                  to need                                 north
vanta         +        ˈvantʰa                 to need                                 northeast
binda         +        ˈpɪnta                  to tie, to bind
binda         +        ˈpɪnta                  to tie, to bind                         north
binda         +        ˈpɪnta                  to tie, to bind                         northeast
banki         +        ˈpauɲ̊cɪ                 bank
banki         +        ˈpauɲ̊cɪ                 bank                                    north
banki         +        ˈpauɲcʰɪ                bank                                    northeast
drangi        +        ˈtrauɲcɪ                pillar (of rock)
drangi        +        ˈtrauɲcɪ                pillar (of rock)                        north
drangi        +        ˈtrauɲcɪ                pillar (of rock)                        northeast
banka         +        ˈpauŋ̊ka                 to knock
banka         +        ˈpauŋ̊ka                 to knock                                north
banka         +        ˈpauŋkʰa                to knock                                northeast
fanga         +        ˈfauŋka                 to catch, to grab
fanga         +        ˈfauŋka                 to catch, to grab                       north
fanga         +        ˈfauŋka                 to catch, to grab                       northeast
hjálpa        +        ˈçaul̥pa                 to help
hjálpa        +        ˈçaul̥pa                 to help                                 north
hjálpa        +        ˈçaulpʰa                to help                                 northeast
Albani        +        ˈalpanɪ                 Albanian (man)
Albani        +        ˈalpanɪ                 Albanian (man)                          north
Albani        +        ˈalpanɪ                 Albanian (man)                          northeast
fálki         +        ˈfaul̥cɪ                 falcon
fálki         +        ˈfaul̥cɪ                 falcon                                  north
fálki         +        ˈfaulcʰɪ                falcon                                  northeast
Belgi         +        ˈpɛlcɪ                  Belgian (man)
Belgi         +        ˈpɛlcɪ                  Belgian (man)                           north
Belgi         +        ˈpɛlcɪ                  Belgian (man)                           northeast
kalka         +        ˈkʰal̥ka                 to go senile
kalka         +        ˈkʰal̥ka                 to go senile                            north
kalka         +        ˈkʰalkʰa                to go senile                            northeast
bólga         +        ˈpoulka                 swelling, inflammation
bólga         +        ˈpoulka                 swelling, inflammation                  north
bólga         +        ˈpoulka                 swelling, inflammation                  northeast
maðkur        +        ˈmaθkʏr                 worm
maðkur        +        ˈmaθkʏr                 worm                                    north
maðkur        +        ˈmaðkʰʏr                worm                                    northeast


### Inserted /j/
Svíi          +        ˈsviːjɪ                 Swede
Svíar         +        ˈsviːjar                Swedes (indef nom pl)
Svíum         +        ˈsviːjʏm                Swedes (indef dat pl)
olía          +        ˈɔːlija                 oil
olíu          +        ˈɔːlijʏ                 oil (indef acc/dat/gen sg)
sveia         +        ˈsveija                 to huff and puff, to tsk-tsk
bleium        +        ˈpleijʏm                diapers (indef dat pl)
bleyjum        +       ˈpleijʏm                diapers (indef dat pl)
heyið         +        ˈheijɪð                 the hay (def nom sg); you all make hay (2nd pl pres indic); you all carry out, perform (2nd pl pres indic)
hlýir         +        ˈl̥iːjɪr                 warm (strong masc nom pl); you may warm up (2nd sg pres subj)
nýir          +        ˈniːjɪr                 new (strong masc nom pl)
hlæi          +        ˈl̥aijɪ                  I/he/she/they may laugh (1/3 sg or 3 pl pres subj)
hlægi         +        ˈl̥aijɪ                  I/he/she might have laughed (1/3 sg past subj)
hlæja         +        ˈl̥aija                  to laugh
g_æi          +        ˈkaijɪ                  dude, guy
K_enía        +        ˈkʰɛːnija               Kenya


### Words with clusters

## from Eiríkur
káfa          +        ˈkʰauː(v)a              to finger; to grope                          -             for -áf-
mágur         +        ˈmauː(ɣ)ʏr              brother-in-law                               -             for -ág-
rófa          +        ˈrouː(v)a               tail; turnip                                 -             for -óf-
bógur         +        ˈpouː(ɣ)ʏr              shoulder (of an animal); bow (of a ship)     -             for -óg-
ljúfur        +        ˈljuː(v)ʏr              nice, pleasant                               -             for -úf-
bljúgur       +        ˈpljuː(ɣ)ʏr             shy, humble                                  -             for -úg-
efldi         +        ˈɛ(v)ltɪ                strengthened, reinforced (weak masc nom sg)  -             for -fld-
teflt         +        ˈtʰɛl̥t                  played (of a game; strong neut nom/acc sg)   -             for -flt-
hefndi        +        ˈhɛmtɪ                  avenged (weak masc nom sg)                   -             for -fnd-
hrafns        +        ˈr̥apn̥s[careful pronunciation],ˈr̥afs[natural or fast/allegro pronunciation]           raven (indef gen sg)                         -             for -fns-
jafnt         +        ˈjam̥t                   equally, evenly; equal, even (weak neut nom/acc sg)  -     for -fnt-
lofts         +        ˈlɔf(t)s                air; sky; ceiling (indef gen sg)             -             for -fls-
sigldi        +        ˈsɪltɪ                  widely travelled (weak masc nom sg)          -             for -g(g)ld-
siglt         +        ˈsɪl̥t                   widely travelled (strong neut nom/acc sg)    -             for -g(g)lt-
rigndi        +        ˈrɪŋtɪ                  it rained (past indic/subj)                  -             for -g(g)nd-
gagns         +        ˈkakn̥s[careful pronunciation],ˈkaxs[natural or fast/allegro pronunciation]            use, benefit (indef gen sg)                  -             for -gns-; https://enska.arnastofnun.is/is/ord/14704/tungumal/EN for <gagnslaus> has [kakstlœis]
skyggnst      +        ˈscɪŋst                 looked, scanned (supine)                     -             for -g(g)nst-
hrygnt        +        ˈr̥ɪŋ̊t                   spawned (supine)                             -             for -g(g)nt-
gjögts        +        ˈcœx(t)s                swaying, swinging (indef gen sg)             -             for -gts-
sýknt         +        ˈsiŋ̊t                   acquitted (adv.)                             -             for -knt-
svekkts       +        ˈsvɛx(t)s               disappointed (strong masc/neut gen sg)       -             for -k(k)ts-
þvælds        +        ˈθvail(t)s              crumpled; worn-out (strong masc/neut gen sg)  -             for -l(l)ds-
hvolfdi       +        ˈkʰvɔltɪ                overturned, capsized (3rd sg past indic)     -             for -lfd-
ýlfra         +        ˈil(v)ra                to howl, to whine                            -             for -lfr-
úlfs          +        ˈul(f)s                 wolf (indef gen sg)                          -             for -lfs-
tólfti        +        ˈtʰoul̥tɪ                twelfth                                      -             for -lft-
fylgdi        +        ˈfɪltɪ                  followed, accompanied (3rd sg past indic)    -             for -lgd-
volgna        +        ˈvɔlna                  to heat up, to grow warm (intrans)           -             for -lgn-
fólks         +        ˈfoul̥ks[careful pronunciation],ˈfouls[natural or fast/allegro pronunciation]          people, folk (indef gen sg)                  -             for -lks-
velktur       +        ˈvɛl̥tʏr                 thumbed-through, dog-eared                   -             for -lkt-
hvolps        +        ˈkʰvɔl̥ps[careful pronunciation],ˈkʰvɔls[natural or fast/allegro pronunciation]        puppy (indef gen sg)                         -             for -lps-
falsks        +        ˈfals(ks)               false, fake (str masc/neut gen sg)           -             for -lsks-
pólskt        +        ˈpʰoulst                Polish (strong neut nom/acc sg)              -             for -lskt-
gyllts        +        ˈcɪl̥(t)s                golden; gilded (strong fem nom or neut nom/acc sg)  -      for -l(l)ts-
rembdist      +        ˈrɛmtɪst                to struggle, to strain (1/2/3 sg past indic)  -            for -mbd-
lambs         +        ˈlams                   lamb (indef gen sg)                          -             for -mbs-
kembt         +        ˈcʰɛm̥t                  combed; debugged (supine)                    -             for -mbt-
límds         +        ˈlim(t)s                glued; stuck (strong masc/neut gen sg)       -             for -m(m)ds-
svamps        +        ˈsvam̥ps[careful pronunciation],ˈsvams[natural or fast/allegro pronunciation]          sponge (indef gen sg)                        -             for -mps-
sands         +        ˈsan(t)s                sand, sandy plain (indef gen sg)             -             for -n(n)ds-
hringdi       +        ˈr̥iŋtɪ                  rang; phoned (1/3 sg past indic)             -             for -ngd-
strengds      +        ˈstreiŋ(t)s             taut; pullled tight (strong masc/neut gen sg)  -           for -ngds-
lungna        +        ˈlu(ŋ)na                lungs (indef gen pl)                         -             for -ngn-
hangs         +        ˈhauŋs                  hanging around, dawdling                     -             for -ngs-
tengt         +        ˈtʰeiŋ̊t                 connected, joined (strong neut nom/acc sg)   -             for -ngt-
dynks         +        ˈtiŋ̊(k)s                thud (indef gen sg)                          -             for -nks-
fransks       +        ˈfrans(ks)              French (strong masc/neut gen sg)             -             for -n(n)sks-
punktur       +        ˈpʰun̥tʏr                point; period, dot, full stop; unit          -             for -nkt-
finnskt       +        ˈfɪnst                  Finnish (strong neut nom/acc sg)             -             for -n(n)skt-
teppts        +        ˈtʰɛf(t)s               blocked, obstructed (strong masc/neut gen sg)  -           for -p(p)ts-
sperðlar      +        ˈspɛrtlar               sheep sausages (nom pl)                      -             for -rðl-
harðna        +        ˈhartna                 to harden (intrans), to grow more severe     -             for -rðn-
horfði        +        ˈhɔrðɪ                  looked, watched (1/3 sg past indic)          -             for -rfð-
hvarfla       +        ˈkʰvartla               to wander; to hover                          -             for -rfl-
horfnir       +        ˈhɔrtnɪr                disappeared people (strong masc nom pl)      -             for -rfn-
orfs          +        ˈɔr(f)s                 scythe handle; weed whacker (indef gen sg)   -             for -rfs-
horfst        +        ˈhɔ(r̥)st                having looked at each other (supine)         -             for -rfst-
horft         +        ˈhɔr̥t                   having looked at (supine)                    -             for -rft-
mergð         +        ˈmɛrð                   multitude, crowd                             -             for -rgð-
morgna        +        ˈmɔrtna                 to dawn, for morning to come                 -             for -rgn-
dvergs        +        ˈtvɛr(k)s               dwarf (folklore); dwarf, little person       -             for -rgs-
margt         +        ˈmar̥t                   much, many, a lot (strong neut nom/acc sg)   -             for -rgt-
sterks        +        ˈstɛr̥(k)s               strong (strong masc/neut gen sg)             -             for -r(r)ks-
styrkst       +        ˈstɪ(r̥)st               having gotten stronger (supine)              -             for -rkst-
myrkt         +        ˈmɪr̥t                   dark (strong neut nom/acc sg)                -             for -rkt-
styrkts       +        ˈstɪr̥(t)s               supported, sponsored (strong masc/neut gen sg)  -          for -rkts-
karls         +        ˈkʰa((r)t)ls            man (indef gen sg)                           -             for -rls-
þyrmdi        +        ˈθɪ(r)mtɪ               spared (1/3 sg past indic)                   -             for -rmd-
harms         +        ˈha(r)ms                sorrow, grief (indef gen sg)                 -             for -rms-
hermt         +        ˈhɛ(r̥)m̥t                told, reported (supine)                      -             for -rmt-
fyrndur       +        ˈfɪ(r)ntʏr              outdated, obsolete                           -             for -rnd-
barns         +        ˈpar̥s                   child (indef gen sg)                         -             for -rns-
bernska       +        ˈpɛ(r)nska              childhood                                    -             for -rnsk-
hyrnt         +        ˈhɪn̥t                   horned (strong neut nom/acc sg)              -             for -rnt-
þorps         +        ˈθɔr̥(p)s                small village, hamlet (indef gen sg)         -             for -rps-
skerpst       +        ˈscɛ(r̥)st               having become clearer, having sharpened (intrans) (supine)  -  for -rpst-
skyrpti       +        ˈscɪr̥tɪ                 spit (1/3 sg past indic)                     -             for -rpt-
skerpts       +        ˈscɛr̥(t)s               sharpened (strong masc/neut gen sg)          -             for -rpts-
norskur       +        ˈnɔ(r̥)skʏr              Norwegian                                    -             for -rsk-
fjarski       +        ˈfja(r̥)scɪ              vast distance, far distance                  -             for -rsk- + "front" vowel (i/e/æ/ei)
þorsks        +        ˈθɔr̥s[careful or natural pronunciation],ˈθɔsks[careful or natural pronunciation],ˈθɔsː[fast/allegro pronunciation]      cod; fool (indef gen sg)                     -             for -rsks-
gerskt        +        ˈcɛ(r̥)st                Russian (historical) (strong neut nom/acc sg)  -           for -rskt-
sparsla       +        ˈspa(r̥)stla             to spackle, to plaster, to fill holes in     -             for -rsl-
versna        +        ˈvɛ(r̥)stna              to deteriorate, to get worse                 -             for -rsn-
berst         +        ˈpɛ(r̥)st                to fight, to struggle; to travel far (1/2/3 sg pres indic)  -  for -r(r)st-
fyrsts        +        ˈfɪsts[careful or natural pronunciation],ˈfɪsː[fast/allegro pronunciation]            first (strong masc/neut gen sg)              -             for -rsts-
svarts        +        ˈsvar̥(t)s               black (strong masc/neut gen sg)              -             for -r(r)ts-
fisks         +        ˈfɪsks[careful pronunciation],ˈfɪsː[natural or fast/allegro pronunciation]            fish (indef gen sg)                          -             for -sks-
frískt        +        ˈfrist                  healthy; brisk; fresh (strong neut nom/acc sg)  -          for -skt-
rasps         +        ˈrasps[careful pronunciation],ˈrasː[natural or fast/allegro pronunciation]            breadcrumbs; rasp (indef gen sg)             -             for -sps-
systkin       +        ˈsɪscɪn                 siblings                                     -             for -stk-
prests        +        ˈpʰrɛsts[careful pronunciation],ˈpʰrɛsː[natural or fast/allegro pronunciation]        priest (indef gen sg)                        -             for -sts-
vatns         +        ˈvasː                   water; lake (indef gen sg)                   -             for -tns-

## Additional cluster words (from Handbók um íslenskan framburð)
allra         +        ˈatl̥ra                  ... of all
elri          +        ˈɛltrɪ                  alder tree
fullnaðar     +        ˈfʏtl̥naðar              final; conclusive (prefix)
elna          +        ˈɛlna                   to grow (intrans); to worsen
snilld        +        ˈstnɪlt                 genius, mastery
felldi        +        ˈfɛltɪ                  pleated (weak masc nom sg)
við-felldnir  +        ˈvɪðˌfɛltnɪr            pleasant, nice, agreeable (strong masc nom pl)
allt          +        ˈal̥t                    everything; all the ..., the whole ...
stilltur      +        ˈstɪl̥tʏr                quiet; tranquil
villtra       +        ˈvɪl̥tra                 wild; disoriented; ferocious, savage (strong all-gender gen pl)
íllska        illska   ˈilska                  evil; malice; anger
hellst        +        ˈhɛlst                  preferably, especially; primarily
fellst        +        ˈfɛlst                  agree (1/2/3 sg pres indic)
ílls viti     ills viti   ˈils ˈvɪːtɪ          bad omen, jinx
Halls         +        ˈhals                   Halls cough drops, or Halls (British/American surname)          
alls          +        ˈals                    all together, in total
Falls         +        ˈfals                   (in Niagara Falls, Victoria Falls, etc.)

## Additional cluster words (from Handbók um íslenskan framburð)
sargla        +        ˈsartla                 to clatter, to rattle; to make a scraping sound (literary)    -        for -rgl-
bernskt       +        ˈpɛ(r)nst               childish; naive (strong neut nom/acc sg)                      -        for -rnskt-
bernsks       +        ˈpɛ(r)ns(ks)            childish; naive (strong masc/neut gen sg)                     -        for -rnsks-


### Words with indicated affixes

brall+s       +        ˈpratl̥s                 mischief; scheme, speculation (indef gen sg)
fall+s        +        ˈfatl̥s                  fall; collapse; (linguistics) case; (mathematics) function (indef gen sg)
Hall+s        +        ˈhatl̥s                  Hallur (surname) (gen sg)


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
ríg-halda  +  ˈriːɣˌhalta    hold tight
ríg-hélt   +  ˈrixˌçɛl̥t,ˈriɣˌçɛl̥t      held tight (1st/3rd. sg. past indic)         -         [note that hé- doesn't count as h+vowel because -é- is phonemically /jɛ/]

## First part ends in -p, -t, -k or -s and second part begins with a consonant or cluster (MANY EXCEPTIONS)
tap-rekstur  +  ˈtʰaːpˌrɛkstʏr   loss-making business
at-kvæði     +  ˈaːtˌkʰvaiːðɪ   syllable
mót-læti     +  ˈmouːtˌlaiːtɪ   adversity; misfortune
bik-svartur  +  ˈpɪːkˌsvar̥tʏr   pitch black
sak-laus     +  ˈsaːkˌlœiːs   innocent
hús-maður    +  ˈhuːsˌmaːðʏr   farmhand (archaic)
ís-lenskur   +  ˈiːsˌlɛnskʏr   Icelandic

## First part ends in another consonant (resonant, or fricative other than -s) and second part begins with a consonant or cluster
að-ferð      +  ˈaðˌfɛrð      method          -
af-greiða    +  ˈavˌkreiːða   to serve; to deal with; to complete, to process      -
lag-laus     +  ˈlaɣˌlœiːs    tone-deaf       -
veg-sama     +  ˈvɛxˌsaːma,ˈvɛɣˌsaːma    to praise, to glorify      -
Dal-vík      +  ˈtalˌviːk     [female given name]        -
kol-svartur  +  ˈkʰɔlˌsvar̥tʏr  coal black     -
mál-tíð      +  ˈmaulˌtʰiːð    meal; mealtime     -
stór-gerður  +  ˈstourˌcɛrðʏr  rugged, coarse-hewn (of facial features); coarse, crude     -
vor-koma     +  ˈvɔr̥ˌkʰɔːma    arrival of spring    -      note the devoiced r before written <k> in this case across compound boundaries
frum-legur   +  ˈfrʏmˌlɛːɣʏr   original, novel      -
vin-semd     +  ˈvɪnˌsɛmt      friendliness, kindness      -
af-taka      +  ˈavˌtʰaːka[modern],ˈafˌtʰaːka[older]     to refuse; execution (killing)  -     devoiced f before written <t> in this case across compound boundaries especially in older speech; [pronounced with /v/ in https://enska.arnastofnun.is/en/ord/2721/tungumal/EN]

## First part ending in /d/ (after /l/ or /n/), drops before /d/ or /t/
sand-dæla    +  ˈsanˌtaiːla    sand pump
sund-tök     +  ˈsʏnˌtʰœːk     swimming strokes (pl.)
hund-tík     +  ˈhʏnˌtʰiːk     female dog, bitch

## First part ending in /d/ (after /l/ or /n/), optionally drops before /s/; "tends to be dropped before /s/, especially in common words"
and-skoti     +  ˈan(t)ˌskɔːtɪ          devil fiend; fucking (adv.) [pronounced with [tʰ] and short [ɔ] in https://enska.arnastofnun.is/en/ord/3292/tungumal/EN]
hand-sama     +  ˈhan(t)ˌsaːma          to seize; to capture; to arrest
hund-skamma   +  ˈhʏn(t)ˌskam(ː)a       to scold severely, to chew out
eld-spýta     +  ˈɛl(t)ˌspiːta          match (for flame)
kvöld-skóli   +  ˈkʰvœl(t)ˌskouːlɪ      night school

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
borð-búnaður   +   ˈpɔrðˌpuːnaðʏr  tableware    -      [/u/ given as short but apparently a typo; compare treggáfaður below with long á]
bragð-betri    +   ˈpraɣðˌpɛːtrɪ   tastier, more delicious
harð-brjósta   +   ˈharðˌprjousta  heartless, callous
orð-tak        +   ˈɔrðˌtʰaːk      expression, idiom
við-tæki       +   ˈvɪðˌtʰaiːcɪ    radio set; extensive, far-reaching (nom. masc. sg. weak)
verð-myndun    +   ˈvɛrðˌmɪntʏn    price determination
verð-skulda    +   ˈvɛrðˌskʏlta    to deserve, to merit

## Names with /ð/ at the end of a compound, which conventionally drops or assimilates
Bárð-dælir     +   ˈpaurðˌtaiːlɪr   [placename]
Bár-dælir      Bárðdælir   ˈpaurˌtaiːlɪr    [placename]     -       local pronunciation
Norð-fjörður   +   ˈnɔrðˌfjœrðʏr    [placename]
Nor-fjörður   Norðfjörður   ˈnɔr̥ˌfjœrðʏr     [placename]     -       local pronunciation
Norð-lendingur  +  ˈnɔrðˌlɛntiŋkʏr  [placename]
Nor-lendingur  Norðlendingur  ˈnɔrˌlɛntiŋkʏr   [placename]     -       local pronunciation
Norð-lingar    +   ˈnɔrðˌliŋkar     [placename]
Nor-lingar    Norðlingar   ˈnɔrˌliŋkar      [placename]     -       local pronunciation
Breið-dalur    +   ˈpreiðˌtaːlʏr    [placename]
Brei[t]-dalur    Breiðdalur   ˈpreitˌtalʏr     [placename]     -       local pronunciation [it appears vowels are short directly after a geminate]
Skrið-dalur    +   ˈskrɪðˌtaːlʏr    [placename]
Skri[t]-dalur    Skriðdalur   ˈskrɪtˌtalʏr     [placename]     -       local pronunciation

## First part ending in /f/, which becomes [v] before a vowel, voiced sound, unaspirated stop or /h/ + vowel
of-ætlun     +    ˈɔːvˌaihtlʏn       insurmountable task
af-dalur     +    ˈavˌtaːlʏr         side valley; isolated valley
raf-geymir   +    ˈravˌceiːmɪr       accumulator, storage battery
haf-gola     +    ˈhavˌkɔːla         sea breeze
af-hausa     +    ˈaːvˌhœiːsa        to behead
a-fausa     afhausa    ˈaːˌfœiːsa    to behead      -       with assimilation
líf-láta     +      ˈlivˌlauːta      to put to death, to execute; execution, murder (gen pl indef)
raf-neisti   +      ˈravˌneistɪ      electric spark
raf-reiknir  +      ˈravˌreihknɪr    (historical) computer

## First part ending in /f/, which becomes [f] before &lt;s> and in older pronunciation before other voiceless fricatives and approximants and aspirated stops
af-hjúpa      +    ˈavˌçuːpa[modern],ˈafˌçuːpa[older]          to unveil; to reveal
af-hrak       +    ˈavˌr̥aːk[modern],ˈafˌr̥aːk[older]            outcast, pariah
af-kimi       +    ˈavˌcʰɪːmɪ[modern],ˈafˌcʰɪːmɪ[older]        nook, corner
af-koma       +    ˈavˌkʰɔːma[modern],ˈafˌkʰɔːma[older]        profits, financial situation
af-taka       +    ˈavˌtʰaːka[modern],ˈafˌtʰaːka[older]        to refuse; execution (killing)
raf-tækni     +    ˈravˌtʰaihknɪ[modern],ˈrafˌtʰaihknɪ[older]  electronics
Rif-tún       +    ˈrɪvˌtʰuːn[modern],ˈrɪfˌtʰuːn[older]        [placename, a farm in the municipality of Ölfus in South Iceland]
af-skekktur   +    ˈafˌscɛxtʏr                                 remote, isolated, secluded
af-staða      +    ˈafˌstaːða                                  position, attitude, stance; location
of-hleðsla    +    ˈɔvˌl̥ɛðstla[modern],ˈɔfˌl̥ɛðstla[older]      overload
of-hvörf      +    ˈɔvˌkʰvœrv[modern],ˈɔfˌkʰvœrv[older]        hyperbole; (linguistics) semantic bleaching
of-sjónir     +    ˈɔfˌsjouːnɪr                                hallucinations

## First part ending in /f/, which formerly could become [p] before /l/ or /n/ across a compound boundary (as is normal when not across a boundary); now rare
Hab-liði      Hafliði    ˈhapˌlɪːðɪ                    [placename]                      -          dialectal
líb-legur     líflegur   ˈlipˌlɛːɣʏr                   lively, spirited                 -          dialectal
Stab-nes      Stafnes    ˈstapˌnɛːs                    [placename]                      -          dialectal

## First part ending in /f/, which tends to form a geminate before <f> or <v> (but aff- can sometimes be [avf-]); directly after a geminate, it seems the next vowel must be short
af-fall       +          ˈafˌfatl̥                      outflow; wastewater
af-ferma      +          ˈafˌfɛrma                     to unload
of-veiði      +          ˈɔvˌveiðɪ                     overfishing; overhunting
of-viti       +          ˈɔvˌvɪtɪ                      genius, prodigy; idiot savant

## First part ending in /f/, before /m/; assimilates informally in common words
af-má         +          ˈavˌmauː[formal],ˈamˌmau[informal]                      to wipe, to erase
af-mynda      +          ˈavˌmɪnta[formal],ˈamˌmɪnta[informal]                     to distort, to deform
af-mæli       +          ˈavˌmaiːlɪ[formal],ˈamˌmailɪ[informal]                    birthday, anniversary
a-mæli        afmæli     ˈaːˌmaiːlɪ                    birthday, anniversary           -          alternative pronunciation

## First part ending in /f/, before a labial; it becomes [v] or (in everyday speech, but not formal speech) assimilates to the labial
raf-magn       +   ˈravˌmakn̥[formal],ˈramˌmakn̥[informal]      electricity
af-bera        +   ˈavˌpɛːra[formal],ˈapˌpɛra[informal]       to tolerate, to bear
af-bragð       +   ˈavˌpraɣð[formal],ˈapˌpraɣð[informal]       excellent thing/person
of-boðs-legur  +   ˈɔvˌpɔðsˌlɛːɣʏr[formal],ˈɔpˌpɔðsˌlɛːɣʏr[informal]         tremendous, enormous; terrible, awful
o-boðs-legur  ofboðslegur   ˈɔːˌpɔðsˌlɛːɣʏr           tremendous, enormous; terrible, awful      -         alternative informal form

## First part ending in soft /g/, which becomes [ɣ] before a vowel, voiced sound, unaspirated stop or /h/ + vowel
## Commonly in fast speech, especially in common words, the [ɣ] is dropped before a consonant and the preceding vowel lengthened; not acceptable in formal speech.
aug-ljós       +   ˈœiɣˌljouːs     obvious, apparent
dag-blað       +   ˈtaɣˌplaːð      newspaper
dag-legur      +   ˈtaɣˌlɛːɣʏr     daily, everyday
dag-mamma      +   ˈtaɣˌmam(ː)a    childminder, daycare provider, childcare provider
fag-maður      +   ˈfaɣˌmaːðʏr     professional, expert
hag-ræða       +   ˈhaɣˌraiːða     get comfortable; adjust, sort out; economize; adapt, modify
lag-hentur     +   ˈlaːɣˌhɛn̥tʏr     handy, dexterous
leg-bólga      +   ˈlɛɣˌpoulka     uterine inflammation
nag-dýr        +   ˈnaɣˌtiːr       rodent
sog-æðar       +   ˈsɔːɣˌaiːðar     lymphatic vessels
treg-gáfaður   +   ˈtʰrɛɣˌkauː(v)aðʏr   slow-witted, dim

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
lág-nætti      +   ˈlauɣˌnaihtɪ,ˈlauːˌnaihtɪ        midnight (dated)
skóg-lendi     +   ˈskouɣˌlɛntɪ,ˈskouːˌlɛntɪ        woodland, wooded area
drjúg-virkur   +   ˈtrjuɣˌvɪr̥kʏr,ˈtrjuːˌvɪr̥kʏr       efficient, highly effective

## First part ending in /k/: pre-aspirated in some common compound words
ein-stakk-lingur   einstaklingur  ˈeinˌstahkˌliŋkʏr    individual, person
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
vinnsla         +   ˈvɪnstla        processing (noun)

## <n-b> across a compound boundary informally becomes /mp/, <n-k> informally becomes /ŋkʰ/; in colloquial speech the <n> may drop but this is frowned on in formal speech
eim-búi         einbúi       ˈeimˌpuːɪ           loner, hermit, recluse                    -              informal
eim-býlis-hús   einbýlishús  ˈeimˌpiːlɪsˌhuːs       detached house, single-family home        -              informal   
imm-bú          innbú        ˈɪmˌpuː             household goods                           -              informal
ɪmm-bær         Innbær       ˈɪmˌpaiːr           inner city                                -              informal
innan-sleikjur  +            ˈɪn(ː)anˌstleiːcʏr     trifles
undam-brögð     undanbrögð   ˈʏntamˌprœɣð        excuses, pretexts                         -              informal
undaŋ-koma      undankoma    ˈʏntaŋˌkʰɔːma       escape, way out                           -              informal

## &lt;p> across a compound boundary disappears before <b>, &lt;p>
kaup-bætir      +           ˈkʰœiːˌpaiːtɪr       added bonus, something coming along "in the bargain"
kaup-binding    +           ˈkʰœiːˌpɪntiŋk       wage freeze
lop-band        +           ˈlɔːˌpant            band or ribbon of coarse wool yarn        -               book says [lɔpːand], probably a mistake
upp-bót         +           ˈʏhˌpouːt            supplement; compensation                  -               book says [ʏhbout], probably a mistake

## &lt;p> across a compound boundary especially in kaup- and upp- informally assimilates to a geminate /fː/ before <f>, with shortening of preceding and following vowels if long; not in formal speech
kaup-fé-lag      +           ˈkʰœiːpˌfjɛːˌlaːɣ[formal],ˈkʰœifˌfjɛˌlaːɣ[informal]   (merchant) cooperative
kau-fé-lag       kaupfélag   ˈkʰœiːˌfjɛːˌlaːɣ                           (merchant) cooperative        -     alternative informal pronunciation
kaup-far         +           ˈkʰœiːpˌfaːr[formal],ˈkʰœifˌfar[informal]           merchant ship; trader
kau-far          kaupfar     ˈkʰœiːˌfaːr                               merchant ship; trader         -     alternative informal pronunciation
upp‿fyrir        +           ˈʏhpˌfɪːrɪr[formal],ˈʏfˌfɪrɪr[informal]             above
upp-fræða        +           ˈʏhpˌfraiːða[formal],ˈʏfˌfraiːða[informal]           educate; inform

## &lt;p> across a compound boundary sometimes becomes /f/ before &lt;s> and <t> (with shortening of a preceding vowel if long), across a compound boundary
kaup-sýsla       +           ˈkʰœiːpˌsistla[formal],ˈkʰœifˌsistla[informal]      trade, commerce
kaup-tíð         +           ˈkʰœiːpˌtʰiːð[formal],ˈkʰœifˌtʰiːð[informal]        trading season (historical)
kaup-trygging    +           ˈkʰœiːpˌtʰrɪc(ː)iŋk[formal],ˈkʰœifˌtʰrɪc(ː)iŋk[informal]  guaranteed minimum wage

## &lt;p> across a compound boundary may be aspirated before /m/
kaup-maður       +           ˈkʰœiːpˌmaːðʏr,ˈkʰœihpˌmaːðʏr               merchant, trader
kaup-mennska     +           ˈkʰœiːpˌmɛnska,ˈkʰœihpˌmɛnska               commerce, business
Kaup-manna-höfn  +           ˈkʰœiːpˌman(ː)aˌhœpn̥,ˈkʰœihpˌman(ː)aˌhœpn̥           Copenhagen

## First part of compound ending in <r>, which becomes devoiced before a voiceless fricative or approximant or aspirated stop (other than /h/ + vowel)
## 1. Before &lt;p>, <t>, <k>, &lt;s>:
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

## &lt;s> at the end of the first part of a compound is maintained unless the second part begins with an &lt;s>
ríkis-sjóður     +               ˈriːcɪˌsjouːðʏr    national treasury, public purse
heims-sýn        +               ˈheimˌsiːn         worldview; panorama
lands-sam-band   +               ˈlan(t)ˌsamˌpant   national association
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

## with assimilation involving &lt;s>
pres[:]-ekkja     prestsekkja     ˈpʰrɛsːˌɛhca       priest's widow                                 -                the notation [:] forces a geminate
pre[s]-setur      prestssetur     ˈpʰrɛsˌsɛtʏr       vicarage, parsonage                            -                the notation [s] forces an /s/ even where it would be otherwise dropped; NOTE: immediately before and after a geminate, long vowels are shortened
Vas[:]-dalur     Vatnsdalur      ˈvasːˌtaːlʏr       [placename; Lake Valley, northwest Iceland]
Mýva-sveit       Mývatnssveit    ˈmiːvaˌsveiːt      [placename; (Lake) Mývatn Region, northeast Iceland]

## <t>; in some words at the end of the first component of a compound before <l> or <t> at the beginning of the second component, there is pre-aspiration, as if a non-compound word
á-gætt-lega      ágætlega        ˈauːˌcaihtˌlɛːɣa  well, fine                                     -                 alternative pronunciation
mótt-taka        móttaka         ˈmouhˌtʰaːka      reception (event, function); reception desk; (in the pl.) reception, welcome        -     alternative pronunciation
rótt-tækur       róttækur        ˈrouhˌtʰaiːkʏr    radical, extreme                               -                 alternative pronunciation
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
rit-dómur        +               ˈrɪːˌtouːmʏr      review, critique                               -                 pronounced as [ˈrɪːtᵊˌtouːmʏr] with double articulation (two releases) in https://enska.arnastofnun.is/en/ord/33391/tungumal/EN, although the book proscribes this; note that the website's pronunciation of <þátttaka> does not have double articulation or gemination
þátt-taka        +               ˈθauhˌtʰaːka      participation
eitt-hvað        +               ˈeihtˌkʰvaːð      something
sitt-hvað        +               ˈsɪhtˌkʰvaːð      a few, some
eihkvað          eitthvað        ˈeihkvað          something                                      -                 informal
sihkvað          sitthvað        ˈsɪhkvað          a few, some                                    -                 informal

## misc compounds
geim-steinn        +             ˈceimˌsteitn̥       meteoroid
loft-steinn        +             ˈlɔftˌsteitn̥       meteorite
gvuð-spjall        guðspjall     ˈkvʏðˌspjatl̥       gospel
ski[f]-stjóri      skipstjóri    ˈscɪfˌstjouːrɪ     captain                                        -                 [not with /f/ in https://enska.arnastofnun.is/en/ord/36534/tungumal/EN]
Mel-rakka-slétta   +             ˈmɛlˌrahkaˌstljɛhta  [placename, peninsula in northeast Iceland]  
Raufar-höfn        +             ˈrœiːvarˌhœpn̥       [village in Melrakkaslétta peninsula]
Heim-skauts-gerði  +             ˈheimˌskœitsˌcɛrðɪ   [Arctic Henge, a modern mystical monument near the village of Raufarhöfn]
Hraun-hafnar-tanga-viti    +     ˈr̥œiːnˌhapnar̥ˌtʰauŋkaˌvɪːtɪ    [Hraunhafnartanga Lighthouse, the northernmost lighthouse in Iceland]
Hraun-hafnar-tanga-viti    +     ˈr̥œiːnˌhapnar̥ˌtʰauŋkaˌvɪːtʰɪ    [Hraunhafnartanga Lighthouse, the northernmost lighthouse in Iceland]        northeast
Eyja-fjalla-jökull         +     ˈeijaˌfjatlaˌjœːkʏtl̥    [well-known volcano in southern Iceland]
jökul-hlaup        +             ˈjœːkʏl̥ˌl̥œip        [type of glacial outburst flood]
Brenni-steins-alda         +     ˈprɛn(ː)ɪˌsteinsˌalta    [volcano in southern Iceland]
Fljóts-dals-hérað          +     ˈfljoutsˌtalsˌçɛːrað     [former municipality in eastern Iceland]
Akur-eyri          +             ˈaːkʏrˌeiːrɪ          [large town in northern Iceland]
Akur-eyri          +             ˈaːkʰʏrˌeiːrɪ          [large town in northern Iceland]           north
of-fitu-vanda-mál  +             ˈɔfˌfɪtʏˌvantaˌmauːl    (in the plural) problem of obesity
fjár-afla-maður    +             ˈfjauːrˌaplaˌmaːðʏr      tycoon, magnate
fjár-bú-skapur     +             ˈfjaurˌpuːˌskaːpʏr       sheep raising                 -                          [in https://enska.arnastofnun.is/en/ord/62651/tungumal/EN, however, fjár- is long]
sauð-fjár-bú-skapur      +       ˈsœiðˌfjaurˌpuːˌskaːpʏr    sheep farming, sheep husbandry
sauð-fjár-veiki-varnir   +       ˈsœiðˌfjaurˌveiːcɪˌvartnɪr   measures to prevent the spread of sheep disease       [in https://enska.arnastofnun.is/en/ord/64828/tungumal/EN, sauð- and veiki- appear long]
sauma-vélar-nál    +             ˈsœiːmaˌvjɛːlarˌnauːl     sewing machine needle
fé-lags-mála-ráðu-neyti    +     ˈfjɛːˌlaksˌmauːlaˌrauːðʏˌneiːtɪ         ministry of social affairs
deildar-hjúkrunar-fræðingur  +   ˈteiltar̥ˌçuːkrʏnar̥ˌfraiːðiŋkʏr         head nurse (lit. "ward registered nurse", more lit. "ward nursing expert")
]==]

return export
