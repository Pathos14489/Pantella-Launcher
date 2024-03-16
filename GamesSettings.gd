extends GridContainer

@onready var game_settings_panel = preload("res://GameSettingsPanel.tscn")
@onready var game_toggles = $"../../../HBoxContainer2/VBoxContainer2/GameToggles"
@onready var label = $"../GameSettingsLabel"

var DIR = OS.get_executable_path().get_base_dir() + "/"

var game_configs_dir = "res://game_configs/"
var game_icons_dir = "res://game_icons/"

var game_configs = []
var game_icon_textures_filename = []
var game_icon_textures = {}
var mod_manager_icon_textures = {}

signal games_loaded

func _ready():
	if !OS.has_feature("standalone"):
		game_configs_dir = ProjectSettings.globalize_path(game_configs_dir)
	else:
		game_configs_dir = DIR + game_configs_dir.replace("res://", "")
	print(game_configs_dir)
	# For each file in the game_icons_dir load the texture
	var game_icons_dir_access = DirAccess.open(game_icons_dir)
	if game_icons_dir_access:
		game_icons_dir_access.list_dir_begin()
		var file_name = game_icons_dir_access.get_next()
		while file_name != "":
			if file_name.ends_with(".png"):
				game_icon_textures_filename.append(file_name)
			file_name = game_icons_dir_access.get_next()
	for game_icon_texture in game_icon_textures_filename:
		var image = Image.load_from_file(game_icons_dir + game_icon_texture)
		var texture = ImageTexture.create_from_image(image)
		game_icon_textures[game_icon_texture.replace(".png", "")] = texture
	# For each file in the game_configs_dir
	var game_configs_dir_access = DirAccess.open(game_configs_dir)
	if game_configs_dir_access:
		game_configs_dir_access.list_dir_begin()
		var file_name = game_configs_dir_access.get_next()
		while file_name != "":
			print(file_name)
			if file_name.ends_with(".json"):
				var file = FileAccess.open(game_configs_dir + file_name, FileAccess.READ)
				if file:
					var json = JSON.parse_string(file.get_as_text())
					print(json)
					file.close()
					json["file_name"] = str(file_name)
					game_configs.append(json)
			file_name = game_configs_dir_access.get_next()
	for game_config in game_configs:
		game_config["slug"] = game_config["file_name"].replace(".json", "")
		var game_settings_panel_instance = game_settings_panel.instantiate()
		var game_toggle = CheckButton.new()
		# Set the game icon
		if game_icon_textures.has(game_config["slug"]):
			game_settings_panel_instance.get_node("TextureRect").texture = game_icon_textures[game_config["slug"]]
			game_settings_panel_instance.game = game_config
		game_toggle.text = game_config["title"]
		game_toggle.size_flags_horizontal = 4
		game_toggle.pressed.connect(game_settings_panel_instance.toggle_visibility)
		game_settings_panel_instance.get_node("Title").text = game_config["title"]
		game_settings_panel_instance.visible = false
		add_child(game_settings_panel_instance)
		game_toggle.pressed.connect(label._on_game_visiblity_changed)
		game_toggle.pressed.connect($"../.."._on_settings_resized)
		if game_config["mod_organizer_path"] != "" or game_config["mod_organizer_type"] != "":
			game_toggle.button_pressed = true
		game_toggles.add_child(game_toggle)
		
	# Load the mod manager icons
	var mo2_path = "res://assets/mo2.png"
	var vortex_path = "res://assets/vortex-logomark.png"
	if OS.has_feature("standalone"):
		mo2_path = DIR + mo2_path.replace("res://", "")
		vortex_path = DIR + vortex_path.replace("res://", "")
	else:
		mo2_path = ProjectSettings.globalize_path(mo2_path)
		vortex_path = ProjectSettings.globalize_path(vortex_path)
	mod_manager_icon_textures["mo2"] = ImageTexture.create_from_image(Image.load_from_file(mo2_path))
	mod_manager_icon_textures["vortex"] = ImageTexture.create_from_image(Image.load_from_file(vortex_path))
	
	games_loaded.emit()
