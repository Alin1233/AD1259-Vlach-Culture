<!--
	AD1259 - Vlach Culture : noble patch (applied to the merged NPCCharacters data, see
	vlach_settlements.xslt for how .xslt patches work).

	Effect: the eight nobles of the clan "Vlachs of Muntenia and Oltenia" get the Vlach
	culture (their children are then born Vlach and get Romanian names), and two names are
	given their Romanian form. Faces, equipment, traits and family ties are unchanged.
-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output omit-xml-declaration="yes"/>

	<xsl:template match="@*|node()">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template match="NPCCharacter[
		  @id='lord_bulgaria_3a' or @id='lord_bulgaria_3b' or @id='lord_bulgaria_3c' or @id='lord_bulgaria_3d'
		or @id='lord_bulgaria_3e' or @id='lord_bulgaria_3f' or @id='lord_bulgaria_3g' or @id='lord_bulgaria_3h'
		]/@culture">
		<xsl:attribute name="culture">Culture.vlach</xsl:attribute>
	</xsl:template>

	<!-- "Johannes" is the Latin spelling used in the 1247 Diploma of the Knights Hospitaller. -->
	<xsl:template match="NPCCharacter[@id='lord_bulgaria_3c']/@name">
		<xsl:attribute name="name">{=ad1259vlach_lord_bulgaria_3c}Ioan, Kenez of South Oltenia</xsl:attribute>
	</xsl:template>

	<xsl:template match="NPCCharacter[@id='lord_bulgaria_3f']/@name">
		<xsl:attribute name="name">{=ad1259vlach_lord_bulgaria_3f}Eufrosina</xsl:attribute>
	</xsl:template>
</xsl:stylesheet>
