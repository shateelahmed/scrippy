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


# Function to display status with symbols and colors
show_status() {
    local dir_name="$1"
    local output="$2"
    local status="$3"
    local symbol="$4"
    local color="$5"

    echo -e "${color} $symbol Directory: $dir_name${reset}"
    echo -e "     - changes:"

    # Add proper indentation for each line of output
    while IFS= read -r line; do
        echo -e "           $line"
    done <<< "$output"

    echo -e "     - status: ${status}\n\n"
}


# Handle positional arguments (remaining after flags)
arguments=("$@")
required_number_of_arguments=2
provided_number_of_arguments=${#arguments[@]}
if [ "$provided_number_of_arguments" != "$required_number_of_arguments" ]; then
    echo "$required_number_of_arguments arguments required. $provided_number_of_arguments provided"
    exit
fi

# Load libraries if needed
for lib_file in "$script_location"/lib/*.sh; do
    source "$lib_file"
done

source_branch="${arguments[0]}"
target_branch="${arguments[1]}"

echo -e "Target directory   : ${green}$target_directory${reset}"
echo -e "Source branch      : ${green}$source_branch${reset}"
echo -e "Target branch      : ${green}$target_branch${reset}"
echo -e "Clear proxy        : ${green}$clear_proxy${reset}\n"

# Spinner for progress indication
while true; do
    spin
    sleep 0.1
done &

# Iterate over each subdirectory in the target directory
for child_directory in $(ls -d "$target_directory"/*/); do
    child_directory_name=$(basename "$child_directory")

    # Check if it's a Git repository
    if [ ! -d "$child_directory/.git" ]; then
        show_status "$child_directory_name" "Not a Git repository" "${red}Failed to merge" "✘" "$red"
        continue
    fi

    # Check if the source and target branches exist
    if ! git -C "$child_directory" show-ref --quiet --heads "$source_branch"; then
        show_status "$child_directory_name" "Source branch '$source_branch' does not exist" "${red}Failed to merge" "✘" "$red"
        continue
    fi
    if ! git -C "$child_directory" show-ref --quiet --heads "$target_branch"; then
        show_status "$child_directory_name" "Target branch '$target_branch' does not exist" "${red}Failed to merge" "✘" "$red"
        continue
    fi

    # Checkout the target branch
    current_branch=$(git -C "$child_directory" branch --show-current)
    if [ "$current_branch" != "$target_branch" ]; then
        git -C "$child_directory" checkout "$target_branch"
        current_branch=$(git -C "$child_directory" branch --show-current)
    fi
    if [ "$current_branch" != "$target_branch" ]; then
        show_status "$child_directory_name" "Could not checkout to $target_branch" "${red}Failed to merge" "✘" "$red"
        continue
    fi

    # Perform git merge
    merge_output=$(git -C "$child_directory" merge "$source_branch" 2>&1)

    # Show results with status
    if [[ "$merge_output" =~ "Already up to date" ]]; then
        show_status "$child_directory_name" "$merge_output" "${green}Merge successful" "✔" "$green"
    else
        show_status "$child_directory_name" "$merge_output" "${red}Merge failed" "✘" "$red"
    fi
done

# Kill the spinner process
kill $!

# Ensure the spinner is stopped after the final merge
endspin
