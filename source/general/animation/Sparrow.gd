static var _xml_parser: XMLParser = XMLParser.new()
static var sparrows_loaded: Dictionary = {}

const deg_90 = deg_to_rad(-90)

##Load the data from the xml file, [param file] have to be the EXACT LOCATION.[br][br]
## Example: [codeblock]
##loadSparrow("images/Image.xml") #Wrong
##loadSparrow("C:/Users/[Your Username]/Images/images/Image.xml") #Correct
##loadSparrow(Paths.detectFileFolder("images/Image.xml")) #Also works if the file are found.
##[/codeblock]
static func loadSparrow(file: String) -> Dictionary:
	if !file.ends_with('.xml'):
		file += '.xml'
		
	if sparrows_loaded.has(file):
		return sparrows_loaded[file]
	if !FileAccess.file_exists(file):
		return {}
	
	var sparrow: Dictionary[String,Array] = {}
	_xml_parser.open(file)
	while _xml_parser.read() == OK:
		var xmlName: String = _xml_parser.get_named_attribute_value_safe('name')
		if !xmlName: continue
		
		var frameData: Dictionary[String,Variant] = {}
		var frame: int = xmlName.right(4).to_int()
		
		frameData.region_rect = Rect2(
			float(_xml_parser.get_named_attribute_value('x')),
			float(_xml_parser.get_named_attribute_value('y')),
			float(_xml_parser.get_named_attribute_value('width')),
			float(_xml_parser.get_named_attribute_value('height'))
		)
		
		var size = frameData.region_rect.size
		var position: Vector2 = Vector2.ZERO
		if _xml_parser.get_named_attribute_value_safe('rotated') == 'true':
			frameData["rotation"] = deg_90
			frameData["size"] = Vector2(size.y,size.x)
			position.y += size.x
		else:
			frameData["rotation"] = 0
			frameData["size"] = size

		if _xml_parser.has_attribute('frameX'):
			position += -Vector2(
				float(_xml_parser.get_named_attribute_value('frameX')),
				float(_xml_parser.get_named_attribute_value('frameY'))
			)
			frameData["frameSize"] = Vector2(
				float(_xml_parser.get_named_attribute_value('frameWidth')),
				float(_xml_parser.get_named_attribute_value('frameHeight'))
			)
		
		if _xml_parser.has_attribute('pivotX'):
			frameData["pivot_offset"] = Vector2(
				float(_xml_parser.get_named_attribute_value_safe('pivotX')),
				float(_xml_parser.get_named_attribute_value_safe('pivotY'))
			)
		
		frameData["position"] = position
		##Remove frame from name
		xmlName = xmlName.left(-4)
		
		var animationFrames: Array[Dictionary] = sparrow.get_or_add(
			xmlName,
			Array([],TYPE_DICTIONARY,'',null)
		)
		var frames = animationFrames.size()

		if frames == frame: 
			animationFrames.append(frameData);
			continue
		
		frames -= 1
		while frames < frame:
			animationFrames.append({})
			frames += 1
		animationFrames[frame] = frameData
		#Just set the frame if not inserted already.
		if !animationFrames[frame]: animationFrames[frame] = frameData
	
	for i in sparrow.values():
		if i and !i[0]:
			i.remove_at(0)
	sparrows_loaded[file] = sparrow
	return sparrow
