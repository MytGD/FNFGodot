extends MenuButton
@export_dir var dir_to_look: String = ''
@export var filters: PackedStringArray

func _ready() -> void: _refresh()
func _refresh(): 
	var popup = get_popup()
	popup.clear()
	PopupUtils.addPopupItemsFromDir(popup,dir_to_look,filters)
