extends FileDialog

@onready var root = get_tree().root.get_child(0)

func _on_dir_selected(dir):
	visible = false
	$"../VBoxContainer/ModManagerPathButton".text = dir
	
func _on_game_path_button_2_pressed():
	visible = true
