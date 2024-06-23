-- runLog.lua
-- Copyright (C) 2023 yaoyuan.dou <douyaoyuan@126.com>

local M = {}
local dbgFlg = true

--设置 dbg 开关
M.setDbg = function(flg)
    dbgFlg = flg

    print('runLog dbgFlg is ' .. tostring(dbgFlg))
end

local current_path = string.sub(debug.getinfo(1).source, 2, string.len("/runLog.lua") * -1)
M.logDoc = current_path .. 'runLog.txt'

M.writeLog = function(logStr, newLineFlg)
    logStr = logStr or "nothing"

    if not newLineFlg then newLineFlg = true end

    local f = io.open(M.logDoc, 'a')
    if f then
        local timeStamp = os.date("%Y/%m/%d %H:%M:%S")
        f:write(timeStamp .. '[' .. _VERSION .. ']' .. '\t' .. logStr .. '\n')
        f:close()
    end
end

--===========================test========================
M.test = function(printPrefix)
    if nil == printPrefix then
        printPrefix = ' '
    end
    if dbgFlg then
        M.writeLog('this is a test string on new line', true)
        M.writeLog('this is a test string appending the last line', false)
        M.writeLog('runLogDoc is: ' .. M.logDoc, true)
    end
end

function M.init(...)
    --如果有需要初始化的动作，可以在这里运行
end

M.init()

return M
