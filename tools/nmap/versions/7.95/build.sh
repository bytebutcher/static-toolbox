#!/bin/sh

set -ex

# Source versions
. "$(dirname "$0")/versions.env"

# Set variables
SCRIPT_PATH=$(dirname "$0")
BUILD_DIRECTORY="/build"
OUTPUT_DIRECTORY="/output"
SOURCE_DIRECTORY="/src"
ARCH="x86"

# Setup directories
mkdir -p $BUILD_DIRECTORY $OUTPUT_DIRECTORY $SOURCE_DIRECTORY

# List of binaries to copy to the output directory after a successful build
BINARIES=$(cat <<EOF
nmap-${NMAP_VERSION}/nmap
nmap-${NMAP_VERSION}/ncat/ncat
nmap-${NMAP_VERSION}/nping/nping
EOF
)

# Set custom variables
CROSS_COMPILE="x86_64-linux-musl"
CC="x86_64-linux-musl-gcc"

# Export cross-compiler path
export PATH="/build/x86_64-linux-musl-cross/bin:${PATH}"
export PATH="/build/x86_64-linux-musl-cross/x86_64-linux-musl/bin:${PATH}"

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

# Install cross-compiler
install_cross_compiler() {
    local file_name=$(download_file "https://musl.cc/${CROSS_COMPILE}-cross.tgz")
    tar -xf "${file_name}"
    rm "${file_name}"
    echo "[+] Finished installing cross compiler for ${ARCH}"
}

# Build OpenSSL
build_openssl() {
    local file_name=$(download_file "https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz")
    tar -xzf "${file_name}"
    (
        cd "openssl-${OPENSSL_VERSION}"
        CC=${CC} ./Configure no-shared linux-x86_64
        make -j4
    )
    echo "[+] Finished building OPENSSL for ${OPENSSL_VERSION} for ${ARCH}"
}

# Build zlib
build_zlib() {
    local file_name=$(download_file "https://zlib.net/fossils/zlib-${ZLIB_VERSION}.tar.gz")
    tar -xzf "${file_name}"
    (
        cd "zlib-${ZLIB_VERSION}"
        CC=${CC} CFLAGS="-fPIC" ./configure --static
        make -j4
    )
    echo "[+] Finished building ZLIB ${ZLIB_VERSION} for ${ARCH}"
}

# Build libpcap
build_libpcap() {
    local file_name=$(download_file "https://www.tcpdump.org/release/libpcap-${LIBPCAP_VERSION}.tar.gz")
    tar -xzf "${file_name}"
    (
        cd "libpcap-${LIBPCAP_VERSION}"
        CC=${CC} CFLAGS="-fPIC" ./configure --disable-shared
        make -j4
    )
    echo "[+] Finished building LIBPCAP ${LIBPCAP_VERSION} for ${ARCH}"
}

# Build Nmap
build_nmap() {
    local file_name=$(download_file "https://nmap.org/dist/nmap-${NMAP_VERSION}.tar.bz2")
    tar -xjf "${file_name}"
    (
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
    )
    echo "[+] Finished building Nmap ${NMAP_VERSION} for ${ARCH}"
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
    install_cross_compiler
    build_openssl
    build_zlib
    build_libpcap
    build_nmap
}

# Main execution function
main() {
    cd "${BUILD_DIRECTORY}"
    case "$1" in
        install_cross_compiler)
            install_cross_compiler
            ;;
        build_openssl)
            build_openssl
            ;;
        build_zlib)
            build_zlib
            ;;
        build_libpcap)
            build_libpcap
            ;;
        build_nmap)
            build_nmap
            ;;
        all)
            build_all
            ;;
        *)
            echo "Usage: $0 {install_packages|install_cross_compiler|build_openssl|build_zlib|build_libpcap|build_nmap|all}"
            exit 1
            ;;
    esac
    copy_binaries
}

# Run main function with provided argument
main "$@"