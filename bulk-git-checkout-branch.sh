#!/bin/bash

# This script checks out to a specific local branch in all directories

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

branch_to_checkout="${arguments[0]}"

echo "Target directory: ${green}$target_directory${reset}"
echo "Branch to checkout: ${green}$branch_to_checkout${reset}"

for child_directory in $(ls -d $target_directory/*/); do # iterate over each directory
    if [ ! -d "$child_directory/.git" ] \
    || ! ( git -C "$child_directory" show-ref --quiet --heads $branch_to_checkout ); then
        # condition 1: current child_directory is not a git repo
        # condition 2: branch_to_checkout does not exist locally

        continue
    fi

    child_directory_name=$(get_directory_name "$child_directory")
    echo -e "\nWorking directory ${green}$child_directory_name${reset}" # display child_directory name

    current_branch=$(git -C "$child_directory" branch --show-current)
    if [ "$current_branch" != "$branch_to_checkout" ]; then  # if the current git branch is not "$branch_to_checkout"
        git -C "$child_directory" checkout $branch_to_checkout
        current_branch=$(git -C "$child_directory" branch --show-current)
    fi
    if [ "$current_branch" != "$branch_to_checkout" ]; then  # if the current git branch is not "$branch_to_checkout"
        echo "Could not checkout"
        continue
    fi

    echo "Checked out"
done