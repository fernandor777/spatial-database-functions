package com.spdba.dbutils.sql;

import com.spdba.dbutils.Constants;
import com.spdba.dbutils.spatial.SDO;
import com.spdba.dbutils.tools.LOGGER;

import com.spdba.dbutils.tools.Strings;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;

import java.sql.Statement;

import oracle.jdbc.OracleConnection;
import oracle.jdbc.OracleResultSet;
import oracle.jdbc.pool.OracleDataSource;

public class DBConnection {
    
    private static OracleConnection g_connection;

    public DBConnection() {
        super();
    }
    
    public static void setConnection(OracleConnection _conn) {
        if (_conn != null) {
            g_connection = _conn;
        }
    }

    /**
     * getConnection
     * @return OracleConnection : normally default connection
     * @since            : August 2006, Original Coding
     * @copyright        : Simon Greener, 2006 - 2013
     * @license          : Creative Commons Attribution-Share Alike 2.5 Australia License.
     *                     http://creativecommons.org/licenses/by-sa/2.5/au/
     */
    public static OracleConnection getConnection() 
    throws SQLException {
        if (g_connection == null || g_connection.isClosed()) {
            OracleDataSource ods;
            ods = new OracleDataSource();
            ods.setURL("jdbc:default:connection:");
            g_connection = (OracleConnection)ods.getConnection();
        }
        if (g_connection == null) {
            throw new SQLException("No connection available");
        }
        if (g_connection.isClosed()) {
            throw new SQLException("Connection is closed");
        }
        return g_connection;
    }
    
    public static String getCharacterSet(Connection _conn) 
    throws SQLException,
           IllegalArgumentException
    {
        OracleConnection conn = (OracleConnection)
                                (_conn == null 
                                 ? getConnection()
                                 : _conn );
        String characterSet = "UTF-8";
        Statement stmt = conn.createStatement();
        ResultSet rs = stmt.executeQuery("SELECT value FROM NLS_DATABASE_PARAMETERS WHERE parameter = 'NLS_CHARACTERSET'");
        if ( rs.next() ) {
            characterSet = rs.getString(1);
        }
        rs.close();
        stmt.close();
        return characterSet;
    }

    public static String getSrsNames(Connection _conn,
                                     int        _srid,
                                     String     _separator,
                                     boolean    _insert) 
      throws SQLException
    {
        String sql = "select 'select' as source_object,\n" +
                     "       scrs.srid,\n" +
                     "       'x-ogc:def:'         || case when data_source is null then 'SDO' else UPPER(scrs.data_source) end || ':' || scrs.srid as srsname,\n" + 
                     "       'urn:x-ogc:def:crs:' || case when data_source is null then 'SDO' else UPPER(scrs.data_source) end as srsnamespace\n" +
                     "  from sdo_coord_ref_system scrs\n" +
                     " where scrs.srid = ?\n" +
                     "   and not exists (select 1 from MDSYS.SrsNameSpace_Table snst where snst.sdo_srid = scrs.srid)\n" +
                     "union all\n" +
                     "select 'table' as source_object,\n" +
                     "       snst.sdo_srid,\n" +
                     "       snst.srsname, \n" +
                     "       snst.srsnamespace \n" +
                     "  from MDSYS.SrsNameSpace_Table snst \n" +
                     " where snst.sdo_srid = ?\n" +
                     "   and exists (select 1 from MDSYS.SrsNameSpace_Table snst1 where snst1.sdo_srid = snst.sdo_srid)";
        PreparedStatement ps = _conn.prepareStatement(sql);
        ps.setInt(1,_srid);
        ps.setInt(2,_srid);
        //        LOGGER.info(sql + 
        //            "\n? = " + _srid +
        //            "\n? = " + _srid );
        
        ps.setFetchSize(100); // default is 10
        ps.setFetchDirection(ResultSet.FETCH_FORWARD);
        ResultSet rSet = ps.executeQuery();
        String sep = Strings.isEmpty(_separator) ? "," : _separator;
        String sourceObject = "", srsName = "", srsNamespace = "";
        int sdo_srid = SDO.SRID_NULL;
        if (rSet.next()) {
            sourceObject = rSet.getString(1);
            sdo_srid     = rSet.getInt(2);
            srsName      = rSet.getString(3);
            srsNamespace = rSet.getString(4);
        }
        rSet.close(); rSet = null;
        ps.close(); ps = null;
        
        // Do we need to insert into table?
        if ( _insert ) {
            if ( !Strings.isEmpty(sourceObject) && sourceObject.equalsIgnoreCase("select") ) {
              // SQL
              sql = "insert into MDSYS.SrsNameSpace_Table (sdo_srid,srsname,srsnamespace) values (?,?,?)";
              PreparedStatement insertPS = _conn.prepareStatement(sql);
              insertPS.setInt(1,sdo_srid);
              insertPS.setString(2,srsName);
              insertPS.setString(3,srsNamespace);
              insertPS.execute();
              if ( ! _conn.getAutoCommit() ) {
                  _conn.commit(); 
              }
              insertPS.close(); insertPS = null;
            }
        }
        return srsName + sep + srsNamespace;
    }
    

}
