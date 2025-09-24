-- Helpers.server.lua
-- Provides some global helper functions. (Consider migrating away from _G later.)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Support either folder name: Remotes or RemoteEvents
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then
	remotesFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
end
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "Remotes"
	remotesFolder.Parent = ReplicatedStorage
end

-- Ensure NotifyEvent exists
local notifyEvent = remotesFolder:FindFirstChild("NotifyEvent")
if not notifyEvent then
	notifyEvent = Instance.new("RemoteEvent")
	notifyEvent.Name = "NotifyEvent"
	notifyEvent.Parent = remotesFolder
end

_G.notify = function(player, text: string)
	if player then
		notifyEvent:FireClient(player, text)
	else
		for _, p in ipairs(Players:GetPlayers()) do
			notifyEvent:FireClient(p, text)
		end
	end
end

_G.updateLeaderboardGui = function(data) --[[ stub ]] end
_G.executeTrade = function(trade) --[[ stub ]] end