
CREATE OR REPLACE PACKAGE test_cogo 
AUTHID DEFINER
AS

  --%suite(COGO Package Test Suite)

  --%test(Test ST_Normalize )
  procedure test_st_normalize;
  --%test(Test DMS2DD )
  procedure test_dms2dd;
  --%test(Test DD2DMS )
  procedure test_dd2dms;
  --%test(Test DD2TIME )
  Procedure test_dd2time;
  --%test(Test CardinalDirection )  
  procedure test_CardinalDirection;
  --%test(Test QuadrantBearing )  
  procedure test_QuadrantBearing;
  --%test(Test GreatCircleBearing )  
  Procedure test_greatCircleBearing;
  
end;
/
show errors

create or replace package body test_cogo as

  procedure test_st_normalize
  As
  Begin
    ut.expect(COGO.ST_Normalize(0)).to_equal(0);
    ut.expect(COGO.ST_Normalize(45)).to_equal(45);
    ut.expect(COGO.ST_Normalize(90)).to_equal(90);
    ut.expect(COGO.ST_Normalize(135)).to_equal(135);
    ut.expect(COGO.ST_Normalize(180)).to_equal(180);
    ut.expect(COGO.ST_Normalize(225)).to_equal(225);
    ut.expect(COGO.ST_Normalize(270)).to_equal(270);
    ut.expect(COGO.ST_Normalize(315)).to_equal(315);
    ut.expect(COGO.ST_Normalize(360)).to_equal(0);
    ut.expect(COGO.ST_Normalize(405)).to_equal(45);
    ut.expect(COGO.ST_Normalize(450)).to_equal(90);
    ut.expect(COGO.ST_Normalize(495)).to_equal(135);
    ut.expect(COGO.ST_Normalize(540)).to_equal(180);
    ut.expect(COGO.ST_Normalize(585)).to_equal(225);
    ut.expect(COGO.ST_Normalize(630)).to_equal(270);
    ut.expect(COGO.ST_Normalize(675)).to_equal(315);
    ut.expect(COGO.ST_Normalize(720)).to_equal(360);
  End test_st_normalize;
  procedure test_dms2dd
  As
  Begin
    ut.expect( COGO.DMS2DD('22^10''11"') ).to_equal(22.16972222222222222222222222222222222223);
    ut.expect( COGO.DMS2DD('N22.1697E') ).to_equal(22.1697);
    ut.expect( COGO.DMS2DD('S52E') ).to_equal(52);
    ut.expect( COGO.DMS2DD('15°51''5.424"') ).to_equal(15.85150666666666666666666666666666666667);
  End;
  procedure test_dd2dms
  As
  Begin
    ut.expect( COGO.DD2DMS(0)    ).to_equal('0°00''00.000"');
    ut.expect( COGO.DD2DMS(22.5) ).to_equal('22°30''00.000"');
    ut.expect( COGO.DD2DMS(45)   ).to_equal('45°00''00.000"');
    ut.expect( COGO.DD2DMS(67.5) ).to_equal('67°30''00.000"');
    ut.expect( COGO.DD2DMS(90)   ).to_equal('90°00''00.000"');
    ut.expect( COGO.DD2DMS(112.5)).to_equal('112°30''00.000"');
    ut.expect( COGO.DD2DMS(135)  ).to_equal('135°00''00.000"');
    ut.expect( COGO.DD2DMS(157.5)).to_equal('157°30''00.000"');
    ut.expect( COGO.DD2DMS(180)  ).to_equal('180°00''00.000"');
    ut.expect( COGO.DD2DMS(202.5)).to_equal('202°30''00.000"');
    ut.expect( COGO.DD2DMS(225)  ).to_equal('225°00''00.000"');
    ut.expect( COGO.DD2DMS(247.5)).to_equal('247°30''00.000"');
    ut.expect( COGO.DD2DMS(270)  ).to_equal('270°00''00.000"');
    ut.expect( COGO.DD2DMS(292.5)).to_equal('292°30''00.000"');
    ut.expect( COGO.DD2DMS(315)  ).to_equal('315°00''00.000"');
    ut.expect( COGO.DD2DMS(337.5)).to_equal('337°30''00.000"');
    ut.expect( COGO.DD2DMS(0,'^')).to_equal('0^00''00.000"');
    ut.expect( COGO.DD2DMS(15.8515065952945) ).to_equal('15°51''05.424"');  
  End;
  Procedure test_dd2time
  As
  Begin
    ut.expect(COGO.DD2TIME(0,0)).to_equal('0hr 0min');
    ut.expect(COGO.DD2TIME(45,0)).to_equal('1hr 30min');
    ut.expect(COGO.DD2TIME(90,0)).to_equal('3hr 0min');
    ut.expect(COGO.DD2TIME(135,0)).to_equal('4hr 30min');
    ut.expect(COGO.DD2TIME(180,0)).to_equal('6hr 0min');
    ut.expect(COGO.DD2TIME(225,0)).to_equal('7hr 30min');
    ut.expect(COGO.DD2TIME(270,0)).to_equal('9hr 0min');
    ut.expect(COGO.DD2TIME(315,0)).to_equal('10hr 30min');
    ut.expect(COGO.DD2TIME(360,0)).to_equal('12hr 0min');
    ut.expect(COGO.DD2TIME(0,1)).to_equal('12hr 0min');
    ut.expect(COGO.DD2TIME(45,1)).to_equal('13hr 30min');
    ut.expect(COGO.DD2TIME(90,1)).to_equal('15hr 0min');
    ut.expect(COGO.DD2TIME(135,1)).to_equal('16hr 30min');
    ut.expect(COGO.DD2TIME(180,1)).to_equal('18hr 0min');
    ut.expect(COGO.DD2TIME(225,1)).to_equal('19hr 30min');
    ut.expect(COGO.DD2TIME(270,1)).to_equal('21hr 0min');
    ut.expect(COGO.DD2TIME(315,1)).to_equal('22hr 30min');
    ut.expect(COGO.DD2TIME(360,1)).to_equal('24hr 0min');
  End test_dd2time;
  procedure test_CardinalDirection
  As
  Begin
    ut.expect( COGO.CardinalDirection(0,    0) ).to_equal('N');
    ut.expect( COGO.CardinalDirection(22.5, 0) ).to_equal('NNE');
    ut.expect( COGO.CardinalDirection(45,   0) ).to_equal('NE');
    ut.expect( COGO.CardinalDirection(67.5, 0) ).to_equal('ENE');
    ut.expect( COGO.CardinalDirection(90,   0) ).to_equal('E');
    ut.expect( COGO.CardinalDirection(112.5,0) ).to_equal('ESE');
    ut.expect( COGO.CardinalDirection(135,  0) ).to_equal('SE');
    ut.expect( COGO.CardinalDirection(157.5,0) ).to_equal('SSE');
    ut.expect( COGO.CardinalDirection(180,  0) ).to_equal('S');
    ut.expect( COGO.CardinalDirection(202.5,0) ).to_equal('SSW');
    ut.expect( COGO.CardinalDirection(225,  0) ).to_equal('SW');
    ut.expect( COGO.CardinalDirection(247.5,0) ).to_equal('WSW');
    ut.expect( COGO.CardinalDirection(270,  0) ).to_equal('W');
    ut.expect( COGO.CardinalDirection(292.5,0) ).to_equal('WNW');
    ut.expect( COGO.CardinalDirection(315,  0) ).to_equal('NW');
    ut.expect( COGO.CardinalDirection(337.5,0) ).to_equal('NNW');
    ut.expect( COGO.CardinalDirection(0,    1) ).to_equal('North');
    ut.expect( COGO.CardinalDirection(22.5, 1) ).to_equal('North-NorthEast');
    ut.expect( COGO.CardinalDirection(45,   1) ).to_equal('NorthEast');
    ut.expect( COGO.CardinalDirection(67.5, 1) ).to_equal('East-NorthEast');
    ut.expect( COGO.CardinalDirection(90,   1) ).to_equal('East');
    ut.expect( COGO.CardinalDirection(112.5,1) ).to_equal('East-SouthEast');
    ut.expect( COGO.CardinalDirection(135,  1) ).to_equal('SouthEast');
    ut.expect( COGO.CardinalDirection(157.5,1) ).to_equal('South-SouthEast');
    ut.expect( COGO.CardinalDirection(180,  1) ).to_equal('South');
    ut.expect( COGO.CardinalDirection(202.5,1) ).to_equal('South-SouthWest');
    ut.expect( COGO.CardinalDirection(225,  1) ).to_equal('SouthWest');
    ut.expect( COGO.CardinalDirection(247.5,1) ).to_equal('West-SouthWest');
    ut.expect( COGO.CardinalDirection(270,  1) ).to_equal('West');
    ut.expect( COGO.CardinalDirection(292.5,1) ).to_equal('West-NorthWest');
    ut.expect( COGO.CardinalDirection(315,  1) ).to_equal('NorthWest');
    ut.expect( COGO.CardinalDirection(337.5,1) ).to_equal('North-NorthWest');
  End;
  procedure test_QuadrantBearing
  As
  Begin
    ut.expect( COGO.QuadrantBearing(  0,  '^') ).to_equal('N');
    ut.expect( COGO.QuadrantBearing(112.5,'^') ).to_equal('S67.5^E');
    ut.expect( COGO.QuadrantBearing(135,  '^') ).to_equal('S45^E');
    ut.expect( COGO.QuadrantBearing(157.5,'^') ).to_equal('S22.5^E');
    ut.expect( COGO.QuadrantBearing(180,  '^') ).to_equal('S');
    ut.expect( COGO.QuadrantBearing(202.5,'^') ).to_equal('S22.5^W');
    ut.expect( COGO.QuadrantBearing(22.5, '^') ).to_equal('N22.5^E');
    ut.expect( COGO.QuadrantBearing(225,  '^') ).to_equal('S45^W');
    ut.expect( COGO.QuadrantBearing(247.5,'^') ).to_equal('S67.5^W');
    ut.expect( COGO.QuadrantBearing(270,  '^') ).to_equal('W');
    ut.expect( COGO.QuadrantBearing(292.5,'^') ).to_equal('N22.5^W');
    ut.expect( COGO.QuadrantBearing(315,  '^') ).to_equal('N45^W');
    ut.expect( COGO.QuadrantBearing(337.5,'^') ).to_equal('N67.5^W');
    ut.expect( COGO.QuadrantBearing(45,   '^') ).to_equal('N45^E');
    ut.expect( COGO.QuadrantBearing(67.5, '^') ).to_equal('N67.5^E');
    ut.expect( COGO.QuadrantBearing(90,   '^') ).to_equal('E');
  End;
  Procedure test_greatCircleBearing
  As
  Begin
    ut.expect( COGO.GreatCircleBearing(146,-43,147,-42) ).to_equal(36.74);
  End test_greatCircleBearing;

end;
/
show errors

set serveroutput on size unlimited
begin ut.run('test_cogo'); end;

