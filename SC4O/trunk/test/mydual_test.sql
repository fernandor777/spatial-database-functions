declare
  type mycur_t  is ref cursor;
  mycur  mycur_t;
  result varchar2(4000);
begin
  open mycur for 'SELECT * FROM DUAL';
  result := javageom.mydual( mycur );
  dbms_output.put_line( result );
end;
/

