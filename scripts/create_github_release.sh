#!/usr/bin/env bash

set -e

# Determine the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Navigate to the root directory of the project
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Directory containing the built binaries
BUILD_OUTPUT_DIR="$PROJECT_ROOT/build_output"

# Ensure we have a GitHub token
if [ -z "${GITHUB_TOKEN:-}" ]; then
    echo "Error: GITHUB_TOKEN is not set"
    exit 1
fi

# Fetch tags
git fetch --tags

# Get the latest tag
LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")

# Increment the patch version
IFS='.' read -ra VERSION_PARTS <<< "${LATEST_TAG#v}"
MAJOR="${VERSION_PARTS[0]}"
MINOR="${VERSION_PARTS[1]}"
PATCH=$((VERSION_PARTS[2] + 1))
NEW_TAG="v$MAJOR.$MINOR.$PATCH"

# Create a new tag
git config user.name "GitHub Actions"
git config user.email "actions@github.com"
git tag -a "$NEW_TAG" -m "Release $NEW_TAG"
git push origin "$NEW_TAG"

# Create GitHub release
release_notes="Automated release $NEW_TAG"
response=$(curl -X POST \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/$GITHUB_REPOSITORY/releases" \
    -d "{
        \"tag_name\": \"$NEW_TAG\",
        \"name\": \"Release $NEW_TAG\",
        \"body\": \"$release_notes\",
        \"draft\": false,
        \"prerelease\": false
    }")

# Extract the upload URL from the response
upload_url=$(echo "$response" | jq -r .upload_url | sed -e "s/{?name,label}//")

# Upload each binary to the release
for binary in "$BUILD_OUTPUT_DIR"/*; do
    filename=$(basename "$binary")
    curl -X POST \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Content-Type: application/octet-stream" \
        --data-binary "@$binary" \
        "${upload_url}?name=${filename}"
done

echo "GitHub release $NEW_TAG created and binaries uploaded successfully."
