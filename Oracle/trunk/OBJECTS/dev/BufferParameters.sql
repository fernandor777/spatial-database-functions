DEFINE INSTALL_SCHEMA='&1'

SET VERIFY OFF;

CREATE OR REPLACE EDITIONABLE TYPE &&INSTALL_SCHEMA..BUFFERPARAMETERS 
AUTHID CURRENT_USER
AS Object (

  quadrantSegments INTEGER,
  endCapStyle      INTEGER,
  joinStyle        INTEGER,
  mitreLimit       Number,
  bIsSingleSided   INTEGER,
  simplifyFactor   Number,
  
  /**
   * Creates a default set of parameters
   *
   */
  Constructor Function BufferParameters(SELF IN OUT NOCOPY BufferParameters) 
                Return Self As Result,

  /**
   * Creates a set of parameters with the
   * given quadrantSegments value.
   * 
   * @param quadrantSegments the number of quadrant segments to use
   */
  Constructor Function BufferParameters(SELF IN OUT NOCOPY BufferParameters,
	                                    quadrantSegments in integer) 
                Return Self As Result,

  /**
   * Creates a set of parameters with the
   * given quadrantSegments and endCapStyle values.
   * 
   * @param quadrantSegments the number of quadrant segments to use
   * @param endCapStyle the end cap style to use
   */
  Constructor Function BufferParameters(SELF IN OUT NOCOPY BufferParameters,
	                                    quadrantSegments in integer,
                                        endCapStyle      in integer) 
                Return self as Result,

  /**
   * Creates a set of parameters with the
   * given parameter values.
   * 
   * @param quadrantSegments the number of quadrant segments to use
   * @param endCapStyle the end cap style to use
   * @param joinStyle the join style to use
   * @param mitreLimit the mitre limit to use
   */
  Constructor Function BufferParameters(SELF IN OUT NOCOPY BufferParameters,
                                        quadrantSegments in integer,
                                        endCapStyle      in integer,
                                        joinStyle        in integer,
                                        mitreLimit       in number) 
                Return self as Result,

  /**
   * Gets the number of quadrant segments which will be used
   * 
   * @return the number of quadrant segments
   */
  Member Function getQuadrantSegments
           Return integer deterministic,

  /**
   * Sets the number of line segments used to approximate an angle fillet.
   * <ul>
   * <li>If <tt>quadSegs</tt> &gt;= 1, joins are round, and <tt>quadSegs</tt> indicates the number of
   * segments to use to approximate a quarter-circle.
   * <li>If <tt>quadSegs</tt> = 0, joins are bevelled (flat)
   * <li>If <tt>quadSegs</tt> &lt; 0, joins are mitred, and the value of qs
   * indicates the mitre ration limit as
   * <pre>
   * mitreLimit = |<tt>quadSegs</tt>|
   * </pre>
   * </ul>
   * For round joins, <tt>quadSegs</tt> determines the maximum
   * error in the approximation to the true buffer curve.
   * The default value of 8 gives less than 2% max error in the buffer distance.
   * For a max error of &lt; 1%, use QS = 12.
   * For a max error of &lt; 0.1%, use QS = 18.
   * The error is always less than the buffer distance 
   * (in other words, the computed buffer curve is always inside the true
   * curve).
   * 
   * @param quadSegs the number of segments in a fillet for a quadrant
   */
  Member Procedure setQuadrantSegments(SELF IN OUT NOCOPY BufferParameters,
                                       quadSegs in integer),

  /**
   * Computes the maximum distance error due to a given level
   * of approximation to a true arc.
   * 
   * @param quadSegs the number of segments used to approximate a quarter-circle
   * @return the error of approximation
   */
  Member Function bufferDistanceError(quadSegs in integer)
           Return number deterministic,

  /**
   * Gets the end cap style.
   * 
   * @return the end cap style
   */
  Member Function getEndCapStyle
           Return integer deterministic,

  /**
   * Specifies the end cap style of the generated buffer.
   * The styles supported are {@link #CAP_ROUND}, {@link #CAP_FLAT}, and {@link #CAP_SQUARE}.
   * The default is CAP_ROUND.
   *
   * @param endCapStyle the end cap style to specify
   */
  Member Procedure setEndCapStyle(SELF IN OUT NOCOPY BufferParameters,
                                  endCapStyle in integer),

  /**
   * Gets the join style
   * 
   * @return the join style code
   */
  Member Function getJoinStyle return integer deterministic,

  /**
   * Sets the join style for outside (reflex) corners between line segments.
   * Allowable values are {@link #JOIN_ROUND} (which is the default),
   * {@link #JOIN_MITRE} and {link JOIN_BEVEL}.
   * 
   * @param joinStyle the code for the join style
   */
  Member Procedure setJoinStyle(SELF IN OUT NOCOPY BufferParameters,
                                joinStyle in integer),

  /**
   * Gets the mitre ratio limit.
   * 
   * @return the limit value
   */
  Member Function getMitreLimit return number deterministic,

  /**
   * Sets the limit on the mitre ratio used for very sharp corners.
   * The mitre ratio is the ratio of the distance from the corner
   * to the end of the mitred offset corner.
   * When two line segments meet at a sharp angle, 
   * a miter join will extend far beyond the original geometry.
   * (and in the extreme case will be infinitely far.)
   * To prevent unreasonable geometry, the mitre limit 
   * allows controlling the maximum length of the join corner.
   * Corners with a ratio which exceed the limit will be beveled.
   *
   * @param mitreLimit the mitre ratio limit
   */
  Member Procedure setMitreLimit(SELF IN OUT NOCOPY BufferParameters,
                                 mitreLimit in number),

  /**
   * Sets whether the computed buffer should be single-sided.
   * A single-sided buffer is constructed on only one side of each input line.
   * <p>
   * The side used is determined by the sign of the buffer distance:
   * <ul>
   * <li>a positive distance indicates the left-hand side
   * <li>a negative distance indicates the right-hand side
   * </ul>
   * The single-sided buffer of point geometries is 
   * the same as the regular buffer.
   * <p>
   * The End Cap Style for single-sided buffers is 
   * always ignored, 
   * and forced to the equivalent of <tt>CAP_FLAT</tt>. 
   * 
   * @param isSingleSided true if a single-sided buffer should be constructed
   */
  Member Procedure setSingleSided(SELF IN OUT NOCOPY BufferParameters,
                                  isSingleSided in integer),

  /**
   * Tests whether the buffer is to be generated on a single side only.
   * 
   * @return true if the generated buffer is to be single-sided
   */
  Member Function isSingleSided return integer deterministic,

  /**
   * Gets the simplify factor.
   * 
   * @return the simplify factor
   */
  Member Function getSimplifyFactor Return Number deterministic, 

  /**
   * Sets the factor used to determine the simplify distance tolerance
   * for input simplification.
   * Simplifying can increase the performance of computing buffers.
   * Generally the simplify factor should be greater than 0.
   * Values between 0.01 and .1 produce relatively good accuracy for the generate buffer.
   * Larger values sacrifice accuracy in return for performance.
   * 
   * @param simplifyFactor a value greater than or equal to zero.
   */
  Member Procedure setSimplifyFactor(SELF IN OUT NOCOPY BufferParameters,
                                     simplifyFactor in number)

);
/
show errors

CREATE OR REPLACE EDITIONABLE TYPE BODY &&INSTALL_SCHEMA..BUFFERPARAMETERS 
AS 

  Constructor Function BufferParameters(SELF IN OUT NOCOPY BufferParameters) 
                Return Self As Result
  As
  Begin
    SELF.quadrantSegments := &&INSTALL_SCHEMA..BufferParameterConstants.DEFAULT_QUADRANT_SEGMENTS;
    SELF.endCapStyle      := &&INSTALL_SCHEMA..BufferParameterConstants.CAP_ROUND;
    SELF.joinStyle        := &&INSTALL_SCHEMA..BufferParameterConstants.JOIN_ROUND;
    SELF.mitreLimit       := &&INSTALL_SCHEMA..BufferParameterConstants.DEFAULT_MITRE_LIMIT;
    SELF.bIsSingleSided   := 0 /*false*/;
    SELF.simplifyFactor   := &&INSTALL_SCHEMA..BufferParameterConstants.DEFAULT_SIMPLIFY_FACTOR;
    RETURN;
  End BufferParameters;

  Constructor Function BufferParameters(SELF IN OUT NOCOPY BufferParameters,
	                                    quadrantSegments in integer) 
                Return Self As Result
  As 
  Begin
    SELF.setQuadrantSegments(quadrantSegments);
    RETURN;
  END BufferParameters;

  Constructor Function BufferParameters(SELF IN OUT NOCOPY BufferParameters,
	                                    quadrantSegments in integer,
                                        endCapStyle      in integer) 
                Return self as Result
  As
  Begin
    SELF.setQuadrantSegments(quadrantSegments);
    SELF.setEndCapStyle(endCapStyle);
    RETURN;
  End BufferParameters;

  /**
   * Creates a set of parameters with the
   * given parameter values.
   * 
   * @param quadrantSegments the number of quadrant segments to use
   * @param endCapStyle the end cap style to use
   * @param joinStyle the join style to use
   * @param mitreLimit the mitre limit to use
   */
  Constructor Function BufferParameters(SELF IN OUT NOCOPY BufferParameters,
                                        quadrantSegments in integer,
                                        endCapStyle      in integer,
                                        joinStyle        in integer,
                                        mitreLimit       in number) 
                Return self as Result
  As
  Begin
    SELF.setQuadrantSegments(quadrantSegments);
    SELF.setEndCapStyle(endCapStyle);
    SELF.setJoinStyle(joinStyle);
    SELF.setMitreLimit(mitreLimit);
    RETURN;
  END BufferParameters;
  /**
   * Gets the number of quadrant segments which will be used
   * 
   * @return the number of quadrant segments
   */
  Member Function getQuadrantSegments
           Return integer 
  As
  Begin
    Return SELF.quadrantSegments;
  End getQuadrantSegments;

  /**
   * Sets the number of line segments used to approximate an angle fillet.
   * <ul>
   * <li>If <tt>quadSegs</tt> &gt;= 1, joins are round, and <tt>quadSegs</tt> indicates the number of
   * segments to use to approximate a quarter-circle.
   * <li>If <tt>quadSegs</tt> = 0, joins are bevelled (flat)
   * <li>If <tt>quadSegs</tt> &lt; 0, joins are mitred, and the value of qs
   * indicates the mitre ration limit as
   * <pre>
   * mitreLimit = |<tt>quadSegs</tt>|
   * </pre>
   * </ul>
   * For round joins, <tt>quadSegs</tt> determines the maximum
   * error in the approximation to the true buffer curve.
   * The default value of 8 gives less than 2% max error in the buffer distance.
   * For a max error of &lt; 1%, use QS = 12.
   * For a max error of &lt; 0.1%, use QS = 18.
   * The error is always less than the buffer distance 
   * (in other words, the computed buffer curve is always inside the true
   * curve).
   * 
   * @param quadSegs the number of segments in a fillet for a quadrant
   */
  Member Procedure setQuadrantSegments(SELF IN OUT NOCOPY BufferParameters,
                                       quadSegs in integer)
  As
  Begin
    SELF.quadrantSegments := quadSegs;

    /** 
     * Indicates how to construct fillets.
     * If qs >= 1, fillet is round, and qs indicates number of 
     * segments to use to approximate a quarter-circle.
     * If qs = 0, fillet is bevelled flat (i.e. no filleting is performed)
     * If qs < 0, fillet is mitred, and absolute value of qs
     * indicates maximum length of mitre according to
     * 
     * mitreLimit = |qs|
     */
    if (SELF.quadrantSegments = 0) Then
      SELF.joinStyle := &&INSTALL_SCHEMA..BufferParameterConstants.JOIN_BEVEL;
    End If;
    if (SELF.quadrantSegments < 0) then
      SELF.joinStyle  := &&INSTALL_SCHEMA..BufferParameterConstants.JOIN_MITRE;
      SELF.mitreLimit := ABS(SELF.quadrantSegments);
    end if;

    if (quadSegs <= 0) Then
      SELF.quadrantSegments := 1;
    End If;

    /**
     * If join style was set by the quadSegs value,
     * use the default for the actual quadrantSegments value.
     */
    if (joinStyle != &&INSTALL_SCHEMA..BufferParameterConstants.JOIN_ROUND) then
      SELF.quadrantSegments := &&INSTALL_SCHEMA..BufferParameterConstants.DEFAULT_QUADRANT_SEGMENTS;
    end If;
  End setQuadrantSegments;

  /**
   * Computes the maximum distance error due to a given level
   * of approximation to a true arc.
   * 
   * @param quadSegs the number of segments used to approximate a quarter-circle
   * @return the error of approximation
   */
  Member Function bufferDistanceError(quadSegs in integer)
           Return number 
  As
    alpha number;
  Begin
     alpha := &&INSTALL_SCHEMA..COGO.PI() / 2.0 / quadSegs;
    return 1.0 - COS(alpha / 2.0);
  End bufferDistanceError;

  /**
   * Gets the end cap style.
   * 
   * @return the end cap style
   */
  Member Function getEndCapStyle
           Return integer 
  As
  Begin
    return SELF.endCapStyle;
  End getEndCapStyle;

  /**
   * Specifies the end cap style of the generated buffer.
   * The styles supported are {@link #CAP_ROUND}, {@link #CAP_FLAT}, and {@link #CAP_SQUARE}.
   * The default is CAP_ROUND.
   *
   * @param endCapStyle the end cap style to specify
   */
  Member Procedure setEndCapStyle(SELF IN OUT NOCOPY BufferParameters,
                                  endCapStyle in integer)
  As
  Begin
    SELF.endCapStyle := endCapStyle;
  End setEndCapStyle;

  /**
   * Gets the join style
   * 
   * @return the join style code
   */
  Member Function getJoinStyle 
  return integer 
  As
  Begin
    return SELF.joinStyle;
  End getJoinStyle;

  /**
   * Sets the join style for outside (reflex) corners between line segments.
   * Allowable values are {@link #JOIN_ROUND} (which is the default),
   * {@link #JOIN_MITRE} and {link JOIN_BEVEL}.
   * 
   * @param joinStyle the code for the join style
   */
  Member Procedure setJoinStyle(SELF IN OUT NOCOPY BufferParameters,
                                joinStyle in integer)
  As
  Begin
    SELF.joinStyle := joinStyle;
  End setJoinStyle;

  /**
   * Gets the mitre ratio limit.
   * 
   * @return the limit value
   */
  Member Function getMitreLimit 
  return number 
  As
  Begin
    return SELF.mitreLimit;
  End getMitreLimit;

  /**
   * Sets the limit on the mitre ratio used for very sharp corners.
   * The mitre ratio is the ratio of the distance from the corner
   * to the end of the mitred offset corner.
   * When two line segments meet at a sharp angle, 
   * a miter join will extend far beyond the original geometry.
   * (and in the extreme case will be infinitely far.)
   * To prevent unreasonable geometry, the mitre limit 
   * allows controlling the maximum length of the join corner.
   * Corners with a ratio which exceed the limit will be beveled.
   *
   * @param mitreLimit the mitre ratio limit
   */
  Member Procedure setMitreLimit(SELF IN OUT NOCOPY BufferParameters,
                                 mitreLimit in number)
  As
  Begin
    SELF.mitreLimit := mitreLimit;
  End setMitreLimit;

  /**
   * Sets whether the computed buffer should be single-sided.
   * A single-sided buffer is constructed on only one side of each input line.
   * <p>
   * The side used is determined by the sign of the buffer distance:
   * <ul>
   * <li>a positive distance indicates the left-hand side
   * <li>a negative distance indicates the right-hand side
   * </ul>
   * The single-sided buffer of point geometries is 
   * the same as the regular buffer.
   * <p>
   * The End Cap Style for single-sided buffers is 
   * always ignored, 
   * and forced to the equivalent of <tt>CAP_FLAT</tt>. 
   * 
   * @param isSingleSided true if a single-sided buffer should be constructed
   */
  Member Procedure setSingleSided(SELF IN OUT NOCOPY BufferParameters,
                                  isSingleSided in integer)
  As
  Begin
    SELF.bIsSingleSided := isSingleSided;
  End setSingleSided;

  /**
   * Tests whether the buffer is to be generated on a single side only.
   * 
   * @return true if the generated buffer is to be single-sided
   */
  Member Function isSingleSided 
  return integer 
  As
  Begin
    return SELF.bIsSingleSided;
  End isSingleSided;

  /**
   * Gets the simplify factor.
   * 
   * @return the simplify factor
   */
  Member Function getSimplifyFactor 
  Return Number 
  As
  Begin
    return SELF.simplifyFactor;
  End getSimplifyFactor;

  /**
   * Sets the factor used to determine the simplify distance tolerance
   * for input simplification.
   * Simplifying can increase the performance of computing buffers.
   * Generally the simplify factor should be greater than 0.
   * Values between 0.01 and .1 produce relatively good accuracy for the generate buffer.
   * Larger values sacrifice accuracy in return for performance.
   * 
   * @param simplifyFactor a value greater than or equal to zero.
   */
  Member Procedure setSimplifyFactor(SELF IN OUT NOCOPY BufferParameters,
                                     simplifyFactor in number)
  As
  Begin
    SELF.simplifyFactor := case when simplifyFactor < 0.0 then 0 else simplifyFactor end;
  End setSimplifyFactor;

END;
/
SHOW ERRORS

