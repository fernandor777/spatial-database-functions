Prompt Conduct Tests
Prompt Construct a 2D Point
select ST_Point(1,2) from dual;
Prompt Construct a 3D Point
select ST_Point(1,2,3) from dual;
Prompt Construct a 4D Point
select ST_Point(1,2,3,4) from dual;
Prompt Construct a 2D Point from WKT
select ST_Point('POINT((1 2))') from dual;
Prompt Construct a 3D Point from WKT
select ST_Point('POINTZ((1 2 3))') from dual;
Prompt Construct a 4D Point from WKT
select ST_Point('POINTZM((1 2 3 4))') from dual;
Prompt Test AsText Method for 2D Point
select a.mypoint.ST_AsText() from ( select ST_Point(1,2) as mypoint from dual) a;
Prompt Test AsText Method for 3D Point
select a.mypoint.ST_AsText() from ( select ST_Point(1,2,3) as mypoint from dual) a;
Prompt Test AsText Method for 4D Point
select a.mypoint.ST_AsText() from ( select ST_Point(1,2,3,4) as mypoint from dual) a;
Prompt Test AsSVG Method for 2D Point
select a.mypoint.AsSVG() from ( select ST_Point(1,2) as mypoint from dual) a;
Prompt Test AsSVG Method for 3D Point
select a.mypoint.AsSVG() from ( select ST_Point(1,2,3) as mypoint from dual) a;
Prompt Test AsSVG Method for 4D Point
select a.mypoint.AsSVG() from ( select ST_Point(1,2,3,4) as mypoint from dual) a;
Prompt Test Distance Method for 2D Point
select a.mypoint.Distance(ST_Point(2,2)) from ( select ST_Point(1,1) as mypoint from dual) a;
Prompt Test Distance Method for 3D Point
select a.mypoint.Distance(ST_Point(2,2,0)) from ( select ST_Point(1,1,0) as mypoint from dual) a;
Prompt Test Distance Method for 4D Point
select a.mypoint.Distance(ST_Point(2,2,2,0)) from ( select ST_Point(1,1,1,0) as mypoint from dual) a;
set numformat 99999.999999999
Prompt Test ST_ExplicitPoint function
select a.mypoint.ST_ExplicitPoint() from ( select ST_Point(1,2,3,4) as mypoint from dual) a;
quit;
