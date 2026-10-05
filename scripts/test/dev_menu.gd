extends Control
## Dočasné vývojářské menu, později ho nahradí hlavní menu hry.

const SCENES := [
	["Editor písně", "res://scenes/song_editor.tscn"],
	["Kalibrace", "res://scenes/calibration.tscn"],
	["Test timingu", "res://scenes/test_conductor.tscn"],
]


func _ready() -> void:
	var box := UiKit.screen(self, 48, 24)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(UiKit.label("Taneční hra – vývoj", 40))
	for s in SCENES:
		UiKit.button(s[0], box, 32, 110).pressed.connect(
				func() -> void: get_tree().change_scene_to_file(s[1]))
