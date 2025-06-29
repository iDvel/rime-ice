# Rime 鼠须管（Squirrel）

[Rime 官网](https://github.com/rime/home/wiki)

## 快速部署

安装鼠须管（Squirrel）可以从 [https://rime.im/download/](https://rime.im/download/) 下载，也可以使用 Homebrew：

```bash
brew install --cask squirrel
```

安装完成后，前往“系统设置 → 键盘 → 输入法”添加鼠须管。默认输出为繁体中文，可用 `Control+`` 或 `F4\` 快捷键切换简繁体。

配置部署可使用以下命令：

```bash
cp -r ~/Library/Rime ~/Library/Rime.bak 

git clone git@github.com:Hydraallen/Rime.git ~/Library/Rime
```

部署后点击菜单栏“ㄓ”图标，选择“重新部署”，或使用快捷键 \`Control + Option + \`\`。

## 自定义配置

鼠须管的配置文件位于 `~/Library/Rime` 目录下。

输入方案通过 `default.yaml` 配置，如下：

```yaml
schema_list:
  - schema: luna_pinyin_simp
  - schema: double_pinyin_flypy
  - schema: double_pinyin
  - schema: numbers
```
候选词数量可通过如下设置修改：

```yaml
menu/page_size: 9
```

中英文切换键配置如下：

```yaml
ascii_composer/good_old_caps_lock: true
ascii_composer/switch_key:
  Caps_Lock: commit_code
  Shift_L: commit_code
  Shift_R: commit_code
  Control_L: noop
  Control_R: noop
```

短语自定义文件为 `custom_phrase.txt`，格式如下：

```text
Rime	rime	4
鼠须管	rime	3
```

在`rime_hydraallen.dict.yaml`中添加自定义词典，格式如下：

```yaml
import_tables:
  - cn_dicts/8105     # 字表
  # - cn_dicts/41448  # 大字表（按需启用）（启用时和 8105 同时启用并放在 8105 下面）
  - cn_dicts/base     # 基础词库
  - cn_dicts/ext      # 扩展词库
  - cn_dicts/tencent  # 腾讯词向量（大词库，部署时间较长）
  - cn_dicts/others   # 一些杂项
```

在`rime_hydraallen.schema.yaml`中添加自定义输入方案，格式如下：

```yaml
switches:
  - name: ascii_mode
    states: [ 中, Ａ ]
  - name: ascii_punct  # 中英标点
    states: [ ¥, $ ]
  - name: traditionalization
    states: [ 简, 繁 ]
  - name: emoji
    states: [ 💀, 😄 ]
    reset: 1
  - name: full_shape
    states: [ 半角, 全角 ]
  - name: search_single_char  # search.lua 的功能开关，辅码查词时是否单字优先
    states: [正常, 单字]
    abbrev: [词, 单]
```

在`squirrel.yaml`中添加自定义配置，格式如下：

```yaml
app_options:
  # com.apple.Spotlight:
  #   ascii_mode: true    # 开启默认英文
  com.microsoft.VSCode:
    ascii_mode: true    # 开启默认英文
  com.apple.Terminal:
    ascii_mode: true    # 开启默认英文
  com.apple.kitty:
    ascii_mode: true    # 开启默认英文
```


## References
This repo is forked from [iDvel/rime-ice](https://github.com/iDvel/rime-ice).