# Determine whether a directory should be skipped.
#
# Reads the SKIP_DIRS .env variable, a comma and/or whitespace separated list of
# directory names to exclude from every command.
#
# Args:
#   $1 (string): Directory path.
#
# Returns:
#   0 if the directory should be skipped, 1 otherwise.
is_skipped_directory() {
    directory_path="$1"
    [ -z "$SKIP_DIRS" ] && return 1

    directory_name="$(basename "${directory_path%/*}")"

    for skip_entry in ${SKIP_DIRS//,/ }; do # normalize commas to spaces, then iterate
        if [ "$directory_name" == "$skip_entry" ]; then
            return 0
        fi
    done

    return 1
}
