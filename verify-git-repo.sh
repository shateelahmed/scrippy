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
    # The -C option in the git command allows you to specify a different directory in which Git commands will be executed.
    # >/dev/null: Redirects standard output (stdout) to /dev/null (essentially discarding it).
    # 2>&1: Redirects stderr to stdout, which is already being discarded by /dev/null.
    git -C "$directory" rev-parse --is-inside-work-tree >/dev/null 2>&1
    # $? returns the exit status of the last executed command, which is 0 if the directory is a Git repository and non-zero otherwise.
    return $?
}
