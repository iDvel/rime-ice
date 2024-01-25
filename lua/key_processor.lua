-- key_processor.lua
-- Copyright (C) Mirtle <mirtle.cn@outlook.com>
-- Distributed under terms of the MIT license.

KEYTABLE = {}
COMMITHISTTORY = {}

local P = {}

-- 处理提供的规则，用了特殊符号搭桥
local function c(s)
    s = s:gsub("%%(%w)", '➋%1')
    s = s:gsub("(%w)%-(%w)", "%1➌%2")
    s = s:gsub("([%.%+%-%*%?%[%]%^%$%(%)%%])", "%%%1")
    s = s:gsub([[\\]], [[/]])
    s = s:gsub('➋', '%%')
    s = s:gsub('➌', '-')
    -- log.error(s)
    return s
end

-- 提取规则中的文本
local function r(s)
    return s:gsub('^' .. '%%%%', ''):gsub(' %d+$', '')
end

-- 判断是否符合自定义规则
local function r_match(str, pattern)
    if pattern:find('^%%%%') then
        return str:find("[" .. c(r(pattern)) .. "]$")
    else
        return str:find(c(r(pattern)) .. "$")
    end
    return false
end

-- 判断是否以中文结尾
local function endsWithChinese(str)
    -- 使用UTF-8编码，中文字符的最高位二进制表示是"110"
    local pattern = "[\xe4-\xe9][\x80-\xbf]+$"
    -- 使用string.match函数检查字符串是否以中文结尾
    return string.match(str, pattern) ~= nil
end

-- 不处理的按键序列
local function except(s)
    if s:find("BackSpace%|BackSpace") then
        return true
    elseif s:find("Control%+a%|BackSpace") then
        return true
    end
    return false
end

function P.init(env)
    COMMITHISTTORY[1] = ''
    KEYTABLE[0] = '-'
    KEYTABLE[1] = '-'
    KEYTABLE[2] = '-'
    COMMITHISTTORY[0] = ''
    KEYS = ''

    local config = env.engine.schema.config
    env.name_space = env.name_space:gsub("^*", "")
    P.history_key = config:get_string(env.name_space .. '/commit_history_key')
    -- P.search_key = config:get_string("key_binder/search") or config:get_string(env.name_space .. "/key") or '`'
    P.debug = config:get_bool(env.name_space .. "/debug")

    -- 当检测到此按键时，清空当前会话的提交历史记录
    local key_list = config:get_list(env.name_space .. '/clear_history_key')
    P.key_list = Set({"Up","Down","Escape","Shift+Return"})
    if key_list then
        for i = 0, key_list.size - 1 do
            local k = key_list:get_value_at(i).value
            if k then
                P.key_list[k] = true
            end
        end
    end

    -- 中文后的符号转换规则，和 rime 的算法规则一致
    local cn_rules = config:get_list(env.name_space .. '/cn_rules')
    if cn_rules then
        P.projection = Projection()
        P.projection:load(cn_rules)
    end

    -- ascii/历史/按键/
    local list = config:get_list(env.name_space .. '/ascii_rules')
    if list then
        P.ascii = {}
        for i = 0, list.size - 1 do

            local configString = list:get_value_at(i).value
            local key, value = configString:match('^ascii/(.+)/(.+)/$')
            if key and value then
                key = c(key)
                value = c(value)
                P.ascii[key] = value
            end
        end
    end

    -- # fnr/历史字符/按键/上屏/
    local c_rules = config:get_list(env.name_space .. '/custom_rules')
    if c_rules then
        -- 设置三个表，绕开 utf-8 处理的麻烦
        P.c_rules_match = {}
        P.c_rules = {}
        P.match = '' -- 方便先匹配一次
        for i = 0, c_rules.size - 1 do
            local configString = c_rules:get_value_at(i).value
            local m, k, v = configString:match('^fnr/(.+)/(.+)/(.+)/$')
            if m and k and v then
                m = m:gsub([[\\]], [[/]])
                k = k:gsub([[\\]], [[/]])
                v = v:gsub([[\\]], [[/]])
                -- log.error( m .. k .. v)
                P.match = P.match .. m:gsub('^%%%%', '')
                m = m .. ' ' .. i -- 添加 i 以标记不同的规则
                k = k .. ' ' .. i
                P.c_rules_match[m] = k
                P.c_rules[k] = v
            end
        end
        P.match = '[' .. c(P.match) .. ']'
        -- log.error(P.match)
    end

    -- 判断是否无规则
    if not list and not cn_rules and c_rules then
        P.no_rules = true
    end
end

function P.func(key, env)
    local context = env.engine.context
    local latest_text = context.commit_history:latest_text()
    -- 获取当前的 key 所代表的符号
    local ascii_str = ''
    if key.keycode > 0x20 and key.keycode < 0x7f then
        ascii_str = string.char(key.keycode)
    end

    -- 记录最近三个按键和两个提交记录，用于规避空格、退格清空历史
    -- 作用为，按下退格后，仍使用退格前的提交判断
    if not key:release() then
        -- local Pattern = "%w%|BackSpace"
        local Pattern = ".+%|BackSpace"
        -- key|space|BackSpace
        if KEYS:find("%|" .. Pattern .. "$") and not except(KEYS) then
            latest_text = COMMITHISTTORY[1]
        end

        -- space|BackSpace|Shift+Shift_L：这是以 Shift 引导的按键
        if KEYS:find("^" .. Pattern .. "%|Shift") and not except(KEYS) then
            latest_text = COMMITHISTTORY[0]
        end

        COMMITHISTTORY[1] = COMMITHISTTORY[0] or ''
        COMMITHISTTORY[0] = latest_text
        KEYTABLE[2] = KEYTABLE[1] or '-' -- 赋值以规避 error log 的产生
        KEYTABLE[1] = KEYTABLE[0] or '-'
        KEYTABLE[0] = key:repr() or '-'
        KEYS = KEYTABLE[2] .. '|' .. KEYTABLE[1] .. '|' .. KEYTABLE[0]

        if P.debug then
            -- log.warning('history Liter: ' .. context.commit_history:repr())
            -- log.warning('latest_text: ' .. context.commit_history:latest_text())
            log.warning('KEYS_sequence: ' .. KEYS)
            log.warning('COMMITHISTTORY: ' .. COMMITHISTTORY[0] .. '|' .. COMMITHISTTORY[1])
            -- log.warning('key_string: ' .. ascii_str)
        end
    end

    -- 检测到相关按键，清空历史记录
    if P.key_list and P.key_list[key:repr()] and not context:is_composing() then
        context.commit_history:clear()
    end

    -- 按下特定按键后，历史记录上屏
    if P.history_key then
        if context.input:match("^" .. P.history_key .. '$') then
            context:clear()
            env.engine:commit_text(latest_text)
            return 1
        end
    end

    -- 这是配合辅助码反查使用的，只允许输入一个辅助码
    -- if P.search_key then
    --     if context.input:find("^[a-z;]+" .. P.search_key) and ascii_str == P.search_key then
    --         return 1 -- 不处理
    --     end
    -- end

    -- 下面开始处理按键规则
    -- 不处理的情况
    if context:is_composing() -- 正在编辑
    or context:has_menu() -- 有菜单
    or P.no_rules -- 不指定规则
    or key:ctrl() or key:alt() or key:super() -- 按下 ctrl() alt() 或者 super()
    or key:release() -- 释放事件不处理
    -- or key.keycode < 0x21 -- 控制符号
    -- or key.keycode > 0x7e -- 非字母符号区
    or ascii_str == '' or (not latest_text) -- 无上一次输入
    or (latest_text == '') -- 上一次输入未记住
    or (latest_text:find("^%s+$")) -- 上一次输入了空字符串
    then
        return 2
    end

    -- log.error('A: ' .. latest_text .. ' B: ' .. ascii_str)
    -- log.error('Key Liter: ' .. key:repr())
    -- log.error('History Liter: ' .. context.commit_history:repr())

    -- 首先处理自定义规则
    if P.c_rules_match and P.c_rules and latest_text:find(P.match) then
        for m, v in pairs(P.c_rules_match) do
            if r_match(latest_text, m) and r_match(ascii_str, v) then
                local str = P.c_rules[v]
                if str:find('^%%%%1') then
                    return 1 -- 禁用
                elseif str:find('^%%%%0') then
                    return 0 -- 停止处理，让系统处理
                elseif str:find('^%%%%2') then
                    return 2 -- 放行
                else
                    env.engine:commit_text(str)
                    return 1
                end
            end
        end
    end

    -- 处理中文规则：有相关规则；上一次以中文结尾；输入的为标点
    if P.projection and endsWithChinese(latest_text) and not ascii_str:find("%w") then
        -- log.error('key: ' .. ascii_str .. ' c: ' .. P.projection:apply(ascii_str))
        local c = P.projection:apply(ascii_str)
        if c and c ~= '' then
            env.engine:commit_text(c)
            return 1
        end
    end

    -- 处理 ascii 规则
    if not P.ascii then
        return 2
    end
    for k, v in pairs(P.ascii) do
        if latest_text:match("[" .. k .. "]$") and ascii_str:match("[" .. v .. "]") then
            -- 一种解决办法，直接用 commit_text 方法
            env.engine:commit_text(ascii_str)
            return 1

            -- 当 return 0 使用系统处理按键时
            -- 含有 Shift 键的键顶掉历史，因而获取到的记录将为空，可以手动推进去
            -- if ascii_str:find('[{(<>)}]') then
            --     context.commit_history:push(env.engine.context.composition, ascii_str)
            -- end
            -- return 0
        end
    end
    return 2
end

function P.fini(env)
    -- 清空
    KEYTABLE = {}
    COMMITHISTTORY = {}
end

return P
