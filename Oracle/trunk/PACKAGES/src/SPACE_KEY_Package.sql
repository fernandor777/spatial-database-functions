DEFINE defaultSchema='&1'
set serveroutput on size 1000000
ALTER SESSION SET plsql_optimize_level=1;

create or replace TYPE t_grid AS OBJECT (
   gcol  number,
   grow  number,
   geom  mdsys.sdo_geometry
);
/
SHOW ERRORS

grant execute on &&defaultSchema..t_grid to public;

create or replace
PACKAGE SPACE_KEY
AUTHID CURRENT_USER
AS

 /* create or replace TYPE t_grid AS OBJECT (
      gcol  number,
      grow  number,
      geom  mdsys.sdo_geometry
   );
   grant execute on t_grid to public;
 */
 TYPE t_GridSet   IS TABLE OF &&defaultSchema..T_Grid;

 /* ----------------------------------------------------------------------------------------
    -- @function   : Morton
    -- @precis     : This function calculates the Morton number of a cell at the given row and col[umn]
    -- @version    : 1.0
    -- @usage      : select Morton (0,0) from dual;
    -- @note       : Ignores any 3rd dimension.
    -- @history    : Written:  D.M. Mark, Jan 1984;
    -- @history    : Simon Greener (SpatialDB Advisor) - Nov 2009  - Converted to PL/SQL
    -- @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License. (http://creativecommons.org/licenses/by-sa/2.5/au/)
 */
 Function Morton (p_col Natural, p_row Natural)
    Return INTEGER Deterministic;

 /* ----------------------------------------------------------------------------------------
    -- @function   : QuadTree
    -- @precis     : Tesselates the two-dimensional space defined by p_Search_Table using a
    --               quad tree algorithm based on a set of criteria.
    --                  * Depth of the Tree;
    --                  * Number of features per quad
    --               The ouput polygons representing the quads that contain the data
    --               are written to the p_TagetTable with some specific fields
    -- @version    : 1.0
    -- @usage      : FUNCTION QuadTree ( ** various call signatures ** )
    -- @example    : DECLARE
    --                 v_quadid INTEGER;
    --               BEGIN
    --                 &&defaultSchema..Tesselate.Initialise(20,
    --                                      'TEST_POINTS',
    --                                      'SHAPE',
    --                                      20);
    --                 v_QuadId := &&defaultSchema..Tesselate.QuadTree;
    --               END;
    --               /
    -- @note       : Ignores any 3rd dimension.
    -- @history    : Simon Greener (SpatialDB Advisor) - March 2006 - Original Coding as a single function
    -- @history    : Simon Greener (SpatialDB Advisor) - June 2006  - Turned original code into an Oracle Package
    -- @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License. (http://creativecommons.org/licenses/by-sa/2.5/au/)
 */

/* Bunch of QuadTree Initialisation Functions
 */
   PROCEDURE
     Initialise( p_MaxCount     IN INTEGER );

   Procedure
     Initialise( p_format       IN Varchar2 );

   PROCEDURE
     Initialise( p_MaxCount     IN INTEGER,
                 p_SearchTable  IN VARCHAR2,
                 p_SearchColumn IN VARCHAR2 );

   PROCEDURE
     Initialise( p_MaxCount     IN INTEGER,
                 p_SearchTable  IN VARCHAR2,
                 p_SearchColumn IN VARCHAR2,
	               p_TargetTable  IN VARCHAR2,
                 p_TargetColumn IN VARCHAR2);

   PROCEDURE
     Initialise( p_MaxCount     IN INTEGER,
                 p_SearchTable  IN VARCHAR2,
                 p_SearchColumn IN VARCHAR2,
                 p_MaxQuadLevel IN INTEGER);

   PROCEDURE
     Initialise( p_MaxCount     IN INTEGER,
	               p_SearchTable  IN VARCHAR2,
                 p_SearchColumn IN VARCHAR2,
	               p_TargetTable  IN VARCHAR2,
                 p_TargetColumn IN VARCHAR2,
                 p_MaxQuadLevel IN INTEGER);

   Procedure SetGeom2SQLMM;
   Procedure SetGeom2SDO;

   Function
     QuadTree( p_SearchTable  IN VARCHAR2,
               p_SearchColumn IN VARCHAR2,
               p_TargetTable  IN VARCHAR2,
               p_TargetColumn IN VARCHAR2,
               p_MaxQuadLevel IN INTEGER,
               p_MaxCount     IN INTEGER,
               p_LL           IN MDSYS.SDO_POINT_TYPE,
               p_UR           IN MDSYS.SDO_POINT_TYPE)
               RETURN INTEGER DETERMINISTIC;

   Function
     QuadTree( p_SearchTable  IN VARCHAR2,
               p_SearchColumn IN VARCHAR2,
               p_TargetTable  IN VARCHAR2,
               p_TargetColumn IN VARCHAR2,
               p_MaxQuadLevel IN INTEGER,
               p_MaxCount     IN INTEGER,
               p_DimInfo      IN MDSYS.SDO_DIM_ARRAY)
               RETURN INTEGER DETERMINISTIC;

   Function
     QuadTree( p_diminfo      IN MDSYS.SDO_DIM_ARRAY)
               RETURN INTEGER DETERMINISTIC;

   Function
     QuadTree( p_LL           IN MDSYS.SDO_POINT_TYPE,
               p_UR           IN MDSYS.SDO_POINT_TYPE )
               RETURN INTEGER DETERMINISTIC;

   Function
     QuadTree  RETURN INTEGER DETERMINISTIC;

 /* ----------------------------------------------------------------------------------------
    -- @function   : RegularGrid
    -- @precis     : Tesselates a two-dimensional space using a simple rectangular grid.
    --               Returns 2003 geometries in a Pipelined Geometry Set.
    --               Similar to MDSYS.SDO_SAM.TILED_BINS.
    -- @version    : 1.0
    -- @usage      : FUNCTION RegularGrid ( p_LL       In MDSYS.SDO_POINT_TYPE,
    --                                      p_UR       In MDSYS.SDO_POINT_TYPE,
    --                                      p_TileSize In MDSYS.SDO_POINT_TYPE,
    --                                      p_srid     In Number Default Null )
    --                        Return &&defaultSchema..T_GeometrySet Pipelined;
    -- @example    : Select *
    --                 From Table(&&defaultSchema..SPACE_KEY.RegularGrid(
    --                            MDSYS.SDO_Point_Type(0,0,NULL),
    --                            MDSYS.SDO_Point_Type(1000,500,NULL),
    --                            MDSYS.SDO_Point_Type(100,50,NULL),
    --                            Null ) );
    -- @param      : p_LL        : Lower bound of the extent to be tesselated
    -- @paramtype  : p_LL        : MDSYS.SDO_Point_Type
    -- @param      : p_UR        : Upper bound of the extent to be tesselated
    -- @paramtype  : p_UR        : MDSYS.SDO_Point_Type
    -- @param      : p_TileSize  : Size of cells as Width/Height where x=width and y=height.
    -- @paramtype  : p_TileSize  : MDSYS.SDO_Point_Type
    -- @param      : p_SRID      : SRID value to be included for the coordinate system in the returned tile geometries.
    -- @paramtype  : p_SRID      : NUMBER
    -- @return     : Geometries  : Table of 2003 Optimised Rectangle geometries.
    -- @rtnType    : Geometries  : &&defaultSchema..T_GeometrySet
    -- @note       : Ignores any 3rd dimension.
    -- @history    : Simon Greener - Aug 2006 - Original coding.
    -- @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License. (http://creativecommons.org/licenses/by-sa/2.5/au/)
 */
   Function RegularGrid( p_LL       In MDSYS.SDO_Point_Type,
                         p_UR       In MDSYS.SDO_Point_Type,
                         p_TileSize In MDSYS.SDO_Point_Type,
                         p_srid     In Number Default Null,
                         p_point    in pls_integer default 0)
            Return &&defaultSchema..SPACE_KEY.t_GridSet Pipelined;

   Function RegularGridPoint(p_LL       In MDSYS.SDO_POINT_TYPE,
                             p_UR       In MDSYS.SDO_POINT_TYPE,
                             p_TileSize In MDSYS.SDO_POINT_TYPE,
                             p_srid     In Number Default Null )
            Return &&defaultSchema..SPACE_KEY.t_GridSet Pipelined;

   -- Version that uses a 2003/3003 Optimized Rectangle geometry defining the required extent (eg from SDO_AGGR_UNION)
   Function RegularGrid( p_geometry In MDSYS.SDO_Geometry,
                         p_TileSize In MDSYS.SDO_Point_Type,
                         p_point    in pls_integer Default 0)
            Return &&defaultSchema..SPACE_KEY.t_GridSet Pipelined;

   Function RegularGridPoint(p_geometry In MDSYS.SDO_Geometry,
                             p_TileSize In MDSYS.SDO_Point_Type )
            Return &&defaultSchema..SPACE_KEY.t_GridSet Pipelined;
            
   Function RegularGrid( p_geometry In MDSYS.SDO_Geometry,
                         p_divisor  In Number,
                         p_point    in pls_integer := 0)
            Return &&defaultSchema..SPACE_KEY.t_GridSet Pipelined;

   Function RegularGridXY(p_xmin      in number,
                          p_ymin      in number,
                          p_xmax      in number,
                          p_ymax      in number,
                          p_TileSizeX in number,
                          p_TileSizeY in number,
                          p_srid      in pls_integer,
                          p_point     in pls_integer Default 0)
     return &&defaultSchema..SPACE_KEY.t_GridSet pipelined;

   /* A bunch of wrappers over the HHENCODE function for generating simple space_keys
   */
   Function
     SPACE_KEY( p_point       IN MDSYS.SDO_POINT_TYPE,
                p_ll          IN MDSYS.SDO_POINT_TYPE,
                p_ur          IN MDSYS.SDO_POINT_TYPE)
                RETURN RAW DETERMINISTIC;

   Function
     SPACE_KEY( p_ll          IN MDSYS.SDO_POINT_TYPE,
                p_ur          IN MDSYS.SDO_POINT_TYPE)
                RETURN RAW DETERMINISTIC;

   Function
     SPACE_KEY( p_shape      IN mdsys.sdo_geometry,
                p_diminfo    IN mdsys.sdo_dim_array )
                RETURN RAW DETERMINISTIC;

   Function
     SPACE_KEY( p_x           IN NUMBER,
                p_y           IN NUMBER,
                p_diminfo     IN MDSYS.SDO_DIM_ARRAY )
                RETURN RAW DETERMINISTIC;

   Function
     SPACE_KEY( p_point       IN MDSYS.SDO_POINT_TYPE,
                p_diminfo     IN MDSYS.SDO_DIM_ARRAY )
                RETURN RAW DETERMINISTIC;

   -- Compute the coefficients for the plane defined by
   -- points (x1,y1,z1), (x2,y2,z3), (x3,y3,z3)
   Procedure Compute_Plane(x1 In Number,
                           y1 In Number,
                           z1 In Number,
                           x2 In Number,
                           y2 In Number,
                           z2 In Number,
                           x3 In Number,
                           y3 In Number,
                           z3 In Number,
                           a  In Out NoCopy Number,
                           b  In Out NoCopy Number,
                           c  In Out NoCopy Number,
                           d  In Out NoCopy Number);

END SPACE_KEY;
/
SHOW ERRORS

Prompt ----------------------000000000000000000000000000--------------------------

create or replace
PACKAGE BODY SPACE_KEY
AS

  c_SQLMM               CONSTANT VARCHAR2(5) := 'SQLMM';
  c_SDO                 CONSTANT VARCHAR2(5) := 'SDO';

  v_format              VARCHAR2(5)  := c_SDO;
  v_format_type         VARCHAR2(32) := 'MDSYS.SDO_GEOMETRY';  -- Or 'MDSYS.ST_POLYGON'

  v_select_sql          VARCHAR2(4000);
  v_insert_sql          VARCHAR2(4000);
  v_MaxQuadLevel        INTEGER;
  v_MaxCount            INTEGER;
  v_SearchTable         VARCHAR2(32);
  v_SearchColumn        VARCHAR2(32);
  v_SRID                VARCHAR2(10);
  v_TargetTable         VARCHAR2(32);
  v_TargetColumn        VARCHAR2(32) := 'GEOMETRY';
  v_lvl                 INTEGER        := 8;    -- Encoding level for hhcode function

  -- Private internal utility functions
  --
  Function Rectangle2WKT( p_LL_x in Number,
                          p_LL_y in Number,
                          p_UR_x in Number,
                          p_UR_y in Number)
           Return Varchar2
  Is
  Begin
     Return 'POLYGON((' || p_LL_x || ' ' || p_LL_Y || ', ' ||
                           p_UR_x || ' ' || p_LL_Y || ', ' ||
                           p_UR_x || ' ' || p_UR_Y || ', ' ||
                           p_LL_x || ' ' || p_UR_Y || ', ' ||
                           p_LL_x || ' ' || p_LL_Y || '))';
  End Rectangle2WKT;

  Function Rectangle2WKT( p_LL in MDSYS.SDO_Point_Type,
                          p_UR in MDSYS.SDO_Point_Type )
           Return Varchar2
  Is
  Begin
     Return 'POLYGON((' || p_LL.x || ' ' || p_LL.Y || ', ' ||
                           p_UR.x || ' ' || p_LL.Y || ', ' ||
                           p_UR.x || ' ' || p_UR.Y || ', ' ||
                           p_LL.x || ' ' || p_UR.Y || ', ' ||
                           p_LL.x || ' ' || p_LL.Y || '))';
  End Rectangle2WKT;

  Procedure SetSQL
  Is
  BEGIN
    v_select_sql := 'SELECT count(*)';
    IF ( DBMS_DB_VERSION.VERSION < 10 ) THEN
      v_select_sql := v_select_sql || '  FROM user_sdo_geom_metadata asgm, ' || v_SearchTable || ' a ';
      v_select_sql := v_select_sql || ' WHERE ( asgm.table_name = UPPER('''|| v_SearchTable || ''') AND asgm.column_name = UPPER(''' || v_SearchColumn || ''') )';
      v_select_sql := v_select_sql || '   AND MDSYS.SDO_RELATE(a.' || v_SearchColumn;
    ELSE
      v_select_sql := v_select_sql || '  FROM '|| v_SearchTable || ' a ';
      v_select_sql := v_select_sql || ' WHERE SDO_ANYINTERACT(a.' || v_SearchColumn;
    END IF;
    v_select_sql := v_select_sql || ',MDSYS.SDO_GEOMETRY(2003,'|| v_SRID || ',NULL,';
    v_select_sql := v_select_sql || 'MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,3),MDSYS.SDO_ORDINATE_ARRAY(:1,:2,:3,:4))';
    IF ( DBMS_DB_VERSION.VERSION < 10 ) THEN
      v_select_sql := v_select_sql || ',''mask=ANYINTERACT''';
    END IF;
    v_select_sql := v_select_sql || ') = ''TRUE''';
    v_insert_sql := 'INSERT INTO ' || v_TargetTable ||
                        ' (quad_id,quad_level,space_key,feature_count,xlo,ylo,xhi,yhi,' || v_TargetColumn || ') ' ||
                        ' VALUES (:1,:2,:3,:4,:5,:6,:7,:8,';
    If ( DBMS_DB_VERSION.VERSION < 10 ) OR ( v_format = c_SDO) Then
        v_insert_sql := v_insert_sql || ':9)';
    Else
        v_insert_sql := v_insert_sql || 'MDSYS.ST_POLYGON.ST_BDPOLYFROMTEXT(:9,:10))';
    End If;
  END SetSQL;

  Procedure SetGeom2SQLMM
  Is
  Begin
    v_Format      := c_SQLMM;
    v_format_type := 'MDSYS.ST_POLYGON';
  End SetGeom2SQLMM;

  Procedure SetGeom2SDO
  Is
  Begin
    v_Format      := c_SDO;
    v_format_type := 'MDSYS.SDO_GEOMETRY';
  End SetGeom2SDO;

  Procedure DropTargetTableMetadata
  Is
  Begin
    EXECUTE IMMEDIATE 'DELETE FROM USER_SDO_GEOM_METADATA WHERE TABLE_NAME = ''' || UPPER(v_TargetTable) || '''';
    COMMIT;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
  End DropTargetTableMetadata;

  Procedure CreateTargetTableMetadata( p_diminfo IN MDSYS.SDO_DIM_ARRAY )
  Is
    v_SRID_n number := NULL;
  Begin
    If ( v_SRID <> 'NULL' ) Then
      v_SRID_n := to_number(v_srid);
    End If;
    DropTargetTableMetadata;
    If ( v_Format = c_SDO ) Then
      INSERT INTO USER_SDO_GEOM_METADATA (TABLE_NAME,COLUMN_NAME,SRID,DIMINFO)
         VALUES(v_TargetTable,v_TargetColumn,v_SRID_n,p_diminfo);
    Else
      INSERT INTO USER_SDO_GEOM_METADATA (TABLE_NAME,COLUMN_NAME,SRID,DIMINFO)
         VALUES(v_TargetTable,v_TargetColumn||'.GEOM',v_SRID_n,p_diminfo);
    End If;
    COMMIT;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
  End CreateTargetTableMetadata;

  Procedure DropTargetTable
  Is
  Begin
    EXECUTE IMMEDIATE 'DROP TABLE ' || v_TargetTable;
    EXCEPTION
	WHEN OTHERS THEN
   NULL;
  End DropTargetTable;

  Procedure CreateTargetTable
  Is
  BEGIN
    EXECUTE IMMEDIATE 'CREATE TABLE ' || v_TargetTable || '(
      quad_id       NUMBER(38) NOT NULL,
      quad_level    INTEGER,
      space_key     RAW(64),
      feature_Count NUMBER,
      xlo           NUMBER,
      ylo           NUMBER,
      xhi           NUMBER,
      yhi           NUMBER,
      '|| v_TargetColumn || '      ' || v_format_type || ')';
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
  END CreateTargetTable;

  -- ***********************************************************************************
  -- Space_Key constructors
  --
  Function
    SPACE_KEY( p_point       IN MDSYS.SDO_POINT_TYPE,
               p_ll          IN MDSYS.SDO_POINT_TYPE,
               p_ur          IN MDSYS.SDO_POINT_TYPE)
               RETURN RAW
  IS
  BEGIN
    RETURN MDSYS.MD.HHENCODE( p_point.x, p_ll.x, p_ll.y, v_lvl,
                              p_point.y, p_ur.x, p_ur.y, v_lvl);
  END;

  Function
    SPACE_KEY( p_ll          IN MDSYS.SDO_POINT_TYPE,
               p_ur          IN MDSYS.SDO_POINT_TYPE)
               RETURN RAW
  IS
  BEGIN
    RETURN MDSYS.MD.HHENCODE( ( p_ll.x + p_ur.x ) / 2, p_ll.x, p_ll.y, v_lvl,
                              ( p_ur.y + p_ur.y ) / 2, p_ur.x, p_ur.y, v_lvl);
  END;

  Function
    SPACE_KEY( p_x           IN NUMBER,
               p_y           IN NUMBER,
               p_diminfo     IN MDSYS.SDO_DIM_ARRAY )
               RETURN RAW
  IS
    v_ll    MDSYS.SDO_POINT_TYPE := MDSYS.SDO_POINT_TYPE(0,0,0);
    v_ur    MDSYS.SDO_POINT_TYPE := MDSYS.SDO_POINT_TYPE(0,0,0);
  BEGIN
    v_ll.x  := p_diminfo(1).sdo_lb;
    v_ur.x  := p_diminfo(1).sdo_ub;
    v_ll.y  := p_diminfo(2).sdo_lb;
    v_ur.y  := p_diminfo(2).sdo_ub;
    RETURN Space_Key( mdsys.sdo_point_type(p_x,p_y,NULL), v_ll, v_ur );
  END;

  Function
    SPACE_KEY( p_point       IN MDSYS.SDO_POINT_TYPE,
               p_diminfo     IN MDSYS.SDO_DIM_ARRAY )
               RETURN RAW
  IS
    v_ll    MDSYS.SDO_POINT_TYPE := MDSYS.SDO_POINT_TYPE(0,0,0);
    v_ur    MDSYS.SDO_POINT_TYPE := MDSYS.SDO_POINT_TYPE(0,0,0);
  BEGIN
    v_ll.x  := p_diminfo(1).sdo_lb;
    v_ur.x  := p_diminfo(1).sdo_ub;
    v_ll.y  := p_diminfo(2).sdo_lb;
    v_ur.y  := p_diminfo(2).sdo_ub;
    RETURN Space_Key( p_point, v_ll, v_ur );
  END;

  Function
   SPACE_KEY (  p_shape   IN MDSYS.SDO_GEOMETRY,
                p_diminfo IN MDSYS.SDO_DIM_ARRAY )
     RETURN RAW
  IS
    v_point MDSYS.SDO_POINT_TYPE := MDSYS.SDO_POINT_TYPE(0,0,0);
    v_ll    MDSYS.SDO_POINT_TYPE := MDSYS.SDO_POINT_TYPE(0,0,0);
    v_ur    MDSYS.SDO_POINT_TYPE := MDSYS.SDO_POINT_TYPE(0,0,0);
  BEGIN
    v_point := &&defaultSchema..CENTROID.SDO_CENTROID(p_shape,1,p_diminfo).sdo_point;
    v_ll.x  := p_diminfo(1).sdo_lb;
    v_ur.x  := p_diminfo(1).sdo_ub;
    v_ll.y  := p_diminfo(2).sdo_lb;
    v_ur.y  := p_diminfo(2).sdo_ub;
    RETURN Space_Key( v_point, v_ll, v_ur );
  END;

  Function morton (p_col Natural, p_row Natural)
  Return INTEGER
  As
      /*  unsigned xy_to_morton (col,row)
          unsigned col,row;
          {
             unsigned key;
             int level, left_bit, right_bit, quadrant;
             key = 0;
             level = 0;
             while ((row>0) || (col>0))
             {
               left_bit  = row % 2;
               right_bit = col % 2;
               quadrant = right_bit + 2*left_bit;
               key += quadrant<<(2*level);
               row /= 2;
               col /= 2;
               level++;
             }
             return (key);
          }
      */
      v_row       Natural := ABS(p_row);
      v_col       Natural := ABS(p_col);
      v_key       Natural := 0;
      v_level     BINARY_INTEGER := 0;
      v_left_bit  BINARY_INTEGER;
      v_right_bit BINARY_INTEGER;
      v_quadrant  BINARY_INTEGER;

      Function Left_Shift( p_val Natural, p_shift Natural)
      Return PLS_Integer
      As
      Begin
         Return trunc(p_val * power(2,p_shift));
      End;

  Begin
      while ((v_row>0) Or (v_col>0)) Loop
         /*   split off the row (left_bit) and column (right_bit) bits and
              then combine them to form a bit-pair representing the
              quadrant                                                  */
         v_left_bit  := MOD(v_row,2);
         v_right_bit := MOD(v_col,2);
         v_quadrant  := v_right_bit + ( 2 * v_left_bit );
         v_key       := v_key + Left_Shift( v_quadrant,( 2 * v_level ) );
         /*   row, column, and level are then modified before the loop
              continues                                                */
         v_row := trunc( v_row / 2 );
         v_col := trunc( v_col / 2 );
         v_level := v_level + 1;
       End Loop;
      return (v_key);
  End Morton;

   -- ***********************************************************************************
   -- QuadTree public functions
   --
   Procedure
     Initialise
   IS
   Begin
      If ( v_SearchTable IS NULL ) Then
         raise_application_error(-20100,'Table for Quadding not set.',TRUE);
      End If;
      DropTargetTable;
      CreateTargetTable;
      SetSQL;
   END;


   Procedure
     Initialise( p_format IN Varchar2 )
   IS
   Begin
      If    ( UPPER(p_format) = c_SDO   ) Then
        SetGeom2SDO;
      ElsIf ( UPPER(p_format) = c_SQLMM ) Then
        SetGeom2SQLMM;
      Else
         raise_application_error(-20100,'Output geometry format for Quad table is either '||c_SDO||' or '||c_SQLMM||'.',TRUE);
      End If;
      Initialise;
   END;

   Procedure
     Initialise( p_MaxCount IN INTEGER )
   IS
   Begin
      v_MaxCount := p_MaxCount;
      Initialise;
   END;

   Procedure
     Initialise( p_MaxCount     IN INTEGER,
                 p_MaxQuadLevel IN INTEGER )
   Is
   Begin
     v_MaxQuadLevel := p_MaxQuadLevel;
     Initialise(p_MaxCount);
   End;

   ProcedurE
     Initialise( p_MaxCount     IN INTEGER,
                 p_SearchTable  IN VARCHAR2,
                 p_SearchColumn IN VARCHAR2 )
   Is
      v_sql varchar2(4000);
   Begin
      v_SearchTable  := UPPER(p_SearchTable);
      v_SearchColumn := UPPER(p_SearchColumn);
      -- Check if table and metadata exist by getting a srid value (don't catch exception)
      v_sql :=          'SELECT DECODE(usgm.srid,NULL,''NULL'',TO_CHAR(usgm.srid)) ';
      v_sql := v_sql || '  FROM USER_SDO_GEOM_METADATA USGM, '||v_SearchTable||' a ';
      v_sql := v_sql || ' WHERE ( usgm.table_name = '''||v_SearchTable||''' AND usgm.column_name = '''||v_SearchColumn||''' ) ';
      v_sql := v_sql || '   AND a.rowid is not null AND rownum = 1 ';
      EXECUTE IMMEDIATE v_sql INTO v_SRID;
      Initialise(p_MaxCount);
   End;

   Procedure
     Initialise( p_MaxCount     IN INTEGER,
                 p_SearchTable  IN VARCHAR2,
                 p_SearchColumn IN VARCHAR2,
	         p_TargetTable  IN VARCHAR2,
                 p_TargetColumn IN VARCHAR2)
   Is
   Begin
      v_TargetTable  := UPPER(p_TargetTable);
      v_TargetColumn := UPPER(p_TargetColumn);
      Initialise(p_MaxCount,p_SearchTable,p_SearchColumn);
   End;

   Procedure
     Initialise( p_MaxCount     IN INTEGER,
                 p_SearchTable  IN VARCHAR2,
                 p_SearchColumn IN VARCHAR2,
                 p_MaxQuadLevel IN INTEGER)
   Is
   BEGIN
     v_MaxQuadLevel := p_MaxQuadLevel;
     Initialise(p_MaxCount,p_SearchTable,p_SearchColumn);
   END;

   Procedure
     Initialise( p_MaxCount     IN INTEGER,
                 p_SearchTable  IN VARCHAR2,
                 p_SearchColumn IN VARCHAR2,
	         p_TargetTable  IN VARCHAR2,
                 p_TargetColumn IN VARCHAR2,
                 p_MaxQuadLevel IN INTEGER )
   Is
   Begin
     v_MaxQuadLevel := p_MaxQuadLevel;
     Initialise(p_MaxCount,p_SearchTable,p_SearchColumn,p_TargetTable,p_TargetColumn);
   End;

  -- Internal routine that does all the work...
  --
  Function
    QuadTree( p_QuadId       IN INTEGER,
              p_LL           IN MDSYS.SDO_POINT_TYPE,
              p_UR           IN MDSYS.SDO_POINT_TYPE,
              p_QuadLevel    IN INTEGER)
    RETURN INTEGER
  IS
    v_count     NUMBER;
    v_temp      NUMBER;
    v_QuadLevel INTEGER;
    v_QuadID    INTEGER;
    v_LL        MDSYS.SDO_POINT_TYPE := MDSYS.SDO_POINT_TYPE(0,0,0);
    v_UR        MDSYS.SDO_POINT_TYPE := MDSYS.SDO_POINT_TYPE(0,0,0);

    Procedure InsertTile
    Is
      v_srid_n    NUMBER;
    Begin
      v_srid_n := NULL;
      If ( v_srid <> 'NULL' ) Then
        v_srid_n := to_number(v_srid);
      End If;
      -- Create the actual record
      If ( v_Format = c_SDO ) Then
        EXECUTE IMMEDIATE v_insert_sql
                    USING p_QuadId,
                          v_QuadLevel,
                          Space_Key(v_LL,v_UR),
                          v_count,
                          v_LL.X, v_LL.Y,
                          v_UR.X, v_UR.Y,
                          MDSYS.SDO_GEOMETRY(2003,v_srid_n,NULL,
                                             MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,3),
                                             MDSYS.SDO_ORDINATE_ARRAY(v_LL.X,v_LL.Y,v_UR.X,v_UR.Y));
      Else
        EXECUTE IMMEDIATE v_insert_sql
                    USING p_QuadId,
                          v_QuadLevel,
                          Space_Key(v_LL,v_UR),
                          v_count,
                          v_LL.X, v_LL.Y,
                          v_UR.X, v_UR.Y,
                          Rectangle2WKT(v_LL,v_UR),
			  v_srid_n;
      End If;
    End InsertTile;

  BEGIN
    If ( p_QuadId = 0 And p_QuadLevel = 0 ) Then
      CreateTargetTableMetadata( MDSYS.SDO_DIM_ARRAY(MDSYS.SDO_DIM_ELEMENT('X',p_LL.X,p_UR.x,0.5),
                                                     MDSYS.SDO_DIM_ELEMENT('Y',p_LL.Y,p_UR.Y,0.5)) );
    End If;
    v_QuadId    := p_QuadId;
    v_QuadLevel := p_QuadLevel;
    v_LL        := p_LL;
    v_UR        := p_UR;
    -- Performance optimisation
    --   When at level 0 don't execute a search but start tesselating
    If ( v_QuadLevel <> 0 ) Then
      EXECUTE IMMEDIATE v_select_sql
              INTO v_count
              USING v_LL.X,v_LL.Y,v_UR.X,v_UR.Y ;
      IF ( v_count = 0 ) THEN
        RETURN v_QuadId;
      END IF;
      IF ( v_count <= v_MaxCount ) THEN
        InsertTile;
        RETURN v_QuadId + 1;
      END IF;
    End If;

    v_QuadLevel := p_QuadLevel + 1;
    IF ( v_QuadLevel > v_MaxQuadLevel ) THEN
      RETURN v_QuadId;
    END IF;
    -- Still need to tessellate the space!
    --
    -- initialize tmp node with corner data
    -- +---+---R
    -- |   |   |
    -- +---+---+
    -- | x |   |
    -- L---+---+
    v_UR.X := v_LL.X + ( v_UR.X - v_LL.X ) / 2;
    v_UR.Y := v_LL.Y + ( v_UR.Y - v_LL.Y ) / 2;
    v_QuadId := QuadTree(v_QuadId,v_LL,v_UR,v_QuadLevel);
    -- +---+---+
    -- | x |   |
    -- +---R---+
    -- | 1 |   |
    -- L---+---+
    v_temp := ( v_UR.Y - v_LL.Y );
    v_LL.Y := v_UR.Y;
    v_UR.Y := v_LL.Y + v_temp;
    v_QuadId := QuadTree(v_QuadId,v_LL,v_UR,v_QuadLevel);
    -- +---R---+
    -- | 2 |   |
    -- L---+---+
    -- |   | x |
    -- +---+---+
    v_temp := ( v_UR.X - v_LL.X );
    v_LL.X := v_UR.X;
    v_UR.X := v_LL.X + v_temp;
    v_temp := ( v_UR.Y - v_LL.Y );
    v_UR.Y := v_LL.Y;
    v_LL.Y := v_UR.Y - v_temp;
    v_QuadId := QuadTree(v_QuadId,v_LL,v_UR,v_QuadLevel);
    -- +---+---+
    -- |   | x |
    -- +---+---U
    -- |   | 3 |
    -- +---L---+
    v_temp := ( v_UR.Y - v_LL.Y );
    v_LL.Y := v_UR.Y;
    v_UR.Y := v_LL.Y + v_temp;
    RETURN QuadTree(v_QuadId,v_LL,v_UR,v_QuadLevel);
  END;

  Function
    QuadTree( p_SearchTable  IN VARCHAR2,
              p_SearchColumn IN VARCHAR2,
              p_TargetTable  IN VARCHAR2,
              p_TargetColumn IN VARCHAR2,
              p_MaxQuadLevel IN INTEGER,
              p_MaxCount     IN INTEGER,
              p_LL           IN MDSYS.SDO_POINT_TYPE,
              p_UR           IN MDSYS.SDO_POINT_TYPE)
    RETURN INTEGER
  IS
  BEGIN
    Initialise( p_MaxCount, p_SearchTable, p_SearchColumn, p_TargetTable, p_TargetColumn, p_MaxQuadLevel );
    RETURN QuadTree( 0, p_LL, p_UR, 0 );
  END;

  Function
    QuadTree( p_LL           IN MDSYS.SDO_POINT_TYPE,
              p_UR           IN MDSYS.SDO_POINT_TYPE)
    Return Integer
  Is
  Begin
    RETURN QuadTree( 0, p_LL, p_UR, 0 );
  End;

  Function
    QuadTree( p_DimInfo IN MDSYS.SDO_DIM_ARRAY)
    Return Integer
  Is
    v_LL        MDSYS.SDO_POINT_TYPE := MDSYS.SDO_POINT_TYPE(0,0,0);
    v_UR        MDSYS.SDO_POINT_TYPE := MDSYS.SDO_POINT_TYPE(0,0,0);
  BEGIN
    v_ll.x  := p_diminfo(1).sdo_lb;
    v_ur.x  := p_diminfo(1).sdo_ub;
    v_ll.y  := p_diminfo(2).sdo_lb;
    v_ur.y  := p_diminfo(2).sdo_ub;
    RETURN QuadTree( 0, v_LL, v_UR, 0 );
  End;

  Function
    QuadTree
    Return Integer
  Is
    v_geom      MDSYS.SDO_GEOMETRY;
    v_LL        MDSYS.SDO_POINT_TYPE := MDSYS.SDO_POINT_TYPE(0,0,0);
    v_UR        MDSYS.SDO_POINT_TYPE := MDSYS.SDO_POINT_TYPE(0,0,0);
  Begin
    SELECT MDSYS.SDO_TUNE.EXTENT_OF(v_SearchTable,v_SearchColumn)
      INTO v_geom
      FROM DUAL;
    v_ll.X := v_geom.sdo_ordinates(1);
    v_ll.Y := v_geom.sdo_ordinates(2);
    v_ur.X := v_geom.sdo_ordinates(3);
    v_ur.Y := v_geom.sdo_ordinates(4);
    RETURN QuadTree( 0, v_LL, v_UR, 0 );
  End;

  Function
    QuadTree( p_SearchTable  IN VARCHAR2,
              p_SearchColumn IN VARCHAR2,
              p_TargetTable  IN VARCHAR2,
              p_TargetColumn IN VARCHAR2,
              p_MaxQuadLevel IN INTEGER,
              p_MaxCount     IN INTEGER,
              p_DimInfo      IN MDSYS.SDO_DIM_ARRAY)
    RETURN INTEGER
  IS
    v_LL        MDSYS.SDO_POINT_TYPE := MDSYS.SDO_POINT_TYPE(0,0,0);
    v_UR        MDSYS.SDO_POINT_TYPE := MDSYS.SDO_POINT_TYPE(0,0,0);
    v_QuadLevel INTEGER := 0;
  BEGIN
    Initialise( p_MaxCount, p_SearchTable, p_SearchColumn, p_TargetTable, p_TargetColumn, p_MaxQuadLevel );
    v_ll.x  := p_diminfo(1).sdo_lb;
    v_ur.x  := p_diminfo(1).sdo_ub;
    v_ll.y  := p_diminfo(2).sdo_lb;
    v_ur.y  := p_diminfo(2).sdo_ub;
    RETURN QuadTree( 0, v_LL, v_UR, v_QuadLevel );
  END;

  -- Create a "Laser-Scan" RT compliant grid with internal gap from these quad-tree tessellations
  -- p_output_table must exist... should check and test this.
  --
  Procedure ConvertToLaserScan( p_gap IN NUMBER,
                                p_output_table IN varchar2 )
  Is
     v_quad_id      INTEGER;
     v_geometry     MDSYS.SDO_GEOMETRY;
     v_new_geometry MDSYS.SDO_GEOMETRY;
     v_vertices     MDSYS.VERTEX_SET_TYPE;
     v_xlo          NUMBER;
     v_ylo          NUMBER;
     v_xhi          NUMBER;
     v_yhi          NUMBER;
     v_sql          Varchar2(256);
     TYPE cur_type IS REF CURSOR;  -- Need a ref cursor for the generated SQL
     v_cursor      cur_type;
   BEGIN
     v_sql := 'SELECT QUAD_ID,XLO,YLO,XHI,YHI,A.GEOMETRY FROM '|| v_TargetTable || ' A';
     If ( v_Format = c_SQLMM ) Then
       v_sql := 'SELECT QUAD_ID,XLO,YLO,XHI,YHI,A.GEOMETRY.GEOM FROM '|| v_TargetTable || ' A';
     End If;
     OPEN v_cursor FOR v_sql;
     LOOP
        FETCH v_cursor INTO v_quad_id, v_xlo, v_ylo, v_xhi, v_yhi, v_geometry;
        EXIT WHEN v_cursor%NOTFOUND;
        -- For non-10g sites that have not got the VERTEX_SET_TYPE the following
        -- should be used in preference to the above (both are here as an example)
        v_xlo := v_xlo + p_gap;
        v_ylo := v_ylo + p_gap;
        v_xhi := v_xhi - p_gap;
        v_yhi := v_yhi - p_gap;
        -- QuadTree produces optimized rectangle geometries
        -- An alternate method for modifying the geometry is as follows
        v_vertices     := MDSYS.SDO_UTIL.GetVertices(v_geometry);
        v_vertices(1).x := v_vertices(1).x + p_gap;
        v_vertices(1).y := v_vertices(1).y + p_gap;
        v_vertices(2).x := v_vertices(2).x - p_gap;
        v_vertices(2).y := v_vertices(2).y - p_gap;
        IF ( DBMS_DB_VERSION.VERSION < 10 ) THEN
          -- No choice but to "hard-code" the 4 coordinates
          -- by appropriately specifing them in the mdsys.sdo_ordinate_array constructor
          v_new_geometry := MDSYS.SDO_GEOMETRY(2002,
                                               v_geometry.sdo_srid,
                                               NULL,
                                               mdsys.sdo_elem_info_array(1,2,1),
                                               MDSYS.SDO_ORDINATE_ARRAY(
                                                     v_vertices(1).x,v_vertices(1).y,
                                                     v_vertices(1).x,v_vertices(2).y,
                                                     v_vertices(2).x,v_vertices(2).y,
                                                     v_vertices(2).x,v_vertices(1).y
                                               ));
        ELSE
          -- Now use use the POLYGONTOLINE function in mdsys.sdo_util 10g to do what we
          -- want more succinctly than for earlier versions
          v_new_geometry := MDSYS.SDO_GEOMETRY(v_geometry.sdo_gtype,
                                               v_geometry.sdo_srid,
                                               NULL,
                                               v_geometry.sdo_elem_info,
                                               MDSYS.SDO_ORDINATE_ARRAY(
                                                     v_vertices(1).x,v_vertices(1).y,
                                                     v_vertices(2).x,v_vertices(2).y
                                               ));
   	EXECUTE IMMEDIATE 'SELECT MDSYS.SDO_UTIL.POLYGONTOLINE(:1) FROM DUAL' INTO v_new_geometry USING v_new_geometry;
        END IF;
        EXECUTE IMMEDIATE 'INSERT INTO '|| p_Output_Table || '(GRID_ID,XLO,YLO,XHI,YHI,GEOMETRY) VALUES(:1,:2,:3,:4,:5,:6)'
                 USING v_quad_id,v_xlo,v_ylo,v_xhi,v_yhi,v_new_geometry;
     END LOOP;
     CLOSE v_cursor;
     COMMIT;
   END;

   /** -------------------------------------------------------------------------- **/
  
   Function RegularGrid( p_LL       In MDSYS.SDO_POINT_TYPE,
                         p_UR       In MDSYS.SDO_POINT_TYPE,
                         p_TileSize In MDSYS.SDO_POINT_TYPE,
                         p_srid     In Number Default Null,
                         p_point    in pls_integer default 0)
            Return &&defaultSchema..SPACE_KEY.t_GridSet Pipelined
   Is
     v_half_x number := p_TileSize.x / 2.0;
     v_half_y number := p_TileSize.y / 2.0;
     v_loCol  PLS_Integer;
     v_hiCol  PLS_Integer;
     v_loRow  PLS_Integer;
     v_hiRow  PLS_Integer;
   Begin
     v_loCol := TRUNC( p_LL.X / p_TileSize.X );
     v_hiCol := CEIL( p_UR.X / p_TileSize.X ) - 1;
     v_loRow := TRUNC( p_LL.Y / p_TileSize.Y );
     v_hiRow := CEIL( p_UR.Y / p_TileSize.Y ) - 1;
     <<column_interator>>
     For v_col in v_loCol..v_hiCol Loop
       <<row_iterator>>
       For v_row in v_loRow..v_hiRow Loop
       PIPE ROW (&&defaultSchema..t_Grid(
                 v_col, v_row,
                 MDSYS.SDO_Geometry(2003,
                                    p_srid,
                                    case when p_point = 0 then NULL 
                                         else MDSYS.SDO_Point_Type((v_col * p_TileSize.X) + v_half_x,
                                                                   (v_row * p_TileSize.Y) + V_Half_Y,
                                                                   NULL)
                                     end,
                                    MDSYS.SDO_Elem_Info_Array(1,1003,3),
                                    MDSYS.SDO_Ordinate_Array(v_col * p_TileSize.X,
                                                             v_row * p_TileSize.Y,
                                                             (v_col * p_TileSize.X) + p_TileSize.X,
                                                             (v_row * p_TileSize.Y) + p_TileSize.Y))));
       End Loop row_iterator;
     End Loop col_iterator;
     return;
   End RegularGrid;

   Function RegularGridPoint(p_LL       In MDSYS.SDO_POINT_TYPE,
                             p_UR       In MDSYS.SDO_POINT_TYPE,
                             p_TileSize In MDSYS.SDO_POINT_TYPE,
                             p_srid     In Number Default Null )
            Return &&defaultSchema..SPACE_KEY.t_GridSet Pipelined
   Is
     v_half_x number := p_TileSize.x / 2.0;
     v_half_y number := p_TileSize.y / 2.0;
     v_loCol  PLS_Integer;
     v_hiCol  PLS_Integer;
     v_loRow  PLS_Integer;
     v_hiRow  PLS_Integer;
   Begin
     v_loCol := TRUNC( p_LL.X / p_TileSize.X );
     v_hiCol := CEIL( p_UR.X / p_TileSize.X ) - 1;
     v_loRow := TRUNC( p_LL.Y / p_TileSize.Y );
     v_hiRow := CEIL( p_UR.Y / p_TileSize.Y ) - 1;
     <<column_interator>>
     For v_col in v_loCol..v_hiCol Loop
       <<row_iterator>>
       For v_row in v_loRow..v_hiRow Loop
       PIPE ROW (&&defaultSchema..t_Grid(
                 v_col, v_row,
                 MDSYS.SDO_Geometry(2001,
                                    p_srid,
                                    MDSYS.SDO_Point_Type((v_col * p_TileSize.X) + v_half_x,
                                                         (v_row * p_TileSize.Y) + V_Half_Y,
                                                         NULL),
                                    NULL,NULL)));
       End Loop row_iterator;
     End Loop col_iterator;
     return;
   End RegularGridPoint;

   Function RegularGridXY(p_xmin       in number,
                          p_ymin       in number,
                          p_xmax       in number,
                          p_ymax       in number,
                          p_TileSizeX  in number,
                          p_TileSizeY  in number,
                          p_srid       pls_integer,
                          p_point      in pls_integer Default 0)
   Return &&defaultSchema..SPACE_KEY.t_GridSet pipelined
   As
     v_half_x number := p_TileSizex / 2.0;
     v_half_y number := p_TileSizey / 2.0;
     v_loCol  PLS_Integer;
     v_hiCol  PLS_Integer;
     v_loRow  PLS_Integer;
     v_hiRow  PLS_Integer;
   Begin
     v_loCol := TRUNC( p_xmin / p_TileSizeX );
     v_hiCol := CEIL(  p_xmax / p_TileSizeX ) - 1;
     v_loRow := TRUNC( p_ymin / p_TileSizeY );
     v_hiRow := CEIL(  p_ymax / p_TileSizeY ) - 1;
     <<column_interator>>
     For v_col in v_loCol..v_hiCol Loop
       <<row_iterator>>
       For v_row in v_loRow..v_hiRow Loop
       PIPE ROW (&&defaultSchema..t_Grid(
                 v_col, v_row,
                 MDSYS.SDO_Geometry(2003,
                                    p_srid,
                                    case when p_point = 0 then NULL 
                                         else MDSYS.SDO_Point_Type((v_col * p_TileSizeX) + v_half_x,
                                                                   (v_row * p_TileSizeY) + V_Half_Y,
                                                                   NULL)
                                     end,
                                    MDSYS.SDO_Elem_Info_Array(1,1003,3),
                                    MDSYS.SDO_Ordinate_Array(v_col * p_TileSizeX,
                                                             v_row * p_TileSizeY,
                                                             (v_col * p_TileSizeX) + p_TileSizeX,
                                                             (v_row * p_TileSizeY) + p_TileSizeY))));
       End Loop row_iterator;
     End Loop col_iterator;
     return;
   End RegularGridXY;

   Function RegularGrid( p_geometry In MDSYS.SDO_Geometry,
                         p_TileSize In MDSYS.SDO_Point_Type,
                         p_point    in pls_integer Default 0 )
            Return &&defaultSchema..SPACE_KEY.t_GridSet Pipelined
   Is
     v_half_x                number := p_TileSize.x / 2.0;
     v_half_y                number := p_TileSize.y / 2.0;
     v_loCol                 PLS_Integer;
     v_hiCol                 PLS_Integer;
     v_loRow                 PLS_Integer;
     v_hiRow                 PLS_Integer;
     v_geometry              MDSYS.SDO_GEOMETRY := p_geometry;
     v_elem_info             MDSYS.SDO_ELEM_INFO_ARRAY;
     NOT_MBR_POLYGON         EXCEPTION;
     NOT_OPTIMIZED_RECTANGLE EXCEPTION;
   Begin
     IF ( v_geometry is null ) THEN
        RETURN;
     END IF;
     IF ( v_geometry.get_gtype() != 3 ) THEN
       RAISE NOT_MBR_POLYGON;
     END IF;
     IF ( v_geometry.get_dims() = 3 ) THEN
       v_geometry := &&defaultSchema..geom.to_2D( p_geometry );
     END IF;
     IF ( v_geometry.sdo_elem_info(2) <> 1003 OR v_geometry.sdo_elem_info(3) <> 3 ) THEN
       RAISE NOT_OPTIMIZED_RECTANGLE;
     END IF;
     v_loCol := TRUNC( v_geometry.sdo_ordinates(1) / p_TileSize.X );
     v_hiCol := CEIL( v_geometry.sdo_ordinates(3)  / p_TileSize.X ) - 1;
     v_loRow := TRUNC( v_geometry.sdo_ordinates(2) / p_TileSize.Y );
     v_hiRow := CEIL( v_geometry.sdo_ordinates(4)  / p_TileSize.Y ) - 1;
     <<column_interator>>
     For v_col in v_loCol..v_hiCol Loop
       <<row_iterator>>
       For v_row in v_loRow..v_hiRow Loop
           PIPE ROW (&&defaultSchema..t_Grid(
                     v_col, v_row,
                     MDSYS.SDO_Geometry(2003,
                                        v_geometry.sdo_srid,
                                        case when p_point = 0 then NULL 
                                             else MDSYS.SDO_Point_Type((v_col * p_TileSize.X) + v_half_x,
                                                                       (v_row * p_TileSize.Y) + V_Half_Y,
                                                                       NULL)
                                         end,
                                        MDSYS.SDO_Elem_Info_Array(1,1003,3),
                                        MDSYS.SDO_Ordinate_Array(v_col * p_TileSize.X,
                                                                 v_row * p_TileSize.Y,
                                                                (v_col * p_TileSize.X) + p_TileSize.X,
                                                                (v_row * p_TileSize.Y) + p_TileSize.Y))));
       End Loop row_iterator;
     End Loop col_iterator;
     EXCEPTION
        WHEN NOT_MBR_POLYGON THEN
             raise_application_error(-20100,'Can only pass in a single polyon composed of a single optimized rectangle.',TRUE);
        WHEN NOT_OPTIMIZED_RECTANGLE THEN
             raise_application_error(-20100,'Can only pass in a single polyon composed of a single optimized rectangle.',TRUE);        
   End RegularGrid;

   Function RegularGridPoint(p_geometry In MDSYS.SDO_Geometry,
                             p_TileSize In MDSYS.SDO_Point_Type )
            Return &&defaultSchema..SPACE_KEY.t_GridSet Pipelined
   Is
     v_half_x                number := p_TileSize.x / 2.0;
     v_half_y                number := p_TileSize.y / 2.0;
     v_loCol                 PLS_Integer;
     v_hiCol                 PLS_Integer;
     v_loRow                 PLS_Integer;
     v_hiRow                 PLS_Integer;
     v_geometry              MDSYS.SDO_GEOMETRY := p_geometry;
     v_elem_info             MDSYS.SDO_ELEM_INFO_ARRAY;
     NOT_MBR_POLYGON         EXCEPTION;
     NOT_OPTIMIZED_RECTANGLE EXCEPTION;
   Begin
     IF ( v_geometry is null ) THEN
        RETURN;
     END IF;
     IF ( v_geometry.get_gtype() != 3 ) THEN
       RAISE NOT_MBR_POLYGON;
     END IF;
     IF ( v_geometry.get_dims() = 3 ) THEN
       v_geometry := &&defaultSchema..geom.to_2D( p_geometry );
     END IF;
     IF ( v_geometry.sdo_elem_info(2) <> 1003 OR v_geometry.sdo_elem_info(3) <> 3 ) THEN
       RAISE NOT_OPTIMIZED_RECTANGLE;
     END IF;
     v_loCol := TRUNC( v_geometry.sdo_ordinates(1) / p_TileSize.X );
     v_hiCol := CEIL( v_geometry.sdo_ordinates(3)  / p_TileSize.X ) - 1;
     v_loRow := TRUNC( v_geometry.sdo_ordinates(2) / p_TileSize.Y );
     v_hiRow := CEIL( v_geometry.sdo_ordinates(4)  / p_TileSize.Y ) - 1;
     <<column_interator>>
     For v_col in v_loCol..v_hiCol Loop
       <<row_iterator>>
       For v_row in v_loRow..v_hiRow Loop
           PIPE ROW (&&defaultSchema..t_Grid(
                     v_col, v_row,
                     MDSYS.SDO_Geometry(2001,
                                        v_geometry.sdo_srid,
                                        MDSYS.SDO_Point_Type((v_col * p_TileSize.X) + v_half_x,
                                                             (v_row * p_TileSize.Y) + V_Half_Y,
                                                             NULL),
                                        NULL,NULL)));
       End Loop row_iterator;
     End Loop col_iterator;
     EXCEPTION
        WHEN NOT_MBR_POLYGON THEN
             raise_application_error(-20100,'Can only pass in a single polyon composed of a single optimized rectangle.',TRUE);
        WHEN NOT_OPTIMIZED_RECTANGLE THEN
             raise_application_error(-20100,'Can only pass in a single polyon composed of a single optimized rectangle.',TRUE);        
   End RegularGridPoint;


   Function RegularGrid( p_geometry In MDSYS.SDO_Geometry,
                         p_divisor  In Number,
                         p_point    in pls_integer Default 0 )
            Return &&defaultSchema..SPACE_KEY.t_GridSet Pipelined
   Is
     v_half_x                number;
     v_half_y                number;
     v_width                 Number;
     v_height                Number;
     v_loCol                 PLS_Integer;
     v_hiCol                 PLS_Integer;
     v_loRow                 PLS_Integer;
     v_hiRow                 PLS_Integer;
     v_geometry              MDSYS.SDO_GEOMETRY := p_geometry;
     v_elem_info             MDSYS.SDO_ELEM_INFO_ARRAY;
     v_ordinates             MDSYS.SDO_ORDINATE_ARRAY;
     NOT_MBR_POLYGON         EXCEPTION;
     NOT_OPTIMIZED_RECTANGLE EXCEPTION;
   Begin
     IF ( v_geometry.get_gtype() != 3 ) THEN
       RAISE NOT_MBR_POLYGON;
     END IF;
     IF ( v_geometry.get_dims() = 3 ) THEN
       v_geometry := &&defaultSchema..geom.to_2D( p_geometry );
     END IF;
     v_elem_info := v_geometry.sdo_elem_info;
     IF ( v_elem_info(2) <> 1003 AND v_elem_info(3) <> 3 ) THEN
       RAISE NOT_OPTIMIZED_RECTANGLE;
     END IF;
     v_ordinates := v_geometry.sdo_ordinates;
     v_width  := CEIL( (v_ordinates(3) - v_ordinates(1)) / p_divisor );
     v_height := CEIL( (v_ordinates(4) - v_ordinates(2)) / p_divisor );
     v_half_x := v_width / 2.0;
     v_half_y := v_height / 2.0;
     v_loCol  := TRUNC( v_ordinates(1) / v_width );
     v_hiCol  := CEIL(  v_ordinates(3) / v_width ) - 1;
     v_loRow  := TRUNC( v_ordinates(2) / v_height );
     v_hiRow  := CEIL(  v_ordinates(4) / v_height ) - 1;
     <<column_interator>>
     For v_col in v_loCol..v_hiCol Loop
       <<row_iterator>>
       For v_row in v_loRow..v_hiRow Loop
       PIPE ROW (&&defaultSchema..t_Grid(
                 v_col, v_row,
                 MDSYS.SDO_Geometry(2003,
                                    v_geometry.sdo_srid,
                                    case when p_point = 0 then NULL 
                                         else MDSYS.SDO_Point_Type((v_col * v_width)  + v_half_x,
                                                                   (v_row * v_height) + V_Half_Y,
                                                                   NULL)
                                     end,
                                    MDSYS.SDO_Elem_Info_Array(1,1003,3),
                                    MDSYS.SDO_Ordinate_Array(v_col * v_width,
                                                             v_row * v_height,
                                                             (v_col * v_width) + v_width,
                                                             (v_row * v_height) + v_height))));
       End Loop row_iterator;
     End Loop col_iterator;
   End RegularGrid;

  /** ------------------------------------------------------------------------------------------- **/
  
   -- Compute the coefficients for the plane defined by
   -- points (x1,y1,z1), (x2,y2,z3), (x3,y3,z3)
   Procedure Compute_Plane(x1 In Number,
                           y1 In Number,
                           z1 In Number,
                           x2 In Number,
                           y2 In Number,
                           z2 In Number,
                           x3 In Number,
                           y3 In Number,
                           z3 In Number,
                           a  In Out NoCopy Number,
                           b  In Out NoCopy Number,
                           c  In Out NoCopy Number,
                           d  In Out NoCopy Number)
   Is
     dx12 Number;
     dy12 Number;
     dz12 Number;
     dx32 Number;
     dy32 Number;
     dz32 Number;
   Begin
     dx12 := x1 - x2;
     dy12 := y1 - y2;
     dz12 := z1 - z2;
     dx32 := x3 - x2;
     dy32 := y3 - y2;
     dz32 := z3 - z2;
     -- Compute the coefficients.
     a := dy12*dz32 - dz12*dy32;
     b := dz12*dx32 - dx12*dz32;
     c := dx12*dy32 - dy12*dx32;
     d := -(a*x1 + b*y1 + c*z1);
  End Compute_Plane;

BEGIN
  SetGeom2SDO;
  v_SearchTable  := NULL;
  v_SearchColumn := NULL;
  v_TargetTable  := 'QUAD';
  v_SRID         := 'NULL';
  v_MaxQuadLevel := 40;
END SPACE_KEY;
/
SHOW ERRORS

set serveroutput on size unlimited
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
   v_OK       boolean := true;
   v_obj_name varchar2(30) := 'SPACE_KEY';
BEGIN
   FOR rec IN (select object_name || '.' || object_Type as package_name, status 
                 from user_objects
                where object_name = v_obj_name) LOOP
      IF ( rec.status = 'VALID' ) Then
         dbms_output.put_line('Package ' || USER || '.' || rec.package_name || ' is valid.');
      ELSE
         dbms_output.put_line('Package ' || USER || '.' || rec.package_name || ' is invalid.');
         v_ok := false;
      END IF;
   END LOOP;
   IF ( NOT v_OK ) THEN
      RAISE_APPLICATION_ERROR(-20000,v_obj_name || ' failed to install.');
   END IF;
END;
/
SHOW ERRORS

GRANT EXECUTE ON SPACE_KEY TO PUBLIC;

QUIT;


