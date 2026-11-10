<!--
	AD1259 - Vlach Culture : settlement patch.

	How it works: Bannerlord applies an .xslt file to the Settlements data merged from all
	previously loaded modules (Native ... AD1259), then merges the .xml file with the same
	name (vlach_settlements.xml, intentionally empty). AD1259's files are never modified.

	Effect: the settlements below get the Vlach culture. Owners, buildings and everything
	else stay as AD1259 defines them. A settlement's culture decides which notables spawn
	there (Vlach templates and Romanian names) and which troops its volunteers offer.

	Note: Pitesti, Balti, Kellia and Mauricastro remain owned by Bulgaria's royal clan
	(Bulgarian culture), so they get the vanilla "Owner Culture" loyalty penalty
	(-3 per day). This was a deliberate design choice; see docs/DESIGN.md.
-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output omit-xml-declaration="yes"/>

	<!-- Identity: copy everything unchanged... -->
	<xsl:template match="@*|node()">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>

	<!-- ...except the culture of these settlements. -->
	<xsl:template match="Settlement[
		  @id='town_bacau' or @id='town_giurgiu' or @id='town_pitesti'
		or @id='town_balti' or @id='town_kellia' or @id='town_mauricastro'
		or @id='town_bacau_suceava' or @id='town_bacau_husi' or @id='town_bacau_barlad'
		or @id='town_giurgiu_colentina' or @id='town_giurgiu_turnu'
		or @id='town_pitesti_craiova' or @id='town_pitesti_corabla'
		or @id='town_balti_soroca'
		or @id='town_kellia_oblucita' or @id='town_kellia_palada'
		or @id='town_mauricastro_orhei' or @id='town_mauricastro_causeni'
		or @id='castle_soimos_hunyad' or @id='castle_kraszna_doboka'
		or @id='town_gyulafehervar_cluj' or @id='town_gyulafehervar_kukullovar'
		or @id='castle_kronstadt_prazsmar'
		]/@culture">
		<xsl:attribute name="culture">Culture.vlach</xsl:attribute>
	</xsl:template>
</xsl:stylesheet>
