extends Panel

func _on_resized():
	custom_minimum_size.y = $VBoxContainer.size.y + 50

func _on_settings_resized():
	$VBoxContainer/GamesSettings.columns = int(size.x / 800)

func _on_games_settings_games_loaded():
	$VBoxContainer/GamesSettings.columns = int(size.x / 800)
