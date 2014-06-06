#!/usr/bin/env python
# -*- coding, utf-8 -*-

# FIDATA. Open-source system for analysis of financial and economic data
# Copyright © 2013  Basil Peace

# This file is part of FIDATA.
#
# FIDATA is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# FIDATA is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with FIDATA.  If not, see <http://www.gnu.org/licenses/>.


from FIDATA import *
initArgParser('Importer of predefined data', defLogFilename = 'import.log')
initFIDATA()

from csv import DictReader
from os import path
from PIL import Image

classes = []

logging.info('Import of predefined data started')

# logging.info('Importing langs')
# reader = DictReader(open('langs.csv', 'r', encoding = 'UTF8'), delimiter = ';')
# for row in reader:
	# Lang(FIDATA, row = row, write = True, tryGetFromDB = False)
# del reader
# commit()
# classes += [Lang]

logging.info('Importing scripts')
reader = DictReader(open('scripts.csv', 'r', encoding = 'UTF8'), delimiter = ';')
for row in reader:
	Script(FIDATA, row = row, write = True, tryGetFromDB = False)
del reader
commit()
classes += [Script]

logging.info('Importing countries')
reader = DictReader(open('countries.csv', 'r', encoding = 'UTF8'), delimiter = ';')
for row in reader:
	# parent_country
	# associated_with
	if row['alpha2_code'] == '':
		row['alpha2_code'] = None
	else:
		flagFilename = 'flags\{:s}.png'.format(row['alpha2_code'].lower())
		if path.exists(flagFilename):
			row['flag'] = Image.open(flagFilename)
			
	if row['gov_website'] == '':
		row['gov_website'] = None
	if row['stats_website'] == '':
		row['stats_website'] = None
	FIDATA.country(row = row, write = True, tryGetFromDB = False)
del reader
commit()
classes += [Country]

# logging.info('Importing issuers')
# reader = DictReader(open('issuers.csv', 'r', encoding = 'UTF8'), delimiter = ';')
# for row in reader:
	# FIDATA.issuer(row = row, write = True, tryGetFromDB = False)
# del reader
# commit()
# classes += [Issuer]

# logging.info('Importing currencies')
# reader = DictReader(open('currencies.csv', 'r', encoding = 'UTF8'), delimiter = ';')
# for row in reader:
	# row['instr_type'] = InstrumentType.Currency
	# FIDATA.instrument(row = row, write = True, tryGetFromDB = False)
# del reader
# commit()

# logging.info('Importing instruments')
# reader = DictReader(open('instruments.csv', 'r', encoding = 'UTF8'), delimiter = ';')
# for row in reader:
	# FIDATA.instrument(row = row, write = True, tryGetFromDB = False)
# del reader
# commit()

# classes += [Instrument]

logging.info('Importing markets')
reader = DictReader(open('markets.csv', 'r', encoding = 'UTF8'), delimiter = ';')
child_markets = list()
for row in reader:
	if row['country_alpha2_code'] == '':
		row['country'] = None
	else:
		row['country'] = FIDATA.country(row = {
			'alpha2_code': row['country_alpha2_code'],
			'name'       : row['country_name']
		})
	if row['acronym'] == '':
		row['acronym'] = None
	if row['website'] == '':
		row['website'] = None
	if row['trade_organizer_symbol'] == '':
		FIDATA.market(row = row, write = True, tryGetFromDB = False)
	else:
		child_markets.append((FIDATA.market(row = row, write = False, tryGetFromDB = False), row['trade_organizer_symbol']))
del reader
for (market, trade_organizer_symbol) in child_markets:
	market.tradeOrganizer = FIDATA.market(row = {'symbol': trade_organizer_symbol})
	market.write()
del child_markets
commit()
classes += [Market]

logging.info('Importing data providers')
reader = DictReader(open('data_providers.csv', 'r', encoding = 'UTF8'), delimiter = ';')
for row in reader:
	if row['trade_organizer_symbol'] == '':
		row['trade_organizer'] = None
	else:
		row['trade_organizer'] = FIDATA.market(row = {'symbol': row['trade_organizer_symbol']})
	FIDATA.dataProvider(row = row, write = True, tryGetFromDB = False)
del reader
commit()
classes += [DataProvider]

logging.info('Import of predefined data finished')

FIDATA.analyze(classes)
