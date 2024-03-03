extends Panel
@onready var root = get_tree().root.get_child(0)
@onready var python = get_tree().root.get_child(0).get_node("PythonInterpreter")
@onready var http_request = get_tree().root.get_child(0).get_node("HTTPRequest")
@onready var plugins_menu = get_tree().root.get_child(0).get_node("UI/ScrollContainer2/VBoxContainer/PluginsMenu")
@onready var status_bar = get_tree().root.get_child(0).get_node("UI/ScrollContainer/VBoxContainer/Panel/StatusBar")

@onready var plugins_button = preload("res://plugin_button.tscn") # TODO: Probably a bad idea to have every repo preload this, but will fix later when not sleep deprived. move to the plugin node prolly

signal download_extracted

var DIR = OS.get_executable_path().get_base_dir() + "/"

var repo = {
	"args": [],
	"file_name": "N/A",
	"name": "N/A",
	"description": "N/A",
	"repo": "N/A",
	"watchdog": false,
	"entry_point": "N/A",
	"blacklist": [],
	"plugins": [],
	"color": "ffffff"
}
@export var script_path = "run_repo.py"
@export var watchdog = false
var PID = 0
var installed = false
var repositories_dir = "res://repositories/"
var repo_dir = repositories_dir+repo["repo"].replace("/", "_")
var temp_path = "res://temp/"
var active = false
var current_download = {
	"repo": "N/A",
	"name": "N/A",
}

func apply_repo(json):
	print("Applying repo")
	repo = json
	print(repo)
	get_node("HBoxContainer/Info/Title").text = repo["name"]
	get_node("HBoxContainer/Info/Title").self_modulate = Color.from_string(repo["color"], Color.WHITE)
	get_node("HBoxContainer/Info/Repo").text = "Git: " +  repo["repo"]
	get_node("HBoxContainer/Info/Desc").text = repo["description"]
	script_path = script_path 
	watchdog = repo["watchdog"]
	if !OS.has_feature("standalone"):
		repositories_dir = ProjectSettings.globalize_path(repositories_dir)
	else:
		repositories_dir = DIR + repositories_dir
	repo_dir = repositories_dir+repo["repo"].replace("/", "_")
	var dir_access = DirAccess.open(repo_dir)
	if dir_access:
		installed = true
		get_node("HBoxContainer/Controls/Download").text = "Update"
	# get_node("HBoxContainer/Controls/Start").visible = false
	get_node("HBoxContainer/Controls/Download").visible = false
	print("Applied repo")

func download_repo():
	print("Downloading repo")
	# Get all nodes in group download_buttons and disable them
	var buttons = get_tree().get_nodes_in_group("download_buttons")
	for button in buttons:
		button.disabled = true
	get_node("HBoxContainer/Controls/Download").text = "Downloading..."
	var repositories = get_tree().get_nodes_in_group("repository")
	for repository in repositories:
		repository.get_node("Button").disabled = true
	status_bar.text = "Downloading " + repo["name"] + " Backend..."
	var repo_url = "https://github.com/" + repo["repo"] + "/archive/refs/heads/main.zip"
	var repo_path = "res://temp/" + repo["repo"].replace("/", "_") + ".zip"
	http_request.download_file = repo_path
	http_request.request(repo_url)
	http_request.request_completed.connect(download_completed)
	current_download = {
		"repo": repo["repo"],
		"name": repo["name"],
	}
	await download_extracted # Wait for repo download to complete
	status_bar.text = "Downloading " + repo["name"] + " Plugins..."
	for plugin in repo["plugins"]:
		var plugin_url = "https://github.com/" + plugin["repo"] + "/archive/refs/heads/main.zip"
		var plugin_path = "res://temp/" + plugin["repo"].replace("/", "_") + ".zip"
		http_request.download_file = plugin_path
		http_request.request(plugin_url)
		current_download = plugin
		status_bar.text = "Downloading " + current_download["repo"] + "..."
		await download_extracted # Wait for plugin download to complete
	for button in buttons:
		button.disabled = false
	get_node("HBoxContainer/Controls/Download").text = "Update"
	# get_node("HBoxContainer/Controls/Start").visible = true
	installed = true
	for repository in repositories:
		repository.get_node("Button").disabled = false

func download_completed(_status, _body, _headers, _code):
	print("Download completed")
	status_bar.text = "Downloaded " + current_download["repo"] + ", extracting..."
	print(http_request.download_file)
	print(current_download)
	# Check if repo directory exists, if not create it
	var zip_path = http_request.download_file # "res://temp/" + repo["repo"].replace("/", "_") + ".zip"
	if !OS.has_feature("standalone"):
		zip_path = ProjectSettings.globalize_path(zip_path)
	else:
		zip_path = DIR + zip_path
	var main_dir = temp_path + current_download["repo"].split("/")[1]+"-main/*"
	var output_dir = repositories_dir + current_download["repo"].replace("/", "_")
	print(temp_path)
	print(zip_path)
	print(main_dir)
	print(output_dir)
	
	# Clear everything but the filenames in repo["blacklist"] from the repo directory
	if installed:
		var dir_access = DirAccess.open(output_dir)
		if dir_access:
			dir_access.list_dir_begin()
			while true:
				var file = dir_access.get_next()
				if file == "":
					break
				if file in repo["blacklist"]:
					continue
				OS.move_to_trash(output_dir + "/" + file)
		else:
			DirAccess.make_dir_absolute(output_dir)
	else:
		DirAccess.make_dir_absolute(output_dir)

	OS.execute("tar", ["-xf", zip_path, "-C", temp_path]) # Extract the downloaded zip to the temp directory
	OS.execute("powershell.exe", ["mv", main_dir, output_dir]) # Move the contents of the temp directory to the repo directory
	# Remove the temp directory
	OS.move_to_trash(main_dir.replace("/*", ""))
	OS.move_to_trash(zip_path)
	status_bar.text = "Extracted " + repo["name"] + ", ready to start"
	download_extracted.emit()
	print("Extracted zip")

func _ready():
	if !OS.has_feature("standalone"):
		temp_path = ProjectSettings.globalize_path(temp_path)
	else:
		temp_path = DIR + temp_path
	if !OS.has_feature("standalone"):
		repo_dir = ProjectSettings.globalize_path(repo_dir)
	else:
		repo_dir = DIR + repo_dir

# func start_repo():
# 	if $HBoxContainer/Controls/Start.text == "Start":
# 		_start_repo()
# 	else:
# 		_stop_repo()

func _start_repo():
	print("Starting repo")
	# $HBoxContainer/Controls/Start.text = "Stop"
	status_bar.text = "Running " + repo["name"] + "..."
	print(repo_dir)
	print(script_path)
	# var buttons = get_tree().get_nodes_in_group("start_button")
	# for button in buttons:
	# 	if button != get_node("HBoxContainer/Controls/Start"):
	# 		button.disabled = true
	get_node("HBoxContainer/Controls/Download").visible = false
	
	var wd = watchdog
	if root.settings["crash_recovery"] != true:
		wd = false
	PID = python.run_script(script_path, ["\""+repo['repo']+"\""], root.settings["debug_console"], wd)
	active = true
	var repositories = get_tree().get_nodes_in_group("repository")
	for repository in repositories:
		repository.get_node("Button").disabled = true
	print("Started repo")

func _stop_repo():
	print("Stopping repo")
	# $HBoxContainer/Controls/Start.text = "Start"
	status_bar.text = "Stopping " + repo["name"] + "..."
	python.stop_PID(PID)
	var buttons = get_tree().get_nodes_in_group("start_button")
	for button in buttons:
		button.disabled = false
	get_node("HBoxContainer/Controls/Download").visible = true
	var repositories = get_tree().get_nodes_in_group("repository")
	for repository in repositories:
		repository.get_node("Button").disabled = false
	active = false
	status_bar.text = repo["name"] + " has been stopped"
	print("Stopped repo")


func _on_info_resized():
	custom_minimum_size.y = $HBoxContainer/Info.size.y + 50
	
func _on_button_pressed(): # When selected, visible = false for all other repositories download and start buttons
	var repositories = get_tree().get_nodes_in_group("repository")
	for repository in repositories:
		if repository != self:
			repository.get_node("HBoxContainer/Controls/Download").visible = false
			# repository.get_node("HBoxContainer/Controls/Start").visible = false
	self.get_node("HBoxContainer/Controls/Download").visible = true
	if installed:
		plugins_menu.visible = true
		plugins_menu.get_node("VBoxContainer/Panel2/Label3").text = repo["name"]
		plugins_menu.get_node("VBoxContainer/Panel2/Label3").self_modulate = Color.from_string(repo["color"], Color.WHITE)
		# if installed:
			# self.get_node("HBoxContainer/Controls/Start").visible = true
		# remove all child nodes from plugins_menu.get_node("VBoxContainer/Panel/Plugins")
		for child in plugins_menu.get_node("VBoxContainer/Panel3/VBoxContainer/Plugins").get_children():
			child.queue_free()
		for plugin in repo["plugins"]:
			var button = plugins_button.instantiate()
			button.plugin = plugin
			button.repo = self
			plugins_menu.get_node("VBoxContainer/Panel3/VBoxContainer/Plugins").add_child(button)
		
		
func plugin_selected(plugin): # from plugin button
	print("Plugin selected")
	if "plugin_path" not in root.settings or root.settings["plugin_path"] == "":
		status_bar.text = "Please set the plugin path in the settings"
	else:
		if active == true: # If the repo is running, stop it
			_stop_repo()
		else: # If the repo is not running, start it
			root.plugin_selected(plugin)
			_start_repo()

func save_repo():
	var file = FileAccess.open("res://repo_configs/"+repo["file_name"], FileAccess.WRITE)
	file.store_string(JSON.stringify(repo))
	file.close()
