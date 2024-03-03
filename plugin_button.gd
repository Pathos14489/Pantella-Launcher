extends Button

@onready var root = get_tree().root.get_child(0)

var plugin = {
	"name":"",
	"repo":"",
	"plugin_path":""
}

var repo = null

func _on_pressed():
	if text == plugin["name"]:
		text = "Stop"
	else:
		text = plugin["name"]
	if repo != null:
		repo.plugin_selected(plugin)

func _ready():
	text = plugin["name"]
	if "plugin_path" not in root.settings or root.settings["plugin_path"] == "":
		disabled = true
