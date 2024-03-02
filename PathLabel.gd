extends Button

@onready var root = get_tree().root.get_child(0)

func _on_root_settings_loaded():
	if root.settings["plugin_path"] != "":
		text = root.settings["plugin_path"]
