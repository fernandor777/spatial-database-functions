DROP   FUNCTION IF EXISTS spdba.random_between(numeric,numeric);

CREATE FUNCTION spdba.random_between(
  low  numeric,
  high numeric
) 
RETURNS numeric 
AS
$$
BEGIN
   RETURN low + (random()* (high-low + 1.0));
END;
$$ language 'plpgsql' STRICT
COST 100;

select f.gs as id,
       spdba.random_between(345643.0,5200456.2)
  from (select generate_series(1,50,1) as gs ) as f;
