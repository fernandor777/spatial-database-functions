package com.spdba.dbutils.io.exp.xbase;

import com.spdba.dbutils.Constants;
import com.spdba.dbutils.spatial.SDO;
import com.spdba.dbutils.sql.OraRowSetMetaDataImpl;
import com.spdba.dbutils.tools.Strings;

import org.locationtech.jts.geom.Geometry;

import java.io.IOException;
import java.io.Reader;

import java.math.BigDecimal;

import java.nio.ByteBuffer;
import java.nio.CharBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.Charset;
import java.nio.charset.CharsetDecoder;

import java.sql.ResultSet;
import java.sql.SQLException;

import java.text.SimpleDateFormat;

import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.logging.Logger;

import javax.sql.RowSetMetaData;

import oracle.jdbc.OracleResultSet;
import oracle.jdbc.OracleTypes;

import oracle.sql.CLOB;
import oracle.sql.INTERVALDS;
import oracle.sql.NCLOB;
import oracle.sql.RAW;
import oracle.sql.ROWID;

import org.geotools.util.logging.Logging;

import org.xBaseJ.micro.DBF;
import org.xBaseJ.micro.DBFTypes;
import org.xBaseJ.micro.fields.Field;
import org.xBaseJ.micro.fields.CharField;
import org.xBaseJ.micro.fields.DateField;
import org.xBaseJ.micro.fields.FloatField;
import org.xBaseJ.micro.fields.MemoField;
import org.xBaseJ.micro.fields.NumField;
import org.xBaseJ.micro.xBaseJException;


public class DBaseWriter {

    private static final Logger LOGGER = Logging.getLogger("com.spdba.export.io.xbase.DBaseWriter");

    /** Maximum char column length allowed in Dbase (other than Memo). **/    
    public static final int       MAX_CHAR_LENGTH = 254;
    public static final int          ROWID_LENGTH = 18;
    
    /** Maximum numeric column length allowed in Dbase III. 
    * MapInfo allows 19. Some dbase doc says 19,15, xBase says:
    * FloatField - Length range is 1 to 19 bytes
    * FloatField - Number of decimal positions range from 2 to 17 byte
    **/
    public static final int    MAX_INTEGER_LENGTH = 15;
    public static final int    MAX_NUMERIC_LENGTH = 19;
    public static final int     MAX_NUMERIC_SCALE = 17;
    public static final int     MIN_NUMERIC_SCALE = 2;
  
    /** Binary Precision indicator **/
    public static final int BINARY_SCALE_INDICTOR = -127;
    /** Binary Precision indicator == 18 Decimal digits of precision **/
    public static final int        REAL_INDICATOR = 63;
    /** Binary Precision indicator == 38 Decimal digits of precision **/
    public static final int      DOUBLE_INDICATOR = 126;
    /** FLOAT(n) - number with max number of binary digits of b (multiply by 0.30103 to get number of decimal digits **/
    public static final double  BINARY_TO_DECIMAL = 0.30103;
    
    public String                      DATEFORMAT = "yyyyMMdd";
    public DBF                             DBFile = null;
    public DBFTypes                       DBFType = DBFTypes.DBASEIII;
    public LinkedHashMap<String,Field>     fields = null;
    private SimpleDateFormat                   df = null; 
    private String           recordIdentifierName = null;

    public DBaseWriter() {
        this.df = new SimpleDateFormat(DATEFORMAT); 
    }

    public boolean needsRecordIdentifier() {
        return Strings.isEmpty(this.recordIdentifierName) ? false : true;
    }

    public void setRecordIdentiferName(String _rid) {
        this.recordIdentifierName = Strings.isEmpty(_rid) ? null : _rid.toUpperCase();
    }

    public String getRecordIdentiferName() {
        return this.recordIdentifierName;
    }
    
    // DBase dates have to be in format CCYYMMDD
    public SimpleDateFormat getDateFormat() {
      return this.df;
    }

    public void setDateFormat(SimpleDateFormat _sdf) {
      this.df = _sdf;
    }

    public Field getField(String _fieldName) 
    throws Exception 
    {
        if (Strings.isEmpty(_fieldName) ) {
            return null;
        }
        if ( this.fields == null || this.fields.size()==0 ) {
            throw new Exception("DBF Header Has No Fields");
        }
        Field f = fields.get(_fieldName);
        if ( f==null ) {
            throw new Exception("DBF Field, " + _fieldName + ", Does Not Exist");
        }
        return f;
    }

    public void setField(Field _field) 
    throws Exception 
    {
        if ( _field == null ) {
            return;
        }
        if ( this.fields == null || this.fields.size()==0 ) {
            throw new Exception("DBF Header Has No Fields");
        }
        if ( this.fields.containsKey(_field.getName()) ) {
            this.fields.put(_field.getName(), _field);
        }
    }
    
    // Note, Max columns in Oracle table is 1000    
    public int getMaxColumns() {
      switch (this.DBFType) {
        case DBASEIII :  
        case DBASEIII_WITH_MEMO : return 128;
        case DBASEIV : 
        case DBASEIV_WITH_MEMO  : return 256;
        case FOXPRO_WITH_MEMO   : return 255;
        default: return 0;
      }
    }
    
    public DBFTypes getXBaseType() {
        return this.DBFType;  
    }
    
    public void setXBaseType(DBFTypes _xBaseType) {
        switch ( _xBaseType ) {
          case DBASEIII           : this.DBFType = DBFTypes.DBASEIII; break;
          case DBASEIV            : this.DBFType = DBFTypes.DBASEIV; break;
          case DBASEIII_WITH_MEMO : this.DBFType = DBFTypes.DBASEIII_WITH_MEMO; break;
          case DBASEIV_WITH_MEMO  : this.DBFType = DBFTypes.DBASEIV_WITH_MEMO; break;
          case FOXPRO_WITH_MEMO   : this.DBFType = DBFTypes.FOXPRO_WITH_MEMO; break;
          default                 : this.DBFType = DBFTypes.DBASEIII; break;
        }
    }
          
    public void setXBaseType(String _xBaseType) {
        DBFTypes xType = DBFTypes.DBASEIII;
        try {
            xType = DBFTypes.valueOf(_xBaseType);
        } catch (Exception e) {
            xType = DBFTypes.DBASEIII;
        }
        setXBaseType(xType);
    }
    
    public boolean hasMemo() {
        return this.DBFType == DBFTypes.DBASEIII_WITH_MEMO || 
               this.DBFType == DBFTypes.DBASEIV_WITH_MEMO || 
               this.DBFType == DBFTypes.FOXPRO_WITH_MEMO;
    }

    /**
     * Determines if the given column type is defined/handled by this writer.  Undefined column types
     * are ignored by this writer.
     * @param columnType the oracle column type.
     * @return true if the column type is defined, otherwise false.
     */
    public static boolean isSupportedType(int    columnType,
                                          String columnTypeName) 
    {
            return (columnType == OracleTypes.ROWID ||
                    columnType == OracleTypes.NCLOB ||
                    columnType == OracleTypes.CLOB  ||
                    columnType == OracleTypes.NCHAR || 
                    columnType == OracleTypes.CHAR  || 
                    columnType == OracleTypes.NVARCHAR || 
                    columnType == OracleTypes.VARCHAR  || 
                    columnType == OracleTypes.SMALLINT ||
                    columnType == OracleTypes.INTEGER  ||
                    columnType == OracleTypes.NUMBER   || 
                    columnType == OracleTypes.FLOAT    ||
                    columnType == OracleTypes.DOUBLE   ||
                    columnType == OracleTypes.BINARY_DOUBLE ||
                    columnType == OracleTypes.BINARY_FLOAT  ||
                    columnType == OracleTypes.DATE ||
                    columnType == OracleTypes.TIME || 
                    columnType == OracleTypes.TIMESTAMP ||
                    columnType == OracleTypes.INTERVALDS || 
                    columnType == OracleTypes.INTERVALYM ||                     
                    columnType == OracleTypes.TIMESTAMP || 
                    columnType == OracleTypes.TIMESTAMPTZ || 
                    columnType == OracleTypes.TIMESTAMPLTZ || 
                    ( columnType == OracleTypes.STRUCT &&
                      ( columnTypeName.equalsIgnoreCase(SDO.TAG_MDSYS_SDO_GEOMETRY)   ||
                        columnTypeName.equalsIgnoreCase(SDO.TAG_MDSYS_ST_GEOMETRY)    ||
                        columnTypeName.equalsIgnoreCase(SDO.TAG_MDSYS_SDO_POINT_TYPE) ||
                        columnTypeName.equalsIgnoreCase(SDO.TAG_MDSYS_VERTEX_TYPE) 
                      ) 
                    )
                );
    }
    
    /**
     * Counts resultSet fields that are supported in output XBase file
     * @param metaData the result set's metadata
     * @throws SQLException if there is an error reading the result set metadata. 
     */
    public static int supportedColumnCount(Map<Integer,RowSetMetaData> _metaData,
                                           String                      _geomColumn) 
    throws SQLException
    {
        int fieldCount = 0;
        RowSetMetaData rsmd;
        Iterator iter = _metaData.keySet().iterator();
        while (iter.hasNext()) {
            rsmd = _metaData.get(iter.next());
            // We don't add actual geometry object to dbase file
            //
            if (Strings.isEmpty(_geomColumn) ||
                 rsmd.getColumnName(1).replace("\"","").equalsIgnoreCase(_geomColumn.replace("\"","")) ) {
                continue;
            }
            if (isSupportedType(rsmd.getColumnType(1),
                                rsmd.getColumnTypeName(1))) {
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
    public static int validateMaxCharLength(int length) {
            return (length > MAX_CHAR_LENGTH ? MAX_CHAR_LENGTH : length);
    }
    
    /**
     * Validates the given length is valid for a Dbase numeric column.
     * @param length the length to validate.
     * @return the maximum length for a Dbase numeric column if the length exceeds the maximum; otherwise
     * returns length.
     */
    public static int validateMaxNumericLength(int length) {
            return (length > MAX_NUMERIC_LENGTH ? MAX_NUMERIC_LENGTH : length);
    }

    private String mapOraColumnNameToDBFName(String _oraColumnName) {
        String mappedName = "";
        mappedName = Strings.Left(_oraColumnName,10);
        // Check if exists
        if ( this.fields == null || this.fields.size()==0 ) {
            return mappedName; // Let other methods take care of this problem
        }
        Field f = fields.get(mappedName);
        int prefix = 0;
        // Loop until we have a unique name
        while ( f!=null && prefix < 100) {
            // Add digit to end of string.
            if ( prefix <= 9 ) 
                mappedName = mappedName.substring(0,8) + String.valueOf(prefix);
            else
                 mappedName = mappedName.substring(0,7) + String.valueOf(prefix);
            f = fields.get(mappedName);
        }
        return mappedName;  // if mappedName not unique, at least I tried!
    }
    
    /**
     * Maps Oracle columns to XBase field types and returns the field object
     * @param _metaData from which the XBase fields are created.
     * @return the appropriate Dbase column length.
     * @throws SQLException if there is an error reading the result set metadata.
     */
    public Field getXbaseField(OraRowSetMetaDataImpl _metaData) 
    throws  SQLException,
            IOException,
            xBaseJException 
    {
        OraRowSetMetaDataImpl orsmd = (OraRowSetMetaDataImpl)_metaData;
        Field field = null;
        String fieldName = orsmd.getColumnName(1).toUpperCase();  // Locale?
        String dbaseFieldName = this.mapOraColumnNameToDBFName(fieldName);
        switch (orsmd.getColumnType(1))
        {
           case OracleTypes.ROWID : field = new CharField(dbaseFieldName,ROWID_LENGTH); break;
           case OracleTypes.BLOB  : 
           case OracleTypes.BFILE :
           case OracleTypes.VARBINARY:
           case OracleTypes.RAW   : break;
        
           case OracleTypes.NCLOB :
           case OracleTypes.CLOB  : if ( this.hasMemo() )
                                        field = new MemoField(dbaseFieldName);
                                    else
                                        field = new CharField(dbaseFieldName,MAX_CHAR_LENGTH);
                                    break;
            case OracleTypes.NCHAR:
            case OracleTypes.CHAR     : field =  new CharField(dbaseFieldName,orsmd.getPrecision(1)); break;
        
            case OracleTypes.NVARCHAR :
            case OracleTypes.VARCHAR  : if ( orsmd.getColumnDisplaySize(1) <= MAX_CHAR_LENGTH )
                                            field =  new CharField(dbaseFieldName,orsmd.getColumnDisplaySize(1));
                                        else {
                                            if (this.hasMemo())
                                                field = new MemoField(dbaseFieldName);
                                            else 
                                                field = new CharField(dbaseFieldName,MAX_CHAR_LENGTH);
                                        }
                                        break;
                
            case OracleTypes.INTEGER  :
            case OracleTypes.SMALLINT : field =  new NumField(dbaseFieldName,
                                                              validateMaxCharLength(orsmd.getColumnDisplaySize(1)),
                                                              0);
                                        break;
            case OracleTypes.DECIMAL  :
            case OracleTypes.NUMBER   : // If scale == 0 then make it a Long otherwise a Double
                                        // After all, we are just writing the data to a text file!
                                        int iScale       = orsmd.getScale(1);
                                        int colPrecision = orsmd.getPrecision(1);
                                        if ( (colPrecision == 0 && iScale == 0 ) || 
                                              colPrecision >= MAX_NUMERIC_LENGTH ) {
                                            // Make it a max sized NumField
                                            field = new FloatField(dbaseFieldName,
                                                                   MAX_NUMERIC_LENGTH,
                                                                   (iScale <= 0) ? (MAX_NUMERIC_SCALE / 2) /* How determine??? */ : iScale);
                                            
                                        } else if ( iScale == 0 && orsmd.getPrecision(1) < 63 ) {
                                            field =  new NumField(dbaseFieldName,
                                                                  validateMaxNumericLength(orsmd.getPrecision(1)),
                                                                  0);
                                        } else {
                                            field =  new NumField(dbaseFieldName,
                                                                  validateMaxNumericLength(colPrecision),
                                                                  (iScale <= 0 ? 0 : iScale));
                                        }
                                        break;
            case OracleTypes.BINARY_DOUBLE :
            case OracleTypes.BINARY_FLOAT  :
            case OracleTypes.DOUBLE        :
            case OracleTypes.FLOAT         : field = new FloatField(dbaseFieldName, MAX_NUMERIC_LENGTH, (MAX_NUMERIC_LENGTH / 2) ); break;
            case OracleTypes.INTERVALDS    : 
            case OracleTypes.INTERVALYM    : field = new CharField(dbaseFieldName,20); break;
            case OracleTypes.TIMESTAMP     :
            case OracleTypes.TIMESTAMPTZ   :
            case OracleTypes.TIMESTAMPLTZ  : field = new CharField(dbaseFieldName,40); break;
            case -100: /* This is actually a TIMESTAMP */
            case OracleTypes.DATE          :
            case OracleTypes.TIME          : field =  new DateField(dbaseFieldName); break;
            case OracleTypes.STRUCT :
               if ( orsmd.getColumnTypeName(1).equalsIgnoreCase(SDO.TAG_MDSYS_SDO_GEOMETRY)   ||
                    orsmd.getColumnTypeName(1).equalsIgnoreCase(SDO.TAG_MDSYS_ST_GEOMETRY)    ||
                    orsmd.getColumnTypeName(1).equalsIgnoreCase(SDO.TAG_MDSYS_SDO_POINT_TYPE) ||
                    orsmd.getColumnTypeName(1).equalsIgnoreCase(SDO.TAG_MDSYS_VERTEX_TYPE) ) {
                   if ( this.hasMemo() )
                       field = new MemoField(dbaseFieldName);
                   else
                       field = new CharField(dbaseFieldName,MAX_CHAR_LENGTH);
                   break;
              }
              break;
         } // switch case
        return field;
    }

    public LinkedHashMap<String,Field> getFields() {
        return this.fields;
    }
    
    /**
     * Creates the Xbase file header Field set for all valid fields in the result set.
     * @param resultSet - The resultSet whose metaData is used to define the Xbase header.
     * @throws SQLException if there is an error reading the result set metadata. 
     * @throws xBaseJException if there is an error creating the header file object.
     */
    public void createHeader(LinkedHashMap<Integer,RowSetMetaData> _metaData,
                             String                                _geomColumnName) 
    throws  SQLException, 
            xBaseJException,
            IOException
    {

        fields = new LinkedHashMap<String,Field>();
        int numberOfFields = supportedColumnCount(_metaData,
                                                  _geomColumnName);

        // If numberOfFields==0 then we only have an SDO_GEOMETRY column: we need at least an integer ID to write to DBF file.
        if ( numberOfFields==0 ) {
            if (Strings.isEmpty(this.recordIdentifierName)==false ) {
              Field f = new NumField(this.recordIdentifierName, DBaseWriter.MAX_INTEGER_LENGTH,
                                     0 /*Scale*/);
              fields.put(this.recordIdentifierName,f);
              // Add field to dbaseFile's header
              //
              this.DBFile.addField(f);
              // Nothing more to do
              return;
            } else {
                throw new IOException("DBaseWriter.createHeader(): Can't have a DBF File With No Attributes");
            }
        } 

        // Add to Field Array supported attributes
        //
        RowSetMetaData rsmd;
        String columnName = "";
        Iterator iter = _metaData.keySet().iterator();
        while (iter.hasNext()) {
            rsmd = _metaData.get(iter.next());
            columnName = (Strings.isEmpty(rsmd.getColumnLabel(1))
                          ? rsmd.getColumnName(1)
                          : rsmd.getColumnLabel(1));
            
            // We don't add actual geometry object to dbase file
            //
            if ( columnName.equalsIgnoreCase(_geomColumnName) ) {
                continue;
            }

            // ignore unrecognised types
            //
            if (isSupportedType(rsmd.getColumnType(1),
                                rsmd.getColumnTypeName(1)))
            {
                try {
                    // Create field
                    //
                    Field fld = getXbaseField((OraRowSetMetaDataImpl)rsmd);
                    fields.put(columnName, fld);
                    // Populate dbaseFile's header
                    //
                    this.DBFile.addField(fld);
                }
                catch (IOException ioe) {
                    ioe.printStackTrace();
                    throw new xBaseJException("DBaseWriter.createHeader: DBF Header IO Error is " + ioe.getLocalizedMessage());
                }
                catch (xBaseJException dfe) {
                    dfe.printStackTrace();
                    throw new xBaseJException("DBaseWriter.createHeader: DBF Header XBase Error is " + dfe.getLocalizedMessage());
                }
            }
        }
    }
    
    public void createDBF(String _sFileName,
                          String _encoding) 
    throws xBaseJException,
           IOException 
    {
        this.DBFile = new DBF(_sFileName,
                              this.DBFType,
                              true,
                              _encoding);
    }
    
    public void write() 
    throws xBaseJException, 
           IOException {
        this.DBFile.write();
    }

    public void close() 
    throws IOException {
        try {
            this.DBFile.close();
        } catch (IOException ioe) {
            throw new IOException("IOException: DBaseWriter.close(): " + ioe.getMessage());
        } catch (Exception ioe) {
            throw new IOException("Exception: DBaseWriter.close(): " + ioe.getMessage());
        }

    }
    
    /**
     * Reads the value at the specified column index as an object of the given class type.
     * @param resultSet the result set.
     * @param columnType the required object column type.
     * @param columnIndex the column index to read in the result set.
     * @return the value as the required type.
     * @throws SQLException if there is an error reading the result set.
     */
    public Object getDataValue(ResultSet resultSet,
                               int       columnType,
                               int       dataScale,
                               int       columnIndex) 
    throws  SQLException,
            IOException
    {
        Object xbaseObject = null;
        
        // Actual Geometry object
        Geometry geom;
        switch (columnType)
        {
            case OracleTypes.STRUCT :
                String sGeometry = "";
                xbaseObject = hasMemo() ? 
                              sGeometry : 
                              sGeometry.substring(0,
                                                  (sGeometry.length() > MAX_CHAR_LENGTH ? 
                                                  MAX_CHAR_LENGTH - 1 : 
                                                  sGeometry.length()));
                break;
            case OracleTypes.NCLOB:
            String nClob = "";
            NCLOB nClobVal = (oracle.sql.NCLOB)((OracleResultSet)resultSet).getObject(columnIndex);
            if (!resultSet.wasNull()) {
                Reader in = nClobVal.getCharacterStream(  ); 
                int length = (int)nClobVal.length(); 
                char[] buffer = new char[1024]; 
                while ((length = in.read(buffer)) != -1) { 
                    nClob += String.valueOf(buffer).substring(0,length);
                } 
                in.close( ); 
                in = null; 
            }
            xbaseObject = this.hasMemo() 
                          ? nClob 
                          : nClob.substring(0,
                                          (nClob.length() > MAX_CHAR_LENGTH ? 
                                          MAX_CHAR_LENGTH - 1 : 
                                          nClob.length()));
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
                xbaseObject = this.hasMemo() 
                              ? sClob 
                              : sClob.substring(0,
                                              (sClob.length() > MAX_CHAR_LENGTH ? 
                                              MAX_CHAR_LENGTH - 1 : 
                                              sClob.length()));
                break;
            case -3:
            case OracleTypes.RAW:
                RAW rawval = ((OracleResultSet)resultSet).getRAW(columnIndex);
                String sRaw = rawval.stringValue();
                xbaseObject = hasMemo() ? 
                                sRaw : 
                                sRaw.substring(0,
                                              (sRaw.length() > MAX_CHAR_LENGTH ? 
                                              MAX_CHAR_LENGTH - 1 : 
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
                   LOGGER.info("Error decoding rowid");
                   System.exit(-1);
                }
                sRowid = rowidChars.toString();
                xbaseObject = hasMemo() ? 
                                sRowid : 
                                sRowid.substring(0,
                                                (sRowid.length() > MAX_CHAR_LENGTH ? 
                                                MAX_CHAR_LENGTH - 1 : 
                                                sRowid.length()));
                break;
            case OracleTypes.NCHAR       :
            case OracleTypes.CHAR        : xbaseObject = String.valueOf(resultSet.getByte(columnIndex)); break;
            case OracleTypes.NVARCHAR    : xbaseObject = resultSet.getNString(columnIndex); break;
            case OracleTypes.VARCHAR     : xbaseObject = resultSet.getString(columnIndex); break;
            case OracleTypes.TIME        : xbaseObject = resultSet.getTime(columnIndex); break;
            case OracleTypes.SMALLINT    : xbaseObject = new Short(resultSet.getShort(columnIndex)); break;
            case OracleTypes.INTEGER     : xbaseObject = new Integer(resultSet.getInt(columnIndex)); break;
            case OracleTypes.DECIMAL     : xbaseObject = new BigDecimal(resultSet.getDouble(columnIndex)); break;
            case OracleTypes.FLOAT       : xbaseObject = new Float(resultSet.getFloat(columnIndex)); break;
            case OracleTypes.DOUBLE      : xbaseObject = new Double(resultSet.getDouble(columnIndex)); break;
            case OracleTypes.TIMESTAMPNS : /* This is actually a TIMESTAMP */
            case OracleTypes.TIMESTAMP   : xbaseObject = resultSet.getTimestamp(columnIndex); break;
            case OracleTypes.DATE        : xbaseObject = resultSet.getDate(columnIndex); break;
            case OracleTypes.NUMERIC  : 
                // If scale == 0 then make it a Long otherwise a Double
                if ( dataScale == 0 )
                    xbaseObject = new Long(resultSet.getLong(columnIndex));
                else
                    xbaseObject = new Double(resultSet.getDouble(columnIndex));
                 break;
            default                      : xbaseObject = resultSet.getObject(columnIndex);
        } // switch case
        return xbaseObject;
    }

}
