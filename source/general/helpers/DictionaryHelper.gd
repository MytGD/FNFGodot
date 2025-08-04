class_name DictionaryHelper

static func merge_existing(dic: Dictionary, to: Dictionary) -> Dictionary:
	for i in dic:
		if to.has(i):
			dic[i] = to[i]
	return dic

static func front(dic: Dictionary): ##Retruns the first element from [param dic].
	if !dic:
		return null
	return dic[dic.keys().front()]

static func back(dic: Dictionary) -> Variant: ##Retruns the last element from [param dic].
	if !dic:
		return null
	return dic[dic.keys().back()]

static func rename_key(dic: Dictionary, key: Variant, new_key: Variant):
	if !dic.has(key):
		return
	dic[new_key] = dic[key]
	dic.erase(key)
