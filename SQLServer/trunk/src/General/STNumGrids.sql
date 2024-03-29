USE $(usedbname)
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

PRINT '******************************************************************';
PRINT 'Database Schema Variables are: Owner($(cogoowner)) owner($(owner))';
GO

IF EXISTS (
    SELECT * FROM sysobjects WHERE id = object_id(N'[$(owner)].[STNumGrids]') 
    AND xtype IN (N'FN', N'IF', N'TF')
)
BEGIN
  DROP FUNCTION [$(owner)].[STNumGrids];
  PRINT 'Dropped [$(owner)].[STNumGrids] ...';
END;
GO

CREATE FUNCTION [$(owner)].[STNumGrids]
(
  @p_ll_x        float,
  @p_ll_y        float,
  @p_ur_x        float,
  @p_ur_y        float,
  @p_GridSize_X  float,
  @p_GridSize_Y  float
)
Returns Int
as
/****f* INSPECT/STNumGrids (2012)
 *  NAME
 *    STNumGrids -- Calculates the number of grids that would cover the supplied MBR (LL/UR) given the size of a grid cell.
 *  SYNOPSIS
 *    Function STNumGrids (
 *       @p_ll_x        float,
 *       @p_ll_y        float,
 *       @p_ur_x        float,
 *       @p_ur_y        float,
 *       @p_GridSize_X  float,
 *       @p_GridSize_Y  float
 *    )
 *     Returns int 
 *  USAGE
 *    SELECT [$(owner)].[STNumGrids] (149.911044572819, -27.0987879643185, 153.205876564311, -24.0798390343147, 0.00225, 0.00225) / 4 as numGridCells;
 *    GO
 *    numGridCells
 *    491507
 *  DESCRIPTION
 *    This function calculates the number of grids that would cover the supplied MBR (LL/UR) given the size of a tile (grid cell).
 *  NOTES
 *    See also STGeometry2MBR
 *  INPUTS
 *    @p_ll_x       (float) - X ordinate of lower left corner of envelope/MBR to be gridded.
 *    @p_ll_y       (float) - Y ordinate of lower left corner of envelope/MBR to be gridded.
 *    @p_ur_x       (float) - X ordinate of upper right corner of envelope/MBR to be gridded.
 *    @p_ur_y       (float) - Y ordinate of upper right corner of envelope/MBR to be gridded.
 *    @p_GridSize_X (float) - Size of grid cell in X ordinate dimension
 *    @p_GridSize_Y (float) - Size of grid cell in Y ordinate dimension
 *  RESULT
 *    Number of grid cells (int) - N where N = 1 or more.
 *  AUTHOR
 *    Simon Greener
 *  HISTORY
 *    Simon Greener - December 2012 - Original TSQL Coding for SQL Spatial.
 *  COPYRIGHT
 *    (c) 2008-2018 by TheSpatialDBAdvisor/Simon Greener
******/
begin
   DECLARE
     @v_count      BigInt = 0,
     @v_loCol      int,
     @v_hiCol      int,
     @v_loRow      int,
     @v_hiRow      int;
   Begin
     -- Calculate rows/cols to create
     --
     SET @v_loCol = FLOOR(   @p_LL_X / @p_GridSize_X );
     SET @v_hiCol = CEILING( @p_UR_X / @p_GridSize_X ) - 1;
     SET @v_loRow = FLOOR(   @p_LL_Y / @p_GridSize_Y );
     SET @v_hiRow = CEILING( @p_UR_Y / @p_GridSize_Y ) - 1;
     RETURN ( ( @v_hiCol - @v_loCol ) + 1 ) * ( ( @v_hiRow - @v_loRow ) + 1 );
   END;
End
Go

PRINT 'Testing [$(owner)].[STNumGrids] ...';
GO

select [$(owner)].[STNumGrids](149.911044572819, -27.0987879643185, 153.205876564311, -24.0798390343147, 0.00225, 0.00225) / 4
GO

QUIT
GO

