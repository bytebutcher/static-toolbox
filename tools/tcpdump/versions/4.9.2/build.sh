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
tcpdump-${TCPDUMP_VERSION}/tcpdump
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
    local tool_name="tcpdump"
    local tool_version="${TCPDUMP_VERSION}" # from versions.env
    local file_name=$(download_file "https://www.tcpdump.org/release/tcpdump-${TCPDUMP_VERSION}.tar.gz")
    tar -xvf ${file_name}
    (
        cd tcpdump-${TCPDUMP_VERSION}
        CFLAGS="-static" LDFLAGS="-static" ./configure --without-crypto
        make LDFLAGS="-static"
    )
    echo "[+] Finished building "${tool_name}" ${tool_version} for ${ARCH}"
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
