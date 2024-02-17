-- 让写在 alphabet 中的某标点自动上屏
-- 配置，在方案中填写 auto_commit_single_punct: '`'
-- 用途示例： `（反引号）被添加到了 speller/alphabet 来响应辅码，如 gan`shuijin 得到「淦」。
--          这样导致在输入单个的 ` 时仍然需要按空格选择一下。
--          因为 ` 只在非开头状态下产生作用，所以我希望输入单个的 ` 时和其他标点一样都直接上屏。
local P = {}

function P.get_punct_text(cfg, path)
    if cfg:is_list(path) then
        -- null value or list -> return nil
        -- `: [`,-] -> nil
        return nil
    elseif cfg:is_map(path) then
        local map = cfg:get_map(path)
        -- map and has commit key -> return commit text
        -- `: {commit: '*'} -> *
        -- `: {pair: ["‘", "’"]} -> nil
        if map:has_key("commit") then
            return map:get_value("commit").value
        end
    elseif cfg:is_value(path) then
        -- string -> return value
        -- `: '`' -> `
        return cfg:get_string(path)
    end
    return nil
end

function P.init(env)
    local cfg = env.engine.schema.config
    P.punct = cfg:get_string(env.name_space:gsub('^*', ''))
    if not P.punct then
        return
    end

    local full_shape_path = "punctuator/full_shape/" .. P.punct
    local half_shape_path = "punctuator/half_shape/" .. P.punct
    P.full_shape_text = P.get_punct_text(cfg, full_shape_path)
    P.half_shape_text = P.get_punct_text(cfg, half_shape_path)
end

function P.func(key, env)
    local context = env.engine.context

    -- 不影响组合键
    if not P.punct or key:release() or key:ctrl() or key:alt() or key:super() then
        return 2 -- kNoop
    end

    local ascii_str = ''
    if key.keycode > 0x20 and key.keycode < 0x7f then
        ascii_str = string.char(key.keycode)
    end

    -- 解开下面三行，将只允许一次辅码上屏（辅码检索时，将会阻止再次输入辅码）
    -- if context.input:find("^[a-z;]+" .. P.char) and ascii_str == P.char then
    -- 	return 1
    -- end

    if not context:is_composing() and ascii_str == P.punct then
        local is_full_shape = env.engine.context:get_option("full_shape")
        if is_full_shape and P.full_shape_text then
            env.engine:commit_text(P.full_shape_text)
            return 1
        elseif (not is_full_shape) and P.half_shape_text then
            env.engine:commit_text(P.half_shape_text)
            return 1
        end
    end
    return 2 -- kNoop
end

return P
