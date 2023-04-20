-- Rime Lua 扩展 https://github.com/hchunhui/librime-lua
-- 文档 https://github.com/hchunhui/librime-lua/wiki/Scripting
-------------------------------------------------------------
-- 日期时间
-- 提高权重的原因：因为在方案中设置了大于 1 的 initial_quality，导致 rq sj xq dt ts 产出的候选项在所有词语的最后。
function date_translator(input, seg, env)
    local config = env.engine.schema.config
    local date = config:get_string(env.name_space .. "/date") or "rq"
    local time = config:get_string(env.name_space .. "/time") or "sj"
    local week = config:get_string(env.name_space .. "/week") or "xq"
    local datetime = config:get_string(env.name_space .. "/datetime") or "dt"
    local timestamp = config:get_string(env.name_space .. "/timestamp") or "ts"
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
    -- -- 输出内存
    -- local cand = Candidate("date", seg.start, seg._end, ("%.f"):format(collectgarbage('count')), "")
    -- cand.quality = 100
    -- yield(cand)
    -- if input == "xxx" then
    --     collectgarbage()
    --     local cand = Candidate("date", seg.start, seg._end, "collectgarbage()", "")
    --     cand.quality = 100
    --     yield(cand)
    -- end
end
-------------------------------------------------------------
-- 以词定字
-- https://github.com/BlindingDark/rime-lua-select-character
-- 删除了默认按键，需要在 key_binder 下设置
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
    local count = config:get_int(env.name_space .. "/count") or 2
    local idx = config:get_int(env.name_space .. "/idx") or 4

    local code = env.engine.context.input -- 当前编码
    if string.find(code, "[aeo]") then    -- 要提升的词汇的拼音一定是包含 a o e 的
        local l = {}
        local firstWordLength = 0 -- 记录第一个候选词的长度，提前的候选词至少要比第一个候选词长
        local done = 0 -- 记录筛选了多少个词条(只提升 count 个词的权重)
        local i = 1
        for cand in input:iter() do
            -- 找到要提升的词
            local leng = utf8.len(cand.text)
            if (firstWordLength < 1 or i < idx) then
                i = i + 1
                firstWordLength = leng
                yield(cand)
            elseif ((leng > firstWordLength) and (done < count)) and (string.find(cand.text, "[%w%p%s]+") == nil) then
                yield(cand)
                done = done + 1
            else
                table.insert(l, cand)
            end
            -- 找齐了或者 l 太大了，就不找了
            if (done == count) or (#l > 50) then
                break
            end
        end
		-- yield l
        for _, cand in ipairs(l) do
            yield(cand)
        end
		-- l 弄完了立马给丫回收了
		l = nil
        if collectgarbage('count') < 3000 then
            collectgarbage("step")
        else
            collectgarbage('collect')
        end
		-- yield 其他
        for cand in input:iter() do
            yield(cand)
        end
    end

    for cand in input:iter() do
        yield(cand)
    end
end
-------------------------------------------------------------
-- 降低部分英语单词在候选项的位置
-- https://dvel.me/posts/make-rime-en-better/#短单词置顶的问题
-- 感谢大佬 @[Shewer Lu](https://github.com/shewer) 指点
function reduce_english_filter(input, env)
    local config = env.engine.schema.config
    -- load data
    if not env.idx then
        env.idx = config:get_int(env.name_space .. "/idx") -- 要插入的位置
    end
    if not env.words then
        env.words = {} -- 要过滤的词
        local list = config:get_list(env.name_space .. "/words")
        for i = 0, list.size - 1 do
            local word = list:get_value_at(i).value
            env.words[word] = true
        end
    end

    -- filter start
    local code = env.engine.context.input
    if env.words[code] then
        local pending_cands = {}
        local index = 0
        for cand in input:iter() do
            index = index + 1
            if string.lower(cand.text) == code then
                table.insert(pending_cands, cand)
            else
                yield(cand)
            end
            if index >= env.idx + #pending_cands - 1 then
                for _, cand in ipairs(pending_cands) do
                    yield(cand)
                end
                break
            end
        end
    end

    -- yield other
    for cand in input:iter() do
        yield(cand)
    end
end
-------------------------------------------------------------
-- v 模式，单个字符优先
-- 因为设置了英文翻译器的 initial_quality 大于 1，导致输入「va」时，候选项是「van vain …… ā á ǎ à」
-- 把候选项应改为「ā á ǎ à …… van vain」，让单个字符的排在前面
-- 感谢改进 @[t123yh](https://github.com/t123yh) @[Shewer Lu](https://github.com/shewer)
function v_filter(input, env)
    local code = env.engine.context.input -- 当前编码
    env.v_spec_arr = env.v_spec_arr or Set(
        {"0️⃣", "1️⃣", "2️⃣", "3️⃣", "4️⃣", "5️⃣", "6️⃣", "7️⃣", "8️⃣", "9️⃣", "Vs."})
    -- 仅当当前输入以 v 开头，并且编码长度为 2，才进行处理
    if (string.len(code) == 2 and string.find(code, "^v")) then
        local l = {}
        for cand in input:iter() do
            -- 特殊情况处理
            if (env.v_spec_arr[cand.text]) then
                yield(cand)
                -- 候选项为单个字符的，提到前面来。
            elseif (utf8.len(cand.text) == 1) then
                yield(cand)
            else
                table.insert(l, cand)
            end
        end
        for _, cand in ipairs(l) do
            yield(cand)
        end
    else
        for cand in input:iter() do
            yield(cand)
        end
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
-- Unicode 输入
-- 复制自： https://github.com/shewer/librime-lua-script/blob/main/lua/component/unicode.lua
function unicode(input, seg, env)
    local ucodestr = seg:has_tag("unicode") and input:match("U(%x+)")
    if ucodestr and #ucodestr > 1 then
        local code = tonumber(ucodestr, 16)
        local text = utf8.char(code)
        yield(Candidate("unicode", seg.start, seg._end, text, string.format("U%x", code)))
        if #ucodestr < 5 then
            for i = 0, 15 do
                local text = utf8.char(code * 16 + i)
                yield(Candidate("unicode", seg.start, seg._end, text, string.format("U%x~%x", code, i)))
            end
        end
    end
end
-------------------------------------------------------------
