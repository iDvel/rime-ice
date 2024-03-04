-- Unicode
-- 复制自： https://github.com/shewer/librime-lua-script/blob/main/lua/component/unicode.lua
-- 示例：输入 U62fc 得到「拼」
-- 触发前缀默认为 recognizer/patterns/unicode 的第 2 个字符，即 U
-- 2024.02.26: 限定编码最大值
local function unicode(input, seg, env)
    -- 获取 recognizer/patterns/unicode 的第 2 个字符作为触发前缀
    env.unicode_keyword = env.unicode_keyword or
        env.engine.schema.config:get_string('recognizer/patterns/unicode'):sub(2, 2)
    if seg:has_tag("unicode") and env.unicode_keyword ~= '' and input:sub(1, 1) == env.unicode_keyword then
        local ucodestr = input:match(env.unicode_keyword .. "(%x+)")
        if ucodestr and #ucodestr > 1 then
            local code = tonumber(ucodestr, 16)
            if code > 0x10FFFF then
                yield(Candidate("unicode", seg.start, seg._end, "数值超限！", ""))
                return
            end
            local text = utf8.char(code)
            yield(Candidate("unicode", seg.start, seg._end, text, string.format("U%x", code)))
            if code < 0x10000 then
                for i = 0, 15 do
                    local text = utf8.char(code * 16 + i)
                    yield(Candidate("unicode", seg.start, seg._end, text, string.format("U%x~%x", code, i)))
                end
            end
        end
    end
end

return unicode
