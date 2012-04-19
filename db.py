# from db import connect, call, sqlExec, sqlFetchAll, sqlFetchRow, sqlFetchValue

import MySQLdb, MySQLdb.cursors
from MySQLdb.constants import FIELD_TYPE
	# http://www.mikusa.com/python-mysql-docs/docs/MySQLdb.constants.FIELD_TYPE.html
	# from MySQLdb import _mysql

# from:  http://mysql-python.sourceforge.net/MySQLdb.html#mysqldb
# can use named params as:
# (user="deweyg",host="127.0.0.1",port=3306,passwd="moonpie",db="thangs")

# db exceptions listed here:  http://www.tutorialspoint.com/python/python_database_access.htm
# evn_event_notification is a CLIENT only table  (its only on server as a template for client); no data there
db = {}
cur = 0

def connect():
	global db, cur, FIELD_TYPE
	try:  # prod / deploy db user is:  cc_app  w pw=88cc_app77
		# dbhost = app.config['DBHOST']
		# dbuser = app.config['DBUSER']
		# dbpw = app.config['DBPW']
		# dbname = app.config['DBNAME']

		conn = MySQLdb.connect(host='localhost', user='deweyg', passwd='zebra10', db='att'
			# , conv={FIELD_TYPE.LONG: int, FIELD_TYPE.TINY: int} # defaults are better here
			, cursorclass=MySQLdb.cursors.DictCursor
			, init_command='set autocommit=1;')
		conn.commit() # clear out anything lingering unsaved
		# copy conn at bottom of file
		# conn.cursor() # returns rows as tuples
		# conn.cursor(MySQLdb.cursors.DictCursor) # returns rows as dictionaries

		cur = conn.cursor(MySQLdb.cursors.DictCursor)
		# cur.execute('set autocommit=1;')
		cur.callproc('up_SessInit_Connect',(0,))
		cur.nextset() # get rid of any lingering results
		
		# test = sqlFetchAll('SHOW variables;')
		# print(test)
		
	except MySQLdb.Error, e:
		print "Error %d: %s" % (e.args[0], e.args[1])
		exit (e)
		
	db["conn"] = conn
	db["cur"] = cur
	# cur.callproc('spTest', (1,))
	return conn, cur

def fetchAll(): # returns results from last query or sp call
	return cur.fetchall()
		
def call(procName, paramsAsSequence):
	global cur
	cur.callproc(procName, paramsAsSequence)  # 'att.'+ procName
	allSets = list()
	results = fetchAll()
	# print('abv results')
	# print(results)
	while results:
		allSets.append(results)
		cur.nextset()
		results = fetchAll()
	if len(allSets) == 1:
		allSets = allSets[0] # return the tuple for 1st result set if only 1
	return allSets # either a list of tuples (mult results) or one tuple (1 result set)

def sqlExec(query):
	global cur
	# print('abt to execute:')
	# print(query)
	return cur.execute(query)
	
def sqlFetchAll(query):
	global cur
	sqlExec(query)
	return fetchAll()

def sqlFetchRow(query):
	global cur
	sqlExec(query)
	return cur.fetchone() # returns None when no more rows to fetch

def sqlFetchValue(query):
	return sqlFetchRow(query).values()[0]