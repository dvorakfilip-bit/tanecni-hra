extends SceneTree
## Kontrola dat bez editoru:
## godot --headless --path . --script res://tools/check_data.gd


func _init() -> void:
	var ok := true
	var figury := FigureDb.load_all()
	print("Figury: %d (karet %d)" % [figury.size(), FigureDb.karty().size()])
	for f in figury:
		print("  %-22s %s -> %s  obt %d  en %d  %s" % [f.id, f.vstup, f.vystup, f.obtiznost, f.narocnost_energie, f.typ])
	ok = ok and figury.size() == 10

	var partnerky := PartnerDb.load_all()
	print("Partnerky: %d" % partnerky.size())
	for p in partnerky:
		print("  %s úroveň %d energie %d oblíbený %s" % [p.id, p.uroven, p.energie_max, p.oblibeny_typ])
	ok = ok and partnerky.size() == 1

	var song := SongDb.load_song(SongDb.MVP_SONG)
	ok = ok and song != null
	if song:
		var stream: AudioStream = load(song.soubor)
		print("Píseň: %s, %d BPM, doba %.4f s, offset %d ms, audio %s" % [
				song.nazev, song.bpm, song.seconds_per_beat, song.offset_ms,
				("%.1f s" % stream.get_length()) if stream else "CHYBÍ"])
		ok = ok and stream != null

	print("OK" if ok else "CHYBA")
	quit(0 if ok else 1)
