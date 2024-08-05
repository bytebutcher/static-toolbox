#!/bin/bash
VERSION_INFO_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${VERSION_INFO_SCRIPT_DIR}/../../scripts/helper/version_utils.sh"

get_latest_openssl_version() {
    get_latest_version_from_github "openssl" "openssl" "openssl-"
}

get_latest_libpcap_version() {
    get_latest_version_from_url "https://www.tcpdump.org/release/" 'libpcap-[0-9.]+\.tar\.gz' 's/.*-([0-9.]+[a-z]?)\.tar\..*/\1/'
}

get_latest_zlib_version() {
    get_latest_version_from_url "https://zlib.net/" 'zlib-[0-9.]+\.tar\.gz' 's/.*-([0-9.]+[a-z]?)\.tar\..*/\1/'
}

get_latest_version() {
    get_latest_version_from_url "https://nmap.org/dist/" 'nmap-[0-9.]+\.tar\.bz2' 's/.*-([0-9.]+[a-z]?)\.tar\..*/\1/'
}

get_latest_versions() {
    echo "NMAP_VERSION=$(get_latest_version)"
    echo "OPENSSL_VERSION=$(get_latest_openssl_version)"
    echo "LIBPCAP_VERSION=$(get_latest_libpcap_version)"
    echo "ZLIB_VERSION=$(get_latest_zlib_version)"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    parse_arguments "$@"
fi
