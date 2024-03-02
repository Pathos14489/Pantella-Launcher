extends Node

# @onready var program = get_tree().root.get_child(0)
# @onready var python = get_tree().root.get_child(0).get("PythonInterpreter")

var DIR = OS.get_executable_path().get_base_dir() + "/"
var interpreter_path = "python3" # DIR + 

var process_ids = []
var watched_pids = {}

var OS_name = OS.get_name()

var delay = 1.0
var time_passed = 0.0
@export var watchdogable = false

signal all_processes_closed
signal interpreter_ready

func _ready():
	# Delete log.txt on startup
	if !OS.has_feature("standalone"):
		interpreter_path = ProjectSettings.globalize_path("res://python-3.10.11-embed/python.exe")
	else:
		interpreter_path = DIR + "python-3.10.11-embed/python.exe"
	print("Python interpreter path: " + interpreter_path)
	interpreter_ready.emit()

func run_script(script_path, script_args=[], console=true, watchdog=false):
	print("Running Python script: " + script_path)
	if !OS.has_feature("standalone"):
		script_path = ProjectSettings.globalize_path("res://" + script_path)
	else:
		script_path = DIR + script_path
	var args = [script_path] + script_args
	var PID = OS.create_process(interpreter_path, args, console)
	if watchdog:
		watched_pids[PID] = [interpreter_path, args, console, watchdog]
		print("Watchdog enabled for process: " + str(PID))
	print("Process ID: " + str(PID))
	process_ids.append(PID)
	return PID
	
func run_script_from_dir(dir, script_path, console=true, watchdog=false):
	print("Running Python script: " + script_path)
	if dir.ends_with("/"):
		dir = dir.substr(0, dir.length() - 1)
	script_path = dir + "/" + script_path
	var requirements = dir + "/requirements.txt"
	# var args = ["/c", "cd", dir, ";", interpreter_path + " -m pip install -r " + requirements, ";", interpreter_path, module_path]
	# print("CMD.exe", args, console)
	# print("CMD.exe " + " ".join(args))
	# var PID = OS.create_process("CMD.exe", args, console)
	var args = ["/d", "cd", dir, ";", interpreter_path, "-m", "pip", "install", "-r", requirements, ";", interpreter_path, script_path]
	print("start", args, console)
	print("start " + " ".join(args))
	var PID = OS.create_process("start", args, console)
	if watchdog:
		watched_pids[PID] = ["CMD.exe", args, console, watchdog]
		print("Watchdog enabled for process: " + str(PID))
	print("Process ID: " + str(PID))
	process_ids.append(PID)
	return PID

func execute_script(script_path):
	print("Executing Python script: " + script_path)
	if !OS.has_feature("standalone"):
		script_path = ProjectSettings.globalize_path("res://" + script_path)
	else:
		script_path = DIR + script_path
	var args = [script_path]
	OS.execute(interpreter_path, args)

func run(command):
	print("Running command: " + command)
	var args = [command]
	var PID = OS.create_process(interpreter_path, args, true)
	print("Process ID: " + str(PID))
	process_ids.append(PID)
	return PID

func install_packages(packages):
	print("Installing packages: " + str(packages))
	var args = ["-m", "pip", "install"]
	for package in packages:
		args.append(package)
	print(interpreter_path+" ", args)
	OS.execute(interpreter_path, args)

func _notification(what):
	if what == Node.NOTIFICATION_WM_CLOSE_REQUEST:
		for PID in process_ids:
			OS.kill(PID)
			print("Killed process: " + str(PID))
		get_tree().quit()

func _process(delta):
	if !watchdogable:
		return
	time_passed += delta
	if time_passed > delay:
		time_passed = 0.0
		# check if process ids are still running
		# print("Checking processes")
		for PID in process_ids:
			if !OS.is_process_running(PID):
				print("Process " + str(PID) + " has exited")
				var repos = get_tree().get_nodes_in_group("repository")
				if PID in watched_pids:
					var ip = watched_pids[PID][0]
					var args = watched_pids[PID][1]
					var console = watched_pids[PID][2]
					var watchdog = watched_pids[PID][3]
					print("Restarting process: " + str(PID))
					var newPID = OS.create_process(ip, args, console)
					watched_pids.erase(PID)
					for repo in repos:
						if repo.PID == PID:
							repo.PID = newPID
					if watchdog:
						watched_pids[newPID] = [interpreter_path, args, console, watchdog]
						print("Watchdog enabled for process: " + str(newPID))
					process_ids.append(newPID)
				else:
					for repo in repos:
						if repo.PID == PID:
							if repo.active:
								repo._stop_repo()
				process_ids.erase(PID)
				break
		if process_ids.size() == 0:
			all_processes_closed.emit()

func stop():
	for PID in process_ids:
		OS.kill(PID)
		print("Killed process: " + str(PID))

func stop_PID(PID):
	watched_pids.erase(PID)
	if PID != null:
		OS.kill(PID)
		print("Killed process: " + str(PID))

# func _on_l_la_m_acpp_on_connected():
# 	watchdogable = true

# func _on_timer_timeout():
# 	watchdogable = true
