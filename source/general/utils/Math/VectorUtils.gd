class_name VectorUtils

const vectors: Dictionary = {
	TYPE_VECTOR2: true,
	TYPE_VECTOR2I: true,
	TYPE_VECTOR3: true,
	TYPE_VECTOR3I: true,
	TYPE_VECTOR4: true,
	TYPE_VECTOR4I: true
}
const vectors_index: PackedStringArray = ['x','y','z','w']

static func get_vector_size(type: Variant.Type) -> int:
	match type:
		TYPE_VECTOR2,TYPE_VECTOR2I: return 2
		TYPE_VECTOR3,TYPE_VECTOR3I: return 3
		TYPE_VECTOR4,TYPE_VECTOR4I: return 4
		_: return 0

static func is_vector(variable) -> bool: return typeof(variable) in vectors

static func is_vector_type(type: int):return type in vectors

static func sin_vec(number: Variant):return Vector2(sin(number.x), sin(number.y))

static func float_vec(number: Variant) -> Variant: return Vector2(number, number)

static func flip_vec(vector: Variant) -> Variant:
	match typeof(vector):
		TYPE_VECTOR2: return Vector2(vector.y, vector.x)
		TYPE_VECTOR2I: return Vector2i(vector.y, vector.x)
		TYPE_VECTOR3: return Vector3(vector.z, vector.y, vector.x)
		TYPE_VECTOR3I: return Vector3i(vector.z, vector.y, vector.x)
		TYPE_VECTOR4: return Vector4(vector.w, vector.z, vector.y, vector.x)
		TYPE_VECTOR4I: return Vector4i(vector.w,vector.z,vector.y,vector.x)
	return vector

static func array_to_vec(array: Array) -> Variant:
	match array.size():
		0: return Vector2.ZERO
		1: return Vector2(array[0],array[0])
		2: return Vector2(array[0],array[1])
		3: return Vector3(array[0],array[1],array[2])
		_: return Vector4(array[0],array[1],array[2],array[3])

static func vector_to_array(vector: Variant) -> PackedFloat64Array:
	match typeof(vector):
		TYPE_VECTOR2,TYPE_VECTOR2I: return [vector.x, vector.y]
		TYPE_VECTOR3,TYPE_VECTOR3I: return [vector.x, vector.y, vector.z]
		TYPE_VECTOR4,TYPE_VECTOR4I: return [vector.x, vector.y, vector.z, vector.w]
		_:return [0,0]

static func as_vector2(value: Variant) -> Vector2:
	match typeof(value):
		TYPE_ARRAY,TYPE_PACKED_FLOAT32_ARRAY,TYPE_PACKED_FLOAT64_ARRAY,\
		TYPE_PACKED_INT32_ARRAY,TYPE_PACKED_INT64_ARRAY: 
			var size = value.size()
			if !size: return Vector2.ZERO
			return Vector2(value[0],value[1] if size >= 2 else value[0])
		TYPE_VECTOR2,TYPE_VECTOR2I: return value
		TYPE_FLOAT: return Vector2(value,value)
		_: return Vector2.ZERO
