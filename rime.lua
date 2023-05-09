-- Rime Lua 扩展 https://github.com/hchunhui/librime-lua
-- 文档 https://github.com/hchunhui/librime-lua/wiki/Scripting

-- 以词定字
select_character = require("select_character")
-- 日期时间
date_translator = require("date_translator")
-- Unicode
unicode = require("unicode")
-- 为用户词典中（输入过）的内容结尾加上一个星号
is_in_user_dict = require("is_in_user_dict")
-- v 模式 symbols 优先
v_filter = require("v_filter")
-- 降低部分英语单词在候选项的位置
reduce_english_filter = require("reduce_english_filter")
-- 长词优先
long_word_filter = require("long_word_filter")
-- 词条隐藏、降频
cold_word_drop_processor = require("cold_word_drop.processor")
cold_word_drop_filter = require("cold_word_drop.filter")
