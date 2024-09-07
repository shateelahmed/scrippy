#!/bin/bash

script_location="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"

source $script_location/load-env.sh
source $script_location/target-directory.sh
source $script_location/verify-git-repo.sh

# Get terminal color codes
green=$(tput setaf 2)
reset=$(tput sgr0)

# Iterate over immediate child directories
for child_directory in in $(ls -d "$target_directory"/*/); do
    if is_git_repo "$child_directory"; then
        # child_directory_name will contain only the name of the child directory; not the full path
        child_directory_name="$(basename "${child_directory%/*}")"
        current_branch=$(git -C "$child_directory" branch --show-current)
        echo "$child_directory_name - ${green}$current_branch${reset}"
    fi
done