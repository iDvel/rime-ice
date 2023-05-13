-- Unicode
-- 示例：输入 U62fc 得到「拼」
-- 复制自： https://github.com/shewer/librime-lua-script/blob/main/lua/component/unicode.lua
local function unicode(input, seg, env)
    local ucodestr = seg:has_tag("unicode") and input:match("U(%x+)")
    if ucodestr and #ucodestr > 1 then
        local code = tonumber(ucodestr, 16)
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

return unicode
