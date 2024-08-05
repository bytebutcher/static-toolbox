#!/bin/bash

get_latest_version_from_github() {
    local owner="$1"
    local repo="$2"
    local version_prefix="${3:-}"
    local auth_header=""
    if [ -n "$GITHUB_TOKEN" ]; then
        auth_header="-H 'Authorization: token $GITHUB_TOKEN'"
    fi
    local version=$(curl --silent $auth_header "https://api.github.com/repos/$owner/$repo/releases/latest" |
                    grep '"tag_name":' | 
                    sed -E 's/.*"([^"]+)".*/\1/' | 
                    sed "s/^$version_prefix//")
    echo "$version"
}

get_latest_version_from_gitlab() {
    local owner="$1"
    local repo="$2"
    local project_id="${owner}%2f${repo}"
    local version_prefix="${3:-}"
    local auth_header=""
    if [ -n "$GITLAB_TOKEN" ]; then
        auth_header="--header 'PRIVATE-TOKEN: $GITLAB_TOKEN'"
    fi
    local version=$(curl --silent $auth_header "https://gitlab.com/api/v4/projects/$project_id/releases" |
                    jq -r '.[0].tag_name' |
                    sed "s/^$version_prefix//")
    echo "$version"
}

get_latest_version_from_url() {
    local url="$1"
    local pattern="$2"
    local sed_command="$3"

    curl --silent "$url" | 
    grep -oP "$pattern" | 
    sort -V | 
    tail -n 1 | 
    sed -E "$sed_command"
}


show_usage() {
    echo "Usage: $0 [option]"
    echo "Options:"
    echo "  -l, --latest      Get latest version"
    echo "  -a, --all         Get all latest versions"
    echo "  -h, --help        Show this help message"
}

parse_arguments() {
    case "$1" in
        -l|--latest)
            get_latest_version
            ;;
        -a|--all)
            get_latest_versions
            ;;
        -h|--help)
            show_usage
            ;;
        "")
            # Default behavior when no arguments are provided
            get_latest_versions
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
}