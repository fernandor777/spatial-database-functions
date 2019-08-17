DEFINE defaultSchema = '&1'

SET VERIFY OFF;

ALTER SESSION SET plsql_optimize_level=1;

CREATE OR REPLACE PACKAGE AFFINE
AUTHID CURRENT_USER
As

   Function PI
     Return Number deterministic;

   Function ST_Degrees(p_radians in number)
     Return number deterministic;
  
   Function ST_Radians(p_degrees in number)
     Return number deterministic;

   Function ST_Rotate(p_geometry      in mdsys.sdo_geometry,
                      p_angle_rad     in number)
     Return mdsys.sdo_geometry deterministic;

   Function ST_Rotate(p_geometry     in mdsys.sdo_geometry,
                      p_angle_rad    in number,
                      p_dir          in pls_integer,
                      p_rotate_point in mdsys.sdo_geometry,
                      p_line1        in mdsys.sdo_geometry)
     Return mdsys.sdo_geometry deterministic;

   Function ST_Rotate(p_geometry     in mdsys.sdo_geometry,
                      p_angle_rad    in number,
                      p_rotate_x     in number,
                      p_rotate_y     in number)
     Return mdsys.sdo_geometry deterministic;

   Function ST_Rotate(p_geometry     in mdsys.sdo_geometry,
                      p_angle_rad    in number,
                      p_rotate_point in mdsys.sdo_geometry)
     Return mdsys.sdo_geometry deterministic;

   Function ST_Scale(p_geometry in mdsys.sdo_geometry,
                     p_sx       in number,
                     p_sy       in number,
                     p_sz       in number,
                     p_scale_pt in mdsys.sdo_geometry)
     Return mdsys.sdo_geometry deterministic;

   Function ST_Scale(p_geometry in mdsys.sdo_geometry,
                     p_sx       in number,
                     p_sy       in number,
                     p_sz       in number)
     Return mdsys.sdo_geometry deterministic;

   Function ST_Scale(p_geometry in mdsys.sdo_geometry,
                     p_sx       in number,
                     p_sy       in number)
     Return mdsys.sdo_geometry deterministic;

   Function ST_Translate(p_geometry in mdsys.sdo_geometry,
                         p_tx       in number,
                         p_ty       in number,
                         p_tz       in number)
     Return mdsys.sdo_geometry deterministic;

   Function ST_Translate(p_geometry in mdsys.sdo_geometry,
                         p_tx       in number,
                         p_ty       in number)
     Return mdsys.sdo_geometry deterministic;

   Function ST_RotateTranslateScale(p_geometry  in mdsys.sdo_geometry,
                                    p_angle_rad in number,
                                    p_rs_point  in mdsys.sdo_geometry,
                                    p_sx        in number,
                                    p_sy        in number,
                                    p_sz        in number,
                                    p_tx        in number,
                                    p_ty        in number,
                                    p_tz        in number)
     Return mdsys.sdo_geometry deterministic;

    /* ----------------------------------------------------------------------------------------
  * @function   : Affine
  * @precis     : Applies a 3d affine transformation to the geometry to do things like translate, rotate, scale in one step.
  * @version    : 1.0
  * @description: Applies a 3d affine transformation to the geometry to do things like translate, rotate, scale in one step.
  *               To apply a 2D affine transformation only supply a, b, d, e, xoff, yoff
  * @usage      : Function Affine ( p_geom IN MDSYS.SDO_GEOMETRY,
  * @param      : p_geom  : MDSYS.SDO_GEOMETRY : The shape to rotate.
  * @param      : a, b, c, d, e, f, g, h, i, xoff, yoff, zoff :
  *               Represent the transformation matrix
  *                 / a  b  c  xoff \
  *                 | d  e  f  yoff |
  *                 | g  h  i  zoff |
  *                 \ 0  0  0     1 /
  *               and the vertices are transformed as follows:
  *                 x' = a*x + b*y + c*z + xoff
  *                 y' = d*x + e*y + f*z + yoff
  *                 z' = g*x + h*y + i*z + zoff
  * @requires   : SDO_UTIL.GetVertices Function
  *               SYS.UTL_NLA Package
  *               SYS.UTL_NLA_ARRAY_DBL Type
  *               SYS.UTL_NLA_ARRAY_INT Type
  * @return     : newGeom  : MDSYS.SDO_GEOMETRY : Transformed input geometry.
  * @note       : Cartesian arithmetic only
  *             : Not for Oracle XE. Only 10g and above.
  * @history    : Simon Greener, SpatialDB Advisor - Feb 2009 - Original coding.
  * @copyright  : Simon Greener, 2011, 2012
  * @license    : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/.
  *               Any bugs or improvements to be supplied back to Simon Greener
  **/
  Function ST_Affine( p_geometry in mdsys.sdo_geometry,
                      p_a        in number,
                      p_b        in number,
                      p_c        in number,
                      p_d        in number,
                      p_e        in number,
                      p_f        in number,
                      p_g        in number,
                      p_h        in number,
                      p_i        in number,
                      p_xoff     in number,
                      p_yoff     in number,
                      p_zoff     in number)
    return mdsys.sdo_geometry deterministic;

  /* ----------------------------------------------------------------------------------------
  * @function   : MOVE
  * @precis     : Pure PLSQL Function which updates all coordinates in a shape by applying x/y shift.
  * @version    : 2.0
  * @description: This function iterates though all the coordinates of a shape and applys the delta
  *               provided by the p_deltaX, p_deltaY and, optionally, p_deltaZ to them.
  *               If p_filter_mbr is provided (must be an SDO_GEOMETRY Optimized Rectangle), only those 
  *               coordinate that fall within it are moved, otherwise all are moved.
  * @usage      : Function Move ( p_geometry       IN MDSYS.SDO_GEOMETRY,
  *                               p_deltaX         IN number,
  *                               p_deltaY         IN number,
  *                               p_deltaZ         IN number         := NULL,
  *                               p_decimal_digits IN INTEGER        := 8,
  *                               p_filter_mbr IN MDSYS.SDO_GEOMETRY := NULL 
  *                              ) 
  *                 Return MDSYS.SDO_GEOMETRY DETERMINISTIC;
  *               eg movedShape := Move(shape,-0.33,1.345,null,3,null);
  * @param      : p_geometry       : MDSYS.SDO_GEOMETRY : The shape to move.
  * @param      : p_deltaX         : number : Shift to be applied to the X coordinate.
  * @param      : p_deltaY         : number : Shift to be applied to the Y coordinate.
  * @param      : p_deltaZ         : number : Shift to be applied to the Z coordinate.
  * @param      : p_decimal_digits : Integer : Value used to ROUND computed XY ordinates.
  * @param      : p_filter_mbr     : MDSYS.SDO_GEOMETRY : An optimized rectangle shape defining a sub-area in which p_geometry's coordinates have to be within for move.
  * @return     : movedShape       : MDSYS.SDO_GEOMETRY : Shape whose coordinates are 'moved'.
  * @history    : Simon Greener - Mar 2003 - Original coding.
  * @history    : Simon Greener - Jul 2006 - Migrated to GF package and made 3D aware.
  * @history    : Simon Greener - Sep 2007 - Removed need for SDO_GEOM.RELATE via use of MBR type.
  * @history    : Simon Greener - Jun 2008 - Removed modification of ordinates to precision of diminfo/tolerance as duplicates Tolerance() function.
  * @history    : Simon Greener - Feb 2018 - Moved from GEOM package to here. Revamped code.
  * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/
  FUNCTION Move( p_geometry       IN MDSYS.SDO_GEOMETRY,
                 p_deltaX         IN NUMBER,
                 p_deltaY         IN NUMBER,
                 p_deltaZ         IN NUMBER             := NULL,
                 p_decimal_digits IN Integer            := 8,
                 p_filter_mbr     IN MDSYS.SDO_GEOMETRY := NULL
               )
    Return MDSYS.SDO_GEOMETRY Deterministic;

  /* ----------------------------------------------------------------------------------------
  * @function   : SCALE
  * @precis     : Function which updates all coordinates in a shape by applying an x/y/z factor.
  * @version    : 1.0
  * @description: As against, move, which adds a supplied delta to existing coords, Scale multiplies
  *               existing coordinates by the supplied factors. Rounding is applied to the result using
  *               the supplied tolerances.
  * @usage      : Function Scale( p_geometry       IN MDSYS.SDO_GEOMETRY,
  *                               p_deltaX         IN number,
  *                               p_deltaY         IN number,
  *                               p_deltaZ         IN number  := NULL,
  *                               p_decimal_digits IN INTEGER := 8
  *                             )
  *                 Return MDSYS.SDO_GEOMETRY DETERMINISTIC;
  *               eg fixedShape := Scale(shape,0.43,6.3,null,3);
  * @param      : p_geometry       : MDSYS.SDO_GEOMETRY : The shape to move.
  * @param      : p_XFactor        : number : Factor to be applied to the X coordinate.
  * @param      : p_YFactor        : number : Factor to be applied to the Y coordinate.
  * @param      : p_ZFactor        : number : Factor to be applied to the Z coordinate.
  * @param      : p_decimal_digits : Integer : Value used to ROUND computed XY ordinates.
  * @requires   : &&defaultSchema..GEOM.isMeasure and &&defaultSchema..GEOM.ADD_Coordinate
  * @return     : newShape      : MDSYS.SDO_GEOMETRY : Shape whose coordinates have been scaled.
  * @history    : Simon Greener - Jan 2008 - Original coding.
  * @history    : Simon Greener - Feb 2018 - Moved from GEOM package to here. Revamped code.
  * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  **/

  FUNCTION Scale( p_geometry       IN MDSYS.SDO_GEOMETRY,
                  p_XFactor        IN NUMBER,
                  p_YFactor        IN NUMBER,
                  p_ZFactor        IN NUMBER  := NULL,
                  p_decimal_digits IN Integer := 8
                )
    Return MDSYS.SDO_GEOMETRY Deterministic;

  /* ----------------------------------------------------------------------------------------
  * @function   : Rotate
  * @precis     : Function which rotates a shape.
  * @version    : 1.0
  * @description: Simply rotates a shape around supplied axis point (or centre of MBR) by a
  *               specified rotation in whole circle degrees.
  * @usage      : Function Rotate ( p_geometry       IN MDSYS.SDO_GEOMETRY,
  *                                 p_rX             IN number,
  *                                 p_rY             IN number,
  *                                 p_angle          IN number,
  *                                 p_decimal_digits IN INTEGER
  *                        )
  *                 Return MDSYS.SDO_GEOMETRY DETERMINISTIC;
  * @param      : p_geometry       : MDSYS.SDO_GEOMETRY : The shape to rotate.
  * @param      : p_rX             : number : Rotation point X
  * @param      : p_rY             : number : Rotation point Y
  * @param      : p_angle          : number : Rotation between 0..360 degrees
  * @param      : p_decimal_digits : Integer : Value used to ROUND computed XY ordinates.
  * @return     : Rotated Shape    : MDSYS.SDO_GEOMETRY : Shape whose coordinates are 'rotated'.
  * @note       : Cartesian arithmetic only
  * @history    : Simon Greener, SpatialDB Advisor - Sept 2005 - Original coding.
  * @history    : Simon Greener - Feb 2018 - Moved from GEOM package to here. Revamped code.
  * @copyright  : Licensed under a Creative Commons Attribution-Share Alike 2.5 Australia License.
  *               http://creativecommons.org/licenses/by-sa/2.5/au/
  *               Any bugs or improvements to be supplied back to Simon Greener
  **/
  Function Rotate( p_geometry       IN MDSYS.SDO_GEOMETRY,
                   p_rX             IN number,
                   p_rY             IN number,
                   p_angle          IN number,  -- 0 to 360 degrees
                   p_decimal_digits IN Integer := 8
                 )
    Return MDSYS.SDO_GEOMETRY Deterministic;

END Affine;
/
show errors

CREATE OR REPLACE PACKAGE BODY AFFINE
As

  Function PI
  Return Number
  As
  Begin
    Return acos(-1);
  End Pi;

  Function ST_Degrees(p_radians in number)
  Return number
  Is
  Begin
    return p_radians * (180.0 / &&defaultSchema..AFFINE.PI());
  End ST_Degrees;

  Function ST_Radians(p_degrees in number)
    Return number
  Is
  Begin
    Return p_degrees * (&&defaultSchema..AFFINE.PI() / 180.0);
  End ST_Radians;

   Function ST_Rotate(p_geometry     in mdsys.sdo_geometry,
                      p_angle_rad    in number,
                      p_dir          in pls_integer,
                      p_rotate_point in mdsys.sdo_geometry,
                      p_line1        in mdsys.sdo_geometry)
     Return mdsys.sdo_geometry
   As
   Begin
      If ( p_geometry is NULL ) Then
         RETURN p_geometry;
      End If;
     -- dir - Rotation parameter for x(0), y(1), or z(2)-axis roll.
     --       You cannot set p_dir => 0, 1 or 2. Only -1, -2, -3. They don't seem to affect the result.
     -- For two-dimensional geometries, rotation uses the p1 and angle values.
     If ( p_geometry.get_dims() = 2 ) Then
       If ( p_angle_rad is null and p_rotate_point is null ) Then
          raise_application_error(-20001,'For 2D geometry rotation, p_angle_rad and p_rotate_point must not be null',true);
       End If;
     Else
         -- For three-dimensional geometries, rotation uses either:
         --     1. the angle and dir values or
         --     2. the angle and line1 values.
         If ( p_angle_rad is null ) Then
            raise_application_error(-20001,'For 3D geometry rotation, p_angle_rad must not be null',true);
         End If;
         If ( p_dir is null and p_line1 is null ) Then
            raise_application_error(-20001,'For 3D geometry rotation, both p_dir and p_line1 cannot be null',true);
         End If;
     End If;
     Return SDO_UTIL.AffineTransforms (
        geometry    => p_geometry,
        rotation    => 'TRUE',
          p1        => p_rotate_point,
          angle     => p_angle_rad,
          dir       => p_dir,
          line1     => p_line1,
        translation => 'FALSE', tx => 0.0, ty => 0.0, tz => 0.0,
        scaling     => 'FALSE', psc1 => NULL,    sx => 0.0,    sy => 0.0,   sz => 0.0,
        shearing    => 'FALSE', shxy => 0.0,   shyx => 0.0,  shxz => 0.0, shzx => 0.0, shyz => 0.0, shzy => 0.0,
        reflection  => 'FALSE', pref => NULL, lineR => NULL, dirR => -1,
        planeR      => 'FALSE',    n => null,  bigD => null
    );
   End ST_Rotate;

   Function ST_Rotate(p_geometry     in mdsys.sdo_geometry,
                      p_angle_rad    in number,
                      p_rotate_x     in number,
                      p_rotate_y     in number)
     Return mdsys.sdo_geometry
   As
   Begin
      If ( p_geometry is NULL ) Then
        RETURN p_geometry;
      End If;
     -- dir - Rotation parameter for x(0), y(1), or z(2)-axis roll.
     -- For two-dimensional geometries, rotation uses the p1 and angle values.
     If ( p_geometry.get_dims() = 2 ) Then
       If ( p_angle_rad is null and p_rotate_x is null and p_rotate_y is null ) Then
          raise_application_error(-20001,'For 2D geometry rotation, p_angle_rad, p_rotate_x and p_rotate_y must not be null.',true);
       End If;
     Else
       raise_application_error(-20001,'This version of ST_Rotate only supports 2D geometry rotation.',true);
     End If;
     Return ST_Rotate(p_geometry     => p_geometry,
                      p_angle_rad    => p_angle_rad,
                      p_dir          => -1,
                      p_rotate_point => mdsys.sdo_geometry(2001,p_geometry.sdo_srid,mdsys.sdo_point_type(p_rotate_x,p_rotate_y,NULL),NULL,NULL),
                      p_line1        => NULL);
   End ST_Rotate;

   Function ST_Rotate(p_geometry     in mdsys.sdo_geometry,
                      p_angle_rad    in number,
                      p_rotate_point in mdsys.sdo_geometry)
     Return mdsys.sdo_geometry
   As
   Begin
      If ( p_geometry is NULL ) Then
        RETURN p_geometry;
      End If;
     -- dir - Rotation parameter for x(0), y(1), or z(2)-axis roll.
     -- For two-dimensional geometries, rotation uses the p1 and angle values.
     If ( p_geometry.get_dims() = 2 ) Then
        If ( p_angle_rad is null and p_rotate_point is null ) Then
          raise_application_error(-20001,'For 2D geometry rotation, p_angle_rad and p_rotate_point must not be null.',true);
        End If;
     Else
        raise_application_error(-20001,'This version of ST_Rotate only supports 2D geometry rotation.',true);
     End If;
     Return ST_Rotate(p_geometry     => p_geometry,
                      p_angle_rad    => p_angle_rad,
                      p_dir          => -1,
                      p_rotate_point => p_rotate_point,
                      p_line1        => NULL);
   End ST_Rotate;

   Function ST_Rotate(p_geometry      in mdsys.sdo_geometry,
                      p_angle_rad     in number)
     Return mdsys.sdo_geometry
   As
   Begin
      If ( p_geometry is NULL ) Then
        RETURN p_geometry;
      End If;
      -- dir - Rotation parameter for x(0), y(1), or z(2)-axis roll.
      -- For two-dimensional geometries, rotation uses the p1 and angle values.
      If ( p_geometry.get_dims() = 2 ) Then
        If ( p_angle_rad is null ) Then
          raise_application_error(-20001,'For 2D geometry rotation, p_angle_rad must not be null.',true);
        End If;
      Else
        raise_application_error(-20001,'This version of ST_Rotate only supports 2D geometry rotation.',true);
      End If;
      Return ST_Rotate(p_geometry     => p_geometry,
                       p_angle_rad    => p_angle_rad,
                       p_dir          => -1,
                       p_rotate_point => mdsys.sdo_geometry(2001,p_geometry.sdo_srid,mdsys.sdo_point_type(0.0,0.0,0.0),null,null),
                       p_line1        => NULL);
   End ST_Rotate;

   /** =================================================================== **/

   /**  Scales the geometry to a new size by multiplying the ordinates with the parameters:
   *    ST_Scale(geom, Xfactor, Yfactor, Zfactor, scale Point).
   *    ST_Scale(geom, Xfactor, Yfactor, Zfactor).
   *    ST_Scale(geom, Xfactor, Yfactor).
   * **/
   Function ST_Scale(p_geometry in mdsys.sdo_geometry,
                     p_sx       in number,
                     p_sy       in number,
                     p_sz       in number,
                     p_scale_pt in mdsys.sdo_geometry)
     Return mdsys.sdo_geometry
   As
     -- psc1 is Point on the input geometry about which to perform the scaling
     v_dims   pls_integer;
     v_gtype  pls_integer;
     v_vertex mdsys.vertex_type;
     v_psc1   mdsys.sdo_geometry;
     v_sx     number := case when p_sx is null then 0.0 else p_sx end;
     v_sy     number := case when p_sy is null then 0.0 else p_sy end;
     v_sz     number := case when p_sz is null then 0.0 else p_sz end;
   Begin
      If ( p_geometry is NULL ) Then
        RETURN p_geometry;
      End If;
      -- Point on the input geometry about which to perform the scaling.
      -- This geometry should be either a zero point (with 0,0 or 0,0,0
      -- ordinates for scaling about the origin) or a nonzero point (with ordinates
      -- for scaling about a point other than the origin).
      v_dims := p_geometry.get_dims();
      v_gtype := (v_dims * 1000) + 1;
      if ( p_scale_pt is null ) then
        v_psc1 := mdsys.sdo_geometry(v_gtype,p_geometry.sdo_srid,mdsys.sdo_point_type(0.0,0.0,case when v_gtype=3001 then 0.0 else null end),null,null);
      else
        v_vertex := sdo_util.getVertices(p_geometry)(1);
        v_psc1   := mdsys.sdo_geometry(v_gtype,p_geometry.sdo_srid,mdsys.sdo_point_type(v_vertex.x,v_vertex.y,v_vertex.z),null,null);
      end if;
      Return SDO_UTIL.AffineTransforms (
        geometry    => p_geometry,
        scaling     => 'TRUE',
          psc1        => v_psc1,
          sx          => v_sx,
          sy          => v_sy,
          sz          => v_sz,
        rotation    => 'FALSE', p1 => NULL, angle => 0.0, dir => -1, line1 => NULL,
        translation => 'FALSE', tx => 0.0, ty => 0.0, tz => 0.0,
        shearing    => 'FALSE', shxy => 0.0,   shyx => 0.0,  shxz => 0.0, shzx => 0.0, shyz => 0.0, shzy => 0.0,
        reflection  => 'FALSE', pref => NULL, lineR => NULL, dirR => -1,
        planeR      => 'FALSE',    n => null,  bigD => null
    );
   End ST_Scale;

   Function ST_Scale(p_geometry in mdsys.sdo_geometry,
                     p_sx       in number,
                     p_sy       in number,
                     p_sz       in number)
     Return mdsys.sdo_geometry
   As
   Begin
      If ( p_geometry is NULL ) Then
        Return p_geometry;
      End If;
      Return ST_Scale(p_geometry => p_geometry,
                      p_sx       => p_sx,
                      p_sy       => p_sy,
                      p_sz       => p_sz,
                      p_scale_pt => null);
   End ST_Scale;

   Function ST_Scale(p_geometry in mdsys.sdo_geometry,
                     p_sx       in number,
                     p_sy       in number)
     Return mdsys.sdo_geometry
   As
   Begin
      If ( p_geometry is NULL ) Then
        Return p_geometry;
      End If;
      Return ST_Scale(p_geometry => p_geometry,
                      p_sx       => p_sx,
                      p_sy       => p_sy,
                      p_sz       => 0.0,
                      p_scale_pt => null);
   End ST_Scale;

   /** =================================================================== **/

   /** Translates the geometry to a new location using the numeric parameters as offsets.
   *   ST_Translate(geom, X, Y) or
   *   ST_Translate(geom, X, Y, Z)
   */
   function ST_Translate(p_geometry in mdsys.sdo_geometry,
                         p_tx       in number,
                         p_ty       in number,
                         p_tz       in number)
     return mdsys.sdo_geometry
   As
     v_tx number := case when p_tx is null then 0.0 else p_tx end;
     v_ty number := case when p_ty is null then 0.0 else p_ty end;
     v_tz number := case when p_tz is null then 0.0 else p_tz end;
   Begin
     If ( p_geometry is NULL ) Then
       Return p_geometry;
     End If;
     if ( p_geometry.get_dims() = 2 ) then
        v_tz := 0.0;
     End If;
     Return SDO_UTIL.AffineTransforms (
        geometry    => p_geometry,
        translation => 'TRUE',
          tx => v_tx,
          ty => v_ty,
          tz => v_tz,
        scaling    => 'FALSE', psc1 => NULL,    sx => 0.0,    sy => 0.0,   sz => 0.0,
        rotation   => 'FALSE', p1   => NULL, angle => 0.0,   dir => -1, line1 => NULL,
        shearing   => 'FALSE', shxy => 0.0,   shyx => 0.0,  shxz => 0.0, shzx => 0.0, shyz => 0.0, shzy => 0.0,
        reflection => 'FALSE', pref => NULL, lineR => NULL, dirR => -1,
        planeR     => 'FALSE',    n => null,  bigD => null
    );
  End ST_Translate;

   Function ST_Translate(p_geometry in mdsys.sdo_geometry,
                         p_tx       in number,
                         p_ty       in number)
     return mdsys.sdo_geometry
   As
   Begin
     If ( p_geometry is NULL ) Then
       Return p_geometry;
     End If;
     Return AFFINE.ST_Translate(p_geometry,
                                p_tx,
                                p_ty,
                                0.0);
  End ST_Translate;

   Function ST_RotateTranslateScale(p_geometry  in mdsys.sdo_geometry,
                                    p_angle_rad in number,
                                    p_rs_point  in mdsys.sdo_geometry,
                                    p_sx        in number,
                                    p_sy        in number,
                                    p_sz        in number,
                                    p_tx        in number,
                                    p_ty        in number,
                                    p_tz        in number)
     return mdsys.sdo_geometry
   As
     v_dims   pls_integer;
     v_gtype  pls_integer;
     v_psc1   mdsys.sdo_geometry;
     v_vertex mdsys.vertex_type;
     v_sx     number := case when p_sx is null then 0.0 else p_sx end;
     v_sy     number := case when p_sy is null then 0.0 else p_sy end;
     v_sz     number := case when p_sz is null then 0.0 else p_sz end;
     v_tx     number := case when p_tx is null then 0.0 else p_tx end;
     v_ty     number := case when p_ty is null then 0.0 else p_ty end;
     v_tz     number := case when p_tz is null then 0.0 else p_tz end;
   Begin
     If ( p_geometry is NULL ) Then
       Return p_geometry;
     End If;
     if ( p_geometry.get_dims() = 2 ) then
        v_tz := 0.0;
     End If;
     -- dir - Rotation parameter for x(0), y(1), or z(2)-axis roll.
     --       You cannot set p_dir => 0, 1 or 2. Only -1, -2, -3. They don't see to affect the result.
     -- For two-dimensional geometries, rotation uses the p1 and angle values.
     If ( p_geometry.get_dims() = 2 ) Then
       If ( p_angle_rad is null and p_rs_point is null ) Then
          raise_application_error(-20001,'For 2D geometry rotation, p_angle_rad and p_rs_point must not be null.',true);
       End If;
     Else
       raise_application_error(-20001,'This function does not support 3D geometry rotation - Use other functions.',true);
     End If;
     v_dims := p_geometry.get_dims();
     v_gtype := (v_dims * 1000) + 1;
     if ( p_rs_point is null ) then
        v_psc1 := mdsys.sdo_geometry(v_gtype,p_geometry.sdo_srid,mdsys.sdo_point_type(0.0,0.0,case when v_gtype=3001 then 0.0 else null end),null,null);
     else
        v_vertex := sdo_util.getVertices(p_rs_point)(1);
        v_psc1   := mdsys.sdo_geometry(v_gtype,p_geometry.sdo_srid,mdsys.sdo_point_type(v_vertex.x,v_vertex.y,case when v_gtype=3001 then v_vertex.z else null end),null,null);
     end if;
     Return SDO_UTIL.AffineTransforms (
        geometry    => p_geometry,
           rotation => 'TRUE',
                 p1 => p_rs_point,
              angle => p_angle_rad,
                dir => -1,
              line1 => NULL,
        translation => 'TRUE',
                 tx => v_tx,
                 ty => v_ty,
                 tz => v_tz,
            scaling => 'TRUE',
               psc1 => v_psc1,
                 sx => v_sx,
                 sy => v_sy,
                 sz => v_sz,
        shearing    => 'FALSE', shxy => 0.0,   shyx => 0.0,  shxz => 0.0, shzx => 0.0, shyz => 0.0, shzy => 0.0,
        reflection  => 'FALSE', pref => NULL, lineR => NULL, dirR => -1,
        planeR      => 'FALSE',    n => null,  bigD => null
    );
  End ST_RotateTranslateScale;

   /** =================================================================== **/

  Function ST_Affine( p_geometry in mdsys.sdo_geometry,
                      p_a        in number,
                      p_b        in number,
                      p_c        in number,
                      p_d        in number,
                      p_e        in number,
                      p_f        in number,
                      p_g        in number,
                      p_h        in number,
                      p_i        in number,
                      p_xoff     in number,
                      p_yoff     in number,
                      p_zoff     in number)
    Return mdsys.sdo_geometry
  Is
      -- Transformation matrix is represented by:
      -- / a  b  c  xoff \
      -- | d  e  f  yoff |
      -- | g  h  i  zoff |
      -- \ 0  0  0     1 /
      --
      -- For 2D only need to supply: a, b, d, e, xoff, yoff
      v_A          SYS.UTL_NLA_ARRAY_DBL :=
                   SYS.UTL_NLA_ARRAY_DBL(
                       p_a,            p_d,    NVL(p_g,0),    0,
                       p_b,            p_e,    NVL(p_h,0),    0,
                       NVL(p_c,0), NVL(p_f,0), NVL(p_i,1),    0,
                       p_xoff,         p_yoff, NVL(p_zoff,0), 1 );
      v_C           SYS.UTL_NLA_ARRAY_DBL;  -- Coordinates to be transformed
      v_ipiv        SYS.utl_nla_array_int := SYS.utl_nla_array_int(0,0,0,0);
      -- Geometry variables
      v_dims        PLS_Integer;
      v_measure_dim PLS_Integer;
      v_ord         PLS_Integer;
      v_sdo_point   mdsys.sdo_point_type := NULL;
      v_trans_point mdsys.sdo_point_type;
      v_ordinates   mdsys.sdo_ordinate_array := NULL;
      -- Cursor over vertices
      CURSOR c_coordinates( p_geometry in mdsys.sdo_geometry) IS
      SELECT v.*
        FROM TABLE(mdsys.sdo_util.GetVertices(p_geometry)) v;

      Function TransformPoint(p_x in number,
                              p_y in number,
                              p_z in number)
        return mdsys.sdo_point_type
      Is
        v_info        Integer;
        v_point       mdsys.sdo_point_type := mdsys.sdo_point_type(p_x,p_y,p_z);
      Begin
        v_C := SYS.UTL_NLA_ARRAY_DBL(p_x,
                                     p_y,
                                     case when p_z is null then 0 else p_z end,  -- Supply 0 instead of NULL as this will crash LAPACK_GESV
                                     0);
       --  Vertices are transformed as follows:
       --  x' = a*x + b*y + c*z + xoff
       --  y' = d*x + e*y + f*z + yoff
       --  z' = g*x + h*y + i*z + zoff
       --
       SYS.UTL_NLA.LAPACK_GESV (
          n      => 4,      -- A number of rows and columns
          nrhs   => 1,      -- B number of columns
          a      => v_A,    -- matrix A
          lda    => 4,      -- max(1, n)
          ipiv   => v_ipiv, -- pivot indices (set to zeros)
          b      => v_C,    -- matrix Result
          ldb    => 4,      -- ldb >= max(1,n)
          info   => v_info, -- operation status (0=sucess)
          pack   => 'C'     -- how the matrices are stored
                            -- (C=column-wise)
        );
        IF (v_info = 0) THEN
          v_point.x := v_C(1);
          v_point.y := v_C(2);
          v_point.z := case when p_z is null then null else v_C(3) end;  -- Return correct value only if one supplied.
        ELSE
          raise_application_error( -20001,
                                   'Matrix transformation by LAPACK_GESV failed with error ' || v_info,
                                   False );
        END IF;
        RETURN v_point;
      End TransformPoint;

  Begin
      If ( p_geometry is NULL ) Then
        Return p_geometry;
      End If;
      If ( p_a is null OR
           p_b is null OR
           p_d is null OR
           p_e is null OR
           p_xoff is null OR
           p_yoff is null ) Then
          RETURN p_geometry;
     End If;

    v_dims        := TRUNC(p_geometry.sdo_gtype/1000,0);
    v_measure_dim := MOD(trunc(p_geometry.sdo_gtype/100),10);

    -- Transform any point in the geometry object
    If ( p_geometry.sdo_point is not null ) Then
      v_sdo_point := TransformPoint(p_geometry.sdo_point.x,
                                    p_geometry.sdo_point.y,
                                    p_geometry.sdo_point.z);
    End If;

    If ( p_geometry.sdo_ordinates is not null ) Then
      v_ordinates := new mdsys.sdo_ordinate_array(1);
      v_ordinates.DELETE;
      v_ordinates.EXTEND(p_geometry.sdo_ordinates.count);
      v_ord    := 1;
      -- Loop around coordinates and apply matrix to them.
      <<for_all_coords>>
      FOR coord in c_coordinates( p_geometry ) loop
        v_trans_point := TransformPoint(coord.x,
                                        coord.y,
                                        case when v_measure_dim=3 then null else coord.z end);
        v_ordinates(v_ord) := v_trans_point.x; v_ord := v_ord + 1;
        v_ordinates(v_ord) := v_trans_point.y; v_ord := v_ord + 1;
        if ( v_dims >= 3 ) Then
           v_ordinates(v_ord) := v_trans_point.z; v_ord := v_ord + 1;
        end if;
        if ( v_dims >= 4 ) Then
           v_ordinates(v_ord) := coord.w; v_ord := v_ord + 1;
        end if;

      END LOOP for_all_coords;
    End If;
    Return mdsys.sdo_geometry(p_geometry.sdo_gtype,
                              p_geometry.sdo_srid,
                              v_sdo_point,
                              p_geometry.sdo_elem_info,
                              v_ordinates
                              );
  End ST_Affine;

  /* Pure PLSQ Implementation */

  /* Shared Local Functions */

  PROCEDURE ADD_Coordinate( p_ordinates  in out nocopy mdsys.sdo_ordinate_array,
                            p_dim        in number,
                            p_coord_x    in number,
                            p_coord_y    in number,
                            p_coord_z    in number,
                            p_coord_w    in number,
                            p_measured   in boolean := false)
  As
  Begin
    IF ( p_dim >= 2 ) Then
      p_ordinates.extend(2);
      p_ordinates(p_ordinates.count-1) := p_coord_x;
      p_ordinates(p_ordinates.count  ) := p_coord_y;
    END IF;
    IF ( p_dim >= 3 ) Then
      p_ordinates.extend(1);
      p_ordinates(p_ordinates.count)   := p_coord_z;
    END IF;
    IF ( p_dim = 4 ) Then
      p_ordinates.extend(1);
      p_ordinates(p_ordinates.count)   := p_coord_w;
    END IF;
  END ADD_Coordinate;

  Function isOrientedPoint( p_elem_info in mdsys.sdo_elem_info_array)
    return integer
  is
  Begin
    /* Single Oriented Point
    // Sdo_Elem_Info = (1,1,1, 3,1,0), SDO_ORDINATE_ARRAY(12,14, 0.3,0.2)));
    // The Final 1,0 In 3,1,0 Indicates That This Is An Oriented Point.
    //
    // Multi Oriented Point
    // Sdo_Elem_Info_Array(1,1,1, 3,1,0, 5,1,1, 7,1,0), Sdo_Ordinate_Array(12,14, 0.3,0.2, 12,10, -1,-1)));
    */
    If ( P_Elem_Info Is Null ) Then
       Return 0;
    Elsif ( P_Elem_Info.Count >= 6 ) Then
       Return case when ( P_Elem_Info(2) = 1 ) /* Point */          And
                        ( P_Elem_Info(3) = 1 ) /* Single Point */   And
                        ( P_Elem_Info(5) = 1 ) /* Oriented Point */ And
                        ( P_Elem_Info(6) = 0 )
                   then 1
                   else 0
              end;
    Else
       Return 0;
    End If;
  End isOrientedPoint;

  Function isMeasured( p_gtype in number )
    return boolean
  is
  Begin
    Return CASE WHEN MOD(trunc(p_gtype/100),10) = 0
                THEN False
                ELSE True
             END;
  End isMeasured;

  FUNCTION Move( p_geometry       IN MDSYS.SDO_GEOMETRY,
                 p_deltaX         IN NUMBER,
                 p_deltaY         IN NUMBER,
                 p_deltaZ         IN NUMBER             := NULL,
                 p_decimal_digits IN Integer            := 8,
                 p_filter_mbr     IN MDSYS.SDO_GEOMETRY := NULL
                )
    Return MDSYS.SDO_GEOMETRY
  Is
    v_geometry    mdsys.sdo_geometry       := p_geometry;
    v_Filter      sdo_geometry;
    v_filter_mask varchar2(100) := 'INSIDE'; /* Always - See GEOM.MOVE for richer options */
    v_ordinates   mdsys.sdo_ordinate_array := mdsys.sdo_ordinate_array();
    v_ord         pls_integer;
    v_gtype       number;
    v_dims        number;
    v_isMeasured  boolean;
    v_n_points    pls_integer;

    Function Contains( p_X In Number,
                       p_Y In Number )
      Return Boolean
        -- @function  : Contains
        -- @version   : 1.0
        -- @precis    : Method that tests if a point is within the current MBR
        -- @return    : True or False
        -- @returntype: Boolean
        -- @history   : SGG November 2004 - Original Coding
        -- @history   : SGG February 2018 - Removed MBR Object Type dependency.
    Is
    Begin
      Return (p_X >= v_filter.sdo_ordinates(1) /*MinX*/ And
              p_X <= v_filter.sdo_ordinates(3) /*MaxX*/ And
              p_Y >= v_filter.sdo_ordinates(2) /*MinY*/ And
              p_Y <= v_filter.sdo_ordinates(4) /*MaxY*/
             );
    End Contains;

  Begin
    If ( p_geometry is NULL ) Then
      RETURN p_geometry;
    End If;
    If ( p_filter_mbr IS NOT NULL ) Then
      v_filter := SDO_GEOM.SDO_MBR(p_filter_mbr);
    Else
      v_filter := SDO_GEOM.SDO_MBR(p_geometry);
    End If;

    v_dims       := TRUNC(p_geometry.sdo_gtype/1000,0);
    v_gtype      := Mod(p_geometry.sdo_gtype,10);
    v_isMeasured := isMeasured(p_geometry.sdo_gtype);

    If ( p_geometry.sdo_point is not null ) Then
      IF ( Contains(p_geometry.sdo_point.X,
                    p_geometry.sdo_point.Y) ) Then
        -- Move Point
        v_geometry.Sdo_Point.X := v_geometry.Sdo_Point.X+p_deltaX;
        v_geometry.Sdo_Point.Y := v_geometry.Sdo_Point.Y+p_deltaY;
        If (     v_dims > 2
             And p_deltaZ is not null
             And v_geometry.Sdo_Point.Z is not null ) Then
           v_geometry.Sdo_Point.Z := v_geometry.Sdo_Point.Z+p_deltaZ;
        End If;
      End If;
      If ( v_gtype = 1 ) Then
        Return mdsys.sdo_geometry(v_geometry.sdo_gtype,
                                  v_geometry.sdo_srid,
                                  v_geometry.sdo_point,
                                  v_geometry.sdo_elem_info,
                                  v_ordinates
                                  );
      End If;
    End If;

    v_n_points := p_geometry.sdo_ordinates.count / v_dims;
    For i In 1..v_n_points Loop
      v_ord := 1 + ((i - 1) * v_dims);
      IF     v_filter is not null
         and v_filter.sdo_ordinates is not null
         and Contains(p_geometry.sdo_ordinates(v_ord),
                      p_geometry.sdo_ordinates(v_ord+1)) THEN
        ADD_Coordinate(v_ordinates,
                       v_dims,
                       p_geometry.sdo_ordinates(v_ord)   + p_deltaX,
                       p_geometry.sdo_ordinates(v_ord+1) + p_deltaY,
                       case when v_dims = 3 then p_geometry.sdo_ordinates(v_ord+2) + p_deltaZ else null end,
                       case when v_dims = 4 then p_geometry.sdo_ordinates(v_ord+3) else null end,
                       v_isMeasured);
      ELSE
        ADD_Coordinate(v_ordinates,
                       v_dims,
                       p_geometry.sdo_ordinates(v_ord),
                       p_geometry.sdo_ordinates(v_ord+1),
                       case when v_dims = 3 then p_geometry.sdo_ordinates(v_ord+2) else null end,
                       case when v_dims = 4 then p_geometry.sdo_ordinates(v_ord+3) else null end,
                       v_isMeasured);
      END IF;
    End Loop;
    Return mdsys.sdo_geometry(v_geometry.sdo_gtype,
                              v_geometry.sdo_srid,
                              v_geometry.sdo_point,
                              v_geometry.sdo_elem_info,
                              v_ordinates
                              );
  End Move;

  FUNCTION Scale( p_geometry       IN MDSYS.SDO_GEOMETRY,
                  p_XFactor        IN NUMBER,
                  p_YFactor        IN NUMBER,
                  p_ZFactor        IN NUMBER  := NULL,
                  p_decimal_digits IN Integer := 8
                   )
    Return MDSYS.SDO_GEOMETRY
  Is
    v_ordinates mdsys.sdo_ordinate_array  := new mdsys.sdo_ordinate_array();
    v_gtype     number;
    v_dims      number;
    v_round     mdsys.sdo_point_type := new mdsys.sdo_point_type(p_decimal_digits,p_decimal_digits,p_decimal_digits);
    v_factor    mdsys.sdo_point_type := new mdsys.sdo_point_type(p_XFactor,p_YFactor,p_ZFactor);
    v_geometry  mdsys.sdo_geometry := p_geometry;

    CURSOR c_coordinates( p_geometry in mdsys.sdo_geometry,
                          p_XFactor   in number,
                          p_YFactor   in number,
                          p_ZFactor   in number,
                          p_round    in mdsys.sdo_point_type) IS
    SELECT round(a.x*p_XFactor,p_round.x) as x,
           round(a.y*p_YFactor,p_round.y) as y,
           CASE WHEN MOD(trunc(p_geometry.sdo_gtype/100),10) <> 3
                THEN case when a.z is null
                          then null
                          else case when p_ZFactor is null
                                    then a.z
                                    else round(a.z*p_ZFactor,p_round.z)
                                end
                      end
                ELSE NULL
            END as z,
           CASE WHEN MOD(trunc(p_geometry.sdo_gtype/100),10) = 3
                THEN a.z
                ELSE a.w
            END as w,
            rownum as id
      FROM TABLE(mdsys.sdo_util.GetVertices(p_geometry)) a;

  Begin
    If ( p_geometry is NULL ) Then
      RETURN p_geometry;
    End If;

    If ( p_XFactor = NULL ) THEN
      v_factor.X := 1.0;
    End If;
    If ( p_YFactor = NULL ) THEN
      v_factor.Y := 1.0;
    End If;
    If ( p_ZFactor = NULL ) THEN
      v_factor.Z := 1.0;
    End If;

    If ( v_factor.X = 1.0 and v_factor.Y = 1.0 and v_factor.Z = 1.0 ) Then
      return p_geometry;
    End If;

    -- Compute needed variables
    v_dims := TRUNC(p_geometry.sdo_gtype/1000,0);
    v_gtype := Mod(p_geometry.sdo_gtype,10);

    -- Assign rounding factors for when comparing coordinates
    v_round.x := NVL(p_decimal_digits,8);
    v_round.y := NVL(p_decimal_digits,8);
    If ( v_dims > 2 And Not isMeasured(p_geometry.sdo_gtype) ) Then
      v_round.z := NVL(p_decimal_digits,8);
    End If;

    If ( p_geometry.sdo_point is not null ) Then
      v_geometry.Sdo_Point.X := round(v_geometry.Sdo_Point.X * v_factor.X,v_round.x);
      v_geometry.Sdo_Point.Y := round(v_geometry.Sdo_Point.Y * v_factor.Y,v_round.y);
      If (     v_dims > 2
           And v_Factor.Z is not null
           And v_geometry.Sdo_Point.Z is not null ) Then
        v_geometry.Sdo_Point.Z := ROUND(v_geometry.Sdo_Point.Z * v_factor.Z,v_round.z);
      End If;
      If ( v_gtype = 1 ) Then
        Return mdsys.sdo_geometry(v_geometry.sdo_gtype,
                                  v_geometry.sdo_srid,
                                  v_geometry.sdo_point,
                                  v_geometry.sdo_elem_info,
                                  v_ordinates
                                  );
      End If;
    End If;

    For rec in c_coordinates(v_geometry,
                             v_factor.X,
                             v_Factor.Y,
                             v_Factor.Z,
                             v_round) Loop
          ADD_Coordinate(v_ordinates,
                         v_dims,
                         rec.x,
                         rec.y,
                         rec.z,
                         rec.w,
                         isMeasured(p_geometry.sdo_gtype));
    End Loop;

    Return mdsys.sdo_geometry(v_geometry.sdo_gtype,
                              v_geometry.sdo_srid,
                              v_geometry.sdo_point,
                              v_geometry.sdo_elem_info,
                              v_ordinates
                              );
  End Scale;

  Function Rotate( p_geometry       IN MDSYS.SDO_GEOMETRY,
                   p_rX             IN number,
                   p_rY             IN number,
                   p_angle          IN number,  -- 0 to 360 degrees
                   p_decimal_digits IN Integer := 8
                 )
    Return MDSYS.SDO_GEOMETRY
  Is
     v_geometry        mdsys.sdo_geometry := p_geometry;
     v_mbr             mdsys.sdo_geometry;
     v_ordinates       mdsys.sdo_ordinate_array;
     v_round           mdsys.sdo_point_type := new mdsys.sdo_point_type(p_decimal_digits,p_decimal_digits,p_decimal_digits);
     v_rotation_params mdsys.sdo_point_type := new mdsys.sdo_point_type(p_rX,p_rY,p_angle);
     v_cos_angle       number;
     v_sin_angle       number;
     v_new_x           number := 0;
     v_new_y           number := 0;
     v_gtype           number;
     v_dims            number;
     WRONG_ROTATION    EXCEPTION;

     CURSOR c_coordinates( p_geometry  in mdsys.sdo_geometry,
                           p_X         in number,
                           p_Y         in number,
                           p_cos_angle in number,
                           p_sin_angle in number,
                           p_round     in mdsys.sdo_point_type )
     IS
     SELECT round(((a.x - p_x) * p_cos_angle -
                   (a.y - p_y) * p_sin_angle) + p_x,
                  p_round.X) as x,
            round(((a.x - p_x) * v_sin_angle  +
                   (a.y - p_y) * v_cos_angle) + p_y,
                  p_round.Y) as y,
            CASE WHEN MOD(trunc(p_geometry.sdo_gtype/100),10) <> 3
                 THEN case when a.z is null
                           then null
                           else a.z
                       end
                 ELSE NULL
             END as z,
            CASE WHEN MOD(trunc(p_geometry.sdo_gtype/100),10) = 3
                 THEN a.z
                 ELSE a.w
             END as w,
            rownum as id
       FROM TABLE(mdsys.sdo_util.GetVertices(p_geometry)) a;

      CURSOR c_rotate_oriented_points (p_geometry  in mdsys.sdo_geometry,
                                       p_X         in number,
                                       p_Y         in number,
                                       p_cos_angle in number,
                                       p_sin_angle in number,
                                       p_round     in mdsys.sdo_point_type,
                                       p_dims      in integer)
      IS
      SELECT case when MOD(e.coord_id,2) = 1
                  then (e.x - LAG(e.x,1) OVER (ORDER BY e.coord_id))
                  else e.x
              end as x,
             case when MOD(e.coord_id,2) = 1
                  then (e.y - LAG(e.y,1) OVER (ORDER BY e.coord_id))
                  else e.y
              end as y,
             e.z,
             e.w,
             e.coord_id as id
        FROM ( SELECT round(((d.x - p_x) * v_cos_angle -
                             (d.y - p_y) * v_sin_angle ) + p_x,
                            p_round.X) as x,
                      round(((d.x - p_x) * v_sin_angle +
                             (d.y - p_y) * v_cos_angle ) + p_y,
                            p_round.Y) as y,
                      d.z,d.w,d.coord_id
                FROM (SELECT c.coord_id,
                             case when MOD(c.coord_id,2) = 1
                                  then c.x + (LAG(c.x,1) OVER (ORDER BY c.coord_id))
                                  else c.x
                                  end as x,
                             case when MOD(coord_id,2) = 1
                                  then c.y + (LAG(c.y,1) OVER (ORDER BY c.coord_id))
                                  else c.y
                                  end as y,
                             c.z,c.w
                        FROM (SELECT b.coord_id, sum(b.x) as x,sum(b.y) as y,sum(b.z) as z,sum(b.w) as w
                                FROM (SELECT  floor((rownum-1)/p_dims) as coord_id,
                                             case when mod(rownum-1,p_dims) = 0 then a.column_value else null end as x,
                                             case when mod(rownum-1,p_dims) = 1 then a.column_value else null end as y,
                                             case when mod(rownum-1,p_dims) = 2 then a.column_value else null end as z,
                                             case when mod(rownum-1,p_dims) = 3 then a.column_value else null end as w
                                        FROM TABLE(p_geometry.sdo_ordinates) a
                                      ) b
                                GROUP BY b.coord_id
                                ORDER BY 1
                              ) c
                     ) d
          ) e;

  Begin
    If ( p_geometry is NULL ) Then
      RETURN p_geometry;
    End If;

    If ( p_angle is NULL ) Or ( p_angle NOT BETWEEN -360 AND 360 ) Then
      raise WRONG_ROTATION;
    End If;

    v_mbr               := SDO_GEOM.SDO_MBR(p_geometry);
    v_dims              := TRUNC(p_geometry.sdo_gtype/1000,0);
    v_gtype             := Mod(p_geometry.sdo_gtype,10);
    IF ( p_rX is NULL or p_rY is NULL ) Then
      -- Get Center of shape's MBR as point around which to rotate
      -- Should extend geometry package to return center of MBR (called ENVELOPE in geometry)
      v_rotation_params.X := v_mbr.sdo_ordinates(1) + (v_mbr.sdo_ordinates(3)-v_mbr.sdo_ordinates(1))/2.0;
      v_rotation_params.Y := v_mbr.sdo_ordinates(2) + (v_mbr.sdo_ordinates(4)-v_mbr.sdo_ordinates(2))/2.0;
    ELSE
      v_rotation_params.X := p_rX;
      v_rotation_params.Y := p_rY;
    END IF;
    v_rotation_params.Z := NVL(p_angle,0.0);
    v_cos_angle         := COS(ST_Radians(v_rotation_params.Z));
    v_sin_angle         := SIN(ST_Radians(v_rotation_params.Z));
    v_round.x           := NVL(p_decimal_digits,8);
    v_round.y           := NVL(p_decimal_digits,8);
    v_round.z           := NVL(p_decimal_digits,8);

    If ( p_geometry.sdo_point is not null ) Then
      If NOT ( v_rotation_params.X IS NULL OR v_rotation_params.Y IS NULL ) Then
        -- x' = x Cos(¸) - y Sin(¸)
        -- y' = x Sin(¸) + y Cos(¸)
        v_new_x := (v_rotation_params.X + (
                   ((v_geometry.Sdo_Point.x - v_rotation_params.X) * v_cos_angle) -
                   ((v_geometry.Sdo_Point.y - v_rotation_params.Y) * v_sin_angle)
                   ));
        v_new_y := (v_rotation_params.Y + (
                   ((v_geometry.Sdo_Point.x - v_rotation_params.X) * v_sin_angle) +
                   ((v_geometry.Sdo_Point.y - v_rotation_params.Y) * v_cos_angle)
                   ));
        v_geometry.Sdo_Point.X := round( v_new_x, v_round.X);
        v_geometry.Sdo_Point.Y := round( v_new_y, v_round.Y);
      End If;
    End If;

    If ( p_geometry.sdo_elem_info IS NOT NULL ) Then
      v_ordinates := new mdsys.sdo_ordinate_array();
      If ( IsOrientedPoint(P_Geometry.Sdo_Elem_Info)=1 ) Then
        For rec in c_rotate_oriented_points(v_geometry,
                                            v_rotation_params.X,
                                            v_rotation_params.Y,
                                            v_cos_angle,
                                            v_sin_angle,
                                            v_round,
                                            v_dims) Loop
            ADD_Coordinate(v_ordinates,
                           v_dims,
                           rec.x,
                           rec.y,
                           rec.z,
                           rec.w,
                           isMeasured(p_geometry.sdo_gtype)
                          );
        End Loop;
      Else
        v_ordinates := new mdsys.sdo_ordinate_array();
        For rec in c_coordinates(v_geometry,
                                 v_rotation_params.X,
                                 v_rotation_params.Y,
                                 v_cos_angle,
                                 v_sin_angle,
                                 v_round) Loop
            ADD_Coordinate(v_ordinates,
                           v_dims,
                           rec.x,
                           rec.y,
                           rec.z,
                           rec.w,
                           isMeasured(p_geometry.sdo_gtype));
        End Loop;
      End If;
    End If;
    Return mdsys.sdo_geometry(v_geometry.sdo_gtype,
                              v_geometry.sdo_srid,
                              v_geometry.sdo_point,
                              v_geometry.sdo_elem_info,
                              v_ordinates
                              );
    EXCEPTION
      WHEN WRONG_ROTATION THEN
         raise_application_error(-20001,
                                 'Rotation value must be supplied and must be between 0 and 360.',
                                 TRUE);
         RETURN p_geometry;
  End Rotate;

End Affine;
/
show errors

set serveroutput on size unlimited
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
   v_OK       boolean := true;
   v_obj_name varchar2(30) := 'AFFINE';
BEGIN
   FOR rec IN (select object_name || '.' || object_Type as package_name, status 
                 from user_objects
                where object_name = v_obj_name) LOOP
      IF ( rec.status = 'VALID' ) Then
         dbms_output.put_line('Package ' || USER || '.' || rec.package_name || ' is valid.');
      ELSE
         dbms_output.put_line('Package ' || USER || '.' || rec.package_name || ' is invalid.');
         v_ok := false;
      END IF;
   END LOOP;
   IF ( NOT v_OK ) THEN
      RAISE_APPLICATION_ERROR(-20000,v_obj_name || ' failed to install.');
   END IF;
END;
/
SHOW ERRORS

grant execute on AFFINE to public;

QUIT;

