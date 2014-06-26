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
-- See also comments about sources of code and applied licenses


DO LANGUAGE plpgsql $$
	BEGIN
		CREATE SCHEMA common;
	EXCEPTION
		WHEN duplicate_schema THEN
			NULL;
	END;
$$;

GRANT
	ALL PRIVILEGES
	ON SCHEMA common
	TO fidata_admin;
GRANT
	USAGE
	ON SCHEMA common
	TO fidata;

ALTER DEFAULT PRIVILEGES IN SCHEMA common GRANT
	EXECUTE
	ON FUNCTIONS
	TO fidata;




CREATE DOMAIN common.name_type character varying(64);
	
	
	
-------------------------------------------------------------------------------
-- Original: http://www.postgresql.org/message-id/Pine.LNX.4.44.0310170926100.10119-100000@RedDragon.Childs
-------------------------------------------------------------------------------

CREATE FUNCTION common.xor(boolean, boolean) RETURNS boolean
	LANGUAGE sql IMMUTABLE
AS $$
	SELECT ($1 AND NOT $2) OR (NOT $1 AND $2);
$$;

DROP OPERATOR IF EXISTS ~|(boolean, boolean);

CREATE OPERATOR ~| (
	LEFTARG = boolean,
	RIGHTARG = boolean,
	PROCEDURE = common.xor,
	COMMUTATOR = ~|
);

-------------------------------------------------------------------------------




CREATE FUNCTION common.is_valid_alpha_code(code character varying) RETURNS boolean
	LANGUAGE plpgsql IMMUTABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN code SIMILAR TO '[a-zA-Z]+';
	END
$$;

CREATE FUNCTION common.is_valid_numerical_code(code character varying) RETURNS boolean
	LANGUAGE plpgsql IMMUTABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN code SIMILAR TO '[0-9]+';
	END
$$;

CREATE FUNCTION common.is_valid_alpha_numerical_code(code character varying) RETURNS boolean
	LANGUAGE plpgsql IMMUTABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN code SIMILAR TO '[a-zA-Z0-9]+';
	END
$$;




CREATE DOMAIN common.inn_type character(10);

CREATE FUNCTION common.is_valid_inn(inn common.inn_type) RETURNS boolean
	LANGUAGE plpgsql IMMUTABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN TRUE;
	END
$$;




-------------------------------------------------------------------------------
-- Based on code from Wikipedia
-- Licensed under Creative Commons Attribution-ShareAlike 3.0 Unported License
-------------------------------------------------------------------------------

CREATE DOMAIN common.isin_type character(12);

-- Check of ISIN code:
--   NULL  - invalid format (should be 2 letters + 9 letters/digits + 1 digit)
--   TRUE  - valid code
--   FALSE - invalid check digit
-- Original: http://ru.wikipedia.org/wiki/Международный_идентификационный_код_ценной_бумаги
CREATE FUNCTION common.is_valid_isin(isin common.isin_type) RETURNS boolean
	LANGUAGE plpgsql IMMUTABLE RETURNS NULL ON NULL INPUT
AS $$
	DECLARE
		digit_code  character varying(24);
		check_sum   int;
		p           character(1);          -- Current symbol
		t           int;                   -- Current digit
	BEGIN
		-- Conversion of all letters into upper case
		isin := upper(isin);
	 
		-- Check of format
		IF NOT isin SIMILAR TO '[A-Z][A-Z]_________[0-9]' THEN
			RETURN NULL;
		END IF;
		
		-- TODO: Check of existence of country
	 
		-- Conversion of letters into digits
		digit_code := '';
	 
		FOR i IN 1..length(isin) LOOP
			p := substr(isin, i, 1);
			CASE
				WHEN p BETWEEN '0' AND '9' THEN
					digit_code := digit_code || p;
				WHEN p BETWEEN 'A' AND 'Z' THEN
					-- A -> 10, B -> 11, …, Z -> 35
					digit_code := digit_code || ltrim(to_char(ascii(p) - 65 + 10, '99'));
				ELSE
					RETURN NULL;
			END CASE;
		END LOOP;
	 
		-- Calculation of check sum
		check_sum := 0;
	 
		FOR i IN 1..length(digit_code) LOOP
			t := (ascii(substr(digit_code, i)) - 48) * ((length(digit_code) - i) % 2 + 1);
			IF t > 9 THEN
				t := t - 9;
			END IF;
			check_sum := check_sum + t;
		END LOOP;
	 
		-- Valid ISIN codes has remainder == 0
		RETURN (check_sum % 10) = 0;
	END
$$;

CREATE DOMAIN common.cusip_type character(9);
CREATE FUNCTION common.is_valid_cusip(cusip common.cusip_type) RETURNS boolean
	LANGUAGE plpgsql IMMUTABLE RETURNS NULL ON NULL INPUT
AS $$
	DECLARE
		p         character(1);
		v         int;
		check_sum int;
	BEGIN
		-- Check of format
		IF substr(cusip, 9, 1) NOT BETWEEN '0' AND '9' THEN
			RETURN NULL;
		END IF;
		check_sum := 0;
		FOR i IN 1..length(cusip) LOOP
			p := substr(cusip, i, 1);
			CASE
				WHEN p BETWEEN '0' AND '9' THEN
					v := ascii(p) - 48;
				WHEN p BETWEEN 'A' AND 'Z' THEN
					-- A -> 10, B -> 11, …, Z -> 35
					v := ascii(p) - 65 + 10;
				WHEN p = '*' THEN
					v := 36;
				WHEN p = '@' THEN
					v := 37;
				WHEN p = '#' THEN
					v := 38;
				ELSE
					RETURN NULL;
			END CASE;
			IF i % 2 = 0 THEN
				v := v * 2;
			END IF;
			check_sum := check_sum + v / 10 + v % 10;
		END LOOP;
		RETURN (check_sum % 10) = 0;
	END
$$;

CREATE DOMAIN common.sedol_type character(7);
CREATE FUNCTION common.is_valid_sedol(sedol common.sedol_type) RETURNS boolean
	LANGUAGE plpgsql IMMUTABLE RETURNS NULL ON NULL INPUT
AS $$
	DECLARE
		weights   int[];
		p         character(1);
		check_sum int;
	BEGIN
		-- Check of format
		IF substr(sedol, 7, 1) NOT BETWEEN '0' AND '9' THEN
			RETURN NULL;
		END IF;
		weights := ARRAY[1, 3, 1, 7, 3, 9, 1];
		check_sum := 0;
		FOR i IN 1..length(sedol) LOOP
			p := substr(sedol, i, 1);
			CASE
				WHEN p BETWEEN '0' AND '9' THEN
					check_sum := check_sum + weights[i] * (ascii(p) - 48);
				-- Vowels aren't used
				WHEN p IN ('A', 'E', 'I', 'O', 'U') THEN
					RETURN NULL;
				WHEN p BETWEEN 'B' AND 'Z' THEN
					-- B -> 11, C -> 12, …, Z -> 35
					check_sum := check_sum + weights[i] * (ascii(p) - 65 + 10);
				ELSE
					RETURN NULL;
			END CASE;
		END LOOP;
		RETURN (check_sum % 10) = 0;
	END
$$;

CREATE DOMAIN common.grnv_type character(15); -- ToDo
-------------------------------------------------------------------------------




CREATE DOMAIN common.timezone_type AS character varying(32);




CREATE FUNCTION common.execute_mysql_statement(statement varchar) RETURNS VOID
	LANGUAGE plpgsql VOLATILE
AS $$
	BEGIN
		EXECUTE replace(statement, '`', '"');
	END
$$;

CREATE FUNCTION common.escape_query_for_python(query text) RETURNS text
	LANGUAGE plpgsql IMMUTABLE
AS $$
	BEGIN
		RETURN replace(query, '%', '%%');
	END
$$;




CREATE FUNCTION common.is_aggregate_function(proc regproc) RETURNS bool
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN (SELECT proisagg FROM pg_proc WHERE oid = proc);
	END
$$;

CREATE FUNCTION common.is_window_function(proc regproc) RETURNS bool
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN (SELECT proiswindow FROM pg_proc WHERE oid = proc);
	END
$$;




-------------------------------------------------------------------------------
-- Original: http://wiki.postgresql.org/wiki/First/last_%28aggregate%29
-- Licensed under PostgreSQL license
-------------------------------------------------------------------------------

-- Create a function that always returns the first non-NULL item
CREATE FUNCTION common.first_agg (anyelement, anyelement) RETURNS anyelement
	LANGUAGE sql IMMUTABLE RETURNS NULL ON NULL INPUT
AS $$
	SELECT $1;
$$;
 
-- And then wrap an aggregate around it
CREATE AGGREGATE public.first (
	sfunc    = common.first_agg,
	basetype = anyelement,
	stype    = anyelement
);
 
-- Create a function that always returns the last non-NULL item
CREATE FUNCTION common.last_agg (anyelement, anyelement) RETURNS anyelement
	LANGUAGE sql IMMUTABLE RETURNS NULL ON NULL INPUT
AS $$
	SELECT $2;
$$;
 
-- And then wrap an aggregate around it
CREATE AGGREGATE public.last (
	sfunc    = common.last_agg,
	basetype = anyelement,
	stype    = anyelement
);

-------------------------------------------------------------------------------
