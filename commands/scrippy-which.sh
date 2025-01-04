#!/bin/bash

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

for lib_file in "$script_location"/lib/*.sh; do
    source "$lib_file"
done

# Define table headers
header1="Directory"
header2="Current Branch"

# Initialize arrays for dynamic width calculation
directories=()
branches=()


while true; do
    spin
    sleep 0.1
done &

# Add Target Directory as the first row
directories+=("Target directory")
branches+=("$target_directory")

# Collect data for directories and branches
for child_directory in $(ls -d "$target_directory"/*/); do
    if ! is_git_repo "$child_directory"; then
        continue
    fi
    directories+=("$(get_directory_name "$child_directory")")
    branches+=("$(git -C "$child_directory" branch --show-current)")
done

# Determine dynamic column widths
col1_width=$((${#header1} > $(printf "%s\n" "${directories[@]}" | wc -L) ? ${#header1} : $(printf "%s\n" "${directories[@]}" | wc -L)))
col2_width=$((${#header2} > $(printf "%s\n" "${branches[@]}" | wc -L) ? ${#header2} : $(printf "%s\n" "${branches[@]}" | wc -L)))

# Define table borders dynamically
border_top="+$(printf -- '-%.0s' $(seq $((col1_width + 2))))+$(printf -- '-%.0s' $(seq $((col2_width + 2))))+"
echo -e "\n"

# Print the table header with borders
printf "%s\n" "$border_top"
printf "| %-*s | %-*s |\n" "$col1_width" "$header1" "$col2_width" "$header2"
printf "%s\n" "$border_top"

# Print the rows dynamically with color for the target directory
for i in "${!directories[@]}"; do
    dir_name="${directories[$i]}"
    branch_name="${branches[$i]}"
    if [ "$i" -eq 0 ]; then
        printf "| ${yellow}%-*s${reset} | ${green}%-*s${reset} |\n" "$col1_width" "$dir_name" "$col2_width" "$branch_name"
    else
        printf "| %-*s | ${green}%-*s${reset} |\n" "$col1_width" "$dir_name" "$col2_width" "$branch_name"
    fi
done

# Print the bottom border
printf "%s\n" "$border_top"

# Kill the spinner once git fetch completes
kill $!
# Ensure the spinner is stopped after the final fetch
endspin
