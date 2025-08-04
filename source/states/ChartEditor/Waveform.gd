extends Node2D


var _audio_capture: AudioEffectCapture
var bus_capture_index: int = -1

var _last_audio_bus: String
var waveform_audio: AudioStreamPlayer:
	set(value):
		_audio_capture = null
		if !value:
			return
		if !value.stream:
			print_debug('Error on @waveform_audio setter: stream of "',value.name,'" is null.')
			return
		
		var bus_index = AudioServer.get_bus_index(value.bus)
		for i in range(AudioServer.get_bus_effect_count(bus_index)):
			var capture = AudioServer.get_bus_effect(bus_index,i)
			if capture is AudioEffectCapture:
				_audio_capture = capture
				break
		
		if !_audio_capture:
			print_debug('Error on @waveform_audio setter: ',value.name,' must be in a Bus that have a Capture audio effect.')
			return
		waveform_audio = value
var waveform_audio_packet_data: Array
var waveform_color: Color = Color.WHITE
var waveform_size: Vector2 = Vector2(10,10)
var waveform_scale: float = 0.05
var waveform_up: bool = false
var waveform_offset: Vector2 = Vector2(10,10)

func _ready():
	name = 'Waveform'
func draw_waveform(from: float = 0, to: float = -1):
	if !waveform_audio or !waveform_audio.stream:
		return
	if to == -1:
		to = waveform_audio.stream.get_length()
	queue_redraw()
