from att import Entity

company_id = 22
curUser_id = 333

user333Atts = Entity('user', company_id, curUser_id) # new attribute obj for this user

attsToStore = {'name': {'value': 'johnP'}
			, 'handle': {'value': '@johnParker', 'domain': 'identity'}
			, 'age': {'value': 26}
			, 'access': {'value': '0'}
			, 'dob': {'value': '1982-01-14'}}

# all (except for "handle") stored in the "attribute" domain
user333Atts.setAtts('attribute', attsToStore) 

egOverrideKeepOld = {'value': 'johnnyP', 'keepOld': 1}
egOverrideDomain = {'domain': 'privilege', 'value': '1'}

attsToUpdate = {'name': egOverrideKeepOld # remember prior value in history
			, 'age': {'value': 32}
			, 'dob': {'value': '1984-04-10'}
			, 'access': egOverrideDomain} # this att stored under "privilege" domain
			# all others stored under the "attribute" domain
			
user333Atts.setAtts('attribute', attsToUpdate, 0) # 0 means DON'T archive old vals
# but "name" will be archived because overriden

prefsToStore = {'autoLogoffInterval': {'value': 15}, 'userHandle': {'value': 'IamBob'}, 'buttonColor': {'value': '125-30-255'}}
user333Atts.setAtts('preference', prefsToStore)

prefsToUpdate = {'autoLogoffInterval': {'value': 22}, 'userHandle': {'value': 'IamBob222'}, 'listColor': {'value': '120-130-200'}}
user333Atts.setAtts('preference', attsToStore, 1) # keep old vals


allAttributeVals = user333Atts.getAtts('attribute')

prefsToFetch = ['autoLogoffInterval', 'listColor']
partialPreferenceVals = user333Atts.getAtts('preference', prefsToFetch)

print('allAttributeVals')
print(allAttributeVals)
print('')
print('partialPreferenceVals')
print(partialPreferenceVals)