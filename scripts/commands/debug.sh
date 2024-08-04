#!/bin/bash
# Set constants
SCRIPT="${BASH_SOURCE[0]}"
SCRIPT_NAME="buildctl"
SCRIPT_DIR="$( cd "$( dirname "${SCRIPT}" )" && pwd )"
PROJECT_ROOT="$(cd "$(dirname "$(readlink -f "${SCRIPT}")")/../.." && pwd)"
TOOLS_DIR="$PROJECT_ROOT/tools"

# Set default arguments
ARG_VERBOSE=false

# Function to show a file and its output
show_file() {
    local relative_file="$1"
    local file="$path/$relative_file"
    if ! [ -f "$file" ] ; then
        echo "Error: File $relative_file not found"
        return 1
    fi
    echo "File: $relative_file";
    if [ "$ARG_VERBOSE" = true ] ; then
        echo "----------------------------------------------------------------------"
        cat "$file";
        echo "----------------------------------------------------------------------"
    fi
}

# Function to list and show directory content
show_directory_content() {
    local path="$1"
    find "$path" -type f \( \
        -not -path "*/src/*" -and \
        -not -path "*/.git/*" -and \
        -not -path "*/build_output/*" \
    \) -print0 | while IFS= read -r -d '' file; do
        local relative_file=$(echo "$file" | sed -e "s|$path/||")
        show_file "$relative_file"
    done
}

# Function to debug project
debug() {
    local tool="$1"
    if [ -n "$tool" ] ; then
        if [ -d "$TOOLS_DIR/$tool" ] ; then
            show_directory_content "$TOOLS_DIR/$tool"
        else
            echo "Error: Tool $tool not found"
        fi
    else
        show_directory_content "$PROJECT_ROOT"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [ "$1" = "-h" ]; then
        echo "Usage: ${SCRIPT_NAME} debug [verbose]"
        exit 1
    fi
    if [ -n "$1" ] ; then
      ARG_VERBOSE=true
    fi
    debug
fi