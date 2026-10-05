class_name TimelineView
extends Control
## Časová osa jednoho cyklu 1-2-3-tap-5-6-7-tap (PRD 6.1).

const LABELS := ["1", "2", "3", "tap", "5", "6", "7", "tap"]
const GAP := 6.0

const C_CELL := Color(0.22, 0.22, 0.26)
const C_ONE := Color(0.22, 0.45, 0.85)
const C_WINDOW := Color(0.16, 0.55, 0.40)
const C_TAP := Color(0.16, 0.16, 0.19)
const C_TEXT := Color(0.92, 0.92, 0.95)
const C_TEXT_DIM := Color(0.55, 0.55, 0.6)
const C_CURSOR := Color(1, 1, 1)

var conductor: Conductor


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var w := size.x / 8.0
	var pos := -1.0
	if conductor and conductor.song:
		pos = conductor.get_beat_position()
	var in_cycle := fposmod(pos, 8.0) if pos >= 0.0 else -1.0
	var font := get_theme_default_font()
	var font_size := int(size.y * 0.32)

	for i in 8:
		var rect := Rect2(i * w + GAP / 2, 0, w - GAP, size.y)
		var c := C_CELL
		if i == 0:
			c = C_ONE
		elif i >= 4 and i <= 6:
			c = C_WINDOW
		elif i == 3 or i == 7:
			c = C_TAP
		if in_cycle >= 0.0 and int(in_cycle) == i:
			c = c.lightened(0.35)
		draw_rect(rect, c)
		var tc := C_TEXT_DIM if (i == 3 or i == 7) else C_TEXT
		var fs := font_size if LABELS[i] != "tap" else int(font_size * 0.6)
		var baseline := rect.position.y + (rect.size.y + fs * 0.7) / 2
		draw_string(font, Vector2(rect.position.x, baseline), LABELS[i],
				HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, fs, tc)

	if in_cycle >= 0.0:
		var x := in_cycle * w
		draw_line(Vector2(x, -6), Vector2(x, size.y + 6), C_CURSOR, 3.0)
