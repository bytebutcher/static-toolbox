#!/bin/bash
# Include constants
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIR}/../helper/command_env.sh"

# Set default arguments
ARG_VERBOSE=false


# Function to list all tools and their build ignore status
list_tools() {
    local format="%-20s %-10s %s\n"
    printf "${format}" "TOOL NAME" "VERSION" "STATUS"
    printf "${format}" "---------" "------" "-------"
    for tool in "${TOOLS_DIR}"/*; do
        if [ -d "${tool}" ]; then
            local tool_name="$(basename "${tool}")"
            local tool_status=$([[ -f "${tool}/.buildignore" ]] && echo "IGNORED" || echo "ACTIVE")
            local tool_version=$(readlink -f "${tool}/latest" 2>/dev/null | xargs -r basename || echo "N/A")
            printf "${format}" "${tool_name}" "${tool_version}" "${tool_status}"
            if [ "$ARG_VERBOSE" = true ]; then
                while read tool_version; do
                    printf "${format}" "${tool_name}" "${tool_version}" "${tool_status}"
                done < <(list_tool_versions "${tool_name}" true)
            fi
        fi
    done
}

list_tool() {
    local tool="$1"
    local format="%s\n"
    printf "${format}" "VERSION"
    printf "${format}" "-------"
    list_tool_versions "${tool}" false
}

# New function to list all versions of a tool
list_tool_versions() {
    local tool="$1"
    local ignore_latest="$2"

    if [ ! -d "${TOOLS_DIR}/${tool}/versions" ]; then
        echo "No versions found"
        return
    fi

    for version in "${TOOLS_DIR}/${tool}/versions"/*; do
        if [ -d "${version}" ]; then
            local version_name="$(basename "${version}")"
            if [ "$(readlink -f "${TOOLS_DIR}/${tool}/latest")" = "${version}" ]; then
                if [ "${ignore_latest}" = false ] ; then
                    echo "${version_name} (latest)"
                fi
            else
                echo "${version_name}"
            fi
        fi
    done
}

# Ensure this script is sourced, not executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    ARG_VERBOSE="$2"
    if [ "$1" = "-h" ]; then
        echo "Usage: ${SCRIPT_NAME} list" >&2
        exit 1
    fi

    if [ -n "$1" ] ; then
        list_tool "$1"
    else
        list_tools
    fi
fi