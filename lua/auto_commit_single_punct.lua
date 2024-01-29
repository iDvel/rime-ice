-- 让写在 alphabet 中的某标点自动上屏
-- 配置，在方案中填写 auto_commit_single_punct: '`'
-- 用途示例： `（反引号）被添加到了 speller/alphabet 来响应辅码，如 gan`shuijin 得到「淦」。
--          这样导致在输入单个的 ` 时仍然需要按空格选择一下。
--          因为 ` 只在非开头状态下产生作用，所以我希望输入单个的 ` 时和其他标点一样都直接上屏。

local P = {}

function P.init(env)
	P.punct = env.engine.schema.config:get_string(env.name_space:gsub('^*', ''))
end

function P.func(key, env)
	local context = env.engine.context

	-- 不影响组合键
	if not P.punct or key:release() or key:ctrl() or key:alt() or key:super() or key:shift() then
		return 2 -- kNoop
	end

	local ascii_str = ''
	if key.keycode > 0x20 and key.keycode < 0x7f then
		ascii_str = string.char(key.keycode)
	end

	-- 解开下面三行，将只允许一次辅码上屏（辅码检索时，将会阻止再次输入辅码）
	-- if context.input:find("^[a-z;]+" .. P.char) and ascii_str == P.char then
	-- 	return 1
	-- end

	if not context:is_composing() and ascii_str == P.punct then
		return 0 -- kRejected
	end

	return 2 -- kNoop
end

return P
