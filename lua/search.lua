-- search.lua
-- Copyright (C) Mirtle <mirtle.cn@outlook.com>
-- Distributed under terms of the MIT license.
-- select_notifier 逻辑取自 AuxFilter

-- 取中文字符的第一个 by ChatGPT
local function getFirstChineseCharacter(str)
    local index = 1
    local byteCount = 0

    while index <= #str do
        local byte = string.byte(str, index)
        local charLen = 1

        if byte >= 0xC0 and byte <= 0xDF then
            charLen = 2
        elseif byte >= 0xE0 and byte <= 0xEF then
            charLen = 3
        elseif byte >= 0xF0 and byte <= 0xF7 then
            charLen = 4
        end

        if charLen > 1 then
            -- Found a multi-byte character
            byteCount = byteCount + 1
            if byteCount == 1 then
                return string.sub(str, index, index + charLen - 1)
            end
        end

        index = index + charLen
    end

    return nil -- No Chinese character found
end

local function alt_lua_punc(s)
    if s then
        return s:gsub("([%.%+%-%*%?%[%]%^%$%(%)%%])", "%%%1")
    else
        return ''
    end
end

local f = {}

-- 逻辑
-- 当在 engine 出直接指定了 namespace 则使用该 namespace 进行 schema 匹配
-- 当在 search_in_cand 节点下指定了 schema 和 db 则进行相应匹配
-- 当该节点下 schema 为 0 或者 false，或者不存在时，不进行相应匹配

function f.init(env)
    local config = env.engine.schema.config
    local ns = 'search'

    f.schema = config:get_string(ns .. '/schema')
    if f.schema == 'false' or f.schema == '0' then
        goto checkdb
    end
    if not env.name_space:find('^%*') then
        f.schema = env.name_space
    end
    if f.schema then
        f.mem = Memory(env.engine, Schema(f.schema))
    end
    f.schema_search_limit = config:get_int(ns .. "/schema_search_limit") or 1000
    ::checkdb::
    f.db = config:get_list(ns .. '/db')
    f.if_schema_lookup = false
    f.if_reverse_lookup = false
    if f.schema and f.mem then
        f.if_schema_lookup = true
        -- log.error('if_schema_lookup: ' .. 'true')
    end
    if f.db then
        f.wildcard = config:get_string(ns .. "/wildcard") or "-"
        f.if_reverse_lookup = true
        -- log.error('if_reverse_lookup: ' .. 'true')
    end

    -- 查找的引导符号需要加入 speller 的字母表当中 
    f.search_key = config:get_string("key_binder/search") or config:get_string(ns .. "/key") or '`'

    -- 处理一下输入码
    f.search_key_string = alt_lua_punc(f.search_key)

    -- 如果不使用任何反查手段，则不接管选词逻辑
    if not f.if_reverse_lookup and not f.if_schema_lookup then
        return
    end

    -- 接管选词逻辑，是词组则始终保留引导码，否则直接上屏
    env.notifier = env.engine.context.select_notifier:connect(function(ctx)
        if not ctx.input:find("^[a-z;]+" .. f.search_key_string) then
            return
        end
        local preedit = ctx:get_preedit()
        local no_search_string = ctx.input:match("^(.-)" .. f.search_key_string)
        -- log.warning('[no_search_string]: '..no_search_string)
        local edit = preedit.text:match('^(.-)' .. f.search_key_string)
        -- log.warning('[edit]: ' .. edit)

        ctx.input = no_search_string

        if edit and edit:match('[a-z;]') then
            ctx.input = ctx.input .. f.search_key
        else
            ctx:commit()
            -- 此种上屏方法似乎无法记录到历史记录中，若需要，可解开下面的代码手动 push
            -- ctx.commit_history:push("user_phrase", edit)
        end
    end)

end

-- 查询反查词典当中的匹配项，并且返回字表
function f.dict_init(search_string)
    local dict_table = {}
    if f.mem:dict_lookup(search_string, true, f.schema_search_limit) then
        for entry in f.mem:iter_dict() do
            -- log.error('text: ' .. entry.text .. ' code: ' .. entry.comment)
            -- table.insert(dict_table, entry.text)
            dict_table[entry.text] = true
            -- dict_table[entry.text] = entry.comment
        end
    end
    return dict_table
end

-- 通过 schema 的方式查询（以码查字，然后轮询匹配，非常慢，但能够匹配到算法转换过的码）
function f.dict_match(table, text)
    -- for i, dict in ipairs(table) do
    --     if text == dict then
    --         return true
    --     end
    -- end
    if table[text] == true then
        return true
    end
    return false
end

-- 通过 reverse db 查询（以字查码，然后比对辅码是否相同，比校快，但只能匹配未经算法转换的码）
function f.reverse_lookup(text, s)
    local list = f.db
    s = s:gsub(f.wildcard, '.*')
    -- log.error(s)
    for i = 0, list.size - 1 do
        local code = ReverseLookup(list:get_value_at(i).value):lookup(text)
        if code:find(' ' .. s) or code:find('^' .. s) then
            return true
        end
    end
    return false
end

function f.func(input, env)
    local input_code = env.engine.context.input
    -- 当且仅当当输入码中含有辅码引导符号，并有有辅码存在，进入匹配逻辑
    -- 当无任何查询方式存在，直接上屏
    if (input_code:find("^[a-z;]+" .. f.search_key_string .. '.+$')) and (f.if_reverse_lookup or f.if_schema_lookup) then
        f.search_string = input_code:match("^.*" .. f.search_key_string .. "(.*)$")
    else
        for cand in input:iter() do
            yield(cand)
        end
        return
    end

    -- 查字时是否单字优先
    local if_single_char_first = env.engine.context:get_option("single_char")

    local dict_table
    if f.if_schema_lookup then
        dict_table = f.dict_init(f.search_string)
    end

    local other_cand = {}
    local other_cand_last = {}

    for cand in input:iter() do
        local type = cand.type -- 类型
        local text = cand.text -- 候选文字
        local comment = cand.comment
        if utf8.len(text) > 1 and if_single_char_first then
            table.insert(other_cand_last, cand)
            goto skip
        end

        -- 处理经过 simplify 转化过的候选，使之能够正确匹配
        if cand:get_dynamic_type() == "Shadow" then
            local originalCand = cand:get_genuine()
            cand = ShadowCandidate(originalCand, originalCand.type, cand.text, cand.comment)
            type = cand.type
            text = cand.text
        end

        -- 只有 script_translator 下的用户词和词才去匹配
        if (type == 'phrase' or type == 'user_phrase') then
            -- 当候选多于一个汉字，则取第一个匹配
            if utf8.len(text) > 1 then
                text = getFirstChineseCharacter(text)
            end
        else
            table.insert(other_cand, cand)
            goto skip
        end

        -- 匹配逻辑
        local match = false
        if f.if_schema_lookup then
            match = f.dict_match(dict_table, text)
            if match then
                yield(cand)
                goto skip
            end
        end

        -- 支持同时指定 schema 查询和 reverse 查询
        if f.if_reverse_lookup then
            match = f.reverse_lookup(text, f.search_string)
            if match then
                yield(cand)
                goto skip
            end
        end

        -- 上屏匹配的候选和插入其余的候选
        if match then
            yield(cand)
        else
            table.insert(other_cand, cand)
        end

        ::skip::
    end
    -- 上屏其余的候选
    for i, cand in ipairs(other_cand) do
        yield(cand)
    end

    for i, cand in ipairs(other_cand_last) do
        yield(cand)
    end
end

function f.fini(env)
    if not f.if_reverse_lookup and not f.if_schema_lookup then
        return
    end
    env.notifier:disconnect()
    -- env.commit_notifier:disconnect()
end

return f