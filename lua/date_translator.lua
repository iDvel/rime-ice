-- 日期时间
-- 提高权重的原因：因为在方案中设置了大于 1 的 initial_quality，导致 rq sj xq dt ts 产出的候选项在所有词语的最后。
local function yield_cand(seg, text)
    local cand = Candidate('date', seg.start, seg._end, text, '')
    cand.quality = 100
    yield(cand)
end

local function date_translator(input, seg, env)
    if not env.date then
        local config = env.engine.schema.config
        env.name_space = env.name_space:gsub('^*', '')
        env.date = config:get_string(env.name_space .. '/date') or 'rq'
        env.time = config:get_string(env.name_space .. '/time') or 'sj'
        env.week = config:get_string(env.name_space .. '/week') or 'xq'
        env.datetime = config:get_string(env.name_space .. '/datetime') or 'dt'
        env.timestamp = config:get_string(env.name_space .. '/timestamp') or 'ts'
    end

    -- 日期
    if (input == env.date) then
        local current_time = os.time()
        yield_cand(seg, os.date('%Y-%m-%d', current_time))
        yield_cand(seg, os.date('%Y/%m/%d', current_time))
        yield_cand(seg, os.date('%Y.%m.%d', current_time))
        yield_cand(seg, os.date('%Y%m%d', current_time))
        yield_cand(seg, os.date('%Y 年 %m 月 %d 日', current_time):gsub(' 0', ' '))

    -- 时间
	elseif (input == env.time) then
        local current_time = os.time()
        yield_cand(seg, os.date('%H:%M', current_time))
        yield_cand(seg, os.date('%H:%M:%S', current_time))

    -- 星期
    elseif (input == env.week) then
        local current_time = os.time()
        local week_tab = {'日', '一', '二', '三', '四', '五', '六'}
        local text = week_tab[tonumber(os.date('%w', current_time) + 1)]
        yield_cand(seg, '星期' .. text)
        yield_cand(seg, '礼拜' .. text)
        yield_cand(seg, '周' .. text)

    -- ISO 8601/RFC 3339 的时间格式 （固定东八区）（示例 2022-01-07T20:42:51+08:00）
	elseif (input == env.datetime) then
        local current_time = os.time()
        yield_cand(seg, os.date('%Y-%m-%dT%H:%M:%S+08:00', current_time))
        yield_cand(seg, os.date('%Y%m%d%H%M%S', current_time))

    -- 时间戳（十位数，到秒，示例 1650861664）
    elseif (input == env.timestamp) then
        local current_time = os.time()
        yield_cand(seg, string.format('%d', current_time))
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


return date_translator
