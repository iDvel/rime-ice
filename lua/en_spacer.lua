-- 中文或者英文后，再输入英文单词自动添加空格
local F = {}

function F.func( input, env )
    local latest_text = env.engine.context.commit_history:latest_text()
    for cand in input:iter() do
        if cand.text:match( '^[%a\']+[%a\']*$' ) and latest_text and #latest_text > 0 and
            not latest_text:find( '[%p%s。，；？：—！《》‘’“”、¥…（）【】「」『』]$' ) then
            cand = cand:to_shadow_candidate( 'en_spacer', cand.text:gsub( '(%a+\'?%a*)', ' %1' ), cand.comment )
        end
        yield( cand )
    end
end

return F

