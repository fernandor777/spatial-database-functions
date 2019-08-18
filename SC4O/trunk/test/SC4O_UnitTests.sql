create or replace package test_sc4o
as

  --%suite(SC4O Package Test Suite)

  --%test(Test ST_GeomFromEWKT)
  procedure test_st_geomfromewkt;
  --%test(Test ST_GeomFromEWKT_Empty)
  procedure test_st_geomfromewkt_empty;

  --%test(Test ST_Delaunay)
  procedure test_st_delaunay_mgeom;
  --%test(Test ST_Voronoi)
  procedure test_ST_Voronoi_mgeom;
  --%test(Test ST_Densify)
  Procedure test_ST_Densify;
  --%test(Test ST_DouglasPeuckerSimplify)
  Procedure test_ST_DouglasPeuckerSimplify;
  --%test(Test ST_TopologyPreservingSimplify)
  Procedure ST_TopologyPreservingSimplify;
  
  --%test(Test ST_InsertVertex)
  --%throws(-29532)
  Procedure ST_InsertVertex;
  --%test(Test ST_InsertVertexException1)
  --%throws(-29532)
  Procedure ST_InsertVertexException1;
  --%test(Test ST_InsertVertex_diff_dims)
  --%throws(-29532)
  Procedure ST_InsertVertex_diff_dims;

  --%test(Test ST_UpdateVertexDimError)
  --%throws(-29532)
  Procedure ST_UpdateVertexDimError;
  --%test(Test ST_UpdateLinearRing)
  --%throws(-29532)
  Procedure ST_UpdatePolygonRing;
  --%test(Test ST_UpdateVertexSridError)
  --%throws(-29532)
  Procedure ST_UpdateVertexSridError;
  --%test(Test ST_UpdateVertexAt)
  Procedure ST_UpdateVertexAt;
  --%test(Test ST_UpdateVertex)
  Procedure ST_UpdateVertex;

  --%test(Test ST_DeleteVertexPointError)
  --%throws(-29532)
  Procedure ST_DeleteVertexPointError;
  --%test(Test ST_DeleteVertex2of3PointsError)
  --%throws(-29532)
  Procedure ST_DeleteVertex2of3PointsError;
  --%test(Test ST_DeleteVertex)
  Procedure ST_DeleteVertex;

  --%test(Test ST_LineMerger)
  Procedure ST_LineMerger;

  --%test(Test ST_PolygonBuilderParamErr)
  --%throws(-29532)
  Procedure ST_PolygonBuilderParamErr;
  --%test(Test ST_PolygonBuilder)
  Procedure ST_PolygonBuilder;

end;
/
show errors

create or replace package body test_sc4o 
as

  g_mPoint_ewkt_XYZ    varchar2(32000) := 'SRID=32615;MULTIPOINT ((755441.542258283 3678850.38541675 9.14999999944121), (755438.136705691 3679051.52458636 9.86999999918044), (755642.681431119 3678853.79096725 10.0000000018626), (755639.275877972 3679054.93014137 10), (755635.870328471 3679256.06930606 8.62999999988824), (755843.82060051 3678857.19651868 10), (755840.415056435 3679058.33568674 9.99999999906868), (755837.009506021 3679259.47485623 10), (755959.586342714 3679438.15319976 5.94999999925494), (756044.959776444 3678860.6020602 9.95000000018626), (756041.554231838 3679061.74123334 10.0000000009313), (756038.148680523 3679262.88040789 9.26999999862164))';
  g_mPoint_geom_XYZ    mdsys.sdo_geometry := MDSYS.SDO_GEOMETRY(3005,32615,NULL,MDSYS.SDO_ELEM_INFO_ARRAY(1,1,12),MDSYS.SDO_ORDINATE_ARRAY(755441.542258283,3678850.38541675,9.14999999944121,755438.136705691,3679051.52458636,9.86999999918044,755642.681431119,3678853.79096725,10.0000000018626,755639.275877972,3679054.93014137,10,755635.870328471,3679256.06930606,8.62999999988824,755843.82060051,3678857.19651868,10,755840.415056435,3679058.33568674,9.99999999906868,755837.009506021,3679259.47485623,10,755959.586342714,3679438.15319976,5.94999999925494,756044.959776444,3678860.6020602,9.95000000018626,756041.554231838,3679061.74123334,10.0000000009313,756038.148680523,3679262.88040789,9.26999999862164));
  g_lineString_geom_XY mdsys.sdo_geometry := MDSYS.SDO_GEOMETRY(2002, NULL, NULL, MDSYS.SDO_ELEM_INFO_ARRAY(1,2,1), MDSYS.SDO_ORDINATE_ARRAY(191060.535, 576339.562, 186987.358, 581000.620, 184257.910, 575373.757, 181570.453, 577305.367, 180562.657, 571300.581, 175901.599, 580958.628, 174263.930, 574575.919, 171282.533, 575037.825, 170694.652, 572266.385));
  v_mLinestring        mdsys.sdo_geometry := mdsys.sdo_geometry('MULTILINESTRING ((1.1 1.1, 2.2 2.2, 3.3 3.3), (10.0 10.0, 10.0 20.0))');
  v_2d_point           mdsys.sdo_geometry := mdsys.sdo_geometry('POINT(-1 -1)');
  v_linestring         mdsys.sdo_geometry := mdsys.sdo_geometry('LINESTRING(1.12345 1.3445,2.43534 2.03998398,3.43513 3.451245)');
  v_3d_point           mdsys.sdo_geometry := mdsys.SDO_Geometry(3001,null,sdo_point_type(4.555,4.666,10),null,null) ;
  v_before             mdsys.sdo_geometry := mdsys.SDO_Geometry(3001,null,sdo_point_type(1.12345,2.43534,3.43513),null,null);
  v_mPoint             mdsys.sdo_geometry := mdsys.SDO_Geometry(2005,null,null,sdo_elem_info_array(1,1,3),sdo_ordinate_array(1.1,1.3,2.4,2.03,3.4,3.5));
  
  procedure test_st_geomfromewkt
  As
    v_geom   mdsys.sdo_geometry;
    v_relate varchar2(100);
  Begin
    v_geom   := SC4O.ST_GeomFromEWKT(g_mPoint_ewkt_XYZ);
    v_relate := SUBSTR(sdo_geom.RELATE(v_geom,'DETERMINE',g_mPoint_geom_XYZ,0.005),1,100);
    v_relate := SUBSTR(
                  SC4O.ST_RELATE(
                    p_geom1     => v_geom,
                    p_mask      => 'DETERMINE',
                    p_geom2     => g_mPoint_geom_XYZ,
                    p_precision => 2
                  ),1,20
                );
    ut.expect( v_relate, 'Failed to compare ST_GeomFromEWKT to generated output' ).to_equal('EQUAL');
  END test_st_geomfromewkt;

  procedure test_st_geomfromewkt_empty
  As
    v_geom   mdsys.sdo_geometry;
    v_result varchar2(100);
  Begin
    v_geom   := SC4O.ST_GeomFromEWKT('POINT EMPTY',null);
    v_result := case when v_geom.sdo_gtype     is null
                      and v_geom.sdo_point     is null
                      and v_geom.sdo_elem_info is null
                      and v_geom.sdo_ordinates is null
                     then 'EMPTY'
                     else 'NOT EMPTY'
                 end;
    ut.expect( v_result, 'POINT EMPTY failed to return empty sdo_geometry' ).to_equal('EMPTY');

    -- Supply sdo_srid should still get same result
    v_geom   := SC4O.ST_GeomFromEWKT('POINT EMPTY',4283);
    v_result := case when v_geom.sdo_gtype     is null
                      and v_geom.sdo_srid      is null
                      and v_geom.sdo_point     is null
                      and v_geom.sdo_elem_info is null
                      and v_geom.sdo_ordinates is null
                     then 'EMPTY'
                     else 'NOT EMPTY'
                 end;
    ut.expect( v_result, 'POINT EMPTY with SRID failed to return empty sdo_geometry' ).to_equal('EMPTY');

  END test_st_geomfromewkt_empty;

  procedure test_st_delaunay_mgeom
  As
    v_geom mdsys.sdo_geometry;
  Begin
    v_geom := SC4O.ST_DelaunayTriangles(g_mPoint_geom_XYZ,0.05,10);
    ut.expect( sdo_util.GETNUMELEM(v_geom), 'Number of Delaunay triangles generated is not as expected.' ).to_equal(13);
  End test_st_delaunay_mgeom;

  procedure test_ST_Voronoi_mgeom
  As
    v_geom mdsys.sdo_geometry;
  Begin
    v_geom := SC4O.ST_Voronoi(g_mPoint_geom_XYZ,null,0.05,10);
    ut.expect( sdo_util.GETNUMELEM(v_geom), 'Number of Voronoi triangles generated is not as expected.' ).to_equal(12);
  End test_ST_Voronoi_mgeom;

  Procedure test_st_densify
  As
    v_geom   mdsys.sdo_geometry;
    v_result varchar2(100);
  Begin
    v_geom := SC4O.ST_Densify (
            p_geom              => g_lineString_geom_XY,
            p_precision         => 2,
            p_distanceTolerance => 90
         );
    v_result := case when sdo_util.GetNumVertices(v_geom) > sdo_util.GetNumVertices(g_lineString_geom_XY) then 'MORE' else 'LESS' end;
    ut.expect( v_result, 'Number of vertices in densified linestring is not as expected.' ).to_equal('MORE');
  End test_st_densify;

  Procedure test_ST_DouglasPeuckerSimplify
  As
    v_geom   mdsys.sdo_geometry;
    v_before mdsys.sdo_geometry;
    v_result varchar2(100);
  Begin
    v_before := mdsys.sdo_geometry('LINESTRING (638519.55 7954026.82, 638698.9 7954082.66, 638991.52 7954171.75, 638996.74 7954168.49, 639003.12 7954163.42, 639017.59 7954147.08, 639028.14 7954134.75, 639034.33 7954127.23, 639042.73 7954120.35, 639051.74 7954114.53, 639064.05 7954108.85, 639076.59 7954107.04, 639088.23 7954106.72, 639093.85 7954106.11, 639102.77 7954101.85, 639139.16 7954082.66, 639184.34 7954056.68, 639187.97 7954055.01, 639191.73 7954053.66, 639195.59 7954052.65, 639199.53 7954051.99, 639203.51 7954051.68, 639207.5 7954051.73, 639211.48 7954052.13, 639215.4 7954052.88, 639219.24 7954053.98, 639222.96 7954055.42, 639420.74 7953960.97)',29182);
    v_geom   := SC4O.ST_DouglasPeuckerSimplify(v_before,20,2);
    ut.expect( sdo_util.GetNumVertices(v_geom), 'Number of vertices after processing with ST_DouglasPeuckerSimplify is not as expected.' ).to_be_less_than(sdo_util.GetNumVertices(v_before));
  End test_ST_DouglasPeuckerSimplify;
  
  Procedure ST_TopologyPreservingSimplify
  As
    v_geom   mdsys.sdo_geometry;
    v_before mdsys.sdo_geometry;
    v_result varchar2(100);
  Begin
    v_before := mdsys.sdo_geometry('LINESTRING (638519.55 7954026.82, 638698.9 7954082.66, 638991.52 7954171.75, 638996.74 7954168.49, 639003.12 7954163.42, 639017.59 7954147.08, 639028.14 7954134.75, 639034.33 7954127.23, 639042.73 7954120.35, 639051.74 7954114.53, 639064.05 7954108.85, 639076.59 7954107.04, 639088.23 7954106.72, 639093.85 7954106.11, 639102.77 7954101.85, 639139.16 7954082.66, 639184.34 7954056.68, 639187.97 7954055.01, 639191.73 7954053.66, 639195.59 7954052.65, 639199.53 7954051.99, 639203.51 7954051.68, 639207.5 7954051.73, 639211.48 7954052.13, 639215.4 7954052.88, 639219.24 7954053.98, 639222.96 7954055.42, 639420.74 7953960.97)',29182);
    v_geom := SC4O.ST_TopologyPreservingSimplify(v_before,20,2);
    ut.expect( sdo_util.GetNumVertices(v_geom), 'Number of vertices after processing with ST_TopologyPreservingSimplify is not as expected.' ).to_be_less_than(sdo_util.GetNumVertices(v_before));
  End ST_TopologyPreservingSimplify;

  Procedure ST_InsertVertex
  As
    v_relate      varchar2(1000);
    v_geom        mdsys.sdo_geometry;
    v_pos         pls_integer;
    v_numVertices pls_integer;
  Begin
    -- At beginning
    v_geom   := SC4O.ST_InsertVertex(
                p_geom       => v_before,
                p_point      => v_3d_point,
                p_pointIndex => 1
              );
    ut.expect( mdsys.sdo_util.getNumVertices(v_before), 
               'ST_InsertVertex insert point at beginning failed as result geometry is same as before.' 
             ).to_be_less_than(mdsys.sdo_util.getNumVertices(v_geom));

    -- At end
    v_geom := SC4O.ST_InsertVertex(
                p_geom       => v_before,
                p_point      => v_3d_point,
                p_pointIndex => -1
              );
    ut.expect( mdsys.sdo_util.getNumVertices(v_before), 
               'ST_InsertVertex insert point at end failed as result geometry is same as before.' 
             ).to_be_less_than(mdsys.sdo_util.getNumVertices(v_geom));
    
    -- Add point at every position in MultiPoint
    v_numVertices := sdo_util.GetNumVertices(v_mpoint);
    for i in 1..v_numVertices+2 loop
      if ( i = (v_numVertices+2) ) Then
        v_pos := -1;
      Else
        v_pos := i;
      End If;
      v_geom := SC4O.ST_InsertVertex(
                p_geom       => v_mpoint,
                p_point      => v_3d_point,
                p_pointIndex => v_pos
              );
      ut.expect( mdsys.sdo_util.getNumVertices(v_mpoint), 
                 'ST_InsertVertex at position ' || v_pos || ' failed as result geometry is same as before.'
               ).to_be_less_than(sdo_util.getNumVertices(v_geom));
    end loop;
    
    -- Insert at the beginning of the linestring
    v_geom := SC4O.ST_InsertVertex(
                p_geom       => v_linestring,
                p_point      => v_3d_point,
                p_pointIndex => 1
              );

    -- Insert at the beginning of the MultiLineString
    v_geom := SC4O.ST_InsertVertex(
                p_geom       => v_mLinestring,
                p_point      => v_2d_point,
                p_pointIndex => 1
              );

    -- Insert at the end of the MultiLineString
    v_geom := SC4O.ST_InsertVertex(
                p_geom       => v_mLinestring,
                p_point      => mdsys.sdo_geometry('POINT(30 30)'),
                p_pointIndex => -1
              );

  End ST_InsertVertex;

  Procedure ST_InsertVertexException1
  As
    v_geom mdsys.sdo_geometry;
  Begin
    -- Test a linestring (should throw exception)
    v_geom := SC4O.ST_InsertVertex(
                p_geom       => v_linestring,
                p_point      => v_3d_point, 
                p_pointIndex => null /*Will throw exception as null interpreted as 0*/
              );
  End ST_InsertVertexException1;

  Procedure ST_InsertVertex_diff_dims
  As
    v_geom mdsys.sdo_geometry;
  Begin
    -- Dimensions different, should throw:
    -- throw new SQLException("SDO_Geometries have different coordinate dimensions."); 
    v_geom := SC4O.ST_InsertVertex(
                p_geom       => v_mLinestring,
                p_point      => v_3d_point,
                p_pointIndex => 4
              );
  End ST_InsertVertex_diff_dims;

  -- ******************************************************************************************
  
  Procedure ST_UpdateVertexDimError
  As
    v_geom mdsys.sdo_geometry;
  Begin
    v_geom := SC4O.ST_UpdateVertex(
                      mdsys.SDO_Geometry(3002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1.12345,1.3445,1,2.43534,2.03998398,2,3.43513,3.451245,3)),
                      mdsys.SDO_Geometry(2001,null,sdo_point_type(3.43513,3.451245,null),null,null),
                      mdsys.SDO_Geometry(2001,null,sdo_point_type(4.555,  4.666,  null),null,null)
              );
  End ST_UpdateVertexDimError;

  Procedure ST_UpdateVertexSridError
  As
    v_geom mdsys.sdo_geometry;
  Begin
    v_geom := SC4O.ST_UpdateVertex(
                      mdsys.SDO_Geometry(2002,8317,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1.12345,1.3445,2.43534,2.03998398,3.43513,3.451245)),
                      mdsys.SDO_Geometry(2001,null,sdo_point_type(3.43513,3.451245,null),null,null),
                      mdsys.SDO_Geometry(2001,null,sdo_point_type(4.555,  4.666,  null),null,null)
              );
  End ST_UpdateVertexSridError;

  Procedure ST_UpdatePolygonRing
  As
    v_geom mdsys.sdo_geometry;
  Begin
    -- If point first or last in existing polygon it will fail .... 
    v_geom := SC4O.ST_UpdateVertex(
                mdsys.sdo_geometry('POLYGON((2 2, 2 7, 12 7, 12 2, 2 2))',NULL),
                mdsys.SDO_Geometry(2001,null,sdo_point_type(1,1,null),null,null),
                1
              );
  End ST_UpdatePolygonRing;

  Procedure ST_UpdateVertexAt
  As
    v_relate      varchar2(100);
    v_pos         pls_integer;
    v_numVertices pls_integer;
    v_tgeom       SPDBA.T_GEOMETRY;
    v_point       MDSYS.SDO_GEOMETRY;
    v_geom        MDSYS.SDO_GEOMETRY;
    v_vertex      SPDBA.T_VERTEX;
    v_vertexN     SPDBA.T_VERTEX;
  Begin
    v_point       := mdsys.SDO_Geometry(3001,32615,sdo_point_type(4.5,4.6,4.7),null,null);
    v_vertex      := SPDBA.T_Vertex(v_point);
    v_numVertices := sdo_util.GetNumVertices(g_mPoint_geom_XYZ);
    for i in 1..v_numVertices+1 loop
      if ( i = (v_numVertices+1) ) Then
        v_pos := -1;
      Else
        v_pos := i;
      End If;
      v_tgeom := SPDBA.T_GEOMETRY(
                    SC4O.ST_UpdateVertex(
                      p_geom       => g_mPoint_geom_XYZ,
                      p_point      => v_point,
                      p_pointIndex => v_pos
                     ),
                     0.005,2,1);
      v_vertexN := SPDBA.T_Vertex(v_tgeom.ST_PointN(case when v_pos=-1 then v_numVertices else v_pos end).geom);
      ut.expect( v_vertexN.ST_AsText(), 'ST_UpdateVertex at position ' || v_pos || ' does not equal update point.' ).to_equal(v_vertex.ST_AsText());
    end loop;
  End ST_UpdateVertexAt;
  
  Procedure ST_UpdateVertex
  As
    v_relate      varchar2(100);
    v_pos         pls_integer;
    v_numVertices pls_integer;
    v_tgeom       SPDBA.T_GEOMETRY;
    v_point       MDSYS.SDO_GEOMETRY;
    v_geom        MDSYS.SDO_GEOMETRY;
  Begin
    -- ST_UpdateVertex from/to 
    v_geom := SC4O.ST_UpdateVertex(mdsys.SDO_Geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1.12345,1.3445,2.43534,2.03998398,3.43513,3.451245)),
                                   mdsys.SDO_Geometry(2001,null,sdo_point_type(3.43513,3.451245,null),null,null),
                                   mdsys.SDO_Geometry(2001,null,sdo_point_type(4.555,  4.666,  null),null,null)
              );
    v_relate := SUBSTR(
                  SC4O.ST_RELATE(
                    mdsys.SDO_Geometry(2002,null,null,sdo_elem_info_array(1,2,1),sdo_ordinate_array(1.12345,1.3445,2.43534,2.03998398,3.43513,3.451245)),
                    'EQUAL',
                    v_geom,2
                  ),1,20
                );
    ut.expect( v_relate, 'ST_UpdateVertex From/To at position ' || v_pos || ' is same as original.' ).to_equal('FALSE');

    -- LinearRing single point update return LINESTRING 
    v_geom := SC4O.ST_UpdateVertex(
                    mdsys.sdo_geometry('LINESTRING(2 2, 2 7, 12 7, 12 2, 2 2)',NULL),
                    mdsys.SDO_Geometry(2001,null,sdo_point_type(1,1,null),null,null),
                    1
               );  
    -- So up overloaded ST_UpdateVertex...
    v_geom := SC4O.ST_UpdateVertex(
                mdsys.sdo_geometry('POLYGON((2 2, 2 7, 12 7, 12 2, 2 2))',NULL),
                mdsys.SDO_Geometry(2001,null,sdo_point_type(2,2,null),null,null),
                mdsys.SDO_Geometry(2001,null,sdo_point_type(1,1,null),null,null)
              );
    v_relate := SUBSTR(sdo_geom.RELATE(v_geom,'DETERMINE',mdsys.sdo_geometry('POLYGON((1 1, 2 7, 12 7, 12 2, 1 1))',NULL),0.005),1,100);
    ut.expect( v_relate, 'ST_UpdateVertex of first/last point in polygon failed.' ).to_equal('EQUAL');
  End ST_UpdateVertex;

  Procedure ST_DeleteVertexPointError
  As
    v_geom MDSYS.SDO_GEOMETRY;
  Begin
    -- Try to remove a point from 2 point linestring (should get error)
    v_geom := SC4O.ST_DeleteVertex(mdsys.sdo_geometry('LINESTRING(1.1 1.1,2.2 2.2)',null),1);
  End ST_DeleteVertexPointError;

  Procedure ST_DeleteVertex2of3PointsError
  As
    v_geom MDSYS.SDO_GEOMETRY;
  Begin
    -- Try to remove 2 points from three point linestring (should get error)
    v_geom := SC4O.ST_DeleteVertex(
                 SC4O.ST_DeleteVertex(mdsys.sdo_geometry('LINESTRING(1.1 1.1,2.2 2.2,3.3 3.3)',null),1),
                 1);
  End ST_DeleteVertex2of3PointsError;

  Procedure ST_DeleteVertex
  As
    v_i           pls_integer;
    v_numVertices pls_integer;
    v_geom        mdsys.sdo_geometry;
  Begin
    -- Test single point
    v_geom := SC4O.ST_DeleteVertex(mdsys.SDO_Geometry(3001,null,sdo_point_type(1.1,2.4,3.5),null,null),1);

    -- Remove vertices from multipoint
    v_numVertices := sdo_util.GetNumVertices(v_mPoint);
    FOR i in 1 .. v_NumVertices+1 LOOP
      if ( i < v_numVertices ) Then
        v_i := i;
      else
        v_i := -1;
      End If; 
      v_geom := SC4O.ST_DeleteVertex(v_mPoint,v_i);
      ut.expect( sdo_util.getNumVertices(v_geom), 'ST_UpdateVertex at position ' || v_i || ' does not equal update point.' ).to_be_less_than(v_numVertices);
    END LOOP;
    
    -- Remove first coordinate in standard LineString
    v_geom := SC4O.ST_DeleteVertex(mdsys.sdo_geometry('LINESTRING(1.1 1.1,2.2 2.2,3.3 3.3)',null),1);

/*
-- Remove points 1-4 in a 3D LineString, note 0 and NULL denote is the last coord
With data as (
  select mdsys.SDO_Geometry(3002,null,null,
                            sdo_elem_info_array(1,2,1),
                            sdo_ordinate_array(1.1,1.1,9, 2.2,2.2,9, 3.3,3.3,9)) as geom 
    from dual
)
select case when LEVEL < 4 then LEVEL else -1 END  as point,
       SC4O.ST_DeleteVertex(
                  a.geom,
                  case when LEVEL < a.numVertices then LEVEL else -1 END 
       ) as RemovedPoint
  from (select sdo_util.getNumVertices(b.geom)+1 as numVertices, b.geom
          from data b
       ) a
 connect by level <= a.numVertices;
 
-- Test single polygon  
select null as removedVertex, mdsys.sdo_geometry('POLYGON((2 2, 12 2, 12 7, 2 7, 2 2))',NULL) as geom from dual
union all select 2 as removedVertex, SC4O.ST_DeleteVertex(sdo_geometry('POLYGON((2 2, 12 2, 12 7, 2 7, 2 2))',NULL),2) as geom from dual
union all select 3 as removedVertex, SC4O.ST_DeleteVertex(sdo_geometry('POLYGON((2 2, 12 2, 12 7, 2 7, 2 2))',NULL),3) as geom from dual;
*/
 End ST_DeleteVertex;

  Procedure ST_LineMerger
  As
    v_geom            mdsys.sdo_geometry;
    v_geom_collection mdsys.sdo_geometry_array;
  Begin
    select cast(multiset(
             select mdsys.sdo_geometry('LINESTRING (220 160, 240 150, 270 150, 290 170)',NULL) as geom from dual union all
             select mdsys.sdo_geometry('LINESTRING (60 210, 30 190, 30 160)',NULL) as geom from dual union all
             select mdsys.sdo_geometry('LINESTRING (70 430, 100 430, 120 420, 140 400)',NULL) as geom from dual union all
             select mdsys.sdo_geometry('LINESTRING (160 310, 160 280, 160 250, 170 230)',NULL) as geom from dual union all
             select mdsys.sdo_geometry('LINESTRING (170 230, 180 210, 200 180, 220 160)',NULL) as geom from dual union all
             select mdsys.sdo_geometry('LINESTRING (30 160, 40 150, 70 150)',NULL) as geom from dual union all
             select mdsys.sdo_geometry('LINESTRING (160 310, 200 330, 220 340, 240 360)',NULL) as geom from dual union all
             select mdsys.sdo_geometry('LINESTRING (140 400, 150 370, 160 340, 160 310)',NULL) as geom from dual union all
             select mdsys.sdo_geometry('LINESTRING (160 310, 130 300, 100 290, 70 270)',NULL) as geom from dual union all
             select mdsys.sdo_geometry('LINESTRING (240 360, 260 390, 260 410, 250 430)',NULL) as geom from dual union all
             select mdsys.sdo_geometry('LINESTRING (70 150, 100 180, 100 200)',NULL) as geom from dual union all
             select mdsys.sdo_geometry('LINESTRING (70 270, 60 260, 50 240, 50 220, 60 210)',NULL) as geom from dual union all
             select mdsys.sdo_geometry('LINESTRING (100 200, 90 210, 60 210)',NULL) as geom from dual
        ) as mdsys.sdo_geometry_array) as mLines
      into v_geom_collection 
      from dual;
    v_geom := SC4O.ST_LineMerger(v_geom_collection,3);
    ut.expect( sdo_util.getNumVertices(v_geom), 
               'ST_LineMerger does not contain expected (41) number of vertices.' 
             ).to_equal(41);
    ut.expect( sdo_util.getNumElem(v_geom),
               'ST_LineMerger does not contain expected (5) number of linestrings.' 
             ).to_equal(5);
  End ST_LineMerger;
 
  Procedure ST_PolygonBuilderParamErr
  As
    v_geom            mdsys.sdo_geometry;
    v_geom_collection mdsys.sdo_geometry_array := NULL;
  Begin
    -- No parameter value
    v_geom := SC4O.ST_Polygonbuilder(v_geom_collection,1);
  End ST_PolygonBuilderParamErr;

  Procedure ST_PolygonBuilder
  As
    v_geom            mdsys.sdo_geometry;
    v_geom_collection mdsys.sdo_geometry_array;
  Begin
    -- Create polygon from COLLECTion of lines 
    select cast(
             multiset(
               select mdsys.sdo_geometry('LINESTRING (1.0 1.0, 10.0 1.0)')   as line from dual union all
               select mdsys.sdo_geometry('LINESTRING (10.0 1.0, 10.0 10.0)') as line from dual union all
               select mdsys.sdo_geometry('LINESTRING (10.0 10.0, 1.0 10.0)') as line from dual union all
               select mdsys.sdo_geometry('LINESTRING (1.0 10.0, 1.0 1.0)')   as line from dual
             ) as mdsys.sdo_geometry_array
           ) as mLines
      into v_geom_collection 
      from dual;
    v_geom := SC4O.ST_Polygonbuilder(v_geom_collection,1);
    ut.expect( sdo_util.getNumVertices(v_geom), 
               'ST_LineMerger does not contain expected (5) number of vertices.' 
             ).to_equal(5);
    ut.expect( sdo_util.getNumElem(v_geom),
               'ST_LineMerger does not contain expected (1) number of polygons.' 
             ).to_equal(1);
  End ST_PolygonBuilder;
  
end;
/
show errors

set serveroutput on size unlimited
begin ut.run('test_sc4o'); end;
