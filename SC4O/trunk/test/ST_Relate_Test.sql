Select SC4O.ST_Relate(
         sdo_geometry('POLYGON ((100.0 0.0, 400.0 0.0, 400.0 480.0, 160.0 480.0, 160.0 400.0, 240.0 400.0,240.0 300.0, 100.0 300.0, 100.0 0.0))',NULL),
         'DETERMINE',
         sdo_geometry('POLYGON ((-175.0 0.0, 100.0 0.0, 0.0 75.0, 100.0 75.0, 100.0 200.0, 200.0 325.0, 200.0 525.0, -175.0 525.0, -175.0 0.0))',NULL),
         2
       ) as relations
  from dual;

Select SC4O.ST_Relate(
         sdo_geometry('LINESTRING (100.0 0.0, 400.0 0.0)',NULL),
         'DETERMINE',
         sdo_geometry('LINESTRING (90.0 0.0, 100.0 0.0)',NULL),
         2
       ) as relations
  from dual;

Select SC4O.ST_Relate(
         sdo_geometry('POLYGON ((100.0 0.0, 400.0 0.0, 400.0 480.0, 160.0 480.0, 160.0 400.0, 240.0 400.0,240.0 300.0, 100.0 300.0, 100.0 0.0))',NULL),
         'DETERMINE',
         sdo_geometry('POINT (250 150)',NULL),
         2
       ) as relations
  from dual;

Select t.intValue as precision,
       SC4O.ST_Relate(
         sdo_geometry('POINT (250.001 150.0)'    ,NULL),
         'EQUAL',
         sdo_geometry('POINT (250.0   150.002)',NULL),
         t.intvalue
       ) as relations
  from table(SPDBA.tools.GENERATE_SERIES(0,3,1)) t

 PRECISION RELATIONS
---------- ---------
         0 EQUAL
         1 EQUAL
         2 EQUAL
         3 FALSE

Select SC4O.ST_Relate(
         sdo_geometry('POINT (250.001 150.0)'    ,NULL),
         '0FFFFFFF2',
         sdo_geometry('POINT (250.0   150.002)',NULL),
         t.intvalue
       ) as relations
  from dual;
  
RELATIONS
---------
TRUE

  
