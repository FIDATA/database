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
--                          AGGREGATING FUNCTIONS                            --
-------------------------------------------------------------------------------

INSERT INTO procs.procs (name, proc_type, dbms_proc_namespace, dbms_proc, input_field_class, output_type, description) VALUES
	('open',   'aggr_func', NULL, 'first', 'Flows',  NULL,     ''),
	('high',   'aggr_func', NULL, 'max',   'Flows',  NULL,     ''),
	('low',    'aggr_func', NULL, 'min',   'Flows',  NULL,     ''),
	('close',  'aggr_func', NULL, 'last',  'Flows',  NULL,     ''),
	('number', 'aggr_func', NULL, 'count', 'Stocks', 'pieces', ''),
	('sum',    'aggr_func', NULL, 'sum',   'Stocks', NULL,     '')
;


INSERT INTO procs.proc_input_scales (proc, scale) VALUES
	('open',   'Time'    ),
	('open',   'Ordinal' ),
	('open',   'Interval'),
	('open',   'Ratio'   ),
	('open',   'Absolute'),
	
	('high',   'Ordinal' ),
	('high',   'Interval'),
	('high',   'Ratio'   ),
	('high',   'Absolute'),
	
	('low',    'Ordinal' ),
	('low',    'Interval'),
	('low',    'Ratio'   ),
	('low',    'Absolute'),
	
	('close',  'Time'    ),
	('close',  'Ordinal' ),
	('close',  'Interval'),
	('close',  'Ratio'   ),
	('close',  'Absolute'),
	
	-- 'number' has no input
	
	('sum',    'Ratio'),
	('sum',    'Absolute')
;

-------------------------------------------------------------------------------
