-- 日期时间
-- 提高权重的原因：因为在方案中设置了大于 1 的 initial_quality，导致 rq sj xq dt ts 产出的候选项在所有词语的最后。
local formats = {
    date = {
        '%Y-%m-%d',
        '%Y/%m/%d',
        '%Y.%m.%d',
        '%Y%m%d',
    },
    time = {
        '%H:%M',
        '%H:%M:%S'
    },
    datetime = {
        '%Y-%m-%dT%H:%M:%S+08:00',
        '%Y%m%d%H%M%S'
    },
    week = {
        '星期%s',
        '礼拜%s',
        '周%s'
    },
    timestamp = {
        '%d'
    }
}

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

    local current_time = os.time()

    local yield_cand = function(type, text)
        local cand = Candidate(type, seg.start, seg._end, text, '')
        cand.quality = 100
        yield(cand)
    end

    -- 日期
    if (input == env.date) then
        for _, fmt in ipairs(formats.date) do
            yield_cand('date', os.date(fmt, current_time))
        end
		yield_cand('date', os.date('%Y 年 %m 月 %d 日', current_time):gsub(' 0', ' '))
    end
    -- 时间
    if (input == env.time) then
        for _, fmt in ipairs(formats.time) do
          yield_cand('time', os.date(fmt, current_time))
        end
    end
    -- 星期
    if (input == env.week) then
        local week_tab = { '日', '一', '二', '三', '四', '五', '六' }
        for _, fmt in ipairs(formats.week) do
          local text = week_tab[tonumber(os.date('%w', current_time) + 1)]
          yield_cand('week', string.format(fmt, text))
        end
    end
    -- ISO 8601/RFC 3339 的时间格式 （固定东八区）（示例 2022-01-07T20:42:51+08:00）
    if (input == env.datetime) then
        for _, fmt in ipairs(formats.datetime) do
          yield_cand('datetime', os.date(fmt, current_time))
        end
    end
    -- 时间戳（十位数，到秒，示例 1650861664）
    if (input == env.timestamp) then
        for _, fmt in ipairs(formats.timestamp) do
          yield_cand('timestamp', string.format(fmt, current_time))
        end
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
