--------------------------------------------------------
--  File created - Friday-August-09-2019   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Type T_Precision
--------------------------------------------------------

CREATE OR REPLACE EDITIONABLE TYPE SPDBA.T_PrecisionModel
AUTHID DEFINER
AS OBJECT (

  /****t* OBJECT TYPE/T_PrecisionModel
  *  NAME
  *    T_PrecisionModel -- Object type holding ordinate precision values
  *  DESCRIPTION
  *    JTS has a PrecisionModel class. With the use of NUMBER data type most of the JTS PrecisionModel types (eg FIXED, FLOATING_SINGLE etc)
  *    are not neded. What is needed is a single place one can record XY, Z and M ordinate precision (scale) values.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - July 2019 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2019 by TheSpatialDBAdvisor/Simon Greener
  ******/

  /****v* T_SEGMENT/ATTRIBUTES(T_SEGMENT)
  *  ATTRIBUTES
  *           XY -- Single scale/precision value for X and Y ordinates.
  *            Z -- Scale/precision value for the Z ordinate.
  *            W -- Scale/precision value for the W ordinate.
  *    tolerance -- Standard Oracle Spatial tolerance value eg 0.005.
  *  SOURCE
  */
  xy        integer,
  z         integer,
  w         integer,
  tolerance number
  /*******/

);

/
