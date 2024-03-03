extends Button

@onready var root = get_tree().root.get_child(0)
@onready var start_last_button = get_tree().root.get_child(0).get_node("UI/ScrollContainer2/VBoxContainer/SettingsPanel/VBoxContainer/StartLastButton")
@onready var undeploy_button = get_tree().root.get_child(0).get_node("UI/ScrollContainer2/VBoxContainer/SettingsPanel/VBoxContainer/UndeployButton")

var plugin = {
	"name":"",
	"repo":"",
	"plugin_path":""
}

var repo = null

func _on_pressed():
	print("PluginButton: " + plugin["name"])
	start_last_button.plugin = plugin
	start_last_button.repository = repo
	undeploy_button.plugin = plugin
	undeploy_button.repository = repo
	if text != "Stop":
		text = "Stop"
		start_last_button.text = "Stop"
		undeploy_button.disabled = true
	else:
		text = plugin["name"]
		start_last_button.text = "Start " + repo.repo["name"]
		undeploy_button.disabled = false
	if repo != null:
		repo.plugin_selected(plugin)
		start_last_button.visible = true
		undeploy_button.visible = true

func _ready():
	text = plugin["name"]
	if "plugin_path" not in root.settings or root.settings["plugin_path"] == "":
		disabled = true
