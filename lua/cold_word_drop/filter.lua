-- 词条隐藏、降频
-- 在 engine/processors 增加 - lua_processor@cold_word_drop.processor
-- 在 engine/filters 增加 - lua_filter@cold_word_drop.filter
-- 在 key_binder 增加快捷键：
-- turn_down_cand: "Control+j"  # 匹配当前输入码后隐藏指定的候选字词 或候选词条放到第四候选位置
-- drop_cand: "Control+d"       # 强制删词, 无视输入的编码
-- get_record_filername() 函数中仅支持了 Windows、macOS、Linux

local filter = {}

function filter.init(env)
	local engine = env.engine
	local config = engine.schema.config
	env.word_reduce_idx = config:get_int("cold_word_reduce/idx") or 4
	env.drop_words = require("cold_word_drop.drop_words") or {}
	env.hide_words = require("cold_word_drop.hide_words") or {}
	env.reduce_freq_words = require("cold_word_drop.reduce_freq_words") or {}
end

function filter.func(input, env)
	local cands = {}
	local context = env.engine.context
	local preedit_str = context.input:gsub(" ", "")
	local drop_words = env.drop_words
	local hide_words = env.hide_words
	local word_reduce_idx = env.word_reduce_idx
	local reduce_freq_words = env.reduce_freq_words
	for cand in input:iter() do
		local cand_text = cand.text:gsub(" ", "")
		local preedit_code = cand.preedit:gsub(" ", "") or preedit_str

		local reduce_freq_list = reduce_freq_words[cand_text] or {}
		if word_reduce_idx > 1 then
			-- 前三个 候选项排除 要调整词频的词条, 要删的(实际假性删词, 彻底隐藏罢了) 和要隐藏的词条
			if reduce_freq_list and table.find_index(reduce_freq_list, preedit_code) then
				table.insert(cands, cand)
			elseif
				not (
					table.find_index(drop_words, cand_text)
					or (hide_words[cand_text] and table.find_index(hide_words[cand_text], preedit_code))

				)
			then
				yield(cand)
				word_reduce_idx = word_reduce_idx - 1
			end
		else
			if
				not (
					table.find_index(drop_words, cand_text)
					or (hide_words[cand_text] and table.find_index(hide_words[cand_text], preedit_code))
				)
			then
				table.insert(cands, cand)
			end
		end

		if #cands >= 180 then
			break
		end
	end

	for _, cand in ipairs(cands) do
		yield(cand)
	end
end

return filter
