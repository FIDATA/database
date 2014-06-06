-- FIDATA. Open-source system for analysis of financial and economic data
-- Copyright © 2012-2013  Basil Peace

/*
   This file is part of FIDATA.

   FIDATA is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.
   
   FIDATA is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with FIDATA.  If not, see <http://www.gnu.org/licenses/>.
*/


-------------------------------------------------------------------------------
--                        DYNAMICS SHOWING FUNCTIONS                         --
-------------------------------------------------------------------------------

CREATE FUNCTION procs.change(x2 time_interval, x1 time_interval) RETURNS time_interval
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN x2 - x1;
	END
$$;

CREATE FUNCTION procs.change(x2 time_moment, x1 time_moment) RETURNS time_interval
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN x2 - x1;
	END
$$;

CREATE FUNCTION procs.change(x2 price_type, x1 price_type) RETURNS amount_type
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN x2 - x1;
	END
$$;

CREATE FUNCTION procs.change(x2 pieces_type, x1 pieces_type) RETURNS pieces_type
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN x2 - x1;
	END
$$;

CREATE FUNCTION procs.change(x2 amount_type, x1 amount_type) RETURNS amount_type
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN x2 - x1;
	END
$$;

CREATE FUNCTION procs.change(x2 double precision, x1 double precision) RETURNS double precision
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN x2 - x1;
	END
$$;

CREATE FUNCTION procs.growth_rate(x2 anyelement, x1 anyelement) RETURNS double precision
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		IF sign(x1) * sign(x2) >= 0 THEN
			IF x1 <> 0 THEN
				RETURN x2 / x1;
			-- Here we assume that '0' means '+0'
			ELSIF x2 > 0 THEN
				RETURN 'Infinity'::double precision;
			ELSIF x2 < 0 THEN
				RETURN '-Infinity'::double precision;
			ELSE -- x2 = 0
				RETURN 1; -- no growth
			END IF;
		ELSE -- sign(x1) * sign(x2) < 0
			RETURN 'NaN'::double precision;
		END IF;
	END
$$;

CREATE FUNCTION procs.change_rate(x2 anyelement, x1 anyelement) RETURNS double precision
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		IF sign(x1) * sign(x2) >= 0 THEN
			IF x1 <> 0 THEN
				RETURN x2 / x1 - 1;
			-- Here we assume that '0' means '+0'
			ELSIF x2 > 0 THEN
				RETURN 'Inifinity'::double precision;
			ELSIF x2 < 0 THEN
				RETURN '-Inifinity'::double precision;
			ELSE -- x2 = 0
				RETURN 0; -- no change
			END IF;
		ELSE -- sign(x1) * sign(x2) < 0
			RETURN 'NaN'::double precision;
		END IF;
	END
$$;

CREATE FUNCTION procs.ln_growth_rate(x2 anyelement, x1 anyelement) RETURNS double precision
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		-- Here we assume that '0' means '+0'
		IF sign(x2) * sign(x1) > 0 THEN
			RETURN ln(x2 / x1);
		ELSIF (x2 > 0) AND (x1 = 0) THEN
			RETURN 'Inifinity'::double precision;
		ELSIF (x2 = 0) AND (x1 > 0) THEN
			RETURN '-Inifinity'::double precision;
		ELSIF (x2 = 0) AND (x1 = 0) THEN
			RETURN 0; -- no growth
		ELSE -- sign(x2) * sign(x1) < 0
			RETURN 'NaN'::double precision;
		END IF;
	END
$$;

CREATE FUNCTION procs.one_percent_of_change(x2 anyelement, x1 anyelement) RETURNS anyelement
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		IF x1 <> 0 THEN
			RETURN x1 / 100;
		ELSIF x2 > x1 THEN
			RETURN 'Infinity'::double precision;
		ELSIF x2 < x1 THEN
			RETURN '-Inifinity'::double precision;
		ELSE -- x2 = x1 = 0
			RETURN 0;
		END IF;
	END
$$;


INSERT INTO procs.procs (name, proc_type, dbms_proc_namespace, dbms_proc, output_type, output_type_is_diff, description) VALUES
	('change',                'dyn_show_func', 'procs', 'change',                NULL,       TRUE , ''),
	('growth_rate',           'dyn_show_func', 'procs', 'growth_rate',           'ratio',    FALSE, ''),
	('change_rate',           'dyn_show_func', 'procs', 'change_rate',           'ratio',    FALSE, ''),
	('ln_growth_rate',        'dyn_show_func', 'procs', 'ln_growth_rate',        'ln_ratio', FALSE, ''),
	('one_percent_of_change', 'dyn_show_func', 'procs', 'one_percent_of_change', NULL,       FALSE, '')
;


INSERT INTO procs.proc_input_scales (proc, scale) VALUES
	('change',                'Interval'),
	('change',                'Ratio'   ),
	('change',                'Absolute'),
	
	('growth_rate',           'Ratio'   ),
	('growth_rate',           'Absolute'),
	
	('change_rate',           'Ratio'   ),
	('change_rate',           'Absolute'),
	
	('ln_growth_rate',        'Ratio'   ),
	('ln_growth_rate',        'Absolute'),
	
	('one_percent_of_change', 'Ratio'   ),
	('one_percent_of_change', 'Absolute')
;

-------------------------------------------------------------------------------
