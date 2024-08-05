#!/bin/bash
# Include constants
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "${SCRIPT_DIR}/../helper/command_env.sh"
source "${SCRIPT_DIR}/../helper/release_utils.sh"

# Function to release a single tool
release_tool() {
    local tool_name="$1"
    local version="$2"
    local tool_dir="${BUILD_OUTPUT_DIR}/${tool_name}/${version}"

    # Check if the binary does exists
    if [ -z "$(ls -A "${tool_dir}")" ]; then
        echo "Error: Binary not found for ${tool_name} version ${version}"
        return 1
    fi

    local tag="${tool_name}-${version}"

    # Check if the release already exists
    if release_exists "${tool_name}" "${version}"; then
        echo "Release ${tag} already exists. Skipping."
        return 0
    fi

    # Create a new tag (if it does not already exist)
    if ! git rev-parse "${tag}" >/dev/null 2>&1; then
        echo "Creating tag ${tag}"
        git config user.name "GitHub Actions"
        git config user.email "actions@github.com"
        git tag -a "${tag}" -m "Release ${tag}"
        git push origin "${tag}"
    fi

    # Create GitHub release
    echo "Creating release for ${tag}"
    local release_notes="Automated release of ${tool_name} version ${version}"
    local response=$(curl -X POST \
        -H "Authorization: token ${GITHUB_TOKEN}" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/${GITHUB_REPOSITORY}/releases" \
        -d "{
            \"tag_name\": \"${tag}\",
            \"name\": \"${tool_name} ${version}\",
            \"body\": \"${release_notes}\",
            \"draft\": false,
            \"prerelease\": false
        }")


    # Extract the upload URL from the response
    local upload_url=$(echo "${response}" | jq -r .upload_url | sed -e "s/{?name,label}//")

    # Upload all binaries in the tool directory
    for binary in "${tool_dir}"/*; do
        if [ -f "${binary}" ]; then
            local binary_name=$(basename "${binary}")
            echo "Uploading ${binary_name}..."
            curl -X POST \
                -H "Authorization: token ${GITHUB_TOKEN}" \
                -H "Content-Type: application/octet-stream" \
                --data-binary "@${binary}" \
                "${upload_url}?name=${binary_name}"
        fi
    done

    echo "GitHub release ${tag} created and all binaries uploaded successfully."
}

# Function to release all tools or a set of given tools
release_tools() {
    local tools=("$@")
    local tool_dirs=("$BUILD_OUTPUT_DIR"/*)
    [ $# -eq 0 ] && tools=("${BUILD_OUTPUT_DIR}"/*)

    # Check whether we do have something to release
    if [ ${#tool_dirs[@]} -eq 0 ] || [ ! -d "${tool_dirs[0]}" ]; then
        echo "Skipping release: No tools to release"
        return 0
    fi

    # Ensure we have a GitHub token
    if [ -z "${GITHUB_TOKEN:-}" ]; then
        echo "Error: GITHUB_TOKEN is not set"
        exit 1
    fi

    # Ensure we have all tags
    echo "Fetching latest tags..."
    git fetch --tags --force

    echo "Releasing tools..."
    for tool_dir in "${tools[@]}"; do
        local tool_name=$(basename "${tool_dir}")
        version_dirs=("$tool_dir"/*)
        if [ ${#version_dirs[@]} -eq 0 ] || [ ! -d "${version_dirs[0]}" ]; then
            echo "Skipping release: No versions to release for $tool_name"
            continue
        fi
        for version_dir in "${tool_dir}"/*; do
            local version=$(basename "${version_dir}")
            release_tool "${tool_name}" "${version}"
        done
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [ "$1" = "-h" ]; then
        echo "Usage: ${SCRIPT_NAME} release [tool...]"
        exit 1
    fi
    release_tools "$@"
fi