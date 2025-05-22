-- 以词定字
-- 原脚本 https://github.com/BlindingDark/rime-lua-select-character
-- 可在 default.yaml → key_binder 下配置快捷键，默认为左右中括号 [ ]
-- 20230526195910 不再错误地获取commit_text，而是直接获取get_selected_candidate().text
-- 20240128141207 重写：将读取设置移动到 init 方法中；简化中文取字方法；预先判断候选存在与否，无候选取 input
-- 20240508111725 当候选字数为 1 时，快捷键使该字上屏
-- 20250515093039 以词定字支持长句输入
-- 20250516231523 当候选字数为 1 且还有未处理的输入时，快捷键使该字上屏, 保留未处理部分

local select = {}

function select.init(env)
    local config = env.engine.schema.config
    env.first_key = config:get_string('key_binder/select_first_character')
    env.last_key = config:get_string('key_binder/select_last_character')
end

function select.func(key, env)
    local engine = env.engine
    local context = env.engine.context

    if
        not key:release()
        and (context:is_composing() or context:has_menu())
        and (env.first_key or env.last_key)
    then
        local candidate = context.input
        if context:get_selected_candidate() then
            candidate = context:get_selected_candidate().text
        end
        local selected = ""
        if utf8.len(candidate) > 1 then
            if (key:repr() == env.first_key) then
                selected = candidate:sub(1, utf8.offset(candidate, 2) - 1)
            elseif (key:repr() == env.last_key) then
                selected = candidate:sub(utf8.offset(candidate, -1))
            else
                return 2
            end
        else
            if key:repr() == env.first_key or key:repr() == env.last_key then
                selected = candidate
            else
                return 2
            end
        end
        local committed = context:get_commit_text()
        local start_pos, end_pos = committed:find(candidate)
        if start_pos and end_pos then
            local part1 = committed:sub(1, end_pos):gsub(candidate, selected)
            local part2 = committed:sub(end_pos + 1)
            engine:commit_text(part1)
            context:clear()
            if part2 ~= "" then
                context:push_input(part2)
            end
            return 1
        else
            return 2
        end
    end
    return 2
end

return select
