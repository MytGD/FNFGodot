class_name PopupUtils

static func addPopupItemsFromDir(popup: PopupMenu, dir: String, filters: Variant = '') -> void:
	var last_mod = ''
	var events_loaded: PackedStringArray = []
	for i in Paths.getFilesAt(dir,true,filters):
		var file = i.get_file()
		if file in events_loaded: continue
		var mod = Paths.getModFolder(i)
		if !mod: mod = Paths.game_name
		
		if last_mod != mod: popup.add_separator(mod); last_mod = mod
		
		events_loaded.append(i)
		popup.add_item(file)
		pass
	
