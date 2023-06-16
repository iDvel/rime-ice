-- 长词优先（提升「西安」「提案」「图案」「饥饿」等词汇的优先级）
-- 感谢&参考于： https://github.com/tumuyan/rime-melt
-- 修改：不提升英文和中英混输的
local M = {}

function M.init(env)
    -- 提升 count 个词语，插入到第 idx 个位置，默认 2、4。
    local config = env.engine.schema.config
    env.name_space = env.name_space:gsub("^*", "")
    M.idx = config:get_int(env.name_space .. "/idx") or 4
    M.count = config:get_int(env.name_space .. "/count") or 2
end

function M.func(input, env)
    local l = {}
    local firstWordLength = 0 -- 记录第一个候选词的长度，提前的候选词至少要比第一个候选词长
    local done = 0 -- 记录筛选了多少个词条(只提升 count 个词的权重)
    local i = 1
    for cand in input:iter() do
        -- 找到要提升的词
        local leng = utf8.len(cand.text)
        if (firstWordLength < 1 or i < M.idx) then
            i = i + 1
            firstWordLength = leng
            yield(cand)
        elseif ((leng > firstWordLength) and (done < M.count)) and (string.find(cand.text, "[%w%p%s]+") == nil) then
            yield(cand)
            done = done + 1
        else
            table.insert(l, cand)
        end
        -- 找齐了或者 l 太大了，就不找了
        if (done == M.count) or (#l > 50) then
            break
        end
    end
    for _, cand in ipairs(l) do
        yield(cand)
    end
    for cand in input:iter() do
        yield(cand)
    end
end

return M
