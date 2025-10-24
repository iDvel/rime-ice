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
		(rand(0, 255) & 0x0F) | 0x40,
		rand(0, 255),
		(rand(0, 255) & 0x3F) | 0x80,
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
	M.uuid = env.engine.schema.config:get_string(env.name_space:gsub("^*", "")) or "uuid"
end

function M.func(input, seg, _)
	if input == M.uuid then
		randomseed(os.time())
		yield_cand(seg, generate_uuid_v4())
	end
end

return M
