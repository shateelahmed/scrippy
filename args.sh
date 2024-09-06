short_flags=()
long_flags=()
arguments=()

for flag in "$@"; do
    # echo "arg value: $flag"
    if [[ $flag == -[^-]* ]]; then
        # Remove the leading hyphen
        hyphenless_flag="${flag#-}"

        # Loop through each character of the cleaned flag
        for (( i=0; i<${#hyphenless_flag}; i++ )); do
            # Get the character
            char="${hyphenless_flag:$i:1}"

            # Prepend a hyphen and add to the flags array
            short_flags+=("-$char")
        done
    elif [[ $flag == --* ]]; then
        long_flags+=("$flag")
    elif [[ $flag != -* ]]; then
        arguments+=("$flag")
    fi
done

