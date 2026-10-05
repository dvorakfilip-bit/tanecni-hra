class_name CardView
extends Control
## Karta figury (PRD 6.2). Vstup řeší herní obrazovka, karta se jen kreslí.

const ZVEDNUTI := 18.0
const C_BG := Color(0.2, 0.2, 0.24)
const C_BG_DIM := Color(0.14, 0.14, 0.16)
const C_BORDER := Color(0.4, 0.4, 0.45)
const C_SELECTED := Color(0.35, 0.6, 1.0)
const C_TEXT := Color(0.94, 0.94, 0.96)
const C_TEXT_DIM := Color(0.5, 0.5, 0.55)
const C_MALO_ENERGIE := Color(1.0, 0.4, 0.35)
const C_TYP := {
	&"prechod": Color(0.55, 0.75, 0.95),
	&"figura": Color(0.6, 0.85, 0.6),
	&"otocka": Color(0.95, 0.7, 0.4),
	&"styling": Color(0.9, 0.55, 0.8),
	&"efektni": Color(1.0, 0.85, 0.35),
}

var figura: Figura
var vybrana := false
var hratelna := true
## partnerka nemá na figuru dost energie
var malo_energie := false


func nastav(f: Figura, je_vybrana: bool, je_hratelna: bool, je_malo_energie: bool) -> void:
	if f == figura and je_vybrana == vybrana and je_hratelna == hratelna and je_malo_energie == malo_energie:
		return
	figura = f
	vybrana = je_vybrana
	hratelna = je_hratelna
	malo_energie = je_malo_energie
	queue_redraw()


func _draw() -> void:
	if not figura:
		return
	var rect := Rect2(Vector2(0, ZVEDNUTI), size - Vector2(0, ZVEDNUTI))
	if vybrana:
		rect.position.y -= ZVEDNUTI
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(14)
	sb.bg_color = C_BG if hratelna else C_BG_DIM
	sb.border_color = C_SELECTED if vybrana else C_BORDER
	sb.set_border_width_all(4 if vybrana else 1)
	sb.draw(get_canvas_item(), rect)

	var font := get_theme_default_font()
	var text := C_TEXT if hratelna else C_TEXT_DIM
	var w := rect.size.x - 16
	var x := rect.position.x + 8
	var y := rect.position.y + 14
	var typ_barva: Color = C_TYP.get(figura.typ, C_TEXT)
	if not hratelna:
		typ_barva = typ_barva.darkened(0.5)
	draw_string(font, Vector2(x, y + 20), Nazvy.typ(figura.typ), HORIZONTAL_ALIGNMENT_LEFT, w, 20, typ_barva)
	draw_multiline_string(font, Vector2(x, y + 58), figura.nazev, HORIZONTAL_ALIGNMENT_LEFT, w, 26, 3, text)
	var dole := rect.end.y - 16
	draw_string(font, Vector2(x, dole - 60), "%s →" % Nazvy.vstup(figura), HORIZONTAL_ALIGNMENT_LEFT, w, 19, text)
	var vystup := Nazvy.drzeni(figura.vystup) if figura.vystup != &"" else "stejné"
	draw_string(font, Vector2(x, dole - 34), vystup, HORIZONTAL_ALIGNMENT_LEFT, w, 19, text)
	var tecky := "●".repeat(figura.obtiznost) + "○".repeat(3 - figura.obtiznost)
	draw_string(font, Vector2(x, dole), tecky, HORIZONTAL_ALIGNMENT_LEFT, w, 20, text)
	var cena := "−%d" % figura.narocnost_energie if figura.narocnost_energie > 0 else "0"
	draw_string(font, Vector2(x, dole), cena, HORIZONTAL_ALIGNMENT_RIGHT, w, 22,
			C_MALO_ENERGIE if malo_energie else text)
