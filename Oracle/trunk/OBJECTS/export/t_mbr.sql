--------------------------------------------------------
--  File created - Friday-August-09-2019   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Type T_MBR
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE TYPE "SPDBA"."T_MBR" 
AUTHID DEFINER
AS OBJECT (

/****t* OBJECT TYPE/T_MBR 
*  NAME
*    T_MBR - Object Type representing a Minimum Bounding Rectangle (MBR) or a geometry Envelope
*  DESCRIPTION
*    An object type that represents an MBR/Envelope of a geometry.
*    Includes methods to manipulate eg Expand/Contract, convert to SDO_DIM_ARRAY.
*  NOTES
*    Only supports Planar / 2D ordinates.
*  AUTHOR
*    Simon Greener
*  HISTORY
*    Simon Greener - Jan 2005 - Original coding.
*  COPYRIGHT
*    (c) 2005-2018 by TheSpatialDBAdvisor/Simon Greener
******/

  /****v* T_MBR/ATTRIBUTES(T_MBR) 
  *  ATTRIBUTES
  *    MinX -- X Ordinate of lower left (LL) corner of MBR.
  *    MinY -- Y Ordinate of lower left (LL) corner of MBR.
  *    MaxX -- X Ordinate of upper right (UR) corner of MBR.
  *    MaxY -- Y Ordinate of upper right (UR) corner of MBR.
  *  SOURCE
  */
   MinX  Number,
   MinY  Number,
   MaxX  Number,
   MaxY  Number,
  /*******/

 /****m* T_MBR/CONSTRUCTORS(T_MBR) 
  *  NAME
  *    A collection of &&INSTALL_SCHEMA..T_MBR Constructors.
  *  SOURCE
  */
   Constructor Function T_MBR(SELF IN OUT NOCOPY T_MBR)
                   Return SELF as Result,

   Constructor Function T_MBR(SELF IN OUT NOCOPY T_MBR,
                              p_mbr in spdba.T_MBR)
                   Return SELF as Result,

   Constructor Function T_MBR( SELF        IN OUT NOCOPY T_MBR,
                               p_geometry  IN MDSYS.SDO_GEOMETRY,
                               p_tolerance IN NUMBER DEFAULT 0.005)
                   Return SELF as Result,

   Constructor Function T_MBR( SELF       IN OUT NOCOPY T_MBR,
                               p_geometry IN MDSYS.SDO_GEOMETRY,
                               p_dimarray IN MDSYS.SDO_DIM_ARRAY )
                   Return SELF as Result,

   Constructor Function T_MBR( SELF      IN OUT NOCOPY T_MBR,
                               p_Vertex  In spdba.T_Vertex,
                               p_dExtent In Number)
                   Return SELF as Result,

   Constructor Function T_MBR( SELF      IN OUT NOCOPY T_MBR,
                               p_dX      In NUMBER,
                               p_dY      In Number,
                               p_dExtent In Number)
                   Return SELF as Result,
  /*******/

  /****v* T_MBR/Modifiers(T_MBR) 
  *  SOURCE
  */
  Member Procedure SetEmpty(SELF IN OUT NOCOPY T_MBR),

  -- ----------------------------------------------------------------------------------------
  -- @procedure  : SetToPart
  -- @precis     : initialiser that sets SELF to MBR of the smallest/largest part in a multi-part shape.
  -- @version    : 1.0
  -- @description: Occasionally the MBR of the smallest/largest part of a multi-part shape is
  --               needed - see sdo_centroid.  SELF.function iterates over all the parts of
  --               a multi-part (SDO_GTYPE == 2007) shape, computes their individual MBRs
  --               and returns the smallest/largest.
  -- @usage      : FUNCTION SetToPart ( p_geometry IN MDSYS.SDO_GEOMETRY );
  --               eg SetToPart(shape,diminfo);
  -- @param      : p_geometry  : MDSYS.SDO_GEOMETRY : A shape.
  -- @param      : p_which     : integer        : Flag indicating smallest (0) part required or largest (1)
  -- @history    : Simon Greener - Feb 2012 - Original coding.
  -- @copyright  : GPL - Free for public use
  Member Function SetToPart(p_geometry in mdsys.sdo_geometry, 
                            p_which    in integer /* 0 smallest, 1 largest */ )
           Return spdba.T_MBR Deterministic,

  -- ----------------------------------------------------------------------------------------
  -- @procedure  : SetSmallestPart
  -- @precis     : initialiser that sets SELF to MBR of the smallest part in a multi-part shape.
  -- @version    : 1.0
  -- @description: Occasionally the MBR of the smallest part of a multi-part shape is
  --               needed - see sdo_centroid.  SELF.function iterates over all the parts of
  --               a multi-part (SDO_GTYPE == 2007) shape, computes their individual MBRs
  --               and returns the smallest.
  -- @usage      : FUNCTION SetSmallestPart ( p_geometry IN MDSYS.SDO_GEOMETRY );
  --               eg SetSmallestPart(shape,diminfo);
  -- @param      : p_geometry  : A shape.
  -- @paramtype  : p_geomery   : MDSYS.SDO_GEOMETRY
  -- @history    : Simon Greener - Feb 2012 - Original coding.
  -- @copyright  : GPL - Free for public use
  Member Function SetSmallestPart(p_geometry IN MDSYS.SDO_GEOMETRY )
           Return spdba.T_MBR Deterministic,

  -- ----------------------------------------------------------------------------------------
  -- @procedure  : SetLargestPart
  -- @precis     : initialiser that sets SELF to MBR of the largest part in a multi-part shape.
  -- @version    : 1.0
  -- @description: Occasionally the MBR of the largest part of a multi-part shape is
  --               needed - see sdo_centroid.  SELF.function iterates over all the parts of
  --               a multi-part (SDO_GTYPE == 2007) shape, computes their individual MBRs
  --               and returns the largest.
  -- @usage      : FUNCTION SetLargestPart ( p_geometry IN MDSYS.SDO_GEOMETRY );
  --               eg SetLargestPart(shape,diminfo);
  -- @param      : p_geometry  : A shape.
  -- @paramtype  : p_geomery   : MDSYS.SDO_GEOMETRY
  -- @history    : Simon Greener - Apr 2003 - Original coding.
  -- @copyright  : GPL - Free for public use
  Member Function SetLargestPart(p_geometry IN MDSYS.SDO_GEOMETRY )
           Return spdba.T_MBR Deterministic,

  Member Function Intersection(p_other In spdba.T_MBR )
           Return spdba.T_MBR Deterministic,

  Member Function Expand(p_Vertex IN spdba.T_Vertex)
           Return spdba.T_MBR Deterministic,

  -- @function  : Expand
  -- @version   : 1.0
  -- @precis    : Enlarges the boundary of the Current MBR so that it contains (x,y).
  --              Does nothing if (x,y) is already on or within the boundaries.
  -- @param     : dX - the value to lower the minimum x to or to raise the maximum x to
  -- @paramType : double
  -- @param     : dY -  the value to lower the minimum y to or to raise the maximum y to
  -- @paramType : double
  -- @history   : SGG November 2004 - Original Coding
  Member Function Expand(p_dX IN NUMBER,
                         p_dY IN NUMBER)
           Return spdba.T_MBR Deterministic,

  -- @procedure : Expand
  -- @version   : 1.0
  -- @precis    : Enlarges the boundary of the Current MBR so that it contains another MBR.
  --              Does nothing if other is wholly on or within the boundaries.
  -- @param     : p_other - MBR to merge with
  -- @paramType : T_MBR
  -- @history   : SGG November 2004 - Original Coding
  Member Function Expand(p_other IN spdba.T_MBR)
           Return spdba.T_MBR Deterministic,

  -- @function  : Normalize(ratio)
  -- @version   : 1.0
  -- @precis    : Method that adjusts width/height etc based on passed ratio eg imageWidth/imageHeight.
  --              If > 0 then the MBR's width is changed to height * ratio.
  --              If < 0 then the MBR's height is changed to width * ratio.
  -- @history   : SGG August 2006 - Original Coding
  Member Function Normalize(p_dRatio In Number)
           Return spdba.T_MBR Deterministic,

/*******/

  /****v* T_MBR/Testers(T_MBR) 
  *  SOURCE
  */
   Member Function isEmpty
            Return Boolean Deterministic,

  -- @function  : contains
  -- @version   : 1.0
  -- @precis    : Returns true if all points on the boundary of p_other
  --              lie in the interior or on the boundary of current MBR.
  -- @return    : True or False
  -- @returntype: Boolean
  -- @history   : SGG November 2004 - Original Coding
  Member Function Contains( p_other In spdba.T_MBR )
           Return Boolean Deterministic,

  -- @function  : Contains
  -- @version   : 1.0
  -- @precis    : Method that tests if a point is within the current MBR
  -- @return    : True or False
  -- @returntype: Boolean
  -- @history   : SGG November 2004 - Original Coding
  Member Function Contains( p_dX In Number,
                            p_dY In Number )
           Return Boolean Deterministic,

  Member Function Contains( p_vertex In mdsys.vertex_type )
           Return Boolean Deterministic,

  Member Function Contains( p_vertex In spdba.T_Vertex ) 
           Return Boolean Deterministic,

  -- @function  : Compare
  -- @version   : 1.0
  -- @precis    : compares 2 MBRs and returns percentage area of overlap.
  -- @return    : 0 (don't overlap) - 100 (equal)
  -- @returntype: Number
  -- @history   : SGG May 2005 - Original Coding
  --
  Member Function Compare( p_other In spdba.T_MBR )
           Return Integer Deterministic,

  -- @function  : Overlap
  -- @version   : 1.0
  -- @precis    : Returns true if any points on the boundary of another MBR
  --              coincide with any points on the boundary of SELF.MBR.
  -- @return    : True or False
  -- @returntype: Boolean
  -- @history   : SGG November 2004 - Original Coding
  Member Function Overlap( p_other in spdba.T_MBR )
           Return Boolean Deterministic,

  -- @function : Intersects
  -- @version  : 1.0
  -- @precis   : Test the point q to see whether it intersects the Envelope defined by p1-p2
  -- @param    : p1 one extremal point of the envelope
  -- @param    : p2 another extremal point of the envelope
  -- @param    : q the point to test for intersection
  -- @return   : true if q intersects the envelope p1-p2
  Static Function Intersects(p1 in spdba.T_Vertex, p2 in spdba.T_Vertex, q in spdba.T_Vertex)
           Return boolean Deterministic,
           

  /**
   * Tests whether the envelope defined by p1-p2
   * and the envelope defined by q1-q2
   * intersect.
   * 
   * @param p1 one extremal point of the envelope P
   * @param p2 another extremal point of the envelope P
   * @param q1 one extremal point of the envelope Q
   * @param q2 another extremal point of the envelope Q
   * @return <code>true</code> if Q intersects P
   */
  Static Function Intersects (
                      p1 in spdba.t_vertex, p2 in spdba.T_Vertex, 
                      q1 in spdba.t_vertex, q2 in spdba.t_vertex)
           return boolean deterministic,
  /*******/


  /****v* T_MBR/Inspectors(T_MBR) 
  *  SOURCE
  */

  -- @property  : X
  -- @version   : 1.0
  -- @precis    : Returns the centre X ordinate of the MBR.
  -- @return    : (maxx - minx) / 2
  -- @returntype: Number
  -- @history   : SGG August 2006 - Original Coding
  Member Function X
           Return Number Deterministic,

  -- @property  : Y
  -- @version   : 1.0
  -- @precis    : Returns the centre Y ordinate of the MBR.
  -- @return    : (maxy - miny) / 2
  -- @returntype: Number
  -- @history   : SGG August 2006 - Original Coding
  Member Function Y
           Return Number Deterministic,

  -- @property  : Width
  -- @version   : 1.0
  -- @precis    : Returns the width of the MBR.
  --              Width is defined as the difference between the maximum and minimum x values.
  -- @return    : width (ie maxx - minx) or Empty if MBR has not been set.
  -- @returntype: Number
  -- @history   : SGG November 2004 - Original Coding
  Member Function Width
           Return Number Deterministic,

  -- @property  : Height
  -- @version   : 1.0
  -- @precis    : Returns the height of the current MBR.
  --              Height is defined as the difference between the maximum and minimum y values.
  -- @return    : height (ie maxy - miny) or Empty if MBR has not been set.
  -- @returntype: Number
  -- @history   : SGG November 2004 - Original Coding
  Member Function Height
           Return Number Deterministic,

  Member Function Area
           Return Number Deterministic,

  -- @property  : Centre
  -- @version   : 1.0
  -- @precis    : Returns the centre via a T_Vertex.
  -- @return    : xy
  -- @returntype: T_Vertex
  -- @history   : SGG August 2006 - Original Coding
  Member Function Centre
           Return spdba.T_Vertex Deterministic,

  -- @property  : Center
  -- @version   : 1.0
  -- @precis    : Returns the center via a T_Vertex.
  -- @return    : xy
  -- @returntype: T_Vertex
  -- @history   : SGG August 2006 - Original Coding
  Member Function Center
           Return spdba.T_Vertex Deterministic,

  -- @function  : AsDimArray
  -- @version   : 1.0
  -- @precis    : Method that returns MBR as a MdSys.Sdo_Dim_Array
  -- @return    : SELF
  -- @returntype: MdSys.Sdo_Dim_Array
  -- @history   : SGG September 2005 - Original Coding
  Member Function AsDimArray
           Return MDSYS.SDO_DIM_ARRAY Deterministic,

  -- @function  : AsString
  -- @version   : 1.0
  -- @precis    : Method that returns MBR as a <MBR> XML
  -- @return    : <MBR...> XML
  -- @returntype: VarChar2
  -- @history   : SGG April 2002 - Original Coding
  Member Function AsString
           Return VarChar2 Deterministic,

  -- @function  : AsCSV
  -- @version   : 1.0
  -- @precis    : Provides a comma delimited string representation.
  -- @return    : Comma delimited MBR string
  -- @returntype: VarChar2
  -- @history   : SJH Feb 2003 - Original Coding
  Member Function AsCSV
           Return VarChar2 Deterministic,

  Member Function AsWKT
           Return VARCHAR2 Deterministic,

  -- @function  : AsSVG
  -- @version   : 1.0
  -- @precis    : Returns MBR object as SVG <rect > xml
  -- @return    : SVG <rect> XML
  -- @returntype: VarChar2
  -- @history   : SGG April 2002 - Original Coding
  Member Function AsSVG
           Return VarChar2 Deterministic,

  -- @function  : getCentreAsSVG
  -- @version   : 1.0
  -- @precis    : Returns centre coordinate of MBR object as SVG <point> xml
  -- @return    : SVG <point> XML
  -- @returntype: VarChar2
  -- @history   : SGG April 2002 - Original Coding
  Member Function getCentreAsSVG
           Return VarChar2 Deterministic,
  /*******/

  /****v* T_MBR/Sorting(T_MBR) 
  *  SOURCE
  */
  -- @function  : Equals
  -- @version   : 1.0
  -- @precis    : Tests to see if an MBR is equal to another.
  -- @return    : True if p_other is equal to Current else false
  -- @returntype: Boolean
  -- @history   : SGG November 2004 - Original Coding
  Member Function Equals(   p_other In spdba.T_MBR )
           Return Boolean Deterministic,

  -- @function  : Evaluate
  -- @version   : 1.0
  -- @precis    : Returns value that can be used to company two MBRs in an expression of type MBR < OTHER MBR
  -- @return    : Computed number.
  -- @returntype: Number
  -- @history   : SGG August 2006 - Original Coding
  Order 
  Member Function Evaluate(p_other In spdba.T_MBR)
           Return Integer
  /*******/

);
/
CREATE OR REPLACE EDITIONABLE TYPE BODY "SPDBA"."T_MBR" 
AS

  Constructor Function T_MBR(SELF IN OUT NOCOPY T_MBR)
                Return SELF As Result
  As
  Begin
    SELF.SetEmpty();
    Return;
  End T_MBR;

  Constructor Function T_MBR(SELF  IN OUT NOCOPY T_MBR,
                             p_mbr IN spdba.T_MBR)
                Return SELF As Result
  As
  Begin
    SELF.SetEmpty();
    IF ( p_mbr is not null ) THEN
      SELF.MinX := p_mbr.MinX;
      SELF.MinY := p_mbr.MinY;
      SELF.MaxX := p_mbr.MaxX;
      SELF.MaxY := p_mbr.MaxY;
    END IF;
    Return;
  End T_MBR;

  Constructor Function T_MBR(SELF        IN OUT NOCOPY T_MBR,
                             p_geometry  IN MDSYS.SDO_GEOMETRY,
                             p_tolerance IN NUMBER DEFAULT 0.005)
                Return SELF As Result
  AS
    c_MaxVal   Constant Number :=  999999999999.99999999;
    c_MinVal   Constant Number := -999999999999.99999999;
    v_vertices mdsys.vertex_set_type;
    v_dimarray mdsys.sdo_dim_array := MDSYS.SDO_DIM_ARRAY(
                        MDSYS.SDO_DIM_ELEMENT('X',c_MinVal,c_MaxVal,p_tolerance),
                        MDSYS.SDO_DIM_ELEMENT('Y',c_minval,c_maxval,p_tolerance));
  begin
    if (p_geometry is null) then
      return;
    end if;
    /* If not licensed for SDO_MBR do this.
    SELECT min(v.x),max(v.x),min(v.y),max(v.y)
      INTO SELF.MinX, SELF.MaxX, SELF.MinY, SELF.MaxY
      FROM TABLE(mdsys.sdo_util.GetVertices(p_geometry)) v;
    */
    v_vertices := MDSYS.SDO_UTIL.GetVertices(MDSYS.SDO_GEOM.SDO_MBR(p_geometry,v_dimarray));
    if (v_vertices is null or v_vertices.count < 2) then
       return;
    end if;
    SELF.minx := v_vertices(1).x;
    SELF.maxx := v_vertices(1).y;
    SELF.miny := v_vertices(2).x;
    SELF.maxy := v_vertices(2).y;
    Return;
  end T_MBR;

  Constructor Function T_MBR(SELF       IN OUT NOCOPY T_MBR,
                             p_geometry IN MDSYS.SDO_GEOMETRY,
                             p_dimarray IN MDSYS.SDO_DIM_ARRAY )
                Return SELF As Result
  as
    v_vertices mdsys.vertex_set_type;
  begin
    if (p_geometry is null) then
      return;
    end if;
    v_vertices := mdsys.sdo_util.getVertices(mdsys.sdo_geom.sdo_mbr(p_geometry,p_dimarray));
    if (v_vertices is null or v_vertices.count < 2) then
       return;
    end if;
    SELF.minx := v_vertices(1).x;
    SELF.maxx := v_vertices(1).y;
    SELF.miny := v_vertices(2).x;
    SELF.maxy := v_vertices(2).y;
    Return;
  END T_MBR;

  Constructor Function T_MBR(SELF      IN OUT NOCOPY T_MBR,
                             p_dX      In NUMBER,
                             p_dY      In Number,
                             p_dExtent In Number )
                Return SELF As Result
  As
  Begin
    SELF.MinX := p_dX - (p_dExtent / 2);
    SELF.MinY := p_dY - (p_dExtent / 2);
    SELF.MaxX := p_dX + (p_dExtent / 2);
    SELF.MaxY := p_dY + (p_dExtent / 2);
    Return;
  End T_MBR;

  Constructor Function T_MBR(SELF      IN OUT NOCOPY T_MBR,
                             p_Vertex  In spdba.T_Vertex,
                             p_dExtent In Number )
                Return SELF As Result
  As
  Begin
    SELF.MinX := p_Vertex.X - (p_dExtent / 2);
    SELF.MinY := p_Vertex.Y - (p_dExtent / 2);
    SELF.MaxX := p_Vertex.X + (p_dExtent / 2);
    SELF.MaxY := p_Vertex.Y + (p_dExtent / 2);
    Return;
  End T_MBR;

  -- ==============================================================
  -- ================ Modifiers ===================================
  -- ==============================================================

  Member Procedure SetEmpty(SELF IN OUT NOCOPY T_MBR)
  As
    c_MaxVal Constant Number :=  999999999999.99999999;
    c_MinVal Constant Number := -999999999999.99999999;
  Begin
    -- Set extents
    SELF.MinX := c_MaxVal;
    SELF.MinY := c_MaxVal;
    SELF.MaxX := c_MinVal;
    SELF.MaxY := c_MinVal;
    Return;
  End SetEmpty;

  Member Function SetToPart(p_geometry in mdsys.sdo_geometry, 
                            p_which    in integer /* 0 smallest, 1 largest */ )
           Return spdba.T_MBR Deterministic
  Is
    v_self      spdba.T_MBR;
    v_elem_mbr  spdba.T_MBR;
    v_which     pls_integer := NVL(p_which,1);
    v_element   mdsys.sdo_geometry;
    v_num_elems pls_integer;
  BEGIN
    v_self := spdba.T_MBR(SELF);
    if ( p_geometry is null ) then
        return v_self;
    end if;
    if ( p_geometry.get_gtype() in (6,7) ) Then
        v_num_elems := MDSYS.SDO_UTIL.GETNUMELEM(p_geometry);
        <<all_elements>>
        FOR v_elem_no IN 1..v_num_elems LOOP
             -- Get part 
             v_element := MDSYS.SDO_UTIL.EXTRACT(p_geometry,v_elem_no);
             v_elem_MBR := New spdba.T_MBR(p_geometry=>v_element);
             If ( v_elem_no = 1 ) Then
                v_SELF := v_elem_MBR;
             ElsIf ( (   ( v_SELF.maxx     - v_SELF.Minx ) * (     v_SELF.maxy -     v_SELF.miny      ) ) <
                   ( ( v_elem_MBR.maxx - v_elem_MBR.Minx ) * ( v_elem_MBR.maxy - v_elem_MBR.miny ) ) ) Then
                If ( p_which = 1 ) then
                   v_SELF := v_elem_MBR;
                End If;
             Else
                If ( p_which = 0 ) then
                   v_SELF := v_elem_MBR;
                End If;
             End If;
        END LOOP all_elements;
    End If;
    Return spdba.T_MBR(v_elem_MBR);
  End SetToPart;

  Member Function SetSmallestPart(p_geometry IN MDSYS.SDO_GEOMETRY )
           Return spdba.T_MBR Deterministic
  Is
  BEGIN
    Return SELF.SetToPart(p_geometry,0);
  END SetSmallestPart;

  Member Function SetLargestPart(p_geometry IN MDSYS.SDO_GEOMETRY )
           Return spdba.T_MBR Deterministic
  IS
  BEGIN
    Return SELF.SetToPart(p_geometry,1);
  END SetLargestPart;

  Member Function Normalize(p_dRatio In Number)
           Return spdba.T_MBR Deterministic
  As
    v_dWidth  number;
    v_dHeight number;
    v_dX      number;
    v_dY      number;
    v_dRatio  number := NVL(p_dRatio,0);
    v_self    spdba.T_MBR;
  Begin
    v_self := spdba.T_MBR(SELF);
    IF ( v_dRatio = 0 ) Then
      Return spdba.T_MBR(SELF);
    ElsIf ( v_dRatio > 0 ) Then
      -- Compute new width
      v_dWidth  := SELF.Height() * p_dRatio;
      -- Compute new minx and maxx based on centre
      v_dX      := SELF.X();
      v_SELF.MinX := v_dX - (v_dWidth / 2.0);
      v_SELF.MaxX := v_dX + (v_dWidth / 2.0);
    ElsIf ( v_dRatio < 0 ) Then
      v_dRatio  := ABS(p_dRatio);
      -- Compute new height
      v_dHeight := SELF.Width() * v_dRatio;
      -- Compute new minx and maxx based on centre
      v_dY      := SELF.Y();
      v_SELF.MinY := v_dY - (v_dHeight / 2.0);
      v_SELF.MaxY := v_dY + (v_dHeight / 2.0);
    Else
      NULL; -- no change
    End If;
    Return v_self;
  End Normalize;

  Member Function Expand(p_dX IN NUMBER,
                         p_dY IN NUMBER)
           Return spdba.T_MBR 

  Is
    v_self    spdba.T_MBR;
  Begin
    v_self := spdba.T_MBR(SELF);
    If (p_dX Is Null Or p_dY Is Null) Then
       Return spdba.T_MBR(SELF);
     ElsIf ( SELF.IsEmpty() ) Then
       v_SELF.MinX := p_dX;
       v_SELF.MaxX := p_dX;
       v_SELF.MinY := p_dY;
       v_SELF.MaxY := p_dY;
     Else
       If (p_dX < SELF.MinX) Then
         v_SELF.MinX := p_dX;
       End If;
       If (p_dX > SELF.MaxX) Then
         v_SELF.MaxX := p_dX;
       End If;
       If (p_dY < SELF.MinY) Then
         v_SELF.MinY := p_dY;
       End If;
       If (p_dY > SELF.MaxY) Then
         v_SELF.MaxY := p_dY;
       End If;
     End If;
     Return v_self;
  End Expand;

  Member Function Expand(p_Vertex IN spdba.T_Vertex)
           Return spdba.T_MBR 
  Is
  Begin
    Return SELF.Expand(p_dX=>p_Vertex.X, p_dY=>p_Vertex.Y);
  End Expand;

  Member Function Expand(p_other IN spdba.T_MBR)
           Return spdba.T_MBR Deterministic
  Is
    v_self spdba.T_MBR;
  Begin
    v_self := spdba.T_MBR(SELF);
    rIf (p_other is NULL) Then
      Return v_self;
    End If;
    If ( SELF.isEmpty() ) Then
      v_SELF.MinX := p_other.MinX;
      v_SELF.MaxX := p_other.MaxX;
      v_SELF.MinY := p_other.MinY;
      v_SELF.MaxY := p_other.MaxY;
    Else
      If (p_other.MinX < SELF.MinX) Then
        v_SELF.MinX := p_other.MinX;
      End If;
      If (p_other.MaxX > SELF.MaxX) Then
        v_SELF.MaxX := p_other.MaxX;
      End If;
      If (p_other.MinY < SELF.MinY) Then
        v_SELF.MinY := p_other.MinY;
      End If;
      If (p_other.MaxY > SELF.MaxY) Then
        v_SELF.MaxY := p_other.MaxY;
      End If;
    End If;
    Return v_SELF;
  End Expand;

  Member Function isEmpty
           Return Boolean
  Is
  Begin
    Return (SELF.MinX > SELF.MaxX);
  End isEmpty;

  Member Function Contains( p_other In spdba.T_MBR )
           Return Boolean
  Is
  Begin
    Return (p_other.MinX >= SELF.MinX And
            p_other.MaxX <= SELF.MaxX And
            p_other.MinY >= SELF.MinY And
            p_other.MaxY <= SELF.MaxY);
  End Contains;

  Member Function Contains( p_dX In Number,
                            p_dY In Number )
           Return Boolean
  Is
  Begin
    Return (p_dX >= SELF.MinX And
            p_dX <= SELF.MaxX And
            p_dY >= SELF.MinY And
            p_dY <= SELF.MaxY);
  End Contains;

  Member Function Contains( p_vertex In mdsys.vertex_type )
           Return Boolean
  Is
  Begin
    Return SELF.Contains(p_dX=>p_vertex.X,p_dY=>p_vertex.Y);
  End Contains;

  Member Function Contains( p_vertex In spdba.T_Vertex )
           Return Boolean
  Is
  Begin
    Return SELF.Contains(p_dX=>p_vertex.X,p_dY=>p_vertex.Y);
  End Contains;

  Member Function Equals(p_other In spdba.T_MBR)
           Return Boolean
  Is
  Begin
    If (p_Other Is Null) Then
      Return False;
    End If;
    Return (SELF.MaxX = p_other.MaxX And
            SELF.MaxY = p_other.MaxY And
            SELF.MinX = p_other.MinX And
            SELF.MaxX = p_other.MaxX);
  End Equals;

  Member Function Intersection(p_other In spdba.T_MBR)
           Return spdba.T_MBR Deterministic
  Is
    c_MaxVal Constant Number :=  999999999999.99999999;
    c_MinVal Constant Number := -999999999999.99999999;
    v_LL     spdba.T_Vertex;
    v_UR     spdba.T_Vertex;
    v_self   spdba.T_MBR;

    Function MiddleValue(p_dValue In Number,
                         p_dMin   In Number,
                         p_dMax   In Number)
      Return Number
    Is
    Begin
      If (p_dValue < p_dMin) Then
        Return p_dMin;
      ElsIf (p_dValue > p_dMax) Then
        Return p_dMax;
      Else
        Return p_dValue;
      End If;
    End;

  Begin
    v_self   := spdba.T_MBR(SELF);
    v_LL     := New spdba.T_Vertex(p_x=>c_MaxVal,p_y=>c_MaxVal);
    v_UR     := New spdba.T_Vertex(p_x=>c_MaxVal,p_y=>c_MaxVal);
    -- Find minx
    v_LL.X   := MiddleValue(p_other.MinX, SELF.MinX, SELF.MaxX);
    v_LL.Y   := MiddleValue(p_other.MinY, SELF.MinY, SELF.MaxY);
    v_UR.X   := MiddleValue(p_other.MaxX, SELF.MinX, SELF.MaxX);
    v_UR.Y   := MiddleValue(p_other.MaxY, SELF.MinY, SELF.MaxY);
    v_SELF.MinX := v_LL.X;
    v_SELF.MinY := v_LL.Y;
    v_SELF.MaxX := v_UR.X;
    v_SELF.MaxY := v_UR.Y;
    Return v_self;
  End Intersection;

  Member Function Compare(p_other In spdba.T_MBR)
           Return Integer
  Is
    mTmpMBR spdba.T_MBR;
  Begin
    If SELF.equals(p_other) Then
      Return 100;
    ElsIf SELF.contains(p_other) Then
      Return (p_other.Height * p_other.Width) / ( SELF.Height() * SELF.Width() );
    ElsIf SELF.overlap(p_other) Then
      mTmpMBR := SELF.Intersection(p_other);
      Return (mTmpMBR.Height() * mTmpMBR.Width()) / ( SELF.Height() * SELF.Width() );
    Else
      Return 0; -- They don't overlap
    End If;
  End Compare;

  Member Function Overlap(p_other in spdba.T_MBR)
           Return Boolean
  Is
  Begin
    Return Not (p_other.MinX > SELF.MaxX Or
                p_other.MaxX < SELF.MinX Or
                p_other.MinY > SELF.MaxY Or
                p_other.MaxY < SELF.MinY);
  End Overlap;

  Static Function Intersects(p1 in spdba.T_Vertex, p2 in spdba.T_Vertex, q in spdba.T_Vertex)
           Return boolean
  As
  Begin
    -- direct Comparison. 
    if (( (q.x >= (case when p1.x < p2.x then p1.x else p2.x end)) AND (q.x <= (case when p1.x > p2.x then p1.x else p2.x end)) ) AND
        ( (q.y >= (case when p1.y < p2.y then p1.y else p2.y end)) AND (q.y <= (case when p1.y > p2.y then p1.y else p2.y end)) )) then
      return true;
    End If;
    return false;
  end Intersects;

  Static Function Intersects (
                      p1 in spdba.t_vertex, p2 in spdba.T_Vertex, 
                      q1 in spdba.t_vertex, q2 in spdba.t_vertex)
           return boolean 
  As
    minq Number;
    maxq Number;
    minp Number;
    maxp Number;
  Begin  
    minq := LEAST(q1.x, q2.x);
    maxq := GREATEST(q1.x, q2.x);
    minp := LEAST(p1.x, p2.x);
    maxp := GREATEST(p1.x, p2.x);

    if( minp > maxq ) then
        return false;
    end if;
    if( maxp < minq ) then
        return false;
    end if;

    minq := LEAST(q1.y, q2.y);
    maxq := GREATEST(q1.y, q2.y);
    minp := LEAST(p1.y, p2.y);
    maxp := GREATEST(p1.y, p2.y);

    if( minp > maxq ) then
        return false;
    end If;
    if( maxp < minq ) then
        return false;
    end if;
    return true;
  End Intersects;
  
  Member Function X
           Return Number
  Is
  Begin
    Return (SELF.MaxX + SELF.MinX) / 2.0;
  End X;

  Member Function Y
           Return Number
  Is
  Begin
    Return (SELF.MaxY + SELF.MinY) / 2.0;
  End Y;

  Member Function Width
    Return Number
  Is
  Begin
     Return Abs(SELF.MaxX - SELF.MinX);
  End Width;

  Member Function Height
    Return Number
  Is
  Begin
     Return Abs(SELF.MaxY - SELF.MinY);
  End Height;

  Member Function Area
         Return Number
  Is
  Begin
    Return ( SELF.Width() * SELF.Height() );
  End Area;

  Member Function Centre
           Return spdba.T_Vertex
  Is
  Begin
      Return spdba.T_Vertex(p_x=>SELF.X() ,p_y=>SELF.Y() );
  End Centre;

  Member Function Center
           Return spdba.T_Vertex
  Is
  Begin
      Return spdba.T_Vertex(p_x=>SELF.X() ,p_y=>SELF.Y() );
  End Center;

  Member Function AsDimArray
           Return MDSYS.SDO_DIM_ARRAY
  Is
  Begin
    Return ( MDSYS.SDO_DIM_ARRAY(
                   MDSYS.SDO_DIM_ELEMENT('X', SELF.minx, SELF.maxx, .0),
                   MDSYS.SDO_DIM_ELEMENT('Y', SELF.miny, SELF.maxy, .0)));
  End AsDimArray;

  Member Function AsString
           Return VarChar2
  Is
  Begin
    RETURN '<mbr minx=''' || To_Char(SELF.MinX) || ''' miny=''' || To_Char(SELF.MinY) || ''' maxx=''' || To_Char(SELF.MaxX) || ''' maxy=''' || To_Char(SELF.MaxY) || ''' />';
  End AsString;

  Member Function AsCSV
           Return VarChar2
  Is
  Begin
    RETURN To_Char(SELF.MinX) || ',' || To_Char(SELF.MinY) || ',' || To_Char(SELF.MaxX) || ',' || To_Char(SELF.MaxY);
  End AsCSV;

  Member Function AsWKT
           Return VARCHAR2
  IS
  BEGIN
    RETURN 'POLYGON((' ||
      TO_CHAR(SELF.minx) || ' ' || TO_CHAR(SELF.miny) ||','||
      TO_CHAR(SELF.maxx) || ' ' || TO_CHAR(SELF.miny) ||','||
      TO_CHAR(SELF.maxx) || ' ' || TO_CHAR(SELF.maxy) ||','||
      TO_CHAR(SELF.minx) || ' ' || TO_CHAR(SELF.maxy) ||','||
      TO_CHAR(SELF.minx) || ' ' || TO_CHAR(SELF.miny) ||'))';
  END AsWKT;

  Member Function AsSVG
           Return VarChar2
  Is
  BEGIN
    RETURN '<rect x=''' || To_Char(SELF.MinX) || ''' y=''' || To_Char(SELF.MinY) || ''' width=''' || To_Char(SELF.Width) || ''' height=''' || To_Char(SELF.Height) || ''' />';
  End AsSVG;

  Member Function getCentreAsSVG
           Return VarChar2
  Is
  Begin
    RETURN '<point x=''' || To_Char(SELF.X() ) || ''' y=''' || To_Char(SELF.Y() ) || ''' />';
  End GetCentreAsSVG;

  Order Member Function Evaluate(p_other In spdba.T_MBR)
                 Return Integer
  Is
  Begin
    If (MinX < p_other.MinX) Then
      If (MinY <= p_other.MinY) Then
         Return -1;
      ElsIf (MinY = p_other.MinY) Then
         Return -1;
      End If;
    ElsIf (MinX = p_other.MinX) Then
      If (MinY < p_other.MinY) Then
         Return -1;
      ElsIf (MinY = p_other.MinY) Then
         Return 0;
      End If;
    Else
      Return 1;
    End If;
    Return 0;
  End Evaluate;

END;

/
