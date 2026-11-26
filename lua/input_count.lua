-- 输入统计插件
-- 区分设备统计输入，不包含敏感数据，输入sS查看。
-- 统计文件保存在配置目录的input_count.txt里
-- 启用方式：在方案的 engine/translators 增加 - lua_translator@*input_count
-- author: https://github.com/Median109


local M = {}

-- ==================== 可配置项 ====================

local command_key = "sS"

-- 留空则自动读取主机名；也可手动指定如 "PC-Win11"、"Arch-Laptop"
local custom_device_name = ""

-- 统计文件名（位于 Rime 用户配置目录下）
local db_filename = "input_count.txt"

-- 速度统计窗口（秒）
local speed_window_sec = 60

-- 自动落盘最小间隔（秒），避免高频上屏时每次都整文件重写
local save_interval_sec = 10

-- ==================== 路径与工具函数 ====================

local cached_db_path = nil
local last_save_time = 0

local function get_device_id()
    if custom_device_name and custom_device_name ~= "" then
        return custom_device_name:gsub("[%[%]\r\n]", "_")
    end
    local host = os.getenv("COMPUTERNAME") or os.getenv("HOSTNAME") or "default"
    host = host:gsub("%s+", "")
    if host == "" then
        host = "default"
    end
    return host:gsub("[%[%]\r\n]", "_")
end

local function join_path(dir, filename)
    if not dir or dir == "" then
        return filename
    end
    local last = dir:sub(-1)
    if last == "/" or last == "\\" then
        return dir .. filename
    end
    if dir:find("\\", 1, true) then
        return dir .. "\\" .. filename
    end
    return dir .. "/" .. filename
end

local function get_db_path(env)
    if cached_db_path then
        return cached_db_path
    end

    local dir = ""
    if type(rime_api) == "table" and type(rime_api.get_user_data_dir) == "function" then
        local ok, d = pcall(rime_api.get_user_data_dir)
        if ok and type(d) == "string" and d ~= "" then
            dir = d
        end
    end

    if dir == "" and env then
        local d = env.user_data_dir or (env.engine and env.engine.user_data_dir)
        if type(d) == "string" and d ~= "" then
            dir = d
        end
    end

    cached_db_path = join_path(dir, db_filename)
    return cached_db_path
end

local function format_count(n)
    local num = tonumber(n) or 0
    local function trunc(v, digits)
        local p = 10 ^ digits
        return math.floor(v * p) / p
    end
    if num < 1000 then
        return string.format("%d", math.floor(num))
    elseif num < 10000 then
        return string.format("%.2f千", trunc(num / 1000, 2))
    else
        return string.format("%.2f万", trunc(num / 10000, 2))
    end
end

local function utf8_len(text)
    if not text or text == "" then
        return 0
    end
    local _, count = text:gsub("[^\128-\193]", "")
    return count
end

-- 原地清理过期时间戳，减少无意义的整表拷贝
local function trim_timestamps(arr, now, window_sec)
    if not arr or #arr == 0 then
        return {}
    end
    local cutoff = now - window_sec
    local write_idx = 1
    for i = 1, #arr do
        if arr[i] >= cutoff then
            arr[write_idx] = arr[i]
            write_idx = write_idx + 1
        end
    end
    for i = write_idx, #arr do
        arr[i] = nil
    end
    return arr
end

local function calc_rate_per_min(arr, now, window_sec)
    if not arr or #arr < 2 then
        return 0
    end
    local cutoff = now - window_sec
    local first_ts = nil
    local count = 0
    for i = 1, #arr do
        if arr[i] >= cutoff then
            if not first_ts then
                first_ts = arr[i]
            end
            count = count + 1
        end
    end
    if count < 2 or not first_ts then
        return 0
    end
    local span = now - first_ts
    if span < 5 then
        span = 5
    end
    return (count / span) * 60
end

local function trim_commit_events(events, now, window_sec)
    if not events or #events == 0 then
        return {}
    end
    local cutoff = now - window_sec
    local write_idx = 1
    for i = 1, #events do
        if events[i].t >= cutoff then
            events[write_idx] = events[i]
            write_idx = write_idx + 1
        end
    end
    for i = write_idx, #events do
        events[i] = nil
    end
    return events
end

local function calc_commit_wpm(events, now, window_sec)
    if not events or #events == 0 then
        return 0
    end
    local cutoff = now - window_sec
    local total_chars = 0
    local earliest = nil
    for i = 1, #events do
        local ev = events[i]
        if ev.t >= cutoff then
            total_chars = total_chars + (ev.chars or 0)
            if not earliest or ev.t < earliest then
                earliest = ev.t
            end
        end
    end
    if total_chars <= 0 or not earliest then
        return 0
    end
    local span = now - earliest
    if span < 5 then
        span = 5
    end
    return (total_chars / span) * 60
end

-- ==================== 单文件解析与合并保存 ====================

local function new_device_record(dev_id, today, now_iso)
    return {
        device = dev_id,
        start_iso = now_iso,
        total_words = 0,
        total_keys = 0,
        edit_count = 0,
        day_edit_count = 0,
        day = today,
        day_words = 0,
        day_keys = 0,
        last_code = "",
        history = {},
    }
end

-- 解析 input_count.txt 中所有设备段落；兼容旧版无 [device:...] 头部的单机格式
local function parse_all_devices_from_file(path, fallback_dev)
    local devices = {}
    local today = os.date("%Y%m%d")
    local now_iso = os.date("%Y-%m-%d %H:%M:%S")

    local f = io.open(path, "r")
    if not f then
        return devices
    end

    local current = nil
    local function ensure_current(dev_name)
        local name = (dev_name and dev_name ~= "") and dev_name or fallback_dev
        if not devices[name] then
            devices[name] = new_device_record(name, today, now_iso)
        end
        current = devices[name]
    end

    for line in f:lines() do
        line = line:gsub("\r$", "")
        local dev_header = line:match("^%[device:(.+)%]$")
        if dev_header then
            ensure_current(dev_header)
        else
            if not current then
                ensure_current(fallback_dev)
            end

            local day1, day_words1, day_keys1 = line:match("^day=(%d+)%s+day_words=(%d+)%s+day_keys=(%d+)$")
            if day1 then
                table.insert(current.history, {
                    day = day1,
                    day_words = tonumber(day_words1) or 0,
                    day_keys = tonumber(day_keys1) or 0,
                })
            else
                local total_words1, total_keys1 = line:match("^total_words=(%d+)%s+total_keys=(%d+)$")
                if total_words1 and total_keys1 then
                    current.total_words = tonumber(total_words1) or current.total_words
                    current.total_keys = tonumber(total_keys1) or current.total_keys
                else
                    local k, v = line:match("^([%w_]+)=(.+)$")
                    if k and v then
                        if k == "start_iso" or k == "day" or k == "last_code" then
                            current[k] = v
                        elseif k == "total_words" or k == "total_keys"
                            or k == "day_words" or k == "day_keys"
                            or k == "edit_count" or k == "day_edit_count" then
                            current[k] = tonumber(v) or 0
                        end
                    end
                end
            end
        end
    end
    f:close()

    for _, rec in pairs(devices) do
        if #rec.history > 0 then
            table.sort(rec.history, function(a, b) return a.day < b.day end)
            local last = rec.history[#rec.history]
            if last.day == today then
                rec.day = last.day
                rec.day_words = last.day_words
                rec.day_keys = last.day_keys
            else
                -- 跨天后若该设备今天尚无记录，则今日计数归零
                if rec.day ~= today then
                    rec.day = today
                    rec.day_words = 0
                    rec.day_keys = 0
                    rec.day_edit_count = 0
                end
            end
        elseif rec.day ~= today then
            rec.day = today
            rec.day_words = 0
            rec.day_keys = 0
            rec.day_edit_count = 0
        end
    end

    return devices
end

local function sync_history(rec)
    local history = rec.history or {}
    local today = rec.day
    local found = false
    for i = 1, #history do
        if history[i].day == today then
            history[i].day_words = tonumber(rec.day_words) or 0
            history[i].day_keys = tonumber(rec.day_keys) or 0
            found = true
            break
        end
    end
    if not found and today and today ~= "" then
        table.insert(history, {
            day = today,
            day_words = tonumber(rec.day_words) or 0,
            day_keys = tonumber(rec.day_keys) or 0,
        })
    end
    table.sort(history, function(a, b) return a.day < b.day end)
    rec.history = history
end

local function save_stat(env, force)
    local s = _G.my_stat
    if not s then
        return
    end

    local now = os.time()
    if not force and (now - last_save_time) < save_interval_sec then
        return
    end

    local path = get_db_path(env)
    local all_devices = parse_all_devices_from_file(path, s.device)

    sync_history(s)
    all_devices[s.device] = {
        device = s.device,
        start_iso = s.start_iso or os.date("%Y-%m-%d %H:%M:%S"),
        total_words = tonumber(s.total_words) or 0,
        total_keys = tonumber(s.total_keys) or 0,
        edit_count = tonumber(s.edit_count) or 0,
        day_edit_count = tonumber(s.day_edit_count) or 0,
        day = s.day,
        day_words = tonumber(s.day_words) or 0,
        day_keys = tonumber(s.day_keys) or 0,
        last_code = s.last_code or "",
        history = s.history,
    }

    -- 按设备名排序输出，保持文件稳定可读
    local names = {}
    for name in pairs(all_devices) do
        names[#names + 1] = name
    end
    table.sort(names)

    local f = io.open(path, "w")
    if not f then
        return
    end

    for _, name in ipairs(names) do
        local rec = all_devices[name]
        f:write("[device:" .. tostring(rec.device) .. "]\n")
        f:write("start_iso=" .. tostring(rec.start_iso) .. "\n")
        f:write(string.format("total_words=%d total_keys=%d\n", rec.total_words or 0, rec.total_keys or 0))
        f:write(string.format("edit_count=%d day_edit_count=%d\n", rec.edit_count or 0, rec.day_edit_count or 0))
        for i = 1, #(rec.history or {}) do
            local h = rec.history[i]
            f:write(string.format("day=%s day_words=%d day_keys=%d\n", h.day, h.day_words or 0, h.day_keys or 0))
        end
        f:write("last_code=" .. tostring(rec.last_code or "") .. "\n")
    end

    f:close()
    last_save_time = now
end

-- ==================== 内存状态加载（仅初始化与跨天执行） ====================

local function load_stat(env)
    local dev_id = get_device_id()
    local today = os.date("%Y%m%d")

    if not _G.my_stat or _G.my_stat.device ~= dev_id then
        local path = get_db_path(env)
        local devices = parse_all_devices_from_file(path, dev_id)
        local rec = devices[dev_id] or new_device_record(dev_id, today, os.date("%Y-%m-%d %H:%M:%S"))

        _G.my_stat = {
            device = dev_id,
            start_iso = rec.start_iso,
            total_words = rec.total_words or 0,
            total_keys = rec.total_keys or 0,
            edit_count = rec.edit_count or 0,
            day_edit_count = rec.day_edit_count or 0,
            day = rec.day or today,
            day_words = rec.day_words or 0,
            day_keys = rec.day_keys or 0,
            last_code = rec.last_code or "",
            history = rec.history or {},
            key_timestamps = {},
            commit_events = {},
            all_devices_cache = devices,
        }
    end

    local s = _G.my_stat
    if s.day ~= today then
        sync_history(s)
        s.day = today
        s.day_words = 0
        s.day_keys = 0
        s.day_edit_count = 0
        s.last_code = ""
        save_stat(env, true)
    end

    return s
end

-- ==================== Rime 核心入口 ====================

function M.func(input, seg, env)
    local s = load_stat(env)
    local now = os.time()

    if input == "" then
        if s.last_code ~= "" and s.last_code ~= command_key then
            s.edit_count = (s.edit_count or 0) + 1
            s.day_edit_count = (s.day_edit_count or 0) + 1
        end
        s.last_code = ""
        return
    end

    if #input < #s.last_code then
        local del_chars = #s.last_code - #input
        s.edit_count = (s.edit_count or 0) + del_chars
        s.day_edit_count = (s.day_edit_count or 0) + del_chars
        s.last_code = input
    end

    if input == command_key then
        if s.last_code ~= "" and command_key:sub(1, #s.last_code) == s.last_code then
            local rollback = #s.last_code
            if rollback > 0 then
                s.total_keys = math.max(0, s.total_keys - rollback)
                s.day_keys = math.max(0, s.day_keys - rollback)
            end
        end
        s.last_code = input
    elseif input ~= "" and input ~= s.last_code then
        if #input > #s.last_code then
            local diff = #input - #s.last_code
            s.total_keys = s.total_keys + diff
            s.day_keys = s.day_keys + diff
            s.key_timestamps = trim_timestamps(s.key_timestamps, now, speed_window_sec)
            for _ = 1, diff do
                s.key_timestamps[#s.key_timestamps + 1] = now
            end
        end
        s.last_code = input
    end

    if input == command_key then
        -- 强制落盘一次并刷新所有设备缓存，保证 sS 时数据最新且不调用外部命令
        save_stat(env, true)
        local all_devices = parse_all_devices_from_file(get_db_path(env), s.device)
        all_devices[s.device] = {
            device = s.device,
            start_iso = s.start_iso,
            total_words = s.total_words,
            total_keys = s.total_keys,
            edit_count = s.edit_count,
            day_edit_count = s.day_edit_count,
            day = s.day,
            day_words = s.day_words,
            day_keys = s.day_keys,
        }

        local names = {}
        for name in pairs(all_devices) do
            names[#names + 1] = name
        end
        table.sort(names)

        local sum_day_words, sum_day_keys = 0, 0
        local sum_total_words, sum_total_keys = 0, 0
        local sum_edits = 0
        local dev_parts = {}

        for _, name in ipairs(names) do
            local d = all_devices[name]
            sum_day_words = sum_day_words + (d.day_words or 0)
            sum_day_keys = sum_day_keys + (d.day_keys or 0)
            sum_total_words = sum_total_words + (d.total_words or 0)
            sum_total_keys = sum_total_keys + (d.total_keys or 0)
            sum_edits = sum_edits + (d.edit_count or 0)

            dev_parts[#dev_parts + 1] = string.format(
                "[%s] 今%s字/%s键 总%s字/%s键",
                name,
                format_count(d.day_words),
                format_count(d.day_keys),
                format_count(d.total_words),
                format_count(d.total_keys)
            )
        end

        local kpm = calc_rate_per_min(s.key_timestamps, now, speed_window_sec)
        local wpm = calc_commit_wpm(s.commit_events, now, speed_window_sec)
        local edit_rate = (s.total_keys > 0) and ((s.edit_count or 0) / s.total_keys * 100) or 0
        local sum_edit_rate = (sum_total_keys > 0) and (sum_edits / sum_total_keys * 100) or 0
        local from_date = (s.start_iso or ""):match("^(%d%d%d%d%-%d%d%-%d%d)") or ""

        local total_text = string.format(
            "全端总计：%s字/%s键（今%s字/%s键）| %.0f键/分 %.0f字/分 | 删改%d次(%.1f%%)",
            format_count(sum_total_words),
            format_count(sum_total_keys),
            format_count(sum_day_words),
            format_count(sum_day_keys),
            kpm,
            wpm,
            sum_edits,
            sum_edit_rate
        )
        yield(Candidate("stat_all", seg.start, seg._end, total_text, string.format("[共%d台设备 · %s起]", #names, from_date)))

        local per_dev_text = table.concat(dev_parts, " | ")
        yield(Candidate("stat_devices", seg.start, seg._end, per_dev_text, string.format("[本机:%s · 删改%d次/%.1f%%]", s.device, s.edit_count or 0, edit_rate)))
    end
end

function M.init(env)
    load_stat(env)
    pcall(function()
        env.conn = env.engine.context.commit_notifier:connect(function(ctx)
            local text = ctx:get_commit_text()
            if text ~= "" and text ~= command_key then
                local s = load_stat(env)
                local now = os.time()
                local count = utf8_len(text)

                s.total_words = (s.total_words or 0) + count
                s.day_words = (s.day_words or 0) + count
                s.last_code = ""

                s.commit_events = trim_commit_events(s.commit_events, now, speed_window_sec)
                s.commit_events[#s.commit_events + 1] = { t = now, chars = count }

                -- 上屏时按节流间隔保存，避免高频上屏阻塞输入法
                save_stat(env, false)
            end
        end)
    end)
end

function M.processor(key, env)
    return 2
end

return M