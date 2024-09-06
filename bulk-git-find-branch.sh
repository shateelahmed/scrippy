#!/bin/bash

# Find a branch in remote and local repository

script_location="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"

source $script_location/load-env.sh
source $script_location/target-directory.sh

branch_to_find="$1" # $1 contains the first command line argument passed to the script
if [ -z "$branch_to_find" ]; then
    echo "Branch name is required"
    exit
fi

echo "Target directory: $target_directory"
echo "Branch to find: $branch_to_find"

source $script_location/clear-proxy.sh

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
        if [ -z "$found" ]; then
            found="y"
        fi
        echo "$exists: $folder" # display folder name
    fi

    popd &> /dev/null
done

if [ -z "$found" ]; then
    echo "Branch not found in any repo"
fi