class_name DancerView
extends Control
## Zatím jen zástupná grafika páru: podlaha, dvě postavy, ruce podle držení,
## pohupování do rytmu a reakce partnerky. Animace figur přijdou později.

const C_PODLAHA := Color(0.18, 0.17, 0.2)
const C_LEADER := Color(0.25, 0.65, 0.6)
const C_PARTNERKA := Color(0.9, 0.45, 0.35)
const C_RUCE := Color(0.75, 0.75, 0.78)
const C_STIN := Color(0, 0, 0, 0.35)

var drzeni: StringName = &"zavrene"
var doba := 0.0
## krátké zatřesení partnerky (zakopnutí)
var _tres_do := -1.0
var _ikona := ""
var _ikona_do := -1.0


func reakce(ikona: String, zatrest: bool, doba_ted: float) -> void:
	_ikona = ikona
	_ikona_do = doba_ted + 3.0
	if zatrest:
		_tres_do = doba_ted + 1.5


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var stred := Vector2(size.x / 2, size.y * 0.72)
	var podlaha := PackedVector2Array()
	for i in 48:
		var a := TAU * i / 48
		podlaha.append(stred + Vector2(cos(a) * size.x * 0.44, sin(a) * size.y * 0.2))
	draw_colored_polygon(podlaha, C_PODLAHA)

	var rozestup := 70.0 if drzeni == &"zavrene" else 150.0
	var houp := absf(sin(PI * doba)) * 8.0
	var leader := stred + Vector2(-rozestup / 2, 0)
	var partnerka := stred + Vector2(rozestup / 2, 0)
	if doba < _tres_do:
		partnerka.x += sin(doba * 40.0) * 6.0

	_postava(leader, 1.0, C_LEADER, houp)
	_postava(partnerka, 0.88, C_PARTNERKA, houp)

	var ruka_l := leader + Vector2(18, -110 + houp)
	var ruka_p := partnerka + Vector2(-16, -100 + houp)
	match drzeni:
		&"zavrene":
			draw_line(ruka_l, ruka_p + Vector2(10, -6), C_RUCE, 5)
			draw_line(ruka_l + Vector2(0, 30), ruka_p + Vector2(0, 30), C_RUCE, 5)
		&"otevrene":
			draw_line(ruka_l + Vector2(0, 10), ruka_p + Vector2(0, 10), C_RUCE, 5)
			draw_line(ruka_l + Vector2(0, 34), ruka_p + Vector2(0, 34), C_RUCE, 5)
		&"jedna_ruka":
			draw_line(ruka_l + Vector2(0, 22), ruka_p + Vector2(0, 22), C_RUCE, 5)
		&"zkrizene":
			draw_line(ruka_l + Vector2(0, 8), ruka_p + Vector2(0, 36), C_RUCE, 5)
			draw_line(ruka_l + Vector2(0, 36), ruka_p + Vector2(0, 8), C_RUCE, 5)

	if doba < _ikona_do and _ikona != "":
		draw_string(get_theme_default_font(), partnerka + Vector2(-60, -190 + houp), _ikona,
				HORIZONTAL_ALIGNMENT_CENTER, 120, 34, Color.WHITE)


func _postava(pata: Vector2, meritko: float, barva: Color, houp: float) -> void:
	var stin := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24
		stin.append(pata + Vector2(cos(a) * 34 * meritko, sin(a) * 10 * meritko))
	draw_colored_polygon(stin, C_STIN)
	var telo := Rect2(pata + Vector2(-20, -120 + houp) * meritko, Vector2(40, 120 - houp) * meritko)
	draw_rect(telo, barva)
	draw_circle(pata + Vector2(0, -145 + houp) * meritko, 24 * meritko, barva.lightened(0.15))
