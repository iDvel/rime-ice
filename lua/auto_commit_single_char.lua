-- 对于特定的符号，自动上屏
-- 配置，在方案中填写 auto_commit_single_char: '`'
-- 用途示例： `（反引号）被添加到了 speller/alphabet 来响应辅码，如 gan`shuijin 得到「淦」。
--          这样导致在输入单个的 ` 时仍然需要按空格选择一下。
--          因为 ` 只在非开头状态下产生作用，所以我希望输入单个的 ` 时和其他标点一样都直接上屏。

local function auto_commit_single_char(key, env)
	env.char = env.char or env.engine.schema.config:get_string(env.name_space:gsub('^*', ''))

	if not env.engine.context:is_composing()
		and key.keycode > 0x20 and key.keycode < 0x7f
		and string.char(key.keycode) == env.char then
		return 0 -- kRejected
	end

	return 2 -- kNoop
end

return auto_commit_single_char
