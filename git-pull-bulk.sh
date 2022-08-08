#!/bin/bash

# This script runs "git pull" is each directoy residing in its parent directory (default) or in the given directory

read -p "Enter absolute path to directory (Current: $(pwd)): " target_directory
if [ "$target_directory" != "" ]; then
    if ! [ -d $target_directory ]; then
        echo "$target_directory is not a valid directory"
        exit
    fi
else
    target_directory=$(pwd)
fi

read -p "Enter branch name (Default: master): " branch_to_pull
if [ "$branch_to_pull" == "" ]; then
    branch_to_pull="main"
fi

read -p "Checkout to pulled branch (y/n) (Default: n): " checkout_to_pulled_branch
if [ "$checkout_to_pulled_branch" != "" ]; then
    checkout_to_pulled_branch="${checkout_to_pulled_branch,,}"
    if [ "$checkout_to_pulled_branch" != "n" ] && [ "$checkout_to_pulled_branch" != "y" ]; then
        echo "Invalid input"
        exit
    fi
else
    checkout_to_pulled_branch="n"
fi

echo "Target directory: $target_directory"
echo "Branch to pull: $branch_to_pull"
echo "Checkout to pulled branch: $checkout_to_pulled_branch"

for folder in $(ls -d $target_directory/*/); do # iterate over each directory
    pushd $folder &> /dev/null # change present working directory
    if [ -d .git ]; then # check if current folder is a git repo
        # echo $folder
        git ls-remote --exit-code --head origin $branch_to_pull &> /dev/null # check if remote branch exists and set exit code to status variable "$?"
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