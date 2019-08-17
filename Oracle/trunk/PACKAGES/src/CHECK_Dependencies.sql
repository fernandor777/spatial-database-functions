DEFINE defaultSchema='&1'
SELECT LEVEL,
       d.name,
       d.referenced_owner,
       d.referenced_name||'.'||d.referenced_type
  FROM all_dependencies  d
 WHERE referenced_name != 'STANDARD'
CONNECT BY
       PRIOR referenced_owner = owner
   AND PRIOR referenced_type = type
   AND PRIOR referenced_name = name
 START WITH
       owner = '&&defaultSchema.'
   AND type = 'PACKAGE BODY'
   AND name = 'GF'
order by level
/
select owner,name,type,referenced_name
from dba_dependencies
where referenced_name in ('ST_EXPLICITPOINT_TYPE','VECTOR4DTYPE');

