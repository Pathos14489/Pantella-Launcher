extends Panel

func _on_resized():
	custom_minimum_size.y = get_node("VBoxContainer").size.y + 25
