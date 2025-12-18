-- HealthManager.server.lua
-- Manages player health for PvE and The Abyss modes
-- Handles damage events, death, respawn, and health regeneration

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Remote events
local RemoteEvents = RS:FindFirstChild("RemoteEvents")
if not RemoteEvents then
	RemoteEvents = Instance.new("Folder")
	RemoteEvents.Name = "RemoteEvents"
	RemoteEvents.Parent = RS
end

-- Health system remotes
local DamagePlayerRE = RemoteEvents:FindFirstChild("DamagePlayer") or Instance.new("RemoteEvent")
DamagePlayerRE.Name = "DamagePlayer"
DamagePlayerRE.Parent = RemoteEvents

local HealthUpdateRE = RemoteEvents:FindFirstChild("HealthUpdate") or Instance.new("RemoteEvent")
HealthUpdateRE.Name = "HealthUpdate"
HealthUpdateRE.Parent = RemoteEvents

local PlayerDeathRE = RemoteEvents:FindFirstChild("PlayerDeath") or Instance.new("RemoteEvent")
PlayerDeathRE.Name = "PlayerDeath"
PlayerDeathRE.Parent = RemoteEvents

-- Track which players are in health-enabled modes
local playersInHealthMode = {} -- [player] = {mode = "PvE" or "Abyss", lastRegen = tick()}

-- Configuration
local HEALTH_CONFIG = {
	REGEN_ENABLED = true,
	REGEN_RATE = 5, -- HP per second when not in combat
	REGEN_DELAY = 5, -- Seconds after taking damage before regen starts
	RESPAWN_DELAY = 3, -- Seconds before respawn after death
	RESPAWN_HEALTH_PERCENT = 1.0, -- Respawn at 100% health
}

-- ===============================
-- CORE HEALTH FUNCTIONS
-- ===============================

-- Enable health mode for a player
local function enableHealthMode(player, mode)
	if not player or not player.Parent then return end
	
	mode = mode or "PvE"
	playersInHealthMode[player] = {
		mode = mode,
		lastDamageTime = 0,
		lastRegenTime = tick(),
	}
	
	-- Reset to full health when entering mode
	if _G.resetHealth then
		_G.resetHealth(player)
	end
	
	-- Notify client
	local currentHealth = _G.getHealth and _G.getHealth(player) or 100
	local maxHealth = _G.getMaxHealth and _G.getMaxHealth(player) or 100
	HealthUpdateRE:FireClient(player, {
		health = currentHealth,
		maxHealth = maxHealth,
		enabled = true
	})
	
	print(string.format("[HealthManager] Enabled health mode '%s' for %s", mode, player.Name))
end

-- Disable health mode for a player
local function disableHealthMode(player)
	if not player then return end
	
	playersInHealthMode[player] = nil
	
	-- Notify client to hide health UI
	HealthUpdateRE:FireClient(player, {enabled = false})
	
	print(string.format("[HealthManager] Disabled health mode for %s", player.Name))
end

-- Check if player is in a health-enabled mode
local function isInHealthMode(player)
	return playersInHealthMode[player] ~= nil
end

-- Apply damage to a player
local function applyDamage(player, damage, attacker, damageType, ignoreArmor)
	if not isInHealthMode(player) then
		warn(string.format("[HealthManager] Cannot damage %s - not in health mode", player.Name))
		return false
	end
	
	if not _G.damagePlayer then
		warn("[HealthManager] _G.damagePlayer not available")
		return false
	end
	
	-- Apply damage through PlayerDataManager
	local result = _G.damagePlayer(player, damage, ignoreArmor)
	
	-- Update last damage time (for regen delay)
	if playersInHealthMode[player] then
		playersInHealthMode[player].lastDamageTime = tick()
	end
	
	-- Notify client of health update
	local maxHealth = _G.getMaxHealth and _G.getMaxHealth(player) or 100
	HealthUpdateRE:FireClient(player, {
		health = result.newHealth,
		maxHealth = maxHealth,
		damage = result.damageDealt,
		damageType = damageType or "normal"
	})
	
	-- Handle death
	if result.isDead then
		handlePlayerDeath(player, attacker, damageType)
	end
	
	print(string.format("[HealthManager] %s took %.1f damage (%.1f HP remaining)", 
		player.Name, result.damageDealt, result.newHealth))
	
	return true
end

-- Handle player death
function handlePlayerDeath(player, killer, damageType)
	if not player or not player.Parent then return end
	
	local modeData = playersInHealthMode[player]
	if not modeData then return end
	
	print(string.format("[HealthManager] %s died in %s mode", player.Name, modeData.mode))
	
	-- Fire death event to client
	PlayerDeathRE:FireClient(player, {
		killer = killer and killer.Name or "Unknown",
		mode = modeData.mode,
		damageType = damageType or "normal"
	})
	
	-- Update death stat
	if _G.getData then
		local data = _G.getData(player)
		data.death = (data.death or 0) + 1
	end
	
	-- Handle mode-specific death logic
	if modeData.mode == "Abyss" then
		handleAbyssDeath(player, killer)
	else
		-- Regular PvE death - just respawn
		task.wait(HEALTH_CONFIG.RESPAWN_DELAY)
		respawnPlayer(player)
	end
end

-- Handle death in The Abyss (item loss)
function handleAbyssDeath(player, killer)
	print(string.format("[HealthManager] Processing Abyss death for %s", player.Name))
	
	-- TODO: Implement item drop logic
	-- For now, just respawn after delay
	task.wait(HEALTH_CONFIG.RESPAWN_DELAY)
	
	-- Kick player out of Abyss or respawn them
	-- This will be handled by the Abyss mode manager
	disableHealthMode(player)
end

-- Respawn player with health
function respawnPlayer(player)
	if not player or not player.Parent then return end
	
	-- Reset health to respawn percentage
	if _G.getMaxHealth and _G.setHealth then
		local maxHealth = _G.getMaxHealth(player)
		local respawnHealth = maxHealth * HEALTH_CONFIG.RESPAWN_HEALTH_PERCENT
		_G.setHealth(player, respawnHealth)
		
		-- Notify client
		HealthUpdateRE:FireClient(player, {
			health = respawnHealth,
			maxHealth = maxHealth,
			respawned = true
		})
		
		print(string.format("[HealthManager] Respawned %s with %.1f HP", player.Name, respawnHealth))
	end
	
	-- Respawn character
	pcall(function()
		player:LoadCharacter()
	end)
end

-- ===============================
-- HEALTH REGENERATION
-- ===============================

-- Health regen loop
RunService.Heartbeat:Connect(function(deltaTime)
	if not HEALTH_CONFIG.REGEN_ENABLED then return end
	
	local currentTime = tick()
	
	for player, modeData in pairs(playersInHealthMode) do
		if player and player.Parent then
			-- Check if enough time has passed since last damage
			local timeSinceDamage = currentTime - modeData.lastDamageTime
			
			if timeSinceDamage >= HEALTH_CONFIG.REGEN_DELAY then
				-- Check if we should regen (throttle to once per second)
				local timeSinceRegen = currentTime - modeData.lastRegenTime
				
				if timeSinceRegen >= 1.0 then
					-- Apply regeneration
					if _G.getHealth and _G.getMaxHealth and _G.healPlayer then
						local currentHealth = _G.getHealth(player)
						local maxHealth = _G.getMaxHealth(player)
						
						if currentHealth < maxHealth then
							local newHealth = _G.healPlayer(player, HEALTH_CONFIG.REGEN_RATE)
							
							-- Notify client
							HealthUpdateRE:FireClient(player, {
								health = newHealth,
								maxHealth = maxHealth,
								regen = true
							})
							
							modeData.lastRegenTime = currentTime
						end
					end
				end
			end
		else
			-- Clean up disconnected players
			playersInHealthMode[player] = nil
		end
	end
end)

-- ===============================
-- REMOTE EVENT HANDLERS
-- ===============================

-- Handle damage requests from clients (for validation)
DamagePlayerRE.OnServerEvent:Connect(function(player, targetPlayer, damage, damageType)
	-- Validate the damage request
	-- TODO: Add anti-cheat validation here
	
	if typeof(targetPlayer) ~= "Instance" or not targetPlayer:IsA("Player") then
		warn("[HealthManager] Invalid target player")
		return
	end
	
	if type(damage) ~= "number" or damage <= 0 then
		warn("[HealthManager] Invalid damage amount")
		return
	end
	
	applyDamage(targetPlayer, damage, player, damageType)
end)

-- ===============================
-- GLOBAL API
-- ===============================

_G.HealthManager = {
	EnableHealthMode = enableHealthMode,
	DisableHealthMode = disableHealthMode,
	IsInHealthMode = isInHealthMode,
	ApplyDamage = applyDamage,
	RespawnPlayer = respawnPlayer,
	Config = HEALTH_CONFIG,
}

-- ===============================
-- TESTING COMMANDS
-- ===============================

-- Test health system with commands
_G.testHealth = function(playerName)
	local player = Players:FindFirstChild(playerName)
	if not player then
		warn("[HealthManager] Player not found: " .. tostring(playerName))
		return
	end
	
	enableHealthMode(player, "PvE")
	print(string.format("[HealthManager] Test: Enabled health mode for %s", player.Name))
end

_G.damageTest = function(playerName, damage)
	local player = Players:FindFirstChild(playerName)
	if not player then
		warn("[HealthManager] Player not found: " .. tostring(playerName))
		return
	end
	
	applyDamage(player, damage or 25, nil, "test")
	print(string.format("[HealthManager] Test: Applied %.1f damage to %s", damage or 25, player.Name))
end

_G.healTest = function(playerName, amount)
	local player = Players:FindFirstChild(playerName)
	if not player then
		warn("[HealthManager] Player not found: " .. tostring(playerName))
		return
	end
	
	if _G.healPlayer then
		local newHealth = _G.healPlayer(player, amount or 50)
		local maxHealth = _G.getMaxHealth(player)
		
		HealthUpdateRE:FireClient(player, {
			health = newHealth,
			maxHealth = maxHealth,
			regen = true
		})
		
		print(string.format("[HealthManager] Test: Healed %s by %.1f HP (now %.1f/%.1f)", 
			player.Name, amount or 50, newHealth, maxHealth))
	end
end

-- ===============================
-- LIFECYCLE
-- ===============================

Players.PlayerAdded:Connect(function(player)
	-- Enable health mode for all players by default
	task.wait(1) -- Wait for character to load
	enableHealthMode(player, "PvE")
end)

Players.PlayerRemoving:Connect(function(player)
	playersInHealthMode[player] = nil
end)

print("[HealthManager] ✅ Health system initialized - enabled for all players by default")
