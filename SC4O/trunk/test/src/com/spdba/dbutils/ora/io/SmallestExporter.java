package com.spdba.dbutils.ora.io;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.io.Reader;

import java.sql.ResultSetMetaData;
import java.sql.SQLException;

import oracle.jdbc.OracleResultSet;
import oracle.jdbc.OracleTypes;

import oracle.sql.CLOB;

/**
 * Exports a resultSet with a single column to a delimited file
 *
 * @author Simon Greener, The SpatialDB ADvisor, January 2012
 *
 */
 public class SmallestExporter {
    private static String CharsetValue = "US-ASCII";
    private static final double MEG = (Math.pow(1024, 2));
    private static final int BUFSIZE = (int)(2.0 * MEG);   // BufferedWriter default is 8192 
    
    public static boolean isEmpty(String s) {
        return (s == null || s.trim().length()==0);
    }

    /**
     * Main execution method.
     * <p>
     * Writes the given result as delimited text files 
     *  
     * @param _resultSet      - the result set, including a geometry column.
     * @param _outputFileName - the directory, filename and extension to write output files to.
     * @param _charSet        - CharSet for file encoding eg UTF8
     * 
     * @throws SQLException if anything goes wrong.
     */
    public static void write(java.sql.ResultSet _resultSet, 
                             java.lang.String   _outputFileName, 
                             java.lang.String   _charSet) 
    throws  SQLException, 
            IllegalArgumentException,
            FileNotFoundException, 
            IOException {
        try {
            // Check input
            if (_resultSet == null)       throw new IllegalArgumentException("No resultSet/RefCursor to process.");
            if (isEmpty(_outputFileName)) throw new IllegalArgumentException("Output file (plus directory) must be provided and Oracle user must have write permission.");
            if (!isEmpty(_charSet))       CharsetValue = _charSet;
            
            // Assign to local string variables
            //
            OracleResultSet resultSet = (OracleResultSet)_resultSet;
            ResultSetMetaData metaData = _resultSet.getMetaData();
            
            // Check and create filename and file
            //
            File     delimitedFile = new File(_outputFileName);
            OutputStreamWriter osw = new OutputStreamWriter(new FileOutputStream(delimitedFile),CharsetValue);
            BufferedWriter delimitedOutput = new BufferedWriter(osw,BUFSIZE);

            if ( metaData.getColumnCount() !=1 )
                throw new Exception("Record set must contain only one column.");
            
            int   colType = _resultSet.getMetaData().getColumnType(1);
            if ( ! ( colType == OracleTypes.CLOB || colType == OracleTypes.VARCHAR ) )               
                throw new Exception("Record set column is not CLOB or VARCHAR2.");

            // Write header object from the result set metadata column name
            // 
            delimitedOutput.write(metaData.getColumnName(1));
            delimitedOutput.newLine();
            
            // Process the resultset
            //
            Reader       in = null;
            CLOB    clobVal = null;
            int   clobLength = -1;
            char[]    buffer = null;
            String  outValue = "";
            resultSet.setFetchDirection(OracleResultSet.FETCH_FORWARD);
            while (resultSet.next()) 
            {
                // Process the single field
                //
                outValue = "";
                if ( colType == OracleTypes.VARCHAR ) {
                    outValue = resultSet.getString(1);
                    if (resultSet.wasNull())
                        outValue = "NULL";
                    delimitedOutput.write(outValue); 
                    delimitedOutput.newLine();                
                    continue;
                }
                if ( colType == OracleTypes.CLOB ) {
                      clobVal = resultSet.getCLOB(1);
                      if (!_resultSet.wasNull()) {
                          in = clobVal.getCharacterStream(  ); 
                          clobLength = (int)clobVal.length(); 
                          buffer = new char[1024]; 
                          while ((clobLength = in.read(buffer)) != -1) { 
                              outValue += String.valueOf(buffer).substring(0,clobLength);
                          }
                          in.close(); 
                          in = null; 
                      } else
                         outValue = "NULL";
                    delimitedOutput.write(outValue); 
                    delimitedOutput.newLine();                 
                }
            } // while
            delimitedOutput.close();
        }
        catch (SQLException sqle) {
            throw new SQLException("Error executing SQL: " + sqle);
        }
        catch (IOException ioe) {
            throw new IOException(ioe.getMessage());
        }
        catch (IllegalArgumentException iae) {
            throw new IllegalArgumentException(iae.getMessage());
        }
        catch (Exception e) {
            throw new RuntimeException("Error generating delimited file." + e.getMessage());
        }
    }  
}