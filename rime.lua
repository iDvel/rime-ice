-- Rime Lua 扩展 https://github.com/hchunhui/librime-lua
-- 文档 https://github.com/hchunhui/librime-lua/wiki/Scripting

select_character = require("select_character")
date_translator = require("date_translator")
unicode = require("unicode")
is_in_user_dict = require("is_in_user_dict")
v_filter = require("v_filter")
reduce_english_filter = require("reduce_english_filter")
long_word_filter = require("long_word_filter")
cold_word_drop_processor = require("cold_word_drop.processor")
cold_word_drop_filter = require("cold_word_drop.filter")
