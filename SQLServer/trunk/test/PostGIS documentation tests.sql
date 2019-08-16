use DEVDB
go

-- PostGIS documentation tests

SELECT [lrs].[STInterpolatePoint](
              geometry::STGeomFromText('LINESTRING (0 0 NULL 0, 10 0 NULL 20)',0),
			  geometry::STGeomFromText('POINT(5 5)',0),
			  DEFAULT,default 
       );
-- Answer should be 10 and is

SELECT foo.the_geom.AsTextZM() as locatedLine
  FROM (SELECT [lrs].[STLocateAlong] (
     			geometry::STGeomFromText('MULTILINESTRING((1 2 NULL 3, 3 4 NULL 2, 9 4 NULL 3),(1 2 NULL 3, 5 4 NULL 5))',0),
	            3.0 /* MEASURE */,
			    0.0 /* OFFSET */,
			    default,
			    default
		       ) As the_geom
	    ) As foo;

-- EXPECTED: MULTIPOINT M (1 2 3)
-- RESULT:          POINT (1 2 NULL 3)

--Geometry collections are difficult animals so dump them
--to make them more digestable
SELECT ST_AsText((ST_Dump(the_geom)).geom)
	FROM
	(SELECT ST_LocateAlong(
			geometry::STGeomFromText('MULTILINESTRING((1 2 NULL 3, 3 4 NULL 2, 9 4 NULL 3),(1 2 NULL 3, 5 4 NULL 5))',0),
		    3) As the_geom) As foo;

   st_asewkt
---------------
 POINTM(1 2 3)
 POINTM(9 4 3)
 POINTM(1 2 3)

 /* ST_LocateAlong needs to process and find all points within linestring to be same as PostGIS */
/* No: I don't support Measured linestring other than ascending or descending M ordinates.
*/
 SELECT the_geom.AsTextZM()
   FROM (SELECT lrs.STLocateBetween(
		          geometry::STGeomFromText('MULTILINESTRING ((1 2 NULL 3, 3 4 NULL 2, 9 4 NULL 3),(1 2 NULL 3, 5 4 NULL 5))',0),
				  1.5,  /* Start */
				  3.0,  /* End */
				  0.0   /* Offset */,
			      default,
			      default
				 ) As the_geom
		 ) As foo;
-- Me: LINESTRING (4.5 4 NULL 1.5, 9 4 NULL 3)
-- PostGIS GEOMETRYCOLLECTION M (LINESTRING M (1 2 3,3 4 2,9 4 3),POINT M (1 2 3))
