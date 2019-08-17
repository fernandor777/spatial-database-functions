/* Copyright (C) 2002 Albert Tumanov

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

*/

package net.sourceforge.pldoc;

import java.io.*;
import java.util.*;
import java.text.DateFormat;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.Transformer;
import javax.xml.transform.stream.StreamSource;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.dom.DOMResult;
import net.sourceforge.pldoc.parser.PLSQLParser;
import net.sourceforge.pldoc.parser.ParseException;
import net.sourceforge.pldoc.DbmsMetadata;

import org.w3c.dom.Document;
import org.w3c.dom.NodeList;
import org.w3c.dom.Node;
import org.w3c.dom.NamedNodeMap;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;


/**
 * PL/SQL documentation generator.
 * <p>
 * 
 * 2006-05-16 - Matthias Hendler - Rewritten execption handling in Methode run and processPackage. 
 *                                 Now the program ignores not only exceptions thrown by the parser
 *                                 but also thrown errors.
 *                                 Also a summary of skipped packages will be written to stderr at the program end.
 *                                 User can specify if he wants to get a generator summary in which he can see errors
 *                                 encountered during processing packages. 
 *                                 Creation date is also added to the XML document (application.xml) for further XSLT processing.
 * 
 * @author Albert Tumanov
 * @version $Header: /cvsroot/pldoc/sources/src/java/net/sourceforge/pldoc/PLDoc.java,v 1.13 2005/11/29 08:25:00 gpaulissen Exp $
 * </p>
 */
public class PLDoc
{
  // The exception is used when system exit is desired but "finally" clause need also to be run.
  private static class SystemExitException extends RuntimeException {
    /** Serial UID */
    static final long serialVersionUID = 1L;
    
    /** Default-Konstruktor */
    SystemExitException() {
      super();
    }
    
    /** Konstruktor with cause */
    SystemExitException(Throwable t) {
      super(t);
    }
  }

  private static final String lineSeparator = System.getProperty("line.separator");
  private static String programName = "PLDoc version: " + Version.id();

  // Helper object for retrieving resources relative to the installation.
  public static final ResourceLoader resLoader = new ResourceLoader();

  // Runtime settings
  public Settings settings;

  /**
  * Constructor.
  */
  public PLDoc(Settings settings)
  {
    this.settings = settings;
  }

  /** All processing is via the main method */
  public static void main(String[] args) throws Exception
  {
    long startTime = System.currentTimeMillis();
    System.out.println("");
    System.out.println(programName);

    // process arguments
    Settings settings = new Settings();
    settings.processCommandString(args);
    PLDoc pldoc = new PLDoc(settings);

    // start running
    try {
      pldoc.run();
    } catch (SystemExitException e) {
      System.exit(-1);
    }

    long finishTime = System.currentTimeMillis();
    System.out.println("Done (" + (finishTime-startTime)/1000.00 + " seconds).");
  }

  /**
  * Runs pldoc using the specified settings.
  * 
  * 2006-05-16 - Matthias Hendler - Collect some status information during the processing
  *                                 and add them to the application.xml.
  *                                 More verbose output to console added.
  */
  public void run() throws Exception
  {
    // Map with all the packages (like files or database objects) which were skipped
    final SortedMap skippedPackages = new TreeMap();
    // Counts all the packages (like files or database objects) which were processed successfully 
    long processedPackages = 0;
    
    // if the output directory do not exist, create it
    if (!settings.getOutputDirectory().exists()) {
      System.out.println("Directory \"" + settings.getOutputDirectory() + "\" does not exist, creating ...");
      settings.getOutputDirectory().mkdir();
    }

    // open the output file (named application.xml)
    File applicationFile = new File(
      settings.getOutputDirectory().getPath() + File.separator + "application.xml");
    OutputStream output = null;
    try {
      output = new FileOutputStream(applicationFile);
      XMLWriter xmlOut = new XMLWriter(output);
      xmlOut.setMethod("xml");
      if (settings.getOutputEncoding() != null)
        xmlOut.setEncoding(settings.getOutputEncoding());
      xmlOut.setIndent(true);
      xmlOut.setDocType(null, "application.dtd");
      xmlOut.startDocument();
      xmlOut.pushAttribute("NAME", settings.getApplicationName());
      xmlOut.startElement("APPLICATION");

      // read overview file content
      if (settings.getOverviewFile() != null) {
        // overview of the application
        xmlOut.startElement("OVERVIEW");
        xmlOut.cdata(getOverviewFileContent(settings.getOverviewFile()));
        xmlOut.endElement("OVERVIEW");
      }

      // for all the input files
      Iterator it = settings.getInputFiles().iterator();
      while (it.hasNext()) {
        String inputFileName = (String) it.next();
        final String packagename = inputFileName;

        // open the input file
        System.out.println("Parsing file " + inputFileName + " ...");

        try {
          final Throwable throwable = processPackage(
            new BufferedReader(
              new InputStreamReader(
                new FileInputStream(inputFileName), settings.getInputEncoding())
	      ),
              xmlOut, packagename
          );

          // Test the prcoessing result
          if (throwable == null) {
            processedPackages++;
          } else {
            skippedPackages.put(packagename, throwable);
          }
        } catch(FileNotFoundException e) {
          System.err.println("File not found: " + inputFileName);
          throw new SystemExitException(e);
        }
      } // for all the input files.



      // for all the specified packages from the dictionary
      if ( settings.getDbUrl() != null && settings.getDbUser() != null && settings.getDbPassword() != null ) {
        // Load the Oracle JDBC driver class.
        // DriverManager.registerDriver(new OracleDriver());
	Class.forName("oracle.jdbc.driver.OracleDriver");

        Connection conn = null;
        PreparedStatement pstmt = null;

        try {
          conn = DriverManager.getConnection( settings.getDbUrl(), settings.getDbUser(), settings.getDbPassword() );
          pstmt = conn.prepareStatement("SELECT  object_name "+
                                        ",       object_type "+
                                        "FROM    all_objects "+
                                        "WHERE   owner = ? "+
                                        "AND     object_name LIKE ?"+
                                        "AND     object_type in ('PACKAGE', 'TABLE', 'VIEW')"+
                                        "ORDER BY "+
                                        "        object_name");

          DbmsMetadata dbmsMetadata = new DbmsMetadata(conn);

          it = settings.getInputObjects().iterator();
          while (it.hasNext()) {
            String input[] = ((String) it.next()).split("\\."); /* [ SCHEMA . ] PACKAGE */

	    if ( input.length == 0 || input.length > 2 ) {
		continue;
	    }

            String inputSchemaName = ( input.length == 2 ? input[0] : settings.getDbUser() );
            String inputObjectName = ( input.length == 2 ? input[1] : input[0] );

            // get the package name(s)
	    ResultSet rset = null;

	    try {
		pstmt.setString(1, inputSchemaName);
		pstmt.setString(2, inputObjectName);

		rset = pstmt.executeQuery();
		
		// If the object is not present return false
		if (!rset.next()) {
		    // package does not exist

		    System.err.println("Object(s) like " + inputSchemaName + "." + inputObjectName + " do not exist or " + settings.getDbUser() + " does not have enough permissions (SELECT_CATALOG_ROLE role).");
		} else {
		    do {
          final String packagename = inputSchemaName + "." + rset.getString(1);
			System.out.println("Parsing package specification name " + packagename + " ...");

			    final Throwable throwable = processPackage(
                              new BufferedReader(
                                dbmsMetadata.getDdl((rset.getString(2).equals("PACKAGE") ? "PACKAGE_SPEC" : rset.getString(2)), 
						    rset.getString(1), 
						    inputSchemaName, 
						    "COMPATIBLE", 
						    "ORACLE", 
						    "DDL").getCharacterStream()), 
			      xmlOut, packagename
			    );
          
          // Test the prcoessing result
          if (throwable == null) {
            processedPackages++;
          } else {
            skippedPackages.put(packagename, throwable);
          }
	  } while (rset.next());
		}
	    } finally  {
		if( rset != null ) rset.close();
	    }
	  }
	} finally {
	    if( pstmt != null ) pstmt.close();
	    if ( conn != null ) conn.close();
	}
      } // for all the specified packages from the dictionary

      // generator summary
      xmlOut.startElement("GENERATOR");

      // objects like files or database objects
      xmlOut.startElement("OBJECTS");
      // save count processed objects
      xmlOut.pushAttribute("COUNT", String.valueOf(processedPackages));
      xmlOut.startElement("PROCESSED");
      xmlOut.endElement("PROCESSED");
      
      // save errors
      xmlOut.pushAttribute("COUNT", String.valueOf(skippedPackages.size()));
      xmlOut.startElement("SKIPPED");
      if (settings.isShowSkippedPackages()) {
        for (Iterator iter = skippedPackages.keySet().iterator(); iter.hasNext();) {
          final String packagename = (String) iter.next();
          final String error = ((Throwable) skippedPackages.get(packagename)).getLocalizedMessage();
          xmlOut.pushAttribute("ERROR", error);
          xmlOut.pushAttribute("NAME", packagename);
          xmlOut.startElement("OBJECT");
          xmlOut.endElement("OBJECT");
        }
      }
      xmlOut.endElement("SKIPPED");
      xmlOut.endElement("OBJECTS");
      
      // save creation date and time
      final Date date = new Date();
      final String creationdate = DateFormat.getDateInstance(DateFormat.SHORT).format(date);
      final String creationtime = DateFormat.getTimeInstance(DateFormat.SHORT).format(date);
      xmlOut.pushAttribute("DATE", creationdate);
      xmlOut.pushAttribute("TIME", creationtime);
      xmlOut.startElement("CREATED");
      xmlOut.endElement("CREATED");

      xmlOut.endElement("GENERATOR");

      xmlOut.endElement("APPLICATION");
      
      // All Nodes of the type PACKAGE with the same name will be collapsed to one node
      // This is necessary to put all global defined functions/procedures/triggers into one
      // big dummy package _GLOBAL.
      collapsePackageNodes(xmlOut.getDocument());
      
      xmlOut.endDocument();
    } catch(FileNotFoundException e) {
      System.err.println("File cannot be created: " + applicationFile);
      e.printStackTrace();
      throw new SystemExitException();
    } finally {
      if(output != null) {
        output.close();
      }
    }


    // copy required static files into the output directory
    copyStaticFiles(settings.getOutputDirectory());

    // generate HTML files from the applicationFile
    generateHtml(applicationFile);
    
    // write skipped packagenames to console
    if (!skippedPackages.isEmpty()) {
      System.err.println("Following packages were skipped due to errors:");
      for (Iterator iter = skippedPackages.keySet().iterator(); iter.hasNext();) {
        final String packagename = (String) iter.next();
        System.err.print(packagename);
        if (iter.hasNext()) {
          System.err.print(", ");
        }
      }
      System.err.println();
      System.err.println(skippedPackages.size()+" packages skipped!");
    }
    
    // successfully processed packages
    System.out.println(""+processedPackages+" packages processed successfully.");
  }

  /**
  * Processes a package.
  *
  * 2006-05-16 - Matthias Hendler - Rewritten exception handling and methode signature.
  *
  * @param packageSpec  Package specification to parse
  * @param xmlOut       XML writer
  * @param pPackageName The name of the package which is processed
  * @return             Null, if successfully processed or otherwise throwable which was encountered during processing. 
  * @throws SystemExitException   Thrown if an error occurred and the user specified the halt on errors option.
  *                               All other throwables will be caught.     
  */

  private Throwable processPackage(BufferedReader packageSpec, XMLWriter xmlOut, String pPackageName) 
      throws SystemExitException
  {
    Throwable result = null;
    SubstitutionReader input = null;
    try {
      input = new SubstitutionReader(packageSpec, settings.getDefines());

      // parse the input file
      PLSQLParser parser = new PLSQLParser(input);

      // start writing new XML for the input file
      XMLWriter outXML = new XMLWriter();
      outXML.startDocument();
      outXML.startElement("FILE");

      // set parser params
      parser.setXMLWriter(outXML);
      parser.setIgnoreInformalComments(settings.isIgnoreInformalComments());
      parser.setNamesUppercase(settings.isNamesUppercase());
      parser.setNamesLowercase(settings.isNamesLowercase());

      // run parser
      parser.input();

      outXML.endElement("FILE");
      outXML.endDocument();

      // file parsed successfully
      // append all nodes below FILE to the main XML
      xmlOut.appendNodeChildren(outXML.getDocument().getDocumentElement());
    } catch(ParseException e) {
      System.err.println("ParseException at package <"+pPackageName+">: "+e);
      System.err.println("Last consumed token: \"" + e.currentToken + "\"");
      e.printStackTrace(System.err);
      // exit with error only if specifically required by user
      if (settings.isExitOnError()) {
        throw new SystemExitException(e);
      } 
      System.err.println("Package " + pPackageName + " skipped.");
      result = e;
    } catch (Throwable t) {
      // Parser can cause errors which we also want to skip
      System.err.println("Throwable at package <"+pPackageName+">: "+t);
      t.printStackTrace(System.err);
      if (settings.isExitOnError()) {
        throw new SystemExitException(t);
      }
      System.err.println("Package " + pPackageName + " skipped.");
      result = t;
    } finally {
      try {
        if(input != null) {
          input.close();
        }
      } catch (IOException ioe) {
        System.err.println("Can't close input stream! Ignored!");
        System.err.println("IOException: "+ioe);
      }
    }
    
    return result;
  }

  /**
  * Reads the text from the overview file.
  *
  * @param overviewFile  The overview file to read from
  */
  private String getOverviewFileContent(File overviewFile) throws IOException {
    StringBuffer overview = new StringBuffer("");

    try {
      BufferedReader overviewReader =
        new BufferedReader(
          new InputStreamReader(
            new FileInputStream(settings.getOverviewFile()),
            settings.getInputEncoding())
        );
      String line = null;
      while ((line = overviewReader.readLine()) != null) {
        overview.append(line);
        overview.append(lineSeparator);
      }
      overviewReader.close();
    } catch(FileNotFoundException e) {
      System.err.println("File not found: " + settings.getOverviewFile());
      throw e;
    } catch(UnsupportedEncodingException e) {
      throw new IOException(e.toString());
    }

    // extract the text between <BODY> and </BODY>
    int start = overview.toString().toUpperCase().lastIndexOf("<BODY>");
    if (start != -1)
      overview.delete(0, start + 6);
    int end = overview.toString().toUpperCase().indexOf("</BODY>");
    if (end != -1)
      overview.delete(end, overview.length());

    return overview.toString();
  }


  /**
  * Generates HTML files from the provided XML file.
  *
  * 2006-05-16 - Matthias Hendler - Generates now a generator summary page, deprecated list and index list.
  *
  * @param applicationFile  XML application file
  */
  private void generateHtml(File applicationFile) throws Exception {
    // apply xsl to generate the HTML frames
    System.out.println("Generating HTML files ...");
    TransformerFactory tFactory = TransformerFactory.newInstance();
    Transformer transformer;
    // list of schemas
    System.out.println("Generating allschemas.html ...");
    transformer = tFactory.newTransformer(new StreamSource(
      resLoader.getResourceStream("resources/allschemas.xsl")));
    transformer.transform(new StreamSource(applicationFile),
      new StreamResult(new FileOutputStream(
        settings.getOutputDirectory().getPath() + File.separator + "allschemas.html")));
    // summary
    System.out.println("Generating summary.html ...");
    transformer = tFactory.newTransformer(new StreamSource(
      resLoader.getResourceStream("resources/summary.xsl")));
    transformer.transform(new StreamSource(applicationFile),
      new StreamResult(new FileOutputStream(
        settings.getOutputDirectory().getPath() + File.separator + "summary.html")));
    // summary generator
    System.out.println("Generating generator.html ...");
    transformer = tFactory.newTransformer(new StreamSource(
      resLoader.getResourceStream("resources/generator.xsl")));
    transformer.transform(new StreamSource(applicationFile),
      new StreamResult(new FileOutputStream(
        settings.getOutputDirectory().getPath() + File.separator + "generator.html")));
    // deprecated list
    System.out.println("Generating deprecated-list.html ...");
    transformer = tFactory.newTransformer(new StreamSource(
      resLoader.getResourceStream("resources/deprecated-list.xsl")));
    transformer.transform(new StreamSource(applicationFile),
      new StreamResult(new FileOutputStream(
        settings.getOutputDirectory().getPath() + File.separator + "deprecated-list.html")));
    // index list
    System.out.println("Generating index-list.html ...");
    transformer = tFactory.newTransformer(new StreamSource(
      resLoader.getResourceStream("resources/index-list.xsl")));
    transformer.transform(new StreamSource(applicationFile),
      new StreamResult(new FileOutputStream(
        settings.getOutputDirectory().getPath() + File.separator + "index-list.html")));
    // list of packages
    System.out.println("Generating allpackages.html ...");
    transformer = tFactory.newTransformer(new StreamSource(
      resLoader.getResourceStream("resources/allpackages.xsl")));
    transformer.transform(new StreamSource(applicationFile),
      new StreamResult(new FileOutputStream(
        settings.getOutputDirectory().getPath() + File.separator + "allpackages.html")));
    // index
    System.out.println("Generating index.html ...");
    transformer = tFactory.newTransformer(new StreamSource(
      resLoader.getResourceStream("resources/index.xsl")));
    transformer.transform(new StreamSource(applicationFile),
      new StreamResult(new FileOutputStream(
        settings.getOutputDirectory().getPath() + File.separator + "index.html")));
    // description for each package; the DOMResult is actually ignored
    System.out.println("Generating <unit>.html ...");
    transformer = tFactory.newTransformer(new StreamSource(
      resLoader.getResourceStream("resources/unit.xsl")));
    transformer.transform(new StreamSource(applicationFile), new DOMResult());
  }


  /**
  * Copies required static files into the output directory.
  *
  * @param outputDirectory  
  */
  private void copyStaticFiles(File outputDirectory) throws Exception {
    try {
      // copy the stylesheet
      Utils.CopyStreamToFile(
        settings.getStylesheetFile(),
        new File(outputDirectory.getPath() + File.separator + "stylesheet.css"));
      // copy the DTD
      Utils.CopyStreamToFile(
        resLoader.getResourceStream("resources/application.dtd"),
        new File(outputDirectory.getPath() + File.separator + "application.dtd"));
    } catch(FileNotFoundException e) {
      System.err.println("File not found. ");
      e.printStackTrace();
      throw e;
    }
  }
  
  
  /**
   * Collapse all the nodes of type PACKAGE with the same attribute NAME to one node.
   * 
   * 2006-05-18 - Matthias Hendler - added
   * 
   * @param pDocument   The document to work on
   */
  private void collapsePackageNodes(Document pDocument) {
      final String nodeName = "PACKAGE";
      final String attributeName = "NAME";
      final String[] equalValues = findEqualNodesOnAttribute(pDocument, nodeName, attributeName);
      
      for (int index = 0; index < equalValues.length; index++) {
          final String value = equalValues[index];
          System.out.println("Collapsing all nodes of type <"+nodeName+"> on their attribute <"+attributeName+"> with value <"+value+">.");
          collapseNodes(pDocument, nodeName, attributeName, value);
      }
  }
  

  /**
   * Collapse all the nodes in the document which have the given value in the specified attribute.
   * 
   * 2006-05-18 - Matthias Hendler - added
   * 
   * @param pDocument   document to work on
   * @param pNodeName   node name
   * @param pAttribute  attribute name
   * @param pValue      value
   */
  private void collapseNodes(Document pDocument, String pNodeName, String pAttribute, String pValue) {
      Node supernode = null;
      final List remove = new LinkedList();
      final NodeList nl = pDocument.getElementsByTagName(pNodeName);
      for (int index = 0; index < nl.getLength(); index++) {
          final Node node = nl.item(index);
          if (node.hasAttributes()) {
              final NamedNodeMap attributes = node.getAttributes();
              final Node attribute = attributes.getNamedItem(pAttribute);
              if (attribute != null) {
                  final String value = attribute.getNodeValue();
                  if (pValue.equalsIgnoreCase(value)) {
                      if (supernode == null) {
                          supernode = node;
                      } else {
                          if (node.hasChildNodes()) {
                              final NodeList childs = node.getChildNodes();
                              for (int index2 = 0; index2 < childs.getLength(); index2++) {
                                  final Node child = childs.item(index2);
                                  final Node clone = child.cloneNode(true);
                                  supernode.appendChild(clone);
                              }
                          }
                          remove.add(node);
                      }
                  }
              }
          }
      }
  
      if (!remove.isEmpty()) {
          for (Iterator iter = remove.iterator(); iter.hasNext();) {
              final Node node = (Node) iter.next();
              node.getParentNode().removeChild(node);
          }
      }
  }

  
  /**
   * Find all the nodes with equal attributes an return the value of this attribute. 
   * 
   * 2006-05-18 - Matthias Hendler - added
   * 
   * @param pDocument   document 
   * @param pNodeName   name of the element 
   * @param pAttribute  name of the attribute
   * @return            List of values which were identical
   */
  private String[] findEqualNodesOnAttribute(Document pDocument, String pNodeName, String pAttribute) {
      final Map result = new HashMap();
      final Map found = new HashMap();

      final NodeList nl = pDocument.getElementsByTagName(pNodeName);
      for (int index = 0; index < nl.getLength(); index++) {
          final Node node = nl.item(index);
          if (node.hasAttributes()) {
              final NamedNodeMap attributes = node.getAttributes();
              final Node attribute = attributes.getNamedItem(pAttribute);
              if (attribute != null) {
                  final String value = attribute.getNodeValue();
                  if (value != null) {
                      if (found.containsKey(value)) {
                          result.put(value, null);
                      } else {
                          found.put(value, null);
                      }
                  }
              }
          }
      }
      
      return (String[]) result.keySet().toArray(new String[] {});
  }
  
  
}
