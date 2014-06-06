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


-- TODO: indices

DO LANGUAGE plpgsql $$
	BEGIN
		CREATE SCHEMA procs;
	EXCEPTION
		WHEN duplicate_schema THEN
			NULL;
	END
$$;

GRANT
	ALL PRIVILEGES
	ON SCHEMA procs
	TO fidata_admin;
GRANT
	USAGE
	ON SCHEMA procs
	TO fidata;

ALTER DEFAULT PRIVILEGES IN SCHEMA procs GRANT
	EXECUTE
	ON FUNCTIONS
	TO fidata;


CREATE TYPE procs.proc_type AS ENUM (
/*
	Functions, computing fields:
	
	Signature for column name:
		proc_name (input_field_1, ..., input_field_n)
	
	Calling signature:
		SELECT
			dbms_proc(input_field_1, ..., input_field_n)
*/
	'comp_field_func',

/*
	Aggregating functions
	
	Signature for column name:
		proc_name(input_field)
	
	Calling signature:
		SELECT
			dbms_proc(input_field)
		GROUP BY
			timeframe # TODO
*/
	'aggr_func',

/*
	Functions, showing dynamics
	
	Signature for column name:
		proc_name(input_field, lag_size)
	or
		proc_name(input_field, base_time_moment)
	
	Calling signature:
		SELECT
			dbms_proc(input_field, lag(output_field) OVER WINDOW (ORDER BY id, moment/close_moment))
*/
	'dyn_show_func',

/*
	Window functions
	
	Signature for column name:
		proc_name(input_field, window_size, centered, weighting_method, params)
		
	If centered == TRUE then window_size should be finite and odd
	
	Calling signature:
		SELECT
			dbms_proc(input_field, weighting_method, params) OVER WINDOW (ORDER BY id, moment/close_moment RANGE BETWEEN ... AND ...) # TODO
*/
	'window_func'
);


CREATE FUNCTION procs.get_proc_type (proc_name common.name_type) RETURNS procs.proc_type
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN (SELECT proc_type FROM procs.procs WHERE name = proc_name);
	END
$$;

CREATE FUNCTION procs.get_proc_output_type (proc_name common.name_type) RETURNS common.name_type
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN (SELECT output_type FROM procs.procs WHERE name = proc_name);
	END
$$;

CREATE FUNCTION procs.get_proc_output_type_is_diff (proc_name common.name_type) RETURNS bool
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN (SELECT output_type_is_diff FROM procs.procs WHERE name = proc_name);
	END
$$;

CREATE FUNCTION procs.get_proc_output_field (proc_name common.name_type) RETURNS common.name_type
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN (SELECT output_field FROM procs.procs WHERE name = proc_name);
	END
$$;


CREATE FUNCTION procs.is_valid_proc(proc_type procs.proc_type, dbms_proc_namespace_name name, dbms_proc_name name/*, output_type_name common.name_type*/) RETURNS bool
	LANGUAGE plpgsql STABLE
AS $$
	DECLARE
		dbms_proc_namespace_oid oid;
	BEGIN
		IF dbms_proc_namespace_name IS NOT NULL THEN
			SELECT oid FROM pg_namespace WHERE nspname = dbms_proc_namespace_name INTO dbms_proc_namespace_oid;
			IF NOT FOUND THEN
				RETURN FALSE;
			END IF;
		END IF;
		CASE proc_type
			WHEN 'comp_field_func' THEN
				RETURN EXISTS(
					SELECT
						*
					FROM
						pg_proc
					WHERE
						(proname = dbms_proc_name) -- TODO
						AND ((dbms_proc_namespace_oid IS NULL) OR (pronamespace = dbms_proc_namespace_oid))
				);
			WHEN 'aggr_func' THEN
				RETURN EXISTS(
					SELECT
						*
					FROM
						pg_proc
					WHERE
						(proname = dbms_proc_name) -- TODO
						AND proisagg
						AND ((dbms_proc_namespace_oid IS NULL) OR (pronamespace = dbms_proc_namespace_oid))
				);
			WHEN 'dyn_show_func' THEN
				RETURN EXISTS(
					SELECT
						*
					FROM
						pg_proc
					WHERE
						(proname = dbms_proc_name) -- TODO
						AND ((dbms_proc_namespace_oid IS NULL) OR (pronamespace = dbms_proc_namespace_oid))
				);
			WHEN 'window_func' THEN
				RETURN EXISTS(
					SELECT
						*
					FROM
						pg_proc
					WHERE
						(proname = dbms_proc_name)
						AND (proisagg OR proiswindow)
						AND ((dbms_proc_namespace_oid IS NULL) OR (pronamespace = dbms_proc_namespace_oid))
				);
			ELSE
				RETURN FALSE;
		END CASE;
	END
$$;

CREATE TABLE procs.procs (
	name common.name_type PRIMARY KEY
		CHECK (char_length(name) > 0),
	proc_type procs.proc_type NOT NULL,
	dbms_proc_namespace name,
	dbms_proc name NOT NULL,
	CHECK (procs.is_valid_proc(proc_type, dbms_proc_namespace, dbms_proc)),
	
	input_field_class field_class,
	CHECK ((proc_type = 'aggr_func') ~| (input_field_class IS NULL)),
	
	output_type common.name_type
		REFERENCES types (name)
			ON UPDATE CASCADE ON DELETE RESTRICT,
	CHECK ((proc_type <> 'comp_field_func') OR (output_type IS NOT NULL)),
	output_type_is_diff bool,
	CHECK (
		(proc_type <> 'dyn_show_func') AND (output_type_is_diff IS NULL)
		OR (proc_type = 'dyn_show_func') AND (
			(output_type IS NULL)
			OR NOT output_type_is_diff
		)
	),
	output_field common.name_type
		REFERENCES fields (name)
			ON UPDATE CASCADE ON DELETE CASCADE,
	CHECK ((output_field IS NULL) OR (get_field_type(output_field) = output_type)),
	CHECK ((proc_type = 'comp_field_func') ~| (output_field IS NULL)),
	
	description text NOT NULL DEFAULT '' -- TeX, MathML etc.
);
CREATE INDEX ON procs.procs (proc_type);
CREATE INDEX ON procs.procs (output_type);
CREATE INDEX ON procs.procs (output_field);


CREATE TABLE procs.proc_input_scales (
	proc common.name_type NOT NULL
		REFERENCES procs.procs (name)
			ON UPDATE CASCADE ON DELETE CASCADE
		CHECK (
			(procs.get_proc_type(proc) IN ('dyn_show_func', 'window_func'))
			OR (procs.get_proc_type(proc) = 'aggr_func') AND (procs.get_proc_output_type(proc) IS NULL)
		),
	scale scale_type NOT NULL,
	PRIMARY KEY (proc, scale)
);
-- CREATE INDEX ON procs.proc_input_scales (proc);
CREATE INDEX ON procs.proc_input_scales (scale);


CREATE TABLE procs.proc_input_fields (
	proc common.name_type NOT NULL
		REFERENCES procs.procs (name)
			ON UPDATE CASCADE ON DELETE CASCADE
		CHECK (procs.get_proc_type(proc) = 'comp_field_func'),
	field_index smallint NOT NULL
		CHECK (field_index > 0),
	PRIMARY KEY (proc, field_index),
	
	field common.name_type NOT NULL
		REFERENCES fields (name)
			ON UPDATE CASCADE ON DELETE RESTRICT
);
-- CREATE INDEX ON procs.proc_input_fields (proc);
CREATE INDEX ON procs.proc_input_fields (field);


CREATE TABLE procs.proc_params (
	proc common.name_type NOT NULL
		REFERENCES procs.procs (name)
			ON UPDATE CASCADE ON DELETE CASCADE
		CHECK (procs.get_proc_type(proc) = 'window_func'),
	param_index smallint NOT NULL
		CHECK (param_index > 0),
	PRIMARY KEY (proc, param_index),
	
	param_name common.name_type NOT NULL
		CHECK (char_length(param_name) > 0),
	param_type common.name_type NOT NULL
		REFERENCES types (name)
			ON UPDATE CASCADE ON DELETE RESTRICT
);
-- CREATE INDEX ON procs.proc_params (proc);
CREATE UNIQUE INDEX ON procs.proc_params (proc, param_name);
CREATE INDEX ON procs.proc_params (param_type);


-- For window functions
CREATE TABLE procs.weighting_methods (
	name common.name_type PRIMARY KEY
		CHECK (char_length(name) > 0),
	dbms_proc_namespace name,
	dbms_proc name NOT NULL,

	description text NOT NULL DEFAULT '' -- TeX, MathML etc.
);
