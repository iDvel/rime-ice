-- 根据是否在用户词典，在结尾加上一个星号 *
-- is_in_user_dict: true           输入过的内容
-- is_in_user_dict: flase 或不写    未输入过的内容
local function is_in_user_dict(input, env)
	if not env.is_in_user_dict then
		local config = env.engine.schema.config
        env.name_space = env.name_space:gsub('^*', '')
        env.is_in_user_dict = config:get_bool(env.name_space)
	end
    for cand in input:iter() do
        if env.is_in_user_dict then
            if cand.type == "user_phrase" then
                cand.comment = cand.comment .. '*'
            end
        else
            if cand.type ~= "user_phrase" then
                cand.comment = cand.comment .. '*'
            end
        end
        yield(cand)
    end
end

return is_in_user_dict
