# 雾凇拼音

![demo](./others/demo.webp)

功能齐全，词库体验良好，长期更新修订。

<br>

[RIME | 中州韵输入法引擎](https://rime.im/) 是一个跨平台的输入法算法框架，这里是 Rime 的一个配置仓库。

用户需要[下载各平台对应的 Rime 发行版](https://rime.im/download/)，并将此配置应用到配置目录。

详细介绍：[Rime 配置：雾凇拼音](https://dvel.me/posts/rime-ice/)

[常见问题](https://github.com/iDvel/rime-ice/issues/133)

<br>

## 基本套路

- 简体 | 全拼 | 双拼
- 主要功能
  - [melt_eng](https://github.com/tumuyan/rime-melt) 英文输入
  - [优化英文输入体验](https://dvel.me/posts/make-rime-en-better/)
  - [两分输入法](http://cheonhyeong.com/Simplified/download.html) 拼字
  - 简繁切换
  - 日期、时间、星期
  - 自整理的 Emoji
  - [以词定字](https://github.com/BlindingDark/rime-lua-select-character)
  - [长词优先](https://github.com/tumuyan/rime-melt/blob/master/lua/melt.lua)
  - [Unicode](https://github.com/shewer/librime-lua-script/blob/main/lua/component/unicode.lua)
  - 所有标点符号直接上屏，/ 模式改为 v 模式，/ 直接上屏
  - 增加了许多拼音纠错
- 简体字表、词库
  - [《通用规范汉字表》](https://github.com/iDvel/The-Table-of-General-Standard-Chinese-Characters)
  - [华宇野风系统词库](http://bbs.pinyin.thunisoft.com/forum.php?mod=viewthread&tid=30049)
  - [清华大学开源词库](https://github.com/thunlp/THUOCL)
  - [《现代汉语常用词表》](https://gist.github.com/indiejoseph/eae09c673460aa0b56db)
  - [《现代汉语词典》](https://forum.freemdict.com/t/topic/12102)
  - [《同义词词林》](https://forum.freemdict.com/t/topic/1211)
  - [《新华成语大词典》](https://forum.freemdict.com/t/topic/11407)
  - [腾讯词向量](https://ai.tencent.com/ailab/nlp/en/download.html)
- 词库修订
  - 校对大量异形词、错别字、错误注音

<br>

## 长期维护词库

因为没有找到一份比较好的词库，干脆自己维护一个。综合了几个不错的词库，精心调教了很多。

主要维护的词库：

- `8105` 字表。
- `base` 基础词库。
- `ext` 扩展词库，小词库。
- `tencent` 扩展词库，大词库。
- Emoji

维护内容主要是异形词、错别字的校对，错误注音的修正，缺失的常用词汇的增添，词频的调整。

欢迎在词库方面提 issue，我会及时更新修正。

<br>

## 使用说明

建议备份原先配置，清空配置目录。

<details>
<summary>手动安装</summary>

将仓库所有文件复制粘贴进去就好了。

更新词库，手动覆盖 `cn_dicts` `en_dcits` `opencc` 三个文件夹。

</details>
<details>
<summary>东风破 <a href="https://github.com/rime/plum">plum</a></summary>

所有配方（`others/recipes/*.recipe.yaml`）只是简单地更新覆盖文件，适合更新词库时使用。后四个配方只是更新词库文件，并不更新 `rime_ice.dict.yaml` 和 `melt_eng.dict.yaml`，因为用户可能会挂载其他词库。如果更新后部署时报错，可能是增、删、改了文件，需要检查上面两个文件和词库的对应关系。

安装或更新：全部文件

```bash
bash rime-install iDvel/rime-ice:others/recipes/full
```

安装或更新：所有词库文件（包含下面三个）

```bash
bash rime-install iDvel/rime-ice:others/recipes/all_dicts
```

安装或更新：拼音词库文件

```bash
bash rime-install iDvel/rime-ice:others/recipes/cn_dicts
```

安装或更新：英文词库文件

```bash
bash rime-install iDvel/rime-ice:others/recipes/en_dicts
```

安装或更新：opencc(emoji)

```bash
bash rime-install iDvel/rime-ice:others/recipes/opencc
```

</details>

<details>
<summary>Arch Linux <a herf="https://github.com/rime/ibus-rime">中州韵</a></summary>

### 安装

使用 AUR helper 安装 [rime-ice](https://aur.archlinux.org/packages/rime-ice) 包即可。

```bash
yay -S rime-ice
```

或者

```bash
paru -S rime-ice
```

yay用户建议开启[开发包更新](https://github.com/Jguer/yay#development-packages-upgrade)

```bash
yay -Y --devel --save
```

### 配置

推荐使用[补丁](https://github.com/rime/home/wiki/CustomizationGuide#%定製指南)的方式启用。

参考下面的配置示例，修改对应输入法框架用户目录（见下）中的 `rime-ice.custom.yaml` 文件

- iBus 为 `$HOME/.config/ibus/rime/`
- Fcitx5 为 `$HOME/.local/share/fcitx5/rime/`

<details>
<summary>default.custom.yaml</summary>

```yaml
patch:
  "menu/page_size": 8
  schema_list:
    - schema: rime_ice
```

</details>
<details>
<summary>rime-ice.custom.yaml</summary>

```yaml
patch:
  key_binder:
    select_first_character: "bracketleft" #[
    select_last_character: "bracketright" #]
  speller/algebra:
    ### 模糊音
    # 声母
    - derive/^([zcs])h/$1/          # z c s → zh ch sh
    - derive/^([zcs])([^h])/$1h$2/  # zh ch sh → z c s
    - derive/^l/n/  # n → l
    - derive/^n/l/  # l → n
    - derive/^f/h/  # …………
    - derive/^h/f/  # …………
    ...(复制[rime_ice.schema.yaml].speller.algebra到这里,注释/取消注释以更改模糊音)
```

</details>

</details>
<br>

## 感谢 ❤️

感谢上述提到的词库、方案及功能参考。

感谢 [@Huandeep](https://github.com/Huandeep) 整理的多个词库。

感谢所有贡献者。

搜狗转 Rime：[lewangdev/scel2txt](https://github.com/lewangdev/scel2txt)

大量参考[校对网](http://www.jiaodui.com/bbs/)。

Thanks to JetBrains for the OSS development license.

[![JetBrains](https://resources.jetbrains.com/storage/products/company/brand/logos/jb_beam.svg)](https://jb.gg/OpenSourceSupport)

<br>

## 赞助 ☕

如果觉得项目不错，可以请 Dvel 吃个煎饼馃子。

<img src="./others/sponsor.webp" alt="请 Dvel 吃个煎饼馃子" width=600 />
