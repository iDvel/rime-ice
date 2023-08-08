
require('cold_word_drop.string')
require("cold_word_drop.metatable")
-- local puts = require("tools/debugtool")
local drop_list = require("cold_word_drop.drop_words")
local hide_list = require("cold_word_drop.hide_words")
local turndown_freq_list = require("cold_word_drop.turndown_freq_words")
local tbls = {
    ['drop_list'] = drop_list,
    ['hide_list'] = hide_list,
    ['turndown_freq_list'] = turndown_freq_list
}
-- local cold_word_drop = {}


local function get_record_filername(record_type)
    local user_distribute_name = rime_api:get_distribution_name()
    if user_distribute_name == '小狼毫' then
        return string.format("%%APPDATA%%\\Rime\\lua\\cold_word_record\\%s_words.lua", record_type)
    end

    local system = io.popen("uname -s"):read("*l")
    local filename = nil
    -- body
    if system == "Darwin" then
        filename = string.format("%s/Library/Rime/lua/cold_word_drop/%s_words.lua", os.getenv('HOME'), record_type)
    elseif system == "Linux" then
        filename = string.format("%s/.config/ibus/rime/lua/cold_word_drop/%s_words.lua", os.getenv('HOME'), record_type)
    end
    return filename
end

local function write_word_to_file(record_type)
    -- local filename = string.format("%s/Library/Rime/lua/cold_word_drop/%s_words.lua", os.getenv('HOME'), record_type)
    local filename = get_record_filername(record_type)
    local record_header = string.format("local %s_words =\n", record_type)
    local record_tailer = string.format("\nreturn %s_words", record_type)
    local fd = assert(io.open(filename, "w")) --打开
    fd:setvbuf("line")
    fd:write(record_header)                   --写入文件头部
    -- df:flush() --刷新
    local x = string.format("%s_list", record_type)
    local record = table.serialize(tbls[x]) -- lua 的 table 对象 序列化为字符串
    fd:write(record)                        --写入 序列化的字符串
    fd:write(record_tailer)                 --写入文件尾部, 结束记录
    fd:close()                              --关闭
end

local function check_encode_matched(cand_code, word, input_code_tbl, reversedb)
    if #cand_code < 1 and utf8.len(word) > 1 then -- 二字词以上的词条反查, 需要逐个字去反查
        local word_cand_code = string.split(word, "")
        for i, v in ipairs(word_cand_code) do
            -- 如有 `[` 引导的辅助码情况,  去掉引导符及之后的所有形码字符
            local char_code = string.gsub(reversedb:lookup(v), '%[%l%l', '')
            local _char_preedit_code = input_code_tbl[i] or " "
            -- 如有 `[` 引导的辅助码情况,  同上, 去掉之
            local char_preedit_code = string.gsub(_char_preedit_code, '%[%l+', '')
            if not string.match(char_code, char_preedit_code) then
                -- 输入编码串和词条反查结果不匹配(考虑到多音字, 开启了模糊音, 纠错音), 返回false, 表示隐藏这个词条
                return false
            end
        end
    end
    -- 输入编码串和词条反查结果匹配, 返回true, 表示对这个词条降频
    return true
end

local function append_word_to_droplist(ctx, action_type, reversedb)
    local word = ctx.word
    local input_code = ctx.code
    if action_type == 'drop' then
        table.insert(drop_list, word) -- 高亮选中的词条插入到 drop_list
        return true
    end
    local input_code_tbl = string.split(input_code, " ")
    local cand_code = reversedb:lookup(word) or "" -- 反查候选项文字编码
    -- 二字词 的匹配检查, 匹配返回true, 不匹配返回false
    local match_result = check_encode_matched(cand_code, word, input_code_tbl, reversedb)
    local ccand_code = string.gsub(cand_code, '%[%l%l', '')
    -- 如有 `[` 引导的辅助码情况,  去掉引导符及之后的所有形码字符
    local input_str = string.gsub(input_code, '%[%l+', '')
    local input_code_str = table.concat(input_code_tbl, '')
    -- 单字和二字词 的匹配检查, 如果匹配, 降频
    if string.match(ccand_code, input_str) or match_result then
        if turndown_freq_list[word] then
            table.insert(turndown_freq_list[word], input_code_str)
        else
            turndown_freq_list[word] = { input_code_str }
        end
        return 'turndown_freq'
    end

    -- 单字和二字词 如果不匹配 就隐藏
    if not hide_list[word] then
        hide_list[word] = { input_code_str }
        return true
    else
        -- 隐藏的词条如果已经在 hide_list 中, 则将输入串追加到 值表中, 如: ['藏'] = {'chang', 'zhang'}
        if not table.find_index(hide_list[word], input_code_str) then
            table.insert(hide_list[word], input_code_str)
            return true
        else
            return false
        end
    end
end

local function processor(key, env)
    local engine            = env.engine
    local config            = engine.schema.config
    local context           = engine.context
    -- local top_cand_text = context:get_commit_text()
    -- local preedit_code  = context.input
    local preedit_code      = context:get_script_text()
    local turndown_cand_key = config:get_string("key_binder/turn_down_cand") or "Control+j"
    local drop_cand_key     = config:get_string("key_binder/drop_cand") or "Control+d"
    local action_map        = {
        [turndown_cand_key] = 'hide',
        [drop_cand_key] = 'drop'
    }

    -- local schema_id         = config:get_string("schema/schema_id")
    local schema_id         = config:get_string("translator/dictionary") -- 多方案共用字典取主方案名称
    ---@diagnostic disable-next-line: undefined-global
    local reversedb         = ReverseLookup(schema_id)
    if key:repr() == turndown_cand_key or key:repr() == drop_cand_key then
        local cand = context:get_selected_candidate()
        local action_type = action_map[key:repr()]
        local ctx_map = {
            ['word'] = cand.text,
            ['code'] = preedit_code
        }
        local res = append_word_to_droplist(ctx_map, action_type, reversedb)

        context:refresh_non_confirmed_composition() -- 刷新当前输入法候选菜单, 实现看到实时效果
        if type(res) == "boolean" then
            -- 期望被删的词和隐藏的词条写入文件(drop_words.lua, hide_words.lua)
            write_word_to_file(action_type)
        else
            -- 期望 要调整词频的词条写入 turndown_freq_words.lua 文件
            write_word_to_file(res)
        end
        return 1 -- kAccept
    end

    return 2     -- kNoop, 不做任何操作, 交给下个组件处理
end

return processor
