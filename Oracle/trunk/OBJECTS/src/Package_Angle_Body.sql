--------------------------------------------------------
--  File created - Wednesday-July-31-2019   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package Body ANGLE
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "SPDBA"."ANGLE" 
AS

  /**
   * Utility functions for working with angles.
   * Unless otherwise noted, methods in this class express angles in radians.
  */

  PI_TIMES_2 CONSTANT NUMBER := SPDBA.COGO.PI() * 2.0;
  PI_OVER_2  CONSTANT NUMBER := SPDBA.COGO.PI() / 2.0;
  PI_OVER_4  CONSTANT NUMBER := SPDBA.COGO.PI() / 4.0;

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
  LEFT CONSTANT INTEGER := COUNTERCLOCKWISE;
  /**
   * A value that indicates an orientation of collinear, or no turn (straight).
   */
  COLLINEAR CONSTANT INTEGER := 0;
  /**
   * A value that indicates an orientation of collinear, or no turn (straight).
   */
  STRAIGHT CONSTANT INTEGER := COLLINEAR;

  /** Constant representing no orientation */
  NONE CONSTANT INTEGER := COLLINEAR;

  /**
   * Converts from radians to degrees.
   * @param radians an angle in radians
   * @return the angle in degrees
   */
  Function toDegrees(radians in number) 
  Return Number
  As
  Begin
    return (radians * 180.0) / (SPDBA.COGO.PI());
  End toDegrees;

  /**
   * Converts from degrees to radians.
   *
   * @param angleDegrees an angle in degrees
   * @return the angle in radians
   */
  Function toRadians(angleDegrees in number) 
  Return Number
  As
  Begin
    return (angleDegrees * SPDBA.COGO.PI()) / 180.0;
  End toRadians;

  /**
   * Returns the angle of the vector from p0 to p1,
   * relative to the positive X-axis.
   * The angle is normalized to be in the range [ -Pi, Pi ].
   *
   * @return the normalized angle (in radians) that p0-p1 makes with the positive x-axis.
   */
  Function angle(p0 in T_Vertex, p1 in T_Vertex) 
  Return Number
  As
    dx number;
    dy number;
  Begin
    dx := p1.x - p0.x;
    dy := p1.y - p0.y;
    return COGO.ArcTan2(dy, dx);
  End Angle;

  /**
   * Returns the angle that the vector from (0,0) to p,
   * relative to the positive X-axis.
   * The angle is normalized to be in the range ( -Pi, Pi ].
   *
   * @return the normalized angle (in radians) that p makes with the positive x-axis.
   */
  Function angle(p in T_Vertex)
  Return Number
  As
  Begin
      return COGO.ArcTan2(p.y, p.x);
  End angle;


  /**
   * Tests whether the angle between p0-p1-p2 is acute.
   * An angle is acute if it is less than 90 degrees.
   * <p>
   * Note: this implementation is not precise (deterministic) for angles very close to 90 degrees.
   *
   * @param p0 an endpoint of the angle
   * @param p1 the base of the angle
   * @param p2 the other endpoint of the angle
   */
  Function isAcute(p0 in T_Vertex, p1 in T_Vertex, p2 in T_Vertex)
  Return boolean
  As
    dx0     Number;
    dy0     Number;
    dx1     Number;
    dy1     Number;
    dotprod Number;
  Begin
    -- relies on fact that A dot B is positive iff A ang B is acute
    dx0 := p0.x - p1.x;
    dy0 := p0.y - p1.y;
    dx1 := p2.x - p1.x;
    dy1 := p2.y - p1.y;
    dotprod := dx0 * dx1 + dy0 * dy1;
    return dotprod > 0;
  End isAcute;

  /**
   * Tests whether the angle between p0-p1-p2 is obtuse.
   * An angle is obtuse if it is greater than 90 degrees.
   * <p>
   * Note: this implementation is not precise (deterministic) for angles very close to 90 degrees.
   *
   * @param p0 an endpoint of the angle
   * @param p1 the base of the angle
   * @param p2 the other endpoint of the angle
   */
  Function isObtuse(p0 in T_Vertex, p1 in T_Vertex, p2 in T_Vertex)
  Return boolean
  As
    dx0     Number;
    dy0     Number;
    dx1     Number;
    dy1     Number;
    dotprod Number;
  Begin
    -- relies on fact that A dot B is negative iff A ang B is obtuse
    dx0 := p0.x - p1.x;
    dy0 := p0.y - p1.y;
    dx1 := p2.x - p1.x;
    dy1 := p2.y - p1.y;
    dotprod := dx0 * dx1 + dy0 * dy1;
    return dotprod < 0;
  End isObtuse;

  /*
   * Returns the unoriented smallest angle between two vectors.
   * The computed angle will be in the range [0, Pi).
   *
   * @param tip1 the tip of one vector
   * @param tail the tail of each vector
   * @param tip2 the tip of the other vector
   * @return the angle between tail-tip1 and tail-tip2
   */
  Function angleBetween(tip1 in T_Vertex, tail in T_Vertex, tip2 in T_Vertex) 
  Return Number
  As
    a1 number;
    a2 number;
  Begin
    a1 := angle(tail, tip1);
    a2 := angle(tail, tip2);
    return diff(a1, a2);
  End angleBetween;

  /**
   * Returns the oriented smallest angle between two vectors.
   * The computed angle will be in the range (-Pi, Pi].
   * A positive result corresponds to a counterclockwise
   * (CCW) rotation from v1 to v2;
   * a negative result corresponds to a clockwise (CW) rotation;
   * a zero result corresponds to no rotation.
   *
   * @param tip1 the tip of v1
   * @param tail the tail of each vector
   * @param tip2 the tip of v2
   * @return the angle between v1 and v2, relative to v1
   */
  Function angleBetweenOriented(tip1 in T_Vertex, tail in T_Vertex, tip2 in T_Vertex) 
  Return Number
  As
    a1     Number;
    a2     Number;
    angDel Number;
  Begin
    a1     := angle(tail, tip1);
    a2     := angle(tail, tip2);
    angDel := a2 - a1;
    -- normalize, maintaining orientation
    if (angDel <= -SPDBA.COGO.PI()) then
       return angDel + PI_TIMES_2;
    end if;
    if (angDel > SPDBA.COGO.PI()) then
       return angDel - PI_TIMES_2;
    end if;
    return angDel;
  End angleBetweenOriented;

  /**
     * Computes the interior angle between two segments of a ring. The ring is
     * assumed to be oriented in a clockwise direction. The computed angle will be
     * in the range [0, 2Pi]
     * 
     * @param p0
     *          a point of the ring
     * @param p1
     *          the next point of the ring
     * @param p2
     *          the next point of the ring
     * @return the interior angle based at <code>p1</code>
     */
  Function interiorAngle(p0 in T_Vertex, p1 in T_Vertex, p2 in T_Vertex)
  Return number
  As
    anglePrev Number;
    angleNext Number;
  Begin
    anglePrev := angle(p1, p0);
    angleNext := angle(p1, p2);
    return ABS(angleNext - anglePrev);
  end interiorAngle;

  /**
   * Returns whether an angle must turn clockwise or counterclockwise
   * to overlap another angle.
   *
   * @param ang1 an angle (in radians)
   * @param ang2 an angle (in radians)
   * @return whether a1 must turn CLOCKWISE, COUNTERCLOCKWISE or NONE to
   * overlap a2.
   */
  Function getTurn(p_ang1 in number, p_ang2 in number) 
  Return integer
  As
    crossproduct number;
  Begin
    crossproduct := SIN(p_ang2 - p_ang1);
    if (crossproduct > 0) then
      return COUNTERCLOCKWISE;
    end If;
    if (crossproduct < 0) then
      return CLOCKWISE;
    end If;
    return NONE;
  End getTurn;

  /**
   * Computes the normalized value of an angle, which is the
   * equivalent angle in the range ( -Pi, Pi ].
   *
   * @param angle the angle to normalize
   * @return an equivalent angle in the range (-Pi, Pi]
   */
  Function normalize(p_angle in number)
  Return Number
  As
    v_angle Number;
  Begin
    v_angle := p_angle;
    while (v_angle > SPDBA.COGO.PI()) loop
      v_angle := v_angle - PI_TIMES_2;
    end loop; 
    while (v_angle <= 0 - SPDBA.COGO.PI()) loop
      v_angle := v_angle + PI_TIMES_2;
    end loop;
    return v_angle;
  End normalize;

  /**
   * Computes the normalized positive value of an angle, which is the
   * equivalent angle in the range [ 0, 2*Pi ).
   * E.g.:
   * <ul>
   * <li>normalizePositive(0.0) = 0.0
   * <li>normalizePositive(-PI) = PI
   * <li>normalizePositive(-2PI) = 0.0
   * <li>normalizePositive(-3PI) = PI
   * <li>normalizePositive(-4PI) = 0
   * <li>normalizePositive(PI) = PI
   * <li>normalizePositive(2PI) = 0.0
   * <li>normalizePositive(3PI) = PI
   * <li>normalizePositive(4PI) = 0.0
   * </ul>
   *
   * @param angle the angle to normalize, in radians
   * @return an equivalent positive angle
   */
  Function normalizePositive(p_angle in number)
  Return number
  As
    v_angle number;
  Begin
    v_angle := p_angle;
    if (v_angle < 0.0) then
      while (v_angle < 0.0) loop
        v_angle := v_angle + PI_TIMES_2;
      end loop;
        -- in case round-off error bumps the value over 
        if (v_angle >= PI_TIMES_2) then
          v_angle := 0.0;
        end if;
    else 
      while (v_angle >= PI_TIMES_2) loop
        v_angle := v_angle - PI_TIMES_2;
      end loop;
      -- in case round-off error bumps the value under 
      if (v_angle < 0.0) then
        v_angle := 0.0;
      end if;
    End if;
    return v_angle;
  end normalizePositive;

  /**
   * Computes the unoriented smallest difference between two angles.
   * The angles are assumed to be normalized to the range [-Pi, Pi].
   * The result will be in the range [0, Pi].
   *
   * @param ang1 the angle of one vector (in [-Pi, Pi] )
   * @param ang2 the angle of the other vector (in range [-Pi, Pi] )
   * @return the angle (in radians) between the two vectors (in range [0, Pi] )
   */
  Function diff(ang1 in number, ang2 in number) 
  Return Number
  As
    delAngle Number;
  Begin
    if (ang1 < ang2) then
      delAngle := ang2 - ang1;
    else 
      delAngle := ang1 - ang2;
    end if;
    if (delAngle > SPDBA.COGO.PI()) then
      delAngle := (2.0 * SPDBA.COGO.PI()) - delAngle;
    end if;
    return delAngle;
  End diff;

END;
/
show errors

set serveroutput on size unlimited
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
   v_OK       boolean      := FALSE;
   v_obj_name varchar2(30) := 'ANGLE';
BEGIN
   FOR rec IN (select object_name,object_Type, status 
                 from user_objects
                where object_name = v_obj_name
                  and object_type = 'PACKAGE BODY'
                order by object_type) LOOP
      IF ( rec.status = 'VALID' ) Then
         dbms_output.put_line(rec.object_type || ' ' || USER || '.' || rec.object_name || ' is valid.');
         v_ok := TRUE;
      ELSE
         dbms_output.put_line(rec.object_type || ' ' || USER || '.' || rec.object_name || ' is invalid.');
      END IF;
   END LOOP;
   IF ( NOT v_OK ) THEN
      RAISE_APPLICATION_ERROR(-20000,v_obj_name || ' failed to install.');
   END IF;
END;
/
SHOW ERRORS

EXIT SUCCESS;

