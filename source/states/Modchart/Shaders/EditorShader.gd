extends ShaderMaterial
var objects: PackedStringArray = []
var shader_name: String
var uniforms: Dictionary = {}

func loadShader(path: String):
	shader = Paths.loadShaderCode(path)
	if !shader: return
	uniforms = get_shader_uniforms(self)
	for i in uniforms: set_shader_parameter(i,uniforms[i].default)
static func get_shader_uniforms(material: Material):
	var list: Dictionary[String,Dictionary]
	var uid = material.shader.get_rid()
	for i in material.shader.get_shader_uniform_list(true):
		var type = i.type
		var default_value = RenderingServer.shader_get_parameter_default(uid,i.name)
		if default_value == null: default_value = MathUtils.get_new_value(type)
		list[i.name] = {'default': default_value,'type': type}
	return list
