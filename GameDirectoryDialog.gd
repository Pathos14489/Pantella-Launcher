extends FileDialog

@onready var root = get_tree().root.get_child(0)

func _on_dir_selected(dir):
	visible = false
	$"../VBoxContainer/GamePathButton".text = dir
	
func _on_button_pressed():
	visible = true
