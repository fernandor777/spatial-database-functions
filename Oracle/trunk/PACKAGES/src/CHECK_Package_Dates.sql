select object_name, last_ddl_time, timestamp 
  from user_objects 
 where object_type = 'PACKAGE BODY'
   and timestamp > '2009-08-27:10:18:40'
 order by timestamp desc;