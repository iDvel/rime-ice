-- 置顶候选项

local function isInList(list, str)
	for i, v in ipairs(list) do
		if v == str then
			return true, i
		end
	end
	return false, 0
end

local M = {}

function M.init(env)
	local config = env.engine.schema.config
	env.name_space = env.name_space:gsub("^*", "")
	-- 遍历要置顶的候选项列表，将其转换为 table 存储到 M.pin_cands
	-- 'ta	他 她 它' → M.pin_cands["ta"] = {"他", "她", "它"},
	-- 'ni hao	你好 拟好' → M.pin_cands["ni hao"] = {"你好", "拟好"}
	local list = config:get_list(env.name_space)
	M.pin_cands = {}
	for i = 0, list.size - 1 do
		local code, texts = list:get_value_at(i).value:match("([^\t]+)\t(.+)")
		if code and texts then
			M.pin_cands[code] = {}
			for text in texts:gmatch("%S+") do
				table.insert(M.pin_cands[code], text)
			end
		end
	end
end

function M.func(input)
	local pined = {}
	local others = {}
	local pined_count = 0
	for cand in input:iter() do
		local pins = M.pin_cands[cand.preedit]
		if pins then
			-- 给 pined 几个空字符串占位元素，后面直接 pined[idx] = cand 确保 pined 与 pins 顺序一致
			if #pined < #pins then
				for _ = 1, #pins do
					table.insert(pined, '')
				end
			end
			-- 要置顶的放到 pined 中，其余的放到 others
			local ok, idx = isInList(pins, cand.text)
			if ok then
				pined[idx] = cand
				pined_count = pined_count + 1
			else
				table.insert(others, cand)
			end
			-- 找齐了或者 others 太大了，就不找了，一般前 5 个就找完了
			if pined_count == #pins or #others > 50 then
				break
			end
		else
			table.insert(others, cand)
			break
		end
	end

	-- yield pined others 及后续的候选项
	if pined_count > 0 then
		-- 如果因配置写了这个编码没有的字词，导致没有找齐，删掉空字符串占位元素
		local i = 1
		while i <= #pined do
			if pined[i] == '' then
				table.remove(pined, i)
			else
				i = i + 1
			end
		end
		for _, cand in ipairs(pined) do
			yield(cand)
		end
	end
	for _, cand in ipairs(others) do
		yield(cand)
	end
	for cand in input:iter() do
		yield(cand)
	end
end

return M
