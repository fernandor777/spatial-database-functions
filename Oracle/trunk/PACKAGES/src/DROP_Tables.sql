DEFINE defaultSchema='&1'

set serveroutput on size unlimited

Prompt Drop Tables....
declare
   TYPE t_tokenset is table of varchar2(50);
   v_tabs t_tokenset := t_tokenset('COLA_MARKETS','ORACLE_TEST_GEOMETRIES','LRS_ROUTES','COLUMN_ANALYSES','COLUMN_ANALYSIS_SUMMARIES','FEATURE_ERRORS','FEATURE_ERROR_SUMMARIES','GEODPOINT2D','GEODPOINT3D','GEODPOLY2D','LOCALLINE2D','LOCALPOINT2D','LOCALPOLY2D','MANAGED_COLUMNS','PROJ41014POLY2D','PROJ41914POLY2D','PROJCIRCLE2D','PROJCOMPOUND2D','PROJLINE2D','PROJLINE3D','PROJMULTILINE2D','PROJMULTIPOINT2D','PROJMULTIPOINT3D','PROJMULTIPOLY2D','PROJPOINT2D','PROJPOINT3D','PROJPOLY2D','PROJPOLY3D','SDO_GEOM_ERROR','TOOLSPOLY2D','ORIENTED_POINT');
begin
   for tok in v_tabs.FIRST..v_tabs.LAST LOOP
      begin
         dbms_output.put_line('Table ' || v_tabs(tok) || ' ....');
         EXECUTE IMMEDIATE 'drop table &&defaultSchema..' || v_tabs(tok) || ' cascade constraints';
         dbms_output.put_line('___ successfully dropped');
         DELETE FROM USER_SDO_GEOM_METADATA WHERE TABLE_NAME = v_tabs(tok);
         dbms_output.put_line('___ sdo_geom_metadata_removed');
         EXCEPTION
           WHEN OTHERS THEN
              dbms_output.put_line('____ Failed with ' || SQLERRM);
      end;
   end loop;
end;
/
SHOW ERRORS

COMMIT;

set serveroutput on size unlimited
declare
   TYPE t_tokenset is table of varchar2(50);
   v_tabs t_tokenset := t_tokenset('MANAGED_COLUMNS_ID','COLUMN_ANALYSES_ID','COLUMN_ANALYSIS_SUMMARIES_ID','FEATURE_ERRORS_ID','FEATURE_ERRORS_SUMMARIES_ID','ORACLE_TEST_GEOMETRIES_ID_SEQ');
begin
   for tok in v_tabs.FIRST..v_tabs.LAST LOOP
      begin
         dbms_output.put_line('Sequence ' || v_tabs(tok) || ' ....');
         EXECUTE IMMEDIATE 'drop sequence &&defaultSchema..' || v_tabs(tok);
         dbms_output.put_line('___ successfully dropped');
         EXCEPTION
           WHEN OTHERS THEN
              dbms_output.put_line('____ Failed with ' || SQLERRM);
      end;
   end loop;
end;
/
SHOW ERRORS

COMMIT;

purge recyclebin;
exit;
