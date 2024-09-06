#!/bin/bash

# Find a branch in remote and local repository

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

branch_to_delete="${arguments[0]}"
if [ "$branch_to_delete" == "${BULK_GIT_DEFAULT_BRANCH}" ]; then
    echo "Default branch cannot be deleted"
    exit
fi

delete_remote_branch=false

# Loop through the array
for flag in "${short_flags[@]}"; do
    if [ "$flag" == "-r" ]; then
        delete_remote_branch=true
        break
    fi
done
if ! $delete_remote_branch; then
    for flag in "${long_flags[@]}"; do
        if [ "$flag" == "--remote" ]; then
            delete_remote_branch=true
            break
        fi
    done
fi

echo "Target directory: $target_directory"
echo "Branch to delete: $branch_to_delete"
echo "Delete remote branch: $delete_remote_branch"

source $script_location/clear-proxy.sh

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

        if $delete_remote_branch && [ -z "$could_not_delete_local_branch" ]; then
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