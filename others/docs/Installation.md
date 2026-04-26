# 安装指南

- [要求](#要求)
- [安装](#安装)
  - [手动安装](#手动安装)
  - [Git 安装](#git-安装)
  - [东风破 plum](#东风破-plum)
  - [仓输入法 Hamster](#仓输入法-hamster)
  - [Arch Linux](#arch-linux)（AUR）
  - [Linux Fcitx4](#linux-fcitx4)

## 要求

要使用雾凇拼音，需要

- 您的 Rime 前端提供的 librime 版本 ≥ 1.8.5 且
- 含有 librime-lua 依赖

可参考 [rime/librime](https://github.com/rime/librime#frontends) 查看使用 librime 的前端。

雾凇拼音的部分配置可能要求更高的 librime 或者客户端版本，这些功能已在具体配置文件中注明。

## 安装

> [!IMPORTANT]
> 雾凇拼音官方仅维护手动和 plum 安装方式，其余方式由社区维护，不保证及时更新和兼容性。如遇问题，请在 issue 中反馈。

### 手动安装

将仓库打包下载，或者前往 [Release](https://github.com/iDvel/rime-ice/releases) 界面下载 full.zip，将所有文件复制粘贴到 Rime 前端的配置目录，重新部署即可。

只需要使用或者更新词库的话，可以手动粘贴覆盖 `cn_dicts` `en_dicts` `opencc` 三个文件夹。

注意：雾凇拼音中多个文件可能与其他方案同名冲突，如果是新手想一键安装，建议**备份原先配置，清空配置目录**再导入。

如果单独使用词库，注意：`rime_ice.dict.yaml` 下面包含了大写字母，这和配置有些许绑定，可以直接删除，详细说明：[#356](https://github.com/iDvel/rime-ice/issues/356)

### Git 安装

您如果熟悉 git 常用操作，可以使用 git clone 命令将本仓库克隆到对应前端的用户目录。由于本库提交历史较多且更改频繁，添加 `--depth` 参数可以显著减少传输体积。

```bash
git clone https://github.com/iDvel/rime-ice.git Rime --depth 1

# 更新
cd rime/user/path
git pull
```

通过 checkout 命令，您也可以实现更新部分文件的效果。

### 东风破 plum

先根据 /plum/ 说明安装 plum。

<details>
<summary>/plum/ 简易教程</summary>

安装 plum

```bash
# 请先安装 git 和 bash，并加入环境变量
# 请确保和 github.com 的连接稳定
cd ~
git clone https://github.com/rime/plum.git plum
# 卸载 plum 只需要删除 ~/plum 文件夹即可
```

使用 plum

```bash
cd ~/plum
bash rime-install <recipe_name>
```
部分发行版可能需要手动指定安装位置

```bash
# 为 fcitx5 安装
rime_frontend=fcitx5-rime bash rime-install <recipe_name>
```

</details>

然后选择配方（`others/recipes/*.recipe.yaml`）来进行安装或更新。

词库配方只是更新具体词库文件，并不更新 `rime_ice.dict.yaml` 和 `melt_eng.dict.yaml`，因为用户可能会挂载其他词库。如果更新后部署时报错，可能是增、删、改了文件名，需要检查上面两个文件和词库的对应关系。

℞ 安装或更新全部文件

```
bash rime-install iDvel/rime-ice
```

℞ 安装或更新所有词库文件（包含下面三个）

```
bash rime-install iDvel/rime-ice:others/recipes/all_dicts
```

℞ 安装或更新拼音词库文件（`cn_dicts/` 目录内所有文件）

```
bash rime-install iDvel/rime-ice:others/recipes/cn_dicts
```

℞ 安装或更新英文词库文件（`en_dicts/` 目录内所有文件）

```
bash rime-install iDvel/rime-ice:others/recipes/en_dicts
```

℞ 安装或更新 opencc（`opencc/` 目录内所有文件）

```
bash rime-install iDvel/rime-ice:others/recipes/opencc
```

下面这个配方会在 `radical_pinyin.custom.yaml` 和 `melt_eng.custom.yaml` 里将 `speller/algebra` 修改为对应的双拼拼写，选择一个自己使用的双拼作为参数。

℞ 双拼补丁

```
bash rime-install iDvel/rime-ice:others/recipes/config:schema=flypy
bash rime-install iDvel/rime-ice:others/recipes/config:schema=double_pinyin
bash rime-install iDvel/rime-ice:others/recipes/config:schema=mspy
bash rime-install iDvel/rime-ice:others/recipes/config:schema=sogou
bash rime-install iDvel/rime-ice:others/recipes/config:schema=abc
bash rime-install iDvel/rime-ice:others/recipes/config:schema=ziguang
bash rime-install iDvel/rime-ice:others/recipes/config:schema=jiajia
```

℞ 下载特定版本的配置

在仓库后加 `@tag` 即可，例如：

```sh
bash rime-install iDvel/rime-ice@2024.05.21:others/recipes/full
```

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

### Linux Fcitx4

> [!NOTE]
> Fcitx4 于 2024 停止更新。以下安装方式不保证可用性。

执行：

```bash
bash others/fcitx4/install_to_fcitx4.sh
```

如果系统较旧（例如 `librime < 1.8.5` 或缺少 `librime-lua`），可使用兼容模式（禁用 Lua 扩展功能，仅保留基础拼音/词库能力）：

```bash
bash others/fcitx4/install_to_fcitx4.sh --legacy-no-lua
```

说明：默认执行 `bash others/fcitx4/install_to_fcitx4.sh` 时，脚本会自动检测环境；若版本过旧或缺少 `librime-lua`，会自动切换到兼容模式。

兼容模式（`--legacy-no-lua`）会关闭以下 Lua 扩展能力。

兼容模式仍保留：基础拼音输入、词库、`melt_eng` 英文输入、中英混输、简繁切换、Emoji、用户短语。
