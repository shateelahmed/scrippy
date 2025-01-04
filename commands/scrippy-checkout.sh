#!/bin/bash

# This script checks out to a specific local branch in all directories

script_location="$(realpath "$(dirname "${BASH_SOURCE[0]}")/..")"

# Convert long options to short ones
for arg in "$@"; do
    shift
    case "$arg" in
    "--directory")
        set -- "$@" "-d" # Convert --directory to -d
        ;;
    *)
        set -- "$@" "$arg"
        ;; # Pass through the original argument if no match
    esac
done

# Use getopts for short options
while getopts "d:" opt; do
    case $opt in
    d)
        target_directory="$OPTARG"
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

for lib_file in "$script_location"/lib/*.sh; do
    source "$lib_file"
done

branch_to_checkout="${arguments[0]}"

echo "Target directory: ${green}$target_directory${reset}"
echo "Branch to checkout: ${green}$branch_to_checkout${reset}"

while true; do
    spin
    sleep 0.1
done &

# Iterate through directories
for child_directory in $(ls -d $target_directory/*/); do # iterate over each directory
    child_directory_name=$(basename "$child_directory")
    checkout_output=$(git -C "$child_directory" checkout "$branch_to_checkout" 2>&1)

    echo -e "\n"
    if [ -n "$checkout_output" ]; then
        # Determine the icon based on checkout success or failure
        if echo "$checkout_output" | grep -q "error"; then
            icon="✘"
        else
            icon="✔"
        fi

        echo -e "$icon  Directory: ${green}$child_directory_name${reset}"
        echo "    - changes:"
        echo "$checkout_output" | sed 's/^/          &/'  # Correct indentation for changes
    else
        echo -e "${red}✘  Directory: $child_directory_name${reset}"
        echo "    - changes: No changes"
    fi

    current_branch=$(git -C "$child_directory" branch --show-current)
    if [ "$current_branch" != "$branch_to_checkout" ]; then  # if the current git branch is not "$branch_to_checkout"
        echo "    - Branch: ${red}Failed to checkout${reset}"
        echo "    - Status: ${red}Checkout failed${reset}"
    else
        echo "    - Branch: ${green}$current_branch${reset}"
        echo "    - Status: ${green}Checked out successfully${reset}"
    fi

    echo -e "\n"

done

# Kill the spinner once git fetch completes
kill $!
# Ensure the spinner is stopped after the final fetch
endspin
