extends Panel

func _on_close_button_pressed():
	$ScrollContainer.visible = true
	$StatusBarPanel.visible = true
	$Settings.visible = false

func _on_settings_button_pressed():
	$ScrollContainer.visible = false
	$StatusBarPanel.visible = false
	$Settings.visible = true
