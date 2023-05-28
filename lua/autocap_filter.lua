return function(input, env)
---开始---

--　遍历候选
for cand in input:iter() do
--　收集材料
 local    text = cand.text
 local cxinput = env.engine.context.input
--　首位大写|符合词条|符合编码
 if(cxinput:find("^[A-Z]")                           and
       text:find("^[A-za-z0-9%.%- +/éà'’&!:;,<>]+$") and
    cxinput:find("^[A-Za-z%.%-']+$"                  and
   #cxinput>2                                           ))
 then
--　末位大写
  if(cand.type~="completion" and cxinput:find("[A-Z]$"))
--　制作词条
   then text = cand.text:upper()
  else  text = cand.text:sub(1,1):upper()..cand.text:sub(2)
  end
--　挂起处理后的候选
  yield(Candidate(cand.type,0,#cxinput,text,cand.comment))
 else
--　否则挂起原候选
  yield(cand)
 end
end

---结束---
end