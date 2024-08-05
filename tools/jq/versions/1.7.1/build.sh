#!/bin/sh

set -e

# Source versions
. "$(dirname "$0")/versions.env"

# Set constants
SCRIPT_PATH=$(dirname "$0")
BUILD_DIRECTORY="/build"
OUTPUT_DIRECTORY="/output"
SOURCE_DIRECTORY="/src"
ARCH="x86"

# Setup directories
mkdir -p $BUILD_DIRECTORY $OUTPUT_DIRECTORY $SOURCE_DIRECTORY

# List of binaries to copy to the output directory after a successful build
BINARIES=$(cat <<EOF
jq-${JQ_VERSION}/jq
EOF
)

# Set custom variables
CROSS_COMPILE=""
CC=""

# Function to download file
download_file() {
    local download_url="$1"
    local file_name=$(basename "${download_url}")
    if [ -f "${SOURCE_DIRECTORY}/${file_name}" ]; then
        echo "[+] Using local file: ${file_name}" >&2
    else
        echo "[+] Downloading ${download_url} to ${SOURCE_DIRECTORY}/${file_name}..." >&2
        curl --progress-bar -L "${download_url}" -o "${SOURCE_DIRECTORY}/${file_name}"
    fi
    cp -v "${SOURCE_DIRECTORY}/${file_name}" "${file_name}" >&2
    echo "$(pwd)/${file_name}"
}

# Function to copy binaries to the output directory
copy_binaries() {
    for binary in $BINARIES; do
        if [ -f "${binary}" ]; then
            echo "Stripping ${binary}"
            strip "${binary}"
            echo "Copying ${binary} to ${OUTPUT_DIRECTORY}"
            cp "${binary}" "${OUTPUT_DIRECTORY}/"
        else
            echo "Warning: ${binary} not found"
        fi
    done
}

# Build
build_all() {
    local file_name=$(download_file "https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/jq-${JQ_VERSION}.tar.gz")
    tar xzf "${file_name}"
    (
        cd "jq-${JQ_VERSION}"
        autoreconf -fi
        ./configure --disable-shared --enable-static --disable-maintainer-mode
        make LDFLAGS=-all-static
    )
    echo "[+] Finished building jq ${JQ_VERSION} for ${ARCH}"
}

# Main execution function
main() {
    cd $BUILD_DIRECTORY
    case "$1" in
        all)
            build_all
            ;;
        *)
            echo "Usage: $0 <all>"
            exit 1
            ;;
    esac
    copy_binaries
}

# Run main function with provided argument
main "$@"
