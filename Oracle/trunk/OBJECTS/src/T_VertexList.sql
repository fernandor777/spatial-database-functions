DEFINE INSTALL_SCHEMA='&1'

SET VERIFY OFF;

CREATE OR REPLACE TYPE &&INSTALL_SCHEMA..T_VERTEXLIST
AUTHID DEFINER
AS OBJECT (

  /****t* OBJECT TYPE/T_VERTEXLIST
  *  NAME
  *    T_VERTEXLIST -- Object type representing a collection of T_VERTICES
  *  DESCRIPTION
  *    An object type that represents an array/collection of T_VERTICES.
  *    Includes Methods on that type.
  *  NOTES
  *    This also implements JTS's OffsetSegmentString.java.
  *    A dynamic list of the vertices in a constructed offset curve.
  *    Automatically removes adjacent vertices which are closer than a given tolerance.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Martin Davis  - 2016 - Java coding.
  *    Simon Greener - Jul 2019 - extended T_Vertices to include methods derived from OffsetSegmentString.java
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/

  /****v* T_VERTEXLIST/ATTRIBUTES(T_VERTEXLIST)
  *  ATTRIBUTES
  *    seglist is a table of t_segment
  *    minimimVertexDistance is min distance between two vertices. If less then any vertex is not added.
  *  SOURCE
  */
  vertexList            &&INSTALL_SCHEMA..T_VERTICES,
  minimimVertexDistance Number,
  dPrecision            integer,
  /*******/

  /****m* T_VERTEXLIST/CONSTRUCTORS(T_VERTEXE)
  *  NAME
  *    A collection of T_VERTEXLIST Constructors.
  *  SOURCE
  */
  -- Useful as an "Empty" constructor.
  Constructor Function T_VERTEXLIST(SELF IN OUT NOCOPY T_VERTEXLIST)
                Return Self As Result,

  Constructor Function T_VERTEXLIST(SELF     IN OUT NOCOPY T_VERTEXLIST,
                                    p_vertex in &&INSTALL_SCHEMA..T_VERTEX)
                Return Self As Result,

  Constructor Function T_VERTEXLIST(SELF        IN OUT NOCOPY T_VERTEXLIST,
                                    p_segment   in &&INSTALL_SCHEMA..T_SEGMENT)
                Return Self As Result,

  Constructor Function T_VERTEXLIST(SELF        IN OUT NOCOPY T_VERTEXLIST,
                                    p_line      in mdsys.sdo_geometry)
                Return Self As Result,
  /*******/

  /* ******************* Member Methods ************************ */
           
  Member Function ST_Self
           Return &&INSTALL_SCHEMA..T_VERTEXLIST,

  Member Function isDeleted(p_index in integer)
           return integer deterministic,
           
  Member Procedure setDeleted(
            SELF      IN OUT NOCOPY T_VERTEXLIST,
            p_index   IN INTEGER,
            p_deleted IN INTEGER DEFAULT 1),
                              
  Member Function getNumCoordinates
           return integer deterministic,

  Member Function getCoordinates
           Return &&INSTALL_SCHEMA..T_Vertices,

  Member Function getOrdinates
           Return mdsys.sdo_ordinate_array,

  /**
   * Tests whether the given point is redundant
   * relative to the previous
   * point in the list (up to tolerance).
   * 
   * @param p_vertex
   * @return true if the point is redundant
   */
  Member Function isRedundant(p_vertex in &&INSTALL_SCHEMA..T_Vertex)
           Return boolean,

  /**
   * Rounds a 2D Coordinate to the PrecisionModel grid.
   */
  Member Procedure makePrecise(
            SELF         IN OUT NOCOPY T_VERTEXLIST,
            p_coord in out nocopy &&INSTALL_SCHEMA..T_Vertex),

  Member Procedure addVertex(
             SELF     IN OUT NOCOPY T_VERTEXLIST,
             p_vertex in &&INSTALL_SCHEMA..T_Vertex),

  Member Procedure addCoordinate( 
            SELF      IN OUT NOCOPY T_VERTEXLIST,
            p_dim     in number,
            p_x_coord in number,
            p_y_coord in number,
            p_z_coord in number,
            p_m_coord in number,
            p_lrs_dim in integer default 0
          ),

  Member Procedure addCoordinate(
            SELF    IN OUT NOCOPY T_VERTEXLIST,
            p_dim   in number,
            p_coord in &&INSTALL_SCHEMA..T_Vertex
         ),

  Member Procedure addCoordinate( 
            SELF      IN OUT NOCOPY T_VERTEXLIST,
            p_dim     in number,
            p_coord   in mdsys.vertex_type,
            p_lrs_dim in integer default 0
         ),

  Member Procedure addCoordinate(
         SELF      IN OUT NOCOPY T_VERTEXLIST,
         p_dim     in number,
         p_coord   in mdsys.sdo_point_type,
         p_lrs_dim in integer default 0
         ),

  /****m* T_VERTEXLIST/addOrdinates
  *  NAME
  *    addOrdinates -- Allows an sdo_ordinate_array to be directly added to the underlying list.
  *  SYNOPSIS
  *    Member Procedure addOrdinates( 
  *           SELF        IN OUT NOCOPY T_VERTEXLIST,
  *           p_dim       in integer,
  *           p_lrs_dim   in integer,
  *           p_ordinates in mdsys.sdo_ordinate_array ),
  *  DESCRIPTION
  *    This procedure allows for an sdo_ordinate_array to be directly added to the underlying list.
  *    XYZM ordinates are all supported.
  *    All vertices created adopt the SRID of the VertexList's first vertex.
  *    Coordinate dimensionality and lrs dim should be same as underling VertexList.
  *  ARGUMENTS
  *    p_dim                  (integer) -- The coordinate dimension used to interpret the numbers in the sdo_ordinate_array.
  *    p_lrs_dim              (integer) -- The dimension for the LRS ordiante.
  *    p_ordinates (sdo_ordinate_array) -- The sdo_ordinate_array to be added to the vertex list.
  *  EXAMPLE
  *    -- Add sdo_ordinate_array to existing vertex list.
  *    set serveroutput on size unlimited
  *    declare
  *      v_vList    t_vertexlist;
  *      v_vertices &&INSTALL_SCHEMA..T_Vertices;
  *      v_tgeom    t_geometry;
  *    begin
  *      v_vList    := T_VERTEXLIST(p_segment => &&INSTALL_SCHEMA..T_SEGMENT(p_line=>sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(0,0,1,1))));
  *      dbms_output.put_line('Before v_vList.count=' || v_vList.vertexList.count);
  *      v_vList.addOrdinates(
  *               p_dim     => 2,
  *               p_lrs_dim => 0,
  *               p_ordinates => sdo_ordinate_array(1,1,2,2,3,3)
  *       );
  *       dbms_output.put_line('After v_VList.count=' || v_vList.vertexList.count);
  *    end;
  *    /
  *    show errors
  *    
  *    Before v_vList.count=2
  *    After v_VList.count=5
  *    
  *    PL/SQL procedure successfully completed.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - August 2019 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Procedure addOrdinates( 
         SELF        IN OUT NOCOPY T_VERTEXLIST,
         p_dim       in integer,
         p_lrs_dim   in integer,
         p_ordinates in mdsys.sdo_ordinate_array ),

  /****m* T_VERTEXLIST/addVertices
  *  NAME
  *    addVertices -- Enables a collection of vertices to be added to the underlying list.
  *  SYNOPSIS
  *    Member Procedure addVertices(SELF       IN OUT NOCOPY &&INSTALL_SCHEMA..T_VERTEXLIST,
  *                                 p_vertices in &&INSTALL_SCHEMA..T_Vertices, 
  *                                 isForward  in ineger default 1)
  *  DESCRIPTION
  *    This procedure allows for a collection of T_VERTEX objects to be added to the underlying list.
  *    XYZM ordinates are all supported.
  *    isForward is 1, the two vertex lists are merged with no tests are carried out to see if first vertex in list to be added is same as end vertex in underlying list.
  *    However, when isForward is 2 the lists are merged with a test for duplicate coordinates.
  *    If isForward is 2, p_vertices is reversed before appending with a duplicate test carried out.
  *  ARGUMENTS
  *    p_vertices (&&INSTALL_SCHEMA..T_Vertices) -- Collection of t_vertex object to add.
  *    isForward           (boolean) -- Flag indicating whether vertices should be added in reverse order.
  *  EXAMPLE
  *    -- Add vertices of two linestrings with no test for duplicates
  *    set serveroutput on size unlimited
  *    declare
  *      v_vList    t_vertexlist;
  *      v_vertices &&INSTALL_SCHEMA..T_Vertices;
  *      v_tgeom    t_geometry;
  *    begin
  *      v_vList    := T_VERTEXLIST(p_segment => &&INSTALL_SCHEMA..T_SEGMENT(p_line=>sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(0,0,1,1))));
  *      dbms_output.put_line('Before v_vList.count=' || v_vList.vertexList.count);
  *      v_tgeom    := t_geometry(sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1,1,2,2,3,3)));
  *      select v.ST_Self() as vertex
  *        bulk collect into v_vertices
  *        from table(v_tgeom.ST_Vertices()) v;
  *       v_vList.addVertices(p_vertices  => v_vertices,
  *                           p_isForward => 1);
  *       dbms_output.put_line('After v_VList.count=' || v_vList.vertexList.count);
  *    end;
  *    /
  *    show errors
  *    
  *    Before v_vList.count=2
  *    After v_VList.count=5
  *    
  *    PL/SQL procedure successfully completed.
  *
  *    -- Now add vertices of two linestrings testing for duplicates
  *    set serveroutput on size unlimited
  *    declare
  *      v_vList    t_vertexlist;
  *      v_vertices &&INSTALL_SCHEMA..T_Vertices;
  *      v_tgeom    t_geometry;
  *    begin
  *      v_vList    := T_VERTEXLIST(p_segment => &&INSTALL_SCHEMA..T_SEGMENT(p_line=>sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(0,0,1,1))));
  *      dbms_output.put_line('Before v_vList.count=' || v_vList.vertexList.count);
  *      v_tgeom    := t_geometry(sdo_geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1,1,2,2,3,3)));
  *      select v.ST_Self() as vertex
  *        bulk collect into v_vertices
  *        from table(v_tgeom.ST_Vertices()) v;
  *       v_vList.addVertices(p_vertices  => v_vertices,
  *                           p_isForward => 2);
  *       dbms_output.put_line('After v_VList.count=' || v_vList.vertexList.count);
  *    end;
  *    /
  *    show errors
  *    
  *    Before v_vList.count=2
  *    After v_VList.count=4
  *    
  *    PL/SQL procedure successfully completed.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - July 2019 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Procedure addVertices(
            SELF        IN OUT NOCOPY T_VERTEXLIST,
            p_vertices  IN &&INSTALL_SCHEMA..T_Vertices, 
            p_isForward IN integer default 1),

  Member Procedure addSegments(
            SELF        IN OUT NOCOPY T_VERTEXLIST,
            p_vertices  IN &&INSTALL_SCHEMA..T_Vertices, 
            p_isForward IN integer default 1),
            
  /**
   * Add both points in a segment
   * 
   */

  Member Procedure addSegment(
            SELF     IN OUT NOCOPY T_VERTEXLIST,
            p_vertex in &&INSTALL_SCHEMA..T_Segment),

  /**
   * Add first offset point
   * 
   */
  Member Procedure addFirstSegment(
            SELF     IN OUT NOCOPY T_VERTEXLIST,
            p_offset in &&INSTALL_SCHEMA..T_Vertex),

  /**
   * Add last offset point
   */
  Member Procedure addLastSegment(
            SELF     IN OUT NOCOPY T_VERTEXLIST,
            p_offset in &&INSTALL_SCHEMA..T_Vertex),

  Member Procedure setPrecision(
            SELF        IN OUT NOCOPY T_VERTEXLIST,
            p_precision in integer default 3),

  Member Function getPrecision
           Return Integer deterministic,
  
  Member Procedure closeRing(SELF IN OUT NOCOPY T_VERTEXLIST),

  Member Procedure setMinimumVertexDistance(
            SELF       IN OUT NOCOPY T_VERTEXLIST,
            p_distance in number),

  Member Function getMinimumVertexDistance
          return number deterministic
)
INSTANTIABLE NOT FINAL;
/
SHOW ERRORS

set serveroutput on size unlimited
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
   v_OK       boolean := true;
   v_obj_name varchar2(30) := 'T_VERTEXLIST';
BEGIN
   FOR rec IN (select object_name,object_Type, status
                 from user_objects
                where object_name = v_obj_name
                  and object_type = 'TYPE'
               order by object_type
              )
   LOOP
      IF ( rec.status = 'VALID' ) Then
         dbms_output.put_line(rec.object_type || ' ' || USER || '.' || rec.object_name || ' is valid.');
      ELSE
         dbms_output.put_line(rec.object_type || ' ' || USER || '.' || rec.object_name || ' is invalid.');
         v_ok := false;
      END IF;
   END LOOP;
   IF ( NOT v_OK ) THEN
      RAISE_APPLICATION_ERROR(-20000,v_obj_name || ' failed to install.');
   END IF;
   EXECUTE IMMEDIATE 'GRANT EXECUTE ON &&INSTALL_SCHEMA..' || v_obj_name || ' TO public WITH GRANT OPTION';
END;
/
SHOW ERRORS

EXIT SUCCESS;

