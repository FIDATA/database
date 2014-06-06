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


-- Clearing PostgreSQL's default privileges for PUBLIC

ALTER DEFAULT PRIVILEGES REVOKE
	ALL PRIVILEGES
	ON FUNCTIONS
	FROM PUBLIC
	CASCADE;

GRANT
	ALL PRIVILEGES
	ON SCHEMA public
	TO fidata_admin;
GRANT
	USAGE
	ON SCHEMA public
	TO fidata;

-- Clearing privileges for fidata

ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE
	ALL PRIVILEGES
	ON TABLES
	FROM fidata
	CASCADE;

ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE
	ALL PRIVILEGES
	ON SEQUENCES
	FROM fidata
	CASCADE;

ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE
	ALL PRIVILEGES
	ON FUNCTIONS
	FROM fidata
	CASCADE;

-- Setting up new privileges

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT
	SELECT, INSERT, UPDATE
	ON TABLES
	TO fidata;

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT
	SELECT, USAGE
	ON SEQUENCES
	TO fidata;

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT
	EXECUTE
	ON FUNCTIONS
	TO fidata;


DO LANGUAGE plpgsql $$
	BEGIN
		CREATE SCHEMA triggers;
	EXCEPTION
		WHEN duplicate_schema THEN
			NULL;
	END;
$$;

GRANT
	ALL PRIVILEGES
	ON SCHEMA triggers
	TO fidata_admin;

ALTER DEFAULT PRIVILEGES IN SCHEMA triggers GRANT
	EXECUTE
	ON FUNCTIONS
	TO fidata;
