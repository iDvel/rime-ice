-- 置顶候选项
--[[
《说明书》

符合左边的编码(preedit)时，按顺序置顶右边的候选项。只是提升已有候选项的顺序，没有自创编码的功能。
脚本对比的是去掉空格的 cand.preedit，配置里写空格可以生成额外的编码，参考示例。

cand.preedit 是经过 translator/preedit_format 转换后的编码
⚠️ 注意方案的 preedit_format 设定，如果 v 显示为 ü，那么左边也要写 ü
⚠️ 双拼：显示为全拼拼写就要写全拼，如 'shuang pin'，显示为双拼拼写就要写双拼，如 'ul pb'

格式：编码<Tab>字词1<Space>字词2……
按照 YAML 语法，加不加引号都行，也可以这么写 pin_cand_filter: [l	了, 'de	的', "ni hao	你好"]

示例：（文件末尾有常见编码可供直接复制参考）
- 'le	了'       # 输入 le 时，置顶「了」
- 'ta	他 她 它'  # 可以置顶多个字，按顺序排列
- 'l	了 啦'    # 支持单编码，输入 l 时，置顶「了、啦」
- 'l	了 > 啦'  # 右边的字词如果包含空格，用 > 分割也行（大于号左右必须有空格）
- 'ta	啊'     # ❌ 编码不会产生的字词，不会生效且影响查找效率。自创编码的字词句可以写到 custom_phrase 中。
- 'hao	好 👌'  # ❌ 不要写 emoji

### 简拼
支持简拼，简拼加不加空格都行。但需要方案开启简拼，雾凇全拼是默认开启的，双拼默认没开启
- s m	什么
- wsm	为什么

### 空格的作用：
- nihao	你好
无空格，生成原样；
生成 nihao，只有输入完整的 nihao 时首位才是「你好」，但输入 nih 时首位可能是「你会 你还」等其他词语。

- ni hao	你好
包含空格，额外生成最后一个空格后的拼音的首字母简码；
生成 nihao nih ，现在输入 nih 时首位也会是「你好」。

- bu hao chi	不好吃
包含空格且结尾以 zh ch sh 开头，再额外生成最后一个空格后的拼音的 zh ch sh 简码；
生成 buhaochi buhaoc buhaoch

### 优先级：
- da zhuang	大专
- da zhong	大众
上面两行，会额外生成 'da z' 'da zh' 的置顶，前两个候选项是「大专、大众」，先写的排在前面

- da z	打字
如果明确定义了简码形式，则完全使用简码形式
此时输入 daz 首位为「打字」，输入 dazh 首位仍为「大专、大众」
--]]

local function find_index(list, str)
    for i, v in ipairs(list) do
        if v == str then
            return i
        end
    end
    return 0
end

local M = {}

function M.init(env)
    env.name_space = env.name_space:gsub("^*", "")

    if env.pin_cands ~= nil then return end

    local list = env.engine.schema.config:get_list(env.name_space)
    if not list or list.size == 0 then return end

    -- 如果定义了 'da zhuan' 或 'da zhong' ，会自动生成 'daz' 和 'dazh' 的键。
    -- 然而，如果明确定义了 'da z' 或 'da zh'，则会优先使用这些明确自定义的简码，用 set 来做判断。
    local set = {}
    for i = 0, list.size - 1 do
        local preedit, texts = list:get_value_at(i).value:match("([^\t]+)\t(.+)")
        if #preedit > 0 and #texts > 0 then
            set[preedit:gsub(" ", "")] = true
        end
    end

    -- 遍历要置顶的候选项列表，将其转换为 table 存储到 env.pin_cands
    -- 'l	了 啦' → env.pin_cands["l"] = {"了", "啦"}
    -- 'ta	他 她 它' → env.pin_cands["ta"] = {"他", "她", "它"}
    --
    -- 无空格的键，如 `nihao	你好` → env.pin_cands["nihao"] = {"你好"}
    --
    -- 包含空格的的键，同时生成简码的拼写（最后一个空格后的首字母），如：
    -- 'ni hao	你好 拟好' → env.pin_cands["nihao"] = {"你好", "拟好"}
    --                   → env.pin_cands["nih"] = {"你好", "拟好"}
    --
    -- 如果最后一个空格后以 zh ch sh 开头，额外再生成 zh, ch, sh 的拼写，如：
    -- 'zhi chi	支持' → env.pin_cands["zhichi"] = {"支持"}
    --               → env.pin_cands["zhic"] = {"支持"}
    --               → env.pin_cands["zhich"] = {"支持"}
    --
    -- 如果同时定义了 'da zhuan	大专' 'da zhong	大众'，会生成：
    -- env.pin_cands["dazhuan"] = {"大专"}
    -- env.pin_cands["dazhong"] = {"大众"}
    -- env.pin_cands["daz"] = {"大专", "大众"}  -- 先写的排在前面
    -- env.pin_cands["dazh"] = {"大专", "大众"} -- 先写的排在前面
    --
    -- 如果同时定义了 'da zhuan	大专' 'da zhong	大众' 且明确定义了简码形式 'da z	打字'，会生成：
    -- env.pin_cands["dazhuan"] = {"大专"}
    -- env.pin_cands["dazhong"] = {"大众"}
    -- env.pin_cands["daz"] = {"打字"}          -- 明确定义的优先级更高
    -- env.pin_cands["dazh"] = {"大专", "大众"}  -- 没明确定义的，仍然按上面的方式，先写的排在前面

    env.pin_cands = {}
    for i = 0, list.size - 1 do
        local preedit, texts = list:get_value_at(i).value:match("([^\t]+)\t(.+)")
        if #preedit > 0 and #texts > 0 then
            -- 按照 " > " 或 " " 分割词汇
            local delimiter = "\0"
            if texts:find(" > ") then
                texts = texts:gsub(" > ", delimiter)
            else
                texts = texts:gsub(" ", delimiter)
            end

            -- 按照键生成完整的拼写
            local preedit_no_spaces = preedit:gsub(" ", "")
            env.pin_cands[preedit_no_spaces] = {}
            for text in texts:gmatch("[^" .. delimiter .. "]+") do
                table.insert(env.pin_cands[preedit_no_spaces], text)
            end

            -- 额外处理包含空格的 preedit，增加最后一个拼音的首字母和 zh, ch, sh 的简码
            if preedit:find(" ") then
                local preceding_part, last_part = preedit:match("^(.+)%s(%S+)$")
                local p2 = ""
                -- p1 生成最后一个拼音的首字母简码拼写（最后一个空格后的首字母），如 ni hao 生成 nih
                local p1 = preceding_part:gsub(" ", "") .. last_part:sub(1, 1)
                -- p2 生成最后一个拼音的 zh, ch, sh 的简码拼写（最后一个空格后以 zh ch sh 开头），如 zhi chi 生成 zhich
                if last_part:match("^[zcs]h") then
                    p2 = preceding_part:gsub(" ", "") .. last_part:sub(1, 2)
                end
                for _, p in ipairs({ p1, p2 }) do
                    -- 只在没有明确定义此简码时才生成，已有的追加，没有的直接赋值
                    if p ~= "" and not set[p] then
                        if env.pin_cands[p] ~= nil then
                            for text in texts:gmatch("[^" .. delimiter .. "]+") do
                                table.insert(env.pin_cands[p], text)
                            end
                        else
                            env.pin_cands[p] = env.pin_cands[preedit_no_spaces]
                        end
                    end
                end
            end
        end
    end
end

function M.func(input, env)
    -- 当前输入框的 preedit，未经过方案 translator/preedit_format 转换
    -- 输入 nihaoshij 则为 nihaoshij，选择了「你好」后变成 你好shij
    local full_preedit = env.engine.context:get_preedit().text
    -- 非汉字部分的 preedit，如 shij
    local letter_only_preedit = string.gsub(full_preedit, "[^a-zA-Z]", "")

    if env.pin_cands == nil or next(env.pin_cands) == nil or #letter_only_preedit == 0 then
        for cand in input:iter() do yield(cand) end
        return
    end

    --[[
        full_preedit 与候选项的情况
            hao        好、号、毫 ... 哈、蛤、铪
            你hao      好、号、毫 ... 哈、蛤、铪
            haobu      好不、毫不 ... 好、号、毫 ... 哈、蛤、铪
            你haobu    好不、毫不 ... 好、号、毫 ... 哈、蛤、铪
        简化为 letter_only_preedit 与候选项的情况
            hao        好、号、毫 ... 哈、蛤、铪
            haobu      好不、毫不 ... 好、号、毫 ... 哈、蛤、铪

        在循环中随着候选项的变化，cand.preedit 也跟着变化：
        ｜ letter_only_preedit ｜        cand.preedit         ｜
        ｜---------------------｜-----------------------------｜
        ｜         dian        ｜    dian ... di              ｜
        ｜         ha          ｜    ha                       ｜
        ｜         hao         ｜    hao ... ha               ｜
        ｜         haobu       ｜    hao bu ... hao ... ha    ｜
    --]]

    -- 用 pined 和 others 调整顺序，找齐后先遍历 pined 再遍历 others
    local pined = {}  -- 提升的候选项
    local others = {} -- 其余候选项
    local pined_count = 0

    for cand in input:iter() do
        local preedit = cand.preedit:gsub(" ", "") -- 对比去掉空格的 cand.preedit
        local texts = env.pin_cands[preedit]

        if texts == nil then
            -- 当前候选项无须排序，直接 yield 并结束循环
            -- 当前候选项正在排序，例如要置顶某个 `hao`，但从 `hao` 查到 `ha` 了还没找齐，不能直接 yield，要先输出 pined 和 others 中的 `hao`
            if letter_only_preedit == preedit then
                yield(cand)
            else
                table.insert(others, cand)
            end
            break
        else
            -- 给 pined 几个空字符串占位元素，后面直接 pined[idx] = cand 确保 pined 与 texts 顺序一致
            if #pined < #texts then
                for _ = 1, #texts do
                    table.insert(pined, "")
                end
            end
            -- 要置顶的放到 pined 中，其余的放到 others
            local idx = find_index(texts, cand.text)
            if idx ~= 0 then
                pined[idx] = cand
                pined_count = pined_count + 1
            else
                table.insert(others, cand)
            end
            -- 找齐了或查询超过 100 个就不找了（如果要提升的候选项不在前 100 则不会被提升）
            if pined_count == #texts or #others > 100 then
                break
            end
        end
    end

    -- yield pined others 及后续的候选项
    for _, cand in ipairs(pined) do
        if cand ~= "" then
            yield(cand)
        end
    end
    for _, cand in ipairs(others) do
        yield(cand)
    end
    for cand in input:iter() do
        yield(cand)
    end
end

return M


--[[
# 常用编码示例
pin_cand_filter:
  # 格式：编码<Tab>字词1<Space>字词2……
  # 单编码
  - q	去 千
  - w	我 万 往
  - e	呃
  - r	让 人
  - t	他 她 它 祂
  - y	与 于
  # - u 在 custom_phrase 置顶了 有 🈶 又 由
  # - i 在 custom_phrase 置顶了 一 以 已 亦
  - o	哦
  - p	片 篇
  - a	啊
  - s	是 时 使 式
  - d	的 地 得
  - f	发 放 分
  - g	个 各
  - h	和 或
  - j	及 将 即 既 继
  - k	可
  - l	了 啦 喽 嘞
  - z	在 再 自
  - x	想 像 向
  - c	才 从
  # - v
  - b	吧 把 呗 百
  - n	那 哪 拿 呐
  - m	吗 嘛  # 置顶一个来覆盖 custom_phrase.txt 呒(ḿ) 呣(ḿ)
  # 常用单字
  - hm	后面  # 置顶一个覆盖 custom_phrase.txt 噷(hm)
  - qing	请
  - qu	去
  - wo	我
  - wei	为
  - er	而 儿 二
  - en	嗯
  - rang	让
  - ta	他 她 它 祂
  - tai	太
  - tong	同
  - yu	与 于
  - you	有 又 由
  - yao	要
  - ye	也
  - shi	是 时 使 式
  - suo	所
  - shang	上
  - shuo	说
  - de	的 地 得
  - dan	但
  - dou	都
  - dao	到 倒
  - dian	点
  - dang	当
  - dui	对
  - fa	发
  - ge	个 各
  - gang	刚
  - he	和
  - huo	或
  - hui	会
  - hai	还
  - hao	好
  - ji	及 即 既
  - jiu	就
  - jiang	将
  - ke	可
  - kan	看
  - kai	开
  - le	了
  - la	啦 拉
  - lai	来
  - li	里
  - zai	在 再
  - zhi	只
  - zhe	这 着
  - zhen	真
  - zui	最
  - zheng	正
  - zuo	做 坐 左
  - ze	则
  - xiang	想 像 向
  - xian	先
  - xia	下
  - xing	行
  - cai	才
  - cong	从
  - chu	出
  - ba	把 吧
  - bu	不
  - bing	并
  - bei	被
  - bie	别
  - bi	比
  - bing	并
  - na	那 哪 拿 呐
  - ni	你
  - ma	吗 嘛 妈
  - mei	没
  - mai	买 卖
  - reng	仍 扔
  # ta、na
  - ta men	他们 她们 它们
  - tm	他们 她们 它们
  - ta de	他的 她的 它的
  - td	他的 她的 它的
  - ta men de	他们的 她们的 它们的
  - na er	那儿 哪儿
  - na ge	那个 哪个
  - ng	那个 哪个 拿个
  - na xie	那些 哪些
  - na li	那里 哪里
  - na bian	那边 哪边
  - na bian er	那边儿 哪边儿
  - na wei	那位 哪位
  # 简码
  - zh	这
  - dd	等等
  - dddd	等等等等
  - gg	刚刚
  - cgg	才刚刚
  - zd	知道
  - bzd	不知道
  - ww	往往
  - hh	哈哈
  - kk	看看
  - cc	常常
  - xx	想想 想象
  - yw	因为
  - sm	什么
  - wsm	为什么
  - sbs	是不是
  - msm	没什么
  - smd	什么的
  - sms	什么是
  - sma	什么啊
--]]
