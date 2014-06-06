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


CREATE DOMAIN id_type bigint;

-- WARNING: regtype doesn't store type modifiers, so for dbms_type domains should be used!
INSERT INTO types (name, scale, dbms_type, diff_type, foreign_table, foreign_column) VALUES
	('time_interval',  'Ratio',    'time_interval',    NULL           , NULL,      NULL),
	('time_moment',    'Time',     'time_moment',      'time_interval', NULL,      NULL),
	('deal_direction', 'Nominal',  'deal_direction',   NULL           , NULL,      NULL),
	('id',             'Nominal',  'id_type',          NULL           , NULL,      NULL),
	('ticker_id',      'Nominal',  'bigint',           NULL           , 'tickers', 'id'),
	('order_action',   'Nominal',  'order_action',     NULL           , NULL,      NULL),
	('price',          'Ratio',    'price_type',       NULL           , NULL,      NULL),
	('pieces',         'Absolute', 'pieces_type',      NULL           , NULL,      NULL),
	('amount',         'Ratio',    'amount_type',      NULL           , NULL,      NULL),
	('ratio',          'Absolute', 'double precision', NULL           , NULL,      NULL),
	('ln_ratio',       'Absolute', 'double precision', NULL           , NULL,      NULL)
;


INSERT INTO fields (name, data_type, ts_type, field_class) VALUES
	('moment',         'time_moment',    'Moment',  'Time'  ), -- Time scale
	
	('ticker',         'ticker_id',      'Object',  NULL    ), -- Nominal scale
	
	('order_id',       'id',             'Object',  NULL    ), -- Nominal scale
	('order_action',   'order_action',   'Object',  NULL    ), -- Nominal scale
	('order_price',    'price',          'Object',  NULL    ), -- Ratio scale
	
	('deal_id',        'id',             'Object',  NULL    ), -- Nominal scale
	('deal_direction', 'deal_direction', 'Object',  NULL    ), -- Nominal scale
	
	('ask_price',      'price',          'Moment',  'Flows' ), -- Ratio scale
	('bid_price',      'price',          'Moment',  'Flows' ), -- Ratio scale
	('spread',         'price',          'Moment',  'Flows' ), -- Ratio scale
	('mid_price',      'price',          'Moment',  'Flows' ), -- Ratio scale
	
	('price',          'price',          'Moment',  'Flows' ), -- Ratio scale
	('volume',         'pieces',         'Object',  'Stocks'), -- Absolute scale
	('amount',         'amount',         'Moment',  'Stocks'), -- Absolute scale
	('adj_price',      'price',          'Moment',  'Flows' ), -- Ratio scale
	('open_positions', 'pieces',         'Moment',  'Flows' )  -- Absolute scale
;


INSERT INTO object_types (name) VALUES
	('Order'),
	('Deal')
;


INSERT INTO object_fields (object_type, field) VALUES
	('Order', 'ticker'        ),
	('Order', 'order_id'      ),
	('Order', 'deal_direction'),
	('Order', 'order_action'  ),
	('Order', 'order_price'   ),
	('Order', 'volume'        ),
	('Order', 'deal_id'       ),
	('Order', 'price'         ), -- price of deal
	
	('Deal',  'ticker'        ),
	('Deal',  'deal_id'       ),
	('Deal',  'deal_direction'),
	('Deal',  'price'         ), -- price of deal
	('Deal',  'volume'        )
;


INSERT INTO timeframes (id, timefield, quantity) VALUES
	('1s',  'second', 1),
	('2s',  'second', 2),
	('3s',  'second', 3),
	('4s',  'second', 4),
	('5s',  'second', 5),
	('6s',  'second', 6),
	('10s', 'second', 10),
	('12s', 'second', 12),
	('15s', 'second', 15),
	('20s', 'second', 20),
	('30s', 'second', 30),
	
	('1m',  'minute', 1),
	('2m',  'minute', 2),
	('3m',  'minute', 3),
	('4m',  'minute', 4),
	('5m',  'minute', 5),
	('6m',  'minute', 6),
	('10m', 'minute', 10),
	('12m', 'minute', 12),
	('15m', 'minute', 15),
	('20m', 'minute', 20),
	('30m', 'minute', 30),
	
	('1h',  'hour',   1),
	('2h',  'hour',   2),
	('3h',  'hour',   3),
	('4h',  'hour',   4),
	('6h',  'hour',   6),
	('8h',  'hour',   8),
	('12h', 'hour',   12),
	
	('1D',  'day',    1),
	
	('1W',  'day',    7),
	
	('1M',  'month',  1),
	('2M',  'month',  2),
	('1Q',  'month',  3),
	('4M',  'month',  4),
	('1S',  'month',  6),
	('1Y',  'year',   1)
;
