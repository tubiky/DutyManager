extends RefCounted
class_name Staff

var id: String
var name: String
var dept: String
var tags: Array[String] = []
var max_load: int = 3
var unavailable: Dictionary = {} # {"2025-08-12": true, "weekday": ["Mon"]}

func _init(_id: String, _name: String, _dept: String) -> void:
	id = _id
	name = _name
	dept = _dept
