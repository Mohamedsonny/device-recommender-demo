## Reads level JSON files from res://levels/.
class_name LevelLoader
extends RefCounted


static func path_for(id: int) -> String:
	return "res://levels/%03d.json" % id


static func load_file(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("level not found: " + path)
		return {}
	var data = JSON.parse_string(text)
	return data if data is Dictionary else {}
