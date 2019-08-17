create table quad_p (
  quad_id    integer,
  quad_level integer,
  quad_pt    mdsys.st_point );

insert into quad_p ( quad_id, quad_level, quad_pt )
select quad_id,
       quad_level,
       mdsys.st_point( ( xlo + xhi ) / 2, ( ylo + yhi ) / 2 )
  from quad;

create table quad_a (
  quad_id    integer,
  quad_level integer,
  quad_area  mdsys.st_polygon );

insert into quad_a ( quad_id, quad_level, quad_area )
select quad_id,
       quad_level,
       mdsys.st_polygon.ST_BDPolyFromText( q.shape.get_wkt() )
  from quad q;

select p.quad_id, a.quad_area.st_contains(p.quad_pt) 
  from quad_a a, 
       quad_p p
 where p.quad_id = a.quad_id; 

select p.quad_id, count(*)
  from quad_a a, 
       quad_p p
 where a.quad_area.st_contains(p.quad_pt) = 1
 group by p.quad_id; 

