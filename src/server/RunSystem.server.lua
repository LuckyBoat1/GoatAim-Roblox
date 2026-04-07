-- Script Type: ServerScript
-- Location: ServerScriptService
-- MultiPlatformAimRun.lua
warn("[RunSystem] Script starting...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

-- Create RemoteEvents if they don't exist yet
local startRunEvent = ReplicatedStorage:FindFirstChild("StartRun")
if not startRunEvent then
	startRunEvent = Instance.new("RemoteEvent")
	startRunEvent.Name = "StartRun"
	startRunEvent.Parent = ReplicatedStorage
end

local scoreUpdate = ReplicatedStorage:FindFirstChild("ScoreUpdate")
if not scoreUpdate then
	scoreUpdate = Instance.new("RemoteEvent")
	scoreUpdate.Name = "ScoreUpdate"
	scoreUpdate.Parent = ReplicatedStorage
end

local RunDuration = 30
local TargetsPerRun = 30

-- Create a target template
local targetTemplate
if not ReplicatedStorage:FindFirstChild("Target") then
	print("Creating Target template")
	targetTemplate = Instance.new("Part")
	targetTemplate.Name = "Target"
	targetTemplate.Size = Vector3.new(2, 2, 0.2)
	targetTemplate.BrickColor = BrickColor.new("Bright blue")
	targetTemplate.Material = Enum.Material.Neon
	targetTemplate.Anchored = true
	targetTemplate.CanCollide = false

	-- Add a ClickDetector for interaction
	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = 100
	clickDetector.Parent = targetTemplate

	targetTemplate.Parent = ReplicatedStorage
	print("Target created successfully")
else
	targetTemplate = ReplicatedStorage:FindFirstChild("Target")
end

-- Simplified player data for testing if _G.getData isn't working
local localPlayerData = {}

-- FIXED: Proper implementation of getPlayerData using _G.getData
local function getPlayerData(player)
	if _G.getData then
		local success, result = pcall(function()
			return _G.getData(player)
		end)

		if success and result then
			-- Initialize required fields if they don't exist
			if not result.currentRunHits then result.currentRunHits = 0 end
			if not result.runHits then result.runHits = 0 end
			if not result.streak then result.streak = 0 end
			if not result.totalHits then result.totalHits = 0 end
			if not result.sessionHits then result.sessionHits = 0 end

			return result
		end
	end

	-- Fallback to local data if _G.getData fails
	if not localPlayerData[player.UserId] then
		localPlayerData[player.UserId] = {
			runHits = 0,
			streak = 0,
			totalHits = 0,
			sessionHits = 0,
			currentRunHits = 0,
			highScore = 0
		}
	end

	return localPlayerData[player.UserId]
end

local function updateScore(player, score)
	local data = getPlayerData(player)
	if score == "end" then
		scoreUpdate:FireClient(player, "end")
	else
		scoreUpdate:FireClient(player, data.currentRunHits, data.streak)
	end
end

local function onHit(player)
	local data = getPlayerData(player)

	local bonus = math.min((data.streak or 0) * 0.1, 2)
	local money = 10 * (1 + bonus)

	-- Update player stats
	data.totalHits = (data.totalHits or 0) + 1
	data.sessionHits = (data.sessionHits or 0) + 1
	data.currentRunHits = (data.currentRunHits or 0) + 1
	data.streak = (data.streak or 0) + 1

	-- Try to use global money function if available
	pcall(function()
		if _G.addMoney then
			_G.addMoney(player, money)
		end
	end)

	-- Award EXP for practice (2 per target hit, streak bonus up to +1)
	pcall(function()
		if _G.addExp then
			local expGain = math.floor(2 + math.min((data.streak or 0) * 0.1, 1))
			_G.addExp(player, expGain)
		end
	end)

	updateScore(player)
	print("Hit registered! Score: " .. data.currentRunHits)
end

-- Setup global onHit function
_G.onHit = onHit

-- Target spawning function
local function spawnTargets(player, basePosition)
	if not targetTemplate then
		warn("[RunSystem] Target template not found")
		return
	end

	local offsetX = math.random(5, 60)
	local offsetY = math.random(1, 20)
	local offsetZ = math.random(-20, 20)

	local target = targetTemplate:Clone()
	target.Position = basePosition + Vector3.new(offsetX, offsetY, offsetZ)
	target:SetAttribute("PlayerId", player.UserId)
	target.Parent = Workspace

	-- Add click handling
	local clickDetector = target:FindFirstChildOfClass("ClickDetector")
	if clickDetector then
		clickDetector.MouseClick:Connect(function(playerWhoClicked)
			if playerWhoClicked == player then
				print("[RunSystem] Target hit by " .. player.Name)
				onHit(player)
				target:Destroy()
			end
		end)
	else
		warn("[RunSystem] No ClickDetector found on target")
	end

	return target
end

-- Shared function to connect a platform's ProximityPrompt to the aim run logic
local function connectPlatform(platform)
	local prompt = platform:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Start Aim Run"
		prompt.ObjectText = "Test your speed!"
		prompt.HoldDuration = 0.5
		prompt.Parent = platform
	end

	warn("[RunSystem] ✅ ProximityPrompt connected on", platform:GetFullName())

	prompt.Triggered:Connect(function(player)
		warn("[RunSystem] Aim Run triggered by " .. player.Name)

		pcall(function()
			if _G.notify then _G.notify(player, "Aim Run Started") end
		end)

		startRunEvent:FireClient(player)

		local data = getPlayerData(player)
		data.currentRunHits = 0
		data.streak = 0
		updateScore(player)

		local startTime = tick()
		local endTime = startTime + RunDuration

		-- Spawn initial 5 targets
		for i = 1, 5 do
			spawnTargets(player, platform.Position)
			task.wait(0.4)
		end

		-- Respawn loop: keep 5 active targets
		local function spawnMoreTargets()
			if tick() >= endTime then return end

			local activeTargets = 0
			for _, target in pairs(Workspace:GetChildren()) do
				if target.Name == "Target" and target:GetAttribute("PlayerId") == player.UserId then
					activeTargets += 1
				end
			end

			while activeTargets < 5 and tick() < endTime do
				spawnTargets(player, platform.Position)
				activeTargets += 1
				task.wait(0.1)
			end

			if tick() < endTime then
				task.delay(0.5, spawnMoreTargets)
			end
		end
		spawnMoreTargets()

		-- End the run after duration
		task.delay(RunDuration, function()
			pcall(function()
				if _G.notify then _G.notify(player, "Run ended") end
			end)

			if data.currentRunHits > (data.runHits or 0) then
				data.runHits = data.currentRunHits
				warn("[RunSystem] New high score for " .. player.Name .. ": " .. data.runHits)
			end

			pcall(function()
				if _G.forceLeaderboardUpdate then _G.forceLeaderboardUpdate() end
			end)

			updateScore(player, "end")

			for _, target in pairs(Workspace:GetChildren()) do
				if target.Name == "Target" and target:GetAttribute("PlayerId") == player.UserId then
					target:Destroy()
				end
			end

			warn("[RunSystem] Aim Run ended for " .. player.Name .. " | Score: " .. (data.currentRunHits or 0) .. " | High: " .. (data.runHits or 0))
		end)
	end)
end

-- Search RECURSIVELY for StartPlatform (it may be inside Workspace.Game.SpawnArena)
local platformFound = false
warn("[RunSystem] Searching for StartPlatform (recursive)...")
local existingPlatform = Workspace:FindFirstChild("StartPlatform", true)
if existingPlatform then
	platformFound = true
	warn("[RunSystem] Found StartPlatform:", existingPlatform:GetFullName())
	connectPlatform(existingPlatform)
end

-- Create a platform if none exists — place it near SpawnArena
if not platformFound then
	-- Find SpawnArena to place the platform nearby
	local spawnArena = Workspace:FindFirstChild("Game", true) and Workspace.Game:FindFirstChild("SpawnArena")
	local bullPlatform = spawnArena and spawnArena:FindFirstChild("BullPlatform", true)
	local refPos
	if bullPlatform then
		local part = bullPlatform:IsA("BasePart") and bullPlatform or bullPlatform:FindFirstChildWhichIsA("BasePart")
		if part then refPos = part.Position + Vector3.new(30, 0, 0) end
	end
	refPos = refPos or Vector3.new(280, 828, -400) -- fallback near spawn area

	warn("[RunSystem] No StartPlatform found, creating one at", refPos)
	local platform = Instance.new("Part")
	platform.Name = "StartPlatform"
	platform.Size = Vector3.new(10, 1, 10)
	platform.Position = refPos
	platform.Anchored = true
	platform.BrickColor = BrickColor.new("Bright green")
	platform.Material = Enum.Material.Neon
	platform.Parent = spawnArena or Workspace
	connectPlatform(platform)
end

warn("[RunSystem] ✅ MultiPlatformAimRun loaded. platformFound =", platformFound)