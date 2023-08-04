<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/2005/xpath-functions"
  xmlns:map="http://www.w3.org/2005/xpath-functions"
  exclude-result-prefixes="map">
      
  <xsl:template match="map:map" mode="bibframe">    
          <map>

              <!-- id: [string Required] The value MUST be the HTTP(S) URI at which the publication's 
										representation can be dereferenced -->
              <xsl:call-template name="publication-id"/>
								
              <xsl:call-template name="publication-type"/>
              
              <!-- process the contents of the _source key, which contains the bulk of the info: -->
              <xsl:for-each select="map:map[@key='_source']">								
								
                <xsl:call-template name="work-metadata"/>
                
                <xsl:call-template name="instance-title"/>
                
                <xsl:call-template name="instance-contributor-metadata"/>
                
                <xsl:call-template name="instance-metadata"/>
                
                <xsl:call-template name="instance-provision"/>
                
                <xsl:call-template name="instance-parts"/>
                
                <xsl:call-template name="instance-notes"/>
                
                <xsl:call-template name="item-details"/>
                
                <xsl:call-template name="holding-section"/>
                
                <xsl:call-template name="related-works"/>
                
              </xsl:for-each>
          </map>
	
  </xsl:template>
	
	<!-- top-level templates: -->
  
  <xsl:template name="publication-id">
    <xsl:call-template name="find-and-process">
      <xsl:with-param name="path" select="'_id'"/>
      <xsl:with-param name="key" select="'id'"/>
      <!--xsl:with-param name="prefix" select="concat($ng-prefix, 'publication/')"/-->
      <xsl:with-param name="prefix" select="$ng-prefix"/>
    </xsl:call-template>
  </xsl:template>
  
  <xsl:template name="publication-type">
    <string key="type">Instance</string>
  </xsl:template>

  <xsl:template name="get-source-system">
    <xsl:value-of select="ancestor-or-self::map:map[@key='_source']/map:map[@key='@admin']/map:string[@key='source']"/>
  </xsl:template>  
  
  <!-- top-level properties: -->
  
<xsl:template name="work-metadata">
  <map key="instanceOf">
    <map key="Work">
      <xsl:call-template name="instance-title"/>
      <xsl:call-template name="work-contributor-metadata"/>
      <xsl:call-template name="work-summary"/>
      <xsl:call-template name="admin-metadata"/>
      <xsl:call-template name="content-metadata"/>
      <xsl:call-template name="table-of-contents"/>
      <xsl:call-template name="subjects"/>
    </map>
  </map>
</xsl:template>

<xsl:template name="work-summary">
  <xsl:if test="map:array[@key='description']">
    <map key="summary">
      <array key="Summary">
        <xsl:apply-templates select="map:array[@key='description']/map:map" mode="summary"/>
      </array>
    </map>
  </xsl:if>
</xsl:template>

<xsl:template name="instance-contributor-metadata">
  <map key="contribution">
    <array key="Contribution">
      <xsl:call-template name="instance-agents"/>
    </array>
  </map>
</xsl:template>
  
<xsl:template name="work-contributor-metadata">
  <xsl:if test="map:map[@key='work'] or map:array[@key='agent' or @key='organisation' or @key='subject']">
    <map key="contribution">
      <array key="Contribution">
        <xsl:call-template name="work-agents"/>
      </array>
    </map>
  </xsl:if>
</xsl:template>

<xsl:template name="admin-metadata">
  <xsl:if test="map:array[@key='agency']">
    <map key="adminMetadata">
      <map key="AdminMetadata">
        <xsl:call-template name="description-language"/>
        <xsl:call-template name="agencies"/>
      </map>
    </map>
  </xsl:if>
</xsl:template>
  
  <xsl:template name="content-metadata">
    <xsl:call-template name="content-form"/>
  </xsl:template>
  
  <xsl:template name="table-of-contents">
    <xsl:variable name="source-system">
    </xsl:variable>
    <!--xsl:message>Source system is <xsl:value-of select="$source-system"/></xsl:message-->
    <xsl:choose>
      <xsl:when test="$source-system='eos'">
        <xsl:if test="map:array[@key='contents']/map:map[map:string[@key='@tag'][.='505']]">
          <map key="tableOfContents">
            <array key="TableOfContents">
              <xsl:apply-templates select="map:array[@key='contents']/map:map[map:string[@key='@tag'][.='505']]" mode="string"/>
            </array>
          </map>
        </xsl:if>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template name="identifier-types">
    <xsl:param name="type"/>
    <xsl:choose>
      <xsl:when test="translate($type, $uc, $lc)='isbn'">Isbn</xsl:when>
      <xsl:otherwise>Identifier</xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- Subject terms: need to add code to support the other subject codes - only 650 is supported at present.
         Mappings are:
           - 630 -> subject - Hub
           - 648 -> subject - Temporal
           - 651 -> subject - Place
           - 653 -> subject (uncontrolled)
           - 655 -> genreform - GenreForm (this is treated spearately below)
           - 656 -> subject - Topic [occupation]
           - 662 -> subject - Place
  -->
  <xsl:template name="subjects">
    <xsl:variable name="source-system">
      <xsl:call-template name="get-source-system"/>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$source-system='eos'">
        <xsl:if test="map:array[@key='subject']/map:map[map:string[@key='@tag'][.='650' or .='630' or .='648' or .='651' or .='653' or .='656' or .='662']]">
          <map key="subject">
            <xsl:if test="map:array[@key='subject']/map:map[map:string[@key='@tag'][.='650']]">
              <array key="Topic">
                <xsl:apply-templates select="map:array[@key='subject']/map:map[map:string[@key='@tag'][.='650']]" mode="topic"/>
              </array>
            </xsl:if>
          </map>
        </xsl:if>
        <xsl:if test="map:array[@key='subject']/map:map[map:string[@key='@tag'][.='655']]">
          <map key="genreform">
            <array key="GenreForm">
              <xsl:apply-templates select="map:array[@key='subject']/map:map[map:string[@key='@tag'][.='655']]" mode="topic"/>  
            </array>
          </map>
        </xsl:if>
      </xsl:when>
      <xsl:when test="$source-system='tms'">
        <!-- need to implement subjects as recorded in TMS: -->
      </xsl:when>
      <xsl:otherwise>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template name="instance-title">
    <array key="title">
      <map>
        <xsl:call-template name="find-and-process">
          <xsl:with-param name="path" select="'summary.title'"/>
          <xsl:with-param name="key" select="'Title'"/>
        </xsl:call-template>
      </map>
      <xsl:apply-templates select="map:array[@key='title']/map:map" mode="bf-title"/>
    </array>
  </xsl:template>
  
  <xsl:template name="instance-metadata">
    <xsl:call-template name="identifiers"/>
    <xsl:call-template name="media-type"/>
    <xsl:call-template name="carrier-data"/>
    <xsl:call-template name="physical-description"/>
  </xsl:template>
  
  <xsl:template name="instance-provision">
    <xsl:apply-templates select="map:map[@key='creation']" mode="provision"/>
  </xsl:template>
  
  <xsl:template name="instance-parts">
    <xsl:apply-templates select="map:array[@key='multimedia']" mode="hasPart"/>
  </xsl:template>
  
  <xsl:template name="identifiers">
    <array key="identifiedBy">
      <xsl:apply-templates select="map:array[@key='identifier']/map:map" mode="bf-identifier"/>
    </array>
  </xsl:template>
  
  <xsl:template name="media-type">
    <xsl:if test="map:array[@key='media']/map:map">
      <map key="media">
        <array key="Media">
          <xsl:apply-templates select="map:array[@key='media']/map:map" mode="string"/>
        </array>
      </map>
    </xsl:if>
  </xsl:template>
  
  <xsl:template name="carrier-data">
    <xsl:if test="map:array[@key='carrier']/map:map">
      <map key="carrier">
        <array key="Carrier">
          <xsl:apply-templates select="map:array[@key='carrier']/map:map" mode="string"/>
        </array>
      </map>
    </xsl:if>
  </xsl:template>
  
  <xsl:template name="physical-description">
    <xsl:for-each select="map:map[@key='measurements']">
      <xsl:call-template name="dimensions"/>
      <xsl:call-template name="extent"/>
    </xsl:for-each>
  </xsl:template>
  
  <xsl:template name="instance-notes">
    <map key="note">
      <array key="Note">
        <xsl:call-template name="general-notes"/>
        <xsl:call-template name="other-physical-details"/>
      </array>
    </map>
  </xsl:template>
  
  <xsl:template name="item-details">
    <xsl:for-each select="map:array[@key='item']">
      <array key="hasItem">
        <xsl:apply-templates select="map:map" mode="item"/>
      </array>
    </xsl:for-each>
  </xsl:template>
  
    <xsl:template name="holding-section">
      <xsl:apply-templates select="map:map[@key='holdings']/map:string[@key='section']" mode="held-by"/>
    </xsl:template>
    
    <xsl:template name="related-works">
      <xsl:if test="map:array[@key='related']">
        <array key="relatedTo">
          <xsl:apply-templates select="map:array[@key='related']/map:map" mode="related-work"/>
        </array>
      </xsl:if>      
    </xsl:template>

  <!-- low-level properties: -->
  
  <xsl:template name="description-language">
    <array key="descriptionLanguage">
      <map>
        <xsl:call-template name="find-and-process">
          <xsl:with-param name="path" select="'agency.[0].language.[0].value'"/>
          <xsl:with-param name="key" select="'Language'"/>
          <xsl:with-param name="transform" select="'language-url'"/>
        </xsl:call-template>
      </map>
    </array>
  </xsl:template>
  
  <xsl:template name="work-agents">
    <xsl:apply-templates select="map:map[@key='work']/map:map[@key='creation']/map:array[@key='maker']/map:map" mode="agent"/>
    <xsl:apply-templates select="map:array[@key='agent']/map:map" mode="agent"/>
    <xsl:apply-templates select="map:array[@key='organisation']/map:map" mode="agent"/>
    <xsl:apply-templates select="map:array[@key='subject']/map:map[map:string[@key='@tag'][.='600' or .='610' or .='611']]" mode="agent"/>
  </xsl:template>
  
  <xsl:template name="instance-agents">
    <xsl:apply-templates select="map:map[@key='creation']/map:array[@key='maker']/map:map" mode="agent"/>
    <xsl:apply-templates select="map:array[@key='agent']/map:map" mode="agent"/>
    <xsl:apply-templates select="map:array[@key='organisation']/map:map" mode="agent"/>
    <xsl:apply-templates select="map:array[@key='subject']/map:map[map:string[@key='@tag'][.='600' or .='610' or .='611']]" mode="agent"/>
  </xsl:template>
  
  <xsl:template name="agencies">
    <xsl:apply-templates select="map:array[@key='agency']/map:map" mode="agency"/>
  </xsl:template>
  
  <xsl:template name="content-form">
    <xsl:if test="map:array[@key='classification']/map:map">
      <map key="content">
        <array key="Content">
          <xsl:apply-templates select="map:array[@key='classification']/map:map" mode="content"/>
        </array>
      </map>
    </xsl:if>
  </xsl:template>
  
  <xsl:template name="dimensions">
    <array key="dimensions">
      <xsl:apply-templates select="map:array[@key='dimensions']/map:map" mode="bf-dimension"/>
    </array>
  </xsl:template>
  
  <xsl:template name="extent">
    <map key="extent">
      <string key="Extent">
        <xsl:apply-templates select="map:array[@key='extent']/map:string"/>
      </string>
    </map>
  </xsl:template>
  
  <xsl:template name="general-notes">
    <xsl:apply-templates select="map:array[@key='note']/map:map" mode="note"/>
    <xsl:apply-templates select="map:map[@key='event']/map:map[@key='label']" mode="note"/>    
  </xsl:template>
  
  <xsl:template name="other-physical-details">
    <xsl:for-each select="map:map[@key='measurements']">
      <xsl:if test="map:array[@key='other']/map:string">
        <map>
          <string key="type">http://id.loc.gov/vocabulary/mnotetype/physical</string>
          <string key="label">
            <xsl:apply-templates select="map:array[@key='other']/map:string"/>
          </string>
        </map>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>
  
  <!-- specific modes of processing maps, arrays and strings: -->
  
  <xsl:template match="map:map" mode="agent">
    <xsl:variable name="source-system">
      <xsl:call-template name="get-source-system"/>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$source-system='eos'">
        <xsl:variable name="marc-code" select="map:string[@key='@tag']"/>
        <xsl:variable name="agent-type">
          <xsl:choose>
            <xsl:when test="$marc-code='100' or $marc-code='600' or $marc-code='700' or $marc-code='800'">Person</xsl:when>
            <xsl:when test="$marc-code='110' or $marc-code='610' or $marc-code='710' or $marc-code='810'">Organization</xsl:when>
            <xsl:otherwise>Agent</xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="agent-role">
          <xsl:choose>
            <xsl:when test="string(map:map[@key='@link']/map:map[@key='relationship']/map:string[@key='value'])">
              <xsl:value-of select="map:map[@key='@link']/map:map[@key='relationship']/map:string[@key='value']"/>
            </xsl:when>
            <xsl:otherwise>http://id.loc.gov/vocabulary/relators/ctb</xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <map>
          <map key="role">
            <string key="Role"><xsl:value-of select="$agent-role"/></string>
          </map>
          <map key="agent">
            <array key="{$agent-type}">
              <map>
                <string key="label">
                  <xsl:apply-templates select="map:map[@key='name']/map:string[@key='value']" mode="strip-trailing-chars"/>
                </string>
              </map>
            </array>
          </map>
        </map>
      </xsl:when>
      <xsl:when test="$source-system='tms'">
        <!-- need to implement support for agents in TMS: -->
        <xsl:variable name="agent-type" select="'Agent'"/> <!-- can't deduce agent type from TMS data -->
        <xsl:variable name="agent-role">
          <xsl:choose>
            <xsl:when test="string(map:map[@key='@link']/map:array[@key='role']/map:map/map:string[@key='value'])">
              <xsl:value-of select="map:map[@key='@link']/map:array[@key='role']/map:map/map:string[@key='value']"/>
            </xsl:when>
            <xsl:otherwise>http://id.loc.gov/vocabulary/relators/ctb</xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <map>
          <map key="role">
            <string key="Role"><xsl:value-of select="$agent-role"/></string>
          </map>
          <map key="agent">
            <array key="{$agent-type}">
              <map>
                <xsl:call-template name="linked-url"/>
                <string key="label">
                  <xsl:apply-templates select="map:map[@key='summary']/map:string[@key='title']" mode="strip-trailing-chars"/>
                </string>
              </map>
            </array>
          </map>
        </map>
      </xsl:when>
      <xsl:otherwise></xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="map:map" mode="agent-only">
    <map>
      <xsl:call-template name="linked-url"/>
      <string key="label">
        <xsl:apply-templates select="map:map[@key='summary']/map:string[@key='title']" mode="strip-trailing-chars"/>
      </string>
    </map>
  </xsl:template>
  
  <xsl:template match="map:map" mode="agency">
    <xsl:variable name="agency-type" select="map:string[@key='type']"/>
    <xsl:choose>
      <xsl:when test="$agency-type='original cataloguing agency'">
        <map key="assigner">
          <array key="Agent">
            <xsl:for-each select="map:array[@key='name']/map:map/map:string[@key='value']">
              <string><xsl:value-of select="."/></string>
            </xsl:for-each>
          </array>
        </map>
      </xsl:when>
      <xsl:when test="$agency-type='modifying agency'">
        <map key="descriptionModifier">
          <array key="Agent">
            <xsl:for-each select="map:array[@key='name']/map:map/map:string[@key='value']">
              <string><xsl:value-of select="."/></string>
            </xsl:for-each>
          </array>
        </map>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="map:map" mode="content">
    <string><xsl:value-of select="map:string[@key='value']"/></string>
  </xsl:template>
  
  <xsl:template match="map:map" mode="bf-dimension">
    <string><xsl:value-of select="map:string[@key='value']"/></string>
  </xsl:template>
  
  <xsl:template match="map:string" mode="enumeration">
    <string key="enumerationAndChronology"><xsl:value-of select="."/></string>
  </xsl:template>
  
  <xsl:template match="map:array" mode="hasPart">
    <array key="hasPart">
      <xsl:apply-templates select="map:map" mode="part"/>
    </array>
  </xsl:template>
  
  <xsl:template match="map:string" mode="held-by">
    <string key="heldBy"><xsl:value-of select="."/></string>
  </xsl:template>

  <xsl:template match="map:map" mode="bf-identifier">
    <xsl:variable name="identifier-type">
      <xsl:call-template name="identifier-types">
        <xsl:with-param name="type" select="map:string[@key='type']"/>
      </xsl:call-template>
    </xsl:variable>
    <map>
      <string key='{$identifier-type}'>
        <xsl:value-of select="map:string[@key='value']"/>
      </string>
      <xsl:if test="$identifier-type = 'Identifier'">
        <string key="@type"><xsl:value-of select="map:string[@key='type']"/></string>
      </xsl:if>
      <xsl:apply-templates select="map:map[@key='note']" mode="note">
        <xsl:with-param name="inArray" select="false()"/>
      </xsl:apply-templates>
    </map>        
  </xsl:template>

  <xsl:template match="map:map" mode="item">
    <map>
      <!-- map location to heldBy; array member with type="shelf mark" to shelfMark: -->
      <xsl:apply-templates select="map:string[@key='copy']" mode="enumeration"/>
      <xsl:apply-templates select="map:string[@key='location']" mode="held-by"/>
      <xsl:apply-templates select="map:string[@key='status']" mode="sub-location"/>
      <xsl:if test="map:array[@key='identifier']/map:map[map:string='shelf mark']">
        <array key="shelfMark">
          <xsl:for-each select="map:array[@key='identifier']/map:map[map:string[@key='type'][translate(., $uc, $lc)='shelf mark']]">
            <string><xsl:value-of select="map:string[@key='value']"/></string>
          </xsl:for-each>
        </array>      
      </xsl:if>
    </map>
  </xsl:template>
  
  <xsl:template match="map:map" mode="bf-name">
    <map>
      <xsl:for-each select="map:string[@key='value']">
        <string key="label"><xsl:apply-templates select="." mode="strip-trailing-chars"/></string>
      </xsl:for-each>      
    </map>
  </xsl:template>
  
  <xsl:template match="map:array" mode="names">
    <map key="agent">
      <array key="Agent">
        <xsl:apply-templates select="map:map" mode="bf-name"/>
      </array>
    </map>
  </xsl:template>
  
  <xsl:template match="map:map" mode="note">
    <xsl:param name="inArray" select="true()"/>
    <xsl:choose>
      <xsl:when test="$inArray and map:string[@key='type'][.='general note']">
        <map>
          <string key="type">Note</string>
          <xsl:call-template name="find-and-process">
            <xsl:with-param name="path" select="'value'"/>
            <xsl:with-param name="key" select="'label'"/>            
          </xsl:call-template>
          <!--string key="label"><xsl:value-of select="map:string[@key='value']"/></string-->
        </map>
      </xsl:when>
      <xsl:when test="$inArray">
        <map>
          <string key="type">Note</string>
          <xsl:call-template name="find-and-process">
            <xsl:with-param name="path" select="'type'"/>
            <xsl:with-param name="key" select="'noteType'"/>            
          </xsl:call-template>
          <!--xsl:if test="map:string[@key='type']">
            <string key="noteType"><xsl:value-of select="map:string[@key='type']"/></string>
          </xsl:if-->
          <xsl:call-template name="find-and-process">
            <xsl:with-param name="path" select="'value'"/>
            <xsl:with-param name="key" select="'label'"/>            
          </xsl:call-template>
          <!--string key="label"><xsl:value-of select="map:string[@key='value']"/></string-->
        </map>
      </xsl:when>
      <xsl:otherwise>
        <map key="note">
          <map key="Note">
            <xsl:call-template name="find-and-process">
              <xsl:with-param name="path" select="'type'"/>
              <xsl:with-param name="key" select="'noteType'"/>            
            </xsl:call-template>
            <!--xsl:if test="map:string[@key='type']">
              <string key="noteType"><xsl:value-of select="map:string[@key='type']"/></string>
            </xsl:if-->
          <xsl:call-template name="find-and-process">
            <xsl:with-param name="path" select="'value'"/>
            <xsl:with-param name="key" select="'label'"/>            
          </xsl:call-template>
            <!--string key="label"><xsl:value-of select="map:string[@key='value']"/></string-->
          </map>
        </map>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="map:map" mode="part">
    <map>
      <xsl:call-template name="linked-url"/>
      <string key="@type">Media</string>
      <map key="title">
      <xsl:call-template name="find-and-process">
        <xsl:with-param name="path" select="'title.[0].value'"/>
        <xsl:with-param name="key" select="'Title'"/>
        <xsl:with-param name="transform" select="'strip-trailing-chars'"/>
      </xsl:call-template>
      </map>
      <!--map key="digitalCharacteristic">
        <xsl:call-template name="find-and-process">
          <xsl:with-param name="path" select="'@processed.mid.format'"/>
          <xsl:with-param name="key" select="'EncodingFormat'"/>
        </xsl:call-template>
        <xsl:call-template name="find-and-process">
          <xsl:with-param name="path" select="'@processed.mid.measurements.filesize.value'"/>
          <xsl:with-param name="key" select="'FileSize'"/>
        </xsl:call-template>
      </map>
      <xsl:call-template name="find-and-process">
        <xsl:with-param name="path" select="'@processed.mid.measurements.dimensions'"/>
        <xsl:with-param name="key" select="'dimensions'"/>
        <xsl:with-param name="transform" select="'dimensions-to-string'"/>
      </xsl:call-template-->
      <array key="identifiedBy">
        <map>
        <xsl:call-template name="find-and-process">
          <xsl:with-param name="path" select="'@processed.mid.location'"/>
          <xsl:with-param name="key" select="'Identifier'"/>
        </xsl:call-template>
        </map>
      </array>
    </map>
  </xsl:template>
  
  <xsl:template match="map:string" mode="place">
    <map key="place">
      <string key="Place">
        <xsl:apply-templates select="." mode="strip-trailing-chars"/>
      </string>
    </map>
  </xsl:template>

  <xsl:template match="map:map[@key='creation']" mode="provision" priority="2">
    <!--xsl:if test="map:map[@key='date' or @key='place'] or map:array[@key='date' or @key='publisher' or @key='maker']">
      <xsl:variable name="relator">
        <xsl:choose>
          <xsl:when test="map:array[@key='publisher']">publication</xsl:when>
          <xsl:otherwise>provisionActivity</xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:variable name="class">
        <xsl:choose>
          <xsl:when test="map:array[@key='publisher']">Publication</xsl:when>
          <xsl:otherwise>ProvisionActivity</xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <map key="{$relator}">
        <array key="{$class}">
          <map>
            <xsl:apply-templates select="map:array[@key='date']/map:map" mode="bf-date"/>
            <xsl:apply-templates select="map:map[@key='date']" mode="bf-date"/>
            <xsl:apply-templates select="map:map[@key='place']" mode="place"/>
            <xsl:apply-templates select="map:array[@key='publisher']" mode="provision"/>
            <xsl:apply-templates select="map:array[@key='maker']/map:map" mode="provision"/>
          </map>
        </array>
      </map>
    </xsl:if-->
    <xsl:choose>
      <xsl:when test="map:array[@key='publisher']"> <!-- EOS pattern of recording -->
        <map key="publication">
          <array key="Publication">
            <map>
              <xsl:apply-templates select="map:array[@key='date']/map:map" mode="bf-date"/>
              <xsl:apply-templates select="map:map[@key='date']" mode="bf-date"/>
              <xsl:apply-templates select="map:array[@key='publisher']" mode="publication-agent"/>
              <xsl:apply-templates select="map:array[@key='publisher']" mode="publication-place"/>
            </map>
          </array>
        </map>
      </xsl:when>
      <xsl:otherwise>
        <map key="provisionActivity">
          <array key="ProvisionActivity">
            <map>
              <xsl:apply-templates select="map:map[@key='date']" mode="bf-date"/>
              <xsl:apply-templates select="map:map[@key='place']" mode="place"/>
              <xsl:apply-templates select="map:array[@key='maker']" mode="publication-agent"/>
            </map>
          </array>
        </map>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
    
  <xsl:template match="map:array" mode="provision">
    <xsl:choose>
      <xsl:when test="@key='maker'">
        <map key="agent">
          <array key="Agent">
            <xsl:apply-templates select="map:map" mode="agent"/>
          </array>
        </map>
      </xsl:when>
      <xsl:when test="@key='publisher'">
        <map key="publication">
          <array key="Publication">
            <xsl:apply-templates select="map:map" mode="provision"/>
          </array>
        </map>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
    
  <!--xsl:template match="map:map" mode="provision">
    <xsl:choose>
      <xsl:when test="@key='date'">
        <xsl:apply-templates select="." mode="bf-date"/>
      </xsl:when>
      <xsl:when test="../map:array[@key='publisher']">
        <map>
          <xsl:apply-templates select="map:map" mode="publication"/>
        </map>
      </xsl:when>
    </xsl:choose>
  </xsl:template-->
  
  <xsl:template match="map:map" mode="provision">
    <map>
      <xsl:apply-templates select="map:array[@key='name']" mode="names"/>
      <xsl:apply-templates select="map:string[@key='place']" mode="place"/>
    </map>
  </xsl:template>
  
  <xsl:template match="map:array" mode="publication-agent">
    <map key="agent">
      <array key="Agent">
        <xsl:choose>
          <xsl:when test="@key='maker'">
            <!--string>[agent here]</string-->
            <xsl:apply-templates select="map:map" mode="agent-only"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="map:map/map:array[@key='name']/map:map" mode="bf-name"/>
          </xsl:otherwise>
        </xsl:choose>        
      </array>
    </map>
  </xsl:template>
  
  <xsl:template match="map:array" mode="publication-place">
    <map key="place">
      <array key="Place">
        <xsl:apply-templates select="map:map/map:string[@key='place']" mode="string"/>
      </array>
    </map>
  </xsl:template>
  
  <xsl:template match="map:map" mode="publication-agent">
    <map>
      <xsl:apply-templates select="map:map[@key='name']" mode="bf-name"/>
    </map>
  </xsl:template>
  
  <xsl:template match="map:map" mode="publication-place">
    <map>
      <xsl:apply-templates select="map:map[@key='name']" mode="bf-name"/>
    </map>
  </xsl:template>
  
  <xsl:template match="map:map" mode="related-work">
    <map>
      <xsl:call-template name="linked-url"/>
      <string key="label">
        <xsl:apply-templates select="map:map[@key='summary']/map:string[@key='title']" mode="strip-trailing-chars"/>
      </string>      
    </map>
  </xsl:template>
  
  <xsl:template match="map:string" mode="sub-location">
        <string key='subLocation'><xsl:value-of select="."/></string>
  </xsl:template>
  
  <xsl:template match="map:map" mode="summary">
    <map>
      <string key="type"><xsl:value-of select="map:string[@key='type']"/></string>
      <string key="label"><xsl:value-of select="map:string[@key='value']"/></string>
    </map>
  </xsl:template>
  
  <xsl:template match="map:map" mode="bf-title">
    <map>
      <xsl:call-template name="find-and-process">
        <xsl:with-param name="path" select="'value'"/>
        <xsl:with-param name="key" select="'Title'"/>
        <xsl:with-param name="transform" select="strip-trailing-chars"/>
      </xsl:call-template>
      <xsl:call-template name="find-and-process">
        <xsl:with-param name="path" select="'type'"/>
        <xsl:with-param name="key" select="'type'"/>
      </xsl:call-template>
    </map>
  </xsl:template>
  
  <xsl:template match="map:map" mode="topic">
    <string>
      <xsl:value-of select="map:map[@key='summary']/map:string[@key='topic']"/>
    </string>
  </xsl:template>

<!-- low-level generic templates: -->

  <xsl:template match="map:map" mode="bf-date">
    <string key="date"><xsl:apply-templates select="map:string[@key='value']" mode="strip-trailing-chars"/></string>
  </xsl:template>
  
  <xsl:template match="map:map" mode="string">
        <string><xsl:apply-templates select="map:string[@key='value']" mode="strip-trailing-chars"/></string>
  </xsl:template>
  
  <xsl:template match="map:string" mode="string">
        <string><xsl:apply-templates select="." mode="strip-trailing-chars"/></string>
  </xsl:template>
  
  <xsl:template match="map:string" mode="strip-trailing-chars">
    <xsl:call-template name="strip-trailing-chars"/>
  </xsl:template>
		
</xsl:stylesheet>