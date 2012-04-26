from att import Entity, EntitySearch # main module used for the att storage service
# to support direct queries for printing results below, load db
from db import connect, call, sqlExec, sqlFetchAll, sqlFetchRow, sqlFetchValue

# to delete all stored data (except entities) and start over, run this:
#  call zadm_truncTables(0); -- warning;  this will DELETE all atts and attribute archives

company_id = 22
curUser_id = 333

# the tests below store values for 10 distinct attributes
# in FOUR distinct attribute domains which are:
# ('attribute', 'preference', 'privilege', 'identity')
# attribute called "access" exists in BOTH ('attribute', 'privilege') domains (with sep value in each)

user333Atts = Entity('user', company_id, curUser_id) # new attribute obj for this user

attsToStore = {'name': {'value': 'johnP'}
			, 'handle': {'value': '@johnParker', 'domain': 'identity'}
			, 'age': {'value': 22}
			, 'access': {'value': 'no_way'}
			, 'dob': {'value': '1970-01-14'}}

# all (except for "handle") stored in the "attribute" domain
user333Atts.setAtts('attribute', attsToStore) 

overrideNameAndKeepOld = {'value': 'johnnyP', 'keepOld': 1}
storeDifferentAccessInSepDomain = {'domain': 'privilege', 'value': 'yes_really'}

attsToUpdate = {'name': overrideNameAndKeepOld # remember prior value in history
			, 'age': {'value': 33}
			, 'dob': {'value': '1980-04-10', keepOld:1}
			, 'access': storeDifferentAccessInSepDomain} # this att stored under "privilege" domain
			# all others stored under the "attribute" domain
			
user333Atts.setAtts('attribute', attsToUpdate, 0) # 0 means DON'T archive old (keepOld) vals
# but "name" will be archived because overriden
# and a sep copy of "access" will be stored in the privilege domain

prefsToStore = {'autoLogoffInterval': {'value': 15}, 'userHandle': {'value': 'IamBob'}, 'buttonColor': {'value': '125-30-255'}}
user333Atts.setAtts('preference', prefsToStore)

prefsToUpdate = {'autoLogoffInterval': {'value': 22}, 'userHandle': {'value': 'IamBob222'}, 'listColor': {'value': '100-200-300'}}
user333Atts.setAtts('preference', prefsToUpdate, 1) # 1 means keep/archive old vals

allAttributeVals = user333Atts.getAtts('attribute') # get all atts stored in the "attribute" domain

prefsToFetch = ['autoLogoffInterval', 'listColor']
# get a few (two) values stored in the "preference" domain
partialPreferenceVals = user333Atts.getAtts('preference', prefsToFetch)

print('Entity id={0} and type="{1}"'.format(user333Atts['id'], user333Atts['type']))
print('')
print('all Vals from Attribute domain')
print(allAttributeVals)
print('')
print('partial Vals from Preference domain')
print(partialPreferenceVals)

print('')
print('Everything just stored (assuming you truncated first) is:')
results = sqlFetchAll('SELECT * FROM stored_data where ent_id = 17;')
print(results)

userSearchObj = EntitySearch('user', company_id=3)

usersWithTheseAttVals = userSearchObj.fetch('attribute', 'name:dewey gaedcke,age:39,dob:11081963,sex:m,')
print('usersWithTheseAttVals')
print(usersWithTheseAttVals)

# to see all the data just stored (assuming you truncated first), run:
# SELECT STRAIGHT_JOIN
# 	D.dom_name AS domain, A.att_name AS attribute_name
# 	, COALESCE(L.lva_value, V.val_value) AS att_value
# 	, COALESCE(Y.dty_name,'???') AS data_type
# 	, V.val_mod_dttm AS mod_dttm, V.val_id
# 	, V.val_ent_id AS ent_id
# FROM val_value V 
# JOIN dom_domain D ON D.dom_id = V.val_dom_id
# JOIN att_attribute A ON A.att_id = V.val_att_id
# LEFT OUTER JOIN dxa_dom_x_att M ON M.dxa_dom_id = V.val_dom_id AND M.dxa_att_id = V.val_att_id
# LEFT OUTER JOIN dty_data_type Y ON Y.dty_id = COALESCE(M.dxa_dty_id, A.att_dty_id)
# LEFT OUTER JOIN lva_long_value L ON LEFT(V.val_value,2) = '-1' AND L.lva_val_id = V.val_id
# -- where V.val_ent_id = (Select max(ent_id) from ent_entity)
# ORDER BY ent_id, D.dom_name, A.att_name LIMIT 2000;


#  raw DB test is:
# CALL up_SessInit_Connect(0);
# INSERT INTO _att_stage (ats_dom_name, ats_att_name, ats_value, ats_keep_old, ats_is_long, ats_is_multi, ats_hash_it, ats_vers_dttm) VALUES 
# ('attribute', 'access', '0', 0, 0, 0, 0, '0000-00-00')
# , ('attribute', 'dob', '1982-01-14', 0, 0, 0, 0, '0000-00-00')
# , ('attribute', 'age', '26', 0, 0, 0, 0, '0000-00-00')
# , ('identity', 'handle', '@johnParker', 0, 0, 0, 0, '0000-00-00')
# , ('attribute', 'name', 'johnP', 0, 0, 0, 0, '0000-00-00');
# CALL storeAtts(17, 22, 5, 1,1,1,0); -- entity 17 must exist at comp 22 or won't work