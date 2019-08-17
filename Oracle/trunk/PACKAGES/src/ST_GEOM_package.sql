SET SERVEROUTPUT ON
DEFINE defaultSchema='&1'
ALTER SESSION SET plsql_optimize_level=1;

create or replace
PACKAGE ST_GEOM
AUTHID CURRENT_USER
Is

  /* @history  : Simon Greener : Dec 2009 - Added ST_StartPoint
   *                                      - Added ST_EndPoint
   *                                      - Added ST_GeometryN
   *                                      - Added ST_NumGeometries
  */
  
  /* Wrapper function over GEOM.MOVE using OGC Syntax */
  FUNCTION ST_Translate( p_geometry  IN MDSYS.ST_GEOMETRY,
                         p_tolerance IN NUMBER,
                         p_deltaX    IN NUMBER,
                         p_deltaY    IN NUMBER,
                         p_deltaZ    IN NUMBER := NULL )
    Return MDSYS.ST_GEOMETRY DETERMINISTIC;

  FUNCTION ST_Scale( p_geometry    IN MDSYS.ST_GEOMETRY,
                     p_tolerance   IN NUMBER,
                     p_XFactor     IN NUMBER,
                     p_YFactor     IN NUMBER,
                     p_ZFactor     IN NUMBER  := NULL )
    Return MDSYS.ST_GEOMETRY DETERMINISTIC;

  Function ST_Rotate( p_geometry  IN MDSYS.ST_GEOMETRY,
                      p_tolerance IN number,
                      p_rotation  IN number := 0)  -- 0 to 360 degrees
    Return MDSYS.ST_GEOMETRY Deterministic;

  FUNCTION ST_Affine( p_geom in mdsys.ST_geometry,
                      p_a number,
                      p_b number,
                      p_c number,
                      p_d number,
                      p_e number,
                      p_f number,
                      p_g number,
                      p_h number,
                      p_i number,
                      p_xoff number,
                      p_yoff number,
                      p_zoff number)
    Return MDSYS.ST_GEOMETRY DETERMINISTIC;

  /** Wrappers over GEOM.TOLERANCE */
  Function ST_SnapToGrid( p_geometry  IN MDSYS.ST_GEOMETRY,
                          p_size      IN NUMBER)
    RETURN MDSYS.ST_GEOMETRY DETERMINISTIC;

  Function ST_SnapToGrid( p_geometry  IN MDSYS.ST_GEOMETRY,
                          p_sizeX     IN NUMBER,
                          p_sizeY     IN NUMBER )
    RETURN MDSYS.ST_GEOMETRY DETERMINISTIC;

  /* ST_* Wrapper over GEOM.SDO_AddPoint */
  Function ST_AddPoint(p_geometry   IN MDSYS.ST_Geometry,
                       p_point      IN MDSYS.ST_Point,
                       p_position   IN Number )
    Return MDSYS.ST_Geometry Deterministic;

  /* ST_* Wrapper over GEOM.SDO_RemovePoint */
  -- Removes point (p_position) from a linestring. Offset is 1-based.
  Function ST_RemovePoint(p_geometry   IN MDSYS.ST_Geometry,
                          p_position   IN Number)
    Return MDSYS.ST_Geometry Deterministic;

  /* ST_* Wrapper over GEOM.SDO_SetPoint */
  -- Replace point (p_position) of linestring with given point. Index is 1-based.
  Function ST_SetPoint(p_geometry   IN MDSYS.ST_Geometry,
                       p_point      IN MDSYS.ST_Point,
                       p_position   IN Number )
    Return MDSYS.ST_Geometry Deterministic;

  /* ST_* Wrapper over GEOM.SDO_VertexUpdate */
  Function ST_VertexUpdate(p_geometry  IN MDSYS.ST_Geometry,
                           p_old_point IN MDSYS.ST_Point,
                           p_new_point IN MDSYS.ST_Point)
    Return MDSYS.ST_Geometry Deterministic;

  /* Implementation of non-existant ST_GeometryN */
  function st_geometryn ( p_geometry in mdsys.ST_GeomCollection, 
                          p_num      in integer )
  return mdsys.st_geometry deterministic;

  /* Implementation of non-existant ST_NumGeometries */
  function ST_NumGeometries ( p_geometry in mdsys.ST_GeomCollection )
    return Integer deterministic;
      
END ST_GEOM;
/

create or replace
PACKAGE BODY ST_GEOM AS

  /* Private
  **/
  Function Generate_DimInfo(p_dims        in number,
                            p_X_tolerance in number,
                            p_Y_tolerance in number := NULL,
                            p_Z_tolerance in number := NULL)
    Return mdsys.sdo_dim_array
  As
    v_Y_tolerance number := NVL(p_Y_tolerance,p_X_tolerance);
    v_Z_tolerance number := NVL(p_Z_tolerance,p_X_tolerance);
  Begin
    return case when p_dims = 2
                then MDSYS.SDO_DIM_ARRAY(MDSYS.SDO_DIM_ELEMENT('X', &&defaultSchema..Constants.c_MinVal, &&defaultSchema..Constants.c_MaxVal, p_X_tolerance),
                                         MDSYS.SDO_DIM_ELEMENT('Y', &&defaultSchema..Constants.c_MinVal, &&defaultSchema..Constants.c_MaxVal, v_Y_tolerance))
                when p_dims = 3
                then MDSYS.SDO_DIM_ARRAY(MDSYS.SDO_DIM_ELEMENT('X', &&defaultSchema..Constants.c_MinVal, &&defaultSchema..Constants.c_MaxVal, p_X_tolerance),
                                         MDSYS.SDO_DIM_ELEMENT('Y', &&defaultSchema..Constants.c_MinVal, &&defaultSchema..Constants.c_MaxVal, v_Y_tolerance),
                                         MDSYS.SDO_DIM_ELEMENT('Z', &&defaultSchema..Constants.c_MinVal, &&defaultSchema..Constants.c_MaxVal, v_Z_tolerance))
            end;
  End Generate_DimInfo;

  /* PUBLIC
  **/

  FUNCTION ST_Translate( p_geometry  IN MDSYS.ST_GEOMETRY,
                         p_tolerance IN NUMBER,
                         p_deltaX    IN NUMBER,
                         p_deltaY    IN NUMBER,
                         p_deltaZ    IN NUMBER := NULL )
    Return MDSYS.ST_GEOMETRY DETERMINISTIC AS
  BEGIN
    RETURN MDSYS.ST_GEOMETRY.FROM_SDO_GEOM(&&defaultSchema..GEOM.MOVE(p_geometry.Get_Sdo_Geom(), p_tolerance, p_deltax, p_deltaY, p_deltaZ ));
  END ST_Translate;

  FUNCTION ST_Scale( p_geometry    IN MDSYS.ST_GEOMETRY,
                     p_tolerance   IN NUMBER,
                     p_XFactor     IN NUMBER,
                     p_YFactor     IN NUMBER,
                     p_ZFactor     IN NUMBER  := NULL
                    )
    Return MDSYS.ST_GEOMETRY
  Is
  Begin
    Return MDSYS.ST_GEOMETRY.FROM_SDO_GEOM(
            &&defaultSchema..GEOM.SCALE(p_geometry.Get_Sdo_Geom(),
                               Generate_DimInfo(TRUNC(p_geometry.Get_Sdo_Geom().sdo_gtype/1000,0),p_tolerance ),
                               p_XFactor,
                               p_YFactor,
                               p_ZFactor ));
  End ST_Scale;

  Function ST_Rotate( p_geometry  IN MDSYS.ST_GEOMETRY,
                      p_tolerance IN number,
                      p_rotation  IN number := 0)  -- 0 to 360 degrees
    Return MDSYS.ST_GEOMETRY
  Is
  Begin
    Return MDSYS.ST_GEOMETRY.FROM_SDO_GEOM(
            &&defaultSchema..GEOM.Rotate(
                  p_geometry.Get_Sdo_Geom(),
                  Generate_DimInfo(TRUNC(p_geometry.Get_Sdo_Geom().sdo_gtype/1000,0),p_tolerance ),
                  NULL,
                  NULL,
                  p_rotation));
  End ST_Rotate;

  FUNCTION ST_Affine( p_geom in mdsys.ST_geometry,
                      p_a number,
                      p_b number,
                      p_c number,
                      p_d number,
                      p_e number,
                      p_f number,
                      p_g number,
                      p_h number,
                      p_i number,
                      p_xoff number,
                      p_yoff number,
                      p_zoff number)
    Return MDSYS.ST_GEOMETRY
  Is
  Begin
    Return MDSYS.ST_GEOMETRY.FROM_SDO_GEOM(
            &&defaultSchema..GEOM.Affine(
                      p_geom.Get_Sdo_Geom(),
                      p_a ,
                      p_b,
                      p_c,
                      p_d,
                      p_e,
                      p_f,
                      p_g,
                      p_h,
                      p_i,
                      p_xoff,
                      p_yoff,
                      p_zoff));
  End ST_Affine;

  Function ST_SnapToGrid( p_geometry  IN MDSYS.ST_GEOMETRY,
                          p_size      IN NUMBER)
    RETURN MDSYS.ST_GEOMETRY
  IS
  Begin
    RETURN MDSYS.ST_GEOMETRY.FROM_SDO_GEOM(
              &&defaultSchema..GEOM.Tolerance(p_geometry.Get_Sdo_Geom(),
                                     Generate_DimInfo(TRUNC(p_geometry.Get_Sdo_Geom().sdo_gtype/1000,0),p_size )));
  END ST_SnapToGrid;

  Function ST_SnapToGrid( p_geometry  IN MDSYS.ST_GEOMETRY,
                          p_sizeX     IN NUMBER,
                          p_sizeY     IN NUMBER )
    RETURN MDSYS.ST_GEOMETRY
  IS
  Begin
    RETURN MDSYS.ST_GEOMETRY.FROM_SDO_GEOM(
             &&defaultSchema..GEOM.Tolerance(p_geometry.Get_Sdo_Geom(),
                                    Generate_DimInfo(TRUNC(p_geometry.Get_Sdo_Geom().sdo_gtype/1000,0),p_sizeX,p_sizeY )));
  END ST_SnapToGrid;

  Function ST_AddPoint(p_geometry   IN MDSYS.ST_Geometry,
                       p_point      IN MDSYS.ST_Point,
                       p_position   IN Number )
    Return MDSYS.ST_Geometry
  Is
  Begin
      Return MDSYS.ST_GEOMETRY.FROM_SDO_GEOM(
            &&defaultSchema..GEOM.SDO_AddPoint(p_geometry.Get_Sdo_Geom(),
                                      &&defaultSchema..T_Vertex(p_point.ST_X(),
                                                          p_point.ST_Y(),
                                                          NULL, /* p_point.ST_Z() */
                                                          NULL, /* p_point.ST_M() */
                                                          NULL),
                                      p_position));

  End ST_AddPoint;

  -- Removes point (p_position) from a linestring. Offset is 1-based.
  Function ST_RemovePoint(p_geometry   IN MDSYS.ST_Geometry,
                          p_position   IN Number)
    Return MDSYS.ST_Geometry
  Is
  Begin
      Return MDSYS.ST_GEOMETRY.FROM_SDO_GEOM(
            &&defaultSchema..GEOM.SDO_RemovePoint(p_geometry.Get_Sdo_Geom(),
                                         p_position));
  End ST_RemovePoint;

  -- Replace point (p_position) of linestring with given point. Index is 1-based.
  Function ST_SetPoint(p_geometry   IN MDSYS.ST_Geometry,
                       p_point      IN MDSYS.ST_Point,
                       p_position   IN Number )
    Return MDSYS.ST_Geometry
    Is
  Begin
      Return MDSYS.ST_GEOMETRY.FROM_SDO_GEOM(
            &&defaultSchema..GEOM.SDO_SetPoint(p_geometry.Get_Sdo_Geom(),
                                      &&defaultSchema..T_Vertex(p_point.ST_X(),
                                                          p_point.ST_Y(),
                                                          null, /*p_point.ST_Z(),*/
                                                          null, /*p_point.ST_M(),*/
                                                          null),
                                      p_position));

  End ST_SetPoint;

  -- Replace point (p_position) of linestring with given point. Index is 1-based.
  Function ST_VertexUpdate(p_geometry   IN MDSYS.ST_Geometry,
                           p_old_point  IN MDSYS.ST_Point,
                           p_new_point  IN MDSYS.ST_Point )
    Return MDSYS.ST_Geometry
    Is
  Begin
      Return MDSYS.ST_GEOMETRY.FROM_SDO_GEOM(
            &&defaultSchema..GEOM.SDO_VertexUpdate(p_geometry.Get_Sdo_Geom(),
                                          &&defaultSchema..T_Vertex(p_old_point.ST_X(),
                                                              p_old_point.ST_Y(),
                                                              null, /*p_old_point.ST_Z(),*/
                                                              null, /*p_old_point.ST_M(),*/
                                                              null),
                                          &&defaultSchema..T_Vertex(p_new_point.ST_X(),
                                                              p_new_point.ST_Y(),
                                                              null, /*p_new_point.ST_Z(),*/
                                                              null, /*p_new_point.ST_M(),*/
                                                              null)));

  End ST_VertexUpdate;

  function st_geometryn ( p_geometry in mdsys.ST_GeomCollection, 
                          p_num      in integer )
    return mdsys.st_geometry 
  as
    v_geom mdsys.st_geometry;
    /* SELECT b.geom
         FROM TABLE(mdsys.OGC_MultiLineStringFromText('MULTILINESTRING((1 1,2 2),(3 3,4 4))', 28355).ST_Geometries()) b;
    */
  begin
    SELECT c.geom
      INTO v_geom
      FROM (SELECT rownum as rin, 
                   mdsys.ST_Geometry.From_SDO_Geom(g.geom) as geom
              FROM TABLE(SELECT p_geometry.ST_Geometries() FROM DUAL) g
            ) c
    WHERE rin = p_num;
    RETURN v_geom;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
         RETURN NULL;
  end st_geometryn;

  function ST_NumGeometries ( p_geometry in mdsys.ST_GeomCollection )
    return Integer 
  as
    v_count integer;
  begin
    SELECT count(*)
      INTO v_count
      FROM TABLE(SELECT p_geometry.ST_Geometries() FROM DUAL) g;
    RETURN v_count;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
         RETURN NULL;
  end ST_NumGeometries;

END ST_GEOM;
/
show errors

grant execute on st_geom to public;

quit;
