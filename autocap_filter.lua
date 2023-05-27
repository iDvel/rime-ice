-- 输入字符串type、str1、str2
local function cpl_(type,str1,str2)
-- 判断type包含"completion"
if  string.find(type, "completion")
-- 包含　　返回true或str1
then return str1 or true
-- 不包含　返回false或str2
else return str2 or false   end end

-- 输入一个字符串
local function llo_(a)
-- 返回小写拉丁字母
return a:gsub("[^%a]+",""):lower()end


-- require文件将返回函数
return function(input, env)
-- 遍历候选
for cand in input:iter() do
-- 收集材料
 local    text = cand.text
 local    type = cand.type
 local ctx_inp = env.engine.context.input
-- 可选 制作-引导纯英文提示码
-- cand.comment = cpl_(type,"-","")..(llo_(text):gsub("^"..llo_(ctx_inp),""))
-- 可选 空提示码
-- cand.comment = ""
-- 制作词条
 if    (ctx_inp:find("^%u%u.*")) then text = text:upper()
 elseif(ctx_inp:find("^%u.*"  )) then text = text:sub(1,1):upper()..text:sub(2)
 end
-- 挂起候选
  yield(Candidate(type,0,#ctx_inp,text,cand.comment))
 end
-- 结束
end