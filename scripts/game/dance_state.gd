class_name DanceState
extends RefCounted
## Stav páru: držení, energie a pohoda partnerky, historie figur.

var partnerka: Partnerka
var drzeni: StringName = &"zavrene"
var energie: int
var pohoda: float
var zakladnich_po_sobe := 0
## id provedených figur v pořadí
var historie: Array[StringName] = []
var posledni_figura_cyklus := -10


func _init(p: Partnerka, b: Balance) -> void:
	partnerka = p
	energie = p.energie_max
	pohoda = b.pohoda_start


func zmen_pohodu(delta: float) -> void:
	pohoda = clampf(pohoda + delta, 0.0, 100.0)


func zmen_energii(delta: int) -> void:
	energie = clampi(energie + delta, 0, partnerka.energie_max)


## Lineárně: pohoda 0 = ×0,5, 50 = ×1,0, 100 = ×1,5.
func pohoda_nasobic() -> float:
	return 0.5 + pohoda / 100.0
