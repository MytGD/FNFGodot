class_name PopupOptions extends Resource
@export var icon: Texture
@export_node_path("PopupMenu") var submenu: NodePath: set = set_menu_path
@export var text: String

var _popup_index: int

signal submenu_path_changed(new_path: String)
signal icon_changed(_icon: Texture)
signal text_changed(new_text: String)
func set_icon(_icon: Texture) -> void:
	icon = _icon
	icon_changed.emit(_icon)

func set_text(new_text: String) -> void:
	text = new_text
	text_changed.emit(text)

func set_menu_path(path: NodePath) -> void:
	submenu = path
	submenu_path_changed.emit(path)
