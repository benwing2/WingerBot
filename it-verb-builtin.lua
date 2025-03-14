local export = {}

--[=[

Authorship: Ben Wing <benwing2>

]=]

-- This contains "built-in" verbs, i.e. verbs (mostly irregular) whose conjugation is built into the module.
-- We try to provide coverage of all -ere verbs, as well as all irregular -are and -ire verbs (where "irregular"
-- for -ire verbs does not include those whose only irregularity is a present participle ending in -iente), and
-- all syncopated verbs (those in -rre).
--
-- Individual entries in this table are of the form {KEY, VALUE, ENGLISH_DESC}, as follows:
-- 1. KEY is one of the following:
--    a. A string, the infinitive of the verb in question. If the string is preceded by ^, the user-specified verb
--       must exactly match this string; otherwise, it can contain an extra prefix, which is appended onto all
--       generated forms. For example, "andare" will also match "riandare", "trasandare", etc., and "idere" will
--       match "incidere", "elidere", "dividere", etc.; but "^vergere" will only match "vergere", not "convergere"  or
--       "divergere".
--    b. An object of the form {term = "TERM", prefixes = {"PREFIX", "PREFIX", ...}}. In this case, `term` specifies
--       the infinitive to match, and `prefixes` specifies the allowed prefixes that can be prepended onto the
--       infinitive in order for this entry to be considered a match. If a prefix is preceded by ^, it must match
--       exactly; otherwise, longer prefixes ending in the specified string can match. For example, the spec
--      {term = "vedere", prefixes = {"prov", "pro"}} will match "provvedere", "provedere", and prefixed derivatives of
--      these verbs such as "riprovvedere"; but not "rivedere", "prevedere", "vedere" by itself, etc. Similarly, the
--      spec {term = "bere", prefixes = {"^", "ri", "tra"}} will match "bere" by itself (because of the "^"), as well as
--      "ribere", "trabere", "strabere" (because of "tra"), etc.; but not "iubere" or "ebere".
-- 2. VALUE is a string, which is of the same format as is normally used in {{it-conj}} and {{it-verb}} (inside of
--    angle brackets), except that the auxiliary indicator and following slash or backslash is omitted and must be
--    supplied by the user. If the  verb is root-stressed with irregular present indicative principal part and would
--    normally use a spec like (for [[scegliere]]) "a\é\scélgo,scélsi,scélto", the second backslash and preceding
--    single-vowel spec is still included, i.e. the value would look like "é\scélgo,scélsi,scélto". In this case, if
--    the user specifies a slash instead of a backslash, an error is thrown.
-- 3. ENGLISH_DESC is an English-language description of the verbs handled by this entry, such as
--    "<<dare>> and derivatives (<<addare>>, <<ridare>>, <<sdarsi>>); but not <<andare>> or derivatives". This is used
--    in generating the documentation describing the built-in verbs handled by the module. Double angle bracket specs
--    such as <<dare>> are converted into links, and are equivalent to e.g. {{m|it|dare}}. Template references in the
--    description will be expanded.
--
-- The order of the entries matters, as the entries are processed sequentially. The general ordering used is -are, then
-- -ere, then -ire, then syncopated verbs. Within a group, verbs are approximated sorted using right-to-left sorting,
-- so that e.g. all the -cere verbs follow the -bere verbs and precede the -dere verbs; and within the -dere verbs,
-- the -ndere verbs are grouped together following the -idere verbs and preceding the -odere verbs; etc. Exceptions may
-- be made to ensure the right precedence, e.g. "andare" precedes "dare".
export.builtin_verbs = {
	---------------------------------------------- -are verbs --------------------------------------------
	-- must precede dare; va vs. rivà handled automatically
	{"andare", [=[
		-.
		presrow:vàdo,vài,và*,andiàmo,andàte,vànno.
		fut:andrò.
		sub:vàda.
		imp:vài:và'
]=], "<<andare>> and derivatives (<<riandare>>, <<trasandare>>/<<transandare>>)"},
	-- NOTE: specifying détti autogenerates #dètti
	{"dare", [=[
		-,dièdi:diédi:détti.
		phisstem:dé.
		presrow:dò*,dài,dà*!,diàmo,dàte,dànno.
		fut:darò.
		sub:dìa.
		impsub:déssi.
		imp:dài:dà'
]=], "<<dare>> and derivatives (<<addare>>, <<ridare>>, <<sdarsi>>); but not <<andare>> or derivatives"},
	-- NOTE: specifying stétti autogenerates #stètti
	{"stare", [=[
		-,stétti.
		phisstem:sté.
		presrow:stò*,stài,stà*,stiàmo,stàte,stànno.
		fut:starò.
		sub:stìa.
		impsub:stéssi.
		imp:stài:stà'
]=], "<<stare>> and derivatives (<<ristare>>, <<soprastare>>, <<sottostare>>); not <<sovrastare>>"},

	---------------------------------------------- -ere verbs --------------------------------------------
	{"soccombere", "ó+,+,+", "<<soccombere>>"},
	{"combere", "ó,+,-", "<<incombere>>, <<procombere>>"},
	-- iubere: archaic, defective
	-- giacere, piacere, tacere; Hoepli says piacciàmo only, taciàmo only and either giaccìamo or giaciàmo;
	-- but Treccani says all should be in -acciàmo. DOP says piaciàmo and taciàmo are errors and giaciàmo is
	-- "meno bene".
	{"acere", "àccio^à,àcqui.pres1p:acciàmo",
		"<<giacere>>, <<tacere>>, <<piacere>> and derivatives"},
	-- licere (lecere), recere: archaic or poetic, defective
	-- dicere, benedicere: archaic; handled under dire below
	-- soffolcere (suffolcere, soffolgere, suffulcere): archaic, defective
	-- molcere: poetic, defective
	{"vincere", "ì,vìnsi,vìnto", "<<vincere>> and derivatives"},
	{"cuocere", "ò\\cuòcio^ò,còssi,còtto.unstressed_stem:cuoce:coce[now rare]", "<<cuocere>> and derivatives"},
	{"nuocere", "ò\\nòccio:nuòccio^ò,nòcqui,nociùto:nuociùto[rare].unstressed_stem:nuoce:noce[now rare].presp:nocènte",
		"<<nuocere>>, <<rinuocere>>"},
	{"torcere", "ò,tòrsi,tòrto", "<<torcere>> and derivatives"},
	{"nascere", "à,nàcqui,nàto", "<<nascere>>, <<rinascere>>, <<prenascere>>"},
	{"pascere", "à", "<<pascere>>, <<ripascere>>"},
	-- acquiescere: rare, defective in past participle
	{"mescere", "é:è", "<<mescere>>, <<rimescere>>"},
	{"crescere", "é,crébbi", "<<crescere>> and derivatives"},
	-- mansuescere: archaic, rare, infinitive only
	{"noscere", "ó,nóbbi", "<<conoscere>>, archaic <<cognoscere>> and derivatives"},
	-- ducere and derivatives: archaic; handled under -durre below
	-- [[lucere]] itself is poetic and lacking the past historic
	{{term = "lucere", prefixes = {"tra", "ri"}}, "ù,+,-", "<<rilucere>>, <<tralucere>>"},
	-- 'cadere' must precede 'adere'
	{"cadere", "à,càddi.fut:cadrò", "<<cadere>> and derivatives"},
	-- NOTE: (1) per DiPI, [[suadere]] can be pronounced suadére (per Treccani/Hoepli) or suàdere.
	-- (2) [[ridere]] has past historic [[rasi]], with /z/ or traditional /s/, whereas the past historic of the
	-- other verbs has only /z/; but this currently makes no difference as we don't indicate all details of verb
	-- pronunciation. If we change this and start indicating full pronunciation (e.g. as [[Module:fr-verb]] does),
	-- we need to split these verbs.
	{"adere", "à,àsi,àso", "<<radere>> and derivatives; <<suadere>> and derivatives; verbs in ''-vadere'' (<<invadere>>, <<evadere>>, <<pervadere>>); but not <<cadere>> and derivatives"},
	-- reddere: archaic for rendere
	{"succedere", "è,succèssi:+,succèsso:+", "<<succedere> (needs overrides to handle different past historic and past participle in different meanings)"},
	{"concedere", "è,concèssi:+,concèsso", "<<concedere>> and derivatives"},
	-- Hoepli says [[retrocedere]] is conjugated like [[cedere]], but in fact ''retrocesso'' is much more common than ''retroceduto''
	-- (Hoepli even gives two examples using ''retrocesso''), while ''retrocessero'' and ''retrocedettero'' are equally common.
	-- Treccani correctly says "(pass. rem. io retrocèssi [anche retrocedéi o retrocedètti], tu retrocedésti, ecc.; part. pass. retrocèsso)".
	{"retrocedere", "è,retrocèssi:+,retrocèsso", "<<retrocedere>>"},
	-- cedere: cèssi is archaic
	{"cedere", "è", "<<cedere>> and derivatives; but not <<succedere>>, <<concedere>>, <<retrocedere>> or derivatives"},
	{"chiedere", "è:é,chièsi:chiési,chièsto:chiésto", "<<chiedere>> and derivatives"},
	-- riedere: variant of poetic/archaic defective redire (reddire)
	{"siedere", "è:é", "verbs in ''-siedere'' (<<presiedere>>, <<risiedere>>)"},
	{"ledere", "è,lési,léso", "<<ledere>>"},
	-- credere: crési is archaic
	{"credere", "é", "<<credere>> and derivatives (<<discredere>>, <<miscredere>>, <<ricredere>>, <<scredere>>)"},
	-- pedere: obsolete, regular but lacking past participle
	-- Treccani and Hoepli say [[possedere]] and [[sedere]] are conjugated the same; Hoepli says "''sièdo'' o ''sèggo''"
	-- and Treccani says ''sèggo'' is literary. But a corpus study by Anna M. Thornton, "Overabundance: Multiple Forms Realizing the Same Cell"
	-- in ''Morphological Autonomy'', p. 366
	-- [https://www.google.com/books/edition/Morphological_Autonomy/oh3UlV6xSQEC?hl=en&gbpv=1&dq=%22posseggo%22&pg=PA363&printsec=frontcover]
	-- shows that ''seggo'' is rare but ''posseggo'' is not (''possiedo'' 140 to ''posseggo'' 95; ''possiedono'' 1236 to ''posseggono'' 755;
	-- ''possieda'' 174 to ''possegga'' 132; ''possiedano'' 46 to ''posseggano'' 65).
	{"possedere", "possièdo:possiédo:possèggo:posséggo^possiède:possiéde.fut:possiederò[now more common, especially in speech]:+", "<<possedere>> and derivatives"},
	{"sedere", "sièdo:siédo.fut:siederò[now more common, especially in speech]:+", "<<sedere>> and derivatives; but not <<possedere>> or derivatives"},
	-- divedere: defective
	{{term = "vedere", prefixes = {"pre"}}, "é,vìdi,vìsto:vedùto[less popular].fut:vedrò:vederò.presp:+:veggènte", "<<prevedere>>"},
	{{term = "vedere", prefixes = {"prov", "pro"}}, "é,vìdi,vedùto:vìsto[rare in a verbal sense].presp:+:veggènte", "<<provvedere>> (archaic <<provedere>>) and derivatives"},
	-- the following per Dizionario d'ortografia e di pronunzia
	{{term = "vedere", prefixes = {"^rav"}}, "é,vìdi,vedùto.fut:vedrò:vederò.presp:+:veggènte", "<<ravvedere>>"},
	{{term = "vedere", prefixes = {"^tra", "tras", "trans", "stra", "anti"}}, "é,vìdi,vedùto.fut:vedrò.presp:+:veggènte", "<<travedere>> and variants, <<stravedere>>, <<antivedere>>"},
	{"vedere", "é,vìdi,vìsto:vedùto[less popular].fut:vedrò.presp:+:veggènte", "<<vedere>> and some derivatives (e.g. <<avvedere>>, <<intravedere>>, <<rivedere>>); may need overrides, e.g. <<rivedere>> in the meaning \"to revise\" has only <<riveduto>> as past participle"},
	-- stridere: past participle is lacking (per Hoepli), not used (per DOP) or extremely rare (per Treccani)
	{"stridere", "ì,+,-", "<<stridere>>"},
	-- NOTE: [[ridere]] has past historic [[risi]], with /z/ or traditional /s/, whereas the past historic of the
	-- other verbs has only /z/; see comment above about 'adere'.
	{"idere", "ì,ìsi,ìso", "verbs in ''-cidere'' (<<incidere>>, <<coincidere>>, <<uccidere>>, <<decidere>>, etc.; verbs in ''-lidere'' (<<elidere>>, <<collidere>>, <<allidere>>); <<ridere>> and derivatives; <<assidere>>; <<dividere>> and derivatives; but not <<stridere>>"},
	-- Treccani (under [[espandere]]) says past historic only spànsi, past participle only spànso. Hoepli says past
	-- historic spandéi or (uncommon) spandètti or spànsi, past participle spànto or archaic spànso or spandùto.
	-- The reality from reverso.net is somewhere in between.
	{"spandere", "à,spànsi:+[uncommon],spànto:spànso", "<<spandere>> and derivatives"},
	-- must precede cendere
	{"scendere", "é:è,scési,scéso", "<<scendere>> and derivatives"},
	{"cendere", "è,cési,céso", "<<accendere>> and derivatives, <<incendere>>"},
	{{term = "fendere", prefixes = {"di", "de", "of"}}, "è,fési,féso", "<<difendere>> (archaic <<defendere>>), <<offendere>> and derivatives"},
	{"fendere", "è,+,+:fésso", "<<fendere>>, <<rifendere>>, <<sfendere>>; but not <<offendere>>, <<difendere>> or respective derivatives"},
	-- stridere (FIXME: some other verb intended?): past participle is rare (per Hoepli), not used (per DOP and Treccani)
	{"splendere", "è,+,-", "<<splendere>> and derivatives"},
	{"^pendere", "è,+,+[rare]", "<<pendere>>; but not any derivatives"},
	{"propendere", "è,+,propéso[rare]", "<<propendere>>"},
	{"pendere", "è,pési,péso", "<<appendere>>, <<dipendere>>, <<spendere>>, <<sospendere>> and other verbs and derivatives in ''-pendere'' other than <<pendere>> and <<propendere>>"},
	{"prendere", "è,prési,préso", "<<prendere>> and derivatives"},
	{"rendere", "è,rési,réso", "<<rendere>>, <<arrendere>> and <<rirendere>>"},
	{"tendere", "è,tési,téso", "<<tendere>>, <<stendere>> and derivatives of each"},
	{"vendere", "é", "<<vendere>> and derivatives"},
	{"scindere", "ì,scìssi,scìsso", "<<scindere>> and derivatives"},
	{"scondere", "ó,scósi,scósto", "<<nascondere>>, <<ascondere>> and derivatives of each"},
	{"fondere", "ó,fùsi,fùso", "<<fondere>> and derivatives"},
	{"spondere", "ó,spósi,spósto", "<<rispondere>> (archaic <<respondere>>) and derivatives"},
	-- Hoepli says tònso but I suspect it's a mistake; Olivetti says tónso
	{"tondere", "ó,+,+:tónso", "<<tondere>>"},
	{"tundere", "ù,tùsi,tùso", "<<contundere>> and <<ottundere>>"},
	{"godere", "ò.fut:godrò", "<<godere>> and derivatives"},
	{"plodere", "ò,plòsi,plòso", "<<esplodere>>, <<implodere>> and derivatives"},
	{"rodere", "ó,rósi,róso", "<<rodere>> and derivatives"},
	{"ardere", "à,àrsi,àrso", "<<ardere>> and derivatives"},
	{"perdere", "è,pèrsi:perdètti:perdéi[less common],pèrso:perdùto", "<<perdere>> and derivatives"},
	{"mordere", "ò,mòrsi,mòrso", "<<mordere>> and derivatives"},
	-- gaudere: literary or archaic, defective
	{"plaudere", "à,plaudìi,plaudìto", "<<plaudere>>"},
	{"prudere", "ù,+[rare],-", "<<prudere>>"},
	{"udere", "ù,ùsi,ùso", "<<chiudere>> and derivatives; verbs in ''-cludere'' (<<concludere>>, <<includere>>, <<escludere>>, etc.); verbs in ''-ludere'' (<<eludere>>, <<deludere>>, <<alludere>>, etc.); verbs in ''-trudere'' (<<intrudere>>, <<protrudere>>, <<estrudere>>, etc.); but not <<prudere>> or <<gaudere>>"},
	-- piagere, plagere: archaic, defective
	-- traggere and derivatives: archaic; handled under trarre below
	{"eggere", "è,èssi,ètto", "<<leggere>> and derivatives; <<reggere>> and derivatives; <<proteggere>> and derivatives"},
	{{term = "figgere", prefixes = {"^", "con", "ri", "scal", "tra"}}, "ì,fìssi,fìtto", "<<figgere>> and some derivatives (<<configgere>>, <<rifiggere>>, <<scalfiggere>>, <<trafiggere>> and derivatives), with past participle in ''-fitto''"},
	{"figgere", "ì,fìssi,fìsso", "most derivatives of <<figgere>> (<<affiggere>>, <<crocifiggere>> and variants, <<defiggere>>, <<infiggere>>, <<prefiggere>>, <<suffiggere>>, and derivatives), with past participle in ''-fisso''"},
	{"fliggere", "ì,flìssi,flìtto", "verbs in ''-fliggere'' (<<affliggere>>, <<confliggere>>, <<infliggere>>)"},
	{"friggere", "ì,frìssi,frìtto", "<<friggere>> and derivatives"},
	{"struggere", "ù,strùssi,strùtto", "<<struggere>> and derivatives"},
	{"redigere", "ì,redàssi,redàtto", "<<redigere>>"},
	-- indigere: archaic, defective
	-- negligere: uncommon, defective
	{"diligere", "ì+,dilèssi,dilètto", "<<diligere>> and derivatives"},
	{"rigere", "ì,rèssi,rètto", "<<erigere>>, <<dirigere>> and derivatives"},
	{"sigere", "ì,+[uncommon],sàtto", "<<esigere>> and <<transigere>>"},
	-- vigere: highly defective
	-- algere: archaic poetic, defective
	-- soffolgere: archaic, defective; variant of soffolcere, see above
	-- molgere: rare, literary, defective
	{"volgere", "ò,vòlsi,vòlto", "<<volgere>> and derivatives"},
	{"indulgere", "ù,indùlsi,indùlto", "<<indulgere>>"},
	{"fulgere", "ù,fùlsi,-", "<<fulgere>> and derivatives; lacking past participle"},
	-- angere: archaic or poetic, defective
	{{term = "angere", prefixes = {"fr", "pi", "pl"}}, "à,ànsi,ànto", "<<frangere>> and derivatives (some derivatives need special handling of the past participle); <<piangere>> (archaic <<plangere>>) and derivatives"},
	-- piagnere: archaic, defective, no past historic or past participle
	-- clangere: literary, rare, defective, no past historic or past participle
	-- tangere: literary, defective
	-- etc.
	{"spengere", "é:#è,spénsi:#spènsi,spénto:#spènto", "<<spengere>> (Tuscan variant of <<spegnere>>)"},
	{"mingere", "ì,mìnsi,-", "<<mingere>> and derivatives"},
	{"stringere", "ì,strìnsi,strétto", "<<stringere>> and derivatives"},
	{"ingere", "ì,ìnsi,ìnto", "<<cingere>> and derivatives; <<fingere>> and derivatives; <<pingere>> and derivatives; <<spingere>> and derivatives; <<tingere>> and derivatives; but not <<mingere>> (lacking the past participle), and not <<stringere>> and derivatives (with past participle <<stretto>> etc.)"},
	{"fungere", "ù,fùnsi,fùnto[rare]", "<<fungere>> and derivatives"},
	{"ungere", "ù,ùnsi,ùnto", "<<ungere>>; <<giungere>> and derivatives; <<mungere>> and derivatives; <<pungere>> and derivatives; but not <<fungere>> and derivatives (past participle is formed the same way but rare)"},
	-- arrogere: archaic, defective
	{"spargere", "à,spàrsi,spàrso", "<<spargere>> and derivatives"},
	{{term = "ergere", prefixes = {"^", "ad", "ri"}}, "è,èrsi,èrto:#érto", "<<ergere>>, <<adergere>>, <<riergere>>; but not any other verbs in ''-ergere''"},
	{{term = "ergere", prefixes = {"m", "sp", "t"}}, "è,èrsi,èrso", "<<mergere>> and derivatives; <<spergere>> and derivatives; <<tergere>> and derivatives"},
	-- vergere: literary, rare, defective in the past participle
	{"convergere", "è,convèrsi,-", "<<convergere>>"},
	{"divergere", "è,-,-", "<<divergere>>"},
	{{term = "orgere", prefixes = {"c", "p"}}, "ò:ó,òrsi:órsi,òrto:órto", "<<accorgersi>> and derivatives; <<scorgere>>; <<porgere>> and derivatives"},
	{"sorgere", "ó:ò,sórsi:sòrsi,sórto:sòrto", "<<sorgere>>"},
	{"surgere", "ù,sùrsi,sùrto", "<<surgere>> and derivatives"},
	{"urgere", "ù,-,-", "<<urgere>>"},
	-- turgere: poetic, defective
	{"scegliere", "é\\scélgo,scélsi,scélto", "<<scegliere>> and derivatives"},
	-- svegliere: archaic form of svellere, defective
	{{term = "ogliere", prefixes = {"c", "sci", "t"}}, "ò\\òlgo,òlsi,òlto", "<<cogliere>> and derivatives; <<sciogliere>> and derivatives; <<togliere>> and derivatives"},
	{"adempiere", "é,adempiéi.pres2p:adempìte", "<<adempiere>>; see also <<adempire>> of the same meaning"},
	-- Can't use é for present spec because stem:émpi specified; we'd get present #émpo
	{"empiere", "é\\émpio,empìi:empiéi[less common],empiùto.stem:émpi", "<<empiere>>, <<riempiere>>; but not <<adempiere>>, which borrows fewer forms from <<adempire>>; see also <<empire>>, <<riempire>> of the same meaning"},
	{"compiere", [=[
	ó:ò,compiéi:compìi[more common].pres2p:compiéte:compìte[more common].
	imperf:compiévo:compìvo[more common].
	impsub:compiéssi:compìssi[more common].
	fut:compierò:compirò[more common]
]=], "<<compiere>>, <<ricompiere>>; see also <<compire>>, <<ricompire>>"},
	-- calere: rare/literary, defective
	{"valere", "vàlgo^à,vàlsi,vàlso.fut:varrò", "<<valere>> and derivatives"},
	{"eccellere", "è+,eccèlsi,-", "<<eccellere>>"},
	{"pellere", "è,pùlsi,pùlso", "verbs in ''-pellere'' (<<espellere>>, <<impellere>>, <<propellere>>, <<repellere>>, etc."},
	{"avellere", "è,vùlsi,vùlso", "<<avellere>>"},
	-- per Canepari, svèlto or svélto but just divèlto
	{"svellere", "è\\è:svèlgo,svèlsi,svèlto:svélto", "<<svellere>>, <<disvellere>>"},
	{"divellere", "è\\è:divèlgo,divèlsi,divèlto", "<<divellere>>"},
	-- vellere, evellere, convellere: literary or archaic, defective
	-- tollere: archaic, unclear conjugation
	-- attollere, estollere: literary, defective
	-- colere: archaic, defective
	{"dolere", "dòlgo^duòle,dòlsi,+.fut:dorrò", "<<dolere>> and derivatives"},
	{"solere", "sòglio^suòle,soléi[rare],sòlito.pres1p:sogliàmo.fut:-.imp:-.presp:-", "<<solere>>"},
	{"volere", [=[
		-,vòlli.
		presrow:vòglio,vuòi,vuòle,vogliàmo,voléte,vògliono.
		fut:vorrò.
		improw:vògli,vogliàte
]=], "<<volere>> and derivatives"},
	{"gemere", "è", "<<gemere>> and derivatives"},
	{"fremere", "è", "<<fremere>>"},
	-- premere, spremere: regular; past historic prèssi and past participle prèsso archaic
	{"premere", "è", "<<premere>>, <<spremere>> and derivatives"},
	{"temere", "è:#é", "<<temere>> and derivatives"},
	{"redimere", "ì,redènsi,redènto", "<<redimere>>"},
	{"perplimere", "ì,+,perplèsso:perplimùto[rare]", "<<perplimere>>"},
	{"dirimere", "ì+,+[rare],-", "<<dirimere>>"},
	{"primere", "ì,prèssi,prèsso", "verbs in ''-primere'' (<<comprimere>>, <<deprimere>>, <<esprimere>>, <<imprimere>>, etc."},
	{"esimere", "ì,+,-", "<<esimere>>"},
	-- presummere: obsolete, unclear conjugation
	-- promere: archaic, defective
	{"sumere", "ù,sùnsi,sùnto", "verbs in ''-sumere'' (<<assumere>>, <<consumere>>, <<presumere>>, <<resumere>>, etc.)"},
	{"rimanere", "rimàngo^à,rimàsi,rimàsto.fut:rimarrò", "<<rimanere>>"},
	{"permanere", "permàngo^à,permàsi,-.fut:permarrò", "<<permanere>>"},
	{"tenere", "tèngo^tiène:tiéne,ténni:tènni.fut:terrò", "<<tenere>> and derivatives"},
	{"spegnere", "é:#è\\spéngo:#spèngo,spénsi:#spènsi,spénto:#spènto", "<<spegnere>> and derivatives"},
	-- accignere, scignere, pignere and derivatives, strignere and derivatives, ugnere: all obsolete, unclear conjugation
	-- Past participle cernìto; lacking in derivatives or rare -crèto. Both cerné and cernétte/cernètte
	-- are very rare, with the former actually occuring more often (same in derivatives).
	{{term = "cernere", prefixes = {"^", "ri"}}, "è,-,cernìto", "<<cernere>> and derivatives"},
	{{term = "cernere", prefixes = {"con", "dis"}}, "è,-,-", "<<concernere>>, <<discernere>> and derivatives"},
	{"secernere", "è+,+,secrèto", "<<secernere>>"},
	-- Hoepli specifically says that [[sapere]] lacks a present participle, hence [[sapiente]] isn't it
	{"sapere", [=[
		-,sèppi.
		presrow:sò*,sài,sà*,sappiàmo,sapéte,sànno.
		fut:saprò.
		sub:sàppia.
		improw:sàppi,sappiàte.
		presp:-
]=], "<<sapere>> and derivatives"},
	{"rompere", "ó,rùppi,rótto", "<<rompere>> and derivatives"},
	-- scerpere: archaic/obsolete, unclear conjugation
	{"serpere", "è,-,-", "<<serpere>>"},
	{"^parere", "pàio^à,pàrvi,pàrso.pres1p:paiàmo.fut:parrò.imp:-.presp:parvènte", "<<parere>>"},
	-- sparere, trasparere: archaic/obsolete, unclear conjugation
	-- sofferere: archaic/obsolete, unclear conjugation
	-- cherere, chierere: archaic/obsolete, unclear conjugation
	{"correre", "ó,córsi,córso", "<<correre>> and derivatives"},
	-- comburere: literary, defective
	-- furere: archaic rare, unclear conjugation
	{{term = "essere", prefixes = {"^", "ri"}}, [=[
		è\-,-,stàto.
		presrow:sóno,sèi,è!,siàmo,siéte:#siète,sóno.
		imperfrow:èro,èri,èra,eravàmo,eravàte,èrano.
		phisrow:fùi,fósti,fù*,fùmmo,fóste,fùrono.
		fut:sarò.
		sub:sìa.
		impsub:fóssi.
		improw:sìi,siàte.
		presp:-
]=], "<<essere>>, <<riessere>>"},
	{"tessere", "è,tesséi,+", "<<tessere>> and derivatives"},
	{"mietere", "è:é,mietéi,+", "<<mietere>>"},
	{"ripetere", "è", "<<ripetere>>"},
	{"competere", "è,competéi,-", "<<competere>> and derivatives"},
	{"potere", [=[
		-,potéi:potètti[less common].
		presrow:pòsso,puòi,può*,possiàmo,potéte,pòssono.
		fut:potrò.
		imp:-
]=], "<<potere>> and derivatives"},
	{"cotere", "ò,còssi,còsso", "verbs in ''-cotere'' (popular or poetic variant of verbs in ''-cuotere'', such as <<percuotere>> and <<scuotere>>)"},
	{"cuotere", "ò,còssi,còsso.unstressed_stem:cuote:cote[now rare]",
		"verbs in ''-cuotere'' (<<percuotere>>, <<scuotere>>, etc.)"},
	{"^vertere", "è,+,-", "<<vertere>> (but not any derivatives)"},
	-- divertere, convertere, etc.: archaic, unclear conjugation
	-- avertere: archaic
	-- Treccani and Hoepli say [[controvertere]] is conjugated as if it were ''controvertire'', but Google
	-- disagrees except for ''controvertito'' (which is rare).
	{"controvertere", "è,-,-", "<<controvertere>>"},
	{"estrovertere", "è,-,estrovèrso:estrovertìto[less common]", "<<estrovertere>>"},
	-- see also introvertire of the same meaning, which has -ire forms
	{"introvertere", "è,-,introvèrso", "<<introvertere>>"},
	{"sistere", "ì,+,sistìto", "verbs in ''-sistere'' (<<consistere>>, <<esistere>>, <<insistere>>, <<resistere>>, etc.)"},
	{"battere", "à", "<<battere>> and derivatives"},
	{"flettere", "è,+:flèssi[less common],flèsso", "<<flettere>> and derivatives; <<riflettere>> needs an override to handle differences in the past participle"},
	{"mettere", "é,mìsi,mésso", "<<mettere>> and derivatives"},
	{"nettere", "é:#è,+:néssi[less common]:#nèssi[less common],nésso:#nèsso", "verbs in ''-nettere'' (<<annettere>>, <<connettere>> and derivatives)"},
	{"fottere", "ó", "<<fottere>> and derivatives"},
	-- Hoepli says [[incutere]] has past historic ''incutéi'' or ''incùssi''; DOP says "[[incussi]] (non [[incutei]])";
	-- Treccani agrees with DOP, saying [[incutere]] is conjugated like [[discutere]]
	{"cutere", "ù,cùssi,cùsso", "verbs in ''-cutere'' (<<discutere>>, <<escutere>>, <<incutere>>)"},
	{"stinguere", "ì,stìnsi,stìnto", "verbs in ''-stinguere'' (<<estinguere>>, <<distinguere>> and derivatives)"},
	-- delinquere, relinquere: defective, rare or poetic
	{"riavere", [=[
		-,rièbbi:riébbi.
		presrow:riò,riài,rià,riabbiàmo,riavéte,riànno.
		fut:riavrò.
		sub:riàbbia.
		improw:riàbbi,riabbiàte.
		presp:riavènte:riabbiènte
]=], "<<riavere>>"},
	{"^avere", [=[
		-,èbbi:ébbi.
		presrow:hò*,hài,hà*,abbiàmo,avéte,hànno.
		fut:avrò.
		sub:àbbia.
		improw:àbbi,abbiàte.
		presp:avènte:abbiènte
]=], "<<avere>> (but not derivative <<riavere>>)"},
	-- bevere: archaic; handled under bere below
	{"ricevere", "é", "<<ricevere>> and derivatives"},
	{"scrivere", "ì,scrìssi,scrìtto", "<<scrivere>> and derivatives"},
	{{term = "vivere", prefixes = {"con", "soprav"}}, "ì,vìssi,vissùto.fut:vivrò:+", "<<convivere>>, <<sopravvivere>>"},
	{"vivere", "ì,vìssi,vissùto.fut:vivrò", "<<vivere>>, <<rivivere>>"},
	{"sciolvere", "ò,+:sciòlsi,sciòlto", "<<sciolvere>>, <<asciolvere>>"},
	-- solvere: archaic
	{"solvere", "ò,sòlsi,sòlto", "verbs in ''-solvere'' (<<assolvere>>, <<dissolvere>>, <<risolvere>>, etc.)"},
	-- volvere, svolvere, etc. archaic
	{"volvere", "ò,vòlsi:+,volùto", "<<devolvere>>, <<evolvere>>"},
	{"dovere", [=[
		dèvo:dévo:dèbbo:débbo^dève:déve.pres1p:dobbiàmo.
		fut:dovrò.
		sub:dèbba:débba.
		presp:-.
		imp:-
]=]},
	{"piovere", "ò,piòvvi", "<<piovere>> and derivatives"},
	-- movere and derivatives: archaic
	{"muovere", "ò,mòssi,mòsso.unstressed_stem:muove:move[now rare]"},
	{"fervere", "è,+[rare],-"},

	---------------------------------------------- -ire verbs --------------------------------------------
	-- NOTE: Does not include verbs whose only irregularity is a present participle in -iènte, e.g. [[ambire]],
	-- [[ubbidire]], [[impedire]], [[regredire]]/[[progredire]]/[[trasgredire]], [[spedire]], [[blandire]],
	-- and many others.

	-- ire: archaic, defective
	--
	-- assorbire: assòrto as pp is archaic; list ò before +isc because it is much more common per Google Ngrams.
	{{term = "sorbire", prefixes = {"as", "ad", "de"}}, "ò:+isc.presp:+", "<<assorbire>>, <<adsorbire>>, rare <<desorbire>>; but not <<sorbire>>"},
	-- folcire: rare, literary, defective: fólce, folcìsse
	{"escire", "è.presp:+", "<<escire>> and derivatives (archaic/popular for <<uscire>>)"},
	{"uscire", "èsco", "<<uscire>> and derivatives"},
	{"cucire", "cùcio^ù.presp:+", "<<cucire>> and derivatives"},
	-- Treccani says sdrùcio/sdrùce forms are rare but Ngrams does not bear that out (relatively).
	{"sdrucire", "+isc:sdrùcio^+isc:ù.pres3p:+:sdrùcono.presp:+", "<<sdrucire>> and derivatives"},
	-- redire, reddire: poetic, highly defective
	{"applaudire", "à:+isc[uncommon].presp:+", "<<applaudire>> and derivatives"},
	-- Not technically necessary to enumerate the prefixes but we don't want accidental use of @ in verbs like
	-- [[accudire]], [[esaudire]], [[incrudire]] to trigger this.
	{{term = "udire", prefixes = {"^", "ri", "tra"}}, "òdo.fut:udrò:+.presp:+:udiènte", "<<udire>> and derivatives"},
	-- gire: archaic, defective
	{"fuggire", "ù", "<<fuggire>> and derivatives"},
	{"muggire", "+isc.pres3s:+:mùgge.pres3p:+:mùggono", "<<muggire>> and derivatives"},
	{"salire", "sàlgo^à.presp:+:saliènte", "<<salire>> and derivatives"},
	-- boglire: archaic, unclear conjugation
	{"seppellire", "+isc,+,sepólto:+", "<<seppellire>> and derivatives"},
	{"sbollire", "+isc:ó", "<<sbollire>>"},
	{"bollire", "ó", "<<bollire>> and derivatives, except <<sbollire>>"},
	{"dormire", "ò.presp:+:dormiènte", "<<dormire>> and derivatives"},
	{"venire", "vèngo^viène:viéne,vénni:vènni,venùto.fut:verrò.presp:veniènte", "<<venire>> and derivatives"},
	{{term = "mpire", prefixes = {"ade", "co"}}, "+isc.ger:mpièndo.presp:mpiènte", "<<adempire>> and <<compire>>"},
	{"empire", "émpio,+:empiéi[less common],+:empiùto[less common].ger:empièndo.presp:empiènte",
		"<<empire>> and <<riempire>>; not <<adempire>>, which has a more regular conjugation"},
	{{term = "parire", prefixes = {"ap", "com"}}, "pàio:+isc^à:+isc,pàrvi:parìi[less common]:pàrsi[less common],pàrso", "<<apparire>>, <<comparire>> and derivatives; but note that <<comparire>> and <<scomparire>> need special treatment as different variant forms are associated with distinct meanings"},
	{"^sparire", "+isc,spàrvi:sparìi[less common]:spàrsi[less common],spàrso", "<<sparire>>"},
	{"disparire", "dispàio^à,+:dispàrvi", "<<disparire>>"},
	{"trasparire", "traspàio:+isc^à+:+isc", "<<trasparire>>"},
	{"inferire", "+isc,infèrsi,infèrto", "<<inferire>> in the meaning \"to inflict, to strike\" (a blow); use 'a/+isc' for other meanings"},
	{"profferire", "+isc,+:proffèrsi,proffèrto", "<<profferire>>"},
	-- perire: regular except in archaic/poetic usage pèro, etc.
	{"offrire", "ò,+:offèrsi[less common],offèrto.presp:offerènte", "<<offrire>>, <<soffrire>> and derivatives"},
	{"morire", "muòio^muòre,+,mòrto.fut:+:morrò.presp:+", "<<morire>> and derivatives (<<smorire>> has no past participle and needs an override)"},
	{"aprire", "à,+:apèrsi,apèrto.presp:+", "<<aprire>> and derivatives"},
	{"coprire", "ò,+:copèrsi,copèrto.presp:+", "<<coprire>> and derivatives"},
	-- scovrire: archaic, unclear conjugation
	{"borrire", "+isc:ò.presp:+", "<<aborrire>>, <<abborrire>>"},
	{"nutrire", "ù:+isc[less common].presp:nutriènte", "<<nutrire>> and derivatives"},
	-- putrire: literary, rare
	-- Hoepli doesn't mention present participle mentente but it probably exists
	{"^mentire", "é:#è:+isc", "<<mentire>>; but not derivative <<smentire>>, nor <<sementire>> or <<intormentire>>, all of which are regular in -isc-"},
	{"pentire", "è.presp:-", "<<pentirsi>> and derivatives"},
	-- sentire has rare sentènte and adjective-only senziènte
	{{term = "sentire", prefixes = {"^", "^ri", "intra"}}, "è.presp:-", "<<sentire>>, <<risentire>>, <<intrasentire>>; but not any other derivatives"},
	-- presentire has presenziènte but it's rare and literary
	{"presentire", "è+:+isc.presp:-", "<<presentire>>"},
	{"sentire", "è.presp:senziènte", "derivatives of <<sentire>> other than <<sentire>> itself, <<risentire>>, <<intrasentire>> and <<presentire>>, e.g. <<assentire>>, <<consentire>>, <<dissentire>>"},
	{"inghiottire", "+isc[in the literal meaning]:ó[figuratively]"},
	-- See also introvertere of the same meaning, which has -ere forms.
	{"introvertire", "+isc,-,+", "<<introvertire>>"},
	-- Many of the verbs in -vertire have additional archaic, literary, etc. forms; e.g. [[convertire]] has archaic or dialectal +isc forms, archaic or literary past historic convèrsi, archaic or literary past participle convèrso.
	{"vertire", "è", "verbs in ''-vertire'' other than <<introvertire>>, e.g. <<avvertire>>, <<convertire>>, <<divertire>>, <<invertire>>, <<pervertire>>, <<sovvertire>>"},
	{"compartire", "+isc:à", "<<compartire>> and derivatives"},
	{"partire", "à", "<<partire>>, <<dipartire>>, <<ripartire>> in the intransitive usage (use 'a/+isc' for the transitive usage)"},
	{"^sortire", "ò", "<<sortire>> in the intransitive usage (use 'a/+isc' for the transitive usage); not any derivatives"},
	{"vestire", "è", "<<vestire>> and derivatives"},
	{"putire", "+isc:ù", "<<putire>>"},
	{"languire", "+isc:à", "<<languire>>"},
	{"eseguire", "+isc:é:è", "<<eseguire>> and derivatives"}, -- [r:DiPI:eseguo]
	{"seguire", "é:è", "<<seguire>> and derivatives; but not <<eseguire>> and derivatives"}, -- [r:DiPI:seguo], [r:DiPI:conseguo], [r:DiPI:inseguo], [r:DiPI:perseguo], [r:DiPI:proseguo], [r:DiPI:susseguo]
	-- costruire (archaic construire); costrùssi, costrùtto given as "literary" by Hoepli but "archaic" by DOP, which
	-- seems closer to the truth. Per Anna Thornton in ''Morphological Autonomy'' p. 368, [[costrutto]] is
	--   no longer recognized as a pp in modern Italian but only as a noun.
	{"servire", "è", "<<servire>> and derivatives (although not <<asservire>>, which should use 'a/+isc')"},

	------------------------------------------- syncopated verbs -----------------------------------------
	-- affare: 3rd person only, no pp, affà
	-- assuefare, confare, contraffare, disassuefare, dissuefare, mansuefare, putrefare, rarefare, rifare, sopraffare,
	--   strafare, stupefare, torrefare, tumefare: like fare, written assuefò/assuefà, confò/confà, etc. will be
	--   handled automatically as the accent removal is late and dependent on the number of syllables in the word.
	-- malfare: infinitive only
	-- sfare: like fare
	{"disfare", [=[
		-,disféci,disfàtto.
		stem:disfàce.
		presrow:disfàccio:dìsfo,dìsfi,dìsfa,disfacciàmo,disfàte,dìsfano.
		sub:dìsfi.
		fut:disfarò.
		imp:disfà:disfài
]=], "<<disfare>>, <<soddisfare>> (<<sodisfare>>)"},
	-- liquefare: same as fare except for proscribed variants e.g. lìquefo, lìquefa
	{"fare", [=[
		-,féci,fàtto.
		stem:fàce.
		presrow:fàccio,fài,fà*,facciàmo,fàte,fànno.
		sub:fàccia.
		imp:fài:fà'
]=], "<<fare>> and derivatives; but not <<disfare>> or <<soddisfare>>"},
	{"trarre", "tràggo,tràssi,tràtto.stem:tràe"},
	-- archaic variant of trarre, with some different present tense (hence subjunctive/imperative) forms
	{"traggere", "à\\tràggo^tràgge,tràssi,tràtto.pres1p:traggiàmo.fut:trarrò.stem:tràe"},
	{{term = "bere", prefixes = {"^", "ri", "tra"}}, "bévo,bévvi:bevétti.fut:berrò.stem:béve",
		"<<bere>>, <<strabere>>, <<trabere>>, <<ribere>>; but not verbs in ''-combere'', archaic <<ebere||to weaken>>, archaic <<iubere||to command, to order>> or obsolete <<assorbere>>"},
	{"bevere", "é,bévvi:bevétti.fut:berrò", "<<bevere>> and derivatives (archaic variant of <<bere>>)"},
	-- benedire (strabenedire, ribenedire), maledire (stramaledire, rimaledire)
	{{term = "dire", prefixes = {"bene", "male", "mala"}}, "+,dìssi:dìi[popular],détto.stem:dìce.pres2p:dìte.imperf:+:dìvo[popular]", "<<benedire>>, <<maledire>> and derivatives"},
	-- dire, ridire
	{{term = "dire", prefixes = {"^", "ri"}}, "+,dìssi,détto.stem:dìce.pres2p:dìte.imp:dì':dì*!", "<<dire>>, <<ridire>>; not any other derivatives"},
	-- addire, contraddire, ricontraddire, indire, interdire, predire, etc.
	{"dire", "+,dìssi,détto.stem:dìce.pres2p:dìte", "derivatives of <<dire>> other than <<benedire>>, <<maledire>> and <<ridire>>"},
	-- dicere: archaic; not included due to multiple variants
	{"porre", "ó\\póngo,pósi,pósto:pòsto.stem:póne"},
	-- archaic variant of porre
	{"ponere", "ó\\póngo,pósi,pósto:pòsto.fut:porrò"},
	-- condurre, etc.
	{"durre", "+,dùssi,dótto.stem:dùce"},
	-- archaic variant of -durre
	{"ducere", "ù,dùssi,dótto.fut:durrò"},
}

return export
