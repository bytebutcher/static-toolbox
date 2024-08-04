#!/bin/bash

# Function to check if a release already exists
release_exists() {
    local tool_name="$1"
    local version="$2"
    local tag="${tool_name}-${version}"
    local response=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
        "https://api.github.com/repos/${GITHUB_REPOSITORY}/releases/tags/${tag}")

    echo "Checking for release: ${tag}"
    if [[ $(echo "${response}" | jq -r '.message') != "Not Found" ]]; then
        return 0  # Release exists
    else
        return 1  # Release does not exist
    fi
}