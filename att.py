# to run this server
#  python ~/Sites/att/att.py
# to update EC2 w latest script, go to ~/Sites/att & run:


# to see errors; ssh to the site and then run
# cat /tmp/server.log
# to restart api:  ./startserver.sh
# to config DB:  sudo nano /etc/mysql/my.cnf  to restart:  sudo service mysql restart
# to restart DB see:  http://www.cyberciti.biz/faq/install-mysql-server-5-on-ubuntu-linux/

from datetime import datetime
from time import time
import json, MySQLdb, MySQLdb.cursors
	# from MySQLdb import _mysql

# from:  http://mysql-python.sourceforge.net/MySQLdb.html#mysqldb
# can use named params as:
# (user="deweyg",host="127.0.0.1",port=3306,passwd="moonpie",db="thangs")

# db exceptions listed here:  http://www.tutorialspoint.com/python/python_database_access.htm
# evn_event_notification is a CLIENT only table  (its only on server as a template for client); no data there

# app.config.pyfile(app.root_path+'/papi_settings.cfg', silent=False)
# read vals with app.config['UC_VAL_NAME'] -- app.config['DEBUG']

import logging
import logging.handlers

def dbConnect(db={}):
	try:  # prod / deploy db user is:  cc_app  w pw=88cc_app77
		# dbhost = app.config['DBHOST']
		# dbuser = app.config['DBUSER']
		# dbpw = app.config['DBPW']
		# dbname = app.config['DBNAME']
		
		conn = MySQLdb.connect(host='localhost', user='deweyg', passwd='zebra10', db='att', conv={FIELD_TYPE.LONG: int}, init_command='set autocommit=1;')
		# copy conn at bottom of file
		# conn.cursor() returns rows as tuples
		# conn.cursor(MySQLdb.cursors.DictCursor)
		cur = conn.cursor(MySQLdb.cursors.DictCursor) # returns rows as dictionaries
			# cur.execute('set autocommit=1;')
			# cur.callproc('cmn.init_session',(0,))
			# cur.nextset()
	except MySQLdb.Error, e:
		print "Error %d: %s" % (e.args[0], e.args[1])
		exit (e)
	
	db.conn = conn
	db.cur = cur
	return db

global db = dbConnect()

	
# an "entity_type" is basically a table in another schema
# a "domain" is a grouping of attributes  (user_prefs_ui_agent, user_prefs_ui_sup, user_prefs_security, )
	# attributes at SOME domains can be created on the fly by the app
# an "entity" is the abstract pointer for "entity_type"  (cols:  xxx_id, ety_id, encode, com_id)
# an "attribute" is something that stores a value in the named domain; each att contains the following:
# 	name, [listOfIncludedDomains], isLong, encrypt, [perDomainDataType]
# a "data_type" is the kind of value stored in an attribute
# val_value is the actual value stored for this entity, for this attribute, in this domain
# every call requires:  company_id, domain, attribute, value

# expectedDomains = ['company', 'companyPref', 'role', 'user', 'userPref']
# atts = [{}, {}, {}, {}, {}]

	def call(procName, paramsAsSequence):
		db.cur.callproc('att.'+ procName, paramsAsSequence)
		allSets = []
		count = 0
		results = db.cur.fetchall()
		while results:
			allSets[count] = results
			db.cur.nextset()
			results = db.cur.fetchall()
			count += 1
		return allSets
		
	def sqlExec(query):
		return db.cur.execute(query)

	def sqlFetchAll(query):
		sqlExec(query)
		return db.cur.fetchall()
			
	def sqlFetchRow(query):
		sqlExec(query)
		return db.cur.fetchone() # returns None when no more rows to fetch
	
	def sqlFetchValue(query):
		return sqlFetchRow(query)[0].values()[0]
		
	def validate(val_type, val_name):
		'''make sure that name is a valid rec in type'''
		return True
	
	def isValidEntityType(entity_type):
		return sqlFetchValue("Select ety_id from ety_entity_type where ety_name = '{0}';".format(entity_type))

	def isValidDomain(domain):
		return sqlFetchValue("Select dom_id from dom_domain where dom_name = '{0}';".format(domain))

	def loadEntity(instance, id):
		instance._data = sqlFetch(instance.type_id, id)
		instance.id = instance._data.ent_xxx_id
		if instance.id is None or instance.id <= 0:
			raise ValueError
		return instance

class Entity:
	'''returns an entity obj for which you can get & set attributes
	
	user = Entity('user', company_id=3, id=45)
	user.domains()  #prints list of domains for which "user" attributes exists
			eg:  preferences, privileges, ui_colors, etc
	user.atts('' or 'preferences') #prints list of atts in named domains (or all if dom param empty)
			eg: auto_signout_interval, 
	user.setAtts('preferences', {auto_signout_interval: 3600}, keepVersion=True)
	user.getAtts('preferences', [auto_signout_interval, display_handle])  #empty list returns all
	
	max att size = 16 mb
	'''
	allInstances = {} # list of created instances; class var
	
	def __init__(self, entity_type, company_id, id=0):
		# type_id = isValidEntityType(entity_type)
		# if type_id is None or type_id < 1:
		# 	raise Error
		# self.type_id = type_id
		self.type = entity_type
		self.company_id = company_id
		loadEntity(self, id) # stores other cols on self/instance._data
		allInstances.setdefault(self, True) # keep track of created instances for destruction in cleanUp() below

	def domains():
		''''''
		
		
	def atts(domain = ''):
		''''''
		
	def setAtts(self, domain, att_dict, keepVersion=True):
	
	def getAtts(self, domain, att_dict = {}): # empty dict means all
		"""retrieve atts for an entity
		
		getAtts(domain, att_dict = {dob=True,facebookHandle=True})
		returns a dictionary of lists (value, datatype, version, isMissing, isLong, isEncrypted)
			empty or "all" in domain (P1) means: get atts for all domains
			empty dict (P2) means all atts for the specified domains
		"""
	def clearAtts(self):
		
	def getHistory(self):
		
	@classmethod
	def cleanUp(cls):
		# for k, v in allInstances:
		
class Admin:
	
def addDomain(name='companyPref', atts=None, company=0):  # classes and their atts are system global unless company passed in
	
	
def addAttsToDomain(name='companyPref', atts=None, company=0):
	
	
def addObject(domain='companyPref', objID=None, objName='', atts=None, company=0):
	
	
def setObjectAtts (domain='', objID=None, atts=None, company=0): #addAttsToObject


def getObjectAtts(domain='', objID=None, atts=None, company=0):
	
	
def listObjects(domain='companyPref', company=0, atts=None):
	
	

@app.route('/')
@app.route('/status/')
def hello_world():
	#return "Hello Terra {0} ".format('girl')
	# sqlExec("select 1, 2, 3, DATE_FORMAT(Now(),'%Y-%m-%d %H:%i:%s') AS DtAdded;")
	# resp = db.cur.fetchone()
	return jsonify({'results': 'Minggl API confirmed!','status':'ok'})

@app.route('/error/') # to test throwing an err & getting msg
def testErrorEmail():
	try:
		1/0
	except:
		app.logger.exception('you should get this email')
		return jsonify({'results': 'email sent','status':'error'})

@app.route('/hello/<name>')
def hello(name=None):
	# no such template
	return render_template('hello.html', name=name, pic='/static/Icon.jpg')


def requestDataAsDict():
	try:
		if request.method == 'POST':
			# data = json.loads(request.form['data'])
			data = request.json # if mime type is set to application/json
		elif request.method == 'GET':
			data = json.loads(request.args['data'])
	except KeyError:
		data = {'err' : 'nothing found in "data" for get or post'}
	return data # or 'data must have been None'
		
@app.route('/ws/user/create/', methods=['POST'])
def user_create():
	data = requestDataAsDict()
	# print(data)
	# data = {'use_uuid':'888777', 'use_handle':'dewe888777', 'use_first': 'dewey', 'use_last': 'gaed', 'use_email': 'dewey@hello.com', 'use_post_code':78730, 'use_phone': '512-785', 'use_salt': 'gh', 'use_pw': 'north', 'use_birth': '1961-11-08', 'use_city': 'houston', 'use_state': 'tx', 'use_lost_pw_ques': 'dog name', 'use_lost_pw_answ': 'frisky', 'use_sta_id': 0, 'use_typ_id': 111, 'use_mail_list':0, 'use_profile_visib': 1, 'use_msg_notify_encode':33, 'use_encode':0}
	# FIXME  put IGNORE in the insert below after extensive testing
	query = '''INSERT INTO gro.use_user (use_uuid, use_handle, use_first, use_last, use_email, use_post_code, use_phone, use_salt, use_pw, use_birth, use_city, use_state, use_lost_pw_ques, use_lost_pw_answ, use_add_dttm, use_sta_id, use_typ_id, use_mail_list, use_profile_visib, use_msg_notify_encode, use_encode)
	VALUES
	("{use_uuid}", "{use_handle}", "{use_first}", "{use_last}", "{use_email}", "{use_post_code}", "{use_phone}", "{use_salt}", "{use_pw}", "{use_birth}", "{use_city}", "{use_state}", "{use_lost_pw_ques}", "{use_lost_pw_answ}", now(), {use_sta_id}, {use_typ_id}, {use_mail_list}, {use_profile_visib}, {use_msg_notify_encode}, {use_encode});'''
	query = query.format(**data) #['use']
	# print(query)
	sqlExec(query)
	query = """Select use_id from gro.use_user where use_uuid = '{use_uuid}';"""
	query = query.format(**data)
	# print(query)
	# query = """Select LAST_INSERT_ID() as use_id;""" # dont use this in case already inserted and fails (ignore) above
	sqlExec(query)
	use_id = db.cur.fetchone() #or {'use_id':0}  #FIXME after testing
	# print(use_id)
	return jsonify({'use_id': use_id['use_id'], 'use_uuid': data['use_uuid']})

@app.route('/ws/user/update/', methods=['POST'])
def user_update():
	data = requestDataAsDict()
	# calc a unique handle
	# data['use_handle'] = returnUniqueHandle(data['use_id'], data['use_handle'])
	
	query = '''UPDATE use_user
	SET use_handle = "{use_handle}", use_first = "{use_first}", use_last = "{use_last}"
	, use_email = "{use_email}", use_post_code = "{use_post_code}", use_phone = "{use_phone}"
	, use_pw = "{use_pw}", use_birth = "{use_birth}", use_city = "{use_city}"
	, use_state = "{use_state}", use_image_uri = "{use_image_uri}", use_lost_pw_ques = "{use_lost_pw_ques}"
	, use_lost_pw_answ = "{use_lost_pw_answ}", use_sta_id = {use_sta_id}, use_typ_id = {use_typ_id}
	, use_mail_list = {use_mail_list}, use_profile_visib = {use_profile_visib}
	, use_msg_notify_encode = {use_msg_notify_encode}, use_encode = {use_encode}
	WHERE use_id = {use_id};'''
	query = query.format(**data)
	# if any vals were not passed, there will be strs like {col_name} left in the sql
	# change it to col = col  (aka change nothing)
	query = query.replace('"{','')
	query = query.replace('}"','')
	query = query.replace('{','') # do same for unquoted strs
	query = query.replace('}','')
	sqlExec(query)
# /ws/user/update/	

@app.route('/ws/user/lookup/', methods=['POST'])
def user_lookup():
	'''takes method and value and finds user details'''
	data = requestDataAsDict()
	print('cc just searched on ' + data['value'])
	# use_lookup(p_use_id, p_meth_id, p_srchVal, p_encode)
	db.cur.callproc('gro.use_lookup', (data['use_id'], data['method'], data['value'], 0))
	# returns:  use_id, use_handle, use_first, use_last, use_email, use_post_code, use_phone
	# 	, use_birth, use_city, use_state, use_image_uri
	userRec = db.cur.fetchone() or {'use_id':0}
	print('and found user_id=' + str(userRec['use_id']))
	db.cur.nextset()
	return jsonify({'results' : userRec})
# /ws/user/lookup/
	

@app.route('/ws/user/ic/getUpdates/', methods=['POST'])
def list_recentFlockSharedEvents():
	# load all event recs that girls in my flock have shared w server
	# since my last sync
	# then I'll need to load their responses to my events as well
	data = requestDataAsDict() # should contain data to create/update inner circle list
	user_id = int(data["use_id"]) # int(data["use_id"])
	last_sync = datetime.fromtimestamp(data["last_sync"]) # this is a unixtime in secs
	last_sync = last_sync.strftime("%Y-%m-%d %H:%M:%S")
	# print('last_sync:')
	# print(last_sync)
	query = '''SELECT STRAIGHT_JOIN
		E.eve_id, E.eve_use_id, E.eve_beh_id, E.eve_per_id
		, E.eve_per_nickname, E.eve_ven_id, E.eve_glo_id
		, UNIX_TIMESTAMP(E.eve_occur_dttm) as eve_occur_dttm
		, UNIX_TIMESTAMP(E.eve_add_dttm) as eve_add_dttm, E.eve_scale
		, E.eve_note, E.eve_notifyPrefs, (E.eve_encode|8) as eve_encode
		, E.eve_resp_pref_typ_id 
	FROM gro.inc_inner_circle I
	JOIN gzt.eve_event E
	ON E.eve_use_id = I.inc_dst_use_id and E.eve_add_dttm > "{0}"
	-- JOIN gro.per_person P ON P.per_id = E.eve_per_id 
	WHERE I.inc_src_use_id = {1} ;'''
	query = query.format(last_sync, user_id)
	# print(query)
	sqlExec(query)
	results = {}
	results["updates"] = db.cur.fetchall() or {}
	# print('int(time()):')
	# print(int(time()))
	results["serverTime"] = int(time())  # secs since epoch
	db.cur.nextset()
	results["responses"] = getResponses(user_id, last_sync)
	# print(results)
	return jsonify({'results': results})
# /ws/user/ic/getUpdates/

@app.route('/ws/user/ic/getResponses/', methods=['POST'])
def getResponses_from_innercircle():
	# niu;  data returned in getUpdates above
	data = requestDataAsDict()
	user_id = int(data['use_id'])
	last_sync = datetime.fromtimestamp(data["last_sync"]) # this is a unixtime in secs
	last_sync = last_sync.strftime("%Y-%m-%d %H:%M:%S")
	results = {}
	results["responses"] = getResponses(user_id, last_sync)
	results["serverTime"] = int(time())
	return jsonify({'results': results})
# /ws/user/ic/getResponses/	

db=MySQLdb.connect(host='localhost', user='deweyg', passwd='zebra10', db='gro', conv={ FIELD_TYPE.LONG: int })
	# attempt initial connection to confirm db available at server start
if __name__ == '__main__':
	# host = app.config['HOST']
	# port = app.config['PORT']
	# debug = app.config['DEBUG']
	app.run(host="ec2-107-21-98-73.compute-1.amazonaws.com", port=5000, debug=True) # app.run()