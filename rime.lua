-- Rime lua 扩展：https://github.com/hchunhui/librime-lua
-------------------------------------------------------------
-- 日期时间
-- 提高权重的原因：因为在方案中设置了大于 1 的 initial_quality，导致 rq sj xq dt ts 产出的候选项在所有词语的最后。
function date_translator(input, seg, env)
	local config = env.engine.schema.config
	local date = config:get_string(env.name_space .."/date") or "rq"
	local time = config:get_string(env.name_space .."/time") or "sj"
	local week = config:get_string(env.name_space .."/week") or "xq"
	local datetime = config:get_string(env.name_space .."/datetime") or "dt"
	local timestamp = config:get_string(env.name_space .."/timestamp") or "ts"
    -- 日期
    if (input == date) then
        local cand = Candidate("date", seg.start, seg._end, os.date("%Y-%m-%d"), "")
        cand.quality = 100
        yield(cand)
        local cand = Candidate("date", seg.start, seg._end, os.date("%Y/%m/%d"), "")
        cand.quality = 100
        yield(cand)
        local cand = Candidate("date", seg.start, seg._end, os.date("%Y.%m.%d"), "")
        cand.quality = 100
        yield(cand)
        local cand = Candidate("date", seg.start, seg._end, os.date("%Y 年 %m 月 %d 日"), "")
        cand.quality = 100
        yield(cand)
    end
    -- 时间
    if (input == time) then
        local cand = Candidate("time", seg.start, seg._end, os.date("%H:%M"), "")
        cand.quality = 100
        yield(cand)
        local cand = Candidate("time", seg.start, seg._end, os.date("%H:%M:%S"), "")
        cand.quality = 100
        yield(cand)
    end
    -- 星期
    if (input == week) then
        local weakTab = {'日', '一', '二', '三', '四', '五', '六'}
        local cand = Candidate("week", seg.start, seg._end, "星期" .. weakTab[tonumber(os.date("%w") + 1)], "")
        cand.quality = 100
        yield(cand)
		local cand = Candidate("week", seg.start, seg._end, "礼拜" .. weakTab[tonumber(os.date("%w") + 1)], "")
        cand.quality = 100
        yield(cand)
        local cand = Candidate("week", seg.start, seg._end, "周" .. weakTab[tonumber(os.date("%w") + 1)], "")
        cand.quality = 100
        yield(cand)
    end
    -- ISO 8601/RFC 3339 的时间格式 （固定东八区）（示例 2022-01-07T20:42:51+08:00）
    if (input == datetime) then
        local cand = Candidate("datetime", seg.start, seg._end, os.date("%Y-%m-%dT%H:%M:%S+08:00"), "")
        cand.quality = 100
        yield(cand)
        local cand = Candidate("time", seg.start, seg._end, os.date("%Y%m%d%H%M%S"), "")
        cand.quality = 100
        yield(cand)
    end
    -- 时间戳（十位数，到秒，示例 1650861664）
    if (input == timestamp) then
        local cand = Candidate("datetime", seg.start, seg._end, os.time(), "")
        cand.quality = 100
        yield(cand)
    end
end
-------------------------------------------------------------
-- 以词定字
-- https://github.com/BlindingDark/rime-lua-select-character
-- 删除了默认按键，需要在 key_binder（default.custom.yaml）下设置
local function utf8_sub(s, i, j)
    i = i or 1
    j = j or -1

    if i < 1 or j < 1 then
        local n = utf8.len(s)
        if not n then
            return nil
        end
        if i < 0 then
            i = n + 1 + i
        end
        if j < 0 then
            j = n + 1 + j
        end
        if i < 0 then
            i = 1
        elseif i > n then
            i = n
        end
        if j < 0 then
            j = 1
        elseif j > n then
            j = n
        end
    end

    if j < i then
        return ""
    end

    i = utf8.offset(s, i)
    j = utf8.offset(s, j + 1)

    if i and j then
        return s:sub(i, j - 1)
    elseif i then
        return s:sub(i)
    else
        return ""
    end
end

local function first_character(s)
    return utf8_sub(s, 1, 1)
end

local function last_character(s)
    return utf8_sub(s, -1, -1)
end

function select_character(key, env)
    local engine = env.engine
    local context = engine.context
    local commit_text = context:get_commit_text()
    local config = engine.schema.config

    -- local first_key = config:get_string('key_binder/select_first_character') or 'bracketleft'
    -- local last_key = config:get_string('key_binder/select_last_character') or 'bracketright'
    local first_key = config:get_string('key_binder/select_first_character')
    local last_key = config:get_string('key_binder/select_last_character')

    if (key:repr() == first_key and commit_text ~= "") then
        engine:commit_text(first_character(commit_text))
        context:clear()

        return 1 -- kAccepted
    end

    if (key:repr() == last_key and commit_text ~= "") then
        engine:commit_text(last_character(commit_text))
        context:clear()

        return 1 -- kAccepted
    end

    return 2 -- kNoop
end
-------------------------------------------------------------
-- 长词优先（提升「西安」「提案」「图案」「饥饿」等词汇的优先级）
-- 感谢&参考于： https://github.com/tumuyan/rime-melt
-- 修改：不提升英文和中英混输的
function long_word_filter(input, env)
    -- 提升 count 个词语，插入到第 idx 个位置，默认 2、4。
	local config = env.engine.schema.config
	local count = config:get_string(env.name_space .."/count") or 2
    local idx = config:get_string(env.name_space .."/idx") or 4


    local l = {}
    local firstWordLength = 0 -- 记录第一个候选词的长度，提前的候选词至少要比第一个候选词长
    -- local s1 = 0 -- 记录筛选了多少个英语词条(只提升 count 个词的权重，并且对comment长度过长的候选进行过滤)
    local s2 = 0 -- 记录筛选了多少个汉语词条(只提升 count 个词的权重)

    local i = 1
    for cand in input:iter() do
        leng = utf8.len(cand.text)
        if (firstWordLength < 1 or i < tonumber(idx)) then
            i = i + 1
            firstWordLength = leng
            yield(cand)
		-- 不知道这两行是干嘛用的，似乎注释掉也没有影响。
		-- elseif #table > 30 then
		--     table.insert(l, cand)
		-- 注释掉了英文的
		-- elseif ((leng > firstWordLength) and (s1 < 2)) and (string.find(cand.text, "^[%w%p%s]+$")) then
		--     s1 = s1 + 1
		--     if (string.len(cand.text) / string.len(cand.comment) > 1.5) then
		--         yield(cand)
		--     end
		-- 换了个正则，否则中英混输的也会被提升
		-- elseif ((leng > firstWordLength) and (s2 < count)) and (string.find(cand.text, "^[%w%p%s]+$")==nil) then
        elseif ((leng > firstWordLength) and (s2 < tonumber(count))) and (string.find(cand.text, "[%w%p%s]+") == nil) then
            yield(cand)
            s2 = s2 + 1
        else
            table.insert(l, cand)
        end
    end
    for i, cand in ipairs(l) do
        yield(cand)
    end
end
-------------------------------------------------------------
-- 因为英文方案的 initial_quality 大于 1，导致输入「va」时，候选项是「van vain。。。」
-- 单字优先，候选项应改为「ā á ǎ à」
--
-- 不知道这个方法为什么不行啊？？？
-- function v_single_char_first_filter(input)
--     if (string.find(input, "v") == 1 and string.len(input) == 2) then
--         local l = {}
--         for cand in input:iter() do
--             if (utf8.len(cand.text) == 1) then
--                 yield(cand)
--             else
--                 table.insert(l, cand)
--             end
--         end
--         for cand in ipairs(l) do
--             yield(cand)
--         end
--     end
-- end
--
-- 反正是解决了，不知道怎么就解决了，就是最后多一个候选项，没多大影响。
function v_single_char_first_filter(input, seg)
    if (string.find(input, "v") == 1 and string.len(input) == 2) then
        yield(Candidate("", seg.start, seg._end, "", ""))
    end
end
-------------------------------------------------------------
-- iRime 九宫格专用，将输入框的数字转为对应的拼音或英文
function irime_t9_preedit(input, env)
    for cand in input:iter() do
        if (string.find(cand.text, "%w+") ~= nil) then
            cand:get_genuine().preedit = cand.text
        else
            cand:get_genuine().preedit = cand.comment
        end
        yield(cand)
    end
end
-------------------------------------------------------------
-- 限制码长（最多能输入 length_limit 个字符，超过后不再上屏，不设置时默认 100）
-- 参考于：https://github.com/rime/weasel/issues/733
function code_length_limit_processor(key, env)
    local ctx = env.engine.context
    local config = env.engine.schema.config
    -- 限制
    local length_limit = config:get_string(env.name_space) or 100
    if (length_limit ~= nil) then
        if (string.len(ctx.input) > tonumber(length_limit)) then
            -- ctx:clear()
            ctx:pop_input(1) -- 删除输入框中最后个编码字符
            return 1
        end
    end
    -- 放行
    return 2
end
-------------------------------------------------------------
