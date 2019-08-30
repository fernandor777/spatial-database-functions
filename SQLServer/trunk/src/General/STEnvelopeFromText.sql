use spatialdb
go

SET ANSI_NULLS ON
SET ARITHABORT ON 
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (SELECT * 
             FROM sysobjects 
            WHERE id = object_id (N'[$(owner)].[STEnvelopeFromText]')
              AND xtype IN (N'FN', N'IF', N'TF') 
)
BEGIN
  DROP FUNCTION [$(owner)].[STEnvelopeFromText];
  PRINT 'Dropped [$(owner)].[STEnvelopeFromText] ...';
END;
GO

PRINT 'Creating [$(owner)].[STEnvelopeFromText] ...';
GO

Create Function [$(owner)].[STEnvelopeFromText] (
  @p_mbr_coords varchar(max),
  @p_srid       integer
)
Returns geometry 
As
/****f* EDITOR/STEnvelopeFromText
 *  NAME
 *    STEnvelopeFromText -- Function that constructs a 5 point polygon from supplied string.
 *  SYNOPSIS
 *    Function [dbo].[STEnvelopeFromText] (
 *               @p_mbr_coords in varchar,
 *               @p_srid       in integer default null
 *             )
 *     Returns geometry 
 *  DESCRIPTION
 *  NOTES
 *    2D only.
 *  INPUTS
 *    @p_mbr_coords (varchar) - 2 coordinates, 4 ordinates
 *    @p_srid       (integer) - geometry srid
 *  RESULT
 *    geometry     (geometry) - Input coordinates converted to 5 point polygon.
 *  EXAMPLE
 *    USE GISDB
 *    GO
 *    SELECT [dbo].[STEnvelopeFromText]('0 0,1 1',null) as mbr;
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - August 2019 - Original TSQL Coding.
 *  COPYRIGHT
 *    (c) 2008-2019 by TheSpatialDBAdvisor/Simon Greener
******/
Begin
 Declare
  @v_comma_pos integer,
  @v_ll_point  varchar(100),
  @v_ur_point  varchar(100),
  @v_ll_x      varchar(100),
  @v_ll_y      varchar(100),
  @v_ur_x      varchar(100),
  @v_ur_y      varchar(100),
  @v_wkt       varchar(100);
 Begin
  IF ( @p_mbr_coords is null ) 
    RETURN NULL;
  SET @v_comma_pos  = CHARINDEX(',',@p_mbr_coords);
  IF ( @v_comma_pos = 0)
    Return null;

  SET @v_ll_point = SUBSTRING(@p_mbr_coords,1,@v_comma_pos-1);
  SET @v_ll_x     = SUBSTRING(@v_ll_point,1,CHARINDEX(' ',@v_ll_point)-1);
  SET @v_ll_y     = SUBSTRING(@v_ll_point,CHARINDEX(' ',@v_ll_point)+1,LEN(@v_ll_point));
  SET @v_ur_point = SUBSTRING(@p_mbr_coords,@v_comma_pos+1,LEN(@p_mbr_coords));
  SET @v_ur_x     = SUBSTRING(@v_ur_point,1,CHARINDEX(' ',@v_ur_point)-1);
  SET @v_ur_y     = SUBSTRING(@v_ur_point,CHARINDEX(' ',@v_ur_point)+1,LEN(@v_ur_point));
  SET @v_wkt = 'POLYGON((' + 
                         @v_ll_x + ' ' + @v_ll_y + ',' +
                         @v_ur_x + ' ' + @v_ll_y + ',' +
                         @v_ur_x + ' ' + @v_ur_y + ',' +
                         @v_ll_x + ' ' + @v_ur_y + ',' +
                         @v_ll_x + ' ' + @v_ll_y
			+ '))';
  RETURN geometry::STGeomFromText(@v_wkt,ISNULL(@p_srid,0));
 End;
End
GO

SELECT [$(owner)].[STEnvelopeFromText]('0 0,1 1',null) as mbr;

QUIT
GO
