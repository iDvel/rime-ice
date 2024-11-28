local completion_filter = {}

function completion_filter.init( env )
    env.completion_cand_count = env.engine.schema.config:get_int( 'translator/word_completion_count' ) or 1 -- set to 0 to disable
end

function completion_filter.func( input, env )
    local completion_cand_count = 0
    for cand in input:iter() do
        -- 对于 rime-ice 而言，实际上可以判断 cand.comment 是否含有标记
        -- 但是这里为了通用，所以只判断文本是否含有英文字符
        if env.completion_cand_count > 0 and cand.type == 'completion' and not cand.text:find( '%a' ) then
            completion_cand_count = completion_cand_count + 1
            if completion_cand_count > env.completion_cand_count then goto skip end
        end
        yield( cand )
        ::skip::
    end
end

function completion_filter.tags_match( seg, env ) if seg.tags['abc'] then return true end end

return completion_filter
