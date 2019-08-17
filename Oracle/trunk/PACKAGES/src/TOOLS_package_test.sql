DEFINE defaultSchema='&1'
set serveroutput on size 1000000
set pagesize 5000 linesize 131

DROP   TABLE ToolsPoly2D PURGE;
CREATE TABLE ToolsPoly2D ( fid integer, 
	                   geom mdsys.sdo_geometry, 
                           centroid mdsys.sdo_geometry );
INSERT INTO  ToolsPoly2D (fid,Geom) 
VALUES( 1,MDSYS.SDO_GEOMETRY(2003, NULL, NULL, 
       MDSYS.SDO_ELEM_INFO_ARRAY(1, 1003, 1, 77, 2003, 1), 
       MDSYS.SDO_ORDINATE_ARRAY(
524570.7, 5202359.4, 524267.6, 5202035.7, 524720, 5201928.8, 524725.1, 5201939.5, 
524739.1, 5201953.4, 524752.6, 5201964.8, 524766, 5201976.2, 524783.1, 5201991.4,
524797.6, 5202011.7, 524804.6, 5202025, 524815, 5202040.8, 524815.6, 5202042.1,
524820.6, 5202052.9, 524825.9, 5202063.1, 524834.6, 5202085.3, 524843.6, 5202099.9,
524853.9, 5202114.5, 524864.6, 5202124.6, 524868.6, 5202130, 524876.1, 5202139.8,
524890.1, 5202158.2, 524903, 5202177.8, 524914.4, 5202194.3, 524925.9, 5202214.7,
524933.5, 5202228, 524945.6, 5202245.1, 524959, 5202260.3, 524968.6, 5202276.2,
524976.9, 5202289.5, 524984.5, 5202299.6, 524987.6, 5202304.1, 524995.4, 5202314.8, 
525005.5, 5202329.5, 525016.4, 5202343.4, 525022.6, 5202354.2, 525023.2, 5202355,
524976.5, 5202359.4, 524570.7, 5202359.4,
524548.319747, 5202136.448354,
524548.319747, 5202227.311646,
524738.654430, 5202227.311646,
524738.654430, 5202136.448354,
524548.319747, 5202136.448354
)));
INSERT INTO TOOLSPoly2D (fid,Geom) VALUES( 2,
MDSYS.SDO_GEOMETRY(2003, NULL, NULL, 
MDSYS.SDO_ELEM_INFO_ARRAY(1, 1003, 1), 
MDSYS.SDO_ORDINATE_ARRAY(
524570.7, 5202359.4, 524267.6, 5202035.7, 524720, 5201928.8, 524725.1, 5201939.5, 
524739.1, 5201953.4, 524752.6, 5201964.8, 524766, 5201976.2, 524783.1, 5201991.4,
524797.6, 5202011.7, 524804.6, 5202025, 524815, 5202040.8, 524815.6, 5202042.1,
524820.6, 5202052.9, 524825.9, 5202063.1, 524834.6, 5202085.3, 524843.6, 5202099.9,
524853.9, 5202114.5, 524864.6, 5202124.6, 524868.6, 5202130, 524876.1, 5202139.8,
524890.1, 5202158.2, 524903, 5202177.8, 524914.4, 5202194.3, 524925.9, 5202214.7,
524933.5, 5202228, 524945.6, 5202245.1, 524959, 5202260.3, 524968.6, 5202276.2,
524976.9, 5202289.5, 524984.5, 5202299.6, 524987.6, 5202304.1, 524995.4, 5202314.8, 
525005.5, 5202329.5, 525016.4, 5202343.4, 525022.6, 5202354.2, 525023.2, 5202355,
524976.5, 5202359.4, 524570.7, 5202359.4)));
update toolspoly2d set centroid = CENTROID.sdo_centroid(p_geometry=>geom,p_start=>1,p_tolerance=>0.05) where fid = 1;
commit;

BEGIN
  &&defaultSchema..tools.MetadataAnalyzer( 
                    p_owner                   => '&&defaultSchema.',
                    p_table_regex             => 'TOOLS*',
                    p_column_regex            => '*',
                    p_fixed_srid              => -9999,
                    p_fixed_diminfo           => NULL,
                    p_tablespace              => NULL,
                    p_work_tablespace         => NULL,
                    p_pin_non_leaf            => FALSE,
                    p_stats_percent           => 100,
                    p_min_projected_tolerance => 0.05,
                    p_rectify_geometry	      => TRUE );
END;
/
show errors

BEGIN
  &&defaultSchema..tools.MetadataAnalyzer( 
                    p_owner                   => '&&defaultSchema.',
                    p_table_regex             => 'GEOD*',
                    p_column_regex            => 'GEOM*',
                    p_fixed_srid              => -9999,
                    p_fixed_diminfo           => NULL,
                    p_tablespace              => NULL,
                    p_work_tablespace         => NULL,
                    p_pin_non_leaf            => FALSE,
                    p_stats_percent           => 100,
                    p_min_projected_tolerance => 0.05,
                    p_rectify_geometry	      => TRUE );
END;
/
show errors
BEGIN
  &&defaultSchema..tools.MetadataAnalyzer( 
                    p_owner                   => '&&defaultSchema.',
                    p_table_regex             => 'PROJ*',
                    p_column_regex            => 'GEOM*',
                    p_fixed_srid              => -9999,
                    p_fixed_diminfo           => NULL,
                    p_tablespace              => NULL,
                    p_work_tablespace         => NULL,
                    p_pin_non_leaf            => FALSE,
                    p_stats_percent           => 100,
                    p_min_projected_tolerance => 0.05,
                    p_rectify_geometry	      => TRUE );
END;
/
show errors
commit;
SELECT Result From COLUMN_ANALYSES;
SELECT * FROM COLUMN_ANALYSIS_SUMMARIES;
execute &&defaultSchema..TOOLS.GeometryCheck('&&defaultSchema.','PROJGEOM2D','GEOM',NULL);
execute &&defaultSchema..TOOLS.GeometryCheck('&&defaultSchema.','PROJPOLY2D','GEOM',NULL);
SELECT * FROM FEATURE_ERROR_SUMMARIES;
SELECT * FROM FEATURE_ERRORS;
-- VARIABLE jobno number;
-- BEGIN
--   DBMS_JOB.SUBMIT(:jobno,'&&defaultSchema..TOOLS.GeometryCheck(''&&defaultSchema.'',''PROJGEOM2D'',''GEOM'',NULL)'',''simon@spatialdbadvisor.com'' );',SYSDATE,'next_day(sysdate,''SUNDAY'')' );
--    COMMIT;
-- END;
-- /
Begin
  &&defaultSchema..tools.SpatialIndexUnindexed( p_owner  => '&&defaultSchema.',
                                       p_check           => TRUE,
                                       p_tablespace      => NULL,
                                       p_work_tablespace => NULL,
                                       p_pin_non_leaf    => FALSE,
                                       p_stats_percent   => 0 );
END;
/
spool off
quit;
