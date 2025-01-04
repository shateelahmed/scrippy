#!/bin/bash

# Function to install on Linux and MacOS
install_unix() {
    echo "Detected Unix-based OS. Installing..."

    # Ensure git is installed
    if ! command -v git &> /dev/null; then
        echo "Git is required. Please install Git first."
        exit 1
    fi

    # Define install directory in the user's home directory
    install_dir="$HOME/.scrippy"

    # Create the directory if it doesn't exist
    mkdir -p "$install_dir"

    # Copy scripts to the install directory
    rsync -av --exclude '.git/' --exclude '.gitignore' . "$install_dir" # copy all files to the install directory
    chmod +x "$install_dir"/commands/scrippy*.sh # Make the scrippy prefixed scripts executable

    # for file in scrippy*.sh; do mv "$file" "scrippy${file#bulk-git}"; done
    for file in "$install_dir"/commands/scrippy*.sh; do
        mv "$file" "${file%.sh}"
    done

    # Add the install directory to PATH if it's not already there
    default_shell="$(basename $SHELL)"
    shell_config="$HOME/.${default_shell}rc"  # Modify based on the user's shell (e.g., .zshrc for zsh)
    if ! grep -q "$install_dir" "$shell_config"; then
        echo "export PATH=\"\$PATH:$install_dir/commands\"" >> "$shell_config"
        echo "Added $install_dir to PATH in $shell_config. Please restart your terminal or source the file to use the scripts."
    else
        echo "$install_dir is already in PATH."
    fi

    echo "Installation complete. You can run the scripts globally after restarting your terminal or running 'source $shell_config'."
}

# Function to install on Windows
install_windows() {
    # echo "Detected Windows OS. Installing..."
    echo "Detected Windows OS. No supported at the moment"
    exit

    # Check if PowerShell is available
    if ! command -v powershell.exe &> /dev/null; then
        echo "PowerShell is required but not found. Please install PowerShell."
        exit 1
    fi

    # Invoke the PowerShell script for installation on Windows
    powershell.exe -ExecutionPolicy Bypass -File ./install.ps1
}

# Detect OS
case "$OSTYPE" in
    linux* | darwin*)
        install_unix
        ;;
    msys* | cygwin* | win32)
        install_windows
        ;;
    *)
        echo "Unsupported OS: $OSTYPE"
        exit 1
        ;;
esac
