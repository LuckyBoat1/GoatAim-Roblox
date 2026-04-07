warn("[BullseyeAimRun] Script starting...")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

-- Create RemoteEvents if they don't exist (don't rely on RunSystem loading first)
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
--
local RunDuration = 10
local MaxShots = 30
local BullseyesPerRun = 3

local speed = 0.9 -- movement speed per frame
local maxDistance = 16 -- max distance bullseye can move from its spawnPos

local function spawnBullseyes(player, basePosition)
	local targetTemplate = ReplicatedStorage:FindFirstChild("Bullseye")
	if not targetTemplate then
		warn("Bullseye Not Found")
		return
	end

	for i = 1, BullseyesPerRun do
		local offsetX = math.random(30, 60)
		local offsetY = math.random(18, 30) -- FIXED: typo math.ramdom → math.random
		local offsetZ = math.random(-20, 20)

		local target = targetTemplate:Clone()
		local spawnPos = basePosition + Vector3.new(offsetX, offsetY, offsetZ)
		local rotation = CFrame.Angles(math.rad(90), 0, math.rad(90))
		target:PivotTo(CFrame.new(spawnPos) * rotation)
		target:SetAttribute("PlayerId", player.UserId)
		target.Parent = Workspace -- FIXED: Targets must be parented to Workspace or they won't appear

		task.spawn(function()
			local currentDirection = math.random(1, 4)
			local currentPos = spawnPos

			while target.Parent do
				local moveTime = math.random(1, 15) / 10 -- FIXED: to allow 1–1.5 seconds
				local elapsed = 0

				while elapsed < moveTime and target.Parent do
					local dt = task.wait(0.03)
					elapsed += dt

					local moveVector = Vector3.new()

					if currentDirection == 1 then
						moveVector = Vector3.new(0, speed, 0)
					elseif currentDirection == 2 then
						moveVector = Vector3.new(0, -speed, 0)
					elseif currentDirection == 3 then
						moveVector = Vector3.new(0, 0, -speed)
					elseif currentDirection == 4 then
						moveVector = Vector3.new(0, 0, speed)
					end

					local newPos = currentPos + moveVector
					local offsetFromSpawn = newPos - spawnPos

					if offsetFromSpawn.Magnitude > maxDistance then
						currentDirection = ((currentDirection) % 4) + 1
					else
						currentPos = newPos
						local pivot = target:GetPivot()
						local rotationOnly = pivot - pivot.Position -- FIXED: wrong subtraction
						target:PivotTo(CFrame.new(currentPos) * rotationOnly)
					end
				end
				currentDirection = math.random(1, 4)
			end
		end)
	end
end

local function updateScore(player, points, streak, ammo)
	scoreUpdate:FireClient(player, points, streak, ammo)
end

local bullseyeFound = false
warn("[BullseyeAimRun] Searching for BullseyePlatform (recursive)...")
local foundPlatform = Workspace:FindFirstChild("BullseyePlatform", true)

-- If no BullseyePlatform exists, create one near SpawnArena
if not foundPlatform then
	local spawnArena = Workspace:FindFirstChild("Game", true) and Workspace.Game:FindFirstChild("SpawnArena")
	local bullPlatform = spawnArena and spawnArena:FindFirstChild("BullPlatform", true)
	local refPos
	if bullPlatform then
		local part = bullPlatform:IsA("BasePart") and bullPlatform or bullPlatform:FindFirstChildWhichIsA("BasePart")
		if part then refPos = part.Position + Vector3.new(-30, 0, 0) end
	end
	refPos = refPos or Vector3.new(226, 828, -400) -- fallback near spawn area

	warn("[BullseyeAimRun] No BullseyePlatform found, creating one at", refPos)
	foundPlatform = Instance.new("Part")
	foundPlatform.Name = "BullseyePlatform"
	foundPlatform.Size = Vector3.new(10, 1, 10)
	foundPlatform.Position = refPos
	foundPlatform.Anchored = true
	foundPlatform.BrickColor = BrickColor.new("Bright blue")
	foundPlatform.Material = Enum.Material.Neon
	foundPlatform.Parent = spawnArena or Workspace
end

if foundPlatform then
	bullseyeFound = true
	warn("[BullseyeAimRun] Using BullseyePlatform:", foundPlatform:GetFullName())
	local platform = foundPlatform
		local prompt = platform:FindFirstChildOfClass("ProximityPrompt")
		if not prompt then
			warn("[BullseyeAimRun] ⚠️ No ProximityPrompt on BullseyePlatform! Creating one...")
			prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Start Bullseye Run"
			prompt.ObjectText = "Bullseye Aim Training"
			prompt.HoldDuration = 0.5
			prompt.Parent = platform
		end
		if prompt then
			warn("[BullseyeAimRun] ✅ ProximityPrompt connected on", platform:GetFullName())
			prompt.Triggered:Connect(function(player)
				pcall(function()
					if _G.notify then
						_G.notify(player, "Bullseye Run Started")
					end
				end)

				startRunEvent:FireClient(player, "bullseye", MaxShots)

				local ok, data = pcall(function() return _G.getData(player) end)
				if not ok or not data then
					warn("[BullseyeAimRun] _G.getData failed for", player.Name)
					return
				end
				data.remainingShots = MaxShots
				data.bullseyeScore = 0

				spawnBullseyes(player, platform.Position)



				task.delay(RunDuration, function()
					pcall(function() if _G.notify then _G.notify(player, "Run ended") end end)

					for _, bullseye in pairs (Workspace:GetChildren()) do
						if bullseye.Name == "Bullseye" and bullseye:GetAttribute("PlayerId")== player.UserId then
							bullseye:Destroy()
						end
					end
					scoreUpdate:FireClient(player, "end")
				end)
			end)
		end
end

_G.onBullseyeHit = function(player, ringNumber)
	print("[BullseyeAimRun] onBullseyeHit called. Ring:", ringNumber) -- DEBUG
	local ok, data = pcall(function() return _G.getData(player) end)
	if not ok or not data then return end
	if not data.remainingShots or data.remainingShots <= 0 then return end

	local ringPoints = {6, 5, 4, 3, 2, 1}
	local points = ringPoints[ringNumber] or 0

	local money = points * 5
	pcall(function() if _G.addMoney then _G.addMoney(player, money) end end)

	data.remainingShots -= 1
	data.bullseyeScore += points

	if data.remainingShots == 0 then
		for _, bullseye in pairs (Workspace:GetChildren()) do
			if bullseye.Name == "Bullseye" and bullseye:GetAttribute("PlayerId") == player.UserId then
				bullseye:Destroy()
			end
		end
		pcall(function() if _G.notify then _G.notify(player, "Run ended") end end)
		scoreUpdate:FireClient(player, "end")

	end

	updateScore(player, data.bullseyeScore, nil, data.remainingShots)
end

_G.onBullseyeMiss = function(player)
	local ok, data = pcall(function() return _G.getData(player) end)
	if not ok or not data or not data.remainingShots or data.remainingShots <= 0 then return end
	data.remainingShots -= 1
	if data.remainingShots == 0 then
		for _, bullseye in pairs (Workspace:GetChildren()) do
			if bullseye.Name == "Bullseye" and bullseye:GetAttribute("PlayerId") == player.UserId then
				bullseye:Destroy()
			end
		end
		pcall(function() if _G.notify then _G.notify(player, "Run ended") end end)
		scoreUpdate:FireClient(player, "end")

	end
	updateScore(player, data.bullseyeScore, nil, data.remainingShots)

end

if not bullseyeFound then
	warn("[BullseyeAimRun] ⚠️ No 'BullseyePlatform' found in Workspace! Bullseye runs won't work.")
	warn("[BullseyeAimRun] Add a Part named 'BullseyePlatform' to Workspace to enable bullseye aim runs.")
end

local bullseyeTemplate = ReplicatedStorage:FindFirstChild("Bullseye")
if not bullseyeTemplate then
	warn("[BullseyeAimRun] ⚠️ No 'Bullseye' template found in ReplicatedStorage! Targets can't spawn.")
else
	warn("[BullseyeAimRun] ✅ Bullseye template found in ReplicatedStorage")
end

warn("[BullseyeAimRun] ✅ Script loaded. BullseyePlatform found =", bullseyeFound)
