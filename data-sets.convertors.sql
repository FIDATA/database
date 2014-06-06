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
--                           DATA SET CONVERTORS                             --
-------------------------------------------------------------------------------

CREATE FUNCTION procs.build_deals_ds(src_ds_id bigint) RETURNS bigint
	LANGUAGE plpgsql VOLATILE RETURNS NULL ON NULL INPUT
AS $$
	DECLARE
		dst_ds_id bigint;
		src_t name;
	BEGIN
		IF get_ds_object_type(src_ds_id) IS DISTINCT FROM 'Order' THEN
			RAISE EXCEPTION 'Object type of source data set is not Order';
		END IF;
		
		src_t := get_ds_table_name(src_ds_id);
		
		dst_ds_id := create_dst_ds(src_ds_id, 'Object', 'Deal', NULL, NULL, NULL);
		PERFORM create_ds_table(dst_ds_id);
		
		EXECUTE
			get_data_insert_query(dst_ds_id)||'
			SELECT
				dst_ds_id,
				avg(moment),
				deal_id,
				(SELECT deal_direction FROM '||src_t||' WHERE deal_id = src_t.deal_id ORDER BY moment DESC, id DESC LIMIT 1) AS deal_direction,
				avg(deal_price),
				avg(volume)
			FROM
				'||src_t||' AS src_t
			WHERE
				(order_action = ''Execution'')
				OR deal_id IS NOT NULL
			GROUP BY
				deal_id
			ORDER BY
				avg(moment),
				min(id)
			;
		';
		RETURN dst_ds_id;
	END
$$;

CREATE FUNCTION procs.build_moment_bid_ds(src_ds_id bigint) RETURNS bigint
	LANGUAGE plpgsql VOLATILE RETURNS NULL ON NULL INPUT
AS $$
	DECLARE
		dst_ds_id bigint;
		src_t name;
	BEGIN
		IF get_ds_object_type(src_ds_id) IS DISTINCT FROM 'Order' THEN
			RAISE EXCEPTION 'Object type of source data set is not Order';
		END IF;
		
		src_t := get_ds_table_name(src_ds_id);
		
		dst_ds_id := create_dst_ds(src_ds_id, 'Moment', NULL, NULL, NULL, NULL);
		INSERT INTO data_set_fields(ds, field, base_field, src_field) VALUES
			(dst_ds_id, 'bid_price', NULL, NULL),
			(dst_ds_id, 'volume', NULL, NULL),
			(dst_ds_id, 'sum', NULL, NULL)
		;
		PERFORM create_ds_table(dst_ds_id);
		
		EXECUTE
			get_data_insert_query(dst_ds_id)||'
			SELECT
				dst_ds_id,
				moment,
				deal_price,
				volume,
				deal_price * volume AS sum
			FROM
				'||src_t||'
			WHERE
				(order_action = ''Execution'')
				AND (deal_direction = ''Sell'')
			ORDER BY
				moment,
				id
			;
		';
		RETURN dst_ds_id;
	END
$$;

CREATE FUNCTION procs.build_moment_ask_ds(src_ds_id bigint) RETURNS bigint
	LANGUAGE plpgsql VOLATILE RETURNS NULL ON NULL INPUT
AS $$
	DECLARE
		dst_ds_id bigint;
		src_t name;
	BEGIN
		IF get_ds_object_type(src_ds_id) IS DISTINCT FROM 'Order' THEN
			RAISE EXCEPTION 'Object type of source data set is not Order';
		END IF;
		
		src_t := get_ds_table_name(src_ds_id);
		
		dst_ds_id := create_dst_ds(src_ds_id, 'Moment', NULL, NULL, NULL, NULL);
		INSERT INTO data_set_fields(ds, field, base_field, src_field) VALUES
			(dst_ds_id, 'ask_price', NULL, NULL),
			(dst_ds_id, 'volume', NULL, NULL),
			(dst_ds_id, 'sum', NULL, NULL)
		;
		PERFORM create_ds_table(dst_ds_id);
		
		EXECUTE
			get_data_insert_query(dst_ds_id)||'
			SELECT
				dst_ds_id,
				moment,
				deal_price,
				volume,
				deal_price * volume AS sum
			FROM
				'||src_t||'
			WHERE
				(order_action = ''Execution'')
				AND (deal_direction = ''Buy'')
			ORDER BY
				moment,
				id
			;
		';
		RETURN dst_ds_id;
	END
$$;

CREATE FUNCTION procs.build_interval_ds(src_ds_id bigint, open_moment time_moment, timeframe character varying(3)) RETURNS bigint
	LANGUAGE plpgsql VOLATILE
AS $$
	DECLARE
		close_moment time_moment;
		dst_ds_id bigint;
		src_t name;
		insert_fields_query text[] = ARRAY[];
		src_column_names text[] = ARRAY['dst_ds_id', 'open_moment', 'close_moment'];
		insert_query text;
		i RECORD;
	BEGIN
		IF get_ds_ts_type(src_ds_id) IS DISTINCT FROM 'Moment' /*ANY ('Moment', 'Interval')*/ THEN
			RAISE EXCEPTION 'Type of time series of source data set is not Moment';
		END IF;
		/*IF get_ds_timeframe(src_ds_id) >= timeframe THEN
			RAISE EXCEPTION 'Timeframe of source data set should be less than timeframe of destination data set';
		END IF;*/
		
		src_t := get_ds_table_name(src_ds_id);
		EXECUTE 'SELECT max(moment) FROM '||src_t INTO close_moment;
		
		dst_ds_id := create_dst_ds(src_ds_id, 'Interval', NULL, timeframe, NULL, NULL);
		FOR i IN
			SELECT
				src_ds_fields.id AS src_field,
				src_ds_fields.field AS base_field_name,
				dst_ds_fields.name AS field_name,
				get_column_name(dst_ds_fields.name, src_ds_fields.field, src_ds_fields.id) AS dst_field_name
			FROM
				(
					SELECT
						id AS id,
						field AS field
					FROM
						data_set_fields
					WHERE
						(ds = src_ds_id)
						AND field IN (SELECT name FROM data_fields WHERE data_field_class IS DISTINCT FROM 'Flows')
				) AS src_ds_fields
				INNER JOIN
				(
					SELECT
						name
					FROM
						data_fields
					WHERE
						(data_fields.ts_type = 'Interval')
						AND (field_class = 'Stocks')
				) AS dst_ds_fields
				ON
					TRUE
		LOOP
			CASE i.field_name
				WHEN 'open' THEN
					src_column_names := src_column_names || ('(SELECT '||i.base_field_name||' FROM '||src_t||'WHERE (moment >= open_moment) AND (moment < close_moment) ORDER BY moment ASC, id ASC LIMIT 1) AS '||i.dst_field_name);
				WHEN 'high' THEN
					src_column_names := src_column_names || ('max('||i.base_field_name||') AS '||i.dst_field_name);
				WHEN 'low' THEN
					src_column_names := src_column_names || ('min('||i.base_field_name||') AS '||i.dst_field_name);
				WHEN 'close' THEN
					src_column_names := src_column_names || ('(SELECT '||i.base_field_name||' FROM '||src_t||'WHERE (moment >= open_moment) AND (moment < close_moment) ORDER BY moment DESC, id DESC LIMIT 1) AS '||i.dst_field_name);
				ELSE
					CONTINUE;
			END CASE;
			insert_fields_query := insert_fields_query || ('('||dst_ds_id||', '||i.field_name||', '||i.base_field_name||', '||i.src_field||')');
		END LOOP;
		FOR i IN
			SELECT
				src_ds_fields.id AS src_field,
				src_ds_fields.field AS base_field_name,
				dst_ds_fields.name AS field_name,
				get_column_name(dst_ds_fields.name, src_ds_fields.field, src_ds_fields.id) AS dst_field_name
			FROM
				(
					SELECT
						id AS id,
						field AS field,
						get_scale_type(get_data_field_type(field, base_field, src_field)) AS scale_type
					FROM
						data_set_fields
					WHERE
						(ds = src_ds_id)
						AND field IN (SELECT name FROM data_fields WHERE field_class IS DISTINCT FROM 'Flows')
				) AS src_ds_fields
				INNER JOIN
				(
					SELECT
						name,
						aggregatable_scale_types
					FROM
						data_fields
					WHERE
						(data_fields.ts_type = 'Interval')
						AND (field_class = 'Flows')
				) AS dst_ds_fields
				ON
					src_ds_fields.scale_type = ANY (dst_ds_fields.aggregatable_scale_types)
			UNION
			VALUES (NULL, NULL, 'number')
		LOOP
			CASE i.field_name
				WHEN 'sum' THEN
					src_column_names := src_column_names || ('sum('||i.base_field_name||') AS '||i.dst_field_name);
				WHEN 'number' THEN
					src_column_names := src_column_names || ('count(id) AS '||i.dst_field_name);
				ELSE
					CONTINUE;
			END CASE;
			insert_fields_query := insert_fields_query || ('('||dst_ds_id||', '||i.field_name||', '||i.base_field||', '||i.src_field||')');
		END LOOP;
		EXECUTE
			'INSERT INTO data_set_fields(ds, field, base_field, src_field) VALUES
				'||array_to_string(insert_fields_query, ', ')
		;
		PERFORM create_ds_table(dst_ds_id);
		insert_query := get_data_insert_query(dst_ds_id);
		
		WHILE open_moment <= close_moment LOOP
			EXECUTE '
				WITH select_interval(open_moment, close_moment) AS (
					SELECT
						'||array_to_string(src_column_names, ', ')||'
					FROM
						'||src_t||'
					WHERE
						(moment >= open_moment)
						AND (moment < close_moment)
				)
				'||insert_query||'
				SELECT * FROM select_interval($1, $2)'
				USING
					open_moment,
					open_moment + timeframe
			;
			open_moment := open_moment + timeframe;
		END LOOP;
		RETURN dst_ds_id;
	END
$$;

CREATE FUNCTION procs.build_chained_changes_ds(src_ds_id bigint, lag int) RETURNS bigint
	LANGUAGE plpgsql VOLATILE RETURNS NULL ON NULL INPUT
AS $$
	DECLARE
		src_ds_ts_type time_series_type;
		timeframe character varying(3);
		dst_ds_id bigint;
		src_t name;
		insert_fields_query text[] = '{}';
		src_column_names text[] = '{}';
		select_order_field text;
		select_query text;
		insert_query text;
		aggregate_statement text[];
		i RECORD;
	BEGIN
		IF NOT (lag > 0) THEN
			RAISE EXCEPTION 'Lag should be defined and be positive';
		END IF;
		SELECT data_sets.ts_type, data_sets.timeframe FROM data_sets WHERE id = src_ds_id INTO STRICT src_ds_ts_type, timeframe;
		src_t := get_ds_table_name(src_ds_id);
		IF src_ds_ts_type = 'Moment' THEN
			dst_ds_id := create_dst_ds(src_ds_id, 'Interval', NULL, NULL, lag, NULL);
			aggregate_statement := ARRAY[dst_ds_id::text, 'base_data.close_moment', 'curr_data.open_moment'];
			-- select_query_parts := ARRAY['moment'];
			select_order_field = 'moment';
			FOR i IN
				SELECT
					src_ds_fields.id AS src_field,
					src_ds_fields.field AS base_field,
					dst_ds_fields.name AS field_name,
					src_ds_fields.column_name::text AS src_column_name,
-- 					get_column_name(dst_ds_fields.name, src_ds_fields.field, src_ds_fields.id) AS dst_column_name,
					get_dbms_type(get_field_type(dst_ds_fields.name, src_ds_fields.field, src_ds_fields.id)) AS dbms_type
				FROM
					(
						SELECT
							id AS id,
							field AS field,
							get_column_name(field, base_field, src_field) AS column_name,
							get_scale_type(get_data_field_type(field, base_field, src_field)) AS scale_type
						FROM
							data_set_fields
						WHERE
							(ds = src_ds_id)
							AND field IN (SELECT name FROM data_fields WHERE field_class IS DISTINCT FROM 'Stocks')
					) AS src_ds_fields
					INNER JOIN
					(
						SELECT
							name,
							aggregatable_scale_types
						FROM
							data_fields
						WHERE
							(data_fields.ts_type = 'Interval')
							AND (field_class = 'Flows')
					) AS dst_ds_fields
					ON
						src_ds_fields.scale_type = ANY (dst_ds_fields.aggregatable_scale_types)
				/*UNION
				VALUES (NULL, NULL, 'number')*/
			LOOP
				CASE i.field_name
					WHEN 'absolute_increase' THEN
						aggregate_statement := aggregate_statement || (
							'curr_data.'||i.src_column_name||' - base_data.'||i.src_column_name
						);
					WHEN 'growth_rate' THEN
						aggregate_statement := aggregate_statement || (
							'CASE
								WHEN (base_data.'||i.src_column_name||' <> 0) THEN
									CAST(curr_data.'||i.src_column_name||' AS '||i.dbms_type||') / base_data.'||i.src_column_name||'
								WHEN (curr_data.'||i.src_column_name||' = 0) AND (base_data.'||i.src_column_name||' = 0) THEN
									CAST(''NaN'' AS '||i.dbms_type||')
								ELSE
									CAST(''Infinity'' AS '||i.dbms_type||') * sign(curr_data.'||i.src_column_name||')
							END'
						);
					WHEN 'increase_rate' THEN
						aggregate_statement := aggregate_statement || (
							'CASE
								WHEN (base_data.'||i.src_column_name||' <> 0) THEN
									CAST(curr_data.'||i.src_column_name||' AS '||i.dbms_type||') / base_data.'||i.src_column_name||' - 1
								WHEN (curr_data.'||i.src_column_name||' = 0) AND (base_data.'||i.src_column_name||' = 0) THEN
									CAST(''NaN'' AS '||i.dbms_type||')
								ELSE
									CAST(''Infinity'' AS '||i.dbms_type||') * sign(curr_data.'||i.src_column_name||')
							END'
						);
					WHEN 'ln_growth_rate' THEN
						aggregate_statement := aggregate_statement || (
							'CASE
								WHEN (curr_data.'||i.src_column_name||' * base_data.'||i.src_column_name||' > 0) THEN
									ln(CAST(curr_data.'||i.src_column_name||' AS '||i.dbms_type||') / base_data.'||i.src_column_name||')
								WHEN (curr_data.'||i.src_column_name||' = 0) AND (base_data.'||i.src_column_name||' > 0) THEN
									CAST(''-Infinity'' AS '||i.dbms_type||')
								WHEN (curr_data.'||i.src_column_name||' > 0) AND (base_data.'||i.src_column_name||' = 0) THEN
									CAST(''Infinity'' AS '||i.dbms_type||')
								ELSE
									CAST(''NaN'' AS '||i.dbms_type||')
							END'
						);
					WHEN 'one_percent_of_increase' THEN
						aggregate_statement := aggregate_statement || (
							'base_data.'||i.src_column_name||' / 100.0' -- Cast ? -- TODO
						);
					ELSE
						CONTINUE;
				END CASE;
				src_column_names := src_column_names || i.src_column_name;
				insert_fields_query := insert_fields_query || ('('||dst_ds_id||', '''||i.field_name||''', '''||i.base_field||''', '||i.src_field||')');
			END LOOP;
		ELSIF src_ds_ts_type = 'Interval' THEN
			dst_ds_id := create_dst_ds(src_ds_id, 'Interval', NULL, timeframe, lag, NULL);
			aggregate_statement := ARRAY[dst_ds_id::text, 'base_data.close_moment', 'curr_data.open_moment'];
			-- select_query_parts := ARRAY['open_moment', 'close_moment'];
			select_order_field = 'close_moment';
			FOR i IN
				SELECT
					src_ds_fields.id AS src_field,
					src_ds_fields.field AS base_field,
					dst_ds_fields.name AS field_name,
					src_ds_fields.column_name::text AS src_column_name,
-- 					get_column_name(dst_ds_fields.name, src_ds_fields.field, src_ds_fields.id) AS dst_column_name,
					get_dbms_type(get_field_type(dst_ds_fields.name, src_ds_fields.field, src_ds_fields.id)) AS dbms_type
				FROM
					(
						SELECT
							id AS id,
							field AS field,
							get_column_name(field, base_field, src_field) AS column_name,
							get_scale_type(get_data_field_type(field, base_field, src_field)) AS scale_type
						FROM
							data_set_fields
						WHERE
							(ds = src_ds_id)
							AND field IN (SELECT name FROM data_fields WHERE field_class IS DISTINCT FROM 'Flows')
					) AS src_ds_fields
					INNER JOIN
					(
						SELECT
							name,
							aggregatable_scale_types
						FROM
							data_fields
						WHERE
							(data_fields.ts_type = 'Interval')
							AND (field_class = 'Flows')
					) AS dst_ds_fields
					ON
						src_ds_fields.scale_type = ANY (dst_ds_fields.aggregatable_scale_types)
				/*UNION
				VALUES (NULL, NULL, 'number')*/
			LOOP
				CASE i.field_name
					WHEN 'absolute_increase' THEN
						aggregate_statement := aggregate_statement || (
							'curr_data.'||i.src_column_name||' - base_data.'||i.src_column_name
						);
					WHEN 'growth_rate' THEN
						aggregate_statement := aggregate_statement || (
							'CASE
								WHEN (base_data.'||i.src_column_name||' <> 0) THEN
									CAST(curr_data.'||i.src_column_name||' AS '||i.dbms_type||') / base_data.'||i.src_column_name||'
								WHEN (curr_data.'||i.src_column_name||' = 0) AND (base_data.'||i.src_column_name||' = 0) THEN
									CAST(''NaN'' AS '||i.dbms_type||')
								ELSE
									CAST(''Infinity'' AS '||i.dbms_type||') * sign(curr_data.'||i.src_column_name||')
							END'
						);
					WHEN 'increase_rate' THEN
						aggregate_statement := aggregate_statement || (
							'CASE
								WHEN (base_data.'||i.src_column_name||' <> 0) THEN
									CAST(curr_data.'||i.src_column_name||' AS '||i.dbms_type||') / base_data.'||i.src_column_name||' - 1
								WHEN (curr_data.'||i.src_column_name||' = 0) AND (base_data.'||i.src_column_name||' = 0) THEN
									CAST(''NaN'' AS '||i.dbms_type||')
								ELSE
									CAST(''Infinity'' AS '||i.dbms_type||') * sign(curr_data.'||i.src_column_name||')
							END'
						);
					WHEN 'ln_growth_rate' THEN
						aggregate_statement := aggregate_statement || (
							'CASE
								WHEN (curr_data.'||i.src_column_name||' * base_data.'||i.src_column_name||' > 0) THEN
									ln(CAST(curr_data.'||i.src_column_name||' AS '||i.dbms_type||') / base_data.'||i.src_column_name||')
								WHEN (curr_data.'||i.src_column_name||' = 0) AND (base_data.'||i.src_column_name||' > 0) THEN
									CAST(''-Infinity'' AS '||i.dbms_type||')
								WHEN (curr_data.'||i.src_column_name||' > 0) AND (base_data.'||i.src_column_name||' = 0) THEN
									CAST(''Infinity'' AS '||i.dbms_type||')
								ELSE
									CAST(''NaN'' AS '||i.dbms_type||')
							END'
						);
					WHEN 'one_percent_of_increase' THEN
						aggregate_statement := aggregate_statement || (
							'base_data.'||i.src_column_name||' / 100.0' -- Cast ? -- TODO
						);
					ELSE
						CONTINUE;
				END CASE;
				src_column_names := src_column_names || i.src_column_name;
-- 				IF dst_ds_id IS NULL THEN
-- 					RAISE EXCEPTION '1';
-- 				ELSIF i.field_name IS NULL THEN
-- 					RAISE EXCEPTION '2';
-- 				ELSIF i.base_field IS NULL THEN
-- 					RAISE EXCEPTION '3';
-- 				ELSIF i.src_field IS NULL THEN
-- 					RAISE EXCEPTION '4';
-- 				END IF;	
				insert_fields_query := insert_fields_query || ('('||dst_ds_id||', '''||i.field_name||''', '''||i.base_field||''', '||i.src_field||')');
			END LOOP;
		ELSE
			RAISE EXCEPTION 'Type of time series of source data set is not Moment or Interval';
		END IF;
		EXECUTE
			'INSERT INTO data_set_fields(ds, field, base_field, src_field) VALUES
				'||array_to_string(insert_fields_query, ', ')
		;
		PERFORM create_ds_table(dst_ds_id);
		insert_query := get_data_insert_query(dst_ds_id);
		
		select_query :=
			'SELECT
				'||array_to_string(src_column_names, ', ')||'
			FROM
				'||src_t||'
			ORDER BY
				'||select_order_field||' ASC,
				id ASC
			'
		;
		EXECUTE '
			DO language plpgsql $insert_do$
				DECLARE
					base_data RECORD;
					curr_data RECORD;
					base_c refcursor;
					curr_c refcursor;
				BEGIN
					OPEN base_c FOR	'||select_query||';
					OPEN curr_c FOR '||select_query||';
					MOVE RELATIVE '||lag||' FROM curr_c;
				
					WHILE TRUE LOOP
						FETCH NEXT FROM curr_c INTO curr_data;
						EXIT WHEN NOT FOUND;
						FETCH NEXT FROM base_c INTO base_data;
						'||insert_query||' VALUES
							('||array_to_string(aggregate_statement, ', ')||')
						;
					END LOOP;
					
					CLOSE curr_c;
					CLOSE base_c;
				END
			$insert_do$;
		';
		
		RETURN dst_ds_id;
		
/*		EXECUTE ' 
			PREPARE insert_data(
					bigint,
					time_moment,
					time_moment,
					time_interval,
					price_type,
					double precision,
					double precision,
					double precision,
					price_type
				) AS
					INSERT INTO '||t||'(
						id,
						open_moment,
						close_moment,
						time_change,
						absolute_increase,
						growth_rate,
						ln_growth_rate,
						increase_rate,
						one_percent_of_increase
					) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9);
		';*/
-- 		DEALLOCATE insert_data;
	END
$$;

-------------------------------------------------------------------------------
