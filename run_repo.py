import sys
import os
import argparse
import json
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
                    repo_json = json_obj
                    break
        if repo_json is None:
            raise Exception("No config file found for this repository")
        repo_path = os.path.join(os.getcwd(), "repositories\\" + args.repo_path.replace("/", "_") + repo_json["dir_suffix"])
        sys.path.append(repo_path)
        launcher_logging.info(sys.path)
        # Change working directory to the repository
        os.chdir(repo_path)
        # Set vargs
        sys.argv = [
            repo_json['entry_point'],
        ] + repo_json["args"]
        launcher_logging.info(sys.argv)


        # Start the repository by running whatever entry point is specified to be as a cmd line arg
        if repo_json["install_requirements"]:
            command_script = python_path + " -m pip install -r " + os.path.join(repo_path, "requirements.txt")
            os.system(command_script)
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