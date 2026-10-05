class_name DbUtil
extends RefCounted


## Načte všechny resource soubory ze složky. ResourceLoader.list_directory
## funguje i v exportu, kde se .tres mění na binární / .remap.
static func load_resources(dir: String) -> Array[Resource]:
	var out: Array[Resource] = []
	var names := Array(ResourceLoader.list_directory(dir))
	names.sort()
	for name: String in names:
		if name.ends_with("/"):
			continue
		var r := load(dir.path_join(name))
		if r:
			out.append(r)
	return out
