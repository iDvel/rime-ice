return function(input, env)
    for cand in input:iter() do
        local code = env.engine.context.input -- 输入码
        local text = cand.text                -- 候选词

        -- 输入码结尾大写，候选词转换为大写
        if #code > 2 and code:find("%u$") then
            text = text:upper()
            yield(Candidate(cand.type, 0, #code, text, cand.comment))
        -- 除了输入码结尾大写做转换外，如果原词条包含大写字母，后面的方式将不做任何处理
        elseif text:find("%u") then
            yield(cand)
        -- 输入码前两位大写，候选词转换为全大写
        elseif code:find("^%u%u+.*") then
            text = text:upper()
            yield(Candidate(cand.type, 0, #code, text, cand.comment))
        -- 输入码首位大写，候选词转换为首位大写
        elseif code:find("^%u.*") then
            text = text:sub(1, 1):upper() .. text:sub(2)
            yield(Candidate(cand.type, 0, #code, text, cand.comment))
        -- 其他
        else
            yield(cand)
        end
    end
end
