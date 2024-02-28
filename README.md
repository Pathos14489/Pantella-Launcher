# Mantella Launcher

Launcher for easily running Mantella development branches from source in it's proper dev/production ready environment.

![Screenshot](https://raw.githubusercontent.com/Pathos14489/Mantella-Launcher/main/assets/example.png)

## Features
 
- Download and run Mantella forks from source
- Automatically update forks to the latest version when you're ready
- Easily switch between forks
- Easy to use interface
- Don't have to install Python or any dependencies to run the Mantella server
- Automatic Crash Recovery

## How to Use

Download the latest release from the releases tab, or clone this repository and build from source. Run the Mantella_Launcher.exe, Download a fork and click Start to open Mantella. Please verify that all configuration settings are set in the fork you're trying to use before reporting a bug.

## Build from Source

Open the project.godot file, or import the project folder into the project manager for Godot 4.2.2. Click Project>Export from the dropdown menu at the top left, then "Export All..." and finally Debug/Release depending on the type of build you're trying to make. The run_repo.py file can be edited without rebuilding the exe.

## llama-cpp-python Support

If a repository uses this package, please install it using the included bat files. This is a requirement for some forks to run properly. If these forks have llama-cpp-python in their requirements.txt, it is recommended to disable automatic requirements.txt installation in the settings after the first run and overwrite the installed version with the included bat files for your setup if you're trying to use llama-cpp-python with a GPU.