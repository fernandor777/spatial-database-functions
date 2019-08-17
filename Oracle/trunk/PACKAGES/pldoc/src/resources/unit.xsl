<?xml version="1.0" encoding="iso-8859-1"?>

<!-- Copyright (C) 2002 Albert Tumanov

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

-->
<!--$Header: /cvsroot/pldoc/sources/src/resources/unit.xsl,v 1.5 2004/07/06 13:04:58 altumano Exp $-->

<!DOCTYPE xsl:stylesheet [
<!ENTITY nbsp "&#160;">
]>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
  xmlns:java="java"
  xmlns:str="http://exslt.org/strings"
  xmlns:lxslt="http://xml.apache.org/xslt"
  xmlns:redirect="http://xml.apache.org/xalan/redirect"
  extension-element-prefixes="redirect str java">

  <xsl:output method="html" indent="yes" encoding="iso-8859-1"/>
  <xsl:variable name="uppercase">ABCDEFGHIJKLMNOPQRSTUVWXYZ</xsl:variable>
  <xsl:variable name="lowercase">abcdefghijklmnopqrstuvwxyz</xsl:variable>
  <xsl:param name="output-dir"/>
  
  <!-- ********************** NAVIGATION BAR TEMPLATE ********************** -->
  <xsl:template name="NavigationBar">
    <TABLE BORDER="0" WIDTH="100%" CELLPADDING="1" CELLSPACING="0">
    <TR>
    <TD COLSPAN="2" CLASS="NavBarRow1">
    <TABLE BORDER="0" CELLPADDING="0" CELLSPACING="3">
      <TR ALIGN="center" VALIGN="top">
      <TD CLASS="NavBarRow1"><A HREF="summary.html"><FONT CLASS="NavBarFont1"><B>Overview</B></FONT></A> &nbsp;</TD>
      <TD CLASS="NavBarRow1"><A HREF="deprecated-list.html"><FONT CLASS="NavBarFont1"><B>Deprecated</B></FONT></A> &nbsp;</TD>
      <TD CLASS="NavBarRow1"><A HREF="index-list.html"><FONT CLASS="NavBarFont1"><B>Index</B></FONT></A> &nbsp;</TD>
      <TD CLASS="NavBarRow1"><A HREF="generator.html"><FONT CLASS="NavBarFont1"><B>Generator</B></FONT></A> &nbsp;</TD>
      </TR>
    </TABLE>
    </TD>
    <TD ALIGN="right" VALIGN="top" rowspan="3"><EM>
      <b><xsl:value-of select="../@NAME"/></b></EM>
    </TD>
    </TR>

    <TR>
    <TD VALIGN="top" CLASS="NavBarRow3"><FONT SIZE="-2">
      SUMMARY:  <A HREF="#field_summary">FIELD</A> | <A HREF="#type_summary">TYPE</A> | <A HREF="#method_summary">METHOD</A></FONT></TD>
    <TD VALIGN="top" CLASS="NavBarRow3"><FONT SIZE="-2">
    DETAIL:  <A HREF="#field_detail">FIELD</A> | <A HREF="#type_detail">TYPE</A> | <A HREF="#method_detail">METHOD</A></FONT></TD>
    </TR>
    </TABLE>
    <HR/>
  </xsl:template>

  <!-- ***************** CUSTOM TAGS TEMPLATE ****************** -->
  <!-- Special defined custom tags are processed here ! -->
  <xsl:template name="CustomTagsTemplate">

	<DL>
		<!-- deprecated -->
        <xsl:if test="TAG[@TYPE='@deprecated']">
  	      <DT>Deprecated:</DT>
		  <xsl:for-each select="TAG[@TYPE='@deprecated']">
	        <DD>
	        <xsl:for-each select="COMMENT">
	          <xsl:value-of select="." disable-output-escaping="yes" />
	        </xsl:for-each>
	        </DD>
	      </xsl:for-each>
	      <P/>
        </xsl:if>
		
		<!-- value -->
        <xsl:if test="TAG[@TYPE='@value']">
          <DT>Value:</DT>
          <xsl:for-each select="TAG[@TYPE='@value']">
            <DD><CODE><xsl:value-of select="@NAME"/></CODE> -
              <xsl:for-each select="COMMENT">
                <xsl:value-of select="." disable-output-escaping="yes" />
              </xsl:for-each>
            </DD>
          </xsl:for-each>
        </xsl:if>
        
		<!-- usage -->
        <xsl:if test="TAG[@TYPE='@usage']">
          <DT>Usage:</DT>
          <xsl:for-each select="TAG[@TYPE='@usage']">
            <DD>
              <xsl:for-each select="COMMENT">
                <xsl:value-of select="." disable-output-escaping="yes" />
              </xsl:for-each>
            </DD>
          </xsl:for-each>
        </xsl:if>
        
		<!-- author -->
        <xsl:if test="TAG[@TYPE='@author']">
          <DT>Author:</DT>
          <xsl:for-each select="TAG[@TYPE='@author']">
            <DD>
              <xsl:for-each select="COMMENT">
                <xsl:value-of select="." disable-output-escaping="yes" />
              </xsl:for-each>
            </DD>
          </xsl:for-each>
        </xsl:if>
        
		<!-- version -->
        <xsl:if test="TAG[@TYPE='@version']">
          <DT>Version:</DT>
          <xsl:for-each select="TAG[@TYPE='@version']">
            <DD>
              <xsl:for-each select="COMMENT">
                <xsl:value-of select="." disable-output-escaping="yes" />
              </xsl:for-each>
            </DD>
          </xsl:for-each>
        </xsl:if>

		<!-- since -->
        <xsl:if test="TAG[@TYPE='@since']">
          <DT>Version:</DT>
          <xsl:for-each select="TAG[@TYPE='@since']">
            <DD>
              <xsl:for-each select="COMMENT">
                <xsl:value-of select="." disable-output-escaping="yes" />
              </xsl:for-each>
            </DD>
          </xsl:for-each>
        </xsl:if>
        
		<!-- see -->
        <xsl:if test="TAG[@TYPE='@see']">
          <DT>See also:</DT>
          <xsl:for-each select="TAG[@TYPE='@see']">
            <DD>
              <xsl:for-each select="COMMENT">
	            <A>
            	<xsl:choose>
            	  <xsl:when test="starts-with(., '#')">
                	<xsl:attribute name="href"><xsl:value-of select="." disable-output-escaping="yes"/></xsl:attribute>
                	<xsl:value-of select="substring-after(., '#')" disable-output-escaping="yes"/>
            	  </xsl:when>
            	  <xsl:otherwise>
  	            	<xsl:choose>
	            	  <xsl:when test="string-length(substring-before(., '#')) &lt; 1">
	               		<xsl:attribute name="href"><xsl:value-of select="." disable-output-escaping="yes"/>.html</xsl:attribute>
	               		<xsl:value-of select="." disable-output-escaping="yes"/>
	            	  </xsl:when>
                	  <xsl:otherwise>
	               		<xsl:attribute name="href"><xsl:value-of select="concat(substring-before(., '#'), '.html#', substring-after(., '#'))" disable-output-escaping="yes"/></xsl:attribute>
	               		<xsl:value-of select="substring-before(., '#')" disable-output-escaping="yes"/>.<xsl:value-of select="substring-after(., '#')" disable-output-escaping="yes"/>
                	  </xsl:otherwise>
  	                </xsl:choose>
            	  </xsl:otherwise>
            	</xsl:choose>
            	</A>
              </xsl:for-each>
            </DD>
          </xsl:for-each>
        </xsl:if>
        
	</DL>     
	   
  </xsl:template>

  <!-- ***************** METHOD/TYPE/TRIGGER SUMMARY TEMPLATE ****************** -->
  <xsl:template name="MethodOrTypeOrTriggerSummary">
    <xsl:param name="fragmentName" />
    <xsl:param name="title" />
    <xsl:param name="mainTags" />
    <xsl:param name="childTags" />
    <xsl:param name="flagTrigger" />

    <A NAME="{$fragmentName}"></A>
    <xsl:if test="$mainTags">

    <TABLE BORDER="1" CELLPADDING="3" CELLSPACING="0" WIDTH="100%">
    <TR CLASS="TableHeadingColor">
    <TD COLSPAN="2"><FONT SIZE="+2">
    <B><xsl:value-of select="$title"/></B></FONT></TD>
    </TR>

    <xsl:for-each select="$mainTags">
      <xsl:sort select="@NAME"/>
      <TR CLASS="TableRowColor">
      <TD ALIGN="right" VALIGN="top" WIDTH="1%"><FONT SIZE="-1">
      <CODE><xsl:text>&nbsp;</xsl:text>
      <xsl:value-of select="RETURN/@TYPE"/>
      </CODE></FONT></TD>
      <TD><CODE>
        <B><xsl:element name="A"><xsl:attribute name="HREF">#<xsl:value-of select="translate(@NAME, $uppercase, $lowercase)" />
        <xsl:if test="*[name()=$childTags]">
        <xsl:text>(</xsl:text>
        <xsl:for-each select="*[name()=$childTags]">
          <xsl:value-of select="translate(@TYPE, $uppercase, $lowercase)"/>
          <xsl:if test="not(position()=last())"><xsl:text>,</xsl:text></xsl:if>
        </xsl:for-each>
        <xsl:text>)</xsl:text>
        </xsl:if>
        </xsl:attribute><xsl:value-of select="@NAME"/></xsl:element></B>
        <xsl:if test="not($flagTrigger)"><xsl:text>(</xsl:text></xsl:if>
        <xsl:for-each select="*[name()=$childTags]">
          <xsl:value-of select="translate(@NAME, $uppercase, $lowercase)"/>
          <xsl:if test="string-length(@MODE) &gt; 0">
            <xsl:text> </xsl:text><xsl:value-of select="@MODE"/>
          </xsl:if>
          <xsl:text> </xsl:text><xsl:value-of select="@TYPE"/>
          <xsl:if test="string-length(@DEFAULT) &gt; 0">
            <xsl:text> DEFAULT </xsl:text><xsl:value-of select="@DEFAULT"/>
          </xsl:if>
          <xsl:if test="not(position()=last())"><xsl:text>, </xsl:text></xsl:if>
        </xsl:for-each>
        <xsl:if test="not($flagTrigger)"><xsl:text>)</xsl:text></xsl:if>
        </CODE>
      <BR/>
      &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
      <xsl:if test="not(./TAG[@TYPE='@deprecated'])">
        <xsl:for-each select="COMMENT_FIRST_LINE">
          <xsl:value-of select="." disable-output-escaping="yes" />
        </xsl:for-each>
      </xsl:if>
      <xsl:for-each select="TAG[@TYPE='@deprecated']">
        <B>Deprecated.</B>&nbsp;<I>
        <xsl:for-each select="COMMENT">
          <xsl:value-of select="." disable-output-escaping="yes" />
        </xsl:for-each></I>
      </xsl:for-each>
      </TD>
      </TR>
    </xsl:for-each>

    </TABLE>
    <P/>

    </xsl:if>
  </xsl:template>

  <!-- ************************* METHOD/TYPE/TRIGGER DETAIL TEMPLATE *************************** -->
  <xsl:template name="MethodOrTypeOrTriggerDetail">
    <xsl:param name="fragmentName" />
    <xsl:param name="title" />
    <xsl:param name="mainTags" />
    <xsl:param name="childTags" />
    <xsl:param name="flagTrigger" />
    
    <A NAME="{$fragmentName}"></A>
    <xsl:if test="$mainTags">

    <TABLE BORDER="1" CELLPADDING="3" CELLSPACING="0" WIDTH="100%">
    <TR CLASS="TableHeadingColor">
    <TD COLSPAN="1"><FONT SIZE="+2">
    <B><xsl:value-of select="$title"/></B></FONT></TD>
    </TR>
    </TABLE>

    <xsl:for-each select="$mainTags">
      <xsl:element name="A"><xsl:attribute name="NAME"><xsl:value-of select="translate(@NAME, $uppercase, $lowercase)" />
        <xsl:if test="*[name()=$childTags]">
        <xsl:text>(</xsl:text>
        <xsl:for-each select="*[name()=$childTags]">
          <xsl:value-of select="translate(@TYPE, $uppercase, $lowercase)"/>
          <xsl:if test="not(position()=last())"><xsl:text>,</xsl:text></xsl:if>
        </xsl:for-each>
        <xsl:text>)</xsl:text>
        </xsl:if>
        </xsl:attribute></xsl:element>
      <H3><xsl:value-of select="@NAME"/></H3>
      <PRE>
        <xsl:variable name="methodText">
	      <xsl:if test="not($flagTrigger)">public</xsl:if><xsl:text> </xsl:text><xsl:value-of select="RETURN/@TYPE"/><xsl:text> </xsl:text><B><xsl:value-of select="@NAME"/></B>
        </xsl:variable>
        <xsl:variable name="methodTextString" select="java:lang.String.new($methodText)"/>
  		  <xsl:if test="not($flagTrigger)">public</xsl:if><xsl:text> </xsl:text><xsl:value-of select="RETURN/@TYPE"/><xsl:text> </xsl:text><B><xsl:value-of select="@NAME"/></B>
          <xsl:if test="not($flagTrigger)">
	        <xsl:text>(</xsl:text>
	        <xsl:for-each select="*[name()=$childTags]">
	          <!-- pad arguments with appropriate number of spaces -->
	          <xsl:if test="not(position()=1)"><BR/><xsl:value-of select="str:padding(java:length($methodTextString)+1)"/></xsl:if>
	          <xsl:value-of select="translate(@NAME, $uppercase, $lowercase)"/>
	          <xsl:if test="string-length(@MODE) &gt; 0">
	            <xsl:text> </xsl:text><xsl:value-of select="@MODE"/>
	          </xsl:if>
	          <xsl:text> </xsl:text><xsl:value-of select="@TYPE"/>
	          <xsl:if test="string-length(@DEFAULT) &gt; 0">
	            <xsl:text> DEFAULT </xsl:text><xsl:value-of select="@DEFAULT"/>
	          </xsl:if>
	          <xsl:if test="not(position()=last())"><xsl:text>, </xsl:text></xsl:if>
	        </xsl:for-each>
	        <xsl:text>)</xsl:text>
          </xsl:if>
      </PRE>
      
      <DL>

      <DD>
        <xsl:for-each select="COMMENT">
          <xsl:value-of select="." disable-output-escaping="yes" />
        </xsl:for-each>
      </DD>

      <DD><DL>
        <xsl:if test="*[name()=$childTags][COMMENT]">
        <DT>Parameters:
        <xsl:for-each select="*[name()=$childTags]">
          <xsl:if test="COMMENT">
            <DD><CODE><xsl:value-of select="translate(@NAME, $uppercase, $lowercase)"/></CODE> -
              <xsl:for-each select="COMMENT">
                <xsl:value-of select="." disable-output-escaping="yes" />
              </xsl:for-each>
            </DD>
          </xsl:if>
        </xsl:for-each>
        </DT>
        </xsl:if>
        <xsl:for-each select="RETURN/COMMENT">
        <DT>Returns:
          <DD><xsl:value-of select="." disable-output-escaping="yes" /></DD>
        </DT>
        </xsl:for-each>
        <xsl:if test="THROWS">
        <DT>Throws:
        <xsl:for-each select="THROWS">
            <DD><CODE><xsl:value-of select="@NAME"/></CODE> -
              <xsl:for-each select="COMMENT">
                <xsl:value-of select="." disable-output-escaping="yes" />
              </xsl:for-each>
            </DD>
        </xsl:for-each>
        </DT>
        </xsl:if>

		  <!-- triggers only -->
	      <xsl:if test="DECLARATION">
			<DT>Declaration:</DT>
	        <DD>
	          <xsl:value-of select="DECLARATION/@TEXT" disable-output-escaping="yes" />
	        </DD>
	      </xsl:if>
        
    </DL></DD>

	<!-- print custom tags --> 
	<P/>   
    <xsl:call-template name="CustomTagsTemplate"/>
    
    </DL>

    <HR/>
    </xsl:for-each>

    </xsl:if>
  </xsl:template>

  <!-- ************************* START OF PAGE ***************************** -->
  <xsl:template match="/APPLICATION">
  <!-- ********************* START OF PACKAGE PAGE ************************* -->
  <!--<xsl:for-each select="PACKAGE | PACKAGE_BODY">-->
  <xsl:for-each select="PACKAGE">

    <redirect:write file="{translate(@NAME, $uppercase, $lowercase)}.html">

    <HTML>
    <HEAD>
      <TITLE><xsl:value-of select="../@NAME"/></TITLE>
      <LINK REL="stylesheet" TYPE="text/css" HREF="stylesheet.css" TITLE="Style"/>
    </HEAD>
    <BODY BGCOLOR="white">

    <!-- **************************** HEADER ******************************* -->
    <xsl:call-template name="NavigationBar"/>

    <!-- ********************** PACKAGE DECRIPTION ************************* -->
    <H2>
    <FONT SIZE="-1"><xsl:value-of select="@SCHEMA"/></FONT><BR/>
    Package  <xsl:value-of select="@NAME"/>
    </H2>

	<!-- package comment -->
    <xsl:for-each select="COMMENT">
      <xsl:value-of select="." disable-output-escaping="yes" />
    </xsl:for-each>

	<P/>
	
	<!-- print custom tags -->    
    <xsl:call-template name="CustomTagsTemplate"/>

    <HR/>
    <P/>

    <!-- ************************** FIELD SUMMARY ************************** -->
    <A NAME="field_summary"></A>
    <xsl:if test="CONSTANT | VARIABLE">

    <TABLE BORDER="1" CELLPADDING="3" CELLSPACING="0" WIDTH="100%">
    <TR CLASS="TableHeadingColor">
    <TD COLSPAN="2"><FONT SIZE="+2">
    <B>Field Summary</B></FONT></TD>
    </TR>

    <xsl:for-each select="CONSTANT | VARIABLE">
      <xsl:sort select="@NAME"/>
      <TR CLASS="TableRowColor">
      <TD ALIGN="right" VALIGN="top" WIDTH="1%"><FONT SIZE="-1">
      <CODE><xsl:text>&nbsp;</xsl:text>
      <xsl:value-of select="RETURN/@TYPE"/>
      </CODE></FONT></TD>
      <TD><CODE><B><A HREF="#{@NAME}">
        <xsl:value-of select="@NAME"/></A></B>
        </CODE>
      <BR/>
      &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
      <xsl:if test="not(./TAG[@TYPE='@deprecated'])">
        <xsl:for-each select="COMMENT_FIRST_LINE">
          <xsl:value-of select="." disable-output-escaping="yes" />
        </xsl:for-each>
      </xsl:if>
      <xsl:for-each select="TAG[@TYPE='@deprecated']">
        <B>Deprecated.</B>&nbsp;<I>
        <xsl:for-each select="COMMENT">
          <xsl:value-of select="." disable-output-escaping="yes" />
        </xsl:for-each></I>
      </xsl:for-each>
      </TD>
      </TR>
    </xsl:for-each>

    </TABLE>
    <P/>

    </xsl:if>

    <!-- ************************* TYPE SUMMARY ************************** -->
    <xsl:call-template name="MethodOrTypeOrTriggerSummary">
      <xsl:with-param name="fragmentName">type_summary</xsl:with-param>
      <xsl:with-param name="title">Type Summary</xsl:with-param>
      <xsl:with-param name="mainTags" select="TYPE" />
      <xsl:with-param name="childTags" select="'FIELD'" />
    </xsl:call-template>

    <!-- ************************* METHOD SUMMARY ************************** -->
    <xsl:call-template name="MethodOrTypeOrTriggerSummary">
      <xsl:with-param name="fragmentName">method_summary</xsl:with-param>
      <xsl:with-param name="title">Method Summary</xsl:with-param>
      <xsl:with-param name="mainTags" select="FUNCTION | PROCEDURE" />
      <xsl:with-param name="childTags" select="'ARGUMENT'" />
    </xsl:call-template>

    <!-- ************************* TRIGGER SUMMARY ************************** -->
    <xsl:call-template name="MethodOrTypeOrTriggerSummary">
      <xsl:with-param name="fragmentName">trigger_summary</xsl:with-param>
      <xsl:with-param name="title">Trigger Summary</xsl:with-param>
      <xsl:with-param name="mainTags" select="TRIGGER" />
      <xsl:with-param name="childTags" select="''" />
      <xsl:with-param name="flagTrigger" select="'TRUE'" />
    </xsl:call-template>

    <!-- ************************** FIELD DETAIL *************************** -->
    <A NAME="field_detail"></A>
    <xsl:if test="CONSTANT | VARIABLE">

    <TABLE BORDER="1" CELLPADDING="3" CELLSPACING="0" WIDTH="100%">
    <TR CLASS="TableHeadingColor">
    <TD COLSPAN="1"><FONT SIZE="+2">
    <B>Field Detail</B></FONT></TD>
    </TR>
    </TABLE>

    <xsl:for-each select="CONSTANT | VARIABLE">
      <A NAME="{@NAME}"></A><H3><xsl:value-of select="@NAME"/></H3>
      <PRE>
  public <xsl:value-of select="RETURN/@TYPE"/><xsl:text> </xsl:text><B><xsl:value-of select="@NAME"/></B>
      </PRE>
      <DL>
      <xsl:for-each select="TAG[@TYPE='@deprecated']">
        <DD><B>Deprecated.</B>&nbsp;<I>
          <xsl:for-each select="COMMENT">
            <xsl:value-of select="." disable-output-escaping="yes" />
          </xsl:for-each></I>
        </DD><P/>
      </xsl:for-each>
      <DD>
        <xsl:for-each select="COMMENT">
          <xsl:value-of select="." disable-output-escaping="yes" />
        </xsl:for-each>
      </DD>

      <DD><DL>
    </DL>
    </DD>
    </DL>

    <HR/>
    </xsl:for-each>

    </xsl:if>

    <!-- ************************* TYPE DETAIL *************************** -->
    <xsl:call-template name="MethodOrTypeOrTriggerDetail">
      <xsl:with-param name="fragmentName">type_detail</xsl:with-param>
      <xsl:with-param name="title">Type Detail</xsl:with-param>
      <xsl:with-param name="mainTags" select="TYPE" />
      <xsl:with-param name="childTags" select="'FIELD'" />
    </xsl:call-template>

    <!-- ************************* METHOD DETAIL *************************** -->
    <xsl:call-template name="MethodOrTypeOrTriggerDetail">
      <xsl:with-param name="fragmentName">method_detail</xsl:with-param>
      <xsl:with-param name="title">Method Detail</xsl:with-param>
      <xsl:with-param name="mainTags" select="FUNCTION | PROCEDURE" />
      <xsl:with-param name="childTags" select="'ARGUMENT'" />
    </xsl:call-template>

    <!-- ************************* TRIGGER DETAIL *************************** -->
    <xsl:call-template name="MethodOrTypeOrTriggerDetail">
      <xsl:with-param name="fragmentName">trigger_detail</xsl:with-param>
      <xsl:with-param name="title">Trigger Detail</xsl:with-param>
      <xsl:with-param name="mainTags" select="TRIGGER" />
      <xsl:with-param name="childTags" select="''" />
      <xsl:with-param name="flagTrigger" select="'TRUE'" />
    </xsl:call-template>

    <!-- ***************************** FOOTER ****************************** -->
    <xsl:call-template name="NavigationBar"/>

    </BODY>
    </HTML>

    </redirect:write>
  </xsl:for-each> <!-- select="PACKAGE | PACKAGE_BODY" -->

  <!-- ********************** START OF TABLE PAGE ************************** -->
  <xsl:for-each select="TABLE | VIEW">

    <redirect:write file="{translate(@NAME, $uppercase, $lowercase)}.html">

    <HTML>
    <HEAD>
      <TITLE><xsl:value-of select="../@NAME"/></TITLE>
      <LINK REL="stylesheet" TYPE="text/css" HREF="stylesheet.css" TITLE="Style"/>
    </HEAD>
    <BODY BGCOLOR="white">

    <!-- **************************** HEADER ******************************* -->
    <xsl:call-template name="NavigationBar"/>

    <!-- ********************** TABLE DECRIPTION ************************* -->
    <H2>
    <FONT SIZE="-1"><xsl:value-of select="@SCHEMA"/></FONT><BR/>
    <xsl:value-of select="local-name(.)"/><xsl:text> </xsl:text><xsl:value-of select="@NAME"/>
    </H2>
    <xsl:for-each select="TAG[@TYPE='@deprecated']">
      <P>
      <B>Deprecated.</B>&nbsp;<I>
      <xsl:for-each select="COMMENT">
        <xsl:value-of select="." disable-output-escaping="yes" />
      </xsl:for-each></I>
      </P>
    </xsl:for-each>
    <P>
    <xsl:for-each select="COMMENT">
        <xsl:value-of select="." disable-output-escaping="yes" />
    </xsl:for-each>
    </P>
    <HR/>
    <P/>

    <!-- ***************************** COLUMNS ***************************** -->
    <A NAME="field_summary"></A>
    <xsl:if test="COLUMN">

    <TABLE BORDER="1" CELLPADDING="3" CELLSPACING="0" WIDTH="100%">
    <TR CLASS="TableHeadingColor">
    <TD COLSPAN="2"><FONT SIZE="+2">
    <B>Columns</B></FONT></TD>
    </TR>

    <xsl:for-each select="COLUMN">
      <TR CLASS="TableRowColor">
      <TD ALIGN="right" VALIGN="top" WIDTH="1%"><FONT SIZE="-1">
      <CODE><xsl:text>&nbsp;</xsl:text>
      <xsl:value-of select="@TYPE"/>
      </CODE></FONT></TD>
      <TD><CODE><B><A HREF="#{@NAME}">
        <xsl:value-of select="@NAME"/></A></B>
        </CODE>
      <BR/>
      &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
      <xsl:if test="not(./TAG[@TYPE='@deprecated'])">
        <xsl:for-each select="COMMENT">
          <xsl:value-of select="." disable-output-escaping="yes" />
        </xsl:for-each>
      </xsl:if>
      <xsl:for-each select="TAG[@TYPE='@deprecated']">
        <B>Deprecated.</B>&nbsp;<I>
        <xsl:for-each select="COMMENT">
          <xsl:value-of select="." disable-output-escaping="yes" />
        </xsl:for-each></I>
      </xsl:for-each>
      </TD>
      </TR>
    </xsl:for-each>

    </TABLE>
    <P/>

    </xsl:if>

    <!-- ***************************** FOOTER ****************************** -->
    <xsl:call-template name="NavigationBar"/>

    </BODY>
    </HTML>

    </redirect:write>
  </xsl:for-each> <!-- select="TABLE" -->

  </xsl:template>

</xsl:stylesheet>
