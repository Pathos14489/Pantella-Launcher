extends TextureRect


# Called when the node enters the scene tree for the first time.
func _ready():
	visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Rotate the sprite
	pivot_offset = size / 2 - Vector2(1, 1)
	rotation += 0.1
