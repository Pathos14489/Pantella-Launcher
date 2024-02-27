import sys
import os
import argparse

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Run a repository')
    parser.add_argument('repo_path', type=str, help='The path to the repository directory')
    parser.add_argument('entry_point', type=str, help='The entry point of the repository')
    args = parser.parse_args()
    print(sys.path)
    repo_path = os.path.join(os.getcwd(), "repositories/" + args.repo_path.replace("/", "_"))
    sys.path.append(repo_path)
    print(sys.path)
    # Start the repository by running whatever entry point is specified to be as a cmd line arg
    exec(open(os.path.join(repo_path, args.entry_point)).read())
    