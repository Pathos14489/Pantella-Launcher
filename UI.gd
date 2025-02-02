extends Panel

@onready var progress_timer = get_tree().root.get_child(0).get_node("ProgressTimer")
@onready var http_request = get_tree().root.get_child(0).get_node("HTTPRequest")
@onready var status_bar = get_tree().root.get_child(0).get_node("UI/StatusBarPanel/Hotbar/StatusBar")

@export var current_download_name = "N/A"

func _on_close_button_pressed():
	$ScrollContainer.visible = true
	$StatusBarPanel.visible = true
	$Settings.visible = false

func _on_settings_button_pressed():
	$ScrollContainer.visible = false
	$StatusBarPanel.visible = false
	$Settings.visible = true

func start_download(download_name):
	current_download_name = download_name
	progress_timer.start()

func _on_progress_timer_timeout():
	var downloadedBytes = http_request.get_downloaded_bytes()
	var downloaded_megabytes = downloadedBytes / 1024 / 1024
	if downloaded_megabytes > 1024:
		var downloaded_gigabytes = downloaded_megabytes / 1024
		status_bar.text = "Downloading " + current_download_name + " (" + str(downloaded_gigabytes) + " GB)"
	elif downloaded_megabytes > 0:
		status_bar.text = "Downloading " + current_download_name + " (" + str(downloaded_megabytes) + " MB)"
	else:
		status_bar.text = "Downloading " + current_download_name + " (" + str(downloadedBytes / 1024) + " KB)"
