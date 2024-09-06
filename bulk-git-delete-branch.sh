#!/bin/bash

# Find a branch in remote and local repository

script_location="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"

source $script_location/load-env.sh
source $script_location/target-directory.sh

default_clear_proxy="${BULK_GIT_CLEAR_PROXY:-n}"
default_delete_remote_branch="${BULK_GIT_DELETE_REMOTE_BRANCH:-n}"

branch_to_delete="$1" # $1 contains the first command line argument passed to the script
if [ -z "$branch_to_delete" ]; then
    echo "Branch name is required"
    exit
else
    if [ "$branch_to_delete" == "${BULK_GIT_DEFAULT_BRANCH}" ]; then
        echo "Default branch cannot be deleted"
        exit
    fi
fi

read -p "Delete remote branch (y/n) (Default: $default_delete_remote_branch): " delete_remote_branch
delete_remote_branch="${delete_remote_branch:-$default_delete_remote_branch}"
if [ "$delete_remote_branch" != "n" ] && [ "$delete_remote_branch" != "y" ]; then
    echo "Invalid input"
    exit
fi

read -p "Clear proxy (y/n) (Default: $default_clear_proxy): " clear_proxy
clear_proxy="${clear_proxy:-$default_clear_proxy}"
if [ "$clear_proxy" != "n" ] && [ "$clear_proxy" != "y" ]; then
    echo "Invalid input"
    exit
fi

echo "Target directory: $target_directory"
echo "Branch to delete: $branch_to_delete"
echo "Clear proxy: $clear_proxy"
echo "Delete remote branch: $delete_remote_branch"

if [ "$clear_proxy" == "y" ]; then
    unset HTTPS_PROXY https_proxy HTTP_PROXY http_proxy NO_PROXY no_proxy
    echo "Cleared proxy"
fi

found="" # flag to check if branch is found in any folder of the $target_directory

for folder in $(ls -d $target_directory/*/); do # iterate over each directory
    pushd $folder &> /dev/null # change present working directory
    exists="" # flag to check if branch exists locally and/or remotely
    deleted="" # flag to check if branch exists locally and/or remotely
    could_not_delete_local_branch=""
    if [ -d .git ]; then # check if current folder is a git repo
        if git show-ref --quiet --heads $branch_to_delete; then # Check if branch exists locally
            exists+="local"

            current_branch=$(git branch --show-current)
            if [ "$current_branch" == "$branch_to_delete" ]; then  # if the current git branch is "$branch_to_delete"
                git checkout ${BULK_GIT_DEFAULT_BRANCH} &> /dev/null
                current_branch=$(git branch --show-current)
            fi
            if [ "$current_branch" == "$branch_to_delete" ]; then  # if the current git branch is "$branch_to_delete"
                could_not_delete_local_branch="y"
                echo "Could not checkout to default branch in $folder. skipping..."
            else
                git branch -D $branch_to_delete
                deleted+="local"
            fi
        fi

        if [ "$delete_remote_branch" == "y" ] && [ -z "$could_not_delete_local_branch" ]; then
            git ls-remote --exit-code --heads origin $branch_to_delete &> /dev/null # check if remote branch exists and set exit code to status variable "$?"
            exit_code="$?"
            if [ "$exit_code" == "0" ]; then # 0 = exists, 2 = does not exist
                if [ ! -z "$exists" ]; then
                    exists+=" & "
                fi
                exists+="remote"

                default_branch_in_remote=$(git remote show origin | sed -n '/HEAD branch/s/.*: //p')
                if [ "$branch_to_delete" == "${default_branch_in_remote}" ]; then
                    echo "$branch_to_delete is the default branch in $folder. It cannot be deleted."
                else
                    git push origin --delete $branch_to_delete
                    if [ ! -z "$deleted" ]; then
                        deleted+=" & "
                    fi
                    deleted+="remote"
                fi
            fi
        fi
    fi

    if [ ! -z "$exists" ]; then
        if [ -z "$found" ]; then
            found="y"
        fi
        if [ ! -z "$deleted" ]; then
            echo "$deleted deleted: $folder" # display folder name
        fi
    fi

    popd &> /dev/null
done

if [ -z "$found" ]; then
    echo "Branch not found in any repo"
fi