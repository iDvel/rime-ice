local drop_list = require("cold_word_drop.drop_words")
local hide_list = require("cold_word_drop.hide_words")
local turndown_freq_list = require("cold_word_drop.turndown_freq_words")

local function filter(input, env)
    local idx = 3 -- 降频的词条放到第三个后面, 即第四位, 可在 yaml 里配置
    local i = 1
    local cands = {}
    local context = env.engine.context
    local preedit_code = context.input

    for cand in input:iter() do
        local cpreedit_code = string.gsub(cand.preedit, ' ', '')
        if (i <= idx) then
            local tfl = turndown_freq_list[cand.text] or nil
            -- 前三个 候选项排除 要调整词频的词条, 要删的(实际假性删词, 彻底隐藏罢了) 和要隐藏的词条
            if not
                ((tfl and table.find_index(tfl, cpreedit_code)) or
                    table.find_index(drop_list, cand.text) or
                    (hide_list[cand.text] and table.find_index(hide_list[cand.text], cpreedit_code))
                )
            then
                i = i + 1
                ---@diagnostic disable-next-line: undefined-global
                yield(cand)
            else
                table.insert(cands, cand)
            end
        else
            table.insert(cands, cand)
        end
        if (#cands > 50) then
            break
        end
    end
    for _, cand in ipairs(cands) do
        local cpreedit_code = string.gsub(cand.preedit, ' ', '')
        if not
            -- 要删的 和要隐藏的词条不显示
            (
                table.find_index(drop_list, cand.text) or
                (hide_list[cand.text] and table.find_index(hide_list[cand.text], cpreedit_code))
            )
        then
            ---@diagnostic disable-next-line: undefined-global
            yield(cand)
        end
    end
    for cand in input:iter() do
        yield(cand)
    end
end

return filter
