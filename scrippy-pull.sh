#!/bin/bash

# This script runs "git pull" is each directoy residing in its parent directory (default) or in the given directory

script_location="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"

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
required_number_of_arguments=1
provided_number_of_arguments=${#arguments[@]}
if [ "$provided_number_of_arguments" != "$required_number_of_arguments" ]; then
    echo "$required_number_of_arguments argument required. $provided_number_of_arguments provided"
    exit
fi

source $script_location/load-env.sh
source $script_location/target-directory.sh
source $script_location/verify-git-repo.sh
source $script_location/directory-name.sh
source $script_location/terminal-color-codes.sh

branch_to_pull="${arguments[0]}"

echo "Target directory: ${green}$target_directory${reset}"
echo "Branch to pull: ${green}$branch_to_pull${reset}"
echo "Clear proxy: ${green}$clear_proxy${reset}"

source $script_location/clear-proxy.sh

for child_directory in $(ls -d $target_directory/*/); do # iterate over each directory
    if [ ! -d "$child_directory/.git" ]; then
        # condition 1: current child_directory is not a git repo

        continue
    fi

    git -C "$child_directory" ls-remote --exit-code --heads origin $branch_to_pull &> /dev/null # check if remote branch exists and set exit code to status variable "$?"
    exit_code="$?"
    if [ "$exit_code" != "0" ]; then # 0 = exists, 2 = does not exist
        continue
    fi

    child_directory_name=$(get_directory_name "$child_directory")
    echo -e "\nWorking directory ${green}$child_directory_name${reset}" # display child_directory name

    git -C "$child_directory" fetch --all --prune

    current_branch=$(git -C "$child_directory" branch --show-current)
    if [ "$current_branch" != "$branch_to_pull" ]; then  # if the current git branch is not "$branch_to_pull"
        git -C "$child_directory" checkout $branch_to_pull
        current_branch=$(git -C "$child_directory" branch --show-current)
    fi
    if [ "$current_branch" != "$branch_to_pull" ]; then  # if the current git branch is not "$branch_to_pull"
        echo "Could not checkout to $branch_to_pull. skipping..."
        continue # continue to next child_directory as could not checkout to "$branch_to_pull"
    fi

    git -C "$child_directory" pull
done
