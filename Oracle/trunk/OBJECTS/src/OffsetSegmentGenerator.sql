--------------------------------------------------------
--  File created - Wednesday-July-24-2019   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package OFFSETSEGMENTGENERATOR
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "SPDBA"."OFFSETSEGMENTGENERATOR" 
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
                p_s1   in spdba.T_Vertex, 
                p_s2   in spdba.T_Vertex, 
                p_side in integer
            );

  Function getCoordinates
   Return spdba.T_Vertices;

  Procedure closeRing;

  Procedure addSegments(pt in spdba.T_Vertices, isForward in boolean);

  Procedure addFirstSegment;

  /**
   * Add last offset point
   */
  Procedure addLastSegment;

  /*private static Number MAX_CLOSING_SEG_LEN := 3.0;*/

  Procedure addNextSegment(p in spdba.T_Vertex, addStartPoint in boolean);

  /**
   * From RobustLineIntersector
   **/
   Function computeIntersection(p in spdba.T_Vertex, p1 in spdba.T_Vertex, p2 in spdba.T_Vertex) 
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
    Return spdba.T_Vertex deterministic;

  /**
   * Add an end cap around point p1, terminating a line segment coming from p0
   */
  Procedure addLineEndCap(p0 in spdba.T_Vertex, p1 in spdba.T_Vertex);

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
               offset0    in spdba.T_Segment,
               offset1    in spdba.T_Segment,
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
      offset0 in spdba.T_Segment, 
      offset1 in spdba.T_Segment);

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
  Procedure addCornerFillet(p in spdba.T_Vertex, p0 in spdba.T_Vertex, p1 in spdba.T_Vertex, direction in integer, radius in number);

  /**
   * Adds points for a circular fillet arc
   * between two specified angles.  
   * The start and end point for the fillet are not added -
   * the caller must add them if required.
   *
   * @param direction is -1 for a CW angle, 1 for a CCW angle
   * @param radius the radius of the fillet
   */
  Procedure addDirectedFillet(p in spdba.T_Vertex, startAngle in Number, endAngle in Number, direction in integer, radius in Number );

  /**
   * Creates a CW circle around a point
   */
  Procedure createCircle(p in spdba.T_Vertex);

  /**
   * Creates a CW square around a point
   */
  Procedure createSquare(p in spdba.T_Vertex);

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
    return spdba.T_Segment deterministic;

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
               seg      in spdba.T_Segment, 
               side     in pls_integer, 
               distance in Number
            )
    return spdba.T_Segment deterministic;


END;

/
