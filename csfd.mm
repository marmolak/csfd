<map version="0.9.0">
<!-- To view this file, download free mind mapping software FreeMind from http://freemind.sourceforge.net -->
<node CREATED="1361449180288" ID="ID_457596329" MODIFIED="1361450286071" TEXT="main">
<node CREATED="1361449185139" ID="ID_59803788" MODIFIED="1361450441014" POSITION="right" TEXT="1) pool - foreach my dir (@dirs)">
<node CREATED="1361449203034" ID="ID_1009156285" MODIFIED="1361449206542" TEXT="existuje adresar?">
<node CREATED="1361449208201" ID="ID_1006258996" MODIFIED="1361449238751" TEXT="ne?">
<arrowlink DESTINATION="ID_59803788" ENDARROW="Default" ENDINCLINATION="9;-67;" ID="Arrow_ID_1857059660" STARTARROW="None" STARTINCLINATION="-72;-236;"/>
</node>
</node>
<node CREATED="1361449243608" ID="ID_1865896718" MODIFIED="1361449245644" TEXT="ano">
<node CREATED="1361449323204" ID="ID_1970451236" MODIFIED="1361450179189" TEXT="vezmi polozku adresare">
<node CREATED="1361449330747" ID="ID_1455147442" MODIFIED="1361449351964" TEXT="je to adresar?">
<node CREATED="1361449343443" ID="ID_871833286" MODIFIED="1361449345015" TEXT="ano">
<node CREATED="1361449878809" ID="ID_652782194" MODIFIED="1361450475483" TEXT="vezmi jmeno a uprav jej">
<node CREATED="1361449885688" ID="ID_240469727" MODIFIED="1361450618580" TEXT="zavolej csfd">
<node CREATED="1361449996451" ID="ID_1759397320" MODIFIED="1361450032403" TEXT="vyprsel timeout?">
<node CREATED="1361450010586" ID="ID_1508739493" MODIFIED="1361450011511" TEXT="ano">
<node CREATED="1361450013954" ID="ID_453398209" MODIFIED="1361450023434" TEXT="vypis jen nazev adresare"/>
</node>
<node CREATED="1361450032403" ID="ID_1219741162" MODIFIED="1361450033191" TEXT="ne">
<node CREATED="1361449888672" ID="ID_621951446" MODIFIED="1361450028506" TEXT="vratilo se neco?">
<node CREATED="1361449893256" ID="ID_317976225" MODIFIED="1361449894173" TEXT="ano">
<node CREATED="1361450068200" ID="ID_1253518577" MODIFIED="1361450080899" TEXT="zformatuj a vyblej">
<node CREATED="1361450334186" ID="ID_1316170545" MODIFIED="1361450356127" TEXT="uloz nazev upraveneho jmena adresare a udaje o filmu do sqlite databaze"/>
</node>
</node>
<node CREATED="1361449896592" ID="ID_145136496" MODIFIED="1361449897422" TEXT="ne">
<node CREATED="1361449907967" ID="ID_29694992" MODIFIED="1361449917236" TEXT="napis nazev adresare a ostatni nezname"/>
</node>
</node>
</node>
</node>
</node>
</node>
</node>
<node CREATED="1361449351964" ID="ID_33171080" MODIFIED="1361450179188" TEXT="ne">
<arrowlink DESTINATION="ID_1970451236" ENDARROW="Default" ENDINCLINATION="-28;13;" ID="Arrow_ID_51534208" STARTARROW="None" STARTINCLINATION="-47;40;"/>
</node>
</node>
</node>
</node>
</node>
<node CREATED="1361452764998" ID="ID_1253654664" MODIFIED="1361452799809" POSITION="right" TEXT="2) zvys pocet hlidek a zjisti, jestli je vyssi nez povolene maximum v /proc">
<node CREATED="1361450093822" ID="ID_1227655752" MODIFIED="1361452805584" TEXT="pridej hlidky na adresare">
<node CREATED="1361450135892" ID="ID_1076119295" MODIFIED="1361450141881" TEXT="vytvoril se adresar?">
<node CREATED="1361450142891" ID="ID_40210315" MODIFIED="1361450475483" TEXT="ano">
<node CREATED="1361450598149" ID="ID_659444643" MODIFIED="1361450602506" TEXT="vem jmeno a uprav jej">
<node CREATED="1361450481203" ID="ID_867657847" MODIFIED="1361450594270" TEXT="podivej se do cache">
<node CREATED="1361450556240" ID="ID_760741165" MODIFIED="1361450580699" TEXT="je nazev shodny?">
<node CREATED="1361450559975" ID="ID_67455551" MODIFIED="1361450560875" TEXT="ano">
<node CREATED="1361450563287" ID="ID_880860740" MODIFIED="1361451632493" TEXT="pouzij udaje z cache a dej echo o tom, ze je to nove"/>
</node>
<node CREATED="1361450561111" ID="ID_651415267" MODIFIED="1361450618580" TEXT="ne">
<arrowlink DESTINATION="ID_240469727" ENDARROW="Default" ENDINCLINATION="299;29;" ID="Arrow_ID_1168859278" STARTARROW="None" STARTINCLINATION="299;29;"/>
</node>
</node>
</node>
</node>
</node>
</node>
</node>
</node>
<node CREATED="1361450297828" ID="ID_116017715" MODIFIED="1361450397055" POSITION="right" TEXT="3) nahod timer (kazdych 10 minut)">
<node CREATED="1361450397056" ID="ID_1445723135" MODIFIED="1361450403863" TEXT="vypni hlidky">
<node CREATED="1361450314635" ID="ID_1026953908" MODIFIED="1361450421335" TEXT="proved pool">
<arrowlink DESTINATION="ID_59803788" ENDARROW="Default" ENDINCLINATION="-458;295;" ID="Arrow_ID_1152068593" STARTARROW="None" STARTINCLINATION="63;36;"/>
</node>
</node>
</node>
</node>
</map>