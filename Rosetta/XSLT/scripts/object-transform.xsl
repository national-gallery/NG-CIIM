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
                  <xsl:apply-templates select="map:array[@key='category']/map:map" mode="classification"/>
                  <xsl:apply-templates select="map:array[@key='function']/map:map" mode="url-classification"/>
                  <xsl:apply-templates select="map:array[@key='genre']/map:map" mode="url-classification"/>
                  <xsl:apply-templates select="map:array[@key='physical']/map:map" mode="url-classification"/>
                  <xsl:apply-templates select="map:map[@key='legal']/map:string[@key='status']" mode="status-classification"/>
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
                  <xsl:apply-templates select="map:map[@key='provenance']/map:map[@key='text']" mode="provenance"/>
                  <xsl:apply-templates select="map:map[@key='legal']/map:string[@key[starts-with(., 'credit')]]" mode="credit-line"/>
                  <xsl:apply-templates select="map:map[@key='legal']/map:map[@key='image']/map:map[@key='rights']/map:string[@key='details']" mode="image-rights"/>
                  <xsl:apply-templates select="map:map[@key='access']/map:map[@key='item']/map:map[@key='lending']/map:string[@key='restrictions']" mode="access-lending"/>                  
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
                <array key="part_of">
                  <xsl:apply-templates select="map:array[@key='parent']/map:map" mode="part-of"/>
                </array>
                
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
                        may also need to hold any other 'parts' that are identified. The first of these is dimensions: -->
                <array key="part">
                  <xsl:apply-templates select="map:array[@key='material']/map:map" mode="part-made-of"/>
                  <xsl:apply-templates select="map:array[@key='measurements']/map:map" mode="part-dimensions"/>
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
                <array key="carries">
                  <xsl:apply-templates select="map:array[@key='inscription']/map:map" mode="carries"/>
                </array>
                
                <!-- shows: [array Optional] An array of json objects, each of which is a reference to a Visual Work 
                        that this object shows a rendition of -->
                <array key="shows">
                  <xsl:apply-templates select="map:array[@key='style']/map:map" mode="style-classification"/>
                  <xsl:apply-templates select="map:array[@key='subject']/map:map" mode="subject"/>
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
    <!-- to debug JSON serialization errors, set output type to XML and use this command instead of the line above: -->
    <!--xsl:copy-of select="$output"/-->
  </xsl:template>
  
  <xsl:variable name="quot">&quot;</xsl:variable>
  
  <xsl:template name="context">
    <string key="@context">https://linked.art/ns/v1/linked-art.json</string>
  </xsl:template>
  
  <xsl:template name="object-id">
    <xsl:call-template name="find-and-process">
      <xsl:with-param name="path" select="'_id'"/>
      <xsl:with-param name="key" select="'id'"/>
      <xsl:with-param name="prefix" select="concat($ng-prefix, 'object/')"/>
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

  <xsl:template name="dual-classified-as">
    <xsl:param name="url1"/>
    <xsl:param name="url2"/>
    <xsl:param name="label1"/>
    <xsl:param name="label2"/>
    <array key="classified_as">
      <xsl:if test="string($url1) or string($label1)">
        <map>
          <xsl:if test="string($url1)">
            <string key="id"><xsl:value-of select="$url1"/></string>
          </xsl:if>
          <string key="type">Type</string>
          <xsl:if test="string($label1)">
            <string key="_label"><xsl:value-of select="$label1"/></string>
          </xsl:if>
        </map>
      </xsl:if>
      <xsl:if test="string($url2) or string($label2)">
        <map>
          <xsl:if test="string($url2)">
            <string key="id"><xsl:value-of select="$url2"/></string>
          </xsl:if>
          <string key="type">Type</string>
          <xsl:if test="string($label2)">
            <string key="_label"><xsl:value-of select="$label2"/></string>
          </xsl:if>
        </map>
      </xsl:if>
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
  
  <!-- Process-map: creates a content string using summary.title, with prefix and suffix added if present: -->
  <xsl:template name="process-map">
    <xsl:param name="string-key" select="'content'"/>
    <xsl:variable name="content" select="map:map[@key='summary']/map:string[@key='title']"/>
    <xsl:if test="string($content)">
      <xsl:variable name="prefix" select="map:map[@key='@link']/map:string[@key='prefix']"/>
      <xsl:variable name="suffix" select="map:map[@key='@link']/map:string[@key='suffix']"/>
      <xsl:variable name="pre">
        <xsl:if test="string($prefix)">
          <xsl:value-of select="concat($prefix, ' ')"/>
        </xsl:if>
      </xsl:variable>
      <xsl:variable name="post">
        <xsl:if test="string($suffix)">
          <xsl:value-of select="concat(' ', $suffix)"/>
        </xsl:if>
      </xsl:variable>
      <string key="{$string-key}">
        <xsl:value-of select="concat($pre, $content, $post)"/>
      </string>
    </xsl:if>
  </xsl:template>
  
  <!-- more general templates for common cases: -->
  
  <xsl:template match="map:string" mode="textual-object">
    <xsl:param name="node" select="."/>
    <xsl:param name="class-url"/>
    <xsl:param name="class-label"/>
    <xsl:if test="string($node)">
      <map>
        <string key="type">LinguisticObject</string>
        <xsl:if test="string($class-url) or string($class-label)">
          <array key="classified_as">
            <map>
              <xsl:if test="string($class-url)">
                <string key="id"><xsl:value-of select="$class-url"/></string>
              </xsl:if>
              <string key="type">Type</string>
              <xsl:if test="string($class-label)">
                <string key="_label"><xsl:value-of select="$class-label"/></string>
              </xsl:if>
            </map>
          </array>
        </xsl:if>
        <string key="content"><xsl:value-of select="$node"/></string>
      </map>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="map:string" mode="citation">
    <xsl:param name="node" select="."/>
    <xsl:if test="string($node)">
      <!--array key="referred_to_by"-->
      <map>
        <string key="type">LinguisticObject</string>
        <string key="_label">Citations (Bibliographic References)</string>
        <xsl:call-template name="classified-as">
            <xsl:with-param name="url" select="'http://vocab.getty.edu/aat/300311705'"/>
            <xsl:with-param name="label" select="'Citations (Bibliographic References)'"/>
        </xsl:call-template>
        <string key="content"><xsl:value-of select="$node"/></string>
      </map>
      <!--/array-->
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="map:string" mode="note">
    <xsl:param name="node" select="."/>
    <xsl:param name="note-type" select="'note'"/>
    <xsl:if test="string($node)">
      <map>
        <string key="type">LinguisticObject</string>
        <xsl:call-template name="classified-as">
            <xsl:with-param name="url" select="'http://vocab.getty.edu/aat/300435415'"/>
            <xsl:with-param name="label" select="'descriptive note'"/>
        </xsl:call-template>
        <string key="_label"><xsl:value-of select="$note-type"/></string>
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
  <xsl:variable name="apos">&apos;</xsl:variable>
  <xsl:template match="map:map" mode="title">
    <xsl:variable name="title-type">
      <xsl:call-template name="find-node">
        <xsl:with-param name="path" select="'type'"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="title-type-uri">
      <xsl:choose>
        <xsl:when test="$title-type='full title'">
          <xsl:value-of select="'http://vocab.getty.edu/aat/300417476'"/>
        </xsl:when>
        <xsl:when test="$title-type='short title'">
          <xsl:value-of select="'http://vocab.getty.edu/aat/300417477'"/>
        </xsl:when>
        <xsl:when test="$title-type='foreign language title' or $title-type='exhibition title' or $title-type=concat('lender', $apos, 's title')">
          <xsl:value-of select="'http://vocab.getty.edu/aat/300417478'"/>
        </xsl:when>
        <xsl:when test="$title-type='previous title' or $title-type='previous short title'">
          <xsl:value-of select="'http://vocab.getty.edu/aat/300449151'"/>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>
    <!--xsl:variable name="output-title-type">
      <xsl:choose>
        <xsl:when test="$title-type='full title'">
          <xsl:value-of select="'Primary Name'"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$title-type"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable-->
    <map>
      <string key="type">Name</string>
      <xsl:choose>
        <xsl:when test="$title-type='full title'">
          <xsl:call-template name="dual-classified-as">
            <xsl:with-param name="url1" select="'http://vocab.getty.edu/aat/300404670'"/>
            <xsl:with-param name="label1" select="'Primary Name'"/>
            <xsl:with-param name="url2" select="$title-type-uri"/>
            <xsl:with-param name="label2" select="$title-type"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="classified-as">
            <xsl:with-param name="url" select="$title-type-uri"/>
            <xsl:with-param name="label" select="$title-type"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
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
      <xsl:choose>
        <xsl:when test="$class-type='school'">
          <xsl:value-of select="'http://vocab.getty.edu/aat/300015646'"/>
        </xsl:when>
        <xsl:when test="$class-type='function'">
          <xsl:value-of select="'http://vocab.getty.edu/aat/300068844'"/>
        </xsl:when>
      </xsl:choose>
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
        <xsl:when test="string($class-type)">
          <xsl:call-template name="sub-classified-as">
            <xsl:with-param name="class-url" select="'http://vocab.getty.edu/aat/300435444'"/>
            <xsl:with-param name="class-label" select="'Classification'"/>
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
  
  <xsl:template match="map:map" mode="url-classification">
    <xsl:variable name="class-type">
      <xsl:call-template name="find-node">
        <xsl:with-param name="path" select="'@link.role.[0].value'"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="class-url">
      <xsl:choose>
        <xsl:when test="$class-type='function'">
          <xsl:value-of select="'http://vocab.getty.edu/aat/300068844'"/>
        </xsl:when>
        <xsl:when test="$class-type='genre'">
          <xsl:value-of select="' http://vocab.getty.edu/aat/300056462'"/>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>
    <map>
      <!--string key="type">Name</string-->
      <xsl:choose>
        <xsl:when test="string($class-url)">
          <xsl:call-template name="sub-classified-as">
            <xsl:with-param name="class-url" select="'http://vocab.getty.edu/aat/300435444'"/>
            <xsl:with-param name="class-label" select="'Classification'"/>
            <xsl:with-param name="subclass-url" select="$class-url"/>
            <xsl:with-param name="subclass-label" select="$class-type"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="string($class-type)">
          <xsl:call-template name="sub-classified-as">
            <xsl:with-param name="class-url" select="'http://vocab.getty.edu/aat/300435444'"/>
            <xsl:with-param name="class-label" select="'Classification'"/>
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
      <xsl:call-template name="linked-url">
        <xsl:with-param name="endpoint-path" select="'concept'"/>
      </xsl:call-template>
      <string key="_label"><xsl:value-of select="$class-type"/></string>
      <xsl:call-template name="find-and-process">
        <xsl:with-param name="path" select="'summary.title'"/>
        <xsl:with-param name="key" select="'content'"/>
      </xsl:call-template>
    </map>
  </xsl:template>
  
  <xsl:template match="map:string" mode="status-classification">
    <map>
      <xsl:call-template name="sub-classified-as">
        <xsl:with-param name="class-url" select="'http://vocab.getty.edu/aat/300435444'"/>
        <xsl:with-param name="class-label" select="'Classification'"/>
        <xsl:with-param name="subclass-url" select="'http://vocab.getty.edu/aat/300417633'"/>
        <xsl:with-param name="subclass-label" select="'Legal Status'"/>
      </xsl:call-template>
      <string key="type">LinguisticObject</string>
      <string key="_label">Legal Status</string>
      <string key="content"><xsl:value-of select="."/></string>
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
  
  <xsl:template match="map:map" mode="physical-make-up">
    
  </xsl:template>
  
  <xsl:template match="map:map" mode="subject">
    <xsl:variable name="base-datatype" select="map:map[@key='@datatype']/map:string[@key='base']"/>
    <xsl:variable name="admin-id" select="map:map[@key='@admin']/map:string[@key='id']"/>
    <xsl:choose>
      <xsl:when test="$base-datatype='concept'">
        <xsl:apply-templates select="." mode="shows-concept"/>
      </xsl:when>
      <xsl:when test="$base-datatype='agent'">
        <xsl:apply-templates select="." mode="shows-actor"/>
      </xsl:when>
      <xsl:when test="starts-with($admin-id, 'place-')">
        <xsl:apply-templates select="." mode="shows-place"/>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="map:map" mode="shows-concept">
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
  
  <xsl:template match="map:map" mode="shows-actor">
    <map>
      <string key="type">VisualItem</string>
      <array key="represents">
        <map>
          <string key="type">Actor</string>
          <xsl:call-template name="linked-url">
            <xsl:with-param name="endpoint-path" select="'person'"/>
          </xsl:call-template>
          <xsl:call-template name="process-map">
            <xsl:with-param name="string-key" select="'_label'"/>
          </xsl:call-template>
        </map>
      </array>
    </map>    
  </xsl:template>
  
  <xsl:template match="map:map" mode="shows-place">
    <map>
      <string key="type">VisualItem</string>
      <array key="represents">
        <map>
          <string key="type">Place</string>
          <xsl:call-template name="linked-url">
            <xsl:with-param name="endpoint-path" select="'place'"/>
          </xsl:call-template>
          <xsl:call-template name="find-and-process">
            <xsl:with-param name="path" select="'role.[0].value'"/>
            <xsl:with-param name="key" select="'_label'"/>
          </xsl:call-template>
          <xsl:call-template name="process-map">
            <xsl:with-param name="string-key" select="'_label'"/>
          </xsl:call-template>
        </map>
      </array>
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
      <xsl:apply-templates select="map:map[@key='@link']/map:map[@key='details']" mode="citation-note"/>
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
  
  <!-- N.B. we are already at the map node with key 'text': -->
  <xsl:template match="map:map" mode="provenance">
    <map>
      <string key="type">LinguisticObject</string>
      <xsl:call-template name="sub-classified-as">
        <xsl:with-param name="class-url" select="'https://vocab.getty.edu/aat/300435416'"/>
        <xsl:with-param name="class-label" select="'Description'"/>
        <xsl:with-param name="subclass-url" select="'https://vocab.getty.edu/aat/300055863'"/>
        <xsl:with-param name="subclass-label" select="'Provenance Statement'"/>
      </xsl:call-template>
      <xsl:if test="map:map[@key='source']/map:string[@key='value'] or
              ../map:map[@key='incomplete']/map:string[@key='value'] or
              map:map[@key='status']/map:map[@key='note']/map:string[@key='value']">
        <array key="referred_to_by">
          <xsl:apply-templates select="../map:map[@key='incomplete']/map:string[@key='value']" mode="note">
            <xsl:with-param name="note-type" select="'completeness'"/>
          </xsl:apply-templates>
          <xsl:apply-templates select="map:map[@key='source']/map:string[@key='value']" mode="citation"/>
          <xsl:apply-templates select="map:map[@key='status']/map:string[@key='value']" mode="note">
            <xsl:with-param name="note-type" select="'status'"/>
          </xsl:apply-templates>
        </array>
      </xsl:if>
      <xsl:call-template name="process-node">
        <xsl:with-param name="key" select="'content'"/>
        <xsl:with-param name="node" select="map:string[@key='value']"/>
      </xsl:call-template>
    </map>
  </xsl:template>
  
  <xsl:template match="map:string" mode="credit-line">
    <xsl:variable name="text-type">
      <xsl:choose>
        <xsl:when test="@key='credit' or @key='credit_long'">Full Text</xsl:when>
        <xsl:when test="@key='credit_AIL'">Acceptance in Lieu Text</xsl:when>
        <xsl:when test="@key='credit_short'">Brief Text</xsl:when>
      </xsl:choose>
    </xsl:variable>
    <map>
      <string key="type">LinguisticObject</string>
      <xsl:call-template name="sub-classified-as">
        <xsl:with-param name="class-url" select="'https://vocab.getty.edu/aat/300026687'"/>
        <xsl:with-param name="class-label" select="'Credit Statement'"/>
        <xsl:with-param name="subclass-url" select="'https://vocab.getty.edu/aat/300418049'"/>
        <xsl:with-param name="subclass-label" select="$text-type"/>
      </xsl:call-template>
      <string key="content"><xsl:value-of select="."/></string>
    </map>
  </xsl:template>
  
  <xsl:template match="map:map" mode="identifier">
    <xsl:variable name="identifier-type" select="map:string[@key='type']/text()"/>
    <xsl:variable name="type-label">
      <xsl:choose>
        <xsl:when test="$identifier-type='display number'">
          <xsl:value-of select="'Accession number'"/>
        </xsl:when>
        <xsl:when test="$identifier-type='PID'">
          <xsl:value-of select="'Persistent identifier'"/>
        </xsl:when>
        <xsl:when test="$identifier-type='Joint Owner Object Number' or $identifier-type='Owner Object Number' 
              or $identifier-type='Lender Object Number' or $identifier-type='Previous Object Number' 
              or $identifier-type='Catalogue Raisonné Ref' or $identifier-type=concat('Owner', $apos, ' object URI')">
              <!-- or $identifier-type='Incorrect Object Number'" - for testing only -->
          <xsl:value-of select="$identifier-type"/>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="string($type-label)">
      <xsl:variable name="type-url">
        <xsl:choose>
          <xsl:when test="$identifier-type='display number' or $identifier-type='Previous Object Number'">
            <xsl:value-of select="'http://vocab.getty.edu/aat/300312355'"/>
          </xsl:when>
          <xsl:when test="$identifier-type='PID'">
            <xsl:value-of select="'http://vocab.getty.edu/aat/300387580'"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="'http://vocab.getty.edu/aat/300404012'"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <map>
        <string key="type">Identifier</string>
        <xsl:call-template name="classified-as">
          <xsl:with-param name="url" select="$type-url"/>
          <xsl:with-param name="label" select="$type-label"/>
        </xsl:call-template>
        <xsl:apply-templates select="map:map[@key='date']" mode="date-assigned"/>
        <xsl:apply-templates select="map:map[@key='note']/map:string[@key='value']" mode="identifier-note"/>
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
  
  <xsl:template match="map:string" mode="identifier-note">
    <array key="referred-to-by">
      <xsl:apply-templates select="." mode="note"/>
    </array>
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
  
  <xsl:template match="map:map" mode="part-dimensions">
    <xsl:variable name="desc-value">
      <xsl:call-template name="find-node">
        <xsl:with-param name="path" select="'description.value'"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:if test="string($desc-value)">
      <map>
        <string key="type">HumanMadeObject</string>
        <string key="_label"><xsl:value-of select="$desc-value"/></string>
        <array key="dimension">
          <xsl:apply-templates select="map:array[@key='dimensions']/map:map" mode="dimension"/>
        </array>
      </map>
    </xsl:if>
  </xsl:template>
  
  <!-- have not yet addressed date, display or method keys (see object-4668): -->
  <xsl:template match="map:map" mode="dimensions">
    <xsl:variable name="desc-value">
      <xsl:call-template name="find-node">
        <xsl:with-param name="path" select="'description.value'"/>
      </xsl:call-template>
    </xsl:variable>
    <!--xsl:apply-templates select="map:map[@key='description']/map:string[@key='value']" mode="textual-object"/-->
    <xsl:if test="not(string($desc-value))">
      <xsl:apply-templates select="map:array[@key='dimensions']/map:map" mode="dimension"/>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="map:map" mode="dimension">
    <xsl:variable name="measurement" select="map:string[@key='dimension']/text()"/>
    <xsl:variable name="measurement-url">
      <xsl:choose>
        <xsl:when test="$measurement='Height'">
          <xsl:value-of select="'http://vocab.getty.edu/aat/300055644'"/>
        </xsl:when>
        <xsl:when test="$measurement='Width'">
          <xsl:value-of select="'http://vocab.getty.edu/aat/300055647'"/>
        </xsl:when>
        <xsl:when test="$measurement='Depth'">
          <xsl:value-of select="'http://vocab.getty.edu/aat/300072633'"/>
        </xsl:when>
        <xsl:when test="$measurement='Weight'">
          <xsl:value-of select="'http://vocab.getty.edu/aat/300056240'"/>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>
    <map>
      <string key="type">Dimension</string>
      <xsl:call-template name="classified-as">
        <xsl:with-param name="url" select="$measurement-url"/>
        <xsl:with-param name="label" select="$measurement"/>
      </xsl:call-template>
      <xsl:call-template name="dimension-summary"/>
      <xsl:call-template name="process-node-as-number">
        <xsl:with-param name="key" select="'value'"/>
        <xsl:with-param name="node" select="map:string[@key='value']"/>
      </xsl:call-template>
      <xsl:apply-templates select="map:string[@key='units']" mode="units-object"/>
    </map>
  </xsl:template>

    <!-- ** N.B. this summary doesn't appear, because we are now within the individual dimension object. 
              Agreed not to put it in as "referred_to_by" at the top level: -->
    <!--array key="referred_to_by">
      <xsl:apply-templates select="map:string[@key='display']" mode="textual-object">
        <xsl:with-param name="class-url" select="'http://vocab.getty.edu/aat/300435430'"/>
        <xsl:with-param name="class-label" select="'Dimensions description'"/>
      </xsl:apply-templates>
    </array-->
  
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

<!-- use location.@link.supplement if it has a value; otherwise summary.title.
        If using location.@link.supplement, don't output the URI (because it's the permanent location, i.e. it's wrong): -->
  <xsl:template match="map:map" mode="current-location">
    <xsl:variable name="temp-location">
      <xsl:call-template name="find-node">
        <xsl:with-param name="path" select="'@link.supplement'"/>
      </xsl:call-template>
    </xsl:variable>
    <map key="current_location">
      <string key="type">Place</string>
      <xsl:choose>
        <xsl:when test="string($temp-location)">
          <xsl:call-template name="find-and-process">
            <xsl:with-param name="path" select="'@link.supplement'"/>
            <xsl:with-param name="key" select="'_label'"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="linked-url">
            <xsl:with-param name="endpoint-path" select="'place'"/>
          </xsl:call-template>
          <xsl:call-template name="find-and-process">
            <xsl:with-param name="path" select="'summary.title'"/>
            <xsl:with-param name="key" select="'_label'"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </map>
  </xsl:template>  

  <xsl:template match="map:map" mode="carries">
    <map>
      <string key="type">LinguisticObject</string>
      <xsl:call-template name="classified-as">
        <xsl:with-param name="url" select="'http://vocab.getty.edu/aat/300028702'"/>
        <xsl:with-param name="label" select="'inscriptions'"/>
      </xsl:call-template>
      <xsl:call-template name="find-and-process">
        <xsl:with-param name="path" select="'summary'"/>
        <xsl:with-param name="key" select="'_label'"/>
      </xsl:call-template>
      <xsl:call-template name="find-and-process">
        <xsl:with-param name="path" select="'transcription.[0].value'"/>
        <xsl:with-param name="key" select="'content'"/>
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

<xsl:template match="map:map" mode="date-assigned">
  <xsl:if test="string(map:string[@key='from']) or string(map:string[@key='to'])">
    <array key="assigned_by">
      <map>
        <string key="type">AttributeAssignment</string>
        <map key="timespan">
          <string key="type">TimeSpan</string>
          <xsl:apply-templates select="map:string[@key='from']" mode="earliest"/>
          <xsl:apply-templates select="map:string[@key='to']" mode="latest"/>
        </map>
      </map>
    </array>
  </xsl:if>
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
  <xsl:variable name="prefix" select="map:map[@key='@link']/map:string[@key='prefix']"/>
  <xsl:variable name="suffix" select="map:map[@key='@link']/map:string[@key='suffix']"/>
    <map>
      <string key="type">Person</string>
      <xsl:call-template name="linked-url">
        <xsl:with-param name="endpoint-path" select="'person'"/>
      </xsl:call-template>
      <xsl:call-template name="find-and-process">
        <xsl:with-param name="path" select="'summary.title'"/>
        <xsl:with-param name="key" select="'_label'"/>
        <xsl:with-param name="prefix" select="$prefix"/>
        <xsl:with-param name="suffix" select="$suffix"/>
      </xsl:call-template>
    </map>
</xsl:template>

<xsl:template match="map:string" mode="access-lending">
  <map>
    <string key="type">LinguisticObject</string>
    <xsl:call-template name="sub-classified-as">
      <xsl:with-param name="class-url" select="'http://vocab.getty.edu/aat/300133046'"/>
      <xsl:with-param name="class-label" select="'access'"/>
      <xsl:with-param name="subclass-url" select="'http://vocab.getty.edu/aat/300069741'"/>
      <xsl:with-param name="subclass-label" select="'lending'"/>
    </xsl:call-template>    
    <string key="_label">Access: lending</string>
    <string key="content"><xsl:value-of select="."/></string>
  </map>
</xsl:template>

<xsl:template match="map:string" mode="image-rights">
  <map>
    <string key="type">LinguisticObject</string>
    <xsl:call-template name="sub-classified-as">
      <xsl:with-param name="class-url" select="'http://vocab.getty.edu/aat/300435434'"/>
      <xsl:with-param name="class-label" select="'Copyright/License Statement'"/>
      <xsl:with-param name="subclass-url" select="'http://vocab.getty.edu/aat/300418049'"/>
      <xsl:with-param name="subclass-label" select="'Brief Text'"/>
    </xsl:call-template>
    <string key="_label">Image Rights</string>
    <string key="content"><xsl:value-of select="."/></string>
  </map>
</xsl:template>

<xsl:template match="map:map" mode="part-of">
  <xsl:variable name="note" select="map:map[@key='@link']/map:map[@key='note']/map:string[@key='value']"/>
  <map>
    <string key="type">HumanMadeObject</string>
    <xsl:if test="string($note)">
      <array key="referred_to_by">
        <xsl:apply-templates select="$note" mode="note"/>
      </array>
    </xsl:if>
    <xsl:call-template name="linked-url">
      <xsl:with-param name="endpoint-path" select="'object'"/>
    </xsl:call-template>
    <xsl:call-template name="find-and-process">
      <xsl:with-param name="path" select="'summary.title'"/>
      <xsl:with-param name="key" select="'_label'"/>
    </xsl:call-template>
  </map>
</xsl:template>

<xsl:template match="map:map" mode="citation-note">
  <xsl:variable name="note" select="map:map[@key='note']/map:string[@key='value']"/>
  <xsl:if test="string($note)">
    <xsl:variable name="type" select="map:string[@key='type']"/>
    <xsl:variable name="page" select="map:string[@key='page']"/>
    <xsl:variable name="page-ref">
      <xsl:if test="string($page)">
        <xsl:value-of select="concat(' p.', $page)"/>
      </xsl:if>
    </xsl:variable>
    <xsl:variable name="note-type" select="concat($type, $page-ref)"/>
  <array key="referred_to_by">
      <xsl:apply-templates select="$note" mode="note">
        <xsl:with-param name="note-type" select="$note-type"/>
      </xsl:apply-templates>
  </array>
  </xsl:if>
</xsl:template>

</xsl:stylesheet>