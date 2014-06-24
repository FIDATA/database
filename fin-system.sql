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
--                               INSTRUMENT TYPES                            --
-------------------------------------------------------------------------------

CREATE TYPE instrument_type AS ENUM (
	'Stock',
	'Bond',
	'Fund',
	'Currency',
	'Index',
	'Commodity',
	'Wheather',
	'Option',
	'Future',
	'Warrant',
	'DepositaryReceipt'
--	'MacroData'/'MacroIndex'/'EconomicalData'/'CommonData'
);




-- CREATE TABLE instrument_groups (
-- 	instrument_group_id smallint NOT NULL DEFAULT nextval('instrument_groups_instrument_group_id_seq'::regclass) PRIMARY KEY,
-- 	name character varying(32) NOT NULL
--		CHECK (char_length(name) > 0),
-- );
-- CREATE UNIQUE INDEX ON instrument_groups (instrument_group_name);
-- CREATE TABLE instrument_types (
-- 	instrument_type_id smallint NOT NULL DEFAULT nextval('instrument_types_instrument_type_id_seq'::regclass) PRIMARY KEY,
-- 	name character varying(32) NOT NULL
--		CHECK (char_length(name) > 0),
-- );
-- CREATE UNIQUE INDEX ON instrument_types (instrument_type_name);
-- INSERT INTO instrument_types(instrument_type_name) VALUES
-- 	('spot'),	-- 1
-- 	('data'),	-- 2
-- 	('forward'),	-- 3
-- ;




CREATE DOMAIN price_type AS decimal(16, 5);
-- CREATE DOMAIN prices_type  AS decimal(16, 5)[]; -- ToDo
-- WARNING: decimal without precision and scale specified is NOT PORTABLE
CREATE DOMAIN pieces_type decimal;
CREATE DOMAIN amount_type decimal;




-------------------------------------------------------------------------------
--                           GROUPS OF COUNTRIES                             --
-------------------------------------------------------------------------------

CREATE TYPE countries_group_type AS ENUM (
	'Geographical',
-- Political is used for officially founded groups of countries, including
-- economic commonwealths and unions.
-- Economic is used only for unofficial / custom group
	'Political',
	'Economic'
);

CREATE TABLE countries_groups (
	id smallserial PRIMARY KEY,
	name character varying(64),
	group_type countries_group_type NOT NULL
);




-------------------------------------------------------------------------------
--                                COUNTRIES                                  --
-------------------------------------------------------------------------------

CREATE TABLE countries (
	id serial PRIMARY KEY,
	
	alpha2_code character(2) -- ISO 3166-1
		CHECK (common.is_valid_alpha_code(alpha2_code) IS DISTINCT FROM FALSE),
/*	num_code character(3)    -- UN M.49
		CHECK (common.is_valid_numerical_code(num_code)),*/
	name character varying(255) NOT NULL
		CHECK (char_length(name) > 0),
	full_name character varying(255),
		CHECK (char_length(name) IS DISTINCT FROM 0),
		
	is_state boolean NOT NULL DEFAULT TRUE,
	parent_contry int
		REFERENCES countries (id)
			ON UPDATE CASCADE ON DELETE RESTRICT,
	associated_with int
		REFERENCES countries (id)
			ON UPDATE CASCADE ON DELETE RESTRICT,
			
	gov_website character varying(128)
		CHECK (char_length(gov_website) IS DISTINCT FROM 0),
	stats_website character varying(128)
		CHECK (char_length(stats_website) IS DISTINCT FROM 0),
		
	flag bytea DEFAULT NULL,
	
	actuality boolean NOT NULL DEFAULT TRUE,
	comments character varying(255) NOT NULL DEFAULT ''
);
-- TODO: Codes (and names) may be non-unique in long period
CREATE UNIQUE INDEX ON countries (alpha2_code);
-- CREATE UNIQUE INDEX ON countries (num_code);
CREATE UNIQUE INDEX ON countries (upper(name));
CREATE UNIQUE INDEX ON countries (upper(full_name));
CREATE INDEX ON countries (parent_contry);
CREATE INDEX ON countries (associated_with);
CREATE INDEX ON countries (actuality);
SELECT setval('countries_id_seq', 2048);

CREATE FUNCTION triggers.countries_set_codes_case() RETURNS trigger
	LANGUAGE plpgsql VOLATILE
AS $$
	BEGIN
		NEW.alpha2_code := upper(NEW.alpha2_code);
		RETURN NEW;
	END
$$;
CREATE TRIGGER set_codes_case
	BEFORE INSERT
	ON countries
	FOR EACH ROW
	EXECUTE PROCEDURE triggers.countries_set_codes_case()
;


CREATE FUNCTION get_country(country_id int, OUT res countries)
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		SELECT * FROM countries WHERE id = country_id INTO res;
	END
$$;

CREATE FUNCTION get_country_by_alpha2_code(country_alpha2_code character(2), OUT res countries)
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		SELECT * FROM countries WHERE alpha2_code = upper(country_alpha2_code) INTO res;
	END
$$;

/*CREATE FUNCTION get_country_by_num_code(country_num_code character(3), OUT res countries))
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		SELECT * FROM countries WHERE num_code = country_num_code INTO res;
	END
$$;*/

CREATE FUNCTION get_country_by_name(country_name character varying(255), OUT res countries)
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		SELECT * FROM countries WHERE upper(name) = upper(country_name) INTO res;
	END
$$;

CREATE FUNCTION get_country_by_full_name(country_full_name character varying(255), OUT res countries)
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		SELECT * FROM countries WHERE upper(full_name) = upper(country_full_name) INTO res;
	END
$$;




-- CREATE TABLE iso3166_codes + aliases
-- CREATE TABLE int_organizations
-- CREATE TABLE subdivisions
-- CREATE TABLE regions
-- CREATE TABLE cities + timezones
-- capitals




-------------------------------------------------------------------------------
--                                 ISSUERS                                   --
-------------------------------------------------------------------------------

CREATE TABLE issuers (
	id bigserial PRIMARY KEY,
	name character varying(160) NOT NULL
		CHECK (char_length(name) > 0),
	inn common.inn_type
		CHECK (common.is_valid_inn(inn) IS DISTINCT FROM FALSE),
	
	logo bytea DEFAULT NULL,
	
	actuality boolean DEFAULT TRUE,
	comments character varying(255) NOT NULL DEFAULT ''
);
CREATE UNIQUE INDEX ON issuers (upper(name)); -- TODO: Name can be non-unique
CREATE UNIQUE INDEX ON issuers (inn); -- INN can be non-unique in long period (see 1C)
CREATE INDEX ON issuers (actuality);

CREATE FUNCTION get_issuer(issuer_id bigint, OUT res issuers)
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		SELECT * FROM issuers WHERE id = issuer_id INTO res;
	END
$$;

CREATE FUNCTION get_issuer_by_name(issuer_name character varying(160), OUT res issuers)
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		SELECT * FROM issuers WHERE upper(name) = upper(issuer_name) INTO res;
	END
$$;

CREATE FUNCTION get_issuer_by_inn(issuer_inn character varying(160), OUT res issuers)
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		SELECT * FROM issuers WHERE inn = issuer_inn INTO res;
	END
$$;




-------------------------------------------------------------------------------
--                               INSTRUMENTS                                 --
-------------------------------------------------------------------------------

CREATE TABLE currencies (
	id bigint PRIMARY KEY,
	instr_type instrument_type NOT NULL
		CHECK (instr_type = 'Currency')
);


CREATE FUNCTION get_instrument_type(instrument_id bigint) RETURNS instrument_type
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN (SELECT instr_type FROM instruments WHERE id = instrument_id);
	END
$$;

CREATE FUNCTION is_currency(instrument_id bigint) RETURNS boolean
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN (get_instrument_type(instrument_id) = 'Currency');
	END
$$;


CREATE TABLE instruments (
	id bigserial PRIMARY KEY,
	instr_type instrument_type NOT NULL,
	
	issuer bigint
		REFERENCES issuers (id)
			ON UPDATE CASCADE ON DELETE RESTRICT,
	CHECK ((instr_type IN ('Stock', 'Bond', 'Fund', 'DepositaryReceipt')) OR (issuer IS NULL)),
	
	isin common.isin_type
		CHECK (isin IS NULL OR common.is_valid_isin(isin) = TRUE),
	CHECK ((instr_type IN ('Stock', 'Bond', 'Fund', 'DepositaryReceipt')) OR (isin IS NULL)),
	
	cusip common.cusip_type
		CHECK (cusip IS NULL OR common.is_valid_cusip(cusip) = TRUE),
	CHECK ((instr_type IN ('Stock', 'Bond', 'Fund', 'DepositaryReceipt')) OR (cusip IS NULL)),

/* 	sedol common.sedol_type
		CHECK (sedol IS NULL OR common.is_valid_sedol(sedol) = TRUE),
	CHECK ((instr_type IN ('Stock', 'Bond', 'Fund', 'DepositaryReceipt')) OR (sedol IS NULL)),
*/
	grnv common.grnv_type,
--	CHECK ((instr_type IN ('Stock', 'Bond', 'Fund', 'DepositaryReceipt')) OR (grnv IS NULL)), -- TODO
		
	total_count pieces_type
		CHECK ((total_count IS NULL) OR (total_count > 0)),
	nom_price price_type
		CHECK ((nom_price IS NULL) OR (nom_price > 0)),
	nom_price_curr bigint
		REFERENCES currencies (id)
			ON UPDATE CASCADE ON DELETE RESTRICT,
	CHECK ((instr_type IN ('Stock', 'Bond')) OR (nom_price IS NULL) AND (nom_price_curr IS NULL)),
	
	base_instr bigint
		REFERENCES instruments (id)
			ON UPDATE CASCADE ON DELETE RESTRICT,
	CHECK ((instr_type IN ('Option', 'Future', 'Warrant', 'DepositaryReceipt')) ~| (base_instr IS NULL)),

	name character varying(255)
		CHECK (char_length(name) IS DISTINCT FROM 0),
		
	actuality boolean NOT NULL DEFAULT TRUE,
	comments character varying(255) NOT NULL DEFAULT ''
--	update_date timestamptz(0) NOT NULL DEFAULT CURRENT_TIMESTAMP -- In UTC!
);
-- CREATE INDEX ON instruments (issuer);
CREATE INDEX ON instruments (issuer, instr_type, nom_price, nom_price_curr);
-- CREATE INDEX ON instruments (instr_type);
CREATE INDEX ON instruments (instr_type, base_instr);
CREATE UNIQUE INDEX ON instruments (isin);
CREATE UNIQUE INDEX ON instruments (cusip);
-- CREATE UNIQUE INDEX ON instruments (sedol);
CREATE UNIQUE INDEX ON instruments (grnv);
CREATE INDEX ON instruments (nom_price_curr);
CREATE UNIQUE INDEX ON instruments (upper(name));
CREATE INDEX ON instruments (actuality);
/* TODO: Maybe we should ask PostgreSQL team to add feature to allow creation
of foreign key when only part of it is already unique in referenced table */
CREATE UNIQUE INDEX ON instruments (id, instr_type);
SELECT setval('instruments_id_seq', 1048576);

CREATE FUNCTION triggers.instruments_set_codes_case() RETURNS trigger
	LANGUAGE plpgsql VOLATILE
AS $$
	BEGIN
		NEW.isin  := upper(NEW.isin);
		NEW.cusip := upper(NEW.cusip);
--		NEW.sedol := upper(NEW.sedol);
		NEW.grnv  := upper(NEW.grnv); -- TODO
		RETURN NEW;
	END
$$;
CREATE TRIGGER set_codes_case
	BEFORE INSERT
	ON instruments
	FOR EACH ROW
	EXECUTE PROCEDURE triggers.instruments_set_codes_case()
;

CREATE FUNCTION triggers.instruments_after_insert_currency() RETURNS trigger
	LANGUAGE plpgsql VOLATILE
AS $$
	BEGIN
		IF NEW.instr_type = 'Currency' THEN
			INSERT INTO currencies (id, instr_type) VALUES (NEW.id, NEW.instr_type);
		END IF;
		RETURN NULL;
	END
$$;
CREATE TRIGGER after_insert_currency
	AFTER INSERT
	ON instruments
	FOR EACH ROW
	EXECUTE PROCEDURE triggers.instruments_after_insert_currency()
;


CREATE FUNCTION get_instrument(instrument_id bigint, OUT res instruments)
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		SELECT * FROM instruments WHERE id = instrument_id INTO res;
	END
$$;

CREATE FUNCTION get_instrument_by_isin(instr_isin common.isin_type, OUT res instruments)
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		SELECT * FROM instruments WHERE isin = upper(instr_isin) INTO res;
	END
$$;

CREATE FUNCTION get_instrument_by_cusip(instr_cusip common.cusip_type, OUT res instruments)
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		SELECT * FROM instruments WHERE cusip = upper(instr_cusip) INTO res;
	END
$$;

/*CREATE FUNCTION get_instrument_by_sedol(instr_isin common.sedol_type, OUT res instruments)
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		SELECT * FROM instruments WHERE sedol = upper(instr_sedol) INTO res;
	END
$$;*/

CREATE FUNCTION get_instrument_by_grnv(instr_grnv common.grnv_type, OUT res instruments)
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		SELECT * FROM instruments WHERE grnv = upper(instr_grnv) INTO res;
	END
$$;

CREATE FUNCTION get_instrument_by_name(instr_name character varying(255), OUT res instruments)
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		SELECT * FROM instruments WHERE upper(name) = upper(instr_name) INTO res;
	END
$$;


ALTER TABLE currencies ADD
	FOREIGN KEY (id, instr_type) 
		REFERENCES instruments (id, instr_type)
			ON UPDATE CASCADE ON DELETE CASCADE;


-------------------------------------------------------------------------------
--                         CURRENCIES OF COUNTRIES                           --
-------------------------------------------------------------------------------

CREATE TABLE countries_currencies (
	country int NOT NULL
		REFERENCES countries (id)
			ON UPDATE CASCADE ON DELETE CASCADE,
	curr bigint NOT NULL
		REFERENCES currencies (id)
			ON UPDATE CASCADE ON DELETE CASCADE,
	PRIMARY KEY (country, curr)
);
-- CREATE INDEX ON countries_currencies (country);
CREATE INDEX ON countries_currencies (curr);

CREATE FUNCTION triggers.countries_currencies_insert_only_absent() RETURNS trigger
	LANGUAGE plpgsql VOLATILE
AS $$
	BEGIN
		IF NOT EXISTS(SELECT * FROM countries_currencies WHERE (country = NEW.country) AND (curr = NEW.curr)) THEN
			RETURN NEW;
		ELSE
			RETURN NULL;
		END IF;
	END
$$;
CREATE TRIGGER insert_only_absent
	BEFORE INSERT
	ON countries_currencies
	FOR EACH ROW
	EXECUTE PROCEDURE triggers.countries_currencies_insert_only_absent()
;

CREATE RULE protect_country_currency AS
	ON UPDATE
	TO countries_currencies
	DO INSTEAD NOTHING
;

GRANT
	DELETE
	ON TABLE countries_currencies
	TO fidata
;




-------------------------------------------------------------------------------
--                             CORPORATE ACTIONS                             --
-------------------------------------------------------------------------------

CREATE TYPE corporate_action_type AS ENUM (
	'Dividend',
	'Split'
);

CREATE TABLE corporate_actions (
	id bigserial PRIMARY KEY,
	action_date date NOT NULL, -- TODO: timezone
	instrument bigint NOT NULL
		REFERENCES instruments (id)
			ON UPDATE CASCADE ON DELETE CASCADE,
	action_type corporate_action_type NOT NULL,
	dividend_amount amount_type,
	dividend_instrument bigint -- Either currency, stock or something other
		REFERENCES instruments (id)
			ON UPDATE CASCADE ON DELETE RESTRICT,
	split_dividend pieces_type,
	split_divisor pieces_type,
	CHECK (
		(action_type = 'Dividend') AND (dividend_amount > 0) AND (dividend_instrument IS NOT NULL) AND (split_dividend IS NULL) AND (split_divisor IS NULL)
		OR (action_type = 'Split') AND (dividend_amount IS NULL) AND (dividend_instrument IS NULL) AND (split_dividend > 0) AND (split_divisor > 0) AND ((split_dividend <> 1) OR (split_divisor <> 1))
	)
);
CREATE INDEX ON corporate_actions (instrument, action_date);
-- CREATE INDEX ON corporate_actions (action_type);
CREATE INDEX ON corporate_actions (dividend_instrument);




-------------------------------------------------------------------------------
--                                  MARKETS                                  --
-------------------------------------------------------------------------------

CREATE FUNCTION is_trade_organizer(market_id int) RETURNS bool
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN (SELECT trade_organizer IS NULL FROM markets WHERE id = market_id);
	END
$$;

CREATE FUNCTION get_market_trade_organizer(market_id int) RETURNS int
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN (SELECT COALESCE(trade_organizer, id) FROM markets WHERE id = market_id);
	END
$$;


CREATE TABLE markets (
	id serial PRIMARY KEY,
	symbol character(4) -- ISO 10383
		CHECK (common.is_valid_alpha_numerical_code(symbol) IS DISTINCT FROM FALSE),
	trade_organizer int
		REFERENCES markets (id)
			ON UPDATE CASCADE ON DELETE RESTRICT
		CHECK (is_trade_organizer(trade_organizer) IS DISTINCT FROM FALSE),
		
	name character varying(160) NOT NULL
		CHECK (char_length(name) > 0),
	acronym character varying(24)
		CHECK (char_length(acronym) IS DISTINCT FROM 0),
		
	country int
		REFERENCES countries (id)
			ON UPDATE CASCADE ON DELETE RESTRICT,
	city character varying(32)
		CHECK (char_length(city) IS DISTINCT FROM 0),
	website character varying(128)
		CHECK (char_length(website) IS DISTINCT FROM 0),
	CHECK ((city IS NULL) OR (country IS NOT NULL)),
	CHECK ((country IS NOT NULL) OR (website IS NOT NULL)),
	timezone common.timezone_type NOT NULL,
	
	actuality boolean NOT NULL DEFAULT TRUE,
	comments character varying(255) NOT NULL DEFAULT ''
);
CREATE UNIQUE INDEX ON markets (symbol);
-- CREATE UNIQUE INDEX ON markets (trade_organizer, upper(name));
CREATE INDEX ON markets (trade_organizer);
CREATE UNIQUE INDEX ON markets (upper(name));
CREATE /* UNIQUE */ INDEX ON markets (upper(acronym));
CREATE INDEX ON markets (country);
CREATE INDEX ON markets (upper(city));
CREATE INDEX ON markets (actuality);
SELECT setval('markets_id_seq', 16384);

CREATE FUNCTION triggers.markets_set_codes_case() RETURNS trigger
	LANGUAGE plpgsql VOLATILE
AS $$
	BEGIN
		NEW.symbol := upper(NEW.symbol);
		RETURN NEW;
	END
$$;
CREATE TRIGGER set_codes_case
	BEFORE INSERT
	ON markets
	FOR EACH ROW
	EXECUTE PROCEDURE triggers.markets_set_codes_case()
;


CREATE FUNCTION get_market(market_id int, OUT res markets)
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		SELECT * FROM markets WHERE id = market_id INTO res;
	END
$$;

CREATE FUNCTION get_market_by_symbol(market_symbol character(4), OUT res markets)
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		SELECT * FROM markets WHERE symbol = upper(market_symbol) INTO res;
	END
$$;

CREATE FUNCTION get_market_by_name(market_name character varying(160), OUT res markets)
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		SELECT * FROM markets WHERE upper(name) = upper(market_name) INTO res;
	END
$$;




/*CREATE TABLE market_instrument_types (
	market_id int NOT NULL
		REFERENCES markets (id),
	instr_type instrument_type NOT NULL,
	PRIMARY KEY (market_id, instr_type)
);
CREATE INDEX ON market_instrument_types (instr_type);*/

/*CREATE TABLE sessions (
	id serial PRIMARY KEY,
	market int NOT NULL
		REFERENCES trade_organizers (id)
			ON UPDATE CASCADE ON DELETE CASCADE,
	starttime time,
	endtime time
);
CREATE INDEX ON sessions (market);*/




-------------------------------------------------------------------------------
--                              DATA PROVIDERS                               --
-------------------------------------------------------------------------------

CREATE TABLE data_providers (
	id bigserial PRIMARY KEY,
	trade_organizer int
		REFERENCES markets (id)
			ON UPDATE CASCADE ON DELETE SET NULL
		CHECK (is_trade_organizer(trade_organizer) IS DISTINCT FROM FALSE),
	name character varying(160) NOT NULL
		CHECK (char_length(name) > 0),
	website character varying(128)
		CHECK (char_length(website) IS DISTINCT FROM 0),
	timezone common.timezone_type,
	
	actuality boolean NOT NULL DEFAULT TRUE,
	comments character varying(255) NOT NULL DEFAULT ''
);
CREATE INDEX ON data_providers (trade_organizer); -- Non-unique: trade organizer may have a number of methods of supplying data
CREATE UNIQUE INDEX ON data_providers (upper(name));
CREATE INDEX ON data_providers (actuality);
SELECT setval('data_providers_id_seq', 16384);


CREATE FUNCTION get_data_provider(data_provider_id bigint, OUT res data_providers)
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		SELECT * FROM data_providers WHERE id = data_provider_id INTO res;
	END
$$;

CREATE FUNCTION get_data_provider_by_name(data_provider_name character varying(160), OUT res data_providers)
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		SELECT * FROM data_providers WHERE upper(name) = upper(data_provider_name) INTO res;
	END
$$;




-------------------------------------------------------------------------------
--                                  TICKERS                                  --
-------------------------------------------------------------------------------

CREATE FUNCTION get_ticker_instrument(ticker_id bigint) RETURNS bigint
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN (SELECT instrument FROM tickers WHERE id = ticker_id);
	END
$$;

CREATE FUNCTION get_ticker_trade_organizer(ticker_id bigint) RETURNS int
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN (SELECT trade_organizer FROM tickers WHERE id = ticker_id);
	END
$$;

CREATE FUNCTION get_ticker_data_provider(ticker_id bigint) RETURNS bigint
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN (SELECT data_provider FROM tickers WHERE id = ticker_id);
	END
$$;


CREATE FUNCTION is_valid_ticker_symbol(code character varying(10)) RETURNS boolean
	LANGUAGE plpgsql IMMUTABLE RETURNS NULL ON NULL INPUT
AS $$
	DECLARE
		l int;
		p character(1);
	BEGIN
		RETURN code SIMILAR TO '[a-zA-Z0-9~!@#$%^*+=./-]+';
	END
$$;


CREATE TABLE tickers (
	id bigserial PRIMARY KEY,
	
	instrument bigint NOT NULL
		REFERENCES instruments (id)
			ON UPDATE CASCADE ON DELETE RESTRICT,
	trade_organizer int
		REFERENCES markets (id)
			ON UPDATE CASCADE ON DELETE RESTRICT
		CHECK (is_trade_organizer(trade_organizer)),
	data_provider bigint
		REFERENCES data_providers (id)
			ON UPDATE CASCADE ON DELETE RESTRICT,
	symbol character varying(10) NOT NULL
		CHECK (is_valid_ticker_symbol(symbol)),
	
	base_curr bigint -- NOT NULL ??
		REFERENCES currencies (id)
			ON UPDATE CASCADE ON DELETE RESTRICT,
	base_year int,
	CHECK ((base_year IS NULL) OR (base_curr IS NOT NULL))
);
-- CREATE INDEX ON tickers (instrument);
CREATE UNIQUE INDEX ON tickers (instrument, trade_organizer, data_provider, base_curr, base_year);
-- CREATE INDEX ON tickers (trade_organizer);
CREATE UNIQUE INDEX ON tickers (trade_organizer, symbol); -- TODO: uniqueness ?
-- CREATE INDEX ON tickers (data_provider);
CREATE UNIQUE INDEX ON tickers (data_provider, symbol); -- TODO: uniqueness ?
CREATE INDEX ON tickers (symbol);
SELECT setval('tickers_id_seq', 1048576);


CREATE FUNCTION get_ticker(ticker_id bigint, OUT res tickers)
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		SELECT * FROM tickers WHERE id = ticker_id INTO res;
	END
$$;

CREATE FUNCTION get_global_ticker_by_instrument(instrument_id bigint, OUT res tickers)
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		SELECT
			*
		FROM
			tickers
		WHERE
			(instrument = instrument_id)
			AND (trade_organizer IS NULL)
			AND (data_provider IS NULL)
			AND (base_curr IS NULL)
		INTO
			res;
	END
$$;

CREATE FUNCTION get_global_ticker_by_symbol(ticker_symbol character varying(10), OUT res tickers)
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		SELECT
			*
		FROM
			tickers
		WHERE
			(trade_organizer IS NULL)
			AND (data_provider IS NULL)
			AND (base_curr IS NULL)
			AND (symbol = ticker_symbol)
		INTO
			res;
	END
$$;


CREATE FUNCTION get_ticker_by_instrument(
	instrument_id bigint,
	trade_organizer_id int,
	data_provider_id bigint,
	base_curr_id bigint,
	ticker_base_year int,
	OUT res tickers
)
	LANGUAGE plpgsql STABLE
AS $$
	BEGIN
		SELECT
			*
		FROM
			tickers
		WHERE
			(instrument = instrument_id)
			AND (trade_organizer IS NOT DISTINCT FROM trade_organizer_id)
			AND (data_provider IS NOT DISTINCT FROM data_provider_id)
			AND (base_curr IS NOT DISTINCT FROM base_curr_id)
			AND (base_year IS NOT DISTINCT FROM ticker_base_year)
		INTO
			res;
	END
$$;


CREATE FUNCTION get_ticker_by_trade_organizer_symbol(
	trade_organizer_id int,
	ticker_symbol character varying(10),
	OUT res tickers
)
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		SELECT
			*
		FROM
			tickers
		WHERE
			(trade_organizer = trade_organizer_id)
			AND (symbol = ticker_symbol)
		INTO
			res;
	END
$$;

CREATE FUNCTION get_ticker_by_data_provider_symbol(
	data_provider_id bigint,
	ticker_symbol character varying(10),
	OUT res tickers
)
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		SELECT
			*
		FROM
			tickers
		WHERE
			(data_provider = data_provider_id)
			AND (symbol = ticker_symbol)
		INTO
			res;
	END
$$;


CREATE FUNCTION triggers.tickers_set_curr_pair_symbol() RETURNS trigger
	LANGUAGE plpgsql VOLATILE
AS $$
	DECLARE
		ticker1 tickers%ROWTYPE;
		ticker2 tickers%ROWTYPE;
	BEGIN
		IF
			(NEW.symbol IS NULL)
			AND (is_currency(NEW.instrument))
			AND (NEW.base_curr IS NOT NULL)
		THEN
			ticker1 := get_global_ticker_by_instrument(NEW.instrument);
			ticker2 := get_global_ticker_by_instrument(NEW.base_curr);
			NEW.symbol := ticker1.symbol||'/'||ticker2.symbol;
		END IF;
		RETURN NEW;
	END
$$;
CREATE TRIGGER set_curr_pair_symbol
	BEFORE INSERT
	ON tickers
	FOR EACH ROW
	EXECUTE PROCEDURE triggers.tickers_set_curr_pair_symbol()
;

-------------------------------------------------------------------------------




CREATE TYPE deal_direction AS ENUM (
	'Buy',
	'Sell'
);

CREATE TYPE order_action AS ENUM (
	'Addition',
	'Execution',
	'Deletion' -- Cancellation ?
);

-- TODO: types of orders
