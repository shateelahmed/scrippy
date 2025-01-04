#!/bin/bash

# Delete a branch in all directories and optionally delete the remote branch as well

script_location="$(realpath "$(dirname "${BASH_SOURCE[0]}")/..")"

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
        target_directory="$OPTARG"
        ;;
    c)
        clear_proxy=true
        ;;
    r)
        delete_remote_branch=true
        ;;
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

# Source library files
for lib_file in "$script_location"/lib/*.sh; do
    source "$lib_file"
done

branch_to_delete="${arguments[0]}"

# Print formatted output
echo -e "Target directory           : ${green}$target_directory${reset}"
echo -e "Branch to delete           : ${green}$branch_to_delete${reset}"
echo -e "Clear proxy                : ${green}$clear_proxy${reset}"
echo -e "Delete remote branch       : ${green}$delete_remote_branch${reset}"


while true; do
    spin
    sleep 0.1
done &

# source $script_location/lib/clear-proxy.sh

branch_found=false # Flag to track if the branch is found at all

# Function to print the failure message
print_failure_message() {
    local dir_name="$1"
    local reason="$2"
    echo -e "\n✘ ${red}Directory: $dir_name${reset}" # Directory in red with ✘
    echo "    - Changes:"
    echo "        $reason"
    echo "    - Status: ${red}Branch delete failed${reset}"
}

# Iterate over directories and check for the branch
for child_directory in $(ls -d $target_directory/*/); do # iterate over each directory
    if [ ! -d "$child_directory/.git" ]; then
        continue
    fi

    child_directory_name=$(get_directory_name "$child_directory")

    exists="" # flag to check if branch exists locally and/or remotely
    deleted="" # flag to check if branch is deleted locally and/or remotely
    could_not_delete_local_branch=""

    # Check if branch exists locally
    if git -C "$child_directory" show-ref --quiet --heads $branch_to_delete; then
        exists+="local"

        current_branch=$(git -C "$child_directory" branch --show-current)
        if [ "$current_branch" == "$branch_to_delete" ]; then  # if the current git branch is "$branch_to_delete"
            git -C "$child_directory" checkout ${DEFAULT_BRANCH} &> /dev/null
            current_branch=$(git -C "$child_directory" branch --show-current)
        fi
        if [ "$current_branch" == "$branch_to_delete" ]; then
            # If the branch is the default branch, don't delete
            print_failure_message "$child_directory_name" "Branch $branch_to_delete is the default branch and cannot be deleted."
            could_not_delete_local_branch="y"
            continue
        fi

        # Delete local branch if not the default
        git -C "$child_directory" branch -D "$branch_to_delete" &>/dev/null
        deleted+="local"
    fi

    # Check and delete remote branch if required
    if $delete_remote_branch && [ -z "$could_not_delete_local_branch" ]; then
        git_output=$(git -C "$child_directory" push origin --delete $branch_to_delete 2>&1)
        exit_code="$?"

        if [ "$exit_code" == "0" ]; then # Successfully deleted
            exists+=" & remote"

            default_branch_in_remote=$(git -C "$child_directory" remote show origin | sed -n '/HEAD branch/s/.*: //p')
            if [ "$branch_to_delete" == "${default_branch_in_remote}" ]; then
                # Include the "branch is the default" message in the changes section
                print_failure_message "$child_directory_name" "Branch $branch_to_delete is the default branch and cannot be deleted."
                continue
            else
                if [ ! -z "$deleted" ]; then
                    deleted+=" & "
                fi
                deleted+="remote"

                # Corrected indentation here
                echo -e "\n✔ Directory: ${green}$child_directory_name${reset}" # Directory in green with ✔
                echo "    - Changes:"
                echo "        The branch '$branch_to_delete' was deleted from $deleted"
                echo "        To $(git -C "$child_directory" remote get-url origin)"
                echo "        - [deleted]         $branch_to_delete"  # Correct indentation
                echo "    - Status: ${green}Branch deleted successfully${reset}"
            fi
        else
            # Error occurred, print failure
            print_failure_message "$child_directory_name" "Failed to delete remote branch. Output: $git_output"
        fi
    else
        # Handle case where branch doesn't exist remotely
        if [ -z "$exists" ]; then
            print_failure_message "$child_directory_name" "Branch $branch_to_delete not found in this directory."
        fi
    fi
done

kill $!

# Ensure the spinner is stopped after the final fetch
endspin
