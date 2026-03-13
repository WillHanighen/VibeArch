#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE_TAG="${VIBEARCH_DOCKER_IMAGE:-vibearch-builder:latest}"
DOCKER_CONTEXT_DIR="${ROOT_DIR}/docker"
CLEAN_BUILD="${VIBEARCH_CLEAN_BUILD:-1}"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

main() {
  require_cmd docker

  local host_uid host_gid
  host_uid="$(id -u)"
  host_gid="$(id -g)"

  echo "Building Docker image: ${IMAGE_TAG}"
  docker build -t "${IMAGE_TAG}" -f "${DOCKER_CONTEXT_DIR}/Dockerfile.builder" "${DOCKER_CONTEXT_DIR}"

  mkdir -p "${ROOT_DIR}/out" "${ROOT_DIR}/work"

  echo "Running mkarchiso inside container..."
  docker run --rm --privileged \
    -v "${ROOT_DIR}:/workspace" \
    -w /workspace \
    "${IMAGE_TAG}" \
    -lc "VIBEARCH_CLEAN_BUILD=${CLEAN_BUILD} bash iso/build-iso.sh; ec=\$?; chown -R ${host_uid}:${host_gid} /workspace/out /workspace/work || true; exit \$ec"

  echo "Done. ISO artifacts are in ${ROOT_DIR}/out"
}

main "$@"
