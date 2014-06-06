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
--                             WINDOW FUNCTIONS                              --
-------------------------------------------------------------------------------

INSERT INTO procs.procs (name, proc_type, dbms_proc_namespace, dbms_proc, output_type, description) VALUES
	('Count',  'window_func', NULL, 'count',       'pieces', ''),
--	('Mo',     'window_func', NULL, '',            NULL,     ''),
--	('Qntl',   'window_func', NULL, '',            NULL,     ''),
--	('Me',     'window_func', NULL, '',            NULL,     ''),
	('Max',    'window_func', NULL, 'max',         NULL,     ''),
	('Min',    'window_func', NULL, 'min',         NULL,     ''),
	('Mean',   'window_func', NULL, 'avg',         NULL,     ''),
	('Var',    'window_func', NULL, 'var_samp',    NULL,     ''), -- TODO: output_type is price_type^2
	('StdDev', 'window_func', NULL, 'stddev_samp', NULL,     '')  -- TODO: use c4 coefficient
--	('Skew',   'window_func', NULL, '',            'ratio',  ''),
--	('Kurt',   'window_func', NULL, '',            'ratio',  ''),
--	('Ex',     'window_func', NULL, '',            'ratio',  ''),
--	('GMean'   'window_func', NULL, '',            NULL,     '')
;


INSERT INTO procs.proc_input_scales (proc, scale) VALUES
/*
	('Mo',     'Nominal' ),
	('Mo',     'Ordinal' ),
	('Mo',     'Interval'),
	('Mo',     'Ratio'   ),
	('Mo',     'Absolute'),
	          
	('Qntl',   'Ordinal' ),
	('Qntl',   'Interval'),
	('Qntl',   'Ratio'   ),
	('Qntl',   'Absolute'),
	          
	('Me',     'Ordinal' ),
	('Me',     'Interval'),
	('Me',     'Ratio'   ),
	('Me',     'Absolute'),
*/	
	('Max',    'Ordinal' ),
	('Max',    'Interval'),
	('Max',    'Ratio'   ),
	('Max',    'Absolute'),
              
	('Min',    'Ordinal' ),
	('Min',    'Interval'),
	('Min',    'Ratio'   ),
	('Min',    'Absolute'),

	
	('Mean',   'Interval'),
	('Mean',   'Ratio'   ),
	('Mean',   'Absolute'),
	
	('Var',    'Interval'),
	('Var',    'Ratio'   ),
	('Var',    'Absolute'),
	
	('StdDev', 'Interval'),
	('StdDev', 'Ratio'   ),
	('StdDev', 'Absolute')
/*	
	('Skew',   'Interval'),
	('Skew',   'Ratio'   ),
	('Skew',   'Absolute'),
	          
	('Kurt',   'Interval'),
	('Kurt',   'Ratio'   ),
	('Kurt',   'Absolute'),
	          
	('Ex',     'Interval'),
	('Ex',     'Ratio'   ),
	('Ex',     'Absolute'),
	
	('GMean',  'Ratio'   ),
	('GMean',  'Absolute')
*/
;

-------------------------------------------------------------------------------
