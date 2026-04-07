-- duel.server.lua
-- Handles duel requests, accepts, declines, and arena teleportation
-- Works with interaction.client.luau's BillboardGui system

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--------------------------------------------------------------------------
-- SETUP: Create DuelEvent if it doesn't exist
--------------------------------------------------------------------------
local DuelEvent = ReplicatedStorage:FindFirstChild("DuelEvent")
if not DuelEvent then
	DuelEvent = Instance.new("RemoteEvent")
	DuelEvent.Name = "DuelEvent"
	DuelEvent.Parent = ReplicatedStorage
	print("✅ [Duel] Created DuelEvent in ReplicatedStorage")
end

-- PvP Countdown remote (fires countdown numbers to clients)
local PvpCountdownEvent = ReplicatedStorage:FindFirstChild("PvpCountdownEvent")
if not PvpCountdownEvent then
	PvpCountdownEvent = Instance.new("RemoteEvent")
	PvpCountdownEvent.Name = "PvpCountdownEvent"
	PvpCountdownEvent.Parent = ReplicatedStorage
	print("✅ [Duel] Created PvpCountdownEvent in ReplicatedStorage")
end

--------------------------------------------------------------------------
-- ARENA SPAWNS — Pvp folder is at workspace root with spawn parts "1" and "2"
--------------------------------------------------------------------------
local pvpArena = workspace:WaitForChild("Pvp", 30)
local spawn1 = pvpArena and pvpArena:WaitForChild("1", 15)
local spawn2 = pvpArena and pvpArena:WaitForChild("2", 15)

if pvpArena and spawn1 and spawn2 then
	print("✅ [Duel] Pvp arena found with spawn points 1 and 2")
	print(("✅ [Duel] spawn1: %s | spawn2: %s"):format(spawn1:GetFullName(), spawn2:GetFullName()))
else
	warn("⚠️ [Duel] Pvp arena or spawn points not found!")
	warn(("⚠️ [Duel] pvpArena: %s | spawn1: %s | spawn2: %s"):format(
		tostring(pvpArena), tostring(spawn1), tostring(spawn2)))
end

--------------------------------------------------------------------------
-- DUEL STATE
--------------------------------------------------------------------------
local pendingDuels: { [Player]: Player } = {} -- pendingDuels[target] = requester
local activeDuels: { [Player]: Player } = {} -- tracks who is fighting who
local DUEL_COOLDOWN = 3 -- seconds between duel requests
local lastRequest: { [Player]: number } = {}
local INVINCIBILITY_TIME = 5
local COUNTDOWN_TIME = 3
local FIGHT_DURATION = 60 -- seconds for the actual PvP fight
local PVP_MAX_HEARTS = 3 -- hits to kill (headshot = instant)

--------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------
local duelTimers: { [Player]: thread } = {} -- coroutine handle for active fight timers
local preDuelPositions: { [Player]: CFrame } = {} -- saved positions to return players after duel

local function isAlive(plr: Player): boolean
	local char = plr.Character
	if not char then return false end
	local hum = char:FindFirstChildOfClass("Humanoid")
	return hum ~= nil and hum.Health > 0
end

local function grantInvincibility(plr: Player)
	if not isAlive(plr) then return end
	local char = plr.Character
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end

	-- Use Roblox's native ForceField — blocks ALL damage sources
	local existingFF = char:FindFirstChildOfClass("ForceField")
	if existingFF then existingFF:Destroy() end

	local ff = Instance.new("ForceField")
	ff.Name = "DuelForceField"
	ff.Visible = true -- players see the shield bubble
	ff.Parent = char

	-- Also set custom attribute for scripts that check it
	hum:SetAttribute("Invincible", true)

	-- Heal to full
	hum.Health = hum.MaxHealth
	print(("🛡️ [Duel] ForceField + full heal for %s (Health: %d/%d)"):format(plr.Name, hum.Health, hum.MaxHealth))

	task.delay(INVINCIBILITY_TIME, function()
		if ff and ff.Parent then ff:Destroy() end
		if hum and hum.Parent then
			hum:SetAttribute("Invincible", false)
		end
		print(("🛡️ [Duel] Invincibility ended for %s"):format(plr.Name))
	end)
end

local function safeTeleport(plr: Player, spawnPart: BasePart)
	local char = plr.Character
	if not char then
		warn("❌ [Duel] safeTeleport: No character for", plr.Name)
		return
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then
		warn("❌ [Duel] safeTeleport: No humanoid for", plr.Name)
		return
	end
	local rootPart = char:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		warn("❌ [Duel] safeTeleport: No HumanoidRootPart for", plr.Name)
		return
	end

	-- Place player 3 studs above the TOP surface of the spawn part
	local halfHeight = spawnPart.Size.Y / 2
	local targetPos = spawnPart.Position + Vector3.new(0, halfHeight + 3, 0)

	print(("🏟️ [Duel] Teleporting %s to %s (pos: %s)"):format(plr.Name, spawnPart.Name, tostring(targetPos)))

	-- STEP 1: Anchor the root part BEFORE teleporting (prevents falling/void)
	rootPart.Anchored = true

	-- STEP 2: Teleport while anchored
	char:PivotTo(CFrame.new(targetPos))

	-- STEP 3: Zero out any velocity
	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero

	-- STEP 4: Heal to full & ensure alive
	hum.Health = hum.MaxHealth

	-- STEP 5: Wait a frame for position to replicate, then unanchor
	task.delay(0.2, function()
		if rootPart and rootPart.Parent then
			rootPart.Anchored = false
			-- Force into running state so they can move
			if hum and hum.Parent then
				hum:ChangeState(Enum.HumanoidStateType.Running)
			end
			print(("✅ [Duel] %s unanchored at %s"):format(plr.Name, tostring(rootPart.Position)))
		end
	end)
end

-- End a duel cleanly: clear state, stop timer, award stats/gold, tell clients
-- winner: the Player who won, or nil for a draw
local function endDuel(plr1: Player, plr2: Player, reason: string, winner: Player?)
	activeDuels[plr1] = nil
	activeDuels[plr2] = nil

	-- Clear PvP hearts attributes
	if plr1.Character then plr1.Character:SetAttribute("PvpHearts", nil) end
	if plr2.Character then plr2.Character:SetAttribute("PvpHearts", nil) end

	-- Cancel fight timer coroutine
	if duelTimers[plr1] then task.cancel(duelTimers[plr1]); duelTimers[plr1] = nil end
	if duelTimers[plr2] then task.cancel(duelTimers[plr2]); duelTimers[plr2] = nil end

	--------------------------------------------------------------------------
	-- STATS & GOLD REWARDS
	--------------------------------------------------------------------------
	local BASE_GOLD = 100
	local STREAK_BONUS_PERCENT = 0.10 -- 10% per winstreak
	local MAX_STREAK_BONUS = 2.00    -- 200% cap (20 wins)

	if winner and _G.getData then
		local loser = (winner == plr1) and plr2 or plr1

		-- Update winner stats
		local winnerData = _G.getData(winner)
		if winnerData then
			winnerData.wins = (winnerData.wins or 0) + 1
			winnerData.winstreak = (winnerData.winstreak or 0) + 1

			-- Gold reward: 100 base + 10% per winstreak, max 200% bonus (300 total)
			local streakBonus = math.min((winnerData.winstreak - 1) * STREAK_BONUS_PERCENT, MAX_STREAK_BONUS)
			local goldReward = math.floor(BASE_GOLD * (1 + streakBonus))
			if _G.addMoney then
				_G.addMoney(winner, goldReward)
			end

			print(("🏆 [Duel] %s WINS! +%d gold (streak: %d, bonus: %d%%) | W:%d L:%d"):format(
				winner.Name, goldReward, winnerData.winstreak,
				math.floor(streakBonus * 100),
				winnerData.wins, winnerData.losses or 0
			))

			-- Notify winner of gold earned
			PvpCountdownEvent:FireClient(winner, "FightEnd",
				reason .. (" | +%d Gold (Streak: %d)"):format(goldReward, winnerData.winstreak))
		else
			PvpCountdownEvent:FireClient(winner, "FightEnd", reason)
		end

		-- Update loser stats
		local loserData = _G.getData and _G.getData(loser)
		if loserData then
			loserData.losses = (loserData.losses or 0) + 1
			loserData.winstreak = 0 -- reset streak on loss
			print(("📉 [Duel] %s LOST — streak reset | W:%d L:%d"):format(
				loser.Name, loserData.wins or 0, loserData.losses
			))
		end
		-- Always fire FightEnd to the loser regardless of parent/alive state.
		if loser.Parent then
			PvpCountdownEvent:FireClient(loser, "FightEnd", reason)
		else
			pcall(function() PvpCountdownEvent:FireClient(loser, "FightEnd", reason) end)
		end
	else
		-- Draw or no data system — just notify both
		PvpCountdownEvent:FireClient(plr1, "FightEnd", reason)
		PvpCountdownEvent:FireClient(plr2, "FightEnd", reason)
	end

	print(("🏁 [Duel] Fight ended: %s vs %s — %s"):format(plr1.Name, plr2.Name, reason))

	-- Return players to their pre-duel positions after a short delay (let death/respawn settle)
	task.delay(1, function()
		for _, plr in { plr1, plr2 } do
			local savedCF = preDuelPositions[plr]
			preDuelPositions[plr] = nil
			if not savedCF then continue end
			if not plr.Parent then continue end

			local function doReturn(char)
				if not char then return end
				local rootPart = char:FindFirstChild("HumanoidRootPart")
				if not rootPart then return end
				rootPart.Anchored = true
				char:PivotTo(savedCF)
				rootPart.AssemblyLinearVelocity = Vector3.zero
				rootPart.AssemblyAngularVelocity = Vector3.zero
				task.delay(0.2, function()
					if rootPart and rootPart.Parent then
						rootPart.Anchored = false
						local hum = char:FindFirstChildOfClass("Humanoid")
						if hum and hum.Parent then
							hum:ChangeState(Enum.HumanoidStateType.Running)
						end
					end
				end)
				print(("🔙 [Duel] Returned %s to pre-duel position"):format(plr.Name))
			end

			if isAlive(plr) then
				-- Player is alive (they won or it was a draw) — teleport now.
				doReturn(plr.Character)
			else
				-- Player died (lost the duel) — wait for their character to respawn,
				-- then teleport the fresh character back to the pre-duel position.
				local conn
				conn = plr.CharacterAdded:Connect(function(newChar)
					conn:Disconnect()
					task.wait(0.5) -- let spawn settle
					doReturn(newChar)
				end)
				-- Safety timeout: if CharacterAdded doesn't fire within 10 s, give up.
				task.delay(10, function()
					if conn then conn:Disconnect() end
				end)
			end
		end
	end)
end

-- Start the 60-second fight timer; fires every second to both clients
local function startFightTimer(player1: Player, player2: Player)
	local timerThread = task.spawn(function()
		-- Tell clients to show fight timer & hide Stats
		PvpCountdownEvent:FireClient(player1, "FightStart", FIGHT_DURATION)
		PvpCountdownEvent:FireClient(player2, "FightStart", FIGHT_DURATION)

		-- Count down using wall time so cancellation via task.cancel works cleanly.
		-- We do NOT check activeDuels inside the loop — if a player dies, endDuel
		-- calls task.cancel which stops this thread mid-wait. The early-exit guard
		-- that was here before caused the timer to silently exit (and skip FightEnd)
		-- whenever endDuel cleared activeDuels between ticks.
		for t = FIGHT_DURATION, 1, -1 do
			PvpCountdownEvent:FireClient(player1, "FightTimer", t)
			PvpCountdownEvent:FireClient(player2, "FightTimer", t)
			task.wait(1)
		end

		-- Loop completed naturally (60 s expired) — declare a draw.
		if activeDuels[player1] and activeDuels[player2] then
			endDuel(player1, player2, "Time's up — Draw!", nil)
		end
	end)

	duelTimers[player1] = timerThread
	duelTimers[player2] = timerThread
end

local function teleportToArena(player1: Player, player2: Player)
	if not spawn1 or not spawn2 then
		warn("❌ [Duel] ABORTED — spawn points not found!")
		return
	end
	if not isAlive(player1) or not isAlive(player2) then
		warn("❌ [Duel] ABORTED — a player is dead!")
		return
	end

	print(("🏟️ [Duel] Teleporting %s vs %s to arena"):format(player1.Name, player2.Name))

	-- Save pre-duel positions so we can return them after the fight
	if player1.Character and player1.Character:FindFirstChild("HumanoidRootPart") then
		preDuelPositions[player1] = player1.Character:GetPivot()
		print(("📍 [Duel] Saved %s position"):format(player1.Name))
	end
	if player2.Character and player2.Character:FindFirstChild("HumanoidRootPart") then
		preDuelPositions[player2] = player2.Character:GetPivot()
		print(("📍 [Duel] Saved %s position"):format(player2.Name))
	end

	-- Grant invincibility BEFORE teleporting
	grantInvincibility(player1)
	grantInvincibility(player2)

	-- Teleport both players (anchored during teleport to prevent void/fall death)
	safeTeleport(player1, spawn1)
	safeTeleport(player2, spawn2)

	-- Set PvP hearts on both characters
	if player1.Character then player1.Character:SetAttribute("PvpHearts", PVP_MAX_HEARTS) end
	if player2.Character then player2.Character:SetAttribute("PvpHearts", PVP_MAX_HEARTS) end

	-- Notify clients of initial hearts
	PvpCountdownEvent:FireClient(player1, "HeartsUpdate", PVP_MAX_HEARTS)
	PvpCountdownEvent:FireClient(player2, "HeartsUpdate", PVP_MAX_HEARTS)
	print(("❤️ [Duel] Both players set to %d hearts"):format(PVP_MAX_HEARTS))

	-- Start the 60-second fight timer after teleport
	startFightTimer(player1, player2)
end

--------------------------------------------------------------------------
-- DUEL EVENT HANDLER
--------------------------------------------------------------------------
DuelEvent.OnServerEvent:Connect(function(player: Player, action: string, targetPlayer: Player)
	-- Validate target
	if not targetPlayer or not targetPlayer:IsA("Player") then return end
	if targetPlayer == player then return end

	if action == "RequestDuel" then
		-- Cooldown check
		local now = tick()
		if lastRequest[player] and (now - lastRequest[player]) < DUEL_COOLDOWN then
			return -- Too soon, silently ignore
		end
		lastRequest[player] = now

		-- Don't allow if either is already in a duel
		if activeDuels[player] or activeDuels[targetPlayer] then
			return
		end

		-- Don't allow duplicate pending requests
		if pendingDuels[targetPlayer] == player then
			return
		end

		-- Store and send invite
		pendingDuels[targetPlayer] = player
		DuelEvent:FireClient(targetPlayer, "Invite", player)
		print(("⚔️ [Duel] %s challenged %s"):format(player.Name, targetPlayer.Name))

	elseif action == "DeclineDuel" then
		if pendingDuels[player] == targetPlayer then
			pendingDuels[player] = nil
			DuelEvent:FireClient(targetPlayer, "Declined", player)
			print(("❌ [Duel] %s declined %s's duel"):format(player.Name, targetPlayer.Name))
		end

	elseif action == "AcceptDuel" then
		if pendingDuels[player] == targetPlayer then
			pendingDuels[player] = nil

			-- Mark both as in active duel
			activeDuels[player] = targetPlayer
			activeDuels[targetPlayer] = player

			-- Grant ForceField immediately so shots during the countdown can't deal damage.
			-- teleportToArena will call grantInvincibility again after teleport, resetting
			-- the ForceField to a fresh INVINCIBILITY_TIME window.
			grantInvincibility(player)
			grantInvincibility(targetPlayer)

			-- Notify both that duel was accepted
			DuelEvent:FireClient(player, "Message", targetPlayer)
			DuelEvent:FireClient(targetPlayer, "Message", player)
			print(("✅ [Duel] %s vs %s — ACCEPTED! Teleporting in %ds..."):format(
				player.Name, targetPlayer.Name, COUNTDOWN_TIME
			))

			-- Animated countdown — fire each second to both clients
			task.spawn(function()
				-- Show the countdown UI (fires "show" first)
				PvpCountdownEvent:FireClient(player, "Show", targetPlayer.Name)
				PvpCountdownEvent:FireClient(targetPlayer, "Show", player.Name)

				for t = COUNTDOWN_TIME, 1, -1 do
					PvpCountdownEvent:FireClient(player, "Countdown", t)
					PvpCountdownEvent:FireClient(targetPlayer, "Countdown", t)
					task.wait(1)
				end

				-- Fire 0 to hide UI
				PvpCountdownEvent:FireClient(player, "Countdown", 0)
				PvpCountdownEvent:FireClient(targetPlayer, "Countdown", 0)

				if isAlive(player) and isAlive(targetPlayer) then
					teleportToArena(player, targetPlayer)
					print(("🏟️ [Duel] %s vs %s — FIGHT!"):format(player.Name, targetPlayer.Name))
				else
					-- One died during countdown, cancel — fire FightEnd so clients unlock UI
					activeDuels[player] = nil
					activeDuels[targetPlayer] = nil
					PvpCountdownEvent:FireClient(player, "FightEnd", "Duel cancelled")
					PvpCountdownEvent:FireClient(targetPlayer, "FightEnd", "Duel cancelled")
					warn("⚠️ [Duel] Cancelled — a player died during countdown")
				end
			end)
		end
	end
end)

--------------------------------------------------------------------------
-- CLEANUP: Handle duel end when a player dies or leaves
--------------------------------------------------------------------------
local function onPlayerDied(plr: Player)
	local opponent = activeDuels[plr]
	if opponent then
		endDuel(plr, opponent, plr.Name .. " was defeated!", opponent)
	end
end

local function onPlayerAdded(plr: Player)
	plr.CharacterAdded:Connect(function(char)
		local hum = char:WaitForChild("Humanoid", 10)
		if not hum then return end

		-- ====== DEATH DETECTIVE — logs everything when a player dies ======
		local lastHealth = hum.MaxHealth
		local lastDamageSource = "unknown"
		local lastDamageTime = 0

		-- Track every health change so we know what hit them
		hum.HealthChanged:Connect(function(newHealth)
			if newHealth < lastHealth then
				local dmg = lastHealth - newHealth
				local rootPart = char:FindFirstChild("HumanoidRootPart")
				local pos = rootPart and rootPart.Position or Vector3.zero
				local hasFF = char:FindFirstChildOfClass("ForceField") ~= nil
				local isAnchored = rootPart and rootPart.Anchored or false
				local inDuel = activeDuels[plr] ~= nil

				lastDamageSource = string.format(
					"%.1f dmg at pos(%.1f, %.1f, %.1f) FF:%s Anchored:%s InDuel:%s",
					dmg, pos.X, pos.Y, pos.Z,
					tostring(hasFF), tostring(isAnchored), tostring(inDuel)
				)
				lastDamageTime = tick()
				warn(("🔍 [DeathDetective] %s took %.1f damage! Health: %.1f→%.1f | %s"):format(
					plr.Name, dmg, lastHealth, newHealth, lastDamageSource
				))
			end
			lastHealth = newHealth
		end)

		hum.Died:Connect(function()
			local rootPart = char:FindFirstChild("HumanoidRootPart")
			local pos = rootPart and rootPart.Position or Vector3.zero
			local hasFF = char:FindFirstChildOfClass("ForceField") ~= nil
			local isAnchored = rootPart and rootPart.Anchored or false
			local inDuel = activeDuels[plr] ~= nil
			local fallenHeight = workspace.FallenPartsDestroyHeight

			-- Check if position is below the void threshold
			local belowVoid = pos.Y <= fallenHeight

			-- Distance to arena spawns
			local distToSpawn1 = spawn1 and (pos - spawn1.Position).Magnitude or -1
			local distToSpawn2 = spawn2 and (pos - spawn2.Position).Magnitude or -1

			warn("💀💀💀 [DeathDetective] ========== DEATH REPORT ==========")
			warn(("💀 [DeathDetective] Player: %s"):format(plr.Name))
			warn(("💀 [DeathDetective] Position at death: (%.1f, %.1f, %.1f)"):format(pos.X, pos.Y, pos.Z))
			warn(("💀 [DeathDetective] FallenPartsDestroyHeight: %.1f"):format(fallenHeight))
			warn(("💀 [DeathDetective] Below void? %s"):format(tostring(belowVoid)))
			warn(("💀 [DeathDetective] Had ForceField? %s"):format(tostring(hasFF)))
			warn(("💀 [DeathDetective] Was anchored? %s"):format(tostring(isAnchored)))
			warn(("💀 [DeathDetective] In active duel? %s"):format(tostring(inDuel)))
			warn(("💀 [DeathDetective] Dist to spawn1: %.1f | Dist to spawn2: %.1f"):format(distToSpawn1, distToSpawn2))
			warn(("💀 [DeathDetective] Last damage: %s (%.1fs ago)"):format(lastDamageSource, tick() - lastDamageTime))
			warn("💀💀💀 [DeathDetective] ================================")

			onPlayerDied(plr)
		end)

		-- Also detect state changes that might cause death
		hum.StateChanged:Connect(function(_, newState)
			if newState == Enum.HumanoidStateType.Dead then
				local rootPart = char:FindFirstChild("HumanoidRootPart")
				local pos = rootPart and rootPart.Position or Vector3.zero
				warn(("☠️ [DeathDetective] %s entered Dead state at pos(%.1f, %.1f, %.1f)"):format(
					plr.Name, pos.X, pos.Y, pos.Z
				))
			end
		end)
	end)
end

for _, plr in ipairs(Players:GetPlayers()) do
	onPlayerAdded(plr)
end
Players.PlayerAdded:Connect(onPlayerAdded)

Players.PlayerRemoving:Connect(function(plr)
	-- Clean up any pending/active duels
	pendingDuels[plr] = nil
	lastRequest[plr] = nil
	preDuelPositions[plr] = nil

	-- Remove as target from pending
	for target, requester in pairs(pendingDuels) do
		if requester == plr then
			pendingDuels[target] = nil
		end
	end

	-- End active duel
	local opponent = activeDuels[plr]
	if opponent then
		endDuel(plr, opponent, plr.Name .. " left the game", opponent)
	end
end)

print("✅ [Duel] Server script loaded")

--------------------------------------------------------------------------
-- GLOBAL API — so GameShooting.lua can check PvP state & deal hearts damage
--------------------------------------------------------------------------
_G.PvpDuel = {
	-- Check if a player is in an active duel
	isInDuel = function(plr: Player): boolean
		return activeDuels[plr] ~= nil
	end,

	-- Get the opponent of a dueling player
	getOpponent = function(plr: Player): Player?
		return activeDuels[plr]
	end,

	-- Deal 1 heart of damage (headshot = kill instantly)
	-- Returns true if handled as PvP hit, false if not a PvP scenario
	dealPvpHit = function(shooter: Player, victim: Player, isHeadshot: boolean): boolean
		-- Both must be in a duel with each other
		if activeDuels[shooter] ~= victim then return false end

		local victimChar = victim.Character
		if not victimChar then return false end

		local victimHum = victimChar:FindFirstChildOfClass("Humanoid")
		if not victimHum or victimHum.Health <= 0 then return false end

		-- Check ForceField (invincibility period)
		if victimChar:FindFirstChildOfClass("ForceField") then
			print(("🛡️ [Duel] %s hit %s but ForceField is active"):format(shooter.Name, victim.Name))
			return true -- Still counts as "handled" so GameShooting doesn't do anything else
		end

		local currentHearts = victimChar:GetAttribute("PvpHearts") or 0

		if isHeadshot then
			-- Instant kill
			currentHearts = 0
			print(("🎯 [Duel] HEADSHOT! %s → %s — instant kill!"):format(shooter.Name, victim.Name))
		else
			currentHearts = currentHearts - 1
			print(("💔 [Duel] %s hit %s — %d hearts remaining"):format(shooter.Name, victim.Name, currentHearts))
		end

		victimChar:SetAttribute("PvpHearts", math.max(0, currentHearts))

		-- Notify both clients of hearts update
		PvpCountdownEvent:FireClient(victim, "HeartsUpdate", math.max(0, currentHearts))
		PvpCountdownEvent:FireClient(shooter, "OpponentHeartsUpdate", math.max(0, currentHearts))

		-- Notify shooter of the hit type
		if isHeadshot then
			PvpCountdownEvent:FireClient(shooter, "HitMarker", "headshot")
		else
			PvpCountdownEvent:FireClient(shooter, "HitMarker", "body")
		end

		if currentHearts <= 0 then
			-- Kill the victim
			victimHum.Health = 0
			-- endDuel is called via the Died connection
		end

		return true
	end,

	-- Start a duel directly (used by PvpPlatform, bypasses request/accept flow)
	-- Returns true if the duel was started, false if it couldn't be
	startDuel = function(player1: Player, player2: Player): boolean
		-- Don't allow if either is already in a duel
		if activeDuels[player1] or activeDuels[player2] then
			return false
		end
		if not isAlive(player1) or not isAlive(player2) then
			return false
		end

		-- Mark both as in active duel
		activeDuels[player1] = player2
		activeDuels[player2] = player1

		-- Grant ForceField immediately so shots during the countdown can't deal damage
		grantInvincibility(player1)
		grantInvincibility(player2)

		print(("⚔️ [Duel] Platform duel: %s vs %s — ACCEPTED! Teleporting in %ds..."):format(
			player1.Name, player2.Name, COUNTDOWN_TIME
		))

		-- Animated countdown — same as AcceptDuel flow
		task.spawn(function()
			PvpCountdownEvent:FireClient(player1, "Show", player2.Name)
			PvpCountdownEvent:FireClient(player2, "Show", player1.Name)

			for t = COUNTDOWN_TIME, 1, -1 do
				PvpCountdownEvent:FireClient(player1, "Countdown", t)
				PvpCountdownEvent:FireClient(player2, "Countdown", t)
				task.wait(1)
			end

			PvpCountdownEvent:FireClient(player1, "Countdown", 0)
			PvpCountdownEvent:FireClient(player2, "Countdown", 0)

			if isAlive(player1) and isAlive(player2) then
				teleportToArena(player1, player2)
				print(("🏟️ [Duel] %s vs %s — FIGHT!"):format(player1.Name, player2.Name))
			else
				-- Cancelled — fire FightEnd so clients unlock UI
				activeDuels[player1] = nil
				activeDuels[player2] = nil
				PvpCountdownEvent:FireClient(player1, "FightEnd", "Duel cancelled")
				PvpCountdownEvent:FireClient(player2, "FightEnd", "Duel cancelled")
				warn("⚠️ [Duel] Cancelled — a player died during countdown")
			end
		end)

		return true
	end,

	-- Register two players as opponents in the shared activeDuels table.
	-- Called by PvpArena so that GameShooting's hitscan treats them as duelling.
	registerArenaMatch = function(p1: Player, p2: Player)
		activeDuels[p1] = p2
		activeDuels[p2] = p1
	end,

	-- Remove the registration when the arena match ends.
	unregisterArenaMatch = function(p1: Player, p2: Player)
		activeDuels[p1] = nil
		activeDuels[p2] = nil
	end,
}
print("✅ [Duel] Global _G.PvpDuel API registered")
