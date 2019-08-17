DEFINE defaultSchema='&1'

SET VERIFY OFF;

CREATE OR REPLACE PACKAGE TIN 
AUTHID CURRENT_USER
as

  /* TODO enter package declarations (types, exceptions, methods etc) here */
  Function LineFacet(p1 in mdsys.sdo_point_type,
                     p2 in mdsys.sdo_point_type,
                     pa in mdsys.sdo_point_type,
                     pb in mdsys.sdo_point_type,
                     pc in mdsys.sdo_point_type,
                     p_precision in number := 3 )
  Return mdsys.sdo_point_type Deterministic;

  Function LineFacet(p_line      in mdsys.sdo_geometry,
                     p_facet     in mdsys.sdo_geometry,
                     p_precision in number := 3)
    Return mdsys.sdo_point_type Deterministic;
  
  Function ST_InterpolateZ (p  in mdsys.vertex_type, 
                            v0 in mdsys.vertex_type, 
                            v1 in mdsys.vertex_type, 
                            v2 in mdsys.vertex_type) 
    Return number Deterministic;

  Function ST_InterpolateZ (p  in mdsys.sdo_geometry, 
                            v0 in mdsys.sdo_geometry, 
                            v1 in mdsys.sdo_geometry, 
                            v2 in mdsys.sdo_geometry) 
    Return number Deterministic;

  Function ST_InterpolateZ(p_points in mdsys.sdo_geometry, 
                           p_facet  in mdsys.sdo_geometry ) 
    Return sdo_geometry Deterministic;

end tin;
/
show errors

create or replace
package body tin as

  c_i_unsupported          CONSTANT INTEGER       := -20101;
  c_s_unsupported          CONSTANT VARCHAR2(100) := 'Compound objects, Circles, Arcs and Optimised Rectangles currently not supported.';
  c_i_not_point            CONSTANT INTEGER       := -20102;
  c_s_not_point            CONSTANT VARCHAR2(100) := 'Input geometry is not a point';
  c_i_null_geometry        CONSTANT INTEGER       := -20103;
  c_s_null_geometry        CONSTANT VARCHAR2(100) := 'Input geometry must not be null';
  c_i_null_point_geometry  CONSTANT INTEGER       := -20104;
  c_s_null_point_geometry  CONSTANT VARCHAR2(100) := 'Input point must not be null';
  c_i_null_poly_geometry   CONSTANT INTEGER       := -20105;
  c_s_null_poly_geometry   CONSTANT VARCHAR2(100) := 'Input polygon must not be null';
  c_i_facet_poly_geometry  CONSTANT INTEGER       := -20106;
  c_s_facet_poly_geometry  CONSTANT VARCHAR2(100) := 'Facet geometry must be a single polygon.';
  c_i_facet_poly_count     CONSTANT INTEGER       := -20107;
  c_s_facet_poly_count     CONSTANT VARCHAR2(100) := 'Facet polygon must only have 3 corner points ';
  c_i_facet_no_z           CONSTANT INTEGER       := -20108;
  c_s_facet_no_z           CONSTANT VARCHAR2(100) := 'The three facet corners must have a Z value.';

  Function LineFacet(p1 in mdsys.sdo_point_type,
                     p2 in mdsys.sdo_point_type,
                     pa in mdsys.sdo_point_type,
                     pb in mdsys.sdo_point_type,
                     pc in mdsys.sdo_point_type,
                     p_precision in number := 3 )
    Return mdsys.sdo_point_type
  IS
     rndVal  constant number := TRUNC(NVL(p_precision,3));
     RTOD    constant number := 57.2957795;
     EPSILON Constant number := 0.001; /* eps 0.00001*/
     d       number /* double */;
     a1      number /* double */;
     a2      number /* double */;
     a3      number /* double */;
     total   number /* double */;
     denom   number /* double */;
     mu      number /* double */;
     n       mdsys.sdo_point_type := mdsys.sdo_point_type(0,0,0);
     pa1     mdsys.sdo_point_type := mdsys.sdo_point_type(0,0,0);
     pa2     mdsys.sdo_point_type := mdsys.sdo_point_type(0,0,0);
     pa3     mdsys.sdo_point_type := mdsys.sdo_point_type(0,0,0);
     p       mdsys.sdo_point_type := mdsys.sdo_point_type(0,0,0);

     Function vector_length(v in mdsys.sdo_point_type)
       return number /* double */
     Is
     Begin
       return sqrt(v.x*v.x + v.y*v.y + v.z*v.z);
     End vector_length;

     Function Normalise(v in mdsys.sdo_point_type)
       Return mdsys.sdo_point_type
     Is
       len      number /* double */;
       v_normal mdsys.sdo_point_type := mdsys.sdo_point_type(0,0,0);
     begin
       len := vector_length(v);
       if ( len = 0 ) then
         return v;
       end if;
       v_normal.x := v.x / len;
       v_normal.y := v.y / len;
       v_normal.z := v.z / len;
       return v_normal;
     End Normalise;

    /* **** TEST DATA *******
    SELECT TIN.LineFacet(
               MDSYS.SDO_GEOMETRY(3002,82469,null,MDSYS.SDO_ELEM_INFO_ARRAY(1,2,1),MDSYS.SDO_ORDINATE_ARRAY(455376.000,6422435.082,3.825,455376.000,6422435.082,103.825)),
               MDSYS.SDO_GEOMETRY(3003,82469,null,MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1),MDSYS.SDO_ORDINATE_ARRAY(455367.446466,6422435.812842,7,455375.477918,6422440.511886,6,455384.399922,6422428.284375,8,455367.446466,6422435.812842,7)))
      FROM DUAL;
    **/
  BEGIN
     /* Calculate the parameters for the plane */
     n.x := (pb.y - pa.y)*(pc.z - pa.z) - (pb.z - pa.z)*(pc.y - pa.y);
     n.y := (pb.z - pa.z)*(pc.x - pa.x) - (pb.x - pa.x)*(pc.z - pa.z);
     n.z := (pb.x - pa.x)*(pc.y - pa.y) - (pb.y - pa.y)*(pc.x - pa.x);
     n := Normalise(n);
     d := -(n.x * pa.x) - (n.y * pa.y) - (n.z * pa.z);

     /* Calculate the position on the line that intersects the plane */
     denom := n.x * (p2.x - p1.x) + n.y * (p2.y - p1.y) + n.z * (p2.z - p1.z);
--dbms_output.put_line('ABS(denom) = ' || ABS(denom) || ' < ' || EPSILON);
     if (ABS(denom) < EPSILON) then        /* Line and plane don't intersect */
        return NULL;
     end if;
     mu := -(d + n.x * p1.x + n.y * p1.y + n.z * p1.z) / denom;
     p.x := ROUND(p1.x + mu * (p2.x - p1.x),rndVal);
     p.y := ROUND(p1.y + mu * (p2.y - p1.y),rndVal);
     p.z := ROUND(p1.z + mu * (p2.z - p1.z),rndVal);
--DEBUGPKG.PrintPoint(p);
--dbms_output.put_line('mu ' || mu || ' < 0 or mu ' || mu || ' > 1');
     if (mu < 0 or mu > 1) then   /* Intersection not along line segment */
        return NULL;
     end if;
     /* Determine whether or not the intersection point is bounded by pa,pb,pc */
     pa1.x := pa.x - p.x;
     pa1.y := pa.y - p.y;
     pa1.z := pa.z - p.z;
--DEBUGPKG.PrintPoint(pa1);
     pa1   := Normalise(pa1);
     pa2.x := pb.x - p.x;
     pa2.y := pb.y - p.y;
     pa2.z := pb.z - p.z;
--DEBUGPKG.PrintPoint(pa2);
     pa2   := Normalise(pa2);
     pa3.x := pc.x - p.x;
     pa3.y := pc.y - p.y;
     pa3.z := pc.z - p.z;
--DEBUGPKG.PrintPoint(pa3);
     pa3   := Normalise(pa3);
     a1 := pa1.x*pa2.x + pa1.y*pa2.y + pa1.z*pa2.z;
     a2 := pa2.x*pa3.x + pa2.y*pa3.y + pa2.z*pa3.z;
     a3 := pa3.x*pa1.x + pa3.y*pa1.y + pa3.z*pa1.z;
     total := (acos(a1) + acos(a2) + acos(a3)) * RTOD;
--dbms_output.put_line('ABS(' || total || ' - 360) ' || ABS(total - 360) || ' < ' || EPSILON);
     if (ABS(total - 360) > EPSILON) then
        return NULL;
     end if;
     return p;
  END LineFacet;

  Function LineFacet(p_line      in mdsys.sdo_geometry,
                     p_facet     in mdsys.sdo_geometry,
                     p_precision in number := 3)
    Return mdsys.sdo_point_type
  IS
    v_precision      number := TRUNC(NVL(p_precision,3));
    v_line_vertices  mdsys.vertex_set_type := mdsys.sdo_util.getVertices(p_line);
    v_facet_vertices mdsys.vertex_set_type := mdsys.sdo_util.getVertices(p_facet);
  BEGIN
     Return LineFacet(mdsys.sdo_point_type(v_line_vertices(1).x, v_line_vertices(1).y, v_line_vertices(1).z),
                      mdsys.sdo_point_type(v_line_vertices(2).x, v_line_vertices(2).y, v_line_vertices(2).z),
                      mdsys.sdo_point_type(v_facet_vertices(1).x, v_facet_vertices(1).y, v_facet_vertices(1).z),
                      mdsys.sdo_point_type(v_facet_vertices(2).x, v_facet_vertices(2).y, v_facet_vertices(2).z),
                      mdsys.sdo_point_type(v_facet_vertices(3).x, v_facet_vertices(3).y, v_facet_vertices(3).z),
                      v_precision);
  END LineFacet;
  
  FUNCTION ST_InterpolateZ (p  in mdsys.vertex_type, 
                            v0 in mdsys.vertex_type, 
                            v1 in mdsys.vertex_type, 
                            v2 in mdsys.vertex_type) 
    RETURN number DETERMINISTIC
  AS 
    a   number ; 
    b   number ; 
    c   number ; 
    d   number ; 
    det number ; 
    dx  number ; 
    dy  number ; 
    t   number ; 
    u   number ; 
    z   number ; 
  BEGIN 
    IF (p is null) THEN 
       raise_application_error(c_i_null_point_geometry,c_s_null_point_geometry,true); 
    END IF ; 
    a   := v1.x - v0.x ; 
    b   := v2.x - v0.x ; 
    c   := v1.y - v0.y ; 
    d   := v2.y - v0.y ; 
    det := a * d - b * c ; 
    dx  := p .x - v0.x ; 
    dy  := p .y - v0.y ; 
    t   := ( d * dx - b * dy ) / det ; 
    u   := (-c * dx + a * dy ) / det ; 
    z   := v0.z + t * (v1.z - v0.z ) + u *(v2.z - v0.z ) ; 
    return z ; 
  END ST_InterpolateZ ; 
  
  Function ST_InterpolateZ (p  in mdsys.sdo_geometry, 
                            v0 in mdsys.sdo_geometry, 
                            v1 in mdsys.sdo_geometry, 
                            v2 in mdsys.sdo_geometry) 
    Return number 
  As
  Begin
      RETURN ST_InterpolateZ(mdsys.sdo_util.getVertices(p)(1),
                             mdsys.sdo_util.getVertices(v0)(1),
                             mdsys.sdo_util.getVertices(v1)(1),
                             mdsys.sdo_util.getVertices(v2)(1));
  End ST_InterpolateZ;
  
  FUNCTION ST_InterpolateZ(p_points in mdsys.sdo_geometry, 
                           p_facet  in mdsys.sdo_geometry ) 
    RETURN sdo_geometry DETERMINISTIC
  AS 
    v_mpoints        mdsys.VERTEX_SET_TYPE ; 
    v_fpoints        mdsys.VERTEX_SET_TYPE ; 
    v_geometry       mdsys.sdo_geometry ; 
    v_ords           pls_integer;
  BEGIN 
    if (p_points is null) Then
      raise_application_error(c_i_null_point_geometry,c_s_null_point_geometry,true);
    End If ; 
    IF (p_facet is null ) THEN 
      raise_application_error(c_i_null_poly_geometry,c_s_null_poly_geometry,true);
    End If;
    if (sdo_util.GetNumVertices(p_points) = 0 ) THEN 
       RETURN NULL ; 
    end if ; 
    if(p_points.get_gtype() NOT IN (1,5) ) THEN 
       raise_application_error(c_i_not_point,'p_point geometry (' || p_points.get_gtype() || ') can ony be Point (1) or MultiPoint (5).',true); 
    END IF ; 
    v_mpoints := sdo_util.getVertices(p_points) ; 
    if(p_facet.get_gtype() <> 3 ) THEN 
       raise_application_error(c_i_facet_poly_geometry,c_s_facet_poly_geometry,true); 
    END IF ; 
    if(sdo_util.GetNumVertices(p_facet) <> 4 ) THEN 
       raise_application_error(c_i_facet_poly_count,c_s_facet_poly_count || '(' || (sdo_util.GetNumVertices(p_facet)-1) || ').', true); 
    End If; 
    v_fpoints := sdo_util.getVertices(p_facet ) ; 
    if(v_fpoints(1) is null OR v_fpoints(2) is null OR v_fpoints(3) is null ) Then 
       raise_application_error(c_i_facet_no_z,c_s_facet_no_z,true);
    End If ; 
    IF ( v_mpoints.COUNT = 1 ) THEN
         v_geometry := new mdsys.sdo_geometry(3001, 
                                              p_points.sdo_srid , 
                                              mdsys.sdo_point_type(v_mpoints(1).x,
                                                                   v_mpoints(1).y,
                                                                   ST_InterpolateZ(v_mpoints(1),
                                                                                   v_fpoints(1), 
                                                                                   v_fpoints(2), 
                                                                                   v_fpoints(3) )
                                                                  ), 
                                              NULL,NULL); 
    ELSE
      v_geometry := new mdsys.sdo_geometry(3005, 
                                           p_points.sdo_srid , 
                                           null,
                                           new mdsys.sdo_elem_info_array(1,1,v_mpoints.COUNT),
                                           new mdsys.sdo_ordinate_array(1) ) ; 
      v_geometry.sdo_ordinates.DELETE ; 
      v_geometry.sdo_ordinates.EXTEND(v_mpoints.COUNT * 3) ; 
      v_ords := 1;
      FOR i IN 1.. v_mpoints.COUNT LOOP 
         v_geometry.sdo_ordinates(v_ords) := v_mpoints(i).x; v_ords := v_ords + 1; 
         v_geometry.sdo_ordinates(v_ords) := v_mpoints(i).y; v_ords := v_ords + 1; 
         v_geometry.sdo_ordinates(v_ords) := ST_InterpolateZ(v_mpoints(i),
                                                             v_fpoints(1), 
                                                             v_fpoints(2), 
                                                             v_fpoints(3) ) ; 
                                                             v_ords := v_ords + 1;
      END LOOP ; 
    END IF;
    RETURN v_geometry;
  END ST_InterpolateZ; 
  
end tin;
/
show errors

set serveroutput on size unlimited
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
   v_OK       boolean := true;
   v_obj_name varchar2(30) := 'TIN';
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

grant execute on Tin to public;

quit;
