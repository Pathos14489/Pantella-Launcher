extends Button

@onready var root = get_tree().root.get_child(0)

var plugin = {
	"name":"",
	"repo":"",
	"plugin_path":""
}
var repository = null

func _on_root_settings_loaded():
	disabled = true
	if "last_loaded_plugin" in root.settings and root.settings["last_loaded_plugin"]["name"] != "":
		plugin = root.settings["last_loaded_plugin"]
	if plugin["name"] != "":
		disabled = false
	else:
		disabled = true

func _on_pressed():
	disabled = true
	
func _on_hotbar_resized():
	custom_minimum_size.x = $"..".size.y
