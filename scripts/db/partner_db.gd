class_name PartnerDb
extends RefCounted
## Načtení partnerek z res://data/partnerky.

const DIR := "res://data/partnerky"


static func load_all() -> Array[Partnerka]:
	var out: Array[Partnerka] = []
	for r in DbUtil.load_resources(DIR):
		if r is Partnerka:
			out.append(r)
	return out


static func get_by_id(id: StringName) -> Partnerka:
	for p in load_all():
		if p.id == id:
			return p
	return null
