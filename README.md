symbols：全拼 v 开头、双拼大写 V 开头，如 V1 得到 「一, 壹, ¹, ₁, Ⅰ, ⅰ, ①,......」   
拆字反查:uU+拼音，如双拼 uUnqnqnq 得到 「犇」   
拆字辅码：拼音+\`+拆字辅码，如双拼 gv\`fu 得到 「规」   
Unicode：大写 U 开头，如 U62fc 得到「拼」   
数字、金额大写：大写 R 开头，如 R1234 得到「一千二百三十四、壹仟贰佰叁拾肆元整」   
农历指定日期：大写 N 开头，如 N20240210 得到「二〇二四年正月初一」   

# 雾凇拼音

功能齐全，词库体验良好，长期更新修订。

<br>

[Rime Input Method Engine / 中州韵输入法引擎](https://rime.im/) 是一个跨平台的输入法算法框架。

这里是 Rime 的一份配置仓库，用户需要下载各平台对应的前端，并将此配置应用到配置目录。

雾凇拼音提供了一套开箱即用的完整配置，包含输入方案（全拼、常见双拼）、长期维护的开源词库及各项扩展功能。

详细介绍：[Rime 配置：雾凇拼音](https://dvel.me/posts/rime-ice/)

[常见问题](https://github.com/iDvel/rime-ice/issues/133)

[更新日志](./others/CHANGELOG.md)

<br>

## 基本套路

- 简体 | 全拼 | 双拼
- 主要功能
    -   轻量的英文输入，支持中英混输
    -   [优化英文输入体验](https://dvel.me/posts/make-rime-en-better/)
    -   拆字反查（<kbd>uU</kbd>+拼音），拆字辅码（拼音+<kbd>`</kbd>+拆字辅码）
    -   自整理的 Emoji
    -   以词定字（左右中括号：<kbd>[</kbd>、<kbd>]</kbd>）
    -   长词优先
    -   Unicode（<kbd>U</kbd>+Unicode 码位）
    -   数字、人民币大写（<kbd>R</kbd>+数字）
    -   日期、时间、星期（详见方案 `/date_translator` 节点）
    -   农历（转写：<kbd>N</kbd>+八位数字；获取当前农历：全拼<kbd>nl</kbd>，双拼<kbd>lunar</kbd>）
    -   常见错音错字提示
    -   置顶候选项（详见方案 `/pin_cand_filter` 节点）
    -   所有标点符号直接上屏
    -   特殊符号、字符输入（全拼<kbd>v</kbd>+首字母缩写；双拼<kbd>V</kbd>+首字母缩写）
    -   拼音纠错（模糊音）
    -   更多默认未启用的功能请参考 `rime.lua` 文件以及方案注释
- 简体字表、词库
    -   [通用规范汉字表](https://github.com/iDvel/The-Table-of-General-Standard-Chinese-Characters)（by 中华人民共和国教育部）8K 常用汉字
    -   [Unihan 字库](https://www.unicode.org/Public/)（by Unicode lnc | [UNICODE LICENSE V3](https://www.unicode.org/license.txt)）40K 大字库， **默认未启用**
    -   [现代汉语常用词表](https://zh.wikipedia.org/wiki/%E7%8E%B0%E4%BB%A3%E6%B1%89%E8%AF%AD%E5%B8%B8%E7%94%A8%E8%AF%8D%E8%A1%A8)（by 中国国家语言文字工作委员会）
    -   [华宇野风词库](http://bbs.pinyin.thunisoft.com/forum.php?mod=viewthread&tid=30049)（by 野风）
    -   [简化字八股文](https://github.com/rime/rime-essay-simp)（by rime | [LGPL](https://github.com/rime/rime-essay-simp/blob/master/LICENSE)）
    -   [清华大学开源词库](https://github.com/thunlp/THUOCL)（by THUNLP | [MIT](https://github.com/thunlp/THUOCL/blob/master/LICENSE)）
    -   [腾讯词向量](https://ai.tencent.com/ailab/nlp/en/download.html)（@Huandeep [整理](https://github.com/iDvel/rime-ice/issues/24) | by Tencent AI Lab | [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/)）
- 词库修订
    - 校对大量异形词、错别字、错误注音
    - 全词库完成注音
    - 同义多音字注音
    - 参考
      -   《现代汉语词典》
      -   《同义词词林》
      -   《新华成语大词典》
      -   [校对标准论坛](http://www.jiaodui.com/bbs/)
- Rime、Squirrel、Weasel 常用配置项的详尽注释

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

欢迎在词库方面提 issue [#666](https://github.com/iDvel/rime-ice/issues/666) ，我会及时更新修正。

<br>
