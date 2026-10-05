class_name ClickSound
extends RefCounted
## Krátký generovaný klik (sinus s doznívající obálkou).


static func make(freq: float, duration := 0.03, rate := 44100) -> AudioStreamWAV:
	var n := int(duration * rate)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var env := 1.0 - float(i) / n
		var s := sin(TAU * freq * i / rate) * env * env * 0.8
		data.encode_s16(i * 2, int(s * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = data
	return wav
