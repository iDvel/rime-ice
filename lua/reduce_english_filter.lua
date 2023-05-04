-- 降低部分英语单词在候选项的位置
-- https://dvel.me/posts/make-rime-en-better/#短单词置顶的问题
-- 感谢大佬 @[Shewer Lu](https://github.com/shewer) 指点
local function reduce_english_filter(input, env)
    -- load data
    if not env.idx then
        local config = env.engine.schema.config
        env.name_space = env.name_space:gsub("^*", "")
        env.idx = config:get_int(env.name_space .. "/idx") -- 要插入的位置
        env.words = {} -- 要过滤的词
        local list = config:get_list(env.name_space .. "/words")
        for i = 0, list.size - 1 do
            local word = list:get_value_at(i).value
            env.words[word] = true
        end
    end

    -- filter start
    local code = env.engine.context.input
    if env.words[code] then
        local pending_cands = {}
        local index = 0
        for cand in input:iter() do
            index = index + 1
            if string.lower(cand.text) == code then
                table.insert(pending_cands, cand)
            else
                yield(cand)
            end
            if index >= env.idx + #pending_cands - 1 then
                for _, cand in ipairs(pending_cands) do
                    yield(cand)
                end
                break
            end
        end
    end

    -- yield other
    for cand in input:iter() do
        yield(cand)
    end
end

return reduce_english_filter
