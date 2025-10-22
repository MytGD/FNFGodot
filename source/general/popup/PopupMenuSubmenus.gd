@tool
extends PopupMenu
@export var submenus: Array[PopupOptions]: set = set_submenus

func set_submenus(menu: Array[PopupOptions]):
	var index = 0
	
	var menu_size = menu.size()
	while index < menu.size():
		if menu[index] == null: menu[index] = _create_options()
		index += 1
	
	var last_size = submenus.size()
	submenus = menu
	if last_size < menu_size:
		_check_text_exited(menu_size - last_size)
	

func _check_text_exited(how_much_exited: int = 3):
	var texts: PackedStringArray
	for i in submenus: texts.append(i.text)
	
	var index = item_count
	while index:
		index -= 1
		if get_item_text(index) in texts: continue
		_remove_item(index)
		how_much_exited -= 1
		if how_much_exited <= 0: break

func _remove_item(at: int):
	remove_item(at)
	while at < item_count:
		if get_item_submenu_node(at):
			for i in submenus: if i._popup_index >= at: i._popup_index -= 1
		at += 1

func _create_options():
	var pop = PopupOptions.new()
	if pop.submenu: add_submenu_node_item(pop.text,null)
	else: add_item(pop.text) 
	
	pop._popup_index = item_count-1
	pop.text_changed.connect(func(t): set_item_text(pop._popup_index,t))
	pop.submenu_path_changed.connect(func(t): set_item_submenu_node(pop._popup_index,get_node(t)))
	pop.icon_changed.connect(func(t): set_item_icon(pop._popup_index,t))
	return pop
