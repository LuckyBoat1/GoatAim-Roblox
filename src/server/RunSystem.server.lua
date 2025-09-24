-- Script Type: ServerScript
-- Location: ServerScriptService
-- MultiPlatformAimRun.lua
-- Current Date and Time: 2025-08-21 01:07:36
-- Current User: Hulk11121

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

local RunDuration = 3
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

	updateScore(player)
	print("Hit registered! Score: " .. data.currentRunHits)
end

-- Setup global onHit function
_G.onHit = onHit
-- Target spawning function
local function spawnTargets(player, basePosition)
	if not targetTemplate then
		warn("Target template not found")
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
				print("Target hit by " .. player.Name)
				onHit(player)
				target:Destroy()
			end
		end)
	else
		warn("No ClickDetector found on target")
	end

	return target
end

-- Check for existing platforms
local platformFound = false
for _, platform in pairs(Workspace:GetChildren()) do
	if platform.Name == "StartPlatform" then
		platformFound = true

		-- Add prompt if missing
		local prompt = platform:FindFirstChildOfClass("ProximityPrompt")
		if not prompt then
			prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Start Aim Run"
			prompt.ObjectText = "Test your speed!"
			prompt.HoldDuration = 0.5
			prompt.Parent = platform
		end

		-- Connect prompt to start run
		prompt.Triggered:Connect(function(player)
			print("Aim Run triggered by " .. player.Name)

			-- Notify player if function exists
			pcall(function()
				if _G.notify then
					_G.notify(player, "Aim Run Started")
				end
			end)

			startRunEvent:FireClient(player)

			-- Reset current run stats but keep high score
			local data = getPlayerData(player)
			data.currentRunHits = 0
			data.streak = 0

			-- Initial score update
			updateScore(player)

			-- Set end timer
			local startTime = tick()
			local endTime = startTime + RunDuration

			-- Spawn targets
			local spawnedTargets = {}

			-- Spawn initial targets
			for i = 1, 5 do  -- Start with 5 targets
				local target = spawnTargets(player, platform.Position)
				if target then
					table.insert(spawnedTargets, target)
				end
				wait(0.4)
			end

			-- Function to spawn more targets as needed
			local function spawnMoreTargets()
				if tick() < endTime then
					local activeTargets = 0

					-- Count current active targets
					for _, target in pairs(Workspace:GetChildren()) do
						if target.Name == "Target" and target:GetAttribute("PlayerId") == player.UserId then
							activeTargets = activeTargets + 1
						end
					end

					-- Spawn more if needed
					while activeTargets < 5 and tick() < endTime do
						local target = spawnTargets(player, platform.Position)
						if target then
							table.insert(spawnedTargets, target)
							activeTargets = activeTargets + 1
						end
						wait(0.1)
					end

					-- Schedule next check
					if tick() < endTime then
						task.delay(0.5, spawnMoreTargets)
					end
				end
			end

			-- Start the target respawn loop
			spawnMoreTargets()

			-- End the run after duration
			task.delay(RunDuration, function()
				pcall(function()
					if _G.notify then
						_G.notify(player, "Run ended")
					end
				end)

				-- Update high score if current run is better
				if data.currentRunHits > (data.runHits or 0) then
					data.runHits = data.currentRunHits
					print("New high score for " .. player.Name .. ": " .. data.runHits)
				end

				-- IMPORTANT: Force leaderboard update immediately
				pcall(function()
					if _G.forceLeaderboardUpdate then
						_G.forceLeaderboardUpdate()
					end
				end)

				-- Update final score
				updateScore(player, "end")

				-- Clean up targets
				for _, target in pairs(Workspace:GetChildren()) do
					if target.Name == "Target" and target:GetAttribute("PlayerId") == player.UserId then
						target:Destroy()
					end
				end

				print("Aim Run ended for " .. player.Name .. " with score: " .. (data.currentRunHits or 0))
				print("High score: " .. (data.runHits or 0))
			end)
		end)
	end
end

-- Create a platform if none exists
if not platformFound then
	local platform = Instance.new("Part")
	platform.Name = "StartPlatform"
	platform.Size = Vector3.new(10, 1, 10)
	platform.Position = Vector3.new(20, 5, 0)
	platform.Anchored = true
	platform.BrickColor = BrickColor.new("Bright green")
	platform.Material = Enum.Material.Neon
	platform.Parent = Workspace

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Start Aim Run"
	prompt.ObjectText = "Test your speed!"
	prompt.HoldDuration = 0.5
	prompt.Parent = platform

	print("Created new StartPlatform at position " .. tostring(platform.Position))

	-- Connect the same trigger logic as above
	prompt.Triggered:Connect(function(player)
		print("Aim Run triggered by " .. player.Name)

		-- Notify player if function exists
		pcall(function()
			if _G.notify then
				_G.notify(player, "Aim Run Started")
			end
		end)

		startRunEvent:FireClient(player)

		-- Reset current run stats but keep high score
		local data = getPlayerData(player)
		data.currentRunHits = 0
		data.streak = 0

		-- Initial score update
		updateScore(player)

		-- Set end timer
		local startTime = tick()
		local endTime = startTime + RunDuration

		-- Spawn targets
		local spawnedTargets = {}

		-- Spawn initial targets
		for i = 1, 5 do  -- Start with 5 targets
			local target = spawnTargets(player, platform.Position)
			if target then
				table.insert(spawnedTargets, target)
			end
			wait(0.4)
		end

		-- Function to spawn more targets as needed
		local function spawnMoreTargets()
			if tick() < endTime then
				local activeTargets = 0

				-- Count current active targets
				for _, target in pairs(Workspace:GetChildren()) do
					if target.Name == "Target" and target:GetAttribute("PlayerId") == player.UserId then
						activeTargets = activeTargets + 1
					end
				end

				-- Spawn more if needed
				while activeTargets < 5 and tick() < endTime do
					local target = spawnTargets(player, platform.Position)
					if target then
						table.insert(spawnedTargets, target)
						activeTargets = activeTargets + 1
					end
					wait(0.1)
				end

				-- Schedule next check
				if tick() < endTime then
					task.delay(0.5, spawnMoreTargets)
				end
			end
		end

		-- Start the target respawn loop
		spawnMoreTargets()

		-- End the run after duration
		task.delay(RunDuration, function()
			pcall(function()
				if _G.notify then
					_G.notify(player, "Run ended")
				end
			end)

			-- Update high score if current run is better
			if data.currentRunHits > (data.runHits or 0) then
				data.runHits = data.currentRunHits
				print("New high score for " .. player.Name .. ": " .. data.runHits)
			end

			-- IMPORTANT: Force leaderboard update immediately
			pcall(function()
				if _G.forceLeaderboardUpdate then
					_G.forceLeaderboardUpdate()
				end
			end)

			-- Update final score
			updateScore(player, "end")

			-- Clean up targets
			for _, target in pairs(Workspace:GetChildren()) do
				if target.Name == "Target" and target:GetAttribute("PlayerId") == player.UserId then
					target:Destroy()
				end
			end

			print("Aim Run ended for " .. player.Name .. " with score: " .. (data.currentRunHits or 0))
			print("High score: " .. (data.runHits or 0))
		end)
	end)
end

print("MultiPlatformAimRun loaded at 2025-08-21 01:07:36 by Hulk11121")