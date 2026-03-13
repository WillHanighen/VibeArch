#!/usr/bin/env bash

set -euo pipefail

: "${VIBEARCH_STATE_DIR:=/tmp/vibearch-installer}"
: "${VIBEARCH_LOG_FILE:=${VIBEARCH_STATE_DIR}/install.log}"

mkdir -p "${VIBEARCH_STATE_DIR}"

_log_ts() {
  date +"%Y-%m-%d %H:%M:%S"
}

_log_write() {
  local level="$1"
  shift
  local message="$*"
  local line
  line="$(_log_ts) [${level}] ${message}"
  echo "${line}" | tee -a "${VIBEARCH_LOG_FILE}" >&2
}

log_info() {
  _log_write "INFO" "$@"
}

log_warn() {
  _log_write "WARN" "$@"
}

log_error() {
  _log_write "ERROR" "$@"
}

log_fatal() {
  _log_write "FATAL" "$@"
  exit 1
}

require_cmd() {
  local cmd="$1"
  command -v "${cmd}" >/dev/null 2>&1 || log_fatal "Required command not found: ${cmd}"
}

run_cmd() {
  log_info "Running: $*"
  "$@"
}
