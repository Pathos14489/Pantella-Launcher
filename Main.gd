extends Node
var DIR = OS.get_executable_path().get_base_dir() + "/"

var dir = "res://repositories/"
var temp_dir = "res://temp/"

func _ready():
	dir = "res://repositories/"
	if !OS.has_feature("standalone"):
		dir = ProjectSettings.globalize_path(dir)
	else:
		dir = DIR + dir
	temp_dir = "res://temp/"
	if !OS.has_feature("standalone"):
		temp_dir = ProjectSettings.globalize_path(temp_dir)
	else:
		temp_dir = DIR + temp_dir
    # Make sure the directory exists
	DirAccess.make_dir_absolute(dir)
	DirAccess.make_dir_absolute(temp_dir)