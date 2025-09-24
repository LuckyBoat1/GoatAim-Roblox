-- RankSystem: configurable rank thresholds based on target hits per minute and bullseye high score.
-- Edit RANKS below to tweak progression.

-- Each entry: {rank=number, minTPM=targetsPerMinute, minBullseye=score}
-- Ordered ascending; rank 1 is default and omitted.
local RANKS = {
	{rank=2, minTPM=10, minBullseye=5},
	{rank=3, minTPM=15, minBullseye=8},
	{rank=4, minTPM=20, minBullseye=12},
	{rank=5, minTPM=26, minBullseye=15},
	{rank=6, minTPM=32, minBullseye=18},
	{rank=7, minTPM=40, minBullseye=22},
}

-- Config: sliding window (seconds) used to measure targets per minute
local WINDOW_SEC = 60

-- Utility: prune timestamps and compute rate
local function computeTargetsPerMinute(data)
	local now = os.time()
	local list = data.targetHitTimestamps or {}
	-- prune
	local i = 1
	while i <= #list do
		if now - list[i] > WINDOW_SEC then
			table.remove(list, i)
		else
			i += 1
		end
	end
	data.targetHitTimestamps = list
	return (#list) * (60 / WINDOW_SEC)
end

-- Call when a normal target is hit (not bullseye ring). Attach from hitting logic.
_G.recordTargetHit = function(player)
	local d = _G.getData(player)
	local list = d.targetHitTimestamps or {}
	list[#list+1] = os.time()
	d.targetHitTimestamps = list
end

-- Call from bullseye scoring updates (ShootingServer already updates bullseyeCurrent / bullseyeHigh after you adjust it there).

_G.checkRankUp = function(player)
	local d = _G.getData(player)
	if not d then return end
	local tpm = computeTargetsPerMinute(d)
	local high = d.bullseyeHigh or 0
	for _, cfg in ipairs(RANKS) do
		if d.rank < cfg.rank and tpm >= cfg.minTPM and high >= cfg.minBullseye then
			local old = d.rank
			d.rank = cfg.rank
			if _G.notify then _G.notify(player, "Rank Up! New Rank: " .. cfg.rank) end
			if _G.unlockRefiner then _G.unlockRefiner(player, cfg.rank) end
		end
	end
end

-- Optional helper to force recalculation (e.g. periodic).
_G.recalcRanksAll = function()
	for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
		_G.checkRankUp(plr)
	end
end

-- Provide rank progress detail for client UI (Inventory progress bar).
-- Returns table with currentRank, nextRank (or nil if max), tpm, bullseyeHigh, needTPM, needBullseye, fractions and overall percent.
_G.getRankProgress = function(player)
	local d = _G.getData(player)
	if not d then return nil end
	local currentRank = d.rank or 1
	local nextCfg = nil
	for _, cfg in ipairs(RANKS) do
		if cfg.rank > currentRank then
			nextCfg = cfg
			break
		end
	end
	local tpm = computeTargetsPerMinute(d)
	local high = d.bullseyeHigh or 0
	if not nextCfg then
		return {
			currentRank = currentRank,
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
		currentRank = currentRank,
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

