USE [$(usedbname)]
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sys.objects
            WHERE object_id = OBJECT_ID(N'[$(owner)].[STRemoveDuplicatePoints]') 
              AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')
)
BEGIN
  DROP FUNCTION [$(owner)].[STRemoveDuplicatePoints];
  PRINT 'Dropped [$(owner)].[STRemoveDuplicatePoints] ...';
END;
GO

PRINT 'Creating [$(owner)].[STRemoveDuplicatePoints] ...';
GO

CREATE FUNCTION [$(owner)].[STRemoveDuplicatePoints]
(
  @p_geometry geometry,
  @p_round_xy int = 3,
  @p_round_z  int = 2,
  @p_round_m  int = 3
)
Returns geometry
As
/****f* EDIT/STRemoveDuplicatePoints (2008)
 *  NAME
 *    STRemoveDuplicatePoints -- Function which removes duplicate points from a linestring.
 *  SYNOPSIS
 *    Function [$(owner)].[STRemoveDuplicatePoints] (
 *               @p_geometry geometry,
 *               @p_round_xy int = 3,
 *               @p_round_z  int = 2,
 *               @p_round_m  int = 2
 *             )
 *     Returns geometry
 *  USAGE
 *    select 'Text XY Ordinates' as test, [$(owner)].[STRemoveDuplicatePoints](geometry::STGeomFromText('LINESTRING(0 0,1 1,1 1,2 2)',0),3,null,null).AsTextZM() as fixedLine
 *    union all
 *    select 'Test XY ordinates of XYZ' as test, [$(owner)].[STRemoveDuplicatePoints](geometry::STGeomFromText('LINESTRING(0 0 0,1 1 1,1 1 1.1,2 2 2)',0),3,null,null).AsTextZM() as fixedLine
 *    union all
 *    select 'Test XYZ ordinates of XYZ with Z digits that maintains Z' as test, [$(owner)].[STRemoveDuplicatePoints](geometry::STGeomFromText('LINESTRING(0 0 0,1 1 1,1 1 1.1,2 2 2)',0),3,2,null).AsTextZM() as fixedLine
 *    union all
 *    select 'Test XYZ ordinates of XYZ with Z digits that does not maintain Z' as test, [$(owner)].[STRemoveDuplicatePoints](geometry::STGeomFromText('LINESTRING(0 0 0,1 1 1,1 1 1.1,2 2 2)',0),3,0,null).AsTextZM() as fixedLine
 *    union all
 *    select 'Test XY ordinates of XYZM with precision that ignores Z and M differences' as test, [$(owner)].[STRemoveDuplicatePoints](geometry::STGeomFromText('LINESTRING(0 0 0 0,1 1 1 1,1 1 1.1 1.1,2 2 2.1 2.1)',0),3,null,null).AsTextZM() as fixedLine
 *    union all
 *    select 'Test XYZ ordinates of XYZM with Z digits that maintains Z but ignores M differences' as test, [$(owner)].[STRemoveDuplicatePoints](geometry::STGeomFromText('LINESTRING(0 0 0 0,1 1 1 1,1 1 1.1 1.1,2 2 2.1 2.1)',0),3,2,null).AsTextZM() as fixedLine
 *    union all
 *    select 'Test XYM ordinates of XYZM with M digits that maintains M but ignores Z differences' as test, [$(owner)].[STRemoveDuplicatePoints](geometry::STGeomFromText('LINESTRING(0 0 0 0,1 1 1 1,1 1 1.1 1.1,2 2 2.1 2.1)',0),3,null,1).AsTextZM() as fixedLine
 *    union all
 *    select 'Test XYMZ ordinates of XYZM with Z/M digits that maintains Z/M' as test, [$(owner)].[STRemoveDuplicatePoints](geometry::STGeomFromText('LINESTRING(0 0 0 0,1 1 1 1,1 1 1.1 1.1,2 2 2.1 2.1)',0),3,1,1).AsTextZM() as fixedLine
 *    go
 *
 *    test	fixedLine
 *    ----------------------------------------------------------------------------------- -------------------------------------------------------
 *    Text XY Ordinates                                                                   LINESTRING (0 0, 1 1, 2 2)
 *    Test XY ordinates of XYZ                                                            LINESTRING (0 0 0, 1 1 1, 2 2 2)
 *    Test XYZ ordinates of XYZ with Z digits that maintains Z                            LINESTRING (0 0 0, 1 1 1, 1 1 1.1, 2 2 2)
 *    Test XYZ ordinates of XYZ with Z digits that does not maintain Z                    LINESTRING (0 0 0, 1 1 1, 2 2 2)
 *    Test XY ordinates of XYZM with precision that ignores Z and M differences           LINESTRING (0 0 0 0, 1 1 1 1, 2 2 2.1 2.1)
 *    Test XYZ ordinates of XYZM with Z digits that maintains Z but ignores M differences LINESTRING (0 0 0 0, 1 1 1 1, 1 1 1.1 1.1, 2 2 2.1 2.1)
 *    Test XYM ordinates of XYZM with M digits that maintains M but ignores Z differences LINESTRING (0 0 0 0, 1 1 1 1, 1 1 1.1 1.1, 2 2 2.1 2.1)
 *    Test XYMZ ordinates of XYZM with Z/M digits that maintains Z/M                      LINESTRING (0 0 0 0, 1 1 1 1, 1 1 1.1 1.1, 2 2 2.1 2.1)
 *    
 *  DESCRIPTION
 *    Function that removes any duplicate vertices in the supplied linestring.
 *    When comparing two adjacent points, the ordinates are compared to the supplied @p_round_xy and @p_round_z/m digits of precision.
 *    All ordinates are included in the comparison not just XY unless @p_round_z or @p_round_m is null.
 *  INPUTS
 *    @p_geometry (geometry) - Supplied geometry of type linestring.
 *    @p_round_xy (int)      - Decimal degrees of precision to which calculated XY ordinates are compared.
 *    @p_round_z  (int)      - Decimal degrees of precision to which calculated Z ordinates are compared.
 *    @p_round_m  (int)      - Decimal degrees of precision to which calculated M ordinates are compared.
 *  RESULT
 *    fixed line  (geometry) - Corrected input geometry.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - February 2018 - Original TSQL Coding for SQL Server.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
 ******/
Begin
  Declare
     @v_wkt            varchar(max) = '',
     @v_wkt_remainder  varchar(max),
	 @v_GeometryType   varchar(100),
     @v_dimensions     varchar(4),
     @v_round_xy       int = 3,
     @v_pos            int = 0,
	 @v_isEqual        bit = 0,
     @v_point          geometry,
	 @v_previous_point geometry;
  Begin
    If ( @p_geometry is NULL )
      Return @p_geometry;

    SET @v_GeometryType = @p_geometry.STGeometryType();
    IF ( @v_GeometryType NOT IN ('LineString','CircularString','CompoundCurve','MultiLineString') )
      Return @p_geometry;

    SET @v_dimensions = 'XY'
                        + case when @p_geometry.HasZ=1 then 'Z' else '' end +
                        + case when @p_geometry.HasM=1 then 'M' else '' end;

    SET @v_round_xy = ISNULL(@p_round_xy,3);

	SET @v_wkt_remainder = @p_geometry.AsTextZM();
    SET @v_wkt           = SUBSTRING(@v_wkt_remainder,1,CHARINDEX('(',@v_wkt_remainder));
    SET @v_wkt_remainder = SUBSTRING(@v_wkt_remainder,  CHARINDEX('(',@v_wkt_remainder)+1,LEN(@v_wkt_remainder));

    WHILE ( LEN(@v_wkt_remainder) > 0 )
    BEGIN
       -- Is the start of v_wkt_remainder a coordinate?
	   IF ( @v_wkt_remainder like '[-0-9]%' )
 	   BEGIN
         -- We have a coord
         -- Now get position of end of coordinate string
         SET @v_pos = case when CHARINDEX(',',@v_wkt_remainder) = 0
                           then CHARINDEX(')',@v_wkt_remainder)
                           when CHARINDEX(',',@v_wkt_remainder) <> 0 and CHARINDEX(',',@v_wkt_remainder) < CHARINDEX(')',@v_wkt_remainder)
                           then CHARINDEX(',',@v_wkt_remainder)
                           else CHARINDEX(')',@v_wkt_remainder)
                       end;
         -- Create a geometry point from WKT coordinate string
         SET @v_point = geometry::STPointFromText(
		                  'POINT('
                          +
                          SUBSTRING(@v_wkt_remainder,1,@v_pos-1)
                          +
                          ')',
                          @p_geometry.STSrid);
         SET @v_isEqual = 0;
         IF ( @v_previous_point is not null ) 
		 BEGIN
		   IF ( @v_dimensions = 'XY'
                AND ROUND(@v_point.STX,@v_round_xy) = ROUND(@v_previous_point.STX,@v_round_xy) 
		        AND ROUND(@v_point.STY,@v_round_xy) = ROUND(@v_previous_point.STY,@v_round_xy) )
             SET @v_isEqual = 1;
           IF ( @v_dimensions = 'XYZ' 
				AND ROUND(@v_point.STX,@v_round_xy) = ROUND(@v_previous_point.STX,@v_round_xy) 
		        AND ROUND(@v_point.STY,@v_round_xy) = ROUND(@v_previous_point.STY,@v_round_xy)
				AND ( @p_round_z is null 
				 OR ( @p_round_z is not null AND ROUND(@v_point.Z, @p_round_z) = ROUND(@v_previous_point.Z,  @p_round_z) ) 
				)
			  )
			 SET @v_isEqual = 1;
           IF ( @v_dimensions = 'XYZM' 
		        AND ROUND(@v_point.STX,@v_round_xy) = ROUND(@v_previous_point.STX,@v_round_xy) 
		        AND ROUND(@v_point.STY,@v_round_xy) = ROUND(@v_previous_point.STY,@v_round_xy)
		        AND ( @p_round_z is null 
				 OR ( @p_round_z is not null AND ROUND(@v_point.Z, @p_round_z) = ROUND(@v_previous_point.Z,  @p_round_z) ) 
				)
				AND ( @p_round_m is null 
				 OR ( @p_round_m is not null AND ROUND(@v_point.M, @p_round_m) = ROUND(@v_previous_point.M,  @p_round_m) ) 
				)
              )
			 SET @v_isEqual = 1;
		 END;
		 IF ( @v_isEqual = 0 ) 
 		 BEGIN
           -- Add to WKT
           SET @v_wkt   = @v_wkt
                          +
                          [$(owner)].[STPointGeomAsText] (
                                /* @p_point      */ @v_point,
                                /* @p_round_xy   */ @p_round_xy,
                                /* @p_round_z    */ @p_round_z,
                                /* @p_round_m    */ @p_round_m
                          );
         END;
		 -- Now remove the old coord from v_wkt_remainder
		 SET @v_wkt_remainder  = SUBSTRING(@v_wkt_remainder,@v_pos,LEN(@v_wkt_remainder));
		 SET @v_previous_point = @v_point;
       END
	   ELSE
	   BEGIN
	     -- Move to next character
		 IF ( @v_isEqual = 0 ) 
		   SET @v_wkt           = @v_wkt + SUBSTRING(@v_wkt_remainder,1,1);
		 SET @v_wkt_remainder = SUBSTRING(@v_wkt_remainder,2,LEN(@v_wkt_remainder));
	   END;
	END; -- Loop
    Return geometry::STGeomFromText(@v_wkt,@p_geometry.STSrid);
  End;
End
GO

PRINT 'Testing [$(owner)].[STRemoveDuplicatePoints] ...';
GO

-- ********************************************************************
select geometry::STGeomFromText('LINESTRING(0 0,1 1,1 1,2 2)',0) as line;
select geometry::STGeomFromText('LINESTRING(0 0,1 1,1 1,2 2)',0).STNumPoints() as line;
select geometry::STGeomFromText('LINESTRING(0 0,1 1,1 1,2 2)',0).STIsValid() as line;
select geometry::STGeomFromText('LINESTRING(0 0,1 1,1 1,2 2)',0).MakeValid().STNumPoints() as line;

select 'Text XY Ordinates' as test, [$(owner)].[STRemoveDuplicatePoints](geometry::STGeomFromText('LINESTRING(0 0,1 1,1 1,2 2)',0),3,null,null).AsTextZM() as fixedLine
union all
select 'Test XY ordinates of XYZ' as test, [$(owner)].[STRemoveDuplicatePoints](geometry::STGeomFromText('LINESTRING(0 0 0,1 1 1,1 1 1.1,2 2 2)',0),3,null,null).AsTextZM() as fixedLine
union all
select 'Test XYZ ordinates of XYZ with Z digits that maintains Z' as test, [$(owner)].[STRemoveDuplicatePoints](geometry::STGeomFromText('LINESTRING(0 0 0,1 1 1,1 1 1.1,2 2 2)',0),3,2,null).AsTextZM() as fixedLine
union all
select 'Test XYZ ordinates of XYZ with Z digits that does not maintain Z' as test, [$(owner)].[STRemoveDuplicatePoints](geometry::STGeomFromText('LINESTRING(0 0 0,1 1 1,1 1 1.1,2 2 2)',0),3,0,null).AsTextZM() as fixedLine
union all
select 'Test XY ordinates of XYZM with precision that ignores Z and M differences' as test, [$(owner)].[STRemoveDuplicatePoints](geometry::STGeomFromText('LINESTRING(0 0 0 0,1 1 1 1,1 1 1.1 1.1,2 2 2.1 2.1)',0),3,null,null).AsTextZM() as fixedLine
union all
select 'Test XYZ ordinates of XYZM with Z digits that maintains Z but ignores M differences' as test, [$(owner)].[STRemoveDuplicatePoints](geometry::STGeomFromText('LINESTRING(0 0 0 0,1 1 1 1,1 1 1.1 1.1,2 2 2.1 2.1)',0),3,2,null).AsTextZM() as fixedLine
union all
select 'Test XYM ordinates of XYZM with M digits that maintains M but ignores Z differences' as test, [$(owner)].[STRemoveDuplicatePoints](geometry::STGeomFromText('LINESTRING(0 0 0 0,1 1 1 1,1 1 1.1 1.1,2 2 2.1 2.1)',0),3,null,1).AsTextZM() as fixedLine
union all
select 'Test XYMZ ordinates of XYZM with Z/M digits that maintains Z/M' as test, [$(owner)].[STRemoveDuplicatePoints](geometry::STGeomFromText('LINESTRING(0 0 0 0,1 1 1 1,1 1 1.1 1.1,2 2 2.1 2.1)',0),3,1,1).AsTextZM() as fixedLine
go

QUIT
GO
