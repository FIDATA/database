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


CREATE FUNCTION get_max_data_moment(ds_id bigint, OUT res time_moment)
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		IF get_ds_ts_type(ds_id) = 'Interval' THEN
			EXECUTE 'SELECT MAX("close(moment)") FROM '||get_ds_table_name(ds_id) INTO res;
		ELSE
			EXECUTE 'SELECT MAX(moment) FROM '||get_ds_table_name(ds_id) INTO res;
		END IF;
	EXCEPTION
		WHEN undefined_table THEN
			res := NULL;
	END
$$;


/* CREATE FUNCTION list_data_sets() -- ToDo: View
	RETURNS TABLE(
		id bigint,
		ticker bigint,
		data_provider bigint,
		market int,
		ts_type time_series_type,
		src_ds bigint,
		timeframe character varying(3),
		lag int,
		basetime time_moment,
		data_count bigint,
		open_moment  time_moment,
		close_moment time_moment,
		volume decimal,
		avg_volume decimal
	)
	LANGUAGE plpgsql STABLE
AS $$
 	DECLARE
		i RECORD;
		t name;
	BEGIN
		FOR i IN
			SELECT
				*
			FROM
				data_sets
		LOOP
			t := get_ds_table_name(i.id);
			BEGIN
				CASE i.ts_type
					WHEN 'Order', 'Deal', 'Moment' THEN
						RETURN QUERY EXECUTE 'SELECT $1, $2, $3, $4, $5, $6, $7, $8, $9, COUNT(id), MIN(moment), MAX(moment), SUM(volume::decimal), CASE WHEN COUNT(id) IS NULL THEN NULL::decimal ELSE SUM(volume::decimal) / COUNT(id) END FROM '||t USING i.id, i.ticker, i.data_provider, i.market, i.ts_type, i.src_ds, i.timeframe, i.lag, i.basetime;
					WHEN 'OpenHighLowClose' THEN
						RETURN QUERY EXECUTE 'SELECT $1, $2, $3, $4, $5, $6, $7, $8, $9, COUNT(id), MIN(open_moment), MAX(close_moment), NULL::decimal, CASE WHEN COUNT(id) IS NULL THEN NULL::decimal ELSE SUM(volume::decimal) / COUNT(id) END FROM '||t USING  i.id, i.ticker, i.data_provider, i.market, i.ts_type, i.src_ds, i.timeframe, i.lag, i.basetime;
					ELSE
						RETURN QUERY EXECUTE 'SELECT $1, $2, $3, $4, $5, $6, $7, $8, $9, COUNT(id), MIN(open_moment), MAX(close_moment), NULL::decimal, NULL::decimal FROM '||t USING  i.id, i.ticker, i.data_provider, i.market, i.ts_type, i.src_ds, i.timeframe, i.lag, i.basetime;
				END CASE;
			EXCEPTION
				WHEN undefined_table THEN
					NULL;
			END;
		END LOOP;
		RETURN;
	END
$$;*/
