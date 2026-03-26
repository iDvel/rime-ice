#!/bin/bash

run_config_repo_suite() {
  local suite_name="$1"
  local suite_root="${SMOKE_ROOT}/cases/${suite_name}"
  local work_root="${SMOKE_WORK_ROOT}/${suite_name}"
  local log_root="${SMOKE_LOG_ROOT}/${suite_name}"
  local cli_url="${RIME_CLI_URL:-}"
  local config_root="${RIME_CONFIG_ROOT:-${SMOKE_REPO_ROOT}}"
  local cli_paths_file="${work_root}/cli-paths.txt"
  local deployer_path
  local api_console_path
  local user_data_dir="${work_root}/user-data"
  local deploy_stdout="${log_root}/deploy.stdout.log"
  local deploy_stderr="${log_root}/deploy.stderr.log"
  local deploy_combined="${log_root}/deploy.combined.log"
  local deploy_warnings="${log_root}/deploy.warnings.log"

  ensure_clean_dir "${work_root}"
  ensure_clean_dir "${log_root}"
  mkdir -p "${user_data_dir}"

  assert_file_exists "${config_root}/default.yaml"
  assert_file_exists "${config_root}/${suite_name}.schema.yaml"
  require_destructive_cleanup_approval "${config_root}"
  clean_config_artifacts "${config_root}"

  resolve_cli_commands "${cli_url}" "${work_root}" >"${cli_paths_file}"
  deployer_path="$(sed -n '1p' "${cli_paths_file}")"
  api_console_path="$(sed -n '2p' "${cli_paths_file}")"

  log_step "using config root ${config_root}"
  log_step "running deployer"
  if ! run_deployer "${deployer_path}" "${user_data_dir}" "${config_root}" "${deploy_stdout}" "${deploy_stderr}"; then
    combine_logs "${deploy_stdout}" "${deploy_stderr}" "${deploy_combined}"
    set_failure_context "deployment" "${deploy_combined}"
    fail "rime_deployer exited with non-zero status"
  fi

  combine_logs "${deploy_stdout}" "${deploy_stderr}" "${deploy_combined}"
  set_failure_context "deployment" "${deploy_combined}"
  assert_no_error_lines "${deploy_combined}"
  collect_warning_lines "${deploy_combined}" "${deploy_warnings}"
  assert_file_exists "${user_data_dir}/build/default.yaml"
  assert_file_exists "${user_data_dir}/build/${suite_name}.schema.yaml"
  log_pass "deployment passed"

  if [[ -s "${deploy_warnings}" ]]; then
    log_warn "deployment warnings detected"
    cat "${deploy_warnings}"
  fi
  clear_failure_context

  run_config_input_cases "${suite_root}/input_cases.tsv" "${api_console_path}" "${config_root}" "${user_data_dir}" "${log_root}"
}

run_config_input_cases() {
  local case_file="$1"
  local api_console_path="$2"
  local shared_data_dir="$3"
  local user_data_dir="$4"
  local log_root="$5"
  local raw_line
  local pending_schema_id=""
  local pending_case_file="${log_root}/pending_cases.tsv"

  [[ -f "${case_file}" ]] || fail "case file not found: ${case_file}"
  : >"${pending_case_file}"

  while IFS= read -r raw_line || [[ -n "${raw_line}" ]]; do
    if [[ -z "${raw_line}" ]]; then
      flush_schema_case_group \
        "${pending_schema_id}" \
        "${pending_case_file}" \
        "${api_console_path}" \
        "${shared_data_dir}" \
        "${user_data_dir}" \
        "${log_root}"
      pending_schema_id=""
      : >"${pending_case_file}"
      continue
    fi
    if [[ "${raw_line}" == \#* ]]; then
      flush_schema_case_group \
        "${pending_schema_id}" \
        "${pending_case_file}" \
        "${api_console_path}" \
        "${shared_data_dir}" \
        "${user_data_dir}" \
        "${log_root}"
      pending_schema_id=""
      : >"${pending_case_file}"
      printf '%s\n' "${raw_line}"
      continue
    fi

    local case_id
    local schema_id
    local key_sequence
    local expected_text
    IFS=$'\t' read -r case_id schema_id key_sequence expected_text <<<"${raw_line}"
    if [[ -z "${case_id}" ]]; then
      continue
    fi

    if [[ -n "${pending_schema_id}" && "${schema_id}" != "${pending_schema_id}" ]]; then
      flush_schema_case_group \
        "${pending_schema_id}" \
        "${pending_case_file}" \
        "${api_console_path}" \
        "${shared_data_dir}" \
        "${user_data_dir}" \
        "${log_root}"
      : >"${pending_case_file}"
    fi

    pending_schema_id="${schema_id}"
    printf '%s\t%s\t%s\n' "${case_id}" "${key_sequence}" "${expected_text}" >>"${pending_case_file}"
  done <"${case_file}"

  flush_schema_case_group \
    "${pending_schema_id}" \
    "${pending_case_file}" \
    "${api_console_path}" \
    "${shared_data_dir}" \
    "${user_data_dir}" \
    "${log_root}"
}

flush_schema_case_group() {
  local schema_id="$1"
  local case_group_file="$2"
  local api_console_path="$3"
  local shared_data_dir="$4"
  local user_data_dir="$5"
  local log_root="$6"

  [[ -n "${schema_id}" ]] || return 0
  [[ -s "${case_group_file}" ]] || return 0

  local group_name="${schema_id}"
  local group_input_path="${log_root}/${group_name}.group.input.txt"
  local group_stdout_path="${log_root}/${group_name}.group.stdout.log"
  local group_stderr_path="${log_root}/${group_name}.group.stderr.log"
  local group_combined_path="${log_root}/${group_name}.group.combined.log"
  local group_normalized_path="${log_root}/${group_name}.group.normalized.log"

  build_schema_group_input "${schema_id}" "${case_group_file}" "${group_input_path}"
  log_step "running schema group ${schema_id}"
  if ! run_api_console_script "${api_console_path}" "${shared_data_dir}" "${user_data_dir}" "${group_input_path}" "${group_stdout_path}" "${group_stderr_path}"; then
    combine_logs "${group_stdout_path}" "${group_stderr_path}" "${group_combined_path}"
    set_failure_context "schema group ${schema_id}" "${group_combined_path}"
    fail "rime_api_console exited with non-zero status"
  fi

  combine_logs "${group_stdout_path}" "${group_stderr_path}" "${group_combined_path}"
  set_failure_context "schema group ${schema_id}" "${group_combined_path}"
  assert_no_error_lines "${group_combined_path}"
  normalize_console_output "${group_stdout_path}" "${group_normalized_path}"
  clear_failure_context

  assert_schema_group_cases "${schema_id}" "${case_group_file}" "${group_normalized_path}" "${group_combined_path}" "${log_root}"
}

build_schema_group_input() {
  local schema_id="$1"
  local case_group_file="$2"
  local output_path="$3"
  local case_id
  local key_sequence
  local expected_text

  : >"${output_path}"
  while IFS=$'\t' read -r case_id key_sequence expected_text; do
    [[ -n "${case_id}" ]] || continue
    printf 'select schema %s\n%s\n' "${schema_id}" "${key_sequence}" >>"${output_path}"
  done <"${case_group_file}"
  printf 'exit\n' >>"${output_path}"
}

extract_case_output_block() {
  local normalized_path="$1"
  local schema_id="$2"
  local occurrence="$3"
  local output_path="$4"
  awk -v marker="selected schema: [${schema_id}]" -v target="${occurrence}" '
    $0 == marker {
      count++
      if (count == target) {
        printing = 1
      } else if (count > target && printing) {
        exit
      }
    }
    printing {
      print
    }
  ' "${normalized_path}" >"${output_path}"
}

assert_schema_group_cases() {
  local schema_id="$1"
  local case_group_file="$2"
  local group_normalized_path="$3"
  local group_combined_path="$4"
  local log_root="$5"
  local case_index=0
  local case_id
  local key_sequence
  local expected_text
  local resolved_expected_text

  while IFS=$'\t' read -r case_id key_sequence expected_text; do
    [[ -n "${case_id}" ]] || continue
    ((case_index += 1))
    resolved_expected_text="$(resolve_expected_text "${expected_text}")"

    local case_stdout_path="${log_root}/${case_id}.stdout.log"
    extract_case_output_block "${group_normalized_path}" "${schema_id}" "${case_index}" "${case_stdout_path}"

    set_failure_context "case ${case_id}" "${group_combined_path}"
    assert_file_contains "${case_stdout_path}" "selected schema: [${schema_id}]"
    if [[ "${expected_text}" == @regex:* ]]; then
      assert_file_matches "${case_stdout_path}" "${expected_text#@regex:}"
    else
      assert_file_contains "${case_stdout_path}" "commit: ${resolved_expected_text}"
    fi
    log_pass "input case passed: ${case_id}"
    clear_failure_context
  done <"${case_group_file}"
}
