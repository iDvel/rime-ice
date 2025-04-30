--[[
	Lua 阿拉伯数字转中文实现 https://blog.csdn.net/lp12345678910/article/details/121396243
	农历功能复制自 https://github.com/boomker/rime-fast-xhup
--]]
--
-- 农历，可在方案中配置触发关键字。

-- 数字转中文：

local numerical_units = {
    "",
    "十",
    "百",
    "千",
    "万",
    "十",
    "百",
    "千",
    "亿",
    "十",
    "百",
    "千",
    "兆",
    "十",
    "百",
    "千",
}

local numerical_names = {
    "零",
    "一",
    "二",
    "三",
    "四",
    "五",
    "六",
    "七",
    "八",
    "九",
}

local function convert_arab_to_chinese(number)
    local n_number = tonumber(number)
    assert(n_number, "传入参数非正确number类型!")

    -- 0 ~ 9
    if n_number < 10 then
        return numerical_names[n_number + 1]
    end
    -- 一十九 => 十九
    if n_number < 20 then
        local digit = string.sub(n_number, 2, 2)
        if digit == "0" then
            return "十"
        else
            return "十" .. numerical_names[digit + 1]
        end
    end

    --[[
        1. 最大输入9位
            超过9位，string的len加2位（因为有.0的两位）
            零 ~ 九亿九千九百九十九万九千九百九十九
            0 ~ 999999999
        2. 最大输入14位（超过14位会四舍五入）
            零 ~ 九十九兆九千九百九十九亿九千九百九十九万九千九百九十九万
            0 ~ 99999999999999
    --]]
    local len_max = 9
    local len_number = string.len(number)
    assert(
        len_number > 0 and len_number <= len_max,
        "传入参数位数" .. len_number .. "必须在(0, " .. len_max .. "]之间！"
    )

    -- 01，数字转成表结构存储
    local numerical_tbl = {}
    for i = 1, len_number do
        numerical_tbl[i] = tonumber(string.sub(n_number, i, i))
    end

    local pre_zero = false
    local result = ""
    for index, digit in ipairs(numerical_tbl) do
        local curr_unit = numerical_units[len_number - index + 1]
        local curr_name = numerical_names[digit + 1]
        if digit == 0 then
            if not pre_zero then
                result = result .. curr_name
            end
            pre_zero = true
        else
            result = result .. curr_name .. curr_unit
            pre_zero = false
        end
    end
    result = string.gsub(result, "零+$", "")
    return result
end

-- 农历：

--天干名称
local tianGan = { "甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸" }

--地支名称
local diZhi = { "子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥" }

--属相名称
local shengXiao = { "鼠", "牛", "虎", "兔", "龙", "蛇", "马", "羊", "猴", "鸡", "狗", "猪" }

--农历日期名
local lunarDayShuXu = { "初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
	"十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
	"廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十" }

--农历月份名
local lunarMonthShuXu = { "正", "二", "三", "四", "五", "六", "七", "八", "九", "十", "冬", "腊" }

local daysToMonth365 = { 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334 }
local daysToMonth366 = { 0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335 }

--每个农历月所属的季节名称和季节符号表
local jiJieNames = { '春', '春', '春', '夏', '夏', '夏', '秋', '秋', '秋', '冬', '冬', '冬' }
local jiJieLogos = { '🌱', '🌱', '🌱', '🌾', '🌾', '🌾', '🍂', '🍂', '🍂', '❄', '❄', '❄' }

--[[dateLunarInfo说明：
自1901年起，至2100年每年的农历信息，与万年历核对完成
每年第1个数字为闰月月份
每年第2、3个数字为当年春节所在的阳历月份和日期
每年第4个数字为当年中对应月分的大小进，左边起为1月，往后依次为2月，3月，4月，。。。]]
local BEGIN_YEAR = 1901
local NUMBER_YEAR = 199
local dateLunarInfo = { { 0, 2, 19, 19168 }, { 0, 2, 8, 42352 }, { 5, 1, 29, 21096 }, { 0, 2, 16, 53856 }, { 0, 2, 4, 55632 }, { 4, 1, 25, 27304 },
	{ 0, 2, 13, 22176 }, { 0, 2, 2, 39632 }, { 2, 1, 22, 19176 }, { 0, 2, 10, 19168 }, { 6, 1, 30, 42200 }, { 0, 2, 18, 42192 },
	{ 0, 2, 6, 53840 }, { 5, 1, 26, 54568 }, { 0, 2, 14, 46400 }, { 0, 2, 3, 54944 }, { 2, 1, 23, 38608 }, { 0, 2, 11, 38320 },
	{ 7, 2, 1, 18872 }, { 0, 2, 20, 18800 }, { 0, 2, 8, 42160 }, { 5, 1, 28, 45656 }, { 0, 2, 16, 27216 }, { 0, 2, 5, 27968 },
	{ 4, 1, 24, 44456 }, { 0, 2, 13, 11104 }, { 0, 2, 2, 38256 }, { 2, 1, 23, 18808 }, { 0, 2, 10, 18800 }, { 6, 1, 30, 25776 },
	{ 0, 2, 17, 54432 }, { 0, 2, 6, 59984 }, { 5, 1, 26, 27976 }, { 0, 2, 14, 23248 }, { 0, 2, 4, 11104 }, { 3, 1, 24, 37744 },
	{ 0, 2, 11, 37600 }, { 7, 1, 31, 51560 }, { 0, 2, 19, 51536 }, { 0, 2, 8, 54432 }, { 6, 1, 27, 55888 }, { 0, 2, 15, 46416 },
	{ 0, 2, 5,  22176 }, { 4, 1, 25, 43736 }, { 0, 2, 13, 9680 }, { 0, 2, 2, 37584 }, { 2, 1, 22, 51544 }, { 0, 2, 10, 43344 },
	{ 7, 1, 29, 46248 }, { 0, 2, 17, 27808 }, { 0, 2, 6, 46416 }, { 5, 1, 27, 21928 }, { 0, 2, 14, 19872 }, { 0, 2, 3, 42416 },
	{ 3, 1, 24, 21176 }, { 0, 2, 12, 21168 }, { 8, 1, 31, 43344 }, { 0, 2, 18, 59728 }, { 0, 2, 8, 27296 }, { 6, 1, 28, 44368 },
	{ 0, 2, 15, 43856 }, { 0, 2, 5, 19296 }, { 4, 1, 25, 42352 }, { 0, 2, 13, 42352 }, { 0, 2, 2, 21088 }, { 3, 1, 21, 59696 },
	{ 0, 2, 9,  55632 }, { 7, 1, 30, 23208 }, { 0, 2, 17, 22176 }, { 0, 2, 6, 38608 }, { 5, 1, 27, 19176 }, { 0, 2, 15, 19152 },
	{ 0, 2, 3,  42192 }, { 4, 1, 23, 53864 }, { 0, 2, 11, 53840 }, { 8, 1, 31, 54568 }, { 0, 2, 18, 46400 }, { 0, 2, 7, 46752 },
	{ 6, 1, 28, 38608 }, { 0, 2, 16, 38320 }, { 0, 2, 5, 18864 }, { 4, 1, 25, 42168 }, { 0, 2, 13, 42160 }, { 10, 2, 2, 45656 },
	{ 0, 2, 20, 27216 }, { 0, 2, 9, 27968 }, { 6, 1, 29, 44448 }, { 0, 2, 17, 43872 }, { 0, 2, 6, 38256 }, { 5, 1, 27, 18808 },
	{ 0, 2, 15, 18800 }, { 0, 2, 4, 25776 }, { 3, 1, 23, 27216 }, { 0, 2, 10, 59984 }, { 8, 1, 31, 27432 }, { 0, 2, 19, 23232 },
	{ 0, 2, 7, 43872 }, { 5, 1, 28, 37736 }, { 0, 2, 16, 37600 }, { 0, 2, 5, 51552 }, { 4, 1, 24, 54440 }, { 0, 2, 12, 54432 },
	{ 0, 2, 1, 55888 }, { 2, 1, 22, 23208 }, { 0, 2, 9, 22176 }, { 7, 1, 29, 43736 }, { 0, 2, 18, 9680 }, { 0, 2, 7, 37584 },
	{ 5, 1, 26, 51544 }, { 0, 2, 14, 43344 }, { 0, 2, 3, 46240 }, { 4, 1, 23, 46416 }, { 0, 2, 10, 44368 }, { 9, 1, 31, 21928 },
	{ 0, 2, 19, 19360 }, { 0, 2, 8, 42416 }, { 6, 1, 28, 21176 }, { 0, 2, 16, 21168 }, { 0, 2, 5, 43312 }, { 4, 1, 25, 29864 },
	{ 0, 2, 12, 27296 }, { 0, 2, 1, 44368 }, { 2, 1, 22, 19880 }, { 0, 2, 10, 19296 }, { 6, 1, 29, 42352 }, { 0, 2, 17, 42208 },
	{ 0, 2, 6,  53856 }, { 5, 1, 26, 59696 }, { 0, 2, 13, 54576 }, { 0, 2, 3, 23200 }, { 3, 1, 23, 27472 }, { 0, 2, 11, 38608 },
	{ 11, 1, 31, 19176 }, { 0, 2, 19, 19152 }, { 0, 2, 8, 42192 }, { 6, 1, 28, 53848 }, { 0, 2, 15, 53840 }, { 0, 2, 4, 54560 },
	{ 5,  1, 24, 55968 }, { 0, 2, 12, 46496 }, { 0, 2, 1, 22224 }, { 2, 1, 22, 19160 }, { 0, 2, 10, 18864 }, { 7, 1, 30, 42168 },
	{ 0, 2, 17, 42160 }, { 0, 2, 6, 43600 }, { 5, 1, 26, 46376 }, { 0, 2, 14, 27936 }, { 0, 2, 2, 44448 }, { 3, 1, 23, 21936 },
	{ 0, 2, 11, 37744 }, { 8, 2, 1, 18808 }, { 0, 2, 19, 18800 }, { 0, 2, 8, 25776 }, { 6, 1, 28, 27216 }, { 0, 2, 15, 59984 },
	{ 0, 2, 4,  27424 }, { 4, 1, 24, 43872 }, { 0, 2, 12, 43744 }, { 0, 2, 2, 37600 }, { 3, 1, 21, 51568 }, { 0, 2, 9, 51552 },
	{ 7, 1, 29, 54440 }, { 0, 2, 17, 54432 }, { 0, 2, 5, 55888 }, { 5, 1, 26, 23208 }, { 0, 2, 14, 22176 }, { 0, 2, 3, 42704 },
	{ 4, 1, 23, 21224 }, { 0, 2, 11, 21200 }, { 8, 1, 31, 43352 }, { 0, 2, 19, 43344 }, { 0, 2, 7, 46240 }, { 6, 1, 27, 46416 },
	{ 0, 2, 15, 44368 }, { 0, 2, 5, 21920 }, { 4, 1, 24, 42448 }, { 0, 2, 12, 42416 }, { 0, 2, 2, 21168 }, { 3, 1, 22, 43320 },
	{ 0, 2, 9, 26928 }, { 7, 1, 29, 29336 }, { 0, 2, 17, 27296 }, { 0, 2, 6, 44368 }, { 5, 1, 26, 19880 }, { 0, 2, 14, 19296 },
	{ 0, 2, 3, 42352 }, { 4, 1, 24, 21104 }, { 0, 2, 10, 53856 }, { 8, 1, 30, 59696 }, { 0, 2, 18, 54560 }, { 0, 2, 7, 55968 },
	{ 6, 1, 27, 27472 }, { 0, 2, 15, 22224 }, { 0, 2, 5, 19168 }, { 4, 1, 25, 42216 }, { 0, 2, 12, 42192 }, { 0, 2, 1, 53584 },
	{ 2, 1, 21, 55592 }, { 0, 2, 9, 54560 } }

--将给定的十进制数转为二进制字符串
local function dec2Bin(num)
	local str = ""
	local tmp = num
	while (tmp > 0) do
		if (tmp % 2 == 1) then
			str = str .. "1"
		else
			str = str .. "0"
		end

		tmp = math.modf(tmp / 2)
	end
	str = string.reverse(str)
	return str
end

--将给定的两个十进制数转换为两个长度相等的二进制字符串
local function dec2BinWithSameLen(num1, num2)
	local str1 = dec2Bin(num1)
	local str2 = dec2Bin(num2)
	local len1 = string.len(str1)
	local len2 = string.len(str2)
	local len = 0
	local x = 0

	--长度较短的字符串前方补零
	if (len1 > len2) then
		x = len1 - len2
		for i = 1, x do
			str2 = "0" .. str2
		end
		len = len1
	elseif (len2 > len1) then
		x = len2 - len1
		for i = 1, x do
			str1 = "0" .. str1
		end
		len = len2
	end
	len = len1
	return str1, str2, len
end

--将给定的两个十进制数，进行按位与运算，返回算结果
local function bitAnd(num1, num2)
	local str1, str2, len = dec2BinWithSameLen(num1, num2)
	local rtmp = ""
	for i = 1, len do
		local st1 = tonumber(string.sub(str1, i, i))
		local st2 = tonumber(string.sub(str2, i, i))
		if (st1 == 0) then
			rtmp = rtmp .. "0"
		else
			if (st2 ~= 0) then
				rtmp = rtmp .. "1"
			else
				rtmp = rtmp .. "0"
			end
		end
	end
	return tonumber(rtmp, 2)
end

--判断所在年份是否为闰年
local function IsLeapYear(solarYear)
	if solarYear % 4 ~= 0 then
		return 0
	end
	if solarYear % 100 ~= 0 then
		return 1
	end
	if solarYear % 400 == 0 then
		return 1
	end
	return 0
end

local function getYearInfo(lunarYear, index)
	if lunarYear < BEGIN_YEAR or lunarYear > BEGIN_YEAR + NUMBER_YEAR - 1 then
		return
	end
	return dateLunarInfo[lunarYear - 1901 + 1][index]
end

--计算指定公历日期是这一年中的第几天
local function daysCntInSolar(solarYear, solarMonth, solarDay)
	local daysToMonth = daysToMonth365
	if solarYear % 4 == 0 then
		if solarYear % 100 ~= 0 then
			daysToMonth = daysToMonth366
		end
		if solarYear % 400 == 0 then
			daysToMonth = daysToMonth366
		end
	end
	return daysToMonth[solarMonth] + solarDay
end


local function numToCNumber(number)
	local year = tonumber(string.sub(number, 1, 4))
	local month = tonumber(string.sub(number, 5, 6))
	local day = tonumber(string.sub(number, 7, 8))
	local _lunarYear = convert_arab_to_chinese(year)
	local lunarMonth = convert_arab_to_chinese(month)
	local lunarDay = convert_arab_to_chinese(day)
	local tmp_lunarYear = string.gsub(_lunarYear, "千", "")
	tmp_lunarYear = string.gsub(tmp_lunarYear, "百", "")
	tmp_lunarYear = string.gsub(tmp_lunarYear, "十", "")
	local lunarYear = string.gsub(tmp_lunarYear, '零', '〇')
	local cnLunarDate = lunarYear .. "年" .. lunarMonth .. "月" .. lunarDay .. "日"
	return cnLunarDate
end

--[[根据指定的阳历日期，返回一个农历日期的结构体，结构如下：
lunarDate.solarYear：对应的阳历日期年份
lunarDate.solarMonth：对应的阳历日期月份
lunarDate.solarDay：对应的阳历日期日期
lunarDate.solarDate_YYYYMMDD：对应的阳历日期 YYYYMMDD
lunarDate.year：对应农历年份
lunarDate.month：对应农历月份
lunarDate.day：对应农历的日期
lunarDate.leap：是否为农历的闰年
lunarDate.year_shengXiao：用生肖表示的农历年份
lunarDate.year_ganZhi：用干支表示的农历年份
lunarDate.month_shuXu：农历月份的名称
lunarDate.month_ganZhi：用干支表示的农历月份
lunarDate.day_shuXu：农历日期的名称
lunarDate.day_ganZhi：用干支表示的农历日期
lunarDate.lunarDate_YYYYMMDD：以 YYYYMMDD 格式表示的农历日期
lunarDate.lunarDate_1：癸卯年四月十一
lunarDate.lunarDate_2：兔年四月十一
lunarDate.lunarDate_3：癸卯年四月丁亥日
lunarDate.lunarDate_4：癸卯(兔)年四月十一
lunarDate.jiJieName: 日期所属的季节名称
lunarDate.jiJieLogo：日期所属的季节的符号
]]
--阳历转阴历
local function solar2Lunar(solarYear, solarMonth, solarDay)
	local lunarDate = {}
	lunarDate.solarYear = solarYear
	lunarDate.solarMonth = solarMonth
	lunarDate.solarDay = solarDay
	lunarDate.solarDate = ''
	lunarDate.solarDate_YYYYMMDD = ''
	lunarDate.year = solarYear
	lunarDate.month = 0
	lunarDate.day = 0
	lunarDate.leap = false
	lunarDate.year_shengXiao = ''
	lunarDate.year_ganZhi = ''
	lunarDate.month_shuXu = ''
	lunarDate.month_ganZhi = ''
	lunarDate.day_shuXu = ''
	lunarDate.day_ganZhi = ''
	lunarDate.lunarDate_YYYYMMDD = ''
	lunarDate.lunarDate_1 = ''
	lunarDate.lunarDate_2 = ''
	lunarDate.lunarDate_3 = ''
	lunarDate.lunarDate_4 = ''
	lunarDate.jiJieName = ''
	lunarDate.jiJieLogo = ''

	--确定当前日期相对于2000年1月7日的天数，此日期是一个甲子记日的起点
	local tBase = os.time({ year = 2000, month = 1, day = 7 })
	local tThisDay = os.time({ year = math.min(solarYear, 2037), month = solarMonth, day = solarDay })
	lunarDate.daysToBase = math.floor((tThisDay - tBase) / 86400)

	lunarDate.solarDate_YYYYMMDD = os.date("%Y%m%d", tThisDay)

	if lunarDate.solarYear <= BEGIN_YEAR or lunarDate.solarYear > BEGIN_YEAR + NUMBER_YEAR - 1 then
		return lunarDate
	end

	--春节的公历日期
	local solarMontSpring = getYearInfo(lunarDate.year, 2)
	local solarDaySpring = getYearInfo(lunarDate.year, 3)

	--计算这天是公历年的第几天
	local daysCntInSolarThisDate = daysCntInSolar(solarYear, solarMonth, solarDay)
	--计算春节是公历年的第几天
	local daysCntInSolarSprint = daysCntInSolar(solarYear, solarMontSpring, solarDaySpring)
	--计算这天是农历年的第几天
	local daysCntInLunarThisDate = daysCntInSolarThisDate - daysCntInSolarSprint + 1

	if daysCntInLunarThisDate <= 0 then
		--如果 daysCntInLunarThisDate 为负，说明指定的日期在农历中位于上一年的年度内
		lunarDate.year = lunarDate.year - 1
		if lunarDate.year <= BEGIN_YEAR then
			return lunarDate
		end

		--重新确定农历春节所在的公历日期
		solarMontSpring = getYearInfo(lunarDate.year, 2)
		solarDaySpring = getYearInfo(lunarDate.year, 3)

		--重新计算上一年春节是第几天
		daysCntInSolarSprint = daysCntInSolar(solarYear - 1, solarMontSpring, solarDaySpring)
		--计算上一年共几天
		local daysCntInSolarTotal = daysCntInSolar(solarYear - 1, 12, 31)
		--上一年农历年的第几天
		daysCntInLunarThisDate = daysCntInSolarThisDate + daysCntInSolarTotal - daysCntInSolarSprint + 1
	end

	--开始计算月份
	local lunarMonth = 1
	local lunarDaysCntInMonth = 0
	--dec 32768 =bin 1000000000000000，一个掩码
	local bitMask = 32768
	--大小月份的flg数据
	local lunarMonth30Flg = getYearInfo(lunarDate.year, 4)
	--从正月开始，每个月进行以下计算
	while lunarMonth <= 13 do
		--计算这个月总共有多少天
		if bitAnd(lunarMonth30Flg, bitMask) ~= 0 then
			lunarDaysCntInMonth = 30
		else
			lunarDaysCntInMonth = 29
		end

		--检查thisDate距离这个月初一的天数是否小于这个月的总天数
		if daysCntInLunarThisDate <= lunarDaysCntInMonth then
			lunarDate.month = lunarMonth
			lunarDate.day = daysCntInLunarThisDate
			break
		else
			--如果剩余天数还大于这个月的天数，则继续往下个月算
			daysCntInLunarThisDate = daysCntInLunarThisDate - lunarDaysCntInMonth
			lunarMonth = lunarMonth + 1
			--掩码除2，相当于bit位向右移动一位
			bitMask = bitMask / 2
		end
	end

	--闰月所在的月份
	local leapMontInLunar = getYearInfo(lunarDate.year, 1)
	--确定闰月信息
	if leapMontInLunar > 0 and leapMontInLunar < lunarDate.month then
		--如果存在闰月，且闰在前面判断的月份前面，则农历月份需要减 1 处理
		lunarDate.month = lunarDate.month - 1

		if leapMontInLunar == lunarDate.month then
			--如果恰好闰在这个月，则把闰月标记位置
			lunarDate.leap = true
		end
	end
	--合成农历的年月日格式：20240215
	local tmpMonthStr = '0' .. lunarDate.month
	tmpMonthStr = string.sub(tmpMonthStr, (#tmpMonthStr < 3 and 1 or 2), (#tmpMonthStr < 3 and 2 or 3))
	local tmpDayStr = '0' .. lunarDate.day
	tmpDayStr = string.sub(tmpDayStr, (#tmpDayStr < 3 and 1 or 2), (#tmpDayStr < 3 and 2 or 3))
	lunarDate.lunarDate_YYYYMMDD = lunarDate.year .. tmpMonthStr .. tmpDayStr
	lunarDate.lunarDate_YMD = numToCNumber(lunarDate.lunarDate_YYYYMMDD)

	lunarDate.jiJieName = jiJieNames[lunarDate.month]
	lunarDate.jiJieLogo = jiJieLogos[lunarDate.month]

	--确定年份的生肖
	lunarDate.year_shengXiao = shengXiao[(((lunarDate.year - 4) % 60) % 12) + 1]
	--确定年份的干支
	lunarDate.year_ganZhi = tianGan[(((lunarDate.year - 4) % 60) % 10) + 1] ..
		diZhi[(((lunarDate.year - 4) % 60) % 12) + 1]
	--确定月份的数序
	lunarDate.month_shuXu = (lunarDate.leap and '闰' or '') .. lunarMonthShuXu[lunarDate.month]
	--确定月份的干支，暂不支持计算
	lunarDate.month_ganZhi = ''
	--确定日期的数序
	lunarDate.day_shuXu = lunarDayShuXu[lunarDate.day]
	--确定日期的干支
	lunarDate.day_ganZhi = tianGan[(((lunarDate.daysToBase) % 60) % 10) + 1] ..
		diZhi[(((lunarDate.daysToBase) % 60) % 12) + 1]

	--提供国标第一类计年表示格式
	lunarDate.lunarDate_1 = lunarDate.year_ganZhi .. '年' .. lunarDate.month_shuXu .. '月' .. lunarDate.day_shuXu
	--提供国标第二类计年表示格式
	lunarDate.lunarDate_2 = lunarDate.year_shengXiao .. '年' .. lunarDate.month_shuXu .. '月' .. lunarDate.day_shuXu
	--提供国标第三类计年表示格式
	lunarDate.lunarDate_3 = lunarDate.year_ganZhi .. '年' .. lunarDate.month_shuXu .. '月' .. lunarDate.day_ganZhi .. '日'
	--提供非国标的第四类计年表示格式
	lunarDate.lunarDate_4 = lunarDate.year_ganZhi ..
		'(' .. lunarDate.year_shengXiao .. ')年' .. lunarDate.month_shuXu .. '月' .. lunarDate.day_shuXu

	return lunarDate
end

--通过传入的阳历时间，返回一个阴历数据结构
local function solar2LunarByTime(t)
	local year = tonumber(string.sub(t, 1, 4))
	local month = tonumber(string.sub(t, 5, 6))
	local day = tonumber(string.sub(t, 7, 8))
	-- 确保年月日都是有效的整数值
	local timeObj = os.time({
		year = math.floor(year or 0),
		month = math.floor(month or 1),
		day = math.floor(day or 1)
	})
	local solarDate = os.date('*t', timeObj)
	return solar2Lunar(solarDate.year, solarDate.month, solarDate.day)
end


-- 农历
-- 从 lunar: nl 获取农历触发关键字（双拼默认为 lunar）
-- 从 recognizer/patterns/gregorian_to_lunar 获取第 2 个字符作为公历转农历的触发前缀，默认为 N
local function translator(input, seg, env)
    env.lunar_key_word = env.lunar_key_word or
        (env.engine.schema.config:get_string(env.name_space:gsub('^*', '')) or 'nl')
    env.gregorian_to_lunar = env.gregorian_to_lunar or
        (env.engine.schema.config:get_string('recognizer/patterns/gregorian_to_lunar'):sub(2, 2) or 'N')
    if input == env.lunar_key_word then
        local date1, date2 = solar2LunarByTime(os.date("%Y%m%d"))
        local lunar_ymd = (Candidate("", seg.start, seg._end, date2, ""))
        lunar_ymd.quality = 999
        yield(lunar_ymd)
        local lunar_date = Candidate("", seg.start, seg._end, date1, "")
        lunar_date.quality = 999
        yield(lunar_date)
    elseif env.gregorian_to_lunar ~= '' and input:sub(1, 1) == env.gregorian_to_lunar and input:sub(2):find("^%d%d%d%d%d%d%d%d$")  then
        local date1, date2 = solar2LunarByTime(input:sub(2))
        local lunar_ymd = (Candidate("", seg.start, seg._end, date2, ""))
        lunar_ymd.quality = 999
        yield(lunar_ymd)
        local lunar_date = Candidate("", seg.start, seg._end, date1, "")
        lunar_date.quality = 999
        yield(lunar_date)
    end
end

return translator
