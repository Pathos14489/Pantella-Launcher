extends Panel

func _on_info_resized():
	custom_minimum_size.y = $VBoxContainer.size.y + 50

func _ready():
	_on_info_resized()
