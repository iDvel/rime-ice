# 仓库维护指南

本仓库是 Rime 输入法配置仓库，包含输入方案、词库、OpenCC 映射和 Lua 扩展。修改时优先保持现有文件结构和命名风格，不要把生成文件当作源文件直接维护。

## 常用命令

```bash
make -C others/script/ build
make -C others/script/ lint
make -C others/script/ smoke
```

- `build`：生成并排序词库和 OpenCC 映射文件，依赖 Go 环境。
- `lint`：校验 YAML 和 Lua，依赖 `yamllint` 和 `luacheck`。
- `smoke`：执行功能测试。建议只在 CI 中运行，本地执行会清空用户词库。

修改配置、词库、Lua 或生成源文件后，至少运行 `make -C others/script/ build` 和 `make -C others/script/ lint`。只修改文档时不需要运行构建。

## 主要文件

- `cn_dicts/`：中文词库文件。
  - `8105`：默认启用的常用汉字单字。
  - `41448`：大字表，默认不启用，主要收录生僻字。
  - `base`：核心词库，包含两字词和常用词，必须包含注音和词频。
  - `ext`：扩展词库，必须包含注音和词频。
  - `tencent`：大词库，不需要包含注音，禁止加入多音字。
- `en_dicts/*.yaml`：英文词库文件。
  - `en`：核心英文词库，只包含常用英文词。
  - `en_ext`：扩展英文词库，包含术语、流行词、科技短语等。
- `en_dicts/*.txt`：中英混合词库文件，由 `others/cn_en.txt` 派生。
- `opencc/`：OpenCC 映射文件，控制 Emoji 和部分特殊词输出，由 `others/emoji-map.txt` 派生。
- `lua/`：Lua 扩展脚本，使用 `librime-lua` API。
- `others/script/`：构建、检查和测试脚本。
- `others/recipes/`：plum 配方文件。
- `*.schema.yaml`：输入方案文件，定义拼写、翻译器、过滤器和词库引用。
- `*.dict.yaml`：主词库文件，在文件头引用具体词库文件。此类文件的具体格式请参考既有文件的写法，和标准 yaml 有所不同。
- `recipe.yaml`：plum 默认配方。
- `symbols*`：控制 `v`/`V` 模式下的符号输入。
- `weasel.yaml`：小狼毫前端配置。
- `squirrel.yaml`：鼠须管前端配置。
- `default.yaml`：全局默认配置，控制启用方案和通用行为。
- `custom_phrase.txt`：全拼自定义短语。

## 修改规则

- 禁止删除任何文件。
- 禁止修改 README.md。
- 修改或添加中文词，写入 `cn_dicts/` 下对应词典；不要直接修改 `rime_ice.dict.yaml`。
- 修改或添加英文词，写入 `en_dicts/` 下对应词典；不要直接修改 `melt_eng.dict.yaml`。
- 修改中英混合词时，只改 `others/cn_en.txt`，再运行构建生成 `en_dicts/*.txt`。
- 修改 Emoji 映射时，只改 `others/emoji-map.txt`，再运行构建生成 `opencc/*.txt`。
- `*.dict.yaml` 文件很大。确认内容时优先读取前 50 行，再用搜索定位；修改时优先用查找、替换或追加，避免整文件重写。
- 禁止修改 `radical_pinyin.*.yaml` 和 `lua/search.lua`。这些文件从 `mirtlecn/rime-radical-pinyin` 同步；发现问题时应到上游处理。

## 提交规则

提交信息必须使用 Conventional Commits，正文使用中文。类型和作用域（scope）：
- `feat`, `fix`, `refactor`, `ci`, `build`, `docs`, `chore` 等依照常规使用
- `dict(cn)`：修改中文词库。
- `dict(en)`：修改英文词库。
- `dict(radical)`：修改拆字相关词库。
- `dict(opencc)`：修改 `opencc/` 相关源文件或生成结果。
- `config`：修改配置项或输入方案。例如 config(schema) 修改输入方案文件，config(weasel) 修改 `weasel.yaml`。
- 作用域：`lua`，修改 `lua/*.lua` 时使用，例如 `feat(lua)`

破坏性更新在类型或作用域后添加 `!`，例如 `refactor(lua)!: 修改农历输出`，并同步更新 `others/docs/Changelog.md`。

提交前确认工作区只包含本次任务相关文件，不要混入无关格式化或生成结果。
