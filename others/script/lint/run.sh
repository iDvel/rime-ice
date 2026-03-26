#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
YAMLLINT_CONFIG="${SCRIPT_DIR}/.yamllint.yml"
LUACHECK_CONFIG="${SCRIPT_DIR}/.luacheckrc"

log() {
  printf '[lint] %s\n' "$*"
}

log_step() {
  printf '[lint] 🔹 %s\n' "$*"
}

log_pass() {
  printf '[lint] ✅ %s\n' "$*"
}

log_warn() {
  printf '[lint] ⚠️ %s\n' "$*"
}

log_fail() {
  printf '[lint] 🔴 %s\n' "$*" >&2
}

find_business_yaml_files() {
  (
    cd "${REPO_ROOT}"
    find . \
      \( -path "./.git" -o -path "./.git/*" -o -path "./.github" -o -path "./.github/*" -o -path "./others" -o -path "./others/*" \) -prune \
      -o \
      \( -maxdepth 1 -type f \( -name "*.yaml" -o -name "*.yml" \) ! -name "*.dict.yaml" -print \)
  ) | sort
}

sanitize_schema_yaml() {
  local source_file="$1"
  local output_file="$2"

  awk '
    function indent_width(line) {
      match(line, /^ */)
      return RLENGTH
    }

    BEGIN {
      in_pin_cand_filter = 0
      pin_indent = -1
    }

    {
      if (!in_pin_cand_filter) {
        if ($0 ~ /^ *pin_cand_filter:[[:space:]]*$/) {
          in_pin_cand_filter = 1
          pin_indent = indent_width($0)
        }
        print
        next
      }

      if ($0 ~ /^[[:space:]]*$/ || $0 ~ /^[[:space:]]*#/) {
        print
        next
      }

      current_indent = indent_width($0)
      if (current_indent <= pin_indent) {
        in_pin_cand_filter = 0
        print
        next
      }

      if ($0 ~ /^[[:space:]]*-[[:space:]]/) {
        print substr($0, 1, current_indent) "- __PIN_CAND_FILTER_PLACEHOLDER__"
        next
      }

      print
    }
  ' "${source_file}" > "${output_file}"
}

require_tool() {
  local tool_name="$1"
  if ! command -v "${tool_name}" >/dev/null 2>&1; then
    log_fail "missing required tool: ${tool_name}"
    return 1
  fi
}

run_yaml_lint() {
  require_tool yamllint

  local yaml_files=()
  local temp_dir=''
  local lint_status=0
  local total_start_time
  total_start_time="$(date +%s)"
  while IFS= read -r yaml_file; do
    yaml_files+=("${yaml_file}")
  done < <(find_business_yaml_files)

  if [[ "${#yaml_files[@]}" -eq 0 ]]; then
    log_warn 'no business YAML files found'
    return 0
  fi

  temp_dir="$(mktemp -d)"
  trap 'if [[ -n "${temp_dir:-}" ]]; then rm -rf "${temp_dir}"; fi' RETURN

  log_step "yaml-lint checking ${#yaml_files[@]} file(s)"

  for yaml_file in "${yaml_files[@]}"; do
    local lint_target="${yaml_file}"
    local lint_output=''
    local file_start_time
    local file_elapsed
    file_start_time="$(date +%s)"

    log_step "yaml-lint checking ${yaml_file}"

    if [[ "${yaml_file}" == *.schema.yaml ]]; then
      lint_target="${temp_dir}/$(basename "${yaml_file}")"
      sanitize_schema_yaml "${REPO_ROOT}/${yaml_file#./}" "${lint_target}"
    fi

    if ! lint_output="$(cd "${REPO_ROOT}" && yamllint -f parsable -c "${YAMLLINT_CONFIG}" "${lint_target}" 2>&1)"; then
      lint_status=1
      if [[ "${lint_target}" != "${yaml_file}" ]]; then
        lint_output="${lint_output//${lint_target}/${yaml_file}}"
      fi
      printf '%s\n' "${lint_output}"
      log_fail "yaml-lint failed for ${yaml_file}"
    fi

    file_elapsed="$(( $(date +%s) - file_start_time ))"
    log_pass "yaml-lint finished ${yaml_file} in ${file_elapsed}s"
  done

  log_pass "yaml-lint completed in $(( $(date +%s) - total_start_time ))s"

  return "${lint_status}"
}

run_lua_lint() {
  require_tool luacheck
  local lint_output=''
  local lint_status=0
  local last_line=''
  local normalized_last_line=''
  log_step 'lua-lint checking lua/**/*.lua'

  set +e
  lint_output="$(
    (
      cd "${REPO_ROOT}"
      luacheck lua --no-default-config --config "${LUACHECK_CONFIG}" --codes --ranges
    ) 2>&1
  )"
  lint_status=$?
  set -e

  printf '%s\n' "${lint_output}"
  last_line="$(printf '%s\n' "${lint_output}" | tail -n 1)"
  normalized_last_line="$(printf '%s\n' "${last_line}" | sed -E $'s/\x1B\\[[0-9;]*[[:alpha:]]//g')"
  if [[ "${lint_status}" -eq 0 ]]; then
    log_pass 'lua-lint passed'
    return 0
  fi

  if printf '%s\n' "${normalized_last_line}" | grep -Eq '0 errors?'; then
    log_warn 'lua-lint completed with warnings'
    return 0
  fi
  log_fail 'lua-lint completed with errors'
  return 1
}

run_lua_format_check() {
  log_warn 'lua-format-check is not enabled yet'
  return 1
}

run_all() {
  run_yaml_lint
  run_lua_lint
}

usage() {
  cat <<'EOF'
Usage: bash others/script/lint/run.sh <command>

Commands:
  yaml-lint
  lua-lint
  lua-format-check
  all
EOF
}

main() {
  local command="${1:-}"
  case "${command}" in
    yaml-lint)
      run_yaml_lint
      ;;
    lua-lint)
      run_lua_lint
      ;;
    lua-format-check)
      run_lua_format_check
      ;;
    all)
      run_all
      ;;
    help|-h|--help)
      usage
      ;;
    *)
      usage >&2
      return 1
      ;;
  esac
}

main "$@"
