extends Button

@onready var root = get_tree().root.get_child(0)
@onready var plugins_menu = get_tree().root.get_child(0).get_node("UI/ScrollContainer2/VBoxContainer/PluginsMenu/VBoxContainer/Panel3/VBoxContainer/Plugins")
@onready var settings_panel = $"../.."
@onready var undeploy_button = get_tree().root.get_child(0).get_node("UI/ScrollContainer2/VBoxContainer/SettingsPanel/VBoxContainer/UndeployButton")

var plugin = {
	"name":"",
	"repo":"",
	"plugin_path":""
}
var repository = null

func _on_root_settings_loaded():
	visible = false
	if "last_loaded_plugin" in root.settings and root.settings["last_loaded_plugin"]["name"] != "":
		plugin = root.settings["last_loaded_plugin"]
		if plugin["name"] != "":
			for repo in root.repos.get_children():
				for plgin in repo.repo["plugins"]:
					if plgin == plugin:
						repository = repo
						break
			text = "Start " + repository.repo["name"]
			visible = true

func _on_pressed():
	if plugin:
		visible = true
		repository.get_node("Button").pressed.emit() # Open the repository
		var plugin_node = null
		for child in plugins_menu.get_children():
			if child.plugin == plugin:
				plugin_node = child
				break
		if plugin_node == null:
			print("Plugin not found")
		else:
			print("Plugin found")
			print(plugin_node)
			print(plugin_node.text)
			print(plugin)
			plugin_node._on_pressed()
		if repository.active:
			text = "Stop"
			plugin_node.text = "Stop"
			plugin_node.disabled = true
			undeploy_button.disabled = true
		else:
			text = "Start " + repository.repo["name"]
			plugin_node.text = plugin["name"]
			plugin_node.disabled = false
			undeploy_button.disabled = false
	else:
		visible = false

func _on_undeploy_button_pressed():
	visible = false
	plugin = {
		"name":"",
		"repo":"",
		"plugin_path":""
	}
	repository = null