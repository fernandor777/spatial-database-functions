USE [$(usedbname)]
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sys.objects
            WHERE object_id = OBJECT_ID(N'[$(owner)].[STAddZ]') 
              AND type in (N'FN', N'IF', N'TF', N'FS', N'FT')
)
BEGIN
  DROP FUNCTION [$(owner)].[STAddZ];
  PRINT 'Dropped [$(owner)].[STAddZ] ...';
END;
GO

PRINT 'Creating [$(owner)].[STAddZ] ...';
GO

CREATE FUNCTION [$(owner)].[STAddZ]
(
  @p_linestring geometry,
  @p_start_z    float,
  @p_end_z      float,
  @p_round_xy   int = 3,
  @p_round_zm   int = 2
)
Returns geometry
As
/****f* EDITOR/STAddZ (2012)
 *  NAME
 *    STAddZ -- Function that adds elevation (Z) ordinates to the supplied linestring.
 *  SYNOPSIS
 *    Function STAddZ (
 *               @p_linestring geometry,
 *               @p_start_z    float,
 *               @p_end_z      float,
 *               @p_round_xy   int = 3,
 *               @p_round_zm   int = 2
 *             )
 *     Returns geometry 
 *  USAGE
 *    SELECT [$(owner)].[STAddZ] (
 *             geometry::STGeomFromText('LINESTRING(0 0,0.5 0.5,1 1)',0),
 *             1.232,
 *             1.523,
 *             3, 
 *             2 
 *           ).AsTextZM() as LineWithZ;
 *    LineWithZ
  *   ---------------------------------------------
 *    LINESTRING (0 0 1.23, 0.5 0.5 1.38, 1 1 1.52)
 *  DESCRIPTION
 *    Function that add elevation values to the ordinates of the supplied p_linestring.
 *    Supports LineString, CircularString, CompoundCurve geometries
 *    If geometry already has elevation/Z values is returned unchanged.
 *    Start Point is assigned @p_start_Z and End Point is assigned @p_end_Z.
 *    If @p_start_Z or @p_end_Z is null, the original linestring is returned.
 *    Intermediate Points' measure values are calculated based on length calculations.
 *    The updated coordinate's XY ordinates are rounded to p_round_xy number of decimal digits of precision.
 *    The updated coordinate's ZM ordinates are rounded to p_round_ZM number of decimal digits of precision.
 *  INPUTS
 *    @p_linestring     (geometry) - Supplied Linestring geometry.
 *    @p_start_z           (float) - New Start Z Value.
 *    @p_end_z             (float) - New End Z value.
 *    @p_round_xy            (int) - Decimal degrees of precision to which calculated XY ordinates are rounded.
 *    @p_round_zm            (int) - Decimal degrees of precision to which calculated ZM ordinates are rounded.
 *  RESULT
 *    linestring with Z (geometry) - Input linestring with measures applied.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original TSQL Coding for SQL Spatial.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @v_geometry_type     varchar(100),
    @v_wkt               varchar(max),
    @v_dimensions        varchar(4),
    @v_round_xy          int,
    @v_round_zm          int,
    @v_mid_arc_length    float,
    @v_last_Z            float,
    @v_range_z           float,
    @v_isGeography       bit,

    /* STSegmentLine Variables*/
    @v_id               int,
    @v_max_id           int,
    @v_multi_tag        varchar(100),
    @v_element_id       int,
    @v_prev_element_id  int,
    @v_element_tag      varchar(100),
    @v_prev_element_tag varchar(100),
    @v_subelement_id    int,
    @v_subelement_tag   varchar(100),
    @v_segment_id       int, 
    @v_sx               float,  /* Start Point */
    @v_sy               float,
    @v_sz               float,
    @v_sm               float,
    @v_mx               float,  /* Mid Point */
    @v_my               float,
    @v_mz               float,
    @v_mm               float,
    @v_ex               float,  /* End Point */
    @v_ey               float,
    @v_ez               float,
    @v_em               float,
    @v_length           float,
    @v_startLength      float,
    @v_measureRange     float,
    @v_segment_geom     geometry,

    @v_geom_length      float = 0,
    @v_return_geom      geometry;
  Begin
    If ( @p_linestring is null ) 
      Return @p_linestring;

    /* Nothing to do if start or end Z is null */
    IF ( @p_start_Z is null or @p_end_Z is null )
      Return @p_linestring;

    -- Only makes sense to snap a point to a linestring
    If ( @p_linestring.STDimension() <> 1 ) 
      Return @p_linestring;

    /* Nothing to do if already has elevations */
    IF ( @p_linestring.HasZ=1 )
      Return @p_linestring;

    -- Only process linear geometries.
    SET @v_geometry_type = @p_linestring.STGeometryType();
    IF ( @v_geometry_type NOT IN ('LineString',
                                  'CircularString',
                                  'CompoundCurve',
                                  'MultiLineString') )
      Return @p_linestring;

    SET @v_isGeography = [$(owner)].[STIsGeographicSrid](@p_linestring.STSrid);
    SET @v_geom_length = case when @v_isGeography=1
                              then geography::STGeomFromText(@p_linestring.AsTextZM(),@p_linestring.STSrid).STLength()
                              else @p_linestring.STLength()
                          end;
    SET @v_range_z     = @p_end_Z - @p_start_Z;
    SET @v_round_xy    = ISNULL(@p_round_xy,3);
    SET @v_round_zm    = ISNULL(@p_round_zm,2);
    SET @v_dimensions  = 'XYZ' + case when @p_linestring.HasM=1 then 'M' else '' end;

    -- Walk over all the segments of the linear geometry
    DECLARE cSegments 
     CURSOR FAST_FORWARD 
        FOR
     SELECT max(v.id) over (partition by v.multi_tag) as max_id,
            v.id,            v.multi_tag,
            v.element_id,    v.element_tag,
            v.subelement_id, v.subelement_tag,
            v.segment_id, 
            v.sx, v.sy, v.sz, v.sm,
            v.mx, v.my, v.mz, v.mm,
            v.ex, v.ey, v.ez, v.em,
            v.length,
            v.startLength,
            v.measureRange,
            v.geom
       FROM [$(owner)].[STSegmentLine](@p_linestring) as v
      ORDER by v.element_id, 
               v.subelement_id, 
               v.segment_id

   OPEN cSegments;

   FETCH NEXT 
    FROM cSegments 
    INTO @v_max_id,
         @v_id,            @v_multi_tag,
         @v_element_id,    @v_element_tag, 
         @v_subelement_id, @v_subelement_tag, 
         @v_segment_id, 
         @v_sx, @v_sy, @v_sz, @v_sm, 
         @v_mx, @v_my, @v_mz, @v_mm,
         @v_ex, @v_ey, @v_ez, @v_em,
         @v_length,
         @v_startLength,
         @v_measureRange,
         @v_segment_geom;

   SET @v_prev_element_tag = UPPER(@v_element_tag);
   SET @v_prev_element_id  = @v_element_id;
   SET @v_wkt              = UPPER(case when @v_multi_tag is not null then @v_multi_tag else @v_element_tag end) 
                             + 
                             case when @v_multi_tag = 'MultiLineString' then ' ((' else ' (' end
                             + 
                             case when @v_multi_tag = 'CompoundCurve' 
                                  then case when @v_element_tag = 'LineString' then '(' else @v_element_tag + ' (' end 
                                  else '' 
                              end
                             +
                             [$(owner)].[STPointAsText] (
                               /* @p_dimensions XY, XYZ, XYM, XYZM or NULL (XY) */ @v_dimensions,
                               /* @p_X          */ @v_sx,
                               /* @p_Y          */ @v_sy,
                               /* @p_Z          */ @p_start_Z,
                               /* @p_M          */ @v_sm,
                               /* @p_round_x    */ @v_round_xy,
                               /* @p_round_y    */ @v_round_xy,
                               /* @p_round_z    */ @v_round_zm,
                               /* @p_round_m    */ @v_round_zm
                             )
                             + 
                             ',';
   SET @v_last_Z = @p_start_Z;

   WHILE @@FETCH_STATUS = 0
   BEGIN

     IF ( @v_element_tag <> @v_prev_element_tag 
       or @v_element_id  <> @v_prev_element_id )
     BEGIN
       SET @v_wkt = @v_wkt + '), ' + case when @v_element_tag = 'CircularString' then 'CIRCULARSTRING(' else '(' end;
       -- First Coord of new element segment.
       --
       SET @v_wkt = @v_wkt + 
                    [$(owner)].[STPointAsText] (
                      /* @p_dimensions XY, XYZ, XYM, XYZM or NULL (XY) */ @v_dimensions,
                      /* @p_X          */ @v_sx,
                      /* @p_Y          */ @v_sy,
                      /* @p_Z          */ @v_last_Z,
                      /* @p_M          */ @v_sm,
                      /* @p_round_x    */ @v_round_xy,
                      /* @p_round_y    */ @v_round_xy,
                      /* @p_round_z    */ @v_round_zm,
                      /* @p_round_m    */ @v_round_zm
                    )
                    + 
                    ',';
     END
     ELSE
     BEGIN
       IF ( @v_segment_id > 1 ) 
         SET @v_wkt = @v_wkt + ',';
     END;

     -- Is this a circularArc?
     IF ( @v_segment_geom.STGeometryType() = 'CircularString' and @v_mx is not null) 
     BEGIN
       -- compute and write mid vertex of curve
       SET @v_mid_arc_length = [$(cogoowner)].[STComputeLengthToMidPoint] ( @v_segment_geom );
       SET @v_mz             = @v_last_Z + @v_mid_arc_length; 
       SET @v_last_Z         = @v_mz;
       -- Print out new point
       SET @v_wkt = @v_wkt + 
                    [$(owner)].[STPointAsText] (
                       /* @p_dimensions XY, XYZ, XYM, XYZM or NULL (XY) */ @v_dimensions,
                       /* @p_X          */ @v_mx,
                       /* @p_Y          */ @v_my,
                       /* @p_Z          */ @v_mz,
                       /* @p_M          */ @v_mm,
                       /* @p_round_x    */ @v_round_xy,
                       /* @p_round_y    */ @v_round_xy,
                       /* @p_round_z    */ @v_round_zm,
                       /* @p_round_m    */ @v_round_zm
                    )
                    +
                    ',';
       SET @v_length = @v_length - @v_mid_arc_length;
     END;

     -- Compute next/last measure
     SET @v_ez     = case when @v_id = @v_max_id 
                          then @p_end_Z
                          else @v_last_Z + (@v_range_z * ( (@v_startLength+@v_length) / @v_geom_length )) 
                      end;
     SET @v_last_Z = @v_ez;

     -- Print out new point
     SET @v_wkt = @v_wkt + 
                  [$(owner)].[STPointAsText] (
                    /* @p_dimensions XY, XYZ, XYM, XYZM or NULL (XY) */ @v_dimensions,
                    /* @p_X          */ @v_ex,
                    /* @p_Y          */ @v_ey,
                    /* @p_Z          */ @v_ez,
                    /* @p_M          */ @v_em,
                    /* @p_round_x    */ @v_round_xy,
                    /* @p_round_y    */ @v_round_xy,
                    /* @p_round_z    */ @v_round_zm,
                    /* @p_round_m    */ @v_round_zm
                   );

     SET @v_prev_element_tag = @v_element_tag;
     SET @v_prev_element_id  = @v_element_id;

     FETCH NEXT 
      FROM cSegments 
      INTO @v_max_id,
           @v_id,            @v_multi_tag,
           @v_element_id,    @v_element_tag, 
           @v_subelement_id, @v_subelement_tag, 
           @v_segment_id, 
           @v_sx, @v_sy, @v_sz, @v_sm, 
           @v_mx, @v_my, @v_mz, @v_mm,
           @v_ex, @v_ey, @v_ez, @v_em,
           @v_length,
           @v_startLength,
           @v_measureRange,
           @v_segment_geom;
   END;
   CLOSE cSegments
   DEALLOCATE cSegments
   SET @v_wkt = @v_wkt + ')';
   IF ( @v_multi_tag is not null ) 
     SET @v_wkt = @v_wkt + ')';
   Return geometry::STGeomFromText(@v_wkt,@p_linestring.STSrid);
  End;
END
GO

PRINT 'Testing [$(owner).[STAddZ] ...';
GO

SELECT [$(owner)].[STAddZ] (
            geometry::STGeomFromText('LINESTRING(0 0,0.5 0.5,1 1)',0),
            1.232,
            1.523,
            3, 
            2 
       ).AsTextZM() as LineWithZ;
GO

QUIT
GO
