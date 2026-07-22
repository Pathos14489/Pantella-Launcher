import sys
import os
import argparse
import json
import hashlib
import time

class Logger:
    def __init__(self, log_file = './launcher.log'):
        print("Creating Logger")
        self.format = '{time} {level}| {message}'
        self.log_file = log_file

    def get_message_object(self, *args, level = 'INFO'):
        return {
            'time': time.strftime('%Y-%m-%d %H:%M:%S', time.localtime()),
            'level': level,
            'message': ' '.join([str(arg) for arg in args])
        }

    def output(self, message: str, level: str):
        print(message)
        with open(self.log_file, 'a') as f:
            f.write(message + '\n')

    def info(self, *args):
        message = self.get_message_object(*args, level='INFO')
        self.output(self.format.format(**message), 'INFO')

    def error(self, *args):
        message = self.get_message_object(*args, level='ERROR')
        self.output(self.format.format(**message), 'ERROR')

    def warning(self, *args):
        message = self.get_message_object(*args, level='WARNING')
        self.output(self.format.format(**message), 'WARNING')

    def debug(self, *args):
        message = self.get_message_object(*args, level='DEBUG')
        self.output(self.format.format(**message), 'DEBUG')

launcher_logging = Logger() # Create a logger object to be used throughout the program

repo_configs = "repo_configs/"
repo_configs_path = os.path.join(os.getcwd(), repo_configs)
repo_config_path = None
python_path = "python-3.10.11-embed/python.exe"
python_path = os.path.join(os.getcwd(), python_path)

try:
    if __name__ == "__main__":
        parser = argparse.ArgumentParser(description='Run a repository')
        parser.add_argument('repo_path', type=str, help='The path to the repository directory')
        parser.add_argument('--dir_suffix', type=str, default="", help='The suffix to add to the directory name')
        args = parser.parse_args()
        launcher_logging.info("Attempting to run repository at " + args.repo_path)
        launcher_logging.info(sys.path)
        repo_json = None
        for file in os.listdir(repo_configs_path):
            if file.endswith(".json"):
                json_obj = json.load(open(os.path.join(repo_configs_path, file)))
                if "dir_suffix" not in json_obj:
                    json_obj["dir_suffix"] = ""
                # print(json_obj["repo"], args.repo_path, json_obj["dir_suffix"], args.dir_suffix)
                if json_obj["repo"] == args.repo_path and json_obj["dir_suffix"] == args.dir_suffix:
                    repo_config_path = os.path.join(repo_configs_path, file)
                    repo_json = json_obj
                    break
        if repo_json is None:
            raise Exception("No config file found for this repository")
        repo_path = os.path.join(os.getcwd(), "repositories\\" + args.repo_path.replace("/", "_") + repo_json["dir_suffix"])
        sys.path.append(repo_path)
        launcher_logging.info(sys.path)

        python_path = repo_json.get("python_binary", python_path)
        if "/" in python_path or "\\" in python_path:
            python_path = os.path.abspath(os.path.join(os.getcwd(), python_path))
        if not os.path.exists(python_path):
            launcher_logging.error("Python binary not found at " + python_path + ", make sure the path is correct and that the python binary exists at that location. If you're using the launcher, please make sure that you downloaded the embedded python package for this repository and that the path to the python binary is correct in the repository config file. If you're running this script manually, you can specify the path to the python binary in the repository config file as well, just add a field called python_binary with the path to the python binary as the value.")
            input("Press enter to exit...")
            raise Exception("Python binary not found at " + python_path)
        # Change working directory to the repository
        os.chdir(repo_path)

        needs_install = False

        requirements_hash = None

        requirements_filename = "requirements.txt"
        # Windows
        if os.name == 'nt':
            # Check for win_requirements.txt and install if it exists
            if os.path.exists(os.path.join(repo_path, "win_requirements.txt")):
                requirements_filename = "win_requirements.txt"
                launcher_logging.info("Found win_requirements.txt, using that instead of requirements.txt")


        if repo_json["install_requirements"]:
            with open(os.path.join(repo_path, requirements_filename), "rb") as f:
                requirements_hash = hashlib.md5(f.read()).hexdigest()
            launcher_logging.info("Requirements hash: " + requirements_hash)
            if "requirements_hash" in repo_json and repo_json["requirements_hash"].strip() != "":
                if repo_json["requirements_hash"] == requirements_hash:
                    launcher_logging.info("Requirements have not changed since last run, skipping installation")
                    needs_install = False
                else:
                    launcher_logging.info("Requirements have changed since last run, installing requirements")
                    needs_install = True
            else:
                launcher_logging.info("No requirements hash found, installing requirements")
                needs_install = True

        if needs_install and not repo_json["install_requirements"]:
            launcher_logging.warning("New requirements hash found but install_requirements is set to false, not installing requirements, but you should consider setting install_requirements to true to avoid this warning in the future! Pantella might stop working eventually if you don't install the requirements, so keep that in mind!")


                

        # Set vargs
        sys.argv = [
            repo_json['entry_point'],
        ] + repo_json["args"]
        launcher_logging.info(sys.argv)
        import sys
        sys.dont_write_bytecode = True

        if "-3.11.6-" in python_path:
            # Fix PyTorch DLL loading issue on Windows for Python 3.11 https://github.com/pytorch/pytorch/issues/166628
            # You need to add this at the beginning, before importing torch and other conflicting modules
            import os
            import platform
            if platform.system() == "Windows":
                import ctypes
                import site

                for site_path in site.getsitepackages():
                    torch_lib_path = os.path.join(site_path, "torch", "lib")
                    if os.path.exists(torch_lib_path):
                        # Pre-load torch DLLs
                        for dll in ['c10.dll', 'torch_cpu.dll', 'torch_python.dll']:
                            dll_path = os.path.join(torch_lib_path, dll)
                            if os.path.exists(dll_path):
                                try:
                                    ctypes.CDLL(dll_path)
                                except Exception:
                                    pass
                        break


        # Start the repository by running whatever entry point is specified to be as a cmd line arg
        if needs_install:
            installed_requirements = False
            installed_torch = False
            installed_llama_cpp_python = False
            if repo_json["install_requirements"]:
                command_script = f"\"{python_path}\" -m pip install -r \"{os.path.join(repo_path, requirements_filename)}\" --force-reinstall"
                launcher_logging.info(command_script)
                return_code = os.system('"' + command_script + '"')
                if return_code != 0:
                    launcher_logging.error("Failed to install requirements")
                    input("Press enter to exit...")
                    raise Exception("Failed to install requirements")
                installed_requirements = True

            if repo_json.get("install_cuda_torch", False):
                cuda_torch_requirements_filename = "cuda_torch_requirements.txt"
                if os.path.exists(os.path.join(repo_path, cuda_torch_requirements_filename)):
                    torch_command_script = f"\"{python_path}\" -m pip install -r \"{os.path.join(repo_path, cuda_torch_requirements_filename)}\" --force-reinstall --no-deps --no-cache-dir --upgrade"
                    launcher_logging.info(torch_command_script)
                    return_code = os.system('"' + torch_command_script + '"')
                    if return_code != 0:
                        launcher_logging.error("Failed to install CUDA torch requirements")
                        input("Press enter to exit...")
                        raise Exception("Failed to install CUDA torch requirements")
                    installed_torch = True
                else:
                    launcher_logging.error("install_cuda_torch is set to true, but cuda_torch_requirements.txt not found in repository, cannot install CUDA torch requirements")
                    input("Press enter to exit...")
                    raise Exception("install_cuda_torch is set to true, but cuda_torch_requirements.txt not found in repository, cannot install CUDA torch requirements")
            else:
                launcher_logging.info("install_cuda_torch is set to false, skipping installation of CUDA torch requirements")
                installed_torch = True # If we don't need to install it, we can consider it installed

            # Windows
            if repo_json.get("install_llama-cpp-python", False) and os.name == 'nt':
                # Check for llama_cpp_python_wheels.json in repo dir
                llama_cpp_python_wheels_path = os.path.join(repo_path, "llama_cpp_python_wheels.json")
                if not os.path.exists(llama_cpp_python_wheels_path):
                    launcher_logging.error("llama_cpp_python_wheels.json not found in repository, cannot install llama-cpp-python")
                    input("Press enter to exit...")
                    raise Exception("llama_cpp_python_wheels.json not found in repository, cannot install llama-cpp-python")
                launcher_logging.info("Found llama_cpp_python_wheels.json, installing llama-cpp-python")
                with open(llama_cpp_python_wheels_path, "r") as f:
                    llama_cpp_python_wheels = json.load(f)
                # Get the correct wheel for the current cuda version
                import torch # Only import if we need to install llama-cpp-python, since torch is needed to determine the correct wheel to install
                cuda_version = torch.version.cuda
                cuda_slug = None if cuda_version is None else "cu" + cuda_version.replace(".", "")
                wheel_url = llama_cpp_python_wheels.get(cuda_slug, None)
                if wheel_url is None:
                    launcher_logging.error("No wheel found for current cuda version: " + str(cuda_version) + ", cannot install llama-cpp-python! Please reach out for support, this is not something you can fix or your fault!")
                    input("Press enter to exit...")
                    raise Exception("No wheel found for current platform and python version, cannot install llama-cpp-python")
                wheel_install_command = f"\"{python_path}\" -m pip install --force-reinstall \"{wheel_url}\" --no-deps --no-cache-dir --upgrade"
                launcher_logging.info(wheel_install_command)
                return_code = os.system('"' + wheel_install_command + '"')
                if return_code != 0:
                    launcher_logging.error("Failed to install llama-cpp-python - local inference not available -- please reach out for support, this is not something you can fix or your fault!")
                else:
                    launcher_logging.info("Successfully installed llama-cpp-python")
                    installed_llama_cpp_python = True
            else:
                launcher_logging.info("install_llama-cpp-python is set to false or not on Windows, skipping installation of llama-cpp-python")
                installed_llama_cpp_python = True # If we don't need to install it, we can consider it installed
            
            if installed_requirements and installed_torch and installed_llama_cpp_python:
                # Update the requirements hash in the repo config file
                repo_json["requirements_hash"] = requirements_hash
                with open(repo_config_path, "w") as f:
                    json.dump(repo_json, f, indent=4)
                launcher_logging.info("Updated requirements hash in repo config file")

                


                        
        exec(open(os.path.join(repo_path, repo_json['entry_point'])).read())
        
        # command_script = python_path + " " + os.path.join(repo_path, repo_json["entry_point"] + " " + " ".join(repo_json["args"]))
        # print(command_script)
        # command_script = "cd " + repo_path + " && " + command_script
        # os.system(command_script)
except Exception as e:
    launcher_logging.error("An error occurred while trying to run the repository")
    launcher_logging.error(e)
    input("Press enter to exit...")
    raise e