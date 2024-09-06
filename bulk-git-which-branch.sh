#!/bin/bash

script_location="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"

source $script_location/load-env.sh

default_target_directory="${BULK_GIT_TARGET_DIR}"

read -p "Enter absolute path to directory (Default: ${default_target_directory:-"Not set"}): " target_directory
target_directory="${target_directory:-$default_target_directory}"
if ! [ -d $target_directory ]; then
    echo "$target_directory is not a valid directory"
    exit
fi

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