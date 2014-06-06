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


DO LANGUAGE plpgsql $$
	DECLARE
		db name := quote_ident(current_database());
	BEGIN
		EXECUTE '
			REVOKE
				ALL PRIVILEGES
				ON DATABASE '||db||'
				FROM PUBLIC
				CASCADE;
			GRANT
				ALL PRIVILEGES
				ON DATABASE '||db||'
				TO fidata_admin;
			GRANT
				CONNECT, TEMPORARY
				ON DATABASE '||db||'
				TO fidata;
		';
	END
$$;

