# an "entity" is an abstract pointer for a rec of "ety_entity_type"
# 	(cols:  xxx_id, ety_id, encode, com_id)
# an "ety_entity_type" represents a table in another schema
# 	 eg  company, user, case, document, author
# a "dom_domain" is a grouping of related attributes
# 	eg prefs_ui_agent, user_prefs_ui_sup, user_prefs_security
# "att_attribute" is the name of some stored value (think column name)
# 	eg  age, name, dob, hometown
# val_values track the actual column vals;  values are stored at the intersection of:
# 	 ent_entity, att_attribute, dom_domain
# 	val_value is the actual value stored for this entity, for this attribute, in this domain
# attributes at SOME domains can be created on the fly by the EAV system
# a "data_type" is the kind of value stored in an attribute

import re
from types import DictType, StringType, ListType, TupleType, BooleanType, FunctionType
from db import connect, call, sqlExec, sqlFetchAll, sqlFetchRow, sqlFetchValue
conn, cur = connect();

# def validate(val_type, val_name):
# 	'''make sure that name is a valid rec in type'''
# 	return True
# 
# def isValidEntityType(entity_type):
# 	return sqlFetchValue("Select ety_id from ety_entity_type where ety_name = '{0}';".format(entity_type))
# 
# def isValidDomain(domain):
# 	return sqlFetchValue("Select dom_id from dom_domain where dom_name = '{0}';".format(domain))


# I didn't put these functions in the Entity class because I thought that
# some of them might also be used by the Admin class
def loadEntity(instance, xxx_id):
	results = call('att.loadEntity', (instance['type'], xxx_id, instance['company_id'], 0))[0]
	# get 1st row of result tuple
	instance['_entity'] = results
	instance['_all_atts_loaded'] = False
	# print(instance['_entity'])
	instance['id'] = results['ent_id']
	instance['ety_id'] = results['ent_ety_id']
	if instance['id'] is None or instance['id'] <= 0:
		raise ValueError
	return instance

def cacheAtts(instance, attList):
	'''stores atts in a sub-dict ['atts'] of the object'''
	pass # haven't decided how to implement this properly
	instance['atts'] = instance.get('atts') or {}	
	for rec in attList:
		att_name = rec['attribute_name'].lower()
		domain = rec['domain']
		att_value = rec['att_value']
		# mod_dttm = rec['val_mod_dttm']
		# data_type = rec['dty_name']
		# msg = '''att name '{0}' (in '{1}') with val of "{2}" was modified on {3}; type={4}'''.format(att_name, domain, att_value[0:50], mod_dttm, data_type)
		# print(msg)
		instance['atts'][att_name] = att_value
	# print(instance['atts'])

def loadAllAtts(instance, att_names='all'): # , *argsAsSequ
	entVals = instance['_entity']
	attList = call('loadAtts', (entVals['ent_id'], entVals['ent_ety_id'], entVals['ent_com_id'], '', 0, 0) );
	if not attList:
		print('no att vals found')
		attList = tuple()
	instance['_atts_count'] = len(attList[0])
	instance['_all_atts_loaded'] = True
	cacheAtts(instance, attList)
	return len(attList) # instance['atts']

def castNoneAsZero(val):
	'''also casts True as 1'''
	return (val != None) * 1
	
def insertVals(att_name, valsTbl, domain, keepOld):
	'''returns 8 val tuple for the insert stmt in query_insert_atts below
	values in valsTbl take PRECEDENCE over values in P1 & P3
	but NOT P4 (keepOld)...it is global for all rows'''
	# print('key=' + key)
	# print('vals:')
	# print(valsTbl)
	return (valsTbl.get('domain') or domain or ''), (att_name or valsTbl.get('att')), (valsTbl.get('value') or ''), castNoneAsZero(keepOld or valsTbl.get('keepOld')), 0, 0, 0, '0000-00-00'

# query_insert_atts is static string for passing vals
# into sproc storeAtts via setAtts below
query_insert_atts = '''INSERT INTO _att_stage (ats_dom_name, ats_att_name, ats_value, ats_keep_old, ats_is_long, ats_is_multi, ats_hash_it, ats_vers_dttm) VALUES ({0});'''

class Entity(dict): # make it a new style class with base of dictionary
	'''returns an entity obj for which you can get & set attributes
	
	user = Entity('user', company_id=3, id=45)
	user.domains()  #prints list of domains for which "user" attributes exists
			# eg:  preferences, privileges, ui_colors, etc
	user.atts('' or 'preferences') #prints list of atts in named domains (or all if dom param empty)
			# eg: auto_signout_interval, 
	user.setAtts('preferences', {auto_signout_interval: {val: 3600, timestamp: 39349}}, keepOld=True)
	user.getAtts('preferences', [auto_signout_interval, display_handle])  #empty list returns all
	
	max att size = 16 mb
	'''
	
	def __init__(self, entity_type, company_id, xxx_id):
		'''P3 (id) is the ID in some external table;  not ent_entity.ent_id which is internal'''
		assert xxx_id and xxx_id > 0, 'You must pass the external rec_id as P3'
		assert company_id and company_id > 0, 'You must pass the company_id for security reasons'
		dict.__init__(self) # call built in method

		self['type'] = entity_type #['type']
		self['company_id'] = company_id
		# self['atts'] = {} #dict of actual atts retrieved
		# self['_entity'] = {} # place to store the ent_entity rec
		loadEntity(self, xxx_id) # stores other cols on self/instance._data
		
	def __call__(self, domain): # makes instance callable
		# returns all atts within the named domain
		return getAtts(self, domain or 'all')
		# pass
		
	def __getattr__(self, key): # called when an attribute lookup fails
		key = key.lower()
		if not self['_all_atts_loaded']:
			loadAllAtts(self) # must put them in the same place a normal dict would put them
		
		if key not in self['atts']:
			print('attribute "' + key + '" does not exist for this obj')
			
		print('running getattr')
		return self['atts'].get(key) # return loaded value or None	

	def __setattr__(self, name, value):
		# dict.__setattr__(self, name, value)
		self['atts'][name] = value

	def merge(self, other, keep2ndVal):
		for key in other:
			if key not in self['atts'] or keep2ndVal:
				self['atts'][key] = other[key]
	
	def domains(self, entity_type):
		'''returns list of attribute domains for this entity_type'''
		entity_type = entity_type or 'case' # default if no param
		query = '''SELECT STRAIGHT_JOIN D.dom_name
		FROM ety_entity_type T
		JOIN exd_ety_x_domain E ON E.exd_ety_id = T.ety_id
		JOIN dom_domain D ON D.dom_id = E.exd_dom_id
		WHERE ety_name = '{0}';'''.format(entity_type)
		return sqlFetchAll(query)

	def atts(self, domain = ''):
		'''returns list of atts in the named domain (or all)'''
		
		
	def setAtts(self, domain, att_dict, keepOld=False):
		#  str below simulates:  "'{domain}', '{attribute}', '{value}', {keepOld}"...
		# which is based on query_insert_atts
		# insertVals() returns a tuple of 8 values
		# this is a list comprehension
		valuesList = ["'{0[0]}', '{0[1]}', '{0[2]}', {0[3]}, {0[4]}, {0[5]}, {0[6]}, '{0[7]}'".format(insertVals(k, t, domain, keepOld)) for k, t in att_dict.items()]
		insert_vals = '), ('.join(valuesList) # make vals str from list
		insert_vals = query_insert_atts.format(insert_vals)
		# print('------')
		# print(insert_vals)
		# print('------')
		sqlExec(insert_vals) # insert into temp table

		testMode = 0 # set to 16 if you want the sproc to return test results
		# setting to 32 could potentially delete ALL your data
		results = call('storeAtts', (self['id'], self['company_id'], len(valuesList), 1, 1, 1, testMode))
		#  begin test code
		if testMode == 16:
			for row in results:
				for col in row:
					print(col + ' = ' + str(row.get(col) or 'none'))
			print('')
			print('Next Set:')
		# end test code
		return results
		
	def getAtts(self, domain = '', att_list = []): # empty list means all
		"""retrieve atts for an entity
		you can pass simply a comma delim att_name list, or a list of:
		domain:att_name,domain:att_name,
		
		getAtts(domain, att_dict = {'attribute': 'dob', 'attribute': 'facebookHandle', 'preference': 'uiSetting'})
		returns a dictionary of lists (domain_name, attribute_name, value, datatype, mod_dttm, att_id)
			empty or "all" in domain (P1) means: get atts for all domains
			empty dict (P2) means all atts for the specified domains
		"""
		
		if domain in ('all','','ALL'):
			domain = ''
		fld_delim = ':'
		row_delim = ','
		att_names = ''
		att_param_count = 0
		# if not gettina all atts (or all in a given domain), we need to make P4 look like:
		# domain:att_name,domain:att_name,
		if att_list and domain: # both not empty
			param2_type = type(att_list)
			# DictType, StringType, ListType, TupleType
			if param2_type == ListType or param2_type == TupleType:
				# sp_param_type = 'list'
				att_param_count = len(att_list)
				padStr = row_delim + domain + fld_delim
				att_names = padStr.join(att_list)
				att_names = domain + fld_delim + att_names + row_delim
				# print('when att_list is list/tuple, params=' + att_names)

			elif param2_type == DictType:
				# sp_param_type = 'dict'
				att_param_count = len(att_list)
				for dom, att in att_list.items():
					att_names = att_names + dom + fld_delim + att + row_delim
				# print('when att_list is dict, params=' + att_names)
					
			elif param2_type == StringType:
				# sp_param_type = 'string'
				if att_list.find(fld_delim) == -1: # there is only ONE field (att_name) in this string
					# need to add the domain
					for att in att_list.split(row_delim):
						att_param_count = att_param_count + 1
						att_names = att_names + domain + fld_delim + att + row_delim
				# print('when att_list is string, params=' + att_names)
			# P4 should either be a domain name, or a list of domain:att_name, vals
			domain = att_names # end of if stmt
					
		# call loadAtts(p_ent_id, p_ent_ety_id, p_ent_com_id, p_att_list, p_att_count, p_encode);
		attList = call('loadAtts', (self['id'], self['ety_id'], self['company_id'], domain, att_param_count, 0))
		# print(attList)
		cacheAtts(self, attList)
		return attList

	def clearAtts(self, domain, att_list):
		pass
		
	def getHistory(self, domain, attribute):
		pass 
	
class EntitySearch:
	'''locates Entities of a certain type who match specific attribute names & values'''
	def __init__(self, entity_type, company_id):
		self.type = entity_type
		self.company_id = company_id
		
	def strFromParam(att_names_values):
		'''convert dictionary to string & calc # of search vals'''
		numSrchVals = 0
		p2Type = type(att_names_values)
		if p2Type == DictType:
			numSrchVals = len(att_names_values)
			att_names_values = ':'.join(att_names_values)
		# elif p2Type == StringType:
		return att_names_values, numSrchVals
		
	def fetch(self, domain_name, att_names_values):
		# if att_names_values is not formated (ie a dict), i need to make it look like:
		#  name:dewey gaedcke,age:39,dob:11081963,sex:m,'
		# CALL searchForEntity('user', 'attribute', 'name:dewey gaedcke,age:39,dob:11081963,sex:m,', 4, 3, 0);
		
		# att_names_values, value_count = strFromParam(att_names_values)
		value_count = 4
		
		ent_list = call('searchForEntity', (self.type, domain_name, att_names_values, value_count, self.company_id, 0))
		return ent_list # contains list of user ID's who have exact match for att:val in att_names_values
	

# from att import Entity
# x = Entity('user', 33, 66)
# res = x.setAtts('attribute', {'name': {'value': 'Eddie', 'att': 'name', 'domain': 'attribute', 'keepOld': False}, 'age': {'value': 14}, 'hometown':{'value': 'Easton', 'keepOld': True}, 'notes': {'value': 'Earth ****************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************************Earth*******'}}, 1)
# y = x.getAtts()
# y
# x['age']

# print(res[0])


class Admin:
	'''not yet implemented
	to create domains, attributes, data_types, entity_types
	and set data_types for atts in each domain'''
	def addDomain(name='companyPref', atts=None, company=0):
		# classes and their atts are system global unless company passed in
		pass
	
	def addAttsToDomain(name='companyPref', atts=None, company=0):
		pass
	
	def addObject(domain='companyPref', objID=None, objName='', atts=None, company=0):
		pass
	
	def setObjectAtts (domain='', objID=None, atts=None, company=0): #addAttsToObject
		pass

	def getObjectAtts(domain='', objID=None, atts=None, company=0):
		pass
	
	def listObjects(domain='companyPref', company=0, atts=None):
		pass
