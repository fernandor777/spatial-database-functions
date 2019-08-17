DEFINE INSTALL_SCHEMA='&1'

SET VERIFY OFF;
SET SERVEROUTPUT ON;
-- Always aim for a clean compile
ALTER SESSION SET PLSQL_WARNINGS='ERROR:ALL';
-- Enable optimizations
ALTER SESSION SET plsql_optimize_level=2;

CREATE OR REPLACE PACKAGE BODY &&INSTALL_SCHEMA..TOOLS
AS

  Function ST_DB_Version
  Return number
  IS
  Begin
    Return TO_NUMBER(DBMS_DB_VERSION.VERSION || '.' || DBMS_DB_VERSION.RELEASE);
  end ST_DB_Version;

  Function ST_isLocator
    Return Integer
  AS
    v_test_length number;
  BEGIN
    -- DEBUG dbms_output.put_line('TOOLS.ST_isLocator: Test to see if we are running in Enterprise Edition Spatial or Locator');
    v_test_length := mdsys.sdo_geom.sdo_length(
                        mdsys.sdo_geometry(3002,NULL,NULL,
                                           mdsys.sdo_elem_info_array(1,2,1),
                                           mdsys.sdo_ordinate_array(0,0,0,1,1,1)),
                        0.005);
    -- DEBUG dbms_output.put_line('TOOLS.ST_IsLocator.ST_LENGTH: v_test_len = ' || nvl(v_test_len,-9999));
    RETURN case when v_test_length is null 
                then 1
                when ROUND(v_test_length,5) = 1.41421
                then 1
                else 0
            end;
  END ST_isLocator;

  Function Tokenizer(p_string     In clob,
                     p_separators In VarChar2 DEFAULT ' ')
    Return &&INSTALL_SCHEMA..T_Tokens Pipelined
  As
  Begin
    if ( p_string is null
         or
         p_separators is null ) then
       return;
    end if;
    For rec in (
      With myCTE As (
         Select c.beg, c.sep, Row_Number() Over(Order By c.beg Asc) rid
           From (Select b.beg,  CAST(c.sep as varchar2(10)) as sep
                   From (Select CAST(Level as Integer) beg
                           From dual
                          Connect By Level <= length(p_string)
                        ) b,
                        (Select SubStr(p_separators,level,1) as sep
                          From dual
                          Connect By Level <= length(p_separators)
                        ) c
                  Where INSTR(c.sep,
                              dbms_lob.substr( p_string, 
                                               1,
                                               b.beg)    /* SUBSTR(p_string,b.beg,1) */
                              ) >0
                 Union All /* From start to first separator */
                 Select                  0 as beg, cast(null as varchar2(10)) as sep From dual
                 Union All /* From last separator to end */
                 Select length(p_string)+1 as beg, cast(null as varchar2(10)) as sep From dual
               ) c
      )
      Select &&INSTALL_SCHEMA..T_Token(
                Row_Number() Over (Order By a.rid ASC),
                Case When Length(a.token) = 0 Then NULL Else a.token End,
                a.sep
             ) as token
        From (Select d.rid,
                     SubStr(p_string,
                            (d.beg + 1),
                            (Lead(d.beg,1) Over (Order By d.rid Asc) - d.beg - 1) ) as token,
                     Lead(d.sep,1) Over (Order By d.rid asc) as sep
                From MyCTE d
             ) a
       Where Length(a.token) <> 0
          or Length(a.sep)   <> 0
    )
    LOOP
       PIPE ROW(rec.token);
    END LOOP;
    RETURN;
  End Tokenizer;

  Function Tokenizer(p_string     In VarChar2,
                     p_separators In VarChar2 DEFAULT ' ')
    Return &&INSTALL_SCHEMA..T_Tokens Pipelined
  As
  Begin
    For rec in (
      Select &&INSTALL_SCHEMA..T_Token(
               t.id,
               t.token,
               t.separator
             ) as token
        From TABLE(&&INSTALL_SCHEMA..TOOLS.Tokenizer(
                      p_string     => TO_CLOB(p_string),
                      p_separators => p_separators )) t )
    Loop
      PIPE ROW (rec.token);
    End Loop;
  End Tokenizer;

  Function TokenAggregator(p_tokenSet  IN  &&INSTALL_SCHEMA..T_Tokens,
                           p_delimiter IN  VARCHAR2 DEFAULT ',')
    Return VarChar2
  Is
    l_string    varchar2(32767);
    v_separator varchar2(10) := SUBSTR(NVL(p_delimiter,','),1,1);
  Begin
    IF ( p_tokenSet is null ) THEN
      Return NULL;
    END IF;
    FOR i IN p_tokenSet.FIRST .. p_tokenSet.LAST LOOP
      l_string := l_string || p_tokenSet(i).token || NVL(p_tokenSet(i).separator,v_separator);
    END LOOP;
    Return l_string;
  End TokenAggregator;

  Function Generate_Series(p_start in pls_integer,
                           p_end   in pls_integer,
                           p_step  in pls_integer default 1)
    Return &&INSTALL_SCHEMA..T_IntValues Pipelined
  As
    v_i pls_integer := p_start;
  Begin
    while ( v_i <= p_end) Loop
      PIPE ROW ( &&INSTALL_SCHEMA..T_IntValue(v_i) );
      v_i := v_i + p_step;
    End Loop;
    Return;
  End Generate_Series;

  Function ST_GetSridType(p_srid In integer)
    Return varchar2
  As
    c_i_invalid_srid CONSTANT INTEGER       := -20120;
    c_s_invalid_srid CONSTANT VARCHAR2(100) := 'p_srid (*SRID*) must exist in mdsys.cs_srs';
    v_srid_type      varchar2(25);
  Begin
    IF (p_srid is null) Then
      RETURN 'PLANAR';
    End If;
    BEGIN
      SELECT SUBSTR(
               DECODE(crs.coord_ref_sys_kind,
                 'GEOCENTRIC',  'GEOGRAPHIC',
                 'GEOGENTRIC',  'GEOGRAPHIC',  /* <- Spelling error geoGentric */
                 'GEOGRAPHIC2D','GEOGRAPHIC',
                 'GEOGRAPHIC3D','GEOGRAPHIC',
                 'VERTICAL',    'GEOGRAPHIC',
                 'COMPOUND',    'PLANAR',
                 'ENGINEERING', 'PLANAR',
                 'PROJECTED' ,  'PLANAR',
                 'PLANAR'),1,20) as unit_of_measure
        INTO v_srid_type
        FROM mdsys.sdo_coord_ref_system crs
       WHERE crs.srid = p_srid;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          raise_application_error(c_i_invalid_srid,
                                  REPLACE(c_s_invalid_srid,'*SRID*',p_srid));
    END;
    RETURN v_srid_type;
  END ST_GetSridType;

END TOOLS;
/
show errors

Prompt Check package has compiled correctly ...
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
   v_OK       boolean      := FALSE;
   v_obj_name varchar2(30) := 'TOOLS';
BEGIN
   FOR rec IN (select object_name || '.' || object_Type as package_name, status
                 from user_objects
                where object_name = v_obj_name
                  and object_type = 'PACKAGE BODY'
              ) 
   LOOP
      IF ( rec.status = 'VALID' ) Then
         dbms_output.put_line(USER || '.' || rec.package_name || ' is valid.');
         v_ok := TRUE;
      ELSE
         dbms_output.put_line(USER || '.' || rec.package_name || ' is invalid.');
      END IF;
   END LOOP;
   IF ( NOT v_OK ) THEN
      RAISE_APPLICATION_ERROR(-20000,v_obj_name || ' failed to install.');
   END IF;
END;
/
SHOW ERRORS

grant execute on TOOLS to public;

EXIT SUCCESS;

