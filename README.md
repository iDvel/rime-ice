# 雾凇拼音 | Lite

[![License: GPL 3.0](https://img.shields.io/badge/License-GPL--3.0--only-34ad9b)](https://www.gnu.org/licenses/gpl-3.0.txt)

此分支为雾凇拼音的轻量版本，和主分支去区别在于：
- 不含有任何 lua 及相关功能；
- 不包含英文输入（不借助 lua 辅助，全拼和英文输入之间契合程度差）；
- 默认开启大字表
- 默认关闭容错词典
- 不会修改任何主题和样式

如果你仅需要/仅能够/仅希望使用雾凇词库，你可以尝试此版本，可能的使用情境如下：
- 部分 Linux 环境，上游不提供 librime-lua 包；
- 系统版本较早，以至于 librime 版本老旧；
- lua 功能被认为严重破坏了您的输入体验；
- 不清楚什么叫 lua，只需要使用词库

其他功能请参考主分支。

东风破配方：℞ iDvel/rime-ice@lite

```bash
bash rime-install iDvel/rime-ice@lite
```

使用 lite 配置 + 主分支词典 & 更新词典和配置：
```bash
bash rime-install iDvel/rime-ice@lite
bash rime-install iDvel/rime-ice:others/recipes/all_dicts
```
