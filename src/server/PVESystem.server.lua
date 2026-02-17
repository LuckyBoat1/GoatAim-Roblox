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
				-- Spawn physical drop for crates
				local dropsFolder = Workspace:FindFirstChild("Drops")
				if not dropsFolder then
					dropsFolder = Instance.new("Folder")
					dropsFolder.Name = "Drops"
					dropsFolder.Parent = Workspace
				end
				
				-- Try to find crate template
				local crateTemplate = nil
				local cratesFolder = ReplicatedStorage:FindFirstChild("Crates")
				if cratesFolder then
					crateTemplate = cratesFolder:FindFirstChild(itemName)
				end
				
				if crateTemplate then
					for i = 1, amount do
						local crate = crateTemplate:Clone()
						
						-- Random offset from NPC position
						local offset = Vector3.new(
							math.random(-3, 3),
							2,
							math.random(-3, 3)
						)
						
						if crate:IsA("Model") and crate.PrimaryPart then
							crate:SetPrimaryPartCFrame(CFrame.new(position + offset))
						elseif crate:IsA("BasePart") then
							crate.Position = position + offset
						end
						
						crate.Parent = dropsFolder
						
						-- Make it collectible
						crate:SetAttribute("DropItem", itemName)
						crate:SetAttribute("DropAmount", 1)
						
						print("[PVESystem] Spawned crate:", itemName, "at", position + offset)
						
						-- Auto-destroy after 60 seconds if not collected
						task.delay(60, function()
							if crate.Parent then
								crate:Destroy()
							end
						end)
					end
				else
					warn("[PVESystem] Crate template not found:", itemName)
				end
			end
		end
	end
end

-- Track killed NPCs to prevent double rewards
local killedNPCs = {}

-- Show damage VFX to all nearby players
local function showDamageVFX(position, damage, isCrit)
	-- Fire to all players within range
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local dist = (player.Character.HumanoidRootPart.Position - position).Magnitude
			if dist <= 150 then -- Only show to nearby players
				DamageIndicatorEvent:FireClient(player, position, damage, isCrit, false)
			end
		end
	end
end

-- Handle NPC taking damage
local function damageNPC(npcModel, damage, attacker)
	if not npcModel then return false end
	
	-- Check if already dead
	if killedNPCs[npcModel] then
		return false
	end
	
	-- Get hit position for VFX
	local hitPosition = npcModel.PrimaryPart and npcModel.PrimaryPart.Position
		or npcModel:FindFirstChild("Head") and npcModel.Head.Position
		or npcModel:FindFirstChildWhichIsA("BasePart") and npcModel:FindFirstChildWhichIsA("BasePart").Position
		or Vector3.new(0, 0, 0)
	
	-- Determine if critical hit (high damage)
	local isCrit = damage >= 50
	
	-- Show damage VFX
	showDamageVFX(hitPosition, damage, isCrit)
	
	local humanoid = npcModel:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		-- Try attribute-based health (like Bull)
		local currentHealth = npcModel:GetAttribute("Health")
		if currentHealth then
			local newHealth = math.max(0, currentHealth - damage)
			npcModel:SetAttribute("Health", newHealth)
			print("[PVESystem] NPC", npcModel.Name, "hit for", damage, "! Health:", newHealth)
			
			if newHealth <= 0 and not killedNPCs[npcModel] then
				killedNPCs[npcModel] = true
				local pos = npcModel.PrimaryPart and npcModel.PrimaryPart.Position or Vector3.new(0, 0, 0)
				spawnDrops(npcModel, pos, attacker)
				
				-- Clean up tracking after respawn time
				task.delay(10, function()
					killedNPCs[npcModel] = nil
				end)
			end
			return true
		end
		
		warn("[PVESystem] NPC has no Humanoid or Health attribute:", npcModel.Name)
		return false
	end
	
	-- Apply damage to humanoid
	humanoid:TakeDamage(damage)
	print("[PVESystem] NPC", npcModel.Name, "hit for", damage, "! Health:", humanoid.Health, "/", humanoid.MaxHealth)
	
	-- Check if NPC died
	if humanoid.Health <= 0 and not killedNPCs[npcModel] then
		killedNPCs[npcModel] = true
		local pos = npcModel.PrimaryPart and npcModel.PrimaryPart.Position 
			or humanoid.RootPart and humanoid.RootPart.Position
			or Vector3.new(0, 0, 0)
		
		spawnDrops(npcModel, pos, attacker)
		
		-- Notify player
		if attacker and _G.notify then
			_G.notify(attacker, "Killed " .. npcModel.Name .. "!")
		end
		
		-- Clean up tracking after respawn time
		task.delay(10, function()
			killedNPCs[npcModel] = nil
		end)
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
