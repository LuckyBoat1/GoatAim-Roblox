-- PvpArena.server.lua
-- Manages PvP arena matchmaking, teleportation, and fight resolution
-- Arena: workspace.Pvp with spawn parts "1" and "2"

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--------------------------------------------------------------------------
-- SETUP: RemoteEvent for PvP Arena communication
--------------------------------------------------------------------------
local PvpArenaEvent = ReplicatedStorage:FindFirstChild("PvpArenaEvent")
if not PvpArenaEvent then
	PvpArenaEvent = Instance.new("RemoteEvent")
	PvpArenaEvent.Name = "PvpArenaEvent"
	PvpArenaEvent.Parent = ReplicatedStorage
	print("✅ [PvpArena] Created PvpArenaEvent in ReplicatedStorage")
end

--------------------------------------------------------------------------
-- ARENA SPAWNS
--------------------------------------------------------------------------
local pvpArena = workspace:WaitForChild("Pvp", 10)
if not pvpArena then
	warn("❌ [PvpArena] Could not find 'Pvp' in Workspace! Make sure the arena model exists.")
end

local spawn1 = pvpArena and pvpArena:FindFirstChild("1")
local spawn2 = pvpArena and pvpArena:FindFirstChild("2")

if pvpArena and spawn1 and spawn2 then
	print("✅ [PvpArena] Arena found with both spawn points (1 and 2)")
else
	warn("⚠️ [PvpArena] Missing spawn points — ensure Workspace > Pvp > 1 and Workspace > Pvp > 2 exist as Parts")
end

--------------------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------------------
local COUNTDOWN_TIME = 3       -- seconds before fight starts
local INVINCIBILITY_TIME = 5   -- seconds of invincibility after teleport
local REQUEST_COOLDOWN = 3     -- seconds between PvP requests
local MATCH_DURATION = 120     -- max match time in seconds (2 minutes)

--------------------------------------------------------------------------
-- STATE
--------------------------------------------------------------------------
local pendingRequests: { [Player]: Player } = {}  -- pendingRequests[target] = challenger
local activeMatches: { [Player]: Player } = {}    -- tracks who is fighting who
local lastRequestTime: { [Player]: number } = {}
local matchTimers: { [Player]: thread } = {}

--------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------
local function isAlive(plr: Player): boolean
	local char = plr.Character
	if not char then return false end
	local hum = char:FindFirstChildOfClass("Humanoid")
	return hum ~= nil and hum.Health > 0
end

local function isInMatch(plr: Player): boolean
	return activeMatches[plr] ~= nil
end

local function teleportToArena(player1: Player, player2: Player)
	if not spawn1 or not spawn2 then
		warn("⚠️ [PvpArena] Cannot teleport — spawn points missing")
		return false
	end
	if not isAlive(player1) or not isAlive(player2) then
		warn("⚠️ [PvpArena] Cannot teleport — a player is dead")
		return false
	end

	-- Teleport each player to their spawn, slightly above to avoid clipping
	player1.Character:PivotTo(CFrame.new(spawn1.Position + Vector3.new(0, 3, 0)))
	player2.Character:PivotTo(CFrame.new(spawn2.Position + Vector3.new(0, 3, 0)))

	-- Face players toward each other
	local lookDir1 = (spawn2.Position - spawn1.Position).Unit
	local lookDir2 = (spawn1.Position - spawn2.Position).Unit
	player1.Character:PivotTo(CFrame.lookAt(spawn1.Position + Vector3.new(0, 3, 0), spawn1.Position + Vector3.new(0, 3, 0) + lookDir1))
	player2.Character:PivotTo(CFrame.lookAt(spawn2.Position + Vector3.new(0, 3, 0), spawn2.Position + Vector3.new(0, 3, 0) + lookDir2))

	print(("🏟️ [PvpArena] Teleported %s to Spawn1] and %s to Spawn 2"):format(player1.Name, player2.Name))
	return true
end

local function grantInvincibility(plr: Player)
	if not isAlive(plr) then return end
	local hum = plr.Character:FindFirstChildOfClass("Humanoid")
	if not hum then return end

	hum:SetAttribute("Invincible", true)
	task.delay(INVINCIBILITY_TIME, function()
		if hum and hum.Parent then
			hum:SetAttribute("Invincible", false)
		end
	end)
end

local function endMatch(player1: Player, player2: Player, reason: string)
	activeMatches[player1] = nil
	activeMatches[player2] = nil

	-- Cancel match timer
	if matchTimers[player1] then
		task.cancel(matchTimers[player1])
		matchTimers[player1] = nil
	end
	if matchTimers[player2] then
		task.cancel(matchTimers[player2])
		matchTimers[player2] = nil
	end

	-- Notify both players the match ended
	PvpArenaEvent:FireClient(player1, "MatchEnded", player2, reason)
	PvpArenaEvent:FireClient(player2, "MatchEnded", player1, reason)

	print(("🏁 [PvpArena] Match ended: %s vs %s — %s"):format(player1.Name, player2.Name, reason))
end

local function startMatch(challenger: Player, target: Player)
	-- Mark both as in active match
	activeMatches[challenger] = target
	activeMatches[target] = challenger

	-- Notify both players the match is starting
	PvpArenaEvent:FireClient(challenger, "MatchStarting", target, COUNTDOWN_TIME)
	PvpArenaEvent:FireClient(target, "MatchStarting", challenger, COUNTDOWN_TIME)
	print(("⚔️ [PvpArena] %s vs %s — Match starting in %ds"):format(challenger.Name, target.Name, COUNTDOWN_TIME))

	-- Countdown then teleport
	task.delay(COUNTDOWN_TIME, function()
		if not isAlive(challenger) or not isAlive(target) then
			endMatch(challenger, target, "A player died during countdown")
			return
		end

		-- Make sure both are still in the match (didn't disconnect)
		if activeMatches[challenger] ~= target then return end

		local success = teleportToArena(challenger, target)
		if not success then
			endMatch(challenger, target, "Teleport failed")
			return
		end

		-- Grant temporary invincibility
		grantInvincibility(challenger)
		grantInvincibility(target)

		-- Notify fight has begun
		PvpArenaEvent:FireClient(challenger, "FightStarted", target)
		PvpArenaEvent:FireClient(target, "FightStarted", challenger)
		print(("🥊 [PvpArena] %s vs %s — FIGHT!"):format(challenger.Name, target.Name))

		-- Match timeout timer
		local timer = task.delay(MATCH_DURATION, function()
			if activeMatches[challenger] == target then
				endMatch(challenger, target, "Time ran out — draw")
			end
		end)
		matchTimers[challenger] = timer
		matchTimers[target] = timer
	end)
end

--------------------------------------------------------------------------
-- PVP ARENA EVENT HANDLER
--------------------------------------------------------------------------
PvpArenaEvent.OnServerEvent:Connect(function(player: Player, action: string, targetPlayer: Player)
	-- Validate target
	if not targetPlayer or not targetPlayer:IsA("Player") then return end
	if targetPlayer == player then return end

	if action == "RequestPvp" then
		-- Cooldown
		local now = tick()
		if lastRequestTime[player] and (now - lastRequestTime[player]) < REQUEST_COOLDOWN then
			return
		end
		lastRequestTime[player] = now

		-- Don't allow if either is already in a match
		if isInMatch(player) or isInMatch(targetPlayer) then
			PvpArenaEvent:FireClient(player, "Error", "One of you is already in a PvP match!")
			return
		end

		-- Don't allow duplicate pending requests
		if pendingRequests[targetPlayer] == player then return end

		-- Store request and notify target
		pendingRequests[targetPlayer] = player
		PvpArenaEvent:FireClient(targetPlayer, "PvpInvite", player)
		PvpArenaEvent:FireClient(player, "RequestSent", targetPlayer)
		print(("⚔️ [PvpArena] %s challenged %s to PvP"):format(player.Name, targetPlayer.Name))

	elseif action == "AcceptPvp" then
		if pendingRequests[player] == targetPlayer then
			pendingRequests[player] = nil
			startMatch(targetPlayer, player)
		end

	elseif action == "DeclinePvp" then
		if pendingRequests[player] == targetPlayer then
			pendingRequests[player] = nil
			PvpArenaEvent:FireClient(targetPlayer, "Declined", player)
			print(("❌ [PvpArena] %s declined %s's PvP challenge"):format(player.Name, targetPlayer.Name))
		end
	end
end)

--------------------------------------------------------------------------
-- DEATH HANDLING: End match when a player dies
--------------------------------------------------------------------------
local function onPlayerDied(plr: Player)
	local opponent = activeMatches[plr]
	if opponent then
		-- Notify winner
		PvpArenaEvent:FireClient(opponent, "Victory", plr)
		PvpArenaEvent:FireClient(plr, "Defeat", opponent)
		endMatch(plr, opponent, plr.Name .. " was eliminated")
		print(("💀 [PvpArena] %s eliminated — %s wins!"):format(plr.Name, opponent.Name))
	end
end

local function onPlayerAdded(plr: Player)
	plr.CharacterAdded:Connect(function(char)
		local hum = char:WaitForChild("Humanoid", 10)
		if hum then
			hum.Died:Connect(function()
				onPlayerDied(plr)
			end)
		end
	end)
end

for _, plr in ipairs(Players:GetPlayers()) do
	onPlayerAdded(plr)
end
Players.PlayerAdded:Connect(onPlayerAdded)

--------------------------------------------------------------------------
-- CLEANUP: Handle player leaving
--------------------------------------------------------------------------
Players.PlayerRemoving:Connect(function(plr)
	-- Clear pending requests
	pendingRequests[plr] = nil
	lastRequestTime[plr] = nil

	-- Remove as challenger from any pending requests
	for target, challenger in pairs(pendingRequests) do
		if challenger == plr then
			pendingRequests[target] = nil
		end
	end

	-- End active match if in one
	local opponent = activeMatches[plr]
	if opponent then
		PvpArenaEvent:FireClient(opponent, "Victory", plr)
		endMatch(plr, opponent, plr.Name .. " left the game")
	end

	-- Clean up timer
	if matchTimers[plr] then
		matchTimers[plr] = nil
	end
end)

print("✅ [PvpArena] Server script loaded — Arena: Workspace.Pvp, Spawns: 1 & 2")
