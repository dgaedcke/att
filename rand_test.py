import re

class jsStyleDict(dict):
	'''allows use of js style mapping notation to retrieve dict keys'''
		
	def __getattr__(self, name):
		try:
			return dict.__getitem__(self, name) # = __getitem__
		except KeyError as e:
			return None # raise AttributeError(e)

	def __setattr__(self, name, value):
		if isinstance(value, dict):
			value = jsStyleDict(value)
		# print 'ran set item for {0} = {1}'.format(key,value)
		# self[name] = value
		dict.__setitem__(self, name, value)

class Entity(jsStyleDict):
	'''the built-in __init__ for a dict automatically uses
	dict.update() to populate k/v and so any iterable that returns two
	vals can be passed to the default constructor'''

	def __init__(self, *args, **kwargs):
		super(jsStyleDict,self).__init__(self, *args, **kwargs)
		self.all = {} # dict to hold all unique att names
		
	def __getattr__(self, name): # called only for missing atts
		matchObj = re.match(r'^(\w+)[\b-]?(\w*)',name)
		domain = matchObj.group(1)
		attribute = matchObj.group(2)
		value = None
		if attribute and domain: # passed dom-att
			value = self[domain][attribute]
		elif domain: # passed dom string only
			value = self[domain]
		elif attribute: # passed '-att' name only
			value = self.all[attribute]
		return value
		
	def __setattr__(self, name, value):
		if isinstance(value, (dict,list,tuple)):
			value = jsStyleDict(value)
		self[name] = value # causes running of __setitem__

# nautical = Entity(left = "Port", right = "Starboard") # named args
# 
# nautical2 = Entity({"left":"Port","right":"Starboard"}) # dictionary
# 
# nautical3 = Entity([("left","Port"),("right","Starboard")]) # tuples list

user = Entity()  # fields TBD
# user.pers = {}
# user.pers.bio = {'first':'bob'}
# 
# print user.pers

user.last = 'smith'
user.all.last = 'jones'
print user.all.last

md = {"one": "one"}
md2 = dict()
# md["one"] = 'one'
# md2["one"] = 'one'

# print(md.one) #, md2.one)

# for m in matchObj.groups():
# 	print (m + '|')

# for x in [nautical, nautical2, nautical3, nautical4]:
#     print "{0} <--> {1}".format(x.left,x.right)