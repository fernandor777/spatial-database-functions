USE [$(usedbname)]
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER OFF
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner([$(owner)])';
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(owner)].[STRemoveSpikesByWKT]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STRemoveSpikesByWKT];
  PRINT 'Dropped [$(owner)].[STRemoveSpikesByWKT] ...';
END;
GO

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(owner)].[STRemoveSpikes]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STRemoveSpikes];
  PRINT 'Dropped [$(owner)].[STRemoveSpikes] ...';
END;

IF EXISTS (
    SELECT * 
      FROM sysobjects 
     WHERE id = object_id(N'[$(owner)].[STRemoveSpikesAsGeog]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STRemoveSpikesAsGeog];
  PRINT 'Dropped [$(owner)].[STRemoveSpikesAsGeog] ...';
END;

PRINT '*********************************************';
PRINT 'Creating [$(owner)].[STRemoveSpikesByWKT] ...';
GO

Create Function [$(owner)].[STRemoveSpikesByWKT]
(
  @p_linestring      varchar(max),
  @p_srid            int   = 0,
  @p_angle_threshold float = 0.5,
  @p_round_xy        int   = 3,
  @p_round_z         int   = 2,
  @p_round_m         int   = 2 
)
Returns varchar(max)
As
/****f* EDITOR/STRemoveSpikesByWKT (2012)
 *  NAME
 *    STRemoveSpikesByWKT -- Function that removes spikes and unnecessary points that lie on straight line between adjacent points.
 *  SYNOPSIS
 *    Function [$(owner)].[STRemoveSpikesByWKT] (
 *               @p_linestring          varchar(max),
 *               @p_srid                int,
 *               @p_angle_threshold     float = 0.5,
 *               @p_round_xy            int   = 3,
 *               @p_round_z             int   = 1,
 *               @p_round_m             int   = 3
 *             )
 *     Returns varchar(max) 
 *  USAGE
 *    with data as (
 *      select 'LINESTRING(0 0,1 0,2 0,2.1 0,2.2 10.0,2.3 0,3 0)' as geomWKT
 *    )
 *    select 'Angle Threshold' as test, [$(owner)].[STRemoveSpikesByWKT](a.geomWKT,0,3.0,3,2,2) as rsWKT from data as a
 *    union all
 *    select 'Original Line'   as test, c.geom from data as c
 *    go
 *    
 *    test              rsWKT
 *    --------------- ---------------------------------------------
 *    Angle Threshold LINESTRING (0 0, 1 0, 2 0, 2.1 0, 2.3 0, 3 0)
 *  DESCRIPTION
 *    This function tests rolling 3 point line segments to detect spikes.
 *    Spikes are detected where the subtended angle between the segments is less 
 *    than a user provided threshold value (degrees), @p_angle_threshold, the mid point is removed.
 *    The updated coordinate's XY ordinates are rounded to p_round_xy number of decimal digits of precision.
 *    The updated coordinate's Z ordinate is rounded to p_round_Z number of decimal digits of precision.
 *    The updated coordinate's M ordinate is rounded to p_round_M number of decimal digits of precision.
 *  NOTES
 *    The function only processes linestrings not CircularStrings or CompoundCurves.
 *    The function additionally removes any duplicate points from the input linestring cf STRemoveDuplicatePoints
 *  INPUTS
 *    @p_linestring   (varchar max) - Supplied Linestring geography.
 *    @p_srid                 (int) - Srid of @p_linetsring WKT
 *    @p_angle_threshold    (float) - Smallest subtended angle allowed. If mid point angle is < @p_angle_threshold the mid-point is removed.
 *    @p_round_xy             (int) - Decimal degrees of precision to which calculated XY ordinates are rounded.
 *    @p_round_z              (int) - Decimal degrees of precision to which calculated ZM ordinates are rounded.
 *    @p_round_m              (int) - Decimal degrees of precision to which calculated ZM ordinates are rounded.
 *  RESULT
 *    Linestring WKT  (varchar max) - Input linestring with any spikes removed
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - February 2018 - Original TSQL Coding for SQL Spatial.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @v_wkt                varchar(max),
    @v_wkt_remainder      varchar(max),
    @v_next_char          varchar(1),
    @v_last_char          varchar(1),
    @v_srid               int,
    @v_round_xy           int,
    @v_round_z            int,
    @v_round_m            int,
    @v_pos                int,
    @v_subtended_angle    float,
    @v_angle_threshold    float,
    @v_point              geometry,
    @v_point_1            geometry,
    @v_point_2            geometry,
    @v_point_3            geometry,
    @v_test_geog          geography;
  Begin
    SET @v_srid     = ISNULL(@p_srid,0);
    SET @v_round_xy = ISNULL(@p_round_xy,3);
    SET @v_round_z  = ISNULL(@p_round_z,1);
    SET @v_round_m  = ISNULL(@p_round_m,3);

    If ( @p_linestring is null OR @p_linestring = 'LINESTRING EMPTY' ) 
    BEGIN
      Return 'LINESTRING EMPTY';
    END;

    -- Only process linear geometries.
    IF (  @p_linestring NOT LIKE 'LINESTRING%' )
    BEGIN
      Return @p_linestring;
    END;

    SET @v_angle_threshold = ISNULL(@p_angle_threshold,0.5);
    SET @v_angle_threshold = [$(cogoowner)].[STNormalizeBearing](ABS(@p_angle_threshold));
    IF ( @v_angle_threshold > 180.0 )
    BEGIN
      SET @v_angle_threshold = @v_angle_threshold - 180;
    END;

    -- ********************************************************************************************* 
    -- Special Cases
    --
    SET @v_wkt_remainder = @p_linestring;
    SET @v_wkt           = SUBSTRING(@v_wkt_remainder,1,CHARINDEX('(',@v_wkt_remainder));
    SET @v_wkt_remainder = SUBSTRING(@v_wkt_remainder,  CHARINDEX('(',@v_wkt_remainder)+1,LEN(@v_wkt_remainder));

    -- 1. 1 or 2 Point Linestring
    -- 
    IF ( len(@v_wkt_remainder) - len(replace(@v_wkt_remainder,',','') ) IN (0,1) /* ie One or Two points only */ )
    BEGIN
      Return @p_linestring;
    END;

    -- 2. 3 Point Linestring
    -- 
    IF ( len(@v_wkt_remainder) - len(replace(@v_wkt_remainder,',','') ) = 2 /* ie Three points only */ )
    BEGIN
       -- Create a geography point from WKT coordinate string
       -- Get point 1 and remove from WKT
       SET @v_pos           = CHARINDEX(',',@v_wkt_remainder);
       SET @v_point_1       = geometry::STPointFromText( 'POINT(' +  SUBSTRING(@v_wkt_remainder,1,@v_pos-1) + ')', @v_Srid);
       SET @v_wkt_remainder = SUBSTRING(@v_wkt_remainder,@v_pos+1,LEN(@v_wkt_remainder));
       -- Get Point 2 and then remove from WKT
       SET @v_pos           = CHARINDEX(',',@v_wkt_remainder);
       SET @v_point_2       = geometry::STPointFromText( 'POINT(' +  SUBSTRING(@v_wkt_remainder,1,@v_pos-1) + ')', @v_Srid);
       SET @v_wkt_remainder = SUBSTRING(@v_wkt_remainder,@v_pos+1,LEN(@v_wkt_remainder));
       -- Get Point 3
       SET @v_pos           = CHARINDEX(')',@v_wkt_remainder);
       SET @v_point_3       = geometry::STPointFromText( 'POINT(' +  SUBSTRING(@v_wkt_remainder,1,@v_pos-1) + ')', @v_Srid);

          -- We have three points to test...

       -- Are they all equal?
       IF ( @v_point_1.STEquals(@v_point_2)=1
         AND @v_point_1.STEquals(@v_point_3)=1 )
       BEGIN
         Return @v_point_1.AsTextZM();
       END;

       -- Compute angle between three points
       SET @v_subtended_angle = ABS(
                                    [$(cogoowner)].[STDegrees] ( 
                                        [$(cogoowner)].[STSubtendedAngleByPoint] (
                                          @v_point_1,
                                          @v_point_2,
                                          @v_point_3
                                        )
                                      )
                                  );
       IF ( @v_subtended_angle <= @v_angle_threshold )
       BEGIN
         -- Mid Point is a spike.
         -- Test if first and last point are equal.
         If ( @v_point_1.STEquals(@v_point_3)=1 )
         BEGIN
           -- Write first and second.
           Return [$(owner)].[STMakeLine] ( 
                    @v_point_1, 
                    @v_point_2, 
                    @v_round_xy, @v_round_z 
                  ).AsTextZM();
         END;
         -- Otherwise remove @v_point_2 and write first and last.
         return [$(owner)].[STMakeLine] ( 
                  @v_point_1, 
                  @v_point_3, 
                  @v_round_xy, @v_round_z
                ).AsTextZM();
       END;
       -- No spike, write original linestring
       Return @p_linestring;
    END;

    -- Process longer linestrings.
    WHILE ( LEN(@v_wkt_remainder) > 0 )
    BEGIN
       -- Is the start of @v_wkt_remainder a coordinate?
       IF ( @v_wkt_remainder Not like '[-0-9]%' ) 
       BEGIN
         -- Discard spaces 
         -- 
         SET @v_next_char = SUBSTRING(@v_wkt_remainder,1,1);
         IF ( @v_next_char in (' ',',' )  )
         BEGIN
           SET @v_wkt_remainder = SUBSTRING(@v_wkt_remainder,2,LEN(@v_wkt_remainder));
           CONTINUE;
         END;

         -- Now check for end character
         -- If ) Then end of linestring so write it out.
         IF ( @v_next_char = ')' ) 
         BEGIN
            -- Write out remaining points
            IF ( @v_point_1 is not null )
            BEGIN
              SET @v_wkt = @v_wkt 
                           +
                           [$(owner)].[STPointGeomAsText] (
                             /* @p_point    */ @v_point_1,
                             /* @p_round_xy */ @v_round_xy,
                             /* @p_round_z  */ @v_round_z,
                             /* @p_round_m  */ @v_round_m
                           )
                           +
                           case when @v_point_2 is not null 
                                 and @v_point_2.STEquals(@v_point_1) = 0 
                                then ', ' 
                                else '' 
                             end;
            END;
            IF ( @v_point_2 is not null )
            BEGIN
              IF ( @v_point_2.STEquals(@v_point_1) = 0 )
              BEGIN
                SET @v_wkt = @v_wkt 
                             +
                             [$(owner)].[STPointGeomAsText] (
                               /* @p_point    */ @v_point_2,
                               /* @p_round_xy */ @v_round_xy,
                               /* @p_round_z  */ @v_round_z,
                               /* @p_round_m  */ @v_round_m
                             ) 
                             +
                             case when @v_point_3 is not null 
                                   and @v_point_3.STEquals(@v_point_2) = 0 
                                  then ', ' 
                                  else '' 
                               end;
              END;
            END;
            IF ( @v_point_3 is not null )
            BEGIN
              IF ( @v_point_3.STEquals(@v_point_2) = 0 )
                SET @v_wkt = @v_wkt 
                             +
                             [$(owner)].[STPointGeomAsText] (
                               /* @p_point    */ @v_point_3,
                               /* @p_round_xy */ @v_round_xy,
                               /* @p_round_z  */ @v_round_z,
                               /* @p_round_m  */ @v_round_m
                             )
            END;
            SET @v_point_1 = null;
            SET @v_point_2 = null;
            SET @v_point_3 = null;
            SET @v_wkt = @v_wkt + ')';
            SET @v_wkt_remainder = SUBSTRING(@v_wkt_remainder,2,LEN(@v_wkt_remainder));
            CONTINUE;
         END
       END;

       -- We have a coord
       -- Now get position of end of coordinate string
       SET @v_pos = case when CHARINDEX(',',@v_wkt_remainder) = 0
                         then CHARINDEX(')',@v_wkt_remainder)
                         when CHARINDEX(',',@v_wkt_remainder) <> 0 and CHARINDEX(',',@v_wkt_remainder) < CHARINDEX(')',@v_wkt_remainder)
                         then CHARINDEX(',',@v_wkt_remainder)
                         else CHARINDEX(')',@v_wkt_remainder)
                     end;

       -- Create a geography point from WKT coordinate string
       SET @v_point = geometry::STPointFromText(
                        'POINT(' 
                        + 
                        SUBSTRING(@v_wkt_remainder,1,@v_pos-1)
                        + 
                        ')',
                        @v_Srid);

       -- Now remove the old coord from v_wkt_remainder
       SET @v_wkt_remainder = SUBSTRING(@v_wkt_remainder,@v_pos,LEN(@v_wkt_remainder));

       -- Now check if we have all the points need to test for a spike.
       IF ( @v_point_1 is null )
       BEGIN
         SET @v_point_1 = @v_point;
       END
       ELSE IF ( @v_point_2 is null )
       BEGIN
         SET @v_point_2 = @v_point
       END
       ELSE IF ( @v_point_3 is null ) 
       BEGIN
         SET @v_point_3 = @v_point;
       END;

       IF ( @v_point_3 is null )
       BEGIN
         -- Not enough points to conduct spike test.
         CONTINUE;
       END;

       -- We have three points to test...
       -- Compute angle between three points
       SET @v_subtended_angle = ABS(
                                    [$(cogoowner)].[STDegrees] ( 
                                        [$(cogoowner)].[STSubtendedAngleByPoint] (
                                          @v_point_1,
                                          @v_point_2,
                                          @v_point_3
                                        )
                                      )
                                  );

       IF ( @v_subtended_angle <= @v_angle_threshold )
       BEGIN
         -- Mid Point is a spike.
         -- Don't add anything yet.
         -- Shuffle points...
         SET @v_point_2 = @v_point_3;
         SET @v_point_3 = NULL;
       END
       ELSE
       BEGIN
         -- No spike, write and shuffle appropriate points
         SET @v_wkt = @v_wkt 
                      +
                      case when CHARINDEX('(',@v_wkt) = LEN(@v_wkt) then '' else ' ' end 
                      +
                      [$(owner)].[STPointGeomAsText] (
                        /* @p_point    */ @v_point_1,
                        /* @p_round_xy */ @v_round_xy,
                        /* @p_round_z  */ @v_round_z,
                        /* @p_round_m  */ @v_round_m
                      )
                      +
                      ', ';
         SET @v_point_1 = @v_point_2;
         SET @v_point_2 = @v_point_3;
         SET @v_point_3 = NULL;
       END;

    END; -- Loop

    IF ( @v_wkt Not like '%[-0-9]%' ) -- Must have at least an ordinate
    BEGIN
      Return 'LINESTRING EMPTY';
    END;

    IF ( CHARINDEX(',',@v_wkt) = 0) -- Is a point
    BEGIN
      RETURN REPLACE(@v_wkt,'LINESTRING','POINT');
    END;

    Return @v_wkt;
  End;
END
GO

Print '***************************************';
Print 'Creating [$(owner)].[STRemoveSpikes]...';
go

Create Function [$(owner)].[STRemoveSpikes]
(
  @p_linestring      geometry,
  @p_angle_threshold float = 0.5,
  @p_round_xy        int   = 3,
  @p_round_z         int   = 2,
  @p_round_m         int   = 2 
)
Returns geometry
As
/****f* EDITOR/STRemoveSpikes (2012)
 *  NAME
 *    STRemoveSpikes -- Function that removes spikes and unnecessary points that lie on straight line between adjacent points.
 *  SYNOPSIS
 *    Function [$(owner)].[STRemoveSpikes] (
 *               @p_linestring      geometry,
 *               @p_angle_threshold float = 0.5,
 *               @p_round_xy        int   = 3,
 *               @p_round_z         int   = 2,
 *               @p_round_m         int   = 2
 *             )
 *     Returns geometry 
 *  USAGE
 *    with data as (
 *      select geometry::STGeomFromText('LINESTRING(0 0,1 0,2 0,2.1 0,2.2 10.0,2.3 0,3 0)',0) as geom
 *    )
 *    select 'Angle Threshold' as test, [dbo].[STRemoveSpikes](a.geom,3.0,3,2,2).AsTextZM() as result from data as a
 *    union all
 *    select 'Original Line'   as test, c.geom.AsTextZM() from data as c
 *    go
 *    test            result
 *    Angle Threshold LINESTRING (0 0, 1 0, 2 0, 2.1 0, 2.3 0, 3 0)
 *    Original Line   LINESTRING (0 0, 1 0, 2 0, 2.1 0, 2.2 10, 2.3 0, 3 0)
 *  DESCRIPTION
 *    Calls STRemoveSpikesByWKT.
 *  NOTES
 *    The function only processes linestrings and multilinestrings not CircularStrings or CompoundCurves.
 *  INPUTS
 *    @p_linestring       (geometry) - Supplied Linestring geometry.
 *    @p_angle_threshold     (float) - Smallest subtended angle allowed. If mid point angle is < @p_angle_threshold the mid-point is removed.
 *    @p_round_xy              (int) - Decimal degrees of precision to which calculated XY ordinates are rounded.
 *    @p_round_z               (int) - Decimal degrees of precision to which calculated ZM ordinates are rounded.
 *    @p_round_m               (int) - Decimal degrees of precision to which calculated ZM ordinates are rounded.
 *  RESULT
 *    Modified linestring (geometry) - Input linestring with any spikes removed
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - February 2018 - Original TSQL Coding for SQL Spatial.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @v_geometry_type varchar(100),
    @v_wkt           varchar(max);
  Begin
    If ( @p_linestring is null ) 
      Return geometry::STGeomFromText('LINESTRING EMPTY',@p_linestring.STSrid);

    -- Only process linear geometries.
    SET @v_geometry_type = REPLACE(SUBSTRING(@p_linestring.STAsText(),1,CHARINDEX('(',@p_linestring.STAsText())-1),' ','');
    IF ( @v_geometry_type NOT IN ('LINESTRING','MULTILINESTRING') )
      Return @p_linestring.MakeValid();

    IF ( @p_angle_threshold is null )
      Return @p_linestring.MakeValid();

    SET @v_wkt = [dbo].[STRemoveSpikesByWKT] (
                   /* @p_linestring      */ @p_linestring.AsTextZM(),
                   /* @p_srid            */ @p_linestring.STSrid,
                   /* @p_angle_threshold */ @p_angle_threshold,
                   /* @p_round_xy        */ @p_round_xy,
                   /* @p_round_z         */ @p_round_z,
                   /* @p_round_m         */ @p_round_m
                 );

    Return geometry::STGeomFromText(@v_wkt,@p_linestring.STSrid).MakeValid();
  End;
END
GO

Print '***************************************';
Print 'Creating [$(owner)].[STRemoveSpikesAsGeog]...';
go

Create Function [$(owner)].[STRemoveSpikesAsGeog]
(
  @p_linestring      geography,
  @p_angle_threshold float = 0.5,
  @p_round_xy        int   = 8,
  @p_round_z         int   = 2,
  @p_round_m         int   = 2 
)
Returns geography
As
/****f* EDITOR/STRemoveSpikesAsGeog (2012)
 *  NAME
 *    STRemoveSpikesAsGeog -- Function that removes spikes and unnecessary points that lie on straight line between adjacent points.
 *  SYNOPSIS
 *    Function [$(owner)].[STRemoveSpikesAsGeog] (
 *               @p_linestring      geography,
 *               @p_angle_threshold float = 0.5,
 *               @p_round_xy        int   = 3,
 *               @p_round_z         int   = 2,
 *               @p_round_m         int   = 2
 *             )
 *     Returns geometry 
 *  USAGE
 *    With WKT as (
 *      select 'LINESTRING(148.60735 -35.157845 356 0, 148.60724 -35.157917 87 87, 148.60733 -35.157997 9 96, 148.60724 -35.157917 5 101)' as lWkt
 *    )
 *    select 'L' as id, [dbo].[STRemoveSpikesAsGeog] (geography::STGeomFromText(a.lWkt,4283),10.0,8,2,2).AsTextZM() as sLine from wkt as a
 *    union all
 *    select 'O' as id, geography::STGeomFromText(lWkt,4283).AsTextZM() as line from wkt as a
 *    GO
 *    id sLine
 *    L  LINESTRING (148.60735 -35.157845 356 0, 148.60724 -35.157917 87 87)
 *    O  LINESTRING (148.60735 -35.157845 356 0, 148.60724 -35.157917 87 87, 148.60733 -35.157997 9 96, 148.60724 -35.157917 5 101)
 *  DESCRIPTION
 *    Calls STRemoveSpikesByWKT.
 *  NOTES
 *    The function only processes linestrings and multilinestrings not CircularStrings or CompoundCurves.
 *  INPUTS
 *    @p_linestring       (geography) - Supplied Linestring geography.
 *    @p_angle_threshold      (float) - Smallest subtended angle allowed. If mid point angle is < @p_angle_threshold the mid-point is removed.
 *    @p_round_xy               (int) - Decimal degrees of precision to which calculated XY ordinates are rounded.
 *    @p_round_z                (int) - Decimal degrees of precision to which calculated ZM ordinates are rounded.
 *    @p_round_m                (int) - Decimal degrees of precision to which calculated ZM ordinates are rounded.
 *  RESULT
 *    Modified linestring (geography) - Input linestring with any spikes removed
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - February 2018 - Original TSQL Coding for SQL Spatial.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @v_geometry_type varchar(100),
    @v_wkt           varchar(max);
  Begin
    If ( @p_linestring is null ) 
      Return geography::STGeomFromText('LINESTRING EMPTY',@p_linestring.STSrid);

    -- Only process linear geometries.
    SET @v_geometry_type = REPLACE(SUBSTRING(@p_linestring.STAsText(),1,CHARINDEX('(',@p_linestring.STAsText())-1),' ','');
    IF ( @v_geometry_type NOT IN ('LINESTRING','MULTILINESTRING') )
      Return @p_linestring.MakeValid();

    IF ( @p_angle_threshold is null )
      Return @p_linestring.MakeValid();

   SET @v_wkt = [dbo].[STRemoveSpikesByWKT] (
                  /* @p_linestring      */ @p_linestring.AsTextZM(),
                  /* @p_srid            */ @p_linestring.STSrid,
                  /* @p_angle_threshold */ @p_angle_threshold,
                  /* @p_round_xy        */ @p_round_xy,
                  /* @p_round_z         */ @p_round_z,
                  /* @p_round_m         */ @p_round_m
                );
   Return geography::STGeomFromText(@v_wkt,@p_linestring.STSrid).MakeValid();
  End;
END
GO

-- ***********************************************************************************
Print '3. Testing ....';
GO

select 'SQL Server Documentation'          as comment,[$(owner)].[STRemoveSpikesByWKT] ('LINESTRING(1 4, 3 4, 2 4, 2 0)',4283,10.0,8,2,2)
union all
select 'SQL Server Documentation Adjusted (Calls STRemoveSpikes)' as comment,[$(owner)].[STRemoveSpikesByWKT] ('LINESTRING(1 4, 3 4.01, 2 4, 2 0)',4283,10.0,8,2,2)
union all
select 'Duplicate first/last, spike in middle, return first two points' as comment, [$(owner)].[STRemoveSpikesByWKT] ('LINESTRING(148.13719 -35.2973 5 0, 148.13737 -35.29527 10 10, 148.13719 -35.2973 6 16)',4283,10.0,8,2,2)
Union all
select 'Spike in middle' as comment, [$(owner)].[STRemoveSpikesByWKT] ('LINESTRING(148.60735 -35.157845 356 0, 148.60724 -35.157917 87 87, 148.60733 -35.157997 9 96, 148.60724 -35.157917 5 101)',4283,10.0,8,2,2)
GO

select 'O' as id,     geometry::STGeomFromText('LINESTRING(148.60735 -35.157845 356 0, 148.60724 -35.157917 87 87, 148.60733 -35.157997 9 96, 148.60724 -35.157917 5 101)',4283) as line
union all
select 'L' as id, [$(owner)].[STRemoveSpikes] ('LINESTRING(148.60735 -35.157845 356 0, 148.60724 -35.157917 87 87, 148.60733 -35.157997 9 96, 148.60724 -35.157917 5 101)',10.0,8,2,2)
GO

QUIT
GO

