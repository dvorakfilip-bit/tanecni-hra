extends Node
## Autoload SaveManager: nastavení, kalibrace a nejlepší skóre v user:// (PRD 9.4).
signal settings_changed

const SETTINGS_PATH := "user://settings.cfg"
const SCORES_PATH := "user://scores.cfg"
const SECTION := "nastaveni"
const DEFAULTS := {
	"hlasitost_hudby": 1.0,
	"hlasitost_efektu": 1.0,
	"metronom": false,
	"vibrace": true,
	## + = hráč ťuká pozdě (dotyk a audio mají zpoždění), odečítá se od času ťuknutí
	"latence_ms": 0.0,
}

var _settings := DEFAULTS.duplicate()


func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	for key in DEFAULTS:
		_settings[key] = cfg.get_value(SECTION, key, DEFAULTS[key])


func get_setting(key: String) -> Variant:
	return _settings[key]


func set_setting(key: String, value: Variant) -> void:
	assert(DEFAULTS.has(key), "neznámé nastavení %s" % key)
	_settings[key] = value
	var cfg := ConfigFile.new()
	for k in _settings:
		cfg.set_value(SECTION, k, _settings[k])
	var err := cfg.save(SETTINGS_PATH)
	if err != OK:
		push_error("SaveManager: nastavení nejde uložit (%s)" % error_string(err))
	settings_changed.emit()


func latency_s() -> float:
	return float(_settings.latence_ms) / 1000.0


## Nejlepší výsledek písně: { "skore": int, "hvezdy": int }.
func nejlepsi(pisen: String) -> Dictionary:
	var cfg := ConfigFile.new()
	cfg.load(SCORES_PATH)
	return { "skore": cfg.get_value(pisen, "skore", 0), "hvezdy": cfg.get_value(pisen, "hvezdy", 0) }


## Uloží výsledek, pokud je lepší. Vrací true při novém rekordu skóre.
func uloz_vysledek(pisen: String, skore: int, hvezdy: int) -> bool:
	var cfg := ConfigFile.new()
	cfg.load(SCORES_PATH)
	var rekord := skore > int(cfg.get_value(pisen, "skore", 0))
	if rekord:
		cfg.set_value(pisen, "skore", skore)
	cfg.set_value(pisen, "hvezdy", maxi(hvezdy, int(cfg.get_value(pisen, "hvezdy", 0))))
	var err := cfg.save(SCORES_PATH)
	if err != OK:
		push_error("SaveManager: skóre nejde uložit (%s)" % error_string(err))
	return rekord
