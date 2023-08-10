<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"	
	xmlns="http://www.w3.org/2005/xpath-functions"
	xmlns:map="http://www.w3.org/2005/xpath-functions"
	exclude-result-prefixes="map">
	
	<xsl:template match="map:map" mode="jskos">
		<xsl:param name="base"/>
		
		<xsl:for-each select="map:map[@key='_source']">

			<xsl:apply-templates select="map:array[@key='term']/map:map" mode="prefLabel"/>
			<xsl:apply-templates select="map:array[@key='description']/map:map" mode="scopeNote"/>
			<xsl:apply-templates select="map:array[@key='parent']" mode="broader"/>
			<xsl:apply-templates select="map:array[@key='@hierarchy']/map:array[1]" mode="ancestors"/> <!-- only one set of ancestor concepts allowed by JSKOS -->
			<xsl:apply-templates select="map:array[@key='@hierarch']" mode="inScheme"/>
			<xsl:apply-templates select="map:array[@key='coordinates']/map:map" mode="location"/>		
		</xsl:for-each>
	</xsl:template>
	
	<xsl:template match="map:map" mode="prefLabel">
		<xsl:if test="map:boolean[@key='primary'][.=true()]">
			<map key="prefLabel">
				<xsl:call-template name="process-node">
					<xsl:with-param name="key" select="'en'"/>
					<xsl:with-param name="node" select="map:string[@key='value']"/>
				</xsl:call-template>
			</map>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="map:map" mode="scopeNote">
		<xsl:if test="map:string[@key='status'][.='Active']">
			<map key="scopeNote">
				<array key="en">
					<string><xsl:value-of select="map:string[@key='value']"/></string>
				</array>
			</map>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="map:array" mode="broader">
		<xsl:if test="map:map">
			<array key="broader">
				<xsl:apply-templates select="map:map" mode="jskos-concept"/>
			</array>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="map:array" mode="ancestors">
		<array key="ancestors">
			<xsl:call-template name="broader-concepts">
				<xsl:with-param name="concepts" select="map:map"/>
			</xsl:call-template>
		</array>
	</xsl:template>
	
	<xsl:template match="map:array" mode="inScheme">
		<array key="inScheme">
			<xsl:apply-templates select="map:map" mode="jskos-concept"/>
		</array>
	</xsl:template>
	
	<xsl:template match="map:map" mode="jskos-concept">
		<map>
			<xsl:call-template name="linked-url">
				<xsl:with-param name="target-path" select="'uri'"/>
			</xsl:call-template>
			<map key="prefLabel">
				<xsl:call-template name="process-node">
					<xsl:with-param name="key" select="'en'"/>
					<xsl:with-param name="node" select="map:map[@key='summary']/map:string[@key='title']"/>
				</xsl:call-template>
			</map>
		</map>
	</xsl:template>
	
	<xsl:template match="map:map" mode="location">
		<xsl:if test="map:string[@key='format'][.='decimal degrees']">
			<xsl:if test="contains(map:string[@key='value'], ',')">
				<map key="location">
					<string key="type">Point</string>
					<array key="coordinates">
						<number><xsl:value-of select="substring-after(map:string[@key='value'], ',')"/></number>
						<number><xsl:value-of select="substring-before(map:string[@key='value'], ',')"/></number>
					</array>
				</map>
			</xsl:if>
		</xsl:if>
	</xsl:template>
	
	<!-- CIIM outputs concepts from general to specific, so we reverse the order here: -->
	<xsl:template name="broader-concepts">
		<xsl:param name="concepts"/>
		<xsl:variable name="this-concept" select="$concepts[1]"/>
		<xsl:variable name="other-concepts" select="$concepts[position() &gt; 1]"/>
		<!-- this design 'loses' the last concept, which is always the current concept, i.e. not broader nor an ancestor: -->
		<xsl:if test="$other-concepts">
			<xsl:call-template name="broader-concepts">
				<xsl:with-param name="concepts" select="$other-concepts"/>
			</xsl:call-template>
			<xsl:for-each select="$this-concept">
				<map>
					<xsl:call-template name="linked-url">
						<xsl:with-param name="target-path" select="'uri'"/>
					</xsl:call-template>
					<map key="prefLabel">
						<xsl:call-template name="process-node">
							<xsl:with-param name="key" select="'en'"/>
							<xsl:with-param name="node" select="map:map[@key='summary']/map:string[@key='title']"/>
						</xsl:call-template>
					</map>
				</map>
			</xsl:for-each>
		</xsl:if>
	</xsl:template>
	
	<!-- CIIM outputs concepts from general to specific, so we pick off the next to last here as a node list, and check that each is the first
			with that particular UID: -->
	<!--xsl:template name="output-broader-concepts">
		<xsl:param name="broader-concepts"/>
		<xsl:for-each select="$broader-concepts">
			<xsl:variable name="this-uid" select="key('map-with-uid', map:map[@key='@admin']/map:string[@key='uid'])"/>
			<xsl:if test="count($this-uid[ancestor::map:array[@key='@hierarchy']][1]|.) = 1">
				<map>
					<xsl:call-template name="linked-url">
						<xsl:with-param name="target-path" select="'uri'"/>
					</xsl:call-template>
					<map key="prefLabel">
						<xsl:call-template name="process-node">
							<xsl:with-param name="key" select="'en'"/>
							<xsl:with-param name="node" select="map:map[@key='summary']/map:string[@key='title']"/>
						</xsl:call-template>
					</map>
				</map>
			</xsl:if>
		</xsl:for-each>
	</xsl:template-->
	
</xsl:stylesheet>