static var atlas_loaded: Dictionary[String,Dictionary]
static func loadAtlas(file: String) -> Dictionary[String, Array]:
	if !file.ends_with('.txt'): file += '.txt'
	
	if atlas_loaded.get(file): return atlas_loaded[file]
	var data: Dictionary[String, Array] = {}
	for i in FileAccess.get_file_as_string(file).split('\n'):
		if not i: continue
			
		var find_equals = i.find('=')
		if find_equals == -1: continue
		
		var animName = i.left(find_equals-1)
		var find_underline: int = 0
		var prev_underline: int = 0
		while true:
			prev_underline = animName.find('_',prev_underline+1)
			if prev_underline == -1: break
			find_underline += prev_underline
			
		if find_underline == -1: continue
		
		var frame: int = int(animName.right(-find_underline))
		animName = animName.left(find_underline+1)
		
		var anim_frames = data.get_or_add(animName,[])
		
		var anim_data = i.right(-find_equals-1).split(' ',false)
		var rect = Rect2(
				float(anim_data[0]),
				float(anim_data[1]),
				float(anim_data[2]),
				float(anim_data[3])
		)
		if anim_frames.size() < frame+1: anim_frames.resize(frame+1)
		
		var anim_dict: Dictionary[StringName,Variant] = {'region_rect': rect, 'size': rect.size}
		anim_frames[frame] = anim_dict
		
	atlas_loaded[file] = data
	return data
