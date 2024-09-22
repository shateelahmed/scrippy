# Get the name of a directory from its path.
#
# Args:
#   $1 (string): Directory path.
#
# Returns:
#   Directory name.
get_directory_name() {
    # $1 is the first argument passed to the function
    directory_path="$1"
    echo "$(basename "${directory_path%/*}")"
}
