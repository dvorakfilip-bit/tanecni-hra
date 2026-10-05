class_name Nazvy
extends RefCounted
## Zobrazované názvy držení a typů figur.

const DRZENI := {
	&"zavrene": "zavř",
	&"otevrene": "otev",
	&"jedna_ruka": "1 ruka",
	&"zkrizene": "zkříž",
}

const TYP := {
	&"zaklad": "základ",
	&"prechod": "přechod",
	&"figura": "figura",
	&"otocka": "otočka",
	&"styling": "styling",
	&"efektni": "efektní",
}


static func drzeni(id: StringName) -> String:
	return DRZENI.get(id, String(id))


static func typ(id: StringName) -> String:
	return TYP.get(id, String(id))


static func vstup(f: Figura) -> String:
	if f.vstup.is_empty():
		return "cokoli"
	return "/".join(f.vstup.map(func(d: StringName) -> String: return drzeni(d)))
