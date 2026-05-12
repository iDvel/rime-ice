-- 输入单字符 'v' 时，在候选首位插入一条提示候选项，列出常用的
-- v 模式 symbols 触发码（jz 夹注 / bd 标点 / sx 数学 / jt 箭头 ...）。
-- 帮助新用户回忆雾凇 v 模式所提供的反查类目，无需翻 symbols_v.yaml。
--
-- 候选项的 text 为 'v'，hint 文案放在 comment 字段（灰色辅助文）；
-- 不会自动提交，万一被误选也只插入一个 'v'，无破坏性副作用。
--
-- 用 lua_filter 而非 lua_translator 的原因：librime 在短拼音段被
-- script_translator 完整消费后会跳过后续 lua_translator；filter 在
-- 候选流出口运行，不受该路径优化影响。

local function v_hint_filter(input, env)
    local code = env.engine.context.input
    if code == "v" then
        local seg = env.engine.context.composition:back()
        if seg then
            local hint = "jz夹注 bd标点 sx数学 jt箭头 a/o/e/i/u声调 0-10数字"
            local cand = Candidate("v_hint", seg.start, seg._end, "v", hint)
            cand.quality = 9999
            yield(cand)
        end
    end
    for cand in input:iter() do
        yield(cand)
    end
end

return v_hint_filter
