class_name Conductor
extends Node
## Hodiny písně. Čas se bere z pozice přehrávání audia, ne ze snímků (PRD 9.1).
## Doba 0 = první doba 1 písně (offset). Doby před ní jsou záporné.

signal beat(n: int)
signal cycle_start(cycle: int)
signal finished

const DOB_V_CYKLU := 8

var song: SongData

var _player: AudioStreamPlayer
var _output_latency := 0.0
var _last_beat := -1
var _last_time := 0.0


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	add_child(_player)
	_player.finished.connect(func() -> void: finished.emit())


func load_song(s: SongData) -> void:
	song = s
	_player.stream = load(s.soubor)


func play(from_s := 0.0) -> void:
	# get_output_latency() je drahé volání, stačí ho zjistit jednou při startu
	_output_latency = AudioServer.get_output_latency()
	_last_time = from_s
	_last_beat = maxi(ceili(beat_position_at(from_s)) - 1, -1)
	_player.play(from_s)


func stop() -> void:
	_player.stop()


func is_playing() -> bool:
	return _player.playing


func get_length() -> float:
	return _player.stream.get_length() if _player.stream else 0.0


## Čas v sekundách od začátku souboru, který je právě slyšet.
func get_song_time() -> float:
	if not _player.playing:
		return _last_time
	var t := get_mix_time() - _output_latency
	# pozice přehrávání skáče po blocích mixu, čas nesmí jít zpět
	if t < _last_time:
		t = _last_time
	_last_time = t
	return t


## Čas, který se právě mixuje (bez odečtení latence výstupu).
## Hodí se pro zvuky, které mají zaznít současně s hudbou (metronom).
func get_mix_time() -> float:
	return _player.get_playback_position() + AudioServer.get_time_since_last_mix()


func get_output_latency() -> float:
	return _output_latency


func beat_position_at(t: float) -> float:
	return (t - song.offset_s) / song.seconds_per_beat


func get_beat_position() -> float:
	return beat_position_at(get_song_time())


func time_of_beat(n: int) -> float:
	return song.offset_s + n * song.seconds_per_beat


## Doba v cyklu 1–8.
static func beat_in_cycle(n: int) -> int:
	return posmod(n, DOB_V_CYKLU) + 1


func _process(_delta: float) -> void:
	if not _player.playing:
		return
	var current := floori(get_beat_position())
	while _last_beat < current:
		_last_beat += 1
		beat.emit(_last_beat)
		if posmod(_last_beat, DOB_V_CYKLU) == 0:
			cycle_start.emit(_last_beat / DOB_V_CYKLU)
