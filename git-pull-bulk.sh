#!/bin/bash

# This script runs "git pull" is each directoy residing in its parent directory (default) or in the given directory

read -p "Enter absolute path to directory (Current: $(pwd)): " target_directory
if [ "$target_directory" != "" ]; then
    if ! [ -d $target_directory ]; then
        echo "$target_directory is not a valid directory"
        exit
    fi
else
    target_directory=$(pwd)
fi

echo "Target directory $target_directory"

for folder in $(ls -d $target_directory/*/); do # iterate over each directory
    echo "Currently working in $folder" # display folder name
    pushd $folder &> /dev/null # change present working directory\
    current_branch=$(git branch --show-current)
    if [ "$current_branch" != "master" ]; then  # if the current git branch is not "master"
        git checkout master &> /dev/null
    fi
    if [ "$(git branch --show-current)" == "master" ]; then  # if the current git branch is "master"
        git fetch --all --prune
        git pull
    fi
    if [ "$current_branch" != "master" ]; then  # if the current git branch is not "master"
        git checkout $current_branch &> /dev/null
    fi

    popd &> /dev/null
done