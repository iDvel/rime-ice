# 雾凇拼音

![demo](./others/demo.webp)

功能齐全，词库体验良好，长期更新修订。

## 基本套路

- 简体全拼
    - 鼠须管 Squirrel 0.15.2
    - 小狼毫 Weasel 0.14.3
- 主要功能
    -   [melt_eng](https://github.com/tumuyan/rime-melt) 英文输入
    -   [两分输入法](http://cheonhyeong.com/Simplified/download.html) 拼字
    -   简繁切换
    -   日期、时间、星期
    -   自整理的 Emoji
    -   [以词定字](https://github.com/BlindingDark/rime-lua-select-character)
    -   [长词优先](https://github.com/tumuyan/rime-melt/blob/master/lua/melt.lua)
    -   所有标点符号直接上屏，「/」模式改为「v」模式，「/」直接上屏
    -   增加了许多拼音纠错
- 简体字表、词库
    -   [《通用规范汉字表》的 8105 字字表](https://github.com/iDvel/The-Table-of-General-Standard-Chinese-Characters)
    -   [华宇野风系统词库](http://bbs.pinyin.thunisoft.com/forum.php?mod=viewthread&tid=30049)
    -   [清华大学开源词库](https://github.com/thunlp/THUOCL)
    -   [《现代汉语常用词表》](https://gist.github.com/indiejoseph/eae09c673460aa0b56db)
    -   [《现代汉语词典》](https://forum.freemdict.com/t/topic/12102)
    -   [《同义词词林》](https://forum.freemdict.com/t/topic/1211)
    -   [《新华成语大词典》](https://forum.freemdict.com/t/topic/11407)
    -   [搜狗网络流行新词](https://pinyin.sogou.com/dict/detail/index/4)
    -   [腾讯词向量](https://ai.tencent.com/ailab/nlp/zh/download.html)
- 词库更新
    - 校对了大量异形词、错别字、错误注音
    - 长期对词库进行更新修订

<br>

## 使用说明

备份后删除配置目录下原有的配置文件，再将仓库所有文件复制粘贴进去就好了。

方案选单呼出快捷键是：Ctrl + Shift + `` ` ``，可在 `default.custom.yaml` 中设置。

<br>

## 长期维护词库

基本所有时间都花在词库上了，精心调教了很多。既然找不到一份比较满意的简体词库，主流输入法又不公开自己的系统词库，干脆自己搞一个。

主要维护的词库：

- `8105` 字表。
- `base` 基础词库。
- `sogou` 搜狗流行词。
- `ext` 扩展词库，小词库。
- `tencent` 扩展词库，大词库。

维护内容主要是异形词、错别字的校对，错误注音的修正，缺失的常用词汇的增添，词频的调整。

欢迎在词库方面提 issue，我会及时更新修正。

<br>

## 感谢

上述用到的词库，及 [@Huandeep](https://github.com/Huandeep) 整理的多个词库。

上述提到的方案及功能参考。

搜狗转 Rime 词库：[lewangdev/scel2txt](https://github.com/lewangdev/scel2txt)

Thanks to JetBrains for the OSS development license.

[![JetBrains](https://resources.jetbrains.com/storage/products/company/brand/logos/jb_beam.svg)](https://jb.gg/OpenSourceSupport)
<br>

---

详细介绍：[雾凇拼音，我的 Rime 配置及新手指引](https://dvel.me/posts/my-rime/)
