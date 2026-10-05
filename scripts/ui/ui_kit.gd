class_name UiKit
extends RefCounted
## Pomocné funkce pro UI skládané v kódu (vývojářské a testovací scény).

const BG := Color(0.1, 0.1, 0.12)


## Pozadí a okraje přes celou obrazovku, vrací VBox pro obsah.
## scroll = obsah delší než obrazovka jde posouvat.
static func screen(parent: Control, margin := 32, separation := 20, scroll := false) -> VBoxContainer:
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(bg)
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, margin)
	parent.add_child(m)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	if scroll:
		var sc := ScrollContainer.new()
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		m.add_child(sc)
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sc.add_child(box)
	else:
		m.add_child(box)
	return box


static func label(text := "", font_size := 26) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", font_size)
	return l


## Tlačítko bez fokusu, aby mezerník a Enter nemačkaly naposledy použité tlačítko.
static func button(text: String, parent: Control, font_size := 28, min_height := 80) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, min_height)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", font_size)
	parent.add_child(b)
	return b


static func row(parent: Control, separation := 10) -> HBoxContainer:
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", separation)
	parent.add_child(r)
	return r


static func format_time(t: float) -> String:
	return "%d:%04.1f" % [int(t) / 60, fmod(t, 60.0)]
