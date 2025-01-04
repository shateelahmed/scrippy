#!/bin/bash
script_location="$(realpath "$(dirname "${BASH_SOURCE[0]}")/..")"
for lib_file in "$script_location"/lib/*.sh; do
    source "$lib_file"
done
# Function to display command list
show_commands() {
    echo -e "Available Commands and Descriptions:\n"
    echo -e "${green}1. scrippy-checkout${reset}        Checkout to a specific branch"
    echo -e "${green}2. scrippy-create-branch${reset}   Create a new branch in the repository"
    echo -e "${green}3. scrippy-delete${reset}          Delete a branch"
    echo -e "${green}4. scrippy-fetch${reset}           Fetch changes from the remote repository"
    echo -e "${green}5. scrippy-find${reset}            Find a branch in the repository"
    echo -e "${green}6. scrippy-list${reset}            List all branches in the repository"
    echo -e "${green}7. scrippy-merge${reset}           Merge changes from one branch to another"
    echo -e "${green}8. scrippy-pull${reset}            Pull changes from the remote repository"
    echo -e "${green}9. scrippy-push${reset}            Push changes to the remote repository"
    echo -e "${green}10. scrippy-which${reset}          Check which branch you're currently on"
}

# Run the show_commands function to display the list
show_commands
