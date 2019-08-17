select TIN.ST_InterpolateZ(sdo_geometry(2001,null,sdo_POINT_type(0.1,0.5,null),null,null),
                           sdo_geometry(3001,null,sdo_POINT_type(0,0,0),null,null),
                           sdo_geometry(3001,null,sdo_POINT_type(2,0,1),null,null),
                           sdo_geometry(3001,null,sdo_POINT_type(1,1,2),null,null)) as Z
  from dual;

select TIN.ST_InterpolateZ(sdo_geometry(2005,null,null,sdo_elem_info_array(1,1,2),sdo_ordinate_array(0.1,0.5,1.7,0.1)),
                           sdo_geometry(3003,null,null,sdo_elem_info_array(1,1003,1),sdo_ordinate_array(0,0,0,2,0,1,1,1,2,0,0,0)))
       as z
  from dual;

select TIN.ST_InterpolateZ(sdo_geometry(2005,null,null,sdo_elem_info_array(1,1,2),sdo_ordinate_array(0.1,0.5,1.7,0.1)),
                           sdo_geometry(3003,null,null,sdo_elem_info_array(1,1003,1),sdo_ordinate_array(0,0,0,2,0,1,1,1,2,0,0,0)))
       as z
  from dual;

select TIN.ST_InterpolateZ(sdo_geometry(2001,null,sdo_POINT_type(1.7,0.1,null),null,null),
                           sdo_geometry(3003,null,null,sdo_elem_info_array(1,1003,1),sdo_ordinate_array(0,0,0,2,0,1,1,1,2,0,0,0)))
       as z
  from dual;

quit;

