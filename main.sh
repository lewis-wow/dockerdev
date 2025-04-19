#!/bin/zsh

# Default Docker images for languages
declare -A LANG_IMAGES=(
    ["python"]="python"
    ["node"]="node"
    ["go"]="golang"
    ["cpp"]="gcc"
    ["c"]="gcc"
)

# Usage function
usage() {
    echo "Usage: dockerdev <language> [version]"
    echo -n "Supported languages:"
    for lang in "${(@ok)LANG_IMAGES}"; do
        echo -n " $lang"
    done
    echo
    exit 1
}

# Check if the user passed at least one argument
if [ $# -lt 1 ]; then
    usage
fi

# Get language and optional version
LANGUAGE=$1
VERSION=$2

# Check if the language is supported
if [[ -z "${LANG_IMAGES[$LANGUAGE]}" ]]; then
    echo "Error: Unsupported language '$LANGUAGE'"
    usage
fi

# Set the Docker image based on language
IMAGE=${LANG_IMAGES[$LANGUAGE]}

# If no version is specified, use the latest
if [ -z "$VERSION" ]; then
    VERSION="latest"
fi

# Build the full image name
IMAGE_TAG="$IMAGE:$VERSION"

# Special handling for Node.js to include pnpm
if [[ "$LANGUAGE" == "node" ]]; then
    docker run --rm -it \
        -v "$PWD":/workspace \
        -w /workspace \
        "$IMAGE_TAG" \
        bash -c "corepack enable && corepack prepare pnpm@latest --activate && bash"
elif [[ "$LANGUAGE" == "python" ]]; then
    docker run --rm -it \
        -v "$PWD":/workspace \
        -p 8888:8888 \
        -w /workspace \
        "$IMAGE_TAG" \
        bash -c "pip install --root-user-action=ignore notebook ipykernel && jupyter notebook --ip=0.0.0.0 --port=8888 --no-browser --NotebookApp.token='' --NotebookApp.password='' --NotebookApp.allow_origin='*' --NotebookApp.port_retries=0 --allow-root > /dev/null 2>&1 & bash"
else
    docker run --rm -it \
        -v "$PWD":/workspace \
        -w /workspace \
        "$IMAGE_TAG" \
        bash
fi
