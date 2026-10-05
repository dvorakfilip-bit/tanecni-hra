class_name Hand
extends RefCounted
## Balíček a karty v ruce (PRD 5.3).

const VELIKOST := 4

var karty: Array[Figura] = []
## index vybrané karty, -1 = nic
var vybrana := -1
## absolutní doba (od 0), kdy byla karta naposledy vybrána
var vybrana_doba := 0
var zahozeno_v_cyklu := -1

var _vse: Array[Figura] = []
var _balicek: Array[Figura] = []
var _rng := RandomNumberGenerator.new()


## rng_seed < 0 = náhodný
func _init(vsechny_karty: Array[Figura], rng_seed := -1) -> void:
	_vse = vsechny_karty
	if rng_seed >= 0:
		_rng.seed = rng_seed
	else:
		_rng.randomize()
	for i in VELIKOST:
		karty.append(_liznout())


func vyber(i: int, doba: int) -> void:
	vybrana = i
	vybrana_doba = doba


func zrus_vyber() -> void:
	vybrana = -1


## Karta byla zahrána: nahradí se novou a výběr se zruší.
func pouzij(i: int) -> void:
	karty[i] = _liznout()
	zrus_vyber()


func muze_zahodit(cyklus: int) -> bool:
	return zahozeno_v_cyklu != cyklus


func zahod(i: int, cyklus: int) -> bool:
	if not muze_zahodit(cyklus):
		return false
	zahozeno_v_cyklu = cyklus
	if vybrana == i:
		zrus_vyber()
	karty[i] = _liznout()
	return true


## Z balíčku; když dojde, zamíchá se znovu ze všech karet, které nejsou v ruce.
func _liznout() -> Figura:
	if _balicek.is_empty():
		for f in _vse:
			if f not in karty:
				_balicek.append(f)
		for i in range(_balicek.size() - 1, 0, -1):
			var j := _rng.randi_range(0, i)
			var tmp := _balicek[i]
			_balicek[i] = _balicek[j]
			_balicek[j] = tmp
	return _balicek.pop_back()
