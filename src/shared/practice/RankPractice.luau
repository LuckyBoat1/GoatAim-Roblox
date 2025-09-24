--!strict
-- RankPractice: Sliding-window TPM and progress math (no _G usage, pure helpers)

export type RankCfg = { rank: number, minTPM: number, minBullseye: number }
export type PlayerState = {
	-- timestamps (unix seconds) of recent target hits
	targetHitTimestamps: { number }?,
	bullseyeHigh: number?,
	rank: number?,
}

local RankPractice = {}

local DEFAULT_RANKS: { RankCfg } = {
	{rank = 2, minTPM = 10, minBullseye = 5},
	{rank = 3, minTPM = 15, minBullseye = 8},
	{rank = 4, minTPM = 20, minBullseye = 12},
	{rank = 5, minTPM = 26, minBullseye = 15},
	{rank = 6, minTPM = 32, minBullseye = 18},
	{rank = 7, minTPM = 40, minBullseye = 22},
}

local WINDOW_SEC = 60

local function pruneWindow(list: { number }, now: number)
	local i = 1
	while i <= #list do
		if now - list[i] > WINDOW_SEC then
			table.remove(list, i)
		else
			i += 1
		end
	end
end

function RankPractice.targetsPerMinute(state: PlayerState, now: number?): number
	local ts = now or os.time()
	local list = state.targetHitTimestamps or {}
	pruneWindow(list, ts)
	state.targetHitTimestamps = list
	return #list * (60 / WINDOW_SEC)
end

export type Progress = {
	currentRank: number,
	nextRank: number?,
	tpm: number,
	bullseyeHigh: number,
	needTPM: number,
	needBullseye: number,
	tpmFrac: number,
	bullFrac: number,
	overallFrac: number,
	isMax: boolean,
}

function RankPractice.progress(state: PlayerState, ranks: { RankCfg }?): Progress
	local cfg = ranks or DEFAULT_RANKS
	local current = state.rank or 1
	local tpm = RankPractice.targetsPerMinute(state)
	local high = state.bullseyeHigh or 0

	local nextCfg: RankCfg? = nil
	for _, r in ipairs(cfg) do
		if r.rank > current then nextCfg = r; break end
	end

	if not nextCfg then
		return {
			currentRank = current,
			nextRank = nil,
			tpm = tpm,
			bullseyeHigh = high,
			needTPM = 0,
			needBullseye = 0,
			tpmFrac = 1,
			bullFrac = 1,
			overallFrac = 1,
			isMax = true,
		}
	end

	local tpmFrac = (nextCfg.minTPM > 0) and math.clamp(tpm / nextCfg.minTPM, 0, 1) or 1
	local bullFrac = (nextCfg.minBullseye > 0) and math.clamp(high / nextCfg.minBullseye, 0, 1) or 1
	local overall = (tpmFrac + bullFrac) / 2

	return {
		currentRank = current,
		nextRank = nextCfg.rank,
		tpm = tpm,
		bullseyeHigh = high,
		needTPM = nextCfg.minTPM,
		needBullseye = nextCfg.minBullseye,
		tpmFrac = tpmFrac,
		bullFrac = bullFrac,
		overallFrac = overall,
		isMax = false,
	}
end

return RankPractice
