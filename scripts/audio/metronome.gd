class_name Metronome
extends Node
## Metronom podle Conductoru. Kliká podle mixovaného času, aby klik zazněl
## současně s hudbou (latence výstupu se tím vyruší).

@export var enabled := true

var conductor: Conductor

var _player: AudioStreamPlayer
var _click_hi: AudioStreamWAV
var _click_lo: AudioStreamWAV
var _last_click := -1


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	add_child(_player)
	_click_hi = ClickSound.make(1760.0)
	_click_lo = ClickSound.make(1100.0)


func reset() -> void:
	_last_click = -1


func _process(_delta: float) -> void:
	if not conductor or not conductor.is_playing():
		return
	var n := floori(conductor.beat_position_at(conductor.get_mix_time()))
	if n <= _last_click:
		return
	_last_click = n
	if enabled and n >= 0:
		_player.stream = _click_hi if Conductor.beat_in_cycle(n) == 1 else _click_lo
		_player.play()
