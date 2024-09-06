#!/bin/bash

script_location="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"

source $script_location/load-env.sh
source $script_location/target-directory.sh

# Function to check if a directory is a Git repository
is_git_repo() {
  git -C "$1" rev-parse --is-inside-work-tree >/dev/null 2>&1
  return $?
}

# Get terminal color codes
green=$(tput setaf 2)
reset=$(tput sgr0)

# Iterate over immediate child directories
for dir in in $(ls -d "$target_directory"/*/); do
  if [ -d "$dir" ]; then
    if is_git_repo "$dir"; then
      branch=$(git -C "$dir" branch --show-current)
      # base_directory=basename "${dir%/*}"
      # echo $base_directory
      base_directory="$(basename "${dir%/*}")"
      echo "$base_directory - ${green}$branch${reset}"
    fi
  fi
done