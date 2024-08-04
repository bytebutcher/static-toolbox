SCRIPT="${BASH_SOURCE[0]}"
SCRIPT_NAME="buildctl"
PROJECT_ROOT="$(cd "$(dirname "$(readlink -f "${SCRIPT}")")/../.." && pwd)"
TOOLS_DIR="$PROJECT_ROOT/tools"
BUILD_OUTPUT_DIR="$PROJECT_ROOT/build_output"
if [ -z "$GITHUB_REPOSITORY" ] ; then
    GITHUB_REPOSITORY=$(git remote get-url origin  | sed -E 's#.*/([^/]+/[^.]+)(.git)?#\1#')
fi