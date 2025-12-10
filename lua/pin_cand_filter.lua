-- 置顶候选项
--[[
 ====================================《说明书》============================================
 符合左边的编码(preedit)时，按顺序置顶右边的候选项。只是提升已有候选项的顺序，没有自创编码的功能。
 脚本对比的是去掉空格的 cand.preedit，配置里写空格可以生成额外的编码，参考示例。
 
 cand.preedit 是经过 translator/preedit_format 转换后的编码
 ⚠️ 注意方案的 preedit_format 设定，如果 v 显示为 ü，那么左边也要写 ü
 ⚠️ 双拼：如果用户配置了编码框显示为全拼拼写就要写全拼，如 'shuang pin'，显示为双拼拼写就要写双拼，如 'ul pb'
 
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

-- ===================== 核心配置 =====================
 -- 日志开关：true=开启日志（调试），false=关闭日志（上线）
 local LOG_ENABLE = false

 -- 全局配置表：存储所有编码的置顶规则（多窗口切换时共享）
 local GLOBAL_PIN_CANDS = {}
 -- 初始化完成标记：避免多窗口重复解析配置
 local GLOBAL_INIT_DONE = false

-- ===================== 工具函数 =====================
 -- 功能：查找字符串在数组中的索引位置（从1开始）
 -- 参数：list - 目标数组（如{"了","乐","仂","勒"}），str - 要查找的字符串
 -- 返回：找到返回索引，未找到返回0
 local function find_index(list, str)
    -- ipairs遍历连续数字索引数组（适合有序列表）
    for i, v in ipairs(list) do
        if v == str then
            return i -- 找到立即返回索引，结束函数
        end
    end
    return 0 -- 未找到返回0
 end

 -- 功能：写入日志到指定文件（受LOG_ENABLE控制）
 -- 参数：content - 要写入的日志内容
 local function write_single_log(content)
    if not LOG_ENABLE then return end -- 日志关闭时直接返回
    local log_path = "D:\\Rime\\Customer\\pin_cand_filter.log"
    local f = io.open(log_path, "a+") -- 以追加模式打开文件
    if f then
        f:write(content)
        f:close() -- 必须关闭文件，避免句柄泄漏
        f = nil
    end
 end

-- ===================== 核心逻辑 =====================
 local M = {} -- 暴露给Rime的核心表（必须返回）

 -- 功能：脚本初始化（Rime启动/新窗口打开时执行）
 -- 参数：env - Rime传入的环境上下文（系统变量）
 function M.init(env)
    -- 若全局配置已初始化，直接复用并结束函数(如，多窗口切换时跳过)
    if GLOBAL_INIT_DONE then
        write_single_log(string.format(
            "[%s] 全局表已初始化，当前实例直接复用 | env=%s\n",
            os.date("%Y-%m-%d %H:%M:%S"),
            tostring(env)
        ))
        env.pin_cands = GLOBAL_PIN_CANDS -- 绑定全局配置到当前窗口
        return
    end
    -- 日志：记录初始化开始
    write_single_log(string.format(
        "[%s] pin_cand_filter 模块初始化 | env=%s\n",
        os.date("%Y-%m-%d %H:%M:%S"),
        tostring(env)
    ))
    -- 日志：空值保护，env为nil时直接终止
    if not env then 
        write_single_log("[ERROR] 初始化失败：env 为 nil\n")
        return 
    end
    -- 处理命名空间：去除前缀*，兜底为 pin_cand_filter
    env.name_space = env.name_space and env.name_space:gsub("^*", "") or "pin_cand_filter"

    -- 读取配置列表：逐层判空避免崩溃，双路径兜底（命名空间+顶级配置）
    local list = nil
    if env.engine and env.engine.schema and env.engine.schema.config then
        list = env.engine.schema.config:get_list(env.name_space) or env.engine.schema.config:get_list("pin_cand_filter")
    end
    -- 配置列表为空/无效时，记录日志并终止
    if not list or list.size == 0 then 
        write_single_log("[ERROR] 未找到 pin_cand_filter 配置列表，list 为空\n")
        return 
    end
    write_single_log(string.format("[INFO] 成功读取配置，list 大小=%d\n", list.size))

	-- 用户定义编码的快速查询字典 --
    -- 把用户在 pin_cand_filter 中定义的所有有效编码（清洗掉空格后）存入 set 这个「集合表」，
    -- 目的是，如果明确定义了 'da z' 或 'da zh'，则会比`da zhuan`优先使用这些明确自定义的编码，用 set 来做判断。
    local set = {}
    for i = 0, list.size - 1 do
        local item = list:get_value_at(i).value or "" -- 空值兜底
        local preedit, texts = item:match("([^\t]+)\t(.+)") -- 拆分编码和置顶词如 "le[制表符]了 乐 仂 勒"，preedit=="le"，texts=="了 乐 仂 勒"
        preedit = preedit or ""
        texts = texts or ""
        if #preedit > 0 and #texts > 0 then
            set[preedit:gsub(" ", "")] = true -- 存储无空格的编码
        end
    end

    -- 解析配置：生成置顶规则表 --
	 -- 遍历要置顶的候选项列表，将其转换为 table 存储到 GLOBAL_PIN_CANDS
     -- 'l	了 啦' → GLOBAL_PIN_CANDS["l"] = {"了", "啦"}
     -- 'ta	他 她 它' → GLOBAL_PIN_CANDS["ta"] = {"他", "她", "它"}
     --
     -- 无空格的键，如 `nihao	你好` → GLOBAL_PIN_CANDS["nihao"] = {"你好"}
     --
     -- 包含空格的的键，同时生成简码的拼写（最后一个空格后的首字母），如：
     -- 'ni hao	你好 拟好' → GLOBAL_PIN_CANDS["nihao"] = {"你好", "拟好"}
     --                   → GLOBAL_PIN_CANDS["nih"] = {"你好", "拟好"}
     --
     -- 如果最后一个空格后以 zh ch sh 开头，额外再生成 zh, ch, sh 的拼写，如：
     -- 'zhi chi	支持' → GLOBAL_PIN_CANDS["zhichi"] = {"支持"}
     --               → GLOBAL_PIN_CANDS["zhic"] = {"支持"}
     --               → GLOBAL_PIN_CANDS["zhich"] = {"支持"}
     --
     -- 如果同时定义了 'da zhuan	大专' 'da zhong	大众'，会生成：
     -- GLOBAL_PIN_CANDS["dazhuan"] = {"大专"}
     -- GLOBAL_PIN_CANDS["dazhong"] = {"大众"}
     -- GLOBAL_PIN_CANDS["daz"] = {"大专", "大众"}  -- 先写的排在前面
     -- GLOBAL_PIN_CANDS["dazh"] = {"大专", "大众"} -- 先写的排在前面
     --
     -- 如果同时定义了 'da zhuan	大专' 'da zhong	大众' 且明确定义了简码形式 'da z	打字'，会生成：
     -- GLOBAL_PIN_CANDS["dazhuan"] = {"大专"}
     -- GLOBAL_PIN_CANDS["dazhong"] = {"大众"}
     -- GLOBAL_PIN_CANDS["daz"] = {"打字"}          -- 明确定义的优先级更高
     -- GLOBAL_PIN_CANDS["dazh"] = {"大专", "大众"}  -- 没明确定义的，仍然按上面的方式，先写的排在前面
    GLOBAL_PIN_CANDS = {}
    for i = 0, list.size - 1 do
        local item = list:get_value_at(i).value or ""
        local preedit, texts = item:match("([^\t]+)\t(.+)")
        preedit = preedit or ""
        texts = texts or ""
        
        if #preedit > 0 and #texts > 0 then
            -- 拆分置顶词：支持" > "或" "分隔
            local delimiter = "\0"
            if texts:find(" > ") then
                texts = texts:gsub(" > ", delimiter)
            else
                texts = texts:gsub(" ", delimiter)
            end

            -- 生成无空格的编码键，存储置顶词列表
            local preedit_no_spaces = preedit:gsub(" ", "")
            GLOBAL_PIN_CANDS[preedit_no_spaces] = {}
            for text in texts:gmatch("[^" .. delimiter .. "]+") do
                table.insert(GLOBAL_PIN_CANDS[preedit_no_spaces], text)
            end
            write_single_log(string.format("[INFO] 基础映射生成：%s → %s\n", preedit_no_spaces, table.concat(GLOBAL_PIN_CANDS[preedit_no_spaces], ",")))

            -- 处理带空格的编码：自动生成简码（最后一个拼音首字母/zh/ch/sh）
            if preedit:find(" ") then
                local preceding_part, last_part = preedit:match("^(.+)%s(%S+)$")
                local p1, p2 = "", ""
                -- 判空后生成简码，避免nil拼接错误
                if preceding_part and last_part then
                    p1 = preceding_part:gsub(" ", "") .. last_part:sub(1, 1) -- 首字母简码
                    if last_part:match("^[zcs]h") then
                        p2 = preceding_part:gsub(" ", "") .. last_part:sub(1, 2) -- zh/ch/sh简码
                    end
                end

                -- 仅在未手动定义简码时生成，避免覆盖
                for _, p in ipairs({ p1, p2 }) do
                    if p ~= "" and not set[p] then
                        if GLOBAL_PIN_CANDS[p] then
                            -- 已有简码则追加置顶词
                            for text in texts:gmatch("[^" .. delimiter .. "]+") do
                                table.insert(GLOBAL_PIN_CANDS[p], text)
                            end
                        else
                            -- 无简码则直接赋值
                            GLOBAL_PIN_CANDS[p] = GLOBAL_PIN_CANDS[preedit_no_spaces]
                        end
                        write_single_log(string.format("[INFO] 自动简码生成：%s → %s\n", p, table.concat(GLOBAL_PIN_CANDS[p], ",")))
                    end
                end
            end
        end
    end

    -- 统计配置表大小（字符串键需用pairs遍历）
    local map_count = 0
    for _, _ in pairs(GLOBAL_PIN_CANDS) do map_count = map_count + 1 end
    
    -- 标记全局配置初始化完成，绑定到当前窗口
    GLOBAL_INIT_DONE = true
    env.pin_cands = GLOBAL_PIN_CANDS
    write_single_log(string.format("[INFO] 全局表初始化完成，总映射数=%d\n", map_count))

 end

-- 功能：候选词过滤逻辑（输入编码时实时执行）
-- 参数：input - 候选词迭代器，env - 环境上下文
function M.func(input, env)
    -- 空值保护：input/env为空时兜底
    input = input or {}
    env = env or {}

    -- 绑定全局配置到当前窗口
    if GLOBAL_INIT_DONE then
        env.pin_cands = GLOBAL_PIN_CANDS
        write_single_log(string.format("[INFO] 当前实例同步全局表：le → %s\n", table.concat(env.pin_cands["le"] or {"空"}, ",")))
    else
        write_single_log("[WARN] 全局表未初始化，env.pin_cands 赋值为空\n")
        env.pin_cands = {}
    end

    -- 读取输入码：优先原始输入（context.input），兜底编辑区文本
    local full_preedit = ""
    local letter_only_preedit = ""
    if env and type(env) == "table" and env.engine and env.engine.context then
        full_preedit = env.engine.context.input or "" -- 原始输入（如le）
        if full_preedit == "" then
            local preedit_obj = env.engine.context:get_preedit()
            full_preedit = (preedit_obj and preedit_obj.text) or "" -- 编辑区文本（如你好le）
        end
        letter_only_preedit = string.gsub(full_preedit, "[^a-zA-Z]", "") -- 提取纯字母编码
    end

    -- 记录输入日志
    write_single_log(string.format(
        "[%s] 过滤触发 | 原始输入=%s | 纯字母编码=%s\n",
        os.date("%Y-%m-%d %H:%M:%S"),
        tostring(full_preedit),
        tostring(letter_only_preedit)
    ))

    -- 空值保护：配置/输入码为空时，直接返回原始候选词
    local pin_cands = env.pin_cands or {}
    local pin_cands_not_empty = next(pin_cands) ~= nil
    local has_letter_input = #letter_only_preedit > 0
    if not pin_cands_not_empty or not has_letter_input then
        write_single_log(string.format(
            "[%s]  无匹配置顶规则，直接返回候选词 | 配置已定义=%s | 规则表非空=%s | 有字母输入=%s\n",
            os.date("%Y-%m-%d %H:%M:%S"),
            tostring(env.pin_cands ~= nil),
            tostring(pin_cands_not_empty),
            tostring(has_letter_input)
        ))
        if input.iter and type(input.iter) == "function" then
            for cand in input:iter() do yield(cand) end
        end
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
    -- 初始化置顶/其余候选词数组
    local pined = {}  -- 按配置顺序置顶的候选词
    local others = {} -- 不参与置顶的候选词
    local pined_count = 0 -- 已找到的置顶词数量

    -- 迭代器判空：避免调用nil方法崩溃
    if not (input.iter and type(input.iter) == "function") then
        write_single_log("[ERROR] input.iter 方法不存在，直接返回候选\n")
        if input.iter and type(input.iter) == "function" then
            for cand in input:iter() do yield(cand) end
        end
        return
    end
	
    -- 遍历候选词，按规则排序
    for cand in input:iter() do
         -- 处理候选词编码：空值兜底，空编码时用输入码替代
        local preedit = (cand.preedit or ""):gsub(" ", "") -- 对比去掉空格的 cand.preedit
        if preedit == "" then
            preedit = letter_only_preedit
        end
        local texts = pin_cands[preedit] -- 获取当前编码的置顶规则

        -- 记录候选词匹配日志
        write_single_log(string.format(
            "  候选词：%s | 编码：%s | 匹配规则：%s\n",
            cand.text or "",
            preedit,
            texts and "是" or "否"
        ))

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
            local idx = find_index(texts, cand.text or "")
            if idx ~= 0 then
                pined[idx] = cand
                pined_count = pined_count + 1
				write_single_log(string.format("    → 置顶成功：%s（位置：%d）\n", cand.text or "", idx))
            else
                table.insert(others, cand)
            end
            -- 找齐了或查询超过 100 个就不找了（如果要提升的候选项不在前 100 则不会被提升）
            if pined_count == #texts or #others > 50 then
                break
            end
        end
    end

    -- 记录置顶结果日志
    write_single_log(string.format(
        "[%s] 置顶完成 | 置顶数量：%d | 其余候选数量：%d\n",
        os.date("%Y-%m-%d %H:%M:%S"),
        pined_count,
        #others
    ))

    -- 输出置顶候选词
    for _, cand in ipairs(pined) do
        if cand ~= "" then
            yield(cand)
        end
    end
	-- 输出其余候选词
    for _, cand in ipairs(others) do
        yield(cand)
    end
	-- 输出剩余候选词
     if input.iter and type(input.iter) == "function" then
        for cand in input:iter() do
            yield(cand)
        end
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
