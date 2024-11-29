-- 根据是否在用户词典，在 comment 上加上一个星号 *
-- 在 engine/filters 增加 - lua_filter@is_in_user_dict
-- 在方案里写配置项：
-- is_in_user_dict: true     为输入过的内容加星号
-- is_in_user_dict: false    为未输入过的内容加星号

local M = {}

function M.init(env)
    local config = env.engine.schema.config
    env.name_space = env.name_space:gsub('^*', '')
    M.is_in_user_dict = config:get_bool(env.name_space) or nil
end

local is_user = {
    user_table = true,
    user_phrase = true,
}

function M.func(input)
    for cand in input:iter() do
        if is_user[cand.type] == M.is_in_user_dict then
            cand.comment = cand.comment .. '*'
        end
        yield(cand)
    end
end

return M
