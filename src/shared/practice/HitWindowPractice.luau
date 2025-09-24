--!strict
-- HitWindowPractice: Lightweight utilities to record hits and maintain windows/high scores

export type HitState = {
	-- unix timestamps of target hits
	stamp: { number }?,
	-- normal run counters
	runHits: number?,
	streak: number?,
	totalHits: number?,
	-- bullseye
	bullseyeCurrent: number?,
	bullseyeHigh: number?,
}

local HitWindowPractice = {}

local WINDOW_SEC = 60

local function prune(list: { number }, now: number)
	local i = 1
	while i <= #list do
		if now - list[i] > WINDOW_SEC then
			table.remove(list, i)
		else
			i += 1
		end
	end
end

function HitWindowPractice.recordHit(state: HitState, now: number?)
	local t = now or os.time()
	local arr = state.stamp or {}
	arr[#arr + 1] = t
	state.stamp = arr
	state.totalHits = (state.totalHits or 0) + 1
	state.runHits = (state.runHits or 0) + 1
	state.streak = (state.streak or 0) + 1
end

function HitWindowPractice.targetsPerMinute(state: HitState, now: number?): number
	local t = now or os.time()
	local arr = state.stamp or {}
	prune(arr, t)
	state.stamp = arr
	return #arr * (60 / WINDOW_SEC)
end

function HitWindowPractice.onBullseyeRing(state: HitState, ringNumber: number)
	local points = math.max(1, 7 - ringNumber)
	state.bullseyeCurrent = (state.bullseyeCurrent or 0) + points
	if (state.bullseyeCurrent or 0) > (state.bullseyeHigh or 0) then
		state.bullseyeHigh = state.bullseyeCurrent
	end
end

function HitWindowPractice.resetBullseye(state: HitState)
	state.bullseyeCurrent = 0
end

return HitWindowPractice
