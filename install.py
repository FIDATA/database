#!/usr/bin/env python
# -*- coding: utf-8 -*-

# FIDATA. Open-source system for analysis of financial and economic data
# Copyright © 2012-2013  Basil Peace

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


import FIDATA.Engine as engine
engine.initArgParser('Installer of database structure', defLogFilename = 'install.log')
engine.argParser.add_argument('--disable-clear',
	dest = 'clear', action = 'store_false',
	help = "don't clear database structure (only for clean end-user installation, saves some time)"
)
engine.argParser.add_argument('--disable-tests',
	dest = 'tests', action = 'store_false',
	help = "don't run tests"
)
engine.argParser.add_argument('--disable-predefined-data',
	dest = 'predefinedData', action = 'store_false',
	help = "don't import predefined data"
)
engine.connect(asAdmin = True)

import logging
from os import path
srcDir = path.split(path.abspath(__file__))[0]
scripts = [
	'epic/epic.sql',
	
	'pre.sql',
	
	'common.sql',
	
	'intl.sql',
	'fin-system.sql',
	
	'data-sets.sql',
	'data-sets.tools.sql',
	'procs.sql',
	'data-sets.data-set-fields.sql',
	
	'portfolios.sql',
	'trade-systems.sql',
	
	'distributions.sql',
	
	'data-sets.data.sql',
	'procs.comp-field-functions.sql',
	'procs.aggr-functions.sql',
	'procs.dyn-show-functions.sql',
	'procs.window-functions.sql',
	
	'data-sets.convertors.sql',
	
	'test/test.common.sql',
	'test/test.intl.sql',
	'test/test.fin-system.sql',
	'test/test.data-sets.sql',
	'test/test.procs.sql',
	
	'post.sql',
	
	# Internationalization
	'intl/intl.intl.sql',
	'intl/fin-system.intl.sql',
	
	# TODO: Move it before our own tests (problem with search path)
	'epic/test/test_asserts.sql',
	'epic/test/test_core.sql',
	'epic/test/test_globals.sql',
	'epic/test/test_results.sql',
	'epic/test/test_timing.sql',
]

if engine.args.clear:
	scripts.insert(0, 'clear.sql')

cursor = engine.conn.cursor()

for script in scripts:
	logging.info('Importing {:s}'.format(script))
	# TODO: psycopg2 methods of import script?
	file = open(path.join(srcDir, script), mode = 'r')
	scriptText = file.read()
	del file
	cursor.execute(scriptText)
	del scriptText
engine.commit()

if engine.args.tests:
	logging.info('Running tests')
	
	modules = [
		'common',
		'intl',
		'fin-system',
		'data-sets',
		'procs',
	]
	
	# Ensure that there is enough space for test's name during output
	cursor.execute("SELECT typlen from pg_type where oid = 'name'::regtype")
	formatStr = '{0:<'+str(cursor.fetchone()[0])+'s}{1:s}'
	
	for module in modules:
		logging.info('TESTING MODULE: {:s}'.format(module))
		logging.info(formatStr.format('name', 'result'))
		cursor.execute("SELECT name, result, errcode, errmsg FROM test.run_module(%s)", (module,))
		for row in cursor:
			logging.info(formatStr.format(*row))
			if row[2] != '' or row[3] != '':
				logging.info('Error code: {2:s}\nError message: {3:s}'.format(*row))
	del formatStr

del cursor, engine.conn

# Import of predefined data
if engine.args.predefinedData:
	logging.info('Importing predefined data')
	from subprocess import call
	callArgs = ['python', 'import.py', '--log-filename', engine.args.logFilename]
	if engine.args.devDatabase:
		callArgs.append('--use-dev-database')
	res = call(callArgs, cwd = path.join(srcDir, 'predefined-data'))
	if res != 0:
		exit(res)
