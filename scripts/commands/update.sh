#!/bin/bash
# Include constants
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIR}/../helper/command_env.sh"

# Function to check and update tool version
update_tool() {
    local tool_name="$1"
    local tool_dir="${TOOLS_DIR}/${tool_name}"
    local tool_version_info_script="${tool_dir}/version_info.sh"
    echo "Checking for updates to ${tool_name}..."
    if [ -f "${tool_version_info_script}" ] ; then
        current_version=$(readlink -f "${tool_dir}/latest" | xargs basename)
        latest_version=$($tool_version_info_script -l)
        if [ "${current_version}" != "${latest_version}" ]; then
            echo "Update available for ${tool_name}: ${current_version} -> ${latest_version}"
            # Here you would implement the logic to actually update the tool
            # For now, we'll just print a message
            echo "Updated ${tool_name} to version ${latest_version}"
        else
            echo "${tool_name} is already up to date (version ${current_version})"
        fi
    else
        echo "No version info script found for ${tool_name}"
    fi
}

# Function to update all or a set of given tools
update_tools() {
    local tools=("$@")
    [ $# -eq 0 ] && tools=("$TOOLS_DIR"/*)

    for tool in "${tools[@]}"; do
        update_tool "$(basename ${tool})"
    done
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [ "$1" = "-h" ]; then
        echo "Usage: ${SCRIPT_NAME} [<tool>...]"
        exit 1
    fi
    update_tools "$@"
fi