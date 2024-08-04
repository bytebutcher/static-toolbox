#!/bin/bash
# Set constants
SCRIPT="${BASH_SOURCE[0]}"
SCRIPT_NAME="buildctl"
SCRIPT_DIR="$( cd "$( dirname "${SCRIPT}" )" && pwd )"
PROJECT_ROOT="$(cd "$(dirname "$(readlink -f "${SCRIPT}")")/../.." && pwd)"
TOOLS_DIR="$PROJECT_ROOT/tools"

# Function to check for a given tools whether there is an update available
check_tool() {
    local tool_name="$1"
    local tool_dir="${TOOLS_DIR}/${tool_name}"
    local tool_version_info_script="${tool_dir}/version_info.sh"
    if [ -f "${tool_version_info_script}" ]; then
        current_version=$(readlink -f "${tool_dir}/latest" | xargs basename)
        latest_version=$($tool_version_info_script -l)
        if [ "${current_version}" != "${latest_version}" ]; then
            printf "%-20s %-15s %-15s %-20s\n" \
                   "${tool_name}" \
                   "${current_version}" \
                   "${latest_version}" \
                   "Update available"
        else
            printf "%-20s %-15s %-15s %-20s\n" \
                   "${tool_name}" \
                   "${current_version}" \
                   "${latest_version}" \
                   "Up to date"
        fi
    else
        printf "%-20s %-15s %-15s %-20s\n" \
               "${tool_name}" \
               "N/A" \
               "N/A" \
               "No version info script"
    fi
}

# Function to check for all or a set of given tools whether there is an update available
check_tools() {
    # Print table header
    printf "%-20s %-15s %-15s %-20s\n" "Tool" "Current Version" "Latest Version" "Status"
    printf "%-20s %-15s %-15s %-20s\n" "----" "---------------" "--------------" "------"
    local tools=("$@")
    [ $# -eq 0 ] && tools=("$TOOLS_DIR"/*)

    for tool in "${tools[@]}"; do
        check_tool "$(basename ${tool})"
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [ "$1" = "-h" ]; then
        echo "Usage: ${SCRIPT_NAME} check [tool...]"
        exit 1
    fi
    check_tools "$@"
fi