#!/bin/bash
command="$1"
shift

# Try to execute the command with the "scrippy-" prefix
"scrippy-$command" "$@"
