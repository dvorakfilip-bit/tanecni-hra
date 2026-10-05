class_name DanceGame
extends RefCounted
## Herní pravidla jedné písně (PRD 3–5). Nezávisí na audiu ani UI: dostává
## časy ťuknutí v sekundách písně (už po kalibraci) a průběžně čas přes update().
##
## Cyklus c = doby 8c..8c+7, figura cyklu c se potvrzuje na dobu 8c.

signal figura_vyhodnocena(r: Dictionary)
signal zakladni_krok(cyklus: int, nuda: bool)
signal zmena

enum Akce { NIC, VYBER, POTVRZENI }

const DOB_V_CYKLU := 8

var b: Balance
var song: SongData
var stav: DanceState
var ruka: Hand
var skore: ScoreSystem
## cyklus první figury (po úvodu)
var prvni_cyklus: int
## počet celých cyklů, které se vejdou do písně
var pocet_cyklu: int

var _vyreseno := {}
var _akcenty := {}
var _dalsi_cyklus := 0


func _init(s: SongData, karty: Array[Figura], p: Partnerka, balance: Balance,
		delka_s: float, rng_seed := -1) -> void:
	song = s
	b = balance
	stav = DanceState.new(p, b)
	ruka = Hand.new(karty, rng_seed)
	skore = ScoreSystem.new()
	prvni_cyklus = ceili(b.uvod_dob / float(DOB_V_CYKLU))
	pocet_cyklu = 0
	while cas_doby((pocet_cyklu + 1) * DOB_V_CYKLU) <= delka_s:
		pocet_cyklu += 1
	for a in s.akcenty:
		_akcenty[a.doba / DOB_V_CYKLU] = a


func cas_doby(n: int) -> float:
	return song.offset_s + n * song.seconds_per_beat


func doba_v(t: float) -> float:
	return (t - song.offset_s) / song.seconds_per_beat


func je_uvod(t: float) -> bool:
	return doba_v(t) < b.uvod_dob


func je_fraze(cyklus: int) -> bool:
	return (cyklus * DOB_V_CYKLU) % song.delka_frazi_dob == 0


func akcent(cyklus: int) -> Dictionary:
	return _akcenty.get(cyklus, {})


func zvol_drzeni(d: StringName, t: float) -> void:
	if je_uvod(t):
		stav.drzeni = d
		zmena.emit()


## Ťuknutí na kartu i v čase t. Vrací, co se stalo.
func tukni(i: int, t: float) -> Akce:
	var p := doba_v(t)
	var c := roundi(p / DOB_V_CYKLU)
	var odchylka := t - cas_doby(c * DOB_V_CYKLU)
	if ruka.vybrana == i:
		# druhé ťuknutí na vybranou kartu: potvrzení, jen v okně kolem doby 1
		if absf(odchylka) * 1000.0 <= b.miss_ms and c >= prvni_cyklus and c < pocet_cyklu \
				and not _vyreseno.has(c):
			_potvrd(c, i, odchylka)
			return Akce.POTVRZENI
		return Akce.NIC
	if p < b.uvod_vyber_od:
		return Akce.NIC
	ruka.vyber(i, floori(p))
	zmena.emit()
	return Akce.VYBER


## Zahození přejetím dolů, 1× za cyklus. predchozi_vyber = výběr před ťuknutím,
## kterým přejetí začalo (to kartu vybralo, ale hráč ji chtěl zahodit).
func zahod(i: int, t: float, predchozi_vyber: Array) -> bool:
	ruka.vybrana = predchozi_vyber[0]
	ruka.vybrana_doba = predchozi_vyber[1]
	var ok := ruka.zahod(i, floori(doba_v(t) / DOB_V_CYKLU))
	zmena.emit()
	return ok


## Uzavře cykly, jejichž okno potvrzení už skončilo (bez potvrzení = základní krok),
## a přičte pasivní regeneraci energie.
func update(t: float) -> void:
	while _dalsi_cyklus < pocet_cyklu \
			and t > cas_doby(_dalsi_cyklus * DOB_V_CYKLU) + b.miss_ms / 1000.0:
		if not _vyreseno.has(_dalsi_cyklus):
			_zakladni(_dalsi_cyklus)
		if _dalsi_cyklus >= prvni_cyklus:
			stav.zmen_energii(b.energie_pasivni)
			zmena.emit()
		_dalsi_cyklus += 1


func _zakladni(c: int) -> void:
	_vyreseno[c] = true
	if c < prvni_cyklus:
		return
	stav.zmen_energii(b.energie_regenerace)
	stav.zakladnich_po_sobe += 1
	var nuda := stav.zakladnich_po_sobe >= b.necinnost_od
	if nuda:
		stav.zmen_pohodu(b.pohoda_necinnost)
	zakladni_krok.emit(c, nuda)
	zmena.emit()


func _potvrd(c: int, i: int, odchylka: float) -> void:
	_vyreseno[c] = true
	var f := ruka.karty[i]
	var r := {
		"cyklus": c, "figura": f, "odchylka_ms": odchylka * 1000.0, "body": 0,
		"timing": Judge.timing(odchylka, b), "priprava": Judge.Priprava.SPRAVNA,
		"logika": Judge.Logika.OK, "fraze": false, "akcent": false, "rozmanitost": false,
	}

	if r.timing == Judge.Timing.MISS:
		skore.combo_reset()
		stav.zmen_pohodu(b.pohoda_miss)
		ruka.zrus_vyber()
		_zakladni_po_chybe()
		_hotovo(r)
		return

	r.priprava = Judge.priprava(Conductor.beat_in_cycle(ruka.vybrana_doba))
	if r.priprava != Judge.Priprava.SPRAVNA and r.timing == Judge.Timing.PERFECT:
		r.timing = Judge.Timing.GOOD
	if r.priprava == Judge.Priprava.PREDCASNA:
		stav.zmen_pohodu(b.pohoda_predcasna)

	r.logika = Judge.logika(f, stav)
	stav.zakladnich_po_sobe = 0
	ruka.pouzij(i)

	if r.logika == Judge.Logika.SPATNE_DRZENI:
		# zakopnutí: figura se neprovede, držení se nemění
		skore.combo_reset()
		stav.zmen_pohodu(b.pohoda_spatne_drzeni)
		_hotovo(r)
		return

	var pohoda_nasobic := stav.pohoda_nasobic()
	var combo_nasobic := skore.combo_nasobic(b)
	var zaklad := b.body_obtiznost[f.obtiznost - 1]

	if f.id not in stav.historie.slice(-b.rozmanitost_poslednich):
		r.rozmanitost = true
		zaklad += b.bonus_rozmanitost
		stav.zmen_pohodu(b.pohoda_rozmanitost)
	if je_fraze(c) and f.obtiznost >= b.fraze_min_obtiznost:
		r.fraze = true
		zaklad += b.bonus_fraze
	if not akcent(c).is_empty() and f.typ == &"efektni":
		r.akcent = true
		zaklad += b.bonus_akcent
		stav.zmen_pohodu(b.pohoda_akcent)
	if f.typ == stav.partnerka.oblibeny_typ:
		stav.zmen_pohodu(b.pohoda_oblibeny_typ)
	if r.timing == Judge.Timing.PERFECT:
		stav.zmen_pohodu(b.pohoda_perfect)
	if not stav.historie.is_empty() and stav.historie.back() == f.id \
			and stav.posledni_figura_cyklus == c - 1:
		stav.zmen_pohodu(b.pohoda_opakovani)

	var nasobic := (1.0 if r.timing == Judge.Timing.PERFECT else b.nasobic_good) \
			* combo_nasobic * pohoda_nasobic
	match r.logika:
		Judge.Logika.PRILIS_TEZKA:
			nasobic *= b.nasobic_prilis_tezka
			stav.zmen_pohodu(b.pohoda_prilis_tezka)
			skore.combo_reset()
		Judge.Logika.BEZ_ENERGIE:
			nasobic *= b.nasobic_bez_energie
			stav.zmen_pohodu(b.pohoda_bez_energie)
			skore.combo_plus()
		_:
			skore.combo_plus()

	stav.zmen_energii(-f.narocnost_energie)
	stav.drzeni = f.vystupni_drzeni(stav.drzeni)
	stav.historie.append(f.id)
	stav.posledni_figura_cyklus = c
	r.body = roundi(zaklad * nasobic)
	skore.pridej(r.body)
	_hotovo(r)


## Miss: pár tančí základní krok (doplní energii, počítá se do nečinnosti).
func _zakladni_po_chybe() -> void:
	stav.zmen_energii(b.energie_regenerace)
	stav.zakladnich_po_sobe += 1


func _hotovo(r: Dictionary) -> void:
	figura_vyhodnocena.emit(r)
	zmena.emit()


## Maximální skóre: každý cyklus figura referenční obtížnosti na Perfect,
## s rozmanitostí, všemi bonusy, rostoucím combem a pohodou 100.
func max_skore() -> int:
	var celkem := 0.0
	for k in range(pocet_cyklu - prvni_cyklus):
		var c := prvni_cyklus + k
		var zaklad := b.body_obtiznost[b.max_skore_obtiznost - 1] + b.bonus_rozmanitost
		if je_fraze(c):
			zaklad += b.bonus_fraze
		if not akcent(c).is_empty():
			zaklad += b.bonus_akcent
		celkem += zaklad * minf(1.0 + b.combo_krok * k, b.combo_max) * 1.5
	return roundi(celkem)


func vysledky() -> Dictionary:
	var maximum := max_skore()
	var podil := float(skore.skore) / maximum if maximum > 0 else 0.0
	var hvezdy := 0
	for prah in b.hvezdy_prahy:
		if podil >= prah:
			hvezdy += 1
	if hvezdy == 3 and stav.pohoda < b.hvezdy_min_pohoda:
		hvezdy = 2
	return {
		"skore": skore.skore, "max_combo": skore.max_combo, "pohoda": stav.pohoda,
		"podil": podil, "hvezdy": hvezdy,
	}
