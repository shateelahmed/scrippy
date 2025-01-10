#!/bin/bash

# This script runs "git merge" is each directoy residing in its parent directory (default) or in the given directory

script_location="$(realpath "$(dirname "${BASH_SOURCE[0]}")/..")"

# Convert long options to short ones
for arg in "$@"; do
    shift
    case "$arg" in
    "--directory")
        set -- "$@" "-d" # Convert --directory to -d
        ;;
    "--clear-proxy")
        set -- "$@" "-c" # Convert --clear-proxy to -c
        ;;
    *)
        set -- "$@" "$arg"
        ;; # Pass through the original argument if no match
    esac
done

clear_proxy=false

# Use getopts for short options
while getopts "d:c" opt; do
    case $opt in
    d)
        # echo "Flag -d or --directory was triggered, Parameter: $OPTARG"
        target_directory="$OPTARG"
        ;;
    c)
        clear_proxy=true
        ;;
    # \?)
    #     echo "Invalid option: -$OPTARG"
    #     ;;
    esac
done

# Shift off the options and flags, so only positional arguments remain
shift $((OPTIND - 1))

# Handle positional arguments (remaining after flags)
arguments=("$@")
required_number_of_arguments=2
provided_number_of_arguments=${#arguments[@]}
if [ "$provided_number_of_arguments" != "$required_number_of_arguments" ]; then
    echo "$required_number_of_arguments arguments required. $provided_number_of_arguments provided"
    exit
fi

source $script_location/lib/load-env.sh
source $script_location/lib/target-directory.sh
source $script_location/lib/verify-git-repo.sh
source $script_location/lib/directory-name.sh
source $script_location/lib/terminal-color-codes.sh

source_branch="${arguments[0]}"
target_branch="${arguments[1]}"

echo "Target directory: ${green}$target_directory${reset}"
echo "Source branch: ${green}$source_branch${reset}"
echo "Target branch: ${green}$target_branch${reset}"
echo "Clear proxy: ${green}$clear_proxy${reset}"

source $script_location/lib/clear-proxy.sh

for child_directory in $(ls -d $target_directory/*/); do # iterate over each directory
    if [ ! -d "$child_directory/.git" ] \
    || ! ( git -C "$child_directory" show-ref --quiet --heads $source_branch ) \
    || ! ( git -C "$child_directory" show-ref --quiet --heads $target_branch ); then
        # condition 1: current child_directory is not a git repo
        # condition 2: source_branch does not exist locally
        # condition 3: target_branch does not exist locally

        continue
    fi

    child_directory_name=$(get_directory_name "$child_directory")
    echo -e "\nWorking directory ${green}$child_directory_name${reset}" # display child_directory name

    current_branch=$(git -C "$child_directory" branch --show-current)
    if [ "$current_branch" != "$target_branch" ]; then  # if the current git branch is not "$target_branch"
        git -C "$child_directory" checkout $target_branch
        current_branch=$(git -C "$child_directory" branch --show-current)
    fi
    if [ "$current_branch" != "$target_branch" ]; then  # if the current git branch is not "$target_branch"
        echo "Could not checkout to $target_branch. skipping..."
        continue # continue to next child_directory as could not checkout to "$target_branch"
    fi

    git -C "$child_directory" merge $source_branch
done
