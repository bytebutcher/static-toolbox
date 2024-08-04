#!/bin/sh

set -e

# Set variables
SCRIPT_PATH=$(dirname "$0")
PACKAGES_LIST="/tmp/packages.lst"
BUILD_DIRECTORY="/build"
OUTPUT_DIRECTORY="/output"
SOURCE_DIRECTORY="/src"

# Function to get source file
get_source_file() {
    local file_name=$1
    local download_url=$2
    local destination=$3
    if [ -f "$SOURCE_DIRECTORY/$file_name" ]; then
        echo "[+] Using local file: $file_name"
    else                 
        echo "[+] Downloading $file_name..."
        curl --progress-bar "$download_url" -o "$SOURCE_DIRECTORY/$destination"
    fi                                            
    cp "$SOURCE_DIRECTORY/$file_name" "$destination"
}

# Setup directories
if [ "$1" = "get_source" ] ; then
    # Create local source directory
    if [ -f /src ] && [ -x /src ] ; then
        SOURCE_DIRECTORY="/src"
    else
        SOURCE_DIRECTORY="${SCRIPT_PATH}/src"
    fi
    mkdir -p $SOURCE_DIRECTORY
else
    # Create build and output directories
    mkdir -p $BUILD_DIRECTORY $OUTPUT_DIRECTORY
fi

# Build
build() {
    VERSION="$1"
    cd $BUILD_DIRECTORY
    get_source_file "tool-${BIND_VERSION}.tar.xz" \
                    "https://example.com/${VERSION}/bind-${VERSION}.tar.xz" \
                    "bind-${VERSION}.tar.xz"
    tar -xJf tool-${VERSION}.tar.xz
    cd tool-${VERSION}
    CFLAGS="-static" ./configure
    make
}

# Main execution function
main() {
    case "$1" in
        build)
            if [ "$#" -ne 2 ]; then
                echo "Usage: $0 build <name> <version>"
                exit 1
            fi
            NAME="$2"
            VERSION="$3"
            build "$NAME" "$VERSION"
            echo "[+] Finished building "$NAME" $VERSION for $ARCH"
            ;;
        get_source)
            if [ "$#" -ne 4 ]; then
                echo "Usage: $0 get_source <file_name> <download_url> <destination>"
                exit 1
            fi
            get_source_file "$2" "$3" "$4"
            ;;
        all)
            shift
            build "$@"
            ;;
        *)
            echo "Usage: $0 {build_dig|get_source|all}"
            exit 1
            ;;
    esac
}

# Run main function with provided argument
main "$@"
