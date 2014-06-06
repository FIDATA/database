-- FIDATA. Open-source system for analysis of financial and economic data
-- Copyright © 2013  Basil Peace

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


CREATE OR REPLACE FUNCTION test.test_get_proc_type() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: procs
	BEGIN
		PERFORM test.assert(procs.get_proc_type(NULL) IS NULL, 'Null input test failed');
		
		-- Functions, computing fields
		PERFORM test.assert_equal(procs.get_proc_type('spread'), 'comp_field_func');
		
		-- Aggregating functions
		PERFORM test.assert_equal(procs.get_proc_type('sum'), 'aggr_func');
		
		-- Functions, showing dynamics
		PERFORM test.assert_equal(procs.get_proc_type('change'), 'dyn_show_func');
		
		-- Window functions
		PERFORM test.assert_equal(procs.get_proc_type('Var'), 'window_func');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;


CREATE OR REPLACE FUNCTION test.test_get_proc_output_type() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: procs
	BEGIN
		PERFORM test.assert(procs.get_proc_output_type(NULL) IS NULL, 'Null input test failed');
		
		-- Functions, computing fields
		PERFORM test.assert_equal(procs.get_proc_output_type('amount'), 'amount');
		
		-- Aggregating functions
		PERFORM test.assert_equal(procs.get_proc_output_type('number'), 'pieces');
		PERFORM test.assert(procs.get_proc_output_type('high') IS NULL, 'high proc output_type is not null');
		
		-- Functions, showing dynamics
		PERFORM test.assert(procs.get_proc_output_type('change') IS NULL, 'change proc output_type is not null');
		PERFORM test.assert_equal(procs.get_proc_output_type('ln_growth_rate'), 'ln_ratio');
		PERFORM test.assert(procs.get_proc_output_type('one_percent_of_change') IS NULL, 'one_percent_of_change proc output_type is not null');
		
		-- Window functions
		PERFORM test.assert_equal(procs.get_proc_output_type('Count'), 'pieces');
		PERFORM test.assert(procs.get_proc_output_type('Mean') IS NULL, 'Mean proc output_type is not null');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;


CREATE OR REPLACE FUNCTION test.test_get_proc_output_type_is_diff() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: procs
	BEGIN
		PERFORM test.assert(procs.get_proc_output_type_is_diff(NULL) IS NULL, 'Null input test failed');
		
		-- Functions, computing fields
		PERFORM test.assert(procs.get_proc_output_type_is_diff('mid_price') IS NULL, 'mid_price proc output_type_is_diff is not null');
		
		-- Aggregating functions
		PERFORM test.assert(procs.get_proc_output_type_is_diff('close') IS NULL, 'close proc output_type_is_diff is not null');
		
		-- Functions, showing dynamics
		PERFORM test.assert_equal(procs.get_proc_output_type_is_diff('change'), TRUE);
		PERFORM test.assert_equal(procs.get_proc_output_type_is_diff('change_rate'), FALSE);
		PERFORM test.assert_equal(procs.get_proc_output_type_is_diff('one_percent_of_change'), FALSE);
		
		-- Window functions
		PERFORM test.assert(procs.get_proc_output_type_is_diff('Max') IS NULL, 'Max proc output_type_is_diff is not null');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;


CREATE OR REPLACE FUNCTION test.test_get_proc_output_field() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: procs
	BEGIN
		PERFORM test.assert(procs.get_proc_output_field(NULL) IS NULL, 'Null input test failed');
		
		-- Functions, computing fields
		PERFORM test.assert_equal(procs.get_proc_output_field('ask_price'), 'ask_price');
		PERFORM test.assert_equal(procs.get_proc_output_field('mid_price_from_bid_price_ask_price'), 'mid_price');
		
		-- Aggregating functions
		PERFORM test.assert(procs.get_proc_output_field('close') IS NULL, 'close proc output_field is not null');
		
		-- Functions, showing dynamics
		PERFORM test.assert(procs.get_proc_output_field('growth_rate') IS NULL, 'growth_rate proc output_field is not null');
		
		-- Window functions
		PERFORM test.assert(procs.get_proc_output_field('Min') IS NULL, 'Min proc output_field is not null');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;
