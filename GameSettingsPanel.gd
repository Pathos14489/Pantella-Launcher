extends Panel
var DIR = OS.get_executable_path().get_base_dir() + "/"

var game = {
	"title": "",
	"mod_organizer_type": "",
	"mod_organizer_path": "",
	"filename": ""
}

func _on_mod_manager_option_button_item_selected(index): # 0 vortex, 1 mo2, -1 nothing
	print("Selected: " + str(index))
	if index == 0:
		$VBoxContainer/ModOrganizer2PathExplanation.visible = false
		$VBoxContainer/VortexPathExplanation.visible = true
		$VBoxContainer/WarningLabel2.visible = false
		game["mod_organizer_type"] = "vortex"
	elif index == 1:
		$VBoxContainer/ModOrganizer2PathExplanation.visible = true
		$VBoxContainer/VortexPathExplanation.visible = false
		$VBoxContainer/WarningLabel2.visible = false
		game["mod_organizer_type"] = "mo2"
	else:
		$VBoxContainer/ModOrganizer2PathExplanation.visible = false
		$VBoxContainer/VortexPathExplanation.visible = false
		$VBoxContainer/WarningLabel2.visible = true
		game["mod_organizer_type"] = ""
	save_changes()
		


func _on_mod_manager_directory_dialog_dir_selected(dir):
	$VBoxContainer/WarningLabel3.visible = false
	game["mod_organizer_path"] = str(dir)
	save_changes()

func _ready():
	if "mod_organizer_path" in game and game["mod_organizer_path"] != "":
		$VBoxContainer/ModManagerPathButton.text = game["mod_organizer_path"]
		$VBoxContainer/WarningLabel3.visible = false
		visible = true
	if "mod_organizer_type" in game and game["mod_organizer_type"] != "":
		if game["mod_organizer_type"] == "vortex":
			$VBoxContainer/ModManagerOptionButton.selected = 0
			$VBoxContainer/ModOrganizer2PathExplanation.visible = false
			$VBoxContainer/VortexPathExplanation.visible = true
			$VBoxContainer/WarningLabel2.visible = false
			visible = true
		elif game["mod_organizer_type"] == "mo2":
			$VBoxContainer/ModManagerOptionButton.selected = 1
			$VBoxContainer/ModOrganizer2PathExplanation.visible = true
			$VBoxContainer/VortexPathExplanation.visible = false
			$VBoxContainer/WarningLabel2.visible = false
			visible = true

func toggle_visibility():
	visible = !visible

func save_changes():
	print(game)
	var json_path = "res://game_configs/" + game.file_name
	if !OS.has_feature("standalone"):
		json_path = ProjectSettings.globalize_path(json_path)
	else:
		json_path = DIR + json_path.replace("res://", "")
	# Overwrite the file
	var file = FileAccess.open(json_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(game, "\t"))
	file.close()

func _on_v_box_container_resized():
	custom_minimum_size.y = $VBoxContainer.size.y + 105

func _on_clear_button_pressed():
	$VBoxContainer/ModManagerOptionButton.selected = -1
	$VBoxContainer/ModManagerPathButton.text = ""
	$VBoxContainer/WarningLabel3.visible = true
	$VBoxContainer/ModOrganizer2PathExplanation.visible = false
	$VBoxContainer/VortexPathExplanation.visible = false
	$VBoxContainer/WarningLabel2.visible = true
	game["mod_organizer_type"] = ""
	game["mod_organizer_path"] = ""
	save_changes()
