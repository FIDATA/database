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


CREATE TYPE distribution_type AS ENUM (
	'Continuous',
	'Discrete'
);

CREATE FUNCTION get_distribution_distr_type(distr_name common.name_type) RETURNS distribution_type
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN (SELECT distr_type FROM distributions WHERE name = distr_name);
	END
$$;

CREATE TABLE distributions (
	name text PRIMARY KEY    -- Python identifier — length is unlimited
		CHECK (char_length(name) > 0),
	py_module text NOT NULL  -- Python identifier — length is unlimited
		CHECK (char_length(py_module) > 0),
	distr_type distribution_type NOT NULL,
	
	a double precision NOT NULL, -- Lower bound of the support of the distribution
	b double precision NOT NULL, -- Upper bound of the support of the distribution
-- 	xtol double precision,
-- 	moment_tol double precision,
-- 	inc bigint,
	
	description text NOT NULL DEFAULT ''
);

CREATE TABLE distribution_params (
	distrib_name common.name_type NOT NULL
		REFERENCES distributions (name)
			ON UPDATE CASCADE ON DELETE RESTRICT,
	param_name common.name_type NOT NULL
		CHECK (char_length(param_name) > 0),
	PRIMARY KEY (distrib_name, param_name)
);
-- CREATE INDEX ON distribution_params (distrib_name);

REVOKE
	INSERT, UPDATE
	ON TABLE distributions, distribution_params
	FROM fidata
	CASCADE
;

CREATE FUNCTION triggers.distributions_insert_common_params() RETURNS trigger
	LANGUAGE plpgsql VOLATILE
AS $$
	BEGIN
		CASE NEW.distr_type
			WHEN 'Continuous' THEN
				INSERT INTO distribution_params VALUES
					(NEW.name, 'loc'),
					(NEW.name, 'scale')
				;
			WHEN 'Discrete' THEN
				INSERT INTO distribution_params VALUES
					(NEW.name, 'loc')
				;
		END CASE;
		RETURN NULL;
	END
$$;
CREATE TRIGGER insert_common_params
	AFTER INSERT
	ON distributions
	FOR EACH ROW
	EXECUTE PROCEDURE triggers.distributions_insert_common_params()
;

CREATE FUNCTION triggers.distribution_params_protect_common_params_from_delete() RETURNS trigger
	LANGUAGE plpgsql VOLATILE
AS $$
	BEGIN
		CASE get_distribution_distr_type(OLD.distr_type)
			WHEN 'Continuous' THEN
				IF OLD.param_name IN ('loc', 'scale') THEN
					RETURN NULL;
				END IF;
			WHEN 'Discrete' THEN
				IF OLD.param_name = 'loc' THEN
					RETURN NULL;
				END IF;
		END CASE;
		RETURN OLD;
	END
$$;
CREATE TRIGGER protect_common_params_from_delete
	BEFORE DELETE
	ON distribution_params
	FOR EACH ROW
	EXECUTE PROCEDURE triggers.distribution_params_protect_common_params_from_delete()
;


-- Register distributions
CREATE FUNCTION register_distributions(module_name text) RETURNS VOID
	LANGUAGE plpython3u VOLATILE RETURNS NULL ON NULL INPUT
AS $$
	from scipy.stats.distributions import rv_continuous, rv_discrete
	from importlib import import_module
	module = import_module(module_name)
	
	# Workaround for PostgreSQL #8355 bug
	def floatToStr(f):
		if f == float('inf'):
			return 'Infinity'
		elif f == float('-inf'):
			return '-Infinity'
		return str(f)
	
	contDistrPlan = plpy.prepare("INSERT INTO distributions VALUES ($1, $2, 'Continuous', $3, $4, $5)", ["common.name_type", "common.name_type", "double precision", "double precision", "text"])
	discrDistrPlan = plpy.prepare("INSERT INTO distributions VALUES ($1, $2, 'Discrete', $3, $4, $5)", ["common.name_type", "common.name_type", "double precision", "double precision", "text"])
	distrParamPlan = plpy.prepare("INSERT INTO distribution_params VALUES ($1, $2)", ["common.name_type", "common.name_type"])
	
	for (name, value) in module.__dict__.items():
		if isinstance(value, rv_continuous):
			plpy.execute(contDistrPlan, [name, module_name, floatToStr(value.a), floatToStr(value.b), getattr(value, '__doc__', '')])
		elif isinstance(value, rv_discrete):
			plpy.execute(discrDistrPlan, [name, module_name, floatToStr(value.a), floatToStr(value.b), getattr(value, '__doc__', '')])
		else:
			continue
		if value.shapes is not None:
			for param_name in value.shapes.split(','):
				plpy.execute(distrParamPlan, [name, param_name.strip()])
$$;

REVOKE
	EXECUTE
	ON FUNCTION register_distributions(module_name text)
	FROM fidata
	CASCADE
;


SELECT register_distributions('scipy.stats.distributions');
SELECT register_distributions('FIDATA.stat');
