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

--------------------------------------------------------------------------
-- ARENA SPAWNS (optional — if they exist, players teleport there)
--------------------------------------------------------------------------
local arenaFolder = workspace:FindFirstChild("DuelArenaSpawns")
local spawn1 = arenaFolder and arenaFolder:FindFirstChild("ArenaSpawn1")
local spawn2 = arenaFolder and arenaFolder:FindFirstChild("ArenaSpawn2")

if arenaFolder and spawn1 and spawn2 then
	print("✅ [Duel] Arena spawns found — players will teleport on duel start")
else
	warn("⚠️ [Duel] DuelArenaSpawns not found — duels will work but no teleport. Add Workspace > DuelArenaSpawns > ArenaSpawn1 + ArenaSpawn2 to enable.")
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

--------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------
local function isAlive(plr: Player): boolean
	local char = plr.Character
	if not char then return false end
	local hum = char:FindFirstChildOfClass("Humanoid")
	return hum ~= nil and hum.Health > 0
end

local function teleportToArena(player1: Player, player2: Player)
	if not spawn1 or not spawn2 then return end
	if not isAlive(player1) or not isAlive(player2) then return end

	player1.Character:PivotTo(CFrame.new(spawn1.Position + Vector3.new(0, 3, 0)))
	player2.Character:PivotTo(CFrame.new(spawn2.Position + Vector3.new(0, 3, 0)))
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

			-- Notify both
			DuelEvent:FireClient(player, "Message", targetPlayer)
			DuelEvent:FireClient(targetPlayer, "Message", player)
			print(("✅ [Duel] %s vs %s — ACCEPTED! Teleporting in %ds..."):format(
				player.Name, targetPlayer.Name, COUNTDOWN_TIME
			))

			-- Countdown then teleport
			task.delay(COUNTDOWN_TIME, function()
				if isAlive(player) and isAlive(targetPlayer) then
					teleportToArena(player, targetPlayer)
					grantInvincibility(player)
					grantInvincibility(targetPlayer)
					print(("🏟️ [Duel] %s vs %s — FIGHT!"):format(player.Name, targetPlayer.Name))
				else
					-- One died during countdown, cancel
					activeDuels[player] = nil
					activeDuels[targetPlayer] = nil
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
		activeDuels[plr] = nil
		activeDuels[opponent] = nil
		print(("💀 [Duel] %s died — duel with %s ended"):format(plr.Name, opponent.Name))
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

Players.PlayerRemoving:Connect(function(plr)
	-- Clean up any pending/active duels
	pendingDuels[plr] = nil
	lastRequest[plr] = nil

	-- Remove as target from pending
	for target, requester in pairs(pendingDuels) do
		if requester == plr then
			pendingDuels[target] = nil
		end
	end

	-- End active duel
	local opponent = activeDuels[plr]
	if opponent then
		activeDuels[plr] = nil
		activeDuels[opponent] = nil
	end
end)

print("✅ [Duel] Server script loaded")
