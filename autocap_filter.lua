-- 返回函数
return function(input, env)
-- 遍历候选
for cand in input:iter() do
-- 收集材料
 local    text = cand.text
 local cxinput = env.engine.context.input
-- 制作词条
 if    (cxinput:find("^%u.-%u$")) then text = cand.text:upper()
 elseif(cxinput:find("^%u.*"  ))  then text = cand.text:sub(1,1):upper()..cand.text:sub(2)
 end
-- 挂起候选
 yield(Candidate(cand.type,0,#cxinput,text,cand.comment))
 end
-- 结束
end