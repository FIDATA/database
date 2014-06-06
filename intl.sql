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


CREATE DOMAIN common.lang_id character(3);

CREATE TABLE langs (
	id common.lang_id PRIMARY KEY,       -- ISO 639-2/T code
		CHECK (common.is_valid_alpha_code(id)),
	part1_code character(2)              -- ISO 639-1 code, if available
		CHECK (common.is_valid_alpha_code(part1_code) IS DISTINCT FROM FALSE),
	
	name character varying(32) NOT NULL
		CHECK (char_length(name) > 0)
);
CREATE UNIQUE INDEX ON langs(part1_code);
CREATE UNIQUE INDEX ON langs(upper(name));

CREATE FUNCTION triggers.langs_set_codes_case() RETURNS trigger
	LANGUAGE plpgsql VOLATILE
AS $$
	BEGIN
		NEW.id := lower(NEW.id);
		NEW.part1_code := lower(NEW.part1_code);
		RETURN NEW;
	END
$$;
CREATE TRIGGER set_codes_case
	BEFORE INSERT
	ON langs
	FOR EACH ROW
	EXECUTE PROCEDURE triggers.langs_set_codes_case()
;

CREATE FUNCTION get_lang(lang_id common.lang_id, OUT res langs)
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		SELECT * FROM langs WHERE id = lower(lang_id) INTO res;
	END
$$;

CREATE FUNCTION get_lang_by_part1_code(lang_part1_code character(2), OUT res langs)
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		SELECT * FROM langs WHERE part1_code = lower(lang_part1_code) INTO res;
	END
$$;

CREATE FUNCTION get_lang_by_name(lang_name character varying(32), OUT res langs)
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		SELECT * FROM langs WHERE upper(name) = upper(lang_name) INTO res;
	END
$$;


CREATE DOMAIN common.script_id character(4);

CREATE TABLE scripts (
	id common.script_id PRIMARY KEY
		CHECK (common.is_valid_alpha_code(id)),
	num_code character(3)
		CHECK (common.is_valid_numerical_code(num_code) IS DISTINCT FROM FALSE),
	name character varying(64) NOT NULL
		CHECK (char_length(name) > 0)
);
CREATE UNIQUE INDEX ON scripts(num_code);
CREATE UNIQUE INDEX ON scripts(upper(name));

CREATE FUNCTION triggers.scripts_set_codes_case() RETURNS trigger
	LANGUAGE plpgsql VOLATILE
AS $$
	BEGIN
		NEW.id := initcap(NEW.id);
		RETURN NEW;
	END
$$;
CREATE TRIGGER set_codes_case
	BEFORE INSERT
	ON scripts
	FOR EACH ROW
	EXECUTE PROCEDURE triggers.scripts_set_codes_case()
;

CREATE FUNCTION get_script(script_id common.script_id, OUT res scripts)
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		SELECT * FROM scripts WHERE id = initcap(script_id) INTO res;
	END
$$;

CREATE FUNCTION get_script_by_name(script_name character varying(64), OUT res scripts)
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		SELECT * FROM scripts WHERE upper(name) = upper(script_name) INTO res;
	END
$$;


CREATE FUNCTION is_valid_lang_script(lang_id common.lang_id, script_id common.script_id) RETURNS bool
	LANGUAGE plpgsql STABLE
AS $$
	BEGIN
		IF lang_id IS NULL THEN
			RETURN NULL;
		ELSIF script_id IS NULL THEN
			RETURN EXISTS(SELECT * FROM langs WHERE id = lower(lang_id));
		ELSE
			RETURN EXISTS(SELECT * FROM langs_scripts WHERE (lang = lower(lang_id)) AND (script = initcap(script_id)));
		END IF;
	END
$$;

CREATE TABLE langs_scripts (
	lang common.lang_id NOT NULL
		REFERENCES langs (id)
			ON UPDATE CASCADE ON DELETE CASCADE,
	script common.script_id NOT NULL
		REFERENCES scripts (id)
			ON UPDATE CASCADE ON DELETE CASCADE,
	PRIMARY KEY (lang, script)
);
-- CREATE INDEX ON langs_scripts (lang);
CREATE INDEX ON langs_scripts (script);

CREATE FUNCTION triggers.langs_scripts_insert_only_absent() RETURNS trigger
	LANGUAGE plpgsql VOLATILE
AS $$
	BEGIN
		NEW.lang := lower(NEW.lang);
		NEW.script := initcap(NEW.script);
		IF NOT EXISTS(SELECT * FROM langs_scripts where (lang = NEW.lang) AND (script = NEW.script)) THEN
			RETURN NEW;
		ELSE
			RETURN NULL;
		END IF;
	END
$$;
CREATE TRIGGER insert_only_absent
	BEFORE INSERT
	ON langs_scripts
	FOR EACH ROW
	EXECUTE PROCEDURE triggers.langs_scripts_insert_only_absent()
;

GRANT
	DELETE
	ON TABLE langs_scripts
	TO fidata
;
