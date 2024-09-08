#!/bin/bash

script_location="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"

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

source $script_location/load-env.sh
source $script_location/target-directory.sh
source $script_location/verify-git-repo.sh

# Get terminal color codes
green=$(tput setaf 2)
reset=$(tput sgr0)

echo "Target directory: $target_directory"

# Iterate over immediate child directories
for child_directory in in $(ls -d "$target_directory"/*/); do
    if is_git_repo "$child_directory"; then
        # child_directory_name will contain only the name of the child directory; not the full path
        child_directory_name="$(basename "${child_directory%/*}")"
        current_branch=$(git -C "$child_directory" branch --show-current)
        echo "$child_directory_name - ${green}$current_branch${reset}"
    fi
done
