extends Button

func _on_pressed():
	if text == "Start":
		text = "Stop"
		$"../../../../.."._start_repo()
	else:
		text = "Start"
		$"../../../../.."._stop_repo()
