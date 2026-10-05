class_name Judge
extends RefCounted
## Vyhodnocení timingu, přípravy a logiky figury (PRD 4).

enum Timing { PERFECT, GOOD, MISS, MIMO }
enum Priprava { PREDCASNA, SPRAVNA, USPECHANA }
enum Logika { OK, SPATNE_DRZENI, PRILIS_TEZKA, BEZ_ENERGIE }


static func timing(odchylka_s: float, b: Balance) -> Timing:
	var ms := absf(odchylka_s) * 1000.0
	if ms <= b.perfect_ms:
		return Timing.PERFECT
	if ms <= b.good_ms:
		return Timing.GOOD
	if ms <= b.miss_ms:
		return Timing.MISS
	return Timing.MIMO


## doba_v_cyklu 1–8 = kdy byla karta naposledy vybrána.
static func priprava(doba_v_cyklu: int) -> Priprava:
	if doba_v_cyklu <= 4:
		return Priprava.PREDCASNA
	if doba_v_cyklu <= 7:
		return Priprava.SPRAVNA
	return Priprava.USPECHANA


static func logika(f: Figura, stav: DanceState) -> Logika:
	if not f.jde_z(stav.drzeni):
		return Logika.SPATNE_DRZENI
	if f.obtiznost > stav.partnerka.uroven:
		return Logika.PRILIS_TEZKA
	if stav.energie < f.narocnost_energie:
		return Logika.BEZ_ENERGIE
	return Logika.OK
