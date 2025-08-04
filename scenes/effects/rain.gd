@tool
extends GPUParticles2D
@export var width: float = ScreenUtils.screenWidth:
	set(value):
		width = value
		if process_material: process_material.emission_box_extents.x = width
		notify_property_list_changed()
	
