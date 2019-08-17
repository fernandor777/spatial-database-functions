DEFINE defaultSchema='&1'
set serveroutput on size unlimited
declare
   TYPE t_tokenset is table of varchar2(50);
   v_tabs t_tokenset := t_tokenset('LINEAR');
begin
   for tok in v_tabs.FIRST..v_tabs.LAST LOOP
      begin
         dbms_output.put_line('Package ' || v_tabs(tok) || ' ....');
         EXECUTE IMMEDIATE 'DROP PACKAGE &&defaultSchema..' || UPPER(v_tabs(tok));
         dbms_output.put_line('___ successfully dropped');
         EXCEPTION
           WHEN OTHERS THEN
              dbms_output.put_line('____ Failed with ' || SQLERRM);
      end;
   end loop;
end;
/

COMMIT;

purge recyclebin;

exit;

