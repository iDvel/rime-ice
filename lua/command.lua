local map
do
local Sep=package.config:sub(1, 1)
local user=rime_api:get_user_data_dir()
local data=rime_api:get_shared_data_dir()
local program=data:sub(1,-6)
local build=user..Sep.."build"
map={
 -- ["/sep"]={{Sep,"分隔符"}},
 ["/user"]={{user,"用户文件夹"}},
 ["/data"]={{data,"共享文件夹"}},
 ["/program"]={{program,"程序文件夹"}},
 ["/build"]={{build,"部署文件夹"}},
 ["/lua"]={{data..Sep.."lua","lua文件夹"}},
 ["/opencc"]={{data..Sep.."opencc","滤镜文件夹"}},
}
end
local K={
 ["Tab"]={["Tab"]=true},
 ["BackSpace"]={["BackSpace"]=true},
}
local Valid={}
for _,v in pairs(K)do
 for k,_ in pairs(v)do
  Valid[k]=true
 end
end
local cpl_map={}
local symbol="/"
local symbol_l=#symbol
return {
 function(key,env)
  key=key:repr()
  if env.engine.context.input=="" then cpl_map={} return 2 end
  if not Valid[key] then return 2 end--键不合法则直接Return
  local input=env.engine.context.input:lower()
  if input:find("^"..symbol) then--命令未完整进入补全状态
   if #cpl_map==0 then--命令未完整且 cpl_map 长度为零则重新获取 cpl_map 补全列表
    for k,v in pairs(map) do
     if k:find("^"..input..".") then
      cpl_map[#cpl_map+1]=k:sub(1+symbol_l)
     end
    end
    table.sort(cpl_map,function(a,b) return #a>#b end)
    table.insert(cpl_map,1,input:sub(1+symbol_l))
   end
   if K.Tab[key] then--补全状态按 Tab 可以在 cpl_map 列表中循环
    env.engine.context:pop_input(#input-symbol_l)
    env.engine.context:push_input(cpl_map[#cpl_map])
    table.remove(cpl_map,#cpl_map)
    return 1
   end
   if K.BackSpace[key] and input:sub(1+symbol_l)~=cpl_map[1] then--补全状态按 BackSpace 会退出补全状态并归还编码
    env.engine.context:pop_input(#input-symbol_l)
    env.engine.context:push_input(cpl_map[1])
    cpl_map={}
    return 1
   end
   cpl_map={}
  end
  return 2
 end
 ,
 function(_,seg,env)
  local input=env.engine.context.input:lower()
  if map[input] then
   for i=1,#map[input] do
    local cand=Candidate("command",seg.start,seg._end,map[input][i][1],map[input][i][2])
    cand.quality=8102
    yield(cand)
   end
  else
   if input:find("^"..symbol) then
    local cand=Candidate("command",seg.start,seg._end,"Tab补全命令","")
    cand.quality=8102
    yield(cand)
   end
  end
 end
}