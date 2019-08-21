DEFINE INSTALL_SCHEMA='&1'

SET VERIFY OFF;

CREATE OR REPLACE EDITIONABLE PACKAGE &&INSTALL_SCHEMA..OFFSETSEGMENTGENERATOR 
AUTHID CURRENT_USER
AS

  /**
   * Factor which controls how close offset segments can be to
   * skip adding a filler or mitre.
   */
  OFFSET_SEGMENT_SEPARATION Constant Number := 1.0E-3;

  /**
   * Factor which controls how close curve vertices on inside turns can be to be snapped 
   */
  INSIDE_TURN_VERTEX_SNAP_DIST Constant Number := 1.0E-3;

  /**
   * Factor which controls how close curve vertices can be to be snapped
   */
  CURVE_VERTEX_SNAP_DISTANCE Constant Number := 1.0E-6;

  /**
   * Factor which determines how short closing segs can be for round buffers
   */
  MAX_CLOSING_SEG_LEN_FACTOR Constant Number := 80;

  /**
   * Indicates that line segments do not intersect
   */
  NO_INTERSECTION Constant Integer := 0;

  /**
   * Indicates that line segments intersect in a single point
   */
  POINT_INTERSECTION Constant Integer := 1;

  /**
   * Indicates that line segments intersect in a line segment
   */
  COLLINEAR_INTERSECTION Constant Integer := 2;

  Procedure init(
               p_Precision in integer,
               p_bufParams in BufferParameters, 
               p_distance  in number
            ) ;

  /**
   * Tests whether the input has a narrow concave angle
   * (relative to the offset distance).
   * In this case the generated offset curve will contain self-intersections
   * and heuristic closing segments.
   * This is expected behaviour in the case of Buffer curves. 
   * For pure Offset Curves,
   * the output needs to be further treated 
   * before it can be used. 
   * 
   * @return true if the input has a narrow concave angle
   */
  Function hasNarrowConcaveAngle Return boolean deterministic;

  Procedure initSideSegments(
                p_s1   in &&INSTALL_SCHEMA..T_Vertex, 
                p_s2   in &&INSTALL_SCHEMA..T_Vertex, 
                p_side in integer
            );

  Function getCoordinates
   Return &&INSTALL_SCHEMA..T_Vertices;

  Procedure closeRing;

  Procedure addSegments(pt in &&INSTALL_SCHEMA..T_Vertices, isForward in boolean);

  Procedure addFirstSegment;

  /**
   * Add last offset point
   */
  Procedure addLastSegment;

  /*private static Number MAX_CLOSING_SEG_LEN := 3.0;*/

  Procedure addNextSegment(p in &&INSTALL_SCHEMA..T_Vertex, addStartPoint in boolean);

  /**
   * From RobustLineIntersector
   **/
   Function computeIntersection(p in &&INSTALL_SCHEMA..T_Vertex, p1 in &&INSTALL_SCHEMA..T_Vertex, p2 in &&INSTALL_SCHEMA..T_Vertex) 
   Return integer deterministic;

  Procedure addCollinear(addStartPoint in boolean);

  /**
   * Adds the offset points for an outside (convex) turn
   * 
   * @param orientation
   * @param addStartPoint
   */
  Procedure addOutsideTurn(orientation in integer, addStartPoint in boolean);

  /** Adds the offset points for an inside (concave) turn.
   * 
   * @param orientation
   * @param addStartPoint
   */
  Procedure addInsideTurn(orientation in integer, addStartPoint in boolean);

  Function getIntersection(intIndex in integer)
    Return &&INSTALL_SCHEMA..T_Vertex deterministic;

  /**
   * Add an end cap around point p1, terminating a line segment coming from p0
   */
  Procedure addLineEndCap(p0 in &&INSTALL_SCHEMA..T_Vertex, p1 in &&INSTALL_SCHEMA..T_Vertex);

  /**
   * Adds a mitre join connecting the two reflex offset segments.
   * The mitre will be beveled if it exceeds the mitre ratio limit.
   * 
   * @param offset0 the first offset segment
   * @param offset1 the second offset segment
   * @param distance the offset distance
   */
  Procedure addMitreJoin(p        in &&INSTALL_SCHEMA..T_vertex, 
                         offset0  in &&INSTALL_SCHEMA..T_Segment,
                         offset1  in &&INSTALL_SCHEMA..T_Segment,
                         distance in Number);

  /**
   * Adds a limited mitre join connecting the two reflex offset segments.
   * A limited mitre is a mitre which is beveled at the distance
   * determined by the mitre ratio limit.
   * 
   * @param offset0 the first offset segment
   * @param offset1 the second offset segment
   * @param distance the offset distance
   * @param mitreLimit the mitre limit ratio
   */
  Procedure addLimitedMitreJoin( 
               offset0    in &&INSTALL_SCHEMA..T_Segment,
               offset1    in &&INSTALL_SCHEMA..T_Segment,
               p_distance in number,
               mitreLimit in number
            );

  /**
   * Adds a bevel join connecting the two offset segments
   * around a reflex corner.
   * 
   * @param offset0 the first offset segment
   * @param offset1 the second offset segment
   */
  Procedure addBevelJoin( 
      offset0 in &&INSTALL_SCHEMA..T_Segment, 
      offset1 in &&INSTALL_SCHEMA..T_Segment);

  /**
   * Add points for a circular fillet around a reflex corner.
   * Adds the start and end points
   * 
   * @param p base point of curve
   * @param p0 start point of fillet curve
   * @param p1 endpoint of fillet curve
   * @param direction the orientation of the fillet
   * @param radius the radius of the fillet
   */
  Procedure addCornerFillet(p in &&INSTALL_SCHEMA..T_Vertex, p0 in &&INSTALL_SCHEMA..T_Vertex, p1 in &&INSTALL_SCHEMA..T_Vertex, direction in integer, radius in number);

  /**
   * Adds points for a circular fillet arc
   * between two specified angles.  
   * The start and end point for the fillet are not added -
   * the caller must add them if required.
   *
   * @param direction is -1 for a CW angle, 1 for a CCW angle
   * @param radius the radius of the fillet
   */
  Procedure addDirectedFillet(p in &&INSTALL_SCHEMA..T_Vertex, startAngle in Number, endAngle in Number, direction in integer, radius in Number );

  /**
   * Creates a CW circle around a point
   */
  Procedure createCircle(p in &&INSTALL_SCHEMA..T_Vertex);

  /**
   * Creates a CW square around a point
   */
  Procedure createSquare(p in &&INSTALL_SCHEMA..T_Vertex);

  /**
   * Compute an offset segment for an input segment on a given side and at a given distance.
   * The offset points are computed in full Number precision, for accuracy.
   *
   * @param seg the segment to offset
   * @param side the side of the segment ({@link Position}) the offset lies on
   * @param distance the offset distance
   * @param offset the points computed for the offset segment
   */
    Function computeOffsetSegment(
               seg      in &&INSTALL_SCHEMA..T_Segment, 
               side     in pls_integer, 
               distance in Number
            )
    return &&INSTALL_SCHEMA..T_Segment deterministic;

  /**
   * Compute an offset segment for an input segment on a given side and at a given distance.
   * The offset points are computed in full Number precision, for accuracy.
   *
   * @param seg the segment to offset
   * @param side the side of the segment ({@link Position}) the offset lies on
   * @param distance the offset distance
   * @param offset the points computed for the offset segment
   */
    Function computeOffsetCurve(
               seg      in &&INSTALL_SCHEMA..T_Segment, 
               side     in pls_integer, 
               distance in Number
            )
    return &&INSTALL_SCHEMA..T_Segment deterministic;

END;
/
show errors

create or replace PACKAGE Body OffsetSegmentGenerator
AS

  -- From Orientation.java
  
  /**
   * A value that indicates an orientation of clockwise, or a right turn.
   */
  CLOCKWISE CONSTANT INTEGER := -1;
  /**
   * A value that indicates an orientation of clockwise, or a right turn.
   */
  RIGHT CONSTANT INTEGER := CLOCKWISE;
  /**
   * A value that indicates an orientation of counterclockwise, or a left turn.
   */
  COUNTERCLOCKWISE CONSTANT INTEGER := 1;
  /**
   * A value that indicates an orientation of counterclockwise, or a left turn.
   */
  LEFT CONSTANT INTEGER := 1; -- COUNTERCLOCKWISE;
  /**
   * A value that indicates an orientation of collinear, or no turn (straight).
   */
  COLLINEAR CONSTANT INTEGER := 0;
  /**
   * A value that indicates an orientation of collinear, or no turn (straight).
   */
  STRAIGHT CONSTANT INTEGER := 0; -- COLLINEAR;

  /**
   * the max error of approximation (distance) between a quad segment and the true fillet curve
   */
  maxCurveSegmentError Number := 0.0;

  /**
   * The angle quantum with which to approximate a fillet curve
   * (based on the input # of quadrant segments)
   */
  filletAngleQuantum Number;

  /**
   * The Closing Segment Length Factor controls how long
   * "closing segments" are.  Closing segments are added
   * at the middle of inside corners to ensure a smoother
   * boundary for the buffer offset curve. 
   * In some cases (particularly for round joins with default-or-better
   * quantization) the closing segments can be made quite short.
   * This substantially improves performance (due to fewer intersections being created).
   * 
   * A closingSegFactor of 0 results in lines to the corner vertex
   * A closingSegFactor of 1 results in lines halfway to the corner vertex
   * A closingSegFactor of 80 results in lines 1/81 of the way to the corner vertex
   * (this option is reasonable for the very common default situation of round joins
   * and quadrantSegs >= 8)
   */
  closingSegLengthFactor integer := 1;

  seglist               spdba.T_VertexList;
  distance              number := 0.0;
  dPrecision            Integer := 3;
  bufParams             BufferParameters;

  s0                    spdba.T_Vertex;
  s1                    spdba.T_Vertex;
  s2                    spdba.T_Vertex;
  seg0                  spdba.T_Segment := new spdba.T_Segment();
  seg1                  spdba.T_Segment := new spdba.T_Segment();
  offset0               spdba.T_Segment := new spdba.T_Segment();
  offset1               spdba.T_Segment := new spdba.T_Segment();
  side                  pls_integer := 0;
  bHasNarrowConcaveAngle Boolean := false;

  isProper               boolean;
  
  Procedure init(
               p_Precision in integer,
               p_bufParams in BufferParameters, 
               p_distance  in number
            ) 
  As
  Begin 
    dPrecision := p_precision;

    -- compute intersections in full precision, to provide accuracy
    -- the points are rounded as they are inserted into the curve line
    filletAngleQuantum := SPDBA.COGO.PI() / 2.0 / bufParams.getQuadrantSegments();

    /**
     * Non-round joins cause issues with short closing segments, so don't use
     * them. In any case, non-round joins only really make sense for relatively
     * small buffer distances.
     */
    if (bufParams.getQuadrantSegments() >= 8 AND bufParams.getJoinStyle() = BufferParameterConstants.JOIN_ROUND) then
      closingSegLengthFactor := spdba.OffsetSegmentGenerator.MAX_CLOSING_SEG_LEN_FACTOR;
    end if;

    -- Init
    distance             := p_distance;
    maxCurveSegmentError := distance * (1.0 - COS(filletAngleQuantum / 2.0));
    --segList            := new OffsetSegmentString();
    segList              := new spdba.T_VertexList();
    -- segList.setPrecisionModel(precisionModel);
    /**
     * Choose the min vertex separation as a small fraction of the offset distance.
     */
    segList.setMinimumVertexDistance(distance * spdba.OffsetSegmentGenerator.CURVE_VERTEX_SNAP_DISTANCE);
  End init;

  /**
   * Tests whether the input has a narrow concave angle
   * (relative to the offset distance).
   * In this case the generated offset curve will contain self-intersections
   * and heuristic closing segments.
   * This is expected behaviour in the case of Buffer curves. 
   * For pure Offset Curves,
   * the output needs to be further treated 
   * before it can be used. 
   * 
   * @return true if the input has a narrow concave angle
   */
  Function hasNarrowConcaveAngle
   Return boolean
  As
  Begin
    return bHasNarrowConcaveAngle;
  End;

  Procedure initSideSegments(
                p_s1 in spdba.T_Vertex, 
                p_s2 in spdba.T_Vertex, 
                p_side in integer
            )
  As
  Begin
    s1   := new spdba.T_Vertex(p_s1);
    s2   := new spdba.T_Vertex(p_s2);
    side := p_side;
    seg1.ST_SetCoordinates(s1, s2);
    offset1 := computeOffsetSegment(seg1, side, distance);
  End initSideSegments;

  Function getCoordinates
   Return spdba.T_Vertices
  As
    pts SPDBA.T_Vertices;
  Begin
    pts := segList.getCoordinates();
    return pts;
  End getCoordinates;

  Procedure closeRing
  As
  Begin
    segList.closeRing();
  End closeRing;

  Procedure addSegments(pt in spdba.T_Vertices, isForward in boolean)
  As
  Begin
    segList.addPts(pt, isForward);
  End addSegments;

  Procedure addFirstSegment
  As
  Begin
    segList.addPt(offset1.startCoord); --p0);
  End addFirstSegment;

  /**
   * Add last offset point
   */
  Procedure addLastSegment
  As
  Begin
    segList.addPt(offset1.endCoord); -- p1);
  End AddLastSegment;

  -- ************************************************************
  -- Pulled in from other classes

   /**
   * A filter for computing the orientation index of three coordinates.
   * <p>
   * If the orientation can be computed safely using standard DP
   * arithmetic, this routine returns the orientation index.
   * Otherwise, a value i > 1 is returned.
   * In this case the orientation index must 
   * be computed using some other more robust method.
   * The filter is fast to compute, so can be used to 
   * avoid the use of slower robust methods except when they are really needed,
   * thus providing better average performance.
   * <p>
   * Uses an approach due to Jonathan Shewchuk, which is in the public domain.
   * 
   * @param pa a coordinate
   * @param pb a coordinate
   * @param pc a coordinate
   * @return the orientation index if it can be computed safely
   * @return i > 1 if the orientation index cannot be computed safely
   */
  Function orientationIndexFilter(pa in spdba.T_Vertex, pb in spdba.T_Vertex, pc in spdba.T_Vertex)
  return integer
  As
    /**
     * A value which is safely greater than the
     * relative round-off error in double-precision numbers
    */
    DP_SAFE_EPSILON Constant Number := 1e-15;
    detsum   Number;
    detleft  Number;
    detright Number;
    det      Number;
    errbound Number;
  Begin
    detleft  := (pa.x - pc.x) * (pb.y - pc.y);
    detright := (pa.y - pc.y) * (pb.x - pc.x);
    det      := detleft - detright;
    if (detleft > 0.0) then
      if (detright <= 0.0) then
        return sign(det);
      else 
        detsum := detleft + detright;
      End if;
    elsif (detleft < 0.0) then
      if (detright >= 0.0) then
        return sign(det);
      else
        detsum := (-1.0 * detleft) - detright;
      end if;
    else
      return sign(det);
    end if;
    errbound := DP_SAFE_EPSILON * detsum;
    if ((det >= errbound) OR (-det >= errbound)) then
      return sign(det);
    end if;
    return 2;
  End;

    /**
   * Returns the index of the direction of the point <code>q</code> relative to
   * a vector specified by <code>p1-p2</code>.
   * 
   * @param p1 the origin point of the vector
   * @param p2 the final point of the vector
   * @param q the point to compute the direction to
   * 
   * @return 1 if q is counter-clockwise (left) from p1-p2
   * @return -1 if q is clockwise (right) from p1-p2
   * @return 0 if q is collinear with p1-p2
   */
  Function orientationIndex(p1 in spdba.T_Vertex, p2 in spdba.T_Vertex, q in spdba.T_Vertex)
  Return integer
  As
    v_index pls_integer;
    dx1     Number;
    dy1     Number;
    dx2     Number;
    dy2     Number;
  Begin
    -- fast filter for orientation index
    -- avoids use of slow extended-precision arithmetic in many cases
    
    v_index := orientationIndexFilter(p1, p2, q);
    if (v_index <= 1) then
      return v_index;
    end if;
    
    /*
    -- normalize coordinates
    DD dx1 = DD.valueOf(p2.x).selfAdd(-p1.x);
    DD dy1 = DD.valueOf(p2.y).selfAdd(-p1.y);
    DD dx2 = DD.valueOf(q.x).selfAdd(-p2.x);
    DD dy2 = DD.valueOf(q.y).selfAdd(-p2.y);

    -- sign of determinant - unrolled for performance
    return dx1.selfMultiply(dy2)
              .selfSubtract(dy1.selfMultiply(dx2))
              .signum();
    */
    -- normalize coordinates
    dx1 := p2.x - p1.x;
    dy1 := p2.y - p1.y;
    dx2 := q.x  - p2.x;
    dy2 := q.y  - p2.y;

    -- sign of determinant - unrolled for performance
    return SIGN( (dx1 * dy2) - (dy1 * dx2) );

  End orientationIndex;
  
  /**
   * Returns the orientation index of the direction of the point <code>q</code> relative to
   * a directed infinite line specified by <code>p1-p2</code>.
   * The index indicates whether the point lies to the {@link LEFT} or {@link #RIGHT} 
   * of the line, or lies on it {@link #COLLINEAR}.
   * The index also indicates the orientation of the triangle formed by the three points
   * ( {@link #COUNTERCLOCKWISE}, {@link #CLOCKWISE}, or {@link #STRAIGHT} )
   * 
   * @param p1 the origin point of the line vector
   * @param p2 the final point of the line vector
   * @param q the point to compute the direction to
   * 
   * @return -1 ( {@link #CLOCKWISE} or {@link #RIGHT} ) if q is clockwise (right) from p1-p2;
   *         1 ( {@link #COUNTERCLOCKWISE} or {@link LEFT} ) if q is counter-clockwise (left) from p1-p2;
   *         0 ( {@link #COLLINEAR} or {@link #STRAIGHT} ) if q is collinear with p1-p2
   */
  Function oindex(p1 in spdba.T_Vertex, p2 in spdba.T_Vertex, q in spdba.T_Vertex)
  Return integer
  As
  Begin
    /**
     * MD - 9 Aug 2010 It seems that the basic algorithm is slightly orientation
     * dependent, when computing the orientation of a point very close to a
     * line. This is possibly due to the arithmetic in the translation to the
     * origin.
     * 
     * For instance, the following situation produces identical results in spite
     * of the inverse orientation of the line segment:
     * 
     * Coordinate p0 = new Coordinate(219.3649559090992, 140.84159161824724);
     * Coordinate p1 = new Coordinate(168.9018919682399, -5.713787599646864);
     * 
     * Coordinate p = new Coordinate(186.80814046338352, 46.28973405831556); int
     * orient = orientationIndex(p0, p1, p); int orientInv =
     * orientationIndex(p1, p0, p);
     * 
     * A way to force consistent results is to normalize the orientation of the
     * vector using the following code. However, this may make the results of
     * orientationIndex inconsistent through the triangle of points, so it's not
     * clear this is an appropriate patch.
     * 
     */
    return orientationIndex(p1, p2, q);
  End oindex;

  -- ************************************************************************************
  
  /*private static Number MAX_CLOSING_SEG_LEN := 3.0;*/

  Procedure addNextSegment(p in spdba.T_Vertex, addStartPoint in boolean)
  As
    orientation pls_integer;
    outsideTurn boolean ;
  Begin
    -- s0-s1-s2 are the coordinates of the previous segment and the current one
    s0 := s1;
    s1 := s2;
    s2 := p;
    seg0.ST_SetCoordinates(s0, s1);
    offset0 := computeOffsetSegment(seg0, side, distance);
    seg1.ST_SetCoordinates(s1, s2);
    offset1 := computeOffsetSegment(seg1, side, distance);

    -- do nothing if points are equal
    if (s1.ST_Equals(s2,dPrecision)=1) then 
      return;
    End If;

    orientation := oindex(s0, s1, s2);
    outsideTurn := (orientation = CLOCKWISE        AND side = Position.LEFT)
               OR  (orientation = COUNTERCLOCKWISE AND side = Position.RIGHT);

    if (orientation = 0) then -- lines are collinear
      addCollinear(addStartPoint);
    elsif (outsideTurn) then
      addOutsideTurn(orientation, addStartPoint);
    else -- inside turn
      addInsideTurn(orientation, addStartPoint);
    End If;
  End addNextSegment;

  /**
   * From RobustLineIntersector
   **/
   Function computeIntersection(
                p  in spdba.T_Vertex, 
                p1 in spdba.T_Vertex, 
                p2 in spdba.T_Vertex) 
   Return integer
   As
     envelope spdba.T_MBR;
   Begin
    isProper := false;
    -- do between check first, since it is faster than the orientation test
    if (spdba.T_MBR.Intersects(p1, p2, p)) Then
      if ((oindex(p1, p2, p) = 0) AND (oindex(p2, p1, p) = 0)) Then
        isProper := true;
        if ( p.ST_Equals(p1,dPrecision)=1 OR p.ST_Equals(p2,dPrecision)=1 ) Then
          isProper := false;
        End If;
        return spdba.OffsetSegmentGenerator.POINT_INTERSECTION;
      End If;
    End If;
    return spdba.OffsetSegmentGenerator.NO_INTERSECTION;
  End computeIntersection;

  Procedure addCollinear(addStartPoint in boolean)
  As
    numInt number;
  Begin
    /**
     * This test could probably be done more efficiently,
     * but the situation of exact collinearity should be fairly rare.
     */
    numInt := computeIntersection(s0, s1, s2);
    -- SGG int numInt := li.getIntersectionNum();
    /**
     * if numInt is < 2, the lines are parallel and in the same direction. In
     * this case the point can be ignored, since the offset lines will also be
     * parallel.
     */
    if (numInt >= 2) then
      /**
       * segments are collinear but reversing. 
       * Add an "end-cap" fillet
       * all the way around to other direction This case should ONLY happen
       * for LineStrings, so the orientation is always CW. (Polygons can never
       * have two consecutive segments which are parallel but reversed,
       * because that would be a self intersection.
       * 
       */
      if (bufParams.getJoinStyle() = BufferParameterConstants.JOIN_BEVEL 
       OR bufParams.getJoinStyle() = BufferParameterConstants.JOIN_MITRE) Then
        if (addStartPoint) then segList.addPt(offset0.endCoord); End If;
        segList.addPt(offset1.startCoord); -- p0);
      else 
        addCornerFillet(s1, offset0.startCoord, offset1.startCoord, CLOCKWISE, distance);
      End If;
    End If;
  End addCollinear;

  /**
   * Adds the offset points for an outside (convex) turn
   * 
   * @param orientation
   * @param addStartPoint
   */
  Procedure addOutsideTurn(orientation in integer, addStartPoint in boolean)
  As
  Begin
    /**
     * Heuristic: If offset endpoints are very close together, 
     * just use one of them as the corner vertex.
     * This avoids problems with computing mitre corners in the case
     * where the two segments are almost parallel 
     * (which is hard to compute a robust intersection for).
     */
    if (offset0.endCoord.st_distance(offset1.startCoord) < distance * spdba.OffsetSegmentGenerator.OFFSET_SEGMENT_SEPARATION) Then
      segList.addPt(offset0.endCoord); -- p1);
      return;
    End If;

    if (bufParams.getJoinStyle() = spdba.BufferParameterConstants.JOIN_MITRE) Then
      addMitreJoin(s1, offset0, offset1, distance);
    elsif (bufParams.getJoinStyle() = spdba.BufferParameterConstants.JOIN_BEVEL) Then
      addBevelJoin(offset0, offset1);
    else 
      -- add a circular fillet connecting the endpoints of the offset segments
      if (addStartPoint) then segList.addPt(offset0.endCoord); end If;
      -- TESTING - comment out to produce beveled joins
      addCornerFillet(s1, offset0.endCoord, offset1.startCoord, orientation, distance);
      segList.addPt(offset1.startCoord);
    End If;
  End addOutsideTurn;

  Function getIntersection(intIndex in integer)
    Return spdba.T_Vertex
  As
  Begin
    return intPt(intIndex); 
  End getIntersection;

  /** Adds the offset points for an inside (concave) turn.
   * 
   * @param orientation
   * @param addStartPoint
   */
  Procedure addInsideTurn(orientation in integer, addStartPoint in boolean) 
  As
    numInt number;
    mid0 spdba.T_Vertex;
    mid1 spdba.T_Vertex;
  Begin
     /* add intersection point of offset segments (if any)
     */
    --li.computeIntersection(offset0.startCoord, offset0.endCoord, offset1.startCoord, offset1.endCoord);
    --if (li.hasIntersection()) then
    numInt := computeIntersection(
                 offset0.startCoord, 
                 offset0.endCoord, 
                 offset1.startCoord, 
                 offset1.endCoord
              );
    if (numInt != spdba.OffsetSegmentGenerator.NO_INTERSECTION) then
      segList.addPt(getIntersection(0));
    else 
      /**
       * If no intersection is detected, 
       * it means the angle is so small and/or the offset so
       * large that the offsets segments don't intersect. 
       * In this case we must
       * add a "closing segment" to make sure the buffer curve is continuous,
       * fairly smooth (e.g. no sharp reversals in direction)
       * and tracks the buffer correctly around the corner. The curve connects
       * the endpoints of the segment offsets to points
       * which lie toward the centre point of the corner.
       * The joining curve will not appear in the final buffer outline, since it
       * is completely internal to the buffer polygon.
       * 
       * In complex buffer cases the closing segment may cut across many other
       * segments in the generated offset curve.  In order to improve the 
       * performance of the noding, the closing segment should be kept as short as possible.
       * (But not too short, since that would defeat its purpose).
       * This is the purpose of the closingSegFactor heuristic value.
       */ 

       /** 
       * The intersection test above is vulnerable to robustness errors; i.e. it
       * may be that the offsets should intersect very close to their endpoints,
       * but aren't reported as such due to rounding. To handle this situation
       * appropriately, we use the following test: If the offset points are very
       * close, don't add closing segments but simply use one of the offset
       * points
       */
      bHasNarrowConcaveAngle := true;
      --System.out.println("NARROW ANGLE - distance = " + distance);
      if (offset0.endCoord.st_distance(offset1.startCoord) < distance * spdba.OffsetSegmentGenerator.INSIDE_TURN_VERTEX_SNAP_DIST) then
        segList.addPt(offset0.endCoord);
      else
        -- add endpoint of this segment offset
        segList.addPt(offset0.endCoord);

        /**
         * Add "closing segment" of required length.
         */
        if (closingSegLengthFactor > 0) then
          mid0 := new SPDBA.T_Vertex(
                        p_x=>(closingSegLengthFactor*offset0.endCoord.x + s1.x)/(closingSegLengthFactor + 1), 
                        p_y=>(closingSegLengthFactor*offset0.endCoord.y + s1.y)/(closingSegLengthFactor + 1)
                  );
          segList.addPt(mid0);
          mid1 := new SPDBA.T_Vertex(
                        p_x=>(closingSegLengthFactor*offset1.startCoord.x + s1.x)/(closingSegLengthFactor + 1), 
                        p_y=>(closingSegLengthFactor*offset1.startCoord.y + s1.y)/(closingSegLengthFactor + 1)
                  );
          segList.addPt(mid1);
        else 
          /**
           * This branch is not expected to be used except for testing purposes.
           * It is equivalent to the JTS 1.9 logic for closing segments
           * (which results in very poor performance for large buffer distances)
           */
          segList.addPt(s1);
        End If;

        -- add start point of next segment offset
        segList.addPt(offset1.startCoord);
      End If;
    End If;
  End addInsideTurn;

  /**
   * Compute an offset segment for an input segment on a given side and at a given distance.
   * The offset points are computed in full Number precision, for accuracy.
   *
   * @param seg the segment to offset
   * @param side the side of the segment ({@link Position}) the offset lies on
   * @param distance the offset distance
   * @param offset the points computed for the offset segment
   */
  Function computeOffsetSegment(
               seg      in spdba.T_Segment, 
               side     in pls_integer, 
               distance in Number
            )
    return spdba.T_Segment
  As
    sideSign pls_integer;
    dx       Number;
    dy       Number;
    len      Number;
    ux       Number;
    uy       Number;
  Begin
    sideSign := case when side = Position.LEFT then 1 else 1 end;
    dx := seg.endCoord.x - seg.startCoord.x;
    dy := seg.endCoord.y - seg.startCoord.y;
    len := SQRT(dx * dx + dy * dy);
    -- u is the vector that is the length of the offset, in the direction of the segment
    ux := sideSign * distance * dx / len;
    uy := sideSign * distance * dy / len;
    return spdba.T_Segment( p_segment_id => null,
                            p_startCoord => spdba.T_Vertex(
                                               p_x         => seg.startCoord.x - uy,
                                               p_y         => seg.startCoord.y + ux,
                                               p_id        => 1,
                                               p_sdo_gtype => 2001,
                                               p_sdo_srid  => NULL),
                            p_endCoord   => spdba.T_Vertex(
                                               p_x         => seg.endCoord.x - uy,
                                               p_y         => seg.endCoord.y + ux,
                                               p_id        => 1,
                                               p_sdo_gtype => 2001,
                                               p_sdo_srid  => NULL),
                           p_sdo_gtype   => 2002,
                           p_sdo_srid    => Null
        );
--    offset.startCoord.x := seg.startCoord.x - uy;
--    offset.startCoord.y := seg.startCoord.y + ux;
--    offset.endCoord.x := seg.endCoord.x - uy;
--    offset.endCoord.y := seg.endCoord.y + ux;
  End computeOffsetSegment;

  /**
   * Add an end cap around point p1, terminating a line segment coming from p0
   */
  Procedure addLineEndCap(
               p0 in spdba.T_Vertex, 
               p1 in spdba.T_Vertex)
  As
    dx                  Number;
    dy                  Number;
    angle               Number;
    seg                 spdba.T_Segment;
    offsetL             spdba.T_Segment;
    offsetR             spdba.T_Segment;
    squareCapSideOffset SPDBA.T_Vertex;
    squareCapLOffset    SPDBA.T_Vertex;
    squareCapROffset    SPDBA.T_Vertex;
  Begin
    seg     := new spdba.T_Segment( p_segment_id => null,
                                    p_startCoord => spdba.T_Vertex(p0),
                                    p_endCoord   => spdba.T_Vertex(p1),
                                    p_sdo_gtype   => 2002,
                                    p_sdo_srid    => Null
                   );

    offsetL := new spdba.T_Segment();
    offsetL := computeOffsetSegment(seg, Position.LEFT, distance);
    offsetR := new spdba.T_Segment();
    offsetR := computeOffsetSegment(seg, Position.RIGHT, distance);

    dx := p1.x - p0.x;
    dy := p1.y - p0.y;
    angle := spdba.COGO.ArcTan2(dy, dx);

    If (bufParams.getEndCapStyle() = BufferParameterConstants.CAP_ROUND ) Then
        -- add offset seg points with a fillet between them
        segList.addPt(offsetL.endCoord);
        addDirectedFillet(p1, angle + SPDBA.COGO.PI() / 2.0, angle - SPDBA.COGO.PI() / 2.0, CLOCKWISE, distance);
        segList.addPt(offsetR.endCoord);
    ElsIf (bufParams.getEndCapStyle() = BufferParameterConstants.CAP_FLAT ) Then
        -- only offset segment points are added
        segList.addPt(offsetL.endCoord);
        segList.addPt(offsetR.endCoord);
    ElsIf (bufParams.getEndCapStyle() = BufferParameterConstants.CAP_SQUARE ) Then
        -- add a square defined by extensions of the offset segment endpoints
        squareCapSideOffset := new SPDBA.T_Vertex();
        squareCapSideOffset.x := ABS(distance) * COS(angle);
        squareCapSideOffset.y := ABS(distance) * SIN(angle);

        squareCapLOffset := new SPDBA.T_Vertex(
                                  p_x=>offsetL.endCoord.x + squareCapSideOffset.x,
                                  p_y=>offsetL.endCoord.y + squareCapSideOffset.y);
        squareCapROffset := new SPDBA.T_Vertex(
                                  p_x=>offsetR.endCoord.x + squareCapSideOffset.x,
                                  p_y=>offsetR.endCoord.y + squareCapSideOffset.y);
        segList.addPt(squareCapLOffset);
        segList.addPt(squareCapROffset);
    End If;
  End addLineEndCap;

  /**
   * Adds a mitre join connecting the two reflex offset segments.
   * The mitre will be beveled if it exceeds the mitre ratio limit.
   * 
   * @param offset0 the first offset segment
   * @param offset1 the second offset segment
   * @param distance the offset distance
   */
  Procedure addMitreJoin(p        in spdba.T_vertex, 
                         offset0  in spdba.T_Segment,
                         offset1  in spdba.T_Segment,
                         distance in Number)
  As
    isMitreWithinLimit boolean;
    mitreRatio         Number;
    intPt              SPDBA.T_Vertex;

    /**
     * Computes the (approximate) intersection point between two line segments
     * using homogeneous coordinates.
     * <p>
     * Note that this algorithm is
     * not numerically stable; i.e. it can produce intersection points which
     * lie outside the envelope of the line segments themselves.  In order
     * to increase the precision of the calculation input points should be normalized
     * before passing them to this routine.
      throws NotRepresentableException
     */
    Function HIntersection (
      p1 in spdba.T_Vertex, 
      p2 in spdba.T_Vertex,
      q1 in spdba.T_Vertex, 
      q2 in spdba.T_Vertex
    )
     Return spdba.T_Vertex
    As
      px   binary_float;
      py   binary_float;
      pw   binary_float;
      qx   binary_float;
      qy   binary_float;
      qw   binary_float;
      x    binary_float;
      y    binary_float;
      w    binary_float;
      xInt binary_float;
      yInt binary_float;
    Begin
      -- unrolled computation
      px := p1.y - p2.y;
      py := p2.x - p1.x;
      pw := p1.x * p2.y - p2.x * p1.y;

      qx := q1.y - q2.y;
      qy := q2.x - q1.x;
      qw := q1.x * q2.y - q2.x * q1.y;

      x := py * qw - qy * pw;
      y := qx * pw - px * qw;
      w := px * qy - qx * py;

      xInt := x/w;
      yInt := y/w;

      if ( xInt = BINARY_DOUBLE_NAN or xInt = binary_double_infinity 
        or yInt = BINARY_DOUBLE_NAN or yInt = binary_double_infinity ) Then
        raise_application_error(-20001,'NotRepresentableException');
      end if;
      return new spdba.T_Vertex(
                        p_id => 1,
                        p_x  => CAST(xInt as number), 
                        p_y  => CAST(yInt as number),
                        p_sdo_gtype => 2001,
                        p_sdo_srid  => NULL
                 );
    End HIntersection;

  Begin
    isMitreWithinLimit := true;
    intPt              := null;
    /**
     * This computation is unstable if the offset segments are nearly collinear.
     * However, this situation should have been eliminated earlier by the check for
     * whether the offset segment endpoints are almost coincident
     */
    Begin
     intPt      := HIntersection(
                      offset0.startCoord, 
                      offset0.endCoord, 
                      offset1.startCoord, 
                      offset1.endCoord
                   );
     mitreRatio := case when distance <= 0.0 then 1.0 else intPt.st_distance(p) / ABS(distance) end;
     if (mitreRatio > bufParams.getMitreLimit()) then
       isMitreWithinLimit := false;
     End If;
      Exception
        when others /* -20001 NotRepresentableException */ then
          intPt              := new SPDBA.T_Vertex(p_x=>0,p_y=>0);
          isMitreWithinLimit := false;
    End;
    if (isMitreWithinLimit) then
      segList.addPt(intPt);
    else 
      addLimitedMitreJoin(offset0, offset1, distance, bufParams.getMitreLimit());
    end if;
  End addMitreJoin;

  /**
   * Adds a limited mitre join connecting the two reflex offset segments.
   * A limited mitre is a mitre which is beveled at the distance
   * determined by the mitre ratio limit.
   * 
   * @param offset0 the first offset segment
   * @param offset1 the second offset segment
   * @param distance the offset distance
   * @param mitreLimit the mitre limit ratio
   */
  Procedure addLimitedMitreJoin( 
      offset0    in spdba.T_Segment,
      offset1    in spdba.T_Segment,
      p_distance in number,
      mitreLimit in number)
  As
    basePt        spdba.T_Vertex;
    ang0          Number;
    ang1          Number;
    angDiff       Number;
    angDiffHalf   Number;
    midAng        Number;
    mitreMidAng   Number;
    mitreDist     Number;
    bevelDelta    Number;
    bevelHalfLen  Number;
    bevelMidX     Number;
    bevelMidY     Number;
    bevelMidPt    spdba.T_Vertex;
    mitreMidLine  spdba.T_Segment;
    bevelEndLeft  spdba.T_Vertex;
    bevelEndRight spdba.T_Vertex;

  Begin
    basePt      := seg0.endCoord;

    ang0        := Angle.angle(basePt, seg0.startCoord);
    ang1        := Angle.angle(basePt, seg1.endCoord);

    -- oriented angle between segments
    angDiff     := Angle.angleBetweenOriented(seg0.startCoord, basePt, seg1.endCoord);
    -- half of the interior angle
    angDiffHalf := angDiff / 2;

    -- angle for bisector of the interior angle between the segments
    midAng      := Angle.normalize(ang0 + angDiffHalf);
    -- rotating this by PI gives the bisector of the reflex angle
    mitreMidAng := Angle.normalize(midAng + SPDBA.COGO.PI());

    -- the miterLimit determines the distance to the mitre bevel
    mitreDist := mitreLimit * p_distance;
    -- the bevel delta is the difference between the buffer distance
    -- and half of the length of the bevel segment
    bevelDelta   := mitreDist * ABS(SIN(angDiffHalf));
    bevelHalfLen := p_distance - bevelDelta;

    -- compute the midpoint of the bevel segment
    bevelMidX := basePt.x + mitreDist * COS(mitreMidAng);
    bevelMidY := basePt.y + mitreDist * SIN(mitreMidAng);
    bevelMidPt := new SPDBA.T_Vertex(p_x=>bevelMidX, p_y=>bevelMidY);

    -- compute the mitre midline segment from the corner point to the bevel segment midpoint
    mitreMidLine := new spdba.T_Segment( p_segment_id => null,
                            p_startCoord => spdba.T_Vertex(basePt),
                            p_endCoord   => spdba.T_Vertex(bevelMidPt),
                            p_sdo_gtype  => 2002,
                            p_sdo_srid   => Null
        );

    -- finally the bevel segment endpoints are computed as offsets from 
    -- the mitre midline
    bevelEndLeft  := mitreMidLine.ST_PointAlongOffset(1.0, bevelHalfLen);
    bevelEndRight := mitreMidLine.ST_PointAlongOffset(1.0, -bevelHalfLen);

    if (side = Position.LEFT) Then
      segList.addPt(bevelEndLeft);
      segList.addPt(bevelEndRight);
    else 
      segList.addPt(bevelEndRight);
      segList.addPt(bevelEndLeft);     
    End If;
  End addLimitedMitreJoin;

  /**
   * Adds a bevel join connecting the two offset segments
   * around a reflex corner.
   * 
   * @param offset0 the first offset segment
   * @param offset1 the second offset segment
   */
  Procedure addBevelJoin( 
      offset0 in spdba.T_Segment, 
      offset1 in spdba.T_Segment)
  As
  Begin
     segList.addPt(offset0.endCoord);
     segList.addPt(offset1.startCoord);        
  End addBevelJoin;

  /**
   * Add points for a circular fillet around a reflex corner.
   * Adds the start and end points
   * 
   * @param p base point of curve
   * @param p0 start point of fillet curve
   * @param p1 endpoint of fillet curve
   * @param direction the orientation of the fillet
   * @param radius the radius of the fillet
   */
  Procedure addCornerFillet(
               p         in spdba.T_Vertex, 
               p0        in spdba.T_Vertex, 
               p1        in spdba.T_Vertex, 
               direction in integer, 
               radius    in number)
  As
    dx0        Number;
    dy0        Number;
    startAngle Number;
    dx1        Number;
    dy1        Number;
    endAngle   Number;
  Begin
    dx0 := p0.x - p.x;
    dy0 := p0.y - p.y;
    startAngle := ATan2(dy0, dx0);
    dx1 := p1.x - p.x;
    dy1 := p1.y - p.y;
    endAngle := ATan2(dy1, dx1);

    if (direction = CLOCKWISE) then
      if (startAngle <= endAngle) then
         startAngle := startAngle + 2.0 * SPDBA.COGO.PI();
      End If;
    else -- direction = COUNTERCLOCKWISE
      if (startAngle >= endAngle) then
          startAngle := startAngle - 2.0 * SPDBA.COGO.PI();
      End If;
    End If;
    segList.addPt(p0);
    addDirectedFillet(p, startAngle, endAngle, direction, radius);
    segList.addPt(p1);
  End addCornerFillet;

  /**
   * Adds points for a circular fillet arc
   * between two specified angles.  
   * The start and end point for the fillet are not added -
   * the caller must add them if required.
   *
   * @param direction is -1 for a CW angle, 1 for a CCW angle
   * @param radius the radius of the fillet
   */
  Procedure addDirectedFillet(
               p in spdba.T_Vertex, 
               startAngle in Number, 
               endAngle in Number, 
               direction in integer, 
               radius in Number )
  As
    directionFactor pls_integer;
    totalAngle      number;
    nSegs           pls_integer;
    initAngle       number;
    currAngleInc    number;
    currAngle       Number;
    pt              spdba.T_Vertex;
    angle           Number;
  Begin
    directionFactor := case when direction = CLOCKWISE then -1 else 1 end;
    totalAngle      := ABS(startAngle - endAngle);
    nSegs           := (totalAngle / filletAngleQuantum + 0.5);

    if (nSegs < 1) then
      return;    -- no segments because angle is less than increment - nothing to do!
    End If;

    -- choose angle increment so that each segment has equal length
    initAngle    := 0.0;
    currAngleInc := totalAngle / nSegs;

    currAngle := initAngle;
    pt        := new SPDBA.T_Vertex();
    while (currAngle < totalAngle) loop
      angle := startAngle + directionFactor * currAngle;
      pt.x  := p.x + radius * COS(angle);
      pt.y  := p.y + radius * SIN(angle);
      segList.addPt(pt);
      currAngle := currAngle + currAngleInc;
    end loop;
  End addDirectedFillet;

  /**
   * Creates a CW circle around a point
   */
  Procedure createCircle(p in spdba.T_Vertex)
  As
    pt spdba.T_Vertex;
  Begin
    -- add start point
    pt := new spdba.T_Vertex(p_x=>p.x + distance, p_y=>p.y);
    segList.addPt(pt);
    addDirectedFillet(p, 0.0, 2.0 * SPDBA.COGO.PI(), -1, distance);
    segList.closeRing();
  End createCircle;

  /**
   * Creates a CW square around a point
   */
  Procedure createSquare(p in spdba.T_Vertex)
  As
  Begin
    segList.addPt(new SPDBA.T_Vertex(p_x=>p.x + distance, p_y=>p.y + distance));
    segList.addPt(new SPDBA.T_Vertex(p_x=>p.x + distance, p_y=>p.y - distance));
    segList.addPt(new SPDBA.T_Vertex(p_x=>p.x - distance, p_y=>p.y - distance));
    segList.addPt(new SPDBA.T_Vertex(p_x=>p.x - distance, p_y=>p.y + distance));
    segList.closeRing();
  End createSquare;

END;
/
show errors

