-- 长词优先（提升「西安」「提案」「图案」「饥饿」等词汇的优先级）
-- 感谢&参考于： https://github.com/tumuyan/rime-melt
-- 不提升包含英文、数字、emoji、假名的候选项

local function isEmoji(text)
	for _, char in utf8.codes(text) do
		if (char >= 0x1F600 and char <= 0x1F64F) or -- Emoticons
			(char >= 0x1F300 and char <= 0x1F5FF) or -- Misc Symbols and Pictographs
			(char >= 0x1F680 and char <= 0x1F6FF) or -- Transport and Map
			(char >= 0x2600 and char <= 0x26FF) or -- Misc symbols
			(char >= 0x2700 and char <= 0x27BF) or -- Dingbats
			(char >= 0xFE00 and char <= 0xFE0F) or -- Variation Selectors
			(char >= 0x1F900 and char <= 0x1F9FF) or -- Supplemental Symbols and Pictographs
			(char >= 0x1F1E6 and char <= 0x1F1FF) then -- Flags (iOS)
			return true
		end
	end
	return false
end

local function containsJapaneseKana(str)
	for _, code in utf8.codes(str) do
		-- 检查平假名的 Unicode 范围（0x3040 至 0x309F）
		if code >= 0x3040 and code <= 0x309F then
			return true
		end
		-- 检查片假名的 Unicode 范围（0x30A0 至 0x30FF）
		if code >= 0x30A0 and code <= 0x30FF then
			return true
		end
	end
	return false
end

local M = {}

function M.init(env)
	-- 提升 count 个词语，插入到第 idx 个位置，默认 2、4。
	local config = env.engine.schema.config
	env.name_space = env.name_space:gsub("^*", "")
	M.count = config:get_int(env.name_space .. "/count") or 2
	M.idx = config:get_int(env.name_space .. "/idx") or 4
end

function M.func(input)
	local l = {}
	local firstWordLength = 0 -- 记录第一个候选词的长度，提前的候选词至少要比第一个候选词长
	local done = 0            -- 记录筛选了多少个词条(只提升 count 个词的权重)
	local i = 1
	for cand in input:iter() do
		local leng = utf8.len(cand.text)
		-- 只以第一个候选项的长度作为参考
		if firstWordLength < 1 then
			firstWordLength = leng
		end
		-- 不处理 M.idx 之前的候选项
		if i < M.idx then
			i = i + 1
			yield(cand)
		-- 长词直接 yield，其余的放到 l 里
		elseif leng <= firstWordLength or cand.text:find("[%a%d]") or containsJapaneseKana(cand.text) or isEmoji(cand.text) then
			table.insert(l, cand)
		else
			yield(cand)
			done = done + 1
		end
		-- 找齐了或者 l 太大了，就不找了，一般前 50 个就够了
		if done == M.count or #l > 50 then
			break
		end
	end
	-- yield l 及后续的候选项
	for _, cand in ipairs(l) do
		yield(cand)
	end
	for cand in input:iter() do
		yield(cand)
	end
end

return M
