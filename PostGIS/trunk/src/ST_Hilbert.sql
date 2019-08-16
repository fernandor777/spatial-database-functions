DROP FUNCTION IF EXISTS spdba.ST_Hilbert (n int, x int, y int) ;

CREATE FUNCTION spdba.ST_Hilbert (n int, x int, y int) 
Returns int 
AS
$BODY$
  -- convert (x,y) to d
DECLARE
  rx int;
  ry int;
  s  int;
  t  int;
  d  int;
BEGIN
  rx := 0;
  ry := 0;
  t  := 0;
  d  := 0;
  s  := n/2;
  <<Cells>>
  while (s>0) loop
    rx := (x & s) >> 0;
    ry := (y & s) >> 0;
    d  := d + s * s * ((3 * rx) # ry);
    -- rot(s, &x, &y, rx, ry); => void rot(int n, int *x, int *y, int rx, int ry)
    if (ry = 0) Then
      if (rx = 1) Then
        x := s-1 - x;
        y := s-1 - y;
      End If;
      t := x;
      x := y;
      y := t;
    End If;
    s := s/2;
  END LOOP Cells;
  return d;
END;
$BODY$
  LANGUAGE plpgsql IMMUTABLE;

DROP FUNCTION IF EXISTS spdba.ST_Hilbert2Point (int,int) ;

CREATE FUNCTION spdba.ST_Hilbert2Point (n int, d int)
Returns geometry
AS
$$
Declare
  rx int;
  ry int;
  s  int;
  t  int;
  x  int;
  y  int;
Begin
  t  := d;
  rx := 0;
  ry := 0;
  x  := 0;
  y  := 0;
  s  := 1;
  while (s<n) loop
    rx := 1 & (t / 2);
    ry := 1 & (t >> rx);
    -- void rot(int n, int *x, int *y, int rx, int ry) {
    if (ry = 0) Then
      if (rx = 1) then
        x := n-1 - x;
        y := n-1 - y;
      End If;
      -- Swap x and y
      t := x;
      x := y;
      y := t;
    End If;
    x := x + s * rx;
    y := y + s * ry;
    t := t / 4;
    s := s * 2;
  end loop;
  return ST_MakePoint(x, y);
End;
$$
LANGUAGE plpgsql IMMUTABLE;

-- ******************************************************

with data as (
  select generate_series(0,15,1) as x,
         generate_series(0,15,1) as y
)
select hkey,
       ST_AsText(spdba.ST_Hilbert2Point(hKey,(SQRT(hKey))::int)) as nPoint,
       ST_AsText(f.point) as oPoint
  from (select ST_MakePoint(a.x,a.y) as point, 
               spdba.st_hilbert(32,a.x,a.y) as hKey
         from data as a
        ) as f
 order by 1;

