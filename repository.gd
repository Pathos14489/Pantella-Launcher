extends VBoxContainer
@onready var root = get_tree().root.get_child(0)
@onready var python = get_tree().root.get_child(0).get_node("PythonInterpreter")
@onready var http_request = get_tree().root.get_child(0).get_node("HTTPRequest")
@onready var status_bar = get_tree().root.get_child(0).get_node("UI/StatusBarPanel/Hotbar/StatusBar")
@onready var plugins_list = $RepoPanel/VBoxContainer/PluginsList
@onready var plugins_button = preload("res://plugin_button.tscn")

signal download_extracted
signal repo_download_finished

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
	"color": "ffffff",
	"last_checked_for_updates": Time.get_unix_time_from_system(),
	"last_updated": Time.get_unix_time_from_system()
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
	"blacklist": [],
}

func apply_repo(json):
	print("Applying repo")
	repo = json
	print(repo)
	get_node("RepoPanel/VBoxContainer/HBoxContainer/Info/Title").text = repo["name"]
	get_node("RepoPanel/VBoxContainer/HBoxContainer/Info/Title").self_modulate = Color.from_string(repo["color"], Color.WHITE)
	get_node("RepoPanel/VBoxContainer/HBoxContainer/Info/Repo").text = repo["repo"]
	get_node("RepoPanel/VBoxContainer/HBoxContainer/Info/Desc").text = repo["description"]
	script_path = script_path 
	watchdog = repo["watchdog"]
	if !OS.has_feature("standalone"):
		repositories_dir = ProjectSettings.globalize_path(repositories_dir)
	else:
		repositories_dir = DIR + repositories_dir.replace("res://", "")
	repo_dir = repositories_dir+repo["repo"].replace("/", "_")
	
	get_node("RepoPanel/VBoxContainer/HBoxContainer/Controls/Download").visible = false
	get_node("RepoPanel/VBoxContainer/HBoxContainer/Controls/Start").visible = false
	
	var dir_access = DirAccess.open(repo_dir)
	if dir_access:
		check_for_updates()
		installed = true
		get_node("RepoPanel/VBoxContainer/HBoxContainer/Controls/Start").visible = true
	else:
		get_node("RepoPanel/VBoxContainer/HBoxContainer/Controls/Download").visible = true

	# get_node("HBoxContainer/Controls/Start").visible = false
	populate_plugins_list()
	print("Applied repo")

func check_for_updates(force=false):
	var current_timestamp = Time.get_unix_time_from_system()
	# Check every fifteen minutes
	if not force:
		if current_timestamp - repo.last_checked_for_updates < 900: # 15 minutes
			return
	print("Checking for updates")
	var repo_api_url = "https://api.github.com/repos/" + repo["repo"] + "/commits"
	var new_commit_info_path = "res://temp/" + repo["repo"].replace("/", "_") + ".json"
	var old_commit_info_path = "res://install_info/" + repo["repo"].replace("/", "_") + ".json"
	var already_downloaded = false
	if FileAccess.file_exists(old_commit_info_path):
		already_downloaded = true
		$GithubHTTPRequest.download_file = new_commit_info_path
		# if file already exists, remove it
		if FileAccess.file_exists(new_commit_info_path):
			OS.move_to_trash(new_commit_info_path)
	else:
		$GithubHTTPRequest.download_file = old_commit_info_path
	await $GithubHTTPRequest/OffsetTimer.timeout
	$GithubHTTPRequest.request(repo_api_url)
	await $GithubHTTPRequest.request_completed
	get_node("RepoPanel/VBoxContainer/HBoxContainer/Controls/Download").text = "No Updates Available"
	get_node("RepoPanel/VBoxContainer/HBoxContainer/Controls/Download").visible = false
	if already_downloaded:
		var new_commit_info = JSON.parse_string(FileAccess.open(new_commit_info_path, FileAccess.READ).get_as_text())[0]
		var old_commit_info = JSON.parse_string(FileAccess.open(old_commit_info_path, FileAccess.READ).get_as_text())[0]
		if old_commit_info["sha"] != new_commit_info["sha"]:
			print("New commit found")
			get_node("RepoPanel/VBoxContainer/HBoxContainer/Controls/Download").text = "Update"
			get_node("RepoPanel/VBoxContainer/HBoxContainer/Controls/Download").visible = true
	repo["last_checked_for_updates"] = current_timestamp
	save_repo()

	# Check for plugin updates
	for plugin_node in get_tree().get_nodes_in_group("plugin"):
		var plugin = plugin_node.plugin
		var plugin_api_url = "https://api.github.com/repos/" + plugin["repo"] + "/commits"
		var new_plugin_commit_info_path = "res://temp/" + plugin["repo"].replace("/", "_") + ".json"
		var old_plugin_commit_info_path = "res://install_info/" + plugin["repo"].replace("/", "_") + ".json"
		$GithubHTTPRequest.download_file = new_plugin_commit_info_path
		await $GithubHTTPRequest/OffsetTimer.timeout
		$GithubHTTPRequest.request(plugin_api_url)
		await $GithubHTTPRequest.request_completed
		var new_plugin_commit_info = JSON.parse_string(FileAccess.open(new_plugin_commit_info_path, FileAccess.READ).get_as_text())[0]
		var old_plugin_commit_info = JSON.parse_string(FileAccess.open(old_plugin_commit_info_path, FileAccess.READ).get_as_text())[0]
		if old_plugin_commit_info["sha"] != new_plugin_commit_info["sha"]:
			print("New plugin commit found")
			get_node("RepoPanel/VBoxContainer/HBoxContainer/Controls/Download").text = "Update"
			get_node("RepoPanel/VBoxContainer/HBoxContainer/Controls/Download").visible = true
		# move the temp commit info to trash, it is no longer needed - I think
		OS.move_to_trash(new_plugin_commit_info_path)

	
	print("Checked for updates")

func populate_plugins_list():
	if installed:
		for plugin in repo["plugins"]:
			for game in plugin["games"]:
				print("Adding plugin for " + game + " | " + plugin["repo"] + " | to " + repo["name"])
				var button = plugins_button.instantiate()
				button.plugin = plugin
				button.game = game
				button.repo = self
				plugins_list.add_child(button)

func download_repo():
	print("Downloading latest repo")
	root.show_spinner()
	# Get all nodes in group download_buttons and disable them - this is to prevent multiple downloads at the same time
	var buttons = get_tree().get_nodes_in_group("download_buttons")
	for button in buttons:
		button.disabled = true
	get_node("RepoPanel/VBoxContainer/HBoxContainer/Controls/Download").text = "Downloading..."
	status_bar.text = "Downloading " + repo["repo"] + "..."
	
	var update_repo = false
	var repo_already_installed = false
	# Download the commit info
	var repo_api_url = "https://api.github.com/repos/" + repo["repo"] + "/commits"
	var commit_info_path = "res://install_info/" + repo["repo"].replace("/", "_") + ".json"
	var temp_commit_info_path = "res://temp/" + repo["repo"].replace("/", "_") + ".json"
	if FileAccess.file_exists(commit_info_path):
		if DirAccess.dir_exists_absolute("res://repositories/" + repo["repo"].replace("/", "_")):
			repo_already_installed = true
			$GithubHTTPRequest.download_file = temp_commit_info_path
			print("Repo already installed")
		else:
			# Clear the old commit info
			OS.move_to_trash(commit_info_path)
			$GithubHTTPRequest.download_file = commit_info_path
			update_repo = true
	else:
		$GithubHTTPRequest.download_file = commit_info_path
		update_repo = true
		print("Repo not installed -- downloading commit info")
	await $GithubHTTPRequest/OffsetTimer.timeout
	$GithubHTTPRequest.request(repo_api_url)
	await $GithubHTTPRequest.request_completed
	
	if repo_already_installed:
		# Load the commit info from the file
		var new_commit_info = JSON.parse_string(FileAccess.open(temp_commit_info_path, FileAccess.READ).get_as_text())[0]
		var old_commit_info = JSON.parse_string(FileAccess.open(commit_info_path, FileAccess.READ).get_as_text())[0]
		if old_commit_info["sha"] != new_commit_info["sha"]:
			update_repo = true
		else:
			status_bar.text = "Backend already up to date"
		
	if update_repo:
		# Download the repo
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
		# Replace the old commit info with the new commit info
		OS.move_to_trash(commit_info_path)
		OS.execute("mv", [temp_commit_info_path, commit_info_path])
	else:
		OS.move_to_trash(temp_commit_info_path)
	
	# Download related plugins
	status_bar.text = "Downloading " + repo["name"] + " Plugins..."
	for plugin in repo["plugins"]:

		var plugin_download = false
		
		var plugin_repo_api_url = "https://api.github.com/repos/" + plugin["repo"] + "/commits"
		var plugin_commit_info_path = "res://install_info/" + plugin["repo"].replace("/", "_") + ".json"
		var temp_plugin_commit_info_path = "res://temp/" + plugin["repo"].replace("/", "_") + ".json"
		# Download the plugin commit info
		$GithubHTTPRequest.download_file = plugin_commit_info_path
		plugin_download = true
		if FileAccess.file_exists(plugin_commit_info_path): # If the plugin is already installed, download the new commit info to a temp file and check if an update is required
			if DirAccess.dir_exists_absolute("res://repositories/" + plugin["repo"].replace("/", "_")):
				$GithubHTTPRequest.download_file = temp_plugin_commit_info_path
				# Load the commit info from the file
				var new_plugin_commit_info = JSON.parse_string(FileAccess.open(temp_plugin_commit_info_path, FileAccess.READ).get_as_text())[0]
				var old_plugin_commit_info = JSON.parse_string(FileAccess.open(plugin_commit_info_path, FileAccess.READ).get_as_text())[0]
				if old_plugin_commit_info["sha"] != new_plugin_commit_info["sha"]: # If the plugin is not up to date flag it for download
					# Replace the old commit info with the new commit info
					OS.move_to_trash(plugin_commit_info_path)
					OS.execute("mv", [temp_plugin_commit_info_path, plugin_commit_info_path])
				else: # Remove the temp commit info if the plugin is already up to date
					OS.move_to_trash(temp_plugin_commit_info_path)
					plugin_download = false

		await $GithubHTTPRequest/OffsetTimer.timeout
		$GithubHTTPRequest.request(plugin_repo_api_url)
		await $GithubHTTPRequest.request_completed
			
		if plugin_download: # If the plugin is flagged for download, download it
			var plugin_url = "https://github.com/" + plugin["repo"] + "/archive/refs/heads/main.zip"
			var plugin_path = "res://temp/" + plugin["repo"].replace("/", "_") + ".zip"
			http_request.download_file = plugin_path
			http_request.request(plugin_url)
			current_download = plugin
			status_bar.text = "Downloading " + current_download["repo"] + "..."
			await download_extracted # Wait for plugin download to complete
			
			for plugin_node in get_tree().get_nodes_in_group("plugin"):  # undeploy the old plugins that were installed
				if plugin_node.plugin["repo"] == plugin["repo"]:
					if plugin_node.installed:
						plugin_node.undeploy()
						plugin_node._on_install_button_pressed()
	for button in buttons:
		button.disabled = false
	get_node("RepoPanel/VBoxContainer/HBoxContainer/Controls/Download").text = "No Updates Available"
	get_node("RepoPanel/VBoxContainer/HBoxContainer/Controls/Download").visible = false
	# get_node("RepoPanel/VBoxContainer/HBoxContainer/Controls/Start").visible = true
	installed = true
	root.hide_spinner()
	repo_download_finished.emit()

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
		zip_path = DIR + zip_path.replace("res://", "")
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
	OS.execute("powershell.exe", ["mv", "\""+main_dir.replace(" ","' '")+"\"", "\""+output_dir.replace(" ","' '")+"\""]) # Move the contents of the temp directory to the repo directory
	# Remove the temp directory
	OS.move_to_trash(main_dir.replace("/*", ""))
	OS.move_to_trash(zip_path)
	status_bar.text = "Extracted " + current_download["name"] + "..."
	download_extracted.emit()
	print("Extracted zip")

func _ready():
	if !OS.has_feature("standalone"):
		temp_path = ProjectSettings.globalize_path(temp_path)
	else:
		temp_path = DIR + temp_path.replace("res://", "")
	if !OS.has_feature("standalone"):
		repo_dir = ProjectSettings.globalize_path(repo_dir)
	else:
		repo_dir = DIR + repo_dir.replace("res://", "")

# func start_repo():
# 	if $RepoPanel/VBoxContainer/HBoxContainer/Controls/Start.text == "Start":
# 		_start_repo()
# 	else:
# 		_stop_repo()

func _start_repo():
	print("Starting repo")
	# $RepoPanel/VBoxContainer/HBoxContainer/Controls/Start.text = "Stop"
	status_bar.text = "Running " + repo["name"] + "..."
	print(repo_dir)
	print(script_path)
	# var buttons = get_tree().get_nodes_in_group("start_button")
	# for button in buttons:
	# 	if button != get_node("RepoPanel/VBoxContainer/HBoxContainer/Controls/Start"):
	# 		button.disabled = true
	get_node("RepoPanel/VBoxContainer/HBoxContainer/Controls/Download").visible = false
	
	var wd = watchdog
	if root.settings["crash_recovery"] != true:
		wd = false
	PID = python.run_script(script_path, ["\""+repo['repo']+"\""], root.settings["debug_console"], wd)
	active = true
	print("Started repo")

func _stop_repo():
	print("Stopping repo")
	# $RepoPanel/VBoxContainer/HBoxContainer/Controls/Start.text = "Start"
	status_bar.text = "Stopping " + repo["name"] + "..."
	python.stop_PID(PID)
	var buttons = get_tree().get_nodes_in_group("start_button")
	for button in buttons:
		button.disabled = false
	active = false
	status_bar.text = repo["name"] + " has been stopped"
	print("Stopped repo")
	
# func _on_button_pressed(): # When selected, visible = false for all other repositories download and start buttons
# 	var repositories = get_tree().get_nodes_in_group("repository")
# 	for repository in repositories:
# 		if repository != self:
# 			repository.get_node("RepoPanel/VBoxContainer/HBoxContainer/Controls/Download").visible = false
# 			# repository.get_node("RepoPanel/VBoxContainer/HBoxContainer/Controls/Start").visible = false
# 	self.get_node("RepoPanel/VBoxContainer/HBoxContainer/Controls/Download").visible = true
		
		
# func plugin_selected(plugin): # from plugin button
# 	print("Plugin selected")
# 	if "plugin_path" not in root.settings or root.settings["plugin_path"] == "":
# 		status_bar.text = "Please set the plugin path in the settings"
# 	else:
# 		if active == true: # If the repo is running, stop it
# 			_stop_repo()
# 		else: # If the repo is not running, start it
# 			root.plugin_selected(plugin)
# 			_start_repo()

func save_repo():
	var file_path = "res://repo_configs/"+repo["file_name"]
	if !OS.has_feature("standalone"):
		file_path = ProjectSettings.globalize_path(file_path)
	else:
		file_path = DIR + file_path.replace("res://", "")
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(repo, "\t"))
	file.close()

func _on_repo_download_finished():
	populate_plugins_list()
	$RepoPanel/VBoxContainer/HBoxContainer/Controls/Start.visible = true
	status_bar.text = "Finished downloading " + repo["name"] + ", please configure the repo and start it"


func start_repo():
	pass # Replace with function body.
