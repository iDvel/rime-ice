-- Rime Lua 扩展 https://github.com/hchunhui/librime-lua
-- 文档 https://github.com/hchunhui/librime-lua/wiki/Scripting

-- processors:

-- 以词定字，可在 default.yaml → key_binder 下配置快捷键，默认为左右中括号 [ ]
select_character = require("select_character")

-- translators:

-- 日期时间，可在方案中配置触发关键字。
date_translator = require("date_translator")

-- 农历，可在方案中配置触发关键字。
lunar = require("lunar")

-- Unicode，U 开头
unicode = require("unicode")

-- 数字、人民币大写，R 开头
number_translator = require("number_translator")

-- filters:

-- 错音错字提示
-- 关闭此 Lua 时，同时需要关闭 translator/spelling_hints，否则 comment 里都是拼音
corrector = require("corrector")

-- v 模式 symbols 优先（全拼）
v_filter = require("v_filter")

-- 自动大写英文词汇
autocap_filter = require("autocap_filter")

-- 降低部分英语单词在候选项的位置，可在方案中配置要降低的模式和单词
reduce_english_filter = require("reduce_english_filter")

-- 默认未启用：

-- 词条置顶
-- 满足左边的 cand.preedit 时，将右边的 cand 按顺序置顶。
-- 在 engine/filters 增加 - lua_filter@pin_cand_filter
-- 在方案里写配置项：
-- pin_cand_filter:
--   - "l	了"
--   - "le	了"
--   - "ta	他 她 它"
--   - "ni hao	你好 拟好"
pin_cand_filter = require("pin_cand_filter")

-- 长词优先（全拼）
-- 在 engine/filters 增加 - lua_filter@long_word_filter
-- 在方案里写配置项:
-- 提升 count 个词语，插入到第 idx 个位置。
-- 示例：将 2 个词插入到第 4、5 个候选项，输入 jie 得到「1接 2解 3姐 4饥饿 5极恶」
-- long_word_filter:
--   count: 2
--   idx: 4
-- 使用请注意：之前有较多网友反应有内存泄漏，优化过一些但还是偶尔有较高的内存，但并不卡顿也不影响性能，重新部署后即正常
-- 如果要启用，建议放到靠后位置，最后一个放 uniquifier，倒数第二个就放 long_word_filter
long_word_filter = require("long_word_filter")

-- 中英混输词条自动空格
-- 在 engine/filters 增加 - lua_filter@cn_en_spacer
cn_en_spacer = require("cn_en_spacer")

-- 英文词条上屏自动空格
-- 在 engine/filters 增加 - lua_filter@en_spacer
en_spacer = require("en_spacer")

-- 九宫格，将输入框的数字转为对应的拼音或英文，iRime 用，Hamster 不需要。
-- 在 engine/filters 增加 - lua_filter@t9_preedit
t9_preedit = require("t9_preedit")

-- 根据是否在用户词典，在 comment 上加上一个星号 *
-- 在 engine/filters 增加 - lua_filter@is_in_user_dict
-- 在方案里写配置项：
-- is_in_user_dict: true     为输入过的内容加星号
-- is_in_user_dict: false    为未输入过的内容加星号
is_in_user_dict = require("is_in_user_dict")

-- 词条隐藏、降频
-- 在 engine/processors 增加 - lua_processor@cold_word_drop_processor
-- 在 engine/filters 增加 - lua_filter@cold_word_drop_filter
-- 在 key_binder 增加快捷键：
-- turn_down_cand: "Control+j"  # 匹配当前输入码后隐藏指定的候选字词 或候选词条放到第四候选位置
-- drop_cand: "Control+d"       # 强制删词, 无视输入的编码
-- get_record_filername() 函数中仅支持了 Windows、macOS、Linux
cold_word_drop_processor = require("cold_word_drop.processor")
cold_word_drop_filter = require("cold_word_drop.filter")
