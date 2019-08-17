DEFINE defaultSchema='&1'
ALTER SESSION SET plsql_optimize_level=1;

create or replace
TYPE MBR
AS OBJECT (

   MinX  Number,
   MinY  Number,
   MaxX  Number,
   MaxY  Number,

   -- ================== Constructors
   --
   Constructor Function MBR(            p_geometry IN MDSYS.SDO_GEOMETRY )
               Return Self As Result,
   Constructor Function MBR
               Return Self as Result,
   Constructor Function MBR(            p_geometry  IN MDSYS.SDO_GEOMETRY,
                                        p_tolerance IN NUMBER )
               Return Self as Result,
   Constructor Function MBR(            p_geometry IN MDSYS.SDO_GEOMETRY,
                                        p_dimarray IN MDSYS.SDO_DIM_ARRAY )
               Return Self as Result,
   Constructor Function MBR(            p_MBR In MBR )
               Return Self as Result,
   Constructor Function MBR(            p_Point   In &&defaultSchema..ST_Point,
                                        p_dExtent In Number)
              Return Self As Result,
   Constructor Function MBR(            p_Coord2D In &&defaultSchema..T_Coord2D,
                                        p_dExtent In Number)
               Return Self as Result,
   Constructor Function MBR(            p_dX In NUMBER,
                                        p_dY In Number,
                                        p_dExtent In Number)
               Return Self as Result,

   -- ================== Modifiers
   --
   Member Procedure SetEmpty,
   Member Procedure Expand(         p_Coord2D IN &&defaultSchema..T_Coord2D),
   Member Procedure Expand(         p_dX          IN NUMBER,
	                            p_dY          IN NUMBER),
   Member Procedure Expand(         p_other       IN MBR),
   Member Procedure Normalise(      p_dRatio      In Number),
   Member Procedure SetToPart(p_geometry in mdsys.sdo_geometry, 
                              p_which    in pls_integer /* 0 smallest, 1 largest */ ),
   Member Procedure SetSmallestPart(p_geometry    IN MDSYS.SDO_GEOMETRY ),
   Member Procedure SetLargestPart( p_geometry    IN MDSYS.SDO_GEOMETRY ),
   Member Procedure Intersection(   p_other In MBR ),

   -- ================== Testers
   --

   Member Function isEmpty
          Return Boolean Deterministic,
   Member Function Contains( p_other In MBR )
          Return Boolean Deterministic,
   Member Function Contains( p_dX In Number,
                             p_dY In Number )
          Return Boolean Deterministic,
   Member Function Contains( p_Point   In mdsys.vertex_type )
          Return Boolean Deterministic,
   Member Function Contains( p_Point   In &&defaultSchema..T_Vertex )
          Return Boolean Deterministic,
   Member Function Contains( p_Point   In &&defaultSchema..ST_Point )
          Return Boolean Deterministic,
   Member Function Contains( p_Coord2D In &&defaultSchema..T_Coord2D )
          Return Boolean Deterministic,
   Member Function Equals(   p_other In MBR )
          Return Boolean Deterministic,
   Member Function Compare(  p_other In MBR )
          Return Number Deterministic,
   Member Function Overlap(  p_other in MBR )
          Return Boolean Deterministic,

   -- ================== Inspectors

   Member Function X
          Return Number Deterministic,
   Member Function Y
          Return Number Deterministic,
   Member Function Width
          Return Number Deterministic,
   Member Function Height
          Return Number Deterministic,
   Member Function Area
          Return Number Deterministic,
   Member Function Centre
          Return &&defaultSchema..T_Coord2D Deterministic,
   Member Function Center
          Return &&defaultSchema..T_Coord2D Deterministic,
   Member Function AsDimArray
          Return MDSYS.SDO_DIM_ARRAY Deterministic,
   Member Function AsString
          Return VarChar2 Deterministic,
   Member Function AsCSV
          Return VarChar2 Deterministic,
   Member Function AsWKT
          Return VARCHAR2 Deterministic,
   Member Function AsSVG
          Return VarChar2 Deterministic,
   Member Function getCentreAsSVG
          Return VarChar2 Deterministic,

  Order Member Function Evaluate(p_other In MBR)
               Return PLS_Integer

);
/
show errors

Prompt ----------------------000000000000000000000000000000---------------------

create or replace
TYPE BODY MBR AS

  -- @property  : Width
  -- @version   : 1.0
  -- @precis    : Returns the width of the MBR.
  --              Width is defined as the difference between the maximum and minimum x values.
  -- @return    : width (ie maxx - minx), or Empty if MBR has not been set.
  -- @returntype: Number
  -- @history   : SGG November 2004 - Original Coding
  --
  Member Function Width
    Return Number
  Is
  Begin
     Return Abs(Self.MaxX - Self.MinX);
  End Width;

  -- @property  : Height
  -- @version   : 1.0
  -- @precis    : Returns the height of the current MBR.
  --              Height is defined as the difference between the maximum and minimum y values.
  -- @return    : height (ie maxy - miny), or Empty if MBR has not been set.
  -- @returntype: Number
  -- @history   : SGG November 2004 - Original Coding
  --
  Member Function Height
    Return Number
  Is
  Begin
     Return Abs(Self.MaxY - Self.MinY);
  End Height;

  Member Function Area
         Return Number
  Is
  Begin
    Return (Self.Width * Self.Height);
  End Area;

  Member Procedure SetEmpty
  As
  Begin
    -- Set extents
    Self.MinX := &&defaultSchema..Constants.c_MaxVal;
    Self.MinY := &&defaultSchema..Constants.c_MaxVal;
    Self.MaxX := &&defaultSchema..Constants.c_MinVal;
    Self.MaxY := &&defaultSchema..Constants.c_MinVal;
    Return;
  End SetEmpty;

  -- ============================= Constructors and Initialisers
  --
  -- @function  : MBR
  -- @version   : 1.0
  -- @precis    : Implementation of constructor where no arguments provided.
  -- @history   : SGG April 2002 - Original Coding
  --
  Constructor Function MBR
              Return Self As Result
  As
  Begin
    Self.SetEmpty();
    Return;
  End MBR;

  Constructor Function MBR( p_geometry IN MDSYS.SDO_GEOMETRY )
  Return Self As Result 
  AS
  BEGIN
    SELECT min(v.x),max(v.x),min(v.y),max(v.y)
      INTO Self.MinX, Self.MaxX, Self.MinY, Self.MaxY
      FROM TABLE(mdsys.sdo_util.GetVertices(p_geometry)) v;
    Return;
  END MBR;

  Constructor Function MBR( p_geometry  IN MDSYS.SDO_GEOMETRY,
                            p_tolerance IN NUMBER )
              Return Self As Result
  AS
    v_vertices mdsys.vertex_set_type;
    v_dimarray mdsys.sdo_dim_array := MDSYS.SDO_DIM_ARRAY(
                        MDSYS.SDO_DIM_ELEMENT('X',&&defaultSchema..Constants.c_MinVal,&&defaultSchema..Constants.c_MaxVal,p_tolerance),
                        mdsys.sdo_dim_element('Y',&&defaultSchema..constants.c_minval,&&defaultSchema..constants.c_maxval,p_tolerance));
  begin
    if (p_geometry is null) then
      return;
    end if;
    v_vertices := mdsys.sdo_util.getVertices(mdsys.sdo_geom.sdo_mbr(p_geometry,v_dimarray));
    if (v_vertices is null or v_vertices.count < 2) then
       return;
    end if;
    self.minx := v_vertices(1).x;
    self.maxx := v_vertices(1).y;
    self.miny := v_vertices(2).x;
    self.maxy := v_vertices(2).y;
    Return;
  end mbr;

  Constructor Function MBR( p_geometry IN MDSYS.SDO_GEOMETRY,
                            p_dimarray IN MDSYS.SDO_DIM_ARRAY )
              Return Self As Result
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
    self.minx := v_vertices(1).x;
    self.maxx := v_vertices(1).y;
    self.miny := v_vertices(2).x;
    self.maxy := v_vertices(2).y;
    Return;
  END MBR;

  -- @function  : MBR
  -- @version   : 1.0
  -- @precis    : Copies the contents of another, similar object.
  -- @param     : maxx : Easting of top right corner
  -- @paramtype : maxx : Number
  -- @returntype: Boolean
  -- @history   : SGG August 2006 - Original Coding
  --
  Constructor Function MBR(p_MBR In MBR)
              Return Self As Result
  As
  Begin
    If Not (p_MBR Is Null) Then
      Self.MinX := p_MBR.MinX;
      Self.MinY := p_MBR.MinY;
      Self.MaxX := p_MBR.MaxX;
      Self.MaxY := p_MBR.MaxY;
    End If;
    Return;
  End MBR;

  -- @procedure : MBR
  -- @version   : 1.0
  -- @precis    : Implementation of superclass constructor where x,y and extent are provided.
  -- @param     : x : Easting coordinate value.
  -- @paramtype : x : Number
  -- @param     : y : Northing coordinate value.
  -- @paramtype : y : Number
  -- @param     : extent : Width and Height of the extent.
  -- @paramtype : extent : Number
  -- @history   : SGG April 2002 - Original Coding
  --
  Constructor Function MBR( p_dX In NUMBER,
                            p_dY In Number,
                            p_dExtent In Number)
              Return Self As Result
  As
  Begin
    Self.MinX := p_dX - (p_dExtent / 2);
    Self.MinY := p_dY - (p_dExtent / 2);
    Self.MaxX := p_dX + (p_dExtent / 2);
    Self.MaxY := p_dY + (p_dExtent / 2);
    Return;
  End MBR;

  Constructor Function MBR(            p_Point   In &&defaultSchema..ST_Point,
                                       p_dExtent In Number)
              Return Self As Result
  As
  Begin
    Self.MinX := p_Point.X - (p_dExtent / 2);
    Self.MinY := p_Point.Y - (p_dExtent / 2);
    Self.MaxX := p_Point.X + (p_dExtent / 2);
    Self.MaxY := p_Point.Y + (p_dExtent / 2);
    Return;
  End MBR;

  Constructor Function MBR(            p_Coord2D In &&defaultSchema..T_Coord2D,
                                       p_dExtent In Number)
              Return Self As Result
  As
  Begin
    Self.MinX := p_Coord2D.X - (p_dExtent / 2);
    Self.MinY := p_Coord2D.Y - (p_dExtent / 2);
    Self.MaxX := p_Coord2D.X + (p_dExtent / 2);
    Self.MaxY := p_Coord2D.Y + (p_dExtent / 2);
    Return;
  End MBR;

  -- ================== Modifiers

  -- ----------------------------------------------------------------------------------------
  -- @procedure  : SetToPart
  -- @precis     : initialiser that sets Self to MBR of the smallest/largest part in a multi-part shape.
  -- @version    : 1.0
  -- @description: Occasionally the MBR of the smallest/largest part of a multi-part shape is
  --               needed - see sdo_centroid.  Self.function iterates over all the parts of
  --               a multi-part (SDO_GTYPE == 2007) shape, computes their individual MBRs
  --               and returns the smallest/largest.
  -- @usage      : FUNCTION SetToPart ( p_geometry IN MDSYS.SDO_GEOMETRY );
  --               eg SetToPart(shape,diminfo);
  -- @param      : p_geometry  : MDSYS.SDO_GEOMETRY : A shape.
  -- @param      : p_which     : pls_integer        : Flag indicating smallest (0) part required or largest (1)
  -- @history    : Simon Greener - Feb 2012 - Original coding.
  -- @copyright  : GPL - Free for public use
  --
  Member Procedure SetToPart(p_geometry in mdsys.sdo_geometry, 
                             p_which    in pls_integer /* 0 smallest, 1 largest */ )
  Is
    v_elem_MBR  MBR;
    v_which     pls_integer := NVL(p_which,1);
    v_element   mdsys.sdo_geometry;
    v_num_elems pls_integer;
  BEGIN
    if ( p_geometry is null ) then
        return;
    end if;
    if ( p_geometry.get_gtype() in (6,7) ) Then
        v_num_elems := MDSYS.SDO_UTIL.GETNUMELEM(p_geometry);
        <<all_elements>>
        FOR v_elem_no IN 1..v_num_elems LOOP
             -- Get part 
             --
             v_element := MDSYS.SDO_UTIL.EXTRACT(p_geometry,v_elem_no);
             v_elem_MBR := New MBR(v_element);
             If ( v_elem_no = 1 ) Then
                Self := v_elem_MBR;
             ElsIf ( (     ( Self.maxx       - Self.Minx ) * (       Self.maxy - Self.miny      ) ) <
                   ( ( v_elem_MBR.maxx - v_elem_MBR.Minx ) * ( v_elem_MBR.maxy - v_elem_MBR.miny ) ) ) Then
                If ( p_which = 1 ) then
                   Self := v_elem_MBR;
                End If;
             Else
                If ( p_which = 0 ) then
                   Self := v_elem_MBR;
                End If;
             End If;
        END LOOP all_elements;
    End If;
  End SetToPart;
  
  -- ----------------------------------------------------------------------------------------
  -- @procedure  : SetSmallestPart
  -- @precis     : initialiser that sets Self to MBR of the smallest part in a multi-part shape.
  -- @version    : 1.0
  -- @description: Occasionally the MBR of the smallest part of a multi-part shape is
  --               needed - see sdo_centroid.  Self.function iterates over all the parts of
  --               a multi-part (SDO_GTYPE == 2007) shape, computes their individual MBRs
  --               and returns the smallest.
  -- @usage      : FUNCTION SetSmallestPart ( p_geometry IN MDSYS.SDO_GEOMETRY );
  --               eg SetSmallestPart(shape,diminfo);
  -- @param      : p_geometry  : A shape.
  -- @paramtype  : p_geomery   : MDSYS.SDO_GEOMETRY
  -- @history    : Simon Greener - Feb 2012 - Original coding.
  -- @copyright  : GPL - Free for public use
  --
  Member Procedure SetSmallestPart(p_geometry IN MDSYS.SDO_GEOMETRY )
  Is
  BEGIN
    SetToPart(p_geometry,0);
  END SetSmallestPart;
  
  -- ----------------------------------------------------------------------------------------
  -- @procedure  : SetLargestPart
  -- @precis     : initialiser that sets Self to MBR of the largest part in a multi-part shape.
  -- @version    : 1.0
  -- @description: Occasionally the MBR of the largest part of a multi-part shape is
  --               needed - see sdo_centroid.  Self.function iterates over all the parts of
  --               a multi-part (SDO_GTYPE == 2007) shape, computes their individual MBRs
  --               and returns the largest.
  -- @usage      : FUNCTION SetLargestPart ( p_geometry IN MDSYS.SDO_GEOMETRY );
  --               eg SetLargestPart(shape,diminfo);
  -- @param      : p_geometry  : A shape.
  -- @paramtype  : p_geomery   : MDSYS.SDO_GEOMETRY
  -- @history    : Simon Greener - Apr 2003 - Original coding.
  -- @copyright  : GPL - Free for public use
  --
  Member Procedure SetLargestPart(p_geometry IN MDSYS.SDO_GEOMETRY )
  IS
  BEGIN
    SetToPart(p_geometry,1);
  END SetLargestPart;

  -- @function  : normalise(ratio)
  -- @version   : 1.0
  -- @precis    : Method that adjusts width/height etc based on passed ratio eg imageWidth/imageHeight.
  --              If > 0 then the MBR's width is changed to height * ratio.
  --              If < 0 then the MBR's height is changed to width * ratio.
  -- @history   : SGG August 2006 - Original Coding
  --
  Member Procedure normalise(p_dRatio In Number)
  As
    v_dWidth  number;
    v_dHeight  number;
    v_dX      number;
    v_dY      number;
    v_dRatio  number;
  Begin
    If ( v_dRatio > 0 ) Then
      -- Compute new width
      v_dWidth  := Self.Height * p_dRatio;
      -- Compute new minx and maxx based on centre
      v_dX      := Self.X;
      Self.MinX := v_dX - (v_dWidth / 2.0);
      Self.MaxX := v_dX + (v_dWidth / 2.0);
    ElsIf ( v_dRatio < 0 ) Then
      v_dRatio  := ABS(p_dRatio);
      -- Compute new height
      v_dHeight := Self.Width * v_dRatio;
      -- Compute new minx and maxx based on centre
      v_dY      := Self.Y;
      Self.MinY := v_dY - (v_dHeight / 2.0);
      Self.MaxY := v_dY + (v_dHeight / 2.0);
    Else
      NULL; -- no change
    End If;
    Return;
  End normalise;

  -- @function  : Expand
  -- @version   : 1.0
  -- @precis    : Enlarges the boundary of the Current MBR so that it contains (x,y).
  --              Does nothing if (x,y) is already on or within the boundaries.
  -- @param     : dX - the value to lower the minimum x to or to raise the maximum x to
  -- @paramType : double
  -- @param     : dY -  the value to lower the minimum y to or to raise the maximum y to
  -- @paramType : double
  -- @history   : SGG November 2004 - Original Coding
  --
  Member Procedure Expand(p_dX IN NUMBER,
                          p_dY IN NUMBER)
  Is
  Begin
    If (p_dX Is Null Or p_dY Is Null) Then
       Return;
     ElsIf (Self.IsEmpty) Then
       Self.MinX := p_dX;
       Self.MaxX := p_dX;
       Self.MinY := p_dY;
       Self.MaxY := p_dY;
     Else
       If (p_dX < Self.MinX) Then
         Self.MinX := p_dX;
       End If;
       If (p_dX > Self.MaxX) Then
         Self.MaxX := p_dX;
       End If;
       If (p_dY < Self.MinY) Then
         Self.MinY := p_dY;
       End If;
       If (p_dY > Self.MaxY) Then
         Self.MaxY := p_dY;
       End If;
     End If;
     Return;
  End Expand;

  Member Procedure Expand(p_Coord2D IN &&defaultSchema..T_Coord2D)
  Is
  Begin
    Self.Expand(p_Coord2D.X, p_Coord2D.Y);
    Return;
  End Expand;

  -- @procedure : Expand
  -- @version   : 1.0
  -- @precis    : Enlarges the boundary of the Current MBR so that it contains another MBR.
  --              Does nothing if other is wholly on or within the boundaries.
  -- @param     : p_other - MBR to merge with
  -- @paramType : MBRType
  -- @history   : SGG November 2004 - Original Coding
  --
  Member Procedure Expand(p_other IN MBR)
  Is
  Begin
      If (p_other is NULL) Then
        Return;
      End If;
      If (Self.isEmpty) Then
        Self.MinX := p_other.MinX;
        Self.MaxX := p_other.MaxX;
        Self.MinY := p_other.MinY;
        Self.MaxY := p_other.MaxY;
      Else
        If (p_other.MinX < Self.MinX) Then
          Self.MinX := p_other.MinX;
        End If;
        If (p_other.MaxX > Self.MaxX) Then
          Self.MaxX := p_other.MaxX;
        End If;
        If (p_other.MinY < Self.MinY) Then
          Self.MinY := p_other.MinY;
        End If;
        If (p_other.MaxY > Self.MaxY) Then
          Self.MaxY := p_other.MaxY;
        End If;
      End If;
  End Expand;

  -- ================== Testers

  Member Function isEmpty
   Return Boolean
  Is
  Begin
    Return (Self.MinX > Self.MaxX);
  End isEmpty;


  -- @function  : contains
  -- @version   : 1.0
  -- @precis    : Returns true if all points on the boundary of p_other
  --              lie in the interior or on the boundary of current MBR.
  -- @return    : True or False
  -- @returntype: Boolean
  -- @history   : SGG November 2004 - Original Coding
  --
  Member Function Contains( p_other In MBR )
    Return Boolean
  Is
  Begin
    Return (p_other.MinX >= Self.MinX And
            p_other.MaxX <= Self.MaxX And
            p_other.MinY >= Self.MinY And
            p_other.MaxY <= Self.MaxY);
  End Contains;

  -- @function  : Contains
  -- @version   : 1.0
  -- @precis    : Method that tests if a point is within the current MBR
  -- @return    : True or False
  -- @returntype: Boolean
  -- @history   : SGG November 2004 - Original Coding
  --
  Member Function Contains( p_dX In Number,
                            p_dY In Number )
    Return Boolean
  Is
  Begin
      Return (p_dX >= Self.MinX And
              p_dX <= Self.MaxX And
              p_dY >= Self.MinY And
              p_dY <= Self.MaxY);
  End Contains;

  Member Function Contains( p_Point In mdsys.vertex_type )
    Return Boolean
  Is
  Begin
      Return Contains(p_Point.X,p_Point.Y);
  End Contains;

  Member Function Contains( p_Point In &&defaultSchema..T_Vertex )
    Return Boolean
  Is
  Begin
      Return Contains(p_Point.X,p_Point.Y);
  End Contains;

  Member Function Contains(p_Point In &&defaultSchema..ST_Point)
    Return Boolean
  Is
  Begin
      Return Contains(p_Point.X,p_Point.Y);
  End Contains;

  Member Function Contains(p_Coord2D In &&defaultSchema..T_Coord2D)
    Return Boolean
  Is
  Begin
      Return Contains(p_Coord2D.X,p_Coord2D.Y);
  End Contains;

  -- @function  : Equals
  -- @version   : 1.0
  -- @precis    : Tests to see if an MBR is equal to another.
  -- @return    : True if p_other is equal to Current else false
  -- @returntype: Boolean
  -- @history   : SGG November 2004 - Original Coding
  --
  Member Function Equals(p_other In MBR)
    Return Boolean
  Is
  Begin
      If (p_Other Is Null) Then
        Return False;
      End If;
      Return (Self.MaxX = p_other.MaxX And
              Self.MaxY = p_other.MaxY And
              Self.MinX = p_other.MinX And
              Self.MaxX = p_other.MaxX);
  End Equals;

  Member Procedure Intersection(p_other In MBR)
  Is
    v_LL  &&defaultSchema..ST_Point;
    v_UR  &&defaultSchema..ST_Point;

    -- @procedure : MiddleValue
    -- @version   : 2.0
    -- @precis    : An internal function used to test is a value falls within a range.
    -- @history   : SGG April  2002 - Original Coding
    -- @history   : SGG August 2006 - Changed for use in MBR Object
    --
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
    v_LL := New &&defaultSchema..ST_Point(&&defaultSchema..CONSTANTS.c_MaxVal,&&defaultSchema..CONSTANTS.c_MaxVal);
    v_UR := New &&defaultSchema..ST_Point(&&defaultSchema..CONSTANTS.c_MaxVal,&&defaultSchema..CONSTANTS.c_MaxVal);
    -- Find minx
    v_LL.X   := MiddleValue(p_other.MinX, Self.MinX, Self.MaxX);
    v_LL.Y   := MiddleValue(p_other.MinY, Self.MinY, Self.MaxY);
    v_UR.X   := MiddleValue(p_other.MaxX, Self.MinX, Self.MaxX);
    v_UR.Y   := MiddleValue(p_other.MaxY, Self.MinY, Self.MaxY);
    Self.MinX := v_LL.X;
    Self.MinY := v_LL.Y;
    Self.MaxX := v_UR.X;
    Self.MaxY := v_UR.Y;
    Return;
  End Intersection;

  -- @function  : Compare
  -- @version   : 1.0
  -- @precis    : compares 2 MBRs and returns percentage area of overlap.
  -- @return    : 0 (don't overlap) - 100 (equal)
  -- @returntype: Number
  -- @history   : SGG May 2005 - Original Coding
  --
  Member Function Compare(p_other In MBR)
    Return Number
  Is
    mTmpMBR MBR;
  Begin
    If equals(p_other) Then
      Return 100;
    ElsIf contains(p_other) Then
      Return (p_other.Height * p_other.Width) / (Self.Height * Self.Width);
    ElsIf overlap(p_other) Then
      mTmpMBR := Self;
      mTmpMBR.intersection(p_other);
      Return (mTmpMBR.Height * mTmpMBR.Width) / (self.Height * Self.Width);
    Else
      -- They don't overlap
      Return 0;
    End If;
  End Compare;

  -- @function  : Overlap
  -- @version   : 1.0
  -- @precis    : Returns true if any points on the boundary of another MBR
  --              coincide with any points on the boundary of Self.MBR.
  -- @return    : True or False
  -- @returntype: Boolean
  -- @history   : SGG November 2004 - Original Coding
  --
  Member Function Overlap(p_other in MBR)
    Return Boolean
  Is
  Begin
    Return Not (p_other.MinX > Self.MaxX Or
                p_other.MaxX < Self.MinX Or
                p_other.MinY > Self.MaxY Or
                p_other.MaxY < Self.MinY);
  End Overlap;

  -- ================== Inspectors

  -- @property  : X
  -- @version   : 1.0
  -- @precis    : Returns the centre X ordinate of the MBR.
  -- @return    : (maxx - minx) / 2
  -- @returntype: Number
  -- @history   : SGG August 2006 - Original Coding
  --
  Member Function X
  Return Number
  Is
  Begin
    Return (Self.MaxX + Self.MinX) / 2.0;
  End X;

  -- @property  : Y
  -- @version   : 1.0
  -- @precis    : Returns the centre Y ordinate of the MBR.
  -- @return    : (maxy - miny) / 2
  -- @returntype: Number
  -- @history   : SGG August 2006 - Original Coding
  --
  Member Function Y
  Return Number
  Is
  Begin
    Return (Self.MaxY + Self.MinY) / 2.0;
  End Y;

  -- @property  : Centre
  -- @version   : 1.0
  -- @precis    : Returns the centre via a T_Coord2D.
  -- @return    : xy
  -- @returntype: T_Coord2D
  -- @history   : SGG August 2006 - Original Coding
  --
  Member Function Centre
    Return &&defaultSchema..T_Coord2D
  Is
  Begin
      Return &&defaultSchema..T_Coord2D(Self.X,Self.Y);
  End Centre;

  -- @property  : Center
  -- @version   : 1.0
  -- @precis    : Returns the center via a T_Coord2D.
  -- @return    : xy
  -- @returntype: T_Coord2D
  -- @history   : SGG August 2006 - Original Coding
  --
  Member Function Center
    Return &&defaultSchema..T_Coord2D
  Is
  Begin
      Return &&defaultSchema..T_Coord2D(Self.X,Self.Y);
  End Center;

  -- @function  : AsDimArray
  -- @version   : 1.0
  -- @precis    : Method that returns MBR as a MdSys.Sdo_Dim_Array
  -- @return    : Self
  -- @returntype: MdSys.Sdo_Dim_Array
  -- @history   : SGG September 2005 - Original Coding
  --
  Member Function AsDimArray
    Return MDSYS.SDO_DIM_ARRAY
  Is
  Begin
    Return ( MDSYS.SDO_DIM_ARRAY(
                   MDSYS.SDO_DIM_ELEMENT('X', Self.minx, Self.maxx, .0),
                   MDSYS.SDO_DIM_ELEMENT('Y', Self.miny, Self.maxy, .0)));
  End AsDimArray;

  -- @function  : AsString
  -- @version   : 1.0
  -- @precis    : Method that returns MBR as a <MBR> XML
  -- @return    : <MBR...> XML
  -- @returntype: VarChar2
  -- @history   : SGG April 2002 - Original Coding
  --
  Member Function AsString
    Return VarChar2
  Is
  Begin
    RETURN '<mbr minx=''' || To_Char(Self.MinX) || ''' miny=''' || To_Char(Self.MinY) || ''' maxx=''' || To_Char(Self.MaxX) || ''' maxy=''' || To_Char(Self.MaxY) || ''' />';
  End AsString;

  -- @function  : AsCSV
  -- @version   : 1.0
  -- @precis    : Provides a comma delimited string representation.
  -- @return    : Comma delimited MBR string
  -- @returntype: VarChar2
  -- @history   : SJH Feb 2003 - Original Coding
  --
  Member Function AsCSV
    Return VarChar2
  Is
  Begin
    RETURN To_Char(Self.MinX) || ',' || To_Char(Self.MinY) || ',' || To_Char(Self.MaxX) || ',' || To_Char(Self.MaxY);
  End AsCSV;

  Member Function AsWKT
    Return VARCHAR2
  IS
  BEGIN
    RETURN 'POLYGON((' ||
      TO_CHAR(Self.minx) || ' ' || TO_CHAR(Self.miny) ||','||
      TO_CHAR(Self.maxx) || ' ' || TO_CHAR(Self.miny) ||','||
      TO_CHAR(Self.maxx) || ' ' || TO_CHAR(Self.maxy) ||','||
      TO_CHAR(Self.minx) || ' ' || TO_CHAR(Self.maxy) ||','||
      TO_CHAR(Self.minx) || ' ' || TO_CHAR(Self.miny) ||'))';
  END AsWKT;

  -- @function  : AsSVG
  -- @version   : 1.0
  -- @precis    : Returns MBR object as SVG <rect > xml
  -- @return    : SVG <rect> XML
  -- @returntype: VarChar2
  -- @history   : SGG April 2002 - Original Coding
  --
  Member Function AsSVG
    RETURN VarChar2
  Is
  BEGIN
    RETURN '<rect x=''' || To_Char(Self.MinX) || ''' y=''' || To_Char(Self.MinY) || ''' width=''' || To_Char(Self.Width) || ''' height=''' || To_Char(Self.Height) || ''' />';
  End AsSVG;

  -- @function  : getCentreAsSVG
  -- @version   : 1.0
  -- @precis    : Returns centre coordinate of MBR object as SVG <point> xml
  -- @return    : SVG <point> XML
  -- @returntype: VarChar2
  -- @history   : SGG April 2002 - Original Coding
  --
  Member Function getCentreAsSVG
    Return VarChar2
  Is
  Begin
    RETURN '<point x=''' || To_Char(Self.X) || ''' y=''' || To_Char(Self.Y) || ''' />';
  End GetCentreAsSVG;

  -- @function  : Evaluate
  -- @version   : 1.0
  -- @precis    : Returns value that can be used to company two MBRs in an expression of type MBR < MBR
  -- @return    : Computed number.
  -- @returntype: Number
  -- @history   : SGG August 2006 - Original Coding
  --
  Order Member Function Evaluate(p_other In MBR)
               Return PLS_Integer
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
  End Evaluate;

END;
/
show errors

set serveroutput on size unlimited
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
   v_OK       boolean := true;
   v_obj_name varchar2(30) := 'MBR';
BEGIN
   FOR rec IN (select object_name || '.' || object_Type as package_name, status 
                 from user_objects
                where object_name = v_obj_name) LOOP
      IF ( rec.status = 'VALID' ) Then
         dbms_output.put_line('Type ' || USER || '.' || rec.package_name || ' is valid.');
      ELSE
         dbms_output.put_line('Type ' || USER || '.' || rec.package_name || ' is invalid.');
         v_ok := false;
      END IF;
   END LOOP;
   IF ( NOT v_OK ) THEN
      RAISE_APPLICATION_ERROR(-20000,v_obj_name || ' failed to install.');
   END IF;
END;
/
SHOW ERRORS

grant execute on mbr to public;

QUIT;


