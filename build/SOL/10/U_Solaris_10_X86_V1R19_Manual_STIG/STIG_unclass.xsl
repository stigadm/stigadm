<?xml version="1.0" encoding="utf-8" standalone="yes"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:cdf="http://checklists.nist.gov/xccdf/1.1">
	<!--******************************************************************************************************************************************-->
	<!-- Date:            Tuesday, 15 December 2009                                                                                              *-->
	<!-- Programmer: DISA/FSO                                                                                                                    *-->
	<!--                                                                                                                                         *-->
        <!--                                                                                                                                         *-->
	<!--                     Modified: Thursday, 25 February 2010 - IA Controls field included in code                                           *-->
	<!--                                   Friday, 12 March 2010 - Check boxes removed as per meeting held on 11 March 2010                      *-->
	<!--                                              The check box was part of the footer that appeared on each page.                           *-->
	<!--                                   Monday, 15 March 2010 - Sort order indicated on title page                                            *-->
	<!--                                                         This version sorts on Rule Version (STIG ID), ascending order                   *-->
        <!--                                                         There should not be any IAVA's processed by this version of the software        *-->
        <!--                 Wednesday, 7 April 2010 - Sort on STIG ID (STO-ALL-010, first 12 characters in a text-wise fashion)                     *-->
        <!--    Thursday, 20 May 2010 - Firefox fix, removed unnecessary "index" input argument into "buffer-overflow" subroutine                    *-->
        <!--                                                      No need to increment "index" variable within "buffer-overflow" subroutine.         *-->
        <!--      Tuesday, 1 June 2010 - Excel compatability fix (buffer-overflow subroutine parameters modified)                                    *-->
        <!--         Friday, 4 June 2010 - Markings on every printed page using HTML <title>                                                         *--> 
        <!--         Monday, 21 June 2010 - Allow maximum field size of 10,000 characters                                                            *-->
	<!--         Tuesday, 27 July 2010 - Removed artifact from Mitigation Control field                                                          *-->
	<!--         Monday, 2 August 2010 -  Preserved line feeds in Security Override Guidance field                                               *-->
	<!--         Monday, 9 August 2010 - Remove "Circle one/classification marking" annotation in front and "page break"                         *-->    
	<!--         Thursday, 14 October 2010 - Allow maximum field size of 11,000 characters                                                       *--> 
	<!--         Thursday, 13 January 2011 - Suppress <source> reference                                                                         *-->
	<!--         Thursday, 13 January 2011 - Suppress <notice> reference                                                                         *-->
	<!--         Thursday, 2 June 2011 - Sort on entire field  (JG)                                                                              *-->
	<!--         Thursday, 2 June 2011 - CCI field noted (JG)                                                                                    *-->
        <!--         Thursday, 20 October 2011 - "Security override" changed to "Severity override"                                                  *-->
        <!--         Thursday, 1 December 2011 - Multiple CCI's accomodated                                                                          *-->
        <!--         Monday, 9 January 2012 - CCI's more accurately identified, differentiated from CCE's                                            *-->
        <!--         Monday, 9 January 2012 - CCI reporting moved after the vul discussion                                                           *-->
        <!--         Monday, 9 January 2012 - XSL versioning comment introduced                                                                      *-->                                
        <!--         Tuesday, 21 February 2012 - CCI given line feeds in the appropriate places                                                      *-->
        <!--         Wednesday, 22 February 2012 - Text field expanded to accomodate maximum of 15,000 characters (was 11,000 characters)            *-->
    	<!--       Tuesday, 5 May 2012 - Production version of status field used for putting "Draft" in title                                        *-->
	<!--       Tuesday, 19 June 2012 - "SeverityOverride" recognized as a tag                                                                    *-->
        <!--       Thursday, 29 January 2015 - "Responsibility" field display removed                                                                *-->   
	<!--                                                                                                                                         *-->
        <!-- Used in: Removable Storage and External Connection Technologies, Version: 1, Release: .02 STIG                                          *-->
	<!-- *****************************************************************************************************************************************-->
	<!--Start of XML Benchmark Schema/Taxonomy Description                                                                                        -->
	<!--This documentation describes the NEW, APPROVED schema                                                                                     -->
	<!--
 
<Benchmark>    tag consists of the following:
                        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
                        xmlns:cpe="http://cpe.mitre.org/language/2.0"
                        xmlns:dc="http://purl.org/dc/elements/1.1/"
                        xmlns:xhtml="http://www.w3.org/1999/xhtml"
                        xmlns:dsig="http://www.w3.org/2000/09/xmldsig#"
                        xsi:schemaLocation="http://checklists.nist.gov/xccdf/1.1
                                                        http://nvd.nist.gov/schema/xccdf-1.1.4.xsd
                                                        http://cpe.mitre.org/dictionary/2.0
                                                        http://cpe.mitre.org/files/cpe-dictionary_2.1.xsd"
                        xmlns="http://checklists.nist.gov/xccdf/1.1"   vs.  xmlns:cdf="http://checklists.nist.gov/xccdf/1.1"
   <status/>
   <title/>
   <description/>
   <notice/>
   <front-matter/>
   <rear-matter/>
   <reference/>
   <plain-text/>
   <platform/>
   <version/>
   
   <Profile>         <!Profile is now upper-case ->
      <title/>
      <description>
         "<ProfileDescription>","</ProfileDescription>"
      <description/>
      <select/>      <!- vulid #1 ->
         .
         .
         .
      <select/>      <!- vulid #n ->
   </Profile>         <!Profile is now upper-case ->
         .  
         .
         .
         .
   <Profile>         <!- Profile #9 - MAC Level III - Classified ->
      <title/>
      <description> 
         "<ProfileDescription>","</ProfileDescription>"
      </description>
      <select/>      <!- vulid #1 ->
         .
         .
         .
      <select/>      <!- vulid #n ->
   </Profile>

   <Value>
        <title/>
        <description/>
        <value/>
   </Value>

   <Group>           <!- Group is now upper-case ->
      <title/>
      <description> 
         "<GroupDescription>","</GroupDescription>"
      </description>
      <Rule>          <!- Rule is now upper-case ->
         <version/>
         <title/>
         <description> 
             "<VulnDiscussion></VulnDiscussion>"
             "<FalsePositives></FalsePositives>"
             "<FalseNegatives></FalseNegatives>"
             "<Documentable></Documentable>"
             "<Mitigations></Mitigations>"
             "<SecurityOverrideGuidance></SecurityOverrideGuidance>"
             "<PotentialImpacts></PotentialImpacts>"
             "<ThirdPartyTools></ThirdPartyTools>"
             "<MitigationControl></MitigationControl>"
             "<Responsibility></Responsibility>"
             "<IAControls></IAControls>"
         </description>
         <fixtext/>
         <fix/>
         <check>
            <check-content-ref/>
            <check-content/>
         </check>
      </Rule>                    <!- close the Rule ->
   </Group>                    <!- close the Group, go on to next Group ->                                                                  -->
	<!--                                                                                                                                                              -->
	<!-- End of XML Benchmark schema description/taxonomy                                                                               -->
	<!-- ******************************************************************************************************************************-->
	<!-- *************************************************************************************************************** -->
	<!--                                List of templates currently used in this style sheet                                     -->
	<!--                                                                                                                                             -->
	<!--                 Template #0. Root template (match="/")                                                                   -->
	<!--                 Template #1. Benchmark template (select="cdf:Benchmark")                                     -->
	<!--                 Template #2. Group template (select="cdf:Group")                                                    -->
	<!--                 Template #3. Rule template (select="cdf:Rule")                                                        -->
	<!--                 Template #5: fixtext template (select="cdf:fixtext")                                                   -->
	<!--                 Template #6: fix template (select="cdf:fix")                                                              -->
	<!--                 Template #7: check template (select="cdf:check")                                                   -->
	<!--                 Template #8: check-content-ref template (select="cdf:check-content-ref")                  -->
	<!--                 Template #9: @href template (select="@href")                                                        -->
	<!--                 Template #10: check-content template (select="cdf:check-content")                         -->
	<!--                 Template #11: description" template (select="cdf:description")                                 -->
	<!-- ***************************************************************************************************************-->
	<xsl:template match="/">
		<html>
			<head>
				<title>
				UNCLASSIFIED                                                          <!-- 4 June 2010 - ANP -->
					<xsl:value-of select="cdf:Benchmark/title"/>
				</title>
			</head>
			<body>
				<br/>
				<br/>
				<br/>
				<br/>
				<br/>
				<br/>
				<br/>
				<br/>
				<!--       Revisions as of: 7 December 2009
            1. fonts made bigger<br/>
			2. GROUP ID (VULID): inserted<br/>
			3. FOUO removed <br/>
			4. Next - put in check boxes (probably table feature) <br/>
			5. Check on check field                                          <br/>
			6. Worked on title page                                          <br/>
			7. Clean up title page                                             <br/>
			8. Comment out unnecessary data                          <br/>
			9. Merge fields where possible                                <br/>
			10. Suppress blank fields at all costs                      <br/>
			11. Put in check template                                      <br/>
			12. Put in remaining templates                               <br/>
            13. Suprress OVAL                                               <br/>
            14. Supress "fix id", "fixtext refid"                           <br/>
 -->
                <br/>
                <br/>
                <p align="center">
			        <b>
				    <font size="7">UNCLASSIFIED                                                                                                   <!-- 15 December 2009 -->
				    </font>
			        </b>
			        <br/>
		        </p>
				<!-- ********************************************************************************************-->
				<!-- This is where we put in the code for the DoD and DISA logos                            -->
				<!-- DoD logo goes in the upper left corner, DISA logo goes in the upper right corner -->
				<!--********************************************************************************************-->
				<img width="1100" height="330" src="DoD-DISA-logos-as-JPEG.jpg" align="center"> </img>                           <!-- 15 December 2009 -->
				<!--***************************************** Apply Benchmark template (template #1) **************************************************************-->
				<xsl:apply-templates select="cdf:Benchmark"/>
				<!-- Benchmark template applied upon encountering "<Benchmark"-->
				<!-- DO NOT LOOP THROUGH XCCDF FILE FROM THIS LEVEL - DO IT WITHIN THE BENCHMARK TEMPLATE                             -->
				<!-- Other templates will not run from up here, invoke them within the actual cdf: Benchmark template                                               -->
			</body>
		</html>
	</xsl:template>
	<!-- Template #1: cdf:Benchmark template  - title page -->
	<!-- Start of Benchmark template (template #1) -->
	<xsl:template match="cdf:Benchmark">
		<!-- Benchmark template -->
&#160;
            <br/>
		<br/>
		<p align="center">
			<b>
				<font size="7"><xsl:value-of select="cdf:title"/>                 <!-- 15  December 2009 -->
				</font>
			</b>
			<br/>
		</p>
		<!-- Benchmark title              -->
		
		<!-- Benchmark status          -->
                <!-- Un-comment out status field - 15 May 2012 -->
		<p align="center">
			<b>    
                                <font size="7">
                                <xsl:if test="cdf:status='draft'">
                                     DRAFT
                                <br/>
                                </xsl:if>
				
                                </font>
			</b>
		</p>

		
		<p align="center">
			<b>
				<font size="7">Version:&#160;<xsl:value-of select="cdf:version"/>
				</font>
			</b>
			<br/>
		</p>
		<!-- Benchmark version         -->
		<!-- <p align="center"><b><font size= "7"><xsl:value-of select="cdf:plain-text"/></font></b><br/></p>                 -->
		<!-- Benchmark plain-text      -->
		<p align="center">
			<b>
				<font size="7">
					<xsl:value-of select="substring-before(cdf:plain-text,'Benchmark Date:')"/>               <!-- 15 December 2009 -->
				</font>
			</b>
			<br/>
		</p>
		<p align="center">
			<b>
				<font size="7">
					<xsl:value-of select="substring-after(cdf:plain-text,'Benchmark Date:')"/>
				</font>
			</b>
			<br/>
		</p>
		
		<!-- Comment out publisher - 15 December 2009 
		<p align="center">
			<b>
				<font size="7">
					<xsl:value-of select="cdf:reference/dc:publisher"/>
				</font>
			</b>
			<br/>
		</p>                                     
		<!- Reference publisher         -->
		<!-- "Source" commented out on 13 January 2011 -->
		<!-- <p align="center"> -->
			<!-- <b> -->
				<!-- <font size="5"> -->
				<!-- <xsl:value-of select="cdf:reference/dc:source"/> -->
				<!-- </font> -->
			<!-- </b> -->
			<!-- <br/> -->
		<br/><br/><br/><br/><br/>
		<!-- </p> -->
		<!-- ANP - 15 March 2010 - Sort order indicated in the title page -->

                                          <font size="5">
                        <b>XSL Release 1/29/2015 &#160;&#160;&#160;  Sort by: &#160; STIGID</b>     <!--ANP - 19 June 2012 -->
			</font>
			<br/>
	
		<!-- Reference source            -->
		<!-- "Notice" commented out on 13 January 2011 -->
		<!-- <b>Notice:</b>&#160;<xsl:value-of select="cdf:notice/@id"/>       -->
		<!-- <br/>                                                                                        -->
		<!-- Benchmark notice             -->
			<font size="5">
				<b>Description:</b>&#160;<xsl:value-of select="cdf:description"/>
			</font>
			<br/>
			<!-- Benchmark description   -->      
			<xsl:if test="string-length(cdf:front-matter) &gt; 0">     <!-- 16 December 2009 - only process front matter if it exists -->
			    <b>Benchmark front matter</b>:&#160;<br/>
			    <xsl:call-template name="this-is-a-subroutine">
				    <xsl:with-param name="string-size" select="string-length(cdf:front-matter)"/>
				    <xsl:with-param name="string-target" select="cdf:front-matter"/>
				    <xsl:with-param name="index" select="1"/>
			     </xsl:call-template>
			<br/>
			</xsl:if>
			<br/>
			
			<xsl:if test="string-length(cdf:rear-matter) &gt; 0">      <!-- 16 December 2009 - only process rear matter if it exists -->
			   <b>Benchmark rear matter</b>:&#160;<br/>
			   <xsl:call-template name="this-is-a-subroutine">
				   <xsl:with-param name="string-size" select="string-length(cdf:rear-matter)"/>
				   <xsl:with-param name="string-target" select="cdf:rear-matter"/>
				   <xsl:with-param name="index" select="1"/>
			    </xsl:call-template>
			    <br/>
	    </xsl:if>
		<!-- ANP - 9 August 2010 -->  
		<font size="9">
	    _____________________________________________________________
			<br/>
			<!-- ANP - 9 August 2010 -->
		</font>
		<!-- *****************************************************************************************
		<br/>
		<p align="center">
			<b>
				<font size="5">CIRCLE ONE</font>
			</b>
		</p>
		<p align="center">
			<b>
				<font size="5">FOR OFFICIAL USE ONLY </font>
			</b>
			<font size="5">(mark each page)</font>
		</p>
		<p align="center">
			<b>
				<font size="5">CONFIDENTIAL and SECRET </font>
			</b>
			<font size="5">
			  		  (mark each page and each finding)</font>
		</p>
		<br/>
		<br/>
		<br/>
		<p>
			<font size="5">Classification is based on classification of system reviewed:<br/>
				<br/>
			  Unclassified System = FOUO Checklist<br/>
			  Confidential System = CONFIDENTIAL Checklist<br/>
			  Secret System= SECRET Checklist<br/>
			  Top Secret System = SECRET Checklist<br/>
			</font>
		</p>
		<br/>
		<br/>
		<br/>
		<br/>
		<br/>
		<br/>
		<br/>
		<br/>
		<br/>
		<br/>
		<br/>
		<br/>
		<br/>
		<br/>
		<br/>
		<br/>
		<br/>
		<br/>
		<br/>
		<br/>
		<br/>
		<br/>
		<br/>
		<br/>
        ********************************************************************* -->
		<!-- ****************************************************************-->
		<!-- cdf:Group code goes here, cdf: Rule code goes here     -->
		<!-- ****************************************************************-->
		<xsl:for-each select="cdf:Group">
	         <xsl:sort data-type="text" select="cdf:Rule/cdf:version"/>                    <!-- JG - 2 June 2011, code for sorting  -->
	         <!-- ANP - 7 April 2010 -->
	         <!-- xsl:value-of select="substring(cdf:Rule,1,9)"/>                                        debug mode     -->                            
	         <!--xsl:sort data-type="text" select="substring(cdf:Rule,7,6)"/>             ANP - 15 March 2010, commented out 7 April 2010 -->            
			<xsl:apply-templates select="."/>
			<!-- We will invoke the cdf:Group template here       -->
			<xsl:for-each select="cdf:Rule">
				<xsl:apply-templates select="."/>
				<!-- We will invoke the cdf:Rule template here         -->
                                                       <xsl:for-each select="cdf:ident[@system='http://iase.disa.mil/cci']"><br/>   <!-- ANP - 9 January 2012 -->  <!-- ANP - 21 Feb 2012 -->
                                                       <xsl:apply-templates select="."/>             
                          	                           </xsl:for-each>
                                                       <font size="9">

	                                          _____________________________________________________________<br/>
			              <br/>
	
	              	              </font>
			</xsl:for-each>
		</xsl:for-each>
                            <br/>
                            <br/>
                            <p align="center">
			        <b>
				    <font size="7">UNCLASSIFIED                                                                                                   <!-- 15 December 2009 -->
				    </font>
			        </b>
			        <br/>
		        </p>		
	</xsl:template>
	<!-- End of cdf:Benchmark template (template #1)    -->
	<!-- *************************************************************************************************************************************************************-->
	<!-- Template #2: cdf:Group template goes here -->
	<!-- Start of "cdf:Group" template (template #2) -->
	<xsl:template match="cdf:Group">
	    <!-- <font size="9">                       -->                <!-- 15 December 2009 -->  
	    <!-- _____________________________________________________________<br/><br/>  -->
		<!-- <hr size="7"/>                                                                      <!- 15 December 2009 -->
		<!-- </font> -->
		
		<font size="5">
			<b>Group ID (Vulid):&#160;</b></font>
			<font size="5" color="black">                               <!-- ANP - 15 March 2010 -->
			<xsl:value-of select="@id"/>
		    </font>
		<br/>
		<!-- Group id (vulid)                 -->
		<font size="5">
			<b>Group Title:&#160;</b></font>
			<font size="5" color="black">                               <!-- ANP - 15 March 2010 -->
			<xsl:value-of select="cdf:title"/>
		    </font>
		<br/>                                                   <!-- 15 December 2009 -->
		<!-- Group cdf:title                  -->
		<!-- There must be text between  "<VulnDiscussion>this is vulnerability text</VulnDiscussion>"         -->
		<!-- <xsl:apply-templates select="cdf:description"/> -->
		<!-- invokes "cdf:description" template #12       -->
	</xsl:template>
	<!-- End of "cdf:Group" template (template #2) -->
	<!--************************************************************************************************************************************************************-->
	<!-- Template #3: cdf:Rule template goes here -->
	<!-- Start of "cdf:Rule" template (template #3) -->
	<xsl:template match="cdf:Rule">
		<!-- <p align="left">     -->                      <!-- 15 December 2009 -->
		<!-- <font size="5">&#160;</font>  -->    <!-- 15 December 2009 -->
		<!-- </p> -->                                         <!-- 15 December 2009 -->
		<!--<b>Rule:</b>&#160;<xsl:value-of select="."/><br/>      -->
		<!-- Rule, no need to print it out -->
		<font size="5">
			<b>Rule ID:&#160;</b></font>
			<font size="5" color="black">                               <!-- ANP - 15 March 2010 -->
			<xsl:value-of select="@id"/>
		    </font>
		<br/>
		<!-- Rule id                             -->
		<!-- <font size="5">
			<b>DIACAP Impact Code:&#160;</b>                 <!- 15 December 2009 ->
			<xsl:value-of select="@severity"/>
		</font>
		<br/> -->
		
		<!-- Rule impact (severity)        -->
		<xsl:if test="@severity='high' ">
			<font size="5">
				<b>Severity: CAT I</b>
				<br/>
			</font>
		</xsl:if>
		<xsl:if test="@severity='medium' ">
			<font size="5">
				<b>Severity: CAT II</b>
				<br/>
			</font>
		</xsl:if>
		<xsl:if test="@severity='low' ">
			<font size="5">
				<b>Severity: CAT III</b>
				<br/>
			</font>
		</xsl:if>
		<font size="5">
			<b>Rule Version (STIG-ID):&#160;</b></font>     <!-- 15 December 2009 -->
			<font size="5" color="blue">                               <!-- ANP - 15 March 2010 -->
			<xsl:value-of select="cdf:version"/>
		    </font>
		<br/>
		<!-- cdf:Rule version                   -->
		<font size="5">
			<b>Rule Title:&#160;</b>
			<xsl:value-of select="cdf:title"/>
		</font>
		<br/>
		<br/>
		<!-- cdf:Rule title                        -->
		<!-- <font size= "5"><b>Rule Description:&#160;</b><xsl:value-of select="cdf:description"/></font><br/><br/>          <!-  cdf:Rule description             -->
		<!-- ANP - 9 January 2012 - code invoking cdf:ident was commented out to prevent CCI's in the middle -->
                            <!-- <xsl:for-each select="cdf:ident"> -->
                            <!-- <b>this is the cdf ident portion</b> -->
                            
                            <!-- <xsl:apply-templates select="."/> -->
                          	<!-- </xsl:for-each> -->
                            <br/>	
                            <xsl:apply-templates select="cdf:description"/>
		<!-- invokes "cdf:description:" template #11                                                       -->

		<!-- invokes "cdf:ident" template #4, sub-referenced within "cdf:Rule" template #3 -->
		<!-- ****************************************************************************************************************************************************************-->
		<!--    Structure is <cdf:fixtext></cdf:fixtext><cdf:fix></cdf:fix><cdf:check><cdf:check-content-ref/><cdf:check-content/></cdf:check> [see below]     
         <cdf:fixtext/>
         <cdf:fix/>
         <cdf:check>
            <cdf:check-content-ref/>
            <cdf:check-content/>
         </cdf:check>                                                                       -->
		<!--***************************************************************************************************************************************************************-->
		<xsl:apply-templates select="cdf:check"/>
		<!-- invokes "check" template #7, sub-referenced within "cdf:Rule" template #4 -->
		<xsl:apply-templates select="cdf:fixtext"/>
		<!-- invokes "fixtext" template # 5, sub-referenced within "cdf:Rule" template #4 -->
		<xsl:apply-templates select="cdf:fix"/>
		<!-- invokes "fix" template #6, sub-referenced within "cdf:Rule" template #4       -->
		<!-- <br/>       ANP - 12 March 2010 -->
   &#160;
   <!-- The following code was commented out in order to remove the checkboxes - ANP - 12 March 2010 
   <br/>
		<table border="1" cellpadding="12">
			<tbody>
				<tr>
					<td width="15%" align="left">
						<font size="5">Open</font>
					</td>
					<td width="85%" align="left">
						<font size="5">Comments:</font>
					</td>
				</tr>
				<tr>
					<td width="15%" align="left">
						<font size="5">Not a Finding</font>
					</td>
				</tr>
				<tr>
					<td width="15%" align="left">
						<font size="5">Not Applicable</font>
					</td>
				</tr>
				<tr>
					<td width="15%" align="left">
						<font size="5">Not Reviewed</font>
					</td>
				</tr>
			</tbody>
		</table>
        The previous code was commented out in order to remove the checkboxes - ANP - 12 March 2010 -->
        <!-- <br/>                                                                      15 December 2009, commented out 12 Mar 2010 -->
     	<!-- <br/>                                                                      15 December 2009, commented out 12 Mar 2010 -->
              <!-- ANP - 9 Jan 2012 - Rule underscore separation was moved up due to CGI's being at the end -->
	</xsl:template>
	<!-- End of "cdf:Rule" template (template #3) -->
	<!--*****************************************************************************************************************************************************************************-->
	<!-- Template #4: Ident template, referenced by "def:rule" template (template #3) -->
	<!-- Start of "cdf:ident" template (template #4) -->
	<xsl:template match="cdf:ident">
		<!-- <font size="5">This indicates that we have an OVAL instance</font><br/>      -->
		<!-- This can be commented out                   -->    <!-- 15 December 2009 -->
		<!-- <font size="5">
			<b>Rule System:&#160;</b>
			<xsl:value-of select="@system"/> -->
		
		
		<br/><font size="5">  <!-- ANP - 21 February 2012 -->
			<b>CCI:&#160;</b>
			<xsl:value-of select="."/>
		</font>
		<br/>

	</xsl:template>
	<!-- End of "ident" template (template #4)     -->
	<!-- *******************************************************************************************************************************************************************************-->
	<!-- Template # 5: cdf:fixtext template, referenced by "cdf:rule" template (template #3) -->
	<!-- Start of "cdf:fixtext" template (template # 5) -->
	<xsl:template match="cdf:fixtext">
		<br/>
		<!--<font size= "5"><b>Fix Text Ref:&#160;</b><xsl:value-of select="@fixref"/></font><br/                   <!- fix reference                                             -->
		<xsl:if test="string-length(.)>0">
			<font size="5">
				<b>Fix Text:&#160;</b>
				<!-- <xsl:value-of select="."/></font><br/>                          <!- cdf:fixtext                                                -->
				<xsl:call-template name="buffer-overflow">
					<xsl:with-param name="string-size" select="string-length(.)"/>
					<xsl:with-param name="string-target" select="."/>
				</xsl:call-template>
			</font>
		</xsl:if>
	</xsl:template>
	<!-- End of "cdf:fixtext" template (template # 5) -->
	<!-- *******************************************************************************************************************************************************************************-->
	<!-- Template #6: cdf:fix template, referenced by "cdf:rule" template (template #4) -->
	<!-- Start of "cdf:fix" template (template #6)       -->
	<xsl:template match="cdf:fix">
		<!--<br/> -->
		<!--<font size= "5"><b>Fix ID:&#160;</b><xsl:value-of select="@id"/></font><br/>                                <!- cdf:fix id                                                   -->
	</xsl:template>
	<!-- End of "cdf:fix" template (template #6)       -->
	<!-- *******************************************************************************************************************************************************************************-->
	<!-- Template #7: "cdf:check" template, referenced by "cdf:rule" template (template #4) -->
	<!-- Start of "cdf:check" template (template # 7)     -->
	<xsl:template match="cdf:check">
		<!-- **************************************************************************************-->
		<!-- *     Here is where we put in the check for @system = "http://oval"           *-->
		<!-- **************************************************************************************-->
		<xsl:if test="not(substring(@system,1,11)='http://oval') ">
			<!-- Only process if string not equal to "http://oval" -->
			<br/>
			<!-- <font size= "5"><b>Check System:&#160;</b><xsl:value-of select="@system"/></font><br/>  <!- Check system -->
			<xsl:apply-templates select="cdf:check-content-ref"/>
			<!-- invokes "cdf:check-content-ref" template # 8   -->
			<xsl:apply-templates select="cdf:check-content"/>
			<!-- invokes "cdf:check-content" template #10       -->
		</xsl:if>
	</xsl:template>
	<!-- End of "cdf:check" template (template #7)       -->
	<!-- *******************************************************************************************************************************************************************************-->
	<!-- Template #8: "cdf:check-content-ref" template, referenced by "cdf:check" template (template # 7) -->
	<!-- Start of "cdf:check-content-ref" template (template # 8) -->
	<!--                                                                                -->
	<!-- Comment out check content ref name - 15 December 2009
	<xsl:template match="cdf:check-content-ref">
		<font size="5">
			<b>Check Content Ref Name:&#160;</b>
		</font>
		<xsl:if test="(substring(@name,1,1)='M')">
			<xsl:if test="string-length(@name)=1">
				<font size="5">Manual<br/>
				</font>
			</xsl:if>
		</xsl:if>
		<xsl:if test="not(substring(@name,1,1)='M')">
			<font size="5">
				<xsl:value-of select="@name"/>
			</font>
			<br/>
		</xsl:if>
		<xsl:apply-templates select="@href"/>
		<!- invokes "@href" template #9                                     
	</xsl:template>                                                               -->
	<!-- End of "cdf:check-content-ref" template (template # 8)   -->
	
	<!-- *******************************************************************************************************************************************************************************-->
	<!-- Template #9: "href" template, referenced by "cdf:check-content-ref" template (template # 7) -->
	<!-- Start of href" template (template # 9) -->
	<xsl:template match="@href">
		<font size="5">
			<b>Check Content Ref Href:&#160;</b>
		</font>
		<font size="5">
			<xsl:value-of select="."/>
		</font>
		<!-- <br/> -->    <!-- 15 December 2009 -->
	</xsl:template>
	<!-- End of "href" template (template # 9) -->
	<!-- ***********************************************************************************************************************************************************************************-->
	<!-- Template #10: "cdf:check-content" template, referenced by "cdf:check" template (template # 7) -->
	<!-- Start of "cdf:check-content" template (template # 10)-->
	<xsl:template match="cdf:check-content">
		<font size="5">
			<b>Check Content:</b>&#160;   <br/>
			<!--      <xsl:value-of select="."/>       <!- Check content      -->
			<xsl:call-template name="buffer-overflow">
				<xsl:with-param name="string-size" select="string-length(.)"/>
				<xsl:with-param name="string-target" select="."/>
			</xsl:call-template>
			<br/>   
		</font>
	</xsl:template>
	<!-- End of "check-content" template (template # 10)       -->
	<!-- ***********************************************************************************************************************************************************************************-->
	<!-- Template #11: "cdf:description" template, referenced by "cdf:Rule" template (template # 3) -->
	<!-- Start of "cdf:check-content" template (template # 11) -->
	<xsl:template match="cdf:description">
		<!--<font size= "5"><b>Rule Description:</b>&#160;<xsl:value-of select="."/></font><br/>  -->
		<!-- Rule description   -->
		<!-- 1. Vulnerability Discussion - only if not "<VulnDiscussion></VulnDiscussion>"                            -->
		<!-- There must be text between  "<VulnDiscussion>this is vulnerability text</VulnDiscussion>"         -->
		<xsl:if test="string-length(substring-after(substring-before(.,'&lt;/VulnDiscussion&gt;'), '&lt;VulnDiscussion&gt;'))>0">
			<font size="5">
				<b>Vulnerability Discussion:</b>&#160;</font>
			<!-- <br/>    -->
			<!-- <font size= "5">
   <b>STRING LENGTH:&#160;</b>
     <xsl:value-of select="string-length(substring-after(substring-before(.,'&lt;/VulnDiscussion&gt;'), '&lt;VulnDiscussion&gt;'))"/>
    <xsl:value-of select="substring-after(substring-before(.,'&lt;/VulnDiscussion&gt;'),
                                   '&lt;VulnDiscussion&gt;')"/></font><br/><br/>  -->
			<font size="5">
				<xsl:call-template name="buffer-overflow">
					<xsl:with-param name="string-size" select="string-length(substring-after(substring-before(.,'&lt;/VulnDiscussion&gt;'), '&lt;VulnDiscussion&gt;'))"/>
					<xsl:with-param name="string-target" select="substring-after(substring-before(.,'&lt;/VulnDiscussion&gt;'),
                                   '&lt;VulnDiscussion&gt;')"/>
				</xsl:call-template>
			</font>
			<br/>
			<br/>
		</xsl:if>
		<!-- 2. False Positives - only if not "<FalsePositives></FalsePositives>"                                           -->
		<!-- There must be text between  "<FalsePositives>this is false positive text</FalsePositives>"          -->
		<xsl:if test="string-length(substring-after(substring-before(.,'&lt;/FalsePositives&gt;'), '&lt;FalsePositives&gt;'))>0">
			<font size="5">
				<b>False Positives:</b>&#160;</font>
			<br/>
			<font size="5">
				<xsl:value-of select="substring-after(substring-before(.,'&lt;/FalsePositives&gt;'),
                                   '&lt;FalsePositives&gt;')"/>
			</font>
			<br/>
			<br/>
		</xsl:if>
		<!-- 3. False Negatives - only if not "<FalseNegatives></FalseNegatives>"                                        -->
		<!-- There must be text between  "<FalseNegatives>this is false negative text</FalseNegatives>"       -->
		<xsl:if test="string-length(substring-after(substring-before(.,'&lt;/FalseNegatives&gt;'), '&lt;FalseNegatives&gt;'))>0">
			<font size="5">
				<b>False Negatives:</b>&#160;</font>
			<br/>
			<font size="5">
				<xsl:value-of select="substring-after(substring-before(.,'&lt;/FalseNegatives&gt;'),
                                   '&lt;FalseNegatives&gt;')"/>
			</font>
			<br/>
			<br/>
		</xsl:if>
		<!-- 4. Documentable - only if "<Documentable>true</Documentable>"                                          -->
		<!-- There must be text between  "<Documentable>this is documentable text</Documentable>"      -->
		<xsl:if test="string-length(substring-after(substring-before(.,'&lt;/Documentable&gt;'), '&lt;Documentable&gt;'))=4">
			<font size="5">
				<b>Documentable:</b>&#160;YES</font>   <!-- 15 December 2009 -->
			<!-- <br/>   -->                                                <!-- 15 December 2009 -->
			<font size="5">
				<!-- <xsl:value-of select="substring-after(substring-before(.,'&lt;/Documentable&gt;'),
                                   '&lt;Documentable&gt;')"/>    -->               <!-- 15 December 2009 -->
			</font>
			<br/>
            <!-- <br/>     -->                                                             <!-- 15 December 2009 -->
		</xsl:if>
		<!-- 5. Mitigations - only if not "<Mitigations></Mitigations>"                                           -->
		<!-- There must be text between  "<Mitigations>this is mitigations text</Mitigations>"      -->
		<xsl:if test="string-length(substring-after(substring-before(.,'&lt;/Mitigations&gt;'), '&lt;Mitigations&gt;'))>0">
			<font size="5">
				<b>Mitigations:</b>&#160;</font>
			<br/>
			<font size="5">
				<xsl:value-of select="substring-after(substring-before(.,'&lt;/Mitigations&gt;'),
                                   '&lt;Mitigations&gt;')"/>
			</font>
			<br/>
			<br/>
		</xsl:if>
		<!-- 6a. SecurityOverrideGuidance - only if not "<SecurityOverrideGuidance></SecurityOverrideGuidance>"                                           -->
		<!-- There must be text between  "<SecurityOverrideGuidance>this is security override guidance text</SecurityOverrideGuidance>"      -->
		<xsl:if test="string-length(substring-after(substring-before(.,'&lt;/SecurityOverrideGuidance&gt;'), '&lt;SecurityOverrideGuidance&gt;'))>0">
			<font size="5">
				<b>Severity Override Guidance:</b>&#160;</font>
			<br/>
			<font size="5">
					<xsl:call-template name="buffer-overflow">
					<xsl:with-param name="string-size" select="string-length(substring-after(substring-before(.,'&lt;/SecurityOverrideGuidance&gt;'), '&lt;SecurityOverrideGuidance&gt;'))"/>
					<xsl:with-param name="string-target" select="substring-after(substring-before(.,'&lt;/SecurityOverrideGuidance&gt;'),
                                   '&lt;SecurityOverrideGuidance&gt;')"/>	
					</xsl:call-template>
			</font>
			<br/>
			<br/>
		</xsl:if>
		<!-- 6b. SeverityOverrideGuidance - only if not "<SeverityOverrideGuidance></SeverityOverrideGuidance>"                                           -->
		<!-- There must be text between  "<SeverityOverrideGuidance>this is severity override guidance text</SeverityOverrideGuidance>"      -->
		<xsl:if test="string-length(substring-after(substring-before(.,'&lt;/SeverityOverrideGuidance&gt;'), '&lt;SeverityOverrideGuidance&gt;'))>0">
			<font size="5">
				<b>Severity Override Guidance:</b>&#160;</font>
			<br/>
			<font size="5">
					<xsl:call-template name="buffer-overflow">
					<xsl:with-param name="string-size" select="string-length(substring-after(substring-before(.,'&lt;/SeverityOverrideGuidance&gt;'), '&lt;SeverityOverrideGuidance&gt;'))"/>
					<xsl:with-param name="string-target" select="substring-after(substring-before(.,'&lt;/SeverityOverrideGuidance&gt;'),
                                   '&lt;SeverityOverrideGuidance&gt;')"/>	
					</xsl:call-template>
			</font>
			<br/>
			<br/>
		</xsl:if>
		<!-- 7. Potential Impacts - only if not "<PotentialImpacts></PotentialImpacts>"                -->
		<!-- There must be text between  "<Potential Impacts>this is potential impact text</Potential Impacts>"      -->
		<xsl:if test="string-length(substring-after(substring-before(.,'&lt;/PotentialImpacts&gt;'), '&lt;PotentialImpacts&gt;'))>0">
			<font size="5">
				<b>Potential Impacts:</b>&#160;</font>
			<br/>
			<font size="5">
				<xsl:value-of select="substring-after(substring-before(.,'&lt;/PotentialImpacts&gt;'),
                                   '&lt;PotentialImpacts&gt;')"/>
			</font>
			<br/>
			<br/>
		</xsl:if>
		<!-- 8. Third Party Tools - only if not "<ThirdPartyTools></ThirdPartyTools>"                                               -->
		<!-- There must be text between  "<ThirdPartyTools>this is Third Party Tools text</ThirdPartyTools>"          -->
		<!--                                                                                                                                                      -->
		<!-- Comment out third party tools - 15 December 2009
		<xsl:if test="string-length(substring-after(substring-before(.,'&lt;/ThirdPartyTools&gt;'), '&lt;ThirdPartyTools&gt;'))>0">
			<font size="5">
				<b>Third Party Tools:</b>&#160;</font>
			<br/>
			<font size="5">
				<xsl:value-of select="substring-after(substring-before(.,'&lt;/ThirdPartyTools&gt;'),
                                   '&lt;ThirdPartyTools&gt;')"/>
			</font>
			<br/>
			<br/>
		</xsl:if>                                                                                                                                                -->
		
		<!-- 9. Mitigation Control - only if not "<Mitigation Control></Mitigation Control>"                                          -->
		<!-- There must be text between  "<Mitigation Control>this is mitigation control text</Mitigation Control>"      -->
		<xsl:if test="string-length(substring-after(substring-before(.,'&lt;/MitigationControl&gt;'), '&lt;MitigationControl&gt;'))>1">
			<font size="5">
				<b>Mitigation Control:</b>&#160;</font>
			<br/>
			<font size="5">
			<!--<xsl:value-of select="substring-after(substring-before(.,'&lt;/MitigationControl&gt;'),
                                   '&lt;MitigationControl&gt;')"/>
			</font>
			<br/>
			<br/> -->
		   <xsl:call-template name="buffer-overflow">
           <xsl:with-param name="string-size" select="string-length(substring-after(substring-before(.,'&lt;/MitigationControl&gt;'), '&lt;MitigationControl&gt;'))"/>
           <xsl:with-param name="string-target" select="substring-after(substring-before(.,'&lt;/MitigationControl&gt;'),
                                   '&lt;MitigationControl&gt;')"/>
             </xsl:call-template>
            </font>  <!-- ANP - 27 July 2010 -->
			<br/>
			<br/>
		</xsl:if>
		<!-- 10. Responsibility - only if not "<Responsibility></Responsibility>"                                        -->
		<!-- 11. IAControls - only if not "<IAControls></IAControls>"                                                              -->
		<!-- There must be text between  "<IAControls>this is IA Control text</IAControls>"                            -->
	
		<xsl:if test="string-length(substring-after(substring-before(.,'&lt;/IAControls&gt;'), '&lt;IAControls&gt;'))>0">
			<font size="5">
				<b>IAControls:</b>&#160;</font>    <!-- IAControls now takes only one line -->
			<!-- <br/>   -->                                          <!-- 15 December 2009 -->
			<font size="5">
				<xsl:value-of select="substring-after(substring-before(.,'&lt;/IAControls&gt;'),
                                   '&lt;IAControls&gt;')"/>
			</font>
			<br/>
		</xsl:if>
		<!-- &lt;VulnDiscussion&gt;                        -->
		<!--   "<VulnDiscussion>"  artificial start tag -->
		<!--&lt;/VulnDiscussion&gt;                        -->
		<!--   "</VulnDiscussion>" artificial end tag  -->
		<!--&lt;FalsePositives&gt;                           -->
		<!--   "<FalsePositives>"    artificial start tag -->
		<!--&lt;/FalsePositives&gt;                          -->
		<!--   "</FalsePositives>"   artificial end tag  -->
		<!--&lt;FalseNegatives&gt;                          -->
		<!--   "<FalseNegatives>"   artificial start tag -->
		<!--&lt;/FalseNegatives&gt;                         -->
		<!--   "</FalseNegatives>"  artificial end tag  -->
		<!-- &lt;Documentable&gt;                           -->
		<!--    "<Documentable>"    artificial start tag -->
		<!-- &lt;/Documentable&gt;                          -->
		<!--    "</Documentable>"   artificial end  tag -->
		<!-- &lt;Mitigations&gt;                                -->
		<!--    "<Mitigations>"         artificial start tag -->
		<!-- &lt;/Mitigations&gt;                               -->
		<!--    "</Mitigations>"        artificial end  tag -->
		<!-- &lt;SecurityOverrideGuidance&gt;                                -->
		<!--    "<SecurityOverrideGuidance>"         artificial start tag -->
		<!-- &lt;/SecurityOverrideGuidance&gt;                               -->
		<!--    "</SecurityOverrideGuidance>"        artificial end  tag -->
		<!-- &lt;PotentialImpacts&gt;                             -->
		<!--    "<PotentialImpacts>"      artificial start tag -->
		<!-- &lt;/PotentialImpacts&gt;                            -->
		<!--    "</PotentialImpacts>"     artificial end  tag -->
		<!-- &lt;ThirdPartyTools&gt;                               -->
		<!--    "<ThirdPartyTools>"        artificial start tag -->
		<!-- &lt;/ThirdPartyTools&gt;                              -->
		<!--    "</ThirdPartyTools>"       artificial end  tag -->
		<!-- &lt;MitigationControl&gt;                             -->
		<!--    "<MitigationControl>"      artificial start tag -->
		<!-- &lt;/MitigationControl&gt;                             -->
		<!--    "</MitigationControl>"     artificial end  tag  -->
		<!-- &lt;Responsibility&gt;                                  -->
		<!--    "<Responsibility>"          artificial start tag -->
		<!-- &lt;/Responsibility&gt;                                -->
		<!--    "</Responsibility>"         artificial end  tag -->
		<!-- &lt;IAControls&gt;                                      -->
	    <!--    "<IAControls>"          artificial start tag     -->
		<!-- &lt;/IAControls&gt;                                    -->
		<!--    "</IAControls>"         artificial end  tag     -->
	</xsl:template>
	<!-- End of "cdf:description" template (template # 11)   -->
	<xsl:template match="cdf:group/cdf:description">
		<!-- There must be text between  "<VulnDiscussion>this is vulnerability text</VulnDiscussion>"         -->
		<xsl:if test="string-length(substring-after(substring-before(.,'&lt;/GroupDescription&gt;'), '&lt;GroupDescription&gt;'))>0">
			<font size="5">
				<b>Group Discussion:</b>&#160;</font>
			<br/>
			<font size="5">
				<xsl:value-of select="substring-after(substring-before(.,'&lt;/GroupDescription&gt;'),
                                   '&lt;GroupDescription&gt;')"/>
			</font>
			<br/>
			<!-- <br/>     -->     <!-- 15 December 2009 -->
		</xsl:if>
	</xsl:template>
	<!-- *************************************************************************************************************************************-->
	<!--       The following subroutine performs a transformation that preserves all the line feeds and tabs found                    -->
    <!--       in the original XML file thus making the text more human-readable                                                                  -->
	<!--       It changes all line feeds to <br/>                                                                                                                  -->
	<!--       It changes all tabs to 5 spaces, that is, &#160; &#160; &#160; &#160; &#160;                                                -->
	<!-- *************************************************************************************************************************************-->
	<xsl:template name="this-is-a-subroutine">
		<xsl:param name="string-size"/>
		<xsl:param name="string-target"/>
		<xsl:param name="index"/>
		<!-- <b>This is a subroutine</b><br/> -->
		<!-- <b>This is the text length:</b>&#160; -->
		<!-- <xsl:value-of select="$string-size"/><br/> -->
		<!-- <b>This is the index:</b>&#160; -->
		<!--  <xsl:value-of select="$index"/><br/> -->
		<xsl:if test="$index &lt;= $string-size and $string-size &gt;= 0">
			<!--<b>String is:&#160;"</b>-->
			<!-- <xsl:value-of select="substring($string-target,$index,1)"/>    -->
			<xsl:choose>
				<xsl:when test="substring($string-target,$index,1) = '&#xD;' ">
					<!-- Convert line feed to <br/>    -->
					<br/>
				</xsl:when>
				<xsl:when test="substring($string-target,$index,1) = '&#xA;' ">
					<!-- Convert new line to <br/>     -->
					<br/>
				</xsl:when>
				<xsl:when test="substring($string-target,$index,1) = '&#x9;' ">
					<!-- Convert tab to 5 spaces      -->
                 &#160;&#160;&#160;&#160;&#160;
          </xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="substring($string-target,$index,1)"/>
					<!-- Otherwise, print out charcter as it is -->
				</xsl:otherwise>
			</xsl:choose>
			<xsl:call-template name="this-is-a-subroutine">
				<xsl:with-param name="string-size" select="$string-size"/>
				<xsl:with-param name="string-target" select="$string-target"/>
				<xsl:with-param name="index" select="$index + 1"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>

    <!-- *************************************************************************************************************************************-->
	<!--       The following subroutine prevents recursive overflow for fields up to 11,000 characters long                               -->
	<!--       If a field is greater than 11,000 characters, the program will write out the first 11,000 characters.                      -->
	<!--                                                                                                                                                                       -->
	<!--       If string is from 1 to 1,000 characters long then;                                                                                            -->
	<!--             1. Print out all the characters, flush buffer, return                                                                                    -->
	<!--                                                                                                                                                                       -->
	<!--       Else if string is 1,001 to 2,000 characters long then;                                                                                    -->
	<!--            1. print out 1st 1,000 characters, flush buffer                                                                                          -->
	<!--            2. print out characters 1,001 to string-length, flush buffer, return                                                               -->
	<!--                                                                                                                                                                      -->
	<!--       Else if string is 2,001 - 3,000 characters long then;                                                                                      -->
	<!--            1. print out 1st 1,000 characters, flush buffer                                                                                          -->
	<!--            2. print out characters 1,001 to 2,000, flush buffer                                                                                  -->
	<!--            3. print out characters 2,001 to string length, return                                                                               -->
	<!--                                                                                                                                                                     -->
	<!--                                                                                                                                                                      -->
	<!--      Else                                                                                                                                                          -->
	<!--                             ************                                                                                                                          -->
	<!--      Else                                                                                                                                                          -->
	<!--                             ************                                                                                                                          -->
	<!--      Else                                                                                                                                                         -->
	<!--                             ************                                                                                                                          -->
	<!--       Else if string is 10,001 - 11,000 characters long then;                                                                                    -->
	<!--            1. print out 1st 1,000 characters, flush buffer                                                                                          -->
	<!--            2. print out characters 1,001 to 2,000, flush buffer                                                                                  -->
	<!--                             *************                                                                                                                        -->
	<!--            9. print out characters  9,001 to 10,000, flush buffer                                                                                -->
	<!--           10. print out characters 10,001 to string length, return                                                                              -->
	<!--                                                                                                                                                                     -->
	<!--       Else if string is > 11,000 then;                                                                                                                  -->
	<!--           1. print out 1st 1,000 characters, flush buffer                                                                                          -->
	<!--           2. print out characters 1,001 to 2,000, flush buffer                                                                                  -->
	<!--                                                                                                                                                                    -->
	<!--           9. print out characters 9,001 to 10,000, flush buffer, return                                                                      -->
	<!--          10. print out characters 10,001 to 11,000, flush buffer, return                                                                    -->
	<!--          11. all characters beyond 11,000 will be ignored                                                                                      -->
	<!--                                                                                                                                                                    -->
	<!--***********************************************************************************************************************************-->
	<!--                                                                                                                                                                   -->
	<xsl:template name="buffer-overflow">
		<xsl:param name="string-size"/>
		<xsl:param name="string-target"/>
		<!-- String size:&#160;<xsl:value-of select="$string-size"></xsl:value-of>                                  -->
		<xsl:choose>
			<!-- string is 2 to 1,000 characters in length -->
			<xsl:when test="$string-size &gt; 1 and $string-size &lt;= 1000">
		    	<!-- print out characters #1 through 1,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="$string-size"/>
					<xsl:with-param name="string-target" select="$string-target"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
			</xsl:when>
			
			<!-- string is 1,001 to 2,000 characters in length -->
			<xsl:when test="$string-size &gt; 1000 and $string-size &lt;= 2000">
				<!-- print out characters #1 through 1,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,1,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters #1001 through end of string -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="$string-size - 1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,1001,$string-size - 1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
			</xsl:when>
			
			<!-- string is 2,001 to 3,000 characters in length -->
			<xsl:when test="$string-size &gt; 2000 and $string-size &lt;= 3000">
				<!-- print out characters # 1 through 1,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,1,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 1,001 through 2,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,1001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 2,001 through end of string -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="$string-size - 2000"/>
					<xsl:with-param name="string-target" select="substring($string-target,2001, $string-size - 2000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
			</xsl:when>
			
			<!-- string is 3,001 to 4,000 characters in length -->
			<xsl:when test="$string-size &gt; 3000 and $string-size &lt;= 4000">
				<!-- print out characters # 1 through 1,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,1,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 1,001 through 2,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,1001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 2,001 through 3,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,2001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 3,001 through end of string -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="$string-size - 3000"/>
					<xsl:with-param name="string-target" select="substring($string-target,3001, $string-size - 3000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
			</xsl:when>
			
			<!-- string is 4,001 - 5,000 characters in length -->
			<xsl:when test="$string-size &gt; 4000 and $string-size &lt;= 5000">
				<!-- print out characters # 1 through 1,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,1,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 1,001 through 2,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,1001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 2,001 through 3,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,2001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 3,001 through 4,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,3001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 4,001 through end of string -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="$string-size - 4000"/>
					<xsl:with-param name="string-target" select="substring($string-target,4001, $string-size - 4000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
			</xsl:when>
			
			<!-- string is 5,001 - 6,000 characters in length -->
			<xsl:when test="$string-size &gt; 5000 and $string-size &lt;= 6000">
				<!-- print out characters # 1 through 1,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,1,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 1,001 through 2,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,1001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 2,001 through 3,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
				    <xsl:with-param name="string-target" select="substring($string-target,2001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 3,001 through 4,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,3001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 4,001 through 5,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,4001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 5,001 through end of string -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="$string-size - 5000"/>
					<xsl:with-param name="string-target" select="substring($string-target,5001, $string-size - 5000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
			</xsl:when>
			
			<!-- string is 6,001 - 7,000 characters in length -->
			<xsl:when test="$string-size &gt; 6000 and $string-size &lt;= 7000">
				<!-- print out characters # 1 through 1,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,1,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 1,001 through 2,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,1001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 2,001 through 3,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,2001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 3,001 through 4,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,3001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 4,001 through 5,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,4001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 5,001 through 6,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,5001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 6,001 through end of string -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="$string-size - 6000"/>
					<xsl:with-param name="string-target" select="substring($string-target,6001, $string-size - 6000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
			</xsl:when>
			
			<!-- string is 7,001 - 8,000 characters in length -->
			<xsl:when test="$string-size &gt; 7000 and $string-size &lt;= 8000">
				<!-- print out characters # 1 through 1,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,1,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 1,001 through 2,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,1001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 2,001 through 3,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,2001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 3,001 through 4,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,3001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 4,001 through 5,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,4001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 5,001 through 6,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,5001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 6,001 through 7,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,6001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 7,001 through end of string -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="$string-size - 7000"/>
					<xsl:with-param name="string-target" select="substring($string-target,7001, $string-size - 7000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
			</xsl:when>
			
			<!-- string is 8,001 - 9,000 characters in length -->
			<xsl:when test="$string-size &gt; 8000 and $string-size &lt;= 9000">
				<!-- print out characters # 1 through 1,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,1,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 1,001 through 2,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,1001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 2,001 through 3,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,2001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 3,001 through 4,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,3001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 4,001 through 5,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,4001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 5,001 through 6,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,5001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 6,001 through 7,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,6001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 7,001 through 8,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,7001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 8,001 through end of string -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="$string-size - 8000"/>
					<xsl:with-param name="string-target" select="substring($string-target,8001, $string-size - 8000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
			</xsl:when>

			<!-- string is between 9,001 - 10,000 characters in length -->
			<xsl:when test="$string-size &gt; 9000 and $string-size &lt;= 10000">
				<!-- print out characters # 1 through 1,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,1,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 1,001 through 2,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,1001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 2,001 through 3,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,2001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 3,001 through 4,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,3001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 4,001 through 5,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,4001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 5,001 through 6,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,5001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 6,001 through 7,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,6001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 7,001 through 8,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,7001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 8,001 through 9,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,8001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 9,001 through end of string -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="$string-size - 9000"/>
					<xsl:with-param name="string-target" select="substring($string-target,9001, $string-size - 9000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
			</xsl:when>

			<!-- string is between 10,001 - 11,000 characters in length -->
			<xsl:when test="$string-size &gt; 10000 and $string-size &lt;= 11000">			
				<!-- print out characters # 1 through 1,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,1,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 1,001 through 2,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,1001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 2,001 through 3,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,2001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 3,001 through 4,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,3001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 4,001 through 5,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,4001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 5,001 through 6,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,5001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 6,001 through 7,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,6001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 7,001 through 8,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,7001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 8,001 through 9,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,8001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 9,001 through 10,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,9001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 10,001 through end of string -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="$string-size - 10000"/>
					<xsl:with-param name="string-target" select="substring($string-target,10001, $string-size - 10000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
			</xsl:when>

			

			<!-- string is between 11,001 - 12,000 characters in length -->
			<xsl:when test="$string-size &gt; 11000 and $string-size &lt;= 12000">			
				<!-- print out characters # 1 through 1,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,1,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 1,001 through 2,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,1001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 2,001 through 3,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,2001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 3,001 through 4,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,3001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 4,001 through 5,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,4001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 5,001 through 6,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,5001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 6,001 through 7,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,6001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 7,001 through 8,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,7001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 8,001 through 9,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,8001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 9,001 through 10,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,9001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 10,001 through 11,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="$string-size - 10000"/>
					<xsl:with-param name="string-target" select="substring($string-target,10001, $string-size - 10000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 11,001 through 12,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="$string-size - 10000"/>
					<xsl:with-param name="string-target" select="substring($string-target,11001, $string-size - 10000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
			</xsl:when>

			<!-- string is between 12,001 - 13,000 characters in length -->
			<xsl:when test="$string-size &gt; 12000 and $string-size &lt;= 13000">			
				<!-- print out characters # 1 through 1,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,1,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 1,001 through 2,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,1001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 2,001 through 3,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,2001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 3,001 through 4,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,3001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 4,001 through 5,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,4001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 5,001 through 6,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,5001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 6,001 through 7,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,6001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 7,001 through 8,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,7001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 8,001 through 9,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,8001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 9,001 through 10,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,9001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 10,001 through 11,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="$string-size - 10000"/>
					<xsl:with-param name="string-target" select="substring($string-target,10001, $string-size - 10000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 11,001 through 12,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="$string-size - 11000"/>
					<xsl:with-param name="string-target" select="substring($string-target,11001, $string-size - 10000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 12,001 through 13,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="$string-size - 12000"/>
					<xsl:with-param name="string-target" select="substring($string-target,12001, $string-size - 10000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
			</xsl:when>


			<!-- string is between 13,001 - 14,000 characters in length -->
			<xsl:when test="$string-size &gt; 13000 and $string-size &lt;= 14000">	
				<!-- print out characters # 1 - 1,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,1,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 1,001 - 2,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="index" select="1"/>
					<xsl:with-param name="string-target" select="substring($string-target,1001,1000)"/>
				</xsl:call-template>
				<xsl:call-template name="this-is-a-subroutine">
					<!-- print out characters # 2,001 through 3,000 -->
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,2001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 3,001 through 4,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,3001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 4,001 through 5,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,4001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 5,001 through 6,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,5001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 6,001 through 7,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,6001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 7,001 through 8,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,7001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 8,001 through 9,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,8001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 9,001 - 10,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,9001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 10,001 - 11,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,10001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 11,001 - 12,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,11001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 12,001 - 13,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,12001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 13,001 - 14,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,13001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
			</xsl:when>

			<!-- string is between 14,001 - 15,000 characters in length -->
			<xsl:when test="$string-size &gt; 14000 and $string-size &lt;= 15000">	
				<!-- print out characters # 1 - 1,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,1,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 1,001 - 2,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="index" select="1"/>
					<xsl:with-param name="string-target" select="substring($string-target,1001,1000)"/>
				</xsl:call-template>
				<!-- print out characters # 2,001 through 3,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,2001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 3,001 through 4,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,3001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 4,001 through 5,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,4001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 5,001 through 6,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,5001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 6,001 through 7,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,6001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 7,001 through 8,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,7001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 8,001 through 9,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,8001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 9,001 - 10,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,9001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 10,001 - 11,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,10001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 11,001 - 12,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,11001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 12,001 - 13,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,12001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 13,001 - 14,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,13001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
	                        <!-- print out characters # 14,001 - 15,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,14001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
			</xsl:when>
			
			<!-- string is greater than 15,000 characters long, truncate all characters > 15,000 -->
			<xsl:when test="$string-size &gt; 15000">
				<!-- print out characters # 1 - 1,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,1,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 1,001 - 2,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="index" select="1"/>
					<xsl:with-param name="string-target" select="substring($string-target,1001,1000)"/>
				</xsl:call-template>
				<!-- print out characters # 2,001 through 3,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,2001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 3,001 through 4,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,3001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 4,001 through 5,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,4001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 5,001 through 6,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,5001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 6,001 through 7,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,6001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 7,001 through 8,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,7001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 8,001 through 9,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,8001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 9,001 - 10,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,9001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 10,001 - 11,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,10001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 11,001 - 12,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,11001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 12,001 - 13,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,12001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
				<!-- print out characters # 13,001 - 14,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,13001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
	                        <!-- print out characters # 14,001 - 15,000 -->
				<xsl:call-template name="this-is-a-subroutine">
					<xsl:with-param name="string-size" select="1000"/>
					<xsl:with-param name="string-target" select="substring($string-target,14001,1000)"/>
					<xsl:with-param name="index" select="1"/>
				</xsl:call-template>
			</xsl:when>
		</xsl:choose>


	</xsl:template>	
	
</xsl:stylesheet>