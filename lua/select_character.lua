-- 以词定字
-- 来源 https://github.com/BlindingDark/rime-lua-select-character
-- 删除了默认按键 [ ]，和方括号翻页冲突，需要在 key_binder 下指定才能生效
-- 20230526184754 不再错误地获取commit_text，而是直接获取get_selected_candidate().text。
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

local function select_character(key, env)
    -- local first_key = engine.schema.config:get_string('key_binder/select_first_character') or 'bracketleft'
    -- local last_key = engine.schema.config:get_string('key_binder/select_last_character') or 'bracketright'
    local first_key = engine.schema.config:get_string('key_binder/select_first_character')
    local last_key = engine.schema.config:get_string('key_binder/select_last_character')

    if(key:repr() == first_key)then
        local slct_text = env.engine.context:get_selected_candidate().text
        if(slct_text)then
            env.engine:commit_text(utf8_sub(slct_text, 1, 1))
            env.engine.context:clear()

        return 1 -- kAccepted
    end

    if(key:repr() == last_key)then
        local slct_text = env.engine.context:get_selected_candidate().text
        if(slct_text)then
            env.engine:commit_text(utf8_sub(slct_text, 1, 1))
            env.engine.context:clear()

        return 1 -- kAccepted
    end

    return 2 -- kNoop
end

return select_character
