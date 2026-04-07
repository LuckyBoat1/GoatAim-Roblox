-- RankSystem: EXP-based rank progression.
-- Edit RANKS below to change thresholds. Ranks unlock perks via _G.unlockRefiner.

-- Each entry: { rank = number, minExp = totalExpRequired }
local RANKS = {
	{ rank = 2, minExp = 200    },
	{ rank = 3, minExp = 600    },
	{ rank = 4, minExp = 1500   },
	{ rank = 5, minExp = 3500   },
	{ rank = 6, minExp = 8000   },
	{ rank = 7, minExp = 20000  },
}

_G.checkRankUp = function(player)
	local d = _G.getData and _G.getData(player)
	if not d then return end
	local totalExp = d.exp or 0
	for _, cfg in ipairs(RANKS) do
		if (d.rank or 0) < cfg.rank and totalExp >= cfg.minExp then
			d.rank = cfg.rank
			if _G.notify then _G.notify(player, "Rank Up! Now Rank " .. cfg.rank) end
			if _G.unlockRefiner then _G.unlockRefiner(player, cfg.rank) end
		end
	end
end

-- Recalculate ranks for all online players (call periodically if desired)
_G.recalcRanksAll = function()
	for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
		_G.checkRankUp(plr)
	end
end

-- Rank progress for client UI
_G.getRankProgress = function(player)
	local d = _G.getData and _G.getData(player)
	if not d then return nil end
	local currentRank = d.rank or 1
	local totalExp = d.exp or 0
	local nextCfg = nil
	for _, cfg in ipairs(RANKS) do
		if cfg.rank > currentRank then nextCfg = cfg; break end
	end
	if not nextCfg then
		return { currentRank = currentRank, nextRank = nil, exp = totalExp, needExp = 0, expFrac = 1, isMax = true }
	end
	-- Find previous threshold so bar is relative to this rank's bracket
	local prevExp = 0
	for _, cfg in ipairs(RANKS) do
		if cfg.rank == currentRank then prevExp = cfg.minExp; break end
	end
	local bracketSize = nextCfg.minExp - prevExp
	local bracketProgress = totalExp - prevExp
	local frac = bracketSize > 0 and math.clamp(bracketProgress / bracketSize, 0, 1) or 1
	return {
		currentRank  = currentRank,
		nextRank     = nextCfg.rank,
		exp          = totalExp,
		needExp      = nextCfg.minExp,
		expFrac      = frac,
		isMax        = false,
	}
end
