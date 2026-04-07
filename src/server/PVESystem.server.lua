--[[
	PVESystem.server.lua
	Handles PVE combat: bullets damaging NPCs, NPC death, and drop spawning
	Similar to BullBehavior damage system but for all NPCs
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

print("[PVESystem] Initializing...")

-- Setup RemoteEvents for damage VFX
local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not RemoteEvents then
	RemoteEvents = Instance.new("Folder")
	RemoteEvents.Name = "RemoteEvents"
	RemoteEvents.Parent = ReplicatedStorage
end

local DamageIndicatorEvent = RemoteEvents:FindFirstChild("DamageIndicator")
if not DamageIndicatorEvent then
	DamageIndicatorEvent = Instance.new("RemoteEvent")
	DamageIndicatorEvent.Name = "DamageIndicator"
	DamageIndicatorEvent.Parent = RemoteEvents
end

-- Load SimpleNPCStats for drop configuration
local SimpleNPCStats = nil
pcall(function()
	SimpleNPCStats = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SimpleNPCStats"))
end)

if not SimpleNPCStats then
	warn("[PVESystem] SimpleNPCStats not found! Drops will not work.")
end

-- Load DropConfig for per-damage gold rates
local DropConfig = nil
pcall(function()
	DropConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("DropConfig"))
end)

-- Lookup goldPerDamage for an NPC model (case-insensitive, trims spaces)
local function getGoldPerDamage(npcModel)
	if not DropConfig then return 0 end
	-- Exact match first
	local entry = DropConfig[npcModel.Name]
	if entry and entry.goldPerDamage then return entry.goldPerDamage end
	-- Fallback: case-insensitive scan
	local lowerName = npcModel.Name:lower():gsub("%s+", "")
	for k, v in pairs(DropConfig) do
		if type(k) == "string" and k:lower():gsub("%s+", "") == lowerName then
			if v.goldPerDamage then return v.goldPerDamage end
		end
	end
	return 0
end

-- Lookup expPerDamage for an NPC model (case-insensitive, trims spaces)
local function getExpPerDamage(npcModel)
	if not DropConfig then return 0 end
	local entry = DropConfig[npcModel.Name]
	if entry and entry.expPerDamage then return entry.expPerDamage end
	local lowerName = npcModel.Name:lower():gsub("%s+", "")
	for k, v in pairs(DropConfig) do
		if type(k) == "string" and k:lower():gsub("%s+", "") == lowerName then
			if v.expPerDamage then return v.expPerDamage end
		end
	end
	return 0
end

-- Load SkinConfig for damage lookup
local SkinConfig = nil
pcall(function()
	SkinConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SkinConfig"))
end)

if not SkinConfig then
	warn("[PVESystem] SkinConfig not found! Using default damage.")
end

-- Default damage per bullet hit
local DEFAULT_BULLET_DAMAGE = 10

-- Get weapon damage based on tool/skin
local function getWeaponDamage(player)
	local character = player.Character
	if not character then return DEFAULT_BULLET_DAMAGE end
	
	local tool = character:FindFirstChildOfClass("Tool")
	if not tool then return DEFAULT_BULLET_DAMAGE end
	
	-- Check for damage attribute on tool (override)
	local damage = tool:GetAttribute("Damage")
	if damage then return damage end
	
	-- Get SkinId and lookup damage from SkinConfig
	local skinId = tool:GetAttribute("SkinId") or tool.Name
	
	if SkinConfig and SkinConfig.GetDamage then
		local skinDamage = SkinConfig.GetDamage(skinId)
		if skinDamage then
			return skinDamage
		end
	end
	
	return DEFAULT_BULLET_DAMAGE
end

-- Get NPC config from SimpleNPCStats
local function getNPCConfig(npcModel)
	if not SimpleNPCStats then return nil end
	
	local modelName = npcModel.Name
	
	-- Try direct lookup
	if SimpleNPCStats[modelName] then
		return SimpleNPCStats[modelName]
	end
	
	-- Try case-insensitive lookup
	for name, config in pairs(SimpleNPCStats) do
		if type(config) == "table" and config.MODEL_NAME then
			if config.MODEL_NAME:lower() == modelName:lower() then
				return config
			end
		end
	end
	
	return nil
end

-- Spawn drops when NPC dies
local function spawnDrops(npcModel, position, killerPlayer)
	local config = getNPCConfig(npcModel)
	if not config or not config.DROPS then
		print("[PVESystem] No drops configured for:", npcModel.Name)
		return
	end
	
	print("[PVESystem] Rolling drops for:", npcModel.Name)
	
	for _, dropInfo in ipairs(config.DROPS) do
		local roll = math.random()
		
		if roll <= dropInfo.chance then
			local amount = math.random(dropInfo.amount[1], dropInfo.amount[2])
			local itemName = dropInfo.item
			
			print("[PVESystem] Drop rolled:", itemName, "x", amount)
			
			-- Handle Gold specially - add to player data
			if itemName == "Gold" and killerPlayer then
				if _G.addMoney then
					_G.addMoney(killerPlayer, amount)
					print("[PVESystem] Added", amount, "gold to", killerPlayer.Name)
				end
				
				if _G.notify then
					_G.notify(killerPlayer, "+" .. amount .. " Gold!")
				end
			else
				-- Spawn pickupable crate drop (same system as CrateSpawn abyss crates)
				for i = 1, amount do
					local offset = Vector3.new(
						math.random(-3, 3),
						0,
						math.random(-3, 3)
					)
					if _G.SpawnDropCrate then
						_G.SpawnDropCrate(position + offset, itemName)
						print("[PVESystem] Spawned pickupable", itemName, "drop at", position + offset)
					else
						warn("[PVESystem] _G.SpawnDropCrate not ready — CrateSpawn may not have loaded yet")
					end
				end
			end
		end
	end
end

-- Track killed NPCs to prevent double rewards
local killedNPCs = {}

-- Immediately halve any new BillboardGui that enters workspace so health bars
-- are never full-size (client-side property writes on server-owned objects aren't
-- possible from LocalScripts, so we do this server-side).
workspace.DescendantAdded:Connect(function(obj)
	if obj:IsA("BillboardGui") and not obj:GetAttribute("SizeHalved") then
		task.defer(function()  -- defer so Size is already set by whatever created it
			if not obj.Parent then return end
			obj:SetAttribute("SizeHalved", true)
			obj.MaxDistance = 60
			obj.Size = UDim2.new(
				obj.Size.X.Scale / 2, obj.Size.X.Offset / 2,
				obj.Size.Y.Scale / 2, obj.Size.Y.Offset / 2
			)
		end)
	end
end)

-- ── CORPSE HANDLER ────────────────────────────────────────────────────────
-- Hides the health billboard immediately, then fades the body from t=5→10s
-- and destroys it. PVESystem destroys the model; the AI while-loop in each
-- spawner script checks `npc.Parent`, so this also triggers respawn logic.
local function handleNPCCorpse(npcModel)
	if not npcModel or not npcModel.Parent then return end

	-- Disable all BillboardGuis (custom health bars) immediately
	for _, obj in ipairs(npcModel:GetDescendants()) do
		if obj:IsA("BillboardGui") then
			obj.Enabled = false
		end
	end
	-- Also suppress the default Roblox health display
	local hum = npcModel:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.DisplayDistanceType  = Enum.HumanoidDisplayDistanceType.None
		hum.HealthDisplayType    = Enum.HumanoidHealthDisplayType.AlwaysOff
	end

	-- Fade + destroy coroutine
	task.spawn(function()
		task.wait(5) -- lie still for 5 seconds before fading
		if not npcModel.Parent then return end

		local STEPS     = 20
		local STEP_TIME = 5 / STEPS -- fade over 5 seconds → gone at t=10
		for i = 1, STEPS do
			if not npcModel.Parent then return end
			local t = i / STEPS
			for _, desc in ipairs(npcModel:GetDescendants()) do
				if desc:IsA("BasePart") then
					desc.Transparency = t
					desc.CanCollide   = false
				elseif desc:IsA("Decal") or desc:IsA("Texture") then
					desc.Transparency = t
				end
			end
			task.wait(STEP_TIME)
		end

		if npcModel.Parent then
			npcModel:Destroy()
		end
	end)
end

-- Show damage VFX to the attacking player (no distance limit)
local function showDamageVFX(position, damage, isCrit, attacker)
	local target = attacker
	-- If attacker not passed, fire to all players (fallback)
	if target and target:IsA("Player") then
		DamageIndicatorEvent:FireClient(target, position, damage, isCrit, false)
	else
		for _, player in ipairs(Players:GetPlayers()) do
			DamageIndicatorEvent:FireClient(player, position, damage, isCrit, false)
		end
	end
end

-- Handle NPC taking damage
local function damageNPC(npcModel, damage, attacker)
	if not npcModel then return false end

	-- Check if already dead — but verify health wasn't reset (spawner may reuse the same model)
	if killedNPCs[npcModel] then
		local hum = npcModel:FindFirstChildOfClass("Humanoid")
		local stillDead = hum and hum.Health <= 0
		if not stillDead then
			local attr = npcModel:GetAttribute("Health")
			stillDead = attr ~= nil and attr <= 0
		end
		if stillDead then return false end
		-- Health was reset → spawner reused the model; clear the stale entry
		killedNPCs[npcModel] = nil
	end

	-- Re-enable health billboard in case NPC respawned with it disabled
	-- Cap MaxDistance so billboard never takes over the whole screen
	-- Halve billboard visual size once (guarded by attribute so it doesn't keep shrinking)
	for _, obj in ipairs(npcModel:GetDescendants()) do
		if obj:IsA("BillboardGui") then
			obj.Enabled = true
			obj.MaxDistance = 60  -- disappears beyond 60 studs
			if not obj:GetAttribute("SizeHalved") then
				obj:SetAttribute("SizeHalved", true)
				obj.Size = UDim2.new(
					obj.Size.X.Scale / 2, obj.Size.X.Offset / 2,
					obj.Size.Y.Scale / 2, obj.Size.Y.Offset / 2
				)
			end
		end
	end
	
	-- Get hit position for VFX
	local hitPosition = npcModel.PrimaryPart and npcModel.PrimaryPart.Position
		or npcModel:FindFirstChild("Head") and npcModel.Head.Position
		or npcModel:FindFirstChildWhichIsA("BasePart") and npcModel:FindFirstChildWhichIsA("BasePart").Position
		or Vector3.new(0, 0, 0)
	
	-- Determine if critical hit (high damage)
	local isCrit = damage >= 50
	
	-- Show damage VFX
	showDamageVFX(hitPosition, damage, isCrit, attacker)
	
	local humanoid = npcModel:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		-- Try attribute-based health
		local currentHealth = npcModel:GetAttribute("Health")
		if currentHealth then
			local actualDamage = math.min(damage, currentHealth)
			local newHealth = math.max(0, currentHealth - damage)
			npcModel:SetAttribute("Health", newHealth)
			print("[PVESystem] NPC", npcModel.Name, "hit for", damage, "! Health:", newHealth)

			-- Per-damage gold reward
			if attacker then
				local gpd = getGoldPerDamage(npcModel)
				local earned = math.floor(actualDamage * gpd)
				if earned > 0 and _G.addMoney then _G.addMoney(attacker, earned) end
			end

			if newHealth <= 0 and not killedNPCs[npcModel] then
				killedNPCs[npcModel] = true
				local pos = npcModel.PrimaryPart and npcModel.PrimaryPart.Position or Vector3.new(0, 0, 0)
				spawnDrops(npcModel, pos, attacker)
				-- Award EXP
				if attacker and _G.addExp then
					local expConfig = getNPCConfig(npcModel)
					local expAward = (expConfig and expConfig.EXP) or 10
					_G.addExp(attacker, expAward)
				end
				-- Fade body + hide health bar
				handleNPCCorpse(npcModel)
				-- Clear tracking after body is gone
				task.delay(12, function() killedNPCs[npcModel] = nil end)
			end
			return true
		end

		warn("[PVESystem] NPC has no Humanoid or Health attribute:", npcModel.Name)
		return false
	end

	-- Apply damage to humanoid
	-- Remove any ForceField that would silently absorb TakeDamage (common on freshly spawned NPCs)
	for _, ff in ipairs(npcModel:GetDescendants()) do
		if ff:IsA("ForceField") then ff:Destroy() end
	end

	local prevHealth = humanoid.Health
	-- Set Health directly (bypasses ForceField and invincibility scripts that intercept TakeDamage)
	humanoid.Health = math.max(0, humanoid.Health - damage)
	local actualDamage = math.max(0, prevHealth - humanoid.Health)
	print("[PVESystem] NPC", npcModel.Name, "hit for", actualDamage, "! Health:", humanoid.Health, "/", humanoid.MaxHealth)

	-- Per-damage gold reward
	if attacker then
		local gpd = getGoldPerDamage(npcModel)
		local earned = math.floor(actualDamage * gpd)
		if earned > 0 and _G.addMoney then _G.addMoney(attacker, earned) end
	end

	-- Check if NPC died
	if humanoid.Health <= 0 and not killedNPCs[npcModel] then
		killedNPCs[npcModel] = true
		local pos = npcModel.PrimaryPart and npcModel.PrimaryPart.Position
			or humanoid.RootPart and humanoid.RootPart.Position
			or Vector3.new(0, 0, 0)

		spawnDrops(npcModel, pos, attacker)

		-- Award EXP to killer
		if attacker and _G.addExp then
			local expConfig = getNPCConfig(npcModel)
			local expAward = (expConfig and expConfig.EXP) or 10
			_G.addExp(attacker, expAward)
			print("[PVESystem] Awarded", expAward, "EXP to", attacker.Name)
		end

		-- Notify player
		if attacker and _G.notify then
			_G.notify(attacker, "Killed " .. npcModel.Name .. "!")
		end

		-- Fade body + hide health bar; body is destroyed at t=10s
		handleNPCCorpse(npcModel)
		-- Clear kill-tracking after body is gone
		task.delay(12, function() killedNPCs[npcModel] = nil end)
	end
	
	return true
end

-- List of known NPC model names to detect
local NPC_MODEL_NAMES = {
	"Spidy", "TorsoGhost", "Skelly", "Robo", "RedPiggy", 
	"MamaGhost", "BabyGhost", "FishTank",
	"End", "Beginning", "WorldBreaker", "TheWeepingKing", "TwoFace", "Dice"
}

-- Check if a model is an NPC
local function isNPC(model)
	if not model then return false end
	
	-- Check by name
	for _, npcName in ipairs(NPC_MODEL_NAMES) do
		if model.Name == npcName or model.Name:match("^" .. npcName) then
			return true
		end
	end
	
	-- Check if it has NPC-like properties
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		-- Check if it's not a player
		local player = Players:GetPlayerFromCharacter(model)
		if not player then
			-- Has humanoid but not a player = NPC
			-- Additional check: has spawn attributes
			if model:GetAttribute("SpawnX") or model:GetAttribute("IsNPC") then
				return true
			end
		end
	end
	
	return false
end

-- Find NPC model from hit part
local function findNPCFromHit(hitPart)
	if not hitPart then return nil end
	
	local current = hitPart
	while current and current ~= Workspace do
		if isNPC(current) then
			return current
		end
		current = current.Parent
	end
	
	return nil
end

-- Export functions globally for GameShooting integration
_G.PVESystem = {
	damageNPC = damageNPC,
	getWeaponDamage = getWeaponDamage,
	findNPCFromHit = findNPCFromHit,
	isNPC = isNPC,
}

print("[PVESystem] Ready! Functions exported to _G.PVESystem")
print("[PVESystem] Known NPC types:", table.concat(NPC_MODEL_NAMES, ", "))
