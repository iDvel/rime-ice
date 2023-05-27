-- 大写第一个字符，自动转写小写词条为首字母大写
-- 输入的内容大写前 2 个字符，自动转小写词条为全词大写；以两个大写字母开头的专有名词，需要大写前 3 个字符
-- 参考 melt-eng lua 库 <https://github.com/tumuyan/rime-melt/blob/master/lua/melt.lua#LL109C2-L109C2> 适配更多情况。
local function autocap_filter(input, env)
    if true then
        local commit = env.engine.context:get_commit_text()
        --  if( env.engine.context:get_option("autocap_filter")) then
        for cand in input:iter() do
            local text = cand.text
            -- 不大写词组，防止输入 ACG 大写 Animation Comics Games 等情况
            if (not string.find(text, "%s")) then
                -- 输入三个大写字母，候选单词全部大写，除非候选项也是三大写字母开头。比如说 DEVONthink。这是为了大写 VMware 等专有名词
                -- 换句说话，这个脚本无法自动大写以三个大写英文字母开头的极少数专有名词
                if string.find(commit, "^%u%u%u.*") and not string.find(text, "^%u%u%u.*") then
                    yield(Candidate("cap", 0, string.len(commit), string.upper(text), "" .. string.sub(cand.comment, 3)))
                -- 输入两个大写字母，候选单词全部大写，除非候选项也是两个大写字母开头，比如说 VMware，IPv4 等
                elseif (string.find(commit, "^%u%u.*") and not string.find(text, "^%u%u.*")) then
                    if (string.len(text) == 2) then
                        yield(Candidate("cap", 0, 2, commit, ""))
                    else
                        yield(Candidate("cap", 0, string.len(commit), string.upper(text), "" .. string.sub(cand.comment, 2)))
                    end
                -- 输入一个大写字母，并且候选项不以大写字母开头，将首字母大写
                elseif (string.find(text, "^%l+$") and string.find(commit, "^%u+")) then
                    local suffix = string.sub(text, string.len(commit) + 1)
                    yield(Candidate("cap", 0, string.len(commit), commit .. suffix, "" .. suffix))
                -- 其它情况保持原样
                else
                    yield(cand)
                end
            else
                yield(cand)
            end
        end
    else
        for cand in input:iter() do
            yield(cand)
        end
    end
end

return autocap_filter
