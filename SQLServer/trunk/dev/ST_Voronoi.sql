--This function uses the deldir library in R to generate voronoi polygons for an input set of points in a PostGIS table.

--Requirements: 
--  R-2.5.0 with deldir-0.0-5 installed
--  PostgreSQL-8.2.x with PostGIS-1.x and PL/R-8.2.0.4 installed

--Usage: select * from voronoi('table','point-column','id-column');

--Where:
--  'table' is the table or query containing the points to be used for generating the voronoi polygons,
--  'point-column' is a single 'POINT' PostGIS geometry type (each point must be unique)
--  'id-column' is a unique identifying integer for each of the originating points (e.g., 'gid')

--Output: returns a recordset of the custom type 'voronoi', which contains the id of the
--  originating point, and a polygon geometry

create type voronoi as (id integer, polygon geometry);

drop function st_voronoi(text,text,text); 
drop function st_voronoi(geometry); 

create or replace function st_voronoi(text) 
returns setof voronoi 
as 
'library(deldir)

 # select the point x/y coordinates into a data frame...
 points <- pg.spi.exec(sprintf("select row_number() over (order by 1) as id, ST_X(c.geom) as x, ST_Y(c.geom) as y from (SELECT (ST_DumpPoints(ST_GeomFromText(''%1$s''))).geom as geom) as c where c.geom is not null",arg1))

 # calculate an approprate buffer distance (~10%):
 buffer = ((abs(max(points$x)-min(points$x))+abs(max(points$y)-min(points$y)))/2)*(0.10)

 # get EWKB for the overall buffer of the convex hull for all points:
 buffer <- pg.spi.exec(sprintf("select st_buffer(st_convexhull(ST_GeomFromText(''%1$s'')),%2$.6f) as ewkb;",arg1,buffer))

 # the following use of deldir uses high precision and digits to prevent slivers between the output polygons, and uses 
 # a relatively large bounding box with four dummy points included to ensure that points in the peripheral areas of the  
 # dataset are appropriately enveloped by their corresponding polygons:
 voro = deldir(points$x, points$y, 
              digits=22, 
              frac=0.00000000000000000000000001,
              list(ndx=2,ndy=2), 
              rw=c(min(points$x)-abs(min(points$x)-max(points$x)), 
                   max(points$x)+abs(min(points$x)-max(points$x)), 
                   min(points$y)-abs(min(points$y)-max(points$y)), 
                   max(points$y)+abs(min(points$y)-max(points$y))))

 tiles = tile.list(voro)
 poly = array()
 id = array()
 p = 1
 for (i in 1:length(tiles)) {
    tile = tiles[[i]]
    curpoly = "POLYGON(("
    for (j in 1:length(tile$x)) {
         curpoly = sprintf("%s %.6f %.6f,",curpoly,tile$x[[j]],tile$y[[j]])
    }
    curpoly = sprintf("%s %.6f %.6f))",curpoly,tile$x[[1]],tile$y[[1]])
    # this bit will find the original point that corresponds to the current polygon, along with its id and the SRID used for the 
    # point geometry (presumably this is the same for all points)...this will also filter out the extra polygons created for the 
    # four dummy points, as they will not return a result from this query:
    ipoint <- pg.spi.exec(sprintf("select st_intersection(ST_GeomFromText(''%2$s''),''%3$s''::geometry) as polygon where st_intersects(ST_GeomFromText(''%1$s''),ST_GeomFromText(''%2$s''));",arg1,curpoly,buffer$ewkb[1]))
    if (length(ipoint) > 0)
    {
        poly[[p]] <- ipoint$polygon[1]
        id[[p]]   <- p
        p = (p + 1)
    }
 }
 return(data.frame(id,poly))
' language 'plr'
IMMUTABLE;


