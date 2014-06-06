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


-- Clearing database
DO LANGUAGE plpgsql $$
	DECLARE
		nsp_names name[] = ARRAY['public', 'triggers', 'common', 'procs', 'test', 'ds'];
		nsp_name name;
		nsp_oid oid;
		i RECORD;
	BEGIN
		FOR nsp_name IN SELECT * FROM unnest(nsp_names) LOOP
			RAISE INFO 'Clearing scheme %', nsp_name;
			-- EXECUTE 'DROP SCHEMA IF EXISTS '||quote_ident(nsp_name)||' CASCADE';
			
			SELECT oid FROM pg_namespace WHERE nspname = nsp_name INTO nsp_oid;
			IF NOT FOUND THEN
				CONTINUE;
			END IF;
			
			RAISE INFO 'Deleting procedures';
			FOR i IN
				SELECT
					quote_ident(nsp_name)||'.'||quote_ident(proname)||'('||pg_get_function_identity_arguments(pg_proc.oid)||')' AS proc_signature
				FROM
					pg_proc
				WHERE
					NOT pg_proc.proisagg
					AND (pg_proc.pronamespace = nsp_oid)
			LOOP
				EXECUTE 'DROP FUNCTION IF EXISTS '||i.proc_signature||' CASCADE';
			END LOOP;
			
			-- ToDo: Maybe views should be deleted before functions?
			-- But in this case tables should be deleted before functions too
			RAISE INFO 'Deleting views';
			FOR i IN
				SELECT
					quote_ident(nsp_name)||'.'||quote_ident(viewname) AS viewname
				FROM
					pg_views
				WHERE
					schemaname = nsp_name
			LOOP
				EXECUTE 'DROP VIEW IF EXISTS '||i.viewname||' CASCADE';
			END LOOP;
			
			RAISE INFO 'Deleting tables';
			FOR i IN
				SELECT
					quote_ident(nsp_name)||'.'||quote_ident(tablename) AS tablename
				FROM
					pg_tables
				WHERE
					schemaname = nsp_name
			LOOP
				EXECUTE 'DROP TABLE IF EXISTS '||i.tablename||' CASCADE';
			END LOOP;
			
			RAISE INFO 'Deleting domains';
			FOR i IN
				SELECT
					quote_ident(nsp_name)||'.'||quote_ident(typname) AS typname
				FROM
					pg_type
				WHERE
					(typnamespace = nsp_oid)
					AND (typtype = 'd')
			LOOP
				EXECUTE 'DROP DOMAIN IF EXISTS '||i.typname||' CASCADE';
			END LOOP;
			
			RAISE INFO 'Deleting types';
			FOR i IN
				SELECT
					quote_ident(nsp_name)||'.'||quote_ident(typname) AS typname
				FROM
					pg_type
				WHERE
					(typnamespace = nsp_oid)
					AND (typtype = 'e')
			LOOP
				EXECUTE 'DROP TYPE IF EXISTS '||i.typname||' CASCADE';
			END LOOP;
			
			-- EXECUTE 'CREATE SCHEMA '||quote_ident(nsp_name);
		END LOOP;
	END
$$;
