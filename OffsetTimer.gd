extends Timer

@export var min_time = 0.5
@export var max_time = 1.5

# Called when the node enters the scene tree for the first time.
func _ready(): 
	wait_time = randf() * (max_time - min_time) + min_time
	autostart = true
