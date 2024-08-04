#!/bin/bash
# Set constants
SCRIPT="${BASH_SOURCE[0]}"
SCRIPT_NAME="buildctl"
SCRIPT_DIR="$( cd "$( dirname "${SCRIPT}" )" && pwd )"
PROJECT_ROOT="$(cd "$(dirname "$(readlink -f "${SCRIPT}")")/../.." && pwd)"
TOOLS_DIR="$PROJECT_ROOT/tools"

# Function to add a new tool with a specific version
new_tool() {
    local tool="$1"
    local version="$2"
    local tool_dir="$TOOLS_DIR/$tool"
    local version_dir="$tool_dir/versions/$version"

    # Check if the version already exists
    if [ -d "$version_dir" ]; then
        echo "Error: Tool $tool in version $version already exists"
        return 1
    fi

    # Create the version directory
    if ! mkdir -p "$version_dir"; then
        echo "Error: Failed to create version directory: $version_dir"
        return 1
    fi

    # Check/update latest version
    (
        cd "$tool_dir" || exit 1
        if [ -L "latest" ]; then
            local current_latest=$(readlink latest)
            echo "Updating 'latest' from $current_latest to $version"
            rm latest
        elif [ -f "latest" ] ; then
            echo "Error: 'latest' exists in $tool_dir but is not a symlink. Please check and remove manually."
            exit 1
        fi
        # Create symlink
        ln -sf "versions/$version" latest
    ) || return 1

    # Create template
    mkdir "$version_dir/src/"
    touch "$version_dir/src/.gitkeep"
    touch "$version_dir/Dockerfile"
    touch "$version_dir/build.sh"
    chmod +x "$version_dir/build.sh"

    echo "Created tool $tool with version $version"
    echo "Dockerfile: $version_dir/Dockerfile"
    echo "build.sh:   $version_dir/build.sh"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -lt 2 ]] || [[ "$1" = "-h" ]]; then
        echo "Usage: ${SCRIPT_NAME} new <tool> <version>" >&2
        exit 1
    fi
    new_tool "$1" "$2"
fi