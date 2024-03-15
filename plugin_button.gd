extends Panel

var DIR = OS.get_executable_path().get_base_dir() + "/"

@onready var root = get_tree().root.get_child(0)
@onready var start_last_button = get_tree().root.get_child(0).get_node("UI/ScrollContainer2/VBoxContainer/SettingsPanel/VBoxContainer/StartLastButton")
@onready var undeploy_button = get_tree().root.get_child(0).get_node("UI/ScrollContainer2/VBoxContainer/SettingsPanel/VBoxContainer/UndeployButton")

var plugin = {
	"games": [], # not used, but it is here
	"name":"",
	"patches": [],
	"repo":"",
	"blacklist": []
}

var game = ""

var repo = null

var game_settings_node = null

var mod_organizer_path = ""
var plugin_path = ""
var source_path = ""
var plugin_commit_history_path = ""

var installed = false

signal plugin_active
signal plugin_installed

func _ready():
	visible = false
	$HBoxContainer/InstallButton.disabled = true
	for gsn in root.get_node("UI/Settings/Panel/Control/ScrollContainer/VBoxContainer/GamesPanel/VBoxContainer/GamesSettings").get_children():
		if gsn.game["slug"] == game: 
			game_settings_node = gsn
			if game_settings_node.game["mod_organizer_type"] != "" and game_settings_node.game["mod_organizer_path"] != "":
				visible = true
			$HBoxContainer/Label.text = game_settings_node.game["title"] + " - " + plugin["name"]
			$HBoxContainer/GameIcon.texture = root.game_settings.game_icon_textures[game_settings_node.game["slug"]]
			if game_settings_node.game.mod_organizer_type != "":
				$HBoxContainer/ModManagerIcon.texture = root.game_settings.mod_manager_icon_textures[game_settings_node.game.mod_organizer_type]
			mod_organizer_path = game_settings_node.game["mod_organizer_path"]
			if gsn.game["mod_organizer_type"] == "mo2":
				plugin_path = mod_organizer_path + "/mods/"
			else:
				plugin_path = mod_organizer_path + "/"
			source_path = "res://repositories/" + plugin["repo"].replace("/", "_")
			if !OS.has_feature("standalone"):
				source_path = ProjectSettings.globalize_path(source_path)
			else:
				source_path = DIR + source_path.replace("res://", "")
			plugin_commit_history_path = "res://install_info/" + plugin["repo"].replace("/", "_") + ".json"
			if !OS.has_feature("standalone"):
				plugin_commit_history_path = ProjectSettings.globalize_path(plugin_commit_history_path)
			else:
				plugin_commit_history_path = DIR + plugin_commit_history_path.replace("res://", "")
			plugin_active.emit()
			break # only one game can be selected at a time

func _on_plugin_active():
	installed = false
	$HBoxContainer/InstallButton.disabled = false
	$HBoxContainer/InstallButton.text = "Deploy"
	$HBoxContainer/UndeployButton.disabled = true
	$HBoxContainer/UndeployButton.visible = false
	var mod_organizer_dir = DirAccess.open(mod_organizer_path)
	if mod_organizer_dir:
		if mod_organizer_dir.dir_exists(plugin_path + "/" + plugin["repo"].replace("/", "_") + "/"):
			plugin_installed.emit()

func _on_install_button_pressed():
	$HBoxContainer/InstallButton.disabled = true
	$HBoxContainer/InstallButton.text = "Installing..."
	var mod_manager_dir = DirAccess.open(mod_organizer_path)
	if !mod_manager_dir.dir_exists(plugin_path):
		mod_manager_dir.make_dir(plugin_path)
	source_path = "\""+source_path+"/\""
	print("Copying " + source_path + " to " + plugin_path+plugin["repo"].replace("/", "_"))
	OS.execute("powershell.exe", ["Copy-Item", "-Recurse", "\""+source_path.replace(" ","' '")+"\"", "\""+plugin_path.replace(" ","' '")+"\""])
	# copy commit history
	OS.execute("powershell.exe", ["Copy-Item", "\""+plugin_commit_history_path.replace(" ","' '")+"\"", "\""+str(plugin_path+plugin["repo"].replace("/", "_")).replace(" ","' '")+"/commit_history.json"+"\""])
	for patch in plugin["patches"]: # Extract patches from res://plugin_patches/{patch} to the plugin folder
		var patch_path = "res://plugin_patches/" + patch
		if !OS.has_feature("standalone"):
			patch_path = ProjectSettings.globalize_path(patch_path)
		else:
			patch_path = DIR + patch_path.replace("res://", "")
		print("Patching " + patch_path + " to " + plugin_path+"/"+plugin["repo"].replace("/", "_"))
		OS.execute("tar", ["-xf", "\""+patch_path+"\"", "-C", "\""+plugin_path+"/"+plugin["repo"].replace("/", "_")+"\""])
	plugin_installed.emit()

func _on_plugin_installed():
	installed = true
	$HBoxContainer/InstallButton.text = "Deployed"
	$HBoxContainer/InstallButton.disabled = true
	$HBoxContainer/UndeployButton.disabled = false
	$HBoxContainer/UndeployButton.visible = true
	root._a_plugin_installed()

func _repo_updated():
	print("repo updated")
	$HBoxContainer/InstallButton.text = "Updating..."
	$HBoxContainer/UndeployButton.disabled = true
	$HBoxContainer/UndeployButton.visible = true



	$HBoxContainer/UndeployButton.disabled = false
	$HBoxContainer/UndeployButton.visible = true
	$HBoxContainer/InstallButton.text = "Deployed"

func undeploy():
	if !installed:
		return
	$HBoxContainer/InstallButton.text = "Uninstalling..."
	OS.move_to_trash(plugin_path + "/" + plugin["repo"].replace("/", "_")) # move plugin to trash
	$HBoxContainer/InstallButton.disabled = false
	$HBoxContainer/InstallButton.text = "Deploy"
	$HBoxContainer/UndeployButton.disabled = true
	$HBoxContainer/UndeployButton.visible = false
	plugin_active.emit()
	root._a_plugin_undeployed()
