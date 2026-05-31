# 安装指南

- [要求](#要求)
- [安装](#安装)
  - [手动安装](#手动安装)
  - [东风破 plum](#东风破-plum)
  - [Git 安装](#git-安装)
  - [仓输入法 Hamster](#仓输入法-hamster)
  - [Arch Linux](#arch-linux)（AUR）
  - [Fcitx5.js](#fcitx5js)
  - [无法使用 lua 的客户端（e.g. Fcitx4）](#linux-fcitx4-或其他无法使用-lua-的客户端)
  - [Fcitx For Android](#fcitx-for-android)

## 要求

雾凇拼音适配当前主流 Rime 客户端，前往 Rime 官网 & app 商店下载最新版客户端即可。

如使用 Linux/Unix 或其他小众客户端，请要注意雾凇拼音需要：

- Rime 客户端提供的 librime 版本 ≥ 1.8.5
- 含有 librime-lua 依赖

你可以参考 [rime/librime](https://github.com/rime/librime#frontends) 选择你 librime 的前端。

雾凇拼音的部分功能可能要求更高的 librime 或者客户端版本，这些功能会在文档中注明。

## 安装

> [!IMPORTANT]
> 雾凇拼音官方仅维护手动和 plum 安装方式，其余方式由社区维护，不保证及时更新和兼容性。如遇问题，请在 issue 中反馈。

### 手动安装

将仓库打包下载，或者前往 [Release](https://github.com/iDvel/rime-ice/releases) 界面下载 full.zip，将所有文件复制粘贴到 Rime 前端的配置目录，重新部署即可。

只需要使用或者更新词库的话，可以手动粘贴覆盖 `cn_dicts` `en_dicts` `opencc` 三个文件夹。

注意：雾凇拼音中多个文件可能与其他方案同名冲突，如果是新手想一键安装，请**备份原先配置，清空配置目录**再导入。

如果单独使用词库，注意：`rime_ice.dict.yaml` 下面包含了大写字母，这和配置有些许绑定，可以直接删除，详细说明：[#356](https://github.com/iDvel/rime-ice/issues/356)

### 东风破 plum

Plum 这是 [Rime 官方](https://github.com/rime/plum) 使用配置管理工具，可以一行命令安装、配置和更新雾凇拼音。

**1. 安装 plum：**

```bash
# 请先安装 git 和 bash，并加入环境变量
# 请确保和 github.com 的连接稳定
cd ~
git clone https://github.com/rime/plum.git plum
# 卸载 plum 只需要删除 ~/plum 文件夹即可
```

plum 的一般用法是：

```bash
cd ~/plum
# 安装配方到官方客户端的 Rime 目录：
bash rime-install {recipe_name}
# 对于非 Squirrel、Weasel 和 iBus 客户端，请通过 rime_dir 变量，手动指定 Rime 用户目录：
rime_dir="$HOME/.local/share/fcitx5/rime" bash rime-install {recipe_name}
```

**2. 安装雾凇拼音配方**

<details>
<summary>℞ 安装或更新全部文件（初次安装先执行这个）</summary>

```bash
bash rime-install iDvel/rime-ice
```

</details>

<details>
<summary>℞ 安装或更新所有词库文件（中文、英文和 Emoji）</summary>

词库配方只是更新具体词库文件，并不更新 `rime_ice.dict.yaml` 和 `melt_eng.dict.yaml`，因为用户可能会挂载其他词库。如果更新后部署时报错，可能是增、删、改了文件名，需要检查上面两个文件和词库的对应关系。

```bash
bash rime-install iDvel/rime-ice:others/recipes/all_dicts
```

</details>

<details>
<summary>℞ 安装或更新中文词库（`cn_dicts/` 目录内所有文件）</summary>

词库配方只是更新具体词库文件，并不更新 `rime_ice.dict.yaml` 和 `melt_eng.dict.yaml`，因为用户可能会挂载其他词库。如果更新后部署时报错，可能是增、删、改了文件名，需要检查上面两个文件和词库的对应关系。

```bash
bash rime-install iDvel/rime-ice:others/recipes/cn_dicts
```

</details>

<details>
<summary>℞ 安装或更新英文词库（`en_dicts/` 目录内所有文件）</summary>

```bash
bash rime-install iDvel/rime-ice:others/recipes/en_dicts
```

</details>

<details>
<summary>℞ 安装或更新 Emoji（`opencc/` 目录内所有文件）</summary>

```bash
bash rime-install iDvel/rime-ice:others/recipes/opencc
```

</details>

<details><summary>℞ 自动双拼补丁（首次安装后执行，后续更新不需要执行）</summary>

这个配方会在 `radical_pinyin.custom.yaml` 和 `melt_eng.custom.yaml` 里将 `speller/algebra` 修改为对应的双拼拼写，选择一个自己使用的双拼作为参数。

```bash
bash rime-install iDvel/rime-ice:others/recipes/config:schema=double_pinyin_flypy
bash rime-install iDvel/rime-ice:others/recipes/config:schema=double_pinyin
bash rime-install iDvel/rime-ice:others/recipes/config:schema=double_pinyin_mspy
bash rime-install iDvel/rime-ice:others/recipes/config:schema=double_pinyin_dsogou
bash rime-install iDvel/rime-ice:others/recipes/config:schema=double_pinyin_abc
bash rime-install iDvel/rime-ice:others/recipes/config:schema=double_pinyin_ziguang
bash rime-install iDvel/rime-ice:others/recipes/config:schema=double_pinyin_jiajia
```

</details>

<details><summary>℞ 添加语法模型（万象语法模型）（首次安装后执行，后续更新不需要执行）</summary>

```bash
bash rime-install iDvel/rime-ice:others/recipes/grammar:schema=rime_ice
bash rime-install iDvel/rime-ice:others/recipes/grammar:schema=double_pinyin_flypy
bash rime-install iDvel/rime-ice:others/recipes/grammar:schema=double_pinyin
bash rime-install iDvel/rime-ice:others/recipes/grammar:schema=double_pinyin_mspy
bash rime-install iDvel/rime-ice:others/recipes/grammar:schema=double_pinyin_dsogou
bash rime-install iDvel/rime-ice:others/recipes/grammar:schema=double_pinyin_abc
bash rime-install iDvel/rime-ice:others/recipes/grammar:schema=double_pinyin_ziguang
bash rime-install iDvel/rime-ice:others/recipes/grammar:schema=double_pinyin_jiajia
```

</details>

<details><summary>℞ 给反查添加音调（首次安装后执行，后续更新不需要执行）</summary>

```bash
bash rime-install iDvel/rime-ice:others/recipes/reverse_tone:schema=rime_ice
bash rime-install iDvel/rime-ice:others/recipes/reverse_tone:schema=double_pinyin_flypy
bash rime-install iDvel/rime-ice:others/recipes/reverse_tone:schema=double_pinyin
bash rime-install iDvel/rime-ice:others/recipes/reverse_tone:schema=double_pinyin_mspy
bash rime-install iDvel/rime-ice:others/recipes/reverse_tone:schema=double_pinyin_dsogou
bash rime-install iDvel/rime-ice:others/recipes/reverse_tone:schema=double_pinyin_abc
bash rime-install iDvel/rime-ice:others/recipes/reverse_tone:schema=double_pinyin_ziguang
bash rime-install iDvel/rime-ice:others/recipes/reverse_tone:schema=double_pinyin_jiajia
```

</details>

<details><summary>℞ 下载特定版本的配置</summary>

在仓库后加 `@tag` 即可，例如：

```sh
bash rime-install iDvel/rime-ice@2024.05.21:others/recipes/full
```

</details>

<details><summary>℞ 移除所有 lua 依赖</summary>

```bash
bash rime-install iDvel/rime-ice:others/recipes/no_lua_schema
```

</details>

### Git 安装

您如果熟悉 git 常用操作，可以使用 git clone 命令将本仓库克隆到对应前端的用户目录。由于本库提交历史较多且更改频繁，添加 `--depth` 参数可以显著减少传输体积。

```bash
git clone https://github.com/iDvel/rime-ice.git Rime --depth 1

# 更新
cd rime/user/path
git pull
```

通过 checkout 命令，您也可以实现更新部分文件的效果。

### 仓输入法 Hamster

参考 [如何导入"雾凇拼音输入方案"](https://github.com/imfuxiao/Hamster/wiki/%E5%A6%82%E4%BD%95%E5%AF%BC%E5%85%A5%22%E9%9B%BE%E6%B7%9E%E6%8B%BC%E9%9F%B3%E8%BE%93%E5%85%A5%E6%96%B9%E6%A1%88%22)

仓输入法目前已内置雾凇拼音。

使用九宫格，需要同时启用九宫格方案（输入方案设置）和九宫格布局（键盘设置 - 键盘布局 - 中文 9 键）。

### Arch Linux

使用 AUR helper 安装 [rime-ice-git](https://aur.archlinux.org/packages/rime-ice-git) 包即可。

```bash
# paru 默认会每次重新评估 pkgver，所以有新的提交时 paru 会自动更新，
# yay 默认未开启此功能，可以通过此命令开启
# yay -Y --devel --save

paru -S rime-ice-git
# yay -S rime-ice-git
```

推荐使用[补丁](https://github.com/rime/home/wiki/Configuration#補靪)的方式启用。

参考下面的配置示例，修改对应输入法框架用户目录（见下）中的 `default.custom.yaml` 文件

- iBus 为 `$HOME/.config/ibus/rime/`
- Fcitx5 为 `$HOME/.local/share/fcitx5/rime/`

<details>
<summary>default.custom.yaml</summary>

```yaml
patch:
  # 仅使用「雾凇拼音」的默认配置，配置此行即可
  __include: rime_ice_suggestion:/
  # 以下根据自己所需自行定义，仅做参考。
  # 针对对应处方的定制条目，请使用 <recipe>.custom.yaml 中配置，例如 rime_ice.custom.yaml
  __patch:
    key_binder/bindings/+:
      # 开启逗号句号翻页
      - { when: paging, accept: comma, send: Page_Up }
      - { when: has_menu, accept: period, send: Page_Down }
```

</details>

### Fcitx5.js

在 Release 界面，下载 fcitx5_rime_js-rime_ice.zip，将配置 zip 目标指向此压缩包即可。

### Linux Fcitx4 或其他无法使用 lua 的客户端

1. 完整安装雾凇拼音后，再使用 plum 配方安装无 lua 配置：

```bash
bash rime-install iDvel/rime-ice:others/recipes/no_lua_schema
```

2. 或者手动将 `others/no_lua_schema/` 目录下的文件粘贴并替换用户目录下文件。

### Fcitx For Android

先下载并安装 `Fcitx For Android app` + `plugin.rime`：

1. 在输入法设置界面里面，点击 `Addons`，启用 Rime 插件，然后返回设置界面，点击 `Input Methods`，添加 Rime 中州韵输入法。
2. 到雾凇拼音 Release 界面下载 `full.zip`。
3. 在文件浏览器导航到：`/storage/emulated/0/Android/data/org.fcitx.fcitx5.android/files/data/`。
4. 文件夹若不存在 `rime` 目录，新建名为 `rime` 的文件夹；如果存在，首次安装请清空该文件夹，后续更新不需要清空。
5. 解压、替换压缩包里面的所有内容到 `rime` 目录下
6. 返回主界面，点击 `Reload Config`，部署完成后，点击 `🌐`，切换为 Rime。
