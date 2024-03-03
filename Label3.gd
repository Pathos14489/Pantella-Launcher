extends Label

@onready var root = get_tree().root.get_child(0)

func _on_plugin_dir_dialog_dir_selected(dir):
	text = ""
	if dir == "":
		text = "Please set your plugin path!"

func _on_root_settings_loaded():
	text = ""
	if "plugin_path" not in root.settings or root.settings["plugin_path"] == "":
		text = "Please set your plugin path!"
