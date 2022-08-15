#!/bin/bash

# Find a branch in remote and local repository

env_file_location="./.env"
if [ -f "$env_file_location" ]; then # set ENV varaibles from .env file if it exists
    set -o allexport
    source $env_file_location
    set +o allexport
fi

default_target_directory="${BULK_GIT_TARGET_DIR:-$(pwd)}"
default_clear_proxy="${BULK_GIT_CLEAR_PROXY:-n}"

read -p "Absolute path to directory (Default: $default_target_directory): " target_directory
target_directory="${target_directory:-$default_target_directory}"
if ! [ -d $target_directory ]; then
    echo "$target_directory is not a valid directory"
    exit
fi

read -p "Branch to find: " branch_to_find
if [ -z "$branch_to_find" ]; then
    echo "Branch name is required"
    exit
fi

read -p "Clear proxy (y/n) (Default: $default_clear_proxy): " clear_proxy
clear_proxy="${clear_proxy:-$default_clear_proxy}"
if [ "$clear_proxy" != "n" ] && [ "$clear_proxy" != "y" ]; then
    echo "Invalid input"
    exit
fi

echo "Target directory: $target_directory"
echo "Branch to find: $branch_to_find"
echo "Clear proxy: $clear_proxy"

found="" # flag to check if branch is found in any folder of the $target_directory

for folder in $(ls -d $target_directory/*/); do # iterate over each directory
    pushd $folder &> /dev/null # change present working directory
    exists="" # flag to check if branch exists locally and/or remotely
    if [ -d .git ]; then # check if current folder is a git repo
        if git show-ref --quiet --heads $branch_to_find; then # Check if branch exists locally
            exists+="local"
        fi

        git ls-remote --exit-code --heads origin $branch_to_find &> /dev/null # check if remote branch exists and set exit code to status variable "$?"
        exit_code="$?"
        if [ "$exit_code" == "0" ]; then # 0 = exists, 2 = does not exist
            if [ ! -z "$exists" ]; then
                exists+=" & "
            fi
            exists+="remote"
        fi
    fi

    if [ ! -z "$exists" ]; then
        if [ -z $found ]; then
            found="y"
        fi
        echo "$exists: $folder" # display folder name
    fi

    popd &> /dev/null
done

if [ -z $found ]; then
    echo "Branch not found in any repo"
fi