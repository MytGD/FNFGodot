extends Sprite2D
const EventNote = preload("res://source/objects/Notes/EventNote.gd")

var events: Array = []

var strumTime: float = 0.0:
	set(value):
		json_data[0] = value
		strumTime = value

var json_data: Array = [strumTime,[]]:
	set(value):
		json_data = value
		events = json_data[1]
		selectEvent()
		
var event_selected: Array = ['',{}]:
	set(value):
		event_selected = value
		
		if value[1] is Dictionary:
			event_selected_variables = value[1]
		else:
			var dictionary = {
				'value1': value[1],
				'value2': ''
			}
			if value.size() > 2:
				dictionary.value2 = value[2]
				value.remove_at(2)
			value[1] = dictionary
			event_selected_variables = dictionary
		
		event_selected_name = value[0]
	
var event_selected_variables: Dictionary
var event_selected_name: String
var event_index: int = -1

func _init():
	texture = Paths.imageTexture('eventArrow')
	centered = false
	scale = Vector2(0.4,0.4)

func set_variable(variable: String, value: Variant):
	if not event_selected_variables.has(variable): return
	event_selected_variables[variable] = value

func selectEvent(index: int = event_index):
	index = clamp(index,0,events.size()-1)
	event_index = index
	event_selected = ArrayHelper.get_array_index(events,index,['',{}])

func addEvent(event_name: String = '', variables: Dictionary = {},at: int = -1) -> Array:
	var event_default_vars = EventNote.get_event_variables(event_name)
	var event_vars = {}
	var event_data = [event_name,event_vars]
	
	#Set the default value to event
	for vars in event_default_vars:
		event_vars[vars] = variables.get(vars,event_default_vars[vars].default_value)
	
	at = clamp(at,0,events.size())
	if at < events.size()-1: events.insert(at,event_data)
	else: events.append(event_data)
	
	event_selected = event_data
	update_json()
	return event_data

func replaceEvent(replace_to: String):
	addEvent(replace_to,event_selected_variables,event_index)
	if event_index != -1:
		events.remove_at(event_index)
	
func removeEvent(index: int = event_index) -> Array:
	var data = events.get(index)
	if !data:
		return []
	events.remove_at(index)
	update_json()
	return data
	
func update_json():
	json_data[1] = events
