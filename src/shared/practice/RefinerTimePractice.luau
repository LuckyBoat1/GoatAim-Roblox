--!strict
-- RefinerTimePractice: HUD timing math compatible with server os.time() startTime

local RefinerTimePractice = {}

export type Progress = { progress: number, remaining: number }

function RefinerTimePractice.progress(startTime: number, duration: number, now: number?): Progress
	local t = now or os.time()
	local elapsed = math.max(0, t - startTime)
	local remaining = math.max(0, (startTime + duration) - t)
	local frac = 0
	if duration > 0 then frac = math.clamp(elapsed / duration, 0, 1) end
	return { progress = frac, remaining = remaining }
end

local function two(n: number): string
	return string.format("%02d", n)
end

function RefinerTimePractice.format(remaining: number): string
	if remaining <= 0 then return "00:00" end
	local hours = math.floor(remaining / 3600)
	local minutes = math.floor((remaining % 3600) / 60)
	local seconds = remaining % 60
	if hours > 0 then
		return string.format("%s:%s:%s", two(hours), two(minutes), two(seconds))
	end
	return string.format("%s:%s", two(minutes), two(seconds))
end

return RefinerTimePractice
