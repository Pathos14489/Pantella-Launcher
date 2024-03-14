extends Button

func _on_hotbar_resized():
	custom_minimum_size.x = $"..".size.y
