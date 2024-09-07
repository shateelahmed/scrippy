#!/bin/bash

script_location="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"

source $script_location/load-env.sh
source $script_location/target-directory.sh

# Check if a directory is a Git repository.
#
# Args:
#   $1 (string): Directory path to check.
#
# Returns:
#   0 if the directory is a Git repository, 1 otherwise.
is_git_repo() {
    # $1 is the first argument passed to the function
    directory="$1"
    # The -C option in the git command allows you to specify a different directory in which Git commands will be executed.
    # >/dev/null: Redirects standard output (stdout) to /dev/null (essentially discarding it).
    # 2>&1: Redirects stderr to stdout, which is already being discarded by /dev/null.
    git -C "$directory" rev-parse --is-inside-work-tree >/dev/null 2>&1
    # $? returns the exit status of the last executed command, which is 0 if the directory is a Git repository and non-zero otherwise.
    return $?
}

# Get terminal color codes
green=$(tput setaf 2)
reset=$(tput sgr0)

# Iterate over immediate child directories
for child_directory in in $(ls -d "$target_directory"/*/); do
    if is_git_repo "$child_directory"; then
        # child_directory_name will contain only the name of the child directory; not the full path
        child_directory_name="$(basename "${child_directory%/*}")"
        current_branch=$(git -C "$child_directory" branch --show-current)
        echo "$child_directory_name - ${green}$current_branch${reset}"
    fi
done