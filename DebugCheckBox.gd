extends CheckBox

@onready var root = get_tree().root.get_child(0)

func _on_toggled(toggled_on):
	root.update_setting("debug_console", toggled_on)

func _on_root_settings_loaded():
	button_pressed = root.settings["debug_console"]
