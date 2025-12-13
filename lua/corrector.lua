--[[
	错音错字提示。
	示例：「给予」的正确读音是 ji yu，当用户输入 gei yu 时，在候选项的 comment 显示正确读音
	示例：「按耐」的正确写法是「按捺」，当用户输入「按耐」时，在候选项的 comment 显示正确写法

	关闭此 Lua 时，同时需要关闭 translator/spelling_hints，否则 comment 里都是拼音

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
        ["jiao se"] = { text = "角色", comment = "jué sè" },
        ["chi pi sa"] = { text = "吃比萨", comment = "chī bǐ sà" },
        ["pi sa bing"] = { text = "比萨饼", comment = "bǐ sà bǐng" },
        ["shui fu"] = { text = "说服", comment = "shuō fú" },
        ["dao hang"] = { text = "道行", comment = "dào heng" },
        ["mo yang"] = { text = "模样", comment = "mú yàng" },
        ["you mo you yang"] = { text = "有模有样", comment = "yǒu mú yǒu yàng" },
        ["yi mo yi yang"] = { text = "一模一样", comment = "yī mú yī yàng" },
        ["zhuang mo zuo yang"] = { text = "装模作样", comment = "zhuāng mú zuò yàng" },
        ["ren mo gou yang"] = { text = "人模狗样", comment = "rén mú gǒu yàng" },
        ["mo ban"] = { text = "模板", comment = "mú bǎn" },
        ["a mi tuo fo"] = { text = "阿弥陀佛", comment = "ē mí tuó fó" },
        ["na mo a mi tuo fo"] = { text = "南无阿弥陀佛", comment = "nā mó ē mí tuó fó" },
        ["nan wu a mi tuo fo"] = { text = "南无阿弥陀佛", comment = "nā mó ē mí tuó fó" },
        ["nan wu e mi tuo fo"] = { text = "南无阿弥陀佛", comment = "nā mó ē mí tuó fó" },
        ["sha di li"] = { text = "刹帝利", comment = "chà dì lì" },
        ["gei yu"] = { text = "给予", comment = "jǐ yǔ" },
        ["bin lang"] = { text = "槟榔", comment = "bīng láng" },
        ["zhang bai zhi"] = { text = "张柏芝", comment = "zhāng bó zhī" },
        ["teng man"] = { text = "藤蔓", comment = "téng wàn" },
        ["nong tang"] = { text = "弄堂", comment = "lòng táng" },
        ["xin kuan ti pang"] = { text = "心宽体胖", comment = "xīn kuān tǐ pán" },
        ["mai yuan"] = { text = "埋怨", comment = "mán yuàn" },
        ["xu yu wei she"] = { text = "虚与委蛇", comment = "xū yǔ wēi yí" },
        ["mu na"] = { text = "木讷", comment = "mù nè" },
        ["gui lie"] = { text = "龟裂", comment = "jūn liè" },
        ["du le le"] = { text = "独乐乐", comment = "dú yuè lè" },
        ["zhong le le"] = { text = "众乐乐", comment = "zhòng yuè lè" },
        ["xun ma"] = { text = "荨麻", comment = "qián má" },
        ["qian ma zhen"] = { text = "荨麻疹", comment = "xún má zhěn" },
        ["mo ju"] = { text = "模具", comment = "mú jù" },
        ["cao zhi"] = { text = "草薙", comment = "cǎo tì" },
        ["cao zhi jing"] = { text = "草薙京", comment = "cǎo tì jīng" },
        ["cao zhi jian"] = { text = "草薙剑", comment = "cǎo tì jiàn" },
        ["jia ping ao"] = { text = "贾平凹", comment = "jiǎ píng wā" },
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
        ["fa xiao"] = { text = "发酵", comment = "fā jiào" },
        ["xiao mu jun"] = { text = "酵母菌", comment = "jiào mǔ jūn" },
        ["yin hong"] = { text = "殷红", comment = "yān hóng" },
        ["nuan he"] = { text = "暖和", comment = "nuǎn huo" },
        ["mo ling liang ke"] = { text = "模棱两可", comment = "mó léng liǎng kě" },
        ["pan yang hu"] = { text = "鄱阳湖", comment = "pó yáng hú" },
        ["bo jing"] = { text = "脖颈", comment = "bó gěng" },
        ["bo jing er"] = { text = "脖颈儿", comment = "bó gěng er" },
        ["niu pi xian"] = { text = "牛皮癣", comment = "niú pí xuǎn" },
        ["hua ban xian"] = { text = "花斑癣", comment = "huā bān xuǎn" },
        ["ti xian"] = { text = "体癣", comment = "tǐ xuǎn" },
        ["gu xian"] = { text = "股癣", comment = "gǔ xuǎn" },
        ["jiao xian"] = { text = "脚癣", comment = "jiǎo xuǎn" },
        ["zu xian"] = { text = "足癣", comment = "zú xuǎn" },
        ["jie zha"] = { text = "结扎", comment = "jié zā" },
        ["hai shen wei"] = { text = "海参崴", comment = "hǎi shēn wǎi" },
        ["hou pu"] = { text = "厚朴", comment = "hòu pò " },
        ["da wan ma"] = { text = "大宛马", comment = "dà yuān mǎ" },
        ["ci ya"] = { text = "龇牙", comment = "zī yá" },
        ["ci zhe ya"] = { text = "龇着牙", comment = "zī zhe yá" },
        ["ci ya lie zui"] = { text = "龇牙咧嘴", comment = "zī yá liě zuǐ" },
        ["tou pi xue"] = { text = "头皮屑", comment = "tóu pí xiè" },
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
        ["shan qi deng"] = { text = "氙气灯", comment = "氙(xiān)气灯" },
        ["shan qi da deng"] = { text = "氙气大灯", comment = "氙(xiān)气大灯" },
        ["shan qi shou dian tong"] = { text = "氙气手电筒", comment = "氙(xiān)气手电筒" },
        ["yin gai"] = { text = "应该", comment = "应(yīng)该" },
        ["nian tie"] = { text = "粘贴", comment = "粘(zhān)贴" },
        ["nian yi nian"] = { text = "粘一粘", comment = "粘(zhān)" },
        ["gao ju li"] = { text = "高句丽", comment = "高句(gōu)丽" },
        ["jiao dou shi"] = { text = "角斗士", comment = "角(jué)斗士" },
        ["suo sha mi"] = { text = "缩砂密", comment = "缩(sù)砂密" },
        ["po ji pao"] = { text = "迫击炮", comment = "迫(pǎi)击炮" },
        ["feng chan"] = { text = "封禅", comment = "fēng shàn" },
        ["yuan sui"] = { text = "芫荽", comment = "yán suī" },
        ["wen bo"] = { text = "榅桲", comment = "wēn po" },
        ["bi ji"] = { text = "荸荠", comment = "bí qi" },
        ["rou yi"] = { text = "柔荑", comment = "róu tí" },
        ["rou yi hua xu"] = { text = "柔荑花序", comment = "柔荑(tí)花序" },
        ["shou ru rou yi"] = { text = "手如柔荑", comment = "手如柔荑(tí)" },
        ["wen ting jun"] = { text = "温庭筠", comment = "温庭筠(yún)" },
        ["zhu you tang"] = { text = "朱祐樘", comment = "朱祐樘(chēng)" },
        ["guan ka"] = { text = "关卡", comment = "guān qiǎ" },
        ["san wei zhen huo"] = { text = "三昧真火", comment = "三昧(mèi)真火" },
        ["qing ping zhi mo"] = { text = "青𬞟之末", comment = "青𬞟(pín)之末" },
        ["qi yu qing ping zhi mo"] = { text = "起于青𬞟之末", comment = "起于青𬞟(pín)之末" },
        ["feng qi yu qing ping zhi mo"] = { text = "风起于青𬞟之末", comment = "风起于青𬞟(pín)之末" },
        ["you hui juan"] = { text = "优惠券", comment = "优惠券(quàn)" },
        ["gong quan"] = { text = "拱券", comment = "gǒng xuàn" },
        ["pu ru"] = { text = "哺乳", comment = "bǔ rǔ" },
        ["nao zu zhong"] = { text = "脑卒中", comment = "nǎo cù zhòng" },
        ["fa zhi"] = { text = "阈值", comment = "yù zhí" },
        ["xie hu"] = { text = "潟湖", comment = "xì hú" },
        ["guo pu"] = { text = "果脯", comment = "guǒ fǔ" },
        ["rou pu"] = { text = "肉脯", comment = "ròu fǔ" },
        ["huo luo"] = { text = "饸饹", comment = "hé le" },
        ["pu an suan"] = { text = "脯氨酸", comment = "脯(fǔ)氨酸" },
        ["luo an suan"] = { text = "酪氨酸", comment = "酪(lào)氨酸" },
        ["mei shi zi"] = { text = "没食子", comment = "没(mò)食子" },
        ["shang feng die"] = { text = "裳凤蝶", comment = "裳(cháng)凤蝶" },
        ["bai qi tun"] = { text = "白𬶨豚", comment = "bái jì tún" },
        ["nao gu"] = { text = "桡骨", comment = "ráo gǔ" },
        ["bai zhe bu rao"] = { text = "百折不挠", comment = "百折不挠(náo)" },
        ["zhui xin qi xie"] = { text = "椎心泣血", comment = "椎(chuí)心泣血" },
        ["zhui xin qi xue"] = { text = "椎心泣血", comment = "椎(chuí)心泣血" },
        ["xia chi"] = { text = "挟持", comment = "挟(xié)持" },
        ["hao zhou"] = { text = "亳州", comment = "亳(bó)州" },
        ["niu jing"] = { text = "牛丼", comment = "牛丼(dǎn)" },
        ["niu jing fan"] = { text = "牛丼饭", comment = "牛丼(dǎn)饭" },
        ["an pou"] = { text = "安瓿", comment = "安瓿(bù)" },
        ["an pou ping"] = { text = "安瓿瓶", comment = "安瓿(bù)瓶" },
        ["jie pao"] = { text = "解剖", comment = "jiě pōu" },
        ["pao fen"] = { text = "剖分", comment = "pōu fēn" },
        ["pao fu chan"] = { text = "剖腹产", comment = "剖(pōu)腹产" },
        ["pao gong chan"] = { text = "剖宫产", comment = "剖(pōu)宫产" },
        ["jin kui"] = { text = "金匮", comment = "金匮(guì)" },
        ["qing ping le"] = { text = "清平乐", comment = "清平乐(yuè)" },
        ["ta sha xing"] = { text = "踏莎行", comment = "踏莎(suō)行" },
        ["sha cao"] = { text = "莎草", comment = "suō cǎo" },
        ["shan mu"] = { text = "杉木", comment = "shā mù" },
        ["ju mai cai"] = { text = "苣荬菜", comment = "qǔ mǎi cài" },
        ["li li"] = { text = "李悝", comment = "lǐ kuī" },
        ["gui bu"] = { text = "跬步", comment = "kuǐ bù" },
        ["dao zai shi ni"] = { text = "道在屎溺", comment = "道在屎溺(niào)" },
        ["bao lian tian wu"] = { text = "暴殄天物", comment = "暴殄(tiǎn)天物" },
        ["yi ji du ren"] = { text = "以己度人", comment = "以己度(duó)人" },
        ["jing gao"] = { text = "甑糕", comment = "甑(zèng)糕" },
        ["zhao xiang"] = { text = "着想", comment = "着(zhuó)想" },
        ["ge zhi wo"] = { text = "胳肢窝", comment = "胳(gā)肢窝" },
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
        ["geng quan"] = { text = "梗犬", comment = "㹴犬" },
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
