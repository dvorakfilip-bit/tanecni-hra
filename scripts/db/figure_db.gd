class_name FigureDb
extends RefCounted
## Načtení všech figur z res://data/figury.

const DIR := "res://data/figury"


static func load_all() -> Array[Figura]:
	var out: Array[Figura] = []
	for r in DbUtil.load_resources(DIR):
		if r is Figura:
			out.append(r)
	return out


static func karty() -> Array[Figura]:
	return load_all().filter(func(f: Figura) -> bool: return f.je_karta())
