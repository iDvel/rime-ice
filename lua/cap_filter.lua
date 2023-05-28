-- Mirtle, 2023-05-28
--[[
单词, 输入码小写，词组，大写词，非纯英文词 -> 候选项保持原样
SQL Server，APIs，VMware ==

输入码大写 + 小写 -> 候选项首字母大写
Ha -> Have, HAv -> Have

输入码全词大写 -> 候选项全词大写
HA -> HAVE , HAV -> HAVE
--]]
return function(input, env)
    local commit = env.engine.context.input
    local commitLen = commit:len()
    local textPat = "^%u" .. ("%p?%u"):rep(commitLen - 1)
    for cand in input:iter() do
        local text = cand.text
        if
            commit:find("^[%l%p]") or
            text:find("[^%w%p%s]") or
            text:find("%s") or
            text:find(textPat)
        then
            yield(cand)
        else
            if commit == commit:upper() then
                text = text:upper()
            else
                text = text:sub(1, 1):upper() .. text:sub(2)
            end
            yield(Candidate(cand.type, 0, #commit, text, cand.comment))
        end
    end
end
