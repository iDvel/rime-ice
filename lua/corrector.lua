--[[
	错音错字提示。
	示例：「给予」的正确读音是 ji yu，当用户输入 gei yu 时，在候选项的 comment 显示正确读音
	示例：「按耐」的正确写法是「按捺」，当用户输入「按耐」时，在候选项的 comment 显示正确写法

	为了让这个 Lua 同时适配全拼与双拼，使用 `spelling_hints` 生成的 comment（全拼拼音）作为通用的判断条件。
	感谢大佬@[Shewer Lu](https://github.com/shewer)提供的思路。
	
	容错词在 cn_dicts/others.dict.yaml 中，有新增建议可以提个 issue
--]]

local M = {}

function M.init(env)
    local config = env.engine.schema.config
    env.keep_comment = config:get_bool('translator/keep_comments')
    local delimiter = config:get_string('speller/delimiter')
    if delimiter and #delimiter > 0 and delimiter:sub(1,1) ~= ' ' then
        env.delimiter = delimiter:sub(1,1)
    end
    env.name_space = env.name_space:gsub('^*', '')
    M.style = config:get_string(env.name_space) or '{comment}'
    M.corrections = {
        -- 错音
        ["hun dun"] = { text = "馄饨", comment = "hún tun" },
        ["zhu jiao"] = { text = "主角", comment = "zhǔ jué" },
        ["jiao se"] = { text = "角色", comment = "júe sè" },
        ["chi pi sa"] = { text = "吃比萨", comment = "chī bǐ sà" },
        ["pi sa bing"] = { text = "比萨饼", comment = "bǐ sà bǐng" },
        ["shui fu"] = { text = "说服", comment = "shuō fú" },
        ["dao hang"] = { text = "道行", comment = "dào héng" },
        ["mo yang"] = { text = "模样", comment = "mú yàng" },
        ["you mo you yang"] = { text = "有模有样", comment = "yǒu mú yǒu yàng" },
        ["yi mo yi yang"] = { text = "一模一样", comment = "yī mú yī yàng" },
        ["zhuang mo zuo yang"] = { text = "装模作样", comment = "zhuāng mú zuò yàng" },
        ["ren mo gou yang"] = { text = "人模狗样", comment = "rén mú góu yàng" },
        ["mo ban"] = { text = "模板", comment = "mú bǎn" },
        ["a mi tuo fo"] = { text = "阿弥陀佛", comment = "ē mí tuó fó" },
        ["na mo a mi tuo fo"] = { text = "南无阿弥陀佛", comment = "nā mó ē mí tuó fó" },
        ["nan wu a mi tuo fo"] = { text = "南无阿弥陀佛", comment = "nā mó ē mí tuó fó" },
        ["nan wu e mi tuo fo"] = { text = "南无阿弥陀佛", comment = "nā mó ē mí tuó fó" },
        ["gei yu"] = { text = "给予", comment = "jǐ yǔ" },
        ["bin lang"] = { text = "槟榔", comment = "bīng láng" },
        ["zhang bai zhi"] = { text = "张柏芝", comment = "zhāng bó zhī" },
        ["teng man"] = { text = "藤蔓", comment = "téng wàn" },
        ["nong tang"] = { text = "弄堂", comment = "lòng táng" },
        ["xin kuan ti pang"] = { text = "心宽体胖", comment = "xīn kūan tǐ pán" },
        ["mai yuan"] = { text = "埋怨", comment = "mán yuàn" },
        ["xu yu wei she"] = { text = "虚与委蛇", comment = "xū yǔ wēi yí" },
        ["mu na"] = { text = "木讷", comment = "mù nè" },
        ["du le le"] = { text = "独乐乐", comment = "dú yuè lè" },
        ["zhong le le"] = { text = "众乐乐", comment = "zhòng yuè lè" },
        ["xun ma"] = { text = "荨麻", comment = "qián má" },
        ["qian ma zhen"] = { text = "荨麻疹", comment = "xún má zhěn" },
        ["mo ju"] = { text = "模具", comment = "mú jù" },
        ["cao zhi"] = { text = "草薙", comment = "cǎo tì" },
        ["cao zhi jing"] = { text = "草薙京", comment = "cǎo tì jīng" },
        ["cao zhi jian"] = { text = "草薙剑", comment = "cǎo tì jiàn" },
        ["jia ping ao"] = { text = "贾平凹", comment = "jià píng wā" },
        ["xue fo lan"] = { text = "雪佛兰", comment = "xuě fú lán" },
        ["qiang jin"] = { text = "强劲", comment = "qiáng jìng" },
        ["tong ti"] = { text = "胴体", comment = "dòng tǐ" },
        ["li neng kang ding"] = { text = "力能扛鼎", comment = "lì néng gāng dǐng" },
        ["ya lv jiang"] = { text = "鸭绿江", comment = "yā lù jiāng" },
        ["da fu bian bian"] = { text = "大腹便便", comment = "dà fù pián pián" },
        ["ka bo zi"] = { text = "卡脖子", comment = "qiǎ bó zi" },
        ["zhi sheng"] = { text = "吱声", comment = "zī shēng" },
        ["chan he"] = { text = "掺和", comment = "chān huo" },
        ["can huo"] = { text = "掺和", comment = "chān huo" },
        ["can he"] = { text = "掺和", comment = "chān huo" },
        ["cheng zhi"] = { text = "称职", comment = "chèn zhí" },
        ["luo shi fen"] = { text = "螺蛳粉", comment = "luó sī fěn" },
        ["tiao huan"] = { text = "调换", comment = "diào huàn" },
        ["tai xing shan"] = { text = "太行山", comment = "tài háng shān" },
        ["jie si di li"] = { text = "歇斯底里", comment = "xiē sī dǐ lǐ" },
        ["nuan he"] = { text = "暖和", comment = "nuǎn huo" },
        ["mo ling liang ke"] = { text = "模棱两可", comment = "mó léng liǎng kě" },
        ["pan yang hu"] = { text = "鄱阳湖", comment = "pó yáng hú" },
        ["bo jing"] = { text = "脖颈", comment = "bó gěng" },
        ["bo jing er"] = { text = "脖颈儿", comment = "bó gěng er" },
        ["jie zha"] = { text = "结扎", comment = "jié zā" },
        ["hai shen wei"] = { text = "海参崴", comment = "hǎi shēn wǎi" },
        ["hou pu"] = { text = "厚朴", comment = "hòu pò " },
        ["da wan ma"] = { text = "大宛马", comment = "dà yuān mǎ" },
        ["ci ya"] = { text = "龇牙", comment = "zī yá" },
        ["ci zhe ya"] = { text = "龇着牙", comment = "zī zhe yá" },
        ["ci ya lie zui"] = { text = "龇牙咧嘴", comment = "zī yá liě zuǐ" },
        ["tou pi xue"] = { text = "头皮屑", comment = "tóu pi xiè" },
        ["liu an shi"] = { text = "六安市", comment = "lù ān shì" },
        ["liu an xian"] = { text = "六安县", comment = "lù ān xiàn" },
        ["an hui sheng liu an shi"] = { text = "安徽省六安市", comment = "ān huī shěng lù ān shì" },
        ["an hui liu an"] = { text = "安徽六安", comment = "ān huī lù ān" },
        ["an hui liu an shi"] = { text = "安徽六安市", comment = "ān huī lù ān shì" },
        ["nan jing liu he"] = { text = "南京六合", comment = "nán jīng lù hé" },
        ["nan jing shi liu he"] = { text = "南京六合区", comment = "nán jīng lù hé qū" },
        ["nan jing shi liu he qu"] = { text = "南京市六合区", comment = "nán jīng shì lù hé qū" },
        ["nuo da"] = { text = "偌大", comment = "偌(ruò)大" },
        ["yin jiu zhi ke"] = { text = "饮鸩止渴", comment = "饮鸩(zhèn)止渴" },
        ["yin jiu jie ke"] = { text = "饮鸩解渴", comment = "饮鸩(zhèn)解渴" },
        ["gong shang jiao zhi yu"] = { text = "宫商角徵羽", comment = "宫商角(jué)徵羽" },
        -- 错字
        ["pu jie"] = { text = "扑街", comment = "仆街" },
        ["pu gai"] = { text = "扑街", comment = "仆街" },
        ["pu jie zai"] = { text = "扑街仔", comment = "仆街仔" },
        ["pu gai zai"] = { text = "扑街仔", comment = "仆街仔" },
        ["ceng jin"] = { text = "曾今", comment = "曾经" },
        ["an nai"] = { text = "按耐", comment = "按捺(nà)" },
        ["an nai bu zhu"] = { text = "按耐不住", comment = "按捺(nà)不住" },
        ["bie jie"] = { text = "别介", comment = "别价(jie)" },
        ["beng jie"] = { text = "甭介", comment = "甭价(jie)" },
        ["xue mai pen zhang"] = { text = "血脉喷张", comment = "血脉贲(bēn)张 | 血脉偾(fèn)张" },
        ["qi ke fu"] = { text = "契科夫", comment = "契诃(hē)夫" },
        ["zhao cha"] = { text = "找茬", comment = "找碴" },
        ["zhao cha er"] = { text = "找茬儿", comment = "找碴儿" },
        ["da jia lai zhao cha"] = { text = "大家来找茬", comment = "大家来找碴" },
        ["da jia lai zhao cha er"] = { text = "大家来找茬儿", comment = "大家来找碴儿" },
        ["cou huo"] = { text = "凑活", comment = "凑合(he)" },
        ["ju hui"] = { text = "钜惠", comment = "巨惠" },
        ["mo xie zuo"] = { text = "魔蝎座", comment = "摩羯(jié)座" },
        ["pi sa"] = { text = "披萨", comment = "比(bǐ)萨" },
    }
end

function M.func(input, env)
    for cand in input:iter() do
        -- cand.comment 是目前输入的词汇的完整拼音
        local pinyin = cand.comment:match("^［(.-)］$")
        if pinyin and #pinyin > 0 then
            local correction_pinyin = pinyin
            if env.delimiter then
                correction_pinyin = correction_pinyin:gsub(env.delimiter,' ')
            end
            local c = M.corrections[correction_pinyin]
            if c and cand.text == c.text then
                cand:get_genuine().comment = string.gsub(M.style, "{comment}", c.comment)
            else
                if env.keep_comment then
                    cand:get_genuine().comment = string.gsub(M.style, "{comment}", pinyin)
                else
                    cand:get_genuine().comment = ""
                end
            end
        end
        yield(cand)
    end
end

return M
