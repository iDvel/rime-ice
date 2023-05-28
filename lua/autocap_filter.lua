--[[
	#302@abcdefg233  #305@Mirtle

	自动大写英文词汇：
	- 部分规则不做转换
	- 输入首字母大写，候选词转换为首字母大写： Hello → Hello
	- 输入至少前 2 个字母大写，候选词转换为全部大写： HEllo → HELLO
--]]
local function autocap_filter(input, env)
    local code = env.engine.context.input -- 输入码

    for cand in input:iter() do
        local text = cand.text -- 候选词

        -- 不转换的：
        if 
			#code == 1 or  -- 长度为 1
            code:find("^[%l%p]") or  -- 输入码首位为小写字母或标点
            text:find("[^%w%p%s]") or  -- 候选词包含非字母和数字、非标点符号、非空格的字符
            text:find("%s") or  -- 候选词中包含空格
            text:gsub("[%s%-]", ""):find("^" .. code) or -- 输入码完全匹配候选词
			-- 单词与其对应的编码不一致，例如词条 `Photoshop	PS`，输入 PS 的时候，不将 Photoshop 转换为 PHOTOSHOP
			(cand.type ~= "completion" and code:gsub("[%s%-]", ""):lower() ~= text:gsub("[%s%-]", ""):lower())
        then
            yield(cand)

        -- 输入码前 2~10 位大写，候选词转换为全大写
        elseif code:find("^%u%u+.*") then
            text = text:upper()
            yield(Candidate(cand.type, 0, #code, text, cand.comment))

        -- 输入码首位大写，候选词转换为首位大写
        elseif code:find("^%u.*") then
            text = text:sub(1, 1):upper() .. text:sub(2)
            yield(Candidate(cand.type, 0, #code, text, cand.comment))

        else
            yield(cand)
        end
    end
end

return autocap_filter
