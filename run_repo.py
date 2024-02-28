import sys
import os
import argparse
import json

repo_configs = "repo_configs/"
repo_configs_path = os.path.join(os.getcwd(), repo_configs)
python_path = "python-3.10.11-embed/python.exe"
python_path = os.path.join(os.getcwd(), python_path)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Run a repository')
    parser.add_argument('repo_path', type=str, help='The path to the repository directory')
    args = parser.parse_args()
    print(sys.path)
    repo_path = os.path.join(os.getcwd(), "repositories/" + args.repo_path.replace("/", "_"))
    repo_json = None
    for file in os.listdir(repo_configs_path):
        if file.endswith(".json"):
            json_obj = json.load(open(os.path.join(repo_configs_path, file)))
            if json_obj["repo"] == args.repo_path:
                repo_json = json_obj
                break
    if repo_json is None:
        raise Exception("No config file found for this repository")
    sys.path.append(repo_path)
    print(sys.path)
    # Change working directory to the repository
    os.chdir(repo_path)
    # Set vargs
    sys.argv = [
        repo_json['entry_point'],
    ] + repo_json["args"]
    print(sys.argv)


    # Start the repository by running whatever entry point is specified to be as a cmd line arg
    if repo_json["install_requirements"]:
        command_script = python_path + " -m pip install -r " + os.path.join(repo_path, "requirements.txt")
        os.system(command_script)
    exec(open(os.path.join(repo_path, repo_json['entry_point'])).read())
    
    # command_script = python_path + " " + os.path.join(repo_path, repo_json["entry_point"] + " " + " ".join(repo_json["args"]))
    # print(command_script)
    # command_script = "cd " + repo_path + " && " + command_script
    # os.system(command_script)
    