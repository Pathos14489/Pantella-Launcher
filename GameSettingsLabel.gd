extends Label

@onready var games = $"../GamesSettings"

func _on_game_visiblity_changed():
	# Check if any game is visible
	visible = false
	for game in games.get_children():
		if game.visible:
			visible = true
			break

func _ready():
	_on_game_visiblity_changed()
