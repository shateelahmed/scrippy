
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
    - `TARGET_DIR`: Set absolute path to the directory where you want to run scrippy in by default.
    - `DEFAULT_BRANCH`: Set default branch (eg. `master`, `main`) for your repository.
- Make the `install.sh` file executable (`chmod +x <filename>.sh`).
- Run `./install.sh` to install the scripts

## Usage
- Run `scrippy list <source_branch> <destination_branch> <project_folder1, project_folder2>` to check available command of scrippy
- Run `scrippy create-branch ` to check create new branch ( project folder is optional )
- Run `scrippy checkout <branch_name>` to checkout to a specific branch
- Run `scrippy delete <branch_name>` to delete a branch locally. Add `-r` before the `<branch_name>` to delete the branch from remote.
- Run `scrippy fetch` to do a fetch.
- Run `scrippy find <branch_name>` to find a branch in local and remote.
- Run `scrippy merge <source_branch> <destination_branch>` to merge a branch into another.
- Run `scrippy pull <branch_name>` to pull a branch. The pull will always happen in the same branch.
- Run `scrippy push <branch_name>` to push a branch. The push will always happen in the same branch.
- Run `scrippy which` to list the branches that are currently checked out


## Example output

**scrippy list :**

<b>Description</b>:
Lists all the available commands that Scrippy provides, along with a brief description of what each command does. It's a handy way to explore the functionalities of Scrippy and understand its capabilities.

<b>Output Example Explanation:</b>
Displays a formatted list of commands and their descriptions, like scrippy-checkout for checking out to a specific branch or scrippy-pull for pulling updates from a remote branch.

    Available Commands and Descriptions:

       1. scrippy-checkout        Checkout to a specific branch
       2. scrippy-create-branch   Create a new branch in the repository
       3. scrippy-delete          Delete a branch
       4. scrippy-fetch           Fetch changes from the remote repository
       5. scrippy-find            Find a branch in the repository
       6. scrippy-list            List all branches in the repository
       7. scrippy-merge           Merge changes from one branch to another
       8. scrippy-pull            Pull changes from the remote repository
	   9. scrippy-push            Push changes to the remote repository
	   10. scrippy-which          Check which branch you're currently on

<br>**scrippy which :**
<br><b>Description:</b>
Displays the current branch that each directory (microservice) is checked out to. This is particularly useful for keeping track of the branch status across multiple repositories.

<b>Output Example Explanation:</b>
A table is shown with directories and the branches currently checked out in each directory. This helps you quickly understand the state of your microservices.

    +---------------------+----------------------------------------+
    | Directory           | Current Branch                         |
    +---------------------+----------------------------------------+
    | Target directory    | /home/users/Documents/application/dev  |
    | microservice1       | master                                 |
    | microservice2       | develop                                |
    +---------------------+----------------------------------------+```

<br>**scrippy find <branch_name> :**
<br><b>Description:</b>
Searches for a specific branch across all microservices. It indicates whether the branch exists locally, remotely, or not at all.

<b>Output Example Explanation:</b>
The command highlights whether the specified branch (develop in this case) exists locally and/or remotely for each microservice directory.

    Target directory           : /home/users/Documents/application/dev
    Branch to find             : develop
    Clear proxy                : false

    +---------------------+-------+--------+
    | Directory           | Local | Remote |
    +---------------------+-------+--------+
    | microservice2       |   ✔   |   ✘    |
    +---------------------+-------+--------+

<br><b>scrippy checkout <branch_name> :</b>
<br><b>Description:</b>
Switches the current branch to the specified branch (<branch_name>) in all microservices. If the branch is not found, it provides feedback for each directory.

<b>Output Example Explanation:</b>
The command successfully checks out to the master branch in each microservice, indicating any changes or updates made during the process.

    ✔  Directory: microservice1
        - changes:
              Already on 'master'
              Your branch is up to date with 'origin/master'.
        - Branch: master
        - Status: Checked out successfully

    ✔  Directory: microservice2
        - changes:
              Switched to branch 'master'
              Your branch is up to date with 'origin/master'.
        - Branch: master
        - Status: Checked out successfully



<br>**scrippy create-branch <source_branch> <target_branch> <microservice_name> :**
<br><b>Description:</b>
Creates a new branch (<target_branch>) from an existing branch (<source_branch>) in the specified microservice(s). If no microservice is specified, it applies to all.
<microservice_name> name is optional, if you not mentioned that it will be work for all directories

<b>Output Example Explanation:</b>
A new branch release-1.0.1 is created from develop in microservice1. The output confirms the successful branch creation and switch.

    Target directory   : /home/users/Documents/application/dev
    Source branch      : develop
    Target branch      : release-1.0.1
    Clear proxy        : false

    ✔ Directory: microservice1
         - changes:
               Created and checked out to 'release-1.0.1'
               Switched to a new branch 'release-1.0.1'
         - status: Branch created and switched


<br>**scrippy delete <branch_name>:**
<br><b>Description:</b>
Deletes the specified branch (<branch_name>) from the local repository. Add the -r flag to delete the branch from the remote repository as well.

<b>Output Example Explanation:</b>
The branch release-1.0.1 is successfully deleted locally in microservice1, while the branch is not found in microservice2, resulting in partial success.

    Target directory           : /home/users/Documents/application/dev
    Branch to delete           : test
    Clear proxy                : false
    Delete remote branch       : false

    ✔ Directory: microservice1
        - Changes:
            The branch 'release-1.0.1' was deleted locally.
        - Status: Local branch deleted successfully

    ✘ Directory: microservice2
        - Changes:
            Branch release-1.0.1 not found in this directory.
        - Status: Branch delete failed

<br>**scrippy fetch:**
<br><b>Description:</b>
Fetches the latest changes from the remote repositories for all microservices. It doesn’t merge or rebase; it only updates the remote tracking branches.

<b>Output Example Explanation:</b>
The command fetches updates for each microservice directory, indicating any new branches or changes fetched. If no changes are fetched, it notes that as well.

    Target directory: /home/users/Documents/application/dev
    ✔ Directory: microservice1
        - Changes:
            From https://github.com/zzz/microservice1
             * [new branch]      newbranch    -> origin/newbranch
        - Status: fetching done

    ✔ Directory: microservice2
        - Changes:
            * No new changes were fetched.
        - Status: fetching done


<br>**scrippy merge <source_branch> <target_branch>:**
<br><b>Description:</b>
Merges changes from the source_branch into the target_branch in all microservices. If a branch doesn't exist or the merge fails, it provides detailed feedback.

<b>Output Example Explanation:</b>
The command successfully merges release-4.1.0 into master for microservice1. However, the source branch does not exist in microservice2, causing the merge to fail there.

    Target directory   : /home/users/Documents/application/dev
    Source branch      : release-4.1.0
    Target branch      : master
    Clear proxy        : false

    ✔ Directory: microservice1
         - changes:
               Already up to date.
         - status: Merge successful


     ✘ Directory: microservice2
         - changes:
               Source branch 'release-4.1.0' does not exist
         - status: Failed to merge


<br>**scrippy pull <branch_name>:**
<br><b>Description:</b>
Pulls updates for the specified branch (<branch_name>) from the remote repository in all microservices. It fails if there are uncommitted changes or other conflicts.

<b>Output Example Explanation:</b>
The command successfully pulls updates for the master branch in microservice2. However, microservice1 has unstaged changes, causing the pull to fail.
        Target directory    : /home/users/Documents/application/dev
        Branch to pull      : master
        Clear proxy         : false

        ✘ Directory: microservice1
             - changes:
                   error: cannot pull with rebase: You have unstaged changes.
        error: Please commit or stash them.
             - status: Failed to pull master


        ✔ Directory: microservice2
             - changes:
                   Already up to date.
             - status: Successfully pulled master
