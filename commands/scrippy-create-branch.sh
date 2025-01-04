#!/bin/bash

# Function to display status
show_status() {
    directory="$1"
    message="$2"
    status_message="$3"
    status_symbol="$4"
    output="$5"

    # Extract only the directory name (not the full path)
    dir_name=$(basename "$directory")

    # Set default color for directory (green)
    directory_color="${green}"

    # If the status symbol is ✘, set the directory color to red
    if [ "$status_symbol" == "✘" ]; then
        directory_color="${red}"
    fi

    # Show the directory name with appropriate status and color
    echo -e "${directory_color}$status_symbol Directory: $dir_name${reset}"
    echo -e "     - changes:"
    echo -e "           $message"

    # Loop over the output to ensure each line is indented
    while IFS= read -r line; do
        echo -e "           $line"
    done <<< "$output"

    echo -e "     - status: $status_message \n\n"
}

# Get the script's location and set up for library imports
script_location="$(realpath "$(dirname "${BASH_SOURCE[0]}")/..")"

# Convert long options to short ones (for backward compatibility if needed)
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

# Argument validation: Ensure the required arguments are provided
arguments=("$@")
required_number_of_arguments=2
provided_number_of_arguments=${#arguments[@]}
if [ "$provided_number_of_arguments" -lt "$required_number_of_arguments" ]; then
    echo "$required_number_of_arguments arguments required. $provided_number_of_arguments provided"
    exit 1
fi

# Load libraries if needed (if you want to use some common functions or helpers)
for lib_file in "$script_location"/lib/*.sh; do
    source "$lib_file"
done

# Receive the arguments
source_branch="$1"
target_branch="$2"

# Display received arguments
echo -e "Target directory   : ${green}$target_directory${reset}"
echo -e "Source branch      : ${green}$source_branch${reset}"
echo -e "Target branch      : ${green}$target_branch${reset}"
echo -e "Clear proxy        : ${green}$clear_proxy${reset}\n"


# Spinner for progress indication
while true; do
    spin
    sleep 0.1
done &

# Iterate over the provided directories
for child_directory in $(ls -d "$target_directory"/*/); do
    # Check if the directory exists
    if [ ! -d "$child_directory" ]; then
        show_status "$child_directory" "Directory does not exist" "${red}Failed to create branch" "✘"
        continue
    fi

    # Check if it is a Git repository
    if [ ! -d "$child_directory/.git" ]; then
        show_status "$child_directory" "Not a Git repository" "${red}Failed to create branch" "✘"
        continue
    fi

    # Check if the source branch exists
    if ! git -C "$child_directory" show-ref --quiet --heads "$source_branch"; then
        show_status "$child_directory" "Branch '$source_branch' does not exist locally" "${red}Failed to create branch" "✘"
        continue
    fi

    # Create and checkout the new target branch if it's not already present
    if ! git -C "$child_directory" show-ref --quiet --heads "$target_branch"; then
        output=$(git -C "$child_directory" checkout -b "$target_branch" 2>&1)
        show_status "$child_directory" "Created and checked out to '$target_branch'" "${green}Branch created and switched" "✔" "$output"
    else
        # If branch already exists, check it out
        output=$(git -C "$child_directory" checkout "$target_branch" 2>&1)
        show_status "$child_directory" "Checked out to '$target_branch'" "${green}Branch switched" "✔" "$output"
    fi
done

# Kill the spinner process
kill $!

# Ensure the spinner is stopped after the final push
endspin
