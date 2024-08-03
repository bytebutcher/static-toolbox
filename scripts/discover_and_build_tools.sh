#!/usr/bin/env bash

set -e

# Determine the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Navigate to the root directory of the project
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Determine whether build should be ignored locally
IGNORE_FILE=".buildignore"

# Create output directory
OUTPUT_DIR="$PROJECT_ROOT/build_output"
mkdir -p "$OUTPUT_DIR"

# Function to check if a tool should be ignored
should_ignore_tool() {
    local tool_name="$1"
    if [ -f "$PROJECT_ROOT/tools/$tool_name/$IGNORE_FILE" ] ; then
        return 0
    fi
    return 1
}

# Function to build a tool
build_tool() {
    local tool_name="$1"
    local tool_dir="$PROJECT_ROOT/tools/$tool_name"

    if should_ignore_tool "$tool_name"; then
        echo "Skipping $tool_name: Ignored in .buildignore"
        return
    fi
    
    if [ -L "$tool_dir/latest" ] && [ -e "$tool_dir/latest" ]; then
        echo "Building $tool_name"
        "$SCRIPT_DIR/build_tool.sh" "$tool_name" "$OUTPUT_DIR"
    else
        echo "Skipping $tool_name: No 'latest' symlink found"
    fi
}

# Discover and build tools
cd "$PROJECT_ROOT/tools" || exit 1

for tool_dir in */; do
    tool_name="${tool_dir%/}"
    build_tool "$tool_name"
done

echo "All tools have been processed"
