-- 暴力 GC
-- 详情 https://github.com/hchunhui/librime-lua/issues/307
-- 这样也不会导致卡顿，那就每次都调用一下吧，内存稳稳的
local function force_gc()
  -- collectgarbage()
  collectgarbage("step")
end

return force_gc
