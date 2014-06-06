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
--                                COUNTRIES                                  --
-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION test.test_get_country() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: fin-system
	BEGIN
		PERFORM test.assert(get_country(NULL) IS NULL, 'Null input test failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;


CREATE OR REPLACE FUNCTION test.test_get_country_by_alpha2_code() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: fin-system
	BEGIN
		PERFORM test.assert(get_country_by_alpha2_code(NULL) IS NULL, 'Null input test failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;


/* CREATE OR REPLACE FUNCTION test.test_get_country_by_num_code() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: fin-system
	BEGIN
		PERFORM test.assert(get_country_by_num_code(NULL) IS NULL, 'Null input test failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$; */


CREATE OR REPLACE FUNCTION test.test_get_country_by_name() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: fin-system
	BEGIN
		PERFORM test.assert(get_country_by_name(NULL) IS NULL, 'Null input test failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;


CREATE OR REPLACE FUNCTION test.test_get_country_by_full_name() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: fin-system
	BEGIN
		PERFORM test.assert(get_country_by_full_name(NULL) IS NULL, 'Null input test failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;




-------------------------------------------------------------------------------
--                                 ISSUERS                                   --
-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION test.test_get_issuer() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: fin-system
	BEGIN
		PERFORM test.assert(get_issuer(NULL) IS NULL, 'Null input test failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;


CREATE OR REPLACE FUNCTION test.test_get_issuer_by_name() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: fin-system
	BEGIN
		PERFORM test.assert(get_issuer_by_name(NULL) IS NULL, 'Null input test failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;


CREATE OR REPLACE FUNCTION test.test_get_issuer_by_inn() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: fin-system
	BEGIN
		PERFORM test.assert(get_issuer_by_inn(NULL) IS NULL, 'Null input test failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;




-------------------------------------------------------------------------------
--                               INSTRUMENTS                                 --
-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION test.test_get_instrument_type() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: fin-system
	BEGIN
		PERFORM test.assert(get_instrument_type(NULL) IS NULL, 'Null input test failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;


CREATE OR REPLACE FUNCTION test.test_is_currency() RETURNS VOID
	LANGUAGE plpgsql
AS $$
	DECLARE
		instrument_id bigint;
-- module: fin-system
	BEGIN
		PERFORM test.assert(is_currency(NULL) IS NULL, 'Null input test failed');
		
		INSERT INTO instruments (instr_type) VALUES ('Currency') RETURNING id INTO instrument_id;
		PERFORM test.assert_equal(is_currency(instrument_id), TRUE);
		
		INSERT INTO instruments (instr_type) VALUES ('Stock') RETURNING id INTO instrument_id;
		PERFORM test.assert_equal(is_currency(instrument_id), FALSE);
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;




CREATE OR REPLACE FUNCTION test.test_get_instrument() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: fin-system
	BEGIN
		PERFORM test.assert(get_instrument(NULL) IS NULL, 'Null input test failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;


CREATE OR REPLACE FUNCTION test.test_get_instrument_by_isin() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: fin-system
	BEGIN
		PERFORM test.assert(get_instrument_by_isin(NULL) IS NULL, 'Null input test failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;


CREATE OR REPLACE FUNCTION test.test_get_instrument_by_cusip() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: fin-system
	BEGIN
		PERFORM test.assert(get_instrument_by_cusip(NULL) IS NULL, 'Null input test failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;


/* CREATE OR REPLACE FUNCTION test.test_get_instrument_by_sedol() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: fin-system
	BEGIN
		PERFORM test.assert(get_instrument_by_sedol(NULL) IS NULL, 'Null input test failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$; */


CREATE OR REPLACE FUNCTION test.test_get_instrument_by_grnv() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: fin-system
	BEGIN
		PERFORM test.assert(get_instrument_by_grnv(NULL) IS NULL, 'Null input test failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;


CREATE OR REPLACE FUNCTION test.test_get_instrument_by_name() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: fin-system
	BEGIN
		PERFORM test.assert(get_instrument_by_name(NULL) IS NULL, 'Null input test failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;




-------------------------------------------------------------------------------
--                                  MARKETS                                  --
-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION test.test_is_trade_organizer() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: fin-system
	DECLARE
		market1_id int;
		market2_id int;
	BEGIN
		PERFORM test.assert(is_trade_organizer(NULL) IS NULL, 'Null input test failed');
		
		INSERT INTO markets (symbol, trade_organizer, name, website, timezone) VALUES ('TEST', NULL, 'Test trade organizer', 'example.com', 'UTC') RETURNING id INTO market1_id;
		PERFORM test.assert_equal(is_trade_organizer(market1_id), TRUE);
		
		INSERT INTO markets (symbol, trade_organizer, name, website, timezone) VALUES (NULL, market1_id, 'Test market', 'example.com', 'UTC') RETURNING id INTO market2_id;
		PERFORM test.assert_equal(is_trade_organizer(market2_id), FALSE);
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;


CREATE OR REPLACE FUNCTION test.test_get_market_trade_organizer() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: fin-system
	DECLARE
		market1_id int;
		market2_id int;
	BEGIN
		PERFORM test.assert(get_market_trade_organizer(NULL) IS NULL, 'Null input test failed');
		
		INSERT INTO markets (symbol, trade_organizer, name, website, timezone) VALUES ('TEST', NULL, 'Test trade organizer', 'example.com', 'UTC') RETURNING id INTO market1_id;
		PERFORM test.assert_equal(get_market_trade_organizer(market1_id), market1_id);
		
		INSERT INTO markets (symbol, trade_organizer, name, website, timezone) VALUES (NULL, market1_id, 'Test market', 'example.com', 'UTC') RETURNING id INTO market2_id;
		PERFORM test.assert_equal(get_market_trade_organizer(market2_id), market1_id);
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;




CREATE OR REPLACE FUNCTION test.test_get_market() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: fin-system
	BEGIN
		PERFORM test.assert(get_market(NULL) IS NULL, 'Null input test failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;


CREATE OR REPLACE FUNCTION test.test_get_market_by_symbol() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: fin-system
	BEGIN
		PERFORM test.assert(get_market_by_symbol(NULL) IS NULL, 'Null input test failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;


CREATE OR REPLACE FUNCTION test.test_get_market_by_name() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: fin-system
	BEGIN
		PERFORM test.assert(get_market_by_name(NULL) IS NULL, 'Null input test failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;




-------------------------------------------------------------------------------
--                              DATA PROVIDERS                               --
-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION test.test_get_data_provider() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: fin-system
	BEGIN
		PERFORM test.assert(get_data_provider(NULL) IS NULL, 'Null input test failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;


CREATE OR REPLACE FUNCTION test.test_get_data_provider_by_name() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: fin-system
	BEGIN
		PERFORM test.assert(get_data_provider_by_name(NULL) IS NULL, 'Null input test failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;




-------------------------------------------------------------------------------
--                                 TICKERS                                   --
-------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION test.test_get_ticker_instrument() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: fin-system
	BEGIN
		PERFORM test.assert(get_ticker_instrument(NULL) IS NULL, 'Null input test failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;


CREATE OR REPLACE FUNCTION test.test_get_ticker_trade_organizer() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: fin-system
	BEGIN
		PERFORM test.assert(get_ticker_trade_organizer(NULL) IS NULL, 'Null input test failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;


CREATE OR REPLACE FUNCTION test.test_get_ticker_data_provider() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: fin-system
	BEGIN
		PERFORM test.assert(get_ticker_data_provider(NULL) IS NULL, 'Null input test failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;




CREATE OR REPLACE FUNCTION test.test_get_ticker() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: fin-system
	BEGIN
		PERFORM test.assert(get_ticker(NULL) IS NULL, 'Null input test failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;


CREATE OR REPLACE FUNCTION test.test_get_global_ticker_by_instrument() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: fin-system
	BEGIN
		PERFORM test.assert(get_global_ticker_by_instrument(NULL) IS NULL, 'Null input test failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;


CREATE OR REPLACE FUNCTION test.test_get_global_ticker_by_symbol() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: fin-system
	BEGIN
		PERFORM test.assert(get_global_ticker_by_symbol(NULL) IS NULL, 'Null input test failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;


CREATE OR REPLACE FUNCTION test.test_get_ticker_by_instrument() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: fin-system
	DECLARE
		trade_organizer_id int;
		data_provider_id   bigint;
	BEGIN
		PERFORM test.assert(get_ticker_by_instrument(NULL, NULL, NULL, NULL, NULL) IS NULL, 'Null input test 1 failed');
		
		SELECT id FROM get_market_by_symbol('TEST') INTO trade_organizer_id;
		IF trade_organizer_id IS NULL THEN
			INSERT INTO markets (symbol, name, website, timezone) VALUES ('TEST', 'Test Exchange', 'example.com', 'UTC') RETURNING id INTO trade_organizer_id;
		END IF;
		SELECT id FROM get_data_provider_by_name('Test Data') INTO data_provider_id;
		IF data_provider_id IS NULL THEN
			INSERT INTO data_providers (name, timezone) VALUES ('Test Data', current_setting('TIMEZONE')) RETURNING id INTO data_provider_id;
		END IF;
		
		PERFORM test.assert(get_ticker_by_instrument(NULL, trade_organizer_id, NULL, NULL, NULL) IS NULL, 'Null input test 2 failed');
		PERFORM test.assert(get_ticker_by_instrument(NULL, NULL, data_provider_id, NULL, NULL) IS NULL, 'Null input test 3 failed');
		PERFORM test.assert(get_ticker_by_instrument(NULL, trade_organizer_id, data_provider_id, NULL, NULL) IS NULL, 'Null input test 4 failed');
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;


CREATE OR REPLACE FUNCTION test.test_get_ticker_by_trade_organizer_symbol() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: fin-system
	DECLARE
		trade_organizer_id int;
		instrument_id      bigint;
		ticker_id          bigint;
	BEGIN
		PERFORM test.assert(get_ticker_by_trade_organizer_symbol(NULL, NULL) IS NULL, 'Null input test failed');
		
		SELECT id FROM get_market_by_symbol('TEST') INTO trade_organizer_id;
		IF trade_organizer_id IS NULL THEN
			INSERT INTO markets (symbol, name, website, timezone) VALUES ('TEST', 'Test Exchange', 'example.com', 'UTC') RETURNING id INTO trade_organizer_id;
		END IF;
		
		INSERT INTO instruments (instr_type) VALUES ('Stock') RETURNING id INTO instrument_id;
		INSERT INTO tickers (instrument, trade_organizer, data_provider, symbol, base_curr) VALUES (instrument_id, trade_organizer_id, NULL, 'TEST', NULL) RETURNING id INTO ticker_id;
		
		PERFORM test.assert_equal(get_ticker_instrument(ticker_id), instrument_id);
		PERFORM test.assert_equal(get_ticker_trade_organizer(ticker_id), trade_organizer_id);
		PERFORM test.assert(get_ticker_data_provider(ticker_id) IS NULL, 'Data provider of ticker is not null');
		
		PERFORM test.assert_equal((SELECT id FROM get_ticker(ticker_id)), ticker_id);
		PERFORM test.assert_equal((SELECT id FROM get_ticker_by_trade_organizer_symbol(trade_organizer_id, 'TEST')), ticker_id);
		PERFORM test.assert_equal((SELECT id FROM get_ticker_by_instrument(instrument_id, trade_organizer_id, NULL, NULL, NULL)), ticker_id);
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;


CREATE OR REPLACE FUNCTION test.test_get_ticker_by_data_provider_symbol() RETURNS VOID
	LANGUAGE plpgsql
AS $$
-- module: fin-system
	DECLARE
		data_provider_id bigint;
		instrument_id    bigint;
		ticker_id        bigint;
	BEGIN
		PERFORM test.assert(get_ticker_by_trade_organizer_symbol(NULL, NULL) IS NULL, 'Null input test failed');
		
		SELECT id FROM get_data_provider_by_name('Test Data') INTO data_provider_id;
		IF data_provider_id IS NULL THEN
			INSERT INTO data_providers (name, timezone) VALUES ('Test Data', current_setting('TIMEZONE')) RETURNING id INTO data_provider_id;
		END IF;
		
		INSERT INTO instruments (instr_type) VALUES ('Stock') RETURNING id INTO instrument_id;
		INSERT INTO tickers (instrument, trade_organizer, data_provider, symbol, base_curr) VALUES (instrument_id, NULL, data_provider_id, 'TEST', NULL) RETURNING id INTO ticker_id;
		
		PERFORM test.assert_equal(get_ticker_instrument(ticker_id), instrument_id);
		PERFORM test.assert(get_ticker_trade_organizer(ticker_id) IS NULL, 'Trade organizer of ticker is not null');
		PERFORM test.assert_equal(get_ticker_data_provider(ticker_id), data_provider_id);
		
		PERFORM test.assert_equal((SELECT id FROM get_ticker(ticker_id)), ticker_id);
		PERFORM test.assert_equal((SELECT id FROM get_ticker_by_data_provider_symbol(data_provider_id, 'TEST')), ticker_id);
		PERFORM test.assert_equal((SELECT id FROM get_ticker_by_instrument(instrument_id, NULL, data_provider_id, NULL, NULL)), ticker_id);
		
		-- ALWAYS RAISE EXCEPTION at the end of test procs to rollback!
		RAISE EXCEPTION '[OK]';
	END
$$;
