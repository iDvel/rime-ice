-- 九宫格专用
-- 拼写规则通过 xlit 转写： xlit/abcdefghijklmnopqrstuvwxyz/22233344455566677778889999/
-- 然后通过此 Lua 将输入框的数字转为对应的拼音或英文
local function t9_preedit(input, env)
    for cand in input:iter() do
        if (string.find(cand.text, "%w+") ~= nil) then
            cand:get_genuine().preedit = cand.text
        else
            cand:get_genuine().preedit = cand.comment
        end
        yield(cand)
    end
end

return t9_preedit
