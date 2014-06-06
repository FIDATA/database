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
--                                   TYPES                                   --
-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION test.test_get_type_scale() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: data-sets
	BEGIN
		PERFORM test.assert(get_type_scale(NULL) IS NULL, 'Null input test failed');
		
		PERFORM test.assert_equal(get_type_scale('id'), 'Nominal');
		PERFORM test.assert_equal(get_type_scale('time_moment'), 'Time');
		PERFORM test.assert_equal(get_type_scale('price'), 'Ratio');
		PERFORM test.assert_equal(get_type_scale('pieces'), 'Absolute');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;


CREATE OR REPLACE FUNCTION test.test_get_type_dbms_type() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: data-sets
	BEGIN
		PERFORM test.assert(get_type_dbms_type(NULL) IS NULL, 'Null input test failed');
		
		PERFORM test.assert_equal(get_type_dbms_type('time_moment'), 'time_moment');
		PERFORM test.assert_equal(get_type_dbms_type('ln_ratio'), 'double precision');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;


CREATE OR REPLACE FUNCTION test.test_get_type_diff_type() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: data-sets
	BEGIN
		PERFORM test.assert(get_type_diff_type(NULL) IS NULL, 'Null input test failed');
		
		PERFORM test.assert_equal(get_type_diff_type('price'), 'price');
		PERFORM test.assert_equal(get_type_diff_type('time_moment'), 'time_interval');
		PERFORM test.assert_equal(get_type_diff_type('time_interval'), 'time_interval');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;


CREATE OR REPLACE FUNCTION test.test_get_type_foreign_table() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: data-sets
	BEGIN
		PERFORM test.assert(get_type_foreign_table(NULL) IS NULL, 'Null input test failed');
		
		PERFORM test.assert_equal(get_type_foreign_table('ticker_id'), 'tickers');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;


CREATE OR REPLACE FUNCTION test.test_get_type_foreign_column() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: data-sets
	BEGIN
		PERFORM test.assert(get_type_foreign_column(NULL) IS NULL, 'Null input test failed');
		
		PERFORM test.assert_equal(get_type_foreign_column('ticker_id'), 'id');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;




CREATE OR REPLACE FUNCTION test.test_get_foreign_table_column_dbms_type() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: data-sets
	BEGIN
		PERFORM test.assert(get_foreign_table_column_dbms_type(NULL, NULL) IS NULL, 'Null input test 1 failed');
		PERFORM test.assert(get_foreign_table_column_dbms_type('tickers', NULL) IS NULL, 'Null input test 2 failed');
		PERFORM test.assert(get_foreign_table_column_dbms_type(NULL, 'id') IS NULL, 'Null input test 3 failed');
		
		PERFORM test.assert_equal(get_foreign_table_column_dbms_type('tickers', 'id'), 'bigint');
		PERFORM test.assert(get_foreign_table_column_dbms_type('tickers', 'test') IS NULL, 'Invalid input test 1 failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;




-------------------------------------------------------------------------------
--                                   TIMEFRAMES                              --
-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION test.test_get_timeframe_dbms_interval() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: data-sets
	BEGIN
		PERFORM test.assert(get_timeframe_dbms_interval(NULL) IS NULL, 'Null input test failed');
		
		PERFORM test.assert_equal(get_timeframe_dbms_interval('1Q'), '3 month'::interval);
		PERFORM test.assert_equal(get_timeframe_dbms_interval('1s'), '1 second'::interval);
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;




-------------------------------------------------------------------------------
--                                  FIELDS                                   --
-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION test.test_get_field_type() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: data-sets
	BEGIN
		PERFORM test.assert(get_field_type(NULL) IS NULL, 'Null input test failed');
		
		PERFORM test.assert_equal(get_field_type('ask_price'), 'price');
		PERFORM test.assert_equal(get_field_type('volume'), 'pieces');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;


CREATE OR REPLACE FUNCTION test.test_get_field_ts_type() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: data-sets
	BEGIN
		PERFORM test.assert(get_field_ts_type(NULL) IS NULL, 'Null input test failed');
		
		PERFORM test.assert_equal(get_field_ts_type('order_id'), 'Object');
		PERFORM test.assert_equal(get_field_ts_type('price'), 'Moment');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;


CREATE OR REPLACE FUNCTION test.test_get_field_class() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: data-sets
	BEGIN
		PERFORM test.assert(get_field_class(NULL) IS NULL, 'Null input test failed');
		
		PERFORM test.assert(get_field_class('deal_id') IS NULL, 'deal_id field field_class is not null');
		PERFORM test.assert_equal(get_field_class('price'), 'Flows');
		PERFORM test.assert_equal(get_field_class('volume'), 'Stocks');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;




-------------------------------------------------------------------------------
--                                    DATA SETS                              --
-------------------------------------------------------------------------------

/* CREATE OR REPLACE FUNCTION test.test_check_src_ds() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: data-sets
	BEGIN
		PERFORM test.assert(check_src_ds(NULL, NULL) IS NULL, 'Null input test failed');
		
		PERFORM test.assert_equal(check_src_ds(29169, NULL), TRUE);
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$; */


CREATE OR REPLACE FUNCTION test.test_get_ds_ts_type() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: data-sets
	BEGIN
		PERFORM test.assert(get_ds_ts_type(NULL) IS NULL, 'Null input test failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;


CREATE OR REPLACE FUNCTION test.test_get_ds_object_type() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: data-sets
	BEGIN
		PERFORM test.assert(get_ds_object_type(NULL) IS NULL, 'Null input test failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;


/* CREATE OR REPLACE FUNCTION test.test_get_ds_src_ds() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: data-sets
	BEGIN
		PERFORM test.assert(get_ds_src_ds(NULL) IS NULL, 'Null input test failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$; */


CREATE OR REPLACE FUNCTION test.test_get_ds_timeframe() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: data-sets
	BEGIN
		PERFORM test.assert(get_ds_timeframe(NULL) IS NULL, 'Null input test failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;


CREATE OR REPLACE FUNCTION test.test_get_ds_dbms_interval() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: data-sets
	BEGIN
		PERFORM test.assert(get_ds_dbms_interval(NULL) IS NULL, 'Null input test failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;




CREATE OR REPLACE FUNCTION test.test_get_ds_table_name() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: data-sets
	DECLARE
		table_name name;
	BEGIN
		PERFORM test.assert(get_ds_table_name(NULL) IS NULL, 'Null input test failed');
		
		table_name := get_ds_table_name(12345);
		PERFORM test.assert(table_name IS NOT NULL, 'Table name of data set 12345 is null');
		EXECUTE 'CREATE TABLE '||table_name||'(id bigserial)';
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;




-------------------------------------------------------------------------------
--                             DATA SET FIELDS                               --
-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION test.test_get_ds_field_ds() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: data-sets
	BEGIN
		PERFORM test.assert(get_ds_field_ds(NULL) IS NULL, 'Null input test failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;




CREATE OR REPLACE FUNCTION test.test_get_ds_field_oper_field() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: data-sets
	BEGIN
		PERFORM test.assert(get_ds_field_oper_field(NULL, NULL) IS NULL, 'Null input test 1 failed');
		PERFORM test.assert(get_ds_field_oper_field(1, NULL) IS NULL, 'Null input test 2 failed');
		PERFORM test.assert(get_ds_field_oper_field(NULL, 1) IS NULL, 'Null input test 3 failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;


CREATE OR REPLACE FUNCTION test.test_get_ds_field_oper_proc() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: data-sets
	BEGIN
		PERFORM test.assert(get_ds_field_oper_proc(NULL, NULL) IS NULL, 'Null input test 1 failed');
		PERFORM test.assert(get_ds_field_oper_proc(1, NULL) IS NULL, 'Null input test 2 failed');
		PERFORM test.assert(get_ds_field_oper_proc(NULL, 1) IS NULL, 'Null input test 3 failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;




CREATE OR REPLACE FUNCTION test.test_get_ds_field_column_name() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: data-sets
	BEGIN
		PERFORM test.assert(get_ds_field_column_name(NULL) IS NULL, 'Null input test failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;


CREATE OR REPLACE FUNCTION test.test_get_ds_field_type() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: data-sets
	BEGIN
		PERFORM test.assert(get_ds_field_type(NULL) IS NULL, 'Null input test failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;




CREATE OR REPLACE FUNCTION test.test_add_ds_column() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: data-sets
	BEGIN
		PERFORM test.assert_void('SELECT add_ds_column(NULL, NULL, NULL)');
		PERFORM test.assert_void('SELECT add_ds_column(get_ds_table_name(1), NULL, NULL)');
		PERFORM test.assert_void('SELECT add_ds_column(NULL, ''moment'', NULL)');
		PERFORM test.assert_void('SELECT add_ds_column(NULL, NULL, ''time_moment'')');
		PERFORM test.assert_void('SELECT add_ds_column(get_ds_table_name(1), ''moment'', NULL)');
		PERFORM test.assert_void('SELECT add_ds_column(get_ds_table_name(1), NULL, ''time_moment'')');
		PERFORM test.assert_void('SELECT add_ds_column(NULL, ''moment'', ''time_moment'')');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;


CREATE OR REPLACE FUNCTION test.test_drop_ds_column() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: data-sets
	BEGIN
		PERFORM test.assert_void('SELECT drop_ds_column(NULL, NULL)');
		PERFORM test.assert_void('SELECT drop_ds_column(get_ds_table_name(1), NULL)');
		PERFORM test.assert_void('SELECT drop_ds_column(NULL, ''moment'')');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;




CREATE OR REPLACE FUNCTION test.test_add_ds_field() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: data-sets
	DECLARE
		ds_field_oper data_set_field_operations%ROWTYPE;
	BEGIN
		PERFORM test.assert(add_ds_field(NULL, NULL, NULL, NULL) IS NULL, 'Null input test 1 failed');
		PERFORM test.assert(add_ds_field(1, NULL, NULL, NULL) IS NULL, 'Null input test 2 failed');
		ds_field_oper.field = 'price';
		PERFORM test.assert(add_ds_field(NULL, ARRAY[ds_field_oper], NULL, NULL) IS NULL, 'Null input 3 test failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;




CREATE OR REPLACE FUNCTION test.test_create_ds_table() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: data-sets
	BEGIN
		PERFORM test.assert(create_ds_table(NULL) IS NULL, 'Null input test failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;




CREATE OR REPLACE FUNCTION test.test_get_data_insert_query() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: data-sets
	BEGIN
		PERFORM test.assert(get_data_insert_query(NULL) IS NULL, 'Null input test failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;




-------------------------------------------------------------------------------
--                              COMPOUND TESTS                               --
-------------------------------------------------------------------------------

/*CREATE OR REPLACE FUNCTION test.test_create_ds_table_compound() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: data-sets
	DECLARE
		country_id       int;
		market_id        int;
		data_provider_id bigint;
		instrument_id    bigint;
		ticker_id        bigint;
		ds1_id           bigint;
		ds1_table        name;
		ds2_id           bigint;
		ds2_table        name;
		ds3_id           bigint;
		ds3_table        name;
	BEGIN
		-- Create dummy records
		SELECT id FROM get_country_by_alpha2_code('ZZ') INTO country_id;
		IF country_id IS NULL THEN
			INSERT INTO countries (alpha2_code, name) VALUES ('ZZ', 'Test Country') RETURNING id INTO country_id;
		END IF;

		SELECT id FROM get_market_by_symbol('TEST') INTO market_id;
		IF market_id IS NULL THEN
			INSERT INTO markets (symbol, name, website, timezone) VALUES ('TEST', 'Test Exchange', 'example.com', 'Europe/Moscow') RETURNING id INTO market_id;
		END IF;
		
		SELECT id FROM get_data_provider_by_name('Test Data') INTO data_provider_id;
		IF data_provider_id IS NULL THEN
			INSERT INTO data_providers (name, timezone) VALUES ('Test Data', current_setting('TIMEZONE')) RETURNING id INTO data_provider_id;
		END IF;

		SELECT id FROM get_global_ticker_by_symbol('TST') INTO ticker_id;
		IF ticker_id IS NULL THEN
			INSERT INTO instruments (instr_type) VALUES ('Stock') RETURNING id INTO instrument_id;
			PERFORM test.assert_equal(get_instrument_type(instrument_id), 'Stock');
			PERFORM test.assert_equal(is_currency(instrument_id), FALSE);
			INSERT INTO tickers (instrument, trade_organizer, data_provider, symbol, base_curr) VALUES (instrument_id, NULL, NULL, 'TST', NULL) RETURNING id INTO ticker_id;
		ELSE
			instrument_id := get_ticker_instrument(ticker_id);
		END IF;
		PERFORM test.assert_equal((SELECT symbol FROM get_global_ticker_by_instrument(instrument_id)), 'TST');
		PERFORM test.assert_equal((SELECT id FROM get_global_ticker_by_symbol('TST')), ticker_id);
		PERFORM test.assert_equal((SELECT id FROM get_ticker_by_instrument(instrument_id, NULL, NULL, NULL, NULL)), ticker_id);
		
		PERFORM test.assert_equal(get_ticker_instrument(ticker_id), instrument_id);
		PERFORM test.assert(get_ticker_trade_organizer(ticker_id) IS NULL, 'Trade organizer of ticker is not null');
		PERFORM test.assert(get_ticker_data_provider(ticker_id) IS NULL, 'Data provider of ticker is not null');
		
		INSERT INTO data_sets (ticker, data_provider, market, ts_type, object_type) VALUES (ticker_id, data_provider_id, market_id, 'Object', 'Order') RETURNING id INTO ds1_id;
		PERFORM test.assert_equal(get_ds_ts_type(ds1_id), 'Object');
		PERFORM test.assert_equal(get_ds_object_type(ds1_id), 'Order');
		PERFORM test.assert(get_ds_timeframe(ds1_id) IS NULL, 'Timeframe of data set 1 is not null');
		PERFORM test.assert_raises('SELECT * FROM '||get_ds_table_name(ds1_id), NULL, '42P01'); -- DataSet 1 table should not exist before explicit creation
		SELECT create_ds_table(ds1_id) INTO ds1_table;
		EXECUTE 'SELECT * FROM '||ds1_table;
		
		INSERT INTO data_sets (ticker, data_provider, market, ts_type) VALUES (ticker_id, data_provider_id, market_id, 'Moment') RETURNING id INTO ds2_id;
		PERFORM test.assert_equal(get_ds_ts_type(ds2_id), 'Moment');
		PERFORM test.assert(get_ds_object_type(ds2_id) IS NULL, 'Object type of data set 2 is not null');
		PERFORM test.assert(get_ds_timeframe(ds2_id) IS NULL, 'Timeframe of data set 2 is not null');
		PERFORM test.assert_raises('SELECT * FROM '||get_ds_table_name(ds2_id), NULL, '42P01'); -- DataSet 2 table should not exist before explicit creation
		SELECT create_ds_table(ds2_id) INTO ds2_table;
		EXECUTE 'SELECT * FROM '||ds2_table;
		
		INSERT INTO data_sets (ticker, data_provider, market, ts_type, timeframe) VALUES (ticker_id, data_provider_id, market_id, 'Interval', INTERVAL '1 day') RETURNING id INTO ds3_id;
		PERFORM test.assert_equal(get_ds_ts_type(ds3_id), 'Interval');
		PERFORM test.assert(get_ds_object_type(ds3_id) IS NULL, 'Object type of data set 3 is not null');
		PERFORM test.assert_equal(get_ds_timeframe(ds3_id), '1 day'::interval);
		PERFORM test.assert_raises('SELECT * FROM '||get_ds_table_name(ds3_id), NULL, '42P01'); -- DataSet 3 table should not exist before explicit creation
		SELECT create_ds_table(ds3_id) INTO ds3_table;
		EXECUTE 'SELECT * FROM '||ds3_table;
		
		DELETE FROM data_sets WHERE id = ds3_id;
		PERFORM test.assert_raises('SELECT * FROM '||ds3_table, NULL, '42P01'); -- DataSet 2 table should not exist after deletion
		
		DELETE FROM data_sets WHERE id = ds2_id;
		PERFORM test.assert_raises('SELECT * FROM '||ds2_table, NULL, '42P01'); -- DataSet 2 table should not exist after deletion
		
		DELETE FROM data_sets WHERE id = ds1_id;
		PERFORM test.assert_raises('SELECT * FROM '||ds1_table, NULL, '42P01'); -- DataSet 1 table should not exist after deletion
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;*/
