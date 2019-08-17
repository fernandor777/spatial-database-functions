DEFINE INSTALL_SCHEMA='&1'

SET VERIFY OFF;

WHENEVER SQLERROR EXIT FAILURE;

CREATE OR REPLACE TYPE &&INSTALL_SCHEMA..T_Grid 
AUTHID DEFINER
AS OBJECT (

/****t* OBJECT TYPE/T_GRID 
*  NAME
*    T_GRID -- Object type representing a single cell in a matrix of non-overlapping (no gaps) cells.
*  DESCRIPTION
*    An object type that represents a single cell within an array of 
*    optimized rectanges representing a grid or matrix of "raster" style objects.
*    Used mainly with T_GRIDS in PIPELINED T_GEOMETRY methods.
*  NOTES
*    No methods are declared on this type.
*  AUTHOR
*    Simon Greener
*  HISTORY
*    Simon Greener - Jan 2005 - Original coding.
*    Simon Greener - Jan 2013 - Port from GEOM Package.
*  COPYRIGHT
*    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
******/

  /****v* T_GRID/ATTRIBUTES(T_GRID) 
  *  ATTRIBUTES
  *    gCol -- Column Reference 
  *    gRow -- Row Reference
  *    geom -- SDO_GEOMETRY coded as Optimized Rectangle.
  *  SOURCE
  */
  gcol  number,
  grow  number,
  geom  mdsys.sdo_geometry
 /*******/
);
/
SHOW ERRORS

grant execute on &&INSTALL_SCHEMA..T_GRID to public with grant option;

/****s* OBJECT TYPE ARRAY/T_GRIDS 
*  NAME
*    T_GRIDS -- An array (collection/table) of T_GRIDs.
*  DESCRIPTION
*    An array of T_GRID objects that represents an array of optimized rectangles 
*    representing a grid, matrix or "raster".
*    Used mainly by PIPELINED T_GEOMETRY methods.
*  AUTHOR
*    Simon Greener
*  HISTORY
*    Simon Greener - Jan 2005 - Original coding.
*    Simon Greener - Jan 2013 - Port from GEOM Package
*  COPYRIGHT
*    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
*  SOURCE
*/
CREATE OR REPLACE TYPE &&INSTALL_SCHEMA..T_Grids 
           IS TABLE OF &&INSTALL_SCHEMA..T_Grid;
/*******/
/
show errors

grant execute on &&INSTALL_SCHEMA..t_grids to public with grant option;

exit SUCCESS;

