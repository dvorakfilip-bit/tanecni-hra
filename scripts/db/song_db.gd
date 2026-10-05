class_name SongDb
extends RefCounted
## Načtení dat písní z JSON.

const MVP_SONG := "res://songs/incienso.json"


static func load_song(path: String) -> SongData:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("SongDb: nejde načíst %s" % path)
		return null
	var d = JSON.parse_string(text)
	if typeof(d) != TYPE_DICTIONARY:
		push_error("SongDb: neplatný JSON v %s" % path)
		return null
	return SongData.from_dict(d)
