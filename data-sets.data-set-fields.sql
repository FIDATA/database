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
--                             DATA SET FIELDS                               --
-------------------------------------------------------------------------------

CREATE FUNCTION get_ds_field_ds(ds_field_id bigint) RETURNS bigint
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN (SELECT ds FROM data_set_fields WHERE id = ds_field_id);
	END
$$;

CREATE TABLE data_set_fields (
	id bigserial PRIMARY KEY,
	ds bigint NOT NULL
		REFERENCES data_sets (id)
			ON UPDATE CASCADE ON DELETE CASCADE,
	CHECK (get_ds_ts_type(ds) <> 'Object')
);
CREATE INDEX ON data_set_fields (ds);




CREATE FUNCTION get_ds_field_oper_field(ds_field_id bigint, _oper_index int) RETURNS common.name_type
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN (
			SELECT
				field
			FROM
				data_set_field_operations
			WHERE
				(ds_field = ds_field_id)
				AND (oper_index = _oper_index)
		);
	END
$$;

CREATE FUNCTION get_ds_field_oper_proc(ds_field_id bigint, _oper_index int) RETURNS common.name_type
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN (
			SELECT
				proc
			FROM
				data_set_field_operations
			WHERE
				(ds_field = ds_field_id)
				AND (oper_index = _oper_index)
		);
	END
$$;


CREATE TABLE data_set_field_operations (
	ds_field bigint NOT NULL
		REFERENCES data_set_fields (id)
			ON UPDATE CASCADE ON DELETE CASCADE,
	oper_index int NOT NULL
		CHECK (oper_index > 0),
	PRIMARY KEY (ds_field, oper_index),
	
	field common.name_type
		REFERENCES fields (name)
			ON UPDATE CASCADE ON DELETE RESTRICT,
	proc common.name_type
		REFERENCES procs.procs (name)
			ON UPDATE CASCADE ON DELETE RESTRICT,
	CHECK ((proc IS NULL) OR (field IS NULL)),
	
	-- For functions, showing dynamics
	lag_value int
		CHECK ((lag_value IS NULL) OR (lag_value > 0)),
	base_time_moment time_moment, -- TODO: id of row ?
	CHECK (
		(procs.get_proc_type(proc) IS DISTINCT FROM 'dyn_show_func') AND (lag_value IS NULL) AND (base_time_moment IS NULL)
		OR (procs.get_proc_type(proc) = 'dyn_show_func') AND ((lag_value IS NOT NULL) ~| (base_time_moment IS NOT NULL))
	),
	
	-- For window functions
	window_size int
		CHECK ((window_size IS NULL) OR (window_size > 0)),
	centered bool,
	weighting_method common.name_type
		REFERENCES procs.weighting_methods (name)
			ON UPDATE CASCADE ON DELETE RESTRICT,
	CHECK (
		(procs.get_proc_type(proc) IS DISTINCT FROM 'window_func') AND (window_size IS NULL) AND (centered IS NULL) AND (weighting_method IS NULL)
		OR (procs.get_proc_type(proc) = 'window_func') AND (window_size IS NOT NULL) AND (centered IS NOT NULL) AND (weighting_method IS NOT NULL)
	)
);
-- CREATE INDEX ON data_set_field_operations (ds_field);
CREATE INDEX ON data_set_field_operations (field);
CREATE INDEX ON data_set_field_operations (proc);
CREATE INDEX ON data_set_field_operations (weighting_method);


CREATE TABLE data_set_field_oper_source_ds_fields (
	ds_field bigint NOT NULL,
	oper_index int NOT NULL,
	FOREIGN KEY (ds_field, oper_index)
		REFERENCES data_set_field_operations (ds_field, oper_index)
			MATCH FULL
			ON UPDATE CASCADE ON DELETE CASCADE,
	CHECK (get_ds_field_oper_field(ds_field, oper_index) IS NULL),
	field_index int NOT NULL
		CHECK (field_index > 0),
	CHECK (
		(get_ds_field_oper_proc(ds_field, oper_index) IS NULL) AND (field_index = 1)
		OR (get_ds_field_oper_proc(ds_field, oper_index) = 'comp_field_func')
	),
	PRIMARY KEY (ds_field, oper_index, field_index),
	
	source_ds_field bigint NOT NULL
		REFERENCES data_set_fields (id)
			ON UPDATE CASCADE ON DELETE RESTRICT
);
-- CREATE INDEX ON data_set_field_oper_source_ds_fields (ds_field, oper_index);
CREATE INDEX ON data_set_field_oper_source_ds_fields (source_ds_field);


-- For window functions
CREATE TABLE data_set_field_oper_params (
	ds_field bigint NOT NULL,
	oper_index int NOT NULL,
	FOREIGN KEY (ds_field, oper_index)
		REFERENCES data_set_field_operations (ds_field, oper_index)
			MATCH FULL
			ON UPDATE CASCADE ON DELETE CASCADE,
	CHECK (procs.get_proc_type(get_ds_field_oper_proc(ds_field, oper_index)) = 'window_func'),
	param_index int NOT NULL
		CHECK (param_index > 0),
	PRIMARY KEY (ds_field, oper_index, param_index),
	
	param_value double precision NOT NULL
);
-- CREATE INDEX ON data_set_field_oper_params (ds_field, oper_index);




CREATE FUNCTION get_ds_field_column_name(ds_field_id bigint, OUT res name)
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	DECLARE
		i   RECORD;
	BEGIN
		FOR i IN
			SELECT
				*
			FROM
				data_set_field_operations
			WHERE
				ds_field = ds_field_id
			ORDER BY
				oper_index DESC
		LOOP
			IF i.field IS NOT NULL THEN
				res := i.field; -- TODO
				-- TODO: Check res IS NULL
			ELSIF i.proc IS NOT NULL THEN
				CASE get_proc_type(i.proc)
					WHEN 'comp_field_func' THEN
						-- TODO: Check res IS NULL
						res := i.proc||'('||(
							SELECT
								string_aggr(get_ds_field_column_name(source_ds_field) ORDER BY field_index ASC)
							FROM
								data_set_field_oper_source_ds_fields
							WHERE
								(ds_field = i.ds_field)
								AND (oper_index = i.oper_index)
						)||')';
					WHEN 'aggr_func' THEN
						res := i.proc||'('||res||')';
					WHEN 'dyn_show_func' THEN
						res := i.proc||'('||res||', '||COALESCE(i.lag, i.base_time_moment)::name||')';
					WHEN 'window_func' THEN
						res := i.proc||'('||res||', '||i.window_size::name||', '||i.centered::name||', '||i.weighting_method||', '||COALESCE((
							SELECT
								string_aggr(param_value ORDER BY param_index ASC)
							FROM
								data_set_field_oper_params
							WHERE
								(ds_field = i.ds_field)
								AND (oper_index = i.oper_index)
						), '')||')';
				END CASE;
			ELSE
				res := get_ds_field_column_name((
					SELECT
						source_ds_field
					FROM
						data_set_field_oper_source_ds_fields
					WHERE
						(ds_field = i.ds_field)
						AND (oper_index = i.oper_index)
				));
			END IF;
		END LOOP;
	END
$$;

CREATE FUNCTION get_ds_field_type(ds_field_id bigint, OUT res common.name_type)
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	DECLARE
		i           RECORD;
		res_is_diff bool = FALSE;
	BEGIN
		FOR i IN
			SELECT
				*
			FROM
				data_set_field_operations
			WHERE
				ds_field = ds_field_id
			ORDER BY
				oper_index DESC
		LOOP
			IF i.field IS NOT NULL THEN
				res := get_field_type(i.field);
				EXIT;
			ELSIF i.proc IS NOT NULL THEN
				CASE get_proc_type(i.proc)
					WHEN 'comp_field_func' THEN
						res := get_field_type(procs.get_proc_output_field(i.proc));
						EXIT;
					WHEN 'aggr_func' THEN
						res := procs.get_proc_output_type(i.proc);
						EXIT WHEN res IS NOT NULL;
					WHEN 'dyn_show_func' THEN
						res := procs.get_proc_output_type(i.proc);
						res_is_diff := procs.get_proc_output_type_is_diff(i.proc);
						EXIT WHEN res IS NOT NULL;
					WHEN 'window_func' THEN
						NULL;
				END CASE;
			ELSE
				res := get_ds_field_type((
					SELECT
						source_ds_field
					FROM
						data_set_field_oper_source_ds_fields
					WHERE
						(ds_field = i.ds_field)
						AND (oper_index = i.oper_index)
				));
				EXIT;
			END IF;
		END LOOP;
		IF res_is_diff THEN
			res := get_type_diff_type(res);
		END IF;
	END
$$;




CREATE FUNCTION add_ds_column(ds_table_name name, column_name name, column_type common.name_type) RETURNS VOID
	LANGUAGE plpgsql VOLATILE RETURNS NULL ON NULL INPUT
AS $$
	DECLARE
		foreign_table regclass;
	BEGIN
		column_name := quote_ident(column_name);
		IF column_name NOT IN ('moment', 'open(moment)', 'close(moment)') THEN
			EXECUTE '
				ALTER TABLE IF EXISTS '||ds_table_name||'
					ADD COLUMN '||column_name||' '||get_type_dbms_type(column_type)||'
				;'
			;
		END IF;
		foreign_table := get_type_foreign_table(column_type);
		IF foreign_table IS NOT NULL THEN
			EXECUTE '
				ALTER TABLE IF EXISTS '||ds_table_name||'
					ADD FOREIGN KEY ('||column_name||')
						REFERENCES '||foreign_table||' ('||get_type_foreign_column(column_type)||')
							ON UPDATE CASCADE ON DELETE RESTRICT
				;'
			;
		END IF;
		IF
			foreign_table IS NOT NULL
			OR (get_type_scale(column_type) IN ('Nominal', 'Ordinal'))
			OR (column_name IN ('moment', 'open(moment)', 'close(moment)')) 
		THEN
			BEGIN
				EXECUTE 'CREATE INDEX ON '||ds_table_name||' ('||column_name||' ASC);';
			EXCEPTION
				WHEN undefined_table THEN
					NULL;
			END;
		END IF;
	END
$$;

CREATE FUNCTION drop_ds_column(ds_table_name name, column_name common.name_type) RETURNS VOID
	LANGUAGE plpgsql VOLATILE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		EXECUTE 'ALTER TABLE IF EXISTS '||ds_table_name||' DROP COLUMN '||quote_ident(column_name)||' CASCADE;';
	END
$$;


CREATE FUNCTION triggers.object_fields_add_column() RETURNS trigger
	LANGUAGE plpgsql VOLATILE
AS $$
	DECLARE
		i RECORD;
	BEGIN
		FOR i IN
			SELECT
				id
			FROM
				data_sets
			WHERE
				(ts_type = 'Object')
				AND (object_type = NEW.object_type)
		LOOP
			PERFORM add_ds_column(get_ds_table_name(i.id), NEW.field);
		END LOOP;
		RETURN NULL;
	END
$$;
CREATE TRIGGER add_column
	AFTER INSERT
	ON object_fields
	FOR EACH ROW
	EXECUTE PROCEDURE triggers.object_fields_add_column()
;

CREATE FUNCTION triggers.object_fields_drop_column() RETURNS trigger
	LANGUAGE plpgsql VOLATILE
AS $$
	DECLARE
		i bigint; -- data_sets.id%TYPE
	BEGIN
		FOR i IN
			SELECT
				id
			FROM
				data_sets
			WHERE
				(ts_type = 'Object')
				AND (object_type = OLD.object_type)
		LOOP
			PERFORM drop_ds_column(get_ds_table_name(i.id), OLD.field);
		END LOOP;
		RETURN NULL;
	END
$$;
CREATE TRIGGER drop_column
	AFTER DELETE
	ON object_fields
	FOR EACH ROW
	EXECUTE PROCEDURE triggers.object_fields_drop_column()
;

CREATE FUNCTION triggers.data_set_fields_drop_column() RETURNS trigger
	LANGUAGE plpgsql VOLATILE
AS $$
	BEGIN
		PERFORM drop_ds_column(get_ds_table_name(OLD.ds), get_ds_field_column_name(OLD.id));
		RETURN NULL;
	END
$$;
CREATE TRIGGER drop_column
	AFTER DELETE
	ON data_set_fields
	FOR EACH ROW
	EXECUTE PROCEDURE triggers.data_set_fields_drop_column()
;




CREATE FUNCTION add_ds_field(ds_id bigint, ds_field_operations data_set_field_operations[], ds_field_oper_source_ds_fields data_set_field_oper_source_ds_fields[][], ds_field_oper_params data_set_field_oper_params[][]) RETURNS bigint
	LANGUAGE plpgsql VOLATILE
AS $$
	DECLARE
		ds_field_id          bigint;
		oper                 data_set_field_operations%ROWTYPE;
		oper_source_ds_field data_set_field_oper_source_ds_fields%ROWTYPE;
		oper_param           data_set_field_oper_params%ROWTYPE;
	BEGIN
		IF (ds_id IS NULL) OR (ds_field_operations IS NULL) THEN
			RETURN NULL;
		END IF;
		INSERT INTO data_set_fields (ds) VALUES (ds_id) RETURNING id INTO ds_field_id;
		FOR i IN 1 .. array_length(ds_field_operations, 1) LOOP
			oper := ds_field_operations[i];
			oper.ds_field := ds_field_id;
			oper.oper_index := i;
			INSERT INTO data_set_field_operations VALUES (oper.*);
			IF ds_field_oper_source_ds_fields[i] IS NOT NULL THEN
				FOR j IN 1 .. array_length(ds_field_oper_source_ds_fields[i], 1) LOOP
					oper_source_ds_field := ds_field_oper_source_ds_fields[j];
					oper_source_ds_field.ds_field := ds_field_id;
					oper_source_ds_field.oper_index := i;
					oper_source_ds_field.field_index := j;
					INSERT INTO data_set_field_operations VALUES (oper_source_field.*);
				END LOOP;
			END IF;
			IF ds_field_oper_params[i] IS NOT NULL THEN
				FOR j IN 1 .. array_length(ds_field_oper_params[i], 1) LOOP
					oper_param := ds_field_oper_params[j];
					oper_param.ds_field := ds_field_id;
					oper_param.oper_index := i;
					oper_param.param_index := j;
					INSERT INTO data_set_field_operations VALUES (oper_param.*);
				END LOOP;
			END IF;
		END LOOP;
		PERFORM add_ds_column(get_ds_table_name(ds_id), get_ds_field_column_name(ds_field_id), get_ds_field_type(ds_field_id));
		RETURN ds_field_id;
	END
$$;




-- NOTE: data_sets_drop_table trigger is located into data-sets.sql
-- NOTE: triggers.interval_ds_check_moments function is located into data-sets.sql
CREATE FUNCTION create_ds_table(ds_id bigint) RETURNS name
	LANGUAGE plpgsql VOLATILE RETURNS NULL ON NULL INPUT
AS $$
	DECLARE
 		ds_table_name        name;
 		parent_ds_table_name name;
 		ts_type              time_series_type;
 		i                    RECORD;
	BEGIN
		ds_table_name := get_ds_table_name(ds_id);
		BEGIN
			EXECUTE 'SELECT COUNT(id) FROM '||ds_table_name;
		EXCEPTION
			WHEN undefined_table THEN
				ts_type := get_ds_ts_type(ds_id);
				
				IF ts_type = 'Interval' THEN
					parent_ds_table_name := 'di';
				ELSE
					parent_ds_table_name := 'dm';
				END IF;
				EXECUTE 
					'CREATE TABLE '||ds_table_name||' (
						id bigserial PRIMARY KEY,
						CHECK (ds = '||ds_id||')
					) INHERITS ('||parent_ds_table_name||');'
				;
				IF ts_type = 'Interval' THEN
					EXECUTE '
						CREATE TRIGGER check_moments
							BEFORE INSERT
							ON '||ds_table_name||'
							FOR EACH ROW
							EXECUTE PROCEDURE triggers.interval_ds_check_moments()
						;
					';
				END IF;
				
				IF ts_type = 'Object' THEN
					FOR i IN
						SELECT
							field
						FROM
							object_fields
						WHERE
							object_type = get_ds_object_type(ds_id)
						ORDER BY
							id
					LOOP
						PERFORM add_ds_column(ds_table_name, i.field, get_field_type(i.field));
					END LOOP;
				ELSE
					FOR i IN
						SELECT
							id
						FROM
							data_set_fields
						WHERE
							ds = ds_id
						ORDER BY
							id
					LOOP
						PERFORM add_ds_column(ds_table_name, get_ds_field_column_name(i.id), get_ds_field_type(i.id));
					END LOOP;
				END IF;
		END;
		RETURN ds_table_name;
	END
$$;




-- CREATE RULE protect_from_update AS
-- 	ON UPDATE
-- 	TO data_set_fields
-- 	DO INSTEAD NOTHING
-- ;




CREATE FUNCTION triggers.data_sets_insert_moment_fields() RETURNS trigger
	LANGUAGE plpgsql VOLATILE
AS $$
	DECLARE
		src_field      bigint = NULL;
		ds_field_oper1 data_set_field_operations%ROWTYPE;
		ds_field_oper2 data_set_field_operations%ROWTYPE;
	BEGIN
		CASE NEW.ts_type
			WHEN 'Moment' THEN
				ds_field_oper1.field := 'moment';
				PERFORM add_ds_field(NEW.id, ARRAY[ds_field_oper1], NULL, NULL);
			WHEN 'Interval' THEN
				ds_field_oper1.proc := 'open';
				ds_field_oper2.field := 'moment'; -- TODO: use src_ds
				PERFORM add_ds_field(NEW.id, ARRAY[ds_field_oper1, ds_field_oper2], NULL, NULL);
				ds_field_oper1.proc := 'close';
				ds_field_oper2.field := 'moment'; -- TODO: use src_ds
				PERFORM add_ds_field(NEW.id, ARRAY[ds_field_oper1, ds_field_oper2], NULL, NULL);
		END CASE;
		RETURN NULL;
	END
$$;
CREATE TRIGGER insert_moment_fields
	AFTER INSERT
	ON data_sets
	FOR EACH ROW
	EXECUTE PROCEDURE triggers.data_sets_insert_moment_fields()
;

CREATE FUNCTION triggers.data_set_fields_protect_moment_fields_from_delete() RETURNS trigger
	LANGUAGE plpgsql VOLATILE
AS $$
	BEGIN
		CASE get_ds_ts_type(OLD.ds)
			WHEN 'Moment' THEN
				IF get_ds_field_column_name(OLD.id) = 'moment' THEN
					RETURN NULL;
				END IF;
			WHEN 'Interval' THEN
				IF get_ds_field_column_name(OLD.id) IN ('open(moment)', 'close(moment)') THEN
					RETURN NULL;
				END IF;
		END CASE;
		RETURN OLD;
	END
$$;
CREATE TRIGGER protect_moment_fields_from_delete
	BEFORE DELETE
	ON data_set_fields
	FOR EACH ROW
	EXECUTE PROCEDURE triggers.data_set_fields_protect_moment_fields_from_delete()
;




CREATE FUNCTION get_data_insert_query(ds_id bigint) RETURNS text
	LANGUAGE plpgsql VOLATILE RETURNS NULL ON NULL INPUT
AS $$
	DECLARE
		fields_names text;
	BEGIN
		IF get_ds_ts_type(ds_id) <> 'Object' THEN
			SELECT
				string_agg(field_name, ', ' ORDER BY id ASC)
			FROM (
				SELECT
					0 AS id,
					'ds' AS field_name
				UNION (
					SELECT
						id,
						quote_ident(get_ds_field_column_name(id))
					FROM
						data_set_fields
					WHERE
						ds = ds_id
				)
			) AS t
			INTO STRICT fields_names;
		ELSE
			SELECT
				string_agg(field_name, ', ' ORDER BY id ASC)
			FROM (
				SELECT
					0 AS id,
					'ds' AS field_name
				UNION (
					SELECT
						id,
						quote_ident(field)
					FROM
						object_fields
					WHERE
						object_type = get_ds_object_type(ds_id)
				)
			)  AS t
			INTO STRICT fields_names;
		END IF;
		RETURN 'INSERT INTO '||get_ds_table_name(ds_id)||' ('||fields_names||')	';
	END
$$;

CREATE FUNCTION get_data_insert_query_for_python(ds_id bigint) RETURNS text
	LANGUAGE plpgsql VOLATILE RETURNS NULL ON NULL INPUT
AS $$
	DECLARE
		field_names  text;
		field_values text;
	BEGIN
		IF get_ds_ts_type(ds_id) <> 'Object' THEN
			SELECT
				common.escape_query_for_python(string_agg(field_name, ', ' ORDER BY id ASC)),
				string_agg(field_value, ', ' ORDER BY id ASC)
			FROM (
				SELECT
					0 AS id,
					'ds' AS field_name,
					ds_id::text AS field_value
				UNION (
					SELECT
						id,
						quote_ident(get_ds_field_column_name(id)),
/* TODO: psycopg2 ticket
http://psycopg.lighthouseapp.com/projects/62710/tickets/167-problem-with-in-names-of-parameters-in-cursorexecute */
						'%('||get_ds_field_column_name(id)||')s'
					FROM
						data_set_fields
					WHERE
						ds = ds_id
				)
			) AS t
			INTO STRICT field_names, field_values;
		ELSE
			SELECT
				string_agg(field_name, ', ' ORDER BY id ASC),
				string_agg(field_value, ', ' ORDER BY id ASC)
			FROM (
				SELECT
					0 AS id,
					'ds' AS field_name,
					ds_id::text AS field_value
				UNION (
					SELECT
						id,
						quote_ident(field),
/* TODO: psycopg2 ticket 167 */
						'%('||field||')s'
					FROM
						object_fields
					WHERE
						object_type = get_ds_object_type(ds_id)
				)
			)  AS t
			INTO STRICT field_names, field_values;
		END IF;
		RETURN 'INSERT INTO '||get_ds_table_name(ds_id)||' ('||field_names||') VALUES ('||field_values||')';
	END
$$;




GRANT
	DELETE
	ON TABLE data_set_fields, data_set_field_operations, data_set_field_oper_source_ds_fields, data_set_field_oper_params
	TO fidata
;




-------------------------------------------------------------------------------
--                    REPRESENTATIONS OF DATA SET FIELDS                     --
-------------------------------------------------------------------------------

CREATE TYPE representation_direction AS ENUM (
	'Output',
	'Input'
);

CREATE TYPE representation_method AS ENUM (
	'DecimalFraction',  -- With decimal fraction
	'BinaryFractions'   -- With fraction of power of 2 (in 1/2, …, 1/32, …)
);

CREATE TABLE data_set_field_representations (
	ds_field bigint NOT NULL,
	direction representation_direction NOT NULL,
	PRIMARY KEY (ds_field, direction),
	
	exponent int NOT NULL  -- Multiplier (e.g. to omit some digits)
		CHECK (exponent >= 0),
	digits int NOT NULL    -- 0 means no fraction
		CHECK (digits >= 0),
	method representation_method,
	CHECK ((digits = 0) ~| (method IS NOT NULL))
);

GRANT
	DELETE
	ON TABLE data_set_field_representations
	TO fidata
;

-------------------------------------------------------------------------------
