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
--                       FUNCTIONS, COMPUTING FIELDS                         --
-------------------------------------------------------------------------------

CREATE FUNCTION procs.price_semisum(x1 price_type, x2 price_type) RETURNS price_type
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN (bid_price + ask_price) / 2;
	END
$$;

CREATE FUNCTION procs.price_add_half_of_spread(x price_type, spread price_type) RETURNS price_type
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN x + spread / 2;
	END
$$;

CREATE FUNCTION procs.price_sub_half_of_spread(x price_type, spread price_type) RETURNS price_type
	LANGUAGE plpgsql STABLE RETURNS NULL ON NULL INPUT
AS $$
	BEGIN
		RETURN x - spread / 2;
	END
$$;


INSERT INTO procs.procs (name, proc_type, dbms_proc_namespace, dbms_proc, output_type, output_field, description) VALUES
	('amount',                             'comp_field_func', NULL,    'float8mul',                'amount', 'amount',    ''),
	('price',                              'comp_field_func', NULL,    'float8div',                'price',  'price',     ''),
	('volume',                             'comp_field_func', NULL,    'float8div',                'pieces', 'volume',    ''),
	
	('spread',                             'comp_field_func', NULL,    'numeric_sub',              'price',  'spread',    ''),
	('bid_price',                          'comp_field_func', NULL,    'numeric_sub',              'price',  'bid_price', ''),
	('ask_price',                          'comp_field_func', NULL,    'numeric_add',              'price',  'ask_price', ''),
	
	('mid_price_from_bid_price_ask_price', 'comp_field_func', 'procs', 'price_semisum',            'price',  'mid_price', ''),
	('mid_price_from_bid_price_spread',    'comp_field_func', 'procs', 'price_add_half_of_spread', 'price',  'mid_price', ''),
	('mid_price_from_ask_price_spread',    'comp_field_func', 'procs', 'price_sub_half_of_spread', 'price',  'mid_price', ''),
	
	('bid_price_from_mid_price_spread',    'comp_field_func', 'procs', 'price_sub_half_of_spread', 'price',  'bid_price', ''),
	('ask_price_from_mid_price_spread',    'comp_field_func', 'procs', 'price_add_half_of_spread', 'price',  'ask_price', '')
;


INSERT INTO procs.proc_input_fields (proc, field_index, field) VALUES
	('amount',                             1, 'price'    ),
	('amount',                             2, 'volume'   ),
	
	('price',                              1, 'amount'   ),
	('price',                              2, 'volume'   ),
	
	('volume',                             1, 'amount'   ),
	('volume',                             2, 'price'    ),
	
	
	('spread',                             1, 'ask_price'),
	('spread',                             2, 'bid_price'),
	
	('bid_price',                          1, 'ask_price'),
	('bid_price',                          2, 'spread'   ),
	
	('ask_price',                          1, 'bid_price'),
	('ask_price',                          2, 'spread'   ),
	
	
	('mid_price_from_bid_price_ask_price', 1, 'bid_price'),
	('mid_price_from_bid_price_ask_price', 2, 'ask_price'),
	
	('mid_price_from_bid_price_spread',    1, 'bid_price'),
	('mid_price_from_bid_price_spread',    2, 'spread'   ),
	
	('mid_price_from_ask_price_spread',    1, 'ask_price'),
	('mid_price_from_ask_price_spread',    2, 'spread'   ),
	
	
	('bid_price_from_mid_price_spread',    1, 'mid_price'),
	('bid_price_from_mid_price_spread',    2, 'spread'   ),
	
	('ask_price_from_mid_price_spread',    1, 'mid_price'),
	('ask_price_from_mid_price_spread',    2, 'spread'   )
;

-------------------------------------------------------------------------------
