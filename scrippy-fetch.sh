#!/bin/bash

# This script runs "git fetch --all --prune" is each directoy residing in its parent directory (default) or in the given directory

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
source $script_location/directory-name.sh
source $script_location/terminal-color-codes.sh

echo "Target directory: ${green}$target_directory${reset}"
echo "Clear proxy: ${green}$clear_proxy${reset}"

source $script_location/clear-proxy.sh

for child_directory in $(ls -d $target_directory/*/); do # iterate over each directory
    if [ ! -d "$child_directory/.git" ]; then
        # condition 1: current child_directory is not a git repo

        continue
    fi

    child_directory_name=$(get_directory_name "$child_directory")
    echo -e "\nWorking directory: ${green}$child_directory_name${reset}" # display child_directory name

    git -C "$child_directory" fetch --all --prune
done