#!/bin/bash
# Set constants
SCRIPT="${BASH_SOURCE[0]}"
SCRIPT_NAME="buildctl"
SCRIPT_DIR="$( cd "$( dirname "${SCRIPT}" )" && pwd )"
PROJECT_ROOT="$(cd "$(dirname "$(readlink -f "${SCRIPT}")")/../.." && pwd)"
TOOLS_DIR="$PROJECT_ROOT/tools"
BUILD_OUTPUT_DIR="$PROJECT_ROOT/build_output"

# Set constants
IGNORE_FILE=".buildignore"

# Build progress
declare -A BUILD_RESULTS
declare -A TOOL_VERSIONS
TOTAL_TOOLS=0
SUCCESSFUL_BUILDS=0
FAILED_BUILDS=0
SKIPPED_BUILDS=0

# Function to check if a tool should be ignored
should_ignore_tool() {
    local tool_name="$1"
    [[ -f "$PROJECT_ROOT/tools/$tool_name/$IGNORE_FILE" ]]
}

# Function to build a tool
build_tool() {
    local tool_name="$1"
    local output_dir="$2"
    local tool_dir="$TOOLS_DIR/$tool_name"
    local tool_latest_dir="$tool_dir/latest"
    local build_parameters=""

    # Initialise Tool Version
    TOOL_VERSIONS["${tool_name}"]="N/A"

    if [[ ! -d "${tool_dir}" ]]; then
        echo "Error: Tool directory not found: ${tool_dir}" >&2
        return 1
    fi

    if [[ ! -d "${output_dir}" ]]; then
        mkdir -p "${output_dir}" || {
            echo "Error: Could not create output directory: ${output_dir}" >&2
            return 1
        }
    fi

    if should_ignore_tool "${tool_name}"; then
        echo "Skipping ${tool_name}: Ignored in .buildignore"
        BUILD_RESULTS["${tool_name}"]="SKIPPED"
        ((SKIPPED_BUILDS++))
        return 0
    fi

    if [[ ! -L "${tool_latest_dir}" ]] || [[ ! -d "${tool_latest_dir}" ]]; then
        echo "Skipping ${tool_name}: No 'latest' symlink found" >&2
        return 1
    fi

    local tool_latest_version
    tool_latest_version="$(basename "$(readlink -f "${tool_latest_dir}")")"
    TOOL_VERSIONS["${tool_name}"]="${tool_latest_version}"
    (
        echo "Building ${tool_name} version ${tool_latest_version}"
        cd "${tool_latest_dir}" || return 1

        docker build --progress plain --no-cache -t "${tool_name}:${tool_latest_version}" . || {
            echo "Error: Docker build failed for ${tool_name}" >&2
            return 1
        }

        local container_id=$(docker create "${tool_name}:${tool_latest_version}")

        # Creating output directory
        local tool_output_dir="${output_dir}/${tool_name}/${tool_latest_version}"
        mkdir -p "${tool_output_dir}"

        # Copy all files from the container's /output directory to the host
        if ! docker cp "${container_id}:/output/." "${tool_output_dir}/" ; then
            echo "Error: Failed to copy files from container" >&2
            docker rm "${container_id}"
            return 1
        fi

        docker rm "${container_id}"

        echo "Successfully built ${tool_name} version ${tool_latest_version}"
        echo "Binary located at: ${tool_output_dir}/${tool_name}"
    )

    # Check return from subshell
    if [ $? -eq 0 ] ; then
        BUILD_RESULTS["${tool_name}"]="SUCCESS"
        ((SUCCESSFUL_BUILDS++))
        return 0
    else
        return 1
    fi

}

# Function to build all or a set of given tools
build_tools() {
    local tools=("$@")
    local output_dir="$BUILD_OUTPUT_DIR"
    [ $# -eq 0 ] && tools=("$TOOLS_DIR"/*)
    for tool in "${tools[@]}"; do
        local tool_name="$(basename "${tool}")"
        if ! build_tool "${tool_name}" "${output_dir}" ; then
            echo "Failed to build ${tool_name}" >&2
            BUILD_RESULTS["${tool_name}"]="FAILED"
            ((FAILED_BUILDS++))
        fi
    done
}

# Add a new function to display the summary
display_build_summary() {
    echo
    echo "Build Summary:"
    echo "----------------------------------------"
    printf "%-20s %-10s %s\n" "Tool" "Version" "Status"
    echo "----------------------------------------"
    for tool in "${!BUILD_RESULTS[@]}"; do
        printf "%-20s %-10s %s\n" "${tool}" "${TOOL_VERSIONS[${tool}]}" "${BUILD_RESULTS[${tool}]}"
    done
    echo "----------------------------------------"
    printf "%-20s %-10s %s\n" "Total tools:"       "" "${TOTAL_TOOLS}"
    printf "%-20s %-10s %s\n" "Successful builds:" "" "${SUCCESSFUL_BUILDS}"
    printf "%-20s %-10s %s\n" "Failed builds:"     "" "${FAILED_BUILDS}"
    printf "%-20s %-10s %s\n" "Skipped builds:"    "" "${SKIPPED_BUILDS}"
    echo "----------------------------------------"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [ "$1" = "-h" ]; then
        echo "Usage: ${SCRIPT_NAME} build [tool...]" >&2
        exit 1
    fi
    build_tools "$@"
    display_build_summary
fi
