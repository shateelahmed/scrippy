#!/bin/bash

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
    *)
        set -- "$@" "$arg"
        ;; # Pass through the original argument if no match
    esac
done

clear_proxy=false

# Use getopts for short options
while getopts "d:c" opt; do
    case $opt in
    d)
        target_directory="$OPTARG"
        ;;
    c)
        clear_proxy=true
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
    echo "$required_number_of_arguments arguments required. $provided_number_of_arguments provided"
    exit 1
fi

# Load libraries if needed
for lib_file in "$script_location"/lib/*.sh; do
    source "$lib_file"
done

branch_to_push="${arguments[0]}"

# Function to display status with symbols and colors
show_status() {
    local dir_name="$1"
    local output="$2"
    local status="$3"
    local symbol="$4"
    local color="$5"

    # Set the color based on the status
    if [ -z "$color" ]; then
        if [ "$status" == "Successfully pushed" ]; then
            color="${green}"
        else
            color="${red}"
        fi
    fi

    echo -e "${color} $symbol Directory: $dir_name${reset}"
    echo -e "     - changes:"

    # Add proper indentation for each line of output
    while IFS= read -r line; do
        echo -e "           $line"
    done <<< "$output"

    echo -e "     - status: ${color}${status}${reset}\n"
}

# Display initial details
echo -e "Target directory   : ${green}$target_directory${reset}"
echo -e "Branch to push     : ${green}$branch_to_push${reset}"
echo -e "Clear proxy        : ${green}$clear_proxy${reset} \n"

# Spinner for progress indication
while true; do
    spin
    sleep 0.1
done &

# Iterate over each subdirectory in the target directory
for child_directory in $(ls -d "$target_directory"/*/); do
    child_directory_name=$(basename "$child_directory")

    if [ ! -d "$child_directory/.git" ]; then
        show_status "$child_directory_name" "Not a Git repository" "Failed to push" "✘" "$red"
        continue
    fi

    # Check if we are on the correct branch, otherwise checkout to the desired branch
    current_branch=$(git -C "$child_directory" branch --show-current)
    if [ "$current_branch" != "$branch_to_push" ]; then
        git -C "$child_directory" checkout "$branch_to_push" &>/dev/null
        current_branch=$(git -C "$child_directory" branch --show-current)
    fi

    # Check if the branch exists locally
    if ! git -C "$child_directory" show-ref --quiet --heads "$branch_to_push"; then
        show_status "$child_directory_name" "Branch '$branch_to_push' does not exist locally" "Failed to push" "✘" "$red"
        continue
    fi

    # Run git push
    push_output=$(git -C "$child_directory" push -u origin "$branch_to_push" 2>&1)

    # Display results with status
    if [[ "$push_output" =~ "Everything up-to-date" ]]; then
        show_status "$child_directory_name" "$push_output" "Successfully pushed" "✔" "$green"
    else
        show_status "$child_directory_name" "$push_output" "Failed to push" "✘" "$red"
    fi
done

# Kill the spinner process
kill $!

# Ensure the spinner is stopped after the final push
endspin
