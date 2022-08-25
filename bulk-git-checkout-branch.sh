#!/bin/bash

# This script checks out to a specific local branch in all directories

env_file_location="./.env"
if [ -f "$env_file_location" ]; then # set ENV varaibles from .env file if it exists
    set -o allexport
    source $env_file_location
    set +o allexport
fi

default_target_directory="${BULK_GIT_TARGET_DIR:-$(pwd)}"

read -p "Enter absolute path to directory (Default: $default_target_directory): " target_directory
target_directory="${target_directory:-$default_target_directory}"
if ! [ -d $target_directory ]; then
    echo "$target_directory is not a valid directory"
    exit
fi

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