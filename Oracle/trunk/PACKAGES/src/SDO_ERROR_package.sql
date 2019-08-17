define defaultSchema='&1'

SET VERIFY OFF;

-- Types specific to this package
--
CREATE OR REPLACE TYPE &&defaultSchema..T_Error AS OBJECT (
   error   varchar2(10),
   element number,
   ring    number,
   id      number,
   geom    mdsys.sdo_geometry 
);
/

GRANT EXECUTE ON &&defaultSchema..T_Error to public;

CREATE OR REPLACE TYPE &&defaultSchema..t_VertexMark AS OBJECT (
   element number,
   ring    number,
   id      number,
   geom    mdsys.sdo_geometry,
   angle   number,
   text    varchar2(4000) 
);
/
grant execute on &&defaultSchema..T_VertexMark to public;

create or replace
PACKAGE SDO_ERROR 
AUTHID CURRENT_USER
IS
   TYPE T_GeometrySet   IS TABLE OF &&defaultSchema..T_Geometry;
   Type T_ElemInfoSet   Is Table Of &&defaultSchema..T_ElemInfo;
   TYPE T_VectorSet     IS TABLE OF &&defaultSchema..T_Vector;
   TYPE T_ErrorSet      IS TABLE OF &&defaultSchema..T_Error;
   TYPE T_VertexMarkSet IS TABLE OF &&defaultSchema..T_VertexMark;
   TYPE T_Strings       IS TABLE OF varchar2(4000);

    /* Options for marking geometries
    */
    c_ID                   CONSTANT PLS_INTEGER := 0;
    c_ID_COORD             CONSTANT PLS_INTEGER := 1;
    c_COORD                CONSTANT PLS_INTEGER := 2;
    c_ELEM                 CONSTANT PLS_INTEGER := 3;
    
    c_DEGREES              CONSTANT PLS_INTEGER := 0;
    c_RADIANS              CONSTANT PLS_INTEGER := 1;

   /** ----------------------------------------------------------------------------------------
    * @function   : getValidateErrors
    * @precis     : Core, or base, function which returns each individual error in a geometry.
    *               Edge errors returns as separate edges and calculated intersection point unless 
    *               p_all only set to 1.
    * @version    : 1.0
    * @usage      : SELECT b.* FROM test a, TABLE(getValidateErrors(a.geom,0.005,null,0) b;
    * @param      : p_geometry    : MDSYS.SDO_GEOMETRY  : An sdo_geometry object.
    * @param      : p_tolerance   : NUMBER      : Oracle sdo_tolerance value eg 0.005 meters for geodetic.
    * @param      : p_geog_digits : pls_integer : Number of significant digits when p_geometry contains long/lat data.
    * @param      : p_srid        : pls_integer : Projected SRID to be used if p_geometry is geodetic for error calculations.
    * @param      : p_context     : varchar2    : Value returned by validate_geometry_with_context. If null, 
    *                                             the sdo_geom function will be run but this function.
    * @return     : p_all         : pls_integer : If 0 then only the error location is returned, otherwise the 
    *                                            element/ring of host geometry containing error is also returned.
    * @history    : Simon Greener - Jun 2011 - Original coding.
    * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License. 
    *               http://creativecommons.org/licenses/by-sa/2.5/au/
    **/
    Function getValidateErrors(p_geometry    in mdsys.sdo_geometry,
                               p_tolerance   in number      default 0.005,
                               p_geog_digits in pls_integer default NULL, 
                               p_srid        in pls_integer default NULL, 
                               p_all         in pls_integer default 0,
                               p_drilldown   in pls_integer default 1,
                               p_context     in varchar2    default null) 
      return &&defaultSchema..SDO_ERROR.T_ErrorSet pipelined;

   /** ----------------------------------------------------------------------------------------
    * @function   : getErrors
    * @precis     : Function which returns each individual error in a geometry as a single geometry.
    *               Edge errors returns as separate edges and calculated intersection point unless 
    *               p_all only set to 1.
    * @version    : 1.0
    * @usage      : SELECT b.* FROM test a, TABLE(getErrors(a.geom,0.005,null,0) b;
    * @param      : p_geometry    : MDSYS.SDO_GEOMETRY  : An sdo_geometry object.
    * @param      : p_tolerance   : NUMBER      : Oracle sdo_tolerance value eg 0.005 meters for geodetic.
    * @param      : p_geog_digits : pls_integer : Number of significant digits when p_geometry contains long/lat data.
    * @param      : p_srid        : pls_integer : Projected SRID to be used if p_geometry is geodetic for error calculations.
    * @return     : p_all         : pls_integer : If 0 then only the error location is returned, otherwise the 
    *                                            element/ring of host geometry containing error is also returned.
    * @history    : Simon Greener - Jun 2011 - Original coding.
    * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License. 
    *               http://creativecommons.org/licenses/by-sa/2.5/au/
   **/
   Function getErrors(p_geometry    in mdsys.sdo_geometry,
                      p_tolerance   in number      default 0.005,
                      p_geog_digits in pls_integer default NULL, 
                      p_srid        in pls_integer default NULL,
                      p_all         in pls_integer default 0,
                      p_drilldown   in pls_integer default 1)
     return &&defaultSchema..SDO_ERROR.T_ErrorSet pipelined; 
  
   /** ----------------------------------------------------------------------------------------
    * @function   : getErrorsAsMulti
    * @precis     : Function which returns all errors in a geometry as a single multipoint or compound geometry.
    *               Edge errors returns as separate edges and calculated intersection points unless 
    *               p_all only set to 1. If p_all set to 1 a multipoint is returned, otherwise 
    *               possibly a compound geometry composed of points and lines.
    * @version    : 1.0
    * @usage      : SELECT getErrorsAsMulti(a.geom,0.005,null,0) FROM test a;
    * @param      : p_geometry    : MDSYS.SDO_GEOMETRY  : An sdo_geometry object.
    * @param      : p_tolerance   : NUMBER      : Oracle sdo_tolerance value eg 0.005 meters for geodetic.
    * @param      : p_geog_digits : pls_integer : Number of significant digits when p_geometry contains long/lat data.
    * @param      : p_srid        : pls_integer : Projected SRID to be used if p_geometry is geodetic for error calculations.
    * @return     : p_all         : pls_integer : If 0 then only the error location is returned, otherwise the 
    *                                            element/ring of host geometry containing error is also returned.
    * @history    : Simon Greener - Jun 2011 - Original coding.
    * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License. 
    *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
   Function getErrorsAsMulti(p_geometry    in mdsys.sdo_geometry,
                             p_tolerance   in number      default 0.005,
                             p_geog_digits in pls_integer default NULL, 
                             p_srid        in pls_integer default NULL,
                             p_all         in pls_integer default 0)
     return mdsys.sdo_geometry deterministic;

   /** ----------------------------------------------------------------------------------------
    * @function   : getError
    * @precis     : Function which returns a the nominated error number as a single geometry.
    *               Edge errors returns as single edge, points as single point.
    * @version    : 1.0
    * @usage      : SELECT getError(a.geom,0.005,null) FROM test a;
    * @param      : p_geometry    : MDSYS.SDO_GEOMETRY  : An sdo_geometry object.
    * @param      : p_tolerance   : NUMBER      : Oracle sdo_tolerance value eg 0.005 meters for geodetic.
    * @param      : p_geog_digits : pls_integer : Number of significant digits when p_geometry contains long/lat data.
    * @param      : p_srid        : pls_integer : Projected SRID to be used if p_geometry is geodetic for error calculations.
    * @history    : Simon Greener - Jun 2011 - Original coding.
    * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License. 
    *               http://creativecommons.org/licenses/by-sa/2.5/au/
   **/
   Function getError(p_geometry     in mdsys.sdo_geometry, 
                     p_error_number in pls_integer,
                     p_tolerance    in number      default 0.005,
                     p_geog_digits  in pls_integer default NULL,
                     p_srid        in pls_integer  default NULL)
    return mdsys.sdo_geometry deterministic;

   /** ----------------------------------------------------------------------------------------
    * @function   : getErrorText
    * @precis     : Function which returns the text that describes each error in a geometry.
    *               All errors are returned.
    * @version    : 1.0
    * @usage      : SELECT b.* FROM test a, TABLE(getErrorText(a.geom,0.005,null,0) b;
    * @param      : p_geometry    : MDSYS.SDO_GEOMETRY  : An sdo_geometry object.
    * @param      : p_tolerance   : NUMBER      : Oracle sdo_tolerance value eg 0.005 meters for geodetic.
    * @history    : Simon Greener - Jun 2011 - Original coding.
    * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License. 
    *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
   Function getErrorText(p_geometry  in mdsys.sdo_geometry,
                         p_tolerance in number DEFAULT 0.005) 
     return &&defaultSchema..SDO_ERROR.T_Strings pipelined;

   /** ----------------------------------------------------------------------------------------
    * @function   : getErrorText
    * @precis     : Function which returns the text that describes a specific error in a geometry.
    *               Validate_Geometry_With_Context only returns the first error it finds so this
    *               function is useless unless the error is 13356 or 13349 as this package implements
    *               custom processing to discover all errors of this type.
    * @version    : 1.0
    * @usage      : SELECT b.* FROM test a, TABLE(getErrorText(a.geom,0.005,null,0) b;
    * @param      : p_geometry     : MDSYS.SDO_GEOMETRY  : An sdo_geometry object.
    * @param      : p_error_number : pls_integer : The position of the error returned by validate_geometry_with_context.
    * @param      : p_tolerance    : NUMBER      : Oracle sdo_tolerance value eg 0.005 meters for geodetic.
    * @history    : Simon Greener - Jun 2011 - Original coding.
    * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License. 
    *               http://creativecommons.org/licenses/by-sa/2.5/au/
   **/
   Function getErrorText(p_geometry     in mdsys.sdo_geometry,
                         p_error_number in pls_integer,
                         p_tolerance    in number default 0.05)
    return varchar2 deterministic;

   /** ----------------------------------------------------------------------------------------
    * @function   : getMarks
    * @precis     : Returns a table that describes each vertex in the provided geometry.
    *               The desciption can be in one of a number of patterns:
    *                 - &&defaultSchema..SDO_ERROR.c_ID       <id>
    *                 - &&defaultSchema..SDO_ERROR.c_ID_COORD <id>{x,y}
    *                 - &&defaultSchema..SDO_ERROR.c_COORD    {x,y}
    *                 - &&defaultSchema..SDO_ERROR.c_ELEM     {element,ring,id}
    *               The textual marks will be rotated algorithmically depending on the vectors 
    *               in/out of a vertex. The returned angle can be either in radians or degrees
    *               depending on the value of the p_degrees parameter.
    *                 - &&defaultSchema..SDO_ERROR.c_DEGREES 
    *                 - &&defaultSchema..SDO_ERROR.c_RADIANS
    * @version    : 1.0
    * @usage      : SELECT b.* FROM test a, TABLE(getMarks(a.geom,1,0,0.005,null) b;
    * @param      : p_geometry     : MDSYS.SDO_GEOMETRY  : An sdo_geometry object.
    * @param      : p_error_number : pls_integer : The position of the error returned by validate_geometry_with_context.
    * @param      : p_geog_digits  : NUMBER      : Oracle sdo_tolerance value eg 0.005 meters for geodetic.
    * @history    : Simon Greener - Jun 2011 - Original coding.
    * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License. 
    *               http://creativecommons.org/licenses/by-sa/2.5/au/
   **/
   Function getMarks(p_geometry    in mdsys.sdo_geometry,
                     p_markType    in pls_integer default 0,
                     p_degrees     in pls_integer default 0,
                     p_tolerance   in number      default 0.005,
                     p_geog_digits in pls_integer default null)
     return &&defaultSchema..SDO_ERROR.T_VertexMarkSet pipelined;

   /** ----------------------------------------------------------------------------------------
    * @function   : fix13348
    * @precis     : Function that corrects an ORA-13348 - polygon boundary is not closed
    * @version    : 1.0
    * @usage      : SELECT b.* FROM test a, TABLE(getMarks(a.geom,1,0,0.005,null) b;
    * @param      : p_geometry    : MDSYS.SDO_GEOMETRY  : An sdo_geometry object.
    * @param      : p_make_equal  : pls_integer : Boolean flag saying whether to make the last
    *                                         vertex equal (1) to the first or whether to insert
    *                                         a nother vertex (0) at the end that is the same as the first.
    * @param      : p_tolerance    : NUMBER : Oracle sdo_tolerance value eg 0.005 meters for geodetic.
    * @param      : p_geog_digits  : pls_integer : if p_geometry contains long/lat data then this
    *                                              parameter should be set to the number of precise 
    *                                              decimal digits of degrees for comparing two ordinates.
    * @history    : Simon Greener - Jun 2011 - Original coding.
    * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License. 
    *               http://creativecommons.org/licenses/by-sa/2.5/au/
   **/
   Function fix13348(p_geometry    in mdsys.sdo_geometry,
                     p_make_equal  in pls_integer default 1,
                     p_tolerance   in number      default 0.005,
                     p_geog_digits in pls_integer default null)
    return mdsys.sdo_geometry deterministic;

   /** ----------------------------------------------------------------------------------------
    * @function   : FindSpikes
    * @precis     : Function that implements a simple "spike" finder.
    * @version    : 1.0
    * @usage      : SELECT b.* FROM test a, TABLE(FindSpikes(a.geom,0.005) b;
    * @param      : p_geometry  : MDSYS.SDO_GEOMETRY : An sdo_geometry line or polygon object.
    * @param      : p_tolerance : NUMBER             : Oracle sdo_tolerance value eg 0.005 meters for geodetic.
    * @history    : Simon Greener - October 2011 - Original coding.
    * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License. 
    *               http://creativecommons.org/licenses/by-sa/2.5/au/
   **/
   Function FindSpikes(p_geometry    in mdsys.sdo_geometry,
                       p_tolerance   in number default 0.005)
     return &&defaultSchema..SDO_ERROR.T_VectorSet pipelined;

  /** UTILITY FUNCTIONS THAT HAVE TO BE PUBLIC **/
  
    /*********************************************************************************
  * @function    : Tokenizer
  * @precis      : Splits any string into its tokens.
  * @description : Supplied a string and a list of separators this function
  *                returns resultant tokens as a pipelined collection.
  * @example     : SELECT t.column_value
  *                  FROM TABLE(tokenizer('The rain in spain, stays mainly on the plain.!',' ,.!') ) t;
  * @param       : p_string. The string to be Tokenized.
  * @param       : p_separators. The characters that are used to split the string.
  * @requires    : t_TokenSet type to be declared.
  * @history     : Pawel Barut, http://pbarut.blogspot.com/2007/03/yet-another-tokenizer-in-oracle.html
  * @history     : Simon Greener - July 2006 - Original coding (extended SQL sourced from a blog on the internet)
  **/
  Function Tokenizer(p_string     In VarChar2,
                     p_separators In VarChar2)
    Return &&defaultSchema..SDO_ERROR.T_Strings Pipelined;

    /** ----------------------------------------------------------------------------------------
    * @function   : GetVector
    * @precis     : Places a geometry''s coordinates into a pipelined vector data structure.
    * @version    : 3.0
    * @description: Loads the coordinates of a linestring, polygon geometry into a
    *               pipelined vector data structure for easy manipulation by other functions
    *               such as geom.SDO_Centroid.
    * @usage      : Function GetVector( p_geometry IN MDSYS.SDO_GEOMETRY,
    *                                   p_dimarray IN MDSYS.SDO_DIM_ARRAY )
    *                        RETURN VectorSetType PIPELINED
    *               eg select *
    *                    from myshapetable a,
    *                         table(&&defaultSchema..linear.GetVector(a.shape));
    * @param      : p_geometry : MDSYS.SDO_GEOMETRY : A geographic shape.
    * @return     : geomVector : VectorSetType      : The vector pipelined.
    * @requires   : Global data types coordRec, vectorRec and VectorSetType
    * @requires   : GF package.
    * @history    : Simon Greener - July 2006 - Original coding from GetVector
    * @history    : Simon Greener - July 2008 - Re-write to be standalone of other packages eg GF
    * @history    : Simon Greener - October 2008 - Removed 2D limits
    * @copyright  : Free for public use
  **/
  Function GetVector(P_Geometry  In Mdsys.Sdo_Geometry,
                     P_Exception In Pls_Integer Default 0)
    Return &&defaultSchema..SDO_ERROR.T_VectorSet Pipelined ;


end SDO_ERROR;
/
show errors

create or replace
PACKAGE BODY SDO_ERROR 
AS
  c_PI                   CONSTANT NUMBER(16,14) := 3.14159265358979;
  c_MAX                  CONSTANT NUMBER        := 1E38;
  c_Min                  CONSTANT NUMBER        := -1E38;
  
  C_I_No_Error           Constant Pls_Integer   := -20001;
  C_S_No_Error           Constant Varchar2(100) := 'No errors exist in geometry';
  C_I_Null_Geometry      Constant  Integer      := -20002;
  C_S_Null_Geometry      Constant Varchar2(100) := 'Input geometry must not be null';
  C_I_Invalid_Mark       Constant Pls_Integer   := -20003;
  C_S_Invalid_Mark       Constant Varchar2(100) := 'Invalid mark option. Only c_ID(' || &&defaultSchema..SDO_ERROR.C_Id || 
                                                                    '), c_ID_COORD(' || &&defaultSchema..SDO_ERROR.C_Id_Coord || 
                                                                       '), c_COORD(' || &&defaultSchema..SDO_ERROR.C_Coord || 
                                                                     ') and c_ELEM(' || &&defaultSchema..SDO_ERROR.c_ELEM || ') allowed.';
  c_i_invalid_degrees    Constant PLS_Integer   := -20004;
  C_S_Invalid_Radians    Constant Varchar2(100) := 'Invalid degrees value option. Only c_DEGREES(' || &&defaultSchema..SDO_ERROR.C_Degrees || ') or c_RADIANS(' || &&defaultSchema..SDO_ERROR.C_Radians || ') allowed.';
  C_I_Arcs_Unsupported   Constant Integer       := -20005;
  C_S_Arcs_Unsupported   Constant Varchar2(100) := 'Geometries with Circular Arcs not supported.';
  c_i_not_polygon        CONSTANT INTEGER       := -20006;
  c_s_not_polygon        CONSTANT VARCHAR2(100) := 'Input geometry is not a polygon (xxx3) or multi-polygon (xxx7)';
  c_i_not_line_poly      CONSTANT INTEGER       := -20007;
  c_s_not_line_poly      CONSTANT VARCHAR2(200) := 'Input geometry is not a linestring (xxx2), polygon (xxx3), multi-linestring (xxx6) or multi-polygon (xxx7)';

  v_bracketStart         varchar2(2) := '{';
  v_bracketEnd           varchar2(2) := '}';

  /* **************************************************************************************************** 
   * Utilities
  ** *****************************************************************************************************/

  Procedure logger(p_text in varchar2,
                   p_cr   in boolean default true)
  As
  Begin
      if ( p_cr ) then
        dbms_output.put_line(p_text);
      else
        dbms_output.put(p_text);
      end if;
  End logger;

  Procedure PrintVector(p_vector in &&defaultSchema..T_Vector,
                        p_cr     in boolean default true)
  As
  Begin
      logger(p_vector.startCoord.x||','||p_vector.startCoord.y||','||p_vector.endCoord.x||','||p_vector.endCoord.y,p_cr);
  End PrintVector;
  
  Function Tokenizer(p_string     In VarChar2,
                     p_separators In VarChar2)
    Return &&defaultSchema..SDO_ERROR.T_Strings pipelined
  As
    v_strs &&defaultSchema..SDO_ERROR.T_Strings;
  Begin
    With sel_string As (Select p_string fullstring From dual)
    Select substr(fullstring, beg+1, end_p-beg-1) token
           Bulk Collect Into v_strs
      From (Select beg, Lead(beg) Over (Order By beg) end_p, fullstring
              From (Select beg, fullstring
                      From (Select Level beg, fullstring
                              From sel_string
                            Connect By Level <= length(fullstring)
                  )
                     Where instr(p_separators,substr(fullstring,beg,1)) >0
                    Union All
                    Select 0, fullstring
                      From sel_string
                    Union All
                    Select length(fullstring)+1, fullstring
                      From sel_string)
           )
     Where end_p Is Not Null
       And end_p > beg + 1;
    For i In v_strs.first..v_strs.last Loop
      PIPE ROW(v_strs(i));
    End Loop;
    RETURN;
  End Tokenizer;

  Function GetNumRings( p_geometry  in mdsys.sdo_geometry,
                        p_ring_type in integer /* 0 = ALL; 1 = OUTER; 2 = INNER */ )
    Return Number
  Is
     v_ring_count number := 0;
     v_ring_type  number := p_ring_type;
     v_elements   number;
     v_etype      pls_integer;
  Begin
     If ( p_geometry is null ) Then
        return 0;
     End If;
     If ( v_ring_type not in (0,1,2) ) Then
        v_ring_type := 0;
     End If;
     v_elements := ( ( p_geometry.sdo_elem_info.COUNT / 3 ) - 1 );
     <<element_extraction>>
     for v_i IN 0 .. v_elements LOOP
       v_etype := p_geometry.sdo_elem_info(v_i * 3 + 2);
       If  ( v_etype in (1003,1005,2003,2005) and 0 = v_ring_type )
        OR ( v_etype in (1003,1005)           and 1 = v_ring_type )
        OR ( v_etype in (2003,2005)           and 2 = v_ring_type ) Then
           v_ring_count := v_ring_count + 1;
       end If;
     end loop element_extraction;
     Return v_ring_count;
  End GetNumRings;

  Function GetNumRings( p_geometry  in mdsys.sdo_geometry )
    Return Number
  Is
  Begin
    Return GetNumRings(p_geometry,0);
  End GetNumRings;

  Function GetNumOuterRings( p_geometry  in mdsys.sdo_geometry )
    Return Number
  Is
  Begin
    Return GetNumRings(p_geometry,1);
  End GetNumOuterRings;

  Function GetNumInnerRings( p_geometry  in mdsys.sdo_geometry )
    Return Number
  Is
  Begin
    Return GetNumRings(p_geometry,2);
  End GetNumInnerRings;

  /** ----------------------------------------------------------------------------------------
  * @function   : hasCircularArcs
  * @precis     : A function that tests whether an sdo_geometry contains circular arcs
  * @version    : 1.0
  * @history    : Simon Greener - Dec 2008 - Original coding.
  * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License. (http://creativecommons.org/licenses/by-sa/2.5/au/)
  **/
  Function hasCircularArcs(p_elem_info in mdsys.sdo_elem_info_array)
     return boolean 
   Is
     v_elements  number;
   Begin
     v_elements := ( ( p_elem_info.COUNT / 3 ) - 1 );
     <<element_extraction>>
     for v_i IN 0 .. v_elements LOOP
        if ( ( /* etype */         p_elem_info(v_i * 3 + 2) = 2 AND
               /* interpretation*/ p_elem_info(v_i * 3 + 3) = 2 )
             OR
             ( /* etype */         p_elem_info(v_i * 3 + 2) in (1003,2003) AND
               /* interpretation*/ p_elem_info(v_i * 3 + 3) IN (2,4) ) ) then
               return true;
        end If;
     end loop element_extraction;
     return false;
   End hasCircularArcs;

  Function GetVector(p_geometry  IN mdsys.sdo_geometry,
                     p_exception IN PLS_INTEGER DEFAULT 0)
    Return &&defaultSchema..SDO_ERROR.T_VectorSet pipelined 
  Is
    v_element        mdsys.sdo_geometry;
    v_ring           mdsys.sdo_geometry;
    v_element_no     pls_integer;
    v_ring_no        pls_integer;
    v_num_elements   pls_integer;
    v_num_rings      pls_integer;
    v_dims           pls_integer;
    v_coordinates    mdsys.vertex_set_type;
    NULL_GEOMETRY    EXCEPTION;
    NOT_CIRCULAR_ARC EXCEPTION;
    
    Function Vertex2Vertex(p_vertex in mdsys.vertex_type,
                           p_id     in pls_integer)
      return &&defaultSchema..T_Vertex deterministic
    Is
    Begin
       if ( p_vertex is null ) then
          return null;
       end if;
       return new &&defaultSchema..T_Vertex(p_vertex.x,p_vertex.y,p_vertex.z,p_vertex.w,p_id);
    End Vertex2Vertex;

  Begin
    If ( p_geometry is NULL ) Then
       If ( p_exception is null or p_exception = 1) then
          raise NULL_GEOMETRY;
       Else
          return;
       End If;
    End If;

    -- No Points
    -- DEBUG  logger(p_geometry.sdo_gtype);
    If ( Mod(p_geometry.sdo_gtype,10) in (1,5) ) Then
      Return;
    End If;

   If ( hasCircularArcs(p_geometry.sdo_elem_info) ) Then
       If ( p_exception is null or p_exception = 1) then
          raise NOT_CIRCULAR_ARC;
       Else
          return;
       End If;
   End If;

   v_num_elements := MDSYS.SDO_UTIL.GETNUMELEM(p_geometry);
   -- DEBUG logger('GetVector=' || v_num_elements);

   <<all_elements>>
   FOR v_element_no IN 1..v_num_elements LOOP
       v_element := MDSYS.SDO_UTIL.EXTRACT(p_geometry,v_element_no,0);
       -- DEBUG logger('v_element extracted ' || case when v_element is null then 'null' else 'not null' end );
       If ( v_element is not null ) Then 
           -- Polygons
           -- Need to check for inner rings
           --
           -- DEBUG logger( v_element.get_gtype());
           If ( v_element.get_gtype() = 3) Then
              -- Process all rings in this single polygon have?
              v_num_rings := GetNumRings(v_element,0);
              -- DEBUG logger('v_num_rings=' || v_num_rings);

              <<All_Rings>>
              FOR v_ring_no IN 1..v_num_rings LOOP
                  v_ring := MDSYS.SDO_UTIL.EXTRACT(p_geometry,v_element_no,v_ring_no);
                  -- Now generate marks
                  If ( v_ring is not null ) Then
                      v_coordinates := mdsys.sdo_util.getVertices(v_ring);
                      If ( v_ring.sdo_elem_info(2) in (1003,2003) And v_coordinates.COUNT = 2 ) Then
                         PIPE ROW( &&defaultSchema..T_Vector(1, 
                                                    Vertex2Vertex(v_coordinates(1),1),
                                                    &&defaultSchema..T_Vertex(v_coordinates(2).x, v_coordinates(1).y,
                                                                     v_coordinates(1).z, v_coordinates(1).w,
                                                                     2) ) );
                         PIPE ROW( &&defaultSchema..T_Vector(2, 
                                                    &&defaultSchema..T_Vertex(v_coordinates(2).x, v_coordinates(1).y,
                                                                     v_coordinates(1).z, v_coordinates(1).w,
                                                                2),
                                                    Vertex2Vertex(v_coordinates(2),3) ) );
                         PIPE ROW( &&defaultSchema..T_Vector(3, 
                                                    Vertex2Vertex(v_coordinates(2),3),
                                                    &&defaultSchema..T_Vertex(v_coordinates(1).x, v_coordinates(2).y,
                                                                     v_coordinates(1).z, v_coordinates(1).w,
                                                                     4) ) );
                         PIPE ROW( &&defaultSchema..T_Vector(4, 
                                                    &&defaultSchema..T_Vertex(v_coordinates(1).x, v_coordinates(2).y,
                                                                     v_coordinates(1).z, v_coordinates(1).w,
                                                                     4),
                                                    Vertex2Vertex(v_coordinates(1),5) ) );
                      Else 
                         FOR v_coord_no IN 1..v_coordinates.COUNT-1 LOOP
                            PIPE ROW(&&defaultSchema..T_Vector(v_coord_no,
                                                      &&defaultSchema..T_Vertex(v_coordinates(v_coord_no).x,
                                                                       v_coordinates(v_coord_no).y,
                                                                       v_coordinates(v_coord_no).z,
                                                                       v_coordinates(v_coord_no).w,
                                                                       v_coord_no),
                                                      &&defaultSchema..T_Vertex(v_coordinates(v_coord_no+1).x,
                                                                       v_coordinates(v_coord_no+1).y,
                                                                       v_coordinates(v_coord_no+1).z,
                                                                       v_coordinates(v_coord_no+1).w,
                                                                       v_coord_no + 1) ) );
                         END LOOP;
                      End If;
                  End If;
              END LOOP All_Rings;
           -- Linestrings
           --
           ElsIf ( v_element.get_gtype() = 2) Then
               v_coordinates := mdsys.sdo_util.getVertices(v_element);
               FOR v_coord_no IN 1..v_coordinates.COUNT-1 LOOP
                   PIPE ROW(&&defaultSchema..T_Vector(v_coord_no,
                                             &&defaultSchema..T_Vertex(v_coordinates(v_coord_no).x,
                                                              v_coordinates(v_coord_no).y,
                                                              v_coordinates(v_coord_no).z,
                                                              v_coordinates(v_coord_no).w,
                                                              v_coord_no),
                                             &&defaultSchema..T_Vertex(v_coordinates(v_coord_no+1).x,
                                                              v_coordinates(v_coord_no+1).y,
                                                              v_coordinates(v_coord_no+1).z,
                                                              v_coordinates(v_coord_no+1).w,
                                                              v_coord_no + 1)) );
               END LOOP;
           End If;
       End If;
   END LOOP all_elements;
   RETURN;
   EXCEPTION
      WHEN NULL_GEOMETRY THEN
        raise_application_error(c_i_null_geometry, c_s_null_geometry,TRUE);
        RETURN;
      WHEN NOT_CIRCULAR_ARC THEN
        raise_application_error(c_i_arcs_unsupported, c_s_arcs_unsupported,TRUE);
        RETURN;
  End GetVector;

  Procedure ADD_Element( p_sdo_elem_info   in out nocopy mdsys.sdo_elem_info_array,
                         p_elem_info_array in mdsys.sdo_elem_info_array,
                         p_ordinates       in mdsys.sdo_ordinate_array)
  IS
    v_i          pls_integer;
    v_end_elem   pls_integer;
    v_additional pls_integer;
    v_ord_count  pls_integer;
  Begin
    if ( p_sdo_elem_info is null 
         or
         p_elem_info_array is null ) Then
         return;
    End If;
    v_ord_count  := CASE WHEN p_ordinates is null THEN 0 ELSE p_ordinates.COUNT END;
    v_end_elem   := p_sdo_elem_info.COUNT;
    v_additional := p_elem_info_array.COUNT;
    p_sdo_elem_info.extend(v_additional);
    FOR v_i IN 1..v_additional LOOP
        if ( MOD(v_i,3) = 1 ) then
           p_sdo_elem_info(v_end_elem + v_i) := v_ord_count + p_Elem_Info_array(v_i);
        else
           p_sdo_elem_info(v_end_elem + v_i) := p_Elem_Info_array(v_i);
        End If;
    END LOOP;
  END ADD_Element;

  Procedure ADD_Ordinates(p_sdo_ordinates in out nocopy mdsys.sdo_ordinate_array,
                          p_ordinates     in mdsys.sdo_ordinate_array)
  IS
    v_i          pls_integer;
    v_start      pls_integer;
    v_additional pls_integer;
  Begin
    if ( p_sdo_ordinates is null 
         or
         p_ordinates is null ) Then
         return;
    End If;
    v_start      := p_sdo_ordinates.COUNT;
    v_additional := p_ordinates.COUNT;
    p_sdo_ordinates.extend(v_additional);
    FOR v_i IN 1..v_additional LOOP
        p_sdo_ordinates(v_start + v_i) := p_ordinates(v_i);
    END LOOP;
  END ADD_Ordinates;

  PROCEDURE ADD_Coordinate( p_ordinates  in out nocopy mdsys.sdo_ordinate_array,
                            p_dim        in number,
                            p_x_coord    in number,
                            p_y_coord    in number,
                            p_z_coord    in number,
                            p_m_coord    in number,
                            p_measured   in boolean := false,
                            p_duplicates in boolean := false)
    IS
      Function Duplicate
        Return Boolean
      Is
      Begin
        Return case when p_ordinates is null or p_ordinates.count = 0
                    then False
                    Else case p_dim
                              when 2
                              then ( p_ordinates(p_ordinates.COUNT)   = p_y_coord
                                     AND
                                     p_ordinates(p_ordinates.COUNT-1) = p_x_coord )
                              when 3
                              then ( p_ordinates(p_ordinates.COUNT)   =  case when p_measured then p_m_coord else p_z_coord end
                                     AND
                                     p_ordinates(p_ordinates.COUNT-1) = p_y_coord
                                     AND
                                     p_ordinates(p_ordinates.COUNT-2) = p_x_coord )
                              when 4
                              then ( p_ordinates(p_ordinates.COUNT)   = p_m_coord
                                     AND
                                     p_ordinates(p_ordinates.COUNT-1) = p_z_coord
                                     AND
                                     p_ordinates(p_ordinates.COUNT-2) = p_y_coord
                                     AND
                                     p_ordinates(p_ordinates.COUNT-3) = p_x_coord )
                          end
                  End;
      End Duplicate;

  Begin
    If ( p_ordinates is null ) Then
       p_ordinates := new mdsys.sdo_ordinate_array(null);
       p_ordinates.DELETE;
    End If;
    If ( p_duplicates or Not Duplicate() ) Then
      IF ( p_dim >= 2 ) Then
        p_ordinates.extend(2);
        p_ordinates(p_ordinates.count-1) := p_x_coord;
        p_ordinates(p_ordinates.count  ) := p_y_coord;
      END IF;
      IF ( p_dim >= 3 ) Then
        p_ordinates.extend(1);
        p_ordinates(p_ordinates.count)   := case when p_dim = 3 And p_measured
                                                 then p_m_coord
                                                 else p_z_coord
                                            end;
      END IF;
      IF ( p_dim = 4 ) Then
        p_ordinates.extend(1);
        p_ordinates(p_ordinates.count)   := p_m_coord;
      END IF;
    End If;
  END ADD_Coordinate;

  PROCEDURE ADD_Coordinate( p_ordinates  in out nocopy mdsys.sdo_ordinate_array,
                            p_dim        in number,
                            p_coord      in mdsys.sdo_point_type,
                            p_measured   in boolean := false,
                            p_duplicates in boolean := false)
  Is
  Begin
    ADD_Coordinate( p_ordinates, p_dim, p_coord.x, p_coord.y, p_coord.z, NULL, p_measured, p_duplicates);
  END Add_Coordinate;

  Function hasRectangles( p_elem_info in mdsys.sdo_elem_info_array  )
    Return Pls_Integer
  Is
     v_rectangle_count number := 0;
     v_etype           pls_integer;
     v_interpretation  pls_integer;
     v_elements        pls_integer;
  Begin
     If ( p_elem_info is null ) Then
        return 0;
     End If;
     v_elements := ( ( p_elem_info.COUNT / 3 ) - 1 );
     <<element_extraction>>
     for v_i IN 0 .. v_elements LOOP
       v_etype := p_elem_info(v_i * 3 + 2);
       v_interpretation := p_elem_info(v_i * 3 + 3);
       If  ( v_etype in (1003,2003) AND v_interpretation = 3  ) Then
           v_rectangle_count := v_rectangle_count + 1;
       end If;
     end loop element_extraction;
     Return v_rectangle_Count;
  End hasRectangles;

  Function Rectangle2Polygon(p_geometry in mdsys.sdo_geometry)
    return mdsys.sdo_geometry deterministic
  As
    v_dims      pls_integer;
    v_ordinates mdsys.sdo_ordinate_array := new mdsys.sdo_ordinate_array(null);
    v_vertices  mdsys.vertex_set_type;
    v_etype     pls_integer;
    v_start_coord mdsys.vertex_type;
    v_end_coord   mdsys.vertex_type;
  Begin
      v_ordinates.DELETE;
      v_dims        := p_geometry.get_dims();
      v_etype       := p_geometry.sdo_elem_info(2);
      v_vertices    := sdo_util.getVertices(p_geometry);
      v_start_coord := v_vertices(1);
      v_end_coord   := v_vertices(2);
      -- First coordinate
      ADD_Coordinate( v_ordinates, v_dims, v_start_coord.x, v_start_coord.y, v_start_coord.z, v_start_coord.w );
      -- Second coordinate
      If ( v_etype = 1003 ) Then
        ADD_Coordinate(v_ordinates,v_dims,v_end_coord.x,v_start_coord.y,(v_start_coord.z + v_end_coord.z) /2, v_start_coord.w);
      Else
        ADD_Coordinate(v_ordinates,v_dims,v_start_coord.x,v_end_coord.y,(v_start_coord.z + v_end_coord.z) /2,
            (v_end_coord.w - v_start_coord.w) * ((v_end_coord.x - v_start_coord.x) /
           ((v_end_coord.x - v_start_coord.x) + (v_end_coord.y - v_start_coord.y)) ));
      End If;
      -- 3rd or middle coordinate
      ADD_Coordinate(v_ordinates,v_dims,v_end_coord.x,v_end_coord.y,v_end_coord.z,v_end_coord.w);
      -- 4th coordinate
      If ( v_etype = 1003 ) Then
        ADD_Coordinate(v_ordinates,v_dims,v_start_coord.x,v_end_coord.y,(v_start_coord.z + v_end_coord.z) /2,v_start_coord.w);
      Else
        Add_Coordinate(v_ordinates,v_dims,v_end_coord.x,v_start_coord.y,(v_start_coord.z + v_end_coord.z) /2,
            (v_end_coord.w - v_start_coord.w) * ((v_end_coord.x - v_start_coord.x) /
           ((v_end_coord.x - v_start_coord.x) + (v_end_coord.y - v_start_coord.y)) ));
      End If;
      -- Last coordinate
      ADD_Coordinate(v_ordinates,v_dims,v_start_coord.x,v_start_coord.y,v_start_coord.z,v_start_coord.w);
      return mdsys.sdo_geometry(p_geometry.sdo_gtype,p_geometry.sdo_srid,null,mdsys.sdo_elem_info_array(1,v_etype,1),v_ordinates);
  End Rectangle2Polygon;
    
  Function isMeasured( p_gtype in number )
    return boolean
  is
  Begin
    Return CASE WHEN MOD(trunc(p_gtype/100),10) = 0
                THEN False
                ELSE True
             END;
  End isMeasured;

  Function isOrientedPoint( p_elem_info in mdsys.sdo_elem_info_array)
    return boolean
  is
  Begin
    /* Single Oriented Point
    // Sdo_Elem_Info = (1,1,1, 3,1,0), SDO_ORDINATE_ARRAY(12,14, 0.3,0.2)));
    // The Final 1,0 In 3,1,0 Indicates That This Is An Oriented Point.
    //
    // Multi Oriented Point
    // Sdo_Elem_Info_Array(1,1,1, 3,1,0, 5,1,1, 7,1,0), Sdo_Ordinate_Array(12,14, 0.3,0.2, 12,10, -1,-1)));
    */
    If ( P_Elem_Info Is Null ) Then
       Return False;
    Elsif ( P_Elem_Info.Count >= 6 ) Then
       Return ( P_Elem_Info(2) = 1 ) /* Point */          And
              ( P_Elem_Info(3) = 1 ) /* Singlge Point */  And
              ( P_Elem_Info(5) = 1 ) /* Oriented Point */ And
              ( P_Elem_Info(6) = 0 );
    Else
       Return false;
    End If;
  End isOrientedPoint;

  Function GetDimensions( p_gtype in number )
    return integer
  Is
  Begin
    return TRUNC(p_gtype/1000,0);
  End GetDimensions;

  Function GetElemInfo(
    p_geometry in mdsys.sdo_geometry)
    Return &&defaultSchema..SDO_ERROR.T_ElemInfoSet pipelined
  Is
    v_elements  number;
  Begin
    If ( p_geometry is not null ) Then
      v_elements := ( ( p_geometry.sdo_elem_info.COUNT / 3 ) - 1 );
      <<element_extraction>>
      for v_i IN 0 .. v_elements LOOP
         PIPE ROW ( &&defaultSchema..T_ElemInfo(
                      p_geometry.sdo_elem_info(v_i * 3 + 1),
                      p_geometry.sdo_elem_info(v_i * 3 + 2),
                      p_geometry.sdo_elem_info(v_i * 3 + 3) ) );
        end loop element_extraction;
    End If;
    Return;
  End GetElemInfo;

  Function GetNumElem( p_geometry IN mdsys.sdo_geometry )
    return number
  Is
    TYPE T_elemCursor IS REF CURSOR;
    c_elems                T_elemCursor;
    v_num_elems            number := 0;
    v_rin                  number := 0;
    v_compound_element     boolean := FALSE;
    v_compound_element_end number := 0;
  Begin
    If ( p_geometry is not null ) Then
      If ( p_geometry.sdo_elem_info is not null ) Then
        If ( DBMS_DB_VERSION.VERSION < 10 ) Then
          -- Get count of all elements
          OPEN c_elems FOR
            'SELECT rownum as rin,
                    case when i.etype in (4,5,1005,2005) then i.interpretation + rownum else 0 end as celem
               FROM (SELECT rownum as id,
                            e.interpretation,
                            e.etype,
                            e.offset
                      FROM TABLE(&&defaultSchema..SDO_ERROR.GetElemInfo(:1)) e
                         ) i'
            USING p_geometry;
          LOOP
            FETCH c_elems INTO v_rin, v_compound_element_end;
            EXIT WHEN c_elems%NOTFOUND;
            If ( v_compound_element_end <> 0 ) Then
              v_compound_element := TRUE;
              v_num_elems := v_num_elems + 1;
            Else
              If ( v_compound_element ) Then
                 If ( v_compound_element_end = v_rin ) Then
                    v_compound_element := FALSE;
                 End If;
              Else
                 v_num_elems := v_num_elems + 1;
              End If;
            End If;
          END LOOP;
        Else
          EXECUTE IMMEDIATE 'SELECT mdsys.sdo_util.GetNumElem(:1) FROM DUAL' INTO v_num_elems USING p_geometry ;
        END IF;
      End If;
    End If;
    RETURN v_num_elems;
  End GetNumElem;

  Procedure FindLineIntersection(
    x11       in number,        y11       in number,
    x12       in number,        y12       in number,
    x21       in number,        y21       in number,
    x22       in number,        y22       in number,
    inter_x  out nocopy number, inter_y  out nocopy number,
    inter_x1 out nocopy number, inter_y1 out nocopy number,
    inter_x2 out nocopy number, inter_y2 out nocopy number )
  IS
      X1          NUMBER;
      Y1          NUMBER;
      dx2         NUMBER;
      dy2         NUMBER;
      t1          NUMBER;
      t2          NUMBER;
      denominator NUMBER;
  BEGIN
    -- Get the segments' parameters.
    X1 := x12 - x11;
    Y1 := y12 - y11;
    dx2 := x22 - x21;
    dy2 := y22 - y21;

    -- Solve for t1 and t2.
    denominator := (Y1 * dx2 - X1 * dy2);
    IF ( denominator = 0 ) Then
      -- The lines are parallel.
      inter_x  := c_Max;
      inter_y  := c_Max;
      inter_x1 := c_Max;
      inter_y1 := c_Max;
      inter_x2 := c_Max;
      inter_y2 := c_Max;
      RETURN;
    End If;
    t1 := ((x11 - x21) * dy2 + (y21 - y11) * dx2) /  denominator;
    t2 := ((x21 - x11) * Y1  + (y11 - y21) * X1)  / -denominator;

    -- Find the point of intersection.
    inter_x := x11 + X1 * t1;
    inter_y := y11 + Y1 * t1;

    -- Find the closest points on the segments.
    If t1 < 0 Then
      t1 := 0;
    ElsIf t1 > 1 Then
      t1 := 1;
    End If;
    If t2 < 0 Then
      t2 := 0;
    ElsIf t2 > 1 Then
      t2 := 1;
    End If;
    inter_x1 := x11 + X1 * t1;
    inter_y1 := y11 + Y1 * t1;
    inter_x2 := x21 + dx2 * t2;
    inter_y2 := y21 + dy2 * t2;
  END FindLineIntersection;

  Procedure FindLineIntersection(
    p_vector1 in t_vector,      p_vector2 in t_vector,
    inter_x  out nocopy number, inter_y  out nocopy number,
    inter_x1 out nocopy number, inter_y1 out nocopy number,
    inter_x2 out nocopy number, inter_y2 out nocopy number )
  IS
  BEGIN
      FindLineIntersection(
          p_vector1.startCoord.x, p_vector1.startCoord.y, 
          p_vector1.endCoord.x,   p_vector1.endCoord.y,
          p_vector2.startCoord.x, p_vector2.startCoord.y, 
          p_vector2.endCoord.x,   p_vector2.endCoord.y, 
          inter_x,  inter_y,
          inter_x1, inter_y1,
          inter_x2, inter_y2);
  END FindLineIntersection;
  
  /* **************************** COGO FUNCTIONS *************************** */

  Function degrees(p_radians in number)
    return number
  Is
  Begin
    return p_radians * (180.0 / c_PI);
  End degrees;

  Function radians(p_degrees in number)
    Return number
  Is
  Begin
    Return p_degrees * (c_PI / 180.0);
  End radians;

  Function Bearing(dE1 in number, dN1 in number,
                   dE2 in number, dN2 in number)
    Return Number
  IS
      dBearing Number;
      dEast    Number;
      dNorth   Number;
  BEGIN
      If (   dE1 Is Null or dN1 Is Null
          or dE2 Is Null or dE1 Is null ) 
      Then
         Return Null;
      End If;
      If ( (dE1 = dE2) And (dN1 = dN2) ) Then
         Return Null;
      End If;
      dEast  := dE2 - dE1;
      dNorth := dN2 - dN1;
      If ( dEast = 0 ) Then
          If ( dNorth < 0 ) Then
              dBearing := c_PI;
          Else
              dBearing := 0;
          End If;
      Else
          dBearing := -aTan(dNorth / dEast) + c_PI / 2;
      End If;
      If ( dEast < 0 ) Then
          dBearing := dBearing + c_PI;
      End If;
      Return dBearing;
  End Bearing;

  Function Bearing(startCoord in mdsys.sdo_point_type,
                     endCoord in mdsys.sdo_point_type)
  Return Number
  IS
  Begin
    Return Bearing( startCoord.X, startCoord.Y, endCoord.X, endCoord.Y );
  End Bearing;

  Function Bearing(startCoord in mdsys.vertex_type,
                     endCoord in mdsys.vertex_type)
  Return Number
  IS
  Begin
    Return Bearing( startCoord.X, startCoord.Y, endCoord.X, endCoord.Y );
  End Bearing;


  /* **************************************************************************************************** */

  /**
  * ******************************* Error functions ****************************
  * Examples: [Element <>] 
              [Element <>] [Coordinate <>]
              [Element <>] [Coordinate <>][Ring <>]
              [Element <>] [Ring <>]
              [Element <>] [Ring <>][Edge <>] [Element <>] [Ring <>][Edge <>]
              [Element <>] [Ring <>][Edge <>][Edge <>]
              [Element <>] [Rings , ][Edge <> in ring <>][Edge <> in ring <>]
  **/
 Function getValidateErrors(p_geometry    in mdsys.sdo_geometry,
                            p_tolerance   in number      default 0.005,
                            p_geog_digits in pls_integer default NULL, 
                            p_srid        in pls_integer default NULL,
                            p_all         in pls_integer default 0,
                            p_drilldown   in pls_integer default 1,
                            p_context     in varchar2    default null)
    return &&defaultSchema..SDO_ERROR.T_ErrorSet pipelined 
  AS
      v_validate   varchar2(10);
      v_round      pls_integer := case when p_geog_digits is not null 
                                       then p_geog_digits
                                       else case when p_tolerance is null
                                                 then 3
                                                 else round(log(10,(1/p_tolerance)/2))
                                             end
                                   end;
      v_all        boolean := p_all <> 0;
      v_point      mdsys.sdo_geometry;
      v_geom       mdsys.sdo_geometry;
      v_element    mdsys.sdo_geometry;
      V_Ring       Mdsys.Sdo_Geometry;
      v_edge       mdsys.sdo_geometry;
      V_Prev_Edge  Mdsys.Sdo_Geometry;
      v_vector     &&defaultSchema..t_vector;
      v_vectors    &&defaultSchema..SDO_ERROR.T_VectorSet;
      v_vector_max pls_integer;
      v_vertices   MDSYS.VERTEX_SET_TYPE;
      v_part       mdsys.sdo_geometry;
      v_row        PLS_INTEGER;
      V_Validation Varchar2(20000);
      v_error      varchar2(100);
      
      V_Dims       Pls_Integer;
      V_Gtype_P    Pls_Integer;
      V_Gtype_l    Pls_Integer;
      v_vertex     PLS_INTEGER;
      v_rings      PLS_INTEGER;
      v_elements   PLS_INTEGER;
      v_element_no PLS_INTEGER;
      v_ring_no    PLS_INTEGER;
      v_edge_no    PLS_INTEGER;
      v_z          NUMBER;
      
      Function FindPoint(p_vector1     &&defaultSchema..T_Vector,
                         p_vector2     &&defaultSchema..T_Vector,
                         p_tolerance   number,
                         p_geog_digits pls_integer,
                         p_pt_gtype    pls_integer,
                         p_srid        pls_integer)
        return mdsys.sdo_geometry
      Is
         v_round      pls_integer := case when p_geog_digits is not null 
                                         then p_geog_digits
                                         else case when p_tolerance is null
                                                   then 3
                                                   else round(log(10,(1/p_tolerance)/2))
                                               end
                                     end;
        v_validate   varchar2(10);
        v_vector1    &&defaultSchema..t_vector := p_vector1;
        v_vector2    &&defaultSchema..t_vector := p_vector2;
        v_geom       mdsys.sdo_geometry;
        v_geom1      mdsys.sdo_geometry;
        v_geom2      mdsys.sdo_geometry;
        v_inter_x    number;
        v_inter_y    number;
        v_inter_x1   number;
        v_inter_y1   number;
        v_inter_x2   number;
        v_inter_y2   number;
      Begin
-- DEBUG logger(case when v_vector1 is null then 'NULL1' else 'NOT NULL1' end);
-- DEBUG logger(case when v_vector2 is null then 'NULL2' else 'NOT NULL2' end);
          v_validate := 'TOUCH';
          if ( p_geog_digits IS NOT NULL) then
            v_geom1 := sdo_geometry(2002,p_srid,null,
                                      sdo_elem_info_array(1,2,1),
                                      sdo_ordinate_array(p_vector1.startCoord.x, p_vector1.startCoord.y, 
                                                         p_vector1.endCoord.x,   p_vector1.endCoord.y));
            v_geom2 := sdo_geometry(2002,p_srid,null,
                                      sdo_elem_info_array(1,2,1),
                                      sdo_ordinate_array(p_vector2.startCoord.x, p_vector2.startCoord.y, 
                                                         p_vector2.endCoord.x,   p_vector2.endCoord.y));
            v_validate := substr(mdsys.sdo_geom.relate(v_geom1,'DETERMINE',v_geom2,p_tolerance),1,10);
-- DEBUG logger(v_validate);
            If ( v_validate <> 'DISJOINT' And p_srid is not null ) Then
               -- Calculate new vector ordinates by projecting into a suitable UTM Zone
               v_geom := mdsys.sdo_cs.transform(v_geom1,p_srid);
               v_vector1.startCoord.x := v_geom.sdo_ordinates(1);
               v_vector1.startCoord.y := v_geom.sdo_ordinates(2);
               v_vector1.endCoord.x   := v_geom.sdo_ordinates(3);
               v_vector1.endCoord.y   := v_geom.sdo_ordinates(4);
               v_geom := mdsys.sdo_cs.transform(v_geom2,p_srid);
               v_vector2.startCoord.x := v_geom.sdo_ordinates(1);
               v_vector2.startCoord.y := v_geom.sdo_ordinates(2);
               v_vector2.endCoord.x   := v_geom.sdo_ordinates(3);
               v_vector2.endCoord.y   := v_geom.sdo_ordinates(4);
-- DEBUG logger(substr(sdo_geom.relate(sdo_geometry(2002,p_srid,null,
-- DEBUG                                       sdo_elem_info_array(1,2,1),
-- DEBUG                                       sdo_ordinate_array(v_vector1.startCoord.x, v_vector1.startCoord.y, 
-- DEBUG                                                          v_vector1.endCoord.x,   v_vector1.endCoord.y)),
-- DEBUG                       'DETERMINE',
-- DEBUG                       sdo_geometry(2002,p_srid,null,
-- DEBUG                                       sdo_elem_info_array(1,2,1),
-- DEBUG                                       sdo_ordinate_array(v_vector2.startCoord.x, v_vector2.startCoord.y, 
-- DEBUG                                                          v_vector2.endCoord.x,   v_vector2.endCoord.y)),
-- DEBUG                       p_tolerance),1,10));
            End If;
         End If;
         if ( v_validate <> 'DISJOINT' ) Then
-- DEBUG logger('FindLineIntersection');
            -- Find actual intersection
            --
            FindLineIntersection( v_vector1,  v_vector2,
                                  v_inter_x,  v_inter_y,
                                  v_inter_x1, v_inter_y1,
                                  v_inter_x2, v_inter_y2 );
             -- When all three returned points are the same (and not c_Max) we have an actual intersection
             If ( round(v_inter_x,v_round) <> c_Max ) Then
                If ( round(v_inter_x,v_round) = round(v_inter_x1,v_round)
                 and round(v_inter_y,v_round) = round(v_inter_y1,v_round)
                 and round(v_inter_x,v_round) = round(v_inter_x2,v_round)
                 and round(v_inter_y,v_round) = round(v_inter_y2,v_round)
                  or p_geog_digits IS NOT NULL ) THEN 
-- DEBUG logger('Intersection point found or p_geog_digits is not null');
-- DEBUG logger(case when v_inter_x is null then 'null inter x' else 'valid inter x' end);
-- DEBUG logger(case when v_inter_y is null then 'null inter y' else 'valid inter y' end);
                    If ( p_geog_digits IS NOT NULL) then
-- DEBUG logger('returning projected');
                       Return mdsys.sdo_cs.transform(Mdsys.Sdo_Geometry(p_pt_gtype,28355,Mdsys.Sdo_Point_Type(round(v_inter_x,v_round),round(v_inter_y,v_round),null),Null,Null),p_srid);
                    Else
-- DEBUG logger('returning unprojected');
                       Return Mdsys.Sdo_Geometry(p_pt_gtype,P_Srid,Mdsys.Sdo_Point_Type(round(v_inter_x,v_round),round(v_inter_y,v_round),null),Null,Null);
                    End If;
-- DEBUG if (i between 5005 and 5015) then logger('NO'); end if;
                End If;
             End If; -- round(v_inter_x,v_round) <> c_Max ) Then
          End If; -- v_validate <> 'DISJOINT'
          Return NUll;
      End FindPoint;

  Begin
      if ( p_geometry is null ) then
         Return;
      end if;

      if ( p_tolerance is null ) then
         Return;
      end if;

      If ( p_geometry.get_gtype() not in (2,3) ) Then
         return;
      end If;
      
      v_dims := P_Geometry.Get_Dims();
      V_Gtype_P := V_Dims * 1000 + 1;
      V_Gtype_L := V_Dims * 1000 + 2;

      v_validation := p_context;      
      If ( p_context is null ) Then
          v_validation := mdsys.sdo_geom.validate_geometry_with_context(p_geometry,p_tolerance);
      End If;
-- DEBUG logger('getValidateErrors: ' || v_validation || ' tol ' || p_tolerance || ' Rings= ' || getNumRings(p_geometry));
      If ( v_validation is null Or REGEXP_LIKE(v_validation, '^[0-9 ]+$', 'i') or v_validation in ('TRUE','NULL') ) then
          Return;
      End If;
      v_error := substr(v_validation,1,5);

      -- Handle 13356 Duplicate Vertices separately
      --
      If ( (v_error = '13356') And (p_drilldown > 0) ) Then
          V_Gtype_P := V_Dims * 1000 + 1;
          V_Gtype_L := V_Dims * 1000 + 2;
          -- Process looking for vectors with zero length
          Select &&defaultSchema..T_Vector(v.id,V.Startcoord,V.Endcoord) as vector
            Bulk Collect Into V_Vectors 
            From Table(&&defaultSchema..SDO_ERROR.GetVector(P_Geometry)) V
           Where Mdsys.Sdo_Geom.Sdo_Distance(
                                  Mdsys.Sdo_Geometry(V_Gtype_P,P_Geometry.Sdo_Srid,Mdsys.Sdo_Point_Type(V.Startcoord.X,V.Startcoord.Y,V.Startcoord.Z),Null,Null),
                                  Mdsys.Sdo_Geometry(V_Gtype_P,P_Geometry.Sdo_Srid,Mdsys.Sdo_Point_Type(V.Endcoord.X,V.Endcoord.Y,V.Endcoord.Z),Null,Null),
                                  p_tolerance)  = 0.0;
          If ( V_Vectors Is Null Or V_Vectors.Count = 0 ) Then
              Return;
          Else
              If ( V_Dims = 2 Or ( V_Dims = 3 And ( Not Ismeasured(P_Geometry.Sdo_GType)) ) ) Then
                  For I In V_Vectors.First..V_Vectors.Last Loop
                      Pipe Row (&&defaultSchema..T_Error(v_error,1,0,V_Vectors(i).id,Mdsys.Sdo_Geometry(V_Gtype_P,P_Geometry.Sdo_Srid,Mdsys.Sdo_Point_Type(v_vectors(i).Startcoord.X,v_vectors(i).Startcoord.Y,v_vectors(i).Startcoord.Z),Null,Null)));
                  End Loop;
              Elsif ( V_Dims = 3 And IsMeasured(P_Geometry.SDO_GTYPE) ) Then
                  For I In V_Vectors.First..V_Vectors.Last Loop
                      Pipe Row (&&defaultSchema..T_Error(v_error,1,0,V_Vectors(i).id,Mdsys.Sdo_Geometry(V_Gtype_P,P_Geometry.Sdo_Srid,NULL,Mdsys.Sdo_Elem_Info_Array(1,1,1),Mdsys.Sdo_Ordinate_array(v_vectors(i).Startcoord.X,v_vectors(i).Startcoord.Y,v_vectors(i).Startcoord.w))));
                  End Loop;
              Else
                  For I In V_Vectors.First..V_Vectors.Last Loop
                      Pipe Row (&&defaultSchema..T_Error(v_error,1,0,V_Vectors(i).id,Mdsys.Sdo_Geometry(V_Gtype_P,P_Geometry.Sdo_Srid,NULL,Mdsys.Sdo_Elem_Info_Array(1,1,1),Mdsys.Sdo_Ordinate_array(v_vectors(i).Startcoord.X,v_vectors(i).Startcoord.Y,v_vectors(i).Startcoord.Z,v_vectors(i).Startcoord.w))));
                  End Loop;
              End If;
              return;
          End If;
      Else
          v_row := 1;
          v_rings := GetNumRings(v_element);
          FOR rec IN (SELECT b.token_id,
                             b.token                                            as token,
                             TRIM(UPPER(SUBSTR(b.token,1, INSTR(b.token,' ')))) as firstToken,
                             TRIM(UPPER(LAG(SUBSTR(b.token,1, INSTR(b.token,' ')),1) 
                                        OVER (ORDER BY b.token_id)))            as prevToken, 
                             TRIM(UPPER(LEAD(SUBSTR(b.token,1, INSTR(b.token,' ')),1) 
                                        OVER (ORDER BY b.token_id)))            as nextToken, 
                             TO_NUMBER(REGEXP_SUBSTR(b.token,'[0-9]+',1,1))     as firstPosition,
                             TO_NUMBER(REGEXP_SUBSTR(LAG(b.token,1) OVER (ORDER BY b.token_id),'[0-9]+',1,1)) as prevFirstPosition,
                             TRIM(REGEXP_REPLACE(
                                REGEXP_SUBSTR(b.token,
                                             '[,]|>[ ,a-z0-9]+<',1,1),
                                             '(> )|( <)',''))                   as SecondToken,
                             TO_NUMBER(REGEXP_SUBSTR(b.token,'[0-9]+',1,2))     as SecondPosition
                        FROM (SELECT rownum as token_id, 
                                     a.COLUMN_VALUE as token
                                FROM TABLE(&&defaultSchema..SDO_ERROR.Tokenizer(v_validation,'[]')) a
                             ) b
                       WHERE TRIM(b.token) is not null
                         AND UPPER(SUBSTR(b.token,1, INSTR(b.token,' '))) NOT LIKE 'RINGS%'  /* Not needed as in Edge <> in ring <> token that follows */
                         AND NOT REGEXP_LIKE(b.token, '^[0-9 ]+$', 'i') 
                       ORDER BY b.token_id ) LOOP
              IF ( rec.firstToken = 'ELEMENT' ) THEN
                    -- Explode to get multipart indicated by firstPosition
                    -- 13356 [Element <1>] [Coordinate <10>][Ring <1>]
                    v_element_no := CASE WHEN rec.firstPosition = 0 THEN 1 ELSE rec.firstPosition END;
                    v_element := mdsys.sdo_util.Extract(p_geometry,v_element_no,0);
                    If ( rec.nextToken is not null or rec.nextToken = 'Coordinate' ) THEN
                        If ( v_element is not null ) Then
                            v_vertices := mdsys.sdo_util.getVertices(v_element);
                        Else
                            v_vertices := mdsys.sdo_util.getVertices(p_geometry);
                        End If;
                        if ( v_all ) Then
                            PIPE ROW ( &&defaultSchema..T_Error(v_error,v_element_no,0,0,v_element ) );
                        End If;
                    End If;
              ELSIF ( rec.firstToken = 'RING' ) THEN
                   v_ring_no := CASE WHEN rec.SecondToken = 'RING' THEN rec.SecondPosition ELSE 1 END;
                   v_ring := mdsys.sdo_util.Extract(p_geometry,v_element_no,v_ring_no);
                   If ( v_ring is not null ) Then
                      v_vertices := mdsys.sdo_util.getVertices(v_ring);
                      if ( v_all and v_rings > 0 ) Then -- If polygon has only one ring then it is the element
                          PIPE ROW ( &&defaultSchema..T_Error(v_error,v_element_no,v_ring_no,0,v_ring ) );
                      End If;
                      -- eg 13356 [Element <1>] [Coordinate <10>][Ring <1>] <-- Polygons only
                      If ( rec.prevToken = 'COORDINATE' ) THEN
                          v_vertex := CASE WHEN rec.prevFirstPosition = 0 THEN 1 ELSE rec.firstPosition END;
                          v_z      := CASE WHEN v_vertices(v_vertex).z IS NULL THEN NULL ELSE v_vertices(v_vertex).z END;
                          PIPE ROW ( &&defaultSchema..T_Error(v_error,
                                                     v_element_no, 
                                                     v_ring_no, 
                                                     v_vertex,
                                                     MDSYS.SDO_GEOMETRY(v_dims * 1000 +1,
                                                                        p_geometry.SDO_SRID,
                                                                        mdsys.sdo_point_type(v_vertices(v_vertex).x,
                                                                                             v_vertices(v_vertex).y,
                                                                                             v_z),
                                                                        NULL,
                                                                        NULL)) );
                      End If;
                   End If;
                NULL;
              ELSIF ( rec.firstToken = 'EDGE'    ) THEN
                  -- Extract particular vector.
                  -- Examples:
                  -- 13348 [Element <1>] [Ring <80>]
                  -- 13349 [Element <1>] [Ring <1>][Edge <3>][Edge <1>]
                  -- 13351 [Element <1>] [Rings 1, 2][Edge <12> in ring <1>][Edge <10> in ring <2>]
                  -- 13366 [Element <1>] [Rings 1, 11][Edge <0> in ring <1>][Edge <0> in ring <11>]
                  IF ( rec.secondToken = 'in ring' ) THEN
                     v_ring_no := CASE WHEN rec.SecondPosition = 0 THEN 1 ELSE rec.SecondPosition END;
                     v_ring := mdsys.sdo_util.Extract(p_geometry,v_element_no,v_ring_no); -- Extract ring.
                     -- Check if Rectangle and convert to 5 vertex equivalent.
                     -- TOBEDONE: Check circles
                     --
                     If ( v_ring is not null ) Then
                        if ( hasRectangles(v_ring.sdo_elem_info) = 1 ) Then
                           v_vertices := mdsys.sdo_util.getVertices(Rectangle2Polygon(v_ring));
                        else
                           v_vertices := mdsys.sdo_util.getVertices(v_ring);
                        end If;
                     End If;
                  ELSE
                     -- ring already extracted
                     NULL;
                  END IF;
                  v_edge_no := CASE WHEN rec.firstPosition = 0 THEN 1 ELSE rec.firstPosition END;
-- DEBUG logger('v_edge_no=' || v_edge_no);
                  -- Extract edge from vertices list
                  -- Edge 1 is vertex 1 - 2; 2 is 2 - 3; 3 is 3-4
                  -- 
                  v_edge := MDSYS.SDO_GEOMETRY(v_dims * 1000 + 2,
                                               p_geometry.SDO_SRID,
                                               NULL,
                                               mdsys.sdo_elem_info_array(1,2,1),
                                               mdsys.sdo_ordinate_array(v_vertices(v_edge_no).x,
                                                                        v_vertices(v_edge_no).y,
                                                                        v_vertices(v_edge_no+1).x,
                                                                        v_vertices(v_edge_no+1).y));
                  PIPE ROW ( &&defaultSchema..T_Error(v_error,
                                             v_element_no, 
                                             v_ring_no,
                                             v_edge_no,
                                             v_edge ) );
                  if ( rec.prevToken <> 'EDGE' ) then
                     v_prev_edge := v_edge;
                  else
-- DEBUG logger('Now try and compute intersection of edge ' || v_edge_no || ' - ' || rec.prevFirstPosition);
                     v_point := FindPoint(&&defaultSchema..T_Vector(rec.prevFirstPosition,
                                                           &&defaultSchema..t_vertex(v_prev_edge.sdo_ordinates(1), v_prev_edge.sdo_ordinates(2), null,null,rec.prevFirstPosition),
                                                           &&defaultSchema..t_vertex(v_prev_edge.sdo_ordinates(3), v_prev_edge.sdo_ordinates(4), null,null,rec.prevFirstPosition+1)),
                                          &&defaultSchema..T_Vector(v_edge_no,
                                                           &&defaultSchema..t_vertex(v_edge.sdo_ordinates(1),      v_edge.sdo_ordinates(2),      null,null,v_edge_no), 
                                                           &&defaultSchema..t_vertex(v_edge.sdo_ordinates(3),      v_edge.sdo_ordinates(4),      null,null,v_edge_no+1)),
                                          p_tolerance, 
                                          p_geog_digits, 
                                          v_gtype_p, 
                                          p_geometry.sdo_srid);
                     if ( v_point is not null ) then
                         PIPE ROW ( &&defaultSchema..T_Error(v_error,
                                                    v_element_no, 
                                                    v_ring_no,
                                                    rec.prevFirstPosition+1, 
                                                    v_point) );
                     End If;
                  End If; -- rec.prevToken = 'EDGE'
              ELSIF ( rec.firstToken = 'COORDINATE'    ) THEN
                    -- eg 13356 [Element <1>] [Coordinate <10>][Ring <1>] <-- Polygons only
                    --    13356 [Element <1>] [Coordinate <2>]            <-- Linestrings: Only ever reports first duplicate.
                    -- Extract particular coordinate from arrays previously loaded
                    --
                    If ( v_element is not null ) Then
                        If ( v_element.get_gtype() IN (2,6) ) Then -- LineString
                            v_vertex := CASE WHEN rec.firstPosition = 0 THEN 1 ELSE rec.firstPosition END;
                            v_z      := CASE WHEN v_vertices(v_vertex).z IS NULL THEN NULL ELSE v_vertices(v_vertex).z END;
                            PIPE ROW ( &&defaultSchema..T_Error(v_error,
                                                       v_element_no, 
                                                       v_ring_no,
                                                       v_vertex, 
                                                       MDSYS.SDO_GEOMETRY(v_dims * 1000 +1,
                                                                          p_geometry.SDO_SRID,
                                                                          mdsys.sdo_point_type(v_vertices(v_vertex).x,
                                                                                               v_vertices(v_vertex).y,
                                                                                               v_z),
                                                                          NULL,NULL)) );
                        ElsIf ( v_element.get_gtype() IN (3,7) ) Then -- Polygon
                            -- Do nothing
                            --
                            null;
                        End If;
                    End If;
                NULL;
              END IF;
          END LOOP;
      End If;
      
      -- If 13348 see if we can find additional problems in the ring being processed.
      --
      If ( (v_error = '13349') And (p_drilldown > 0) ) Then
-- DEBUG logger('13349');
          -- Process 1st/3rd vectors looking for intersection
          SELECT &&defaultSchema..T_Vector(v.id,V.Startcoord,V.Endcoord) as vector
            BULK COLLECT INTO V_Vectors 
            FROM TABLE(&&defaultSchema..SDO_ERROR.GetVector(P_Geometry)) V
           ORDER BY v.id;

          If ( V_Vectors Is Null Or V_Vectors.Count = 0 ) Then
             Return;
          Else
             v_vector_max := v_vectors.COUNT;
             For I In V_Vectors.First..(V_Vectors.Last-1) Loop
                 if ( i = v_vector_max-1 ) then
                     v_vector := v_vectors(1);
                 Else
                     v_vector := v_vectors(i+2);
                 End If;
-- DEBUG logger('vector('||i||') relate = ' || v_validate);
                 v_geom := FindPoint(v_vectors(i), v_vector, p_tolerance, p_geog_digits, v_gtype_p, p_geometry.sdo_srid);
                 if ( v_geom is not null and mdsys.sdo_geom.relate(v_geom,'DETERMINE',v_point,p_tolerance) <> 'EQUAL' ) then
                     if ( v_all ) Then
                         PIPE ROW ( &&defaultSchema..T_Error('S'||v_error,1,0,V_Vectors(i).id,v_vectors(i).AsSdoGeometry(p_geometry.sdo_srid) ) );
                         PIPE ROW ( &&defaultSchema..T_Error('S'||v_error,1,0,V_Vector.id,    v_vector.AsSdoGeometry(p_geometry.sdo_srid) ) );
                     End If;
                     PIPE ROW (&&defaultSchema..T_Error('S'||v_error,1,0,i+1,v_point));
                 End If;
             End Loop;
          End If;
      End If;  -- 13348
      return;
  End getValidateErrors;

  Function getErrors(p_geometry    in mdsys.sdo_geometry,
                     p_tolerance   in number      default 0.005,
                     p_geog_digits in pls_integer default NULL, 
                     p_srid        in pls_integer default NULL,
                     p_all         in pls_integer default 0,
                     p_drilldown   in pls_integer default 1)
     return &&defaultSchema..SDO_ERROR.T_ErrorSet pipelined 
  AS
      v_geom       mdsys.sdo_geometry;
      v_vectors    &&defaultSchema..SDO_ERROR.T_VectorSet;
      v_vertices   MDSYS.VERTEX_SET_TYPE;
      V_Validation Varchar2(20000);
      v_errors     pls_integer := 0;

      V_Dims       Pls_Integer;
      v_vertex     PLS_INTEGER;

      V_Ring       Mdsys.Sdo_Geometry;
      v_rings      PLS_INTEGER;
      v_ring_no    PLS_INTEGER;

      v_element    mdsys.sdo_geometry;
      v_elements   PLS_INTEGER;
      v_element_no PLS_INTEGER;      
      v_edge_no    PLS_INTEGER;
      
      v_z          NUMBER;
  Begin
      if ( p_geometry is null ) then
         Return;
      end if;

      If ( p_geometry.get_gtype() not in (2,3,4,6,7) ) Then
         return;
      end If;

      V_Dims := P_Geometry.Get_Dims();
      
      -- Process x004, xx02, xx06, x003, x007 elements
      -- For individual errors in their components
      --
      v_elements := MDSYS.SDO_UTIL.GETNUMELEM(p_geometry);
      <<Process_All_Elements>>
      FOR v_element_no IN 1..v_elements LOOP
         v_element := MDSYS.SDO_UTIL.EXTRACT(p_geometry,v_element_no,0);
         If ( v_element is not null ) Then 
             -- If polygon, need to extract inner rings
             --
             If ( v_element.get_gtype() = 3) Then
                -- Process all rings in this single polygon have?
                v_rings := GetNumRings(v_element);
                <<All_Rings>>
                FOR v_ring_no IN 1..v_rings LOOP
                    v_ring := MDSYS.SDO_UTIL.EXTRACT(p_geometry,v_element_no,v_ring_no);
                   <<all_ring_errors>>
-- debug logger('Element ' || v_element_no || ' ring ' || v_ring_no);
                   FOR rec IN (SELECT a.error,a.element,a.ring,a.id,a.GEOM
                                 FROM TABLE(&&defaultSchema..SDO_ERROR.getValidateErrors(v_ring,p_tolerance,p_geog_digits,p_srid,p_all,p_drilldown)) a) 
                   LOOP
                       If ( rec.geom is not null ) then
                          v_errors := v_errors + 1;
                          PIPE ROW (&&defaultSchema..T_Error(rec.error,v_element_no,v_ring_no,rec.id,rec.geom));
                       End If;
                   END LOOP all_ring_errors;                    
                END LOOP All_Rings;
             -- if line-string then get simply process it 
             --
             ElsIf ( v_element.get_gtype() = 2) Then
                 <<all_line_errors>>
                 FOR rec IN (SELECT a.error,a.element,a.ring,a.id,a.GEOM
                               FROM TABLE(&&defaultSchema..SDO_ERROR.getValidateErrors(v_element,p_tolerance,p_geog_digits,p_srid,p_all,p_drilldown)) a) 
                 LOOP
                     If ( rec.geom is not null ) then
                        v_errors := v_errors + 1;
                        PIPE ROW (&&defaultSchema..T_Error(rec.error,v_element_no,0,rec.id,rec.geom));
                     End If;
                 END LOOP all_line_errors;
             End If;
         End If;
     END LOOP Process_All_Elements;
     -- Error may be due to element interaction and not isolatd to each element
     --
     if ( v_errors = 0 ) Then
         <<all_geom_errors>>
         FOR rec IN (SELECT a.error,a.element,a.ring,a.id,a.GEOM
                       FROM TABLE(&&defaultSchema..SDO_ERROR.getValidateErrors(p_geometry,p_tolerance,p_geog_digits,p_srid,p_all,p_drilldown)) a) 
         LOOP
             If ( rec.geom is not null ) then
                v_errors := v_errors + 1;
                PIPE ROW (&&defaultSchema..T_Error(rec.error,rec.element,rec.ring,rec.id,rec.geom));
             End If;
         END LOOP all_geom_errors;     
     End If;
     return;
  End getErrors;

  /** ----------------------------------------------------------------------------------------
    * @function   : getError
    * @precis     : Function which returns a the nominated error number as a single geometry.
    *               Edge errors returns as single edge, points as single point.
  **/
   Function getError(p_geometry     in mdsys.sdo_geometry, 
                     p_error_number in pls_integer,
                     p_tolerance    in number      default 0.005,
                     p_geog_digits  in pls_integer default NULL,
                     p_srid         in pls_integer default NULL)
     Return mdsys.sdo_geometry 
  Is
     v_error pls_integer := 0; -- include error number
     v_geom  mdsys.sdo_geometry;
  Begin
     IF ( p_geometry is null or p_error_number is null) THEN
         RETURN null;
     END IF;
     FOR rec IN (SELECT a.element,a.ring,a.id,a.GEOM 
                   FROM TABLE(&&defaultSchema..SDO_ERROR.getErrors(p_geometry,p_tolerance,p_geog_digits,p_srid,0)) a) LOOP
         If ( rec.geom is not null ) then
             v_error := v_error + 1;
             if ( v_error = p_error_number ) Then
                 return rec.geom;
             End If;
         End If;
     END LOOP;
     RETURN null;
  End getError;
    
  Function getErrorsAsMulti(p_geometry    in mdsys.sdo_geometry, 
                            p_tolerance   in number      default 0.005,
                            p_geog_digits in pls_integer default NULL, 
                            p_srid        in pls_integer default NULL,
                            p_all         in pls_integer default 0) 
    Return mdsys.sdo_geometry 
  Is
     v_geom mdsys.sdo_geometry;
     v_dims pls_integer;
  Begin
     IF ( p_geometry is null ) THEN
         RETURN null;
     END IF;
     v_dims := p_geometry.get_dims();
     v_geom := mdsys.sdo_geometry(v_dims * 1000 + 4,
                                  p_geometry.sdo_srid,
                                  null,
                                  mdsys.sdo_elem_info_array(),
                                  mdsys.sdo_ordinate_array());
     FOR rec IN (SELECT a.element,a.ring,a.id,a.GEOM 
                   FROM TABLE(&&defaultSchema..SDO_ERROR.getErrors(p_geometry,p_tolerance,p_geog_digits,p_srid,p_all)) a) LOOP
         If ( rec.geom is not null ) then
              if ( rec.geom.sdo_point is not null ) then
                  ADD_Element(v_geom.sdo_elem_info,
                              new mdsys.sdo_elem_info_array(1,1,1),
                              v_geom.sdo_ordinates);
                  ADD_Coordinate(v_geom.sdo_ordinates,
                                 v_dims,
                                 rec.geom.sdo_point,
                                 false,
                                 true);
              Else
                  ADD_Element(v_geom.sdo_elem_info,
                              rec.geom.sdo_elem_info,
                              v_geom.sdo_ordinates);
                  ADD_Ordinates(v_geom.sdo_ordinates,
                                rec.geom.sdo_ordinates);
              End if;
         End If;
     END LOOP;
     RETURN v_geom;
  End getErrorsAsMulti;

  Function getErrorText(p_geometry  in mdsys.sdo_geometry,
                        p_tolerance in number default 0.005) 
    return &&defaultSchema..SDO_ERROR.T_Strings pipelined
  Is
     v_validation varchar2(4000);
     v_geom       mdsys.sdo_geometry;
  Begin
      if ( p_geometry is null ) then
         return;
      end if;
      v_validation := mdsys.sdo_geom.validate_geometry_with_context(p_geometry,p_tolerance);
      if ( v_validation is null Or REGEXP_LIKE(v_validation, '^[0-9 ]+$', 'i') or v_validation in ('TRUE','NULL') ) then
          return;
      end if;
      FOR error IN (SELECT *
                      FROM (SELECT rownum as token_id, 
                                   a.COLUMN_VALUE as token
                              FROM TABLE(&&defaultSchema..SDO_ERROR.tokenizer(v_validation,'[]')) a
                           ) b
                     WHERE TRIM(b.token) is not null
                  ORDER BY b.token_id) LOOP
          PIPE ROW ( error.token );
      end loop;
      return;
  End getErrorText;

  Function getErrorText(p_geometry     in mdsys.sdo_geometry,
                        p_error_number in pls_integer,
                        p_tolerance    in number default 0.05 )
    return varchar2 
  Is
     v_error      varchar2(400);
     v_geom       mdsys.sdo_geometry;
  Begin
      if ( p_geometry is null ) then
         return null;
      end if;
      BEGIN
          SELECT f.token
            INTO v_error
            FROM (SELECT rownum as token_id,
                         b.token
                    FROM (SELECT rownum as token_id, 
                                 a.COLUMN_VALUE as token
                            FROM TABLE(&&defaultSchema..SDO_ERROR.getErrorText(p_geometry,p_tolerance)) a
                         ) b
                  ORDER BY b.token_id
                  ) f
           WHERE f.token_id = p_error_number;
           EXCEPTION 
              WHEN NO_DATA_FOUND THEN
                 RETURN NULL;
      END;
      RETURN v_error;
  End getErrorText;
  
  Function getMarks(p_geometry    in mdsys.sdo_geometry,
                    p_markType    in pls_integer default 0,
                    p_degrees     in pls_integer default 0,
                    p_tolerance   in number      default 0.005,
                    p_geog_digits in pls_integer default null) 
    return &&defaultSchema..SDO_ERROR.T_VertexMarkSet pipelined
  Is
     v_element         mdsys.sdo_geometry;
     v_ring            mdsys.sdo_geometry;
     v_element_no      pls_integer;
     v_actual_etype    pls_integer;
     v_ring_elem_count pls_integer := 0;
     v_ring_no         pls_integer;
     v_num_elements    pls_integer;
     v_num_rings       pls_integer;
     v_dims            pls_integer;
     v_coordinates     mdsys.vertex_set_type;
     v_prevVertex      mdsys.vertex_type;
     v_currVertex      mdsys.vertex_type;
     v_nextVertex      mdsys.vertex_type;
     v_bearing         number := 0.0;
     v_bearingNext     number := 0.0;
     v_bearingPrev     number := 0.0;
     v_delta           number := 0.0;
     v_mark_text       varchar2(4000);
     v_round           pls_integer := case when p_geog_digits is null
                                           then case when p_tolerance is null
                                                     then 3
                                                     else round(log(10,(1/p_tolerance)/2))
                                                 end
                                           else p_geog_digits
                                       end;
     
      Function GetETypeAt(
        p_geometry  in mdsys.sdo_geometry,
        p_element   in pls_integer)
        Return pls_integer
      Is
        v_num_elems number;
      Begin
        If ( p_geometry is not null ) Then
          v_num_elems := ( ( p_geometry.sdo_elem_info.COUNT / 3 ) - 1 );
          <<element_extraction>>
          for v_i IN 0 .. v_num_elems LOOP
             if ( (v_i+1) = p_element ) then 
                RETURN p_geometry.sdo_elem_info(v_i * 3 + 2);
            End If;
            end loop element_extraction;
        End If;
        Return NULL;
      End GetETypeAt;
    
  Begin
     If ( p_geometry is null ) Then
        return;
     End If;
     if (     p_markType <> &&defaultSchema..SDO_ERROR.c_ID 
          AND p_markType <> &&defaultSchema..SDO_ERROR.c_ID_COORD
          AND p_markType <> &&defaultSchema..SDO_ERROR.c_COORD
          AND p_markType <> &&defaultSchema..SDO_ERROR.c_ELEM ) 
     Then
        raise_application_error(c_i_invalid_mark,c_s_invalid_mark,true);
     End If;
     if (     p_degrees <> &&defaultSchema..SDO_ERROR.c_DEGREES 
          AND p_degrees <> &&defaultSchema..SDO_ERROR.c_RADIANS ) 
     Then
        raise_application_error(c_i_invalid_degrees,c_i_invalid_degrees,true);
     End If;
     
     v_dims   := p_geometry.get_dims();
     If ( p_geometry.get_gtype()= 1 ) Then
         v_mark_text := case p_markType 
                             when &&defaultSchema..SDO_ERROR.c_ID       
                             then '<1>'
                             when &&defaultSchema..SDO_ERROR.c_ID_COORD 
                             then '<1>' || 
                                  v_bracketStart || 
                                    ROUND(p_geometry.sdo_point.X,v_round) || ',' || ROUND(p_geometry.sdo_point.Y,v_round) || 
                                    CASE WHEN v_dims = 3 THEN ',' || ROUND(p_geometry.sdo_point.Z,v_round) ELSE '' END || 
                                  v_bracketEnd 
                             when &&defaultSchema..SDO_ERROR.c_COORD
                             then v_bracketStart || 
                                    ROUND(p_geometry.sdo_point.X,v_round) || ',' || ROUND(p_geometry.sdo_point.Y,v_round) || 
                                    CASE WHEN v_dims = 3 THEN ',' || ROUND(p_geometry.sdo_point.Z,v_round) ELSE '' END || 
                                  v_bracketEnd 
                             when &&defaultSchema..SDO_ERROR.c_ELEM
                             then '<1,0,1>'
                             else '<1>'
                         end;
         PIPE ROW ( &&defaultSchema..T_VertexMark( 1, 0, 1, p_geometry, 0, v_mark_text ) );
         RETURN;
     ElsIf ( p_geometry.get_gtype() = 5 ) Then
        v_coordinates := mdsys.sdo_util.getVertices(p_geometry);
        if ( v_coordinates is not null ) Then
           For v_coord_no in 1..v_coordinates.COUNT Loop
               v_currVertex := v_coordinates(v_coord_no);
               v_mark_text := case p_markType 
                                   when &&defaultSchema..SDO_ERROR.c_ID
                                   then '<' || v_coord_no || '>'
                                   when &&defaultSchema..SDO_ERROR.c_ID_COORD 
                                   then '<' || v_coord_no || '>' || 
                                        v_bracketStart || 
                                          ROUND(v_currVertex.X,v_round) || ',' || ROUND(v_currVertex.Y,v_round) || 
                                          CASE WHEN v_dims = 3 THEN ',' || ROUND(v_currVertex.Z,v_round) ELSE '' END || 
                                        v_bracketEnd 
                                   when &&defaultSchema..SDO_ERROR.c_COORD
                                   then v_bracketStart || 
                                          ROUND(v_currVertex.X,v_round) || ',' || ROUND(v_currVertex.Y,v_round) || 
                                          CASE WHEN v_dims = 3 THEN ',' || ROUND(v_currVertex.Z,v_round) ELSE '' END || 
                                        v_bracketEnd 
                                   when &&defaultSchema..SDO_ERROR.c_ELEM
                                   then '<1,0,' || v_coord_no || '>'
                                   else '<' || v_coord_no || '>'
                               end;
               PIPE ROW ( &&defaultSchema..T_VertexMark( 1, 0, v_coord_no,
                                        mdsys.sdo_geometry(v_dims * 1000 + 1,p_geometry.sdo_srid,
                                                           mdsys.sdo_point_type(v_coordinates(v_coord_no).X,v_coordinates(v_coord_no).Y,v_coordinates(v_coord_no).Z),NULL,NULL), 
                                        0,
                                        v_mark_text ) );
           End Loop;
        End If;
        RETURN;
     End If;
     
     -- Process Line/Multiline and Polygon/Multipolygon
     --
     v_num_elements := MDSYS.SDO_UTIL.GETNUMELEM(p_geometry);
     <<Process_All_Elements>>
     FOR v_element_no IN 1..v_num_elements LOOP
         v_element := MDSYS.SDO_UTIL.EXTRACT(p_geometry,v_element_no,0);
         If ( v_element is not null ) Then 
             -- Polygons
             -- Need to check for inner rings
             --
             If ( v_element.get_gtype() = 3) Then
                -- Process all rings in this single polygon have?
                v_num_rings := GetNumRings(v_element);
                <<All_Rings>>
                FOR v_ring_no IN 1..v_num_rings LOOP
                    v_ring            := MDSYS.SDO_UTIL.EXTRACT(p_geometry,v_element_no,v_ring_no);
                    v_actual_etype    := GetEtypeAt(p_geometry,(v_ring_elem_count+1));
                    v_ring_elem_count := v_ring_elem_count + v_ring.sdo_elem_info.COUNT / 3;
                    -- Now generate marks
                    If ( v_ring is not null ) Then
                        If ( v_actual_etype = 2003 ) Then -- Extract reverses the linestring
                           v_ring := mdsys.sdo_util.reverse_linestring(
                                            mdsys.sdo_geometry(v_dims*1000+2,
                                                               v_ring.sdo_srid,
                                                               null,
                                                               mdsys.sdo_elem_info_array(1,2,1),
                                                               v_ring.sdo_ordinates));
                        End If;
                        v_coordinates := mdsys.sdo_util.getVertices(v_ring);
                        FOR v_coord_no IN 1..v_coordinates.COUNT LOOP
                            v_currVertex := v_coordinates(v_coord_no);
                            If ( v_coord_no = 1 ) Then
                                v_prevVertex  := v_coordinates(v_coordinates.COUNT-1);
                                v_nextVertex  := v_coordinates(v_coord_no+1);
                                v_bearingNext := ROUND(Degrees(bearing(v_currVertex,v_nextVertex)));
                                v_bearingPrev := ROUND(Degrees(bearing(v_prevVertex,v_currVertex)));
                            ElsIf ( v_coord_no = v_coordinates.count ) Then
                                v_prevVertex  := v_coordinates(v_coord_no-1);
                                v_nextVertex  := v_coordinates(2);
                                v_bearingNext := ROUND(Degrees(bearing(v_currVertex,v_nextVertex)));
                                v_bearingPrev := ROUND(Degrees(bearing(v_prevVertex,v_currVertex)));
                            Else
                                v_prevVertex  := v_coordinates(v_coord_no-1);
                                v_nextVertex  := v_coordinates(v_coord_no+1);
                                v_bearingNext := ROUND(Degrees(bearing(v_currVertex,v_nextVertex)));
                                v_bearingPrev := ROUND(Degrees(bearing(v_prevVertex,v_currVertex)));
                            End If;
                            v_delta   := v_bearingNext - v_bearingPrev;
                            -- DEBUG logger(v_actual_etype);
                            -- Outer ring
                            if ( v_actual_etype = 1003 ) then 
                               if ( SIGN(v_delta) = 1 ) then
                                  v_bearing := v_bearingPrev + ABS(v_delta - 180.0)/2.0;
                               else
                                  v_bearing := (v_bearingNext + (180 + ABS(v_delta))/2.0);
                               end If;
                            -- inner ring
                            ElsIf ( v_actual_etype = 2003 ) Then
                               if ( SIGN(v_delta) = 1 ) then  -- Positive 
                                  if ( v_delta <= 180 ) Then
                                      v_bearing := v_bearingPrev - (180.0 - v_delta)/2.0; 
                                  else
                                      v_bearing := v_bearingNext + (180.0 - v_delta)/2.0; 
                                  end If;
                               Else -- negative angle
                                  if ( abs(v_delta) <= 180 ) Then
                                      v_bearing := v_bearingNext + (v_delta/2.0);
                                  else
                                      v_bearing := v_bearingPrev + (180.0 + v_delta)/2.0;
                                  end if;
                               End If;
                            End If;
                            v_bearing := case when v_bearing >= 360 
                                              then v_bearing - 360 
                                              else case when v_bearing < 0 
                                                   then 360 + v_bearing 
                                                   else v_bearing
                                               end 
                                          end;
                            v_mark_text := case p_markType 
                                                when &&defaultSchema..SDO_ERROR.c_ID       then '<' || v_coord_no || '>'
                                                when &&defaultSchema..SDO_ERROR.c_ID_COORD then '<' || v_coord_no || '>' || 
                                                                                       v_bracketStart || 
                                                                                       ROUND(v_currVertex.X,v_round) || ',' || ROUND(v_currVertex.Y,v_round) || 
                                                                                       CASE WHEN v_dims = 3 THEN ','    ||     ROUND(v_currVertex.Z,v_round) ELSE '' END || 
                                                                                                           v_bracketEnd 
                                                when &&defaultSchema..SDO_ERROR.c_COORD    then v_bracketStart || 
                                                                                       ROUND(v_currVertex.X,v_round) || ',' || ROUND(v_currVertex.Y,v_round) || 
                                                                                       CASE WHEN v_dims = 3 THEN ',' ||        ROUND(v_currVertex.Z,v_round) ELSE '' END || 
                                                                               v_bracketEnd 
                                                when &&defaultSchema..SDO_ERROR.c_ELEM     then '<' || v_element_no || ',' || v_ring_no || ',' || v_coord_no || '>'
                                                else '<' || v_coord_no || '>'
                                            end;
                            -- DEBUG: v_mark_text := v_bearingPrev || ' - ' || v_bearingNext || ' - ' || v_delta || ' - ' || v_bearing;
                            PIPE ROW ( &&defaultSchema..T_VertexMark( v_element_no, v_ring_no, v_coord_no,
                                                     mdsys.sdo_geometry(v_dims * 1000 + 1,p_geometry.sdo_srid,mdsys.sdo_point_type(v_currVertex.X,v_currVertex.Y,v_currVertex.Z),NULL,NULL), 
                                                     NVL(case when p_degrees = &&defaultSchema..SDO_ERROR.C_DEGREES THEN v_bearing ELSE Radians(v_bearing) END,0),
                                                     v_mark_text ) );
                        END LOOP;
                    End If;
                END LOOP All_Rings;
                
             -- Linestrings
             --
             ElsIf ( v_element.get_gtype() = 2) Then
                 v_coordinates := mdsys.sdo_util.getVertices(v_element);
                 v_prevVertex  := v_coordinates(1);
                 v_delta       := 0;
                 FOR v_coord_no IN 1..v_coordinates.COUNT LOOP
                     v_currVertex := v_coordinates(v_coord_no);
                     If ( v_coord_no = v_coordinates.count ) Then
                         v_nextVertex  := v_coordinates(v_coord_no-1);
                         v_bearingNext := ROUND(Degrees(bearing(v_currVertex, v_nextVertex)));
                     elsif ( v_coord_no = 1 ) then
                         v_nextVertex  := v_coordinates(v_coord_no+1);
                         v_bearingNext := ROUND(Degrees(bearing(v_currVertex, v_nextVertex))) + 180;
                     else
                         v_nextVertex  := v_coordinates(v_coord_no+1);
                         v_bearingNext := ROUND(Degrees(bearing(v_nextVertex, v_currVertex)));
                         if ( v_coord_no <> 1 ) Then
                             v_bearingPrev := ROUND(Degrees(bearing(v_currVertex,v_prevVertex)));
                             v_delta   := v_bearingPrev - v_bearingNext;
                         End If;
                     End If;
                     v_bearing := v_bearingNext + (v_delta / 2.0);
                     v_bearing := v_bearing-90.0;
                     v_mark_text := case p_markType 
                                         when &&defaultSchema..SDO_ERROR.c_ID
                                         then '<' || v_coord_no || '>'
                                         when &&defaultSchema..SDO_ERROR.c_ID_COORD 
                                         then '<' || v_coord_no || '>' || 
                                              v_bracketStart || 
                                                ROUND(v_currVertex.X,v_round) || ',' || ROUND(v_currVertex.Y,v_round) || 
                                                CASE WHEN v_dims = 3 THEN ',' || ROUND(v_currVertex.Z,v_round) ELSE '' END || 
                                              v_bracketEnd 
                                         when &&defaultSchema..SDO_ERROR.c_COORD
                                         then v_bracketStart || 
                                                ROUND(v_currVertex.X,v_round) || ',' || ROUND(v_currVertex.Y,v_round) || 
                                                CASE WHEN v_dims = 3 THEN ',' || ROUND(v_currVertex.Z,v_round) ELSE '' END || 
                                              v_bracketEnd
                                         when &&defaultSchema..SDO_ERROR.c_ELEM
                                         then '<1,' || v_element_no || ',' || v_coord_no || '>'
                                         else '<' || v_coord_no || '>'
                                     end;
                     PIPE ROW ( &&defaultSchema..T_VertexMark( v_element_no, 0, v_coord_no,
                                              mdsys.sdo_geometry(v_dims * 1000 + 1,p_geometry.sdo_srid,mdsys.sdo_point_type(v_currVertex.X,v_currVertex.Y,v_currVertex.Z),NULL,NULL), 
                                              case when p_degrees = &&defaultSchema..SDO_ERROR.C_DEGREES THEN v_bearing ELSE Radians(v_bearing) END,
                                              v_mark_text ) );
                END LOOP;
             End If;
         End If;
     END LOOP;
     RETURN;
  End getMarks;

  Function fix13348(p_geometry    in mdsys.sdo_geometry,
                    p_make_equal  in pls_integer default 1,
                    p_tolerance   in number      default 0.005,
                    p_geog_digits in pls_integer default null)
    return mdsys.sdo_geometry deterministic
  as
    v_make_equal   boolean := case when p_make_equal is null then TRUE 
                                   when p_make_equal = 0 then FALSE
                                   else TRUE
                               end;
    v_dims         pls_integer;
    v_num_elements pls_integer;
    v_element_no   pls_integer;
    v_element      mdsys.sdo_geometry;
    v_num_rings    pls_integer;
    v_ring_no      pls_integer;
    v_ring         mdsys.sdo_geometry;
    v_round        pls_integer := case when p_geog_digits is null
                                       then case when p_tolerance is null
                                                 then 3
                                                 else round(log(10,(1/p_tolerance)/2))
                                             end
                                       else p_geog_digits
                                   end;
    v_output_geom  mdsys.sdo_geometry;
    NULL_GEOMETRY  EXCEPTION;
    NOT_POLYGON    EXCEPTION;
  Begin
    If ( p_geometry is null ) Then
      Raise NULL_GEOMETRY;
    ElsIf ( p_geometry.get_gtype() not in (3,7) ) Then
       RAISE NOT_POLYGON;
    End If;
    
    v_dims := p_geometry.get_dims();
    v_num_elements := mdsys.sdo_util.GetNumElem(p_geometry);
    <<for_all_elements>>
    FOR v_element_no IN 1..v_num_elements LOOP
       v_element := mdsys.sdo_util.Extract(p_geometry,v_element_no,0);   -- Extract element with all sub-elements
       v_num_rings := GetNumRings(v_element); 
       <<for_all_rings>>
       FOR v_i in 1..v_num_rings Loop
           v_ring   := mdsys.sdo_util.Extract(v_element,v_i);   -- Extract ring from element
           if NOT ( v_ring.sdo_ordinates is null or v_ring.sdo_ordinates.COUNT < (3*v_dims) ) Then
-- DEBUG logger(round(v_ring.sdo_ordinates(1),v_round_factor) || ' = ' || round(v_ring.sdo_ordinates(v_ring.sdo_ordinates.COUNT-v_dims),v_round_factor) || ' - ' || round(v_ring.sdo_ordinates(2),v_round_factor) || ' = ' || round(v_ring.sdo_ordinates(v_ring.sdo_ordinates.COUNT-(v_dims-1)),v_round_factor) );
              if Not (  round(v_ring.sdo_ordinates(1),v_round) = round(v_ring.sdo_ordinates(v_ring.sdo_ordinates.COUNT-v_dims),v_round) 
                    and round(v_ring.sdo_ordinates(2),v_round) = round(v_ring.sdo_ordinates(v_ring.sdo_ordinates.COUNT-(v_dims-1)),v_round) ) Then
                 if ( v_make_equal ) then
-- DEBUG logger('making equal');
-- DEBUG logger('before: ' || v_ring.sdo_ordinates(v_ring.sdo_ordinates.COUNT-(v_dims-1)) || ',' || v_ring.sdo_ordinates(v_ring.sdo_ordinates.COUNT-(v_dims-2))); 
                     v_ring.sdo_ordinates(v_ring.sdo_ordinates.COUNT-(v_dims-1)) := v_ring.sdo_ordinates(1);
                     v_ring.sdo_ordinates(v_ring.sdo_ordinates.COUNT-(v_dims-2)) := v_ring.sdo_ordinates(2);
-- DEBUG logger('after: ' ||  v_ring.sdo_ordinates(v_ring.sdo_ordinates.COUNT-(v_dims-1)) || ',' || v_ring.sdo_ordinates(v_ring.sdo_ordinates.COUNT-(v_dims-2)));
                     if ( v_dims = 3 ) then
                        v_ring.sdo_ordinates(v_ring.sdo_ordinates.COUNT) := v_ring.sdo_ordinates(3);
                     end if;                 
                 Else
                     -- Add start vertex to end
                     v_ring.sdo_ordinates.EXTEND(v_dims);
                     v_ring.sdo_ordinates(v_ring.sdo_ordinates.COUNT-(v_dims-1)) := v_ring.sdo_ordinates(1);
                     v_ring.sdo_ordinates(v_ring.sdo_ordinates.COUNT-(v_dims-2)) := v_ring.sdo_ordinates(2);
                     if ( v_dims = 3 ) then
                        v_ring.sdo_ordinates(v_ring.sdo_ordinates.COUNT) := v_ring.sdo_ordinates(3);
                     end if;
                     -- Need to fix sdo_elem_info
                  End If;
              End If;
              if ( v_output_geom is null ) then
                 v_output_geom := v_ring;
              else
                 v_output_geom := mdsys.sdo_util.append(v_output_geom,v_ring);
              end if;
           End If;
       End Loop for_all_rings;
    END LOOP for_all_elements;
    return v_output_geom;
    EXCEPTION
      WHEN NULL_GEOMETRY Then
        raise_application_error(c_i_null_geometry, c_s_null_geometry,TRUE);
        RETURN p_geometry;
      WHEN NOT_POLYGON THEN
        raise_application_error(c_i_not_polygon,   c_s_not_polygon,true);
       RETURN p_geometry;
  end fix13348;

  Function FindSpikes(p_geometry    in mdsys.sdo_geometry,
                      p_tolerance   in number default 0.005)
    return &&defaultSchema..SDO_ERROR.T_VectorSet pipelined
  as
    v_vector       &&defaultSchema..t_vector;
    v_vectors      &&defaultSchema..SDO_ERROR.T_VectorSet;
    v_num_elements pls_integer;
    v_element_no   pls_integer;
    v_element      mdsys.sdo_geometry;
    v_num_rings    pls_integer;
    v_ring_no      pls_integer;
    v_ring         mdsys.sdo_geometry;
    v_relate       varchar2(100);
    NULL_GEOMETRY  EXCEPTION;
    NOT_LINE_POLY  EXCEPTION;
  Begin
     If ( p_geometry is null ) Then
       Raise NULL_GEOMETRY;
     ElsIf ( p_geometry.get_gtype() not in (2,5,3,7) ) Then
        RAISE NOT_LINE_POLY;
     End If;
    
     -- Process Line/Multiline and Polygon/Multipolygon
     --
     v_num_elements := MDSYS.SDO_UTIL.GETNUMELEM(p_geometry);
     <<Process_All_Elements>>
     FOR v_element_no IN 1..v_num_elements LOOP
         v_element := MDSYS.SDO_UTIL.EXTRACT(p_geometry,v_element_no,0);
         If ( v_element is not null ) Then 
             -- Polygons
             -- Need to check for inner rings
             --
             If ( v_element.get_gtype() = 3) Then
                -- Process all rings in this single polygon have?
                v_num_rings := GetNumRings(v_element);
                <<All_Rings>>
                FOR v_ring_no IN 1..v_num_rings LOOP
                    v_ring            := MDSYS.SDO_UTIL.EXTRACT(p_geometry,v_element_no,v_ring_no);                    
                    -- Now walk ring's vectors
                    --
                    If ( v_ring is not null ) Then
                       -- Process 1st/2rd vectors looking for spike
                      SELECT &&defaultSchema..T_Vector(v.id,V.Startcoord,V.Endcoord) as vector
                        BULK COLLECT INTO V_Vectors 
                        FROM TABLE(&&defaultSchema..SDO_ERROR.GetVector(v_ring)) V
                       ORDER BY v.id;
                      If Not ( V_Vectors Is Null Or V_Vectors.Count = 0 ) Then
                         For I In V_Vectors.First..V_Vectors.Last Loop
                             if ( i = V_Vectors.Last ) then
                                 v_vector := v_vectors(1);
                             Else
                                 v_vector := v_vectors(i+1);
                             End If;
                             -- Check if the interact in a way other than TOUCH
                             --
                             v_relate := mdsys.sdo_geom.relate(v_vectors(i).AsSdoGeometry(p_geometry.sdo_srid),'DETERMINE',v_vector.asSdoGeometry(p_geometry.sdo_srid),p_tolerance);
                             If ( v_relate <> 'TOUCH' ) Then
                                PIPE ROW ( &&defaultSchema..T_Vector(v_vectors(i).id,v_vectors(i).startCoord,v_vectors(i).endCoord)  );
                                PIPE ROW ( &&defaultSchema..T_Vector(v_vector.id,v_vector.startCoord,v_vector.endCoord) );
                             End If;
                         End Loop;
                      End If;
                    End If;
                END LOOP All_Rings;
             -- Linestrings
             --
             ElsIf ( v_element.get_gtype() = 2) Then
                   -- Process 1st/2rd vectors looking for spike
                  SELECT &&defaultSchema..T_Vector(v.id,V.Startcoord,V.Endcoord) as vector
                    BULK COLLECT INTO V_Vectors 
                    FROM TABLE(&&defaultSchema..SDO_ERROR.GetVector(v_element)) V
                   ORDER BY v.id;
                  If Not ( V_Vectors Is Null Or V_Vectors.Count = 0 ) Then
                     For I In V_Vectors.First..(V_Vectors.Last-1) Loop
                         v_vector := v_vectors(i+1);
                         -- Check if the interact in a way other than TOUCH
                         --
                         v_relate := mdsys.sdo_geom.relate(v_vectors(i).AsSdoGeometry(p_geometry.sdo_srid),'DETERMINE',v_vector.AsSdoGeometry(p_geometry.sdo_srid),p_tolerance);
                         If ( v_relate <> 'TOUCH' ) Then
                             PIPE ROW ( &&defaultSchema..T_Vector(v_vectors(i).id,v_vectors(i).startCoord,v_vectors(i).endCoord)  );
                             PIPE ROW ( &&defaultSchema..T_Vector(v_vector.id,v_vector.startCoord,v_vector.endCoord) );
                         End If;
                     End Loop;
                  End If;             
             End If;
         End If;
     END LOOP;

    return ;
    EXCEPTION
      WHEN NULL_GEOMETRY Then
        raise_application_error(c_i_null_geometry, c_s_null_geometry,TRUE);
        RETURN;
      WHEN NOT_LINE_POLY THEN
        raise_application_error(c_i_not_line_poly,   c_s_not_line_poly,true);
       RETURN ;
  end FindSpikes;

end SDO_ERROR;
/
SHOW ERRORS

set serveroutput on size unlimited
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
   v_OK       boolean := true;
   v_obj_name varchar2(30) := 'SDO_ERROR';
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

grant execute on &&defaultSchema..SDO_ERROR to public;

EXIT;
