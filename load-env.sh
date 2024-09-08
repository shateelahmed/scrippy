env_file_location="$script_location/.env"
if [ -f "$env_file_location" ]; then # set ENV varaibles from .env file if it exists
    set -o allexport
    source $env_file_location
    set +o allexport
fi
