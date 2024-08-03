#!/usr/bin/env bash

set -e

# Determine the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Navigate to the root directory of the project
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Directory containing the built binaries
BUILD_OUTPUT_DIR="$PROJECT_ROOT/build_output"

# Function to increment version
increment_version() {
    local version=$1
    local major minor patch

    # Remove 'v' prefix if present
    version="${version#v}"

    IFS='.' read -r major minor patch <<< "$version"
    
    # Increment patch version
    patch=$((patch + 1))
    
    echo "v$major.$minor.$patch"
}

# Ensure we have a GitHub token
if [ -z "${GITHUB_TOKEN:-}" ]; then
    echo "Error: GITHUB_TOKEN is not set"
    exit 1
fi



echo "Fetching latest tags..."
git fetch --tags --force

echo "Listing all tags:"
git tag -l

LATEST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0")
echo "Latest tag: $LATEST_TAG"

# Generate new tag
NEW_TAG=$(increment_version "$LATEST_TAG")

# Check if the new tag already exists, and keep incrementing if it does
while git rev-parse "$NEW_TAG" >/dev/null 2>&1; do
    echo "Tag $NEW_TAG already exists, incrementing..."
    NEW_TAG=$(increment_version "$NEW_TAG")
done

echo "Creating new tag: $NEW_TAG"

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
