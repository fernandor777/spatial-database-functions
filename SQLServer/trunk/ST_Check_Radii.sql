CREATE OR REPLACE FUNCTION adageo.check_radii(p_geom       geometry, 
                                              p_min_radius Float, 
                                              p_precision  int)
  RETURNS geometry 
AS
/** ----------------------------------------------------------------------------------------
  * @function   : check_radii
  * @precis     : Function that checks vertices in a linestring/multilinestring to see if
  *                the circular arc they describe have radius less than the provided amount.
  *               Each set of three vertices (which could be overlapping) that fail the test
  *               are written to a single MultiPoint object. If no circular arcs in the linestring
  *               describe a circle with radius less than the required amount a NULL geometry is returned.
  *               If another other than a (Multi)linestring is provided it is returned as is. 
  * @version    : 1.0
  * @usage      : Function check_radii(p_geom       geometry,
  *                                     p_min_radius Float,
  *                                     p_precision  int )
  *                 Return geometry 
  *               eg SELECT [qgc].[CheckRadii](geometry::STGeomFromText('LINESTRING(0.0 0.0,10.0 0.0,10.0 10.0)',0), 15.0,3).STAsText();
  * @param      : p_geom       : Projected (Multi)Linestring geometry
  * @paramtype  : p_geom       : geometry
  * @param      : p_min_radius : A not null value that describes the minimum radiue of any arc within the linestring.
  * @paramtype  : p_min_radius : Float
  * @param      : p_precision  : Precision of any XY value ie number of significant digits. If null then 3 is assumed (ie 1 mm): 3456.2345245 -> 3456.235 
  * @paramtype  : p_precision  : Int
  * @return     : mpoint_geom  : Projected 2D MultiPoint geometry
  * @rtnType    : mpoint_geom  : geometry
  * @note       : Supplied geometry must not be geographic: function only guaranteed for projected data.
  * @note       : Does not honour dimensions over 2.
  * @history    : Simon Greener - May 2011 - Original coding.
  * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License. (http://creativecommons.org/licenses/by-sa/2.5/au/)
**/
$BODY$
DECLARE
    v_badRadii       int = 0;
    v_GeometryType   varchar(1000);
    v_WKT            text;
    v_geomn          int;
    v_first          int;
    v_second         int;
    v_third          int;
    v_srid           int;
    v_geom           geometry;
    v_srt_point      geometry;
    v_mid_point      geometry;
    v_end_point      geometry;
    v_cx             float;
    v_cy             float;
    v_radius         float;
    v_precision      integer = CASE WHEN p_precision IS NULL THEN 3 ELSE p_precision END;
    v_format_string  varchar(50);
BEGIN
    v_format_string := 'FM999999999999.' || rpad('',3,'9');
    If ( p_geom is NULL ) Then
      return NULL;
    End If;

    If ( p_min_radius is null ) Then
      return p_geom;
    End If;
    
    v_GeometryType := ST_GeometryType(p_geom);
    If ( v_GeometryType in ('ST_Point','ST_MultiPoint','ST_GeometryCollection','ST_Polygon','ST_MultiPolygon' ) ) Then
       return NULL;
    End If;

    If ( ST_NumPoints(p_geom) < 3 ) Then
      return NULL;
    End If;

    v_srid := ST_Srid(p_geom);
    v_WKT  := 'MULTIPOINT(';
    IF ( v_GeometryType = 'ST_LineString' ) THEN
      v_badRadii := 0;
      v_first    := 1;
      v_second   := 2;
      v_third    := 3;
      WHILE ( v_third <= ST_NumPoints(p_geom) ) LOOP
        v_srt_point := ST_PointN(p_geom,v_first);
        v_first     := v_first  + 1;
        v_mid_point := ST_PointN(p_geom,v_second);
        v_second    := v_second + 1;
        v_end_point := ST_PointN(p_geom,v_third);
        v_third     := v_third  + 1;
        v_radius    := -1;
        -- Call FindCircle
	SELECT ST_X(c.circle) as CX, ST_Y(c.circle) as CY, ST_Z(c.circle)  
	  INTO v_cx, v_cy, v_radius
	  FROM (SELECT adageo.find_circle(ST_MakePoint(ROUND(ST_X(v_srt_point)::numeric,v_precision::integer),
				                       ROUND(ST_Y(v_srt_point)::numeric,v_precision::integer)),
			                  ST_MakePoint(ROUND(ST_X(v_mid_point)::numeric,v_precision::integer),
					               ROUND(ST_Y(v_mid_point)::numeric,v_precision::integer)),
			                  ST_MakePoint(ROUND(ST_X(v_end_point)::numeric,v_precision::integer),
				                       ROUND(ST_Y(v_end_point)::numeric,v_precision::integer))) as circle
	  ) as c;
        IF ( v_radius IS NOT NULL AND v_radius <> -1 AND v_radius < p_min_radius ) THEN
          v_badRadii := v_badRadii + 1;
          IF ( v_WKT <> 'MULTIPOINT(' ) THEN
             v_WKT := v_WKT || ',';
          END IF;
          v_WKT := v_WKT ||
	        '(' || to_char(ST_X(v_srt_point)::double precision,v_format_string) || ' ' ||
	               to_char(ST_Y(v_srt_point)::double precision,v_format_string) || 
	      '),(' || to_char(ST_X(v_mid_point)::double precision,v_format_string) || ' ' ||
                       to_char(ST_Y(v_mid_point)::double precision,v_format_string) ||
              '),(' || to_char(ST_X(v_end_point)::double precision,v_format_string) || ' ' ||
                       to_char(ST_Y(v_end_point)::double precision,v_format_string) ||
                 ')';
        END IF;
      END LOOP; 
      v_WKT := v_WKT || ')';
      IF ( v_badRadii = 0 ) THEN
          RETURN NULL;
      ELSE
          RETURN ST_GeomFromText(v_WKT,v_srid);
      END IF;
    END IF;
    IF ( v_GeometryType = 'ST_MultiLineString' ) THEN
      v_geomn := 1;
      WHILE ( v_geomn <= ST_NumGeometries(p_geom) ) LOOP
        v_badRadii := 0;
        v_geom     := ST_GeometryN(p_geom,v_geomn);
        v_geomn    := v_geomn + 1;
        v_first    := 1;
        v_second   := 2;
        v_third    := 3;
        IF ( ST_NumPoints(v_geom) < 3 ) THEN
           -- Skip this geometry
           CONTINUE;
        END IF;
        WHILE ( v_third <= ST_NumPoints(v_geom) ) LOOP
           v_srt_point  := ST_PointN(v_geom,v_first);
           v_first      := v_first  + 1;
           v_mid_point  := ST_PointN(v_geom,v_second);
           v_second     := v_second + 1;
           v_end_point  := ST_PointN(v_geom,v_third);
           v_third      := v_third  + 1;
           -- Call FindCircle
           v_radius     := -1;
           SELECT ST_X(c.circle) as CX, ST_Y(c.circle) as CY, ST_Z(c.circle)  
             INTO v_cx, v_cy, v_radius
             FROM (SELECT adageo.find_circle(ST_MakePoint(ROUND(ST_X(v_srt_point)::numeric,v_precision::integer),
				                          ROUND(ST_Y(v_srt_point)::numeric,v_precision::integer)),
				             ST_MakePoint(ROUND(ST_X(v_mid_point)::numeric,v_precision::integer),
						          ROUND(ST_Y(v_mid_point)::numeric,v_precision::integer)),
				             ST_MakePoint(ROUND(ST_X(v_end_point)::numeric,v_precision::integer),
						          ROUND(ST_Y(v_end_point)::numeric,v_precision::integer))) as circle
                  ) as c;
           IF ( v_radius IS NOT NULL AND v_radius <> -1 AND v_radius < p_min_radius ) THEN
              v_badRadii := v_badRadii + 1;
              IF ( v_WKT <> 'MULTIPOINT(' ) THEN
                 v_WKT := v_WKT || ',';
              END IF;
              v_WKT := v_WKT ||
                      '(' || to_char(ST_X(v_srt_point)::double precision,v_format_string) ||  ' '  || 
                             to_char(ST_Y(v_srt_point)::double precision,v_format_string) || '),(' ||
                             to_char(ST_X(v_mid_point)::double precision,v_format_string) ||  ' '  ||
                             to_char(ST_Y(v_mid_point)::double precision,v_format_string) || '),(' || 
                             to_char(ST_X(v_end_point)::double precision,v_format_string) ||  ' '  ||
                             to_char(ST_Y(v_end_point)::double precision,v_format_string) || 
                      ')';
           END IF;
        END LOOP;
      END LOOP; 
      v_WKT := v_WKT || ')' ;
      IF ( v_badRadii = 0 ) THEN
         RETURN NULL;
      Else
         RETURN ST_GeomFromText(v_WKT,v_srid);
      END IF;
    END IF;
    RETURN NULL;
End
$BODY$
  LANGUAGE plpgsql VOLATILE STRICT
  COST 100;

select ST_X(c.circle) as CX, ST_Y(c.circle) as CY, ST_Z(c.circle) as radius
  from (select adageo.Find_Circle(ST_MakePoint(0.0,0.0), 
                                  ST_MakePoint(10.0,0.0), 
                                  ST_MakePoint(10.0,10.0)) as circle 
        ) as c;
          
SELECT ST_GeometryType(ST_GeomFromText('LINESTRING(0.0 0.0,10.0 0.0,10.0 10.0)',0));

SELECT ST_AsText(adageo.Check_Radii(ST_GeomFromText('LINESTRING(0.0 0.0,10.0 0.0,10.0 10.0)',0),15.0,3));

SELECT ST_AsText(adageo.Check_Radii(ST_GeomFromText('MULTILINESTRING((0.0 0.0,10.0 0.0,10.0 10.0),(20.0 0.0,30.0 0.0,30.0 10.0))',0), 15.0,3)); 
