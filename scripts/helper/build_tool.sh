#!/usr/bin/env bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

show_usage() {
    echo "Error: No tool name provided"
    echo "Usage: $0 <tool_name>"
    exit 1
}

TOOL_NAME=""
VERBOSE=false
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -v|--verbose) VERBOSE=true ;;
        -h|--help) show_usage ;;
        -*)
            echo "Error: Invalid parameter $1"
            exit 1
            ;;
        *)
            if [ -z "$TOOL_NAME" ] ; then
                TOOL_NAME="$1"
            elif [ -z "$OUTPUT_DIR" ] ; then
                OUTPUT_DIR="$1"    
            else
                echo "Error: Invalid parameter $1"
                exit 1
            fi
            ;;
    esac
    shift
done

if [ -z "$TOOL_NAME" ] ; then
    echo "Error: No toolname specified"
    exit 1
fi

if [ -z "$OUTPUT_DIR" ] ; then
    echo "Error: No output dir specified"
    exit 1
fi