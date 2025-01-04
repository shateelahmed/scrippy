#!/bin/bash

# Script location
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

# Flags
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

# Branch to delete
branch_to_delete="${arguments[0]}"

# Print formatted output
echo -e "Target directory           : ${green}$target_directory${reset}"
echo -e "Branch to delete           : ${green}$branch_to_delete${reset}"
echo -e "Clear proxy                : ${green}$clear_proxy${reset}"
echo -e "Delete remote branch       : ${green}$delete_remote_branch${reset}"

# Start spinner in background
while true; do
    spin
    sleep 0.1
done &

# Function to print success messages
print_success_message() {
    local child_directory_name="$1"
    local branch_to_delete="$2"
    local change_type="$3" # 'local' or 'remote'
    local remote_url="$4" # Remote URL for remote deletion message

    if [ "$change_type" == "local" ]; then
        echo -e "\n✔ Directory: ${green}$child_directory_name${reset}"
        echo "    - Changes:"
        echo "        The branch '$branch_to_delete' was deleted locally."
        echo "    - Status: ${green}Local branch deleted successfully${reset}"
    elif [ "$change_type" == "remote" ]; then
        echo -e "\n✔ Directory: ${green}$child_directory_name${reset}"
        echo "    - Changes:"
        echo "        The branch '$branch_to_delete' was deleted from remote."
        echo "        Remote URL: ${remote_url}" # Now using the provided remote URL
        echo "        - [deleted]         $branch_to_delete"
        echo "    - Status: ${green}Branch deleted successfully${reset}"
    fi
}

# Function to print failure messages
print_failure_message() {
    local dir_name="$1"
    local reason="$2"
    echo -e "\n✘ ${red}Directory: $dir_name${reset}" # Directory in red with ✘
    echo "    - Changes:"
    echo "        $reason"
    echo "    - Status: ${red}Branch delete failed${reset}"
}

# Function to delete a branch (local and/or remote)
delete_branch() {
    local child_directory="$1"
    local child_directory_name="$2"
    local branch_to_delete="$3"
    local is_local="$4"
    local is_remote="$5"

    # Check and delete local branch
    if [ "$is_local" == "true" ]; then
        git -C "$child_directory" branch -D "$branch_to_delete" &>/dev/null
        if [ $? -eq 0 ]; then
            print_success_message "$child_directory_name" "$branch_to_delete" "local"
        else
            print_failure_message "$child_directory_name" "Failed to delete local branch."
        fi
    fi

    # Check and delete remote branch
    if [ "$is_remote" == "true" ]; then
        git_output=$(git -C "$child_directory" push origin --delete "$branch_to_delete" 2>&1)
        if [ $? -eq 0 ]; then
            remote_url=$(git -C "$child_directory" remote get-url origin)  # Get remote URL here
            print_success_message "$child_directory_name" "$branch_to_delete" "remote" "$remote_url"
        else
            print_failure_message "$child_directory_name" "Failed to delete remote branch. Output: $git_output"
        fi
    fi
}

# Iterate over directories and delete branch
for child_directory in $(ls -d $target_directory/*/); do
    if [ ! -d "$child_directory/.git" ]; then
        continue
    fi

    child_directory_name=$(get_directory_name "$child_directory")

    # Flags
    exists=""
    deleted=""
    could_not_delete_local_branch=""

    # Check if branch exists locally
    if git -C "$child_directory" show-ref --quiet --heads $branch_to_delete; then
        exists+="local"

        current_branch=$(git -C "$child_directory" branch --show-current)
        if [ "$current_branch" == "$branch_to_delete" ]; then
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
        delete_branch "$child_directory" "$child_directory_name" "$branch_to_delete" "true" "false"
        deleted+="local"
    fi

    # Check and delete remote branch if required
    if $delete_remote_branch && [ -z "$could_not_delete_local_branch" ]; then
        delete_branch "$child_directory" "$child_directory_name" "$branch_to_delete" "false" "true"
        deleted+="remote"
    fi

    # Handle case where branch doesn't exist
    if [ -z "$exists" ]; then
        print_failure_message "$child_directory_name" "Branch $branch_to_delete not found in this directory."
    fi
done

# Stop the spinner after processing
kill $!
endspin
