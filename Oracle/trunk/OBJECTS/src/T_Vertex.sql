DEFINE INSTALL_SCHEMA='&1'

SET VERIFY OFF;

CREATE OR REPLACE TYPE &&INSTALL_SCHEMA..T_VERTEX 
AUTHID DEFINER
AS OBJECT (

/****t* OBJECT TYPE/T_VERTEX
*  NAME
*    T_VERTEX -- Represents a single coordinate object with variable ordinate dimensions.
*  DESCRIPTION
*    An object type that represents a single vertex/coordinate of a geometry object.
*    Includes Methods on that type.
*  NOTE
*    T_Vertex is provided for two reasons:
*      1. The mdsys constructor for MDSYS.VERTEX_TYPE has changed with each version, making code stability an issue.
*      2. This object allows for the provision of specific methods on a single vertex.
*  AUTHOR
*    Simon Greener
*  HISTORY
*    Simon Greener - Jan 2013 - Original coding.
*  COPYRIGHT
*    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
******/

  /****v* T_VERTEX/ATTRIBUTES(T_VERTEX)
  *  ATTRIBUTES
  *    X         -- X Ordinate
  *    Y         -- Y Ordinate
  *    Z         -- Z Ordinate
  *    W         -- W Ordinate (Normally Measure)
  *    ID        -- Identifier
  *    sdo_gtype -- Geometry Type of Vertex
  *    sdo_srid  -- Spatial Reference ID of Vertex
  *    deleted   -- Flag for use in collections like varrays or T_Vertices
  *  SOURCE
  */
  x         number,
  y         number,
  z         number,
  w         number,
  id        integer,
  sdo_gtype integer,
  sdo_srid  integer,
  deleted   integer,
  /*******/

  /****m* T_VERTEX/CONSTRUCTORS(T_VERTEX)
  *  NAME
  *    A collection of T_VERTEX Constructors.
  *  SOURCE
  */
  Constructor Function T_Vertex( SELF IN OUT NOCOPY T_Vertex)
       Return Self As Result,

  Constructor Function T_Vertex( SELF    IN OUT NOCOPY T_Vertex,
                                 p_vertex In &&INSTALL_SCHEMA..T_vertex )
       Return Self As Result,

  Constructor Function T_Vertex( SELF    IN OUT NOCOPY T_Vertex,
                                 p_point in mdsys.sdo_geometry )
       Return Self As Result,

 /*  EXAMPLE
  *    SELECT t.id,
  *           TRIM(BOTH ' ' FROM t.token) as token,
  *           T_VERTEX(p_coord_string => TRIM(BOTH ' ' FROM t.token),
  *                    p_id           => t.id,
  *                    p_sdo_srid     => null)
  *             .ST_AsText() as vertex
  *      FROM table(tools.tokenizer('1.1 -2.1 3.47, 10 0 2,10 5 3,10 10 4,5 10 5,5 5 6',',')) t
  *    ORDER BY t.id;
  *
  *    ID TOKEN         VERTEX
  *    -- ------------- ----------------------------------------------------------
  *     1 1.1 -2.1 3.47 T_Vertex(X=1.1,Y=-2.1,Z=3.47,W=0.0,ID=1,GT=3001,SRID=NULL)
  *     2 10 0 2        T_Vertex(X=10.0,Y=0.0,Z=2.0,W=0.0,ID=2,GT=3001,SRID=NULL)
  *     3 10 5 3        T_Vertex(X=10.0,Y=5.0,Z=3.0,W=0.0,ID=3,GT=3001,SRID=NULL)
  *     4 10 10 4       T_Vertex(X=10.0,Y=10.0,Z=4.0,W=0.0,ID=4,GT=3001,SRID=NULL)
  *     5 5 10 5        T_Vertex(X=5.0,Y=10.0,Z=5.0,W=0.0,ID=5,GT=3001,SRID=NULL)
  *     6 5 5 6         T_Vertex(X=5.0,Y=5.0,Z=6.0,W=0.0,ID=6,GT=3001,SRID=NULL)
  *
  *     6 rows selected
  *
  *    SELECT t.id,
  *             TRIM(BOTH ' ' FROM t.token) as token,
  *             T_VERTEX(TRIM(BOTH ' ' FROM t.token),
  *                      t.id,
  *                      null)
  *               .ST_AsText() as vertex
  *        FROM table(tools.tokenizer(
  *                     '1.1 -2.1 3.47 1.0,10 0 2 2.1,10 5 3 3,10 10 4 4.1,5 10 5 5.1,5 5 6 6.1',',')) t
  *      ORDER BY t.id;
  *
  *            ID TOKEN             VERTEX
  *    ---------- ----------------- ------------------------------------------------------------
  *             1 1.1 -2.1 3.47 1.0 T_Vertex(X=1.1,Y=-2.1,Z=3.47,W=1.0,ID=1,GT=4401,SRID=NULL)
  *             2 10 0 2 2.1        T_Vertex(X=10.0,Y=0.0,Z=2.0,W=2.1,ID=2,GT=4401,SRID=NULL)
  *             3 10 5 3 3          T_Vertex(X=10.0,Y=5.0,Z=3.0,W=3.0,ID=3,GT=4401,SRID=NULL)
  *             4 10 10 4 4.1       T_Vertex(X=10.0,Y=10.0,Z=4.0,W=4.1,ID=4,GT=4401,SRID=NULL)
  *             5 5 10 5 5.1        T_Vertex(X=5.0,Y=10.0,Z=5.0,W=5.1,ID=5,GT=4401,SRID=NULL)
  *             6 5 5 6 6.1         T_Vertex(X=5.0,Y=5.0,Z=6.0,W=6.1,ID=6,GT=4401,SRID=NULL)
  *
  *     6 rows selected
  */
  Constructor Function T_Vertex( SELF           IN OUT NOCOPY T_Vertex,
                                 p_coord_string in varchar2,
                                 p_id           in integer default 1,
                                 p_sdo_srid     in integer default null)
       Return Self as result,

  Constructor Function T_Vertex( SELF        IN OUT NOCOPY T_Vertex,
                                 p_id        in integer,
                                 p_sdo_gtype in integer default 2001,
                                 p_sdo_srid  in integer default NULL)
       Return Self as result,

  Constructor Function T_Vertex( SELF        IN OUT NOCOPY T_Vertex,
                                 p_x         In number,
                                 p_y         In number)
       Return Self As Result,

  Constructor Function T_Vertex( SELF        IN OUT NOCOPY T_Vertex,
                                 p_x         In number,
                                 p_y         In number,
                                 p_id        In integer,
                                 p_sdo_gtype in integer,
                                 p_sdo_srid  in integer)
       Return Self As Result,

  Constructor Function T_Vertex( SELF        IN OUT NOCOPY T_Vertex,
                                 p_x         In number,
                                 p_y         In number,
                                 p_z         In number,
                                 p_id        In integer,
                                 p_sdo_gtype in integer,
                                 p_sdo_srid  in integer)
       Return Self As Result,

  Constructor Function T_Vertex( SELF        IN OUT NOCOPY T_Vertex,
                                 p_x         In number,
                                 p_y         In number,
                                 p_z         In number,
                                 p_w         In number,
                                 p_id        In integer,
                                 p_sdo_gtype in integer,
                                 p_sdo_srid  in integer)
       Return Self As Result,

  Constructor Function T_Vertex( SELF        IN OUT NOCOPY T_Vertex,
                                 p_vertex    In mdsys.vertex_type,
                                 p_sdo_gtype in integer default 2001,
                                 p_sdo_srid  in integer default null)
       Return Self As Result,

  Constructor Function T_Vertex( SELF        IN OUT NOCOPY T_Vertex,
                                 p_vertex    In mdsys.vertex_type,
                                 p_id        In integer,
                                 p_sdo_gtype in integer default 2001,
                                 p_sdo_srid  in integer default null)
       Return Self As Result,

  Constructor Function T_Vertex( SELF        IN OUT NOCOPY T_Vertex,
                                 p_point     in mdsys.sdo_point_type,
                                 p_sdo_gtype in integer default 2001,
                                 p_sdo_srid  in integer default null)
       Return Self as result,
  /*******/


  /* ********************* Member Functions ********************* */

 /****m* T_VERTEX/INSPECTORS(T_VERTEX)
  *  NAME
  *    A collection of T_VERTEX variable inspectors.
  *  DESCRIPTION
  *    ST_X, ST_Y, ST_Z, ST_W return the relevant (z,y,z,w) underlying ordinate property values.
  *    ST_ID returns the value given to the ID property.
  *    ST_SRID returns the value given to the sdo_srid property.
  *    ST_Sdo_Gtype returns the value given to the sdo_gtype property (see also ST_Dims()).
  *  SOURCE
  */
  Member Function ST_X          Return Number  Deterministic,
  Member Function ST_Y          Return Number  Deterministic,
  Member Function ST_Z          Return Number  Deterministic,
  Member Function ST_W          Return Number  Deterministic,
  Member Function ST_M          Return Number  Deterministic,
  Member Function ST_ID         Return integer Deterministic,
  Member Function ST_SRID       Return integer Deterministic,
  Member Function ST_SDO_GTYPE  Return integer Deterministic,
  Member Function ST_IsDeleted  Return integer Deterministic,
  Member Function ST_IsMeasured Return integer Deterministic,
  /*******/

  /****m* T_VERTEX/ST_Self
  *  NAME
  *    ST_Self -- Handy method for use with TABLE(T_Vertices) to return element as T_Vertex object.
  *  SYNOPSIS
  *    Member Function ST_Self
  *             Return T_Vertex Deterministic,
  *  DESCRIPTION
  *    When extracting vertices from a geometry into T_Vertex objects via a TABLE function call to T_GEOMETRY.T_Vertices()
  *    it is handy to have a method which allows access to the resulting T_VERTEX row as a single object. 
  *    In a sense this method allows access similar to t.COLUMN_VALUE for atmoic datatype access from TABLE functions.
  *  RESULT
  *    vertex (T_VERTEX) -- A single T_Vertex object.
  *  EXAMPLE
  *    set serveroutput on
  *    BEGIN
  *      FOR rec IN (select v.id, v.ST_Self() as vertex
  *                    from table(t_geometry(
  *                                 SDO_GEOMETRY(2002,28355,NULL,
  *                                     SDO_ELEM_INFO_ARRAY(1,2,1),
  *                                     SDO_ORDINATE_ARRAY(252282.861,5526962.496,252282.861,5526882.82, 252315.91,5526905.639, 252287.189,5526942.228)) )
  *                               .ST_Vertices()) v
  *                  )
  *      LOOP
  *        dbms_output.put_line(rec.id || ' => ' || rec.vertex.ST_AsText());
  *      END LOOP;
  *    END;
  *    /
  *    anonymous block completed
  *    1 => T_Vertex(X=252282.9,Y=5526962.5,Z=NULL,W=NULL,ID=1,GT=2001,SRID=28355)
  *    2 => T_Vertex(X=252282.9,Y=5526882.8,Z=NULL,W=NULL,ID=2,GT=2001,SRID=28355)
  *    3 => T_Vertex(X=252315.9,Y=5526905.6,Z=NULL,W=NULL,ID=3,GT=2001,SRID=28355)
  *    4 => T_Vertex(X=252287.2,Y=5526942.2,Z=NULL,W=NULL,ID=4,GT=2001,SRID=28355)
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - September 2018 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Self
           Return &&INSTALL_SCHEMA..T_Vertex Deterministic,

  Member Procedure ST_SetCoordinate(
           SELF  IN OUT NOCOPY T_Vertex,
           p_x   in number,
           p_y   in number,
           p_z   in number default null,
           p_w   in number default null
         ),
  
  Member Procedure ST_SetDeleted(SELF      IN OUT NOCOPY T_Vertex,
                                 p_deleted IN INTEGER DEFAULT 1),
  /****m* T_VERTEX/ST_isEmpty
  *  NAME
  *    ST_isEmpty -- Checks if Vertex data exists or not.
  *  SYNOPSIS
  *    Member Function ST_isEmpty
  *             Return Integer Deterministic,
  *  DESCRIPTION
  *    If vertex object data are not null returns 1(True) else 0 (False).
  *    cf "POINT EMPTY" WKT
  *  RESULT
  *    BOOLEAN (INTEGER) -- 1 if vertex has not values; 0 if has values
  *  EXAMPLE
  *    select t_vertex().ST_isEmpty() as isEmpty,
  *           t_vertex(
  *             p_id => 0,
  *             p_x  => 0.0,
  *             p_y  => 0.0,
  *             p_sdo_gtype => 2001,
  *             p_sdo_srid  => NULL
  *           )
  *           .ST_isEmpty() as vIsEmpty
  *      from dual;
  *    
  *    ISEMPTY VISEMPTY
  *    ------- --------
  *          1        0 
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_isEmpty
         Return integer Deterministic,

  /****m* T_VERTEX/ST_Dims
  *  NAME
  *    ST_Dims -- Returns number of ordinate dimensions
  *  SYNOPSIS
  *    Member Function ST_Dims
  *             Return Integer Deterministic,
  *  DESCRIPTION
  *    Examines SDO_GTYPE (2XXX etc) and extracts coordinate dimensions.
  *    If SDO_GTYPE is null, examines ordinates eg XY not null, Z null -> 2.
  *  RESULT
  *    BOOLEAN (INTEGER) -- 2 if data 2D; 3 if 3D; 4 if 4D
  *  EXAMPLE
  *    select t_vertex().ST_Dims() as eDims,
  *           t_vertex(
  *             p_id => 0,
  *             p_x  => 0.0,
  *             p_y  => 0.0,
  *             p_z  => 0.0,
  *             p_sdo_gtype => 3001,
  *             p_sdo_srid  => NULL
  *           )
  *           .ST_Dims() as dims
  *      from dual;
  *    
  *    EDIMS DIMS
  *    ----- ----
  *        2    3 
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Dims
         Return integer Deterministic,

  /****m* T_VERTEX/ST_hasZ
  *  NAME
  *    ST_hasZ -- Tests vertex to see if coordinates include a Z ordinate.
  *  SYNOPSIS
  *    Member Function ST_hasZ
  *             Return Integer Deterministic,
  *  DESCRIPTION
  *    Examines SDO_GTYPE (DLNN etc). If D position is 2 then vertex does not have a Z ordinate.
  *    If D position is 3 and measure ordinate position (L) is 0 then vertex has Z ordinate.
  *    If D position is 3 and measure ordinate position (L) is not equal to 0 then vertex does not have a Z ordinate.
  *    If D position is 4 and measure ordinate position (L) is equal to 0 or equal to D (4) then vertex has a Z ordinate.
  *    If D position is 4 and measure ordinate position (L) is equal to 3 then vertex does not have a Z ordinate.
  *    If SDO_GTYPE is null, examines Z and W ordinates of the vertex's coordinates to determine if vertex has Z ordinate.
  *  RESULT
  *    BOOLEAN (INTEGER) -- 1 is has Z ordinate, 0 otherwise.
  *  EXAMPLE
  *    select t_vertex().ST_hasZ() as eZ,
  *           t_vertex(
  *             p_id => 0,
  *             p_x  => 0.0,
  *             p_y  => 0.0,
  *             p_sdo_gtype => 2001,
  *             p_sdo_srid  => NULL
  *           )
  *           .ST_Dims() as dims2,
  *           t_vertex(
  *             p_id => 0,
  *             p_x  => 0.0,
  *             p_y  => 0.0,
  *             p_z  => 0.0,
  *             p_sdo_gtype => 3001,
  *             p_sdo_srid  => NULL
  *           )
  *           .ST_Dims() as dims3
  *      from dual;
  *    
  *            EZ      DIMS2      DIMS3
  *    ---------- ---------- ----------
  *             0          2          3 
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_hasZ
         Return integer Deterministic,

  /****m* T_VERTEX/ST_HasM
  *  NAME
  *    ST_HasM -- Tests vertex to see if coordinates include a measure.
  *  SYNOPSIS
  *    Member Function ST_HasM
  *             Return Integer Deterministic,
  *  DESCRIPTION
  *    Examines SDO_GTYPE (DLNN etc) to see if sdo_gtype has measure ordinate eg 3302 not 3002.
  *    If SDO_GTYPE is null, examines coordinates to see if W ordinate is not null.
  *  RESULT
  *    BOOLEAN (INTEGER) -- 1 is measure ordinate exists, 0 otherwise.
  *  EXAMPLE
  *    select t_vertex().ST_hasM() as eM,
  *           t_vertex(
  *             p_id => 0,
  *             p_x  => 0.0,
  *             p_y  => 0.0,
  *             p_sdo_gtype => 2001,
  *             p_sdo_srid  => NULL
  *           )
  *           .ST_hasM() as hasM2,
  *           t_vertex(
  *             p_id => 0,
  *             p_x  => 0.0,
  *             p_y  => 0.0,
  *             p_z  => 0.0,
  *             p_sdo_gtype => 3301,
  *             p_sdo_srid  => NULL
  *           )
  *           .ST_hasM() as hasM3
  *      from dual;
  *      
  *    EM HASM2 HASM3
  *    -- ----- -----
  *     0     0     1
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_HasM
         Return integer Deterministic,

  /****m* T_VERTEX/ST_Lrs_Dim
  *  NAME
  *    ST_Lrs_Dim -- Tests vertex to see if coordinates include a measure ordinate and returns measure ordinate's position.
  *  SYNOPSIS
  *    Member Function ST_Lrs_Dim
  *             Return Integer Deterministic,
  *  DESCRIPTION
  *    Examines SDO_GTYPE (DLNN etc) measure ordinate position (L) and returns it.
  *    If SDO_GTYPE is null, examines coordinates to see if W ordinate is not null.
  *  RESULT
  *    BOOLEAN (INTEGER) -- L from DLNN.
  *  EXAMPLE
  *    select t_vertex().ST_LRS_Dim() as eLrsDim,
  *           t_vertex(
  *             p_id => 0,
  *             p_x  => 0.0,
  *             p_y  => 0.0,
  *             p_sdo_gtype => 2001,
  *             p_sdo_srid  => NULL
  *           )
  *           .ST_LRS_Dim() as lrsDim2,
  *           t_vertex(
  *             p_id => 0,
  *             p_x  => 0.0,
  *             p_y  => 0.0,
  *             p_z  => 0.0,
  *             p_sdo_gtype => 3301,
  *             p_sdo_srid  => NULL
  *           )
  *           .ST_LRS_Dim() as lrsDim3
  *      from dual;
  *    
  *    ELRSDIM LRSDIM2 LRSDIM3
  *    ------- ------- -------
  *          0       0       3 
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Lrs_Dim
         Return Integer Deterministic,

  -- ******************* Set and Calculation functions

  /****m* T_VERTEX/ST_LRS_Set_Measure
  *  NAME
  *    ST_LRS_Set_Measure -- Sets measure attribute, adjusts sdo_gtype.
  *  SYNOPSIS
  *    Member Function ST_LRS_Set_Measure(p_measure in number)
  *             Return T_Vertex Deterministic,
  *  DESCRIPTION
  *    This function sets the W or Z ordinate the the supplied measure value
  *    depending on the dimensionality of the vertex and its LRS dimension (see ST_LRS_Dim()).
  *    Can change dimensionality of underlying T_Vertex object for example if already 3D,
  *    with Z, but unmeasured: result will be vertex with 4401 sdo_gtype.
  *  PARAMETERS
  *    p_measure (number) - New Measure value.
  *  RESULT
  *    vertex (T_VERTEX)
  *  EXAMPLE
  *    -- ST_LRS_Set_Measure
  *    select t_vertex(
  *             p_id => 0,
  *             p_x  => 0.0,
  *             p_y  => 0.0,
  *             p_sdo_gtype => 2001,
  *             p_sdo_srid  => NULL
  *           )
  *           .ST_LRS_Set_Measure(2.1)
  *           .ST_AsText() as new3301Vertex,
  *           t_vertex(
  *             p_id => 0,
  *             p_x  => 0.0,
  *             p_y  => 0.0,
  *             p_z  => 0.0,
  *             p_sdo_gtype => 3001,
  *             p_sdo_srid  => NULL
  *           )
  *           .ST_LRS_Set_Measure(1.2)
  *           .ST_AsText() as new4401Vertex
  *      from dual;
  *    
  *    NEW3301VERTEX                                         NEW4401VERTEX
  *    ----------------------------------------------------- --------------------------------------------------
  *    T_Vertex(X=0,Y=0,Z=2.1,W=NULL,ID=0,GT=3301,SRID=NULL) T_Vertex(X=0,Y=0,Z=0,W=1.2,ID=0,GT=4401,SRID=NULL)
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_LRS_Set_Measure(p_measure in number)
           Return &&INSTALL_SCHEMA..T_Vertex Deterministic,

  /****m* T_VERTEX/ST_To2D
  *  NAME
  *    ST_To2D -- Removes and Z or measured attributes, adjusts sdo_gtype.
  *  SYNOPSIS
  *    Member Function ST_To2D
  *             Return T_Vertex Deterministic,
  *  DESCRIPTION
  *    Changes dimensionality of underlying T_Vertex object.
  *    If Vertex is 2D the vertex is returned unchanged.
  *    If the Vertex is 3D or 4D, any Z or W (measure) will be removed; sdo_gtype is set to 2001.
  *  RESULT
  *    vertex (T_VERTEX)
  *  EXAMPLE
  *    -- ST_To2D
  *    select t_vertex(
  *             p_id => 0,
  *             p_x  => 1.0,
  *             p_y  => 2.0,
  *             p_z  => 3.0,
  *             p_w  => 4.0,
  *             p_sdo_gtype => 4401,
  *             p_sdo_srid  => NULL
  *           )
  *           .ST_To2D()
  *           .ST_AsText() as Vertex2D
  *      from dual;
  *    
  *    VERTEX2D
  *    ------------------------------------------------------
  *    T_Vertex(X=1,Y=2,Z=NULL,W=NULL,ID=0,GT=2001,SRID=NULL)
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_To2D
           Return &&INSTALL_SCHEMA..T_Vertex Deterministic,

  /****m* T_VERTEX/ST_To3D
  *  NAME
  *    ST_To3D -- Adds Z attribute, adjusts sdo_gtype.
  *  SYNOPSIS
  *    Member Function ST_To3D(p_keep_measure in integer,
  *                            p_default_z    in number)
  *             Return T_Vertex Deterministic,
  *  DESCRIPTION
  *    Changes dimensionality of underlying T_Vertex object.
  *    If Vertex is 3D the vertex is returned unchanged unless the vertex is additionally measured
  *    and p_keep_measure = 1. In that case, the Z ordinate will be set to the W (measure) value
  *    and the W (measure) value set to NULL.
  *    If Vertex is 2D the vertex is changed to 3D and the Z ordinate set to p_default_z.
  *    If the Vertex is 4D, any W (measure) is removed unless p_keep_measure is set to 1;
  *    If p_keep_measure is 1, the W value is copied to the Z ordinate and the W ordinate set to null.
  *    The sdo_gtype of the returned vertex is always 3001.
  *  PARAMETERS
  *    p_keep_measure (integer) - If vertex has a measure value, this parameter instructs the function to keep it.
  *    p_default_z    (number)  - If a Z value has to be created (eg in case of 2D vertex being converted to 3D),
  *                               this parameter holds the new value for that ordinate.
  *  RESULT
  *    vertex (T_VERTEX)
  *  EXAMPLE
  *
  *    -- ST_To3D
  *    With Data as (
  *      select t_vertex(
  *               p_id        => 0,
  *               p_x         => 1.0,
  *               p_y         => 2.0,
  *               p_sdo_gtype => 2001,
  *               p_sdo_srid  => NULL
  *             )  as Vertex2D
  *      from dual
  *    )
  *    select a.vertex2D
  *            .ST_To3D(p_keep_measure => 0,
  *                     p_default_z    => 3.0)
  *            .ST_LRS_Set_Measure(4.0)
  *            .ST_AsText() as vertex3
  *      from data a;
  *    
  *    VERTEX3
  *    ------------------------------------------------
  *    T_Vertex(X=1,Y=2,Z=3,W=4,ID=0,GT=4401,SRID=NULL)
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_To3D(p_keep_measure in integer,
                          p_default_z    in number)
           Return &&INSTALL_SCHEMA..T_Vertex Deterministic,

  /****m* T_VERTEX/ST_VertexType
  *  NAME
  *    ST_VertexType -- Returns vertex ordinates as a MDSYS.VERTEX_TYPE object.
  *  SYNOPSIS
  *    Member Function ST_VertexType
  *             Return MDSYS.VERTEX_TYPE Deterministic,
  *  DESCRIPTION
  *    Constructs a MDSYS.VERTEX_TYPE object from the ordinate variables of the type and returns it.
  *  RESULT
  *    vertex (MDSYS.VERTEX_TYPE) -- eg MDSYS.VERTEX_TYPE(x=>SELF.ST_X,y=>SELF.ST_Y,z=>SELF.ST_Z,w=>SELF.ST_W,id=>SELF.ST_Id);
  *  EXAMPLE
  *    -- ST_ToVertexType
  *    select t_vertex(
  *               p_id        => 0,
  *               p_x         => 1.0,
  *               p_y         => 2.0,
  *               p_z         => 3.0,
  *               p_w         => 4.0,
  *               p_sdo_gtype => 4401,
  *               p_sdo_srid  => NULL
  *             ).ST_VertexType()  as VertexType
  *    from dual;
  *    
  *    VERTEXTYPE
  *    ---------------------------------------------------------------
  *    MDSYS.VERTEX_TYPE(1,2,3,4,NULL,NULL,NULL,NULL,NULL,NULL,NULL,0)
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_VertexType
         Return mdsys.vertex_type Deterministic,

  /****m* T_VERTEX/ST_SdoPointType
  *  NAME
  *    ST_SdoPointType -- Returns vertex X,Y and Z ordinates as a MDSYS.SDO_POINT_TYPE object.
  *  SYNOPSIS
  *    Member Function ST_SdoPointType
  *             Return MDSYS.SDO_POINT_TYPE Deterministic,
  *  DESCRIPTION
  *    Constructs a MDSYS.SDO_POINT_TYPE object from the X, Y and Z ordinate variables of the type and returns it.
  *    If Vertex is 2D Z value will be NULL; if vertex dimension is > 3 only the X Y and Z ordinates are returned.
  *  RESULT
  *    vertex (MDSYS.SDO_POINT_TYPE) -- eg MDSYS.SDO_POINT_TYPE(SELF.ST_X,SELF.ST_Y,SELF.ST_Z);
  *  EXAMPLE
  *    -- ST_ToVertexType
  *    select t_vertex(
  *               p_id        => 0,
  *               p_x         => 1.0,
  *               p_y         => 2.0,
  *               p_z         => 3.0,
  *               p_w         => 4.0,
  *               p_sdo_gtype => 4401,
  *               p_sdo_srid  => NULL
  *             ).ST_SdoPointType()  as sdo_point_type
  *    from dual;
  *    
  *    SDO_POINT_TYPE
  *    ---------------------------
  *    MDSYS.SDO_POINT_TYPE(1,2,3)
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_SdoPointType
         Return mdsys.sdo_point_type Deterministic,

  /****m* T_VERTEX/ST_Bearing
  *  NAME
  *    ST_Bearing -- Returns bearing from SELF to supplied T_Vertex.
  *  SYNOPSIS
  *    Member Function ST_Bearing(p_vertex    in &&INSTALL_SCHEMA..T_Vertex,
  *                               p_projected in integer default 1,
  *                               p_normalize in integer default 1 )
  *             Return Number Deterministic
  *  DESCRIPTION
  *    This function computes a bearing from the current object point (SELF) to the supplied T_Vertex.
  *    Result is in degrees.
  *    Use static function TOOLS.ST_Degrees to return as a whole circle bearing.
  *    Geodetic calculations are used if p_projected = 0, otherwise planar calculations are used.
  *    If p_normlize is true (1), the resulting bearing is normalised to a value between 0.360.
  *  PARAMETERS
  *    p_vertex (T_VERTEX)   -- A Vertex to which a bearing is calculated.
  *    p_projected (integer) -- Usually called from T_GEOMETRY with SELF.projected.
  *                             If either 1 for Projected/Planar and 0 for Geographic/Geodetic.
  *                             If NULL, TOOLS.ST_GetSridType is called.
  *    p_normalize (integer) -- If 1 computed bearing is normalized to a value between 0..360 degrees.
  *  RESULT
  *    Bearing (Number) -- Bearing in Degrees.
  *  EXAMPLE
  *    -- Simple bearing for projected data
  *    select round(
  *             T_Vertex(
  *             sdo_geometry('POINT(0 0)',NULL)
  *           )
  *           .ST_Bearing(
  *               T_Vertex(
  *                 sdo_geometry('POINT(10 10)',NULL)
  *               ),
  *               p_projected=>1,
  *               p_normalize=>1
  *           ),8) as bearing
  *      from dual;
  *    
  *    BEARING
  *    -------
  *         45
  *
  *    -- Simple geodetic bearing (2D)
  *    select  COGO.DD2DMS(
  *             T_Vertex(
  *               sdo_geometry('POINT(147.5 -42.5)',4283)
  *             )
  *             .ST_Bearing(
  *                 T_Vertex(
  *                   sdo_geometry('POINT(147.6 -42.5)',4283)
  *                 ),
  *                 p_projected=>0,
  *                 p_normalize=>1
  *             )
  *           ) as bearing
  *      from dual;
  *
  *    BEARING
  *    -------------
  *    90°02'01.606"
  *  SEE ALSO
  *    ST_Degrees.
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Bearing(p_vertex    in &&INSTALL_SCHEMA..T_Vertex,
                             p_projected in integer default 1,
                             p_normalize in integer default 1)
           Return Number Deterministic,

  /****m* T_VERTEX/ST_Distance
  *  NAME
  *    ST_Distance -- Returns distance from current vertex (SELF) to supplied T_Vertex.
  *  SYNOPSIS
  *    Member Function ST_Distance(p_vertex    in &&INSTALL_SCHEMA..T_Vertex,
  *                                p_tolerance in number   default 0.05,
  *                                p_unit      in varchar2 default NULL)
  *             Return Number Deterministic
  *  DESCRIPTION
  *    This function computes a distance from the current object point (SELF) to the supplied T_Vertex.
  *    Result is in the distance units of the SDO_SRID, or in p_units where supplied.
  *  PARAMETERS
  *    p_vertex  (T_VERTEX) - A Vertex to which a bearing is calculated.
  *    p_tolerance (NUMBER) - sdo_tolerance for use with sdo_geom.sdo_distance.
  *    p_unit    (VARCHAR2) - Oracle Unit of Measure eg unit=M.
  *  RESULT
  *    distance (Number) -- Distance in SRID unit of measure or in supplied units (p_unit)
  *  EXAMPLE
  *    -- Planar in Meters
  *    select Round(
  *             T_Vertex(
  *               sdo_geometry('POINT(0 0)',NULL)
  *             )
  *             .ST_Distance(
  *                 p_vertex   => T_Vertex(
  *                                 sdo_geometry('POINT(10 10)',NULL)
  *                               ),
  *                 p_tolerance=> 0.05
  *             ),
  *             3
  *           ) as distance
  *      from dual;
  *
  *    DISTANCE
  *    ----------
  *        14.142
  *    
  *    -- Geodetic In Kilometers
  *    select Round(
  *             T_Vertex(
  *               sdo_geometry('POINT(147.5 -42.5)',4283)
  *             )
  *             .ST_Distance(
  *                 p_Vertex   => T_Vertex(
  *                                 sdo_geometry('POINT(147.6 -42.5)',4283)
  *                               ),
  *                 p_tolerance=> 0.05,
  *                 p_unit     => 'unit=KM'
  *             ),
  *             4
  *           ) as distance
  *      from dual;
  *    
  *      DISTANCE
  *    ----------
  *        8.2199
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Distance(p_vertex    in &&INSTALL_SCHEMA..T_Vertex,
                              p_tolerance in number   default 0.05,
                              p_unit      in varchar2 default NULL)
           Return number Deterministic,

  /****m* T_VERTEX/ST_FromBearingAndDistance
  *  NAME
  *    ST_FromBearingAndDistance -- Returns new T_Vertex given bearing and distance.
  *  SYNOPSIS
  *    Member Function ST_FromBearingAndDistance(p_bearing   in number,
  *                                              p_distance  in number,
  *                                              p_projected in integer default 1)
  *             Return T_Vertex Deterministic
  *  DESCRIPTION
  *    This function computes a new T_VERTEX computed from current object point (SELF)
  *    the supplied bearing and distance.
  *    Geodetic calculations are used if p_projected = 0, otherwise planar calculations are used.
  *  PARAMETERS
  *    p_bearing    (NUMBER) -- A whole circle bearing in radians.
  *    p_distance   (NUMBER) -- Distance expressed in Oracle Unit of Measure eg METER.
  *    p_projected (integer) -- Usually called from T_GEOMETRY with SELF.projected.
  *                             If either 1 for Projected/Planar and 0 for Geographic/Geodetic.
  *                             If NULL, TOOLS.ST_GetSridType is called.
  *  RESULT
  *    vertexx (T_VERTEX) -- New vertex computed using bearing and distance from current object.
  *  EXAMPLE
  *    -- Planar in Meters
  *    select T_Vertex(
  *               sdo_geometry('POINT(0 0)',NULL)
  *             )
  *             .ST_FromBearingAndDistance(
  *                p_bearing   => 45.0,
  *                p_distance  => 14.142,
  *                p_projected => 1
  *             )
  *             .ST_Round(3)
  *             .ST_AsText() as vertex
  *      from dual;
  *    
  *    VERTEX
  *    --------------------------------------------------------
  *    T_Vertex(X=10,Y=10,Z=NULL,W=NULL,ID=1,GT=2001,SRID=NULL)
  *    
  *    -- Geodetic with distance in meters
  *    select T_Vertex(
  *             sdo_geometry('POINT(147.5 -42.5)',4283)
  *           )
  *           .ST_FromBearingAndDistance (
  *               p_bearing   => COGO.DMS2DD('90°02''01.606"'),
  *               p_distance  => 8219.9,
  *               p_projected => 0
  *           )
  *           .ST_Round(6)
  *           .ST_AsText() as vertex
  *      from dual;
  *    
  *    VERTEX
  *    -----------------------------------------------------------------
  *    T_Vertex(X=147.6,Y=-42.5,Z=NULL,W=NULL,ID=NULL,GT=2001,SRID=4283)
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_FromBearingAndDistance(p_Bearing   in number,
                                            p_Distance  in number,
                                            p_projected in integer default 1)
           Return &&INSTALL_SCHEMA..T_Vertex Deterministic,

  /* ================= Useful Math Functions for Circle ===================*/

  Member Function ST_Add(p_vertex in &&INSTALL_SCHEMA..T_Vertex)
           Return &&INSTALL_SCHEMA..T_Vertex Deterministic,

  Member Function ST_Normal
           Return &&INSTALL_SCHEMA..T_Vertex Deterministic,

  Member Function ST_Subtract(p_vertex in &&INSTALL_SCHEMA..T_Vertex)
           Return &&INSTALL_SCHEMA..T_Vertex Deterministic,

  Member Function ST_Scale(p_scale in number default 1)
           Return &&INSTALL_SCHEMA..T_Vertex Deterministic,

  /****m* T_VERTEX/ST_SubtendedAngle
  *  NAME
  *    ST_SubtendedAngle -- Returns angle subtended by p_start_vertex/SELF/p_end_vertex
  *  SYNOPSIS
  *    Member Function ST_SubtendedAngle(p_start_vertex in &&INSTALL_SCHEMA..T_Vertex,
  *                                      p_end_vertex   in &&INSTALL_SCHEMA..T_Vertex)
  *             Return Number deterministic
  *  DESCRIPTION
  *    This function computes the angle subtended by the three points:
  *    p_start_vertex ---> SELF ---> p_end_vertex
  *  PARAMETERS
  *    p_start_vertex (T_VERTEX) -- Vertex that defines first point in angle.
  *    p_end_vertex   (T_VERTEX) -- Vertex that defines last  point in angle.
  *    p_projected     (integer) -- Usually called from T_GEOMETRY with SELF.projected.
  *                                 If either 1 for Projected/Planar and 0 for Geographic/Geodetic.
  *                                 If NULL, TOOLS.ST_GetSridType is called.
  *  RESULT
  *    angle (NUMBER) - Subtended angle in radians.
  *  EXAMPLE
  *    -- Planar in Meters
  *    select Round(
  *           COGO.ST_Degrees(
  *             T_Vertex(
  *               p_id => 1,
  *               p_x  => 0,
  *               p_y  => 0,
  *               p_sdo_gtype=> 2001,
  *               p_sdo_srid => NULL
  *             )
  *             .ST_SubtendedAngle(
  *                 T_Vertex(
  *                    p_id => 2,
  *                    p_x  => 10,
  *                    p_y  => 0,
  *                    p_sdo_gtype=> 2001,
  *                    p_sdo_srid => NULL
  *                 ),
  *                 T_Vertex(
  *                    p_id => 3,
  *                    p_x  => 10,
  *                    p_y  => 10,
  *                    p_sdo_gtype=> 2001,
  *                    p_sdo_srid => NULL
  *                 )
  *             )
  *           ),8) as sAngle
  *      from dual;
  *    
  *    SANGLE
  *    ------
  *        45
  *
  *    -- Geodetic 
  *    select COGO.DD2DMS(
  *            COGO.ST_Degrees(
  *             T_Vertex(
  *               p_id => 1,
  *               p_x  => 147.5,
  *               p_y  => -42.5,
  *               p_sdo_gtype=> 2001,
  *               p_sdo_srid => 4283
  *             )
  *             .ST_SubtendedAngle(
  *                 T_Vertex(
  *                    p_id => 2,
  *                    p_x  => 147.3,
  *                    p_y  => -41.5,
  *                    p_sdo_gtype=> 2001,
  *                    p_sdo_srid => 4283
  *                 ),
  *                 T_Vertex(
  *                    p_id => 3,
  *                    p_x  => 147.8,
  *                    p_y  => -41.1,
  *                    p_sdo_gtype=> 2001,
  *                    p_sdo_srid => 4283
  *                 )
  *             )
  *            )
  *           ) as sAngle
  *      from dual;
  *
  *    SANGLE
  *    --------------
  *    336°35'43.118"
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_SubtendedAngle(p_start_vertex in &&INSTALL_SCHEMA..T_Vertex,
                                    p_end_vertex   in &&INSTALL_SCHEMA..T_Vertex,
                                    p_projected    in integer default 1)
           Return Number Deterministic,

  /****m* T_VERTEX/ST_WithinTolerance
  *  NAME
  *    ST_WithinTolerance -- Discovers whether supplied vertex is within tolerance of current object vertex (SELF).
  *  SYNOPSIS
  *    Member Function ST_WithinTolerance(p_vertex    in &&INSTALL_SCHEMA..T_Vertex,
  *                                       p_tolerance in number default 0.005)
  *             Return Integer deterministic
  *  DESCRIPTION
  *    This function calculates distance from current object vertex (SELF) to supplied vertex (p_vertex)
  *    If distance <= supplied tolerance the function returns 1 (true) otherwise 0 (false).
  *    p_start_vertex ---> SELF ---> p_end_vertex
  *  PARAMETERS
  *    p_vertex  (T_VERTEX) - Vertex that is to be compared to current object (SELF).
  *    p_tolerance (NUMBER) - sdo_tolerance for use with sdo_geom.sdo_distance.
  *  RESULT
  *    BOOLEAN (INTEGER) - 1 is True; 0 is False.
  *  EXAMPLE
  *    -- Geodetic 
  *    set serveroutput on size unlimited
  *    With Data as (
  *      select T_Vertex(
  *               p_x        => 147.5,
  *               p_y        => -42.5,
  *               p_id       => 1,
  *               p_sdo_gtype=> 2001,
  *               p_sdo_srid => 4283
  *             ) as vertex_1,
  *             T_Vertex(
  *                  p_x        => 147.5,
  *                  p_y        => -42.5000003,
  *                  p_id       => 2,
  *                  p_sdo_gtype=> 2001,
  *                  p_sdo_srid => 4283
  *              ) as vertex_2
  *       from dual
  *    )
  *    select a.vertex_1
  *           .ST_Distance(
  *               p_vertex    => new T_Vertex(a.vertex_2),
  *               p_tolerance => 0.005,
  *               p_unit      => 'unit=M'
  *             ) as Distance,
  *           case when t.InTValue = 0 then 0.5 else 0.005 end as tolerance,
  *           a.vertex_1
  *           .ST_WithinTolerance(
  *               p_vertex    => new T_Vertex(a.vertex_2),
  *               p_tolerance => case when t.InTValue = 0 then 0.5 else 0.005 end,
  *               p_projected => 0
  *             ) as withinTolerance
  *      from data a,
  *           table(TOOLS.generate_series(0,1,1)) t;
  *             
  *    
  *      DISTANCE  TOLERANCE WITHINTOLERANCE
  *    ---------- ---------- ---------------
  *    .0333585156         .5               1
  *    .0333585156       .005               0
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_WithinTolerance(P_Vertex    In &&INSTALL_SCHEMA..T_Vertex,
                                     p_tolerance in number  default 0.005,
                                     p_projected in integer default 1)
           Return Integer Deterministic,

  /****m* T_VERTEX/ST_Round
  *  NAME
  *    ST_Round -- Rounds X,Y,Z and m(w) ordinates to passed in precision.
  *  SYNOPSIS
  *    Member Function ST_Round(p_dec_places_x in integer default 8,
  *                             p_dec_places_y in integer default NULL,
  *                             p_dec_places_z in integer default 3,
  *                             p_dec_places_m in integer default 3)
  *             Return T_Vertex Deterministic,
  *  DESCRIPTION
  *    Applies relevant decimal digits of precision value to ordinate.
  *    For example:
  *      SELF.x := ROUND(SELF.x,p_dec_places_x);
  *  PARAMETERS
  *    p_dec_places_x (integer) - value applied to x Ordinate.
  *    p_dec_places_y (integer) - value applied to y Ordinate.
  *    p_dec_places_z (integer) - value applied to z Ordinate.
  *    p_dec_places_m (integer) - value applied to m Ordinate.
  *  RESULT
  *    vertex (T_VERTEX)
  *  EXAMPLE
  *    -- Geodetic
  *    select T_Vertex(
  *             p_x        => 147.5489578,
  *             p_y        => -42.53625,
  *             p_id       => 1,
  *             p_sdo_gtype=> 2001,
  *             p_sdo_srid => 4283
  *           )
  *           .ST_Round(6,6)
  *           .ST_AsText() as vertex
  *     from dual;
  *    
  *    VERTEX
  *    -----------------------------------------------------------------------
  *    T_Vertex(X=147.548958,Y=-42.53625,Z=NULL,W=NULL,ID=1,GT=2001,SRID=4283)
  *    
  *    -- Planar
  *    select T_Vertex(
  *             p_x        => 12847447.54578,
  *             p_y        => 4374842.3425,
  *             p_z        => 3.2746,
  *             p_id       => 1,
  *             p_sdo_gtype=> 3001,
  *             p_sdo_srid => NULL
  *           )
  *           .ST_Round(3,3,2)
  *           .ST_AsText() as vertex
  *     from dual;
  *    
  *    VERTEX
  *    ---------------------------------------------------------------------------
  *    T_Vertex(X=12847447.546,Y=4374842.343,Z=3.27,W=NULL,ID=1,GT=3001,SRID=NULL)
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Round(p_dec_places_x In integer Default 8,
                           p_dec_places_y In integer Default null,
                           p_dec_places_z In integer Default 3,
                           p_dec_places_m In integer Default 3)
  Return &&INSTALL_SCHEMA..T_Vertex Deterministic,

  /****m* T_VERTEX/ST_SdoGeometry
  *  NAME
  *    ST_SdoGeometry -- Returns Vertex as a suitably encoded MDSYS.SDO_GEOMETRY object.
  *  SYNOPSIS
  *    Member Function ST_SdoGeometry
  *             Return MDSYS.SDO_GEOMETRY Deterministic,
  *  DESCRIPTION
  *    The encoding of the returned SDO_GEOMETRY object depends on the dimension of the vertex 
  *    supplied using p_dims or SELF.ST_Dims() if p_dims is null.
  *    This can be best seen in the source code from T_Vertex Type Body at the end of this documentation. 
  *  PARAMETERS
  *    p_dims in integer default null - A dimension value that will override SELF.ST_Dims() eg return 2D from a 3D vertex.
  *  RESULT
  *    point (MDSYS.SDO_GEOMETRY) -- Type of Point geometry depends on what the vertex represents.
  *  EXAMPLE
  *    select T_Vertex(
  *             p_x        => 147.5489578,
  *             p_y        => -42.53625,
  *             p_id       => 1,
  *             p_sdo_gtype=> 2001,
  *             p_sdo_srid => 4283
  *           )
  *           .ST_Round(6,6)
  *           .ST_SdoGeometry() as geom
  *     from dual;
  *    
  *    GEOM
  *    ---------------------------------------------------------------------------
  *    SDO_GEOMETRY(2001,4283,SDO_POINT_TYPE(147.548958,-42.53625,NULL),NULL,NULL)
  *    
  *    select T_Vertex(
  *             p_x        => 12847447.54578,
  *             p_y        => 4374842.3425,
  *             p_z        => 3.2746,
  *             p_id       => 1,
  *             p_sdo_gtype=> 3001,
  *             p_sdo_srid => NULL
  *           )
  *           .ST_Round(3,3,2)
  *           .ST_SdoGeometry() as geom
  *     from dual;
  *    
  *    GEOM
  *    -------------------------------------------------------------------------------
  *    SDO_GEOMETRY(3001,NULL,SDO_POINT_TYPE(12847447.546,4374842.343,3.27),NULL,NULL)
  *    
  *    select T_Vertex(
  *             p_x        => 12847447.54578,
  *             p_y        => 4374842.3425,
  *             p_z        => 3.2746,
  *             p_w        => 0.002,
  *             p_id       => 1,
  *             p_sdo_gtype=> 4401,
  *             p_sdo_srid => NULL
  *           )
  *           .ST_Round(3,3,2)
  *           .ST_SdoGeometry() as geom
  *     from dual;
  *    
  *    GEOM
  *    ---------------------------------------------------------------------------------------------------------------
  *    SDO_GEOMETRY(4401,NULL,NULL,SDO_ELEM_INFO_ARRAY(1,1,1),SDO_ORDINATE_ARRAY(12847447.546,4374842.343,3.27,0.002))
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  *  SOURCE
  */
  --   v_dims integer := NVL(p_dims,SELF.ST_Dims());
  -- Begin
  --   If ( SELF.sdo_gtype is null ) Then
  --      Return null;
  --   ElsIf ( SELF.sdo_gtype = 2001 or v_dims = 2) Then
  --      Return mdsys.sdo_geometry(SELF.sdo_gtype,SELF.sdo_SRID,mdsys.sdo_point_type(self.x,self.y,NULL),null,null);
  --   ElsIf ( v_dims = 3 ) Then
  --      -- 3001, 3301, 4001, 4301 and 4401 all stop with Z. GetVertices places M in 4401 in Z spot not W
  --      Return mdsys.sdo_geometry(SELF.sdo_gtype,SELF.sdo_SRID,mdsys.sdo_point_type(self.x,self.y,self.z),null,null);
  --   ElsIf ( v_dims = 4 ) Then
  --      If ( SELF.ST_Dims() = 3 ) Then
  --         Return mdsys.sdo_geometry(SELF.sdo_gtype,SELF.sdo_SRID,mdsys.sdo_point_type(self.x,self.y,self.z),null,null);
  --      Else
  --         Return mdsys.sdo_geometry(SELF.sdo_gtype,SELF.sdo_SRID,NULL,mdsys.sdo_elem_info_array(1,1,1),mdsys.sdo_ordinate_array(self.x,self.y,self.z,self.w));
  --      End If;
  --   End If;
  /*******/
  Member Function ST_SdoGeometry(p_dims in integer default null)
           Return mdsys.sdo_geometry Deterministic,

  /****m* T_VERTEX/ST_AsText
  *  NAME
  *    ST_AsText -- Returns text Description of Vertex
  *  SYNOPSIS
  *    Member Function ST_AsText(p_format_model in varchar2 default 'TM9')
  *             Return Varchar2 Deterministic,
  *  DESCRIPTION
  *    Returns textual description of vertex.
  *    If rounding of ordinates is required, first use ST_Round.
  *  PARAMETERS
  *    p_format_model (varchar2) -- Oracle Number Format Model (see documentation)
  *                                 default 'TM9') -- was 'TM9'
  *  RESULT
  *    Vertex Representation (varchar2)
  *  EXAMPLE
  *    select T_Vertex(
  *             sdo_geometry('POINT(0 0)',NULL)
  *           )
  *           .ST_AsText() as pVertex,
  *           T_Vertex(
  *             sdo_geometry('POINT(147.5 -42.5)',4283)
  *           )
  *           .ST_AsText() as gVertex
  *      from dual;
  *
  *    PVERTEX                                                   GVERTEX
  *    --------------------------------------------------------- -----------------------------------------------------------------
  *    T_Vertex(X=0,Y=0,Z=NULL,W=NULL,ID=NULL,GT=2001,SRID=NULL) T_Vertex(X=147.5,Y=-42.5,Z=NULL,W=NULL,ID=NULL,GT=2001,SRID=4283)
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_AsText(p_format_model     in varchar2 default 'TM9',
                            p_coordinates_only in integer default 0)
           Return VarChar2 Deterministic,

  Member Function ST_AsEWKT(p_format_model     in varchar2 default 'TM9')
           Return VarChar2 Deterministic,

  /****m* T_VERTEX/ST_AsCoordString
  *  NAME
  *    ST_AsCoordString -- Returns text Description of Vertex
  *  SYNOPSIS
  *    Member Function ST_AsCoordString(p_separator    in varchar2 Default ' ',
  *                                     p_format_model in varchar2 default 'TM9')
  *             Return Varchar2 Deterministic,
  *  DESCRIPTION
  *    Returns textual description of the vertex's ordinates only.
  *    Useful for working with WKT.
  *    If rounding of ordinates is required first use ST_Round.
  *  PARAMETERS
  *    p_separator    (varchar2) -- Separator between ordinates.
  *    p_format_model (varchar2) -- Oracle Number Format Model (see documentation)
  *                                 default 'TM9')
  *  RESULT
  *    Coordinate String (varchar2)
  *  EXAMPLE
  *    select T_Vertex(
  *             sdo_geometry('POINT(0 0)',NULL)
  *           )
  *           .ST_AsText() as pVertex,
  *           T_Vertex(
  *             sdo_geometry('POINT(147.5 -42.5)',4283)
  *           )
  *           .ST_AsText() as gVertex
  *      from dual;
  *
  *    PVERTEX                                                   GVERTEX
  *    --------------------------------------------------------- -----------------------------------------------------------------
  *    T_Vertex(X=0,Y=0,Z=NULL,W=NULL,ID=NULL,GT=2001,SRID=NULL) T_Vertex(X=147.5,Y=-42.5,Z=NULL,W=NULL,ID=NULL,GT=2001,SRID=4283)
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_AsCoordString(p_separator    in varchar2 Default ' ',
                                   p_format_model in varchar2 default 'TM9')
           Return VarChar2 Deterministic,

  /****m* T_VERTEX/ST_Equals
  *  NAME
  *    ST_Equals -- Compares current object (SELF) with supplied vertex.
  *  SYNOPSIS
  *    Member Function ST_Equals(p_vertex    in &&INSTALL_SCHEMA..T_Vertex,
  *                              p_dPrecision in number default 3)
  *             Return Integer deterministic
  *  DESCRIPTION
  *    This function compares current object vertex (SELF) to supplied vertex (p_vertex).
  *    If all ordinates (to supplied precision) are equal, returns True (1) else False (0).
  *    SDO_GTYPE, SDO_SRID and ID are not compared.
  *  PARAMETERS
  *    p_vertex    (T_VERTEX) - Vertex that is to be compared to current object (SELF).
  *    p_dPrecision (INTEGER) - Decimal digits of precision for all ordinates.
  *  RESULT
  *    BOOLEAN (INTEGER) - 1 is True (Equal); 0 is False.
  *  EXAMPLE
  *
  *    select t.IntValue as precision,
  *           T_Vertex(
  *             p_x        => 12847447.54578,
  *             p_y        => 4374842.3425,
  *             p_z        => 3.2746,
  *             p_id       => 1,
  *             p_sdo_gtype=> 3001,
  *             p_sdo_srid => NULL
  *           )
  *           .ST_Equals(
  *               T_Vertex(
  *                 p_x        => 12847447.546,
  *                 p_y        => 4374842.34,
  *                 p_z        => 3.2746,
  *                 p_id       => 1,
  *                 p_sdo_gtype=> 3001,
  *                 p_sdo_srid => NULL
  *               ),
  *               t.IntValue
  *           ) as vEquals
  *      from table(TOOLS.generate_series(1,3,1)) t;
  *      
  *    PRECISION VEQUALS
  *    --------- -------
  *            1       1 
  *            2       1 
  *            3       0 
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Member Function ST_Equals(p_vertex     in &&INSTALL_SCHEMA..T_Vertex,
                            p_dPrecision in integer default 3)
           Return Number Deterministic,

  /****m* T_VERTEX/OrderBy
  *  NAME
  *    OrderBy -- Implements ordering function that can be used to sort a collection of T_Vertex objects.
  *  SYNOPSIS
  *    Order Member Function OrderBy(p_vertex in &&INSTALL_SCHEMA..T_Vertex)
  *                   Return Number deterministic
  *  DESCRIPTION
  *    This order by function allows a collection of T_Vertex objects to be sorted.
  *    For example in the ORDER BY clause of a SELECT statement. Comparison uses all ordinates: X, Y, Z and W.
  *  PARAMETERS
  *    p_vertex (T_VERTEX) - Order pair
  *  RESULT
  *    order value (NUMBER) - -1 less than; 0 equal; 1 greater than
  *  EXAMPLE
  *    With vertices as (
  *    select t_vertex(p_x=>dbms_random.value(0,level),
  *                    p_y=>dbms_random.value(0,level),
  *                    p_id=>1,
  *                    p_sdo_gtype=>2001,
  *                    p_sdo_srid=>null) as vertex
  *      from dual
  *      connect by level < 10
  *    )
  *    select a.vertex.st_astext(2) as vertex
  *      from vertices a
  *      order by a.vertex;
  *
  *    VERTEX
  *    -------------------------------------------------------------
  *    T_Vertex(X=.29,Y=1.61,Z=NULL,W=NULL,ID=1,GT=2001,SRID=NULL)
  *    T_Vertex(X=.32,Y=1.39,Z=NULL,W=NULL,ID=1,GT=2001,SRID=NULL)
  *    T_Vertex(X=.64,Y=.06,Z=NULL,W=NULL,ID=1,GT=2001,SRID=NULL)
  *    T_Vertex(X=1.76,Y=2.76,Z=NULL,W=NULL,ID=1,GT=2001,SRID=NULL)
  *    T_Vertex(X=2.06,Y=5.36,Z=NULL,W=NULL,ID=1,GT=2001,SRID=NULL)
  *    T_Vertex(X=2.56,Y=8.99,Z=NULL,W=NULL,ID=1,GT=2001,SRID=NULL)
  *    T_Vertex(X=3.08,Y=.63,Z=NULL,W=NULL,ID=1,GT=2001,SRID=NULL)
  *    T_Vertex(X=4.17,Y=.57,Z=NULL,W=NULL,ID=1,GT=2001,SRID=NULL)
  *    T_Vertex(X=6.55,Y=1.18,Z=NULL,W=NULL,ID=1,GT=2001,SRID=NULL)
  *    
  *     9 rows selected 
  *  AUTHOR
  *    Simon Greener
  *  HISTORY
  *    Simon Greener - Jan 2013 - Original coding.
  *  COPYRIGHT
  *    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
  ******/
  Order Member Function OrderBy(p_vertex in &&INSTALL_SCHEMA..T_Vertex)
                 Return Number Deterministic

)
INSTANTIABLE NOT FINAL;
/
SHOW ERRORS

set serveroutput on size unlimited
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
   v_OK       boolean := true;
   v_obj_name varchar2(30) := 'T_VERTEX';
BEGIN
   FOR rec IN (select object_name,object_Type, status 
                 from user_objects
                where object_name = v_obj_name
                  and object_type = 'TYPE'
               order by object_type
              ) 
   LOOP
      IF ( rec.status = 'VALID' ) Then
         dbms_output.put_line(rec.object_type || ' ' || USER || '.' || rec.object_name || ' is valid.');
      ELSE
         dbms_output.put_line(rec.object_type || ' ' || USER || '.' || rec.object_name || ' is invalid.');
         v_ok := false;
      END IF;
   END LOOP;
   execute immediate 'GRANT EXECUTE ON &&INSTALL_SCHEMA..' || v_obj_name || ' TO public WITH GRANT OPTION';
   IF ( NOT v_OK ) THEN
      RAISE_APPLICATION_ERROR(-20000,v_obj_name || ' failed to install.');
   END IF;
END;
/
SHOW ERRORS

WHENEVER SQLERROR CONTINUE;

/****s* OBJECT TYPE ARRAY/T_VERTICES 
*  NAME
*    T_VERTICES -- Array of of T_Vertex objects.
*  DESCRIPTION
*    An array of T_VERTEX objects.
*  AUTHOR
*    Simon Greener
*  HISTORY
*    Simon Greener - Jan 2005 - Original coding.
*  COPYRIGHT
*    (c) 2012-2018 by TheSpatialDBAdvisor/Simon Greener
*  SOURCE
*/
CREATE OR REPLACE TYPE &&INSTALL_SCHEMA..T_Vertices 
           IS TABLE OF &&INSTALL_SCHEMA..T_Vertex;
/*******/
/
show errors

grant execute on &&INSTALL_SCHEMA..T_Vertices to public with grant option;

EXIT SUCCESS;
