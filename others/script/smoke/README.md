# Smoke Test Framework

This directory contains the shell-based smoke test framework for the current repository.

## Layout

- `run.sh`: suite entrypoint
- `lib/common.sh`: shared shell helpers
- `suites/config_repo.sh`: generic suite implementation for the current config repository
- `cases/rime_ice/input_cases.tsv`: data-driven input cases

## Current Flow

- uses local `rime_deployer` and `rime_api_console` from `PATH` when available
- otherwise downloads the public Linux CLI bundle when `RIME_CLI_URL` is set
- deploys the current repository with `rime_deployer --build`
- runs `rime_api_console`
- fails on error-level stderr lines, including Rime logs such as `E20260329 ...`
- verifies basic pinyin commit and a stable Lua-driven Unicode commit

## Environment Variables

- `RIME_CLI_URL`: optional public CLI bundle URL
- `RIME_CONFIG_ROOT`: optional repository root override
- `SMOKE_ALLOW_DESTRUCTIVE=1`: required for local runs because the smoke suite removes `${RIME_CONFIG_ROOT:-repo}/build` and `${RIME_CONFIG_ROOT:-repo}/*.userdb`

## Destructive Cleanup

The smoke suite removes the following paths under `RIME_CONFIG_ROOT` before deployment:

- `build/`
- `*.userdb/`

This cleanup is allowed automatically in CI. Local runs must opt in explicitly:

```bash
SMOKE_ALLOW_DESTRUCTIVE=1 ./others/script/smoke/run.sh
```

## Extending

Add more rows to `cases/rime_ice/input_cases.tsv`.
The current tab-separated case format is:

- `case_id`
- `schema_id`
- `key_sequence`
- `expected_text`

`expected_text` also supports:

- `@today:<date format>`, for example `@today:%Y-%m-%d`
- `@regex:<pattern>`, matched against the normalized stdout log

`rime_api_console` is used as the default runner because it is more reliable than `rime_console` for smoke tests that reuse an already deployed workspace.
