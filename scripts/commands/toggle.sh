#!/bin/bash
# Set constants
SCRIPT="${BASH_SOURCE[0]}"
SCRIPT_NAME="buildctl"
SCRIPT_DIR="$( cd "$( dirname "${SCRIPT}" )" && pwd )"
PROJECT_ROOT="$(cd "$(dirname "$(readlink -f "${SCRIPT}")")/../.." && pwd)"
TOOLS_DIR="$PROJECT_ROOT/tools"
BUILD_OUTPUT_DIR="$PROJECT_ROOT/build_output"

# Function to disable a tool (create .buildignore)
disable_tool() {
    local tool="$1"
    if [ -d "${TOOLS_DIR}/${tool}" ]; then
        touch "${TOOLS_DIR}/${tool}/.buildignore"
        echo "Disabled ${tool}"
    else
        echo "Error: Tool ${tool} not found"
    fi
}

# Function to enable a tool (remove .buildignore)
enable_tool() {
    local tool="$1"
    if [ -d "${TOOLS_DIR}/${tool}" ]; then
        rm -f "${TOOLS_DIR}/${tool}/.buildignore"
        echo "Enabled ${tool}"
    else
        echo "Error: Tool ${tool} not found"
    fi
}

# Function to toggle a tool's status
toggle_tool() {
    local tool="$1"
    if [ -d "${TOOLS_DIR}/${tool}" ]; then
        if [ -f "${TOOLS_DIR}/${tool}/.buildignore" ]; then
            enable_tool "${tool}"
        else
            disable_tool "${tool}"
        fi
    else
        echo "Error: Tool ${tool} not found"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [ -z "$1" ] || [ "$1" = "-h" ]; then
        echo "Usage: ${SCRIPT_NAME} toggle <tool>"
        exit 1
    fi
    toggle_tool "$1"
fi