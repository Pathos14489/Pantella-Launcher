extends VBoxContainer

@onready var program = get_tree().root.get_child(0)

var id = null

func _ready():
	print("ready")

func _on_model_button_pressed():
	if !$Downloads.visible:
		program.load_model(self)
	$Downloads.visible = !$Downloads.visible
	for node in get_tree().get_nodes_in_group("downloads"):
		if node != $Downloads:
			node.visible = false

func _on_author_pressed():
	program.sort_models_by_author($ModelButton/HBoxContainer/Author.text)
