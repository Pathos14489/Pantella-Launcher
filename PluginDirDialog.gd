extends FileDialog

@onready var root = get_tree().root.get_child(0)

func _on_path_label_pressed():
	visible = true

func _on_dir_selected(dir):
	$"../UI/ScrollContainer2/VBoxContainer/SettingsPanel/VBoxContainer/PathLabel".text = dir
	visible = false
	root.update_setting("plugin_path", dir)
