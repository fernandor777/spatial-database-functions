<?xml version="1.0" encoding="UTF-8"?>

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

<!DOCTYPE xsl:stylesheet [
<!ENTITY nbsp "&#160;">
]>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
  xmlns:java="java"
  xmlns:str="http://exslt.org/strings"
  xmlns:lxslt="http://xml.apache.org/xslt"
  extension-element-prefixes="str java">

  <xsl:output method="html" indent="yes"/>

  <xsl:variable name="uppercase">ABCDEFGHIJKLMNOPQRSTUVWXYZ</xsl:variable>
  <xsl:variable name="lowercase">abcdefghijklmnopqrstuvwxyz</xsl:variable>

  <xsl:key name="schemaInit" match="*[@SCHEMA]" use="@SCHEMA"/>

  <!-- ********************** NAVIGATION BAR TEMPLATE ********************** -->
  <xsl:template name="NavigationBar">
    <TABLE BORDER="0" WIDTH="100%" CELLPADDING="1" CELLSPACING="0">
    <TR>
    <TD COLSPAN="2" CLASS="NavBarRow1">
    <TABLE BORDER="0" CELLPADDING="0" CELLSPACING="3">
      <TR ALIGN="center" VALIGN="top">
      <TD CLASS="NavBarRow1"><A HREF="summary.html"><FONT CLASS="NavBarFont1"><B>Overview</B></FONT></A> &nbsp;</TD>
      <TD CLASS="NavBarRow1"><A HREF="deprecated-list.html"><FONT CLASS="NavBarFont1"><B>Deprecated</B></FONT></A> &nbsp;</TD>
      <TD CLASS="NavBarRow1Chosen"><FONT CLASS="NavBarFont1Chosen"><B>Index</B></FONT> &nbsp;</TD>
      <TD CLASS="NavBarRow1"><A HREF="generator.html"><FONT CLASS="NavBarFont1"><B>Generator</B></FONT></A> &nbsp;</TD>
      </TR>
    </TABLE>
    </TD>
    <TD ALIGN="right" VALIGN="top" rowspan="3"><EM>
      <b><xsl:value-of select="@NAME"/></b></EM>
    </TD>
    </TR>

    </TABLE>
    <HR/>
  </xsl:template>

  <!-- ************************* INDEX GROUP ***************************** -->
	<xsl:template name="IndexGroup">
    <xsl:param name="indexChar" />

    <DL>
		  <DT>
		  	<!-- anchor -->
		    <xsl:element name="A">
	        <xsl:attribute name="NAME"><xsl:value-of select="$indexChar"/></xsl:attribute>
				</xsl:element>
				<xsl:value-of select="$indexChar"/>
			</DT>
			
			<xsl:for-each select="PACKAGE/child::*">
		  	<xsl:sort select="@NAME"/>
				
				<xsl:if test="starts-with(translate(substring(@NAME, 1,1), $lowercase, $uppercase), $indexChar)">
				<DD>	
					<xsl:variable name="packagename" select="../@NAME"/>
					<!-- create link referrer -->
					<xsl:variable name="referrer">
			      <xsl:value-of select="$packagename"/>
   					      <xsl:value-of select="'.html#'"/>
   					      <xsl:value-of select="@NAME" />
               <xsl:if test="ARGUMENT">
                <xsl:text>(</xsl:text>
								<xsl:for-each select="ARGUMENT">
 									<xsl:value-of select="@TYPE"/>
 									<xsl:if test="not(position()=last())"><xsl:text>,</xsl:text></xsl:if>
								</xsl:for-each>
								<xsl:text>)</xsl:text>
							</xsl:if>
					</xsl:variable>
									
			    <!-- create link -->
			    <xsl:element name="A">
	        <xsl:attribute name="HREF">
			        <xsl:value-of select="$referrer"/>
			      </xsl:attribute>
					  <xsl:value-of select="@NAME"/>        
					</xsl:element>
					
					&nbsp; <FONT SIZE="-1">(<xsl:value-of select="$packagename"/>)</FONT>
					
					<BR/>
				  
				  <xsl:value-of select="COMMENT_FIRST_LINE"/>        
				  
				  <P/>
				</DD>
				</xsl:if>

		</xsl:for-each>

		</DL>

	</xsl:template>

  <!-- ************************* START OF PAGE ***************************** -->
  <xsl:template match="/APPLICATION">
    <HTML>
    <HEAD>
    <TITLE><xsl:value-of select="@NAME" />: Index-List</TITLE>
    <LINK REL ="stylesheet" TYPE="text/css" HREF="stylesheet.css" TITLE="Style" />
    </HEAD>

    <BODY BGCOLOR="white">
    <!-- **************************** HEADER ******************************* -->
    <xsl:call-template name="NavigationBar"/>

    <CENTER><H2>Index</H2></CENTER>
    <P/><P/>

		<!-- Index links -->
		<A HREF="#A">A</A> &nbsp;
		<A HREF="#B">B</A> &nbsp;
		<A HREF="#C">C</A> &nbsp;
		<A HREF="#D">D</A> &nbsp;
		<A HREF="#E">E</A> &nbsp;
		<A HREF="#F">F</A> &nbsp;
		<A HREF="#G">G</A> &nbsp;
		<A HREF="#H">H</A> &nbsp;
		<A HREF="#I">I</A> &nbsp;
		<A HREF="#J">J</A> &nbsp;
		<A HREF="#K">K</A> &nbsp;
		<A HREF="#L">L</A> &nbsp;
		<A HREF="#M">M</A> &nbsp;
		<A HREF="#N">N</A> &nbsp;
		<A HREF="#O">O</A> &nbsp;
		<A HREF="#P">P</A> &nbsp;
		<A HREF="#Q">Q</A> &nbsp;
		<A HREF="#R">R</A> &nbsp;
		<A HREF="#S">S</A> &nbsp;
		<A HREF="#T">T</A> &nbsp;
		<A HREF="#U">U</A> &nbsp;
		<A HREF="#V">V</A> &nbsp;
		<A HREF="#W">W</A> &nbsp;
		<A HREF="#X">X</A> &nbsp;
		<A HREF="#Y">Y</A> &nbsp;
		<A HREF="#Z">Z</A> &nbsp;

		<!-- for each group construct is not standard XSLT -->
    <xsl:call-template name="IndexGroup"><xsl:with-param name="indexChar">A</xsl:with-param></xsl:call-template>
    <xsl:call-template name="IndexGroup"><xsl:with-param name="indexChar">B</xsl:with-param></xsl:call-template>
    <xsl:call-template name="IndexGroup"><xsl:with-param name="indexChar">C</xsl:with-param></xsl:call-template>
    <xsl:call-template name="IndexGroup"><xsl:with-param name="indexChar">D</xsl:with-param></xsl:call-template>
    <xsl:call-template name="IndexGroup"><xsl:with-param name="indexChar">E</xsl:with-param></xsl:call-template>
    <xsl:call-template name="IndexGroup"><xsl:with-param name="indexChar">F</xsl:with-param></xsl:call-template>
    <xsl:call-template name="IndexGroup"><xsl:with-param name="indexChar">G</xsl:with-param></xsl:call-template>
    <xsl:call-template name="IndexGroup"><xsl:with-param name="indexChar">H</xsl:with-param></xsl:call-template>
    <xsl:call-template name="IndexGroup"><xsl:with-param name="indexChar">I</xsl:with-param></xsl:call-template>
    <xsl:call-template name="IndexGroup"><xsl:with-param name="indexChar">J</xsl:with-param></xsl:call-template>
    <xsl:call-template name="IndexGroup"><xsl:with-param name="indexChar">K</xsl:with-param></xsl:call-template>
    <xsl:call-template name="IndexGroup"><xsl:with-param name="indexChar">L</xsl:with-param></xsl:call-template>
    <xsl:call-template name="IndexGroup"><xsl:with-param name="indexChar">M</xsl:with-param></xsl:call-template>
    <xsl:call-template name="IndexGroup"><xsl:with-param name="indexChar">N</xsl:with-param></xsl:call-template>
    <xsl:call-template name="IndexGroup"><xsl:with-param name="indexChar">O</xsl:with-param></xsl:call-template>
    <xsl:call-template name="IndexGroup"><xsl:with-param name="indexChar">P</xsl:with-param></xsl:call-template>
    <xsl:call-template name="IndexGroup"><xsl:with-param name="indexChar">Q</xsl:with-param></xsl:call-template>
    <xsl:call-template name="IndexGroup"><xsl:with-param name="indexChar">R</xsl:with-param></xsl:call-template>
    <xsl:call-template name="IndexGroup"><xsl:with-param name="indexChar">S</xsl:with-param></xsl:call-template>
    <xsl:call-template name="IndexGroup"><xsl:with-param name="indexChar">T</xsl:with-param></xsl:call-template>
    <xsl:call-template name="IndexGroup"><xsl:with-param name="indexChar">U</xsl:with-param></xsl:call-template>
    <xsl:call-template name="IndexGroup"><xsl:with-param name="indexChar">V</xsl:with-param></xsl:call-template>
    <xsl:call-template name="IndexGroup"><xsl:with-param name="indexChar">X</xsl:with-param></xsl:call-template>
    <xsl:call-template name="IndexGroup"><xsl:with-param name="indexChar">Y</xsl:with-param></xsl:call-template>
    <xsl:call-template name="IndexGroup"><xsl:with-param name="indexChar">Z</xsl:with-param></xsl:call-template>



    
	
    <!-- ***************************** FOOTER ****************************** -->
    <xsl:call-template name="NavigationBar"/>

    </BODY>
    </HTML>
  </xsl:template>

</xsl:stylesheet>
