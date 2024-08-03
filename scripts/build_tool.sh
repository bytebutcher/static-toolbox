#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

if [ $# -eq 0 ]; then
    echo "Error: No tool name provided"
    echo "Usage: $0 <tool_name>"
    exit 1
fi

TOOL_NAME="$1"
OUTPUT_DIR="$2"
TOOL_DIR="$PROJECT_ROOT/tools/$TOOL_NAME"
LATEST_VERSION_DIR="$(readlink -f "$TOOL_DIR/latest")"
VERSION="$(basename "$LATEST_VERSION_DIR")"

if [ ! -d "$TOOL_DIR" ]; then
    echo "Error: Tool directory not found: $TOOL_DIR"
    exit 1
fi

if [ ! -L "$TOOL_DIR/latest" ] || [ ! -d "$LATEST_VERSION_DIR" ]; then
    echo "Error: Invalid or missing 'latest' symlink for $TOOL_NAME"
    exit 1
fi

if [ ! -d "$OUTPUT_DIR" ] ; then
    echo "Error: Output directory not found: $OUTPUT_DIR"
    exit 1

fi

echo "Building $TOOL_NAME version $VERSION"

cd "$LATEST_VERSION_DIR" || exit 1

docker build -t "$TOOL_NAME:$VERSION" .

CONTAINER_ID=$(docker create "$TOOL_NAME:$VERSION")
docker cp "$CONTAINER_ID:/output/$TOOL_NAME" "$OUTPUT_DIR/${TOOL_NAME}_${VERSION}"
#docker cp "$CONTAINER_ID:/output/packages.lock" "$TOOL_DIR/versions/$VERSION/packages.lock"
docker rm "$CONTAINER_ID"

echo "Successfully built $TOOL_NAME version $VERSION"
echo "Binary located at: $OUTPUT_DIR/${TOOL_NAME}_${VERSION}"
