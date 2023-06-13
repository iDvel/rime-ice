--[[
t是一个二维数组,储存着编码、总提示码、日期格式、分提示码、特殊提示码
下方演示t的格式:
local t={"", --第一个键值,必填,可以且必须设置为为任意字符串,代表总提示码,作用于所有日期格式,总提示码的优先级最低,但总会出现,默认为空字符串
{ --总表第二个以及以后的键值,都是表,第二个表必填
"date", --表的第一个键值,必填,是表中第三个及以后的日期格式的编码
"日期", --表的第二个键值,必填,是本日期格式组的默认提示码,只作用于这部分日期格式
 {'os.date("%Y-%m-%d")',false}, --表的第三个及以后键值,必填,代表输入编码时所输出的日期格式
 {'os.date("%Y/%m/%d")',false}, --从此开始,所有键值都是选填项,因为你至少得输出一个时间格式才会需要这个脚本
 {'os.date("%Y.%m.%d")',false}, --'%Y-%m-%d'代表日期格式:年-月-日
 {'os.date("%Y%m%d")',false}--false代表特殊提示码,只作用与这一个日期格式,可以设置为false、nil和任意字符串,设置为空字符串""可以关闭这个日期格式的提示码,false和nil代表不设置特殊提示码
--紧凑易读的写法,建议按此格式添加新的日期格式
 {"time","时间",
 {'os.date("%H:%M")',false},
 {'os.date("%H:%M:%S")',false}}, --收尾要两个右花括号

 {"time2","时间2",{'os.date("%H:%M:%S")',false}},--如果你只添加一个日期格式,可以将四项写在一行

 {"time3","时间3",{'os.date("%H:%M:%S")',false}},--最后一组日期格式不需要逗号分隔
 {     "time3",--基于Lua特性,你也可以把表写的很丑
 "时间3"        ,{
 'os.date("%H:%M:%S")'                  ,
 false}
 }

 20230614004921 由蹄垫hoofcushion编辑
}
--]]
w={"日", "一", "二", "三", "四", "五", "六"}
local t={"",
{"date","『日期』",--雾凇默认,日期
 {'os.date("%Y-%m-%d")',false},
 {'os.date("%Y/%m/%d")',false},
 {'os.date("%Y.%m.%d")',false},
 {'os.date("%Y%m%d")',false},
 {'os.date("%Y年%m 月%d 日"):gsub(" 0",""):gsub(" ","")',false}},
{"time","『时间』",--雾凇默认,时间
 {'os.date("%H:%M")',false},
 {'os.date("%H:%M:%S")',false}},
{"datetime","『日期+时间』",--雾凇默认,日期+时间
 {'os.date("%Y-%m-%dT%H:%M:%S+08:00")',"中国标准时间(CST,UTC+8)"},
 {'os.date("%Y%m%d%H%M%S")',false}},
{"week","『星期』",--雾凇默认,星期
 {'"星期"..w[os.date("%w")+1]',false},
 {'"礼拜"..w[os.date("%w")+1]',false},
 {'"周"..w[os.date("%w")+1]',false}},
{"timestamp","『时间戳』",--雾凇默认,时间戳
 {'os.time()',false}},
{"D","『日期』",--蹄垫自用,普通格式日期
 {'os.date("%Y年%m月%d日")',false},
 {'os.date("%Y年%m月%d日")',false},
 {'os.date("%Y%m%d")',false},
 {'os.date("%B %d")',false}},
{"DD","『纯ASCII日期』",--蹄垫自用,纯ASCII日期
 {'os.date("%Y/%m/%d")',false},
 {'os.date("%Y-%m-%d")',false},
 {'os.date("%Y.%m.%d")',false}},
{"S","『日期+时间』",--蹄垫自用,普通格式日期+时间
 {'os.date("%Y年%m月%d日 %H时%M分")',false},
 {'os.date("%Y年%m月%d日 %H时%M分")',false},
 {'os.date("%Y%m%d%H%M%S")',false},
 {'os.date("%B %d %H:%M")',false}},
{"SS","『纯ASCII日期+时间』",--蹄垫自用,纯ASCII日期+时间
 {'os.date("%Y/%m/%d %H:%M")',false},
 {'os.date("%Y-%m-%d %H:%M")',false},
 {'os.date("%Y.%m.%d %H:%M")',false}},
{"ISO","",--蹄垫自用,符合ISO标准的世界协调时
 {'os.date("%Y-%m-%dS%H:%M:%S+08:00")',"中国标准时间(CST,UTC+8)"},--中国标准时间（CST，UTC+8）
 {'os.date("%Y-%m-%dS%H:%M:%SZ")',"『世界协调时』"}},--世界协调时（UTC）
{"ver","『版本号』",--蹄垫自用,快速设置版本号
 {'os.date("%Y%m%d%H%M%S")',false},
 {'os.time()',false},
 {'os.date("%Y%m%d")',false},
 {'os.date("%H%M%S")',false}}
}
return function (input, seg, env)
 for i=1,#t do
  if input==t[i][1] then
   for o=3,#t[i] do
    local text=load('return '..t[i][o][1])()
    local comment=t[i][o][2] or t[i][2] or t[2]
    local cand=Candidate("time_cand",seg.start,seg._end,text,comment)
    cand.quality=8102
    yield(cand)
   end
  end
 end
end
