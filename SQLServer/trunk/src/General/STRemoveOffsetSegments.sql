use $(usedbname)
go

drop function if exists [$(owner)].[STRemoveOffsetSegments] 
go

CREATE FUNCTION [$(owner)].[STRemoveOffsetSegments] (
  @p_linestring      geometry,
  @p_offset_distance float,
  @p_round_xy        int,
  @p_round_zm        int
)
returns geometry
As
Begin
  Declare
    @v_linestring  geometry,
   @v_buffer      geometry,
   @v_buffer_ring geometry;

    IF ( @p_linestring.STNumPoints() = 2 ) 
      Return @p_linestring;

    -- Get start and end segments that don't disappear.
    SET @v_buffer      = @p_linestring.STBuffer(ABS(@p_offset_distance));
    SET @v_buffer_ring = @v_buffer.STExteriorRing();

   -- TODO: Need to extend to all pairs within linestring.
    WITH segments as (
      SELECT s.id, s.geom as segment,
             s.geom.STNumPoints() as numPoints
        FROM [$(owner)].[STSegmentLine](@p_linestring) as s
    ), ids as (
     SELECT MIN(id) as minId, MAX(id) as maxId
       FROM (SELECT /* original Line as offset segments */
                    s.[id],
                   ROUND([$(owner)].[STOffsetSegment] (
                                   s.segment,
                                   @p_offset_distance,
                                   @p_round_xy,
                                   @p_round_zm
                          ).ShortestLineTo(@v_buffer_ring)
                     .STLength(),
                          @p_round_xy
                    ) as Dist2Boundary
               FROM segments s
           ) as f
       WHERE f.Dist2Boundary = 0.0
    )
    SELECT @v_linestring = [$(owner)].[STMakeLineFromGeometryCollection] ( 
                                    geometry::CollectionAggregate ( f.line ),
                                    @p_round_xy,
                                    @p_round_zm 
                           )
      FROM (SELECT TOP (100) PERCENT
                   s.segment as line 
              FROM ids as i
                     INNER JOIN
                       segments as s 
                         ON (s.id between i.minId and i.maxId)
             ORDER BY s.id
          ) as f;
   return @v_linestring;
End
go

QUIT
GO

