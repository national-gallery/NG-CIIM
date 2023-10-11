<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns="http://www.w3.org/2005/xpath-functions"
	xmlns:map="http://www.w3.org/2005/xpath-functions"
	exclude-result-prefixes="map">
	<xsl:output method="text" media-type="application/json" encoding="UTF-8"/>
	<xsl:param name="file"/>
	<xsl:include href="./ng-json-library.xsl"/>
	<xsl:include href="./ng-linked-art-library.xsl"/>
	<xsl:include href="./ng-jskos-library.xsl"/>
	<xsl:include href="./ng-bibframe-library.xsl"/>
	<xsl:variable name="doc" select="json-to-xml(unparsed-text($file))"/>
  
	<xsl:template match="/">    
		<xsl:variable name="output">
			<array xmlns="http://www.w3.org/2005/xpath-functions">
				<xsl:for-each select="$doc/*">
					<map>            
						<xsl:for-each select="map:map[@key='hits']/map:array[@key='hits']/map:map[1]">
							
							<!-- Pick up value of hits.hits[0]._source.@datatype.base -->
							<xsl:variable name="base" select="map:map[@key='_source']/map:map[@key='@datatype']/map:string[@key='base']"/>
							<xsl:variable name="actual-datatype" select="map:map[@key='_source']/map:map[@key='@datatype']/map:string[@key='actual']"/>
							<xsl:variable name="target">
								<xsl:call-template name="target-format">
									<xsl:with-param name="base" select="$base"/>
								</xsl:call-template>
							</xsl:variable>
							<xsl:call-template name="context">
								<xsl:with-param name="target" select="$target"/>
							</xsl:call-template>
							<xsl:call-template name="record-id">
								<xsl:with-param name="target" select="$target"/>
							</xsl:call-template>
							<xsl:call-template name="record-type">
								<xsl:with-param name="target" select="$target"/>
								<xsl:with-param name="base" select="$base"/>
								<xsl:with-param name="actual-datatype" select="$actual-datatype"/>
							</xsl:call-template>
							<xsl:choose>
								<xsl:when test="$target='linked-art'">
									<xsl:apply-templates select="." mode="linked-art">
										<xsl:with-param name="base" select="$base"/>
										<xsl:with-param name="actual-datatype" select="$actual-datatype"/>
									</xsl:apply-templates>
								</xsl:when>
								<xsl:when test="$target='jskos'">
									<xsl:apply-templates select="." mode="jskos">
										<xsl:with-param name="base" select="$base"/>										
									</xsl:apply-templates>
								</xsl:when>
								<xsl:when test="$target='bibframe'">
									<xsl:apply-templates select="." mode="bibframe">										
										<xsl:with-param name="base" select="$base"/>
									</xsl:apply-templates>
								</xsl:when>
							</xsl:choose>							
						</xsl:for-each>
					</map>
				</xsl:for-each>
				<!-- all this code is [just] to support the possible JSKOS mapping of one concept to others
						(because it's a separate map in the top-level array): -->
				<xsl:for-each select="$doc/*">
					<xsl:for-each select="map:map[@key='hits']/map:array[@key='hits']/map:map[1]">
						<xsl:variable name="base" select="map:map[@key='_source']/map:map[@key='@datatype']/map:string[@key='base']"/>
						<xsl:variable name="target">
							<xsl:call-template name="target-format">
								<xsl:with-param name="base" select="$base"/>
							</xsl:call-template>
						</xsl:variable>
						<xsl:if test="$target='jskos'">
							<xsl:apply-templates select="map:map[@key='_source']/map:array[@key='identifier']" mode="exact-match">
								<xsl:with-param name="record-id" select="map:string[@key='_id']"/>
								<xsl:with-param name="target" select="$target"/>
							</xsl:apply-templates>
						</xsl:if>
					</xsl:for-each>
				</xsl:for-each>
			</array>
		</xsl:variable>
		<xsl:value-of select="xml-to-json($output)"/>
		<!-- to debug JSON serialization errors, set output type to XML and use this command instead of the line above: -->
		<!--xsl:copy-of select="$output"/-->              		
	</xsl:template>
	
	<xsl:template name="target-format">
		<xsl:param name="base"/>
		<xsl:choose>
			<xsl:when test="$base='concept' or $base='place'">jskos</xsl:when>
			<xsl:when test="$base='object' or $base='agent' or $base='package' or $base='event'">linked-art</xsl:when>
			<xsl:when test="$base='publication'">bibframe</xsl:when>
			<xsl:otherwise><xsl:message>Unhandled base type: <xsl:value-of select="$base"/></xsl:message></xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!-- only operate on elements with a specific key: -->
	<xsl:template match="map:map" mode="#all" priority="-1"/>
	<xsl:template match="map:string" mode="#all" priority="-1"/>
	<xsl:template match="map:array" mode="#all" priority="-1"/>
	<xsl:template match="text()" mode="#all" priority="-1"/>
	
</xsl:stylesheet>
