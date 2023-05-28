return function(input, env)
	local code = env.engine.context.input -- 输入码
	
    for cand in input:iter() do
		local text = cand.text            -- 候选词

		-- 如果原词条包含大写字母，不做任何处理
        if text:find("%u") then
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
