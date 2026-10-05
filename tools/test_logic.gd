extends Node
## Testy herních pravidel (DanceGame). Spuštění:
## godot --headless --path . res://tools/test_logic.tscn

var _chyby := 0
var _figury := {}


func _ready() -> void:
	for f in FigureDb.load_all():
		_figury[f.id] = f
	test_perfect_a_prechod()
	test_good_miss()
	test_spatne_drzeni()
	test_predcasna_priprava()
	test_necinnost()
	test_uvod_a_ignorovani()
	test_akcent_a_fraze()
	test_zahozeni()
	test_vysledky()
	print("VŠE OK" if _chyby == 0 else "CHYB: %d" % _chyby)
	get_tree().quit(1 if _chyby else 0)


## 120 BPM, offset 0 => doba = 0,5 s, cyklus = 4 s
func _hra(akcenty := []) -> DanceGame:
	var s := SongData.from_dict({ "bpm": 120, "offset_ms": 0, "akcenty": akcenty })
	var karty: Array[Figura] = []
	for f in _figury.values():
		if f.je_karta():
			karty.append(f)
	return DanceGame.new(s, karty, PartnerDb.get_by_id(&"mvp"), load("res://data/balance.tres"), 200.0, 1)


func _karta(g: DanceGame, i: int, id: StringName) -> void:
	g.ruka.karty[i] = _figury[id]


func _cas(doba: float) -> float:
	return doba * 0.5


func _ocekavej(popis: String, skutecne, ocekavane) -> void:
	if typeof(skutecne) == TYPE_FLOAT and typeof(ocekavane) in [TYPE_FLOAT, TYPE_INT]:
		if absf(skutecne - ocekavane) < 0.001:
			return
	elif skutecne == ocekavane:
		return
	_chyby += 1
	push_error("%s: čekáno %s, je %s" % [popis, ocekavane, skutecne])


## Vybere kartu na dobu vyber_doba a potvrdí na dobu 1 cyklu c s odchylkou.
func _zahraj(g: DanceGame, i: int, vyber_doba: float, c: int, odchylka_s: float) -> Dictionary:
	var vysledek := {}
	var zachyt := func(r: Dictionary) -> void: vysledek.merge(r)
	g.figura_vyhodnocena.connect(zachyt)
	g.update(_cas(vyber_doba))
	g.tukni(i, _cas(vyber_doba))
	var t := _cas(c * 8) + odchylka_s
	g.update(t)
	g.tukni(i, t)
	g.figura_vyhodnocena.disconnect(zachyt)
	return vysledek


func test_perfect_a_prechod() -> void:
	var g := _hra()
	_karta(g, 0, &"otevreni")
	var r := _zahraj(g, 0, 13, 2, 0.03)
	_ocekavej("perfect timing", r.timing, Judge.Timing.PERFECT)
	_ocekavej("perfect logika", r.logika, Judge.Logika.OK)
	# (100 + 50 rozmanitost) × 1 × combo 1 × pohoda 1,2
	_ocekavej("perfect body", r.body, 180)
	_ocekavej("perfect držení", g.stav.drzeni, &"otevrene")
	_ocekavej("perfect combo", g.skore.combo, 1)
	_ocekavej("perfect pohoda", g.stav.pohoda, 75.0)
	_ocekavej("perfect energie", g.stav.energie, 95)
	_ocekavej("perfect výběr zrušen", g.ruka.vybrana, -1)


func test_good_miss() -> void:
	var g := _hra()
	_karta(g, 0, &"boky")
	var r := _zahraj(g, 0, 13, 2, -0.08)
	_ocekavej("good timing", r.timing, Judge.Timing.GOOD)
	# (100 + 50) × 0,6 × 1 × 1,2 ; oblíbený styling +4, rozmanitost +2
	_ocekavej("good body", r.body, 108)
	_ocekavej("good pohoda", g.stav.pohoda, 76.0)

	_karta(g, 1, &"vlna")
	r = _zahraj(g, 1, 21, 3, 0.15)
	_ocekavej("miss timing", r.timing, Judge.Timing.MISS)
	_ocekavej("miss combo", g.skore.combo, 0)
	_ocekavej("miss pohoda", g.stav.pohoda, 71.0)
	_ocekavej("miss karta zůstává", g.ruka.karty[1].id, &"vlna")
	_ocekavej("miss výběr zrušen", g.ruka.vybrana, -1)


func test_spatne_drzeni() -> void:
	var g := _hra()
	_karta(g, 0, &"zavreni")
	var r := _zahraj(g, 0, 13, 2, 0.0)
	_ocekavej("zakopnutí logika", r.logika, Judge.Logika.SPATNE_DRZENI)
	_ocekavej("zakopnutí body", r.body, 0)
	_ocekavej("zakopnutí držení", g.stav.drzeni, &"zavrene")
	_ocekavej("zakopnutí pohoda", g.stav.pohoda, 60.0)
	_ocekavej("zakopnutí výběr zrušen", g.ruka.vybrana, -1)


func test_predcasna_priprava() -> void:
	var g := _hra()
	_karta(g, 0, &"boky")
	var r := _zahraj(g, 0, 17, 3, 0.0)  # doba 2 cyklu 2 => předčasně
	_ocekavej("předčasná příprava", r.priprava, Judge.Priprava.PREDCASNA)
	_ocekavej("předčasná max good", r.timing, Judge.Timing.GOOD)
	_karta(g, 1, &"vlna")
	r = _zahraj(g, 1, 31.5, 4, 0.0)  # doba 8
	_ocekavej("uspěchaná příprava", r.priprava, Judge.Priprava.USPECHANA)
	_ocekavej("uspěchaná max good", r.timing, Judge.Timing.GOOD)


func test_necinnost() -> void:
	var g := _hra()
	var nudy := []
	g.zakladni_krok.connect(func(_c: int, nuda: bool) -> void: nudy.append(nuda))
	g.update(_cas(8 * 5) + 0.3)  # uzavře cykly 0–5, z toho 2–5 po úvodu
	_ocekavej("nečinnost kroky", nudy, [false, false, true, true])
	_ocekavej("nečinnost pohoda", g.stav.pohoda, 64.0)


func test_uvod_a_ignorovani() -> void:
	var g := _hra()
	_ocekavej("výběr před dobou 12", g.tukni(0, _cas(10)), DanceGame.Akce.NIC)
	_ocekavej("výběr od doby 12", g.tukni(0, _cas(12.2)), DanceGame.Akce.VYBER)
	_ocekavej("vybraná mimo okno", g.tukni(0, _cas(13.5)), DanceGame.Akce.NIC)
	_ocekavej("potvrzení v úvodu nejde", g.tukni(0, _cas(8)), DanceGame.Akce.NIC)
	g.zvol_drzeni(&"otevrene", _cas(5))
	_ocekavej("držení v úvodu", g.stav.drzeni, &"otevrene")
	g.zvol_drzeni(&"zavrene", _cas(20))
	_ocekavej("držení po úvodu se nemění", g.stav.drzeni, &"otevrene")
	_ocekavej("mimo okno ±200 ms", g.tukni(0, _cas(16) + 0.25), DanceGame.Akce.NIC)


func test_akcent_a_fraze() -> void:
	var g := _hra([{ "doba": 37, "typ": "break" }])  # cyklus 4 = začátek fráze (doba 32)
	_karta(g, 0, &"vlna")
	var r := _zahraj(g, 0, 29, 4, 0.0)
	_ocekavej("akcent", r.akcent, true)
	_ocekavej("fráze", r.fraze, true)
	# (200 + 50 + 100 + 300) × 1,2
	_ocekavej("akcent body", r.body, 780)


func test_zahozeni() -> void:
	var g := _hra()
	var pred := g.ruka.karty[2]
	_ocekavej("zahození 1×", g.zahod(2, _cas(20), [-1, 0]), true)
	_ocekavej("zahození vyměnilo kartu", g.ruka.karty[2] != pred, true)
	_ocekavej("zahození 2× v cyklu", g.zahod(1, _cas(21), [-1, 0]), false)
	_ocekavej("zahození v dalším cyklu", g.zahod(1, _cas(25), [-1, 0]), true)


func test_vysledky() -> void:
	var g := _hra()
	_ocekavej("počet cyklů", g.pocet_cyklu, 50)
	_ocekavej("max skóre > 0", g.max_skore() > 0, true)
	var v := g.vysledky()
	_ocekavej("bez hraní 0 hvězd", v.hvezdy, 0)
