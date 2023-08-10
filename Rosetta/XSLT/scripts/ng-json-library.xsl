<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/2005/xpath-functions"
  xmlns:map="http://www.w3.org/2005/xpath-functions"
  exclude-result-prefixes="map">
  
	<!-- library of generally useful named templates and templates-in-modes,  for processing
			National Gallery CIIM output and generating Linked Data results. -->

  <xsl:variable name="ng-prefix" select="'https://data.ng.ac.uk/'"/>
  
  <xsl:key name="map-with-uid" match="map:map" use="map:map[@key='@admin']/map:string[@key='uid']"/>

  <!-- general templates: now hived off into a separate 'library' file: -->
  
  <xsl:template name="find-and-process">
    <xsl:param name="path"/>
    <xsl:param name="key"/>
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>
    <xsl:param name="transform"/>
    <xsl:param name="node" select="."/>
    <xsl:if test="$node">
      <xsl:variable name="next-path">
        <xsl:choose>
          <xsl:when test="contains($path, '.')">
            <xsl:value-of select="substring-before($path, '.')"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$path"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:choose>
        <xsl:when test="starts-with($next-path, '[') and (local-name($node) = 'array')">
          <xsl:variable name="offset" select="number(substring-before(substring-after($next-path, '['), ']')) + 1"/>
          <xsl:choose>
            <xsl:when test="contains($path, '.')">
              <xsl:call-template name="find-and-process">
                <xsl:with-param name="path" select="substring-after($path, '.')"/>
                <xsl:with-param name="key" select="$key"/>
                <xsl:with-param name="prefix" select="$prefix"/>
                <xsl:with-param name="suffix" select="$suffix"/>
                <xsl:with-param name="transform" select="$transform"/>
                <xsl:with-param name="node" select="$node/*[position()=$offset]"/>
              </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="process-node">
              <xsl:with-param name="key" select="$key"/>
              <xsl:with-param name="prefix" select="$prefix"/>
              <xsl:with-param name="suffix" select="$suffix"/>
              <xsl:with-param name="transform" select="$transform"/>
              <xsl:with-param name="node" select="$node"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="contains($path, '.')">
            <xsl:call-template name="find-and-process">
              <xsl:with-param name="path" select="substring-after($path, '.')"/>
              <xsl:with-param name="key" select="$key"/>
              <xsl:with-param name="prefix" select="$prefix"/>
              <xsl:with-param name="suffix" select="$suffix"/>
              <xsl:with-param name="transform" select="$transform"/>
              <xsl:with-param name="node" select="$node/*[@key=$next-path]"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="process-node">
              <xsl:with-param name="key" select="$key"/>
              <xsl:with-param name="prefix" select="$prefix"/>
              <xsl:with-param name="suffix" select="$suffix"/>
              <xsl:with-param name="transform" select="$transform"/>
              <xsl:with-param name="node" select="$node/*[@key=$next-path]"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
    </xsl:if>
  </xsl:template>
  
  <xsl:template name="find-node">
    <xsl:param name="path"/>
    <xsl:param name="node" select="."/>
    <xsl:if test="$node">
      <xsl:variable name="next-path">
        <xsl:choose>
          <xsl:when test="contains($path, '.')">
            <xsl:value-of select="substring-before($path, '.')"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$path"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:choose>
        <xsl:when test="starts-with($next-path, '[') and (local-name($node) = 'array')">
          <xsl:variable name="offset" select="number(substring-before(substring-after($next-path, '['), ']')) + 1"/>
          <xsl:choose>
            <xsl:when test="contains($path, '.')">
              <xsl:call-template name="find-node">
                <xsl:with-param name="path" select="substring-after($path, '.')"/>
                <xsl:with-param name="node" select="$node/*[position()=$offset]"/>
              </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$node/*[@key=$path]"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="contains($path, '.')">
            <xsl:call-template name="find-node">
              <xsl:with-param name="path" select="substring-after($path, '.')"/>
              <xsl:with-param name="node" select="$node/*[@key=$next-path]"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
              <xsl:value-of select="$node/*[@key=$path]"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
    </xsl:if>
  </xsl:template>
  
  <xsl:template name="process-node">
    <xsl:param name="key"/>
    <xsl:param name="prefix"/>
    <xsl:param name="suffix"/>
    <xsl:param name="transform"/>
    <xsl:param name="node"/>
    <!--xsl:variable name="pre">
      <xsl:if test="string($prefix)">
        <xsl:value-of select="concat($prefix, ' ')"/>
      </xsl:if>
    </xsl:variable>
    <xsl:variable name="post">
      <xsl:if test="string($suffix)">
        <xsl:value-of select="concat(' ', $suffix)"/>
      </xsl:if>
    </xsl:variable-->
    <xsl:variable name="output-node">
      <xsl:choose>
        <xsl:when test="$transform='language-url'">
          <xsl:call-template name="language-url">
            <xsl:with-param name="node" select="$node/text()"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="$transform='strip-trailing-chars'">
          <xsl:call-template name="strip-trailing-chars">
            <xsl:with-param name="s" select="$node/text()"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="$transform='dimensions-to-string'">
          <xsl:for-each select="$node/map:map">
            <xsl:if test="position() &gt; 1">; </xsl:if>
            <xsl:value-of select="concat(map:string[@key='dimension'], ': ', map:number[@key='value'], ' ', map:string[@key='units'])"/>
          </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$node/text()"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="pre">
      <xsl:if test="string($prefix)">
        <xsl:choose>
          <xsl:when test="starts-with($prefix, 'http')">
            <xsl:value-of select="$prefix"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="concat($prefix, ' ')"/>
          </xsl:otherwise>
        </xsl:choose>        
      </xsl:if>
    </xsl:variable>
    <xsl:variable name="post">
      <xsl:if test="string($suffix)">
        <xsl:value-of select="concat(' ', $suffix)"/>
      </xsl:if>
    </xsl:variable>    
    <xsl:if test="$node">
      <string key="{$key}"><xsl:value-of select="concat($pre, $output-node, $post)"/></string>
    </xsl:if>
  </xsl:template>
  
  <xsl:variable name="uc" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'"/>
  <xsl:variable name="lc" select="'abcdefghijklmnopqrstuvwxyz'"/>
  
  <xsl:template name="language-url">
    <xsl:param name="node"/>
    <xsl:if test="string($node)">
      <xsl:value-of select="concat('http://id.loc.gov/vocabulary/languages/', substring(translate($node, $uc, $lc), 1, 3))"/>
    </xsl:if>
  </xsl:template>
  
  <xsl:template name="process-node-as-number">
    <xsl:param name="key"/>
    <xsl:param name="node"/>
    <xsl:if test="$node">
      <number key="{$key}"><xsl:value-of select="$node/text()"/></number>
    </xsl:if>
  </xsl:template>
    
  <xsl:template name="strip-trailing-chars">
    <xsl:param name="s" select="."/>
    <xsl:if test="string($s)">
      <xsl:variable name="last-char" select="substring($s, string-length($s), 1)"/>
      <xsl:choose>
        <xsl:when test="$last-char=' ' or $last-char='/' or $last-char='.' or $last-char=';' or $last-char=':'">
          <xsl:call-template name="strip-trailing-chars">
            <xsl:with-param name="s" select="substring($s, 1, string-length($s)-1)"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$s"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>
  
  <xsl:template name="context">
    <xsl:param name="target"/>
    <xsl:choose>
      <xsl:when test="$target='linked-art'">
        <string key="@context">https://linked.art/ns/v1/linked-art.json</string>        
      </xsl:when>
      <xsl:when test="$target='jskos'">
        <string key="@context">http://richardofsussex.me.uk/ng/jskos.json</string>
      </xsl:when>
      <xsl:when test="$target='bibframe'">
        <string key="@context">http://richardofsussex.me.uk/ng/bibframe-context.json</string>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="record-id">
    <xsl:param name="target"/>
    <xsl:choose>
      <xsl:when test="$target='linked-data'">
        <xsl:call-template name="find-and-process">
          <xsl:with-param name="path" select="'_id'"/>
          <xsl:with-param name="key" select="'id'"/>
          <xsl:with-param name="prefix" select="$ng-prefix"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="$target='jskos'">
        <xsl:call-template name="find-and-process">
          <xsl:with-param name="path" select="'_id'"/>
          <xsl:with-param name="key" select="'uri'"/>
          <xsl:with-param name="prefix" select="$ng-prefix"/>
        </xsl:call-template>        
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="record-type">
    <xsl:param name="target"/>
    <xsl:param name="base"/>
    <xsl:param name="actual-datatype"/>
    <xsl:choose>
      <xsl:when test="$target='linked-art'">
        <string key="type">
          <xsl:choose>
            <xsl:when test="$base='agent'">
              <xsl:choose>
                <xsl:when test="$actual-datatype='Individual'">Person</xsl:when>
                <xsl:when test="$actual-datatype='Organisation'">Group</xsl:when>
                <xsl:otherwise>Agent</xsl:otherwise>
              </xsl:choose>
            </xsl:when>
            <xsl:when test="$base='event'">Event</xsl:when>
            <xsl:when test="$base='package'">Set</xsl:when>
            <xsl:when test="$target='linked-art'">HumanMadeObject</xsl:when>
          </xsl:choose>
        </string>
      </xsl:when>
      <xsl:when test="$target='jskos'">
        <array key="type">
          <string>https://gbv.github.io/jskos/context.json</string>
        </array>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="linked-url">
    <xsl:param name="target-path" select="'id'"/>
    <!--xsl:param name="endpoint-path"/>
    <xsl:variable name="path">
    <xsl:choose>
      <xsl:when test="string($endpoint-path)">
        <xsl:value-of select="$endpoint-path"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="substring-before(map:map[@key='@admin']/map:string[@key='id'], '-')"/>
      </xsl:otherwise>
    </xsl:choose>
    </xsl:variable-->
    <xsl:call-template name="find-and-process">
      <xsl:with-param name="path" select="'@admin.uid'"/>
      <xsl:with-param name="key" select="$target-path"/>
      <!--xsl:with-param name="prefix" select="concat($ng-prefix, $path, '/')"/-->
      <xsl:with-param name="prefix" select="$ng-prefix"/>
    </xsl:call-template>
  </xsl:template>
	
</xsl:stylesheet>