package com.spdba.dbutils.io.exp.xbase;

import com.spdba.dbutils.Constants;
import com.spdba.dbutils.spatial.Renderer.GEO_RENDERER_FORMAT;
import com.spdba.dbutils.spatial.Renderer;
import com.spdba.dbutils.tools.FileUtils;
import com.spdba.dbutils.tools.Strings;

import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.PrecisionModel;
import org.locationtech.jts.io.oracle.OraReader;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.Reader;

import java.math.BigDecimal;

import java.nio.ByteBuffer;
import java.nio.CharBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.Charset;
import java.nio.charset.CharsetDecoder;

import java.sql.Date;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.sql.Time;
import java.sql.Timestamp;

import java.text.SimpleDateFormat;

import java.util.logging.Logger;

import oracle.jdbc.OracleResultSet;
import oracle.jdbc.OracleTypes;

import oracle.sql.CLOB;
import oracle.sql.RAW;
import oracle.sql.ROWID;
import oracle.sql.STRUCT;

import org.geotools.util.logging.Logging;

import org.xBaseJ.micro.DBF;
import org.xBaseJ.micro.DBFTypes;
import org.xBaseJ.micro.fields.CharField;
import org.xBaseJ.micro.fields.DateField;
import org.xBaseJ.micro.fields.Field;
import org.xBaseJ.micro.fields.FloatField;
import org.xBaseJ.micro.fields.LogicalField;
import org.xBaseJ.micro.fields.MemoField;
import org.xBaseJ.micro.fields.NumField;
import org.xBaseJ.micro.fields.PictureField;
import org.xBaseJ.micro.xBaseJException;


public class WriteXBaseFile {

    private static final Logger LOGGER = Logging.getLogger("com.spdba.io.export.xbase.WriteXBaseFile");
    
    private static String              DATEFORMAT = "yyyyMMdd";
    private static OraReader        geomConverter = null; 
    private static GeometryFactory    geomFactory = null;
    private static DBFTypes               DBFType = DBFTypes.DBASEIII;
    private static GEO_RENDERER_FORMAT geomFormat = GEO_RENDERER_FORMAT.EWKT;
    private static int        precisionModelScale = 3;
    private static final Integer    defaultCommit = new Integer(100);
    private static Integer                 commit = defaultCommit;

    public static void write(java.sql.ResultSet _resultSet, 
                             java.lang.String   _outputDirectory, 
                             java.lang.String   _fileName,
                             java.lang.Integer  _commit,
                             java.lang.String   _xbaseType)
    throws xBaseJException, 
           IOException, 
           Exception
    {
        // Check input
        if (Strings.isEmpty(_outputDirectory))
            // though this may not work inside Oracle if user calling procedure has not had granted write permissions
            throw new IllegalArgumentException("Output directory must be provided and Oracle user must have write permission.");
        
        if (Strings.isEmpty(_fileName) )
            throw new IllegalArgumentException("Filename must be provided");
        
        if (_commit == null || _commit.intValue() <= 0)
            setCommit(defaultCommit.intValue());
        else
            setCommit(_commit.intValue());
        
        setXBaseType(_xbaseType);

        // DBase dates have to be in format CCYYMMDD
        SimpleDateFormat df = new SimpleDateFormat(DATEFORMAT); 

        DBF aDB = null;
        try {
            String sFileName = FileUtils.FileNameBuilder(_outputDirectory,_fileName,"dbf");
            aDB = new DBF(sFileName,DBFType,true);

            ResultSetMetaData metaData = _resultSet.getMetaData();
                
            // getXbaseFields needs rowset to have been moved to first because uses it to calculate some field widths
            _resultSet.next();
            Field fields[] = getXbaseFields(_resultSet);
            
            // Populate aDB
            for (int i = 0; i < fields.length; i++) {
              aDB.addField(fields[i]);
            }

            // Now process actual rowset and add rows to aDB
            int fieldNum;
            Object fieldValue;
            do 
            {
                fieldNum = 0;
                for (int i = 1; i <= metaData.getColumnCount(); i++) 
                {
                    // skip geometry column and any undefined column types
                    if (isSupportedType(metaData.getColumnType(i),
                                        metaData.getColumnTypeName(i)))                    
                    {
                        fieldValue = getDataValue( _resultSet, 
                                                   metaData.getColumnType(i),
                                                   metaData.getScale(i),
                                                   i);
                        // Regardless as to xBase field data type all field data are put as strings
                        switch (fields[fieldNum].getType()) 
                        {
                              case 'C': ((CharField)fields[fieldNum]).put((String)fieldValue); 
                                        break;
                              case 'D': if (fieldValue.getClass().equals(Date.class))
                                            ((DateField)fields[fieldNum]).put(df.format((Date)fieldValue));
                                        else if (fieldValue.getClass().equals(Timestamp.class))
                                            ((DateField)fields[fieldNum]).put(df.format((Timestamp)fieldValue));
                                        else /* Time */
                                            ((DateField)fields[fieldNum]).put(df.format((Time)fieldValue)); 
                                        break;
                              case 'F': if (fieldValue.getClass().equals(Float.class))
                                            ((FloatField)fields[fieldNum]).put(((Float)fieldValue).floatValue()); 
                                        else
                                            ((NumField)fields[fieldNum]).put(((Double)fieldValue).doubleValue());   
                                        break;
                              case 'L': ((LogicalField)fields[fieldNum]).put(((Boolean)fieldValue).booleanValue()); 
                                        break;
                              case 'M': ((MemoField)fields[fieldNum]).put((String)fieldValue); 
                                        break;
                              case 'N': if (fieldValue.getClass().equals(Long.class))
                                          ((NumField)fields[fieldNum]).put(((Long)fieldValue).longValue()); 
                                        else
                                          ((NumField)fields[fieldNum]).put(((Double)fieldValue).doubleValue());   
                                        break;
                              case 'P': ((PictureField)fields[fieldNum]).put((byte[])fieldValue); 
                                        break;
                        }
                        fieldNum++;
                        if (fieldNum >= getMaxColumns()) {
                          break;
                        }
                    }
                }
                // write changes to disk
                // 1. Write each and every record
                //
                aDB.write();
            } while (_resultSet.next());
            aDB.close();
        } catch (xBaseJException xe) {
            throw new xBaseJException(xe.getMessage());
        } catch (IOException ioe) {
            throw new IOException(ioe.getMessage());
        } catch (SQLException sqle) {
          throw new SQLException(sqle.getMessage());          
        } finally {
            try { aDB.close(); } catch (Exception e) {}
            aDB = null;
        }
    }
    
    // Note, Max columns in Oracle table is 1000    
    private static int getMaxColumns() {
      switch (DBFType) {
        case DBASEIII :  
        case DBASEIII_WITH_MEMO : return 128;
        case DBASEIV : 
        case DBASEIV_WITH_MEMO  : return 256;
        case FOXPRO_WITH_MEMO   : return 255;
        default: return 0;
      }
    }

    public static void setXBaseType(String _xbaseType) {
        DBFType = DBFTypes.valueOf(_xbaseType);
    }
    
    protected static boolean hasMemo() {
        return DBFType == DBFTypes.DBASEIII_WITH_MEMO || 
               DBFType == DBFTypes.DBASEIV_WITH_MEMO || 
               DBFType == DBFTypes.FOXPRO_WITH_MEMO;
    }
    

    public static void setPrecisionScale ( int scale ) {
        precisionModelScale = scale;
    }    

    public static void setCommit(int _commit) {
      commit = new Integer(_commit);
    }
    
    public static int getCommit() {
        return commit.intValue();
    }
    
    /**
     * Determines if the given column type is defined/handled by this writer.  Undefined column types
     * are ignored by this writer.
     * @param columnType the oracle column type.
     * @return true if the column type is defined, otherwise false.
     */
    protected static boolean isSupportedType(int    columnType,
                                             String columnTypeName) 
    {
        return DBaseWriter.isSupportedType(columnType,columnTypeName);
    }
    
    /**
     * Counts resultSet fields that are supported in output XBase file
     * @param metaData the result set's metadata
     * @throws SQLException if there is an error reading the result set metadata. 
     */
    protected static int supportedColumnCount(ResultSetMetaData metaData) 
    throws SQLException
    {
        int fieldCount = 0;
        for (int i = 1; i <= metaData.getColumnCount(); i++) {
            // Any sdo_geometry object is written to dbase file as string
            //            
            if (DBaseWriter.isSupportedType(metaData.getColumnType(i),
                                            metaData.getColumnTypeName(i))) {
                fieldCount++;
            }
        }
        return fieldCount;
    }
    
    /**
     * Validates the given length is valid for a Dbase char column.
     * @param length the length to validate.
     * @return the maximum length for a Dbase char column if length exceeds the maximum; otherwise
     * returns length.
     */
    protected static int validateMaxCharLength(int length) {
            return (length > DBaseWriter.MAX_CHAR_LENGTH ? DBaseWriter.MAX_CHAR_LENGTH : length);
    }
    
    /**
     * Validates the given length is valid for a Dbase numeric column.
     * @param length the length to validate.
     * @return the maximum length for a Dbase numeric column if the length exceeds the maximum; otherwise
     * returns length.
     */
    protected static int validateMaxNumericLength(int length) {
            return (length > DBaseWriter.MAX_NUMERIC_LENGTH ? DBaseWriter.MAX_NUMERIC_LENGTH : length);
    }

    /**
     * Maps Oracle columns to XBase field types and returns the field object
     * @param resultSet from whose metaData the XBase fields are created.
     * @param columnIndex the index of the column to consider in the result set metadata.
     * @return the appropriate Dbase column length.
     * @throws SQLException if there is an error reading the result set metadata.
     */
    protected static Field getXbaseField(ResultSet  resultSet,
                                         int        columnIndex) 
    throws  SQLException,
            IOException,
            xBaseJException 
    {
        ResultSetMetaData  metaData = resultSet.getMetaData();
        
        Field field = null;
        String fieldName = metaData.getColumnName(columnIndex).toUpperCase();  // Locale?    
        String dbaseFieldName = fieldName.substring(0,(fieldName.length() > 10 ? 9 : fieldName.length()));
        switch (metaData.getColumnType(columnIndex))
        {
            case OracleTypes.STRUCT :
            case OracleTypes.CLOB:
                if ( hasMemo() )
                    field = new MemoField(dbaseFieldName);
                else
                    field = new CharField(dbaseFieldName, DBaseWriter.MAX_CHAR_LENGTH);
                break;
            case -3:
            case OracleTypes.RAW:
            case OracleTypes.VARCHAR:
                if ( metaData.getColumnDisplaySize(columnIndex) <= DBaseWriter.MAX_CHAR_LENGTH )
                    field =  new CharField(dbaseFieldName,metaData.getColumnDisplaySize(columnIndex));
                else {
                    if (hasMemo())
                        field = new MemoField(dbaseFieldName);
                    else 
                        field = new CharField(dbaseFieldName, DBaseWriter.MAX_CHAR_LENGTH);
                }
                break;
            case OracleTypes.ROWID:
                // Obtain the ROWID as a ROWID objects(which is an Oracle Extension
                // datatype. Since ROWID is an Oracle extension, the getROWID method
                // is not available in the ResultSet class. Hence ResultSet has to be
                // cast to OracleResultSet
                ROWID rowid = ((OracleResultSet)resultSet).getROWID(columnIndex);
                if ( rowid.getLength() <= DBaseWriter.MAX_CHAR_LENGTH )
                    field =  new CharField(dbaseFieldName,(int)rowid.getLength());
                else {
                    if (hasMemo())
                        field = new MemoField(dbaseFieldName);
                    else 
                        field = new CharField(dbaseFieldName, DBaseWriter.MAX_CHAR_LENGTH);
                }
                break;
            case OracleTypes.CHAR :
                 field =  new CharField(dbaseFieldName,metaData.getColumnDisplaySize(columnIndex));
                 break;
            case OracleTypes.INTEGER :
            case OracleTypes.SMALLINT :
                 field =  new NumField(dbaseFieldName,
                                     validateMaxCharLength(metaData.getColumnDisplaySize(columnIndex)),
                                     0);
                 break;
            case OracleTypes.DECIMAL:
            case OracleTypes.NUMERIC :
                // If scale == 0 then make it a Long otherwise a Double
                // After all, we are just writing the data to a text file!
                int iScale = metaData.getScale(columnIndex);
                if ( iScale == 0 )
                    field =  new NumField(dbaseFieldName,
                                          (metaData.getPrecision(columnIndex) > 0) ?
                                          metaData.getPrecision(columnIndex) :
                                          validateMaxCharLength(metaData.getColumnDisplaySize(columnIndex)),
                                          0);
                else {
                    int colPrecision = 0;
                    colPrecision = ( metaData.getPrecision(columnIndex) == 0 ? 
                                     metaData.getColumnDisplaySize(columnIndex) : 
                                     metaData.getPrecision(columnIndex) ) + 1;       
                    if ( colPrecision >= DBaseWriter.MAX_NUMERIC_LENGTH && iScale != 0)
                        field = new FloatField(dbaseFieldName, DBaseWriter.MAX_NUMERIC_LENGTH,
                                               (iScale < 0) ? 
                                               (DBaseWriter.MAX_NUMERIC_SCALE / 2) /* How determine??? */ : 
                                               iScale);
                    else
                        field =  new NumField(dbaseFieldName,
                                              validateMaxNumericLength(colPrecision),
                                              (( metaData.getScale(columnIndex) <= 0 ) ? 
                                              0 : iScale + 1 ));
                }
                break;
            case OracleTypes.DOUBLE :
            case OracleTypes.FLOAT :
                 field = new FloatField(dbaseFieldName, DBaseWriter.MAX_NUMERIC_LENGTH, (DBaseWriter.MAX_NUMERIC_LENGTH / 2) );
                 break;
             case -100: /* This is actually a TIMESTAMP */
             case OracleTypes.TIMESTAMP :
             case OracleTypes.DATE:
             case OracleTypes.TIME :
                  field =  new DateField(dbaseFieldName);
                  break;
         } // switch case
        return field;
    }

    /**
     * Creates the Xbase file header Field set for all valid fields in the result set.
     * @param resultSet - The resultSet whose metaData is used to define the Xbase header.
     * @throws SQLException if there is an error reading the result set metadata. 
     * @throws xBaseJException if there is an error creating the header file object.
     */
    protected static Field[] getXbaseFields(ResultSet resultSet) 
    throws  SQLException, 
            xBaseJException ,
            IOException
    {
        // get resultset meta data
        ResultSetMetaData metaData = resultSet.getMetaData();
        
        // Create Field Array from supported attributes
        Field header[] = new Field[supportedColumnCount(metaData)];        
        
        int columnIndex = 0;
        for (int i = 1; i <= metaData.getColumnCount(); i++) {
            // ignore unrecognised types
            //
            if (isSupportedType(metaData.getColumnType(i),
                                metaData.getColumnTypeName(i)) ) 
            {
                try {
                    header[columnIndex] = getXbaseField(resultSet,i);
                    columnIndex++;
                }
                catch (xBaseJException dfe) {
                        throw new xBaseJException("Error constructing dBase file header" + dfe.getLocalizedMessage());
                }
            }
        }
        return header;
    }

    /**
     * Reads the value at the specified column index as an object of the given class type.
     * @param resultSet the result set.
     * @param columnType the required object column type.
     * @param columnIndex the column index to read in the result set.
     * @return the value as the required type.
     * @throws SQLException if there is an error reading the result set.
     */
    protected static Object getDataValue(ResultSet resultSet, 
                                         int       columnType,
                                         int       dataScale,
                                         int       columnIndex) 
    throws  SQLException,
            IOException
    {
        Object xbaseObject = null;
        
        // Actual Geometry object
        String sGeometry = "";
        STRUCT stGeom = null;
        switch (columnType)
        {
            case OracleTypes.STRUCT :
                sGeometry = "";
                // Must be SDO_GEOMETRY as the isSupportedType only allows SDO_GEOMETRY STRUCTs
                stGeom = (STRUCT) resultSet.getObject(columnIndex);
            Renderer.renderSdoGeometry(stGeom, Renderer.GEO_RENDERER_FORMAT.EWKT);
                xbaseObject = hasMemo() ? 
                              sGeometry : 
                              sGeometry.substring(0,
                                                  (sGeometry.length() > DBaseWriter.MAX_CHAR_LENGTH ?
                                     DBaseWriter.MAX_CHAR_LENGTH - 1 : 
                                                  sGeometry.length()));
                break;
            case OracleTypes.CLOB:
                String sClob = "";
                CLOB clobVal = ((OracleResultSet)resultSet).getCLOB(columnIndex);
                if (!resultSet.wasNull()) {
                    Reader in = clobVal.getCharacterStream(  ); 
                    int length = (int)clobVal.length(); 
                    char[] buffer = new char[1024]; 
                    while ((length = in.read(buffer)) != -1) { 
                        sClob += String.valueOf(buffer).substring(0,length);
                    } 
                    in.close( ); 
                    in = null; 
                }
                xbaseObject =   hasMemo() ? 
                                sClob : 
                                sClob.substring(0,
                                              (sClob.length() > DBaseWriter.MAX_CHAR_LENGTH ? DBaseWriter.MAX_CHAR_LENGTH - 1 : 
                                              sClob.length()));
                break;
            case -3:
            case OracleTypes.RAW:
                RAW rawval = ((OracleResultSet)resultSet).getRAW(columnIndex);
                String sRaw = rawval.stringValue();
                xbaseObject = hasMemo() ? 
                                sRaw : 
                                sRaw.substring(0,
                                              (sRaw.length() > DBaseWriter.MAX_CHAR_LENGTH ? DBaseWriter.MAX_CHAR_LENGTH - 1 : 
                                              sRaw.length()));
                break;
            case OracleTypes.ROWID:
                // Obtain the ROWID as a ROWID objects(which is an Oracle Extension
                // datatype. Since ROWID is an Oracle extension, the getROWID method
                // is not available in the ResultSet class. Hence ResultSet has to be
                // cast to OracleResultSet
                String sRowid;
                ROWID rowid = ((OracleResultSet)resultSet).getROWID(columnIndex);
                // Oracle ROWIDs are coded in HEX which means that a delimiter can't appear in it unless delimiter 0-9,A-F
                ByteBuffer asciiBytes = ByteBuffer.wrap(rowid.getBytes());
                Charset charset = Charset.forName("US-ASCII");
                CharsetDecoder decoder = charset.newDecoder();
                CharBuffer rowidChars = null;
                try {
                   rowidChars = decoder.decode(asciiBytes);
                } catch (CharacterCodingException e) {
                   System.err.println("Error decoding rowid");
                   System.exit(-1);
                }
                sRowid = rowidChars.toString();
                xbaseObject = hasMemo() ? 
                                sRowid : 
                                sRowid.substring(0,
                                                (sRowid.length() > DBaseWriter.MAX_CHAR_LENGTH ? DBaseWriter.MAX_CHAR_LENGTH - 1 : 
                                                sRowid.length()));
                break;
            case OracleTypes.CHAR :
                  xbaseObject = String.valueOf(resultSet.getByte(columnIndex));
                  break;
            case OracleTypes.VARCHAR :
                  xbaseObject = resultSet.getString(columnIndex);
                  break;
            case OracleTypes.TIME :
                 xbaseObject = resultSet.getTime(columnIndex);
                 break;
            case OracleTypes.SMALLINT :
                 xbaseObject = new Short(resultSet.getShort(columnIndex));
                 break;
            case OracleTypes.INTEGER :
                 xbaseObject = new Integer(resultSet.getInt(columnIndex));
                 break;
            case OracleTypes.DECIMAL:
                 xbaseObject = new BigDecimal(resultSet.getDouble(columnIndex));
                 break;
            case OracleTypes.NUMERIC :
                // If scale == 0 then make it a Long otherwise a Double
                if ( dataScale == 0 )
                    xbaseObject = new Long(resultSet.getLong(columnIndex));
                else
                    xbaseObject = new Double(resultSet.getDouble(columnIndex));
                 break;
            case OracleTypes.FLOAT :
                 xbaseObject = new Float(resultSet.getFloat(columnIndex));
                 break;
            case OracleTypes.DOUBLE :
                 xbaseObject = new Double(resultSet.getDouble(columnIndex));
                 break;
             case -100: /* This is actually a TIMESTAMP */
             case OracleTypes.TIMESTAMP :
                 xbaseObject = resultSet.getTimestamp(columnIndex);
                 break;
             case OracleTypes.DATE:
                 xbaseObject = resultSet.getDate(columnIndex);
                 break;
             default: xbaseObject = resultSet.getObject(columnIndex);
        } // switch case
        return xbaseObject;
    }

    public static void writeXBaseFile(java.sql.ResultSet _resultSet, 
                                      java.lang.String   _outputDirectory, 
                                      java.lang.String   _fileName,
                                      java.lang.Integer  _commit,
                                      java.lang.String   _xbaseType,
                                      java.lang.String   _geomFormat)
    throws xBaseJException, 
           IOException, 
           Exception
    {
        // Check input
        if (Strings.isEmpty(_outputDirectory) ) {
            // though this may not work inside Oracle if user calling procedure has not had granted write permissions
            throw new IllegalArgumentException("Output directory must be provided and Oracle user must have write permission.");
        }
        
        if (Strings.isEmpty(_fileName) ) {
            throw new IllegalArgumentException("Filename must be provided");
        }
        
        geomFormat = Renderer.GEO_RENDERER_FORMAT.getRendererFormat(_geomFormat);
        setXBaseType(_xbaseType);
        geomFactory   = new GeometryFactory(new PrecisionModel(precisionModelScale));
        geomConverter = new OraReader(geomFactory);
        
        try {
            // Write DBF 
            //
            write(_resultSet,
                  _outputDirectory,
                  _fileName,
                  _commit,
                  _xbaseType);
                        
        } catch (FileNotFoundException fnfe) {
            throw new FileNotFoundException("Unable to access directory for writing: "+fnfe);
        }
        catch (IOException ioe) {
            throw new IOException("Error initialising output streams for writing"+ioe);
        }
    }

    public static Renderer.GEO_RENDERER_FORMAT getGeomFormat() {
        return geomFormat;
    }

    public static void setGeomFormat(Renderer.GEO_RENDERER_FORMAT geomFormat) {
        WriteXBaseFile.geomFormat = geomFormat;
    }

    public static void setGeomFormat(String _geomFormat) {
        WriteXBaseFile.geomFormat = Renderer.GEO_RENDERER_FORMAT.getRendererFormat(_geomFormat);
    }
    
}
