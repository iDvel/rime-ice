# 更新日志

除日常更新词库外的一些主要更新 🆕、破坏性变更 ⚠️。

### 2025.12.08

- 修正了 lua 注释中的引入错误 [#1405](https://github.com/iDvel/rime-ice/issues/1405)

### 2025-10-31

- `uuid.lua` 生成符合 RFC 4122 标准的 UUID v4 [#1383](https://github.com/iDvel/rime-ice/pull/1383)

### 2025-06-09

- 添加拼音加加双拼方案 [#1228](https://github.com/iDvel/rime-ice/pull/1228)

---

*2025.04.06 Release*

## 2025-04-06

- 消除输入框里大写字母之间的空格 [#1213](https://github.com/iDvel/rime-ice/issues/1213)

## 2025-03-30

- `editor` 配置示例（定制操作键的行为） [#1131](https://github.com/iDvel/rime-ice/pull/1131)

## 2025-03-30

- 所有中文词汇的连接号暂时统一使用 Hyphen-minus `U+002D` [#1194](https://github.com/iDvel/rime-ice/pull/1194)

## 2025-02-24

- 适配 `punctuator` 新属性 [#1180](https://github.com/iDvel/rime-ice/issues/1180)

---

*2024.12.12 Release*

## 2024-12-06

- ⚠️ Lua 模块引用方式变更
    - 删除了 `rime.lua`
    - 在方案中引用时添加 `*` 前缀

---

*2024.11.29 Release*

## 2024-11-27

- `calc_translator.lua` 🆕： 计算器插件，按 `cC` 后输入算式获得结果

## 2024-11-21

- ⚙️ 非夹注的 symbol 调用按键从 `vfj` 更改为 `vfjz`

## 2024-11-04

- ⚠️ 同步新版鼠须管配置，注意 `candidate_format` 和 1.0.0 之前的版本不兼容，需要手动改回旧版 `candidate_format: '%c. %@'`

---

*2024-09-25 Release*

## 2024-09-25

- `number_translator.lua`：⚙️ 依会计凭证书写要求，修正万亿的金额大写格式
- radical_pinyin: 🆕 拆字词典更新至 v2，包含更多汉字

## 2024-08-29
- `cold_word_drop`：🆕 支持 iOS (#1003)

## 2024-08-18

- ci: 词典处理脚本可在 GitHub CI 中运行，提交信息以 ` [build]` 结尾或者手动执行时触发。

## 2024-07-27

- `number_translator.lua`: 🆕 转换时，将「拾万」和「壹拾万」作为两个独立的候选。
- `en_spacer.lua`：⚠️ 现在不会在中英标点、空字符前添加空格。将在英文后添加空格，修改为在英文前添加空格。

---

*2024.05.21 Release*

## 2024-05-15

- `select_character.lua`: 🆕 当候选字数为 1 时，快捷键使其上屏（为旧版行为）；
- `search.lua`：
    - 重写，使其在 librime 1.85 也能正常工作；
    - 开启辅码方案的用户字典时（非默认行为，您也不应该这么做），不再造成用户词典锁定
- `corrector.lua`：
    - ⚠️ 使用 translator 中的 comment_format 标记拼音串，以适配 librime 1.11；
    - 🆕 `translator/keep_comments: true`：可以保留拼音注释

## 2024-02-09 ♻️

重构了 `pin_cand_filter.lua` 置顶候选项功能。 [#675](https://github.com/iDvel/rime-ice/issues/675)

- 调整了方案中 `engine/filters` 的排序
- 不再需要在配置中写 emoji，emoji 可自动吸附。

## 2024-02-04 ⚠️

⚠️ 中英混输词库由英文方案附属切换到单独的 table_translator ([#662](https://github.com/iDvel/rime-ice/pull/662))

- 词库文件由 `cn_en*.dict.yaml` 变为 `cn_en*.txt`
- 双拼不再需要去 `melt_eng.dict.yaml` 更改引用词库

## 2024-02-01 🆕

`pin_cand_filter.lua` 置顶候选项 [#586](https://github.com/iDvel/rime-ice/issues/586)

## 2024-01-29 🆕 ⚠️

[部件拆字方案](https://github.com/mirtlecn/rime-radical-pinyin) 反查、辅码 ([#643](https://github.com/iDvel/rime-ice/pull/643))

- 反查：默认以 `uU` 开头
- 辅码：默认以 `` ` ``（反引号）开启查询

⚠️ 部件拆字方案替换掉了两分方案

## 2024-01-02 🆕 🐛 ⚠️

🆕 农历功能 [#565](https://github.com/iDvel/rime-ice/issues/565)

🐛 长词优先 `long_word_filter.lua` 不提升包含英文、数字、emoji、假名的候选项 [#592](https://github.com/iDvel/rime-ice/issues/592)

⚠️ 更新并修改 `weasel_style.yaml` 为 `weasel.yaml` （[#584](https://github.com/iDvel/rime-ice/pull/584)）

## 2023-11-29 ⚠️

九宫格方案 2~9 的映射由 ADGJMPTW 改为 23456789 [a0e0ef8](https://github.com/iDvel/rime-ice/commit/a0e0ef807e4ebc50771563717375f554c9473315)

全键盘切换到九宫格方案不再需要删除词库中的大写字母。

（更新至仓输入法商店版 2.1.0 或 TF 119 后可自动适应）

## 2023-10-30 📖

完成同义多音字的注音问题 [#353](https://github.com/iDvel/rime-ice/issues/353)

## 2023-09-08 🆕

仓输入法九宫格方案 [72acbc7](https://github.com/iDvel/rime-ice/commit/72acbc7a2e53cbac7d6f3ab4a82bc457a7ed8f27)

## 2023-08-07 🆕

支持搜狗双拼 [34ab972](https://github.com/iDvel/rime-ice/commit/34ab9725ea9cdf918cbf9f6a4c27d61db7736b07)

## 2023-08-06 🆕

`corrector.lua` 错音错字提示 [3c3582e](https://github.com/iDvel/rime-ice/commit/3ce582e1951acb6dc381332d8e61381767d35a36)

## 2023-07-28 📖

删除了八股文，因为 [#407](https://github.com/iDvel/rime-ice/issues/407)

全词库完成注音 🎉 [#317](https://github.com/iDvel/rime-ice/issues/317)

## 2023-06-13 ⚠️

中英混输词库不再派生纯大写形式 [6f51bdd](https://github.com/iDvel/rime-ice/commit/6f51bddd1467494c759181a237341f89a1ed3dd1)

- 修改了 `melt_eng.schema.yaml` 派生规则
- 修改了中英混输词库，所有编码前缀加上特殊符号

## 2023-06-09 ⚠️

双拼拼写规则以特殊字符搭桥 （[#332](https://github.com/iDvel/rime-ice/pull/332)），[说明：#356](https://github.com/iDvel/rime-ice/issues/356)

- 修改了全拼及双拼方案的拼写规则

## 2023-06-07 🆕

英文词中数字和标点自动转写 （[#326](https://github.com/iDvel/rime-ice/issues/326)）

- 修改了 `melt_eng.schema.yaml` 拼写派生规则
- 修改了英文词库部分编码

## 2023-05-30 🆕

英文词汇自动大写转换 （[#305](https://github.com/iDvel/rime-ice/pull/305)）

- 增加 Lua 脚本 `autocap_filter.lua`
- 修改了 `melt_eng.schema.yaml` 拼写派生规则。

## 2023-05-24 🐛

修复全拼方案模糊音派生规则 [6c0618a](https://github.com/iDvel/rime-ice/commit/6c0618aeaf2910482e20ff1c057f482aaa98c051)

## 2023-05-13 🆕

数字、金额大写 [#264](https://github.com/iDvel/rime-ice/issues/264)

- 增加 Lua 脚本 `number_translator.lua` 

## 2023-05-09 🆕

添加双拼的中英混输词库 [3e24a1e](https://github.com/iDvel/rime-ice/commit/3e24a1ee202054f776f188ba82e86fa30f16ab55)

## 2023-05-08 ⚠️

Lua 模块化 [a34c46a](https://github.com/iDvel/rime-ice/commit/a34c46ad34673d535dc1df4ef208ad4c7e3baf80) [b514049](https://github.com/iDvel/rime-ice/commit/b514049e33c7e0c8fccacec49faa3830bd7bdf26)

