-- ============================================================
-- ✏️ EASY CONFIG — copy this script for each leaderboard rig,
--    then only change the two values below.
-- ============================================================
local EVENT_NAME = "UpdateTopPlayTimeEvent"  -- must be unique per leaderboard
local RIG_NAME   = "Rig1"                   -- name of the Rig child inside this model
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

-- Create (or reuse) the RemoteEvent for this leaderboard
local updateEvent = ReplicatedStorage:FindFirstChild(EVENT_NAME)
if not updateEvent then
	updateEvent = Instance.new("RemoteEvent")
	updateEvent.Name = EVENT_NAME
	updateEvent.Parent = ReplicatedStorage
end

-- Grab the rig and its Humanoid
local rig      = script.Parent:WaitForChild(RIG_NAME)
local humanoid = rig:WaitForChild("Humanoid")

-- Optional animation module sitt--ing next to this script
local ok, playAnimationInRig = pcall(function()
	return require(script.Parent:WaitForChild("PlayAnimationInRig"))
end)
if not ok then playAnimationInRig = nil end

-- Listen for the client sending the top player's UserId
updateEvent.OnServerEvent:Connect(function(_, topUserId)
	-- Apply the top player's avatar appearance
	local descOk, description = pcall(function()
		return Players:GetHumanoidDescriptionFromUserId(topUserId)
	end)
	if descOk and description then
		humanoid:ApplyDescription(description)
	end

	-- Apply their display name
	local nameOk, playerName = pcall(function()
		return Players:GetNameFromUserIdAsync(topUserId)
	end)
	if nameOk and playerName then
		humanoid.DisplayName = playerName
	end

	-- Play the showcase animation (if module is present)
	if playAnimationInRig then
		if type(playAnimationInRig) == "function" then
			playAnimationInRig(rig)
		elseif playAnimationInRig.Play then
			playAnimationInRig.Play(rig)
		end
	end
end)
