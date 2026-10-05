class_name SongData
extends RefCounted
## Data písně načtená z JSON (PRD 8.1).

var nazev: String
var interpret: String
var styl: StringName
var soubor: String
var bpm: float
## Čas první doby 1 od začátku souboru.
var offset_ms: float
var delka_frazi_dob: int = 32
## [{ "doba": int, "typ": String }], doba se počítá od první doby 1 (od 0).
var akcenty: Array[Dictionary] = []

var seconds_per_beat: float:
	get:
		return 60.0 / bpm

var offset_s: float:
	get:
		return offset_ms / 1000.0


static func from_dict(d: Dictionary) -> SongData:
	var s := SongData.new()
	s.nazev = d.get("nazev", "")
	s.interpret = d.get("interpret", "")
	s.styl = StringName(d.get("styl", "bachata"))
	s.soubor = d.get("soubor", "")
	s.bpm = float(d.get("bpm", 120))
	s.offset_ms = float(d.get("offset_ms", 0))
	s.delka_frazi_dob = int(d.get("delka_frazi_dob", 32))
	for a in d.get("akcenty", []):
		s.akcenty.append({ "doba": int(a.get("doba", 0)), "typ": String(a.get("typ", "")) })
	return s
