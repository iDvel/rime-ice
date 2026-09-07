#!/bin/bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)"
export SMOKE_ROOT="${script_dir}"
export SMOKE_REPO_ROOT="$(cd "${SMOKE_ROOT}/../../.."; pwd)"
export SMOKE_WORK_ROOT="${SMOKE_WORK_ROOT:-${RUNNER_TEMP:-/tmp}/rime-ice-smoke}"
export SMOKE_LOG_ROOT="${SMOKE_LOG_ROOT:-${SMOKE_WORK_ROOT}/logs}"

source "${SMOKE_ROOT}/lib/common.sh"

suite_name="${1:-rime_ice}"

case "${suite_name}" in
  rime_ice)
    source "${SMOKE_ROOT}/suites/config_repo.sh"
    run_config_repo_suite "${suite_name}"
    ;;
  *)
    fail "unknown smoke suite: ${suite_name}"
    ;;
esac
