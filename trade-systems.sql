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


CREATE TABLE trade_systems (
	id bigserial PRIMARY KEY,
	name character varying(64) NOT NULL
		CHECK (char_length(name) > 0),
	-- timeframe interval(YEAR TO DAY),
	description text NOT NULL DEFAULT ''
);
CREATE UNIQUE INDEX ON trade_systems (upper(name));

GRANT
	DELETE, TRUNCATE
	ON TABLE trade_systems
	TO fidata
;

CREATE FUNCTION get_trade_system(trade_system_id bigint, OUT res trade_systems)
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		SELECT * FROM trade_systems WHERE id = trade_system_id INTO res;
	END
$$;

CREATE FUNCTION get_trade_system_by_name(trade_system_name character varying(64), OUT res trade_systems)
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		SELECT * FROM trade_systems WHERE upper(name) = upper(trade_system_name) INTO res;
	END
$$;


CREATE TABLE trade_system_params (
	trade_system bigint NOT NULL
		REFERENCES trade_systems (id)
			ON UPDATE CASCADE ON DELETE CASCADE,
	param_index smallint NOT NULL
		CHECK (param_index > 0),
	PRIMARY KEY (trade_system, param_index),
	
	param_name common.name_type NOT NULL
		CHECK (char_length(param_name) > 0),
	param_type common.name_type NOT NULL
		REFERENCES types (name)
			ON UPDATE CASCADE ON DELETE RESTRICT
);
-- CREATE INDEX ON trade_system_params (trade_system);
CREATE UNIQUE INDEX ON trade_system_params (trade_system, param_name);
CREATE INDEX ON trade_system_params (param_type);


CREATE TABLE trade_system_auxiliary_data_sets (
	trade_system bigint NOT NULL
		REFERENCES trade_systems (id)
			ON UPDATE CASCADE ON DELETE CASCADE,
	data_set_index smallint NOT NULL
		CHECK (data_set_index > 0),
	PRIMARY KEY (trade_system, data_set_index),
	
	data_set bigint NOT NULL
		REFERENCES data_sets
			ON UPDATE CASCADE ON DELETE RESTRICT
);
-- CREATE INDEX ON trade_system_auxiliary_data_sets (trade_system);
CREATE UNIQUE INDEX ON trade_system_auxiliary_data_sets (trade_system, data_set);
CREATE INDEX ON trade_system_auxiliary_data_sets (data_set);


/*
Input:
1. Trading instrument
2. Data sets
3. Event handlers:
3.1. New data + order executed
3.2. Order
3.3. Time
4. Start capital
5. 
*/

/*
Output:
1. Aggregated data:
Total profit/loss
Revenue
Share of profitable deals


2. Detailed data:
2.1. Deals
2.2. Profit/loss realized
2.3. Profit/loss potential
2.4.
*/

CREATE FUNCTION procs.test_trade_system(trade_system_id bigint) RETURNS VOID
	LANGUAGE plpgsql VOLATILE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		NULL;
	END
$$;
