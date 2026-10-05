extends Control
## Kalibrace latence (PRD 9.2): hráč ťuká do kliků, z odchylek se spočítá
## korekce a uloží do nastavení. Korekce jde i ručně doladit.

const BPM := 120.0
const COUNT_IN := 4        # první kliky jen poslouchat
const MEASURED := 24       # počítaných ťuknutí
const MIN_TAPS := 12
const TRIM_S := 0.08       # ťuknutí dál od mediánu se nepočítají
const MAX_SIGMA_MS := 60.0
const LEAD_S := 1.0

var conductor: Conductor

var _devs: Array[float] = []
var _result_ms := NAN

var _tap_zone: Panel
var _tap_label: Label
var _result: Label
var _current: Label
var _start: Button
var _save: Button


func _ready() -> void:
	conductor = Conductor.new()
	add_child(conductor)
	var song := SongData.from_dict({ "nazev": "Kalibrace", "bpm": BPM, "offset_ms": LEAD_S * 1000.0 })
	conductor.load_song(song, ClickSound.make_track(BPM, COUNT_IN + MEASURED + 4, LEAD_S))
	conductor.finished.connect(_finish)
	_build_ui()
	_refresh_current()


func _build_ui() -> void:
	var box := UiKit.screen(self, 40, 24)
	box.add_child(UiKit.label("Kalibrace latence", 40))
	box.add_child(UiKit.label(
			"Ťukej do plochy přesně s kliky. Prvních %d kliků jen poslouchej, pak ťukej %d×." % [COUNT_IN, MEASURED], 26))

	_tap_zone = Panel.new()
	_tap_zone.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tap_zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_tap_zone)
	_tap_label = UiKit.label("", 44)
	_tap_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tap_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_tap_zone.add_child(_tap_label)

	_result = UiKit.label("", 28)
	box.add_child(_result)

	var row := UiKit.row(box, 16)
	_start = UiKit.button("Začít", row, 32, 96)
	_start.pressed.connect(_begin)
	_save = UiKit.button("Uložit", row, 32, 96)
	_save.pressed.connect(func() -> void: _set_latency(_result_ms))
	_save.disabled = true

	_current = UiKit.label("", 28)
	box.add_child(_current)
	var manual := UiKit.row(box, 8)
	for step in [-5, -1, 1, 5]:
		UiKit.button("%+d ms" % step, manual, 26, 80).pressed.connect(
				func() -> void: _set_latency(SaveManager.get_setting("latence_ms") + step))

	UiKit.button("Zpět", box, 32, 96).pressed.connect(
			func() -> void: get_tree().change_scene_to_file("res://scenes/dev_menu.tscn"))
	_tap_label.text = "Zmáčkni Začít"


func _begin() -> void:
	_devs.clear()
	_result_ms = NAN
	_save.disabled = true
	_result.text = ""
	_start.text = "Znovu"
	_tap_label.text = "Poslouchej…"
	conductor.play()


func _process(_delta: float) -> void:
	if not conductor.is_playing() or _devs.size() > 0:
		return
	var n := floori(conductor.get_beat_position())
	if n >= 0 and n < COUNT_IN:
		_tap_label.text = "Poslouchej… %d" % (COUNT_IN - n)
	elif n >= COUNT_IN:
		_tap_label.text = "Ťukej!"


func _input(event: InputEvent) -> void:
	var tapped := false
	if event is InputEventScreenTouch and event.pressed:
		tapped = _tap_zone.get_global_rect().has_point(event.position)
	elif event is InputEventKey and event.pressed and not event.echo:
		tapped = event.keycode == KEY_SPACE
	if not tapped or not conductor.is_playing():
		return
	# surový čas bez korekce, ta se tu teprve měří
	var t := conductor.get_song_time()
	var n := roundi(conductor.beat_position_at(t))
	if n < COUNT_IN:
		return
	_devs.append(t - conductor.time_of_beat(n))
	_tap_label.text = "%d / %d" % [_devs.size(), MEASURED]
	if _devs.size() >= MEASURED:
		conductor.stop()
		_finish()


func _finish() -> void:
	if _devs.size() < MIN_TAPS:
		_tap_label.text = "Málo ťuknutí"
		_result.text = "Potřeba aspoň %d, zkus to znovu." % MIN_TAPS
		return
	var sorted := _devs.duplicate()
	sorted.sort()
	var median: float = sorted[sorted.size() / 2]
	var used := sorted.filter(func(d: float) -> bool: return absf(d - median) <= TRIM_S)
	var mean := 0.0
	for d in used:
		mean += d
	mean /= used.size()
	var var_sum := 0.0
	for d in used:
		var_sum += (d - mean) * (d - mean)
	var sigma_ms := sqrt(var_sum / used.size()) * 1000.0
	_result_ms = roundf(mean * 1000.0)
	_tap_label.text = "Hotovo"
	_result.text = "Naměřeno %+d ms (rozptyl ±%d ms, použito %d/%d)" % [
			_result_ms, roundi(sigma_ms), used.size(), _devs.size()]
	if sigma_ms > MAX_SIGMA_MS:
		_result.text += "\nŤukání bylo nepravidelné, raději to zopakuj."
	_save.disabled = false


func _set_latency(ms: float) -> void:
	if is_nan(ms):
		return
	SaveManager.set_setting("latence_ms", clampf(ms, -300.0, 300.0))
	conductor.input_latency = SaveManager.latency_s()
	_refresh_current()


func _refresh_current() -> void:
	_current.text = "Uložená korekce: %+d ms" % roundi(SaveManager.get_setting("latence_ms"))
