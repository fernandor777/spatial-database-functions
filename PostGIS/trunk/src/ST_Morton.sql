DROP FUNCTION IF EXISTS ST_Morton (int4, int4)

CREATE FUNCTION ST_Morton (p_col int4, p_row int4)
 RETURNS int4 
AS
$$
/*  this procedure calculates the Morton number of a cell
    at the given row and col[umn]  
    Written:  D.M. Mark, Jan 1984;
    Converted to Vax/VMS: July 1985
    Converted to PostgreSQL, Simon Greener, 2010
*/
DECLARE
   v_row          int4 := 0;
   v_col          int4 := 0;
   v_key          int4;
   v_level        int4;
   v_left_bit     int4;
   v_right_bit    int4;
   v_quadrant     int4;
BEGIN
   v_row   := p_row;
   v_col   := p_col;
   v_key   := 0;
   v_level := 0;
   WHILE ((v_row>0) OR (v_col>0)) LOOP
     /* Split off the row (left_bit) and column (right_bit) bits and
     then combine them to form a bit-pair representing the quadrant */
     v_left_bit  := v_row % 2;
     v_right_bit := v_col % 2;
     v_quadrant  := v_right_bit + 2*v_left_bit;
     v_key       := v_key + ( v_quadrant << (2*v_level) );
     /* row, column, and level are then modified before the loop continues */ 
     v_row := v_row / 2;
     v_col := v_col / 2;
     v_level := v_level + 1;

   END LOOP;
   RETURN (v_key);
END;
$$
  LANGUAGE 'plpgsql' IMMUTABLE;

select * 
  from (select a.gcol, 
               b.grow, 
               ST_Morton( a.gcol, b.grow ) as MortonKey,
               ST_MakeBox2D(ST_MakePoint(a.gcol, b.grow)::geometry,ST_MakePoint(a.gcol+100, b.grow+100)::geometry)::geometry as geometry
          from (select 0 + g as gcol from generate_series(0,7,1) as g) as a,
               (select 0 + g as grow from generate_series(0,7,1) as g) as b
        ) as foo 
 order by mortonkey, gcol;
  
