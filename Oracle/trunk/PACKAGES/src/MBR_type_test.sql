set serveroutput on size unlimited
SET SHOWMODE OFF
SET TRIMOUT ON
SET VERIFY OFF

declare
  myExtent MBR := New MBR;
  anExtent MBR;
Begin
  dbms_output.put_line( '=============================' );
  If ( myExtent.isEmpty ) Then
    dbms_output.put_line( 'isEmpty: True');
  Else
    dbms_output.put_line( 'isEmpty: False');
  End If;
  myExtent := MBR(337900, 5429000, 338900, 5430000);
  dbms_output.put_line( myExtent.AsString );
  dbms_output.put_line( myExtent.AsCSV );
  dbms_output.put_line( myExtent.AsWKT );
  dbms_output.put_line( myExtent.AsSVG );
  dbms_output.put_line( myExtent.GetCentreAsSVG );
  dbms_output.put_line( myExtent.X );
  dbms_output.put_line( myExtent.Width );
  dbms_output.put_line( myExtent.Height );
  dbms_output.put_line( myExtent.Y );
  If ( myExtent.contains(337950, 5429050) ) Then
    dbms_output.put_line( 'Contains: True');
  Else
    dbms_output.put_line( 'Contains: False');
  End If;
  If ( myExtent.contains(337950, 5439050) ) Then
    dbms_output.put_line( 'Contains: True');
  Else
    dbms_output.put_line( 'Contains: False');
  End If;
  anExtent := New MBR(337950, 5429050, 338950, 5430500);
  dbms_output.put_line( 'Compare = ' || myExtent.Compare(anExtent));
End;
/
show errors

set serveroutput on size unlimited
declare
  v_mbr mbr := new MBR();
  v_geom sdo_geometry := sdo_geometry(2007,null,null,sdo_elem_info_array(1,1003,3,5,1003,3),sdo_ordinate_array(0,0,10,10,100,100,200,200));
begin
  v_mbr.SetSmallestPart(v_geom);
  dbms_output.put_line( v_mbr.AsString );
  v_mbr.SetLargestPart(v_geom);
  dbms_output.put_line( v_mbr.AsString );
end;
/
show errors

quit;
