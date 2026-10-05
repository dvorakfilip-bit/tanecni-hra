class_name Partnerka
extends Resource
## Partnerka. Data jsou v res://data/partnerky/*.tres.

@export var id: StringName
@export var nazev: String
## Maximální obtížnost figury, kterou zvládne.
@export_range(1, 3) var uroven: int = 1
@export_range(0, 100) var energie_max: int = 100
## Typ figur (viz Figura.typ), za které dává bonus k pohodě.
@export var oblibeny_typ: StringName
