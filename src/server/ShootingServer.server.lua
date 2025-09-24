local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local shootEvent = ReplicatedStorage:WaitForChild("ShootEvent")

-- Bullseye tracking uses bullseyeCurrent / bullseyeHigh fields in player data (set up in PlayerDataManager)
local function updateBullseye(player, ringNumber)
	local d = _G.getData(player)
	if not d then return end
	local points = 7 - ringNumber -- ring1=6 .. ring6=1
	d.bullseyeCurrent = (d.bullseyeCurrent or 0) + points
	if d.bullseyeCurrent > (d.bullseyeHigh or 0) then
		d.bullseyeHigh = d.bullseyeCurrent
	end
end

local function _endBullseyeRound(player)
	local d = _G.getData(player)
	if d then d.bullseyeCurrent = 0 end
end

-- Add global bullseye hit function if not already defined
if not _G.onBullseyeHit then
	_G.onBullseyeHit = function(player, ringNumber)
		updateBullseye(player, ringNumber)
		_G.checkRankUp(player)
	end
end

-- Add global bullseye miss function if not already defined
if not _G.onBullseyeMiss then
	_G.onBullseyeMiss = function(player) end
end

-- Add onShot function if not already defined
if not _G.onShot then
	_G.onShot = function(player)
		local d = _G.getData(player)
		d.sessionShots = (d.sessionShots or 0) + 1
	end
end

shootEvent.OnServerEvent:Connect(function(player, mouseHitPosition)
	-- Track the shot in player data first (regardless of hit/miss)
	pcall(function()
		if _G.onShot then
			_G.onShot(player)
		end
	end)

	if not player or not mouseHitPosition then return end

	local character = player.Character
	if not character then return end

	local head = character:FindFirstChild("Head")
	if not head then return end

	local origin = head.Position
	local directionVector = mouseHitPosition - origin
	local distance = directionVector.Magnitude
	local direction = directionVector.Unit * math.max(distance, 100)

	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = { character }
	-- Blacklist is deprecated; use Exclude to ignore the character
	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	local result = Workspace:Raycast(origin, direction, rayParams)

	if not result or not result.Instance then
		_G.onMiss(player)
		return
	end

	local hitPart = result.Instance
	local bullseyeModel = hitPart:FindFirstAncestor("Bullseye")

	-- 🟢 Bullseye Mode
	if bullseyeModel then
		local playerId = bullseyeModel:GetAttribute("PlayerId")
		if playerId == player.UserId then
			local ringName = hitPart.Parent.Name
			local ringNumber = tonumber(string.match(ringName, "%d+")) or 6
			_G.onBullseyeHit(player, ringNumber)
		else
			_G.onBullseyeMiss(player)
		end
		return
	end

	-- 🟢 Normal Mode
	if hitPart:GetAttribute("PlayerId") == player.UserId then
		hitPart:Destroy()
		_G.recordTargetHit(player)
		if _G.onHit then _G.onHit(player) end
		_G.checkRankUp(player)
	else
		if _G.onMiss then _G.onMiss(player) end
	end
end)

