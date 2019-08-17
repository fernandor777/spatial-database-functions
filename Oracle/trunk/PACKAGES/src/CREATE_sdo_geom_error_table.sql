DROP TABLE SDO_GEOM_ERROR;
CREATE TABLE SDO_GEOM_ERROR (
  code   VARCHAR2(10),
  text   VARCHAR2(255),
  cause  VARCHAR2(1000),
  action VARCHAR2(2000)
);
SET FEEDBACK OFF TIMING OFF
insert into sdo_geom_error values('NULL','Empty shape.','','');
insert into sdo_geom_error values('FALSE','Unknown shape problem.','','');
insert into sdo_geom_error values('13000','dimension number is out of range',
'The specified dimension is either smaller than 1 or greater than the number of dimensions encoded in the HHCODE.',
'Make sure that the dimension number is between 1 and the maximum number of dimensions encoded in the HHCODE.');
insert into sdo_geom_error values('13001','dimensions mismatch error',
'The number of dimensions in two HHCODEs involved in a binary HHCODE operation do not match.',
'Make sure that the number of dimensions in the HHCODEs match.');
insert into sdo_geom_error values('13002','specified level is out of range',
'The specified level is either smaller than 1 or greater than the maximum level encoded in an HHCODE.',
'Verify that all levels are between 1 and the maximum number of levels encoded in the HHCODE.');
insert into sdo_geom_error values('13003','the specified range for a dimension is invalid',
'The specified range for a dimension is invalid.',
'Make sure that the lower bound (lb) is less than the upper bound (ub).');
insert into sdo_geom_error values('13004','the specified buffer size is invalid',
'The buffer size for a function is not valid.',
'This is an internal error. Contact Oracle Support Services.');
insert into sdo_geom_error values('13005','recursive HHCODE function error',
'An error occurred in a recursively called HHCODE function.',
'This is an internal error. Contact Oracle Support Services.');
insert into sdo_geom_error values('13006','the specified cell number is invalid',
'The cell identifier is either less than 0 or greater than (2^ndim - 1).',
'Make sure that the cell identifier is between 0 and (2^ndim - 1).');
insert into sdo_geom_error values('13007','an invalid HEX character was detected',
'A character that is not in the range [0-9] or [A-F a-f] was detected.',
'Verify that all characters in a string are in [0-9] or [A-F a-f].');
insert into sdo_geom_error values('13008','the specified date format has an invalid component',
'Part of specified date format is invalid.',
'Verify that the date format is valid.');
insert into sdo_geom_error values('13009','the specified date string is invalid',
'The specified date string has a bad component or does not match the specified format string.',
'Make sure that the components of the date string are valid and that the date and format strings match.');
insert into sdo_geom_error values('13010','an invalid number of arguments has been specified',
'An invalid number of arguments was specified for an SDO function.',
'Verify the syntax of the function call.');
insert into sdo_geom_error values('13011','value is out of range',
'A specified dimension value is outside the range defined for that dimension.',
'Make sure that all values to be encoded are within the defined dimension range.');
insert into sdo_geom_error values('13012','an invalid window type was specified',
'An invalid window type was specified.',
'Valid window types are RANGE, PROXIMITY, POLYGON.');
insert into sdo_geom_error values('13013','the specified topology was not INTERIOR or BOUNDARY',
'A topology was specified that was not INTERIOR or BOUNDARY.',
'Make sure that INTERIOR or BOUNDARY is used to describe an HHCODE''s topology.');
insert into sdo_geom_error values('13014','a topology identifier outside the range of 1 to 8 was specified',
'A topology identifier outside the range of 1 to 8 was specified.',
'Specify a topology in the range of 1 to 8.');
insert into sdo_geom_error values('13015','the window definition is not valid',
'The number of values used to define the window does not correspond to the window type.',
'Verify that the number of values used to defined the window is correct for the window type and number of dimensions.');
insert into sdo_geom_error values('13016','specified topology [string] is invalid',
'The specified topology did not exist in the database, or some components of the topology were missing from the database.',
'Check the specified topology by executing the SDO_TOPO.validate_topology function.');
insert into sdo_geom_error values('13017','unrecognized line partition shape',
'The shape of a 2-D line partition could not be determined.',
'This is an internal error. Contact Oracle Support Services.');
insert into sdo_geom_error values('13018','bad distance type',
'The specified distance type is invalid.',
'The only supported distance functions are EUCLID and MANHATTAN.');
insert into sdo_geom_error values('13019','coordinates out of bounds',
'Vertex coordinates lie outside the valid range for specified dimension.',
'Redefine vertex coordinates within specified boundaries.');
insert into sdo_geom_error values('13020','coordinate is NULL',
'A vertex coordinate has a NULL value.',
'Redefine vertex coordinate to have non-NULL value.');
insert into sdo_geom_error values('13021','element not continuous',
'The coordinates defining a geometric element are not connected.',
'Redefine coordinates for the geometric element.');
insert into sdo_geom_error values('13022','polygon crosses itself',
'The coordinates defining a polygonal geometric element represent crossing segments.',
'Redefine coordinates for the polygon.');
insert into sdo_geom_error values('13023','interior element interacts with exterior element',
'An interior element of a geometric object interacts with the exterior element of that object.',
'Redefine coordinates for the geometric elements.');
insert into sdo_geom_error values('13024','polygon has less than three segments',
'The coordinates defining a polygonal geometric element represent less than three segments.',
'Redefine the coordinates for the polygon.');
insert into sdo_geom_error values('13025','polygon does not close',
'The coordinates defining a polygonal geometric element represent an open polygon.',
'Redefine the coordinates of the polygon.');
insert into sdo_geom_error values('13026','unknown element type for element string.string.string',
'The SDO_ETYPE column in the <layer>_SDOGEOM table contains an invalid geometric element type value.',
'Redefine the geometric element type in the <layer>_SDOGEOM table for the specified geometric element using one of the supported SDO_ETYPE values. See the Oracle Spatial documentation for an explanation of SDO_ETYPE and its possible values.');
insert into sdo_geom_error values('13027','unable to read dimension definition from string',
'There was a problem reading the dimension definition from the <layer>_SDODIM table.',
'Verify that the <layer>_SDODIM table exists and that the appropriate privileges exist on the table. Address any other errors that might appear with the message.');
insert into sdo_geom_error values('13028','Invalid Gtype in the SDO_GEOMETRY object',
'There is an invalid SDO_GTYPE in the SDO_GEOMETRY object.',
'Verify that the geometries have valid gtypes.');
insert into sdo_geom_error values('13029','Invalid SRID in the SDO_GEOMETRY object',
'There is an invalid SDO_SRID in the SDO_GEOMETRY object. The specified SRID may be outside the valid SRID range.',
'Verify that the geometries have valid SRIDs.');
insert into sdo_geom_error values('13030','Invalid dimension for the SDO_GEOMETRY object',
'There is a mismatch between the dimension in the SDO_GTYPE and dimension in the SDO_GEOM_METADATA for the SDO_GEOMETRY object.',
'Verify that the geometries have valid dimensionality.');
insert into sdo_geom_error values('13031','Invalid Gtype in the SDO_GEOMETRY object for point object',
'There is an invalid SDO_GTYPE in the SDO_GEOMETRY object where the VARRAYs are NULL but the SDO_GTYPE is not of type POINT.',
'Verify that the geometries have valid gtypes.');
insert into sdo_geom_error values('13032','Invalid NULL SDO_GEOMETRY object',
'There are invalid SDO_POINT_TYPE or SDO_ELEM_INFO_ARRAY or SDO_ORDINATE_ARRAY fields in the SDO_GEOMETRY object.',
'Verify that the geometries have valid fields. To specify a NULL geometry, specify the whole SDO_GEOMETRY as NULL instead of setting each field to NULL.');
insert into sdo_geom_error values('13033','Invalid data in the SDO_ELEM_INFO_ARRAY in SDO_GEOMETRY object',
'There is invalid data in the SDO_ELEM_INFO_ARRAY field of the SDO_GEOMETRY object. The triplets in this field do not make up a valid geometry.',
'Verify that the geometries have valid data.');
insert into sdo_geom_error values('13034','Invalid data in the SDO_ORDINATE_ARRAY in SDO_GEOMETRY object',
'There is invalid data in the SDO_ORDINATE_ARRAY field of the SDO_GEOMETRY object. The coordinates in this field do not make up a valid geometry. There may be NULL values for X or Y or both.',
'Verify that the geometries have valid data.');
insert into sdo_geom_error values('13035','Invalid data (arcs in geodetic data) in the SDO_GEOMETRY object',
'There is invalid data in the SDO_ELEM_INFO_ARRAY field of the SDO_GEOMETRY object. There are arcs in a geometry that has geodetic coordinates.',
'Verify that the geometries have valid data.');
insert into sdo_geom_error values('13036','Operation [string] not supported for Point Data',
'The specified geometry function is not supported for point data.',
'Make sure that the specified geometry function is not called on point data.');
insert into sdo_geom_error values('13037','SRIDs do not match for the two geometries',
'A Spatial operation is invoked with two geometries where one geometry has an SRID and the other geometry does not have an SRID.',
'Make sure that the spatial operations are invoked between two geometries with compatible SRIDs.');
insert into sdo_geom_error values('13039','failed to update spatial index for element string.string.string',
'Another error will accompany this message that will indicate the problem.',
'Correct any accompanying errors. If no accompanying error message appears, contact Oracle Support Services.');
insert into sdo_geom_error values('13040','failed to subdivide tile',
'This is an internal error.', 'Note any accompanying errors and contact Oracle Support Services.');
insert into sdo_geom_error values('13041','failed to compare tile with element string.string.string',
'The spatial relationship between a generated tile and the specified element could not be determined.',
'This is an internal error. Verify the geometry using the VALIDATE_GEOMETRY_WITH_CONTEXT procedure. If the procedure does not return any errors, note any errors that accompany 13041 and contact Oracle Support Services.');
insert into sdo_geom_error values('13042','invalid SDO_LEVEL and SDO_NUMTILES combination',
'An invalid combination of SDO_LEVEL and SDO_NUMTILES values was read from the <layer>_SDOLAYER table. The most likely cause is that the columns are NULL.',
'Verify the that SDO_LEVEL and SDO_NUMTILES columns contain valid integer values as described in the Oracle Spatial documentation. Then retry the operation.');
insert into sdo_geom_error values('13043','failed to read metadata from the <layer>_SDOLAYER table',
'An error was encountered reading the layer metadata from the <layer>_SDOLAYER table.',
'This error is usually the result of an earlier error which should also have been reported. Address this accompanying error and retry the current operation. If no accompanying error was reported, contact Oracle Support Services.');
insert into sdo_geom_error values('13044','the specified tile size is smaller than the tolerance',
'The tile size specified for fixed size tessellation is smaller than the tolerance as specified in the layer metadata.',
'See the Oracle Spatial documentation for an explanation of tiling levels, tile size, and tiling resolution. Ensure that the tiling parameters are set such that any generated tile is always larger than or equal to a tile at the maximum level of resolution. This can be achieved by using a fewer number of tiles per geometric object or specifying a smaller tile size value than the current one.');
insert into sdo_geom_error values('13045','invalid compatibility flag',
'This is an internal error.','Contact Oracle Support Services.');
insert into sdo_geom_error values('13046','invalid number of arguments',
'An invalid number of arguments were specified for an SDO_GEOM function.',
'See the Oracle Spatial documentation for a description of the syntax and semantics of the relevant SDO_GEOM function.');
insert into sdo_geom_error values('13047','unable to determine ordinate count from table <layer>_SDOLAYER',
'An SDO_GEOM function was unable to determine the number of ordinates for the SDO layer <layer>.',
'Verify that the <layer>_SDOLAYER table has a valid value for the column SDO_ORDCNT. Then retry the operation.');
insert into sdo_geom_error values('13048','recursive SQL fetch error',
'This is an internal error.','Contact Oracle Support Services.');
insert into sdo_geom_error values('13049','unable to determine tolerance value from table <layer>_SDODIM',
'An SDO_GEOM function was unable to determine the tolerance value for the SDO layer <layer>.',
'Verify that the <layer>_SDODIM table has a valid value for the column SDO_TOLERANCE.');
insert into sdo_geom_error values('13050','unable to construct spatial object',
'This is an internal error.','Contact Oracle Support Services.');
insert into sdo_geom_error values('13051','failed to initialize spatial object',
'This is an internal error.','Contact Oracle Support Services.');
insert into sdo_geom_error values('13052','unsupported geometric type for geometry string.string',
'The geometry type for a specific instance in a <layer>_SDOGEOM table is not among the set of geometry types supported by Oracle Spatial.',
'Check the Oracle Spatial documentation for the list of supported geometry types and workarounds that permit the storage and retrieval of non-supported geometric types with the SDO schema.');
insert into sdo_geom_error values('13053','maximum number of geometric elements in argument list exceeded',
'The maximum number of geometric elements that can be specified in the argument list for an SDO_GEOM function was exceeded.',
'Check the Oracle Spatial documentation for the syntax of the SDO_GEOM function and use fewer arguments to describe the geometry, or check the description of the SDO_WINDOW package for a workaround that permits storing the object in a table and then using it in as an argument in a call to the SDO_GEOM function.');
insert into sdo_geom_error values('13054','recursive SQL parse error',
'This is an internal error.','Contact Oracle Support Services.');
insert into sdo_geom_error values('13055','Oracle object string does not exist in specified table',
'The requested object is not present in the specified table.',
'Verify the syntax of the function or procedure that reported this error and verify that the object does indeed exist in the specified table. Then retry the operation.');
insert into sdo_geom_error values('13108','spatial table string not found',
'The specified spatial table does not exist.',
'Check the Spatial data dictionary to make sure that the table is registered.');
insert into sdo_geom_error values('13109','spatial table string exists',
'The specified spatial table is registered in the Spatial data dictionary.',
'Remove the existing table from the Spatial data dictionary or use a different name.');
insert into sdo_geom_error values('13110','cannot drop topology with associated topo_geometry tables',
'The drop_topology procedure was invoked for a topology that has assocated topo_geometry layers with it.',
'Delete the topo_geometry layers from the topology before dropping the topology. Use SDO_TOPO.delete_topo_geometry_layer to delete topo_geometry layers from the topology.');
insert into sdo_geom_error values('13111','cannot add topo_geometry layer [string] to topology',
'It was not possible to add the specified topo_geometry layer to the topology.',
'Make sure the topo_geometry layer table exists in the database.');
insert into sdo_geom_error values('13112','cannot delete topo_geometry layer [string] from topology',
'It was not possible to delete the specified topo_geometry layer from the topology.',
'Check USER_SDO_TOPO_METADATA to see if the specified topo_geometry layer is part of the topology. Only those topo_geometry layers which are part of the topology can be deleted from it.');
insert into sdo_geom_error values('13113','invalid tg_layer_id in sdo_topo_geometry constructor',
'An invalid layer_id was passed to the SDO_TOPO_GEOMETRY constructor.',
'Valid layer_ids are obtained by adding a topo_geometry layer to the topology. Check USER_SDO_TOPO_METADATA to find out the layer_id for an existing topo_geometry layer.');
insert into sdo_geom_error values('13114','[string]_NODE$ table does not exist',
'The NODE$ table for the topology did not exist in the database.',
'There is a severe corruption of the topology. Call Oracle Support Services with the error number.');
insert into sdo_geom_error values('13115','[string]_EDGE$ table does not exist',
'The EDGE$ table for the topology did not exist in the database.',
'There is a severe corruption of the topology. Call Oracle Support Services with the error number.');
insert into sdo_geom_error values('13116','[string]_FACE$ table does not exist',
'The FACE$ table for the topology did not exist in the database.',
'There is a severe corruption of the topology. Call Oracle Support Services with the error number.');
insert into sdo_geom_error values('13117','[string]_RELATION$ table does not exist',
'The RELATION$ table for the topology did not exist in the database.',
'There is a severe corruption of the topology. Call Oracle Support Services with the error number.');
insert into sdo_geom_error values('13118','invalid node_id [string]',
'A topology node operation was invoked with an invalid node_id.',
'Check the topology node$ table to see if the specified node_id exists in the topology.');
insert into sdo_geom_error values('13119','invalid edge_id [string]',
'A topology edge operation was invoked with an invalid edge_id.',
'Check the topology edge$ table to see if the specified edge_id exists in the topology.');
insert into sdo_geom_error values('13120','invalid face_id [string]',
'A topology face operation was invoked with an invalid face_id.',
'Check the topology face$ table to see if the specified face_id exists in the topology.');
insert into sdo_geom_error values('13121','layer type type mismatch with topo_geometry layer type',
'The tg_type in SDO_TOPO_GEOMETRY constructor did not match the type specified for the layer.',
'Check the USER_SDO_TOPO_METADATA view to see the layer type for the layer and use it in the constructor.');
insert into sdo_geom_error values('13122','invalid topo_geometry specified',
'The SDO_TOPO_GEOMETRY object passed into the function/operator was not valid.',
'Check the SDO_TOPO_GEOMETRY object and verify that it is a valid topo_geometry object.');
insert into sdo_geom_error values('13123','invalid <TOPOLOGY> name specified',
'The create_topo operation requires a unique TOPOLOGY name, that already does not exist in the database.',
'Check to see if there is already an entry in the USER_SDO_TOPO_METADATA (or the MDSYS.SDO_TOPO_METADATA_TABLE) with this topology name.');
insert into sdo_geom_error values('13124','unable to determine column id for column string',
'This is an internal error.','Contact Oracle Support Services.');
insert into sdo_geom_error values('13125','partition key is already set',
'A partition key is already set for the spatial table.',
'Only one partition key can be specified per spatial table.');
insert into sdo_geom_error values('13126','unable to determine class for spatial table string',
'This is an internal error.','Contact Oracle Support Services.');
insert into sdo_geom_error values('13127','failed to generate target partition',
'This is an internal error.','Contact Oracle Support Services.');
insert into sdo_geom_error values('13128','current tiling level exceeds user specified tiling level',
'This is an internal error.','Contact Oracle Support Services.');
insert into sdo_geom_error values('13129','HHCODE column string not found',
'The specified spatial column does not exist.',
'Verify that the specified column is a spatial column by checking the Spatial data dictionary.');
insert into sdo_geom_error values('13135','failed to alter spatial table',
'This is an internal error.','Contact Oracle Support Services.');
insert into sdo_geom_error values('13136','null common code generated',
'This is an internal error.','Contact Oracle Support Services.');
insert into sdo_geom_error values('13137','failed to generate tablespace sequence number',
'This is an internal error.','Contact Oracle Support Services.');
insert into sdo_geom_error values('13138','could not determine name of object string',
'This is an internal error.','Contact Oracle Support Services.');
insert into sdo_geom_error values('13139','could not obtain column definition for string',
'This is an internal error.','Contact Oracle Support Services.');
insert into sdo_geom_error values('13140','invalid target type',
'The specified target type is not valid.',
'Substitute a valid target type. Valid target types are TABLE and VIEW.');
insert into sdo_geom_error values('13141','invalid RANGE window definition',
'The RANGE window specified is not correctly defined.',
'A RANGE window is defined by specifying the lower and upper boundary of each dimension as a pair of values (e.g.lower_bound1,upper_bound1,lower_bound2,upper_bound2,...). There should be an even number of values.');
insert into sdo_geom_error values('13142','invalid PROXIMITY window definition',
'The PROXIMITY window specified is not correctly defined.',
'A PROXIMITY window is defined by specifying a center point and a radius. The center point is defined by ND values. There should be ND+1 values.');
insert into sdo_geom_error values('13143','invalid POLYGON window definition',
'The POLYGON window specified is not correctly defined.',
'A POLYGON window is defined by specifying N pairs of values that represent the vertices of the polygon. There should be an even number of values.');
insert into sdo_geom_error values('13144','target table string not found',
'This is an internal error.','Contact Oracle Support Services.');
insert into sdo_geom_error values('13145','failed to generate range list',
'This is an internal error.','Contact Oracle Support Services.');
insert into sdo_geom_error values('13146','could not find table substitution variable string',
'The partition name substitution variable %s was not found in the SQL filter.',
'The substitution variable %s must be in the SQL filter to indicate where that partition name should be placed.');
insert into sdo_geom_error values('13147','failed to generate MBR',
'This is an internal error.','Contact Oracle Support Services.');
insert into sdo_geom_error values('13148','failed to generate SQL filter',
'This is an internal error.','Contact Oracle Support Services.');
insert into sdo_geom_error values('13149','failed to generate next sequence number for spatial table string',
'This is an internal error.','Contact Oracle Support Services.');
insert into sdo_geom_error values('13150','failed to insert exception record',
'Operation failed to insert a record into the exception table.',
'Fix any other errors reported.');
insert into sdo_geom_error values('13151','failed to remove exception record',
'Operation failed to remove a record from the exception table.',
'Fix any other errors reported.');
insert into sdo_geom_error values('13152','invalid HHCODE type',
'Specified HHCODE type is not valid.',
'Substitute a valid HHCODE type. Valid HHCODE types are POINT and LINE.');
insert into sdo_geom_error values('13153','invalid high water mark specified',
'The high water mark must be greater than or equal to zero.',
'Make sure that the high water mark is an integer greater than or equal to zero.');
insert into sdo_geom_error values('13154','invalid precision specified',
'The precision specified is out of range.',
'The precision must be an integer greater than or equal to zero.');
insert into sdo_geom_error values('13155','invalid number of dimensions specified',
'The number of dimensions specified is out of range.',
'The number of dimension must be between 1 and 32.');
insert into sdo_geom_error values('13156','table to be registered string.string is not empty',
'The specified table has rows in it.',
'Make sure that the table to be registered is empty.');
insert into sdo_geom_error values('13157','Oracle error ORAstring encountered while string',
'The specified Oracle error was encountered.',
'Correct the Oracle error.');
insert into sdo_geom_error values('13158','Oracle object string does not exist',
'The specified object does not exist.',
'Verify that the specified object exists.');
insert into sdo_geom_error values('13159','Oracle table string already exists',
'The specified table already exists.',
'Drop the specified table.');
insert into sdo_geom_error values('13181','unable to determine length of column string_SDOINDEX.SDO_CODE',
'The length of the SDO_CODE column in the <layer>_SDOINDEX table could not be determined.',
'Make sure that the <layer>_SDOINDEX table exists with the SDO_CODE column. Verify that the appropriate privileges exist on the table. Then retry the operation.');
insert into sdo_geom_error values('13182','failed to read element string.string.string',
'The specified element could not be read from the <layer>_SDOGEOM table.',
'Verify that the specified element exists in the table. Then retry the operation.');
insert into sdo_geom_error values('13183','unsupported geometric type for geometry string.string',
'The geometry type in the <layer>_SDOGEOM table is unsupported.',
'Modify the geometry type to be one of the supported types.');
insert into sdo_geom_error values('13184','failed to initialize tessellation package',
'Initialization of the tessellation package failed.',
'Record the error messages that are returned and contact Oracle Support Services.');
insert into sdo_geom_error values('13185','failed to generate initial HHCODE',
'This is an internal error.', 'Record the error messages that are returned and contact Oracle Support Services.');
insert into sdo_geom_error values('13186','fixed tile size tessellation failed',
'This is an internal error.', 'Record the error messages that are returned and contact Oracle Support Services.');
insert into sdo_geom_error values('13187','subdivision failed',
'This is an internal error.', 'Record the error messages that are returned and contact Oracle Support Services.');
insert into sdo_geom_error values('13188','cell decode failed',
'This is an internal error.', 'Record the error messages that are returned and contact Oracle Support Services.');
insert into sdo_geom_error values('13189','recursive SQL parse failed',
'This is an internal error.', 'Record the error messages that are returned and contact Oracle Support Services.');
insert into sdo_geom_error values('13190','recursive SQL fetch failed',
'This is an internal error.', 'Record the error messages that are returned and contact Oracle Support Services.');
insert into sdo_geom_error values('13191','failed to read SDO_ORDCNT value',
'This is an internal error.', 'Record the error messages that are returned and contact Oracle Support Services.');
insert into sdo_geom_error values('13192','failed to read number of element rows',
'This is an internal error.', 'Record the error messages that are returned and contact Oracle Support Services.');
insert into sdo_geom_error values('13193','failed to allocate space for geometry',
'There was insufficient memory to read the geometry from the database.',
'Validate the geometry. Record the error messages that are returned and contact Oracle Support Services.');
insert into sdo_geom_error values('13194','failed to decode supercell',
'This is an internal error.','Contact Oracle Support Services.');
insert into sdo_geom_error values('13195','failed to generate maximum tile value',
'This is an internal error.', 'Record the error messages that are returned and contact Oracle Support Services.');
insert into sdo_geom_error values('13196','failed to compute supercell for element string.string.string',
'The system was unable to compute the minimum bounding HHCODE or supercell for the geometry.',
'Another error might accompany this error. Correct the accompanying error. Also, validate the geometry for correctness.');
insert into sdo_geom_error values('13197','element string.string.string is out of range',
'Tessellation did not generate any tiles for this element. This error could be caused if the geometry definition puts the geometry outside the domain defined in the <layer>_SDODIM table.',
'Verify that the geometry is valid and within the defined domain.');
insert into sdo_geom_error values('13198','Spatial error: string',
'Internal error in some Oracle Spatial stored procedure.',
'Record the sequence of procedure calls or events that preceded this error, and contact Oracle Support Services if the error message text does not clearly specify the cause of the error.');
insert into sdo_geom_error values('13199','%s',
'This is an internal error.','Contact Oracle Support Services.');
insert into sdo_geom_error values('13200','internal error [string] in spatial indexing.',
'This is an internal error.','Contact Oracle Support Services with the exact error text.');
insert into sdo_geom_error values('13201','invalid parameters supplied in CREATE INDEX statement',
'An error was encountered while trying to parse the parameters clause for the spatial CREATE INDEX statement.',
'Check the Oracle Spatial documentation for the number, syntax, and semantics of expected parameters for spatial index creation.');
insert into sdo_geom_error values('13202','failed to create or insert into the SDO_INDEX_METADATA table',
'An error was encountered while trying to create the SDO_INDEX_METADATA table or insert data into it.',
'Verify that the current user has CREATE TABLE privilege and that the user has sufficient quota in the default or specified tablespace.');
insert into sdo_geom_error values('13203','failed to read USER_SDO_GEOM_METADATA view',
'An error encountered while trying to read the USER_SDO_GEOM_METADATA view.',
'Check that USER_SDO_GEOM_METADATA has an entry for the current geometry table.');
insert into sdo_geom_error values('13204','failed to create spatial index table',
'An error was encountered while trying to create the index table.',
'Check that user has CREATE TABLE privilege in the current schema and that the user has sufficient quota in the default or specified tablespace.');
insert into sdo_geom_error values('13205','internal error while parsing spatial parameters',
'An internal error was encountered while parsing the spatial parameters.',
'Check that the parameters passed in the parameter string are all valid.');
insert into sdo_geom_error values('13206','internal error [string] while creating the spatial index',
'An internal error was encountered while creating the spatial index.',
'Contact Oracle Support Services with the exact error text.');
insert into sdo_geom_error values('13207','incorrect use of the [string] operator',
'An error was encountered while evaluating the specified operator.',
'Check the parameters and the return type of the specified operator.');
insert into sdo_geom_error values('13208','internal error while evaluating [string] operator',
'An internal error was encountered.',
'Contact Oracle Support Services with the exact error text.');
insert into sdo_geom_error values('13209','internal error while reading SDO_INDEX_METADATA table',
'An internal error was encountered while trying to read the SDO_INDEX_METADATA table.',
'Contact Oracle Support Services. Note this and accompanying error numbers.');
insert into sdo_geom_error values('13210','error inserting data into the index table',
'An error was encountered while trying to insert data into the index table.','Likely causes are: Insufficient quota in the current tablespace - User does not appropriate privileges. Check the accompanying error messages.');
insert into sdo_geom_error values('13211','failed to tessellate the window object',
'An internal error was encountered while trying to tessellate the window object.',
'Verify the geometric integrity of the window object using the VALIDATE_GEOMETRY_WITH_CONTEXT procedure.');
insert into sdo_geom_error values('13212','failed to compare tile with the window object',
'The spatial relationship between a generated tile and the specified window object could not be determined.',
'This is an internal error. Verify the geometry using the VALIDATE_GEOMETRY_WITH_CONTEXT procedure. If the procedure does not return any errors, note any accompanying errors and contact Oracle Support Services.');
insert into sdo_geom_error values('13213','failed to generate spatial index for window object',
'Another error, indicating the real cause of the problem, should accompany this error.',
'Correct any accompanying errors. If no accompanying error message appears, contact Oracle Support Services.');
insert into sdo_geom_error values('13214','failed to compute supercell for window object',
'The system was unable to compute the minimum bounding tile or supercell for the geometry.',
'Another error might accompany this error. Correct the accompanying error. Also, validate the geometry for correctness.');
insert into sdo_geom_error values('13215','window object is out of range',
'Tessellation did not generate any tiles for this geometry. This error could be caused if the geometry definition puts the geometry outside the domain defined in the USER_SDO_GEOM_METADATA view.',
'Verify that the geometry is valid and within the defined domain.');
insert into sdo_geom_error values('13216','failed to update spatial index',
'Another error will accompany this message that will indicate the problem.',
'Correct any accompanying errors. If no accompanying error message appears, contact Oracle Support Services.');
insert into sdo_geom_error values('13217','invalid parameters supplied in ALTER INDEX statement',
'An error was encountered while trying to parse the parameters clause for the spatial ALTER INDEX statement.',
'Check the Oracle Spatial documentation for the number, syntax, and semantics of expected parameters for the spatial ALTER INDEX statement.');
insert into sdo_geom_error values('13218','max number of supported index tables reached for [string] index',
'An add_index parameter was passed to ALTER INDEX when the number of existing index tables is already at maximum.',
'Delete one of the index tables before adding another index table.');
insert into sdo_geom_error values('13219','failed to create spatial index table [string]',
'An error was encountered while trying to create the index table.',
'There is a table in the index''s schema with the specified name. The CREATE INDEX statement will try to create an index table with this name. Either rename this table or change the name of the index.');
insert into sdo_geom_error values('13220','failed to compare tile with the geometry',
'The spatial relationship between a generated tile and the specified geometry could not be determined.',
'This is an internal error. Validate the geometry using the VALIDATE_GEOMETRY_WITH_CONTEXT procedure. If the procedure does not return any errors, note any errors that accompany 13220 and contact Oracle Support Services.');
insert into sdo_geom_error values('13221','unknown geometry type in the geometry object',
'The SDO_GTYPE attribute in the geometry object contains an invalid value',
'Redefine the geometric type in the geometry table using one of the supported SDO_GTYPE values. See the Oracle Spatial documentation for an explanation of SDO_GTYPE and its possible values.');
insert into sdo_geom_error values('13222','failed to compute supercell for geometry in string',
'The system was unable to compute the minimum bounding tile or supercell for a geometry in the specified table.',
'Another error might accompany this error. Correct the accompanying error. Also, validate the geometry for correctness.');
insert into sdo_geom_error values('13223','duplicate entry for string in SDO_GEOM_METADATA',
'There are duplicate entries for the given table and column value pair in the USER_SDO_GEOM_METADATA view.',
'Check that the specified table and geometry column names are correct. There should be only one entry per table, geometry column pair in the USER_SDO_GEOM_METADATA view.');
insert into sdo_geom_error values('13224','zero tolerance specified for layer in USER_SDO_GEOM_METADATA',
'A tolerance of zero or NULL is supplied for a layer in USER_SDO_GEOM_METADATA view.',
'Check the tolerance specified to make sure it is a positive value.');
insert into sdo_geom_error values('13225','specified index table name is too long for a spatial index',
'An index table name is specified which is longer than the supported length of the spatial index table name.',
'Check the supported size of the index table name and reduce the size of the index name.');
insert into sdo_geom_error values('13226','interface not supported without a spatial index',
'The geometry table does not have a spatial index.',
'Verify that the geometry table referenced in the spatial operator has a spatial index on it.');
insert into sdo_geom_error values('13227','SDO_LEVEL values for the two index tables do not match',
'The SDO_LEVEL values for the two index tables used in the spatial join operator do not match.',
'Verify that two compatible indexes are used for the spatial join operator. Quadtree indexes are compatible if they have the same SDO_LEVEL and SDO_NUMTILES values');
insert into sdo_geom_error values('13228','spatial index create failed due to invalid type',
'An Attempt was made to create a spatial index on a column of type other than SDO_GEOMETRY.',
'Make sure that the index is created on a column of type SDO_GEOMETRY.');
insert into sdo_geom_error values('13230','failed to create temporary table [string] during R-tree creation',
'The specified temporary table either already exists or there is not enough tablespace.',
'Delete the table if it already exists and verify if the current user has CREATE TABLE privileges and has sufficient space in the default or specified tablespace.');
insert into sdo_geom_error values('13231','failed to create index table [string] during R-tree creation',
'The specified index table either already exists or there is not enough tablespace.',
'Delete the table if it already exists and verify if the current user has CREATE TABLE privileges and has sufficient space in the default or specified tablespace. If that fails to correct the problem, contact Oracle Support Services.');
insert into sdo_geom_error values('13232','failed to allocate memory during R-tree creation',
'This feature assumes a minimum of 64K memory for bulk creation.',
'Create the index for a small subset of the data. Then, use transactional insert operations for the rest of the data.');
insert into sdo_geom_error values('13233','failed to create sequence number [string] for R-tree',
'The specified sequence number exists.',
'Delete the sequence object, or contact Oracle Support Services.');
insert into sdo_geom_error values('13234','failed to access R-tree-index table [string]',
'The index table is either deleted or corrupted.',
'Rebuild the index or contact Oracle Support Services with accompanying error messages.');
insert into sdo_geom_error values('13236','internal error in R-tree processing: [string]',
'An internal error occurred in R-tree processing.',
'Contact Oracle Support Services with the message text.');
insert into sdo_geom_error values('13237','internal error during R-tree concurrent updates: [string]',
'An inconsistency is encountered during concurrent updates, possibly due to the use of serializable isolation level.',
'Change the isolation level to "read committed" using the ALTER SESSION statement, or contact Oracle Support Services with the message text.');
insert into sdo_geom_error values('13239','sdo_dimensionality not specified during n-d R-tree creation',
'An error occurred in reading the dimensionality parameter',
'Check the documentation for a valid range, and specify the dimensionality as a parameter.');
insert into sdo_geom_error values('13240','specified dimensionality greater than that of the query mbr',
'An error occurred because of too few values in the query minimum bounding rectangle (MBR).',
'Omit the dimensionality, or use the dimensionality of the query.');
insert into sdo_geom_error values('13241','specified dimensionality does not match that of the data',
'An error occurred because the dimensionality specified in the CREATE INDEX statement does not match that of the data.',
'Change the statement to reflect the data dimensionality.');
insert into sdo_geom_error values('13243','specified operator is not supported for 3- or higher-dimensional R-tree',
'Currently, an R-tree index with three or more index dimensions can be used only with the SDO_FILTER operator.',
'Use the SDO_FILTER operator, and check the documentation for the querytype parameter for SDO_FILTER - or contact Oracle Support Services.');
insert into sdo_geom_error values('13249','%s',
'An internal error was encountered in the extensible spatial index component. The text of the message is obtained from some other server component.',
'Contact Oracle Support Services with the exact error text.');
insert into sdo_geom_error values('13250','insufficient privileges to modify metadata table entries',
'The user requesting the operation does not have the appropriate privileges on the referenced tables.',
'Check that the specified feature and geometry table names are correct, and then verify that the current user has at least SELECT privilege on those tables.');
insert into sdo_geom_error values('13251','duplicate entry string in metadata table',
'The specified entry already exists in the metadata table.',
'Check that the specified feature and geometry table names are correct. A feature-geometry table association should be registered only once.');
insert into sdo_geom_error values('13260','layer table string does not exist',
'Data migration source table <layer>_SDOGEOM does not exist.',
'Ensure that the specified layer name is correct and that the corresponding spatial layer tables exist in the current schema.');
insert into sdo_geom_error values('13261','geometry table string does not exist',
'The specified geometry table does not exist in the current schema.',
'Create a table containing a column of type SDO_GEOMETRY and a column of type NUMBER for the GID values.');
insert into sdo_geom_error values('13262','geometry column string does not exist in table string',
'The specified table does not have a column of type SDO_GEOMETRY.',
'Alter or re-create the table such that it includes a column of type SDO_GEOMETRY and a column of type NUMBER.');
insert into sdo_geom_error values('13263','column string in table string is not of type SDO_GEOMETRY',
'The column intended for storing the geometry is not of type SDO_GEOMETRY.',
'Alter the column definition to be of type SDO_GEOMETRY.');
insert into sdo_geom_error values('13264','geometry identifier column string does not exist in table string',
'The specified table does not contain a GID column.',
'Confirm that the GID column name was correctly specified and that it exists in the specified table.');
insert into sdo_geom_error values('13265','geometry identifier column string in table string is not of type NUMBER',
'GID column is not of type NUMBER.',
'Alter the table definition such that the column containing the geometry identifier (GID) is of type NUMBER.');
insert into sdo_geom_error values('13266','error inserting data into table string',
'An OCI error occurred, or the user has insufficient quota in the active tablespace, or the rollback segments are too small.',
'There should be an accompanying error message that indicates the cause of the problem. Take appropriate action to correct the indicated problem.');
insert into sdo_geom_error values('13267','error reading data from layer table string',
'There was an error reading the geometry data from the <layer>_SDOGEOM table.',
'Verify that <layer>_SDOGEOM and <layer>_SDODIM exist. If they do exist, run VALIDATE_LAYER_WITH_CONTEXT on the specified layer.');
insert into sdo_geom_error values('13268','error obtaining dimension from USER_SDO_GEOM_METADATA',
'There is no entry in the USER_SDO_GEOM_METADATA view for the specified geometry table.',
'Insert an entry for the destination geometry table with the correct dimension information.');
insert into sdo_geom_error values('13269','internal error [string] encountered when processing geometry table',
'An internal error occurred.',
'Contact Oracle Support Services with the exact error message text.');
insert into sdo_geom_error values('13270','OCI error string',
'An OCI error occurred while processing the layer or geometry tables.',
'Take the appropriate steps to correct the OCI-specific error.');
insert into sdo_geom_error values('13271','error allocating memory for geometry object',
'Insufficient memory.',
'Make more memory available to the current session/process.');
insert into sdo_geom_error values('13272','geometric object string in table string is invalid',
'The specified object failed the geometric integrity checks performed by the validation function.',
'Check the Oracle Spatial documentation for information about the geometric integrity checks performed by VALIDATE_GEOMETRY_WITH_CONTEXT and correct the geometry definition if required.');
insert into sdo_geom_error values('13273','dimension metadata table string does not exist',
'The <layer>_SDODIM table does not exist.',
'Verify that the specified layer name is correct and that the <layer>_SDODIM table exists in the current schema.');
insert into sdo_geom_error values('13274','operator invoked with non-compatible SRIDs',
'A Spatial operator was invoked with a window geometry with an SRID but the layer has no SRID - or the window has no SRID but the layer has an SRID.',
'Make sure that the layer and window both have an SRID or that they both do not have an SRID.');
insert into sdo_geom_error values('13275','spatial index creation failure on unsupported type',
'An attempt was made to create a spatial index create on a column that is not of type SDO_GEOMETRY.',
'A spatial index can only be created on a column of type SDO_GEOMETRY. Make sure the indexed column is of type SDO_GEOMETRY.');
insert into sdo_geom_error values('13276','internal error [string] in coordinate transformation',
'OCI internal error.',
'Contact Oracle Support Services with the exact error message text.');
insert into sdo_geom_error values('13278','failure to convert SRID to native format',
'OCI internal error.',
'Contact Oracle Support Services with the exact error message text.');
insert into sdo_geom_error values('13281','failure in execution of SQL statement to retrieve WKT',
'OCI internal error, or SRID does not match a table entry.',
'Check that a valid SRID is being used.');
insert into sdo_geom_error values('13282','failure on initialization of coordinate transformation',
'Parsing error on source or destination coordinate system WKT, or incompatible coordinate systems.',
'Check the validity of the WKT for table entries, and check if the requested transformation is valid.');
insert into sdo_geom_error values('13283','failure to get new geometry object for conversion in place',
'OCI internal error.',
'Contact Oracle Support Services with the exact error message text.');
insert into sdo_geom_error values('13284','failure to copy geometry object for conversion in place',
'OCI internal error.',
'Contact Oracle Support Services with the exact error message text.');
insert into sdo_geom_error values('13285','Geometry coordinate transformation error',
'A coordinate pair was out of valid range for a conversion/projection.',
'Check that data to be transformed is consistent with the desired conversion/projection.');
insert into sdo_geom_error values('13287','can''t transform unknown gtype',
'A geometry with a gtype of <= 0 was specified for transformation. Only a gtype >= 1 is allowed.',
'Check the Oracle Spatial documentation for SDO_GTYPE values, and specify a value whose last digit is 1 or higher.');
insert into sdo_geom_error values('13288','point coordinate transformation error',
'An internal error occurred while transforming points.',
'Check the accompanying error messages.');
insert into sdo_geom_error values('13290','the specified unit is not supported',
'An Oracle Spatial function was called with an unknown UNIT value.',
'Check Spatial documentation for the supported units, and call the function with the correct UNIT parameter.');
insert into sdo_geom_error values('13291','conversion error between the specified unit and standard unit',
'Cannot convert the specified unit from/to standard unit for linear distance, angle, or area.',
'Check the unit specification and respecify it.');
insert into sdo_geom_error values('13292','incorrect ARC_TOLERANCE specification',
'When a SDO_BUFFER or SDO_AGGR_BUFFER function is called on a geodetic geometry, or SDO_ARC_DENSIFY is called, ARC_TOLERANCE must be specified, and it should not be less than the tolerance specified for the geometry.',
'Check ARC_TOLERANCE specification and make sure it is correct.');
insert into sdo_geom_error values('13293','cannot specify unit for geometry without a georeferenced SRID',
'An Oracle Spatial function with a UNIT parameter was called on a geometry without a georeferenced SRID.',
'Make sure that spatial functions with UNIT parameters are only called on geometries with georeferenced SRIDs.');
insert into sdo_geom_error values('13294','cannot transform geometry containing circular arcs',
'It is impossible to transform a 3-point representation of a circular arc without distortion.',
'Make sure a geometry does not contain circular arcs.');
insert into sdo_geom_error values('13295','geometry objects are in different coordinate systems',
'An Oracle Spatial function was called with two geometries that have different SRIDs.',
'Transform geometry objects to be in the same coordinate system and call the spatial function.');
insert into sdo_geom_error values('13296','incorrect coordinate system specification',
'Wrong numbers in WKT for Earth radius or flattening for the current SRID.',
'Check WKT in the MDSYS.CS_SRS table for Earth radius and inverse flattening.');
insert into sdo_geom_error values('13300','single point transform error',
'Low-level coordinate transformation error trap.',
'Check the accompanying error messages.');
insert into sdo_geom_error values('13303','failure to retrieve a geometry object from a table',
'OCI internal error.',
'Contact Oracle Support Services with the exact error message text.');
insert into sdo_geom_error values('13304','failure to insert a transformed geometry object in a table',
'OCI internal error.',
'Contact Oracle Support Services with the exact error message text.');
insert into sdo_geom_error values('13330','invalid MASK',
'The MASK passed to the RELATE function is not valid.',
'Verify that the mask is not NULL. See the Oracle Spatial documentation for a list of supported masks.');
insert into sdo_geom_error values('13331','invalid LRS segment',
'The given LRS segment was not a valid line string.',
'A valid LRS geometric segment is a line string geometry in Oracle Spatial. It could be a simple or compound line string (made of lines or arcs, or both). The dimension information must include the measure dimension as the last element in the Oracle Spatial metadata. Currently, the number of dimensions for an LRS segment must be greater than 2 (x/y or longitude/latitude, plus measure)');
insert into sdo_geom_error values('13332','invalid LRS point',
'The specified LRS point was not a point geometry with measure information.',
'Check the given point geometry. A valid LRS point is a point geometry in Oracle Spatial with an additional dimension for measure.');
insert into sdo_geom_error values('13333','invalid LRS measure',
'The given measure for linear referencing was out of range.',
'Redefine the measure.');
insert into sdo_geom_error values('13334','LRS segments not connected',
'The specified geometric segments are not connected.',
'Check the start/end points of the given geometric segments.');
insert into sdo_geom_error values('13335','LRS measure information not defined',
'The measure information of a geometric segment was not assigned (IS NULL).',
'Assign/define the measure information. An LRS geometric segment is defined if its start and end measure are assigned (non-null).');
insert into sdo_geom_error values('13336','failure in converting standard diminfo/geometry to LRS dim/geom',
'There is no room for the measure dimension in the given diminfo, or the specified standard geometry is not a point a line string.',
'Check if the diminfo dimensions are less than 3 or if the geometry type is point or line string.');
insert into sdo_geom_error values('13337','failure in concatenating LRS polygons',
'LRS concatenation involving LRS polygons is not supported.',
'Check the geometry and element types to make sure the concatenate operation is not called with a polygon type.');
insert into sdo_geom_error values('13338','failure in reversing LRS polygon/collection geometry',
'Reversing an LRS polygon/collection geometry produces an invalid geometry.',
'Check the geometry type to make sure this operation is called on non-polygon geometries.');
insert into sdo_geom_error values('13339','LRS polygon clipping across multiple rings',
'Clipping (dynseg) a polygon across multiple rings is not allowed.',
'Polygon clipping is allowed only for a single ring.');
insert into sdo_geom_error values('13340','a point geometry has more than one coordinate',
'A geometry, specified as being a point, has more than one coordinate in its definition.',
'A point has only one coordinate. If this geometry is intended to represent a point cluster, line, or polygon, set the appropriate SDO_GTYPE or SDO_ETYPE value. If this is a single point object, remove the extraneous coordinates from its definition.');
insert into sdo_geom_error values('13341','a line geometry has fewer than two coordinates',
'A geometry, specified as being a line, has fewer than two coordinates in its definition.',
'A line must consist of at least two distinct coordinates. Correct the geometric definition, or set the appropriate SDO_GTYPE or SDO_ETYPE attribute for this geometry.');
insert into sdo_geom_error values('13342','an arc geometry has fewer than three coordinates',
'A geometry, specified as being an arc, has fewer than three coordinates in its definition.',
'An arc must consist of at least three distinct coordinates. Correct the geometric definition, or set the appropriate SDO_GTYPE or SDO_ETYPE attribute for this geometry.');
insert into sdo_geom_error values('13343','a polygon geometry has fewer than four coordinates',
'A geometry, specified as being a polygon, has fewer than four coordinates in its definition.',
'A polygon must consist of at least four distinct coordinates. Correct the geometric definition, or set the appropriate SDO_GTYPE or SDO_ETYPE attribute for this geometry.');
insert into sdo_geom_error values('13344','an arcpolygon geometry has fewer than five coordinates',
'A geometry, specified as being an arcpolygon, has fewer than five coordinates in its definition.',
'An arcpolygon must consist of at least five coordinates. An arcpolygon consists of an ordered sequence of arcs, each of which must be described using three coordinates. Since arcs are connected the end-point of the first is the start of the second and does not have to be repeated. Correct the geometric definition, or set the appropriate SDO_GTYPE or SDO_ETYPE attribute for this geometry.');
insert into sdo_geom_error values('13345','a compound polygon geometry has fewer than five coordinates',
'A geometry, specified as being a compound polygon, has fewer than five coordinates in its definition.',
'A compound polygon must contain at least five coordinates. A compound polygon consists of at least one arc and one line, each of which must be described using three and at least two distinct coordinates respectively. Correct the geometric definition, or set the appropriate SDO_GTYPE or SDO_ETYPE attribute for this geometry.');
insert into sdo_geom_error values('13346','the coordinates defining an arc are collinear',
'Invalid definition of an arc. An arc is defined using three non-collinear coordinates.',
'Alter the definition of the arc, or set the SDO_ETYPE or SDO_GTYPE to the line type.');
insert into sdo_geom_error values('13347','the coordinates defining an arc are not distinct',
'Two or more of the three points defining an arc are the same.',
'Alter the definition of the arc to ensure that three distinct coordinate values are used.');
insert into sdo_geom_error values('13348','polygon boundary is not closed',
'The boundary of a polygon does not close.',
'Alter the coordinate values or the definition of the SDO_GTYPE or SDO_ETYPE attribute of the geometry.');
insert into sdo_geom_error values('13349','polygon boundary crosses itself',
'The boundary of a polygon intersects itself.',
'Correct the geometric definition of the object.');
insert into sdo_geom_error values('13350','two or more rings of a complex polygon touch',
'The inner or outer rings of a complex polygon touch.',
'All rings of a complex polygon must be disjoint. Correct the geometric definition of the object.');
insert into sdo_geom_error values('13351','two or more rings of a complex polygon overlap',
'The inner or outer rings of a complex polygon overlap.',
'All rings of a complex polygon must be disjoint. Correct the geometric definition of the object.');
insert into sdo_geom_error values('13352','the coordinates do not describe a circle',
'The set of coordinates used to describe a circle are incorrect.',
'Confirm that the set of coordinates actually represent points on the circumference of a circle.');
insert into sdo_geom_error values('13353','ELEM_INFO_ARRAY not grouped in threes',
'The ELEM_INFO_ARRAY in an SDO_GEOMETRY definition has more or fewer elements than expected.',
'Confirm that the number of elements in ELEM_INFO_ARRAY is divisible by 3.');
insert into sdo_geom_error values('13354','incorrect offset in ELEM_INFO_ARRAY',
'The offset field in ELEM_INFO_ARRAY of an SDO_GEOMETRY definition references an invalid array subscript in SDO_ORDINATE_ARRAY.',
'Confirm that the offset is a valid array subscript in SDO_ORDINATE_ARRAY.');
insert into sdo_geom_error values('13355','SDO_ORDINATE_ARRAY not grouped by number of dimensions specified',
'The number of elements in SDO_ORDINATE_ARRAY is not a multiple of the number of dimensions supplied by the user.',
'Confirm that the number of dimensions is consistent with data representation in SDO_ORDINATE_ARRAY.');
insert into sdo_geom_error values('13356','adjacent points in a geometry are redundant',
'There are repeated points in the sequence of coordinates.',
'Remove the redundant point.');
insert into sdo_geom_error values('13357','extent type does not contain 2 points',
'Extent type should be represented by two pointslower left and upper right.',
'Confirm that there are only two points for an extent type.');
insert into sdo_geom_error values('13358','circle type does not contain 3 points',
'Circle type should be represented by three distinct points on the circumference.',
'Confirm that there are only three points for a circle type.');
insert into sdo_geom_error values('13359','extent does not have an area',
'The two points representing the extent are identical.',
'Confirm that the two points describing the extent type are distinct.');
insert into sdo_geom_error values('13360','invalid subtype in a compound type',
'This subtype is not allowed within the ETYPE specified.',
'Check the Oracle Spatial documentation for type definitions.');
insert into sdo_geom_error values('13361','not enough sub-elements within a compound ETYPE',
'The compound type declare more sub-elements than actually defined.',
'Confirm that the number of sub-elements is consistent with the compound type declaration.');
insert into sdo_geom_error values('13362','disjoint sub-element in a compound polygon',
'Compound polygon must describe an enclosed area.',
'Confirm that all sub-elements are connected.');
insert into sdo_geom_error values('13363','no valid ETYPE in the geometry',
'None of the ETYPEs within the geometry is supported.',
'Confirm that there is at least one valid ETYPE.');
insert into sdo_geom_error values('13364','layer dimensionality does not match geometry dimensions',
'The spatial layer has a geometry with a different dimensions than the dimensions specified for the layer.',
'Make sure that all geometries in a layer have the same dimensions and that they match the dimensions in the SDO_DIM_ARRAY object for the layer in the USER_SDO_GEOM_METADATA view.');
insert into sdo_geom_error values('13365','layer SRID does not match geometry SRID',
'The spatial layer has a geometry with a different SRID than the SRID specified for the layer.',
'Make sure that all geometries in a layer have the same SRID and that the SRIDs match the SRID for the layer in the USER_SDO_GEOM_METADATA view.');
insert into sdo_geom_error values('13366','invalid combination of interior exterior rings',
'In an Oracle Spatial geometry, interior and exterior rings are not used consistently.',
'Make sure that the interior rings corresponding to an exterior ring follow the exterior ring in the ordinate array.');
insert into sdo_geom_error values('13367','wrong orientation for interior/exterior rings',
'In an Oracle Spatial geometry, the exterior and/or interior rings are not oriented correctly.',
'Be sure that the exterior rings are oriented counterclockwise and the interior rings are oriented clockwise.');
insert into sdo_geom_error values('13368','simple polygon type has more than one exterior ring',
'In a polygon geometry there is more than one exterior ring.',
'Set the type to be multipolygon if more than one exterior ring is present in the geometry.');
insert into sdo_geom_error values('13369','invalid value for etype in the 4-digit format',
'A 4-digit etype for a non-polygon type element is used, or the orientation is not a valid orientation for interior/exterior rings of the polygon.',
'Correct the geometry definition.');
insert into sdo_geom_error values('13370','failure in applying 3D LRS functions',
'Only non-geodetic 3D line string geometries (made of line segments) are supported for 3D LRS functions.',
'Check the geometry and element types and the SRID values.');
insert into sdo_geom_error values('13371','invalid position of measure dimension',
'LRS measure dimension has to be after spatial dimensions. The position has to be either 3rd or 4th in the dim_info_array.',
'Check the geometry''s gtype and its position in the dim_info_array.');
insert into sdo_geom_error values('13372','failure in modifying metadata for a table with spatial index',
'Modifying the metadata after the index is created will cause an inconsistency between the geometry''s gtype and diminfo.',
'Modify (or Prepare) metadata before creating an index on the SDO_GEOMETRY column.');
insert into sdo_geom_error values('13373','element of type extent is not supported for geodetic data',
'Element type extent for a polygon geometry is not supported for geodetic data.',
'Convert the extent type polygon to a regular 5-point polygon and set the etype accordingly.');
insert into sdo_geom_error values('13374','SDO_MBR not supported for geodetic data',
'The SDO_MBR functionality is not supported for geodetic data.',
'Find an alternative function that can be used in this context.');
insert into sdo_geom_error values('13375','the layer is of type [string] while geometry inserted has type [string]',
'The layer has a type that is different or inconsistent with the type of the current geometry.',
'Change the geometry type to agree with the layer type, or change the layer type to agree with the geometry type.');
insert into sdo_geom_error values('13376','invalid type name specified for layer_gtype parameter',
'An invalid type name is specified for the layer_gtype constraint.',
'See the Spatial documentation for of valid keywords that can be used in defining a layer_gtype constraint.');
insert into sdo_geom_error values('13377','invalid combination of elements with orientation',
'An element of the geometry has orientation specified while some other element has no orientation specified (4-digit etype).',
'Make sure all the polygon elements have orientation specified using the 4-digit etype notation.');
insert into sdo_geom_error values('13378','invalid index for element to be extracted',
'An invalid (or out of bounds) index was specified for extracting an element from a geometry.',
'Make sure the parameters to the extract function are in the valid range for the geometry.');
insert into sdo_geom_error values('13379','invalid index for sub-element to be extracted',
'An invalid (or out of bounds) index was specified for extracting a sub-element from a geometry.',
'Make sure the parameters to the extract function are in the valid range for the geometry.');
insert into sdo_geom_error values('13380','network not found',
'The specified network was not found in the network metadata.',
'Insert the network information in the USER_SDO_NETWORK_METADATA view.');
insert into sdo_geom_error values('13381','table:string not found in network:string',
'The specified table was not found in the network metadata.',
'Insert the table information in the USER_SDO_NETWORK_METADATA view.');
insert into sdo_geom_error values('13382','geometry metadata (table:string column:string) not found in spatial network:string',
'The specified geometry metadata was not found in the spatial network metadata.',
'Insert the spatial metadata information in the USER_SDO_NETWORK_METADATA view.');
insert into sdo_geom_error values('13383','inconsistent network metadata: string',
'There was an inconsistency between the network metadata and the node/link information.',
'Check the network metadata and the node/link information.');
insert into sdo_geom_error values('13384','error in network schema: string',
'The network table(s) did not have required column(s)',
'Check the network schema.');
insert into sdo_geom_error values('13385','error in network manager: [string]',
'There was an internal error in network manager.',
'Contact Oracle Customer Support for more help.');
insert into sdo_geom_error values('13386','commit/rollback operation error: [string]',
'The index-level changes were not fully incorporated as part of the commit or rollback operation.',
'Correct the specified error and use the following statementALTER INDEX <index-name> PARAMETERS (''index_status=synchronize'');');
insert into sdo_geom_error values('13387','sdo_batch_size for array inserts should be in the range [number,number]',
'The specified value for sdo_batch_size was too high or too low.',
'Change the value to be in the specified range.');
insert into sdo_geom_error values('13388','invalid value for dst_spec parameter',
'The dst_spec parameter was specified in the wrong format.',
'Check the documentation for this parameter.');
insert into sdo_geom_error values('13389','unable to compute buffers or intersections in analysis function',
'There was an internal error in computing the buffers or intersections in the specified spatial analysis function.',
'Modify the tolerance value in the USER_SDO_GEOM_METADATA view before invoking the spatial analysis function.');
insert into sdo_geom_error values('13390','error in spatial analysis and mining function: [string]',
'There was an internal error in the specified analysis function.',
'Contact Oracle Customer Support for more help.');
insert into sdo_geom_error values('13401','duplicate entry for string in USER_SDO_GEOR_SYSDATA view',
'The RASTER_DATA_TABLE and RASTER_ID columns contained the same information in two or more rows in the USER_SDO_GEOR_SYSDATA view.',
'Ensure that the RASTER_DATA_TABLE and RASTER_ID columns in the USER_SDO_GEOR_SYSDATA view contain the correct information, and that the value pair is unique for each row.');
insert into sdo_geom_error values('13402','the rasterType is null or not supported',
'The specified rasterType was null or not supported.',
'Check the documentation for the rasterType number and/or formats supported by GeoRaster.');
insert into sdo_geom_error values('13403','invalid rasterDataTable specification',
'One GeoRaster object must have one corresponding RDT table and this table must be of SDO_RASTER type if it is created. However, this was not the case.',
'Check the rasterDataTable name specification and make sure that it is not null, that the corresponding table doesn''t exist, and that it is of SDO_RASTER type if the table exists.');
insert into sdo_geom_error values('13404','invalid ultCoordinate parameter',
'The ultCoordinate array parameter had the wrong length or contained an invalid value.',
'Check the documentation, and make sure the ultCoordinate parameter is correct.');
insert into sdo_geom_error values('13405','null or invalid dimensionSize parameter',
'The dimensionSize array parameter was null, had the wrong length, or contained an invalid value.',
'Check the documentation, and make sure the dimensionSize parameter is correct.');
insert into sdo_geom_error values('13406','null or invalid GeoRaster object for output',
'The GeoRaster object for output was null or invalid.',
'Make sure the GeoRaster object for output has been initialized properly.');
insert into sdo_geom_error values('13407','invalid storage parameter',
'The storage parameter contained an invalid specification.',
'Check the documentation, and make sure the storage parameter is correct.');
insert into sdo_geom_error values('13408','invalid blockSize storage parameter',
'The blockSize storage parameter had the wrong length or contained invalid value.',
'Check the documentation, and make sure the blockSize storage parameter is correct.');
insert into sdo_geom_error values('13409','null or invalid pyramidLevel parameter',
'The specified pyramidLevel parameter was null or invalid.',
'Make sure the pyramidLevel parameter specifies a valid pyramid level value for the GeoRaster object.');
insert into sdo_geom_error values('13410','invalid layerNumbers or bandNumbers parameter',
'The layerNumbers or bandNumbers parameter was invalid.',
'Check the documentation and make sure the layerNumbers or bandNumbers parameter is valid.');
insert into sdo_geom_error values('13411','subset results in null data set',
'The intersection of cropArea and source GeoRaster object was null.',
'Check the documentation, and make sure the cropArea parameter is correct.');
insert into sdo_geom_error values('13412','invalid scale parameter',
'The scale parameter was invalid.',
'Check the documentation, and make sure the scale parameter is correct.');
insert into sdo_geom_error values('13413','null or invalid resampling parameter',
'The resampling parameter was null or invalid.',
'Check the documentation, and make sure the resampling parameter is correct.');
insert into sdo_geom_error values('13414','invalid pyramid parameter',
'The pyramid parameter was invalid.',
'Check the documentation, and make sure the pyramid parameter is correct.');
insert into sdo_geom_error values('13415','invalid or out of scope point specification',
'The point position specified by the <ptGeom, layerNumber> or <rowNumber, colNumber, bandNumber> parameter combination was invalid or out of scope.',
'Make sure the parameter(s) specify a valid point that is or can be translated into a cell position inside the cell space of the GeoRaster object.');
insert into sdo_geom_error values('13416','invalid geometry parameter',
'The geometry parameter did not specify a valid single-point geometry.',
'Specify a valid single-point geometry.');
insert into sdo_geom_error values('13417','null or invalid layerNumber for get functions',
'The layerNumber parameter was null or out of scope.',
'Specify a valid layerNumber parameter.');
insert into sdo_geom_error values('13418','null or invalid parameter(s) for set functions',
'A parameter for set metadata operations was null or invalid.',
'Check the documentation for information about the parameters.');
insert into sdo_geom_error values('13419','cannot perform mosaick operation on the specified table column',
'An attempt to perform a mosaick operation failed because the GeoRaster objects in the specified table column did not meet necessary conditions.',
'Check the documentation for SDO_GEOR.Mosaick for details.');
insert into sdo_geom_error values('13420','the SRID of the geometry parameter was not null',
'The input geometry must be in the GeoRaster cell space, which has a null SRID value.',
'Make sure the geometry parameter has a null SRID.');
insert into sdo_geom_error values('13421','null or invalid cell value',
'The cell value was null or out of scope.',
'Make sure the cell value is not null and is in the range as designated by the cellDepth of the specified GeoRaster object.');
insert into sdo_geom_error values('13422','invalid model coordinate parameter',
'The model coordinate array parameter had the wrong length or had null ordinate element(s).',
'Make sure the model coordinate parameter is valid.');
insert into sdo_geom_error values('13423','invalid cell coordinate parameter',
'The cell coordinate array parameter had the wrong length or had null ordinate element(s).',
'Make sure the cell coordinate parameter is valid.');
insert into sdo_geom_error values('13424','the GeoRaster object is not spatially referenced',
'The GeoRaster object was not spatially referenced.',
'Make sure the GeoRaster object is spatially referenced.');
insert into sdo_geom_error values('13425','function not implemented',
'This specific function was not implemented.',
'Do not use the function that causes this error.');
insert into sdo_geom_error values('13426','invalid window parameter for subset operation',
'The specified window parameter was invalid.',
'Specify a valid window parameter. Check the documentation for details.');
insert into sdo_geom_error values('13427','invalid BLOB parameter for output',
'The specified output BLOB parameter was invalid.',
'Make sure the output BLOB parameter is initialized properly.');
insert into sdo_geom_error values('13428','invalid modelCoordinateLocation',
'The program [or user] specified a modelCoordinateLocation that is not supported, or the modelCoordinateLocation of the GeoRaster object was wrong.',
'Set or specify the modelCoordinateLocation to be CENTER (0) or UPPERLEFT (1).');
insert into sdo_geom_error values('13429','invalid xCoefficients or yCoefficients parameter(s)',
'An attempt to perform a georeference operation failed. Possible reasons include xCoefficients or yCoefficients having the wrong number of coefficients or invalid coefficients.',
'Check the documentation for supported coefficient specifications.');
insert into sdo_geom_error values('13430','the GeoRaster object has null attribute(s)',
'The metadata or rasterType of the GeoRaster object was null.',
'This object may only be used as an output parameter of procedures or functions. It is not valid for other purposes.');
insert into sdo_geom_error values('13431','GeoRaster metadata rasterType error',
'The rasterType in the metadata of the GeoRaster object was inconsistent with the GeoRaster rasterType attribute.',
'Make sure the rasterType in the metadata of the GeoRaster object and the GeoRaster rasterType attribute have the same value.');
insert into sdo_geom_error values('13432','GeoRaster metadata blankCellValue error',
'The blankCellValue specification could be found in the metadata of a blank GeoRaster object.',
'Add blankCellValue to the metadata whenever isBlank is true.');
insert into sdo_geom_error values('13433','GeoRaster metadata default RGB error',
'At least one of the defaultRed, defaultGreen, and defaultBlue values (logical layer numbers) was zero, negative, or out of range.',
'Check the documentation for details.');
insert into sdo_geom_error values('13434','GeoRaster metadata cellRepresentation error',
'The cellRepresentation type was not supported.',
'Check the documentation for supported cellRepresentation types.');
insert into sdo_geom_error values('13435','GeoRaster metadata dimension inconsistent',
'The specification of dimensions or totalDimensions was inconsistent with rasterType, or vice versa.',
'Make sure dimension specifications are consistent.');
insert into sdo_geom_error values('13436','GeoRaster metadata dimensionSize error',
'Either the dimensionSize for each dimension was not specified, or an extraneous dimensionSize was specified.',
'Add a dimsenionSize for each dimension of the GeoRaster object and delete extra dimensionSize elements.');
insert into sdo_geom_error values('13437','GeoRaster metadata blocking error',
'Either the wrong block number(s) or block size(s) along dimensions were specified, or the block numbers and sizes when taken together were not consistent.',
'Check the documentation for details.');
insert into sdo_geom_error values('13438','GeoRaster metadata pyramid type error',
'The specified pyramid type was not supported.',
'Check the documentation for supported pyramid types.');
insert into sdo_geom_error values('13439','GeoRaster metadata pyramid maxLevel error',
'The specified maxLevel exceeded the maximum level allowed by the specified pyramid type.',
'Check the documentation for supported pyramid types and their total level limitations.');
insert into sdo_geom_error values('13440','GeoRaster metadata compression type error',
'The specified compression type was not supported.',
'Check the documentation for supported compression types.');
insert into sdo_geom_error values('13441','GeoRaster metadata SRS error',
'The referenced GeoRaster object had no defined polynomial referencing model.',
'Define or generate the polynomialModel, or set isReferenced to FALSE.');
insert into sdo_geom_error values('13442','GeoRaster metadata SRS error',
'The polynomialModel did not match the supported number of variables.',
'Check the documentation for supported number of variables in the polynomialModel specification.');
insert into sdo_geom_error values('13443','GeoRaster metadata SRS error',
'The polynomialModel specification had an incorrect pType value.',
'Check the documentation for supported polynomial types.');
insert into sdo_geom_error values('13444','GeoRaster metadata SRS error',
'The polynomialModel specification had the wrong number of coefficients.',
'Check the documentation for the required number of coefficients under different conditions.');
insert into sdo_geom_error values('13445','GeoRaster metadata SRS error',
'The polynomialModel specification had a zero denominator.',
'Make sure the denominator of the polynomialModel specification is not zero.');
insert into sdo_geom_error values('13446','GeoRaster metadata TRS error',
'The GeoRaster Temporal Reference System was not supported.',
'Set isReferenced to FALSE.');
insert into sdo_geom_error values('13447','GeoRaster metadata BRS error',
'The GeoRaster Band Reference System was not supported.',
'Set isReferenced to FALSE.');
insert into sdo_geom_error values('13448','GeoRaster metadata BRS error',
'The GeoRaster spectral extent specification was incorrect.',
'The MIN value must be less than the MAX value in the spectralExtent element.');
insert into sdo_geom_error values('13449','GeoRaster metadata ULTCoordinate error',
'The GeoRaster rasterInfo ULTCoordinate was not correct.',
'Check the documentation for restrictions.');
insert into sdo_geom_error values('13450','GeoRaster metadata layerInfo error',
'The GeoRaster had more than one layerInfo element, or the layerDimension value was not supported.',
'The current release only supports one layerInfo element - layer can only be defined along one dimension, and this dimension must be BAND.');
insert into sdo_geom_error values('13451','GeoRaster metadata scaling function error',
'The scaling function had a zero denominator.',
'Make sure the scaling function denominator is not zero.');
insert into sdo_geom_error values('13452','GeoRaster metadata BIN function error',
'The bin function data did not match its type.',
'For EXPLICIT type, provide a binTableName element - otherwise, provide a binFunctionData element.');
insert into sdo_geom_error values('13453','GeoRaster metadata layer error',
'Too many subLayers were defined for the GeoRaster object, or layerNumber or layerDimensionOrdinate was not assigned correctly.',
'The total number of logical layers cannot exceed the total number of physical layers, and each logical layer must be assigned a valid physical layer number following the same order. Check the documentation for more details.');
insert into sdo_geom_error values('13454','GeoRaster metadata is invalid',
'The GeoRaster metadata was invalid against its XML Schema.',
'Run the schemaValidate routine to find the errors.');
insert into sdo_geom_error values('13455','GeoRaster metadata TRS error',
'The beginDateTime value was later than the endDateTime value.',
'Make sure that the beginDateTime value is not later than the endDateTime value.');
insert into sdo_geom_error values('13456','GeoRaster cell data error',
'There was error in the GeoRaster cell data.',
'The GeoRaster object is invalid.');
insert into sdo_geom_error values('13457','GeoRaster cell data error',
'There was error in the cell data of the pyramids.',
'Delete the pyramids and re-generate them.');
insert into sdo_geom_error values('13458','GeoRaster metadata SRS error',
'The polynomial model did not match the requirements of a rectified GeoRaster object.',
'Check the documentation for the requirements of the polynomial model for a rectified GeoRaster object, or set isRectified to be false.');
insert into sdo_geom_error values('13459','GeoRaster metadata SRS error',
'The polynomial model was not an six-parameter transformation, or the six-parameter transformation was not valid.',
'Check the documentation and make sure the polynomial model is a valid six-parameter affine transformation.');
insert into sdo_geom_error values('13460','GeoRaster metadata SRS error',
'The referenced GeoRaster object had a zero model space SRID or the specified model space SRID was zero.',
'Set or specify the model space SRID to be a nonzero number.');
insert into sdo_geom_error values('13461','the interleaving type is not supported',
'The interleaving type of the GeoRaster object was not supported.',
'Check the documentation for the interleaving types supported by GeoRaster. Use SDO_GEOR.changeFormat to transform the image to a supported interleaving type.');
insert into sdo_geom_error values('13462','invalid blocking specification',
'The specified blocking configuration was invalid.',
'Block size must always be a power of 2.');
insert into sdo_geom_error values('13463','error retrieving GeoRaster data: string',
'An internal error occurred while retrieving GeoRaster data from the database.',
'Check the error message for details.');
insert into sdo_geom_error values('13464','error loading GeoRaster data: string',
'An internal error occurred while loading GeoRaster data into the database.',
'Check the error message for details.');
insert into sdo_geom_error values('13465','null or invalid table or column specification',
'The specified table or column did not exist, or the column was not a GeoRaster column.',
'Make sure the specified table exists and the specified column is a GeoRaster column.');
insert into sdo_geom_error values('13480','the Source Type is not supported',
'The specified source type was not supported.',
'Check the documentation for the source types (such as FILE and HTTP) supported by GeoRaster.');
insert into sdo_geom_error values('13481','the destination type is not supported',
'The specified destination type was not supported.',
'Check the documentation for the destination types (such as FILE) supported by GeoRaster.');
insert into sdo_geom_error values('13482','GeoRaster object is not initialized for the image',
'No GeoRaster object has been initialized for the specified image.',
'Initialize a GeoRaster object to hold this image before loading it into the database. Check the documentation for details.');
insert into sdo_geom_error values('13483','insufficient memory for the specified GeoRaster data',
'There was insufficient memory to hold the specified GeoRaster data for this operation.',
'Use SDO_GEOR.subset to isolate a subset of the GeoRaster data, or reblock the GeoRaster data into smaller sized blocks.Check the documentation.');
insert into sdo_geom_error values('13484','the file format and/or compression type is not supported',
'The file format and/or compression type was not supported.',
'Check the documentation for formats that are currently supported by GeoRaster.');
insert into sdo_geom_error values('13497','%s',
'This is an internal GeoRaster error.', 'Contact Oracle Support Services. You may want to make sure the GeoRaster object is valid before you do so.');
insert into sdo_geom_error values('13498','%s',
'This is an internal Spatial error.', 'Contact Oracle Support Services.');
insert into sdo_geom_error values('54500','invalid combination of elements ',
'The geometry did not start from the correct level in the hierarchy.',
'Correct the hierarchy in the geometry.');
insert into sdo_geom_error values('54501','no holes expected ',
'The geometry contained one or more unexpected holes.',
'Remove any holes in the geometry.');
insert into sdo_geom_error values('54502','solid not closed ',
'The solid geometry was not closed i.e., faces of solid are not 2-manifold due to incorrectly defined, oriented, or traversed line segment because each edge of a solid must be traversed exactly twice, once in one direction and once in the reverse direction.',
'Correct the orientation of the edges of the neighboring polygons.');
insert into sdo_geom_error values('54503','incorrect solid orientation ',
'The orientation of the solid was not correct.',
'Correct the orientation or specification of the outer or inner solid geometry according to the geometry rules for such a solid.');
insert into sdo_geom_error values('54504','multiple outer geometries ',
'The geometry contained more than one outer geometry.',
'Remove all but one of the outer geometries.');
insert into sdo_geom_error values('54505','ring does not lie on a plane ',
'The ring was not flat.',
'Make sure all of the vertices of the ring are on the same plane.');
insert into sdo_geom_error values('54506','compound curve not supported for 3-D geometries ',
'The 3-D geometry contained one or more compound curves, which are not supported for 3-D geometries.',
'Remove all compound curves from the geometry.');
insert into sdo_geom_error values('54507','duplicate points in multipoint geometry ',
'The multipoint geometry had two points that either had identical coordinates or were the same point considering the geometry tolerance.',
'Make sure all points are different, considering the tolerance.');
insert into sdo_geom_error values('54508','overlapping surfaces in a multisolid geometry ',
'The multisolid geometry contained one or more fully or partially overlapping surfaces.',
'Ensure that the multisolid geometry contains no overlapping areas.');
insert into sdo_geom_error values('54509','solid not attached to composite solid ',
'To connect solids in a composite solid geometry, at least one of the faces of a solid must be shared (fully or partially) with only another solid. However, at least one of the faces in this composite solid was not shared by exactly two solids only.',
'Ensure that at least one face in a composite solid is shared by exactly two solids.');
insert into sdo_geom_error values('54510','no outer geometry expected ',
'An outer geometry was found when only inner geometries were expected.',
'Remove all outer geometries.');
insert into sdo_geom_error values('54511','edges of inner and outer solids intersect ',
'An inner solid had a common edge with outer solid.',
'Ensure that edges of inner and outer solids do not intersect.');
insert into sdo_geom_error values('54512','a vertex of an inner solid is outside corresponding outer solid ',
'A solid geometry contained an inner solid with at least one vertex outside its corresponding outer solid.',
'Ensure that all vertices of inner solids are not outside their corresponding outer solid.');
insert into sdo_geom_error values('54513','inner solid surface overlaps outer solid surface ',
'One or more faces of an inner solid surface either fully or partially overlapped an outer solid surface.',
'Ensure that inner and outer surfaces have no shared (fully or partially overlapping) faces.');
insert into sdo_geom_error values('54514','overlapping areas in multipolygon ',
'A multipolygon geometry contained one or more common (shared, fully or partially overlapped) polygons.',
'Ensure that no polygons in a multipolygon overlap.');
insert into sdo_geom_error values('54515','outer rings in a composite surface intersect ',
'Outer rings, either on the same plane or different planes, in a composite surface intersected.',
'Ensure that outer rings do not intersect. They can share edges.');
insert into sdo_geom_error values('54516','adjacent outer rings of composite surface cannot be on same plane ',
'The conditional flag was set, and a composite surface had at least two outer rings sharing a common edge on the same plane.',
'Change those outer rings into one larger outer ring.');
insert into sdo_geom_error values('54517','outer ring is on the same plane and overlaps another outer ring ',
'An outer ring in a composite surface shared a common area with another outer ring.',
'Ensure that no outer rings fully or partially overlap.');
insert into sdo_geom_error values('54518','shared edge of composite surface not oriented correctly ',
'A shared edge (one shared by two polygons) in a composite surface was not correctly oriented. Each shared edge must be oriented in one direction with respect to its first polygon and then in the reverse direction with respect to its second polygon.',
'Reverse one of the directions of the shared edge with respect to its polygons.');
insert into sdo_geom_error values('54519','polygon (surface) not attached to composite surface ',
'Not all polygons of a surface had a common (fully or partially shared) edge.',
'Ensure that each polygon is attached to the composite surface by one of its edges.');
insert into sdo_geom_error values('54520','inner ring not on the same plane as its outer ring ',
'An inner ring was not on the same plane as its outer ring.',
'Ensure that each inner ring is on the same plane as its outer ring.');
insert into sdo_geom_error values('54521','inner ring is not inside or is touching outer ring more than once ',
'An inner ring either was not inside its outer ring or touched its outer ring more than once.',
'Ensure that the inner ring is inside its outer ring and does not touch the outer ring more than once. If an inner ring touches its outer ring more than once, then the outer ring is no longer a topologically simple or singly connected polygon (ring).');
insert into sdo_geom_error values('54522','inner rings of same outer ring cannot intersect or share boundary ',
'Two inner rings of the same outer ring intersected or shared a boundary.',
'Ensure that line segments of an inner ring do not intersect or fully or partially coincide with line segments of another inner ring sharing the same outer ring.');
insert into sdo_geom_error values('54523','inner rings of same outer ring cannot touch more than once ',
'Two inner rings of the same outer ring touched more than once.',
'Ensure that inner rings of the same outer ring touch at no more than one point.');
insert into sdo_geom_error values('54524','inner ring cannot be inside another inner ring of same outer ring ',
'An inner ring was inside another ring of the same outer ring.',
'Ensure that no inner ring is inside another inner ring of the same outer ring.');
insert into sdo_geom_error values('54525','incorrect box volume due to wrong ordinates ',
'The rectangular box in shortcut format did not have its first x,y,z coordinates either all greater or less than its second x,y,z coordinates.',
'Make sure that the first x,y,z coordinates are either all greater or all less than the second x,y,z coordinates.');
insert into sdo_geom_error values('54526','multi or composite geometry must be decomposed before extraction ',
'The extraction could not be performed because the multi or composite geometry must first be decomposed into simple geometries (with or without inner geometries). The multi or composite geometry had a gtype of GTYPE_MULTISOLID, GTYPE_MULTISURFACE, GTYPE_MULTICURVE, GTYPE_MULTIPOINT, or GTYPE_COLLECTION, or the geometry was a line string.',
'Use the MULTICOMP_TOSIMPLE parameter to element extractor to decompose the multi or composite geometry to a simple geometry.');
insert into sdo_geom_error values('54527','operation not permitted on a simple geometry ',
'A MULTICOMP_TOSIMPLE parameter to element extractor was attempted on a geometry that is already simple.',
'Do not use the MULTICOMP_TOSIMPLE parameter to element extractor on simple geometries.');
insert into sdo_geom_error values('54528','inner composite surfaces or surfaces with inner ring(s) expected ',
'An INNER_OUTER parameter to element extractor was attempted on a surface that was not simple or composite.',
'Ensure that the etype of the geometry for the INNER_OUTER parameter to element extractor is ETYPE_SURFACE or ETYPE_COMPOSITESURFACE.');
insert into sdo_geom_error values('54529','geometry should have multi-level hierarchy (like triangle) ',
'The geometry did not have the multi-level hierarchy required for this operation. For example, if the parameter to element extractor (hierarchy level) is not LOWER_LEVEL, but the geometry etype is ETYPE_SOLID and gtype is GTYPE_SOLID, an extract operation is not allowed, because a simple solid can only be decomposed into lower level geometries, such as composite surfaces.',
'Ensure that the geometry has the appropriate hierarchy. For example, if the geometry etype is ETYPE_SOLID and gtype is GTYPE_SOLID, the parameter to element extractor (hierarchy level) should be LOWER_LEVEL.');
insert into sdo_geom_error values('54530','invalid etype for element at element offset ',
'An invalid etype was encountered.',
'Correct the etype of the geometry.');
insert into sdo_geom_error values('54531','invalid orientation for element at element offset ',
'The orientation of the current geometry was not valid.',
'Reverse the orientation of the geometry.');
insert into sdo_geom_error values('54532','incomplete composite surface ',
'The end of composite surface was reached before all necessary surfaces were defined.',
'Add more surfaces to match the geometry definition, or reduce the specified number of surfaces.');
insert into sdo_geom_error values('54533','invalid etype in composite surface of solid ',
'The etype of the composite surface of a solid was not valid.',
'Ensure that the etype is orient*1000+ETYPE_SOLID, where orient is 1 for outer solid and 2 for inner solid.');
insert into sdo_geom_error values('54534','incorrect box surface due to wrong specification ',
'The elemInfo definition was not correct for the surface of the axis aligned box.',
'Change the interpretation to 3 in the elemInfo definition.');
insert into sdo_geom_error values('54535','incorrect box surface because it is on arbitrary plane ',
'The axis aligned box surface was not on the yz, xz, or xy plane.',
'Ensure that the first and fourth coordinates, or the second and fifth coordinates, or the third and sixth coordinates are the same. This means that the surface is on the yz, xz or xy plane, respectively.');
insert into sdo_geom_error values('54536','axis aligned box surface not defined properly ',
'The inner geometry etype did not start with 2, or the outer geometry etype did not start with 1, or both occurred.',
'Use the correct etype for the inner and outer geometries.');
insert into sdo_geom_error values('54537','incorrect box surface due to wrong orientation ',
'The rectangular surface in shortcut format did not have its first x,y,z coordinates all greater than or equal to or all less than or equal to its second x,y,z coordinates.',
'Ensure that the first x,y,z coordinates are either all greater than or equal to or all less than or equal to the second x,y,z coordinates.');
insert into sdo_geom_error values('54538','unexpected gtype ',
'The gtype of the geometry was not GTYPE_SOLID, GTYPE_SURFACE, GTYPE_CURVE or GTYPE_POINT.',
'Correct the elemInfo array to fix any invalid gtype and etypes that violate the geometry hierarchy.');
insert into sdo_geom_error values('54539','cannot process the geometry(s) for this operation ',
'The geometry had errors in it.',
'Validate the geometry or geometries to ensure that each is valid.');
insert into sdo_geom_error values('54540','at least one element must be a surface or solid ',
'One of the geometries had holes, and the geometries were neither (A) simple, composite, or multisurfaces, or (B) simple, composite, or multisolids. (Surfaces and solids are the only geometries that can have holes. Points and curves cannot have holes.)',
'Ensure that each geometry having holes is a surface or solid (simple, composite, or multi).');
insert into sdo_geom_error values('54545','holes incorrectly defined ',
'The holes were defined with incorrect etype.',
'Ensure that the etype is correct in the definition of the inner geometry.');
insert into sdo_geom_error values('54546','volume of solid cannot be 0 or less ',
'The solid geometry having one outer and multiple inner geometries had a negative or zero volume.',
'Correct the orientation or specification of the outer solid geometry to obey outer geometry rules so that the outer geometry has a positive volume. Additionally, correct the orientation or specification of inner solid geometries to obey inner geometry rules so that each inner geometry has a negative volume.');
insert into sdo_geom_error values('54547','wrong input for COUNT_SHARED_EDGES ',
'The COUNT_SHARED_EDGES parameter value was not 1 or 2.',
'Ensure that the COUNT_SHARED_EDGES parameter value is either 1 or 2.');
insert into sdo_geom_error values('54548','input geometry gtype must be GTYPE_POLYGON for extrusion ',
'The input geometry gtype was not GTYPE_POLYGON.',
'Ensure that the gtype of the input polygon is GTYPE_POLYGON.');
insert into sdo_geom_error values('54549','input geometry has incorrect elemInfo ',
'The input 2-D polygon did not have only one outer ring.',
'Ensure that the input 2-D polygon has only one outer ring.');
insert into sdo_geom_error values('54550','input 2-D polygon not valid ',
'The 2-D polygon violated the rules for polygons and rings.',
'Correct the polygon definition.');
insert into sdo_geom_error values('54551','grdHeight and/or Height array sizes incorrect ',
'The sizes of grdHeight and Height arrays were not equal to half the size of input 2-D polygon''s ordinates array. As a result, each point in the 2-D polygon could not be extruded from the grdHeight entry to the Height entry.',
'Ensure that the sizes of the grdHeight and Height arrays are half that of input 2-D polygon ordinates array.');
insert into sdo_geom_error values('54552','height entries must be >= to ground height entries ',
'In the definition of a solid, the height values were less than the ground height.',
'Ensure that that height values are greater than or equal to ground height values.');
insert into sdo_geom_error values('54553','incorrect geometry for appending ',
'The geometry could not be appended to a homogeneous collection (for example, multi-geometry) or to a heterogeneous geometry (for example, collection). In other words, the gtype of the geometry to be appended was neither GYTPE_COLLECTION or GTYPE_MULTI-X (where X is point, curve, surface, or solid).',
'Ensure that the geometries involved in the append operation have appropriate gtypes.');
insert into sdo_geom_error values('54554','arcs are not supported as defined ',
'An arc was defined in a geometry type in which arcs are not supported. Arcs are supported for 2-D (circle) polygons, 2-D compound polygons, 2-D single arc, and 2-D compound (composite) curves only.',
'Remove or simplify the arcs.');
insert into sdo_geom_error values('54555','invalid geometry dimension ',
'The geometry did not have three dimensions.',
'Ensure that geometry has three dimensions.');
insert into sdo_geom_error values('54556','operation is not supported for 3-D geometry ',
'A 3-D geometry was passed into an operation that supports only 2-D geometries.',
'Check the Spatial documentation for operations that are supported and not supported on 3-D geometries.');
insert into sdo_geom_error values('54557','incomplete composite solid ',
'The end of composite solid was reached before all necessary solids were defined.',
'Add more solids to match the geometry definition, or reduce the specified number of solids.');
insert into sdo_geom_error values('54558','3D SRID is not found for the corresponding 2D SRID ',
'In extruding a 2D polygon into a 3D geometry, the SRID conversion function did not find an equivalent 3D SRID of the 2D SRID.',
'Specify a 2D SRID that has a 3D equivalent');
insert into sdo_geom_error values('54559','query element and source geometry cannot be the same ',
'A query element geometry and a source geometry were the same, which prevented a label pointing query element in the source geometry from being output.',
'Redefine the query element or the source geometry so that a label can be output.');
insert into sdo_geom_error values('54560','query element cannot be a collection or multitype geometry ',
'A query element was a collection geometry or a multitype geometry. Such geometries are not permitted in a query element because they are at the top of the geometry hierarchy. A query element must be part of the source geometry.',
'Redefine the query element or the source geometry so that a label can be output.');
insert into sdo_geom_error values('54601','CREATE_PC: invalid parameters for creation of Point Cloud ',
'An invalid or unknown parameter was specified in the creation of Point Cloud.',
'Check for valid set of parameters.');
insert into sdo_geom_error values('54602','CREATE_PC: input points table string does not exist ',
'The specified table for loading points into a Point Cloud did not exist.',
'Create the points table with appropriate columns, and then create the Point Cloud.');
insert into sdo_geom_error values('54603','CREATE_PC: specified total dimensionality cannot exceed 8 ',
'The specified total dimensionality for the Point Cloud exceeded the maximum limit of 8.',
'Create the Point Cloud with fewer dimensions. You can store the rest in the output points table.');
insert into sdo_geom_error values('54604','CREATE_PC: input points table should not be empty ',
'The input points table had no data.',
'Insert data into the input points table and then create the Point Cloud.');
insert into sdo_geom_error values('54605','CREATE_PC: scratch-tables/views (string) exist and need to be dropped ',
'Transient tables/views from a previous CREATE_PC operation were still in existence.',
'Delete the invalid Point Cloud from the base table (for cleanup of scratch tables), and initialize and create the Point Cloud again. Alternately, use SDO_UTIL.DROP_WORK_TABLES with oidstring as the parameter.');
insert into sdo_geom_error values('54607','CREATE_PC: error fetching data from input points table ',
'An internal read error occurred during Point Cloud creation.',
'Contact Oracle Support Services with the error number reported.');
insert into sdo_geom_error values('54608','CREATE_PC: error writing Point Cloud LOB ',
'An internal LOB write error occurred during Point Cloud creation. The cause might be lack of table space.',
'Look for information from other errors in the stack, or contact Oracle Support Services with the error number reported.');
insert into sdo_geom_error values('54609','CREATE_PC: input extent cannot be null ',
'The extent of the Point Cloud was null.',
'Specify an extent for the Point Cloud that is not null.');
insert into sdo_geom_error values('54610','CREATE_PC: input extent cannot be more than 2-D for geodetic data ',
'The extent of the Point Cloud was more than 2-D for geodetic data.',
'Change the extent to 2-D (longitude, latitude).');
insert into sdo_geom_error values('54611','INIT: either invalid basetable/schema or they do not exist ',
'The base table or schema, or both, were invalid strings, or the base table and schema combination did not exist.',
'Ensure that the specified base table exists in the specified schema before performing the initialization operation.');
insert into sdo_geom_error values('54613','INIT: internal error creating DML trigger ',
'The necessary privileges to create the trigger were not granted.',
'Grant the necessary privileges to create the trigger. If necessary, contact Oracle Support Services for help with privileges for trigger creation.');
insert into sdo_geom_error values('54614','INIT: block table name has to be unique ',
'The specified block table name was not unique. For example, it might have been used for another block table.',
'Specify a different block table name.');
insert into sdo_geom_error values('54616','INIT: internal error [number, string] ',
'An internal error occurred.','Contact Oracle Support Services.');
insert into sdo_geom_error values('54617','CLIP_PC: Invalid Point Cloud - extent is empty ',
'The input Point Cloud for the CLIP_PC operation was invalid.',
'Specify a point cloud that was created using the CREATE_PC procedure.');
insert into sdo_geom_error values('54618','CLIP_PC: SRIDs of query and Point Cloud are incompatible ',
'The Point Cloud and the query geometry had incompatible SRID values.',
'Change the query SRID to be compatible with that of the Point Cloud.');
insert into sdo_geom_error values('54619','CLIP_PC: Query and BLKID parameters cannot both be null ',
'Both the query and BLKID parameters were null in the call to the CLIP_PC operation.',
'Either specify a query geometry that is not null, or specify a BLKID for use as a query.');
insert into sdo_geom_error values('54620','CLIP_PC: internal error [number, string] ',
'An internal error occurred.',
'Contact Oracle Support Services.');
insert into sdo_geom_error values('54621','TO_GEOMETRY: TOTAL_DIMENSIONALITY not same as in INIT operation ',
'The specified TOTAL_DIMENSIONALITY was invalid.',
'Ensure that the TOTAL_DIMENSIONALITY matches that specified in the call to the initialization operation.');
insert into sdo_geom_error values('54622','TO_GEOMETRY: internal error [number, string] ',
'An internal error occurred.',
'Contact Oracle Support Services.');
insert into sdo_geom_error values('54623','CREATE_PC: internal error [number, string] ',
'An internal error occurred.',
'Contact Oracle Support Services.');
insert into sdo_geom_error values('54640','PARTITION_TABLE utility: invalid input parameters [number, string] ',
'An internal error occurred.',
'Contact Oracle Support Services.');
insert into sdo_geom_error values('54641','PARTITION_TABLE utility: scratch tables exist with oidstr = string ',
'Scratch tables/views could not be created because they already existed.',
'Use SDO_UTIL.DROP_WORK_TABLES with the specified oidstr parameter to clean up the scratch tables.');
insert into sdo_geom_error values('54642','PARTITION_TABLE utility: invalid SORT_DIMENSION specified ',
'An invalid string was specified for the SORT_DIMENSION.',
'Specify the SORT_DIMENSION as ''BEST_DIM'', ''DIMENSION_1'', ''DIMENSION_2'', or ''DIMENSION_3''.');
insert into sdo_geom_error values('54643','PARTITION_TABLE utility: invalid WORKTABLESPACE parameter ',
'An invalid string was specified for the WORKTABLESPACE parameter.',
'Specify an existing valid tablespace for WORKTABLESPACE (to hold the scratch tables).');
insert into sdo_geom_error values('54644','PARTITION_TABLE utility: error in reading input, output tables ',
'The names for the input/output tables were invalid, or the tables did not exist or did not have the right structure.',
'Check the Spatial documentation for PARTITION_TABLE.');
insert into sdo_geom_error values('54651','CREATE_TIN: invalid parameters specified in creation of TIN ',
'An invalid or unknown parameter was specified in the creation of the TIN.',
'Check the Spatial documentation for CREATE_TIN.');
insert into sdo_geom_error values('54652','CREATE_TIN: input points table string does not exist ',
'The specified table for loading points into a TIN did not exist.',
'Create the points table with appropriate columns, and then create the TIN.');
insert into sdo_geom_error values('54653','CREATE_TIN: specified total dimensionality cannot exceed 8 ',
'The specified total dimensionality for the TIN exceeded the maximum limit of 8.',
'Create the TIN with fewer dimensions. You can store the rest in the output points table.');
insert into sdo_geom_error values('54654','CREATE_TIN: input points table should not be empty ',
'The input points table had no data.',
'Insert data into the input points table, and then create the TIN.');
insert into sdo_geom_error values('54655','CREATE_TIN: scratch tables/views(string) exist and need to be dropped ',
'Transient tables from previous CREATE_TIN operation still existed.',
'Delete the invalid TIN from the base table (for cleanup of scratch tables), and initialize and create the TIN again. Alternately, use SDO_UTIL.DROP_WORK_TABLES with oidstring as its parameter.');
insert into sdo_geom_error values('54656','CREATE_TIN: error fetching data from input points table ',
'An internal read error occurred during TIN creation.',
'Contact Oracle Support Services with the error number reported.');
insert into sdo_geom_error values('54657','CREATE_TIN: error writing TIN LOB ',
'An internal LOB write error occurred during TIN creation. The cause might be lack of table space.',
'Look for information from other errors in the stack, or contact Oracle Support Services with the error number reported.');
insert into sdo_geom_error values('54658','CREATE_TIN: input extent cannot be null ',
'The extent of the TIN was null.',
'Specify an extent for the TIN that is not null.');
insert into sdo_geom_error values('54659','CREATE_TIN: input extent has to be 2-D for geodetic data ',
'The extent of the TIN was more than 2-D for geodetic data.',
'Change the extent to 2-D (longitude, latitude).');
insert into sdo_geom_error values('54660','CLIP_TIN: invalid Point Cloud - extent is empty ',
'The input TIN for the CLIP_TIN operation was invalid.',
'Specify a TIN that was created using the CREATE_TIN operation.');
insert into sdo_geom_error values('54661','CLIP_TIN: SRIDs of query and TIN are incompatible ',
'The TIN and the query geometry had incompatible SRID values.',
'Change the query geometry SRID to be compatible with that of TIN.');
insert into sdo_geom_error values('54662','CLIP_TIN: query and blkid parameters cannot both be null ',
'Both the query and blkid parameters were null in the call to the CLIP_TIN operation.',
'Either specify a query geometry that is not null, or specify a blkid for use as a query.');
insert into sdo_geom_error values('54663','CLIP_TIN: internal error [number, string] ',
'An internal error occurred.',
'Contact Oracle Support Services.');
insert into sdo_geom_error values('54664','TO_GEOMETRY: internal error [number, string] ',
'An internal error occurred.',
'Contact Oracle Support Services.');
insert into sdo_geom_error values('54665','CREATE_TIN: internal error [number, string] ',
'An internal error occurred.',
'Contact Oracle Support Services.');
insert into sdo_geom_error values('54666','query gtype is a superset of the source geometry ',
'A query element geometry was at a higher level in the geometry hierarchy than the source geometry.',
'Try replacing the source geometry with the query geometry.');
insert into sdo_geom_error values('54667','query element cannot be matched to an element in source geometry (string) ',
'A query element geometry was not a part of the source geometry.',
'Redefine the query element or the source geometry.');
insert into sdo_geom_error values('54668','a 2D SRID cannot be used with a 3D geometry ',
'A 2D SRID was used with a 3D geometry.',
'Replace the 2D SRID with an appropriate 3D SRID.');
insert into sdo_geom_error values('TRUE','No errors','Nothing to do','No errors');
commit;
SET FEEDBACK ON
SET HEADING OFF
select 'Inserted '||count(*)||' records into sdo_geom_error' 
  from sdo_geom_error;
SET HEADING ON
create index sdo_geom_error_ndx on sdo_geom_error(code);
grant select on sdo_geom_error to public;
SET FEEDBACK ON TIMING ON
EXIT;
