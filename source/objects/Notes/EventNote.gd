##A script to help with Event Notes.
static var eventsFounded: PackedStringArray = []

static func convert_events(events: Array) -> Array:
	var new_events: Array = []
	
	
	for event_data in events:
		var events_array: Array = [event_data[0],[]]
		for event in event_data[1]:
			var event_name = event[0]
			var vars = event[1]
			var properties = get_event_variables(event_name)
			
			if !vars is Dictionary:
				var keys = properties.keys()
				vars = {keys[0]: vars}
				if keys.size() > 1 and ArrayHelper.array_has_index(event,2): vars[keys[1]] = event[2]
			
			for i in properties:
				var default_value = properties[i].default_value
				if vars.has(i): vars[i] = convert_event_type(vars[i],properties[i].type,default_value)
				else: vars[i] = default_value
			
			events_array[1].append([event_name,vars])
		new_events.append(events_array)
	return new_events

static func convert_event_type(value: Variant, type: Variant.Type, default_value: Variant = null):
	if value == null: return MathHelper.get_new_value(type)
	var value_type = typeof(value)
	match type:
		TYPE_NIL: return value
		TYPE_FLOAT,TYPE_INT:
			if value_type == TYPE_STRING and !value and default_value: return default_value
	return type_convert(value,type)
	
static func loadEvents(chart: Array = []) -> Array[Dictionary]:
	eventsFounded.clear()
	var events: Array[Dictionary] = []
	var event_data = convert_events(chart)
	for i in event_data:
		for data in i[1]:
			var event = data[0]
			events.append(
				{
					'strumTime': i[0],
					'event': event,
					'variables': data[1]
				}
			)
			if not event in eventsFounded: eventsFounded.append(event)
			
	events.sort_custom(func(a,b):
		return a.strumTime < b.strumTime
	)
	return events

#region Chart Methods
static var event_variables: Dictionary = {}
static var easing_types: PackedStringArray = []

const default_variables = {
	'value1': {
		'type': TYPE_STRING,
		'default_value': ''
	},
	'value2': {
		'type': TYPE_STRING,
		'default_value': ''
	}
}

static func _static_init() -> void:
	for i in TweenHelper.transitions:
		i = StringHelper.first_letter_upper(i)
		easing_types.append("#"+i)
		if i == 'Linear': easing_types.append("Linear"); continue
		for e in TweenHelper.easings: easing_types.append(i+e)

##Return the variables of the a custom_event using "@vars" in his text.[br]
##The function returns a [Dictionary] that contains an [Array] with its type and its default value.[br][br]
##[b]Example:[/b] [code]{"value1": [TYPE_STRING,''], "value2": [TYPE_FLOAT,0.0]}[/code]
static func get_event_variables(event_name: String) -> Dictionary:
	if event_name in event_variables: return event_variables[event_name]
	var event_data = Paths.loadJson('custom_events/'+event_name+'.json')
	if !event_data or !event_data.has('variables'): return default_variables
	
	var variables: Dictionary = {}
	for i in event_data.variables: variables[i] = _get_value_data(event_data.variables[i])
	event_variables[event_name] = variables
	return variables

static func _get_value_data(value: Dictionary):
	var type = value.get('type','String')

	var value_type: int
	var options: Array = value.get('options',[])
	match type:
		'EasingType':
			options.append_array(easing_types)
			value_type = TYPE_STRING
		_: value_type = MathHelper.type_via_string(type)
		
	var default_value: Variant = value.get('default_value')
	if !default_value or typeof(default_value) != value_type:
		default_value = MathHelper.get_new_value(value_type)
	
	var data = {
		'type': value_type,
		'default_value': default_value
	}

	var look_at = value.get('look_at')
	
	if look_at and look_at.get('directory'):
		var extension = look_at.get('extension','')
		if value.look_at.get('separate_mods'):
			var files_founded = []
			var last_mod: String = ''
			for i in Paths.getFilesAt(look_at.directory,true,extension):
				var file = i.get_file()
				if file in files_founded:
					continue
				var mod = Paths.getModFolder(i)
				if last_mod != mod:
					last_mod = mod
					options.append('#'+mod)
				files_founded.append(file)
				options.append(file)
		else:
			options.append_array(Paths.getFilesAt(look_at.directory,false,extension))
	
	if options:
		data.options = options
	return data
static func _get_property_type(line: String, at: int = 0, replace_to: Dictionary = {}):
	return line.right(-at-1).replace(' ','')

static func _replace_look_at_to_enum(string: String) -> String:
	#Search for "LookAt" types
	var look_at_data = look_for_function_in_line(string,'LookAt')
	var look_at_created = look_at_data[0]
	
	string = look_at_data[1]
	
	var last_mod: String = ''
	for i in look_at_created:
		var data = look_at_created[i]
		var extension = data[1] if data.size() > 1 else ''
		var files = Paths.getFilesAt(data[0],true,extension)
		
		var func_data: String = ''
		
		for f in files:
			var mod = Paths.getModFolder(f)
			if last_mod != mod:
				func_data += ',#'+mod
				last_mod = mod
			func_data += ','+f.get_file()
		string = string.replace(i,'Enum('+func_data.right(-1)+')')
	return string
	
static func look_for_function_in_line(string: String, function: String):
	var index: int = 0
	var functions_created = {}
	
	var function_length = function.length()
	while true:
		index = string.find(function,index)
		if index == -1: break
		
		var index_find = index
		index += function_length
		
		var func_data = string.right(-index-1)
		var func_name = function+str(index)
		
		var variables = func_data.left(StringHelper._find_last_parentese(func_data)+1)
		var variables_array = StringHelper.get_function_data(variables)[1]
		
		functions_created[func_name] = variables_array
		string = string.erase(index_find,function_length+variables.length()+1)
		string = string.insert(index_find,func_name)
	
	return [functions_created,string]
	
static func get_event_description(event_name: StringName) -> String:
	var text = Paths.text('custom_events/'+event_name)
	if !text:
		return ''
	var new_description: String = ''
	for i in text.split('\n'):
		if !i.begins_with('@vars'):
			new_description += i
	return new_description
#endregion
