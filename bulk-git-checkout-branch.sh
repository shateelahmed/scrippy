#!/bin/bash

# This script checks out to a specific local branch in all directories

script_location="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"

source $script_location/load-env.sh
source $script_location/target-directory.sh
source $script_location/args.sh

required_number_of_arguments=1
provided_number_of_arguments=${#arguments[@]}
if [ "$provided_number_of_arguments" != 1 ]; then
    echo "$required_number_of_arguments branch name required. $provided_number_of_arguments provided"
    exit
fi

branch_to_checkout="${arguments[0]}"
if [ -z "$branch_to_checkout" ]; then
    echo "Branch name is required"
    exit
fi

echo "Target directory: $target_directory"
echo "Branch to checkout: $branch_to_checkout"

for folder in $(ls -d $target_directory/*/); do # iterate over each directory
    pushd $folder &> /dev/null # change present working directory
    if [ -d .git ]; then # check if current folder is a git repo
        if git show-ref --quiet --heads $branch_to_checkout; then # Check if branch exists locally
            current_branch=$(git branch --show-current)
            if [ "$current_branch" != "$branch_to_checkout" ]; then  # if the current git branch is not "$branch_to_checkout"
                git checkout $branch_to_checkout
                current_branch=$(git branch --show-current)
            fi
            if [ "$current_branch" != "$branch_to_checkout" ]; then  # if the current git branch is not "$branch_to_checkout"
                echo "Could not checkout in $folder"
            else
                echo "Checked out in $folder"
            fi
        fi
    fi

    popd &> /dev/null
done