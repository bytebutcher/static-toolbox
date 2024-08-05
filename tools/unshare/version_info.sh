#!/bin/bash
VERSION_INFO_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${VERSION_INFO_SCRIPT_DIR}/../../scripts/helper/version_utils.sh"

get_latest_version() {
    get_latest_version_from_url "https://mirrors.edge.kernel.org/pub/linux/utils/util-linux/" "v[0-9.]+(?=/)" "s/^v//"
}

get_latest_versions() {
    echo "UNSHARE_VERSION=$(get_latest_version)"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    parse_arguments "$@"
fi
