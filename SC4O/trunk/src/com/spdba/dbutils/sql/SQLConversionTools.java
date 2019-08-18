package com.spdba.dbutils.sql;

import com.spdba.dbutils.Constants;
import com.spdba.dbutils.spatial.Renderer;
import com.spdba.dbutils.spatial.Renderer.GEO_RENDERER_FORMAT;
import com.spdba.dbutils.spatial.SDO;
import com.spdba.dbutils.tools.LOGGER;
import com.spdba.dbutils.tools.Strings;
import com.spdba.dbutils.tools.Tools;

import java.io.IOException;
import java.io.Reader;

import java.math.BigDecimal;

import java.nio.ByteBuffer;
import java.nio.CharBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.Charset;
import java.nio.charset.CharsetDecoder;

import java.sql.Date;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.sql.Time;
import java.sql.Timestamp;
import java.sql.Types;

import java.text.DecimalFormat;
import java.text.SimpleDateFormat;

import java.util.LinkedHashMap;

import javax.sql.RowSetMetaData;

import oracle.jdbc.OracleConnection;
import oracle.jdbc.OracleResultSet;
import oracle.jdbc.OracleResultSetMetaData;
import oracle.jdbc.OracleTypes;

import oracle.sql.ARRAY;
import oracle.sql.BINARY_DOUBLE;
import oracle.sql.BINARY_FLOAT;
import oracle.sql.CHAR;
import oracle.sql.CLOB;
import oracle.sql.DATE;
import oracle.sql.INTERVALDS;
import oracle.sql.INTERVALYM;
import oracle.sql.NCLOB;
import oracle.sql.NUMBER;
import oracle.sql.RAW;
import oracle.sql.ROWID;
import oracle.sql.STRUCT;
import oracle.sql.TIMESTAMP;
import oracle.sql.TIMESTAMPLTZ;
import oracle.sql.TIMESTAMPTZ;

public class SQLConversionTools {

    private static final LOGGER LOGGER = new LOGGER("org.GeoRaptor.sql.SQLConversionTools");
    
    public SQLConversionTools() {
        super();
    }

    public static boolean hasAttributeColumns(OracleResultSet _rSet,
                                              int             _geomColumnIndex) {
        if ( _rSet == null) {
          return false;
        }
        try {
            ResultSetMetaData metaData = _rSet.getMetaData();
            int attributeColumnCount = metaData.getColumnCount();
            if ( _geomColumnIndex > 0 && _geomColumnIndex <= attributeColumnCount ) {
                attributeColumnCount--;
            }
            return attributeColumnCount >= 1;
        } catch (SQLException e) {
        }
        return false;
    }

    public static LinkedHashMap<Integer,RowSetMetaData> getExportMetadata(OracleResultSetMetaData _meta) 
    {
        if ( _meta ==null  )
            return null;
        try {
            LinkedHashMap<Integer,RowSetMetaData> resultMeta = new LinkedHashMap<Integer,RowSetMetaData>(_meta.getColumnCount());
            int geoColumn = -1;
            for (int col = 1; col <= _meta.getColumnCount(); col++) 
            {
                RowSetMetaData rsMD = new OraRowSetMetaDataImpl();
                rsMD.setColumnCount(1);  // Must go first
                rsMD.setCatalogName(1, "");
                if (_meta.getColumnTypeName(col).equals(SDO.TAG_MDSYS_SDO_GEOMETRY) ) 
                {
                    geoColumn = col;
                    rsMD.setCatalogName(1,_meta.getColumnLabel(col));
                }
                rsMD.setColumnName(1, _meta.getColumnLabel(col));
                rsMD.setColumnType(1, _meta.getColumnType(col));
                rsMD.setColumnDisplaySize(1,_meta.getColumnDisplaySize(col));
                rsMD.setColumnTypeName(1, _meta.getColumnTypeName(col));
                rsMD.setPrecision(1,_meta.getPrecision(col)<0?0:_meta.getPrecision(col));  // BLOBs and CLOBs have -1 precision
                rsMD.setScale(1,_meta.getScale(col)<0?0:_meta.getScale(col));              // Scales like -127 exist for binary_float and binary_double but don't contribute to conversion
                resultMeta.put(col,rsMD);
            }
            if ( geoColumn == -1 ) {
                throw new SQLException ("Table does not have an sdo_geometry column.");
            }
            return new LinkedHashMap<Integer,RowSetMetaData>(resultMeta); 
        } catch (SQLException sqle) {
            LOGGER.severe("ExporterWriter.getExportMetadata(): Exception caught when creating export metadata " + sqle.getMessage());
        }
        return null;
    }

    public static String toString(OracleConnection      _conn,
                                  OracleResultSet       _resultSet,
                                  OraRowSetMetaDataImpl _meta,
                                  int                   _col,
                                  GEO_RENDERER_FORMAT   _geomFormat,
                                  String                _sDelimiter,
                                  SimpleDateFormat      _sdf ) 
    {
        String          value = "";
        String     sDelimiter = Strings.isEmpty(_sDelimiter)?"":_sDelimiter;
        Reader             in = null;
        CHAR       CharString = null;
        OracleConnection conn = null;
        
        try {
            // Null parameter checks    
            if ( _conn == null) {
                conn = DBConnection.getConnection();
            } else {
                conn = _conn;
            }
            
            if ( _resultSet == null ) {
                return null;
            }
        
            // Single point to check if value of column is NULL
            //
            Object objValue = _resultSet.getObject(_col);
            if (_resultSet.wasNull()) {
                return null;
            }

//System.out.println("convertToString(conn,obj,col) - " + _meta.getColumnName(1) + "," + _meta.getColumnDisplaySize(1) + "," + _meta.getColumnType(1) + "/" + _meta.getColumnTypeName(1) + ",("+_meta.getPrecision(1)+ "," +_meta.getScale(1) +")");
            
          int scale = _meta.getScale(1);
          DecimalFormat df = Tools.getDecimalFormatter(scale==0 ? -1 : scale);

          switch ( _meta.getColumnType(1)) {
              case OracleTypes.BFILE      : break;
              case OracleTypes.ROWID      : value = _resultSet.getROWID(_col).stringValue(); break;
              
              // CHAR values retain the same same representation as they have in the database, so there can be no loss of information through conversion. 
          
              case Types.NCHAR          : 
              case Types.NVARCHAR       : value = sDelimiter + _resultSet.getNString(_col) + sDelimiter; 
                                          break;
              case OracleTypes.CHAR     : 
              case OracleTypes.VARCHAR  : CharString = _resultSet.getCHAR(_col);
                                          value = sDelimiter + CharString.stringValue() + sDelimiter;
                                          break;
              
              case OracleTypes.BOOLEAN  : value = _resultSet.getObject(_col).toString(); break; 
          
              case OracleTypes.RAW      :
                 RAW rawval = ((OracleResultSet)_resultSet).getRAW(_col);
                 value = sDelimiter + rawval.stringValue() + sDelimiter;
              break;
              case OracleTypes.BLOB     : break;
              case OracleTypes.NCLOB    :
                 NCLOB nClob = (NCLOB)_resultSet.getObject(_col);
                 in = nClob.getCharacterStream(  );
                 try {
                    value = "";
                    int length = -1;
                    char[] buffer = new char[1024];
                    while ((length = in.read(buffer)) != -1) {
                        value += String.valueOf(buffer).substring(0,length);
                    }
                    in.close( ); 
                    in = null; 
                    value = (nClob.length()<=1000?value:value.substring(0,1000)) + " ... ";
                 } catch (IOException e) {
                    value = null;
                 }
                 break;
                case OracleTypes.CLOB  :
                  CLOB sClob = _resultSet.getCLOB(_col);
                  in = sClob.getCharacterStream();
                  try {
                      value = "";
                      int length = -1;
                      char[] buffer = new char[1024];
                      while ((length = in.read(buffer)) != -1) {
                          value += String.valueOf(buffer).substring(0,length);
                      }
                      in.close( ); 
                      in = null; 
                      value= (sClob.length()<=1000?value:value.substring(0,1000)) + " ... ";
                   } catch (IOException e) {
                      value = null;
                   }
                   value = sDelimiter + value + sDelimiter;
                   break;
          
            case OracleTypes.TINYINT       : /* Integer data from 0 through 255. Storage size is 1 byte. */
            case OracleTypes.SMALLINT      : /* Integer data from -2^15 (-32,768) through 2^15 - 1 (32,767). Storage size is 2 bytes. */
            case OracleTypes.BIGINT        : /* Integer (whole number) data from -2^63 (-9,223,372,036,854,775,808) through 2^63-1 (9,223,372,036,854,775,807). Storage size is 8 bytes. */
            case OracleTypes.INTEGER       : /* Integer (whole number) data from -2^31 (-2,147,483,648) through 2^31 - 1 (2,147,483,647). Storage size is 4 bytes. The SQL-92 synonym for int is integer. */
            case OracleTypes.FLOAT         : 
            case OracleTypes.DOUBLE        : 
            case OracleTypes.DECIMAL       : 
            case OracleTypes.NUMBER        : value = _resultSet.getNUMBER(_col).stringValue();  break;
    
            case OracleTypes.BINARY_DOUBLE : BINARY_DOUBLE bdbl = new BINARY_DOUBLE(_resultSet.getOracleObject(_col).getBytes()); 
                                             value = df.format(new Double(bdbl.stringValue()));
                                             break;
            case OracleTypes.BINARY_FLOAT  : BINARY_FLOAT  bflt = (BINARY_FLOAT)_resultSet.getOracleObject(_col);  
                                             value = df.format(new Float(bflt.stringValue())); 
                                             break; 
            case OracleTypes.TIMESTAMPTZ   : value = _resultSet.getTIMESTAMPTZ(_col).stringValue(conn);   break;
            case OracleTypes.TIMESTAMPLTZ  : value = _resultSet.getTIMESTAMPLTZ(_col).stringValue(conn);  break;
            case OracleTypes.INTERVALYM    : value = _resultSet.getINTERVALYM(_col).stringValue();        break;
            case OracleTypes.INTERVALDS    : value = _resultSet.getINTERVALDS(_col).stringValue();        break;
            case OracleTypes.DATE          : value = _sdf.format(_resultSet.getDate(_col));               break;
            case Types.TIME                : value = _resultSet.getTime(_col).toString();                 break;
            case OracleTypes.TIMESTAMP     :
              if ( _meta.getColumnTypeName(1).equalsIgnoreCase("DATE") ) {
                DATE d = _resultSet.getDATE(_col); 
                try {
                    value = d.stringValue();
                } catch (Exception e) {
                    value = d.stringValue();
                }
              } else {
                  value = _resultSet.getTIMESTAMP(_col).stringValue();
              }
              break;
            
            case OracleTypes.STRUCT : 
              
              if ( _meta.getColumnTypeName(1).equalsIgnoreCase(SDO.TAG_MDSYS_SDO_GEOMETRY) ||
                   _meta.getColumnTypeName(1).equalsIgnoreCase(SDO.TAG_MDSYS_ST_GEOMETRY) ||
                   _meta.getColumnTypeName(1).equalsIgnoreCase(SDO.TAG_MDSYS_SDO_POINT_TYPE) ||
                   _meta.getColumnTypeName(1).equalsIgnoreCase(SDO.TAG_MDSYS_VERTEX_TYPE) ) {
                  STRUCT stGeom = (STRUCT) _resultSet.getObject(_col);
                  value = sDelimiter 
                          + 
                          Renderer.renderSdoGeometry(stGeom,_geomFormat)
                          + 
                          sDelimiter;
              }
              break;
            
            default : LOGGER.warn("Not handled: " + 
                                  _meta.getColumnName(1) + "," + 
                                  _meta.getColumnType(1) + "," +
                                  _meta.getColumnTypeName(1) + "," + 
                                  _meta.getPrecision(1) + "," + 
                                  _meta.getScale(1));
                      value = null;
          }
      } catch (Exception e) {
          value = null;
      }
      return value;
  }
    
    /* Deprecated */
    public static String toString(OracleResultSetMetaData metaData,
                                  OracleResultSet         _resultSet,
                                  int                     i,
                                  GEO_RENDERER_FORMAT     _geomFormat,
                                  String                  _sDelimiter,
                                  SimpleDateFormat        _sdf,
                                  int                     _NOTOBEUSED) 
    throws SQLException, 
           IOException 
    {
        String   outValue = "";
        String sDelimiter = Strings.isEmpty(_sDelimiter)?"":_sDelimiter;

        switch (metaData.getColumnType(i))
        {
            case OracleTypes.STRUCT :
                // Must be SDO_GEOMETRY as the isSupportedType only allows SDO_GEOMETRY STRUCTs
                // Convert geometry object
                STRUCT stGeom = (STRUCT) _resultSet.getObject(i);
                outValue = Renderer.renderSdoGeometry(stGeom,_geomFormat);
                break;
             case OracleTypes.NCLOB    :
                NCLOB nClob = (NCLOB)_resultSet.getObject(i);
                if (!_resultSet.wasNull()) {
                    Reader  in = nClob.getCharacterStream(  );
                    outValue = sDelimiter;
                    int length = -1;
                    char[] buffer = new char[1024];
                    try {
                       while ((length = in.read(buffer)) != -1) {
                           outValue += String.valueOf(buffer).substring(0,length);
                       }
                       in.close( ); 
                       in = null; 
                       outValue = (nClob.length()<=1000?outValue:outValue.substring(0,1000)) + " ... ";
                    } catch (IOException e) {
                    }
                    outValue += sDelimiter;
                } else {
                    outValue = "NULL";
                }
                break;
            case OracleTypes.CLOB:
                outValue = sDelimiter;
                CLOB clobVal = ((OracleResultSet)_resultSet).getCLOB(i);
                if (!_resultSet.wasNull()) {
                    Reader  in = clobVal.getCharacterStream(  ); 
                    int length = (int)clobVal.length(); 
                    char[] buffer = new char[1024];
                    try {
                        while ((length = in.read(buffer)) != -1) {
                            outValue += String.valueOf(buffer).substring(0, length);
                        }
                        in.close(); 
                    } catch (IOException e) {
                    }
                    in = null; 
                    outValue += sDelimiter;
                } else {
                    outValue = "NULL";
                }
            break;
            case -3:
            case OracleTypes.RAW:
                RAW rawval = ((OracleResultSet)_resultSet).getRAW(i);
                outValue = sDelimiter + rawval.stringValue() + sDelimiter;
                break;
            case OracleTypes.ROWID:
                // Obtain the ROWID as a ROWID objects(which is an Oracle Extension
                // datatype. Since ROWID is an Oracle extension, the getROWID method
                // is not available in the ResultSet class. Hence ResultSet has to be
                // cast to OracleResultSet
                ROWID rowid = ((OracleResultSet)_resultSet).getROWID(i);
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
                outValue = rowidChars.toString();
                break;
            case OracleTypes.CHAR :
                  outValue = String.valueOf(_resultSet.getByte(i));
                  break;
            case OracleTypes.VARCHAR :
                  outValue = sDelimiter + _resultSet.getString(i) + sDelimiter;
                  break;
            case OracleTypes.TIME :
                 outValue = _resultSet.getTime(i).toString();
                 break;
            case OracleTypes.SMALLINT :
                 outValue = String.valueOf(_resultSet.getShort(i));
                 break;
            case OracleTypes.INTEGER :
                 outValue = String.valueOf(_resultSet.getInt(i));
                 break;
            case OracleTypes.NUMERIC :
                // If scale == 0 then make it a Long otherwise a Double
                // After all, we are just writing the data to a text file!
                if ( metaData.getScale(i) == 0 )
                    outValue = String.valueOf(_resultSet.getLong(i));
                else
                    outValue = String.valueOf(_resultSet.getDouble(i));
                 break;
            case OracleTypes.FLOAT :
                 outValue = String.valueOf(_resultSet.getFloat(i));
                 break;
            case OracleTypes.DOUBLE :
                 outValue = String.valueOf(_resultSet.getDouble(i));
                 break;
            case OracleTypes.LONGVARCHAR :
                 outValue = String.valueOf(_resultSet.getLong(i));
                 break;
             case -100: /* This is actually a TIMESTAMP */
             case OracleTypes.TIMESTAMP :
                 outValue = sDelimiter + _sdf.format(_resultSet.getTimestamp(i)) + sDelimiter;
                 break;
             case OracleTypes.DATE:
                 outValue = sDelimiter + _sdf.format(_resultSet.getDate(i)) + sDelimiter;
                 break;
             default: outValue = _resultSet.getObject(i).toString();
         } // switch case
         return outValue;
    }

  public static String toString(OracleConnection             _conn,
                                Object                       _object,
                                OraRowSetMetaDataImpl        _meta,
                                Renderer.GEO_RENDERER_FORMAT _geomFormat )
  {
      // Check parameters and load constantly accessed metadata elements to variables.
      String columnName        = "";
      String columnTypeName    = "";
      int    columnType        = -1;
      int    dataTypePrecision = 0;
      int    dataTypeScale     = 0;
      try {
          columnTypeName    = _meta.getColumnTypeName(1);
          columnType        = _meta.getColumnType(1);
          if ( _object == null ) {
              return Constants.NULL;
          }
          dataTypeScale     = _meta.getScale(1);
          columnName        = _meta.getColumnName(1);
          dataTypePrecision = _meta.getPrecision(1);
      } catch (SQLException sqle) {
          LOGGER.error("convertToString: Failed to access metadata needed to convert column " + columnName + " (" + sqle.getMessage());
          return "";
      }

     // System.out.println("SQLConversionTools.toString()(conn,obj,col) - " + _meta.getColumnName(1) + "," +_meta.getColumnDisplaySize(1) + "," + _meta.getColumnType(1) + "/" +_meta.getColumnTypeName(1) + ",(" + _meta.getPrecision(1) + "," + _meta.getScale(1) +")");

      try {
          // Rough mapping as only having access to actual data will help determine correct value
          // ie 255 will be TINYINT but 999 would not be
          //
          DecimalFormat df = Tools.getDecimalFormatter(dataTypeScale==0?-1:dataTypeScale);
          Reader in = null;
          OracleConnection conn = (_conn == null) ? DBConnection.getConnection()  : _conn;
          switch (columnType) 
          {
            case OracleTypes.ROWID   : return ((ROWID)_object).stringValue(); 
            case OracleTypes.BOOLEAN : return ((Boolean)_object).toString();
            case OracleTypes.BFILE   :
            case OracleTypes.RAW     : return "";
            case OracleTypes.BLOB    : return "";
            case OracleTypes.NCLOB   : 
            try {
                in = ((NCLOB)_object).getCharacterStream(  );
                String nClob = "";
                int length = (int)((NCLOB)_object).length();
                char[] buffer = new char[1024];
                while ((length = in.read(buffer)) != -1) {
                    nClob += String.valueOf(buffer).substring(0,length);
                }
                in.close( ); 
                in = null; 
                return (nClob.length()<=1000?nClob:nClob.substring(0,1000)) + " ... ";
             } catch (IOException e) {
                return "";
             }
            case OracleTypes.CLOB  : in = ((CLOB)_object).getCharacterStream(  );
              try {
                  String sClob = "";
                  int length = (int)((CLOB)_object).length();
                  char[] buffer = new char[1024];
                  while ((length = in.read(buffer)) != -1) {
                      sClob += String.valueOf(buffer).substring(0,length);
                  }
                  in.close( ); 
                  in = null; 
                  return (sClob.length()<=1000?sClob:sClob.substring(0,1000)) + " ... ";
               } catch (IOException e) {
                  return "";
               }
            case OracleTypes.NCHAR    : 
            case OracleTypes.CHAR     : 
            case OracleTypes.NVARCHAR : 
            case OracleTypes.VARCHAR  :
              // Try CHAR based conversion first
              String retStr = "";
              try { 
                  retStr = ((CHAR)_object).getString();
              } catch ( Exception e ) {
                  retStr = (String)_object; 
              }
              return retStr;
            case OracleTypes.TINYINT  : /* Integer data from 0 through 255. Storage size is 1 byte. */
            case OracleTypes.SMALLINT : /* Integer data from -2^15 (-32,768) through 2^15 - 1 (32,767). Storage size is 2 bytes. */
            case OracleTypes.BIGINT   : /* Integer (whole number) data from -2^63 (-9,223,372,036,854,775,808) through 2^63-1 (9,223,372,036,854,775,807). Storage size is 8 bytes. */
            case OracleTypes.INTEGER  : /* Integer (whole number) data from -2^31 (-2,147,483,648) through 2^31 - 1 (2,147,483,647). Storage size is 4 bytes. The SQL-92 synonym for int is integer. */
            case OracleTypes.FLOAT    : 
            case OracleTypes.DOUBLE   : 
            case OracleTypes.DECIMAL  : 
            case OracleTypes.NUMBER   :
              if ( _object instanceof java.math.BigDecimal ) {
                  return df.format(_object);
              }
              NUMBER num = (NUMBER)_object;
              if ( dataTypeScale == 0 ) {
                  if (dataTypePrecision == 0)  { Long    l = new Long(Long.MIN_VALUE);       if ( num.isConvertibleTo(l.getClass()) ) return String.valueOf(num.longValue()); }
                  if (dataTypePrecision <= 3 ) { Byte    b = new Byte(Byte.MIN_VALUE);       if ( num.isConvertibleTo(b.getClass()) ) return String.valueOf(num.byteValue()); } 
                  if (dataTypePrecision <= 5 ) { Short   s = new Short(Short.MIN_VALUE);     if ( num.isConvertibleTo(s.getClass()) ) return String.valueOf(num.shortValue()); } 
                  if (dataTypePrecision <= 9 ) { Integer i = new Integer(Integer.MIN_VALUE); if ( num.isConvertibleTo(i.getClass()) ) return String.valueOf(num.intValue()); }
                                                 Long    l = new Long(Long.MIN_VALUE);       if ( num.isConvertibleTo(l.getClass()) ) return String.valueOf(num.longValue());
              }
              if ( dataTypePrecision <= 63  ) { Float  f = new Float(Float.NaN);             if ( num.isConvertibleTo(f.getClass()) ) return String.valueOf(df.format(num.floatValue())); }
              if ( dataTypePrecision == 126 ) { Double d = new Double(Double.NaN);           if ( num.isConvertibleTo(d.getClass()) ) return String.valueOf(df.format(num.doubleValue())); }
                                            BigDecimal m = new BigDecimal(Double.NaN);       if ( num.isConvertibleTo(m.getClass()) ) return String.valueOf(df.format(num.bigDecimalValue()));
              return num.stringValue();
            case OracleTypes.BINARY_DOUBLE : BINARY_DOUBLE bdbl = (BINARY_DOUBLE)_object; return df.format(new Double(bdbl.stringValue()));
            case OracleTypes.BINARY_FLOAT  : BINARY_FLOAT  bflt =  (BINARY_FLOAT)_object; return df.format(new Float(bflt.stringValue())); 
            case OracleTypes.TIMESTAMPTZ   : return((TIMESTAMPTZ)_object).stringValue(conn);
            case OracleTypes.TIMESTAMPLTZ  : return((TIMESTAMPLTZ)_object).stringValue(conn);
            case OracleTypes.INTERVALYM    : return((INTERVALYM)_object).stringValue();  
            case OracleTypes.INTERVALDS    : return((INTERVALDS)_object).stringValue();
            case OracleTypes.TIME          :
            case OracleTypes.TIMESTAMP     :
            case OracleTypes.DATE          :
              if ( columnTypeName.equalsIgnoreCase("DATE") ) {
               java.util.Date date = (java.util.Date)_object;
               return date!=null 
                      ? date.toString() : SQLConversionTools.getDefaultNullValue(OracleTypes.DATE);
                }
                TIMESTAMP ts = (TIMESTAMP) _object;
                Timestamp ti = new Timestamp(1000000); if ( ts.isConvertibleTo(ti.getClass()) ) { return String.valueOf(ts.timestampValue().toString()); }
                Date dt = new Date(20100130);          if ( ts.isConvertibleTo(dt.getClass()) ) { return String.valueOf(ts.dateValue().toString()); }
                Time tm = new Time(1500);              if ( ts.isConvertibleTo(tm.getClass()) ) { return String.valueOf(ts.timeValue().toString()); }
                return (String)_object;
          
            case OracleTypes.STRUCT : 
              
              if ( _meta.getColumnTypeName(1).equalsIgnoreCase(SDO.TAG_MDSYS_SDO_GEOMETRY) ||
                   _meta.getColumnTypeName(1).equalsIgnoreCase(SDO.TAG_MDSYS_ST_GEOMETRY) ||
                   _meta.getColumnTypeName(1).equalsIgnoreCase(SDO.TAG_MDSYS_SDO_POINT_TYPE) ||
                   _meta.getColumnTypeName(1).equalsIgnoreCase(SDO.TAG_MDSYS_VERTEX_TYPE) ) {
                  STRUCT stGeom = (STRUCT) _object;
                  return Renderer.renderSdoGeometry(stGeom,_geomFormat);
              }
              break;
          
            default : 
              LOGGER.warn("SQLConversionTools.toString() did not handle " + columnName +"," + columnTypeName +","+dataTypePrecision+ "," +dataTypeScale);
              return null;
          }
       } catch (SQLException e) {
           LOGGER.warn("SQLConversionTools.toString(): Error converting column value " + columnName +"," + columnTypeName +","+dataTypePrecision+ "," +dataTypeScale + " (" + e.getMessage() + ")");
           return null;
       }
      return null;
    }

    public static boolean isSpatialTypeSupported(Object _value) {
        try {
            if ( _value instanceof oracle.sql.STRUCT ) {
                STRUCT stValue = (STRUCT)_value;
                return ( stValue.getSQLTypeName().indexOf("MDSYS.ST_")==0 ||
                         stValue.getSQLTypeName().equalsIgnoreCase(SDO.TAG_MDSYS_SDO_GEOMETRY) ||
                         stValue.getSQLTypeName().equalsIgnoreCase(SDO.TAG_MDSYS_VERTEX_TYPE) ||
                         stValue.getSQLTypeName().equalsIgnoreCase(SDO.TAG_MDSYS_SDO_POINT_TYPE) );
            } else if (_value instanceof oracle.sql.ARRAY) {
                ARRAY aryValue = (ARRAY)_value;
                return ( aryValue.getSQLTypeName().equals(SDO.TAG_MDSYS_SDO_DIMARRAY) ||
                         aryValue.getSQLTypeName().equals(SDO.TAG_MDSYS_SDO_ELEM_ARRAY) ||
                         aryValue.getSQLTypeName().equals(SDO.TAG_MDSYS_SDO_ORD_ARRAY));
            }
        } catch (SQLException sqle) {
          return false;
        }
        return false;
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
                    columnType == OracleTypes.NCHAR ||  
                    columnType == OracleTypes.NCLOB ||
                    columnType == OracleTypes.NVARCHAR ||  
                    columnType == OracleTypes.RAW ||
                    columnType == OracleTypes.CHAR      || 
                    columnType == OracleTypes.CLOB    || 
                    columnType == OracleTypes.VARCHAR || 
                    columnType == OracleTypes.LONGVARCHAR ||
                    columnType == OracleTypes.SMALLINT  || 
                    columnType == OracleTypes.TINYINT ||
                    columnType == OracleTypes.INTEGER   || 
                    columnType == OracleTypes.BIGINT ||  
                    columnType == OracleTypes.NUMERIC ||
                    columnType == OracleTypes.FLOAT     || 
                    columnType == OracleTypes.BINARY_DOUBLE ||
                    columnType == OracleTypes.BINARY_FLOAT ||
                    columnType == OracleTypes.DOUBLE    || 
                    columnType == OracleTypes.DATE      || 
                    columnType == OracleTypes.TIME      ||
                    columnType == OracleTypes.INTERVALDS || 
                    columnType == OracleTypes.INTERVALYM ||
                    columnType == OracleTypes.TIMESTAMPNS ||
                    columnType == OracleTypes.TIMESTAMP || 
                    columnType == OracleTypes.TIMESTAMPLTZ ||  
                    columnType == OracleTypes.TIMESTAMPTZ ||
                (   columnType == OracleTypes.STRUCT &&
                    columnTypeName.equalsIgnoreCase(SDO.TAG_MDSYS_SDO_GEOMETRY) ||
                    columnTypeName.equalsIgnoreCase(SDO.TAG_MDSYS_SDO_POINT_TYPE) ||
                    columnTypeName.equalsIgnoreCase(SDO.TAG_MDSYS_VERTEX_TYPE) )
                );
    }

    public static String getDefaultNullValue(int _type) 
    {
        switch (_type)
        {
           case OracleTypes.ROWID         : return "";
           case OracleTypes.NCHAR         : 
           case OracleTypes.NVARCHAR      : 
           case OracleTypes.CHAR          : 
           case OracleTypes.VARCHAR       : return "";
           case OracleTypes.NCLOB         :
           case OracleTypes.CLOB          : return "";
           case OracleTypes.TINYINT       : return "0";
           case OracleTypes.SMALLINT      : return "-32768";
           case OracleTypes.BIGINT        : return "-9223372036854775808";
           case OracleTypes.INTEGER       : return "-2147483648";
           case OracleTypes.FLOAT         :
           case OracleTypes.DOUBLE        :
           case OracleTypes.DECIMAL       :
           case OracleTypes.NUMBER        :
           case OracleTypes.BINARY_DOUBLE : return "-9999999999";
           case OracleTypes.TIMESTAMPTZ   : 
           case OracleTypes.TIMESTAMPLTZ  : 
           case OracleTypes.INTERVALYM    : 
           case OracleTypes.INTERVALDS    : 
           case OracleTypes.DATE          : return "1900-01-01";
           case OracleTypes.TIMESTAMP     :
           case OracleTypes.TIME          : return "120000";
           case OracleTypes.BFILE         : 
           case OracleTypes.RAW           :
           case OracleTypes.BLOB          : 
           case OracleTypes.STRUCT        :
           default                        : return "";
        }
    }

    public static boolean isString(int columnType) {
        boolean isString = false;
        isString = columnType == Types.CHAR ||
                   columnType == Types.CLOB ||
                   columnType == Types.VARCHAR;
        return isString;
    }

    /**
     * string2clob
     * Converts a string to an Oracle CLOB
     * @param _str - The string to be converted to a CLOB
     * @return CLOB containing _str
     * @author Simon Greener, April 20th 2010, Original coding
     */
    public static CLOB string2Clob(String _str) 
    throws SQLException
    {
        if ( _str==null || _str.length()==0 ) {
            return null;
        }
        oracle.sql.CLOB clob = CLOB.createTemporary(DBConnection.getConnection(), 
                                                    true, 
                                                    CLOB.DURATION_SESSION);
        char[] chrs = new char[_str.length()];
        _str.getChars(0,_str.length(),chrs,0);
        clob.putChars((long)1,chrs);
        return clob;
    }

    /**
     * clob2string
     * Converts an Oracle CLOB to a string
     * @param _clob - CLOB whose contents will be written to a Java String.
     * @return String containing contents of CLOB 
     * @author Simon Greener, April 20th 2010, Original coding
     */
    public static String clob2string(CLOB _clob) 
    throws SQLException
    {
        if ( _clob==null || _clob.length()==0 ) {
            return null;
        }
        // Convert CLOB to String
        String wkt = "";
        Reader  in = null;
        int length = 0; 

        try {
            if ( _clob.isNCLOB() ) {
               in = ((NCLOB)_clob).getCharacterStream(  );
               length = (int)((NCLOB)_clob).length();
            } else {
                in = ((CLOB)_clob).getCharacterStream(  );
                length = (int)((CLOB)_clob).length();
            }
            char[] buffer = new char[1024];
            while ((length = in.read(buffer)) != -1) {
                wkt += String.valueOf(buffer).substring(0,length);
            }
        } catch (IOException e) {
            System.err.println("Error converting CLOB to string: " + e.getMessage());
        }
        try {in.close( ); } catch (IOException e) {}
        in = null; 
        return wkt;
    }

    public static String dataTypeToXSD(OracleResultSetMetaData _meta,
                                       int                     _column) 
    throws SQLException 
    {
        // Rough mapping as only having access to actual data will help determine correct value
        // ie 255 will be TINYINT but 999 would not be
        //
        switch (_meta.getColumnType(_column)) 
        {
          case Types.ROWID       : return "string"; 
          case Types.BOOLEAN     : return "boolean";
          case OracleTypes.BFILE :
          case OracleTypes.RAW   :
          case Types.BLOB        : return "base64Binary";

          case Types.CLOB     : return "clob";  // for handling of length
          case Types.CHAR     : 
          case Types.NCHAR    :
          case Types.NCLOB    :
          case Types.NVARCHAR :
          case Types.VARCHAR  : return "string"; 
          
          case Types.TINYINT  : return "byte";
              /* Integer data from 0 through 255. Storage size is 1 byte. */
          case Types.SMALLINT : return "short";
              /* Integer data from -2^15 (-32,768) through 2^15 - 1 (32,767). Storage size is 2 bytes. */
          case Types.INTEGER  : return "int"; 
              /* Integer (whole number) data from -2^31 (-2,147,483,648) through 2^31 - 1 (2,147,483,647). Storage size is 4 bytes. The SQL-92 synonym for int is integer. */
          case Types.BIGINT   : return "long"; // or Decimal?
              /* Integer (whole number) data from -2^63 (-9,223,372,036,854,775,808) through 2^63-1 (9,223,372,036,854,775,807). Storage size is 8 bytes. */
        
          case Types.FLOAT    : return "float";
          case Types.DOUBLE   : return "double";
        
          case OracleTypes.BINARY_FLOAT  : return "float";   // 32bit binary number
          case OracleTypes.BINARY_DOUBLE : return "double";  // 64 bit binary float
                                            
        
          case Types.DECIMAL : 
          case OracleTypes.NUMBER :
              if ( _meta.getScale(_column) == 0 ) {
                       if ( _meta.getPrecision(_column) < 3 )  return "byte";
                  else if ( _meta.getPrecision(_column) < 5 )  return "short";
                  else if ( _meta.getPrecision(_column) < 10 ) return "long";
                  else                                         return "integer";
              } else {
                       if ( _meta.getPrecision(_column) == 63  ) return "float";
                  else if ( _meta.getPrecision(_column) == 126 ) return "double";
                  else return "decimal"; 
              }

          case Types.DATE               : return "date"; 
          case Types.TIME               : return "time"; 
          case Types.TIMESTAMP          : if ( _meta.getScale(_column) != 0 ) return "dateTime"; else return "date";
          case OracleTypes.TIMESTAMPLTZ : return "string";
          case OracleTypes.TIMESTAMPTZ  : return "dateTime";
          case OracleTypes.INTERVALDS   : return "string"; // could be "duration" 
          case OracleTypes.INTERVALYM   : return "string";  
        
          case OracleTypes.STRUCT : 
            if ( _meta.getColumnTypeName(_column).equalsIgnoreCase(SDO.TAG_MDSYS_SDO_GEOMETRY) ||
                 _meta.getColumnTypeName(_column).equalsIgnoreCase(SDO.TAG_MDSYS_ST_GEOMETRY) ||
                 _meta.getColumnTypeName(_column).equalsIgnoreCase(SDO.TAG_MDSYS_SDO_POINT_TYPE) ||
                 _meta.getColumnTypeName(_column).equalsIgnoreCase(SDO.TAG_MDSYS_VERTEX_TYPE) ) {
                return "string";
            }
            break;

          default : LOGGER.warn("(Tools.dataTypeToXSD) Data Type Not Handled For Column: " + _meta.getColumnClassName(_column));
                    return "string";
        }
        return "string";
    }

    /** 
    * Finds first sdo_geometry column in resultset metadata
    * @param metaData
    **/
    public static int firstSdoGeometryColumn(ResultSetMetaData metaData)
    throws SQLException 
    {
        int position = -1;
        try {
            for (int i = 1; i <= metaData.getColumnCount(); i++) {
                if ( metaData.getColumnType(i) == OracleTypes.STRUCT &&
                     metaData.getColumnTypeName(i).equalsIgnoreCase(SDO.TAG_MDSYS_SDO_GEOMETRY) ) 
                    return i;
            }
        }
        catch (SQLException sqle) {
            throw new SQLException("Error executing SQL: " + sqle);
        }
        return position;
    }
    
    
}
