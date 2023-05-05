
--[[
librime-lua 样例

调用方法：
在配方文件中作如下修改：
```
  engine:
    ...
    translators:
      ...
      - lua_translator@lua_function3
      - lua_translator@lua_function4
      ...
    filters:
      ...
      - lua_filter@lua_function1
      - lua_filter@lua_function2
      ...
```

其中各 `lua_function` 为在本文件所定义变量名。
--]]

--[[
本文件的后面是若干个例子，按照由简单到复杂的顺序示例了 librime-lua 的用法。
每个例子都被组织在 `lua` 目录下的单独文件中，打开对应文件可看到实现和注解。

各例可使用 `require` 引入。
如：
```
  foo = require("bar")
```
可认为是载入 `lua/bar.lua` 中的例子，并起名为 `foo`。
配方文件中的引用方法为：`...@foo`。

--]]


-- 强制删词，隐藏词条操作的过滤器
cold_word_drop = require('cold_word_drop')
cold_word_drop_filter = cold_word_drop.filter

-- 强制删词，隐藏词组(匹配输入串时) 
cold_word_drop_processor = cold_word_drop.processor


-----------------------------------------------------------------------------------
-- I. translators:

-- datetime_translator: 将 `date`, `rq` ,`week`, `oxq`, `time`, `osj`
-- 翻译为当前日期, 星期, 时间
-- date_translator = require("date")
-- time_translator = require("time")

--[[ date_time = require("date_time")
datetime_translator = date_time.translator ]]

-- number_translator: 将 `/` + 阿拉伯数字 翻译为大小写汉字
-- 详见 `lua/number.lua`
--[[ number = require("number")
number_translator  = number.translator ]]

-- laTex = require("laTex")
-- laTex_translator = laTex.translator


-- 上屏历史记录
--[[ commit_history = require("commit_history")
commit_history_translator = commit_history.translator ]]

-- ---------------------------------------------------------------
-- II. filters:

-- charset_filter: 滤除含 CJK 扩展汉字的候选项
-- charset_comment_filter: 为候选项加上其所属字符集的注释
-- 详见 `lua/charset.lua`
--[[ local charset = require("charset")
charset_withEmoji_filter = charset.filter
charset_comment_filter = charset.comment_filter ]]


-- single_char_filter: 候选项重排序，使单字优先
-- 详见 `lua/single_char.lua`
-- single_char_filter = require("single_char")


-- 英文单词支持首字母大写, 全大写等格式
--[[ engword_autocaps = require("word_autocaps")
engword_autocaps_filter = engword_autocaps.filter ]]


-- 提升1 个中文长词的位置到第二候选, 加入了对提升词的词频计算
-- 除此之外, 对纯英文单词的长词降频
--[[ long_word_up = require("long_word_up")
long_word_up_filter = long_word_up.filter ]]


--  单字和二字词的 全码顶屏(自动上屏)
--[[ top_word_autocommit = require("top_word_autocommit")
top_word_autocommit_filter = top_word_autocommit.filter ]]


-- reverse_lookup_filter: 依地球拼音为候选项加上带调拼音的注释
-- 详见 `lua/reverse.lua`
-- reverse_lookup_filter = require("reverse")

--use wildcard to search code
-- expand_translator = require("expand_translator")

-- ---------------------------------------------------------------
-- III. processors:

-- 以词定字, 附加fix在有引导符`[`时, 不能数字键上屏
--[[ select_char = require("select_char")
select_char_processor = select_char.processor
select_char_translator = select_char.translator ]]


-- switch_processor: 通过选择自定义的候选项来切换开关（以简繁切换和下一方案为例）
-- 详见 `lua/switch.lua`
-- switch_processor = require("switch")


-- 快捷启动应用
--[[ easy_cmd = require("easy_cmd")
easy_cmd_processor = easy_cmd.processor ]]

-- 由lua 導入 engine/下的組件 processor segmentor translator filters
-- 生成一個processor 於自己 schema speller 取得 config
-- processor=Component.Processor(env.engine,"","speller")
-- 生成一每translator 由 luna_pinyin.schema:/translator 取得 translator config

-- tran = Component.Translator(env.engine,Schema('luna_pinyin'),"","script_translator")

-- 配合 test.schema.yaml
--require 'component_test'

