-- Copyright (C) Mirtle <mirtle.cn@outlook.com>
-- [CC BY 3.0 DEED](https://creativecommons.org/licenses/by/3.0/deed)

-- 使用说明：<https://github.com/mirtlecn/rime-radical-pinyin/blob/master/search.lua.md>

-- 感谢 [AuxFilter](https://github.com/HowcanoeWang/rime-lua-aux-code/blob/main/lua/aux_code.lua) 提供参考

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

    -- f.mem_main = Memory(env.engine, env.engine.schema)
    -- local rules = config:get_list('preedit_rules')

    -- if rules then
    --     f.projection = Projection()
    --     f.projection:load(rules)
    -- end

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
        f.wildcard = config:get_string(ns .. "/wildcard") or "'"
        f.if_reverse_lookup = true
        -- log.error('if_reverse_lookup: ' .. 'true')
    end

    f.sort = config:get_bool(ns .. "/show_other_cands")

    -- 反引号作为查找的引导符号，需要加入 speller 的字母表当中
    f.search_key = config:get_string("key_binder/search") or config:get_string(ns .. "/key") or '`'

    -- 处理一下输入码，如果还有没有上屏的词，保留辅助码，否则，清除上屏码
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
            -- local t = f.entry()
            -- log.warning(edit .. '|' .. no_search_string)
            -- 手动推入历史记录
            -- ctx.commit_history:push("user_phrase", edit)
            -- 手动写入用户词库
            -- f.update_dict_entry(edit, no_search_string)
        end
    end)
end

-- function f.update_dict_entry(s, code)
--     local codeLen = #code
--     if s == '' or (#code % 2 ~= 0) then
--         log.warning('Ignored!' .. s)
--         return 0
--     end
--     local e = DictEntry()
--     e.text = s
--     local custom_code = {}
--     for i = 1, #code, 2 do
--         local s = code:sub(i, i + 1)
--         local c = f.projection:apply(s, true)
--         table.insert(custom_code, c)
--     end
--     e.custom_code = table.concat(custom_code, " ") .. ' '
--     log.info("[search.lua]: " .. e.text .. ' ' .. e.custom_code)
--     f.mem_main:update_userdict(e, 1, "")
-- end

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
    local if_single_char_first = env.engine.context:get_option("search_single_char")

    local dict_table
    if f.if_schema_lookup then
        dict_table = f.dict_init(f.search_string)
    end

    local other_cand = {}
    local long_word_cands = {}

    for cand in input:iter() do
        local type = cand.type -- 类型
        local text = cand.text -- 候选文字
        local comment = cand.comment
        -- if utf8.len(text) > 1 and if_single_char_first then
        --     table.insert(other_cand_last, cand)
        --     goto skip
        -- end

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
                text = text:sub(1, utf8.offset(text, 2) - 1)
            end
        else
            table.insert(other_cand, cand)
            goto skip
        end

        -- 匹配逻辑
        if (f.if_reverse_lookup and f.reverse_lookup(text, f.search_string)) or
            (f.if_schema_lookup and f.dict_match(dict_table, text)) then
            if if_single_char_first and utf8.len(cand.text) > 1 then
                table.insert(long_word_cands, cand)
            else
                yield(cand)
            end
        else
            table.insert(other_cand, cand)
        end
        ::skip::
    end
    -- 上屏其余的候选
    for i, cand in ipairs(long_word_cands) do
        yield(cand)
    end

    if f.sort then
        for i, cand in ipairs(other_cand) do
            yield(cand)
        end
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
