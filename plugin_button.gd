extends Button

var plugin = {
	"name":"",
	"repo":""
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
	repo = get_node("/root/Repo")
