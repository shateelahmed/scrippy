target_directory="${BULK_GIT_TARGET_DIR}"
if [ -z "$target_directory" ]; then
    echo "BULK_GIT_TARGET_DIR (Target directory) is not set in the .env file"
    read -p "Enter absolute path to directory: " target_directory
    if ! [ -d $target_directory ]; then
        echo "$target_directory is not a valid directory"
        exit
    fi
fi
