extends CheckBox

@onready var root = get_tree().root.get_child(0)

func _on_toggled(toggled_on):
	root.update_setting("crash_recovery", toggled_on)

func _on_root_settings_loaded():
	button_pressed = root.settings["crash_recovery"]
