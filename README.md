# Pantella Launcher

Launcher for easily running Mantella development branches from source in it's proper dev/production ready environment.

![Screenshot of the Pantella Launcher running Pantella with LLaVA 1.6 34B and nvitop in the background.](https://raw.githubusercontent.com/Pathos14489/Mantella-Launcher/main/assets/example.png)
![Screenshot of the Pantella Launcher Settings Page](https://raw.githubusercontent.com/Pathos14489/Mantella-Launcher/main/assets/example_2.png)

## Features
 
- Download and run Mantella forks from source
- Automatically get notified of new updates and update forks to the latest version when you're ready
- Easily switch between forks, games and plugins with Mantella and other repositories
- Easy to use interface
- Don't have to install Python or any dependencies to run the Mantella server, it comes with an embedded Python environment and all the dependencies it needs to run Mantella and Pantella out of the box
- Automatic Crash Recovery
- Easily manage Mantella repositories across multiple games and mod managers

## How to Use

Download the latest release from the releases tab, or clone this repository and build from source. Unzip the release following the instructions in the release notes, and run the Pantella_Launcher.exe. Download a fork and click Start to open Mantella/Pantella. After downloading and deploying a repository, please verify that all configuration settings are set in the repository you're trying to use before reporting a bug. Mantella uses config.ini and Pantella uses config.json/webUI settings. If you're having trouble with a repository, please report the issue to the repository's issue tracker unless this is an issue with the launcher itself.

### Warning:

Install on the same drive as your Mod Organizer 2 mods folder, or you will be writing and rewriting files to your drive constantly. This can cause damage to your drive over time, especially on SSDs.

## Build from Source

Open the project.godot file, or import the project folder into the project manager for Godot 4.2.1. Click Project>Export from the dropdown menu at the top left, then "Export All..." and finally Debug/Release depending on the type of build you're trying to make. The run_repo.py file can be edited without rebuilding the exe.

## llama-cpp-python Support

If a repository uses this package and you intend to use it, please install it using the included bat files. This is a requirement for some forks to run properly. If these forks have llama-cpp-python in their requirements.txt, it is recommended to disable automatic requirements.txt installation in the settings after the first run and overwrite the installed version with the included bat files for your setup if you're trying to use llama-cpp-python with a GPU.

## Installing Additional Requirements

If you need to manually install additional requirements, open a command prompt in the Mantella_Launcher folder and run the following command:


```
python-3.10.11-embed/python.exe -m pip install PACKAGE_NAME
```

This will install the package to the embedded python environment used by the launcher. Installing dependencies any other way will not work.

## Can't Read Error Messages

Run the ./run_repo.py file in the command prompt to see the error messages. This will help you diagnose the issue and report it to the fork's issue tracker. Here's an example of how to do this when running a command prompt in the Mantella_Launcher folder:

```
python-3.10.11-embed/python.exe ./run_repo.py "Git/Rename-This-Repo-Here"
```
Above is the way that the launcher itself will run the script, but you can also run it manually if you have python installed on your system and the correct depdenencies installed. Or you can directly run the Mantella script using the embedded python. The command prompt will show you the error messages that you can use to diagnose the issue and report it to the fork's issue tracker. The launcher itself also has a log file, and most Mantella forks also have a logging.log file as well.
