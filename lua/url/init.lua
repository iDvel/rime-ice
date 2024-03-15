local function matcher(str,rules)
 local ret={}
 local rest=str
 for i,rule in ipairs(rules) do
  local last=rest
  local value
  local name=rule.name or i
  value,rest=rest:match(rule.pattern.."(.*)")
  if rule.format then
   value=string.format(rule.format,value)
  end
  if rest~=nil then
   ret[name]=value
  else
   if rule.skip==true then
    rest=last
    ret[name]=""
   else
    break
   end
  end
 end
 return ret
end
local url_pattern={
 {pattern="^(%a+):/?/?",  format="%s://",  skip=true},
 {pattern="^([^:/]+)"},
 {pattern="^(:%d+)"},
}
local domain_pattern={
 {pattern="^([^.]+)%.?"},
 {pattern="^([^.]+)%.?"},
 {pattern="^([^.]+)"},
}
local IS_TLDS <const> = require("url.tlds")
local IS_COMMON_DOMAIN <const> = require("url.common_domain")
local IS_HTTP <const> = {
 ["http://"]=true,
 ["https://"]=true,
}
local M={}
M.translator={}
function M.translator.init(env)
 env.tag=env.engine.schema.config:get_string(env.name_space.."/tag") or "url"
 local quality=env.engine.schema.config:get_double(env.name_space.."/initial_quality") or 0
 local comment=env.engine.schema.config:get_string(env.name_space.."/tips") or ""
 function env.yield(text,seg)
  local cand=Candidate("url",seg.start,seg._end,text,comment)
  cand.quality=quality
  yield(cand)
 end
end
function M.translator.func(input,seg,env)
 if seg:has_tag(env.tag)==false then
  return
 end
 local yield=env.yield
 local url=matcher(input,url_pattern)
 local url_part=#url
 if url_part>0 then
  yield(table.concat(url),seg)
 end
 if url_part>1 then
  if url[1]=="" or IS_HTTP[url[1]] then
   local s_domain=string.gsub(url[2],"%.$","")
   local domain=matcher(s_domain,domain_pattern)
   if domain[1]=="www" then
    table.remove(domain,1)
    s_domain=table.concat(domain)
    url[2]=s_domain
   end
   local domain_part=#domain
   -- 识别世界常用域名而补全之。
   local is_common=false
   if IS_COMMON_DOMAIN[domain[1]] then
    is_common=true
    if domain_part==1 then
     url[2]="www."..s_domain..".com"
     yield(table.concat(url),seg)
    elseif domain_part==2 then
     url[2]="www."..s_domain
     yield(table.concat(url),seg)
    elseif domain_part==3 then
     yield(table.concat(url),seg)
    end
   end
   if IS_COMMON_DOMAIN[domain[2]] then
    is_common=true
    -- 主域名为常用域名者，补全缺省之顶级域名。
    if domain_part==2 then
     url[2]=s_domain..".com"
     yield(table.concat(url),seg)
    elseif domain_part==3 then
     yield(table.concat(url),seg)
    end
   end
   if is_common==false then
    -- 补全未收录的域名。
    if domain_part==1 then
     url[2]="www."..s_domain..".com"
     yield(table.concat(url),seg)
    elseif domain_part==2 then
     if IS_TLDS[domain[2]]==nil then
      url[2]=s_domain..".com"
      yield(table.concat(url),seg)
     end
     if domain[1]~="www" then
     url[2]="www."..s_domain
     end
     yield(table.concat(url),seg)
    elseif domain_part==3 then
     yield(table.concat(url),seg)
    end
   end
  else
   yield(table.concat(url),seg)
  end
 end
end
return M
