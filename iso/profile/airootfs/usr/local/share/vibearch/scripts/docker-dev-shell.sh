#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE_TAG="${VIBEARCH_DOCKER_IMAGE:-vibearch-builder:latest}"
DOCKER_CONTEXT_DIR="${ROOT_DIR}/docker"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

main() {
  require_cmd docker

  if ! docker image inspect "${IMAGE_TAG}" >/dev/null 2>&1; then
    echo "Builder image not found, building ${IMAGE_TAG}..."
    docker build -t "${IMAGE_TAG}" -f "${DOCKER_CONTEXT_DIR}/Dockerfile.builder" "${DOCKER_CONTEXT_DIR}"
  fi

  docker run --rm -it --privileged \
    -v "${ROOT_DIR}:/workspace" \
    -w /workspace \
    "${IMAGE_TAG}"
}

main "$@"
