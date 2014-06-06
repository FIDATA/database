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


CREATE OR REPLACE FUNCTION test.test_get_lang() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: intl
	BEGIN
		PERFORM test.assert(get_lang(NULL) IS NULL, 'Null input test failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;

CREATE OR REPLACE FUNCTION test.test_get_lang_by_part1_code() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: intl
	BEGIN
		PERFORM test.assert(get_lang_by_part1_code(NULL) IS NULL, 'Null input test failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;

CREATE OR REPLACE FUNCTION test.test_get_lang_by_name() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: intl
	BEGIN
		PERFORM test.assert(get_lang_by_name(NULL) IS NULL, 'Null input test failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;


CREATE OR REPLACE FUNCTION test.test_get_script() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: intl
	BEGIN
		PERFORM test.assert(get_script(NULL) IS NULL, 'Null input test failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;

CREATE OR REPLACE FUNCTION test.test_get_script_by_name() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: intl
	BEGIN
		PERFORM test.assert(get_script_by_name(NULL) IS NULL, 'Null input test failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;


CREATE OR REPLACE FUNCTION test.test_is_valid_lang_script() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: intl
	BEGIN
		PERFORM test.assert(is_valid_lang_script(NULL, NULL) IS NULL, 'Null input test 1 failed');
		PERFORM test.assert(is_valid_lang_script(NULL, 'Latn') IS NULL, 'Null input test 2 failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;
