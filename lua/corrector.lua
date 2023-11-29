--[[
	错音错字提示。
	示例：「给予」的正确读音是 ji yu，当用户输入 gei yu 时，在候选项的 comment 显示正确读音
	示例：「按耐」的正确写法是「按捺」，当用户输入「按耐」时，在候选项的 comment 显示正确写法

	为了让这个 Lua 同时适配全拼与双拼，使用 `spelling_hints` 生成的 comment（全拼拼音）作为通用的判断条件。
	感谢大佬@[Shewer Lu](https://github.com/shewer)提供的思路。
	
	容错词在 cn_dicts/others.dict.yaml 中，有新增建议可以提个 issue
--]]

local corrections = {
	-- 错音
	["hun dun"] = { text = "馄饨", comment = "hun tun" },
	["zhu jiao"] = { text = "主角", comment = "zhu jue" },
	["jiao se"] = { text = "角色", comment = "jue se" },
	["pi sa"] = { text = "比萨", comment = "bi sa" },
	["chi pi sa"] = { text = "吃比萨", comment = "chi bi sa" },
	["pi sa bing"] = { text = "比萨饼", comment = "bi sa bing" },
	["shui fu"] = { text = "说服", comment = "shuo fu" },
	["dao hang"] = { text = "道行", comment = "dao heng" },
	["mo yang"] = { text = "模样", comment = "mu yang" },
	["you mo you yang"] = { text = "有模有样", comment = "you mu you yang" },
	["yi mo yi yang"] = { text = "一模一样", comment = "yi mu yi yang" },
	["zhuang mo zuo yang"] = { text = "装模作样", comment = "zhuang mu zuo yang" },
	["ren mo gou yang"] = { text = "人模狗样", comment = "ren mu gou yang" },
	["mo ban"] = { text = "模板", comment = "mu ban" },
	["a mi tuo fo"] = { text = "阿弥陀佛", comment = "e mi tuo fo" },
	["na mo a mi tuo fo"] = { text = "南无阿弥陀佛", comment = "na mo e mi tuo fo" },
	["nan wu a mi tuo fo"] = { text = "南无阿弥陀佛", comment = "na mo e mi tuo fo" },
	["nan wu e mi tuo fo"] = { text = "南无阿弥陀佛", comment = "na mo e mi tuo fo" },
	["gei yu"] = { text = "给予", comment = "ji yu" },
	["bin lang"] = { text = "槟榔", comment = "bing lang" },
	["zhang bai zhi"] = { text = "张柏芝", comment = "zhang bo zhi" },
	["teng man"] = { text = "藤蔓", comment = "teng wan" },
	["nong tang"] = { text = "弄堂", comment = "long tang" },
	["xin kuan ti pang"] = { text = "心宽体胖", comment = "xin kuan ti pan" },
	["mai yuan"] = { text = "埋怨", comment = "man yuan" },
	["xu yu wei she"] = { text = "虚与委蛇", comment = "xu yu wei yi" },
	["mu na"] = { text = "木讷", comment = "mu ne" },
	["du le le"] = { text = "独乐乐", comment = "du yue le" },
	["zhong le le"] = { text = "众乐乐", comment = "zhong yue le" },
	["xun ma"] = { text = "荨麻", comment = "qian ma" },
	["qian ma zhen"] = { text = "荨麻疹", comment = "xun ma zhen" },
	["mo ju"] = { text = "模具", comment = "mu ju" },
	["cao zhi"] = { text = "草薙", comment = "cao ti" },
	["cao zhi jing"] = { text = "草薙京", comment = "cao ti jing" },
	["cao zhi jian"] = { text = "草薙剑", comment = "cao ti jian" },
	["jia ping ao"] = { text = "贾平凹", comment = "jia ping wa" },
	["xue fo lan"] = { text = "雪佛兰", comment = "xue fu lan" },
	["qiang jin"] = { text = "强劲", comment = "qiang jing" },
	["tong ti"] = { text = "胴体", comment = "dong ti" },
	["li neng kang ding"] = { text = "力能扛鼎", comment = "li neng gang ding" },
	["ya lv jiang"] = { text = "鸭绿江", comment = "ya lu jiang" },
	["da fu bian bian"] = { text = "大腹便便", comment = "da fu pian pian" },
	["ka bo zi"] = { text = "卡脖子", comment = "qia bo zi" },
	["zhi sheng"] = { text = "吱声", comment = "zi sheng" },
	["chan he"] = { text = "掺和", comment = "chan huo" },
	["chan huo"] = { text = "掺和", comment = "chan huo" },
	["can he"] = { text = "掺和", comment = "chan huo" },
	["cheng zhi"] = { text = "称职", comment = "chen zhi" },
	["luo shi fen"] = { text = "螺蛳粉", comment = "luo si fen" },
	["tiao huan"] = { text = "调换", comment = "diao huan" },
	["tai xing shan"] = { text = "太行山", comment = "tai hang shan" },
	["jie si di li"] = { text = "歇斯底里", comment = "xie si di li" },
	["nuan he"] = { text = "暖和", comment = "nuan huo" },
	["mo ling liang ke"] = { text = "模棱两可", comment = "mo leng liang ke" },
	["pan yang hu"] = { text = "鄱阳湖", comment = "po yang hu" },
	["bo jing"] = { text = "脖颈", comment = "bo geng" },
	["bo jing er"] = { text = "脖颈儿", comment = "bo geng er" },
	["jie zha"] = { text = "结扎", comment = "jie za" },
	-- 错字
	["pu jie"] = { text = "扑街", comment = "仆街" },
	["pu gai"] = { text = "扑街", comment = "仆街" },
	["pu jie zai"] = { text = "扑街仔", comment = "仆街仔" },
	["pu gai zai"] = { text = "扑街仔", comment = "仆街仔" },
	["ceng jin"] = { text = "曾今", comment = "曾经" },
	["an nai"] = { text = "按耐", comment = "按捺(na)" },
	["an nai bu zhu"] = { text = "按耐不住", comment = "按捺(na)不住" },
	["bie jie"] = { text = "别介", comment = "别价(jie)" },
	["beng jie"] = { text = "甭介", comment = "甭价(jie)" },
	["xue mai pen zhang"] = { text = "血脉喷张", comment = "血脉贲(ben)张 | 血脉偾(fen)张" },
	["qi ke fu"] = { text = "契科夫", comment = "契诃(he)夫" },
	["zhao cha"] = { text = "找茬", comment = "找碴" },
	["zhao cha er"] = { text = "找茬儿", comment = "找碴儿" },
	["da jia lai zhao cha"] = { text = "大家来找茬", comment = "大家来找碴" },
	["da jia lai zhao cha er"] = { text = "大家来找茬儿", comment = "大家来找碴儿" },
	["ci ya"] = { text = "龇牙", comment = "龇(zi)牙" },
	["ci zhe ya"] = { text = "龇着牙", comment = "龇(zi)着牙" },
	["ci ya lie zui"] = { text = "龇牙咧嘴", comment = "龇(zi)牙咧嘴" },
	["cou huo"] = { text = "凑活", comment = "凑合(he)" },
}

local function corrector(input)
	for cand in input:iter() do
		-- cand.comment 是目前输入的词汇的完整拼音
		local c = corrections[cand.comment]
		if c and cand.text == c.text then
			cand:get_genuine().comment = c.comment
		elseif cand.type == "user_phrase" or cand.type == "phrase" or cand.type == "sentence" then
			cand:get_genuine().comment = ""
		end
		yield(cand)
	end
end

return corrector
