-- wrap utf8.sub(str,head_index, tail_index)
-- wrap string.split(str,sp,sp1)
--      string.utf8_len = utf8.len
--      string.utf8_offset= utf8.offset
--      string.utf8_sub= utf8.sub
function string.split(str, sp, sp1)
    sp = type(sp) == "string" and sp or " "
    if #sp == 0 then
        sp = "([%z\1-\127\194-\244][\128-\191]*)"
    elseif #sp == 1 then
        sp = "[^" .. (sp == "%" and "%%" or sp) .. "]*"
    else
        sp1 = sp1 or "^"
        str = str:gsub(sp, sp1)
        sp = "[^" .. sp1 .. "]*"
    end

    local tab = {}
    for v in str:gmatch(sp) do
        table.insert(tab, v)
    end
    return tab
end

function utf8.gsub(str, si, ei)
    local function index(ustr, i)
        return i >= 0 and (ustr:utf8_offset(i) or ustr:len() + 1)
            or (ustr:utf8_offset(i) or 1)
    end

    local u_si = index(str, si)
    ei = ei or str:utf8_len()
    ei = ei >= 0 and ei + 1 or ei
    local u_ei = index(str, ei) - 1
    return str:sub(u_si, u_ei)
end

string.utf8_len = utf8.len
string.utf8_offset = utf8.offset
string.utf8_sub = utf8.gsub
return true
