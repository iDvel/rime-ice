return function(input, env)
---开始---

--　遍历候选
for cand in input:iter() do
--　收集材料
 local    text = cand.text
 local cxinput = env.engine.context.input
--　判断首位大写
 if(cxinput:find("^%u.*"  ))then
--　制作词条
  if(cxinput:find("^%u.-%u$"))
   then text = cand.text:upper()
  else  text = cand.text:sub(1,1):upper()..cand.text:sub(2)
  end
--　挂起处理后的候选
  yield(Candidate(cand.type,0,#cxinput,text,cand.comment))
 else
--　否则挂起普通候选
  yield(cand)
 end
end

---结束---
end