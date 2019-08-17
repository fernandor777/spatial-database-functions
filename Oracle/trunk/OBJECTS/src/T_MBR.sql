DEFINE INSTALL_SCHEMA='&1'

SET VERIFY OFF;

CREATE OR REPLACE TYPE &&INSTALL_SCHEMA..T_MBR
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
                              p_mbr in &&INSTALL_SCHEMA..T_MBR)
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
                               p_Vertex  In &&INSTALL_SCHEMA..T_Vertex,
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
           Return &&INSTALL_SCHEMA..T_MBR Deterministic,

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
           Return &&INSTALL_SCHEMA..T_MBR Deterministic,

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
           Return &&INSTALL_SCHEMA..T_MBR Deterministic,

  Member Function Intersection(p_other In &&INSTALL_SCHEMA..T_MBR )
           Return &&INSTALL_SCHEMA..T_MBR Deterministic,
  
  Member Function Expand(p_Vertex IN &&INSTALL_SCHEMA..T_Vertex)
           Return &&INSTALL_SCHEMA..T_MBR Deterministic,

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
           Return &&INSTALL_SCHEMA..T_MBR Deterministic,

  -- @procedure : Expand
  -- @version   : 1.0
  -- @precis    : Enlarges the boundary of the Current MBR so that it contains another MBR.
  --              Does nothing if other is wholly on or within the boundaries.
  -- @param     : p_other - MBR to merge with
  -- @paramType : T_MBR
  -- @history   : SGG November 2004 - Original Coding
  Member Function Expand(p_other IN &&INSTALL_SCHEMA..T_MBR)
           Return &&INSTALL_SCHEMA..T_MBR Deterministic,

  -- @function  : Normalize(ratio)
  -- @version   : 1.0
  -- @precis    : Method that adjusts width/height etc based on passed ratio eg imageWidth/imageHeight.
  --              If > 0 then the MBR's width is changed to height * ratio.
  --              If < 0 then the MBR's height is changed to width * ratio.
  -- @history   : SGG August 2006 - Original Coding
  Member Function Normalize(p_dRatio In Number)
           Return &&INSTALL_SCHEMA..T_MBR Deterministic,

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
  Member Function Contains( p_other In &&INSTALL_SCHEMA..T_MBR )
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

  Member Function Contains( p_vertex In &&INSTALL_SCHEMA..T_Vertex ) 
           Return Boolean Deterministic,

  -- @function  : Compare
  -- @version   : 1.0
  -- @precis    : compares 2 MBRs and returns percentage area of overlap.
  -- @return    : 0 (don't overlap) - 100 (equal)
  -- @returntype: Number
  -- @history   : SGG May 2005 - Original Coding
  --
  Member Function Compare( p_other In &&INSTALL_SCHEMA..T_MBR )
           Return Integer Deterministic,

  -- @function  : Overlap
  -- @version   : 1.0
  -- @precis    : Returns true if any points on the boundary of another MBR
  --              coincide with any points on the boundary of SELF.MBR.
  -- @return    : True or False
  -- @returntype: Boolean
  -- @history   : SGG November 2004 - Original Coding
  Member Function Overlap( p_other in &&INSTALL_SCHEMA..T_MBR )
           Return Boolean Deterministic,

  -- @function : Intersects
  -- @version  : 1.0
  -- @precis   : Test the point q to see whether it intersects the Envelope defined by p1-p2
  -- @param    : p1 one extremal point of the envelope
  -- @param    : p2 another extremal point of the envelope
  -- @param    : q the point to test for intersection
  -- @return   : true if q intersects the envelope p1-p2
  Static Member Function Intersects(p1 in &&INSTALL_SCHEMA..T_Vertex, p2 in &&INSTALL_SCHEMA..T_Vertex, q in &&INSTALL_SCHEMA..T_Vertex)
                  Return boolean Deterministic,
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
           Return &&INSTALL_SCHEMA..T_Vertex Deterministic,

  -- @property  : Center
  -- @version   : 1.0
  -- @precis    : Returns the center via a T_Vertex.
  -- @return    : xy
  -- @returntype: T_Vertex
  -- @history   : SGG August 2006 - Original Coding
  Member Function Center
           Return &&INSTALL_SCHEMA..T_Vertex Deterministic,

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
  Member Function Equals(   p_other In &&INSTALL_SCHEMA..T_MBR )
           Return Boolean Deterministic,

  -- @function  : Evaluate
  -- @version   : 1.0
  -- @precis    : Returns value that can be used to company two MBRs in an expression of type MBR < OTHER MBR
  -- @return    : Computed number.
  -- @returntype: Number
  -- @history   : SGG August 2006 - Original Coding
  Order 
  Member Function Evaluate(p_other In &&INSTALL_SCHEMA..T_MBR)
           Return Integer
  /*******/

);
/
show errors

set serveroutput on size unlimited
WHENEVER SQLERROR EXIT FAILURE;
DECLARE
   v_OK       boolean      := FALSE;
   v_obj_name varchar2(30) := 'T_MBR';
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
         v_ok := TRUE;
      ELSE
         dbms_output.put_line(rec.object_type || ' ' || USER || '.' || rec.object_name || ' is invalid.');
      END IF;
   END LOOP;
   IF ( NOT v_OK ) THEN
      RAISE_APPLICATION_ERROR(-20000,v_obj_name || ' failed to install.');
   END IF;
   execute immediate 'GRANT EXECUTE ON &&INSTALL_SCHEMA..' || v_obj_name || ' TO public WITH GRANT OPTION';
END;
/
SHOW ERRORS

EXIT SUCCESS;
