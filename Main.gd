extends Node
@onready var PythonInterpretter = $".."
@export var script_path = ""
@export var open_console = true
@export var watch = false
# func _on_python_interpreter_interpreter_ready():
# 	PythonInterpretter.run_script(script_path, open_console, watch)
