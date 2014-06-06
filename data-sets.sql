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




/* TODOS
2013-06-15:
1. fields
2. table for params of stat procedures
3. review aggregating procedures

4. move rights and tests into separate file ?
*/

-------------------------------------------------------------------------------
--                                   TYPES                                   --
-------------------------------------------------------------------------------

-- Scales of measure
CREATE TYPE scale_type AS ENUM (
--   Name          Valid comparisons  Arbitrary values  Valid binary operators                                                                                                    Permissive statistics

	'Nominal',  --  ==, !=                                <none>                                                                                                                   Mode
	'Ordinal',  --  ==, !=, >, <                          <none>                                                                                                                   Quantile, Mode
	'Interval', --  ==, !=, >, <                          diff = x2 - x1, x2 = x1 + diff (diff has Ratio scale)                                                                    Arithmetic Mean, Quantile, Mode
	'Time',     --  Special case of Interval scale. Time is always incremental in time series, so applying of max() and min() functions makes no sense
	'Ratio',    --  ==, !=, >, <       0, taken 1         diff = x2 - x1, x2 = x1 + diff (diff has the same scale); ratio` = x2 / x1, x2 = ratio * x1 (ratio has Absolute scale)   Geometic Mean, Arithmetic Mean, Quantile, Mode
	'Absolute'  --  ==, !=, >, <       0, universal 1     diff = x2 - x1, x2 = x1 + diff (diff has the same scale); ratio` = x2 / x1, x2 = ratio * x1 (ratio has Absolute scale)   Geometic Mean, Arithmetic Mean, Quantile, Mode

-- Other known scales (e.g. Binary, LogInterval) currently aren't used and so not supported
);


CREATE FUNCTION get_type_scale(type_name common.name_type) RETURNS scale_type
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN (SELECT scale FROM types WHERE name = type_name);
	END
$$;

CREATE FUNCTION get_type_dbms_type(type_name common.name_type) RETURNS regtype
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN (SELECT dbms_type FROM types WHERE name = type_name);
	END
$$;

CREATE FUNCTION get_type_diff_type(type_name common.name_type) RETURNS common.name_type
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN (SELECT diff_type FROM types WHERE name = type_name);
	END
$$;

CREATE FUNCTION get_type_foreign_table(type_name common.name_type) RETURNS regclass
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN (SELECT foreign_table FROM types WHERE name = type_name);
	END
$$;

CREATE FUNCTION get_type_foreign_column(type_name common.name_type) RETURNS name
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN (SELECT foreign_column FROM types WHERE name = type_name);
	END
$$;


CREATE FUNCTION get_foreign_table_column_dbms_type(foreign_table regclass, foreign_column name) RETURNS regtype
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN (
			SELECT
				atttypid
			FROM
				pg_attribute
			WHERE
				(attrelid = foreign_table)
				AND (attname = foreign_column)
		);
	END
$$;


CREATE TABLE types (
	name common.name_type PRIMARY KEY
		CHECK (char_length(name) > 0),
	scale scale_type NOT NULL,
-- WARNING: regtype doesn't store type modifiers, so for dbms_type domains should be used!
-- TODO: add type modifiers and use format_type
	dbms_type regtype NOT NULL,
	diff_type common.name_type
		REFERENCES types (name)
			ON UPDATE CASCADE ON DELETE CASCADE,
	CHECK (
		(scale IN ('Nominal', 'Ordinal')) AND (diff_type IS NULL)
		OR (scale NOT IN ('Nominal', 'Ordinal')) AND ((diff_type IS NULL) OR (get_type_scale(diff_type) IN ('Ratio', 'Absolute')))
	),
	foreign_table regclass,
	foreign_column name,
	CHECK (
		(foreign_table IS NULL) AND (foreign_column IS NULL)
		OR (get_foreign_table_column_dbms_type(foreign_table, foreign_column) = dbms_type)
	)
);
CREATE INDEX ON types (scale);
CREATE INDEX ON types (diff_type);

CREATE FUNCTION triggers.types_set_diff_type() RETURNS trigger
	LANGUAGE plpgsql VOLATILE
AS $$
	BEGIN
		IF NEW.scale IN ('Ratio', 'Absolute') THEN
			NEW.diff_type = NEW.name;
		END IF;
		RETURN NEW;
	END
$$;
CREATE TRIGGER set_diff_type
	BEFORE INSERT
	ON types
	FOR EACH ROW
	EXECUTE PROCEDURE triggers.types_set_diff_type()
;

CREATE FUNCTION triggers.types_grant_references_privilegy() RETURNS trigger
	LANGUAGE plpgsql VOLATILE
AS $$
	BEGIN
		IF (NEW.foreign_table IS NOT NULL) AND (NEW.foreign_column IS NOT NULL) THEN
			EXECUTE '
				GRANT
					REFERENCES ('||NEW.foreign_column||')
					ON TABLE '||NEW.foreign_table||'
					TO fidata;
			';
		END IF;
		RETURN NEW;
	END
$$;
CREATE TRIGGER grant_references_privilegy
	AFTER INSERT
	ON types
	FOR EACH ROW
	EXECUTE PROCEDURE triggers.types_grant_references_privilegy()
;

CREATE RULE protect_from_update AS
	ON UPDATE
	TO types
	DO INSTEAD NOTHING
;

REVOKE
	INSERT, UPDATE
	ON TABLE types
	FROM fidata
	CASCADE
;




-------------------------------------------------------------------------------
--                                   TIMEFRAMES                              --
-------------------------------------------------------------------------------

CREATE DOMAIN time_moment timestamptz(6);
CREATE DOMAIN time_interval interval(6);

CREATE TYPE time_series_type AS ENUM (
	'Object',   -- Special case of Moment time series, which contains
	            -- attached to time moments objects of particular type
	'Moment',
	'Interval'
);

CREATE FUNCTION get_timeframe_dbms_interval(timeframe character varying(3)) RETURNS interval(0)
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN (SELECT dbms_interval FROM timeframes WHERE id = timeframe);
	END
$$;

CREATE TABLE timeframes (
	id character varying(3) PRIMARY KEY,
	dbms_interval interval(0) NOT NULL,
	timefield character varying(6) NOT NULL
		CHECK (timefield IN ('second', 'minute', 'hour', 'day', 'month', 'year')),
	quantity smallint NOT NULL
		CHECK (quantity > 0)
);
CREATE UNIQUE INDEX ON timeframes (dbms_interval);
CREATE UNIQUE INDEX ON timeframes (timefield, quantity);

CREATE FUNCTION triggers.timeframes_set_dbms_interval() RETURNS trigger
	LANGUAGE plpgsql VOLATILE
AS $$
	BEGIN
		NEW.dbms_interval = (NEW.quantity::text||' '||NEW.timefield)::interval;
		RETURN NEW;
	END
$$;
CREATE TRIGGER set_dbms_interval
	BEFORE INSERT OR UPDATE
	ON timeframes
	FOR EACH ROW
	EXECUTE PROCEDURE triggers.timeframes_set_dbms_interval()
;

REVOKE
	INSERT, UPDATE
	ON TABLE timeframes
	FROM fidata
	CASCADE
;




-------------------------------------------------------------------------------
--                                  FIELDS                                   --
-------------------------------------------------------------------------------

-- In Moment (and Object) time series all fields are Stocks
-- In Interval time series fields may be either Stocks or Flows
CREATE TYPE field_class AS ENUM (
	'Time',   -- Special case of Stocks field type
	'Stocks', -- E.g. Price, Open, Max -- Also called 'Levels'
	'Flows'   -- E.g. Sum, Count       -- Also called 'Aggregated'
);


CREATE FUNCTION get_field_type(field_name common.name_type) RETURNS common.name_type
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN (SELECT data_type FROM fields WHERE name = field_name);
	END
$$;

CREATE FUNCTION get_field_ts_type(field_name common.name_type) RETURNS time_series_type
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN (SELECT ts_type FROM fields WHERE name = field_name);
	END
$$;

CREATE FUNCTION get_field_class(field_name common.name_type) RETURNS field_class
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN (SELECT field_class FROM fields WHERE name = field_name);
	END
$$;

CREATE TABLE fields (
	name common.name_type PRIMARY KEY
		CHECK (char_length(name) > 0)
		-- Names of predefined columns may not be used
		CHECK (name NOT IN ('ds', 'id')),
	
	data_type common.name_type
		REFERENCES types (name)
			ON UPDATE CASCADE ON DELETE RESTRICT,
	ts_type time_series_type NOT NULL,
	-- In Interval time series data type may depend on data type of base (being aggregated) field
	CHECK ((ts_type = 'Interval') OR (data_type IS NOT NULL)),
	
	field_class field_class
);
CREATE INDEX ON fields (data_type);
CREATE INDEX ON fields (ts_type);
CREATE INDEX ON fields (field_class);

CREATE RULE protect_from_update AS
	ON UPDATE
	TO fields
	DO INSTEAD NOTHING
;

REVOKE
	INSERT, UPDATE
	ON TABLE fields
	FROM fidata
	CASCADE
;




-------------------------------------------------------------------------------
--                                  OBJECT TYPES                             --
-------------------------------------------------------------------------------

CREATE TABLE object_types (
	name common.name_type PRIMARY KEY
	-- description, comment ?
);

REVOKE
	INSERT, UPDATE
	ON TABLE object_types
	FROM fidata
	CASCADE
;


CREATE FUNCTION object_type_has_field(object_type_name common.name_type, field_name common.name_type) RETURNS bool
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN EXISTS(
			SELECT
				*
			FROM
				object_fields
			WHERE
				(object_type = object_type_name)
				AND (field = field_name)
		);
	END
$$;

CREATE TABLE object_fields (
	id serial PRIMARY KEY,
	object_type common.name_type NOT NULL
		REFERENCES object_types (name)
			ON UPDATE CASCADE ON DELETE RESTRICT,
	field common.name_type NOT NULL
		REFERENCES fields (name)
			ON UPDATE CASCADE ON DELETE RESTRICT
		CHECK (get_field_ts_type(field) IN ('Object', 'Moment'))
);
-- CREATE INDEX ON object_fields (object_type);
CREATE UNIQUE INDEX ON object_fields (object_type, field);
CREATE INDEX ON object_fields (field);

CREATE FUNCTION triggers.object_types_insert_moment_fields() RETURNS trigger
	LANGUAGE plpgsql VOLATILE
AS $$
	BEGIN
		INSERT INTO object_fields (object_type, field) VALUES
			(NEW.name, 'moment')
		;
		RETURN NULL;
	END
$$;
CREATE TRIGGER insert_moment_fields
	AFTER INSERT
	ON object_types
	FOR EACH ROW
	EXECUTE PROCEDURE triggers.object_types_insert_moment_fields()
;

CREATE RULE protect_from_update AS
	ON UPDATE
	TO object_fields
	DO INSTEAD NOTHING
;

CREATE FUNCTION triggers.object_fields_protect_moment_fields_from_delete() RETURNS trigger
	LANGUAGE plpgsql VOLATILE
AS $$
	BEGIN
		IF OLD.field = 'moment'	THEN
			RETURN NULL;
		ELSE
			RETURN OLD;
		END IF;
	END
$$;
CREATE TRIGGER protect_moment_fields_from_delete
	BEFORE DELETE
	ON object_fields
	FOR EACH ROW
	EXECUTE PROCEDURE triggers.object_fields_protect_moment_fields_from_delete()
;

REVOKE
	INSERT, UPDATE
	ON TABLE object_fields
	FROM fidata
	CASCADE
;




-------------------------------------------------------------------------------
--                                    DATA SETS                              --
-------------------------------------------------------------------------------

CREATE FUNCTION get_ds_ts_type(ds bigint) RETURNS time_series_type
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN (SELECT ts_type FROM data_sets WHERE id = ds);
	END
$$;

CREATE FUNCTION get_ds_object_type(ds bigint) RETURNS common.name_type
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN (SELECT object_type FROM data_sets WHERE id = ds);
	END
$$;

/*CREATE FUNCTION get_ds_src_ds(ds bigint) RETURNS bigint
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN (SELECT src_ds FROM data_sets WHERE id = ds);
	END
$$;*/

CREATE FUNCTION get_ds_timeframe(ds bigint) RETURNS character varying(3)
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN (SELECT timeframe FROM data_sets WHERE id = ds);
	END
$$;

CREATE FUNCTION get_ds_dbms_interval(ds bigint) RETURNS interval(0)
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN get_timeframe_dbms_interval(get_ds_timeframe(ds));
	END
$$;


CREATE TABLE data_sets (
	id bigserial PRIMARY KEY, -- id 0 is reserved for test purposes
	
	ticker bigint
		REFERENCES tickers (id)
			ON UPDATE CASCADE ON DELETE RESTRICT,
	data_provider bigint
		REFERENCES data_providers (id)
			ON UPDATE CASCADE ON DELETE RESTRICT,
	market int
		REFERENCES markets (id)
			ON UPDATE CASCADE ON DELETE RESTRICT,
	CHECK ((get_ticker_trade_organizer(ticker) IS NULL) OR (get_market_trade_organizer(market) IS NULL) OR (get_ticker_trade_organizer(ticker) = get_market_trade_organizer(market))),
	CHECK ((data_provider IS NULL) OR (get_ticker_data_provider(ticker) IS NULL) OR (get_ticker_data_provider(ticker) = data_provider)),
	
	ts_type time_series_type NOT NULL,
	object_type common.name_type
		REFERENCES object_types (name)
			ON UPDATE CASCADE ON DELETE RESTRICT,
	CHECK ((ts_type = 'Object') ~| (object_type IS NULL)),
	
	CHECK (
		((ts_type = 'Object') AND object_type_has_field(object_type, 'ticker') AND (market IS NOT NULL) AND (ticker IS NULL))
		~| (((ts_type <> 'Object') OR (object_type_has_field(object_type, 'ticker') IS DISTINCT FROM FALSE)) AND (ticker IS NOT NULL))
	),
	
-- 	src_ds bigint
-- 		REFERENCES data_sets (id)
-- 			ON UPDATE CASCADE ON DELETE RESTRICT,
-- 	src_ds_time time_moment,
-- 	CHECK ((src_ds IS NOT NULL) ~| (src_ds_time IS NULL)),
-- 	CHECK ((src_ds IS NULL) ~| (data_provider IS NULL)),
	
	timeframe character varying(3)
		REFERENCES timeframes (id)
			ON UPDATE CASCADE ON DELETE RESTRICT,
	CHECK ((ts_type = 'Interval') OR (timeframe IS NULL))
--	lag int CHECK ((lag IS NULL) OR (lag > 0)),
	-- Separate table for parameters used by statistical procedures (method of lagging etc.)
--	basetime time_moment, -- ToDo: Maybe there should be id (especially for moment data sets)
/* 	CHECK (
		(ts_type = 'Interval') AND ((lag IS NULL) ~| (basetime IS NULL))
		OR (ts_type <> 'Interval') AND (lag IS NULL) AND (basetime IS NULL)
	) */
--	update_date timestamptz(0) NOT NULL DEFAULT CURRENT_TIMESTAMP -- In UTC!
--	timezone common.timezone_type
);
-- CREATE INDEX ON data_sets (ticker);
CREATE INDEX ON data_sets (ticker, data_provider, market);
CREATE INDEX ON data_sets (data_provider, market);
CREATE INDEX ON data_sets (market);
CREATE INDEX ON data_sets (ts_type);
CREATE INDEX ON data_sets (object_type);
-- CREATE INDEX ON data_sets (src_ds);
CREATE INDEX ON data_sets (timeframe);
-- CREATE INDEX ON data_sets (lag);
-- CREATE INDEX ON data_sets (basetime);

-- CREATE FUNCTION check_src_ds(ds_id bigint, src_ds_id bigint) RETURNS boolean /* TODO */
-- 	LANGUAGE plpgsql STABLE
-- AS $$
-- 	BEGIN
-- 		RETURN (
-- 			(ds_id IS NOT NULL) AND (src_ds_id IS NULL)
-- 			OR (ds_id NOT IN (
-- 				WITH RECURSIVE sources(ds) AS (
-- 					SELECT src_ds_id AS ds
-- 					UNION
-- 					SELECT data_sets.src_ds FROM data_sets INNER JOIN sources ON sources.ds = data_sets.id
-- 				) SELECT * FROM sources
-- 			))
-- 		);
-- 	END
-- $$;
-- ALTER TABLE data_sets
-- 	ADD CHECK (check_src_ds(id, src_ds))
-- ;

CREATE FUNCTION triggers.data_sets_protect_from_update() RETURNS trigger
	LANGUAGE plpgsql VOLATILE
AS $$
	BEGIN
--		NEW.src_ds = OLD.src_ds;
		NEW.ts_type = OLD.ts_type;
		NEW.timeframe = OLD.timeframe;
/* 		NEW.lag = OLD.lag;
		NEW.basetime = OLD.basetime;
 */		RETURN NEW;
	END
$$;
CREATE TRIGGER protect_from_update
	BEFORE UPDATE
	ON data_sets
	FOR EACH ROW
	EXECUTE PROCEDURE triggers.data_sets_protect_from_update()
;

CREATE FUNCTION triggers.data_sets_update_dst_ds() RETURNS trigger
	LANGUAGE plpgsql VOLATILE
AS $$
	BEGIN
		IF
			(NEW.ticker <> OLD.ticker)
			OR (NEW.market IS DISTINCT FROM OLD.market)
		THEN
			UPDATE data_sets SET (ticker, market) = (NEW.ticker, NEW.market) WHERE src_ds = NEW.id;
		END IF;
		RETURN NULL;
	END
$$;
CREATE TRIGGER update_dst_ds
	AFTER UPDATE
	ON data_sets
	FOR EACH ROW
	EXECUTE PROCEDURE triggers.data_sets_update_dst_ds()
;


DO LANGUAGE plpgsql $$
	BEGIN
		CREATE SCHEMA ds;
	EXCEPTION
		WHEN duplicate_schema THEN
			NULL;
	END;
$$;

ALTER SCHEMA ds
	OWNER TO fidata;

GRANT
	ALL PRIVILEGES
	ON SCHEMA ds
	TO fidata_admin;

ALTER DEFAULT PRIVILEGES IN SCHEMA ds GRANT
	ALL PRIVILEGES
	ON TABLES
	TO fidata_admin;

ALTER DEFAULT PRIVILEGES IN SCHEMA ds GRANT
	ALL PRIVILEGES
	ON SEQUENCES
	TO fidata_admin;


CREATE FUNCTION get_ds_table_name(ds bigint) RETURNS name
	LANGUAGE plpgsql IMMUTABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN 'ds.ds'||ds;
	END
$$;


CREATE FUNCTION triggers.data_sets_update_table_name() RETURNS trigger
	LANGUAGE plpgsql VOLATILE
AS $$
	BEGIN
		IF NEW.id <> OLD.id THEN
			EXECUTE 'ALTER TABLE IF EXISTS '||get_ds_table_name(OLD.id)||' RENAME TO '||get_ds_table_name(NEW.id);
		END IF;
		RETURN NULL;
	END
$$;
CREATE TRIGGER update_table_name
	AFTER UPDATE
	ON data_sets
	FOR EACH ROW
	EXECUTE PROCEDURE triggers.data_sets_update_table_name()
;

CREATE FUNCTION triggers.data_sets_drop_table() RETURNS trigger
	LANGUAGE plpgsql VOLATILE
AS $$
	BEGIN
		EXECUTE 'DROP TABLE IF EXISTS '||get_ds_table_name(OLD.id)||' CASCADE;';
		RETURN NULL;
	END
$$;
CREATE TRIGGER drop_table
	AFTER DELETE
	ON data_sets
	FOR EACH ROW
	EXECUTE PROCEDURE triggers.data_sets_drop_table()
;


CREATE FUNCTION get_data_set(ds_id bigint, OUT res data_sets)
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		SELECT * FROM data_sets WHERE id = ds_id INTO res;
	END
$$;




-- CREATE TABLE source_data_sets (
-- 	id bigserial PRIMARY KEY,
-- 	ds bigint NOT NULL
-- 		REFERENCES data_sets (id)
-- 			ON UPDATE CASCADE ON DELETE CASCADE,
-- 	src_ds bigint NOT NULL
-- 		REFERENCES data_sets (id)
-- 			ON UPDATE CASCADE ON DELETE RESTRICT,
-- 	start_moment time_moment,
-- 	end_moment time_moment,
-- --	source_fields
-- 	CHECK (ds NOT IN (
-- 		WITH RECURSIVE sources(id) AS (
-- 			SELECT
-- 				source_data_sets.src_ds
-- 			FROM
-- 				source_data_sets
-- 			UNION
-- 			SELECT
-- 				source_data_sets.src_ds
-- 			FROM
-- 				source_data_sets, sources
-- 			WHERE
-- 				source_data_sets.ds = sources.id
-- 		) SELECT sources(src_ds)
-- 	))
-- );
-- CREATE UNIQUE INDEX ON source_data_sets (ds, src_ds),
-- CREATE INDEX ON source_data_sets (src_ds),




/* CREATE FUNCTION create_dst_ds(src_ds_id bigint, dst_ts_type time_series_type, dst_object_type common.name_type, dst_timeframe interval(0), dst_lag int, dst_basetime time_moment) RETURNS bigint
	LANGUAGE plpgsql VOLATILE
AS $$
	DECLARE
		src_ticker data_sets.ticker%TYPE;
		src_market data_sets.market%TYPE;
		dst_ds_id bigint;
	BEGIN
		SELECT ticker, market FROM data_sets WHERE id = src_ds_id INTO STRICT src_ticker, src_market;
		INSERT INTO data_sets(data_provider, ticker, market, ts_type, object_type, src_ds, timeframe, lag, basetime) VALUES
			(NULL, src_ticker, src_market, dst_ts_type, dst_object_type, src_ds_id, dst_timeframe, dst_lag, dst_basetime)
			RETURNING id INTO STRICT dst_ds_id
		;
		RETURN dst_ds_id;
	END
$$;
 */



CREATE FUNCTION find_data_sets(ticker_id bigint, data_provider_id bigint, market_id int, ts_type time_series_type, object_type common.name_type, timeframe character varying(3)) RETURNS SETOF data_sets
	LANGUAGE plpgsql STABLE
AS $$
	BEGIN
		RETURN QUERY (
			SELECT
				*
			FROM
				data_sets
			WHERE
				(ticker IS NOT DISTINCT FROM ticker_id)
				AND (data_provider IS NOT DISTINCT FROM data_provider_id)
				AND (market IS NOT DISTINCT FROM market_id)
				AND (data_sets.ts_type IS NOT DISTINCT FROM ts_type)
				AND (object_type IS NOT DISTINCT FROM object_type)
				AND (data_sets.timeframe IS NOT DISTINCT FROM timeframe)
		);
	END
$$;




CREATE TABLE ds.d (
	ds bigint NOT NULL
		REFERENCES data_sets (id)
			ON UPDATE CASCADE ON DELETE CASCADE
);
-- CREATE INDEX ON ds.d (ds);
ALTER TABLE ds.d
	OWNER TO fidata;
  
CREATE TABLE ds.dm (
	"moment" time_moment NOT NULL
) INHERITS (ds.d);
CREATE INDEX ON ds.dm (ds, "moment");
CREATE INDEX ON ds.dm ("moment");
ALTER TABLE ds.dm
	OWNER TO fidata;
  
CREATE TABLE ds.di (
	"open(moment)" time_moment NOT NULL,
	"close(moment)" time_moment NOT NULL,
	CHECK ("close(moment)" > "open(moment)")
) INHERITS (ds.d);
CREATE INDEX ON ds.di (ds, "open(moment)");
CREATE INDEX ON ds.di ("open(moment)");
CREATE INDEX ON ds.di (ds, "close(moment)");
CREATE INDEX ON ds.di ("close(moment)");
ALTER TABLE ds.di
	OWNER TO fidata;

CREATE FUNCTION triggers.interval_ds_check_moments() RETURNS trigger
	LANGUAGE plpgsql VOLATILE
AS $$
	BEGIN
		IF NEW."open(moment)" IS NULL THEN
			NEW."open(moment)" = NEW."close(moment)" - get_ds_dbms_interval(NEW.ds);
		ELSIF NEW."close(moment)" IS NULL THEN
			NEW."close(moment)" = NEW."open(moment)" + get_ds_dbms_interval(NEW.ds);
		END IF;
		RETURN NEW;
	END
$$;

-------------------------------------------------------------------------------

/* InWork:
CREATE FUNCTION day_table(_symbol symbol_type, _rule rule_type, _provider provider_type, _year int)
	RETURNS TABLE(
		weeknumber smallint,
		-- ToDo
		dow1 boolean,
		dow2 boolean,
		dow3 boolean,
		dow4 boolean,
		dow5 boolean,
		dow6 boolean,
		dow7 boolean
	)
	LANGUAGE plpgsql STABLE
AS $$
	BEGIN
		_start := timestamp( AT TIME ZONE 
		SELECT * FROM generate_series(_start,
			_end, '1 day');
	
	END
$$;*/

-- ToDo:
-- Point and figure
-- Kagi
-- Renco


/* 1. Point data:
Date/Time
Price
Volume
Open Interest
Open Positions
ts_type
2. Interval data:
Date/Time
Open
High
Low
Close
Volume
OpenInt

3. Macro Data:
???
Data?
Predicted
Revision*/
