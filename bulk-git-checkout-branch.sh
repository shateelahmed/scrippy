#!/bin/bash

# This script checks out to a specific local branch in all directories

script_location="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"

source $script_location/load-env.sh
source $script_location/target-directory.sh

read -p "Branch to checkout: " branch_to_checkout
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