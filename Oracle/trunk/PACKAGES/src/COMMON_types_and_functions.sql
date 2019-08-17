DEFINE defaultSchema='&1'

-- WindowSet
--
create or replace Type &&defaultSchema..T_WindowSet Is Table Of Number;
/
show errors
grant execute on &&defaultSchema..T_WindowSet to public with grant option;

-- *********************************************************************** 
-- Tokens 
--
-- 1. Tokens + Separators
--
-- We need a type to hold the returned tokens
--
Drop Type &&defaultSchema..T_Token  Force;
Drop Type &&defaultSchema..T_Tokens Force;

create type &&defaultSchema..T_Token as Object (
   id        integer,
   token     varchar2(30000),
   separator varchar2(30000)
);
/
show errors
grant execute on &&defaultSchema..T_Token to public with grant option;

create type &&defaultSchema..T_Tokens As Table Of &&defaultSchema..T_Token;
/
show errors

grant execute on &&defaultSchema..T_Tokens to public with grant option;

-- *********************************************************************** 

Create Type &&defaultSchema..T_Numbers As Table Of Number;
/
show errors
grant execute on &&defaultSchema..T_Numbers to public with grant option;

-- 2D Vertex and Vector types ...
--
CREATE OR REPLACE TYPE &&defaultSchema..T_Coord2D AS OBJECT (
   x number,
   y number );
/
show errors
grant execute on &&defaultSchema..T_Coord2D to public with grant option;

create or replace type &&defaultSchema..T_Coord2DSet
   as table of &&defaultSchema..T_Coord2D
/
show errors
grant execute on &&defaultSchema..T_Coord2DSet to public with grant option;


CREATE OR REPLACE TYPE &&defaultSchema..T_Vector2D AS OBJECT (
   startCoord &&defaultSchema..T_Coord2D,
   endCoord   &&defaultSchema..T_Coord2D );
/
show errors

grant execute on &&defaultSchema..T_Vector2D to public with grant option;

create or replace type &&defaultSchema..T_Vector2DSet
   as table of &&defaultSchema..T_Vector2D
/
show errors
grant execute on &&defaultSchema..T_Vector2DSet to public with grant option;

-- **********************************************************************************
-- Newer types as we migrate away from old
--
-- Element Info Types
--
CREATE OR REPLACE TYPE &&defaultSchema..T_ElemInfo AS OBJECT (
   offset           NUMBER,
   etype            NUMBER,
   interpretation   NUMBER
);
/
grant execute on &&defaultSchema..T_ElemInfo to public;

create or replace type &&defaultSchema..T_ElemInfoSet as table of &&defaultSchema..T_ElemInfo;
/
show errors
grant execute on &&defaultSchema..T_ElemInfoSet to public with grant option;

-- Geometry types....
--

CREATE OR REPLACE TYPE &&defaultSchema..T_Geometry AS OBJECT ( 
   geometry mdsys.sdo_geometry,
   order member function orderBy(p_compare_geom in T_Geometry)
   return number
);
/
show errors

CREATE TYPE BODY &&defaultSchema..T_Geometry 
AS
   Order Member Function orderBy(p_compare_geom in T_Geometry)
   Return number
   Is
   Begin
      /* Simple for time being.. replace with MortonKey+X */
      Return 1;
   End;
End;
/
show errors

grant execute on &&defaultSchema..T_Geometry to public with grant option;

create or replace type &&defaultSchema..T_GeometrySet as table of &&defaultSchema..T_Geometry;
/
show errors
grant execute on &&defaultSchema..T_GeometrySet to public with grant option;

----------------------------------------------------------------

create or replace TYPE &&defaultSchema..T_Vertex IS OBJECT (

  x  number,
  y  number,
  z  number,
  w  number,
  id number,

  Member Function getDims
         Return pls_integer Deterministic,

  Member Function AsSdoGeometry(p_SRID in number)
         Return mdsys.sdo_geometry Deterministic,

  Member Function AsText
         Return VarChar2 Deterministic

);
/
SHOW ERRORS

CREATE OR REPLACE TYPE BODY &&defaultSchema..T_Vertex AS

  Member Function getDims
           Return pls_integer Deterministic 
  AS
  Begin
       return case when self.x is null then 0 else 2 end +
              case when self.z is null then 0 else 1 end +
              case when self.w is null then 0 else 1 end;
  End getDims;

  Member Function AsSdoGeometry(p_SRID in number)
           Return mdsys.sdo_geometry Deterministic 
  AS
  Begin
     If ( self.getDims() = 0 ) Then
        Return null;
     ElsIf ( self.getDims() <= 2 ) Then
        Return mdsys.sdo_geometry(self.getDims()*1000+1,p_SRID,mdsys.sdo_point_type(self.x,self.y,NULL),null,null);
     ElsIf ( self.getDims() = 3 And self.z is not null ) Then
        Return mdsys.sdo_geometry(self.getDims()*1000+1,p_SRID,mdsys.sdo_point_type(self.x,self.y,self.z),null,null);
     ElsIf ( self.getDims() = 3 And self.w is not null ) Then
        Return mdsys.sdo_geometry(self.getDims()*1000+301,p_SRID,mdsys.sdo_point_type(self.x,self.y,self.w),null,null);
     ElsIf ( self.getDims() = 4 ) Then
        Return mdsys.sdo_geometry(self.getDims()*1000+1,p_SRID,NULL,mdsys.sdo_elem_info_array(1,1,1),mdsys.sdo_ordinate_array(self.x,self.y,self.z,self.w));
     End If;
  End AsSdoGeometry;

  Member Function AsText
           Return VarChar2 Deterministic AS
  Begin
    Return 'Vertex(' || self.x || ',' 
                     || self.y || ',' 
                     || case when self.z is null then 'NULL' else to_char(self.z) end || ',' 
                     || case when self.w is null then 'NULL' else to_char(self.w) end || ')';
  End AsText;

END;
/
show errors

set serveroutput on size unlimited
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
   v_OK       boolean := true;
   v_obj_name varchar2(30) := 'T_VERTEX';
BEGIN
   FOR rec IN (select object_name || '.' || object_Type as package_name, status 
                 from user_objects
                where object_name = v_obj_name) LOOP
      IF ( rec.status = 'VALID' ) Then
         dbms_output.put_line('Type ' || USER || '.' || rec.package_name || ' is valid.');
      ELSE
         dbms_output.put_line('Type ' || USER || '.' || rec.package_name || ' is invalid.');
         v_ok := false;
      END IF;
   END LOOP;
   IF ( NOT v_OK ) THEN
      RAISE_APPLICATION_ERROR(-20000,v_obj_name || ' failed to install.');
   END IF;
END;
/
SHOW ERRORS

grant execute on &&defaultSchema..T_Vertex to public;

-- Test
--
select a.t.asText(), a.t.getDims(), a.t.AsSdoGeometry(28355) 
  from (select t_vertex(1,2,null,null,1) as t from dual
        union all
        select t_vertex(1,2,3,null,1) as t from dual
        union all
        select t_vertex(1,2,3,4,1) as t from dual
        union all
        select t_vertex(1,2,null,4,1) as t from dual) a;

-- ***************************************************************
-- Arc Types 
--
CREATE OR REPLACE TYPE &&defaultSchema..T_Arc AS OBJECT (
   StartCoord   &&defaultSchema..T_Vertex,
   MidCoord     &&defaultSchema..T_Vertex,
   EndCoord     &&defaultSchema..T_Vertex );
/
show errors
grant execute on &&defaultSchema..T_Arc to public with grant option;

create or replace type &&defaultSchema..T_ArcSet
   as table of &&defaultSchema..T_Arc
/
show errors
grant execute on &&defaultSchema..T_ArcSet to public with grant option;

---------------------------------------------------------------------

create or replace
TYPE T_Vector IS OBJECT (
    Id             Integer,
    element_id     integer,
    subelement_id  integer,
    startCoord     &&defaultSchema..T_Vertex,
    endCoord       &&defaultSchema..T_Vertex,
    
    Constructor Function T_Vector( p_startCoord In &&defaultSchema..t_vertex,
                                   p_endCoord   In &&defaultSchema..t_vertex,
                                   p_id         in pls_integer)
                Return Self As Result,

    Constructor Function T_Vector( p_id         in pls_integer,
                                   p_startCoord In &&defaultSchema..t_vertex,
                                   p_endCoord   In &&defaultSchema..t_vertex)
                Return Self As Result,

    Constructor Function T_Vector( p_id            in pls_integer,
                                   p_element_id    in pls_integer,
                                   p_subelement_id in pls_integer,
                                   p_startCoord    In &&defaultSchema..t_vertex,
                                   p_endCoord      In &&defaultSchema..t_vertex)
                Return Self As Result,

    Member Function getDims
           Return pls_integer Deterministic,

    Member Function AsSdoGeometry(p_SRID in number)
           Return mdsys.sdo_geometry Deterministic,

    Member Function AsText
           Return VarChar2 Deterministic           
);
/
show errors

create or replace
TYPE BODY         T_VECTOR AS

  Constructor Function T_Vector( p_startCoord In &&defaultSchema..t_vertex,
                                 p_endCoord   In &&defaultSchema..t_vertex,
                                 p_id         in pls_integer)
                Return Self As Result AS
  BEGIN
    self.startCoord := p_startCoord;
    self.endCoord   := p_endCoord;
    self.id         := p_id;
    RETURN;
  END T_Vector;

  Constructor Function T_Vector( p_id         in pls_integer,
                                 p_startCoord In &&defaultSchema..t_vertex,
                                 p_endCoord   In &&defaultSchema..t_vertex)
                Return Self As Result AS
  BEGIN
    self.startCoord := p_startCoord;
    self.endCoord   := p_endCoord;
    self.id         := p_id;
    RETURN;
  END T_Vector;

    Constructor Function T_Vector( p_id            in pls_integer,
                                   p_element_id    in pls_integer,
                                   p_subelement_id in pls_integer,
                                   p_startCoord    In &&defaultSchema..t_vertex,
                                   p_endCoord      In &&defaultSchema..t_vertex)
                Return Self As Result AS
  BEGIN
    self.id            := p_id;
    self.element_id    := p_element_id;
    self.subelement_id := p_subelement_id;
    self.startCoord    := p_startCoord;
    self.endCoord      := p_endCoord;
    RETURN;
  END T_Vector;
                
  Member Function getDims
           Return pls_integer Deterministic 
  AS
  Begin
	If ( self.startCoord is null or self.endCoord is null ) Then
        return 0;
     Else
       return case when self.startCoord.x is null then 0 else 2 end +
              case when self.startCoord.z is null then 0 else 1 end +
              case when self.startCoord.w is null then 0 else 1 end;
     End If;
  End getDims;

  Member Function AsSdoGeometry(p_SRID IN number)
           Return mdsys.sdo_geometry Deterministic 
  AS
  Begin
     If ( self.getDims() = 0 ) Then
        Return null;
     ElsIf ( self.getDims() <= 2 ) Then
	Return mdsys.sdo_geometry(self.getDims()*1000+2,p_SRID,NULL,mdsys.sdo_elem_info_array(1,2,1),
                                  mdsys.sdo_ordinate_array(self.startCoord.x,self.startCoord.y,self.endCoord.x,self.endCoord.y));
     ElsIf ( self.getDims() = 3 And self.startCoord.z is not null ) Then
	Return mdsys.sdo_geometry(self.getDims()*1000+2,p_SRID,NULL,mdsys.sdo_elem_info_array(1,2,1),
                                 mdsys.sdo_ordinate_array(self.startCoord.x,self.startCoord.y,self.endCoord.x,self.endCoord.y));
     ElsIf ( self.getDims() = 3 And self.startCoord.w is not null ) Then
	Return mdsys.sdo_geometry(self.getDims()*1000+302,p_SRID,NULL,mdsys.sdo_elem_info_array(1,2,1),
                                  mdsys.sdo_ordinate_array(self.startCoord.x,self.startCoord.y,self.startCoord.w,
                                                           self.endCoord.x,  self.endCoord.y,  self.endCoord.w));
     ElsIf ( self.getDims() = 4 ) Then
	Return mdsys.sdo_geometry(self.getDims()*1000+402,p_SRID,NULL,mdsys.sdo_elem_info_array(1,2,1),
                                  mdsys.sdo_ordinate_array(self.startCoord.x,self.startCoord.y,self.startCoord.z,self.startCoord.w,
                                                           self.endCoord.x,  self.endCoord.y,  self.endCoord.z,  self.endCoord.w));
     End If;
  End AsSdoGeometry;

  Member Function AsText
           Return VarChar2 Deterministic AS
  BEGIN
    RETURN 'Vector(Start(' || self.startCoord.x || ',' 
                           || self.startCoord.y || ',' 
                           || case when self.startCoord.z is null then 'NULL' else TO_CHAR(self.startCoord.z) end || ',' 
                           || case when self.startCoord.w is null then 'NULL' else TO_CHAR(self.startCoord.w) end || '),End(' 
                           || self.endCoord.x || ',' 
                           || self.endCoord.y || ',' 
                           || case when self.endCoord.z is null then 'NULL' else TO_CHAR(self.endCoord.z) end || ',' 
                           || case when self.endCoord.w is null then 'NULL' else TO_CHAR(self.endCoord.w) end || '))';
  END AsText;

END;
/
show errors

set serveroutput on size unlimited
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
   v_OK       boolean := true;
   v_obj_name varchar2(30) := 'T_VECTOR';
BEGIN
   FOR rec IN (select object_name || '.' || object_Type as package_name, status 
                 from user_objects
                where object_name = v_obj_name) LOOP
      IF ( rec.status = 'VALID' ) Then
         dbms_output.put_line('Type ' || USER || '.' || rec.package_name || ' is valid.');
      ELSE
         dbms_output.put_line('Type ' || USER || '.' || rec.package_name || ' is invalid.');
         v_ok := false;
      END IF;
   END LOOP;
   IF ( NOT v_OK ) THEN
      RAISE_APPLICATION_ERROR(-20000,v_obj_name || ' failed to install.');
   END IF;
END;
/
SHOW ERRORS

grant execute on &&defaultSchema..T_Vector to public;

select a.v.asText(), a.v.getDims(), a.v.AsSdoGeometry(28355) 
  from (select t_vector(t_vertex(1,2,null,null,1),
                        t_vertex(10,20,null,null,2),
                        1) as v from dual
        union all
        select t_vector(t_vertex(1,2,3,null,1),
                        t_vertex(10,20,30,null,2),
                        1) as v from dual
        union all
        select t_vector(t_vertex(1,2,3,4,1),
                        t_vertex(10,20,30,40,2),
                        1) as v from dual
        union all
        select t_vector(t_vertex(1,2,null,4,1),
                        t_vertex(10,20,null,40,2),
                        1) as v from dual) a;

create or replace type &&defaultSchema..T_VectorSet
   as table of &&defaultSchema..T_Vector
/
show errors
grant execute on &&defaultSchema..T_VectorSet to public with grant option;

-- ***************************************************************
-- COGO Bearing and Distance Objects...
create type t_bearing_distance as object (
  sDegMinSec varchar2(4000),
  nBearing   number,
  distance   number,
  Z          number
);
/
show errors

create type tbl_bearing_distances as table of t_bearing_distance;
/
show errors
-- ***************************************************************

create or replace
Function Tokenizer(p_string     In VarChar2,
                   p_separators In VarChar2 DEFAULT ' ') 
  Return &&defaultSchema..T_Tokens Pipelined
As
/*********************************************************************************
* @function    : Tokenizer
* @precis      : Splits any string into its tokens.
* @description : Supplied a string and a list of separators this function
*                returns resultant tokens as a pipelined collection.
* @example     : SELECT t.column_value
*                  FROM TABLE(tokenizer('The rain in spain, stays mainly on the plain.!',' ,.!') ) t;
* @param       : p_string. The string to be Tokenized.
* @param       : p_separators. The characters that are used to split the string.
* @requires    : t_Tokens type to be declared.
* @history     : Pawel Barut, http://pbarut.blogspot.com/2007/03/yet-another-tokenizer-in-oracle.html
* @history     : Simon Greener - July 2006 - Original coding (extended SQL sourced from a blog on the internet)
* @history     : Simon Greener - Apr  2012 - Extended to return tokens and separators
**/
  v_tokens &&defaultSchema..T_Tokens;
Begin
  if ( p_string is null 
       or
       p_separators is null ) then
     return;
  end if;
  With myCTE As (
     Select c.beg, c.sep, Row_Number() Over(Order By c.beg Asc) rid
       From (Select b.beg, c.sep
               From (Select Level beg
                       From dual
                      Connect By Level <= length(p_string)
                    ) b,
                    (Select SubStr(p_separators,level,1) as sep
                      From dual
                      Connect By Level <= length(p_separators)
                    ) c
              Where instr(c.sep,substr(p_string,b.beg,1)) >0
             Union All Select 0, cast(null as varchar2(10)) From dual
           ) c
  )
  Select T_Token(Row_Number() Over (Order By a.rid ASC), 
                 Case When Length(a.token) = 0 Then NULL Else a.token End, 
                 a.sep) as token
    Bulk Collect Into v_tokens
    From (Select d.rid,
                 SubStr(p_string, 
                        (d.beg + 1), 
                        NVL((Lead(d.beg,1) Over (Order By d.rid Asc) - d.beg - 1),length(p_string)) ) as token,
                 Lead(d.sep,1) Over (Order By d.rid asc) as sep
            From MyCTE d 
         ) a
   Where Length(a.token) <> 0 or Length(a.sep) <> 0;
  FOR v_i IN v_tokens.first..v_tokens.last loop  
     PIPE ROW(v_tokens(v_i));
  END LOOP;
  RETURN;
End Tokenizer;
/
show errors

grant execute on &&defaultSchema..Tokenizer to public;

quit;
