--[[
    Lua 阿拉伯数字转中文实现 https://blog.csdn.net/lp12345678910/article/details/121396243
--]]
-- 数字转中文：

local numerical_units = {
    "",
    "十",
    "百",
    "千",
    "万",
    "十",
    "百",
    "千",
    "亿",
    "十",
    "百",
    "千",
    "兆",
    "十",
    "百",
    "千",
}

local numerical_names = {
    "零",
    "一",
    "二",
    "三",
    "四",
    "五",
    "六",
    "七",
    "八",
    "九",
}

local function convert_arab_to_chinese(number)
    local n_number = tonumber(number)
    assert(n_number, "传入参数非正确number类型!")

    -- 0 ~ 9
    if n_number < 10 then
        return numerical_names[n_number + 1]
    end
    -- 一十九 => 十九
    if n_number < 20 then
        local digit = string.sub(n_number, 2, 2)
        if digit == "0" then
            return "十"
        else
            return "十" .. numerical_names[digit + 1]
        end
    end

    --[[
        1. 最大输入9位
            超过9位，string的len加2位（因为有.0的两位）
            零 ~ 九亿九千九百九十九万九千九百九十九
            0 ~ 999999999
        2. 最大输入14位（超过14位会四舍五入）
            零 ~ 九十九兆九千九百九十九亿九千九百九十九万九千九百九十九万
            0 ~ 99999999999999
    --]]
    local len_max = 9
    local len_number = string.len(number)
    assert(
        len_number > 0 and len_number <= len_max,
        "传入参数位数" .. len_number .. "必须在(0, " .. len_max .. "]之间！"
    )

    -- 01，数字转成表结构存储
    local numerical_tbl = {}
    for i = 1, len_number do
        numerical_tbl[i] = tonumber(string.sub(n_number, i, i))
    end

    local pre_zero = false
    local result = ""
    for index, digit in ipairs(numerical_tbl) do
        local curr_unit = numerical_units[len_number - index + 1]
        local curr_name = numerical_names[digit + 1]
        if digit == 0 then
            if not pre_zero then
                result = result .. curr_name
            end
            pre_zero = true
        else
            result = result .. curr_name .. curr_unit
            pre_zero = false
        end
    end
    result = string.gsub(result, "零+$", "")
    return result
end

-- 数字转数位
-- 例如 2026 -> alt_zero ? 二〇二六 : 二零二六
local function convert_digits(number, alt_zero)
    local num_str = tostring(number)
    local result = {}

    for i = 1, #num_str do
        local ch = num_str:sub(i, i)
        local digit = tonumber(ch)

        if digit == 0 then
            table.insert(result, alt_zero and "〇" or "零")
        else
            table.insert(result, numerical_names[digit + 1])
        end
    end

    return table.concat(result)
end

return {
    convert = convert_arab_to_chinese,
    digits = convert_digits
}
