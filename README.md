# Scrippy

Scrippy helps you run a specific command in all the first level directories within a directory. This is specially helpful when you are working on a project with multiple Microservice.

## Use case
Checkout the following scenario. You have a project `amazing` that contains 10 microservices and currently you are working on features `awesome` and `cool`. `awesome` resides in 3 microservices and `cool` is in 5. The features also have 2 microservices in common. You need to constantly switch between these features for development. This is where Scrippy comes in handy. Scippy can find, checkout to, pull or delete a specific git branch in multiple first level directories.

## Features
- Find a specific Git branch
- Checkout to a specific Git branch
- Pull a specific Git branch
- Delete a specific Git branch
- List all currently checked out branches

## Installation
- Clone the repository.
- Copy the `.env.example` file to same directory as `.env`.
- Update the envs to your need in the `.env` file.
- Make the `install.sh` file executable (`chmod +x <filename>.sh`).
- Run `./install.sh` to install the scripts

## Usage
- Run `scrippy checkout <branch_name>` to checkout to a specific branch
- Run `scrippy delete <branch_name>` to delete a branch locally. Add `-r` before the `<branch_name>` to delete the branch from remote.
- Run `scrippy fetch` to do a fetch.
- Run `scrippy find <branch_name>` to find a branch in local and remote.
- Run `scrippy merge <source_branch> <destination_branch>` to merge a branch into another.
- Run `scrippy pull <branch_name>` to pull a branch. The pull will always happen in the same branch.
- Run `scrippy push <branch_name>` to push a branch. The push will always happen in the same branch.
- Run `scrippy which` to list the branches that are currently checked out
