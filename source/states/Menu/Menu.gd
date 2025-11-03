extends Node

const ModeSelect = preload("res://source/states/Menu/ModeSelect.gd")
const AlphabetText = preload("res://source/objects/AlphabetText/AlphabetText.gd")
const SolidSprite = preload("res://source/objects/Sprite/SolidSprite.gd")

var introText: PackedStringArray = [
	'A Engine made on \n#Godot',
	'Total Credits to \nFNF Team',
	'Special Thanks for \nShadow Mario'
]

var curIntroText: int = 0

var introTime: float = 0.0


var alphaText: AlphabetText = AlphabetText.new()

var flash: SolidSprite = SolidSprite.new()
var flashTween: Tween

var gfBeating: FunkinSprite = FunkinSprite.new(true,'gfDanceTitle')
var logoBomping: FunkinSprite = FunkinSprite.new(true,'logoBumpin')
var pressStart: FunkinSprite = FunkinSprite.new(true,'titleEnter')

var bpm: float = 100

var beat: int = 0.0: set = set_beat

var menuState: int = 0

var playIntroText: bool = true

func _ready():
	DiscordRPC.details = 'In Menu'
	DiscordRPC.refresh()
	
	var bpm_data = Paths.loadJson('images/gfDanceTitle')
	
	FunkinGD.playSound(Paths.music('freakyMenu'),1,'freakyMenu',false,true)
	flash.scale = Vector2(ScreenUtils.screenWidth,ScreenUtils.screenHeight)
	flash.modulate.a = 0
	
	alphaText.position = ScreenUtils.screenCenter
	alphaText.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	alphaText.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(alphaText)
	
	add_child(gfBeating)
	
	add_child(pressStart)
	add_child(logoBomping)
	add_child(flash)
	logoBomping.animation.addAnimByPrefix('logo','logo bumpin')
	logoBomping.visible = false
	logoBomping._position = Vector2(bpm_data.get('titlex',-150),bpm_data.get('titley',-100))
	logoBomping.name = 'logoBomping'
	
	gfBeating.image.texture = Paths.imageTexture('gfDanceTitle')
	gfBeating.animation.addAnimByPrefix('danceLeft','gfDance',24,false,range(15))
	gfBeating.animation.addAnimByPrefix('danceRight','gfDance',24,false,range(15,30))
	gfBeating.visible = false
	
	gfBeating._position = Vector2(bpm_data.get('gfx',600),bpm_data.get('gfy',40))
	gfBeating.name = 'GfBeating'
	bpm = bpm_data.get('bpm',102)
	
	pressStart.image.texture = Paths.imageTexture('titleEnter')
	pressStart.animation.addAnimByPrefix('idle','ENTER IDLE',24,true)
	pressStart.animation.addAnimByPrefix('pressed','ENTER PRESSED',24,true)
	pressStart.visible = false
	pressStart._position = Vector2(bpm_data.get('startx',100),bpm_data.get('starty',ScreenUtils.screenHeight - 150))
	pressStart.name = 'pressStart'
	
	Global.onSwapTree.connect(queue_free,CONNECT_ONE_SHOT)
	if not playIntroText: changeState(1)
	
func changeState(state: int = 0):
	if state == 1:
		alphaText.queue_free()
		logoBomping.visible = true
		gfBeating.visible = true
		pressStart.visible = true
		doFlash()
	menuState = state
	
func set_beat(newBeat: int):
	if beat == newBeat: return
	beat = newBeat
	if newBeat % 2 == 1:gfBeating.animation.play('danceRight')
	else: gfBeating.animation.play('danceLeft')
	logoBomping.animation.play('logo',true)
	
func _process(delta: float) -> void:
	var audio = FunkinGD.soundsPlaying.get('freakyMenu')
	if audio: beat = audio.get_playback_position()/(60.0/bpm)
	introTime += delta
	match menuState:
		0:
			if introTime < 1: return
			curIntroText = int(introTime)
			if curIntroText >= introText.size(): 
				changeState(1)
			else:
				var text = introText[curIntroText]
				
				if introTime - curIntroText < 0.5: 
					alphaText.text = text.substr(0,text.find('\n'))
				else: alphaText.text = text

func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.button_index == 1 or event is InputEventKey and event.keycode == KEY_ENTER)\
	 and event.pressed:
		match menuState:
			0:
				changeState(1)
			1:
				pressStart.animation.play('pressed')
				doFlash()
				FunkinGD.playSound(Paths.sound('confirmMenu'))
				get_tree().create_timer(1.5).timeout.connect(Global.swapTree.bind(ModeSelect.new()))
				menuState = 2
func doFlash():
	if flashTween: flashTween.kill()
	flash.modulate.a = 1
	flashTween = create_tween()
	flashTween.tween_property(flash,'modulate:a',0,2.0)
