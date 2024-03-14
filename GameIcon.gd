extends TextureRect

func _on_resized():
	custom_minimum_size.y = $"..".size.y
	custom_minimum_size.x = $"..".size.y
