use SPATIALDB
go

with data as (
/* Unmeasured line */
select geometry::STGeomFromText ('LINESTRING(0 0,100 100)',0) as line
)
, mLine as (
select lrs.STAddMeasure (
             /* @p_linestring    */ a.line,
             /* @p_start_measure */ 0.0,
             /* @p_end_measure   */ a.line.STLength(),
             /* @p_round_xy      */ 3,
             /* @p_round_zm      */ 2
       ) as mline 
  from data as a
)
,splitPoint as (
/* Get measure of point on measured line on which the point falls */
select lrs.STFindMeasure (
           /* @p_linestring*/ a.mline,
           /* @p_point     */ geometry::STPointFromText('POINT(50 50)',0),
           /* @p_round_xy  */ 3,
           /* @p_round_zm  */ 2
        ) as measure
  from mLine as a
)
/* Compute split */
select lrs.STSplitLineSegmentByMeasure  (
            /* @p_linestring */ b.mline,
            /* @p_start_measure */ 0.0,
            /* @p_end_measure   */ a.measure,
            /* @p_offset        */ 0,
            /* @p_round_xy      */ 3,
            /* @p_round_zm      */ 2
        ) as line1,
        a.measure,
		lrs.STSplitLineSegmentByMeasure  (
            /* @p_linestring */ b.mline,
            /* @p_start_measure */ a.measure,
            /* @p_end_measure   */ lrs.STEndMeasure(b.mline),
            /* @p_offset        */ 0,
            /* @p_round_xy      */ 3,
            /* @p_round_zm      */ 2
        ) as line2
  from splitPoint as a,
       mLine as b;