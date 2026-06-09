-- 将今天或者指定的公历日期转换为农历和二十四节气，支持1900-2100之间的日期。输入格式为YYYYMMDD，例如20240101。
-- 默认格式示例：丙午马年正月初一
-- 标准：GB/T 33661-2017 《农历的编算和颁行》；GB/T 15835-2011 《出版物上数字用法》4.2.1；参考：人民日报，新华社
-- 数据：https://www.hko.gov.hk/tc/gts/time/conversion1_text.htm (注：修正源数据 2051 年星期偏移，修正农历年份偏移)
-- ================================
-- 安装：
-- lunar.lua --> lua/lunar.lua
-- lunar.db --> lua/lunar.db
-- 配置：
-- ```yaml
-- engine/translator:
--   - lua_translator@*lunar
-- recognizer/gregorian_to_lunar: "^N[0-9]{1,8}" # 输入N19700101输出对应的农历信息
-- lunar: lunar # 输入此字符输出今日农历信息
-- lunar_template: "{干支年}{生肖}年{俗称农历月}{农历日}" # 可用字段：{干支年} {农历月} {农历日} {生肖} {俗称农历月} {简记农历日}
-- ```
-- =================================
local lunar_translator = {}
local LUNAR_KEYS = { '干支年', '农历月', '农历日', '星期', '生肖', '节气' }
local function new_lunar_cand( lunar_info, env, seg )
    local values = {}
    local i = 1
    for part in string.gmatch( lunar_info, '[^-]+' ) do
        values[LUNAR_KEYS[i]] = part;
        i = i + 1
    end
    values['俗称农历月'] = values['农历月']:gsub( '十二月', '腊月' )
    values['简记农历日'] = values['农历日']:gsub( '^二十([一二三四五六七八九])$', '廿%1' )
    local args = {}
    for _, field in ipairs( env.lunar_template_fields ) do args[#args + 1] = values[field] or '' end
    local cand = Candidate(
                     'lunar', seg.start, seg._end, string.format( env.lunar_format, table.unpack( args ) ),
                     values['星期']
                  )
    cand.quality = 99999
    if values['节气'] then cand.comment = values['星期'] .. ' ' .. values['节气'] end
    return cand
end

function lunar_translator.init( env )
    local ns = env.name_space:gsub( '^*', '' )
    local config = env.engine.schema.config

    env.db = ReverseDb( 'lua/lunar.db' )
    env.lunar_call_prefix = config:get_string( ns ) or 'lunar'
    env.seg_tag = 'gregorian_to_lunar'

    local lunar_template = config:get_string( ns .. '_template' ) or
                               '{干支年}{生肖}年{俗称农历月}{农历日}'
    local template_fields = {}
    env.lunar_format = lunar_template:gsub(
                           '{([^}]+)}', function( field )
            template_fields[#template_fields + 1] = field
            return '%s'
        end
                        )
    env.lunar_template_fields = template_fields
end

function lunar_translator.func( input, seg, env )
    local date
    if input == env.lunar_call_prefix then
        date = os.date( '%Y%m%d' )
    elseif seg:has_tag( env.seg_tag ) then
        date = input:match( '%d+' )
        if date and #date < 8 then
            yield( Candidate( 'lunar', seg.start, seg._end, '输入完整的日期', 'YYYYMMDD' ) )
            return
        end
    end
    if not date then return end
    local date_year = tonumber( date:sub( 1, 4 ) )
    if date_year > 2100 or date_year < 1900 then
        yield( Candidate( 'lunar', seg.start, seg._end, '错误', '仅支持1900-2100之间的日期' ) )
        return
    end
    local lunar_info = env.db:lookup( date )
    if lunar_info and #lunar_info > 0 then
        yield( new_lunar_cand( lunar_info, env, seg ) )
    else
        yield( Candidate( 'lunar', seg.start, seg._end, '错误', '未找到对应的农历信息' ) )
    end
end

return lunar_translator
