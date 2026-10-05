extends Control
## Testovací scéna: přehrání písně, časová osa, metronom a měření odchylky ťuknutí.
## Ťuká se do plochy uprostřed (na PC myší nebo mezerníkem).

const PERFECT_MS := 50.0
const GOOD_MS := 120.0
const MISS_MS := 200.0
const PRUMER_Z := 16

var conductor: Conductor
var metronome: Metronome

var _info: Label
var _beat_label: Label
var _timeline: TimelineView
var _tap_zone: Panel
var _tap_result: Label
var _stats: Label
var _play_button: Button
var _devs: Array[float] = []


func _ready() -> void:
	var song := SongDb.load_song(SongDb.MVP_SONG)
	conductor = Conductor.new()
	add_child(conductor)
	conductor.load_song(song)
	conductor.finished.connect(_on_finished)
	metronome = Metronome.new()
	metronome.conductor = conductor
	add_child(metronome)
	_build_ui()
	_info.text = "%s – %s\n%s BPM · offset %d ms · délka %d s" % [
			song.nazev, song.interpret, song.bpm, song.offset_ms, conductor.get_length()]


func _build_ui() -> void:
	var box := UiKit.screen(self, 32, 24)

	_info = UiKit.label("", 26)
	box.add_child(_info)

	_beat_label = UiKit.label("—", 42)
	box.add_child(_beat_label)

	_timeline = TimelineView.new()
	_timeline.conductor = conductor
	_timeline.custom_minimum_size = Vector2(0, 110)
	box.add_child(_timeline)

	_tap_zone = Panel.new()
	_tap_zone.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tap_zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_tap_zone)
	_tap_result = UiKit.label("Ťukej sem do rytmu", 44)
	_tap_result.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tap_result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_tap_zone.add_child(_tap_result)

	_stats = UiKit.label("", 26)
	box.add_child(_stats)

	var buttons := UiKit.row(box, 16)
	UiKit.button("Zpět", buttons, 32, 96).pressed.connect(
			func() -> void: get_tree().change_scene_to_file("res://scenes/dev_menu.tscn"))
	_play_button = UiKit.button("Hrát", buttons, 32, 96)
	_play_button.pressed.connect(_on_play_pressed)
	var metro := UiKit.button("Metronom: zap", buttons, 32, 96)
	metro.toggle_mode = true
	metro.button_pressed = true
	metro.toggled.connect(func(on: bool) -> void:
		metronome.enabled = on
		metro.text = "Metronom: " + ("zap" if on else "vyp"))


func _on_play_pressed() -> void:
	if conductor.is_playing():
		conductor.stop()
		_play_button.text = "Hrát"
	else:
		_devs.clear()
		metronome.reset()
		conductor.play()
		_play_button.text = "Stop"


func _on_finished() -> void:
	_play_button.text = "Hrát"


func _process(_delta: float) -> void:
	if not conductor.is_playing():
		return
	var pos := conductor.get_beat_position()
	if pos < 0.0:
		_beat_label.text = "intro"
		return
	var n := floori(pos)
	_beat_label.text = "doba %d · cyklus %d · fráze %d" % [
			Conductor.beat_in_cycle(n), n / 8 + 1, n / conductor.song.delka_frazi_dob + 1]


func _input(event: InputEvent) -> void:
	var tapped := false
	if event is InputEventScreenTouch and event.pressed:
		tapped = _tap_zone.get_global_rect().has_point(event.position)
	elif event is InputEventKey and event.pressed and not event.echo:
		tapped = event.keycode == KEY_SPACE
	if not tapped or not conductor.is_playing():
		return
	# čas odečíst hned při zpracování vstupu
	var t := conductor.get_song_time()
	var pos := conductor.beat_position_at(t)
	var nearest := roundi(pos)
	var dev_ms := (t - conductor.time_of_beat(nearest)) * 1000.0
	_show_tap(dev_ms)


func _show_tap(dev_ms: float) -> void:
	var a := absf(dev_ms)
	var verdict := "Perfect" if a <= PERFECT_MS else ("Good" if a <= GOOD_MS else ("Miss" if a <= MISS_MS else "mimo"))
	_tap_result.text = "%s\n%+d ms" % [verdict, roundi(dev_ms)]
	_devs.append(dev_ms)
	if _devs.size() > PRUMER_Z:
		_devs.pop_front()
	var sum := 0.0
	for d in _devs:
		sum += d
	_stats.text = "průměr posledních %d ťuknutí: %+d ms\n(+ = pozdě, − = brzy) · latence výstupu %d ms" % [
			_devs.size(), roundi(sum / _devs.size()), roundi(conductor.get_output_latency() * 1000.0)]
