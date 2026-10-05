class_name ClickSound
extends RefCounted
## Generované kliky (sinus s doznívající obálkou).


static func make(freq: float, duration := 0.03, rate := 44100) -> AudioStreamWAV:
	var n := int(duration * rate)
	var data := PackedByteArray()
	data.resize(n * 2)
	_write_click(data, 0, freq, n, rate)
	return _wav(data, rate)


## Celá stopa kliků: první klik v lead_s, pak každou dobu, každý 4. vyšší.
## Hraje se přes Conductor stejně jako píseň, takže měří stejnou cestu audia.
static func make_track(bpm: float, beats: int, lead_s := 1.0, tail_s := 1.0, rate := 22050) -> AudioStreamWAV:
	var spb := 60.0 / bpm
	var total := int((lead_s + beats * spb + tail_s) * rate)
	var data := PackedByteArray()
	data.resize(total * 2)
	var click_len := int(0.03 * rate)
	for b in beats:
		var start := int((lead_s + b * spb) * rate)
		_write_click(data, start, 1760.0 if b % 4 == 0 else 1100.0, click_len, rate)
	return _wav(data, rate)


static func _write_click(data: PackedByteArray, start: int, freq: float, n: int, rate: int) -> void:
	for i in n:
		var env := 1.0 - float(i) / n
		var s := sin(TAU * freq * i / rate) * env * env * 0.8
		data.encode_s16((start + i) * 2, int(s * 32767.0))


static func _wav(data: PackedByteArray, rate: int) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = data
	return wav
