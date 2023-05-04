-- 为用户词典中（输入过）的内容结尾加上一个星号 *
local function is_in_user_dict(input, env)
    for cand in input:iter() do
        if (string.find(cand.type, "user")) then
            cand.comment = cand.comment .. '*'
        end
        yield(cand)
    end
end

return is_in_user_dict
