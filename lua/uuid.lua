local function yield_cand(seg, text)
	local cand = Candidate("", seg.start, seg._end, text, "")
	cand.quality = 100
	yield(cand)
end

local fmt = string.format
local rand = math.random
local randomseed = math.randomseed

local function generate_uuid_v4()
	return fmt(
		"%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
		rand(0, 255),
		rand(0, 255),
		rand(0, 255),
		rand(0, 255),
		rand(0, 255),
		rand(0, 255),
		((rand(0, 255) % 16) + 64),
		rand(0, 255),
		((rand(0, 255) % 64) + 128),
		rand(0, 255),
		rand(0, 255),
		rand(0, 255),
		rand(0, 255),
		rand(0, 255),
		rand(0, 255),
		rand(0, 255)
	)
end

local M = {}

function M.init(env)
	randomseed(os.time() + os.clock() * 1000)
	M.uuid = env.engine.schema.config:get_string(env.name_space:gsub("^*", "")) or "uuid"
end

function M.func(input, seg, _)
	if input == M.uuid then
		yield_cand(seg, generate_uuid_v4())
	end
end

return M
