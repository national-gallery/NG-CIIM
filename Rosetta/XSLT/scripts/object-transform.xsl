<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/2005/xpath-functions"
  xmlns:map="http://www.w3.org/2005/xpath-functions"
  exclude-result-prefixes="map">
  <xsl:output method="text" media-type="application/json" encoding="UTF-8"/>
  <xsl:param name="file"/>
  <xsl:variable name="ng-prefix" select="'https://data.ng.ac.uk/'"/>
  <xsl:variable name="doc" select="json-to-xml(unparsed-text($file))"/>
  
  <xsl:template match="/">    
    <xsl:variable name="output">
      <array xmlns="http://www.w3.org/2005/xpath-functions">
        <xsl:for-each select="$doc/*">
          <map>
            <!-- @context: [string, array Required] The value MUST be the URI of the Linked Art context as a string,
                    "https://linked.art/ns/v1/linked-art.json" or an array in which the URI is the last entry to allow for 
                    extensions -->
            <xsl:call-template name="context"/>
            
            <xsl:for-each select="map:map[@key='hits']/map:array[@key='hits']/map:map[1]">
              
              <!-- id: [string Required] The value MUST be the HTTP(S) URI at which the object's representation 
                      can be dereferenced
              -->
              <xsl:call-template name="object-id"/>
              
              <!-- type: [string Required] The class for the object, which MUST be the value "HumanMadeObject"
              -->
              <string key="type">HumanMadeObject</string>
              
              <!-- _label: [string Recommended] 	A human readable label for the object, intended for developers -->
              <xsl:call-template name="object-label"/>
              
              <!-- process the contents of the _source key, which contains the bulk of the info.
                      Arrays and objects which I think we will need in the output are left here as empty arrays/objects;
                      those which I don't think we need are commented out below.
                      For each 'target' array in the result, process each member of the CIIM arrays 
                       with the specified keys, in the specified mode: -->
              <xsl:for-each select="map:map[@key='_source']">
                
                <!-- classified_as: [array Recommended] An array of json objects, each of which is a classification 
                          of the object and MUST follow the requirements for Type -->
                <array key="classified_as">
                  <xsl:apply-templates select="map:array[@key='classification']/map:map" mode="classification"/>
                </array>
                
                <!-- identified_by: [array Recommended] An array of json objects, each of which is a name/title 
                        of the object and MUST follow the requirements for Name, or an identifier for the object and 
                        MUST follow the requirements for Identifier -->
                <array key="identified_by">
                  <xsl:apply-templates select="map:array[@key='title']/map:map" mode="title"/>
                  <xsl:apply-templates select="map:array[@key='identifier']" mode="identifier"/>
                </array>
                
                <!-- referred_to_by: [array Optional] An array of json objects, each of which is a human readable 
                        statement about the object and MUST follow the requirements for Statement -->
                <array key="referred_to_by">
                  <xsl:apply-templates select="map:array[@key='description']/map:map" mode="description"/>
                </array>
                
                <!-- equivalent: [array Optional] An array of json objects, each of which is an reference to an 
                        external identity and description of the current object -->
                <!--array key="equivalent">
                </array-->
                
                <!-- representation: [array Optional] An array of json objects, each of which is a reference to 
                        a Visual Work that represents the current object, and MUST follow the requirements for 
                        a reference -->
                <!--array key="representation">
                </array-->
                
                <!-- member_of: [array Optional] An array of json objects, each of which is a Set that the current 
                        object is a member of and MUST follow the requirements for an reference to a Set -->
                <array key="member_of">
                  <xsl:apply-templates select="map:array[@key='package']/map:map" mode="member-of"/>
                </array>
                
                <!-- subject_of: [array Optional] An array of json objects, each of which is a reference to a Textual 
                        Work, the content of which focuses on the current object, and MUST follow the requirements 
                        for an reference -->
                <array key="subject_of">
                  <xsl:apply-templates select="map:array[@key='bibliography' 
                        or @key='bibliogrpahy']/map:map" mode="bibliography"/>
                </array>
                
                <!-- attributed_by: [array Optional] An array of json objects, each of which is a Relationship 
                        Assignment that relates the current object to another entity -->
                <!--array key="attributed_by">
                </array-->
                
                <!--part_of: [array Optional] An array of json objects, each of which is a reference to another 
                        Physical Object that the current object is a part of -->
                <!--array key="part_of">
                </array-->
                
                <!-- dimension: [array Optional] An array of json objects, each of which is a Dimension, such as 
                        height or width, of the current object -->
                <array key="dimension">
                  <xsl:apply-templates select="map:array[@key='measurements']/map:map" mode="dimensions"/>
                </array>
                
                <!-- made_of: [array Optional]  An array of json objects, each of which is a reference to a material 
                        that the object is made_of and MUST follow the requirements for Material -->
                <array key="made_of">
                  <xsl:apply-templates select="map:array[@key='material']/map:map" mode="made-of"/>
                </array>
                
                <!-- part: an array created to hold [the materials of] medium and support, but potentially 
                        may also need to hold any other 'parts' that are identified: -->
                <array key="part">
                  <xsl:apply-templates select="map:array[@key='material']/map:map" mode="part-made-of"/>
                </array>
                
                <!-- current_owner: [array Optional] An array of json, objects each of which is a reference to a
                        Person or Group that currently owns the object -->
                <array key="current_owner">
                  <xsl:call-template name="national-gallery"/>
                  <xsl:apply-templates select="map:map[@key='possession']/map:array[@key='agent']/map:map" mode="shared-ownership"/>
                </array>
                
                <!-- current_custodian: [array Optional] An array of json, objects each of which is a reference to a 
                        Person or Group that currently has custody of the object -->
                <array key="current_custodian">
                  <xsl:call-template name="national-gallery"/>
                </array>
                
                <!-- current_permanent_custodian: [array Optional] An array of json, objects each of which is a
                        reference to a Person or Group that normally has custody of the object, but might not at 
                        the present time -->
                <!--array key="current_permanent_custodian">
                </array-->
                
                <!-- current_location: [json object Optional] A json object which is a reference to the Place where 
                        the object is currently located -->
                  <xsl:apply-templates select="map:map[@key='location']/map:map[@key='current']" mode="current-location"/>
                
                <!-- current_permanent_location: [json object Optional] A json object which is a reference to the 
                        Place where the object is normally located, but might not be at the present time -->
                <!--map key="current_permanent_location">
                </map-->
                
                <!-- carries: [array Optional] An array of json objects, each of which is a reference to a Textual 
                        Work that this object carries the text of-->
                <!--array key="carries">
                </array-->
                
                <!-- shows: [array Optional] An array of json objects, each of which is a reference to a Visual Work 
                        that this object shows a rendition of -->
                <array key="shows">
                  <xsl:apply-templates select="map:array[@key='style']/map:map" mode="style-classification"/>
                  <xsl:apply-templates select="map:array[@key='subject']/map:map" mode="subject-keywords"/>
                </array>
                
                <!-- produced_by: [json object Optional] A json object representing the production of the object, 
                        which follows the requirements for Productions described below. N.B. since the target is an
                        object, we only process the first member of the source array: -->
                <map key="produced_by">
                  <xsl:apply-templates select="map:array[@key='creation']/map:map[1]" mode="creation"/>
                </map>
                
                <!-- destroyed_by: [json object Optional] A json object representing the destruction of the object,
                        which follows the requirements for Destructions described below -->
                <!--map key="destroyed_by">
                </map-->
                
                <!-- removed_by: [json object Optional] A json object representing the removal of the current 
                        object from a larger one it was previously part of, which follows the requirements for 
                        PartRemovals described below -->
                <!--map key="removed_by">
                </map-->
                
              </xsl:for-each>
            </xsl:for-each>
          </map>
        </xsl:for-each>
      </array>
    </xsl:variable>
    <xsl:value-of select="xml-to-json($output)"/>
  </xsl:template>
  
  <xsl:variable name="quot">&quot;</xsl:variable>
  
  <xsl:template name="context">
    <string key="@context">https://linked.art/ns/v1/linked-art.json</string>
  </xsl:template>
  
  <xsl:template name="object-id">
    <xsl:call-template name="find-and-process">
      <xsl:with-param name="path" select="'_id'"/>
      <xsl:with-param name="key" select="'id'"/>
      <xsl:with-param name="prefix" select="$ng-prefix"/>
    </xsl:call-template>
  </xsl:template>
  
  <xsl:template name="object-label">
    <xsl:variable name="object-class">
      <xsl:call-template name="find-node">
        <xsl:with-param name="path" select="'_source.classification.[0].value'"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:call-template name="find-and-process">
      <xsl:with-param name="path" select="'_source.summary.title'"/>
      <xsl:with-param name="key" select="'_label'"/>
      <xsl:with-param name="prefix" select="concat($object-class, ': ')"/>
    </xsl:call-template>    
  </xsl:template>
  
  <!-- general templates: should be hived off into a separate 'library' file: -->
  
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
    <xsl:if test="$node">
      <string key="{$key}"><xsl:value-of select="concat($prefix, $node/text(), $suffix)"/></string>
    </xsl:if>
  </xsl:template>
  
  <xsl:template name="process-node-as-number">
    <xsl:param name="key"/>
    <xsl:param name="node"/>
    <xsl:if test="$node">
      <number key="{$key}"><xsl:value-of select="$node/text()"/></number>
    </xsl:if>
  </xsl:template>
  
  <xsl:template name="classified-as">
    <xsl:param name="url"/>
    <xsl:param name="label"/>
    <array key="classified_as">
      <map>
        <xsl:if test="string($url)">
          <string key="id"><xsl:value-of select="$url"/></string>
        </xsl:if>
        <string key="type">Type</string>
        <xsl:if test="string($label)">
          <string key="_label"><xsl:value-of select="$label"/></string>
        </xsl:if>
      </map>
    </array>
  </xsl:template>

  <xsl:template name="sub-classified-as">
    <xsl:param name="class-url"/>
    <xsl:param name="class-label"/>
    <xsl:param name="subclass-url"/>
    <xsl:param name="subclass-label"/>
    <array key="classified_as">
      <map>
        <xsl:if test="string($class-url)">
          <string key="id"><xsl:value-of select="$class-url"/></string>
        </xsl:if>
        <string key="type">Type</string>
        <xsl:if test="string($class-label)">
          <string key="_label"><xsl:value-of select="$class-label"/></string>
        </xsl:if>
        <array key="classified_as">
          <map>
            <xsl:if test="string($subclass-url)">
              <string key="id"><xsl:value-of select="$subclass-url"/></string>
            </xsl:if>
            <string key="type">Type</string>
            <xsl:if test="string($subclass-label)">
              <string key="_label"><xsl:value-of select="$subclass-label"/></string>
            </xsl:if>
          </map>
        </array>
      </map>
    </array>
  </xsl:template>
  
  <xsl:template name="referred-to-by">
    <xsl:param name="label"/>
    <xsl:param name="content"/>
    <array key="referred_to_by">
      <map>
        <string key="type">LinguisticObject</string>
        <xsl:if test="string($label)">
          <string key="_label"><xsl:value-of select="$label"/></string>
        </xsl:if>
        <xsl:if test="string($content)">
          <string key="content"><xsl:value-of select="$content"/></string>
        </xsl:if>
      </map>
    </array>
  </xsl:template>
  
  <xsl:template name="linked-url">
    <xsl:param name="endpoint-path"/>
    <xsl:variable name="path">
    <xsl:choose>
      <xsl:when test="string($endpoint-path)">
        <xsl:value-of select="$endpoint-path"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="substring-before(map:map[@key='@admin']/map:string[@key='id'], '-')"/>
      </xsl:otherwise>
    </xsl:choose>
    </xsl:variable>
    <xsl:call-template name="find-and-process">
      <xsl:with-param name="path" select="'@admin.uuid'"/>
      <xsl:with-param name="key" select="'id'"/>
      <xsl:with-param name="prefix" select="concat($ng-prefix, $path, '/')"/>
    </xsl:call-template>
  </xsl:template>
  
  <!-- more general templates for common cases: -->
  
  <xsl:template match="map:string" mode="textual-object">
    <xsl:param name="node" select="."/>
    <xsl:if test="string($node)">
      <map>
        <string key="type">LinguisticObject</string>
        <string key="content"><xsl:value-of select="$node"/></string>
      </map>
    </xsl:if>
  </xsl:template>
  
  <!-- outputs the National Gallery details in a form suitable for current_owner and current_custodian: -->  
  <xsl:template name="national-gallery">
    <map>
      <string key="type">Agent</string>
      <string key="id"><xsl:value-of select="concat($ng-prefix, 'agent/', '0P5X-0001-0000-0000')"/></string>
      <string key="_label">National Gallery, London</string>
    </map>
  </xsl:template>
  
  <!-- mode-specific templates: -->
  
  <xsl:template match="map:map" mode="title">
    <map>
      <string key="type">Name</string>
      <xsl:call-template name="classified-as">
        <xsl:with-param name="url" select="'http://vocab.getty.edu/aat/300404670'"/>
        <xsl:with-param name="label" select="'Primary Name'"/>
      </xsl:call-template>
      <xsl:call-template name="find-and-process">
        <xsl:with-param name="path" select="'value'"/>
        <xsl:with-param name="key" select="'content'"/>
      </xsl:call-template>
    </map>
  </xsl:template>
  
  <xsl:template match="map:map" mode="classification">
    <xsl:variable name="class-type">
      <xsl:call-template name="find-node">
        <xsl:with-param name="path" select="'type'"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="style-url">
      <xsl:if test="$class-type='school'">
        <xsl:value-of select="'http://vocab.getty.edu/page/aat/300015646'"/>
      </xsl:if>
    </xsl:variable>
    <map>
      <!--string key="type">Name</string-->
      <xsl:choose>
        <xsl:when test="string($style-url)">
          <xsl:call-template name="sub-classified-as">
            <xsl:with-param name="class-url" select="'http://vocab.getty.edu/aat/300435444'"/>
            <xsl:with-param name="class-label" select="'Classification'"/>
            <xsl:with-param name="subclass-url" select="$style-url"/>
            <xsl:with-param name="subclass-label" select="$class-type"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="classified-as">
            <xsl:with-param name="url" select="'http://vocab.getty.edu/aat/300435444'"/>
            <xsl:with-param name="label" select="'Classification'"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:call-template name="find-and-process">
        <xsl:with-param name="path" select="'value'"/>
        <xsl:with-param name="key" select="'content'"/>
      </xsl:call-template>
    </map>
  </xsl:template>
  
  <xsl:template match="map:map" mode="style-classification">
    <map>
      <string key="type">VisualItem</string>
      <!-- the value of @link.role.[0].value could be used as an informal sub-classification: -->
      <xsl:call-template name="classified-as">
        <xsl:with-param name="url" select="'https://vocab.getty.edu/aat/300015646'"/>
        <xsl:with-param name="label" select="'Style'"/>
      </xsl:call-template>
      <xsl:call-template name="linked-url">
        <xsl:with-param name="endpoint-path" select="'visual'"/>
      </xsl:call-template>
      <xsl:call-template name="find-and-process">
        <xsl:with-param name="path" select="'summary.title'"/>
        <xsl:with-param name="key" select="'_label'"/>
      </xsl:call-template>
    </map>
  </xsl:template>
  
  <xsl:template match="map:map" mode="subject-keywords">
    <map>
      <string key="type">VisualItem</string>
      <xsl:call-template name="sub-classified-as">
        <xsl:with-param name="class-url" select="'http://vocab.getty.edu/aat/300435444'"/>
        <xsl:with-param name="class-label" select="'Classification'"/>
        <xsl:with-param name="subclass-label" select="'Subject Matter'"/>
      </xsl:call-template>
      <xsl:call-template name="linked-url">
        <xsl:with-param name="endpoint-path" select="'visual'"/>
      </xsl:call-template>
      <xsl:call-template name="find-and-process">
        <xsl:with-param name="path" select="'summary.title'"/>
        <xsl:with-param name="key" select="'content'"/>
      </xsl:call-template>
    </map>
  </xsl:template>
  
  <xsl:template match="map:map" mode="bibliography">
    <map>
      <string key="type">LinguisticObject</string>
      <!-- Rob Sanderson advises that this isn't necessary, if we use the subject_of property instead of 
            referred_to_by: -->
      <!--xsl:call-template name="classified-as">
        <xsl:with-param name="url" select="'https://vocab.getty.edu/aat/300311705'"/>
        <xsl:with-param name="label" select="'Citation'"/>
      </xsl:call-template-->
      <xsl:call-template name="linked-url">
        <xsl:with-param name="endpoint-path" select="'text'"/>
      </xsl:call-template>      
      <xsl:call-template name="find-and-process">
        <xsl:with-param name="path" select="'summary.title'"/>
        <xsl:with-param name="key" select="'_label'"/>
      </xsl:call-template>
    </map>
  </xsl:template>
  
  <xsl:template match="map:map" mode="description">
    <map>
      <string key="type">LinguisticObject</string>
      <xsl:call-template name="sub-classified-as">
        <xsl:with-param name="class-url" select="'https://vocab.getty.edu/aat/300435416'"/>
        <xsl:with-param name="class-label" select="'Description'"/>
        <xsl:with-param name="subclass-url" select="'https://vocab.getty.edu/aat/300418049'"/>
        <xsl:with-param name="subclass-label" select="'Brief Text'"/>
      </xsl:call-template>
      <!--xsl:call-template name="process-node">
        <xsl:with-param name="key" select="'type'"/>
        <xsl:with-param name="node" select="map:string[@key='type']"/>
      </xsl:call-template-->
      <xsl:call-template name="process-node">
        <xsl:with-param name="key" select="'content'"/>
        <xsl:with-param name="node" select="map:string[@key='value']"/>
      </xsl:call-template>
    </map>
  </xsl:template>
  
  <xsl:template match="map:map" mode="identifier">
    <xsl:variable name="identifier-type" select="map:string[@key='type']/text()"/>
    <xsl:if test="$identifier-type='display number' or $identifier-type='PID'">
      <xsl:variable name="type-url">
        <xsl:choose>
          <xsl:when test="$identifier-type='display number'">
            <xsl:value-of select="'http://vocab.getty.edu/page/aat/300312355'"/>
          </xsl:when>
          <xsl:when test="$identifier-type='PID'">
            <xsl:value-of select="'http://vocab.getty.edu/page/aat/300387580'"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="'http://vocab.getty.edu/page/aat/300404012'"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:variable name="type-label">
        <xsl:choose>
          <xsl:when test="$identifier-type='display number'">
            <xsl:value-of select="'Accession number'"/>
          </xsl:when>
          <xsl:when test="$identifier-type='PID'">
            <xsl:value-of select="'Persistent identifier'"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="'Unique identifier'"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <map>
        <string key="type">Identifier</string>
        <xsl:call-template name="classified-as">
          <xsl:with-param name="url" select="$type-url"/>
          <xsl:with-param name="label" select="$type-label"/>
        </xsl:call-template>
        <xsl:call-template name="process-node">
          <xsl:with-param name="key" select="'_label'"/>
          <xsl:with-param name="node" select="map:string[@key='type']"/>
        </xsl:call-template>
        <xsl:call-template name="process-node">
          <xsl:with-param name="key" select="'content'"/>
          <xsl:with-param name="node" select="map:string[@key='value']"/>
        </xsl:call-template>
      </map>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="map:map" mode="member-of">
    <map>
      <string key="type">Set</string>
      <xsl:call-template name="linked-url">
        <xsl:with-param name="endpoint-path" select="'set'"/>
      </xsl:call-template>
      <xsl:call-template name="find-and-process">
        <xsl:with-param name="path" select="'summary.title'"/>
        <xsl:with-param name="key" select="'_label'"/>
      </xsl:call-template>
    </map>
  </xsl:template>
  
  <!-- have not yet addressed date, display or method keys (see object-4668): -->
  <xsl:template match="map:map" mode="dimensions">
    <xsl:apply-templates select="map:map[@key='description']/map:string[@key='value']" mode="textual-object"/>
    <xsl:apply-templates select="map:array[@key='dimensions']/map:map" mode="dimension"/>
  </xsl:template>
  
  <xsl:template match="map:map" mode="dimension">
    <map>
      <string key="type">Dimension</string>
      <xsl:call-template name="dimension-summary"/>
      <xsl:call-template name="process-node-as-number">
        <xsl:with-param name="key" select="'value'"/>
        <xsl:with-param name="node" select="map:string[@key='value']"/>
      </xsl:call-template>
      <xsl:apply-templates select="map:string[@key='units']" mode="units-object"/>
    </map>
  </xsl:template>
  
  <xsl:template name="dimension-summary">
    <xsl:variable name="measurement" select="map:string[@key='dimension']/text()"/>
    <xsl:variable name="value" select="map:string[@key='value']/text()"/>
    <xsl:variable name="units" select="map:string[@key='units']/text()"/>
    <string key="_label"><xsl:value-of select="concat($measurement, ' ', $value, ' ', $units)"/></string>
  </xsl:template>
  
  <!-- additional measurement units can (should!) be added here as they crop up: -->
  <xsl:template match="map:string" mode="units-object">
    <xsl:if test="string(.)">
      <xsl:choose>
        <xsl:when test="starts-with(., 'cm')">
          <map key="unit">
            <string key="type">MeasurementUnit</string>
            <string key="id">http://vocab.getty.edu/aat/300379098</string>
            <string key="_label"><xsl:value-of select="'Centimeters (Measurements)'"/></string>
          </map>
        </xsl:when>
      </xsl:choose>
    </xsl:if>
  </xsl:template>
  
  <!-- Asked the Linked Art group about how to encode 'medium' and 'support' (which are
          recorded as 'role'). The answer is to use 'part' for these concepts; however Rob Sanderson
          says that part within an object record is deprecated, and we should be putting this information
          into a separate entry which is 'part_of' the main object: -->
  <xsl:template match="map:map" mode="made-of">
    <xsl:if test="string(map:string[@key='value'])">
      <xsl:apply-templates select="map:string[@key='value']" mode="material"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="map:map" mode="part-made-of">
    <xsl:if test="map:map[@key='@admin']/map:string[@key='uuid']">
      <xsl:variable name="part-type" select="map:map[@key='@link']/map:array[@key='role']/map:map[1]/map:string[@key='value']"/>
      <map>
        <string key="type">HumanMadeObject</string>
        <string key="_label"><xsl:value-of select="$part-type"/></string>
        <xsl:choose>
          <xsl:when test="$part-type='medium'">
            <xsl:call-template name="sub-classified-as">
              <xsl:with-param name="class-url" select="'http://vocab.getty.edu/aat/300010358'"/>
              <xsl:with-param name="class-label" select="'Medium'"/>
              <xsl:with-param name="subclass-url" select="'http://vocab.getty.edu/aat/300241583'"/>
              <xsl:with-param name="subclass-label" select="'Part Type'"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:when test="$part-type='support'">
            <xsl:call-template name="sub-classified-as">
              <xsl:with-param name="class-url" select="'http://vocab.getty.edu/aat/300014844'"/>
              <xsl:with-param name="class-label" select="'Support'"/>
              <xsl:with-param name="subclass-url" select="'http://vocab.getty.edu/aat/300241583'"/>
              <xsl:with-param name="subclass-label" select="'Part Type'"/>
            </xsl:call-template>
          </xsl:when>
        </xsl:choose>
        <array key="made_of">
          <map>
            <string key="type">Material</string>
              <xsl:call-template name="linked-url">
                <xsl:with-param name="endpoint-path" select="'concept'"/>
              </xsl:call-template>
              <xsl:call-template name="find-and-process">
              <xsl:with-param name="path" select="'summary.title'"/>
              <xsl:with-param name="key" select="'_label'"/>
            </xsl:call-template>
          </map>
        </array>
      </map>
    </xsl:if>
  </xsl:template>

  <xsl:template match="map:string" mode="material">
    <xsl:param name="node" select="."/>
    <xsl:if test="string($node)">
      <map>
        <string key="type">Material</string>
        <string key="content"><xsl:value-of select="$node"/></string>
      </map>
    </xsl:if>
  </xsl:template>
  <xsl:template match="map:map" mode="current-location">
    <map key="current_location">
      <string key="type">Place</string>
      <xsl:call-template name="linked-url">
        <xsl:with-param name="endpoint-path" select="'place'"/>
      </xsl:call-template>
      <xsl:call-template name="find-and-process">
        <xsl:with-param name="path" select="'summary.title'"/>
        <xsl:with-param name="key" select="'_label'"/>
      </xsl:call-template>
    </map>
  </xsl:template>  
  
  <xsl:template match="map:map" mode="agent">
    <map>
      <string key="type">Agent</string>
      <xsl:call-template name="linked-url"/>
      <xsl:call-template name="find-and-process">
        <xsl:with-param name="path" select="'summary.title'"/>
        <xsl:with-param name="key" select="'_label'"/>
      </xsl:call-template>
    </map>
  </xsl:template>

  <!-- tests for 'Joint Owner with NG' in the @link.role field, and adds them if this is present: -->
  <xsl:template match="map:map" mode="shared-ownership">
    <xsl:if test="map:map[@key='@link']/map:array[@key='role']/map:map/map:string[@key='value'][.='Joint Owner with NG']">
      <xsl:apply-templates select="." mode="agent"/>
    </xsl:if>
  </xsl:template>  
  
  <xsl:template match="map:map" mode="creation">
      <string key="type">Production</string>
      <xsl:apply-templates select="map:array[@key='date']/map:map[1]" mode="date"/>
      <!-- xsl:apply-templates select="map[@key='timespan']" mode="timespan"/-->
      <array key="took_place_at">
        <xsl:apply-templates select="map:array[@key='place']/map:map" mode="place"/>
      </array>
      <array key="carried_out_by">
        <xsl:apply-templates select="map:array[@key='maker']/map:map" mode="maker"/>
      </array>
  </xsl:template>

<xsl:template match="map:map" mode="date">
  <map key="timespan">
    <string key="type">TimeSpan</string>
    <xsl:apply-templates select="map:string[@key='from']" mode="earliest"/>
    <xsl:apply-templates select="map:string[@key='to']" mode="latest"/>
  </map>
</xsl:template>

<xsl:template match="map:string" mode="earliest">
  <string key="begin_of_the_begin">
    <xsl:call-template name="earliest-date"/>
  </string>
</xsl:template>

<xsl:template match="map:string" mode="latest">
  <string key="end_of_the_end">
    <xsl:call-template name="latest-date"/>
  </string>
</xsl:template>

<xsl:template name="earliest-date">
  <xsl:choose>
    <xsl:when test="string-length(.)=4">
      <xsl:value-of select="concat(., '-01-01T00:00:00Z')"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="."/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="latest-date">
  <xsl:choose>
    <xsl:when test="string-length(.)=4">
      <xsl:value-of select="concat(., '-12-31T23:59:59Z')"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="."/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="map:map" mode="place">
    <map>
      <string key="type">Place</string>
      <xsl:call-template name="linked-url">
        <xsl:with-param name="endpoint-path" select="'place'"/>
      </xsl:call-template>
      <xsl:call-template name="find-and-process">
        <xsl:with-param name="path" select="'summary.title'"/>
        <xsl:with-param name="key" select="'_label'"/>
      </xsl:call-template>
    </map>
</xsl:template>

<xsl:template match="map:map" mode="maker">
    <map>
      <string key="type">Person</string>
      <xsl:call-template name="linked-url">
        <xsl:with-param name="endpoint-path" select="'person'"/>
      </xsl:call-template>
      <xsl:call-template name="find-and-process">
        <xsl:with-param name="path" select="'summary.title'"/>
        <xsl:with-param name="key" select="'_label'"/>
      </xsl:call-template>
    </map>
</xsl:template>

</xsl:stylesheet>