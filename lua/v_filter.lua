-- v 模式，单个字符优先
-- 因为设置了英文翻译器的 initial_quality 大于 1，导致输入「va」时，候选项是「van vain …… ā á ǎ à」
-- 把候选项应改为「ā á ǎ à …… van vain」，让单个字符的排在前面
-- 感谢改进 @[t123yh](https://github.com/t123yh) @[Shewer Lu](https://github.com/shewer)
local function v_filter(input, env)
    local code = env.engine.context.input -- 当前编码
    env.v_spec_arr = env.v_spec_arr or Set({"0️⃣", "1️⃣", "2️⃣", "3️⃣", "4️⃣", "5️⃣", "6️⃣", "7️⃣", "8️⃣", "9️⃣","Vs."})
    -- 仅当当前输入以 v 开头，并且编码长度为 2，才进行处理
    if (string.len(code) == 2 and string.find(code, "^v")) then
        local l = {}
        for cand in input:iter() do
            -- 特殊情况处理
            if (env.v_spec_arr[cand.text]) then
                yield(cand)
        	-- 候选项为单个字符的，提到前面来。
            elseif (utf8.len(cand.text) == 1) then
                yield(cand)
            else
                table.insert(l, cand)
            end
        end
        for _, cand in ipairs(l) do
            yield(cand)
        end
    else
        for cand in input:iter() do
            yield(cand)
        end
    end
end

return v_filter
