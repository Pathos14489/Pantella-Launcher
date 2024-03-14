extends Node

var DIR = OS.get_executable_path().get_base_dir() + "/"

@export var repositories_dir = "res://repositories/"
@export var repo_configs_dir = "res://repo_configs/"
@export var temp_dir = "res://temp/"
@export var settings_file = "res://launcher_settings.json"
@onready var plugins_menu = get_tree().root.get_child(0).get_node("UI/ScrollContainer2/VBoxContainer/PluginsMenu")
@onready var status_bar = $UI/StatusBarPanel/Hotbar/StatusBar
@onready var repos = $UI/ScrollContainer/VBoxContainer/CenterContainer/repos
@onready var game_settings = $UI/Settings/Panel/Control/ScrollContainer/VBoxContainer/GamesPanel/VBoxContainer/GamesSettings

var settings = {
	"plugin_path":"",
	"crash_recovery":true,
	"debug_console": true,
	"last_loaded_plugin": {
		"name": "",
		"repo": "",
		"plugin_path": ""
	}
}

signal settings_loaded

var available_configs = 0
var installed_configs = 0

func update_setting(key, value):
	settings[key] = value
	save_settings()

func save_settings():
	var file = FileAccess.open(settings_file, FileAccess.WRITE)
	file.store_string(JSON.stringify(settings, "\t"))
	file.close()

func _ready():
	if !OS.has_feature("standalone"):
		repositories_dir = ProjectSettings.globalize_path(repositories_dir)
	else:
		repositories_dir = DIR + repositories_dir.replace("res://", "")
	if !OS.has_feature("standalone"):
		temp_dir = ProjectSettings.globalize_path(temp_dir)
	else:
		temp_dir = DIR + temp_dir.replace("res://", "")
	if !OS.has_feature("standalone"):
		settings_file = ProjectSettings.globalize_path(settings_file)
	else:
		settings_file = DIR + settings_file.replace("res://", "")
	# Make sure the directory exists
	DirAccess.make_dir_absolute(repositories_dir)
	DirAccess.make_dir_absolute(temp_dir)
	# Count how many repositories are in the directory
	var repositories_dir_access = DirAccess.open(repositories_dir)
	repositories_dir_access.list_dir_begin()
	var file_name = repositories_dir_access.get_next()
	while file_name != "":
		if not file_name.ends_with(".ini") and not file_name.ends_with(".gdignore"):
				installed_configs += 1
		file_name = repositories_dir_access.get_next()
	# Count how many repositories are in the directory
	var repo_configs_diraccess = DirAccess.open(repo_configs_dir)
	repo_configs_diraccess.list_dir_begin()
	file_name = repo_configs_diraccess.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			available_configs += 1
			var config = FileAccess.open(repo_configs_dir + file_name, FileAccess.READ)
			var data = config.get_as_text()
			var config_data = JSON.parse_string(data)
			config.close()
			for plugin in config_data["plugins"]:
				available_configs += 1
			file_name = repo_configs_diraccess.get_next()
	# Update the status bar
	status_bar.text = "Loaded " + str(installed_configs) + " of " + str(available_configs) + " available configurations."
	# Load settings
	if FileAccess.file_exists(settings_file):
		var file = FileAccess.open(settings_file, FileAccess.READ)
		var data = file.get_as_text()
		file.close()
		settings = JSON.parse_string(data)
		fix_settings()
	else:
		save_settings()
	settings_loaded.emit()

func fix_settings():
	if "last_loaded_plugin" not in settings:
		settings["last_loaded_plugin"] = {
			"name": "",
			"repo": ""
		}
		save_settings()
	if "plugin_path" not in settings:
		settings["plugin_path"] = ""
		save_settings()
	if "crash_recovery" not in settings:
		settings["crash_recovery"] = true
		save_settings()
	if "debug_console" not in settings:
		settings["debug_console"] = true
		save_settings()

func get_plugin_path():
	var p_path = settings["plugin_path"]
	if not p_path.ends_with("/"):
		p_path += "/"
	return p_path

# func plugin_selected(plugin):
# 	print("Plugin selected")
# 	if settings["last_loaded_plugin"]["name"] == "" or settings["last_loaded_plugin"]["name"] != plugin["name"]: # If the last plugin was different
# 		print("Last plugin was different")
# 		var new_plugin_dir = repositories_dir + plugin["repo"].replace("/", "_")
# 		if not new_plugin_dir.ends_with("/"):
# 			new_plugin_dir += "/"
# 		# Move the last plugin from the plugin_path to the last_plugin_dir
		
# 		if settings["last_loaded_plugin"]["repo"] != "":
# 			var last_plugin_dir = repositories_dir + settings["last_loaded_plugin"]["repo"].replace("/", "_")
# 			OS.execute("powershell.exe", ["mv", get_plugin_path()+"*", last_plugin_dir])
# 		# Move the new plugin from the new_plugin_dir to the plugin_path
# 		OS.execute("powershell.exe", ["mv", new_plugin_dir+"*", get_plugin_path()])
# 		# Update the last_loaded_plugin setting
# 		update_setting("last_loaded_plugin", plugin)
			
func _on_undeploy_button_pressed(): # unload last plugin
	#status_bar.text = "Unloading "+settings["last_loaded_plugin"]["name"]+"..."
	#var last_plugin_dir = repositories_dir + settings["last_loaded_plugin"]["repo"].replace("/", "_")
	#OS.execute("powershell.exe", ["mv", get_plugin_path()+"*", last_plugin_dir])
	#update_setting("last_loaded_plugin", {"name": "", "repo": ""})
	for plugin_node in get_tree().get_nodes_in_group("plugin"):
		plugin_node.undeploy()


func _on_games_settings_games_loaded():
	pass # Replace with function body.


func _a_plugin_installed():
	$UI/StatusBarPanel/Hotbar/UndeployButton.disabled = false

func _a_plugin_undeployed():
	var any_plugins_deployed = false
	for plugin_node in get_tree().get_nodes_in_group("plugin"):
		if plugin_node.installed:
			any_plugins_deployed = true
			break
	if not any_plugins_deployed:
		$UI/StatusBarPanel/Hotbar/UndeployButton.disabled = true


func _on_update_button_pressed():
	for repo in get_tree().get_nodes_in_group("repository"):
		repo.check_for_updates(true)

func show_spinner():
	$UI/StatusBarPanel/Hotbar/Spinner.visible = true
	
func hide_spinner():
	$UI/StatusBarPanel/Hotbar/Spinner.visible = false
