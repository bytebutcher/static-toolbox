#!/bin/sh

set -e

# Source versions
source "$(dirname "$0")/versions.env"

# Set variables
SCRIPT_PATH=$(dirname "$0")
PACKAGES_LIST="/tmp/packages.lst"
BUILD_DIRECTORY="/build"
OUTPUT_DIRECTORY="/output"
SOURCE_DIRECTORY="/src"
CROSS_COMPILE="x86_64-linux-musl"
CC="x86_64-linux-musl-gcc"
ARCH="x86_64"

# Export cross-compiler path
export PATH="/opt/x86_64-linux-musl-cross/bin:${PATH}"
export PATH="/opt/x86_64-linux-musl-cross/x86_64-linux-musl/bin:${PATH}"

# Setup directories
if [ "$1" = "get_source" ] ; then
    # Create local source directory
    if [ -f /src ] && [ -x /src ] ; then
        SOURCE_DIRECTORY="/src"
    else
        SOURCE_DIRECTORY="${SCRIPT_PATH}/src"
    fi
    mkdir -p "${SOURCE_DIRECTORY}"
else
    # Create build and output directories
    mkdir -p "${BUILD_DIRECTORY}" "${OUTPUT_DIRECTORY}"
fi

# Function to get source file
get_source_file() {
    local file_name="$1"
    local download_url="$2"
    local destination="$3"
    if [ -f "${SOURCE_DIRECTORY}/${file_name}" ]; then
        echo "[+] Using local file: ${file_name}"
    else                 
        echo "[+] Downloading ${file_name}..."
        curl --progress-bar "${download_url}" -o "${SOURCE_DIRECTORY}/${destination}"
    fi                                            
    cp "${SOURCE_DIRECTORY}/${file_name}" "${destination}"
}

# Install required packages
install_packages() {
    apk update && \
    xargs -a "${PACKAGES_LIST}" apk add && \
    apk info -v | sort > "${OUTPUT_DIRECTORY}/packages.lock"
}

# Install cross-compiler
install_cross_compiler() {
    cd /opt/
    get_source_file "${CROSS_COMPILE}-cross.tgz" \
                    "https://musl.cc/${CROSS_COMPILE}-cross.tgz" \
                    "${CROSS_COMPILE}-cross.tgz"
    tar -xf "${CROSS_COMPILE}-cross.tgz"
    rm "${CROSS_COMPILE}-cross.tgz"
}

# Build OpenSSL
build_openssl() {
    cd "${BUILD_DIRECTORY}"
    get_source_file "openssl-${OPENSSL_VERSION}.tar.gz" \
                    "https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz" \
                    "openssl-${OPENSSL_VERSION}.tar.gz"
    tar -xzf "openssl-${OPENSSL_VERSION}.tar.gz"
    cd "openssl-${OPENSSL_VERSION}"
    CC=${CC} ./Configure no-shared linux-x86_64
    make -j4
}

# Build zlib
build_zlib() {
    cd "${BUILD_DIRECTORY}"
    get_source_file "zlib-${ZLIB_VERSION}.tar.gz" \
                    "https://zlib.net/fossils/zlib-${ZLIB_VERSION}.tar.gz" \
                    "zlib-${ZLIB_VERSION}.tar.gz"
    tar -xzf "zlib-${ZLIB_VERSION}.tar.gz"
    cd "zlib-${ZLIB_VERSION}"
    CC=${CC} CFLAGS="-fPIC" ./configure --static
    make -j4
}

# Build libpcap
build_libpcap() {
    cd "${BUILD_DIRECTORY}"
    get_source_file "libpcap-${LIBPCAP_VERSION}.tar.gz" \
                    "https://www.tcpdump.org/release/libpcap-${LIBPCAP_VERSION}.tar.gz" \
                    "libpcap-${LIBPCAP_VERSION}.tar.gz"
    tar -xzf "libpcap-${LIBPCAP_VERSION}.tar.gz"
    cd "libpcap-${LIBPCAP_VERSION}"
    CC=${CC} CFLAGS="-fPIC" ./configure --disable-shared
    make -j4
}

# Build Nmap
build_nmap() {
    cd "${BUILD_DIRECTORY}"
    get_source_file "nmap-${NMAP_VERSION}.tar.bz2" \
                    "https://nmap.org/dist/nmap-${NMAP_VERSION}.tar.bz2" \
                    "nmap-${NMAP_VERSION}.tar.bz2"
    tar -xjf "nmap-${NMAP_VERSION}.tar.bz2"
    cd "nmap-${NMAP_VERSION}"
    
    # Configure with static flags
    CFLAGS="-static -fPIC" \
    CXXFLAGS="-static -static-libstdc++ -fPIC" \
    LDFLAGS="-static -L${BUILD_DIRECTORY}/openssl-${OPENSSL_VERSION} -L${BUILD_DIRECTORY}/libpcap-${LIBPCAP_VERSION} -L${BUILD_DIRECTORY}/zlib-${ZLIB_VERSION}" \
    CC=${CC} ./configure \
        --without-ndiff \
        --without-zenmap \
        --without-nmap-update \
        --without-libssh2 \
        --with-pcap=linux \
        --with-openssl="${BUILD_DIRECTORY}/openssl-${OPENSSL_VERSION}" \
        --with-libz="${BUILD_DIRECTORY}/zlib-${ZLIB_VERSION}"

    # Make sure we only build the static libraries (see https://github.com/ernw/static-toolbox/blob/master/build/targets/build_nmap.sh)
    sed -i '/build-zlib: $(ZLIBDIR)\/Makefile/!b;n;c\\t@echo Compiling zlib; cd $(ZLIBDIR) && $(MAKE) static;' "${BUILD_DIRECTORY}/nmap-${NMAP_VERSION}/Makefile.in"

    # Build
    make -j4

    # Check if files exist and copy to output directory
    for file in nmap ncat/ncat nping/nping; do
        if [ -f "${file}" ]; then
            echo "Stripping ${file}"
            strip "${file}"

            echo "Copying ${file} to ${OUTPUT_DIRECTORY}"
            cp "${file}" "${OUTPUT_DIRECTORY}/"
        else
            echo "Warning: ${file} not found"
        fi
    done
}

# Main execution function
main() {
    case "$1" in
        install_packages)
            install_packages
            echo "[+] Finished installing packages"
            ;;
        install_cross_compiler)
            install_cross_compiler
            echo "[+] Finished installing cross compiler for ${ARCH}"
            ;;
        build_openssl)
            build_openssl
            echo "[+] Finished building OPENSSL for ${OPENSSL_VERSION} for ${ARCH}"
            ;;
        build_zlib)
            build_zlib
            echo "[+] Finished building ZLIB ${ZLIB_VERSION} for ${ARCH}"
            ;;
        build_libpcap)
            build_libpcap
            echo "[+] Finished building LIBPCAP ${LIBPCAP_VERSION} for ${ARCH}"
            ;;
        build_nmap)
            build_nmap
            echo "[+] Finished building Nmap ${NMAP_VERSION} for ${ARCH}"
            ;;
        get_source)
            echo $#
            if [ "$#" -ne 4 ]; then
                echo "Usage: $0 get_source <file_name> <download_url> <destination>"
                exit 1
            fi
            get_source_file "$2" "$3" "$4"
            ;;
        all)
            install_packages
            install_cross_compiler
            build_openssl
            build_zlib
            build_libpcap
            build_nmap
            ;;
        *)
            echo "Usage: $0 {install_packages|install_cross_compiler|build_openssl|build_zlib|build_libpcap|build_nmap|get_source|all}"
            exit 1
            ;;
    esac
}

# Run main function with provided argument
main "$@"