#!/bin/bash
VERSION_INFO_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${VERSION_INFO_SCRIPT_DIR}/../../scripts/helper/version_utils.sh"

get_latest_version() {
    get_latest_version_from_gitlab "procps-ng" "procps" "v"
}

get_latest_versions() {
    echo "PROCPS_VERSION=$(get_latest_version)"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    parse_arguments "$@"
fi
