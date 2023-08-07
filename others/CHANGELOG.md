# 更新日志

除日常更新词库外的一些主要更新 🆕 及破坏性变更 ⚠️。



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

## 2023-06-15 🐛

修复全拼方案模糊音派生规则

## 2023-05-13 🆕

数字、金额大写 [#264](https://github.com/iDvel/rime-ice/issues/264)

- 增加 Lua 脚本 `number_translator.lua` 

## 2023-05-09 🆕

添加双拼的中英混输词库 [3e24a1e](https://github.com/iDvel/rime-ice/commit/3e24a1ee202054f776f188ba82e86fa30f16ab55)

## 2023-05-08 ⚠️

Lua 模块化 [a34c46a](https://github.com/iDvel/rime-ice/commit/a34c46ad34673d535dc1df4ef208ad4c7e3baf80) [b514049](https://github.com/iDvel/rime-ice/commit/b514049e33c7e0c8fccacec49faa3830bd7bdf26)

