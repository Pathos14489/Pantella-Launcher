extends Panel
@onready var python = get_tree().root.get_child(0).get_node("PythonInterpreter")
@onready var http_request =get_tree().root.get_child(0).get_node("HTTPRequest")
var DIR = OS.get_executable_path().get_base_dir() + "/"

var repo = {
	"file_name": "N/A",
	"name": "N/A",
	"description": "N/A",
	"repo": "N/A",
	"watchdog": false,
	"entry_point": "N/A"
}
@export var script_path = "run_repo.py"
@export var watchdog = false

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
	print("Applied repo")

func download_repo():
	print("Downloading repo")
	var url = "https://github.com/" + repo["repo"] + "/archive/refs/heads/main.zip"
	var path = "res://temp/" + repo["repo"].replace("/", "_") + ".zip"
	http_request.download_file = path
	http_request.request(url)
	http_request.request_completed.connect(download_completed)
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
	DirAccess.remove_absolute(dir)
	DirAccess.make_dir_absolute(dir)
	OS.execute("tar", ["-xf", zip_path, "-C", temp_path])
	# Move the extracted files from the "/"+repo["repo"].split("/")[1]+"-main/*" directory to the repositories directory
	print(main_dir)
	OS.execute("powershell.exe", ["mv", main_dir, dir])
	# Remove the temp directory
	OS.move_to_trash(main_dir.replace("/*", ""))
	OS.move_to_trash(zip_path)
	print("Extracted zip")

func _ready():
	if !OS.has_feature("standalone"):
		dir = ProjectSettings.globalize_path(dir)
	else:
		dir = DIR + dir

func start_repo():
	print("Starting repo")
	print(dir)
	print(script_path)
	python.run_script(script_path, ["\""+repo['repo']+"\"","\""+repo['entry_point']+"\""], true, watchdog)
	print("Started repo")
