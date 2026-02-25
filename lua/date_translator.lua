-- 日期时间，可在方案中配置触发关键字。

-- 提高权重的原因：因为在方案中设置了大于 1 的 initial_quality，导致 rq sj xq dt ts 产出的候选项在所有词语的最后。
local function yield_cand(seg, text)
    local cand = Candidate('', seg.start, seg._end, text, '')
    cand.quality = 100
    yield(cand)
end

local M = {}

function M.init(env)
    local config = env.engine.schema.config
    env.name_space = env.name_space:gsub('^*', '')
    M.date = config:get_string(env.name_space .. '/date') or 'rq'
    M.time = config:get_string(env.name_space .. '/time') or 'sj'
    M.week = config:get_string(env.name_space .. '/week') or 'xq'
    M.datetime = config:get_string(env.name_space .. '/datetime') or 'dt'
    M.timestamp = config:get_string(env.name_space .. '/timestamp') or 'ts'
    M.date_en = config:get_string(env.name_space .. '/dateen') or 'rqen'
end

function M.func(input, seg, env)
    -- 日期
    if (input == M.date) then
        local current_time = os.time()
        yield_cand(seg, os.date('%Y-%m-%d', current_time))
        yield_cand(seg, os.date('%Y/%m/%d', current_time))
        yield_cand(seg, os.date('%Y.%m.%d', current_time))
        yield_cand(seg, os.date('%Y%m%d', current_time))
        yield_cand(seg, os.date('%Y年%m月%d日', current_time):gsub('年0', '年'):gsub('月0', '月'))

        -- 时间
    elseif (input == M.time) then
        local current_time = os.time()
        yield_cand(seg, os.date('%H:%M', current_time))
        yield_cand(seg, os.date('%H:%M:%S', current_time))

        -- 星期
    elseif (input == M.week) then
        local current_time = os.time()
        local week_tab = { '日', '一', '二', '三', '四', '五', '六' }
        local text = week_tab[tonumber(os.date('%w', current_time) + 1)]
        yield_cand(seg, '星期' .. text)
        yield_cand(seg, '礼拜' .. text)
        yield_cand(seg, '周' .. text)

        -- ISO 8601/RFC 3339 的时间格式 （固定东八区）（示例 2022-01-07T20:42:51+08:00）
    elseif (input == M.datetime) then
        local current_time = os.time()
        yield_cand(seg, os.date('%Y-%m-%dT%H:%M:%S+08:00', current_time))
        yield_cand(seg, os.date('%Y-%m-%d %H:%M:%S', current_time))
        yield_cand(seg, os.date('%Y%m%d%H%M%S', current_time))

        -- 时间戳（十位数，到秒，示例 1650861664）
    elseif (input == M.timestamp) then
        local current_time = os.time()
        yield_cand(seg, string.format('%d', current_time))

        -- 英文日期
    elseif (input == M.date_en) then
        local current_time = os.time()
        local day = tonumber(os.date("%d", current_time))
        local month = tonumber(os.date("%m", current_time))
        local year = os.date("%Y", current_time)
        -- 月份名称表
        local month_names_short = {"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}
        local month_names_long = {"January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"}
        -- 计算日期序数后缀
        local suffix = "th"
        if day % 10 == 1 and day ~= 11 then suffix = "st"
        elseif day % 10 == 2 and day ~= 12 then suffix = "nd"
        elseif day % 10 == 3 and day ~= 13 then suffix = "rd"
        end
        -- 生成两种格式
        local date_short = string.format("%d%s %s %s", day, suffix, month_names_short[month], year)
        local date_long  = string.format("%d%s %s %s", day, suffix, month_names_long[month], year)
        
        yield_cand(seg, date_short)
        yield_cand(seg, date_long)
    end

    -- -- 显示内存
    -- local cand = Candidate("date", seg.start, seg._end, ("%.f"):format(collectgarbage('count')), "")
    -- cand.quality = 100
    -- yield(cand)
    -- if input == "xxx" then
    --     collectgarbage()
    --     local cand = Candidate("date", seg.start, seg._end, "collectgarbage()", "")
    --     cand.quality = 100
    --     yield(cand)
    -- end
end

return M
