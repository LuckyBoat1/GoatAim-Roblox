-- BullRewards.server.lua
-- Awards gold and EXP when a player's Bull Arena run ends.
-- Detects two exit conditions:
--   1. Timeout — BullArenaManager calls _G.OnBullRunEnd(player, "timeout")
--   2. Teleport out — player Y drops below arenas (arenas sit at Y=500; spawn/abyss at ground)

local Players = game:GetService("Players")

-- Give BullArenaManager a moment to initialise its globals
task.wait(2)

print("[BullRewards] Initialising...")

-- ── REWARD FORMULA ────────────────────────────────────────────────────────
--   score   = bull hit count (d.bullseyeScore); each hit also pays 100 gold
--             live via _G.onBullHit — so the end-bonus here is purely a
--             completion reward, not per-hit income.
--   Bull HP = 3 000.  Rough mapping (assuming ~20 dmg/hit):
--     ~75 hits  ≈ half kill  →  +500 bonus gold
--     ~150 hits ≈ full kill  →  +20 000–40 000 bonus gold
--   EXP: small flat award, 1 per hit

local function calcRewards(score)
	score = math.max(0, score or 0)
	local gold = 0
	-- Small participation tier (any engagement)
	if score >= 5  then gold = gold + 100 end   -- showed up and shot
	-- Quarter-kill tier (~38 hits)
	if score >= 38 then gold = gold + 400 end   -- ~25 % HP
	-- Half-kill tier (~75 hits) — user target: ~500
	if score >= 75 then gold = gold + 500 end   -- ~half kill bonus
	-- Full-kill tier (~150 hits) — user target: 20k-40k
	if score >= 150 then gold = gold + 30000 end -- full kill jackpot
	local exp = 5 + score  -- 1 EXP per hit + 5 flat
	return gold, exp
end

-- ── END-RUN HANDLER ───────────────────────────────────────────────────────
-- inProgress[userId] = true while we're giving rewards (prevents double-firing)
local inProgress = {}

local function endRun(player, reason)
	if not player or not player.Parent then return end
	if inProgress[player.UserId] then return end

	-- Only fire for players actually in an arena
	if not (_G.GetPlayerArena and _G.GetPlayerArena(player)) then return end

	inProgress[player.UserId] = true

	local d = _G.getData and _G.getData(player)
	local score = (d and d.bullseyeScore) or 0
	local gold, exp = calcRewards(score)

	print(("[BullRewards] %s run ended (%s) | Score: %d → +%d Gold, +%d EXP")
		:format(player.Name, reason, score, gold, exp))

	-- Grant rewards
	if _G.addMoney then _G.addMoney(player, gold) end
	if _G.addExp   then _G.addExp(player, exp)   end

	-- Notify client
	if _G.notify then
		_G.notify(player, ("Bull Run Over! Score: %d  |  +%d Gold  |  +%d EXP")
			:format(score, gold, exp))
	end

	-- Free the arena (resets bull, marks slot available)
	if _G.FreeBullArena then _G.FreeBullArena(player) end

	-- Rate-limit: clear flag after a brief delay so re-entry is possible
	task.delay(2, function()
		inProgress[player.UserId] = nil
	end)
end

-- Expose for BullArenaManager to call when the 10-minute timer expires
_G.OnBullRunEnd = endRun

-- ── POSITION-BASED EXIT DETECTION ─────────────────────────────────────────
-- Bull arenas are placed at Y = 500 (ARENA_HEIGHT in BullArenaManager).
-- Normal spawn / Abyss areas are at ground level (Y ≈ 0-200).
-- If we detect a player in an active run with Y < threshold → they teleported out.
local ARENA_MIN_Y = 300 -- studs; below this = left the arena

task.spawn(function()
	while true do
		task.wait(1)
		if not _G.GetPlayerArena then continue end

		for _, player in ipairs(Players:GetPlayers()) do
			if _G.GetPlayerArena(player) then
				local char = player.Character
				local hrp  = char and char:FindFirstChild("HumanoidRootPart")
				if hrp and hrp.Position.Y < ARENA_MIN_Y then
					print(("[BullRewards] %s left arena area (Y=%.1f) — counting as exit")
						:format(player.Name, hrp.Position.Y))
					endRun(player, "left_arena")
				end
			end
		end
	end
end)

-- Clean up if player leaves the game mid-run (no reward — they quit)
Players.PlayerRemoving:Connect(function(player)
	inProgress[player.UserId] = nil
end)

print("[BullRewards] Ready — rewards fire on timeout or arena exit.")
