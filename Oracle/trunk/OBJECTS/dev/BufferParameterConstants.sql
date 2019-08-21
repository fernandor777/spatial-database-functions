DEFINE INSTALL_SCHEMA='&1'

SET VERIFY OFF;

CREATE OR REPLACE EDITIONABLE PACKAGE &&INSTALL_SCHEMA..BUFFERPARAMETERCONSTANTS 
AUTHID CURRENT_USER
As
  /**
    * Specifies a round line buffer end cap style.
   */
  CAP_ROUND Constant pls_integer := 1;
  /**
   * Specifies a flat line buffer end cap style.
   */
  CAP_FLAT Constant pls_integer := 2;
  /**
   * Specifies a square line buffer end cap style.
   */
  CAP_SQUARE Constant pls_integer := 3;

  /**
   * Specifies a round join style.
   */
  JOIN_ROUND Constant pls_integer := 1;
  /**
   * Specifies a mitre join style.
   */
  JOIN_MITRE Constant pls_integer := 2;
  /**
   * Specifies a bevel join style.
   */
  JOIN_BEVEL Constant pls_integer := 3;

  /**
   * The default number of facets into which to divide a fillet of 90 degrees.
   * A value of 8 gives less than 2% max error in the buffer distance.
   * For a max error of &lt; 1%, use QS = 12.
   * For a max error of &lt; 0.1%, use QS = 18.
   */
  DEFAULT_QUADRANT_SEGMENTS Constant pls_integer := 8;

  /**
   * The default mitre limit
   * Allows fairly pointy mitres.
   */
  DEFAULT_MITRE_LIMIT Constant Number := 5.0;

  /**
   * The default simplify factor
   * Provides an accuracy of about 1%, which matches the accuracy of the default Quadrant Segments parameter.
   */
  DEFAULT_SIMPLIFY_FACTOR Constant Number := 0.01;
end;
/
SHOW ERRORS

