#!/usr/bin/perl
use utf8;
#use open ':std', ':encoding(UTF-8)';

#use warnings;
#use strict;

use FindBin qw($Bin);
use lib "$Bin/..";

# Defines ScriptFunc and ScriptShortFunc attributes.
use horas::Scripting;

#*** translate_cz()
# translates a line from Latin to Czech
# written for Necrologium from Vyšší Brod, CZ (Altovadum)
# will hardly work on anything else...
sub translate_cz : ScriptFunc {

#	my $filename = $ARGV[0];
#	my $i = 0;
	my $line = shift;
	
#	open(FH, '<', $filename) or die $!;
	
#	while(<FH>){
		$line = $_;
	
	$line =~ s/\t\t/  /;
	$line =~ s/ \t/  /;
	$line =~ s/\t/ /g;

	$line =~ s/Purissimi Cordis B\.M\.V\./Nejčistšího Srdce Panny Marie/ig;
	
	$line =~ s/A\.R\.P\./Veledůstojný Otec/ig;
	$line =~ s/A\.R\.D\./Veledůstojný Pán/ig;
	$line =~ s/A\.R\. et Ven.* P\./Veledůstojný a ctihodný Otec/ig;
	$line =~ s/A\.R\. ac Ven.* P\./Veledůstojný a ctihodný Otec/ig;
	$line =~ s/RR\. Domnus/Nejdůstojnější Pán/ig;
	$line =~ s/Reverendissimi Domni|RR\. Domni/Nejdůstojnějšího Pána/ig;

	$line =~ s/professi Altovadensis/vyšebrodského profese/ig;
	$line =~ s/Altovadensis/vyšebrodský/ig;
	$line =~ s/Altovadensi/vyšebrodském/ig;
	$line =~ s/Zarae|Zarensis/ze Žďáru/ig;
	$line =~ s/Ossecensis/osecký/ig;
	$line =~ s/Ossecii/v Oseku/ig;
	$line =~ s/circa Ossecum/v okolí Oseka/ig;
	$line =~ s/Lambacensis/lambašský/ig;
	$line =~ s/in Lambach/v Lambachu/ig;
	$line =~ s/in Schlüchtern/v klášteře Schlüchtern/ig;
	$line =~ s/Plagensis/ze Schläglu/ig;
	$line =~ s/Aulae-Regiae/zbraslavský/ig;
	$line =~ s/Sanctae Coronae|Sacrae Spinae Coronae/zlatokorunský/ig;
	$line =~ s/in Sancta Corona/ve Zlaté Koruně/ig;
	$line =~ s/Neo-Cellae|Neocellensis|Novae-Cellae/z Neuzelle/ig;
	$line =~ s/Plassensis/z Plas/ig;
	$line =~ s/Plassii/v Plasích/ig;
	$line =~ s/Portae.Coeli/v Porta Coeli/ig;
	$line =~ s/Montis Pomarii|ad Montem Pomarium/z kláštera Baumgartenberg/ig;
	$line =~ s/Wellehradensis/velehradský/ig;
	$line =~ s/Hilariae/ve Wilheringu/ig;
	$line =~ s/monasterii Sedlicensis|monasterii Sedlecensis/sedleckého kláštera/ig;
	$line =~ s/Sedlicensis|Sedlecensis/sedlecký/ig;
	$line =~ s/in Valle Mariae/v klášteře Marienthal/ig;
	$line =~ s/in Waldsassen/v klášteře Waldsassen/ig;
	$line =~ s/Sionensis/strahovský/ig;
	$line =~ s/Clarae.Vallis/ze Zwettlu/ig;
	$line =~ s/Sanctae Crucis/Heiligenkreuz/ig;
	$line =~ s/Campililii/v klášteře Lilienfeld/ig;

	$line =~ s/in Valle Virginum/v klášteře Pohled/ig;
	$line =~ s/in Valle.Mariae/v klášteře Marienthal/ig;
	$line =~ s/Mariae.Stellae|Stellae.Mariae|Mariae.Stelae|Stelae.Mariae/v klášteře Marienstern/ig;
	

	$line =~ s/Altovado/Vyšší Brod/ig;
	$line =~ s/in Altovado/ve Vyšším Brodě/ig;
	$line =~ s/in oppido Altovadeno/ve městě Vyšší Brod/ig;
	$line =~ s/de oppido Altovadeno|de oppido Altovado/z města Vyšší Brod/ig;
	$line =~ s/in capella Beatae Mariae Virginis/v kapli Panny Marie/ig;
	$line =~ s/Bechinensis/bechyňský/ig;
	$line =~ s/Capellensis/z Kapliček/ig;
	$line =~ s/in Capella/v Kapličkách/ig;
	$line =~ s/Hoericii|Hoericium|Hoeric|Haeric/Hořice/ig;
	$line =~ s/ad Fonticulum|ad Fontem Salubrem|ad Salubrem Fonticulum/na Dobré Vodě/ig;
	$line =~ s/Oberheid|Mericae Superioris/v Horním Dvořišti/ig;
	$line =~ s/Unterheid|Merica Inferioris|Merica inferior/Dolní Dvořiště/ig;
	$line =~ s/Rosenthal/Rožmitál/ig;
	$line =~ s/Priethalium|Priethal/Přídolí/ig;
	$line =~ s/Cajoviae/v Kájově/ig;
	$line =~ s/Gratzen/Nové Hrady/ig;
	$line =~ s/praedii Komařiciensis/statku v Komařicích/ig;
	$line =~ s/Strziczicium/Strýčice/ig;
	$line =~ s/Strýčiciensis/strýčcký/ig;
	$line =~ s/Strakonicensis/strakonický/ig;
	$line =~ s/Tarnoviensis/trnavského/ig;
	$line =~ s/Strobniciensis/stropnický/ig;
	$line =~ s/Strobnicii/ve Stropnici/ig;
	$line =~ s/Kalschingensis|Chvalšinensis/chvalšinský/ig;
	$line =~ s/Driesendorf/Střížov/ig;
	$line =~ s/Boreschovii/v Boršově/ig;
	$line =~ s/de Budvicio/z Budějovic/ig;
	$line =~ s/Budvicii/v Budějovicích/ig;
	$line =~ s/Černicensis/v Černici/ig;
	$line =~ s/Potvoroviensi/potvorovské/ig;
	$line =~ s/Malsching/Malšín/ig;
	$line =~ s/de Rosenberg|de Rosis/z Rožmberka/ig;
	$line =~ s/Rosenberg/Rožmberk/ig;
	$line =~ s/Crumlovia|Crumlov/Krumlov/ig;
	$line =~ s/Sobieslavia/Soběslav/ig;
	$line =~ s/Kozojedii|in Kozojed/v Kozojedech/ig;
	$line =~ s/Sanctae Annae/Svaté Anny/ig;
	$line =~ s/ad Sanctum Martinum/u svatého Martina/ig;
	$line =~ s/in monasterio Sanctae Clarae virginis/v klášteře svaté Kláry Panny/ig;
	$line =~ s/in monasterio/v klášteře/ig;
	$line =~ s/in nostra ecclesia/v našem kostele/ig;
	$line =~ s/in ecclesia/v kostele/ig;
	$line =~ s/in instituto philosophico/na filosofickém institutu/ig;
	$line =~ s/Tento-Richnov.*/Rychnov u Nových Hradů/ig;
	$line =~ s/Plan /Planá /ig;
	$line =~ s/Plan\./Planá\./ig;
	$line =~ s/Mariae.Ratschitz|Maria Ratschitz/Mariánské Radčice/ig;
	$line =~ s/Kirchschlag/Světlík/ig;
	$line =~ s/Antiqua Bruna/Staré Brno/ig;
	$line =~ s/Bruna/Brno/ig;
	$line =~ s/ad Sanctum Oswaldum/ve Svatém Osvaldu/ig;

	$line =~ s/Austriae superioris/v Horním Rakousku/ig;
	$line =~ s/Austriae|in Austria/v Rakousku/ig;
	$line =~ s/per Bohemiam/pro Čechy/ig;
	$line =~ s/in Lusatia/v Lužici/ig;
	$line =~ s/Lusatiam/Lužici/ig;
	$line =~ s/in Hungaria/v Maďarsku/ig;
	$line =~ s/in Polonia/v Polsku/ig;

	$line =~ s/abbatiae Ossecensis/oseckého opatství/ig;

	$line =~ s/Ordinis Sancti Joannis hospitalis in Jerusalem/hospitálního Řádu svatého Jana v Jeruzalémě/ig;

	$line =~ s/abbas/opat/ig;
	$line =~ s/abbatiae/opatství/ig;
	$line =~ s/abbatissa/abatyše/ig;
	$line =~ s/praepositus/probošt/ig;
	$line =~ s/visitator/vizitátor/ig;
	$line =~ s/subprior/podpřevor/ig;
	$line =~ s/prior.administrator/převor-administrátor/ig;
	$line =~ s/prior /převor /ig;
	$line =~ s/prior\./převor\./ig;
	$line =~ s/prior\,/převor\,/ig;
	$line =~ s/Religiosus|Religiosa/Řeholní/gi;
	$line =~ s/ Frater | Fr\. / bratr /gi;
	$line =~ s/Reverendus/Důstojný/gi;
	$line =~ s/Conversus/konvrš/gi;
	$line =~ s/confraternitatem fecit/uzavřel konfraternitu/gi;
	$line =~ s/confrater noster/náš spolubratr/gi;
	$line =~ s/confratris nostri/našeho spolubratra/ig;
	$line =~ s/confrater/spolubratr/gi;
	$line =~ s/Virgo/Panna/gi;
	$line =~ s/Domina/Paní/gi;
	$line =~ s/Dominus/Pán/gi;
	$line =~ s/magister infirmorum|infirmarius/infirmář/ig;
	$line =~ s/Domini abbatis/Pana Opata/gi;
	$line =~ s/abbatis/Opata/gi;
	$line =~ s/Domini /Pána /gi;
	$line =~ s/gubernator/hejtman/gi;
	$line =~ s/conventualis/konventní/gi;
	$line =~ s/episcopi Budvicensis/biskupa budějovického/gi;
	$line =~ s/stabilitatis/se slibem stability/gi;
	$line =~ s/cum disputationibus/při disputacích/gi;
	$line =~ s/habitis/konaných/gi;
	$line =~ s/mortuus/zemřel/gi;
	$line =~ s/in parochia/ve farnosti/gi;
	
	$line =~ s/Quirini/Quirina/ig;
	$line =~ s/illustrissimum dominum/nejjasnějšího pána/gi;
	$line =~ s/cum monasterio nostro/s naším klášterem/gi;
	$line =~ s/huic monasterio/tomuto klášteru/gi;
	$line =~ s/fidelem curam/věrnou péči/gi;
	$line =~ s/in officio suo/ve svém úřadu/gi;
	$line =~ s/impendit/vynakládal/gi;
	$line =~ s/serenissimi/nejjasnějšího/gi;
	$line =~ s/magnifici/vznešeného/gi;
	$line =~ s/magnificus/vznešený/gi;
	$line =~ s/Inclytus/Slavný/gi;
	$line =~ s/Regis/Krále/ig;
	$line =~ s/protonotarius/protonotář/ig;
	$line =~ s/prothonotarii|protonotarii/protonotáře/ig;
	$line =~ s/presbyteri/kněze/gi;
	$line =~ s/Honorabilis/Ctihodný/gi;
	$line =~ s/Honesta/Ctná/gi;
	$line =~ s/Honestus/Ctný/gi;
	$line =~ s/supremus/nejvyšší/gi;
	$line =~ s/praestans/vynikající/gi;
	$line =~ s/organista/varhaník/gi;
	$line =~ s/decanus personalis/osobní děkan/gi;
	$line =~ s/decanus/děkan/gi;
	$line =~ s/cancellariae et aedificiorum inspector/správce kanceláří a budov/gi;
	$line =~ s/inspector aedificiorum/správce budov/gi;
	$line =~ s/capellae regalis/královské kapely/gi;
	$line =~ s/canonicus/kanovník/gi;

	
	$line =~ s/parochus emeritus/emeritní farář/gi;
	$line =~ s/parochus/farář/gi;
	$line =~ s/clericus/klerik/gi;
	$line =~ s/studens|scholarius/student/gi;
	$line =~ s/diaconus/jáhen/gi;
	$line =~ s/plebanus/plebán/gi;
	$line =~ s/auxiliator /pomocný duchovní /gi;
	$line =~ s/cooperator administratoris|cooperator|capellanus|cooperatus|adjutor parochiae|adjutor parochi/kaplan/gi;
	$line =~ s/presbyteri/kněze/gi;

	$line =~ s/archivarius/archivář/ig;
	$line =~ s/praefectus pharmacopae/prefekt lékárny/ig;
	$line =~ s/praefectus culinae abbatialis/prefekt opatské kuchyně/ig;
	$line =~ s/praefectus culinae|culinae praefectus/prefekt kuchyně/ig;
	$line =~ s/praefectus/prefekt/ig;
	$line =~ s/cellae vinariarum/vinných sklepů/ig;
	$line =~ s/magister conversorum/konvršmistr/ig;
	$line =~ s/magister novitiorum|novitiorum magister/novicmistr/ig;
	$line =~ s/administrator oeconomiae/hospodářský správce/ig;
	$line =~ s/inspector oeconomiae/hospodářský správce/ig;
	$line =~ s/bibliothecarius/knihovník/ig;
	$line =~ s/confessarius/zpovědník/ig;
	$line =~ s/cantor/kantor/ig;
	$line =~ s/regens chori figuralis/dirigent orchestru a sboru/ig;
	$line =~ s/regens chori/regenschori/ig;
	$line =~ s/huius loci/tohoto kláštera/ig;
	$line =~ s/domni abbatis/pana opata/ig;
	$line =~ s/administrator|procurator/správce/gi;
	$line =~ s/aurifaber/zlatník/gi;
	$line =~ s/pharmacopoia/lékárník/gi;
	$line =~ s/granarius/správce sýpky/gi;
	$line =~ s/quaesturae provisor/finanční správce/gi;
	$line =~ s/provisor/správce/gi;
	$line =~ s/gymnasii/gymnázia/gi;
	$line =~ s/Ordinis doctor theologus/řádový doktor teologie/gi;
	$line =~ s/Ordinis cisterciensis|cisterciensis Ordinis/cisterciáckého Řádu/gi;
	$line =~ s/Ordinis/Řádu/gi;
	$line =~ s/director/ředitel/gi;
	$line =~ s/congregationis|congregatio/kongregace/gi;
	$line =~ s/in prioratu/v převorství/gi;

	$line =~ s/Joannis/Jana/ig;
	$line =~ s/Jodoci/Jocha/ig;
	$line =~ s/Augustini/Augustina/ig;
	$line =~ s/Ulrici/Oldřicha/ig;
	$line =~ s/Ulricus/Oldřich/ig;
	$line =~ s/Bartholomaei/Bartoloměje/ig;
	$line =~ s/Henricus/Jindřich/ig;
	$line =~ s/Henrici /Jindřicha /ig;
	$line =~ s/Matthiae /Matyáše /ig;
	$line =~ s/Ungaricae /Uherského /ig;
	$line =~ s/Martini/Martina/ig;
	$line =~ s/Sancti Viti/svatého Víta/ig;
	$line =~ s/Viti /Víta /ig;
	$line =~ s/Edmundi/Edmunda/ig;
	$line =~ s/Procopii/Prokopa/ig;


	$line =~ s/canoniae/kanonie/ig;
	$line =~ s/vinearum/vinic/ig;
	$line =~ s/parochii/farnosti/ig;
	$line =~ s/Reverendi /důstojného /ig;
	$line =~ s/capituli/kapituly/ig;
	$line =~ s/monialium/sester/ig;
	
	$line =~ s/dioeceseos Budvicensis/budějovické diecéze/ig;
	$line =~ s/notarius archiepiscopialis/arcibiskupský notář/ig;
	$line =~ s/notarius episcopalis/biskupský notář/ig;
	$line =~ s/proto.notarius apostolicus/apoštolský protonotář/ig;
	$line =~ s/notarius apostolicus/apoštolský notář/ig;
	$line =~ s/vicarius generalis/generální vikář/ig;
	$line =~ s/ordinis Cisterciensis/cisterciáckého řádu/ig;
	$line =~ s/secretarius/sekretář/ig;
	$line =~ s/notarius/notář/ig;
	$line =~ s/cellarius/sklepmistr/ig;
	$line =~ s/cellarii/sklepů/ig;
	$line =~ s/cellerarius/celerář/ig;
	$line =~ s/sacrista /sakristán /ig;
	$line =~ s/consiliar.* constistorialis|consiliarius consistorialis/konsistorní rada/ig;
	$line =~ s/episcopi /biskupa /ig;
	$line =~ s/ fratris/ bratra/ig;
	$line =~ s/plebanus/plebán/ig;
	$line =~ s/benefactor singularis/jedinečný dobrodinec/ig;
	$line =~ s/benefactor noster/náš dobrodinec/ig;
	$line =~ s/benefactor/dobrodinec/ig;
	$line =~ s/benefactrix/dobrodinka/ig;
	$line =~ s/fautor/mecenáš/ig;
	$line =~ s/ praenobilis/ převznešený/ig;
	$line =~ s/ nobilis/ vznešený/ig;
	$line =~ s/famosus/slavný/ig;
	$line =~ s/exemplaris/příkladný/ig;
	$line =~ s/generosa/štědrá/ig;
	$line =~ s/generosae/štědré/ig;
	$line =~ s/generosi/štědrého/ig;
	$line =~ s/generosus/štědrý/ig;
	$line =~ s/virtuosa/ctnostná/ig;
	$line =~ s/virtuosus/ctnostný/ig;
	$line =~ s/primus/první/ig;
	$line =~ s/camerarius/komorník/ig;
	$line =~ s/laudabiliter/chvályhodně/ig;
	$line =~ s/persolvit/vykonával/ig;
	$line =~ s/nostri /našeho /ig;
	$line =~ s/huius monasterii/tohoto kláštera/ig;
	$line =~ s/monasterii/kláštera/ig;
	$line =~ s/officium/úřad/ig;		######### OFFICIUM #########
	$line =~ s/physicae/fyziky/ig;
	$line =~ s/mathematicae/matematiky/ig;
	$line =~ s/philosophiae professor|professor philosophiae/profesor filosofie/ig;
	$line =~ s/professor/profesor/ig;
	$line =~ s/pictor /malíř /ig;
	$line =~ s/pictor\./malíř\./ig;
	$line =~ s/sutor/švec/ig;
	$line =~ s/sartor /krejčí /ig;
	$line =~ s/sartor\./krejčí\./ig;
	$line =~ s/capitaneus|capitanei/správce/ig;
	$line =~ s/doleatoris/ranhojiče/ig;
	$line =~ s/tumulatus est/je pohřben/ig;
	$line =~ s/philosophiae doctor|doctor philosophiae/doktor filosofie/ig;
	$line =~ s/theologiae doctor|doctor theologiae/doktor teologie/ig;
	$line =~ s/doctor/doktor/ig;
	$line =~ s/theologiae baccalaureus|baccalaureus theologiae/bakalář teologie/ig;
	$line =~ s/theologiae-dogmaticae professor/profesor dogmatické teologie/ig;
	$line =~ s/theologiae|theologia/teologie/ig;
	$line =~ s/pater spiritualis/otec spirituál/ig;
	$line =~ s/per complures annos/po mnoho let/ig;
	$line =~ s/adjutor oeconomiae|adiutor oeconomiae/pomocný správce/ig;
	$line =~ s/in hospitali/ve špitále/ig;
	$line =~ s/procuratrix/správkyně/ig;
	$line =~ s/balneator/lazebník/ig;
	$line =~ s/portarius/fortnýř/ig;
	$line =~ s/domi /domu /ig;
	$line =~ s/domi\./domu\./ig;
	$line =~ s/domi\,/domu\,/ig;
	$line =~ s/officialis/hodnostář/ig;
	$line =~ s/coadiutor/coadjutor/ig;
	$line =~ s/ecclesiae Wratislaviensis/vratislavské katedrály/ig;

	$line =~ s/pater eius/jeho otec/ig;
	$line =~ s/pater /otec /ig;
	$line =~ s/patris/otce/ig;
	$line =~ s/filius/syn/ig;
	$line =~ s/sororis/sestry/ig;
	$line =~ s/soror/sestra/ig;
	$line =~ s/filia /dcera /ig;
	$line =~ s/mater eius/jeho matka/ig;
	$line =~ s/mater /matka /ig;
	$line =~ s/matrona /dáma /ig;
	$line =~ s/civissa/občanka/ig;
	$line =~ s/cives |civis /občan /ig;
	$line =~ s/conthoralis/choť/ig;
	$line =~ s/consanguinea/rodná sestra/ig;
	$line =~ s/confratrix nostra/členka naší konfraternity/ig;
	$line =~ s/vidua /vdova /ig;
	$line =~ s/germanus/rodný bratr/ig;
	$line =~ s/parens/rodič/ig;
	$line =~ s/uxor eius/jeho manželka/ig;
	$line =~ s/uxor/manželka/ig;
	$line =~ s/hic professi/zdejšího profese/ig;
	$line =~ s/in oppido/ve městě/ig;
	$line =~ s/ante altare/před Oltářem/ig;
	$line =~ s/post expulsionem/po vyhnání/ig;
	
	$line =~ s/eodem anno /Téhož roku /ig;
	$line =~ s/Anno /Roku /ig;
	$line =~ s/Die /Dne /ig;
	$line =~ s/quondam/kdysi/ig;
	$line =~ s/hic /zde /ig;
	$line =~ s/dein /poté /ig;
	$line =~ s/sepultus est/je pohřbený/ig;
	$line =~ s/sepultus iacet/leží pohřbený/ig;
	$line =~ s/sepultus/pohřbený/ig;
	$line =~ s/sepulta est/je pohřbená/ig;
	$line =~ s/sepulta/pohřbená/ig;
	$line =~ s/mensis/měsíce/ig;

	$line =~ s/januarii/ledna/ig;
	$line =~ s/februarii/února/ig;
	$line =~ s/martii/března/ig;
	$line =~ s/aprilis/dubna/ig;
	$line =~ s/maii|maji/května/ig;
	$line =~ s/iunii|junii/června/ig;
	$line =~ s/iulii|julii/července/ig;
	$line =~ s/augusti/srpna/ig;
	$line =~ s/septembris/září/ig;
	$line =~ s/octobris/října/ig;
	$line =~ s/novembris/listopadu/ig;
	$line =~ s/decembris/prosince/ig;

	$line =~ s/pie in Domino obdormierunt/zbožně v Pánu zesnuli/ig;
	$line =~ s/monachus chori/chórový mnich/ig;
	$line =~ s/monachus/mnich/ig;
	$line =~ s/professus iubilatus|professus jubilatus/profes po slavném jubileu/ig;
	$line =~ s/sacerdos iubilatus|sacerdos jubilatus/kněz po slavném jubileu/ig;
	$line =~ s/sacerdos/kněz/gi;
	$line =~ s/professus/profes/ig;
	$line =~ s/professi/profese/ig;
	$line =~ s/ibidem/na témž místě/ig;
	$line =~ s/B\.M\.V\./Panny Marie/ig;
	$line =~ s/ et / a /ig;
	$line =~ s/ qui / který /ig;
	$line =~ s/ ubi / kde /ig;
	$line =~ s/ er / a /ig;
	$line =~ s/ in / v obci /ig;
	$line =~ s/ ac / a /ig;
	$line =~ s/ apud / u /ig;
	$line =~ s/ de la / de-la /gi;
	$line =~ s/ de / z obce /gi;
	$line =~ s/ de-la / de la /gi;
	$line =~ s/ ad[ij]utor/ pomocný/gsi;
	$line =~ s/(i|j)ubilatus]/slavný/gsi;
	
#	print $line;
#	$i++;
	#if ( $i > 30 ) { last; }
#	}
	return $line;	
#	close(FH);
}
1;
