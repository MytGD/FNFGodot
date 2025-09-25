extends Node

func _ready():
	DiscordRPC.app_id = 1228864907252863017
	DiscordRPC.large_image = 'fnf_godot_e'
	DiscordRPC.start_timestamp = 0
	DiscordRPC.refresh()

func _process(delta: float) -> void:
	DiscordRPC.run_callbacks()
