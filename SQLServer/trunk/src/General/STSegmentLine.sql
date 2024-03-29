USE [$(usedbname)]
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(owner)].[STSegmentLine]') 
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [$(owner)].[STSegmentLine];
  PRINT 'Dropped [$(owner)].[STSegmentLine] ...';
END;
GO

PRINT 'Creating [$(owner)].[STSegmentLine] ...';
GO

CREATE FUNCTION [$(owner)].[STSegmentLine]
(
  @p_geometry geometry
)
RETURNS @Segments TABLE
(
  id             int,
  multi_tag      varchar(100),
  element_id     int,
  element_tag    varchar(100),
  subelement_id  int,
  subelement_tag varchar(100),
  segment_id     int,
  sx             float,  /* Start Point */
  sy             float,
  sz             float,
  sm             float,
  mx             float,  /* Mid Point */
  my             float,
  mz             float,
  mm             float,
  ex             float,  /* End Point */
  ey             float,
  ez             float,
  em             float,
  length         float,
  startLength    float,
  measureRange   float,
  geom           geometry  /* Useful esp if segment is a circular arc */
)
AS
/****f* GEOPROCESSING/STSegmentLine (2012)
 *  NAME
 *    STSegmentLine - Segments the supplied linestring into 2-point linestrings or 3 point CircularStrings. 
 *  SYNOPSIS
 *    Function STSegmentLine(
 *       @p_geometry geometry
 *     )
 *     Returns @geometries TABLE 
 *     (
 *       id             int,
 *       multi_tag      varchar(100),
 *       element_id     int,
 *       element_tag    varchar(100),
 *       subelement_id  int,
 *       subelement_tag varchar(100),
 *       segment_id     int,
 *       sx             float,  
 *       sy             float,
 *       sz             float,
 *       sm             float,
 *       mx             float,  
 *       my             float,
 *       mz             float,
 *       mm             float,
 *       ex             float, 
 *       ey             float,
 *       ez             float,
 *       em             float,
 *       length         float,
 *       startLength    float,
 *       measureRange   float,
 *       geom           geometry
 *     )  
 *  DESCRIPTION
 *    This function segments the supplied linestring into 2-point linestrings or 3 point CircularStrings. 
 *    The returned data includes all the metadata about the segmented linestring:
 *    * WKT tags;
 *    * Segment identifiers (ie from 1 through n);
 *    * Start/Mid/End Coordinates as ordinates;
 *    * Segment length and cumulative length from start;
 *    * Measure range for segment (endM - startM)
 *    * Geometry representation of segment.
 *  NOTES
 *    Supports LineString (2008), MultiLineString (2008), CircularString (2012) and CompoundCurve (2012) geometry types.
 *    This version supports CircularString/CompoundCurve geometry types available from  SQL Server 2012 onwards.
 *  INPUTS
 *    @p_geometry (geometry) - Linear geometry types.
 *  EXAMPLE
 *    SELECT t.*
 *      FROM [$(owner)].[STSegmentLine](geometry::STGeomFromText('POLYGON((0 0,20 0,20 20,0 20,0 0),(10 10,10 11,11 11,11 10,10 10),(5 5,5 7,7 7,7 5,5 5))',0)) as t
 *    GO
 *  RESULT
 *    Table (Array) of segments:
 *     id             (int)        - Unique identifier starting at segment 1.
 *     multi_tag      (varchar100) - WKT Tag if Multi geometry eg MULTILINESTRING/MULTICURVE/MULTIPOLYGON.
 *     element_id     (int)        - Top level element identifier eg 1 for first polygon in multiPolygon.
 *     element_tag    (varchar100) - WKT Tag for first element eg POLYGON if part of MULTIPOlYGON.
 *     subelement_id  (int)        - SubElement identifier of subelement of element with parts eg OuterRing of Polygon
 *     subelement_tag (varchar100) - WKT Tag for first subelement of element with parts eg OuterRing of Polygon
 *     segment_id     (int)        - Unique identifier starting at segment 1 for each element.
 *     sx             (float)      - Start Point X Ordinate 
 *     sy             (float)      - Start Point Y Ordinate 
 *     sz             (float)      - Start Point Z Ordinate 
 *     sm             (float)      - Start Point M Ordinate
 *     mx             (float)      - Mid Point X Ordinate (Only if CircularString)
 *     my             (float)      - Mid Point Y Ordinate (Only if CircularString)
 *     mz             (float)      - Mid Point Z Ordinate (Only if CircularString)
 *     mm             (float)      - Mid Point M Ordinate (Only if CircularString)
 *     ex             (float)      - End Point X Ordinate 
 *     ey             (float)      - End Point Y Ordinate 
 *     ez             (float)      - End Point Z Ordinate 
 *     em             (float)      - End Point M Ordinate 
 *     length         (float)      - Length of this segment in SRID units
 *     startLength    (float)      - Cumulative Length (from start of geometry) at the start of this segment in SRID units
 *     measureRange   (float)      - Measure Range ie EndM - StartM
 *     geom           (geometry)   - Geometry representation of segment.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - Dec 2017 - TSQL SQL Server
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare
    @v_MainGeomType     varchar(100),
    @v_GeomType         varchar(1000),
    @v_LastGeomType     varchar(100),
    @v_isGeography      bit,
    -- Iteration Variables
    @v_id               int = 1,
    @v_geomn            int = 0,
    @v_CurveN           int = 0,
    @v_SubElement       int = 0,
    @v_segment_id       int = 0,
    @v_NumGeoms         int = 0,
    @v_NumElements      int = 0,
    @v_first_pointN     int = 0,
    @v_second_pointN    int = 0,

    -- Segment Variables
    @v_start_point      geometry,
    @v_end_point        geometry,
    @v_segment_geom     geometry,
    @v_start_length     float,
    @v_end_length       float,
    @v_vector_length    float,
    @v_total_length     float,

    -- Extracted Element/SUbElement Geometries
    @v_curve            geometry,
    @v_geom             geometry;
  Begin
    If ( @p_geometry is NULL )
      Return;

    SET @v_MainGeomType = @p_geometry.STGeometryType();

    IF ( @v_MainGeomType NOT IN ('MultiLineString',
                                 'LineString',
                                 'CircularString',
                                 'CompoundCurve' ) )
    BEGIN
      Return;
    END;

    -- CompoundCurve objects are made up of N x CircularCurves and/or M x LineStrings.
    -- All accessed via STCurveN (even LineString)

    SET @v_isGeography  = [$(owner)].[STIsGeographicSrid](@p_geometry.STSrid);
    SET @v_id           = 1;
    SET @v_LastGeomType = 'NULL';
    SET @v_geomn        = 1;
    SET @v_segment_id   = 0;
    SET @v_total_length = 0.0;
    SET @v_NumGeoms     = case when @v_MainGeomType in ('CompoundCurve')
                               then @p_geometry.STNumCurves()
                               else @p_geometry.STNumGeometries()
                           end;

    -- Loop over all geometries or curves ....
    WHILE ( @v_geomn <= @v_NumGeoms )
    BEGIN

      -- Extract appropriate subelement
      SET @v_geom = case when @v_MainGeomType = 'CompoundCurve'
                         then @p_geometry.STCurveN(   @v_geomn)
                         else @p_geometry.STGeometryN(@v_geomn)
                     end;

      -- STCurveN extracts subelements as elements if CircularString with more than one curve.
      SET @v_NumElements = case when @v_MainGeomType = 'CompoundCurve'
                                then 1
                                else @v_NumElements + 1
                            end;

      -- Processing depends on sub-element type
      SET @v_GeomType  = @v_geom.STGeometryType();

      -- Even if CompoundCurve has LINESTRING with more than one vector,
      -- STCurveN() API call extracts as many 2 point linestrings as exist in the original LINESTRING subelement.
      -- And as many 3 point CircularStrings as there are in the CircularString subelement.
      --
      IF ( @v_MainGeomType = 'CompoundCurve' )
      BEGIN
        -- Increase SubElement Count only when processing CircularString for first time
        IF ( @v_LastGeomType != @v_GeomType )
          SET @v_SubElement = @v_SubElement + 1;
      END;

      IF ( @v_GeomType = 'LineString' )
      BEGIN

        SET @v_first_pointN      = 1;
        SET @v_second_pointN     = 2;

        WHILE ( @v_second_pointN <= @v_geom.STNumPoints() )
        BEGIN

          SET @v_segment_id    = @v_segment_id + 1;
          SET @v_start_point   = @v_geom.STPointN(@v_first_pointN);
          SET @v_end_point     = @v_geom.STPointN(@v_second_pointN);
          SET @v_segment_geom  = [$(owner)].[STMakeLine] (
                                     @v_start_point,
                                     @v_end_point,
                                     15,
                                     15
                                 );
          SET @v_vector_length = case when @v_isGeography=1
                                      then geography::STGeomFromText(@v_segment_geom.AsTextZM(),@v_segment_geom.STSrid).STLength()
                                      else @v_segment_geom.STLength()
                                  end;
          INSERT INTO @Segments (
                     [id],
                     [multi_tag],
                     [element_id],
                     [element_tag],
                     [subelement_id],
                     [subelement_tag],
                     [segment_id],
                     [sx],[sy],[sz],[sm],
                     [ex],[ey],[ez],[em],
                     [length],
                     [startLength],
                     [measureRange],
                     [geom]
          ) VALUES ( @v_id,
                     case when @v_MainGeomType in ('CompoundCurve','MultiLineString' ) then UPPER(@v_MainGeomType) else null end,
                     @v_NumElements,
                     UPPER(@v_geomType),
                     @v_SubElement,
                     null,
                     @v_segment_id,
                     @v_start_point.STX,@v_start_point.STY, @v_start_point.Z,@v_start_point.M,
                       @v_end_point.STX,  @v_end_point.STY,   @v_end_point.Z,  @v_end_point.M,
                     @v_vector_length,
                     @v_total_length,
                     case when @p_geometry.HasM=1 then ( @v_end_point.M - @v_start_point.M ) else null end,
                     @v_segment_geom
          );
          SET @v_total_length  = @v_total_length + @v_vector_length;
          SET @v_id            = @v_id     + 1;
          SET @v_first_pointN  = @v_first_pointN  + 1;
          SET @v_second_pointN = @v_second_pointN + 1;
        END;
      END; -- IF ( @v_GeomType = 'LineString' )
 
      IF ( @v_GeomType = 'CircularString' )
      BEGIN

        SET @v_CurveN   = 1;
        WHILE ( @v_CurveN <= @v_geom.STNumCurves() )
        BEGIN
          SET @v_segment_id    = @v_segment_id + 1;
          SET @v_curve         = @v_geom.STCurveN(@v_CurveN);
          SET @v_vector_length = case when @v_isGeography=1
                                      then geography::STGeomFromText(@v_curve.AsTextZM(),@v_curve.STSrid).STLength()
                                      else @v_curve.STLength()
                                  end;
          INSERT INTO @Segments (
                     [id],
                     [multi_tag],
                     [element_id],
                     [element_tag],
                     [subelement_id],
                     [subelement_tag],
                     [segment_id],
                     [sx],[sy],[sz],[sm],
                     [mx],[my],[mz],[mm],
                     [ex],[ey],[ez],[em],
                     [length],
                     [startLength],
                     [measureRange],
                     [geom]
          ) VALUES ( @v_id                  /*             id */,
                     case when @v_MainGeomType in ('CompoundCurve','MultiLineString' ) then UPPER(@v_MainGeomType) else null end,
                     @v_NumElements         /*     element_id */,
                     UPPER(@v_geomType),
                     case when @v_MainGeomType = 'CompoundCurve'
                          then @v_SubElement
                          else @v_CurveN
                      end                   /*  subelement_id */,
                     NULL                   /* subelement_tag */,
                     @v_segment_id         /*      segment_id */,
                     @v_curve.STPointN(1).STX,@v_curve.STPointN(1).STY,@v_curve.STPointN(1).Z,@v_curve.STPointN(1).M,
                     @v_curve.STPointN(2).STX,@v_curve.STPointN(2).STY,@v_curve.STPointN(2).Z,@v_curve.STPointN(2).M,
                     @v_curve.STPointN(3).STX,@v_curve.STPointN(3).STY,@v_curve.STPointN(3).Z,@v_curve.STPointN(3).M,
                     @v_vector_length,
                     @v_total_length,
                     case when @p_geometry.HasM=1 then ( @v_curve.STPointN(3).M - @v_curve.STPointN(1).M ) else null end,
                     @v_curve
          );
          SET @v_total_length = @v_total_length + @v_vector_length;
          SET @v_id           = @v_id     + 1;
          SET @v_CurveN       = @v_CurveN + 1;
        END;
      END; -- IF ( @v_GeomType = 'CircularString' )

      SET @v_LastGeomType = @v_GeomType;
      SET @v_geomn        = @v_geomn  + 1;

    END; -- WHILE ( @v_geomn <= @v_NumGeoms )
    RETURN;
  END;
END
GO

PRINT 'Testing [$(owner)].[STSegmentLine] ...';
GO

with data as (
select 0 as testid, geometry::STGeomFromText('LINESTRING(0 0,5 5,10 10,11 11,12 12,100 100,200 200)',0) as linestring
union all
select 1 as testid, geometry::STGeomFromText('MULTILINESTRING((0 0,5 5,10 10,11 11,12 12),(100 100,200 200))',0) as linestring
union all
select 2 as testid, geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING (3 6.3246,0 7,-3 6.3246),(-3 6.3246,0 0,3 6.3246))',0) as linestring
union all
select 3 as testid, geometry::STGeomFromText('COMPOUNDCURVE(CIRCULARSTRING(0 0,1 2.1082,3 6.3246,0 7,-3 6.3246,-1 2.1082,0 0))',0) as linestring 
union all
select 4 as testid, geometry::STGeomFromText('COMPOUNDCURVE (CIRCULARSTRING (0 0,1 2.1082,3 6.3246), CIRCULARSTRING(3 6.3246,0 7,-3 6.3246), CIRCULARSTRING(-3 6.3246,-1 2.1082,0 0))',0) as linestring
union all
select 5 as testid, geometry::STGeomFromText('COMPOUNDCURVE((0 -23.43778,0 23.43778),CIRCULARSTRING(0 23.43778,-45 23.43778,-90 23.43778),(-90 23.43778,-90 -23.43778),CIRCULARSTRING(-90 -23.43778,-45 -23.43778,0 -23.43778))',0) as linestring
)
select t.*
  from data as d
       cross apply [$(owner)].[STSegmentLine](d.linestring) as t
where d.testid = 1;
GO

QUIT
GO
