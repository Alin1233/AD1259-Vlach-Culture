<!--
	AD1259 - Vlach Culture : clan patch (applied to the merged Factions data, see
	vlach_settlements.xslt for how .xslt patches work).

	Effect: the clan "Vlachs of Muntenia and Oltenia" (clan_bulgaria_3) gets the Vlach
	culture. It stays a vassal clan of the Kingdom of Bulgaria (super_faction unchanged).
	A clan's culture decides the troops its lords start with and recruit.
-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output omit-xml-declaration="yes"/>

	<xsl:template match="@*|node()">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template match="Faction[@id='clan_bulgaria_3']/@culture">
		<xsl:attribute name="culture">Culture.vlach</xsl:attribute>
	</xsl:template>
</xsl:stylesheet>
