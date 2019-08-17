DEFINE defaultSchema='&1'
set serveroutput on size unlimited
declare
   TYPE t_types is table of varchar2(50);
   v_tabs       t_types := t_types('MBR', 'T_ArcSet', 'T_VectorSet', 'T_Vector2DSet', 'T_Coord2DSet', 'T_ElemInfoSet', 'T_GeometrySet', 'VarChar2_Table', 
                                   'T_Arc', 'T_Vertex', 'T_Vector2D', 'T_Vector', 'T_Coord2D', 'T_ElemInfo', 'T_Geometry', 'T_Grid', 'T_WindowSet', 
                                   'ST_POINT_AGGR_TYPE', 'ST_POINTAGGR', 'ST_PointSet', 'ST_POINT', 'ST_EXPLICITPOINT_TYPE', 
                                   'T_Error', 'T_VertexMark', 'T_TokenSet', 'T_Tokens', 'T_Token', 'T_Numbers','TBL_BEARING_DISTANCES','T_BEARING_DISTANCE');

begin
   for tok in v_tabs.FIRST..v_tabs.LAST LOOP
      begin
         dbms_output.put_line('Type ' || v_tabs(tok) || ' ....');
         EXECUTE IMMEDIATE 'DROP TYPE &&defaultSchema..' || UPPER(v_tabs(tok)) || case when DBMS_DB_VERSION.VERSION > 10 then ' force'  else '' end;
         dbms_output.put_line('___ successfully dropped');
         EXCEPTION
           WHEN OTHERS THEN
              dbms_output.put_line('____ Failed with ' || SQLERRM);
      end;
   end loop;
end;
/
show errors

DROP FUNCTION Tokenizer;

-- Potentially older types used in previous releases
--
set serveroutput on size unlimited
declare
   TYPE t_types is table of varchar2(50);
   v_tabs       t_types := t_types(
'GEOMETRYSETTYPE',
'ELEMINFOSETTYPE',
'VERTEX_SET_TYPE',
'VECTOR2DSETTYPE',
'COORD2DSETTYPE',
'WINDOWSETTYPE',
'VECTORSETTYPE',
'VECTOR2DTYPE',
'GEOMETRYTYPE',
'ELEMINFOTYPE',
'VERTEX_TYPE',
'COORD2DTYPE',
'VECTORTYPE',
'ARCSETTYPE',
'T_TOKENSET',
'MBRTYPE',
'ARCTYPE');
begin
   for tok in v_tabs.FIRST..v_tabs.LAST LOOP
      begin
         dbms_output.put_line('Type ' || v_tabs(tok) || ' ....');
         EXECUTE IMMEDIATE 'drop type &&defaultSchema..' || UPPER(v_tabs(tok)) || case when DBMS_DB_VERSION.VERSION > 10 then ' force'  else '' end;
         dbms_output.put_line('___ successfully dropped');
         EXCEPTION
           WHEN OTHERS THEN
              dbms_output.put_line('____ Failed with ' || SQLERRM);
      end;
   end loop;
end;
/
show errors

purge recyclebin;

EXIT;

