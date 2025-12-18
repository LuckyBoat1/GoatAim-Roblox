-- BullArenaManager.server.lua
-- Clones BullArena instances and manages arena pool for players

print("=" .. string.rep("=", 60))
print("🚀 BULL ARENA MANAGER - SCRIPT START")
print("=" .. string.rep("=", 60))
print("📍 Script Location:", script:GetFullName())
print("⏰ Time:", os.date("%H:%M:%S"))
print("")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
print("✅ Services loaded")

-- Configuration
local ARENA_COUNT = 1 -- Reduced from 10 to prevent lag
local ARENA_SPACING = 10000
local ARENA_HEIGHT = 500 -- Height to prevent falling into void
local ANIMATION_ID = "rbxassetid://102385254834975" -- Bull walk animation
local GAME_DURATION = 600 -- Seconds (10 minutes)
print("⚙️ Config: " .. ARENA_COUNT .. " arena(s), " .. ARENA_SPACING .. " studs apart, height: " .. ARENA_HEIGHT)
print("")

-- Setup RemoteEvents
local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not RemoteEvents then
	RemoteEvents = Instance.new("Folder")
	RemoteEvents.Name = "RemoteEvents"
	RemoteEvents.Parent = ReplicatedStorage
end

local GameTimerRE = RemoteEvents:FindFirstChild("GameTimer")
if not GameTimerRE then
	GameTimerRE = Instance.new("RemoteEvent")
	GameTimerRE.Name = "GameTimer"
	GameTimerRE.Parent = RemoteEvents
end

local TrafficLightRE = RemoteEvents:FindFirstChild("TrafficLightUpdate")
if not TrafficLightRE then
	TrafficLightRE = Instance.new("RemoteEvent")
	TrafficLightRE.Name = "TrafficLightUpdate"
	TrafficLightRE.Parent = RemoteEvents
end

print("🔍 Searching for BullArena in Workspace...")
local templateArena = workspace:WaitForChild("BullArena", 0.1)

if not templateArena then
	error("❌ CRITICAL: BullArena not found in Workspace after 0.1 second wait!")
end

print("✅ Template arena found: " .. templateArena.Name)
print("   📦 Type: " .. templateArena.ClassName)
print("   🎯 PrimaryPart: " .. tostring(templateArena.PrimaryPart))
print("   👶 Children count: " .. #templateArena:GetChildren())

local children = {}
for _, child in ipairs(templateArena:GetChildren()) do
	table.insert(children, child.Name .. " (" .. child.ClassName .. ")")
end
print("   📋 Children: " .. table.concat(children, ", "))

-- Debug: Print all descendants to find lights
print("   🔍 Searching for lights in template...")
for _, desc in ipairs(templateArena:GetDescendants()) do
	if desc.Name:match("Light") or desc.Name:match("Glow") then
		print("      Found: " .. desc.Name .. " (" .. desc.ClassName .. ") Parent: " .. desc.Parent.Name)
	end
end
print("")

-- Storage for cloned arenas
local arenaPool = {}
local playerArenas = {}
local deathConnections = {} -- Track death connections to disconnect on cleanup
print("📊 Arena pool initialized (empty)")
print("")

local TweenService = game:GetService("TweenService")

-- Helper to anchor all parts in a model
local function anchorModel(model)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			-- Anchor EVERYTHING, including the Bull.
			-- This prevents the Bull from falling/shifting during the cloning/setup process.
			-- The BullBehavior script will handle its own anchoring/unanchoring when it starts.
			descendant.Anchored = true
		end
	end
end

-- Helper to manage Traffic Light Game Logic (Red/Green Light)
local function startTrafficLightGame(player, arena)
	task.spawn(function()
		print("🚦 Starting Traffic Light Game for " .. player.Name)
		
		-- Set TargetPlayer for Bull
		if arena.bull then
			local targetVal = arena.bull:FindFirstChild("TargetPlayer")
			if not targetVal then
				targetVal = Instance.new("ObjectValue")
				targetVal.Name = "TargetPlayer"
				targetVal.Parent = arena.bull
			end
			targetVal.Value = player
		end
		
		-- Reset Score
		if _G.getData then
			local d = _G.getData(player)
			if d then
				d.bullseyeScore = 0
				local BullScoreUpdate = RemoteEvents:FindFirstChild("BullScoreUpdate")
				if BullScoreUpdate then
					BullScoreUpdate:FireClient(player, 0)
				end
			end
		end
		
		while player and player.Parent and arena.Parent do
			-- GREEN LIGHT (Go)
			local greenDuration = math.random(3, 6)
			TrafficLightRE:FireClient(player, "Green")
			if arena.bull then
				arena.bull:SetAttribute("TrafficLightState", "Green")
			end
			print("   🟢 Green Light for " .. greenDuration .. "s")
			task.wait(greenDuration)
			
			-- RED LIGHT (Stop)
			local redDuration = math.random(3, 5)
			TrafficLightRE:FireClient(player, "Red")
			if arena.bull then
				arena.bull:SetAttribute("TrafficLightState", "Red")
				arena.bull:SetAttribute("AggroEndTime", 0) -- Reset aggro timer
			end
			print("   🔴 Red Light for " .. redDuration .. "s")
			
			-- Check for movement during Red Light (Simple check)
			local startTime = os.time()
			local endTime = startTime + redDuration
			local isAggroed = false -- Tracks if bull is currently in aggro mode
			
			local character = player.Character
			local rootPart = character and character:FindFirstChild("HumanoidRootPart")
			local lastPos = rootPart and rootPart.Position
			
			while os.time() < endTime do
				task.wait(0.1)
				if not player or not player.Parent then break end
				
				-- Check for Attack Trigger (Aggro management)
				if arena.bull and arena.bull:GetAttribute("AttackTriggered") then
					if not isAggroed then
						-- First hit during red light - SET 20 seconds from now (only first hit counts)
						print("   ⏳ Bull AGGROED! Setting 20s aggro timer!")
						endTime = os.time() + 20
						isAggroed = true
						arena.bull:SetAttribute("AggroEndTime", endTime)
					else
						-- Already aggroed - ignore subsequent hits (no extension)
						print("   ⏳ Bull hit again but already aggroed - ignoring")
					end
					-- Reset attribute so we can detect next hit
					arena.bull:SetAttribute("AttackTriggered", false)
				end
				
				-- Movement detection logic could go here
				-- For now, we just wait out the duration
			end
		end
	end)
end

-- Helper to move arena so that its SpawnPlatform is at target position
local function moveArenaTo(arenaModel, targetPosition)
	local spawnPoint = arenaModel:FindFirstChild("ArenaPlatform")
	local currentSpawnPos
	
	if spawnPoint then
		if spawnPoint:IsA("BasePart") then
			currentSpawnPos = spawnPoint.Position
		elseif spawnPoint:IsA("Model") then
			if spawnPoint.PrimaryPart then
				currentSpawnPos = spawnPoint.PrimaryPart.Position
			else
				local firstPart = spawnPoint:FindFirstChildWhichIsA("BasePart", true)
				if firstPart then
					currentSpawnPos = firstPart.Position
				end
			end
		end
	end
	
	if not currentSpawnPos then
		warn("⚠️ Could not find spawn position for " .. arenaModel.Name .. " - using Model Pivot")
		if arenaModel.PrimaryPart then
			arenaModel:SetPrimaryPartCFrame(CFrame.new(targetPosition))
		else
			arenaModel:PivotTo(CFrame.new(targetPosition))
		end
		return
	end
	
	-- Calculate offset to move the spawn to the target
	local offset = targetPosition - currentSpawnPos
	arenaModel:PivotTo(arenaModel:GetPivot() + offset)
	print("   Moved " .. arenaModel.Name .. " by offset " .. tostring(offset))
end

-- Clone and position arenas
local function createArenaInstances()
	print("🏗️ Creating arena instances...")
	print("")
	
	-- Arena 1: Use template
	templateArena.Name = "BullArena_1"
	
	-- Ensure template is anchored first
	anchorModel(templateArena)
	
	-- Position first arena using smart move
	moveArenaTo(templateArena, Vector3.new(ARENA_SPACING, ARENA_HEIGHT, 0))
	
	-- Setup lights for template
	-- setupArenaLights(templateArena) -- DEPRECATED: Using UI based traffic light
	
	local spawnPoint = templateArena:FindFirstChild("ArenaPlatform")
	local bull = templateArena:FindFirstChild("bull")
	
	-- Inject Server-Side Movement Script
	local behaviorScript = script.Parent:FindFirstChild("BullBehavior")
	if behaviorScript then
		local clone = behaviorScript:Clone()
		clone.Parent = bull
		print("   ✅ Injected BullBehavior script")
	else
		warn("   ❌ BullBehavior script not found in ServerScriptService!")
	end
	
	print("   Arena 1:")
	print("      Name: " .. templateArena.Name)
	print("      Bull: " .. tostring(bull))
	print("      Spawn: " .. tostring(spawnPoint))
	if spawnPoint and spawnPoint:IsA("BasePart") then
		print("      Spawn Position: " .. tostring(spawnPoint.Position))
	end
	print("      Position: (" .. ARENA_SPACING .. ", " .. ARENA_HEIGHT .. ", 0)")
	
	table.insert(arenaPool, {
		arena = templateArena,
		bull = bull,
		spawnPoint = spawnPoint,
		occupied = false,
		player = nil
	})
	
	print("   ✅ Arena 1 added to pool")
	print("")
	
	-- Clone additional arenas
	for i = 2, ARENA_COUNT do
		print("   Cloning arena " .. i .. "...")
		local newArena = templateArena:Clone()
		newArena.Name = "BullArena_" .. i
		
		-- Ensure clone is anchored
		anchorModel(newArena)
		
		local angle = (2 * math.pi / ARENA_COUNT) * (i - 1)
		local x = math.round(math.cos(angle) * ARENA_SPACING)
		local z = math.round(math.sin(angle) * ARENA_SPACING)
		
		moveArenaTo(newArena, Vector3.new(x, ARENA_HEIGHT, z))
		
		newArena.Parent = workspace
		
		-- Setup lights for clone
		-- setupArenaLights(newArena) -- DEPRECATED: Using UI based traffic light
		
		local clonedSpawnPoint = newArena:FindFirstChild("ArenaPlatform")
		local clonedBull = newArena:FindFirstChild("bull")
		-- Animation handled on client
		
		print("      Bull: " .. tostring(clonedBull))
		print("      Spawn: " .. tostring(clonedSpawnPoint))
		if clonedSpawnPoint and clonedSpawnPoint:IsA("BasePart") then
			print("      Spawn Position: " .. tostring(clonedSpawnPoint.Position))
		end
		print("      Position: (" .. x .. ", " .. ARENA_HEIGHT .. ", " .. z .. ")")
		
		table.insert(arenaPool, {
			arena = newArena,
			bull = clonedBull,
			spawnPoint = clonedSpawnPoint,
			occupied = false,
			player = nil
		})
		
		print("   ✅ Arena " .. i .. " added to pool")
	end
	
	print("")
	print("=" .. string.rep("=", 60))
	print("✅ ARENA CREATION COMPLETE")
	print("📊 Total arenas in pool: " .. #arenaPool)
	print("=" .. string.rep("=", 60))
	print("")
end

-- Get an available arena for a player
local function getAvailableArena(player)
	print("🔍 [" .. player.Name .. "] Searching for arena...")
	print("   Pool size: " .. #arenaPool)
	
	if #arenaPool == 0 then
		warn("   ❌ POOL IS EMPTY - createArenaInstances() was never called!")
		return nil
	end
	
	for i, arenaData in ipairs(arenaPool) do
		local status = arenaData.occupied and ("OCCUPIED by " .. tostring(arenaData.player)) or "AVAILABLE"
		print("   Arena " .. i .. ": " .. status)
		
		if not arenaData.occupied then
			arenaData.occupied = true
			arenaData.player = player
			playerArenas[player.UserId] = arenaData
			print("   ✅ Assigned " .. arenaData.arena.Name)
			return arenaData
		end
	end
	
	warn("   ⚠️ All arenas occupied!")
	return nil
end

-- Free up an arena when player leaves
local function freeArena(player)
	local arenaData = playerArenas[player.UserId]
	if arenaData then
		-- Signal bull to reset (stops attack, resets state)
		if arenaData.bull then
			arenaData.bull:SetAttribute("ResetBull", true)
			local maxHealth = arenaData.bull:GetAttribute("MaxHealth") or 3000
			arenaData.bull:SetAttribute("Health", maxHealth)
			arenaData.bull:SetAttribute("AggroEndTime", 0)
			print("💚 Reset bull health to " .. maxHealth .. " and triggered full reset")
		end
		
		arenaData.occupied = false
		arenaData.player = nil
		playerArenas[player.UserId] = nil
		print("🔓 Freed arena " .. arenaData.arena.Name .. " from " .. player.Name)
	end
	
	-- Disconnect death connection if exists
	if deathConnections[player.UserId] then
		deathConnections[player.UserId]:Disconnect()
		deathConnections[player.UserId] = nil
		print("🔌 Disconnected death listener for " .. player.Name)
	end
	
	-- Notify that player can use platform again (for BullTeleporter)
	_G.ClearPlayerFromPlatform = _G.ClearPlayerFromPlatform or function() end
	_G.ClearPlayerFromPlatform(player)
end

-- Teleport player to arena
local function teleportToArena(player, arenaData)
	local character = player.Character
	if not character then 
		warn("❌ No character for " .. player.Name)
		return false 
	end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then 
		warn("❌ No HumanoidRootPart for " .. player.Name)
		return false 
	end
	
	local spawnPoint = arenaData.spawnPoint
	if not spawnPoint then
		warn("❌ No spawn point found in arena " .. arenaData.arena.Name)
		print("Arena contents:", table.concat(arenaData.arena:GetChildren(), ", "))
		return false
	end
	
	-- Get spawn position
	local targetCFrame
	if spawnPoint:IsA("BasePart") then
		-- It's a part - use its CFrame but ensure upright orientation
		targetCFrame = CFrame.new(spawnPoint.Position + Vector3.new(0, 5, 0))
	elseif spawnPoint:IsA("Model") then
		-- It's a model - try PrimaryPart or first BasePart
		if spawnPoint.PrimaryPart then
			targetCFrame = CFrame.new(spawnPoint.PrimaryPart.Position + Vector3.new(0, 5, 0))
		else
			-- Find first BasePart in the model
			local firstPart = spawnPoint:FindFirstChildWhichIsA("BasePart", true)
			if firstPart then
				targetCFrame = CFrame.new(firstPart.Position + Vector3.new(0, 5, 0))
			else
				warn("❌ Model has no parts! Model:", spawnPoint.Name)
				return false
			end
		end
	else
		warn("❌ Spawn point is invalid type: " .. spawnPoint.ClassName)
		warn("   Expected: BasePart or Model")
		warn("   Got:", spawnPoint:GetFullName())
		return false
	end
	
	-- Teleport player with upright orientation
	humanoidRootPart.CFrame = targetCFrame
	print("✅ Teleported " .. player.Name .. " to " .. arenaData.arena.Name .. " at position: " .. tostring(targetCFrame.Position))
	
	-- Connect to player death to free arena
	local humanoid = character:FindFirstChild("Humanoid")
	if humanoid then
		-- Disconnect previous connection if exists
		if deathConnections[player.UserId] then
			deathConnections[player.UserId]:Disconnect()
		end
		
		deathConnections[player.UserId] = humanoid.Died:Connect(function()
			print("💀 " .. player.Name .. " died in arena - freeing arena")
			freeArena(player)
		end)
		print("🔗 Connected death listener for " .. player.Name)
	end
	
	-- Start Game Timer (Animation handled by client)
	task.spawn(function()
		local timeLeft = GAME_DURATION
		
		-- Start Traffic Light Game Logic
		startTrafficLightGame(player, arenaData.arena)
			
			-- Loop while time remains and player is still in this arena
			while timeLeft >= 0 and arenaData.occupied and arenaData.player == player do
				if GameTimerRE then
					-- Send time and arena model to client
					GameTimerRE:FireClient(player, timeLeft, arenaData.arena)
				end
				
				if timeLeft == 0 then
					print("🏁 Game over for " .. player.Name)
					break
				end
				
				timeLeft = timeLeft - 1
				task.wait(1)
			end
	end)
	
	return true
end

-- Public function for other scripts to request arena
function _G.RequestBullArena(player)
	local arenaData = getAvailableArena(player)
	if arenaData then
		local success = teleportToArena(player, arenaData)
		if success then
			return arenaData
		else
			freeArena(player)
			return nil
		end
	end
	return nil
end

-- Public function to free arena
function _G.FreeBullArena(player)
	freeArena(player)
end

-- Public function to get player's current arena
function _G.GetPlayerArena(player)
	return playerArenas[player.UserId]
end

-- Clean up when player leaves game
Players.PlayerRemoving:Connect(function(player)
	freeArena(player)
end)

-- Initialize arenas
print("🎬 Calling createArenaInstances()...")
local success, err = pcall(createArenaInstances)

if not success then
	error("❌ FATAL: createArenaInstances() failed: " .. tostring(err))
end

print("=" .. string.rep("=", 60))
print("✅ BULL ARENA MANAGER READY")
print("📊 Total arenas: " .. #arenaPool .. "/" .. ARENA_COUNT)
print("🌍 Global functions set: _G.RequestBullArena, _G.FreeBullArena")
print("=" .. string.rep("=", 60))

-- Export for other scripts
return {
	RequestArena = _G.RequestBullArena,
	FreeArena = _G.FreeBullArena,
	GetPlayerArena = _G.GetPlayerArena,
	ArenaCount = ARENA_COUNT
}
