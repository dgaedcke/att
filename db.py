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
			, conv={FIELD_TYPE.LONG: int, FIELD_TYPE.TINY: int}, cursorclass=MySQLdb.cursors.DictCursor
			, init_command='set autocommit=1;  CREATE TEMPORARY TABLE IF NOT EXISTS _att_stage LIKE _tpl_att_stage;')
		# copy conn at bottom of file
		# conn.cursor() returns rows as tuples
		# conn.cursor(MySQLdb.cursors.DictCursor)
		# dictCursor = conn.cursor(MySQLdb.cursors.DictCursor) # returns rows as dictionaries

			# cur.execute('set autocommit=1;')
			# cur.callproc('cmn.init_session',(0,))
			# cur.nextset()
	except MySQLdb.Error, e:
		print "Error %d: %s" % (e.args[0], e.args[1])
		exit (e)
		
	db["conn"] = conn
	cur = conn.cursor(MySQLdb.cursors.DictCursor)
	db["cur"] = cur

	# print('dictCursor')
	# print(db["cur"])
	
	# db["cur"].callproc('spTest', (1,))
	return conn, cur #db["cur"]
	
def call(procName, paramsAsSequence):
	global cur
	cur.callproc(procName, paramsAsSequence)  # 'att.'+ procName
	allSets = list()
	results = cur.fetchall()
	# print('abv results')
	# print(results)
	while results:
		allSets.append(results)
		cur.nextset()
		results = cur.fetchall()
	return allSets

def sqlExec(query):
	global cur
	return cur.execute(query)

def sqlFetchAll(query):
	global cur
	sqlExec(query)
	return cur.fetchall()

def sqlFetchRow(query):
	global cur
	sqlExec(query)
	return cur.fetchone() # returns None when no more rows to fetch

def sqlFetchValue(query):
	return sqlFetchRow(query)[0].values()[0]