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




CREATE OR REPLACE FUNCTION test.test_xor() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: common
	BEGIN
		PERFORM test.assert(common.xor(NULL, NULL) IS NULL, 'Null input test 1 failed');
		PERFORM test.assert(common.xor(NULL, TRUE) IS NULL, 'Null input test 2 failed');
		PERFORM test.assert(common.xor(FALSE, NULL) IS NULL, 'Null input test 3 failed');
		
		PERFORM test.assert_equal(common.xor(FALSE, FALSE), FALSE);
		PERFORM test.assert_equal(common.xor(FALSE, TRUE), TRUE);
		PERFORM test.assert_equal(common.xor(TRUE, FALSE), TRUE);
		PERFORM test.assert_equal(common.xor(TRUE, TRUE), FALSE);
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;

CREATE OR REPLACE FUNCTION test.test_xor_operator() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: common
	BEGIN
		PERFORM test.assert((NULL::bool ~| NULL) IS NULL, 'Null input test 1 failed');
		PERFORM test.assert((NULL::bool ~| FALSE) IS NULL, 'Null input test 2 failed');
		PERFORM test.assert((TRUE ~| NULL) IS NULL, 'Null input test 3 failed');
		
		PERFORM test.assert_equal(FALSE ~| FALSE, FALSE);
		PERFORM test.assert_equal(FALSE ~| TRUE, TRUE);
		PERFORM test.assert_equal(TRUE ~| FALSE, TRUE);
		PERFORM test.assert_equal(TRUE ~| TRUE, FALSE);
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;




CREATE OR REPLACE FUNCTION test.test_is_valid_alpha_code() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: common
	BEGIN
		PERFORM test.assert(common.is_valid_alpha_code(NULL) IS NULL, 'Null input test failed');
		
		PERFORM test.assert_equal(common.is_valid_alpha_code('A'), TRUE);
		PERFORM test.assert_equal(common.is_valid_alpha_code('AB'), TRUE);
		PERFORM test.assert_equal(common.is_valid_alpha_code('CDE'), TRUE);
		PERFORM test.assert_equal(common.is_valid_alpha_code('scAl'), TRUE);
		
		PERFORM test.assert_equal(common.is_valid_alpha_code(' A'), FALSE);
		PERFORM test.assert_equal(common.is_valid_alpha_code('A '), FALSE);
		PERFORM test.assert_equal(common.is_valid_alpha_code('A_'), FALSE);
		PERFORM test.assert_equal(common.is_valid_alpha_code('-'), FALSE);
		PERFORM test.assert_equal(common.is_valid_alpha_code('1'), FALSE);
		PERFORM test.assert_equal(common.is_valid_alpha_code(''), FALSE);
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;


CREATE OR REPLACE FUNCTION test.test_is_valid_numerical_code() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: common
	BEGIN
		PERFORM test.assert(common.is_valid_numerical_code(NULL) IS NULL, 'Null input test failed');
		
		PERFORM test.assert_equal(common.is_valid_numerical_code('0'), TRUE);
		PERFORM test.assert_equal(common.is_valid_numerical_code('01'), TRUE);
		PERFORM test.assert_equal(common.is_valid_numerical_code('123'), TRUE);
		
		PERFORM test.assert_equal(common.is_valid_numerical_code(' 1'), FALSE);
		PERFORM test.assert_equal(common.is_valid_numerical_code('1 '), FALSE);
		PERFORM test.assert_equal(common.is_valid_numerical_code('1_'), FALSE);
		PERFORM test.assert_equal(common.is_valid_numerical_code('-'), FALSE);
		PERFORM test.assert_equal(common.is_valid_numerical_code('O'), FALSE);
		PERFORM test.assert_equal(common.is_valid_numerical_code(''), FALSE);
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;


CREATE OR REPLACE FUNCTION test.test_is_valid_alpha_numerical_code() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: common
	BEGIN
		PERFORM test.assert(common.is_valid_alpha_numerical_code(NULL) IS NULL, 'Null input test failed');
		
		PERFORM test.assert_equal(common.is_valid_alpha_numerical_code('A'), TRUE);
		PERFORM test.assert_equal(common.is_valid_alpha_numerical_code('AB'), TRUE);
		PERFORM test.assert_equal(common.is_valid_alpha_numerical_code('CDE'), TRUE);
		PERFORM test.assert_equal(common.is_valid_alpha_numerical_code('scAl'), TRUE);
		PERFORM test.assert_equal(common.is_valid_alpha_numerical_code('0'), TRUE);
		PERFORM test.assert_equal(common.is_valid_alpha_numerical_code('01'), TRUE);
		PERFORM test.assert_equal(common.is_valid_alpha_numerical_code('123'), TRUE);
		
		PERFORM test.assert_equal(common.is_valid_alpha_numerical_code(' A'), FALSE);
		PERFORM test.assert_equal(common.is_valid_alpha_numerical_code('A '), FALSE);
		PERFORM test.assert_equal(common.is_valid_alpha_numerical_code('A_'), FALSE);
		PERFORM test.assert_equal(common.is_valid_alpha_numerical_code('-'), FALSE);
		PERFORM test.assert_equal(common.is_valid_alpha_numerical_code(' 1'), FALSE);
		PERFORM test.assert_equal(common.is_valid_alpha_numerical_code('1 '), FALSE);
		PERFORM test.assert_equal(common.is_valid_alpha_numerical_code('1_'), FALSE);
		PERFORM test.assert_equal(common.is_valid_alpha_numerical_code('-'), FALSE);
		PERFORM test.assert_equal(common.is_valid_alpha_numerical_code(''), FALSE);
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;




CREATE OR REPLACE FUNCTION test.test_is_valid_inn() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: common
	BEGIN
		PERFORM test.assert(common.is_valid_inn(NULL) IS NULL, 'Null input test failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;




CREATE OR REPLACE FUNCTION test.test_is_valid_isin() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: common
	BEGIN
		PERFORM test.assert(common.is_valid_isin(NULL) IS NULL, 'Null input test failed');
	
		PERFORM test.assert_equal(common.is_valid_isin('US0378331005'), TRUE);
		PERFORM test.assert_equal(common.is_valid_isin('AU0000XVGZA3'), TRUE);
		PERFORM test.assert_equal(common.is_valid_isin('GB0002634946'), TRUE);
		
		PERFORM test.assert_equal(common.is_valid_isin('US0378333005'), FALSE);
		PERFORM test.assert_equal(common.is_valid_isin('AU0020XVGZA3'), FALSE);
		PERFORM test.assert_equal(common.is_valid_isin('GB4002634946'), FALSE);
		
		PERFORM test.assert(common.is_valid_isin('U50378331005') IS NULL, 'Invalid format test 1 failed');
		PERFORM test.assert(common.is_valid_isin('US037833100S') IS NULL, 'Invalid format test 2 failed');
		PERFORM test.assert(common.is_valid_isin('4U0000XVGZA3') IS NULL, 'Invalid format test 3 failed');
		PERFORM test.assert(common.is_valid_isin('US037833100') IS NULL, 'Invalid format test 4 failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;


CREATE OR REPLACE FUNCTION test.test_is_valid_cusip() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: common
	BEGIN
		PERFORM test.assert(common.is_valid_cusip(NULL) IS NULL, 'Null input test failed');
		
		PERFORM test.assert_equal(common.is_valid_cusip('037833100'), TRUE);
		
		PERFORM test.assert_equal(common.is_valid_cusip('037843100'), FALSE);
		
		PERFORM test.assert(common.is_valid_cusip('03784310O') IS NULL, 'Invalid format test 1 failed');
		PERFORM test.assert(common.is_valid_cusip('03783310') IS NULL, 'Invalid format test 2 failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;


CREATE OR REPLACE FUNCTION test.test_is_valid_sedol() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: common
	BEGIN
		PERFORM test.assert(common.is_valid_sedol(NULL) IS NULL, 'Null input test failed');
		
		PERFORM test.assert_equal(common.is_valid_sedol('0263494'), TRUE);
		PERFORM test.assert_equal(common.is_valid_sedol('B1F3M59'), TRUE);
		
		PERFORM test.assert_equal(common.is_valid_sedol('B1H54P6'), FALSE);
		
		PERFORM test.assert(common.is_valid_cusip('O263494') IS NULL, 'Invalid format test 1 failed');
		PERFORM test.assert(common.is_valid_sedol('BIF3M59') IS NULL, 'Invalid format test 2 failed');
		PERFORM test.assert(common.is_valid_sedol('026349') IS NULL, 'Invalid format test 3 failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;
