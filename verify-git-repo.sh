# Check if a directory is a Git repository.
#
# Args:
#   $1 (string): Directory path to check.
#
# Returns:
#   0 if the directory is a Git repository, 1 otherwise.
is_git_repo() {
    # $1 is the first argument passed to the function
    directory="$1"

    if [ ! -d "$directory/.git" ]; then
        # condition 1: current directory is not a git repo

        return 1
    fi

    return 0;
}
