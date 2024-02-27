extends VBoxContainer

var DIR = OS.get_executable_path().get_base_dir() + "/"
var repos_dir = "repo_configs/"
var repos = []

@onready var repo_button = preload("res://repository.tscn")

func _ready():
	if !OS.has_feature("standalone"):
		repos_dir = ProjectSettings.globalize_path(repos_dir)
	else:
		repos_dir = DIR + repos_dir
	# read json files from repos_dir
	
	print(repos_dir)
	var dir = DirAccess.open(repos_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".json"):
				var file = FileAccess.open(repos_dir + file_name, FileAccess.READ)
				if file:
					var json = JSON.parse_string(file.get_as_text())
					file.close()
					json["file_name"] = file_name
					repos.append(json)
					load_repo(json)
			file_name = dir.get_next()
	print(repos)


func load_repo(repo):
	var button = repo_button.instantiate()
	button.apply_repo(repo)
	add_child(button)
