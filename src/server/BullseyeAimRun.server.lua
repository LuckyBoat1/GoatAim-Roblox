local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local startRunEvent = ReplicatedStorage:WaitForChild("StartRun")
local scoreUpdate = ReplicatedStorage:WaitForChild("ScoreUpdate")

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

for _, platform in pairs(Workspace:GetChildren()) do
	if platform.Name == "BullseyePlatform" then
		local prompt = platform:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			prompt.Triggered:Connect(function(player)
				_G.notify(player, "Bullseye Run Started")
				startRunEvent:FireClient(player, "bullseye", MaxShots)


				local data = _G.getData(player)
				data.remainingShots = MaxShots
				data.bullseyeScore = 0

				spawnBullseyes(player, platform.Position)



				task.delay(RunDuration, function()
					_G.notify(player, "Run ended")

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
end

_G.onBullseyeHit = function(player, ringNumber)
	print("[BullseyeAimRun] onBullseyeHit called. Ring:", ringNumber) -- DEBUG
	local data = _G.getData(player)
	if not data.remainingShots or data.remainingShots <= 0 then return end

	local ringPoints = {6, 5, 4, 3, 2, 1}
	local points = ringPoints[ringNumber] or 0

	local money = points * 5
	_G.addMoney(player, money)

	data.remainingShots -= 1
	data.bullseyeScore += points

	if data.remainingShots == 0 then
		for _, bullseye in pairs (Workspace:GetChildren()) do
			if bullseye.Name == "Bullseye" and bullseye:GetAttribute("PlayerId") == player.UserId then
				bullseye:Destroy()
			end
		end
		_G.notify(player, "Run ended")
		scoreUpdate:FireClient(player, "end")

	end

	updateScore(player, data.bullseyeScore, nil, data.remainingShots)
end

_G.onBullseyeMiss = function(player)
	local data = _G.getData(player)
	if not data or data.remainingShots <= 0 then return end
	data.remainingShots -= 1
	if data.remainingShots == 0 then
		for _, bullseye in pairs (Workspace:GetChildren()) do
			if bullseye.Name == "Bullseye" and bullseye:GetAttribute("PlayerId") == player.UserId then
				bullseye:Destroy()
			end
		end
		_G.notify(player, "Run ended")
		scoreUpdate:FireClient(player, "end")

	end
	updateScore(player, data.bullseyeScore, nil, data.remainingShots)

end
