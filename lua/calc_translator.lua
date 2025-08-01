-- 计算器插件
-- author: https://github.com/ChaosAlphard
-- contributor: https://github.com/DeepChirp
local calc = {}

function calc.init( env )
    local config = env.engine.schema.config
    env.prefix = config:get_string( 'calculator/prefix' ) or 'cC'
    env.show_prefix = config:get_bool( 'calculator/show_prefix' ) -- set to true to show prefix in preedit area
    -- env.decimalPlaces = config:get_string('calculator/decimalPlaces') or '4'
end

local function startsWith( str, start ) return string.sub( str, 1, string.len( start ) ) == start end

local function truncateFromStart( str, truncateStr ) return string.sub( str, string.len( truncateStr ) + 1 ) end

local function yield_calc_cand( seg, cand_text, cand_comment, cand_preedit, show_prefix )
    local cand = Candidate( 'calc', seg.start, seg._end, cand_text, cand_comment )
    cand.quality = 99999
    if not show_prefix then cand.preedit = cand_preedit end
    yield( cand )
end

-- 函数表
local calcPlugin = {
    -- e, exp(1) = e^1 = e
    e = math.exp( 1 ),
    -- π
    pi = math.pi,
}

-- random([m [,n ]]) 返回m-n之间的随机数, n为空则返回1-m之间, 都为空则返回0-1之间的小数
local function random( ... ) return math.random( ... ) end
-- 注册到函数表中
calcPlugin['rdm'] = random
calcPlugin['random'] = random

-- 正弦
local function sin( x ) return math.sin( x ) end
calcPlugin['sin'] = sin

-- 双曲正弦
local function sinh( x ) return math.sinh( x ) end
calcPlugin['sinh'] = sinh

-- 反正弦
local function asin( x ) return math.asin( x ) end
calcPlugin['asin'] = asin

-- 余弦
local function cos( x ) return math.cos( x ) end
calcPlugin['cos'] = cos

-- 双曲余弦
local function cosh( x ) return math.cosh( x ) end
calcPlugin['cosh'] = cosh

-- 反余弦
local function acos( x ) return math.acos( x ) end
calcPlugin['acos'] = acos

-- 正切
local function tan( x ) return math.tan( x ) end
calcPlugin['tan'] = tan

-- 双曲正切
local function tanh( x ) return math.tanh( x ) end
calcPlugin['tanh'] = tanh

-- 反正切
-- 返回以弧度为单位的点相对于x轴的逆时针角度。x是点的横纵坐标比值
-- 返回范围从−π到π （以弧度为单位），其中负角度表示向下旋转，正角度表示向上旋转
local function atan( x ) return math.atan( x ) end
calcPlugin['atan'] = atan

-- 反正切
-- atan( y/x ) = atan2(y, x)
-- 返回以弧度为单位的点相对于x轴的逆时针角度。y是点的纵坐标，x是点的横坐标
-- 返回范围从−π到π （以弧度为单位），其中负角度表示向下旋转，正角度表示向上旋转
-- 与 math.atan(y/x) 函数相比，具有更好的数学定义，因为它能够正确处理边界情况（例如x=0）
local function atan2( y, x ) return math.atan2( y, x ) end
calcPlugin['atan2'] = atan2

-- 将角度从弧度转换为度 e.g. deg(π) = 180
local function deg( x ) return math.deg( x ) end
calcPlugin['deg'] = deg

-- 将角度从度转换为弧度 e.g. rad(180) = π
local function rad( x ) return math.rad( x ) end
calcPlugin['rad'] = rad

-- 返回两个值, 无法参与运算后续, 只能单独使用
-- 返回m,e 使得x = m * 2^e
local function frexp( x )
    local m, e = math.frexp( x )
    return m .. ' * 2^' .. e
end
calcPlugin['frexp'] = frexp

-- 返回 x * 2^y
local function ldexp( x, y ) return math.ldexp( x, y ) end
calcPlugin['ldexp'] = ldexp

-- 返回 e^x
local function exp( x ) return math.exp( x ) end
calcPlugin['exp'] = exp

-- 返回x的平方根 e.g. sqrt(x) = x^0.5
local function sqrt( x ) return math.sqrt( x ) end
calcPlugin['sqrt'] = sqrt

-- y为底x的对数, 使用换底公式实现
local function log( y, x )
    -- 不能为负数或0
    if x <= 0 or y <= 0 then return nil end

    return math.log( x ) / math.log( y )
end
calcPlugin['log'] = log

-- e为底x的对数
local function loge( x )
    -- 不能为负数或0
    if x <= 0 then return nil end

    return math.log( x )
end
calcPlugin['loge'] = loge

-- 10为底x的对数
local function log10( x )
    -- 不能为负数或0
    if x <= 0 then return nil end

    return math.log10( x )
end
calcPlugin['log10'] = log10

-- 平均值
local function avg( ... )
    local data = { ... }
    local n = select( '#', ... )
    -- 样本数量不能为0
    if n == 0 then return nil end

    -- 计算总和
    local sum = 0
    for _, value in ipairs( data ) do sum = sum + value end

    return sum / n
end
calcPlugin['avg'] = avg

-- 方差
local function variance( ... )
    local data = { ... }
    local n = select( '#', ... )
    -- 样本数量不能为0
    if n == 0 then return nil end

    -- 计算均值
    local sum = 0
    for _, value in ipairs( data ) do sum = sum + value end
    local mean = sum / n

    -- 计算方差
    local sum_squared_diff = 0
    for _, value in ipairs( data ) do sum_squared_diff = sum_squared_diff + (value - mean) ^ 2 end

    return sum_squared_diff / n
end
calcPlugin['var'] = variance

-- 阶乘
local function factorial( x )
    -- 不能为负数
    if x < 0 then return nil end
    if x == 0 or x == 1 then return 1 end

    local result = 1
    for i = 1, x do result = result * i end

    return result
end
calcPlugin['fact'] = factorial

-- 实现阶乘计算(!)
local function replaceToFactorial( str )
    -- 替换[0-9]!字符为fact([0-9])以实现阶乘
    return str:gsub( '([0-9]+)!', 'fact(%1)' )
end

-- 处理百分号
local function replacePercent(str)
    str = str .. ' '
    -- 先处理括号形式 ( ... )%
    str = str:gsub("(%b())%%(%D)", function(block, tail)
        return "(" .. block .. "/100)" .. tail
    end)
    -- 再处理纯数字形式 123% 12.3%
    str = str:gsub("(%d+%.?%d*)%%(%D)", function(num, tail)
        return "(" .. num .. "/100)" .. tail
    end)
    return str:sub(1, -2)
end

-- 简单计算器
function calc.func( input, seg, env )
    if not seg:has_tag( 'calculator' ) or input == '' then return end
    -- 提取算式
    local express = truncateFromStart( input, env.prefix )
    if express == '' then return end -- 防止用户写错了正则表达式造成错误
    local code = replacePercent( replaceToFactorial( express ) )
    local success, result = pcall( load( 'return ' .. code, 'calculate', 't', calcPlugin ) )
    if success and result and (type( result ) == 'string' or type( result ) == 'number') and #tostring( result ) > 0 then
        yield_calc_cand( seg, result, '', express, env.show_prefix )
        yield_calc_cand( seg, express .. '=' .. result, '', express, env.show_prefix )
    else
        yield_calc_cand( seg, express, '解析失败', express, env.show_prefix )
        yield_calc_cand( seg, code, '入参', express, env.show_prefix )
    end
end

return calc
