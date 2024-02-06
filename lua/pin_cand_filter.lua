-- 置顶候选项
-- Powered By ChatGPT

local function is_in_list(list, str)
	for i, v in ipairs(list) do
		if v == str then
			return true, i
		end
	end
	return false, 0
end

local M = {}

function M.init(env)
	env.name_space = env.name_space:gsub("^*", "")
	local list = env.engine.schema.config:get_list(env.name_space)
	if not list then return end -- no configuration found -> stop

	-- 如果定义了 'da zhuan' 或 'da zhong' ，会自动生成 'daz' 和 'dazh' 的键。
	-- 然而，如果明确定义了 'da z' 或 'da zh'，则会优先使用这些明确自定义的简码，用 set 来做判断。
	local set = {}
	for i = 0, list.size - 1 do
		local preedit, texts = list:get_value_at(i).value:match("([^\t]+)\t(.+)")
		if #preedit > 0 and #texts > 0 then
			set[preedit:gsub(" ", "")] = true
		end
	end

	-- 遍历要置顶的候选项列表，将其转换为 table 存储到 M.pin_cands
	-- 'l	了 啦' → M.pin_cands["l"] = {"了", "啦"}
	-- 'ta	他 她 它' → M.pin_cands["ta"] = {"他", "她", "它"}
	--
	-- 无空格的键，如 `nihao	你好` → M.pin_cands["nihao"] = {"你好"}
	--
	-- 包含空格的的键，同时生成简码的拼写（最后一个空格后的首字母），如：
	-- 'ni hao	你好 拟好' → M.pin_cands["nihao"] = {"你好", "拟好"}
	--                   → M.pin_cands["nih"] = {"你好", "拟好"}
	--
	-- 如果最后一个空格后以 zh ch sh 开头，额外再生成 zh, ch, sh 的拼写，如：
	-- 'zhi chi	支持' → M.pin_cands["zhichi"] = {"支持"}
	--               → M.pin_cands["zhic"] = {"支持"}
	--               → M.pin_cands["zhich"] = {"支持"}
	--
	-- 如果同时定义了 'da zhuan	大专' 'da zhong	大众'，会生成：
	-- M.pin_cands["dazhuan"] = {"大专"}
	-- M.pin_cands["dazhong"] = {"大众"}
	-- M.pin_cands["daz"] = {"大专", "大众"}  -- 先写的排在前面
	-- M.pin_cands["dazh"] = {"大专", "大众"} -- 先写的排在前面
	--
	-- 如果同时定义了 'da zhuan	大专' 'da zhong	大众' 且明确定义了简码形式 'da z	打字'，会生成：
	-- M.pin_cands["dazhuan"] = {"大专"}
	-- M.pin_cands["dazhong"] = {"大众"}
	-- M.pin_cands["daz"] = {"打字"}          -- 明确定义的优先级更高
	-- M.pin_cands["dazh"] = {"大专", "大众"}  -- 没明确定义的，仍然按上面的方式生成

	M.pin_cands = {}
	for i = 0, list.size - 1 do
		local preedit, texts = list:get_value_at(i).value:match("([^\t]+)\t(.+)")
		if #preedit > 0 and #texts > 0 then
			-- 按照 " > " 或 " " 分割词汇
			local delimiter = "\0"
			if texts:find(" > ") then
				texts = texts:gsub(" > ", delimiter)
			else
				texts = texts:gsub(" ", delimiter)
			end
			-- 按照键生成完整的拼写
			local preedit_no_spaces = preedit:gsub(" ", "")
			M.pin_cands[preedit_no_spaces] = {}
			for text in texts:gmatch("[^" .. delimiter .. "]+") do
				table.insert(M.pin_cands[preedit_no_spaces], text)
			end
			-- 额外处理包含空格的 preedit，增加最后一个拼音的首字母和 zh, ch, sh 的简码
			if preedit:find(" ") then
				local preceding_part, last_part = preedit:match("^(.+)%s(%S+)$")
				if #last_part > 0 then
					-- 生成最后一个拼音的简码拼写（最后一个空格后的首字母），如 ni hao 生成 nih
					local p1 = preceding_part:gsub(" ", "") .. last_part:sub(1, 1)
					-- 只在没有明确定义此简码时才生成，已有的追加，没有的直接赋值
					if not set[p1] then
						if M.pin_cands[p1] ~= nil then
							for text in texts:gmatch("[^" .. delimiter .. "]+") do
								table.insert(M.pin_cands[p1], text)
							end
						else
							M.pin_cands[p1] = M.pin_cands[preedit_no_spaces]
						end
					end
					-- 生成最后一个拼音的 zh, ch, sh 的简码拼写（最后一个空格后以 zh ch sh 开头），如 zhi chi 生成 zhich
					if last_part:match("^[zcs]h") then
						local p2 = preceding_part:gsub(" ", "") .. last_part:sub(1, 2)
						-- 只在没有明确定义此简码时才生成，已有的追加，没有的直接赋值
						if not set[p2] then
							if M.pin_cands[p2] ~= nil then
								for text in texts:gmatch("[^" .. delimiter .. "]+") do
									table.insert(M.pin_cands[p2], text)
								end
							else
								M.pin_cands[p2] = M.pin_cands[preedit_no_spaces]
							end
						end
					end
				end
			end
		end
	end
end

function M.func(input, env)
	-- 当前输入框的 preedit，未经过方案 translator/preedit_format 转换
	-- 输入 nihaoshij 则为 nihaoshij，选择了「你好」后变成 你好shij
	local full_preedit = env.engine.context:get_preedit().text
	-- 非汉字部分的 preedit，如 shij
	local letter_only_preedit = string.gsub(full_preedit, "[^a-zA-Z]", "")
	-- 是否正在选词（已经选择了至少一个字词，如 `你好shij` 这种状态）
	-- local isSelecting = full_preedit ~= letter_only_preedit

	-- If there is no configuration, no filtering will be performed
	if not M.pin_cands or #letter_only_preedit == 0 then
		for cand in input:iter() do yield(cand) end
		return
	end

	local pined = {} -- 提升的候选项
	local others = {} -- 其余候选项
	local pined_count = 0

	for cand in input:iter() do
		local cand_preedit_no_spaces = cand.preedit:gsub(" ", "")

		-- 无关的输入直接 break
		if string.find(letter_only_preedit, "^" .. cand_preedit_no_spaces) == nil then
			yield(cand)
			break
		end

		local texts = M.pin_cands[cand_preedit_no_spaces]

		-- 跳过不需要处理的部分，对后续的候选项排序
		if texts == nil then
			yield(cand)
		else
			-- 给 pined 几个空字符串占位元素，后面直接 pined[idx] = cand 确保 pined 与 texts 顺序一致
			if #pined < #texts then
				for _ = 1, #texts do
					table.insert(pined, '')
				end
			end
			-- 处理简繁转换后的问题
			local cand_text = cand.text
			if cand:get_dynamic_type() == "Shadow" then
				-- handle cands converted by simplifier
				local originalCand = cand:get_genuine()
				if #originalCand.text == #cand_text and not is_in_list({ "↑", "←", "→", "↓", "丶", "✅", "✔", "⭕" }, cand.text) then
					-- 笑|😄 cand_text = 😄; 麼|么 cand_text = 麼;
					cand_text = originalCand.text
				end
			end
			-- 要置顶的放到 pined 中，其余的放到 others
			local ok, idx = is_in_list(texts, cand_text)
			if ok then
				pined[idx] = cand
				pined_count = pined_count + 1
			else
				table.insert(others, cand)
			end
			-- 找齐了或者 others 太大了，就不找了，一般前 5 个就找完了
			if pined_count == #texts or #others > 50 then
				break
			end
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
