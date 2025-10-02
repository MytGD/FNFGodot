static var _xml_parser: XMLParser = XMLParser.new()
static var sparrows_loaded: Dictionary[String,Dictionary] = {}

const region = StringName('region_rect')
const size = StringName('size')
const rotation = StringName('rotation')
const frameSize = StringName('frameSize')
const pivot = StringName('pivot_offset')
const position = StringName('position')
const frameCenter = StringName('frameCenter')

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
		var xmlName = _xml_parser.get_named_attribute_value_safe('name')
		if !xmlName: continue;

		var frame: int = xmlName.right(4).to_int()
		
		##Remove frame from name
		xmlName = xmlName.left(-4)
		var animationFrames: Array[Dictionary] = sparrow.get_or_add(
			xmlName,
			Array([],TYPE_DICTIONARY,'',null)
		)
		
		var region_data: Rect2 = Rect2(
				float(_xml_parser.get_named_attribute_value('x')),
				float(_xml_parser.get_named_attribute_value('y')),
				float(_xml_parser.get_named_attribute_value('width')),
				float(_xml_parser.get_named_attribute_value('height'))
		)
		
		#Frame Data
		var s = region_data.size
		var f_s: Vector2 = s
		var r: float = 0.0
		var p: Vector2 = Vector2.ZERO
		
		var last_frame: Dictionary = prevFrameProperties.get_or_add(xmlName,{})
		
		if _xml_parser.get_named_attribute_value_safe('rotated') == 'true':
			r = deg_90
			p.y += s.x
			s = Vector2(s.y,s.x)
		
		var frameData: Dictionary = {
			region: region_data,
			position: p,
			size: s,
			rotation: r
		}
		
		var need_center_update: bool = !last_frame
		
		if _xml_parser.has_attribute('frameX'):
			frameData[position] += -Vector2(
				float(_xml_parser.get_named_attribute_value('frameX')),
				float(_xml_parser.get_named_attribute_value('frameY'))
			)
			f_s =  Vector2(
				float(_xml_parser.get_named_attribute_value('frameWidth')),
				float(_xml_parser.get_named_attribute_value('frameHeight'))
			)
			frameData[frameSize] = f_s
			if last_frame and f_s != last_frame.get(frameSize):
				need_center_update = true
		
		#if _xml_parser.has_attribute('pivotX'):
			#frameData[pivot] = Vector2(
				#float(_xml_parser.get_named_attribute_value('pivotX')),
				#float(_xml_parser.get_named_attribute_value('pivotY'))
			#)
		
		
		if last_frame:
			#if !need_center_update: frameData[position] -= last_frame[frameCenter]
			#Remove values if not change.
			for i in frameData:
				var data = frameData[i]
				var last_val = last_frame.get(i)
				if last_val != null and data == last_val: 
					frameData.erase(i)
					continue
		
		last_frame.merge(frameData,true)
		
		
		
		var frames = animationFrames.size()
		if frames == frame: 
			animationFrames.append(frameData);
			continue
		
		while frames <= frame: animationFrames.append({}); frames += 1
		animationFrames[frame] = frameData
	
	for i in sparrow.values(): if i and !i[0]: i.remove_at(0)
	sparrows_loaded[file] = sparrow
	return sparrow
