class_name PopupUtils extends Object

static func addPopupItemsFromDir(popup: PopupMenu, dir: String, filters: Variant = '', with_extension: bool = false) -> void:
	var last_mod: String
	var files_find: PackedStringArray
	var min_size: int
	for i in Paths.getFilesAt(dir,true,filters,with_extension):
		var file = i.get_file()
		if file in files_find: continue
		
		var mod: String = Paths.getModFolder(i)
		if !mod: mod = Paths.game_name
		
		if last_mod != mod:
			min_size = maxi(min_size,int(popup.get_theme_font(&'font_separator').get_string_size(mod).x)) 
			popup.add_separator(mod); last_mod = mod
		files_find.append(file)
		popup.add_item(file)
	min_size += 100
	popup.visibility_changed.connect(func():
		if !popup.visible: return
		popup.min_size.x = min_size
		popup.size.x = min_size
	)
