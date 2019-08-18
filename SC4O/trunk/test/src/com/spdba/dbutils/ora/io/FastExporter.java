package com.spdba.dbutils.ora.io;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.io.Reader;

import java.nio.ByteBuffer;
import java.nio.MappedByteBuffer;
import java.nio.channels.FileChannel;
import java.nio.channels.NonWritableChannelException;
import java.nio.charset.Charset;
import java.nio.charset.CharsetEncoder;

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
 public class FastExporter {
    private static String CharsetValue = "US-ASCII";
    private static final int MEG = (int)Math.pow(1024, 2);
    private static final int BUFSIZE = (int)(2 * MEG);   // BufferedWriter default is 8192 
    
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
            if (isEmpty(_charSet)) {
                CharsetValue = System.getProperty("file.encoding"); // 1.5 Charset.defaultCharset();
            } else {
                CharsetValue = _charSet;
                System.setProperty("file.encoding" , CharsetValue);
            }
                
            // Assign to local string variables
            //
            OracleResultSet resultSet = (OracleResultSet)_resultSet;
            ResultSetMetaData metaData = _resultSet.getMetaData();
            
            if ( metaData.getColumnCount() !=1 )
                throw new Exception("Record set must contain only one column.");
            
            int   colType = _resultSet.getMetaData().getColumnType(1);
            if ( ! ( colType == OracleTypes.CLOB || colType == OracleTypes.VARCHAR ) )               
                throw new Exception("Record set column is not CLOB or VARCHAR2.");

            String newline = System.getProperty("line.separator");

            // Check and create filename and file
            /*
            File     delimitedFile = new File(_outputFileName);
            OutputStreamWriter osw = new OutputStreamWriter(new FileOutputStream(delimitedFile),CharsetValue);
            BufferedWriter delimitedOutput = new BufferedWriter(osw,BUFSIZE);
            */
            Charset        charset = Charset.forName(CharsetValue);  
            CharsetEncoder encoder = charset.newEncoder();
            //CharBuffer          cb = CharBuffer.allocate(MEG);
            ByteBuffer            bb = ByteBuffer.allocate(MEG);

            // Write header object from the result set metadata column name
            // 
            //cb = cb.put(metaData.getColumnName(1) + newline);
            bb.put(((String)metaData.getColumnName(1)).getBytes(CharsetValue)).put(newline.getBytes(CharsetValue));
int size = metaData.getColumnName(1).length() + 2;            
            // Process the resultset
            //
            Reader       in = null;
            CLOB    clobVal = null;
            int   clobLength = -1;
            char[]    buffer = null;
            String colValue = "";
            resultSet.setFetchDirection(OracleResultSet.FETCH_FORWARD);
            while (resultSet.next()) 
            {
                // Process the single field
                //
                if ( colType == OracleTypes.VARCHAR ) {
                    colValue = resultSet.getString(1);
                    if (resultSet.wasNull())
                        bb.put("NULL".getBytes(CharsetValue));
                    else
                        bb.put(colValue.getBytes(CharsetValue));
                    bb.put(newline.getBytes(CharsetValue));
size += colValue.length() + 2;
                    continue;
                }
                if ( colType == OracleTypes.CLOB ) {
                      clobVal = resultSet.getCLOB(1);
                      if (!_resultSet.wasNull()) {
                          in = clobVal.getCharacterStream(  ); 
                          clobLength = (int)clobVal.length(); 
                          buffer = new char[1024]; 
                          while ((clobLength = in.read(buffer)) != -1) { 
                              bb.put(String.valueOf(buffer).getBytes(CharsetValue));
                          }
                          in.close(); 
                          in = null; 
                      } else
                         bb.put("NULL".getBytes(CharsetValue));
                      bb.put(newline.getBytes(CharsetValue));
                }
            } // while
            // Write to file
            RandomAccessFile raf = new RandomAccessFile(new File(_outputFileName),"rw");
            //Mapping a file into memory
            ByteBuffer wBuf = ByteBuffer.allocate(bb.position());
            wBuf = bb.get(wBuf.array(),0,bb.position());
System.out.println("String size="+ size + " wBuf.limit()="  + wBuf.limit() + " bb.position=" + bb.position() + " wBuf.position=" + wBuf.position());
            MappedByteBuffer fileByteBuffer = raf.getChannel().map(FileChannel.MapMode.READ_WRITE, 0, wBuf.limit());
//System.out.println(raf.getChannel().size());
            fileByteBuffer.put(wBuf);
            fileByteBuffer.force();
            raf.close();
        }
        catch (SQLException sqle) {
            throw new SQLException("Error executing SQL: " + sqle);
        }
        catch (IOException ioe) {
            throw new IOException(ioe.getMessage());
        }
        catch (NonWritableChannelException  nwce) {
            throw new SQLException(nwce.getMessage());
        }
        catch (IllegalArgumentException iae) {
            throw new IllegalArgumentException(iae.getMessage());
        }
        catch (Exception e) {
            throw new RuntimeException("Error generating delimited file." + e.getMessage());
        }
    }  
}