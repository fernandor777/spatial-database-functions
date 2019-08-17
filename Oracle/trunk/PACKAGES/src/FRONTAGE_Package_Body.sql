create or replace 
package body FRONTAGE 
AS

  -- Needs external types
  -- create or replace TYPE SPDBA.TClockFace IS OBJECT (
  --      clockface varchar2(20),
  --      distance  sdo_geometry,
  --      centroid  sdo_geometry,
  --      vector    sdo_geometry
  -- );
  
  Function DD2TIME(dDecDeg in Number)
    RETURN VARCHAR2
  IS 
    vDecDeg NUMBER := Round((dDecDeg/360)*12,2);
    IDEG    INTEGER;
    iMin    INTEGER;
  BEGIN
    IDEG := TRUNC(VDECDEG);
    IMIN := (VDECDEG - IDEG) * 60;
    RETURN TO_CHAR(IDEG) || 'Hr ' || TO_CHAR(IMIN) ||'min';
  END DD2TIME;

  /**Compass point	Ordinal direction abbreviations	Clock face direction
    * North	N	0 Hr 00 min 00 sec
    * North-northeast	NNE	0 Hr 45 min 00 sec
    * Northeast	NE	1 Hr 30 min 00 sec
    * East-northeast	ENE	2 Hr 15 min 00 sec
    * East	E	3 Hr 00 min 00 sec
    * East-southeast	ESE	3 Hr 45 min 00 sec
    * Southeast	SE	4 Hr 30 min 00 sec
    * South-southeast	SSE	5 Hr 15 min 00 sec
    * South	S	6 Hr 00 min 00 sec
    * South-southwest	SSW	6 Hr 45 min 00 sec
    * Southwest	SW	7 Hr 30 min 00 sec
    * West-southwest	WSW	8 Hr 15 min 00 sec
    * West	W	9 Hr 00 min 00 sec
    * West-northwest	WNW	9 Hr 45 min 00 sec
    * Northwest	NW	10 Hr 30 min 00 sec
    * North-northwest	NNW	11 Hr 15 min 00 sec
    *
    * Generated using:
    select midBearing,
           'when v_bearing between ' || to_char(midBearing-11.25) || ' AND ' || to_char(mod(midBearing + 11.25,360)) || ' then ''' || substr(ordinal,1,instr(ordinal,':')-1)||'''' ,
           'when v_bearing between ' || to_char(midBearing-11.25) || ' AND ' || to_char(mod(midBearing + 11.25,360)) || ' then ''' || substr(ordinal,instr(ordinal,':')+1)||''''
      from (select midBearing,
                   DECODE(midBearing/22.5,
                   16,'North:N',
                    1,'North-NorthEast:NNE',
                    2,'NorthEast:NE',
                    3,'East-NorthEast:ENE',
                    4,'East:E',
                    5,'East-SouthEast:ESE',
                    6,'SouthEast:SE',
                    7,'South-SouthEast:SSE',
                    8,'South:S',
                    9,'South-SouthWest:SSW',
                   10,'SouthWest:SW',
                   11,'West-SouthWest:WSW',
                   12,'West:W',
                   13,'West-NorthWest:WNW',
                   14,'NorthWest:NW',
                   15,'North-NorthWest:NNW',
                   null) as ordinal
              from (select (22.5*level) as midbearing
                      from dual
                      connect by level < 17
                   )
           )
    order by midBearing;
  * 
  * Testing
  *
  *   select 2*level as bearing,
  *        Frontage.CompassPoint(2*level,0) as compassPoint,
  *        Frontage.CompassPoint(2*level,1) as compassPointFull
  *   from dual
  * connect by level < 181;
  *
  **/
  Function CompassPoint(p_bearing      in number,
                        p_abbreviation in integer default 1)
    Return varchar2
  As
    v_bearing number;
  Begin
    If ( p_bearing is null ) then
      Return null;
    End If;
    v_bearing := round(abs(p_bearing),2); 
    Return case when NVL(p_abbreviation,1) <> 0 
                then case when v_bearing between   0.00 AND  11.25 then 'North'
                          when v_bearing between  11.25 AND  33.75 then 'North-NorthEast'
                          when v_bearing between  33.75 AND  56.25 then 'NorthEast'
                          when v_bearing between  56.25 AND  78.75 then 'East-NorthEast'
                          when v_bearing between  78.75 AND 101.25 then 'East'
                          when v_bearing between 101.25 AND 123.75 then 'East-SouthEast'
                          when v_bearing between 123.75 AND 146.25 then 'SouthEast'
                          when v_bearing between 146.25 AND 168.75 then 'South-SouthEast'
                          when v_bearing between 168.75 AND 191.25 then 'South'
                          when v_bearing between 191.25 AND 213.75 then 'South-SouthWest'
                          when v_bearing between 213.75 AND 236.25 then 'SouthWest'
                          when v_bearing between 236.25 AND 258.75 then 'West-SouthWest'
                          when v_bearing between 258.75 AND 281.25 then 'West'
                          when v_bearing between 281.25 AND 303.75 then 'West-NorthWest'
                          when v_bearing between 303.75 AND 326.25 then 'NorthWest'
                          when v_bearing between 326.25 AND 348.75 then 'North-NorthWest'
                          when v_bearing between 348.75 AND 360.00 then 'North'
                          else null
                      end
                else case when v_bearing between   0.00 AND  11.25 then 'N'
                          when v_bearing between  11.25 AND  33.75 then 'NNE'
                          when v_bearing between  33.75 AND  56.25 then 'NE'
                          when v_bearing between  56.25 AND  78.75 then 'ENE'
                          when v_bearing between  78.75 AND 101.25 then 'E'
                          when v_bearing between 101.25 AND 123.75 then 'ESE'
                          when v_bearing between 123.75 AND 146.25 then 'SE'
                          when v_bearing between 146.25 AND 168.75 then 'SSE'
                          when v_bearing between 168.75 AND 191.25 then 'S'
                          when v_bearing between 191.25 AND 213.75 then 'SSW'
                          when v_bearing between 213.75 AND 236.25 then 'SW'
                          when v_bearing between 236.25 AND 258.75 then 'WSW'
                          when v_bearing between 258.75 AND 281.25 then 'W'
                          when v_bearing between 281.25 AND 303.75 then 'WNW'
                          when v_bearing between 303.75 AND 326.25 then 'NW'
                          when v_bearing between 326.25 AND 348.75 then 'NNW'
                          when v_bearing between 348.75 AND 360.00 then 'N'
                          else null
                      end
           end;
  End CompassPoint;
  
  Function ST_GetNumRings(p_geometry  in mdsys.sdo_geometry,
                          p_ring_type in integer /* 0 = ALL; 1 = OUTER; 2 = INNER */ )
    Return Number
  Is
    v_elements   pls_integer := 0;
    v_ring_count pls_integer := 0;
    v_etype      pls_integer;
    v_ring_type  pls_integer := case when ( p_ring_type is null OR
                                            p_ring_type not in (0,1,2) )
                                     Then 0
                                     Else p_ring_type
                                 End;
  Begin
    If ( p_geometry is not null ) Then
      v_elements := ( ( p_geometry.sdo_elem_info.COUNT / 3 ) - 1 );
      <<element_extraction>>
      FOR v_i IN 0 .. v_elements LOOP
        v_etype := p_geometry.sdo_elem_info(v_i * 3 + 2);
        If ( ( v_etype in (1003,1005,2003,2005) and 0 = v_ring_type )
          OR ( v_etype in (1003,1005)           and 1 = v_ring_type )
          OR ( v_etype in (2003,2005)           and 2 = v_ring_type ) ) Then
           v_ring_count := v_ring_count + 1;
        End If;
      END LOOP element_extraction;
    End If;
    Return v_ring_count;
  End ST_GetNumRings;

  Function ST_HasCircularArcs(p_elem_info in mdsys.sdo_elem_info_array)
    return integer
  Is
     v_elements  number;
  Begin
     v_elements := ( ( p_elem_info.COUNT / 3 ) - 1 );
     <<element_extraction>>
     for v_i IN 0 .. v_elements LOOP
        if ( ( /* etype */         p_elem_info(v_i * 3 + 2) = 2 AND
               /* interpretation*/ p_elem_info(v_i * 3 + 3) = 2 )
             OR
             ( /* etype */         p_elem_info(v_i * 3 + 2) in (1003,2003) AND
               /* interpretation*/ p_elem_info(v_i * 3 + 3) IN (2,4) ) ) then
               return 1;
        end If;
     end loop element_extraction;
     return 0;
  End ST_hasCircularArcs;

  Function ST_BearingPlanar(p_x1 in number,
                            p_y1 in number,
                            p_x2 in number,
                            p_y2 in number)
    Return Number 
  IS
    v_bearing Number;
    v_delta_x Number;
    v_delta_y Number;
  BEGIN
    If (   p_x1 Is Null
        or p_y1 Is Null
        or p_x2 Is Null
        or p_y2 Is null ) THEN
       Return Null;
    End If;
    If ( (p_x1 = p_x2) And (p_y1 = p_y2) ) Then
       Return Null;
    End If;
    v_delta_x := p_x2 - p_x1;
    v_delta_y := p_y2 - p_y1;
    If ( v_delta_x = 0 ) Then
        If ( v_delta_y < 0 ) Then
            v_bearing := COGO.PI();
        Else
            v_bearing := 0;
        End If;
    Else
        v_bearing := -aTan(v_delta_y / v_delta_x) + COGO.PI() / 2;
    End If;
    If ( v_delta_x < 0 ) Then
        v_bearing := v_bearing + COGO.PI();
    End If;
    Return v_bearing;
  End ST_BearingPlanar;

  Function ST_Bearing(p_line in mdsys.sdo_geometry)
  Return Number
  As
  Begin
    if (p_line is null or p_line.get_gtype() <> 2) Then
      Return null;
    End If; 
    return frontage.st_bearingPlanar(
                       p_line.sdo_ordinates(1),
                       p_line.sdo_ordinates(2),
                       p_line.sdo_ordinates(p_line.sdo_ordinates.count-1),
                       p_line.sdo_ordinates(p_line.sdo_ordinates.count));
  End ST_Bearing;
  
  Function ST_BearingGeodetic(p_Start_Point in MDSYS.SDO_GEOMETRY,
                              p_End_Point   in MDSYS.SDO_GEOMETRY)
  Return Number
  As
    v_v_bearing Number;
    v_dTilt    Number;
  Begin
    If (p_Start_Point is null or p_End_Point is null) Then
       Return null;
    End If;
    If (p_Start_Point.sdo_srid is null or p_End_Point.sdo_srid is null) Then
       Return null;
    End If;
    MDSYS.SDO_UTIL.BEARING_TILT_FOR_POINTS(
         p_start_point,
         p_end_point,
         0.05,          -- standard geodetic tolerance
         v_v_bearing,
         v_dTilt);
    -- DEBUG dbms_output.put_line('bearing is ' || v_v_bearing);
    Return v_v_bearing;
  End ST_BearingGeodetic;
  
  Function ST_BearingGreatCircle(p_lon1 in number,
                                 p_lat1 in number,
                                 p_lon2 in number,
                                 p_lat2  in number)
    Return number 
  Is
     c_i_not_RADIANS  CONSTANT NUMBER        := -20102;
     c_s_not_RADIANS  CONSTANT VarChar2(100) := 'Supplied longitude/latitude not in RADIANS.';
     v_dLong     number;
     v_cosC      number;
     v_cosD      number;
     v_C         number;
     V_D         number;
     v_pi        number;
     NOT_RADIANS EXCEPTION; 
     PRAGMA EXCEPTION_INIT(NOT_RADIANS,-20102);
  Begin
     v_pi := COGO.PI();
     IF ( ABS(p_lon1) > v_pi ) OR
        ( ABS(p_lat1) > v_pi ) OR
        ( ABS(p_lon2) > v_pi ) OR
        ( ABS(p_lat2) > v_pi ) THEN
        RAISE NOT_RADIANS;
     END IF;
     v_dLong := p_lon2 - p_lon1;
     v_cosD  := ( sin(p_lat1) * sin(p_lat2) ) +
                ( cos(p_lat1) * cos(p_lat2) * cos(v_dLong) );
     v_D     := acos(v_cosD);
     if ( v_D = 0.0 ) then
       v_D := 0.00000001; -- roughly 1mm
     end if;
     v_cosC  := ( sin(p_lat2) - v_cosD * sin(p_lat1) ) /
                ( sin(v_D) * cos(p_lat1) );
     -- numerical error can result in |cosC| slightly > 1.0
     if ( v_cosC > 1.0 ) then
         v_cosC := 1.0;
     end if;
     if ( v_cosC < -1.0 ) then
         v_cosC := -1.0;
     end if;
     v_C  := 180.0 * acos( v_cosC ) / COGO.PI();
     if ( sin(v_dLong) < 0.0 ) then
         v_C := 360.0 - v_C;
     end if;
     return (round( 100 * v_C ) / 100.0);
     EXCEPTION
       when NOT_RADIANS then
         dbms_output.put_line(c_s_not_RADIANS );
         return 0;
       when VALUE_ERROR then
         DBMS_OUTPUT.PUT_LINE(SQLERRM);
         dbms_output.put_line(p_lon1||','||p_lat1||','||P_LON2||','||p_lat2);
         return -1;
  End ST_BearingGreatCircle;

  Function ST_BearingGreatCircle( P_GEOM in MDSYS.SDO_GEOMETRY )
    Return Number 
  As
  Begin
    Return FRONTAGE.ST_BearingGreatCircle(
               COGO.ST_RADIANS(P_GEOM.SDO_ORDINATES(1)),
               COGO.ST_RADIANS(P_GEOM.SDO_ORDINATES(2)),
               COGO.ST_RADIANS(P_GEOM.SDO_ORDINATES(p_geom.get_Dims()+1)),
               COGO.ST_RADIANS(P_GEOM.SDO_ORDINATES(p_geom.get_Dims()+2))
           );
  End ST_BearingGreatCircle;

  Function ST_RoundOrdinates(p_geom       In MDSYS.SDO_GEOMETRY,
                             p_dec_places In Number Default 3)
    Return MDSYS.SDO_GEOMETRY
  Is
    v_geom       mdsys.sdo_geometry := p_geom; -- Copy so it can be edited
    v_dec_places pls_integer  := NVL(p_dec_places,3);
  Begin
    If ( p_geom is null ) Then
       Return null;
    End If;
    -- Process possibly independent sdo_point object
    If ( v_geom.Sdo_Point Is Not Null ) Then
      v_geom.sdo_point.X := Round(v_geom.sdo_point.x,v_dec_places);
      v_geom.Sdo_Point.Y := Round(v_geom.Sdo_Point.Y,v_dec_places);
      If ( p_geom.get_dims() > 2 ) Then
        v_geom.sdo_point.z := Round(v_geom.sdo_point.z,v_dec_places);
      End If;
    End If;
    -- Now let's round the ordinates
    If ( p_geom.sdo_ordinates is not null ) Then
      <<while_vertex_to_process>>
      For v_i In 1..v_geom.sdo_ordinates.COUNT Loop
         v_geom.sdo_ordinates(v_i) := Round(p_geom.sdo_ordinates(v_i),
                                            v_dec_places);
      End Loop while_vertex_to_process;
    End If;
    Return v_geom;
  End ST_RoundOrdinates;

  Function ST_Centroid_L(P_Geometry In Mdsys.Sdo_Geometry,
                         P_Option   In Varchar2 := 'LARGEST',
                         P_Round_X  In Pls_Integer := 3,
                         P_Round_Y  In Pls_Integer := 3,
                         p_round_z  IN pls_integer := 2,
                         P_Unit     In Varchar2 Default Null)
    Return MDSYS.SDO_GEOMETRY 
  AS
    c_s_unsupported     Constant VarChar2(100) := 'Unsupported geometry type (*GTYPE*)';
    c_s_option_value    Constant VarChar2(100) := 'p_option value (*VALUE*) must be SMALLEST,LARGEST(Default),MULTI.';
    C_S_NULL_GEOMETRY  CONSTANT VARCHAR2(100) := 'Input geometry must not be null';
    C_S_LINECENTROID   CONSTANT VARCHAR2(250) := 'sdo_centroid calculation failed: couldn''t find segment containing centroid.';    

    V_Option_Value      Varchar2(10) := Substr(Trim(Both ' ' From Nvl(P_Option,'LARGEST')),1,10);
    v_current_meas      number :=0;
    V_Centroid_Len_Meas Pls_Integer :=0;
    v_position_as_ratio number := 0.5;   
    v_NumElems          pls_integer;
    v_Dims              pls_integer;
    v_numVertices       pls_integer;
    v_egeom             mdsys.sdo_geometry;
    V_Centroid          Mdsys.Sdo_Geometry;
    v_tolerance_x       number := 1/POWER(10,nvl(P_ROUND_X,3));
    
    Function Centroid_L(P_Geometry In Mdsys.Sdo_Geometry)
      Return Mdsys.Sdo_Geometry
    As
      v_centroid mdsys.sdo_geometry;
    Begin
      SELECT mdsys.sdo_geometry(i3.gtype,
                                i3.srid,
                                mdsys.sdo_point_type(
                                      round(i3.x2-((i3.x2-i3.x1)*i3.vectorPositionRatio),p_round_x), /* what about geographic data? */
                                      round(i3.y2-((i3.y2-i3.y1)*i3.vectorPositionRatio),p_round_y),
                                      CASE WHEN i3.z2 IS NOT NULL
                                           THEN round(i3.z2-((i3.z2-i3.z1)*vectorPositionRatio),p_round_z)
                                           ELSE NULL
                                       END),
                                null,
                                null) as centroid
        INTO v_centroid
        FROM (SELECT /* select vector/segment "containing" centroid Or mid-point of linestring */
                     I2.gtype,I2.SRID,
                     i2.X1,i2.Y1,i2.Z1,
                     I2.X2,I2.Y2,I2.Z2,
                     (i2.cumLength-i2.pointDistance)/(case when i2.vectorLength = 0 then 0.001 else i2.vectorLength end) as vectorPositionRatio,
                     CASE WHEN pointDistance between
                               case when lag(cumLength,1) over (order by rid) is null
                                    then 0
                                    else lag(cumLength,1) over (order by rid)
                                end
                                and vectorLength +
                                case when lag(cumLength,1) over (order by rid) is null
                                    then 0
                                    else lag(cumLength,1) over (order by rid)
                                end
                          THEN 1
                          ELSE 0
                      END as RightSegment
                FROM (SELECT I1.RID,
                             i1.gtype, i1.SRID,
                             i1.X1,i1.Y1,i1.Z1,
                             i1.X2,i1.Y2,i1.Z2,
                             i1.vectorLength,
                             i1.pointDistance,
                             /* generate cumulative length */
                            SUM(vectorLength) OVER (ORDER BY rid ROWS UNBOUNDED PRECEDING) as cumLength
                        FROM (SELECT ROWNUM AS RID,
                                     a.gtype, a.srid,
                                     a.pointDistance,
                                     v.startCoord.x as X1,
                                     v.startCoord.y as Y1,
                                     v.startCoord.z as Z1,
                                       v.endCoord.x as X2,
                                       v.endCoord.y as Y2,
                                       V.Endcoord.Z As Z2,
                                     Case When P_Unit Is Null 
                                          Then SDO_GEOM.SDO_DISTANCE(
                                                   mdsys.sdo_geometry(a.gtype,a.srid,mdsys.sdo_point_type(v.startCoord.X,v.startCoord.y,v.startCoord.z),NULL,NULL),
                                                   Mdsys.Sdo_Geometry(A.Gtype,A.Srid,Mdsys.Sdo_Point_Type(V.Endcoord.X,V.Endcoord.Y,V.Endcoord.Z),Null,Null),
                                                   v_tolerance_x)
                                          Else SDO_GEOM.SDO_DISTANCE(
                                                   mdsys.sdo_geometry(a.gtype,a.srid,mdsys.sdo_point_type(v.startCoord.X,v.startCoord.y,v.startCoord.z),NULL,NULL),
                                                   Mdsys.Sdo_Geometry(A.Gtype,A.Srid,Mdsys.Sdo_Point_Type(V.Endcoord.X,V.Endcoord.Y,V.Endcoord.Z),Null,Null),
                                                   v_tolerance_x,
                                                   P_Unit)
                                       END AS VECTORLENGTH
                                FROM (SELECT ((P_GEOMETRY.GET_DIMS() * 1000) + 1) AS GTYPE,
                                             P_Geometry.Sdo_Srid As Srid,
                                             Case When P_Unit Is Null 
                                                  Then Mdsys.Sdo_Geom.Sdo_Length(P_Geometry,v_tolerance_x)
                                                  Else Mdsys.Sdo_Geom.Sdo_Length(P_Geometry,v_tolerance_x,p_unit)
                                              end * v_POSITION_AS_RATIO 
                                               as pointDistance
                                        FROM DUAL) a,
                                     TABLE(T_GEOMETRY(p_geometry,0.005,2,1).ST_Segmentize('ALL')) v
                             ) i1
                     ORDER BY rid
                   ) i2
                  )  i3
            WHERE i3.rightSegment = 1
              AND rownum < 2;
      RETURN v_centroid;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
             dbms_output.put_line(c_s_linecentroid);
             RETURN NULL;
         --WHEN OTHERS THEN
         --    dbms_output.put_line(SQLERRM);
         --    RETURN NULL;
    End Centroid_L;

  Begin  
    If (P_Geometry Is Null) Then
       Dbms_Output.Put_Line(C_S_NULL_GEOMETRY);
       Return null;
    End If;
    If ( p_geometry.get_gtype() Not In (2,6) ) Then
       Dbms_Output.Put_Line(Replace(C_S_Unsupported,'*GTYPE*',p_geometry.get_gtype()));
    END IF;
    If ( Not V_Option_Value In ('SMALLEST','LARGEST','MULTI') ) Then
      dbms_output.put_line(REPLACE(c_s_option_value,'*VALUE*',v_option_value));
    End If;
    
    V_NumElems := Sdo_Util.GetNumElem(P_Geometry);
    If (V_NumElems = 1 ) Then
       v_numVertices := sdo_util.getNumVertices(p_geometry);
       If ( v_numVertices = 32 ) Then
         /* Special case. Just average vertices include geodetic (though this is wrong for long line). 
            Recode Geodetic case using SDO_UTIL.BEARING_TILT_FOR_POINTS and sdo_util.point_at_bearing
          */
         v_dims := p_geometry.get_dims();
         Return sdo_geometry(( v_dims * 1000) + 1,
                             p_geometry.sdo_srid,
                             sdo_point_type( (p_geometry.sdo_ordinates(1) + p_geometry.sdo_ordinates(3+(v_dims-2))) / 2.0,
                                             (p_geometry.sdo_ordinates(2) + p_geometry.sdo_ordinates(4+(v_dims-2))) / 2.0,
                                             case when p_geometry.get_dims() = 2 then NULL else (p_geometry.sdo_ordinates(3) + p_geometry.sdo_ordinates(6)) / 2.0 end 
                                           ),
                            NULL,NULL);
       End If;
       return centroid_l(p_geometry);
    End If;
    <<For_All_Linestrings_In_Multi>>
    For V_Elem In 1..V_NumElems Loop
      V_Egeom        := Mdsys.Sdo_Util.Extract(p_geometry,V_Elem);
      V_Current_Meas := Case When P_Unit Is Null Then Sdo_Geom.Sdo_Length(V_Egeom,V_Tolerance_X) Else Sdo_Geom.Sdo_Length(V_Egeom,V_Tolerance_X,P_Unit) End;
      if ( v_elem = 1 ) Then
          if ( v_option_value = 'LARGEST' ) Then
              v_centroid_len_meas := -1;
          Elsif ( V_Option_Value = 'SMALLEST' ) Then
              v_centroid_len_meas := case When P_Unit Is Null Then Sdo_Geom.Sdo_Length(p_geometry,V_Tolerance_X) Else Sdo_Geom.Sdo_Length(p_geometry,V_Tolerance_X,P_Unit) End;
          End If;
      End If;
      If ( v_option_value = 'MULTI' ) Then
          If ( V_Centroid Is Null ) Then
             v_centroid := centroid_l(v_egeom);
          Else
             v_centroid := mdsys.sdo_util.append(v_centroid,centroid_l(v_egeom));
          End If;
      Else -- Smallest or Largest
          If ( V_Option_Value = 'LARGEST' And V_Current_Meas > V_Centroid_Len_Meas ) Then
             v_centroid := centroid_l(v_egeom);
             v_centroid_len_meas := v_current_meas;
          ElsIf ( v_option_value = 'SMALLEST' and v_current_meas < v_centroid_len_meas ) Then
             v_centroid := centroid_l(v_egeom);
             v_centroid_len_meas := v_current_meas;
          End If;
      End If;
    END LOOP for_all_linestrings_in_multi;
    Return V_Centroid;
  End ST_Centroid_L;

  Function ST_RemoveInnerRings(p_geometry  in mdsys.sdo_geometry)
    Return mdsys.sdo_geometry 
  Is
     v_vertices        mdsys.vertex_set_type;
     v_ords            mdsys.sdo_ordinate_array :=  new mdsys.sdo_ordinate_array(null);
     v_num_dims        pls_integer;
     v_num_elems       pls_integer;
     v_actual_etype    pls_integer;
     v_ring_elem_count pls_integer := 1;
     v_ring            mdsys.sdo_geometry;
     v_num_rings       pls_integer;
     v_geom            sdo_geometry;
     v_ok              number;      
  Begin
    If ( p_geometry is null or Mod(p_geometry.sdo_gtype,10) not in (3,7) ) Then
       raise_application_error(-20001,'p_geometry is null or is not a polygon',true);
    End If;
    /* The processing below assumes the structure of a polygon/multipolygon 
       is correct and passes sdo_geom.validate_geometry */
    v_num_dims  := p_geometry.get_dims();
    v_num_elems := MDSYS.SDO_UTIL.GETNUMELEM(p_geometry);  -- Gets number of 1003 geometries
    <<all_elements>>
    FOR v_elem_no IN 1..v_num_elems LOOP
        -- Need to process and check all inner rings
        --
        -- Process all rings in the extracted single - 2003 - polygon
        v_num_rings := FRONTAGE.ST_GetNumRings(MDSYS.SDO_UTIL.EXTRACT(p_geometry,v_elem_no),0);
        <<All_Rings>>
        FOR v_ring_no IN 1..v_num_rings LOOP
            v_ring := MDSYS.SDO_UTIL.EXTRACT(p_geometry,v_elem_no,v_ring_no);
            IF ( v_ring is not null ) Then
               If ( v_ring_no = 1 ) Then -- outer ring
                 v_geom := case when ( v_geom is null ) then v_ring else mdsys.sdo_util.APPEND(v_geom,v_ring) end;
               End If;
            END IF;
        END LOOP All_Rings;
    END LOOP all_elements;
    Return v_geom;
  End ST_RemoveInnerRings;

  /* ***********************************************************************
   * ******************** Main Function ************************************
   * ***********************************************************************
   **/
  Function Clockface(P_CAD_GID     In integer,
                     P_STREET_NAME in varchar2,
                     P_STREET_OBJ  In MDSYS.SDO_GEOMETRY,
                     p_dec_places  In Integer  default 8,
                     p_tolerance   In Number   default 0.005,
                     p_unit        In Varchar2 default null)
    Return SPDBA.T_Clockfaces 
  As 
    c_bearing_error_bar constant number := 15;
    c_one_chain_road    varchar2(50)    := 'distance=20.117';
    v_tolerance         Number          := NVL(p_tolerance,0.005);
    v_dec_places        Integer         := NVL(p_dec_places,2);
    v_unit              varchar2(100);
    v_clockfaces        spdba.t_clockfaces;
  Begin
    IF ( p_cad_gid is null or p_street_name is null or p_street_obj is null) THEN
       Return null;
    END IF;
    With Vectorset As (
      SELECT f.pid, f.street_name, f.street_relationship, V.segment_Id As VID, V.Startcoord, V.Endcoord,  /* Keep vector before any de-duplication */
             Sdo_Geometry(2002,p_street_obj.sdo_srid,Null,Sdo_Elem_Info_Array(1,2,1),Sdo_Ordinate_Array(V.Startcoord.X,V.Startcoord.Y,V.Endcoord.X,V.Endcoord.Y)) As VectorAsGeom,
             f.geom
       FROM (Select /*+ORDERED*/
                    case when g.GID = c.GID then 0-c.GID       else G.GID end As Pid,
                    case when g.GID = c.GID then p_street_name else null  end as street_name,
                    case when g.GID = c.GID then 'CAD'
                         else NVL((select mdsys.sdo_geom.relate(s.geom,'DETERMINE',g.geom,v_tolerance) as relate 
                                     from VW_STREETS s 
                                    where sdo_anyinteract(s.geom,g.geom) = 'TRUE' 
                                      and rownum < 2
                                  ),'DISJOINT') end as street_relationship,
                    g.geom
               FROM VW_PARCELS c,
                    VW_PARCELS G
              WHERE c.GID = p_cad_gid
                And Sdo_AnyInteract(G.geom,c.geom) = 'TRUE' /* Now retrieve all VW_PARCELS around the location's parcel. SDO_TOUCH does not return the search polygon */
            ) f,
            Table(T_GEOMETRY(Frontage.ST_RemoveInnerRings(f.geom),0.005,2,1)
                    .ST_Round()
                    .ST_Segmentize('ALL')
                  ) v
       WHERE f.pid < 0 
          OR f.street_relationship = 'DISJOINT'
    ) --select * from Vectorset f;
    , reorderedVectorSet As (
      Select D.Pid,D.VId,D.Street_Name,D.Start_X,D.Start_Y,D.End_X,D.End_Y
        From ( Select c.pid,
                      C.VID,
                      c.Street_Name,
                      /* De-Duplicate the vectors to get rid of side boundaries */
                      Case When ( C.Startcoord.X <= C.Endcoord.X )    Then C.Startcoord.X Else C.Endcoord.X   End As Start_X,
                      Case When ( C.Startcoord.X <= C.Endcoord.X )    Then C.Endcoord.X   Else C.Startcoord.X End As End_X,
                      Case When ( C.Startcoord.X <  C.Endcoord.X )    Then C.Startcoord.Y Else 
                      Case When ( C.Startcoord.X =  C.Endcoord.X )    Then 
                      case when (   C.ENDCOORD.Y <  C.STARTCOORD.Y )  then C.ENDCOORD.Y   else C.STARTCOORD.Y end
                           Else C.Endcoord.Y End
                       End As Start_Y,
                      case when ( C.STARTCOORD.X < C.ENDCOORD.X )     then C.ENDCOORD.Y   else 
                      Case When ( C.Startcoord.X = C.Endcoord.X )     Then 
                      case when ( C.ENDCOORD.Y   < C.STARTCOORD.Y )   then C.STARTCOORD.Y else C.ENDCOORD.Y end
                           ELSE c.StartCoord.Y END
                      End As End_Y
                 From VectorSet C
             ) D
    ) -- select * from reorderedVectorSet;
    , deduplicatedVectorSet As (
        Select Min(E.Pid)         As dPid,          /* Shared boundaries will be removed by count(*) > 1, with single vectors having right PID */
               Min(E.VId)         As dVId,          /* Shared boundaries will be removed by count(*) > 1, with single vectors having right vector_id */
               MAX(E.Street_Name) As dStreet_Name,  /* For shared boundaries aggregate having clause throws away result. Where not shared, there will only be one row, one street_name */
               SDO_GEOMETRY(2002,p_street_obj.sdo_srid,NULL,Sdo_Elem_Info_Array(1,2,1),Sdo_Ordinate_Array(e.Start_X,e.Start_Y,e.End_X,e.End_Y)) as dVector, /* Original vector will replace this flipped one */
               SDO_GEOMETRY(2001,p_street_obj.sdo_srid,SDO_POINT_TYPE((e.Start_X+e.End_X)/2.0,(e.Start_Y+e.End_Y)/2,null),null,null)            as dVCentre /* Original vector will replace this flipped one */
          From reorderedVectorSet E 
         Group By E.Start_X, E.Start_Y, E.End_X, E.End_Y
         Having Count(*) = 1  /* OUTER BOUNDARY i.e. FRONTAGE */
         Order By 1,2
    ) -- select * from deduplicatedVectorSet;
    , thinByStreet as (
    select f.pid,
           f.street_name,
           f.VectorAsGeom,
           (f.vDegrees-f.lDegrees) + (f.lDegrees-f.vDegrees) as diffDeg,
           f.distance,
           count(*) over (order by pid) as line_count
      from (Select /*+ ORDERED USE_NL(d,v,c) INDEX(c BLACKMANSBAYSTREETS_GEOM_SPX) */
                   d.dPid as Pid, 
                   c.street_name, 
                   v.VectorAsGeom,
                   Round(COGO.ST_Degrees(Frontage.ST_Bearing(v.VectorAsGeom))) as vDegrees,
                   Round(COGO.ST_Degrees(Frontage.ST_Bearing(c.geom)))         as lDegrees,
                   sdo_geom.sdo_distance(C.geom,d.dVCentre,0.005,NULL)         as distance
              From deduplicatedVectorSet  D,
                   Vectorset              V,
                   VW_STREETS             C
             Where v.Pid = d.dPid 
               And V.VID = d.dVID /* Join to get original vectors to merge */
               And SDO_NN(C.geom,d.dVCentre,c_one_chain_road || ' sdo_num_res=5' || case when p_unit is null then '' else ' '||p_unit end,1) = 'TRUE'
               And c.street_name = p_street_name
           ) f
     where f.pid < 0
       and (f.vDegrees-f.lDegrees) + (f.lDegrees-f.vDegrees) between -1*c_bearing_error_bar and c_bearing_error_bar
    ) -- select count(*) into v_count from thinByStreet e where sdo_geom.validate_geometry(e.VectorAsGeom,v_tolerance)='TRUE'; dbms_output.put_line(v_count);
    Select SPDBA.T_CLOCKFACE(
             SubStr(
               Frontage.Dd2time(
                   COGO.ST_Degrees(
                       Frontage.ST_BearingPlanar(H.Centroid.Sdo_Point.X,H.Centroid.Sdo_Point.Y,
                                                 P_STREET_OBJ.SDO_POINT.X,P_STREET_OBJ.SDO_POINT.Y))),1,20),
             Round(
                sdo_geom.sdo_length(
                    sdo_cs.transform(
                           sdo_geometry(2002,p_street_obj.sdo_srid,NULL,
                                        sdo_elem_info_array(1,2,1),
                                        sdo_ordinate_array(H.Centroid.Sdo_Point.X,H.Centroid.Sdo_Point.Y,
                                                           P_STREET_OBJ.SDO_POINT.X,P_STREET_OBJ.SDO_POINT.Y)),
                           4283),
                    v_tolerance),
                v_dec_places),
             h.centroid,
             sdo_geometry(2002,
                          p_street_obj.sdo_srid,
                          NULL,
                          sdo_elem_info_array(1,2,1),
                          sdo_ordinate_array(H.Centroid.Sdo_Point.X,H.Centroid.Sdo_Point.Y,
                                             P_STREET_OBJ.SDO_POINT.X,P_STREET_OBJ.SDO_POINT.Y))
           ) As Clockface
      bulk collect 
      into v_clockfaces
      from (Select f.Pid, 
                   f.Street_Name, 
                   frontage.St_Centroid_L(f.VectorAsGeom,'LARGEST',v_dec_places,v_dec_places,v_dec_places) As Centroid
              From (SELECT e.Pid, e.street_name, SDO_AGGR_CONCAT_LINES(e.VectorAsGeom) as VectorAsGeom
                      FROM thinByStreet e 
                     WHERE e.line_count > 1
                     GROUP BY e.Pid, e.street_name
                     ORDER BY e.pid, e.street_name
                   )  f
           ) H;
    Return V_Clockfaces;
  End Clockface;

  /* ***********************************************************************
   * ************* Public Overloads of the main Function *******************
   * ***********************************************************************
   **/

  Function Clockface(P_CAD_GID      In integer,
                     P_STREET_NAME  in varchar2,
                     P_STREET_OBJ_X In Number,
                     P_STREET_OBJ_Y In Number,
                     P_SRID         IN NUMBER   default 8307,
                     p_dec_places   In Integer  default 8,
                     p_tolerance    In Number   default 0.005,
                     p_unit         In Varchar2 default null)
    Return SPDBA.T_Clockfaces
  As
    v_ok integer;
  Begin
    Begin
      -- Validate street name exists
      Select 1
        into v_ok
        From VW_STREETS s  
       where s.street_name = P_STREET_NAME; 
      EXCEPTION
       WHEN NO_DATA_FOUND THEN
         raise_application_error(-20101,'Street name does not exist in VW_STREETS.',true);
    END;
    -- Call Main Method 
    Return SPDBA.Frontage.ClockFace(
             p_cad_gid     => p_cad_gid,
             P_STREET_NAME => p_street_name,
             P_STREET_OBJ  => MDSYS.SDO_GEOMETRY(2001,p_srid,mdsys.sdo_point_type(P_STREET_OBJ_X,P_STREET_OBJ_Y,NULL),NULL,NULL),
             p_dec_places  => P_DEC_PLACES,
             p_tolerance   => P_TOLERANCE,
             p_unit        => p_unit
           ); 
  End Clockface;

  /** Original clockface function that takes in identifiers and street object elements.
   **/
  Function Clockface(P_CAD_GID        In integer,
                     P_STREET_LINE_ID In varchar2,
                     P_STREET_OBJ     In mdsys.sdo_geometry,
                     p_dec_places     In Integer  default 8,
                     p_tolerance      In Number   default 0.005,
                     p_unit           In Varchar2 default null)
    Return SPDBA.T_clockfaces
  As
  Begin
    Return SPDBA.FRONTAGE.ClockFace(
             P_CAD_GID        => p_cad_gid,
             P_STREET_LINE_ID => P_STREET_LINE_ID,
             P_STREET_OBJ     => p_street_obj,
             p_dec_places     => P_DEC_PLACES,
             p_tolerance      => P_TOLERANCE,
             p_unit           => p_unit
           ); 
  End Clockface;

  /* ******************************************************************
   * ********************** No Longer Visible *************************
   * ******************************************************************/
  
  /** Alternate Clockface function 
   ** main cad_id coded as negative in SPDBA.TGEOMROW in SPDBA.TGEOMETRIES
    */

  Function Clockface(P_STREET_OBJ     In mdsys.sdo_geometry,
                     P_CAD_NEIGHBOURS In SPDBA.T_GEOMETRIES,
                     p_dec_places     In Integer  default 8,
                     p_tolerance      In Number   default 0.005,
                     p_unit           in varchar2 default NULL)
    Return SPDBA.T_Clockfaces
  As
    v_clockfaces  SPDBA.t_clockfaces;
    v_tolerance   Number  := NVL(p_tolerance,0.005);
    v_dec_places  Integer := NVL(p_dec_places,2);
  Begin
  -- dbms_output.ENABLE(1000000);
  -- debugpkg.printgeom(p_street_obj,3,false,'ST_OBJ:');
  -- for i in 1..p_cad_neighbours.count loop
  --   debugpkg.printgeom(p_cad_neighbours(i).geometry,3,false,'CAD_OBJ('||p_cad_neighbours(i).gid||'):');
  -- end loop;

    /* Get Vectors of CAD objects */
    WITH 
    Vectorset As (
      Select C.GID        AS PID,
             V.segment_Id As VID, 
             V.Startcoord, 
             V.Endcoord,  /* Keep vector before any de-duplication */
             Sdo_Geometry(2002,p_street_obj.sdo_srid,Null,
                          Sdo_Elem_Info_Array(1,2,1),
                          Sdo_Ordinate_Array(V.Startcoord.X,V.Startcoord.Y,V.Endcoord.X,V.Endcoord.Y)) As Vector,
             C.geometry as geom
        From (select t.gid,t.geometry from Table(P_CAD_NEIGHBOURS) t) c,
               Table(
                 SPDBA.T_GEOMETRY(
                   SPDBA.Frontage.ST_RemoveInnerRings(c.geometry),
                   0.005,2,1
                 )
                  .ST_Round(3)
                  .ST_Segmentize('ALL')
              ) v
   ), 
   Reorder_Vectors As (
     Select D.PID,D.VID,D.Start_X,D.Start_Y,D.End_X,D.End_Y
       From (Select c.PID,
                    C.VID,
                    /* De-Duplicate the vectors to get rid of side boundaries */
                    Case When (  C.Startcoord.X <= C.Endcoord.X)  Then C.Startcoord.X Else C.Endcoord.X   End As Start_X,
                    Case When (  C.Startcoord.X <= C.Endcoord.X)  Then C.Endcoord.X   Else C.Startcoord.X End As End_X,
                    Case When (  C.Startcoord.X <  C.Endcoord.X)  Then C.Startcoord.Y Else 
                      Case When (C.Startcoord.X =  C.Endcoord.X)  Then 
                        case when (C.ENDCOORD.Y < C.STARTCOORD.Y) Then C.ENDCOORD.Y   Else C.STARTCOORD.Y end
                      Else C.Endcoord.Y End
                    End As Start_Y,
                    case when (    C.STARTCOORD.X < C.ENDCOORD.X) Then C.ENDCOORD.Y   else 
                      Case When (  C.Startcoord.X = C.Endcoord.X) Then 
                        case when (  C.ENDCOORD.Y < C.STARTCOORD.Y) Then C.STARTCOORD.Y else C.ENDCOORD.Y end
                        ELSE c.StartCoord.Y END
                    End As End_Y
               From VectorSet C
            ) D
   ),
   outer_boundary as (
     Select Min(E.Pid) As Pid,   /* Shared boundaries will be removed by count(*) > 1, with single vectors having right PID ... */
            Min(E.VID) As VID,   /* .... and right VID */
            e.Start_X, e.Start_Y, e.End_X,   e.End_Y   /* Original vector to replace flipped ones */
       From reorder_vectors e
      Group By E.Start_X, E.Start_Y,  
               E.End_X, E.End_Y
     Having Count(*) = 1  /* OUTER BOUNDARY i.e. FRONTAGE */
      Order By Pid,VID
   )
   Select SPDBA.T_CLOCKFACE(
            SubStr(
               Frontage.Dd2time(
                   COGO.ST_Degrees(
                       Frontage.ST_BearingPlanar(H.Centroid.Sdo_Point.X,H.Centroid.Sdo_Point.Y,P_STREET_OBJ.SDO_POINT.X,P_STREET_OBJ.SDO_POINT.Y)
                   )
               ),1,20
            ),
            Round(sdo_geom.sdo_length(
                       sdo_cs.transform(
                              sdo_geometry(2002,3112,NULL,
                                           sdo_elem_info_array(1,2,1),
                                           sdo_ordinate_array(H.Centroid.Sdo_Point.X,H.Centroid.Sdo_Point.Y,P_STREET_OBJ.SDO_POINT.X,P_STREET_OBJ.SDO_POINT.Y)),
                              4283),
                       v_tolerance),
                   2),
            h.centroid,
            sdo_geometry(2002,3112,NULL,sdo_elem_info_array(1,2,1),sdo_ordinate_array(H.Centroid.Sdo_Point.X,H.Centroid.Sdo_Point.Y,P_STREET_OBJ.SDO_POINT.X,P_STREET_OBJ.SDO_POINT.Y))
        ) As Clockface
        bulk collect into v_clockfaces
        from (Select g.Pid, frontage.St_Centroid_L(g.Vector,'LARGEST',3,3,2) As Centroid, g.Vector
                From (Select /*+ ORDERED USE_NL(f,v,c)*/
                             F.Pid, 
                             Sdo_Aggr_Concat_Lines(V.Vector) As Vector
                        From outer_boundary F,
                             Vectorset      V
                       Where F.PID = V.PID 
                         And V.PID = F.PID 
                         And V.VID = F.VID
                         And f.pid < 0
                      group by F.Pid
                      Order By 1
                  ) G
          ) H;
   Return v_clockfaces;
  End ClockFace;

  /** Clockface with three sdo_geometry inputs.
    * Retrieves all parcels around the location's parcel. 
   **/

  Function Clockface(P_CAD_OBJ         In mdsys.sdo_geometry,
                     P_STREET_LINE_OBJ In mdsys.sdo_geometry,
                     P_STREET_OBJ      In mdsys.sdo_geometry,
                     p_dec_places      In Integer  default 8,
                     p_tolerance       In Number   default 0.005,
                     p_unit            in varchar2 default NULL)
    Return SPDBA.T_Clockfaces
  As 
    v_tolerance      Number  := NVL(p_tolerance,0.005);
    v_dec_places     Integer := NVL(p_dec_places,2);
    v_cad_neighbours SPDBA.T_GEOMETRIES;
  Begin
    select CAST(
            COLLECT(
              SPDBA.T_Geometry_Row(/* Need to mark the target CAD Parcel With Negative CAD_ID */
                 gid        =>  case when mdsys.sdo_geom.relate(g.geom,'EQUAL',P_CAD_OBJ,v_tolerance)='EQUAL' then (0-g.gid) /* Mark Target Parcel */ else g.gid end,
                 geometry   => g.geom,
                 dTolerance => 0.005,
                 dPrecision => 2,
                 projected  => 0 
              )
            ) AS SPDBA.T_GEOMETRIES
         ) as CAD_NEIGHBOURS
    Into v_cad_neighbours
    From VW_PARCELS g
   Where Sdo_AnyInteract(G.geom,P_CAD_OBJ) = 'TRUE' /* SDO_TOUCH does not return the search polygon */ 
     And ( mdsys.sdo_geom.relate(g.geom,'DETERMINE',P_STREET_LINE_OBJ,v_tolerance) = 'DISJOINT' /* We don't want neighbouring parcels that could be road easements */
        or mdsys.sdo_geom.relate(g.geom,'EQUAL',    P_CAD_OBJ,        v_tolerance) = 'EQUAL'    /* We don't want to lose our parcel because a road centreline crosses it: easement? */
    );
    Return SPDBA.Frontage.ClockFace(
             P_STREET_OBJ     => P_STREET_OBJ,
             P_CAD_NEIGHBOURS => v_cad_neighbours,
             p_dec_places     => V_DEC_PLACES,
             p_tolerance      => V_TOLERANCE,
             p_unit           => p_unit
           );
  End ClockFace;

End Frontage;
/
show errors

