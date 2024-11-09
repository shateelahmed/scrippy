#!/bin/bash

# Delete a branch in all directories and optionally delete the remote branch as well

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
    "--delete-remote-branch")
        set -- "$@" "-r" # Convert --delete-remote-branch to -r
        ;;
    *)
        set -- "$@" "$arg"
        ;; # Pass through the original argument if no match
    esac
done

clear_proxy=false
delete_remote_branch=false

# Use getopts for short options
while getopts "d:cr" opt; do
    case $opt in
    d)
        # echo "Flag -d or --directory was triggered, Parameter: $OPTARG"
        target_directory="$OPTARG"
        ;;
    c)
        clear_proxy=true
        ;;
    r)
        delete_remote_branch=true
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

branch_to_delete="${arguments[0]}"

echo "Target directory: ${green}$target_directory${reset}"
echo "Branch to delete: ${green}$branch_to_delete${reset}"
echo "Clear proxy: ${green}$clear_proxy${reset}"
echo "Delete remote branch: ${green}$delete_remote_branch${reset}"

source $script_location/clear-proxy.sh

found="" # flag to check if branch is found in any child_directory of the $target_directory

for child_directory in $(ls -d $target_directory/*/); do # iterate over each directory
    if [ ! -d "$child_directory/.git" ]; then
        # condition 1: current child_directory is not a git repo

        continue
    fi

    child_directory_name=$(get_directory_name "$child_directory")
    echo -e "\nWorking directory ${green}$child_directory_name${reset}" # display child_directory name

    exists="" # flag to check if branch exists locally and/or remotely
    deleted="" # flag to check if branch exists locally and/or remotely
    could_not_delete_local_branch=""
    if git -C "$child_directory" show-ref --quiet --heads $branch_to_delete; then # Check if branch exists locally
        exists+="local"

        current_branch=$(git -C "$child_directory" branch --show-current)
        if [ "$current_branch" == "$branch_to_delete" ]; then  # if the current git branch is "$branch_to_delete"
            git -C "$child_directory" checkout ${BULK_GIT_DEFAULT_BRANCH} &> /dev/null
            current_branch=$(git -C "$child_directory" branch --show-current)
        fi
        if [ "$current_branch" == "$branch_to_delete" ]; then  # if the current git branch is "$branch_to_delete"
            could_not_delete_local_branch="y"
            echo "Could not checkout to default branch in $child_directory. skipping..."
        else
            git -C "$child_directory" branch -D $branch_to_delete
            deleted+="local"
        fi
    fi

    if $delete_remote_branch && [ -z "$could_not_delete_local_branch" ]; then
        git -C "$child_directory" ls-remote --exit-code --heads origin $branch_to_delete &> /dev/null # check if remote branch exists and set exit code to status variable "$?"
        exit_code="$?"
        if [ "$exit_code" == "0" ]; then # 0 = exists, 2 = does not exist
            if [ ! -z "$exists" ]; then
                exists+=" & "
            fi
            exists+="remote"

            default_branch_in_remote=$(git -C "$child_directory" remote show origin | sed -n '/HEAD branch/s/.*: //p')
            if [ "$branch_to_delete" == "${default_branch_in_remote}" ]; then
                echo "$branch_to_delete is the default branch in $child_directory. It cannot be deleted."
            else
                git -C "$child_directory" push origin --delete $branch_to_delete
                if [ ! -z "$deleted" ]; then
                    deleted+=" & "
                fi
                deleted+="remote"
            fi
        fi
    fi

    if [ ! -z "$exists" ]; then
        if [ -z "$found" ]; then
            found="y"
        fi
        if [ ! -z "$deleted" ]; then
            echo "$deleted deleted: ${green}$child_directory_name${reset}" # display child_directory name
        fi
    fi
done

if [ -z "$found" ]; then
    echo "Branch not found in any repository"
fi