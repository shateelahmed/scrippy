target_directory="${target_directory:-$BULK_GIT_TARGET_DIR}"
if [ -z "$target_directory" ]; then
    echo "Target directory is not set. Please provide the absolute path to the target directory using -d or --directory flag or set it in the BULK_GIT_TARGET_DIR variable of the .env file"
    exit
fi
if ! [ -d $target_directory ]; then
    echo "$target_directory is not a valid directory"
    exit
fi
