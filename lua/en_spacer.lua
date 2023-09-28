local function add_space_at_end(s)
    -- Check if the string contains all English characters
    if s:match("^[a-zA-Z%p%s]+$") then
        s = s .. " " -- Add a space at the end of the string
    end
    return s
end

local function en_spacer(input, env)
    for cand in input:iter() do
        cand = cand:to_shadow_candidate(cand.type, add_space_at_end(cand.text), cand.comment)
        yield(cand)
    end
end

return en_spacer
