SELECT sdo_geom.validate_geometry(ELMS_ADMIN.SPATIAL.ST_ROUNDORDINATES(VB.COORDINATES,3),0.005) AS GSIZE
  FROM VW_BOUNDARY VB 
 WHERE BOUNDARY_ID = 286095;
-- 13367 (wrong orientation of outer/inner boundaries
SELECT sdo_geom.validate_geometry(ELMS_ADMIN.SPATIAL.ST_ROUNDORDINATES(sdo_util.rectify_geometry(VB.COORDINATES,0.005),3),0.005) AS GSIZE
  FROM VW_BOUNDARY VB 
 WHERE BOUNDARY_ID = 286095;
-- TRUE
SELECT sdo_geom.validate_geometry(ELMS_ADMIN.SPATIAL.ST_ROUNDORDINATES(sdo_util.rectify_geometry(VB.COORDINATES,0.005),2),0.005) AS GSIZE
  FROM VW_BOUNDARY VB 
 WHERE BOUNDARY_ID = 286095;
-- TRUE
-- 1 DECIMAL PLACE GIVES FALSE

CREATE OR REPLACE 
FUNCTION GeoCompress(P_GEOMETRY IN SDO_GEOMETRY, P_DEC_DIGITS IN INTEGER DEFAULT 3)
RETURN SDO_GEOMETRY DETERMINISTIC
As
  v_vertices mdsys.vertex_set_type;
  v_geometry mdsys.sdo_geometry;
Begin
  v_geometry := sdo_geometry(p_geometry.sdo_gtype,
                             p_geometry.sdo_srid,
                             p_geometry.sdo_point,
                             P_GEOMETRY.SDO_ELEM_INFO,
                             new mdsys.sdo_ordinate_array());
  V_VERTICES := MDSYS.SDO_UTIL.GETVERTICES(P_GEOMETRY);
  v_geometry.sdo_ordinates.EXTEND(p_geometry.sdo_ordinates.COUNT);
  v_geometry.sdo_ordinates(1) := ROUND(v_vertices(1).x,p_dec_digits);
  v_geometry.sdo_ordinates(2) := ROUND(v_vertices(1).y,p_dec_digits);
  FOR I IN 2 .. V_VERTICES.COUNT LOOP
    V_GEOMETRY.SDO_ORDINATES(I*2-1) := ROUND(V_VERTICES(I).X-V_VERTICES(i-1).X,P_DEC_DIGITS);
    v_geometry.sdo_ordinates(i*2)   := ROUND(v_vertices(i).y-v_vertices(i-1).y,p_dec_digits);
  END LOOP;
  RETURN V_GEOMETRY;
End GeoCompress;
/
SHOW ERRORS

SELECT GeoCompress(sdo_util.rectify_geometry(VB.COORDINATES,0.005),2).get_wkt() AS GSIZE
  FROM VW_BOUNDARY VB 
 WHERE BOUNDARY_ID = 286095;

SELECT BOUNDARY_ID,
       LENGTH(GeoCompress(VB.COORDINATES,2).GET_WKT()) AS GWKT2,
       LENGTH(GeoCompress(VB.COORDINATES,3).GET_WKT()) AS GWKT3,
       LENGTH(REPLACE(GeoCompress(VB.COORDINATES,2).GET_WKT(),', ',',')) AS GWKT2S,
       LENGTH(REPLACE(GeoCompress(VB.COORDINATES,3).GET_WKT(),', ',',')) AS GWKT3S
  FROM (SELECT BOUNDARY_ID,SDO_UTIL.RECTIFY_GEOMETRY(VB.COORDINATES,0.0005) AS COORDINATES 
          FROM ELMS.VW_BOUNDARY VB 
         WHERE BOUNDARY_ID = 286095) VB;

BOUNDARY_ID      GWKT2      GWKT3     GWKT2S     GWKT3S
----------- ---------- ---------- ---------- ----------
     286095      37639      43721      34577      40659 

-- Size compared to original
SELECT ROUND(37639/109607*100,2) GWKT2, 
       ROUND(43721/109607*100,2) GWKT3,
       ROUND(34577/109607*100,2) GWKT2S, 
       ROUND(40659/109607*100,2) GWKT3S
  FROM DUAL;

     GWKT2      GWKT3     GWKT2S     GWKT3S
---------- ---------- ---------- ----------
     34.34      39.89      31.55       37.1 
     
SELECT BOUNDARY_ID,
       LENGTH(GeoCompress(VB.COORDINATES,2).GET_WKB()) AS GWKT2,
       LENGTH(GeoCompress(VB.COORDINATES,3).get_WKB()) AS GWKT3
  FROM (SELECT BOUNDARY_ID,
               SDO_UTIL.RECTIFY_GEOMETRY(VB.COORDINATES,0.0005) AS COORDINATES 
          FROM ELMS.VW_BOUNDARY VB 
         WHERE BOUNDARY_ID = 286095) VB

BOUNDARY_ID      GWKT2      GWKT3
----------- ---------- ----------
     286095      49021      49021
     
SELECT ROUND((109607-49021)/109607*100,2) FROM DUAL; 
-- Saving of 55.28

-- Note: WKB Coding may give no additional benefit.

-- ELM06NP
SELECT VB.BOUNDARY_NAME, VB.BOUNDARY_TYPE,SDO_GEOM.VALIDATE_GEOMETRY(ELMS_ADMIN.SPATIAL.ST_ROUNDORDINATES(VB.COORDINATES,3),0.005) AS GSIZE
  FROM elms.VW_BOUNDARY VB 
 WHERE BOUNDARY_ID = 286095;

set long 8192
SELECT SDO_CS.TRANSFORM(WSBOUNDARY.GETNETWORKBOUNDARYGEOMETRY ('SAM','2ABN-03'),4283).GET_WKT() AS G4283 FROM DUAL;
-- Ordinates like -34.5450070000235 need to be rounded to 6 decimal places -34.545007
-- select round(-34.5450070000235,6) from dual;
SELECT LENGTH(SDO_CS.TRANSFORM(WSBOUNDARY.GETNETWORKBOUNDARYGEOMETRY ('SAM','2ABN-03'),4283).GET_WKT()) AS G4283 FROM DUAL;
--      G4283
-- ----------
--      10929
SELECT LENGTH(ELMS_ADMIN.SPATIAL.ST_ROUNDORDINATES(SDO_CS.TRANSFORM(WSBOUNDARY.GETNETWORKBOUNDARYGEOMETRY ('SAM','2ABN-03'),4283),6).GET_WKT()) AS G4283 FROM DUAL;
--      G4283
-- ----------
--       8335 
SELECT LENGTH(REPLACE(ELMS_ADMIN.SPATIAL.ST_ROUNDORDINATES(SDO_CS.TRANSFORM(WSBOUNDARY.GETNETWORKBOUNDARYGEOMETRY ('SAM','2ABN-03'),4283),6).GET_WKT(),', ',',')) AS G4283 FROM DUAL;
--      G4283
-- ----------
--       7971
SELECT SDO_GEOMETRY(REPLACE(ELMS_ADMIN.SPATIAL.ST_ROUNDORDINATES(SDO_CS.TRANSFORM(WSBOUNDARY.GETNETWORKBOUNDARYGEOMETRY ('SAM','2ABN-03'),4283),6).GET_WKT(),', ',','),4283) AS G4283 FROM DUAL;
-- OK
SET LONG 8192
SELECT GeoCompress(ELMS_ADMIN.SPATIAL.ST_ROUNDORDINATES(SDO_CS.TRANSFORM(ELMS_WS.WSBOUNDARY.GETNETWORKBOUNDARYGEOMETRY ('SAM','2ABN-03'),4283),6),6).GET_WKT() AS G4283 FROM DUAL;
SELECT 0.001473 * 1000 FROM DUAL;
-- ie can apply multiplier to deltas
SELECT LENGTH(REPLACE(GeoCompress(ELMS_ADMIN.SPATIAL.ST_ROUNDORDINATES(SDO_CS.TRANSFORM(ELMS_WS.WSBOUNDARY.GETNETWORKBOUNDARYGEOMETRY ('SAM','2ABN-03'),4283),6),6).GET_WKT(),', ',',')) AS G4283 FROM DUAL;
--      G4283
-- ----------
--       6064

DROP FUNCTION GeoCompress;

CREATE FUNCTION GeoCompress(P_GEOMETRY     IN SDO_GEOMETRY, 
                               P_DEC_DIGITS   IN INTEGER DEFAULT 3,
                               p_delta_factor in number default 1)
RETURN SDO_GEOMETRY DETERMINISTIC
AS
  V_VERTICES     MDSYS.VERTEX_SET_TYPE;
  V_GEOMETRY     MDSYS.SDO_GEOMETRY;
  v_delta_factor number := NVL(p_delta_factor,1);
Begin
  v_geometry := sdo_geometry(p_geometry.sdo_gtype,
                             p_geometry.sdo_srid,
                             p_geometry.sdo_point,
                             P_GEOMETRY.SDO_ELEM_INFO,
                             new mdsys.sdo_ordinate_array());
  V_VERTICES := MDSYS.SDO_UTIL.GETVERTICES(P_GEOMETRY);
  v_geometry.sdo_ordinates.EXTEND(p_geometry.sdo_ordinates.COUNT);
  v_geometry.sdo_ordinates(1) := ROUND(v_vertices(1).x,p_dec_digits);
  v_geometry.sdo_ordinates(2) := ROUND(v_vertices(1).y,p_dec_digits);
  FOR I IN 2 .. V_VERTICES.COUNT LOOP
    V_GEOMETRY.SDO_ORDINATES(I*2-1) := ROUND(V_DELTA_FACTOR * (V_VERTICES(I).X-V_VERTICES(I-1).X),P_DEC_DIGITS);
    v_geometry.sdo_ordinates(i*2)   := ROUND(v_delta_factor * (v_vertices(i).y-v_vertices(i-1).y),p_dec_digits);
  END LOOP;
  RETURN V_GEOMETRY;
End GeoCompress;
/
SHOW ERRORS

SELECT REPLACE(GeoCompress(ELMS_ADMIN.SPATIAL.ST_ROUNDORDINATES(SDO_CS.TRANSFORM(ELMS_WS.WSBOUNDARY.GETNETWORKBOUNDARYGEOMETRY ('SAM','2ABN-03'),4283),6),6,1000).GET_WKT(),', ',',') AS G4283 FROM DUAL;
-- G4283                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- POLYGON ((150.789076 -34.545028,1.708 0.217,1.473 -0.196,1.045 -1.27,0.947 -1.698,0.826 -1.155,2.088 -1.709,0.079 0.03,

SELECT LENGTH(REPLACE(GeoCompress(ELMS_ADMIN.SPATIAL.ST_ROUNDORDINATES(SDO_CS.TRANSFORM(ELMS_WS.WSBOUNDARY.GETNETWORKBOUNDARYGEOMETRY ('SAM','2ABN-03'),4283),6),6,1000).GET_WKT(),', ',',')) AS G4283 FROM DUAL;
--      G4283
-- ----------
--       4752 

SELECT SDO_GEOMETRY(REPLACE(GeoCompress(ELMS_ADMIN.SPATIAL.ST_ROUNDORDINATES(SDO_CS.TRANSFORM(ELMS_WS.WSBOUNDARY.GETNETWORKBOUNDARYGEOMETRY ('SAM','2ABN-03'),4283),6),6,1000).GET_WKT(),', ',','),4283) AS G4283 FROM DUAL;
-- It converts so we can reverse the process, but it won't validate.
SELECT SDO_GEOM.validate_geometry(SDO_GEOMETRY(REPLACE(GeoCompress(ELMS_ADMIN.SPATIAL.ST_ROUNDORDINATES(SDO_CS.TRANSFORM(ELMS_WS.WSBOUNDARY.GETNETWORKBOUNDARYGEOMETRY ('SAM','2ABN-03'),4283),6),6,1000).GET_WKT(),', ',','),4283),0.05) AS G4283 FROM DUAL;
-- G4283
-- -----
-- 13348

CREATE OR REPLACE 
FUNCTION GEOUnCOMPRESS(P_GEOMETRY     IN SDO_GEOMETRY, 
                       P_DEC_DIGITS   IN INTEGER DEFAULT 3,
                       p_delta_factor in number default 1)
RETURN SDO_GEOMETRY DETERMINISTIC
AS
  V_VERTICES     MDSYS.VERTEX_SET_TYPE;
  V_GEOMETRY     MDSYS.SDO_GEOMETRY;
  v_delta_factor number := NVL(p_delta_factor,1);
Begin
  v_geometry := sdo_geometry(p_geometry.sdo_gtype,
                             p_geometry.sdo_srid,
                             p_geometry.sdo_point,
                             P_GEOMETRY.SDO_ELEM_INFO,
                             new mdsys.sdo_ordinate_array());
  V_VERTICES := MDSYS.SDO_UTIL.GETVERTICES(P_GEOMETRY);
  V_GEOMETRY.SDO_ORDINATES.EXTEND(P_GEOMETRY.SDO_ORDINATES.COUNT);
  v_geometry.sdo_ordinates(1) := v_vertices(1).x;
  v_geometry.sdo_ordinates(2) := v_vertices(1).y;
  FOR I IN 2 .. V_VERTICES.COUNT LOOP
    V_GEOMETRY.SDO_ORDINATES(I*2-1) := ROUND(V_GEOMETRY.SDO_ORDINATES((I-1)*2-1) + (V_VERTICES(I).X/V_DELTA_FACTOR),P_DEC_DIGITS);
    V_GEOMETRY.SDO_ORDINATES(I*2)   := ROUND(V_GEOMETRY.SDO_ORDINATES((I-1)*2  ) + (V_VERTICES(I).y/V_DELTA_FACTOR),P_DEC_DIGITS);
  END LOOP;
  RETURN V_GEOMETRY;
End GeoUnCompress;
/
SHOW ERRORS

SELECT GEOUNCOMPRESS(SDO_GEOMETRY(REPLACE(GEOCOMPRESS(ELMS_ADMIN.SPATIAL.ST_ROUNDORDINATES(SDO_CS.TRANSFORM(ELMS_WS.WSBOUNDARY.GETNETWORKBOUNDARYGEOMETRY ('SAM','2ABN-03'),4283),6),6,1000).GET_WKT(),', ',','),4283),6,1000).GET_WKT() AS G4283 FROM DUAL;
G4283
----------------------------------------------------------------------------------------------------------------------------------
POLYGON ((150.789076 -34.545028, 150.790784 -34.544811, 150.792257 -34.545007, 150.793302 -34.546277, 150.794249 -34.547975, [...]

SELECT ELMS_ADMIN.SPATIAL.ST_ROUNDORDINATES(SDO_CS.TRANSFORM(ELMS_WS.WSBOUNDARY.GETNETWORKBOUNDARYGEOMETRY ('SAM','2ABN-03'),4283),6).GET_WKT() AS G4283 FROM DUAL;
G4283
----------------------------------------------------------------------------------------------------------------------------------
POLYGON ((150.789076 -34.545028, 150.790784 -34.544811, 150.792257 -34.545007, 150.793302 -34.546277, 150.794249 -34.547975, [...]

-- sAME
