class_name ScoreSystem
extends RefCounted
## Skóre a combo (PRD 5.6).

var skore := 0
var combo := 0
var max_combo := 0


func combo_nasobic(b: Balance) -> float:
	return minf(1.0 + b.combo_krok * combo, b.combo_max)


func pridej(body: int) -> void:
	skore += body


func combo_plus() -> void:
	combo += 1
	max_combo = maxi(max_combo, combo)


func combo_reset() -> void:
	combo = 0
