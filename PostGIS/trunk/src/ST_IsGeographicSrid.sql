DROP FUNCTION IF EXISTS spdba.ST_IsGeographicSrid(int);

CREATE FUNCTION spdba.ST_IsGeographicSrid
( 
  p_srid int 
)
Returns int
/****f* TOOLS/STIsGeographicSrid (2012)
 *  NAME
 *    STIsGeographicSrid -- Checks p_srid to see if exists in sys.spatial_reference_systems table (which holds geodetic SRIDS)
 *  SYNOPSIS
 *    Function STIsGeographicSrid (
 *               p_srid int 
 *             )
 *     Returns int 
 *  USAGE
 *    SELECT [$(owner)].[STIsGeographicSrid](4283) as isGeographicSrid
 *    GO
 *    isGeographicSrid
 *    ----------------
 *    1
 *  DESCRIPTION
 *    All geographic/geodetic SRIDs are stored in the sys.spatial_reference_systems table.
 *    This function checks to see if the supplied SRID is in that table. 
 *    If it is, 1 is returned otherwise 0.
 *  INPUTS
 *    p_srid (int) - Srid value.
 *  RESULT
 *    Y/N    (int) - 1 if True; 0 if False
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - June 2018     - Original TSQL Coding for SQL Server.
 *    Simon Greener - February 2019 - Original pgPLSQL Coding for PostGIS
 *  COPYRIGHT
 *    (c) 2008-2019 by TheSpatialDBAdvisor/Simon Greener
******/
As
$$
Declare 
  v_is_geographic_srid int;
Begin
  If ( p_srid is null ) Then
    Return 0;
  End If;
  select count(*) 
    into v_is_geographic_srid 
    from public.spatial_ref_sys 
   where srid = p_srid;
  Return case when v_is_geographic_srid = 0 then 0 else 1 end;
END $$
LANGUAGE plpgsql
STABLE
RETURNS NULL ON NULL INPUT;


SELECT 4283 as srid,case when spdba.ST_IsGeographicSrid(4283)=1 then 'Geographic' else 'Geometry' end as isGeographic;



