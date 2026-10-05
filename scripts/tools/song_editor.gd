extends Control
## Editor písně (PRD 8.2): offset první doby 1, BPM, akcenty, uložení do JSON.
##
## Klávesy na PC: mezerník = hrát/pauza, T nebo Enter = ťuknutí na dobu,
## A = akcent na aktuální dobu, šipky = offset ±1 ms (se Shiftem ±10 ms).

const TYPY_AKCENTU := ["break", "stop", "vrchol"]
const MIN_TAPS_OFFSET := 4
const MIN_TAPS_BPM := 16

var song: SongData
var song_path := SongDb.MVP_SONG
var conductor: Conductor
var metronome: Metronome

var _taps: Array[float] = []
var _tap_offset_ms := NAN
var _fit_bpm := NAN
var _fit_offset_ms := NAN
var _dirty := false
var _seeking := false

var _pos_label: Label
var _timeline: TimelineView
var _seek: HSlider
var _play_button: Button
var _offset_label: Label
var _bpm_label: Label
var _tap_zone: Panel
var _tap_label: Label
var _tap_result: Label
var _use_offset: Button
var _use_bpm: Button
var _accent_type: OptionButton
var _accent_list: ItemList
var _status: Label


func _ready() -> void:
	song = SongDb.load_song(song_path)
	conductor = Conductor.new()
	add_child(conductor)
	conductor.load_song(song)
	conductor.finished.connect(func() -> void: _play_button.text = "Hrát")
	metronome = Metronome.new()
	metronome.conductor = conductor
	add_child(metronome)
	_build_ui()
	_refresh_values()
	_refresh_accents()
	_refresh_taps()


func _build_ui() -> void:
	var box := UiKit.screen(self, 24, 12, true)

	box.add_child(UiKit.label("Editor písně – %s" % song.nazev, 30))
	_pos_label = UiKit.label("", 26)
	box.add_child(_pos_label)

	_timeline = TimelineView.new()
	_timeline.conductor = conductor
	_timeline.custom_minimum_size = Vector2(0, 80)
	box.add_child(_timeline)

	_seek = HSlider.new()
	_seek.max_value = conductor.get_length()
	_seek.step = 0.1
	_seek.focus_mode = Control.FOCUS_NONE
	_seek.custom_minimum_size = Vector2(0, 40)
	_seek.drag_started.connect(func() -> void: _seeking = true)
	_seek.drag_ended.connect(func(_changed: bool) -> void:
		_seeking = false
		_seek_to(_seek.value))
	box.add_child(_seek)

	var transport := UiKit.row(box)
	UiKit.button("|◀", transport).pressed.connect(func() -> void: _seek_to(0.0))
	UiKit.button("−10 s", transport).pressed.connect(func() -> void: _seek_to(conductor.get_song_time() - 10.0))
	_play_button = UiKit.button("Hrát", transport)
	_play_button.pressed.connect(_toggle_play)
	UiKit.button("+10 s", transport).pressed.connect(func() -> void: _seek_to(conductor.get_song_time() + 10.0))

	box.add_child(_section("Offset první doby 1"))
	_offset_label = UiKit.label("", 28)
	box.add_child(_offset_label)
	var off_row := UiKit.row(box, 6)
	for step in [-1000, -10, -1, 1, 10, 1000]:
		var text := ("%+d doba" % (step / 1000)) if absi(step) == 1000 else ("%+d" % step)
		UiKit.button(text, off_row, 24, 72).pressed.connect(_shift_offset.bind(step))

	box.add_child(_section("BPM"))
	_bpm_label = UiKit.label("", 28)
	box.add_child(_bpm_label)
	var bpm_row := UiKit.row(box, 6)
	for d in [-1.0, -0.1, 0.1, 1.0]:
		UiKit.button("%+.1f" % d, bpm_row, 24, 72).pressed.connect(_set_bpm.bind(d, 1.0))
	UiKit.button("×2", bpm_row, 24, 72).pressed.connect(_set_bpm.bind(0.0, 2.0))
	UiKit.button("÷2", bpm_row, 24, 72).pressed.connect(_set_bpm.bind(0.0, 0.5))

	box.add_child(_section("Ťukání na doby"))
	_tap_zone = Panel.new()
	_tap_zone.custom_minimum_size = Vector2(0, 120)
	_tap_zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_tap_zone)
	_tap_label = UiKit.label("", 26)
	_tap_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tap_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_tap_zone.add_child(_tap_label)
	_tap_result = UiKit.label("", 22)
	box.add_child(_tap_result)
	var tap_row := UiKit.row(box)
	_use_offset = UiKit.button("Použít offset", tap_row, 24, 72)
	_use_offset.pressed.connect(_apply_tap_offset)
	_use_bpm = UiKit.button("Použít BPM", tap_row, 24, 72)
	_use_bpm.pressed.connect(_apply_tap_bpm)
	UiKit.button("Vymazat", tap_row, 24, 72).pressed.connect(func() -> void:
		_taps.clear()
		_refresh_taps())
	UiKit.button("Export", tap_row, 24, 72).pressed.connect(_export_taps)

	box.add_child(_section("Akcenty"))
	var acc_row := UiKit.row(box)
	_accent_type = OptionButton.new()
	_accent_type.focus_mode = Control.FOCUS_NONE
	_accent_type.custom_minimum_size = Vector2(180, 72)
	_accent_type.add_theme_font_size_override("font_size", 24)
	for t in TYPY_AKCENTU:
		_accent_type.add_item(t)
	acc_row.add_child(_accent_type)
	UiKit.button("Akcent na aktuální dobu", acc_row, 24, 72).pressed.connect(_add_accent)
	_accent_list = ItemList.new()
	_accent_list.focus_mode = Control.FOCUS_NONE
	_accent_list.custom_minimum_size = Vector2(0, 180)
	_accent_list.add_theme_font_size_override("font_size", 24)
	box.add_child(_accent_list)
	var acc_row2 := UiKit.row(box)
	UiKit.button("Přejít před akcent", acc_row2, 24, 72).pressed.connect(_goto_accent)
	UiKit.button("Smazat akcent", acc_row2, 24, 72).pressed.connect(_delete_accent)

	var bottom := UiKit.row(box)
	UiKit.button("Zpět", bottom).pressed.connect(
			func() -> void: get_tree().change_scene_to_file("res://scenes/dev_menu.tscn"))
	var metro := UiKit.button("Metronom: zap", bottom)
	metro.toggle_mode = true
	metro.button_pressed = true
	metro.toggled.connect(func(on: bool) -> void:
		metronome.enabled = on
		metro.text = "Metronom: " + ("zap" if on else "vyp"))
	UiKit.button("Uložit", bottom).pressed.connect(_save)
	_status = UiKit.label("", 22)
	box.add_child(_status)


func _section(text: String) -> Label:
	var l := UiKit.label(text, 22)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	return l


# --- přehrávání ---

func _toggle_play() -> void:
	if conductor.is_playing():
		conductor.pause()
		_play_button.text = "Hrát"
	else:
		conductor.play(conductor.get_song_time())
		metronome.resync()
		_play_button.text = "Pauza"


func _seek_to(t: float) -> void:
	conductor.seek(t)
	conductor.resync()
	metronome.resync()


func _process(_delta: float) -> void:
	var t := conductor.get_song_time()
	if not _seeking:
		_seek.set_value_no_signal(t)
	var pos := conductor.beat_position_at(t)
	var beat_text := "intro"
	if pos >= 0.0:
		var n := floori(pos)
		beat_text = "doba %d (%d) · cyklus %d · fráze %d" % [
				n, Conductor.beat_in_cycle(n), n / 8 + 1, n / song.delka_frazi_dob + 1]
	_pos_label.text = "%s / %s · %s" % [
			UiKit.format_time(t), UiKit.format_time(conductor.get_length()), beat_text]


# --- offset a BPM ---

## step v ms, ±1000 znamená ±1 doba.
func _shift_offset(step: int) -> void:
	if absi(step) == 1000:
		song.offset_ms += signi(step) * song.seconds_per_beat * 1000.0
	else:
		song.offset_ms += step
	_after_grid_change()


func _set_bpm(delta: float, factor: float) -> void:
	song.bpm = clampf(snappedf(song.bpm * factor + delta, 0.01), 40.0, 260.0)
	_after_grid_change()


func _after_grid_change() -> void:
	conductor.resync()
	metronome.resync()
	_mark_dirty()
	_refresh_values()
	_refresh_accents()
	_refresh_taps()


func _refresh_values() -> void:
	_offset_label.text = "%d ms" % roundi(song.offset_ms)
	_bpm_label.text = "%s BPM  (doba %.1f ms)" % [song.bpm, song.seconds_per_beat * 1000.0]


# --- ťukání ---

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		if _tap_zone.get_global_rect().has_point(event.position):
			_tap()
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_T, KEY_ENTER:
			_tap()
		KEY_SPACE:
			_toggle_play()
		KEY_A:
			_add_accent()
		KEY_LEFT:
			_shift_offset(-10 if event.shift_pressed else -1)
		KEY_RIGHT:
			_shift_offset(10 if event.shift_pressed else 1)
		_:
			return
	get_viewport().set_input_as_handled()


func _tap() -> void:
	if not conductor.is_playing():
		return
	_taps.append(conductor.get_input_time())
	_refresh_taps()


## Z ťuknutí odhadne offset (fáze mřížky, BPM beze změny) a lineární regresí
## i BPM. Která doba je „1“, se nemění, posun mřížky je nejvýš půl doby.
## Pořadí ťuknutí nehraje roli, takže jde ťukat i po přetočení.
func _refresh_taps() -> void:
	_tap_offset_ms = NAN
	_fit_bpm = NAN
	_fit_offset_ms = NAN
	_tap_label.text = "Ťukej sem na každou dobu (%d)" % _taps.size()
	var spb := song.seconds_per_beat
	var lines: Array[String] = []
	if _taps.size() < MIN_TAPS_OFFSET:
		lines.append("pro odhad offsetu aspoň %d ťuknutí" % MIN_TAPS_OFFSET)
	else:
		var sx := 0.0
		var sy := 0.0
		for t in _taps:
			var a := TAU * (t - song.offset_s) / spb
			sx += cos(a)
			sy += sin(a)
		var shift := atan2(sy, sx) / TAU * spb
		var off := song.offset_s + shift
		_tap_offset_ms = off * 1000.0
		var dev := 0.0
		for t in _taps:
			var r := fposmod(t - off + spb / 2.0, spb) - spb / 2.0
			dev += r * r
		lines.append("offset %d ms (posun %+d ms, rozptyl ±%d ms) – BPM beze změny" % [
				roundi(_tap_offset_ms), roundi(shift * 1000.0), roundi(sqrt(dev / _taps.size()) * 1000.0)])

		var fit := _fit_grid(off, spb)
		if fit.is_empty():
			lines.append("pro odhad BPM ťukej aspoň %d dob v rozsahu 2+ cyklů" % MIN_TAPS_BPM)
		else:
			_fit_bpm = 60.0 / fit.b
			_fit_offset_ms = fit.a * 1000.0
			lines.append("BPM %.2f · offset %d ms · přesnost ±%.1f ms" % [
					_fit_bpm, roundi(_fit_offset_ms), fit.sigma / sqrt(fit.used) * 1000.0])
			lines.append("rozptyl ±%d ms · použito %d/%d ťuknutí · rozsah %d dob" % [
					roundi(fit.sigma * 1000.0), fit.used, _taps.size(), fit.span])
			if fit.has("thirds"):
				lines.append("odchylka začátek / střed / konec: %+d / %+d / %+d ms" % fit.thirds)
	_tap_result.text = "\n".join(lines)
	_use_offset.disabled = is_nan(_tap_offset_ms)
	_use_bpm.disabled = is_nan(_fit_bpm)


## Regrese t = a + b·n. Číslo doby n se přiřadí podle mřížky a mřížka se
## pak zpřesní; ťuknutí dál než čtvrt doby od mřížky (přeťuknutí) se vyřadí.
## Vrací {a, b, sigma, used, span, thirds?} nebo {}, když dat není dost.
func _fit_grid(a: float, b: float) -> Dictionary:
	var ns: Array[float] = []
	var ts: Array[float] = []
	for iter in 4:
		ns.clear()
		ts.clear()
		for t in _taps:
			var n := roundf((t - a) / b)
			if absf(t - (a + b * n)) <= b * 0.25:
				ns.append(n)
				ts.append(t)
		if ns.size() < MIN_TAPS_BPM or ns.max() - ns.min() < 16.0:
			return {}
		var mn := 0.0
		var mt := 0.0
		for i in ns.size():
			mn += ns[i]
			mt += ts[i]
		mn /= ns.size()
		mt /= ns.size()
		var cov := 0.0
		var vn := 0.0
		for i in ns.size():
			cov += (ns[i] - mn) * (ts[i] - mt)
			vn += (ns[i] - mn) * (ns[i] - mn)
		b = cov / vn
		a = mt - b * mn

	var n_min: float = ns.min()
	var span: float = ns.max() - n_min
	var res2 := 0.0
	var sums := [0.0, 0.0, 0.0]
	var counts := [0, 0, 0]
	for i in ns.size():
		var r := ts[i] - (a + b * ns[i])
		res2 += r * r
		var third := mini(int((ns[i] - n_min) / span * 3.0), 2)
		sums[third] += r
		counts[third] += 1
	var out := { "a": a, "b": b, "sigma": sqrt(res2 / ns.size()), "used": ns.size(), "span": int(span) }
	# při stálém tempu jsou všechny tři odchylky kolem nuly
	if span >= 64.0 and counts.min() > 0:
		out.thirds = [roundi(sums[0] / counts[0] * 1000.0), roundi(sums[1] / counts[1] * 1000.0),
				roundi(sums[2] / counts[2] * 1000.0)]
	return out


## Uloží ťuknutí (časy v s, seřazené) pro rozbor průběhu tempa mimo hru.
func _export_taps() -> void:
	var sorted := _taps.duplicate()
	sorted.sort()
	var path := "user://taps.json"
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		_status.text = "Export selhal (%s)" % error_string(FileAccess.get_open_error())
		return
	f.store_string(JSON.stringify({ "bpm": song.bpm, "offset_ms": song.offset_ms, "taps": sorted }, "", false, true))
	_status.text = "%d ťuknutí uloženo do %s" % [sorted.size(), ProjectSettings.globalize_path(path)]


func _apply_tap_offset() -> void:
	if is_nan(_tap_offset_ms):
		return
	song.offset_ms = _positive_offset(_tap_offset_ms)
	_after_grid_change()


func _apply_tap_bpm() -> void:
	if is_nan(_fit_bpm):
		return
	song.bpm = snappedf(_fit_bpm, 0.01)
	song.offset_ms = _positive_offset(_fit_offset_ms)
	_after_grid_change()


## Záporný offset (první doba 1 před začátkem souboru) posune o celé cykly.
func _positive_offset(ms: float) -> float:
	var cycle_ms := song.seconds_per_beat * 8000.0
	while ms < 0.0:
		ms += cycle_ms
	return ms


# --- akcenty ---

func _add_accent() -> void:
	var n := roundi(conductor.get_beat_position())
	if n < 0:
		_status.text = "Akcent musí být až po první době 1."
		return
	var typ: String = TYPY_AKCENTU[_accent_type.selected]
	for a in song.akcenty:
		if a.doba == n:
			a.typ = typ
			_mark_dirty()
			_refresh_accents()
			return
	song.akcenty.append({ "doba": n, "typ": typ })
	song.akcenty.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return x.doba < y.doba)
	_mark_dirty()
	_refresh_accents()


func _refresh_accents() -> void:
	_accent_list.clear()
	for a in song.akcenty:
		_accent_list.add_item("doba %d (%d) · cyklus %d · %s · %s" % [
				a.doba, Conductor.beat_in_cycle(a.doba), a.doba / 8 + 1, a.typ,
				UiKit.format_time(conductor.time_of_beat(a.doba))])


func _selected_accent() -> int:
	var sel := _accent_list.get_selected_items()
	return sel[0] if sel.size() > 0 else -1


func _goto_accent() -> void:
	var i := _selected_accent()
	if i >= 0:
		_seek_to(conductor.time_of_beat(song.akcenty[i].doba - 8))


func _delete_accent() -> void:
	var i := _selected_accent()
	if i >= 0:
		song.akcenty.remove_at(i)
		_mark_dirty()
		_refresh_accents()


# --- uložení ---

func _mark_dirty() -> void:
	_dirty = true
	_status.text = "Neuloženo"


func _save() -> void:
	var err := SongDb.save_song(song, song_path)
	if err == OK:
		_dirty = false
		_status.text = "Uloženo do %s" % song_path
	else:
		_status.text = "Uložení selhalo (%s)" % error_string(err)
