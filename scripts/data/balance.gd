class_name Balance
extends Resource
## Herní konstanty. Jsou v datech (res://data/balance.tres), aby šly ladit
## bez úprav kódu (PRD 9.6).

@export_group("Timing")
@export var perfect_ms := 50.0
@export var good_ms := 120.0
@export var miss_ms := 200.0

@export_group("Úvod")
## Počet dob úvodu, první figura jde potvrdit na dobu uvod_dob (počítáno od 0).
@export var uvod_dob := 16
## Od které doby (od 0) jde v úvodu vybrat kartu (5. doba druhého cyklu).
@export var uvod_vyber_od := 12

@export_group("Energie")
## Základní krok doplní energii.
@export var energie_regenerace := 15
## Každý cyklus po úvodu doplní energii, ať se tancuje cokoli.
@export var energie_pasivni := 3

@export_group("Pohoda")
@export var pohoda_start := 70.0
@export var pohoda_perfect := 3.0
@export var pohoda_oblibeny_typ := 4.0
@export var pohoda_akcent := 6.0
@export var pohoda_rozmanitost := 2.0
@export var pohoda_predcasna := -2.0
@export var pohoda_spatne_drzeni := -10.0
@export var pohoda_prilis_tezka := -12.0
@export var pohoda_bez_energie := -6.0
@export var pohoda_miss := -5.0
@export var pohoda_necinnost := -3.0
## Od kolikátého základního kroku po sobě pohoda klesá.
@export var necinnost_od := 3
@export var pohoda_opakovani := -2.0

@export_group("Skóre")
## Body podle obtížnosti 1–3.
@export var body_obtiznost: Array[int] = [100, 200, 300]
@export var nasobic_good := 0.6
@export var combo_krok := 0.1
@export var combo_max := 2.0
@export var bonus_rozmanitost := 50
## Figura, která nebyla mezi posledními N, dává bonus za rozmanitost.
@export var rozmanitost_poslednich := 3
@export var bonus_fraze := 100
@export var fraze_min_obtiznost := 2
@export var bonus_akcent := 300
@export var nasobic_prilis_tezka := 0.5
@export var nasobic_bez_energie := 0.5

@export_group("Hvězdičky")
## Podíl z maximálního skóre pro 1, 2 a 3 hvězdičky.
@export var hvezdy_prahy: Array[float] = [0.40, 0.65, 0.85]
@export var hvezdy_min_pohoda := 50.0
## Obtížnost, se kterou se počítá maximální skóre písně.
@export var max_skore_obtiznost := 2
