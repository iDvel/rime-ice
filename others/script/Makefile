.DEFAULT_GOAL := default

.PHONY: default build lint lint-yaml lint-lua lint-lua-format smoke

default:
	@:

build:
	go mod tidy && go run . --rime_path "$$(cd ../.. && pwd)" --auto_confirm

lint:
	bash lint/run.sh all

lint-yaml:
	bash lint/run.sh yaml-lint

lint-lua:
	bash lint/run.sh lua-lint

lint-lua-format:
	bash lint/run.sh lua-format-check

smoke:
	bash ./smoke/run.sh rime_ice
