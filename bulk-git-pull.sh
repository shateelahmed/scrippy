#!/bin/bash

# This script runs "git pull" is each directoy residing in its parent directory (default) or in the given directory

script_location="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"

source $script_location/load-env.sh
source $script_location/target-directory.sh

default_branch_to_pull="${BULK_GIT_DEFAULT_BRANCH:-master}"
default_checkout_to_pulled_branch="${BULK_GIT_CHECKOUT_TO_PULLED_BRANCH:-n}"
default_clear_proxy="${BULK_GIT_CLEAR_PROXY:-n}"

read -p "Branch to pull (Default: $default_branch_to_pull): " branch_to_pull
branch_to_pull="${branch_to_pull:-$default_branch_to_pull}"

read -p "Checkout to pulled branch (y/n) (Default: $default_checkout_to_pulled_branch): " checkout_to_pulled_branch
checkout_to_pulled_branch="${checkout_to_pulled_branch:-$default_checkout_to_pulled_branch}"
if [ "$checkout_to_pulled_branch" != "n" ] && [ "$checkout_to_pulled_branch" != "y" ]; then
    echo "Invalid input"
    exit
fi

read -p "Clear proxy (y/n) (Default: $default_clear_proxy): " clear_proxy
clear_proxy="${clear_proxy:-$default_clear_proxy}"
if [ "$clear_proxy" != "n" ] && [ "$clear_proxy" != "y" ]; then
    echo "Invalid input"
    exit
fi

echo "Target directory: $target_directory"
echo "Branch to pull: $branch_to_pull"
echo "Checkout to pulled branch: $checkout_to_pulled_branch"
echo "Clear proxy: $clear_proxy"

if [ "$clear_proxy" == "y" ]; then
    unset HTTPS_PROXY https_proxy HTTP_PROXY http_proxy NO_PROXY no_proxy
    echo "Cleared proxy"
fi

for folder in $(ls -d $target_directory/*/); do # iterate over each directory
    pushd $folder &> /dev/null # change present working directory
    if [ -d .git ]; then # check if current folder is a git repo
        # echo $folder
        git ls-remote --exit-code --heads origin $branch_to_pull &> /dev/null # check if remote branch exists and set exit code to status variable "$?"
        exit_code="$?"
        if [ "$exit_code" == "0" ]; then # 0 = exists, 2 = does not exist
            echo "Working directory in $folder" # display folder name

            current_branch=$(git branch --show-current)
            if [ "$current_branch" != "$branch_to_pull" ]; then  # if the current git branch is not "$branch_to_pull"
                git checkout $branch_to_pull
                current_branch=$(git branch --show-current)
            fi
            if [ "$current_branch" != "$branch_to_pull" ]; then  # if the current git branch is not "$branch_to_pull"
                echo "Could not checkout to $branch_to_pull. skipping..."
                continue # continue to next folder as could not checkout to "$branch_to_pull"
            fi

            git fetch --all --prune
            git pull

            # if the current git branch is not "$branch_to_pull" and checkout to "$branch_to_pull" is not selected
            if [ "$current_branch" != "$branch_to_pull" ] && [ "$checkout_to_pulled_branch" != "y" ]; then
                git checkout $current_branch &> /dev/null # checkout back to "$current_branch"
            fi
        fi
    fi

    popd &> /dev/null
done