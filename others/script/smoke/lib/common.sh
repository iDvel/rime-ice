#!/bin/bash

if [[ -z "${SMOKE_ROOT:-}" ]]; then
  SMOKE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.."; pwd)"
fi
if [[ -z "${SMOKE_REPO_ROOT:-}" ]]; then
  SMOKE_REPO_ROOT="$(cd "${SMOKE_ROOT}/../../.."; pwd)"
fi
if [[ -z "${SMOKE_WORK_ROOT:-}" ]]; then
  SMOKE_WORK_ROOT="${RUNNER_TEMP:-/tmp}/rime-ice-smoke"
fi
if [[ -z "${SMOKE_LOG_ROOT:-}" ]]; then
  SMOKE_LOG_ROOT="${SMOKE_WORK_ROOT}/logs"
fi

SMOKE_CURRENT_LABEL="${SMOKE_CURRENT_LABEL:-}"
SMOKE_CURRENT_LOG_FILE="${SMOKE_CURRENT_LOG_FILE:-}"

log() {
  printf '[smoke] %s\n' "$*"
}

log_step() {
  printf '[smoke] 🔹 %s\n' "$*"
}

log_pass() {
  printf '[smoke] ✅ %s\n' "$*"
}

log_warn() {
  printf '[smoke] ⚠️ %s\n' "$*"
}

fail() {
  printf '[smoke] 🔴 %s\n' "$*" >&2
  if [[ -n "${SMOKE_CURRENT_LABEL}" ]]; then
    printf '[smoke][context] %s\n' "${SMOKE_CURRENT_LABEL}" >&2
  fi
  if [[ -n "${SMOKE_CURRENT_LOG_FILE}" && -f "${SMOKE_CURRENT_LOG_FILE}" ]]; then
    printf '[smoke][log] begin %s\n' "${SMOKE_CURRENT_LOG_FILE}" >&2
    sed -n '1,240p' "${SMOKE_CURRENT_LOG_FILE}" >&2
    printf '[smoke][log] end %s\n' "${SMOKE_CURRENT_LOG_FILE}" >&2
  fi
  exit 1
}

set_failure_context() {
  local label="$1"
  local log_file="$2"
  SMOKE_CURRENT_LABEL="${label}"
  SMOKE_CURRENT_LOG_FILE="${log_file}"
}

clear_failure_context() {
  SMOKE_CURRENT_LABEL=""
  SMOKE_CURRENT_LOG_FILE=""
}

require_command() {
  local command_name="$1"
  command -v "${command_name}" >/dev/null 2>&1 ||
    fail "required command not found: ${command_name}"
}

ensure_clean_dir() {
  local dir_path="$1"
  rm -rf "${dir_path}"
  mkdir -p "${dir_path}"
}

require_destructive_cleanup_approval() {
  local config_root="$1"
  local build_dir="${config_root}/build"

  if [[ "${CI:-}" == "true" || "${GITHUB_ACTIONS:-}" == "true" ]]; then
    return 0
  fi

  if [[ "${SMOKE_ALLOW_DESTRUCTIVE:-}" == "1" ]]; then
    log_warn "destructive cleanup approved by SMOKE_ALLOW_DESTRUCTIVE=1"
    return 0
  fi

  fail "smoke test will remove ${build_dir} and ${config_root}/*.userdb; rerun with SMOKE_ALLOW_DESTRUCTIVE=1 for local execution, or run in CI"
}

clean_config_artifacts() {
  local config_root="$1"
  local build_dir="${config_root}/build"

  if [[ -d "${build_dir}" ]]; then
    log_step "removing ${build_dir}"
    rm -rf "${build_dir}"
  fi

  find "${config_root}" -mindepth 1 -maxdepth 1 -type d -name '*.userdb' -print0 |
    while IFS= read -r -d '' userdb_dir; do
      log_step "removing ${userdb_dir}"
      rm -rf "${userdb_dir}"
    done
}

download_file() {
  local file_url="$1"
  local output_path="$2"
  curl -fsSL --retry 3 -o "${output_path}" "${file_url}"
}

prepare_cli_archive() {
  local cli_url="$1"
  local output_path="$2"
  local cache_path="${RIME_CLI_CACHE_PATH:-}"

  if [[ -n "${cache_path}" && -f "${cache_path}" ]]; then
    log_step "using cached rime cli bundle ${cache_path}" >&2
    cp "${cache_path}" "${output_path}"
    return 0
  fi

  log_step "downloading rime cli bundle" >&2
  download_file "${cli_url}" "${output_path}"

  if [[ -n "${cache_path}" ]]; then
    mkdir -p "$(dirname "${cache_path}")"
    cp "${output_path}" "${cache_path}"
  fi
}

extract_zip() {
  local archive_path="$1"
  local output_dir="$2"
  unzip -q "${archive_path}" -d "${output_dir}"
}

prepare_cli_bundle() {
  local archive_path="$1"
  local output_dir="$2"
  local nested_archive_path
  local bundle_root

  extract_zip "${archive_path}" "${output_dir}"

  nested_archive_path="$(find "${output_dir}" -maxdepth 2 -type f \( -name 'rime_cli-*.zip' -o -name 'rime-cli-*.zip' \) | head -n 1)"
  if [[ -n "${nested_archive_path}" ]]; then
    local nested_root="${output_dir}/nested"
    mkdir -p "${nested_root}"
    extract_zip "${nested_archive_path}" "${nested_root}"
    output_dir="${nested_root}"
  fi

  bundle_root="$(find "${output_dir}" -maxdepth 3 -type f -path '*/bin/rime_deployer' | head -n 1)"
  [[ -n "${bundle_root}" ]] || fail "rime_deployer not found in bundle"
  dirname "$(dirname "${bundle_root}")"
}

resolve_cli_commands() {
  local cli_url="${1:-}"
  local work_root="$2"
  local deployer_path
  local api_console_path
  local cli_archive
  local extract_root
  local bundle_root

  if [[ -n "${cli_url}" ]]; then
    require_command curl
    require_command unzip

    cli_archive="${work_root}/rime-cli.zip"
    extract_root="${work_root}/cli"

    prepare_cli_archive "${cli_url}" "${cli_archive}"
    log_step "extracting rime cli bundle" >&2
    bundle_root="$(prepare_cli_bundle "${cli_archive}" "${extract_root}")"
    deployer_path="${bundle_root}/bin/rime_deployer"
    api_console_path="${bundle_root}/bin/rime_api_console"
  else
    deployer_path="$(command -v rime_deployer || true)"
    api_console_path="$(command -v rime_api_console || true)"
    [[ -n "${deployer_path}" ]] || fail "RIME_CLI_URL is not set and local rime_deployer was not found in PATH"
    [[ -n "${api_console_path}" ]] || fail "RIME_CLI_URL is not set and local rime_api_console was not found in PATH"
    log_step "using local rime cli commands from PATH" >&2
  fi

  [[ -x "${deployer_path}" ]] || fail "rime_deployer is not executable: ${deployer_path}"
  [[ -x "${api_console_path}" ]] || fail "rime_api_console is not executable: ${api_console_path}"
  printf '%s\n%s\n' "${deployer_path}" "${api_console_path}"
}

combine_logs() {
  local stdout_path="$1"
  local stderr_path="$2"
  local output_path="$3"
  {
    printf '== stdout ==\n'
    cat "${stdout_path}"
    printf '\n== stderr ==\n'
    cat "${stderr_path}"
  } >"${output_path}"
}

normalize_console_output() {
  local input_path="$1"
  local output_path="$2"
  tr -d '\r' <"${input_path}" >"${output_path}"
}

assert_file_exists() {
  local file_path="$1"
  [[ -f "${file_path}" ]] || fail "expected file not found: ${file_path}"
}

assert_file_contains() {
  local file_path="$1"
  local expected_text="$2"
  grep -F -- "${expected_text}" "${file_path}" >/dev/null ||
    fail "expected '${expected_text}' in ${file_path}"
}

assert_file_matches() {
  local file_path="$1"
  local expected_pattern="$2"
  grep -E -- "${expected_pattern}" "${file_path}" >/dev/null ||
    fail "expected pattern '${expected_pattern}' in ${file_path}"
}

resolve_expected_text() {
  local expected_text="$1"
  if [[ "${expected_text}" == @today:* ]]; then
    local date_format="${expected_text#@today:}"
    date +"${date_format}"
    return 0
  fi
  printf '%s\n' "${expected_text}"
}

assert_no_error_lines() {
  local file_path="$1"
  local match_path="${file_path}.errors"
  if grep -Ein '(^E[0-9]+[[:space:]])|(^ERROR[:[:space:]])|(^Error([^[:alpha:]]|$))|(^error([^[:alpha:]]|$))|(^fatal([^[:alpha:]]|$))|([^[:alpha:]]error:)' "${file_path}" >"${match_path}"; then
    cat "${match_path}" >&2
    fail "unexpected error output detected in ${file_path}"
  fi
  rm -f "${match_path}"
}

collect_warning_lines() {
  local file_path="$1"
  local output_path="$2"
  grep -En '(^W[0-9]+[[:space:]])|(^WARNING[:[:space:]])|([Ww]arning)' "${file_path}" >"${output_path}" || true
}

run_deployer() {
  local deployer_path="$1"
  local user_data_dir="$2"
  local shared_data_dir="$3"
  local stdout_path="$4"
  local stderr_path="$5"
  "${deployer_path}" --build "${user_data_dir}" "${shared_data_dir}" >"${stdout_path}" 2>"${stderr_path}"
}

run_api_console_script() {
  local api_console_path="$1"
  local shared_data_dir="$2"
  local user_data_dir="$3"
  local input_path="$4"
  local stdout_path="$5"
  local stderr_path="$6"
  RIME_SHARED_DATA_DIR="${shared_data_dir}" \
    RIME_USER_DATA_DIR="${user_data_dir}" \
    "${api_console_path}" <"${input_path}" >"${stdout_path}" 2>"${stderr_path}"
}
