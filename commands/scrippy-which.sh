#!/bin/bash

script_location="$(realpath "$(dirname "${BASH_SOURCE[0]}")/..")"

# Convert long options to short ones
for arg in "$@"; do
    shift
    case "$arg" in
    "--directory")
        set -- "$@" "-d" # Convert --directory to -d
        ;;
    *)
        set -- "$@" "$arg"
        ;; # Pass through the original argument if no match
    esac
done

# Use getopts for short options
while getopts "d:" opt; do
    case $opt in
    d)
        # echo "Flag -d or --directory was triggered, Parameter: $OPTARG"
        target_directory="$OPTARG"
        ;;
    # \?)
    #     echo "Invalid option: -$OPTARG"
    #     ;;
    esac
done

source $script_location/lib/load-env.sh
source $script_location/lib/target-directory.sh
source $script_location/lib/verify-git-repo.sh
source $script_location/lib/directory-name.sh
source $script_location/lib/terminal-color-codes.sh

echo "Target directory: $target_directory"
# exit

# Iterate over immediate child directories
for child_directory in $(ls -d $target_directory/*/); do # iterate over each directory
    if ! is_git_repo "$child_directory"; then
        # condition 1: current child_directory is not a git repo

        continue
    fi

    child_directory_name=$(get_directory_name "$child_directory")
    current_branch=$(git -C "$child_directory" branch --show-current)
    echo "$child_directory_name - ${green}$current_branch${reset}"
done
