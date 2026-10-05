class_name Figura
extends Resource
## Taneční figura (karta). Data jsou v res://data/figury/*.tres.

@export var id: StringName
@export var nazev: String
@export var styl: StringName = &"bachata"   # "bachata", "salsa"
## Držení, ze kterých jde figura zahrát. Prázdné = libovolné.
@export var vstup: Array[StringName] = []
## Držení po figuře. Prázdné = stejné jako vstup.
@export var vystup: StringName
@export var delka_dob: int = 8
@export_range(1, 3) var obtiznost: int = 1
## Kolik energie figura partnerce ubere. Záporná hodnota = regenerace.
@export var narocnost_energie: int = 0
@export var typ: StringName                 # "zaklad", "prechod", "figura", "otocka", "styling", "efektni"


func jde_z(drzeni: StringName) -> bool:
	return vstup.is_empty() or drzeni in vstup


func vystupni_drzeni(z: StringName) -> StringName:
	return z if vystup == &"" else vystup


func je_karta() -> bool:
	return typ != &"zaklad"
