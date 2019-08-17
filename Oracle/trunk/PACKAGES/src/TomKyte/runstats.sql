Prompt Execute the following grants as SYS
grant select on v_$latch    to public;
grant select on v_$mystat   to public;
grant select on v_$statNAME to public;

Prompt Execute the following in the schema granted 
create or replace view stats
    as SELECT 'STAT...' || a.name name, 
              b.value
         FROM v$statname a,
              v$mystat b
        WHERE a.statistic# = b.statistic#
       union all
       SELECT 'LATCH.' || name,
              gets
         FROM v$latch;

create global temporary table run_stats (
  runid  varchar2(15),
  name   varchar2(80),
  value  int 
)
on commit preserve rows;

create or replace package runstats_pkg
as
  Procedure rs_start;
  Procedure rs_middle;
  Procedure rs_stop( p_difference_threshold in number default 0 );
end;
/
show errors
create or replace package body runstats_pkg
as
  g_start number;
  g_run1  number;
  g_run2  number;

  Procedure rs_start
  Is
  Begin
    DELETE FROM run_stats;
    INSERT INTO run_stats
    SELECT 'before', stats.* FROM stats;
    g_start := dbms_utility.get_time;
  End rs_start;

  Procedure rs_middle
  Is
  Begin
    g_run1 := ( dbms_utility.get_time - g_start );
    INSERT INTO run_stats
    SELECT 'after 1', stats.* FROM stats;
    g_start := dbms_utility.get_time;
  End rs_middle;

  Procedure rs_stop( p_difference_threshold in number default 0 )
  Is
    v_num_format varchar2(20) := '999,999,999';
  Begin
    g_run2 := ( dbms_utility.get_time - g_start );
    dbms_output.put_line('Run1 ran in ' || g_run1 || ' hsecs' );
    dbms_output.put_line('Run2 ran in ' || g_run2 || ' hsecs' );
    dbms_output.put_line('Run 1 ran in ' || ROUND(g_run1/g_run2*100,2) || ' % of the time' );
    dbms_output.put_line(CHR(9));
    insert into run_stats
    SELECT 'after 2', stats.* FROM stats;
    dbms_output.put_line( RPAD( 'Name', 30 ) || 
                          LPAD( 'Run1', length(v_num_format)+1 ) ||
                          LPAD( 'Run2', length(v_num_format)+1 ) || 
                          LPAD( 'Diff', length(v_num_format)+1 ) );
    <<stats_loop>>
    FOR x IN (SELECT RPAD( a.name, 30 ) ||
                     TO_CHAR(     b.value - a.value,v_num_format ) ||
                     TO_CHAR(     c.value - b.value,v_num_format ) ||
                     TO_CHAR( ( ( c.value - b.value ) - 
                                ( b.value - a.value ) ),
			      v_num_format ) data
                FROM run_stats a, 
                     run_stats b, 
                     run_stats c
               WHERE a.name = b.name
                  AND b.name = c.name
                  AND a.runid = 'before'
                  AND b.runid = 'after 1'
                  AND c.runid = 'after 2'
                  AND (c.value-a.value) > 0
                  AND ABS( ( c.value - b.value )- 
                           ( b.value - a.value ) ) > p_difference_threshold
             order by ABS( (c.value-b.value)-(b.value-a.value) )
           ) 
    LOOP
      dbms_output.put_line( x.data );
    END LOOP stats_loop;
    dbms_output.put_line(CHR(9));
    dbms_output.put_line( 'Run1 latches total versus runs -- difference AND pct');
    dbms_output.put_line( LPAD( 'Run1', length(v_num_format)+1 ) || 
                          LPAD( 'Run2', length(v_num_format)+1 ) ||
                          LPAD( 'Diff', length(v_num_format)+1 ) || 
                          LPAD( 'Pct' , length(v_num_format)+2 ) );
    <<latch_loop>>
    FOR x IN (SELECT TO_CHAR( run1, v_num_format ) ||
                     TO_CHAR( run2, v_num_format ) ||
                     TO_CHAR( diff, v_num_format ) ||
                     TO_CHAR( ROUND( run1/run2*100,2),
			             v_num_format  ) || '%' data
                FROM ( SELECT SUM(   b.value - a.value ) run1,
                              SUM(   c.value - b.value ) run2,
                              SUM( ( c.value - b.value ) -
                                   ( b.value - a.value ) ) diff
                         FROM run_stats a, run_stats b, run_stats c
                        WHERE a.name = b.name
                          AND b.name = c.name
                          AND a.runid = 'before'
                          AND b.runid = 'after 1'
                          AND c.runid = 'after 2'
                          AND a.name LIKE 'LATCH%'
                    )
             ) 
   LOOP
      dbms_output.put_line( x.data );
   END LOOP latch_loop;
  End rs_stop;

end;
/
show errors
