extends Control
## Herní obrazovka (PRD 6.1): lišta stavu, pár, časová osa, karty.
## Ovládání: ťuknutí na kartu = výběr / potvrzení, přejetí dolů = zahození.
## Na PC: klávesy 1–4 = ťuknutí na kartu, Shift+1–4 = zahození.

const SONG_PATH := SongDb.MVP_SONG
const PARTNERKA := &"mvp"
const PREJETI_PX := 80.0

var conductor: Conductor
var metronome: Metronome
var game: DanceGame

var _pisen_id: String
var _stisky := {}
var _hraje_se := false
var _feedback_do := -1.0

var _pohoda: Label
var _skore: Label
var _combo: Label
var _energie: ProgressBar
var _dancer: DancerView
var _figura_label: Label
var _feedback: Label
var _uvod: HBoxContainer
var _info: Label
var _timeline: TimelineView
var _karty: Array[CardView] = []
var _start: Button
var _vysledky: PanelContainer
var _vysledky_text: Label


func _ready() -> void:
	var song := SongDb.load_song(SONG_PATH)
	_pisen_id = SONG_PATH.get_file().get_basename()
	conductor = Conductor.new()
	add_child(conductor)
	conductor.load_song(song)
	conductor.finished.connect(_konec)
	metronome = Metronome.new()
	metronome.conductor = conductor
	metronome.enabled = SaveManager.get_setting("metronom")
	add_child(metronome)

	game = DanceGame.new(song, FigureDb.karty(), PartnerDb.get_by_id(PARTNERKA),
			load("res://data/balance.tres"), conductor.get_length())
	game.figura_vyhodnocena.connect(_on_figura)
	game.zakladni_krok.connect(_on_zakladni)
	game.zmena.connect(_obnov)
	_build_ui()
	_obnov()


func _build_ui() -> void:
	var box := UiKit.screen(self, 20, 10)

	var lista := UiKit.row(box, 12)
	_pohoda = _stat(lista)
	_skore = _stat(lista)
	_combo = _stat(lista)
	var energie_rada := UiKit.row(box, 12)
	var energie_label := UiKit.label("Energie", 22)
	energie_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	energie_rada.add_child(energie_label)
	_energie = ProgressBar.new()
	_energie.max_value = game.stav.partnerka.energie_max
	_energie.custom_minimum_size = Vector2(0, 22)
	_energie.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_energie.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_energie.show_percentage = false
	_energie.add_theme_stylebox_override("background", _plocha(Color(0.2, 0.2, 0.24)))
	_energie.add_theme_stylebox_override("fill", _plocha(Color(1.0, 0.75, 0.25)))
	energie_rada.add_child(_energie)

	_dancer = DancerView.new()
	_dancer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_dancer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_dancer)
	_figura_label = UiKit.label("", 30)
	_figura_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_figura_label.offset_top = 8
	_dancer.add_child(_figura_label)
	_feedback = UiKit.label("", 44)
	_feedback.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_feedback.offset_top = 56
	_dancer.add_child(_feedback)
	_uvod = HBoxContainer.new()
	_uvod.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_uvod.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_uvod.offset_top = 130
	_uvod.add_theme_constant_override("separation", 20)
	_dancer.add_child(_uvod)
	for d in [[&"otevrene", "Otevřené"], [&"zavrene", "Zavřené"]]:
		var b := UiKit.button(d[1], _uvod, 30, 90)
		b.custom_minimum_size.x = 220
		b.pressed.connect(func() -> void: game.zvol_drzeni(d[0], conductor.get_input_time()))

	_info = UiKit.label("", 24)
	box.add_child(_info)
	_timeline = TimelineView.new()
	_timeline.conductor = conductor
	_timeline.custom_minimum_size = Vector2(0, 80)
	box.add_child(_timeline)
	box.add_child(Control.new())  # místo pro značku akcentu pod osou

	var rada := UiKit.row(box, 10)
	rada.custom_minimum_size = Vector2(0, 290)
	for i in Hand.VELIKOST:
		var k := CardView.new()
		k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		k.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rada.add_child(k)
		_karty.append(k)

	_start = Button.new()
	_start.text = "Hrát"
	_start.focus_mode = Control.FOCUS_NONE
	_start.add_theme_font_size_override("font_size", 48)
	_start.custom_minimum_size = Vector2(320, 140)
	_start.set_anchors_preset(Control.PRESET_CENTER)
	_start.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_start.grow_vertical = Control.GROW_DIRECTION_BOTH
	_start.pressed.connect(_zacni)
	add_child(_start)

	_vysledky = PanelContainer.new()
	_vysledky.set_anchors_preset(Control.PRESET_CENTER)
	_vysledky.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_vysledky.grow_vertical = Control.GROW_DIRECTION_BOTH
	_vysledky.custom_minimum_size = Vector2(560, 0)
	var okno := _plocha(Color(0.16, 0.16, 0.19))
	okno.set_content_margin_all(32)
	okno.border_color = Color(0.4, 0.4, 0.45)
	okno.set_border_width_all(2)
	_vysledky.add_theme_stylebox_override("panel", okno)
	_vysledky.visible = false
	add_child(_vysledky)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 20)
	_vysledky.add_child(vb)
	_vysledky_text = UiKit.label("", 32)
	vb.add_child(_vysledky_text)
	var tl := UiKit.row(vb, 16)
	UiKit.button("Znovu", tl, 32, 96).pressed.connect(func() -> void: get_tree().reload_current_scene())
	UiKit.button("Menu", tl, 32, 96).pressed.connect(
			func() -> void: get_tree().change_scene_to_file("res://scenes/dev_menu.tscn"))


func _plocha(barva: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = barva
	sb.set_corner_radius_all(10)
	return sb


func _stat(parent: Control) -> Label:
	var l := UiKit.label("", 28)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(l)
	return l


func _zacni() -> void:
	_start.visible = false
	_hraje_se = true
	metronome.reset()
	conductor.play()


func _process(_delta: float) -> void:
	if not _hraje_se:
		return
	var t := conductor.get_input_time()
	game.update(t)
	var p := conductor.get_beat_position()
	_dancer.doba = p
	_uvod.visible = game.je_uvod(t)
	if p >= 0.0 and conductor.get_song_time() > _feedback_do:
		_feedback.text = ""
	_info.text = _info_text(p)


func _info_text(p: float) -> String:
	if p < 0.0:
		return "Připrav se…"
	var c := floori(p / 8.0)
	if game.je_uvod(conductor.get_input_time()):
		return "Úvod: zvol držení · první figura za %d dob" % ceili(game.b.uvod_dob - p)
	var casti: Array[String] = ["fráze %d · cyklus %d/4" % [c * 8 / game.song.delka_frazi_dob + 1, c % 4 + 1]]
	if not game.akcent(c + 1).is_empty():
		casti.append("další: AKCENT")
	elif game.je_fraze(c + 1):
		casti.append("další: začátek fráze")
	return " · ".join(casti)


func _obnov() -> void:
	var s := game.stav
	_pohoda.text = "Pohoda %d" % roundi(s.pohoda)
	var barva := Color(0.5, 0.9, 0.5) if s.pohoda >= 60 else (Color(1, 0.85, 0.4) if s.pohoda >= 30 else Color(1, 0.45, 0.4))
	_pohoda.add_theme_color_override("font_color", barva)
	_skore.text = "Skóre %d" % game.skore.skore
	_combo.text = "Combo ×%d" % game.skore.combo
	_energie.value = s.energie
	_dancer.drzeni = s.drzeni
	for i in _karty.size():
		var f := game.ruka.karty[i]
		_karty[i].nastav(f, game.ruka.vybrana == i, f.jde_z(s.drzeni))


func _ukaz(text: String, barva: Color) -> void:
	_feedback.text = text
	_feedback.add_theme_color_override("font_color", barva)
	_feedback_do = conductor.get_song_time() + 1.5


func _on_figura(r: Dictionary) -> void:
	var f: Figura = r.figura
	var p := conductor.get_beat_position()
	if r.timing == Judge.Timing.MISS:
		_ukaz("Miss", Color(1, 0.45, 0.4))
		_figura_label.text = "základní krok"
		return
	match r.logika:
		Judge.Logika.SPATNE_DRZENI:
			_ukaz("Zakopnutí!", Color(1, 0.45, 0.4))
			_figura_label.text = "%s nejde z tohoto držení" % f.nazev
			_dancer.reakce("?", true, p)
			return
		Judge.Logika.PRILIS_TEZKA:
			_dancer.reakce("!", true, p)
		Judge.Logika.BEZ_ENERGIE:
			_dancer.reakce("…", false, p)
	var text := "Perfect" if r.timing == Judge.Timing.PERFECT else "Good"
	var bonusy: Array[String] = []
	if r.akcent:
		bonusy.append("akcent")
	if r.fraze:
		bonusy.append("fráze")
	if r.logika == Judge.Logika.PRILIS_TEZKA:
		bonusy.append("příliš těžká")
	elif r.logika == Judge.Logika.BEZ_ENERGIE:
		bonusy.append("bez energie")
	text += "  +%d" % r.body
	if not bonusy.is_empty():
		text += "\n" + ", ".join(bonusy)
	_ukaz(text, Color(0.5, 0.9, 0.5) if r.timing == Judge.Timing.PERFECT else Color(0.6, 0.8, 1.0))
	_figura_label.text = f.nazev
	if r.akcent or f.typ == game.stav.partnerka.oblibeny_typ:
		_dancer.reakce("♥", false, p)


func _on_zakladni(_c: int, nuda: bool) -> void:
	_figura_label.text = "základní krok"
	if nuda:
		_ukaz("Partnerka se nudí", Color(1, 0.85, 0.4))
		_dancer.reakce("zZz", false, conductor.get_beat_position())


func _input(event: InputEvent) -> void:
	if not _hraje_se:
		return
	if event is InputEventScreenTouch:
		var t := conductor.get_input_time()
		if event.pressed:
			var i := _karta_pod(event.position)
			if i < 0:
				return
			var pred := [game.ruka.vybrana, game.ruka.vybrana_doba]
			var akce := game.tukni(i, t)
			_stisky[event.index] = { "i": i, "pos": event.position, "pred": pred, "akce": akce }
			_vibrace()
		elif _stisky.has(event.index):
			var s: Dictionary = _stisky[event.index]
			_stisky.erase(event.index)
			if s.akce != DanceGame.Akce.POTVRZENI and event.position.y - s.pos.y > PREJETI_PX:
				_zahod(s.i, t, s.pred)
	elif event is InputEventKey and event.pressed and not event.echo:
		var i: int = event.keycode - KEY_1
		if i < 0 or i >= Hand.VELIKOST:
			return
		var t := conductor.get_input_time()
		if event.shift_pressed:
			_zahod(i, t, [game.ruka.vybrana, game.ruka.vybrana_doba])
		else:
			game.tukni(i, t)


func _zahod(i: int, t: float, pred: Array) -> void:
	if not game.zahod(i, t, pred):
		_ukaz("Zahodit jde jen 1× za cyklus", Color(1, 0.85, 0.4))


func _karta_pod(pos: Vector2) -> int:
	for i in _karty.size():
		if _karty[i].get_global_rect().has_point(pos):
			return i
	return -1


func _vibrace() -> void:
	if SaveManager.get_setting("vibrace"):
		Input.vibrate_handheld(15)


func _konec() -> void:
	_hraje_se = false
	game.update(conductor.get_length() + 1.0)
	var v := game.vysledky()
	var rekord := SaveManager.uloz_vysledek(_pisen_id, v.skore, v.hvezdy)
	_vysledky_text.text = "%s\n\nSkóre %d%s\nMax. combo %d\nPohoda %d\n%d %% z maxima" % [
			"★".repeat(v.hvezdy) + "☆".repeat(3 - v.hvezdy), v.skore, "  (rekord!)" if rekord else "",
			v.max_combo, roundi(v.pohoda), roundi(v.podil * 100.0)]
	_vysledky.visible = true
