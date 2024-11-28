-- Copyright (C) [Mirtle](https://github.com/mirtlecn)
-- License: CC BY-SA 4.0 (https://creativecommons.org/licenses/by-sa/4.0/)
-- 使用说明：<https://github.com/mirtlecn/rime-radical-pinyin/blob/master/search.lua.md>
-- 处理 lua 中的特殊字符用于匹配
local function alt_lua_punc( s )
    if s then
        return s:gsub( '([%.%+%-%*%?%[%]%^%$%(%)%%])', '%%%1' )
    else
        return ''
    end
end

-- 获取指定字符在文本中的位置
local function get_pos( text, char )
    local pos = {}
    if text:find( char ) then
        local tmp = text
        for i = 1, utf8.len( tmp ) do
            local first_char = tmp:sub( 1, utf8.offset( tmp, 2 ) - 1 )
            if first_char == char then pos[i] = true end
            tmp = tmp:gsub( '^' .. first_char, '' )
            i = i + 1
        end
    end
    return pos
end

-- 此函数用于手动写入用户词库，目前仅对双拼有效
local function update_dict_entry( s, code, mem, proj )
    if #s == 0 or utf8.len( s ) == #s or (#code % 2 ~= 0) then
        log.info( '[search.lua]: Ignored' .. s )
        return 0
    end
    local e = DictEntry()
    s = s:gsub( '^%s+', '' ):gsub( '%s+$', '' )
    e.text = s

    local pos = {}
    if s:find( '·' ) and (utf8.len( s ) > 1) then pos = get_pos( s, '·' ) end

    local custom_code = {}
    local loop = 1
    for i = 1, #code, 2 do
        local code_convert = code:sub( i, i + 1 )
        local p = proj:apply( code_convert, true )
        if p and #p > 0 then code_convert = p end
        if code_convert == 'dian' and pos[loop] then
            -- Ignored
        else
            table.insert( custom_code, code_convert )
        end
        loop = loop + 1
    end

    e.custom_code = table.concat( custom_code, ' ' ) .. ' '
    if mem.start_session then mem:start_session() end -- new on librime 2024.05
    mem:update_userdict( e, 1, '' )
    if mem.finish_session then mem:finish_session() end -- new on librime 2024.05
end

-- 通过 schema 的方式查询（以辅码查字，然后对比候选，慢，但能够匹配到算法转换过的码）
-- 查询方案中的匹配项，并返回字表
local function dict_init( search_string, mem, search_limit, code_projection )
    local dict_table = {}
    if code_projection then
        -- old librime(<= 2023.06) do not return original string when apply failed
        local p = code_projection:apply( search_string, true )
        if p and #p > 0 then search_string = p end
    end
    if mem:dict_lookup( search_string, true, search_limit ) then
        for entry in mem:iter_dict() do dict_table[entry.text] = true end
    end
    return dict_table
end

-- 匹配候选
local function dict_match( table, text )
    if table[text] == true then return true end
    return false
end

-- 通过 reverse db 查询（以字查码，然后比对辅码是否相同，快，但只能匹配未经算法转换的码）
local function reverse_lookup( code_projection, db_table, wildcard, text, s, global_match )
    if wildcard then s = s:gsub( wildcard, '.*' ) end
    if code_projection then
        -- old librime do not return original string when apply failed
        local p = code_projection:apply( s, true )
        if p and #p > 0 then s = p end
    end
    -- log.error(s)
    for _, db in ipairs( db_table ) do
        local code = db:lookup( text )
        if code and #code > 0 then
            for part in code:gmatch( '%S+' ) do
                if global_match then
                    if part:find( s ) then return true end
                else
                    if part:find( '^' .. s ) then return true end -- an error pointing at this line. do not know why. so I'll keep an eye.
                end
            end
        end
    end
    return false
end

-- 处理单字优先
local function handle_long_cand( if_single_char_first, cand, long_word_cands )
    if if_single_char_first and utf8.len( cand.text ) > 1 then
        table.insert( long_word_cands, cand )
    else
        yield( cand )
    end
end

local f = {}

function f.init( env )
    local config = env.engine.schema.config
    local ns = 'search'
    env.if_schema_lookup = false
    env.if_reverse_lookup = false

    -- 配置：仅限 script_translator 引擎
    local engine = config:get_list( 'engine/translators' )
    local engine_table = {}
    for i = 0, engine.size - 1 do engine_table[engine:get_value_at( i ).value] = true end
    if not engine_table['script_translator'] then
        log.error( '[search.lua]: script_translator not found in engine/translators, search.lua will not work' )
        return
    end

    -- 配置：辅码查字方法
    -- --
    -- 当在 engine 出直接指定了 namespace 则使用该 namespace 进行 schema 匹配
    -- 当在 search_in_cand 节点下指定了 schema 和 db 则进行相应匹配
    -- 当该节点下 schema 为 0 或者 false，或者不存在时，不进行相应匹配
    -- --
    local schema_name = config:get_string( ns .. '/schema' )
    if not env.name_space:find( '^%*' ) then schema_name = env.name_space end
    if not schema_name or schema_name == 'false' or schema_name == '0' or #schema_name == 0 then goto checkdb end
    env.search = Memory( env.engine, Schema( schema_name ) )
    if schema_name and env.search then
        env.if_schema_lookup = true
        env.search_limit = config:get_int( ns .. '/schema_search_limit' ) or 1000
    end

    ::checkdb::

    local db = config:get_list( ns .. '/db' )
    if db and db.size > 0 then
        env.wildcard = alt_lua_punc( config:get_string( ns .. '/wildcard' ) ) or '*'
        env.db_table = {}
        for i = 0, db.size - 1 do table.insert( env.db_table, ReverseLookup( db:get_value_at( i ).value ) ) end
        env.if_reverse_lookup = true
    end
    if not env.if_reverse_lookup and not env.if_schema_lookup then return end

    -- 配置：辅码转换规则
    -- --
    -- 例如：- xlit/ABCD/1234/ 就可以用 ABCD 来输入 1234（地球拼音音调）
    local fuma_format = config:get_list( ns .. '/fuma_format' )
    if fuma_format and fuma_format.size > 0 then
        env.code_projection = Projection()
        env.code_projection:load( fuma_format )
    else
        env.code_projection = nil
    end

    -- 配置：是否显示不符合辅码的候选
    env.show_other_cands = config:get_bool( ns .. '/show_other_cands' )
    -- 配置：辅码引导符号，默认为反引号 `
    local search_key = config:get_string( 'key_binder/search' ) or config:get_string( ns .. '/key' ) or '`'
    env.search_key_alt = alt_lua_punc( search_key )
    local code_pattern = config:get_string( ns .. '/code_pattern' ) or '[a-z;]'

    -- 配置：seg tag
    local tag = config:get_list( ns .. '/tags' )
    if tag and tag.size > 0 then
        env.tag = {}
        for i = 0, tag.size - 1 do table.insert( env.tag, tag:get_value_at( i ).value ) end
    else
        env.tag = { 'abc' }
    end

    -- 配置：手动写入用户词库
    local rules = config:get_list( ns .. '/input2code_format' )
    if rules and rules.size > 0 then
        env.projection = Projection()
        env.projection:load( rules )
        env.mem = Memory( env.engine, env.engine.schema )
    end

    -- 推入输入历史，并手动（如果设定了按键到编码的转换规则）写入用户词库
    env.commit_notifier = env.engine.context.commit_notifier:connect(
                              function( ctx )
            if env.have_select_commit and env.commit_code then
                local commit_text = ctx:get_commit_text()
                if env.mem then
                    update_dict_entry( commit_text, env.commit_code, env.mem, env.projection )
                end
                ctx.commit_history:push( 'search.lua', commit_text )
                env.have_select_commit = false
            else
                return
            end
        end
                           )

    -- 接管选词逻辑，是词组则始终保留引导码，否则直接上屏
    env.notifier = env.engine.context.select_notifier:connect(
                       function( ctx )
            local input = ctx.input
            local code = input:match( '^(.-)' .. env.search_key_alt )
            if (not code or #code == 0) then return end

            local preedit = ctx:get_preedit()
            local no_search_string = ctx.input:match( '^(.-)' .. env.search_key_alt )
            local edit = preedit.text:match( '^(.-)' .. env.search_key_alt )
            env.have_select_commit = true

            if edit and edit:match( code_pattern ) then
                ctx.input = no_search_string .. search_key
            else
                ctx.input = no_search_string
                env.commit_code = no_search_string
                ctx:commit()
            end
        end
                    )
end

function f.func( input, env )
    -- 当且仅当当输入码中含有辅码引导符号，并有有辅码存在，进入匹配逻辑
    local code, fuma = env.engine.context.input:match( '^(.-)' .. env.search_key_alt .. '(.+)$' )
    if (not code or #code == 0) or (not fuma or #fuma == 0) or (not env.if_reverse_lookup and not env.if_schema_lookup) then
        for cand in input:iter() do yield( cand ) end
        return
    end

    local if_single_char_first = env.engine.context:get_option( 'search_single_char' )
    local dict_table
    local fuma_2
    local other_cand = {}
    local long_word_cands = {}
    if env.if_schema_lookup then dict_table = dict_init( fuma, env.search, env.search_limit, env.code_projection ) end

    if fuma:find( env.search_key_alt ) then fuma, fuma_2 = fuma:match( '^(.-)' .. env.search_key_alt .. '(.*)$' ) end

    for cand in input:iter() do
        if cand.type == 'sentence' then goto skip end

        local cand_text = cand.text
        local text = cand_text
        local text_2 = nil

        -- 当候选多于一个字，则取第一个匹配
        if utf8.len( cand_text ) and utf8.len( cand_text ) > 1 then
            text = cand_text:sub( 1, utf8.offset( cand_text, 2 ) - 1 )
            local cand_text_2 = cand_text:gsub( '^' .. text, '' )
            text_2 = cand_text_2:sub( 1, utf8.offset( cand_text_2, 2 ) - 1 )
        end

        if fuma_2 and #fuma_2 > 0 and env.if_reverse_lookup and not env.if_schema_lookup then
            if -- 第一个辅码匹配第一个字，第二个辅码正则匹配第一个字**或者**匹配第二个字
            reverse_lookup( env.code_projection, env.db_table, env.wildcard, text, fuma ) and
                ((text_2 and reverse_lookup( env.code_projection, env.db_table, env.wildcard, text_2, fuma_2 )) or
                    reverse_lookup( env.code_projection, env.db_table, env.wildcard, text, fuma_2, true )) then
                handle_long_cand( if_single_char_first, cand, long_word_cands )
            else
                table.insert( other_cand, cand )
            end
        else
            if -- 用辅码匹配第一个字
            (env.if_reverse_lookup and reverse_lookup( env.code_projection, env.db_table, env.wildcard, text, fuma )) or
                (env.if_schema_lookup and dict_match( dict_table, text )) then
                handle_long_cand( if_single_char_first, cand, long_word_cands )
            else
                table.insert( other_cand, cand )
            end
        end
        ::skip::
    end

    -- 上屏其余的候选
    for i, cand in ipairs( long_word_cands ) do yield( cand ) end
    if env.show_other_cands then for i, cand in ipairs( other_cand ) do yield( cand ) end end
end

function f.tags_match( seg, env )
    for i, v in ipairs( env.tag ) do if seg.tags[v] then return true end end
    return false
end

function f.fini( env )
    if env.if_reverse_lookup or env.if_schema_lookup then
        env.notifier:disconnect()
        env.commit_notifier:disconnect()
        if env.mem and env.mem.disconnect then env.mem:disconnect() end
        if env.search and env.search.disconnect then env.search:disconnect() end
        if env.mem or env.search or env.db_table then
            env.db_table = nil
            env.mem = nil
            env.search = nil
            collectgarbage( 'collect' )
        end
    end
end

return f
