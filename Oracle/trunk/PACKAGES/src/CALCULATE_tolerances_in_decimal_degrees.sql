-- Define two coordinates where circular arc geometry resides that are 1cm apart
-- Note: Being 1cm apart in longtiude is different from being 1cm in latitude
--       or even where 1cm is on hypotenuse as 45 degrees
--

select cos(cogo.radians(45)) * 0.01 as longDiff,
       sin(cogo.radians(45)) * 0.01 as latDiff 
  from dual;
LONGDIFF                                   LATDIFF
------------------------------------------ --------------------------------------------
0.0070710678118654809688556830101184416685 0.007071067811865469519161204231973904191141

select round(SQRT( POWER(0.0070710678118654809688556830101184416685,2) + POWER(0.007071067811865469519161204231973904191141,2)),3) from dual;

select east1cm, ROUND(ABS(g.g.sdo_point.x - g.gE.sdo_point.x ),10) as longDiffE, ROUND(ABS(g.g.sdo_point.y - g.gE.sdo_point.y ),10) as latDiffE,
       north1cm,ROUND(ABS(g.g.sdo_point.x - g.gN.sdo_point.x ),10) as longDiffN, ROUND(ABS(g.g.sdo_point.y - g.gN.sdo_point.y ),10) as latDiffN,
       NE1cm,   ROUND(ABS(g.g.sdo_point.x - g.gNE.sdo_point.x),10) as longDiffNE,ROUND(ABS(g.g.sdo_point.y - g.gNE.sdo_point.y),10) as latDiffNE
  from (select Round(SDO_GEOM.SDO_Distance(point,pointE,0.005),4)  as east1cm,
               Round(SDO_GEOM.SDO_Distance(point,pointN,0.005),4)  as north1cm,
               Round(SDO_GEOM.SDO_Distance(point,pointNE,0.005),4) as NE1cm,
               sdo_cs.transform(point,8307)   as g,
               sdo_cs.transform(pointE,8307)  as gE,
               sdo_cs.transform(pointN,8307)  as gN,
               sdo_cs.transform(pointNE,8307) as gNE
          from (select sdo_geometry(2001,28355,sdo_point_type(516717.291,5237465.745,null),null,null) as point,
                       sdo_geometry(2001,28355,sdo_point_type(516717.281,5237465.745,null),null,null) as pointE,
                       sdo_geometry(2001,28355,sdo_point_type(516717.291,5237465.735,null),null,null) as pointN,
                       sdo_geometry(2001,28355,
                                    sdo_point_type(516717.291  + (cos(cogo.radians(45)) * 0.01),
                                                   5237465.745 + (sin(cogo.radians(45)) * 0.01),
                                                   null),null,null) as pointNE
                  from dual
              ) f
      ) g;

EAST1CM    LONGDIFFE     LATDIFFE NORTH1CM    LONGDIFFN     LATDIFFN NE1CM   LONGDIFFNE    LATDIFFNE
------- ------------ ------------ -------- ------------ ------------ ----- ------------ ------------
   0.01 0.0000001227 0.0000000002     0.01 0.0000000003 0.0000000901  0.01 0.0000000866 0.0000000638 

-- Check with generic coversion effectively at centre of coordinate system (ie equator)
--
select round(    geom.Convert_Distance(8307,0.01,'CM'), 1) as centimeters_per_degree,
       round(1 / geom.Convert_Distance(8307,0.01,'CM'),10) as degrees_per_centimetre
  from dual;
  
CENTIMETERS_PER_DEGREE DEGREES_PER_CENTIMETRE
---------------------- ----------------------
              111319.5           0.0000089832 

-- Chose the value you want for the tolerance and for the arc tolerance and convert as above.
-- eg if tolerance is 1cm then the tolerance in DD is either of the LONG or LAT DIFF values above.
-- Then if the tolerance is 1cm then you might want a tolerance that is 10 x that so take the tolerance in DD and multiply by 10.