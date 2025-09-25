static var _xml_parser: XMLParser = XMLParser.new()
static var sparrows_loaded: Dictionary[String,Dictionary] = {}

const region = StringName('region_rect')
const size = StringName('size')
const rotation = StringName('rotation')
const frameSize = StringName('frameSize')
const pivot = StringName('pivot_offset')
const position = StringName('position')

const deg_90 = deg_to_rad(-90)

##Load the data from the xml file, [param file] have to be the EXACT LOCATION.[br][br]
## Example: [codeblock]
##loadSparrow("images/Image.xml") #Wrong
##loadSparrow("C:/Users/[Your Username]/Images/images/Image.xml") #Correct
##loadSparrow(Paths.detectFileFolder("images/Image.xml")) #Also works if the file are found.
##[/codeblock]
static func loadSparrow(file: String) -> Dictionary[String,Array]:
	if !file.ends_with('.xml'): file += '.xml'
	if sparrows_loaded.has(file): return sparrows_loaded[file]
	if !FileAccess.file_exists(file):return {}
	
	var sparrow: Dictionary[String,Array] = {}
	_xml_parser.open(file)
	
	var prevFrameProperties: Dictionary = {}
	while _xml_parser.read() == OK:
		if _xml_parser.get_node_type() != XMLParser.NODE_ELEMENT: continue
		var xmlName: String = _xml_parser.get_named_attribute_value_safe('name')
		if !xmlName:  continue;
		
		var frame: int = xmlName.right(4).to_int()
		var region_data: Rect2 = Rect2(
				float(_xml_parser.get_named_attribute_value('x')),
				float(_xml_parser.get_named_attribute_value('y')),
				float(_xml_parser.get_named_attribute_value('width')),
				float(_xml_parser.get_named_attribute_value('height'))
		)
		var r: float = 0
		var p: Vector2 = Vector2.ZERO
		var s: Vector2 = region_data.size
		var f_s: Vector2 = s
		
		if _xml_parser.get_named_attribute_value_safe('rotated') == 'true':
			r = deg_90
			p.y += s.x
			s = Vector2(s.y,s.x)
		if _xml_parser.has_attribute('frameX'):
			p += -Vector2(
				float(_xml_parser.get_named_attribute_value('frameX')),
				float(_xml_parser.get_named_attribute_value('frameY'))
			)
			f_s = Vector2(
				float(_xml_parser.get_named_attribute_value('frameWidth')),
				float(_xml_parser.get_named_attribute_value('frameHeight'))
			)
		
		var frameData: Dictionary = {
			region: region_data,
			position: p,
			size: s,
			rotation: r,
			frameSize: f_s
		}
		
		if _xml_parser.has_attribute('pivotX'):
			frameData[pivot] = Vector2(
				float(_xml_parser.get_named_attribute_value_safe('pivotX')),
				float(_xml_parser.get_named_attribute_value_safe('pivotY'))
			)
		
		
		##Remove frame from name
		xmlName = xmlName.left(-4)
		
	
		
		var last_frame: Dictionary = prevFrameProperties.get_or_add(xmlName,{})
		if !last_frame:
			last_frame.assign(frameData)
		else:
			for i in frameData.keys():
				var data = frameData[i]
				
				if data == last_frame[i]: 
					frameData.erase(i)
					continue
				last_frame[i] = data
		var animationFrames: Array[Dictionary] = sparrow.get_or_add(
			xmlName,
			Array([],TYPE_DICTIONARY,'',null)
		)
		
		var frames = animationFrames.size()
		if frames == frame: 
			animationFrames.append(frameData);
			continue
		
		while frames <= frame: animationFrames.append({}); frames += 1
		animationFrames[frame] = frameData
	
	for i in sparrow.values(): if i and !i[0]: i.remove_at(0)
	sparrows_loaded[file] = sparrow
	return sparrow
