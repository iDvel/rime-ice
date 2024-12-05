# 双拼补丁示例

目前配置中有个别功能仍然默认使用全拼拼写：

拼字时，全拼需要输入 `uUshuishuishui` 来打出「淼」，小鹤双拼用户更希望使用 `uUuvuvuv` 来打出。

英文派生规则中，全拼输入 `windowsshi` 即得到「Windows 10」，小鹤双拼用户更希望使用 `windowsui`。

<br>

不能自动适配，需要手动修改一下：

- 英文中部分符号的派生规则：在英文方案文件 `melt_eng.schema.yaml > speller > algebra` 修改为对应的双拼拼写运算

- 部件拆字的拼写规则：在部件拆字方案 `radical_pinyin.schema.yaml > speller > algebra` 修改为对应的双拼拼写运算

<br>

可以参考仓库主页的 README 中使用 plum 一键补丁。

<br>

也可以从此文件夹中直接复制粘贴到配置目录，默认启用的是小鹤的。

