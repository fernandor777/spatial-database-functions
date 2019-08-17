DELIMITER $$

USE `gisdb`$$

DROP function IF EXISTS `ST_Morton`$$

Create Function `ST_Morton`
(
  p_col int,
  p_row int
)
Returns int
/****m* SORT/ST_Morton (1.0)
 *  NAME
 *    ST_Morton -- Function which creates a Morton (Space) Key from the supplied row and column reference.
 *  SYNOPSIS
 *    Function ST_Morton ( 
 *                p_col int,
 *                p_row int 
 *             )
 *     Returns int
 *  USAGE
 *    SELECT ST_Morton (10, 10) as mKey;
 *
 *     # mKey
 *     828
 *  DESCRIPTION
 *    Function that creates a Morton Key from a row/col (grid) reference. 
 *    The generated value can be used to order/sort geometry objects.
 *  INPUTS
 *    p_col      (int) - Grid Column Reference.
 *    p_row      (int) - Grid Row Reference.
 *  RESULT
 *    morton_key (int) - single integer morton key.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2017 - Original Coding for MySQL.
 *  COPYRIGHT
 *    (c) 2012-2017 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
  Declare v_col       int;
  Declare v_row       int;
  Declare v_key       int;
  Declare v_level     int;
  Declare v_left_bit  int;
  Declare v_right_bit int;
  Declare v_quadrant  int;
  SET v_col   = abs(p_col);
  SET v_row   = abs(p_row);
  SET v_key   = 0;
  SET v_level = 0;
  WHILE ( (v_row>0) OR (v_col>0) ) DO
     /* split off the row (left_bit) and column (right_bit) bits and
        then combine them to form a bit-pair representing the quadrant */
     SET v_left_bit  = v_row % 2;
     SET v_right_bit = v_col % 2;
     SET v_quadrant  = v_right_bit + (2*v_left_bit);
     /* row, column, and level are then modified before the loop continues */
     SET v_key       = v_key + (v_quadrant<<(2*v_level));
     If ( v_row = 1 And v_col = 1 ) Then
       Set v_row = 0; 
       Set v_col = 0;
     Else
       Set v_row   = v_row / 2;
       Set v_col   = v_col / 2;
       Set v_level = v_level + 1;
     End If;
   END WHILE;
   Return v_key;
End$$

DELIMITER ;

/* ************************ TESTING *****************************/

Select ST_Morton(10,10) as mKey;
-- # mKey
-- '828'

Select vRow,vCol, ST_Morton(vRow,vCol) as morton_key
  from (SELECT @rownum := @rownum + 1 AS vRow
          FROM information_schema.tables, 
               (SELECT @rownum := 0) r
	   ) rws,
       (select @rownum := @rownum + 1 AS vCol
		  from information_schema.tables cls, 
               (SELECT @rownum := 0) r
	   ) f;
