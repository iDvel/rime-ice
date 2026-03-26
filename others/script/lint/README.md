# YAML and Lua lint entrypoint

This directory contains the lightweight lint entrypoint used by local commands.

## Dependencies

Current stage:

- `yamllint`
- `luacheck`

Example install on macOS:

```bash
brew install yamllint luacheck
```

## Usage

From the repository root:

```bash
bash others/script/lint/run.sh yaml-lint
bash others/script/lint/run.sh lua-lint
bash others/script/lint/run.sh all
make -C others/script lint-yaml
make -C others/script lint-lua
make -C others/script lint
make -C others/script smoke
```

## Notes

- The current implementation enables YAML linting and Lua linting.
- The first stage checks repository-root business YAML files and root
  `*.schema.yaml` files.
- `*.schema.yaml` files are preprocessed before linting so the `pin_cand_filter`
  tab-separated list does not break generic YAML parsing.
- `lua-lint` runs `luacheck` with a repository-local configuration derived from
  the librime-lua globals currently used by this repository.
- `lua-format-check` is reserved for a later stage.
- `smoke` mirrors the current CI smoke invocation and runs
  `bash ./others/script/smoke/run.sh rime_ice` through Make.
- GitHub Actions are intentionally not changed in this stage.
