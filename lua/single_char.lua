--[[
single_char_filter: 候选项重排序，使单字优先（当键入长度<4，且只使一个单字优先，其它单字正常排序）
--]]

local function filter(input, env)
    local inputKeys = env.engine.context.input

    if (#inputKeys < 4) then
        local l = {}

        for cand in input:iter() do
            if (utf8.len(cand.text) == 1) then
                yield(cand)
                break
            else
                table.insert(l, cand)
            end
        end

        if (#l > 0) then
            for _, cand in ipairs(l) do
                yield(cand)
            end
        end
    end

    for cand in input:iter() do
        yield(cand)
    end
end

return filter