extends Panel
@onready var python = get_tree().root.get_child(0).get_node("PythonInterpreter")
@onready var http_request =get_tree().root.get_child(0).get_node("HTTPRequest")
var DIR = OS.get_executable_path().get_base_dir() + "/"

var repo = {
	"args": [],
	"file_name": "N/A",
	"name": "N/A",
	"description": "N/A",
	"repo": "N/A",
	"watchdog": false,
	"entry_point": "N/A",
	"blacklist": []
}
@export var script_path = "run_repo.py"
@export var watchdog = false
var PID = 0
var installed = false
var dir = "res://repositories/"+repo["repo"].replace("/", "_")

func apply_repo(json):
	print("Applying repo")
	repo = json
	print(repo)
	get_node("HBoxContainer/Info/Title").text = "Title: " + repo["name"]
	get_node("HBoxContainer/Info/Repo").text = "Git: " +  repo["repo"]
	get_node("HBoxContainer/Info/Desc").text = repo["description"]
	script_path = script_path 
	watchdog = repo["watchdog"]
	dir = "res://repositories/"+repo["repo"].replace("/", "_")
	if !OS.has_feature("standalone"):
		dir = ProjectSettings.globalize_path(dir)
	else:
		dir = DIR + dir
	var dir_access = DirAccess.open(dir)
	if dir_access:
		installed = true
		get_node("HBoxContainer/Controls/Download").text = "Update"
		get_node("HBoxContainer/Controls/Start").visible = true
	else:
		get_node("HBoxContainer/Controls/Download").text = "Download"
		get_node("HBoxContainer/Controls/Start").visible = false
	print("Applied repo")

func download_repo():
	print("Downloading repo")
	var url = "https://github.com/" + repo["repo"] + "/archive/refs/heads/main.zip"
	var path = "res://temp/" + repo["repo"].replace("/", "_") + ".zip"
	http_request.download_file = path
	http_request.request(url)
	http_request.request_completed.connect(download_completed)
	# Get all nodes in group download_buttons and disable them
	var buttons = get_tree().get_nodes_in_group("download_buttons")
	for button in buttons:
		button.disabled = true
	print("Downloaded repo")

func download_completed(_status, _body, _headers, _code):
	print("Download completed")
	# Check if repo directory exists, if not create it
	var zip_path = http_request.download_file
	if !OS.has_feature("standalone"):
		zip_path = ProjectSettings.globalize_path(zip_path)
	else:
		zip_path = DIR + zip_path
	var temp_path = "res://temp/"
	if !OS.has_feature("standalone"):
		temp_path = ProjectSettings.globalize_path(temp_path)
	else:
		temp_path = DIR + temp_path
	var main_dir = temp_path + repo["repo"].split("/")[1]+"-main/*"
	print(dir)
	print(zip_path)
	print(temp_path)
	
	# Clear everything but the filenames in repo["blacklist"] from the repo directory
	if installed:
		var dir_access = DirAccess.open(dir)
		if dir_access:
			dir_access.list_dir_begin()
			while true:
				var file = dir_access.get_next()
				if file == "":
					break
				if file in repo["blacklist"]:
					continue
				OS.move_to_trash(dir + "/" + file)
		else:
			DirAccess.make_dir_absolute(dir)

	OS.execute("tar", ["-xf", zip_path, "-C", temp_path])
	# Move the extracted files from the "/"+repo["repo"].split("/")[1]+"-main/*" directory to the repositories directory
	print(main_dir)
	OS.execute("powershell.exe", ["mv", main_dir, dir])
	# Remove the temp directory
	OS.move_to_trash(main_dir.replace("/*", ""))
	OS.move_to_trash(zip_path)
	print("Extracted zip")
	var buttons = get_tree().get_nodes_in_group("download_buttons")
	for button in buttons:
		button.disabled = false
	get_node("HBoxContainer/Controls/Download").text = "Update"
	get_node("HBoxContainer/Controls/Start").visible = true

func _ready():
	if !OS.has_feature("standalone"):
		dir = ProjectSettings.globalize_path(dir)
	else:
		dir = DIR + dir

func start_repo():
	if $HBoxContainer/Controls/Start.text == "Start":
		$HBoxContainer/Controls/Start.text = "Stop"
		_start_repo()
	else:
		$HBoxContainer/Controls/Start.text = "Start"
		_stop_repo()

func _start_repo():
	print("Starting repo")
	print(dir)
	print(script_path)
	PID = python.run_script(script_path, ["\""+repo['repo']+"\""], true, watchdog)
	print("Started repo")

func _stop_repo():
	print("Stopping repo")
	python.stop_PID(PID)
	print("Stopped repo")
