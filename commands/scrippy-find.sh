#!/bin/bash

# Find a branch in remote and local repository

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
        # echo "Flag -d or --directory was triggered, Parameter: $OPTARG"
        target_directory="$OPTARG"
        ;;
    c)
        clear_proxy=true
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

for lib_file in "$script_location"/lib/*.sh; do
    source "$lib_file"
done

branch_to_find="${arguments[0]}"

echo -e "Target directory           : ${green}$target_directory${reset}"
echo -e "Branch to find             : ${green}$branch_to_find${reset}"
echo -e "Clear proxy                : ${green}$clear_proxy${reset}"

# Initialize dynamic arrays for the table
directories=()
local_status=()
remote_status=()


function strip_color {
    echo -e "$1" | sed -r 's/\x1B\[[0-9;]*m//g'
}

spin &
SPINNER_PID=$!



# Collect data for directories, local status, and remote status
for child_directory in $(ls -d $target_directory/*/); do
    if [ ! -d "$child_directory/.git" ]; then
        continue
    fi

    # Check if the branch exists locally
    if git -C "$child_directory" show-ref --quiet --heads $branch_to_find; then
        # exists+="${green}  ✔ ${reset}"
        local_status+=("${green}  ✔  ${reset}")
    else
        # exists+="${red}  ✘ ${reset}"
        local_status+=("${red}  ✘  ${reset}")
    fi

    # Check if the branch exists remotely
    git -C "$child_directory" ls-remote --exit-code --heads origin $branch_to_find &> /dev/null
    if [ "$?" == "0" ]; then
        remote_status+=("${green}  ✔   ${reset}")
    else
        remote_status+=("${red}  ✘   ${reset}")
    fi

    child_directory_name=$(get_directory_name "$child_directory")
    directories+=("$child_directory_name")
done

# Define table headers
header1="Directory"
header2="Local"
header3="Remote"

endspin

col1_width=$((${#header1} > $(printf "%s\n" "${directories[@]}" | wc -L) ? ${#header1} : $(printf "%s\n" "${directories[@]}" | wc -L)))
col2_width=$((${#header2} > $(printf "%s\n" "$(printf "%s\n" "${local_status[@]}" | while read line; do strip_color "$line"; done)" | wc -L) ? ${#header2} : $(printf "%s\n" "${local_status[@]}" | while read line; do strip_color "$line"; done | wc -L)))
col3_width=$((${#header3} > $(printf "%s\n" "$(printf "%s\n" "${remote_status[@]}" | while read line; do strip_color "$line"; done)" | wc -L) ? ${#header3} : $(printf "%s\n" "${remote_status[@]}" | while read line; do strip_color "$line"; done | wc -L)))


# Define table borders dynamically
border_top="+$(printf -- '-%.0s' $(seq $((col1_width + 2))))+$(printf -- '-%.0s' $(seq $((col2_width))))+$(printf -- '-%.0s' $(seq $((col3_width))))+"
echo -e "\n"

# Print the table header with borders
printf "%s\n" "$border_top"
printf "| %-*s | %-*s | %-*s |\n" "$col1_width" "$header1" "" "$header2" "" "$header3"
printf "%s\n" "$border_top"

# Print the rows dynamically
for i in "${!directories[@]}"; do
    dir_name="${directories[$i]}"
    local_check="${local_status[$i]}"
    remote_check="${remote_status[$i]}"
    printf "| %-*s | %-*s | %-*s |\n" "$col1_width" "$dir_name" "$col2_width" "$local_check" "$col3_width" "$remote_check"
done

# Print the bottom border
printf "%s\n" "$border_top"
