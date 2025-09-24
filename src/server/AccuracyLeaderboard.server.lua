local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LeaderboardUpdateEvent = Instance.new("RemoteEvent")
LeaderboardUpdateEvent.Name = "LeaderboardUpdateEvent"
LeaderboardUpdateEvent.Parent = ReplicatedStorage

local leaderboard = {
	ClassicScore = "runHits",
	BullsyeScore = "bullseyeScore"
}

local updateInterval = 1

-- Fix: Added null check and proper error handling
local function buildLeaderboard(statKey)
	local entries = {}
	for _, player in pairs(Players:GetPlayers()) do
		local success, data = pcall(function() 
			-- Make sure _G.getData exists before calling it
			if _G.getData then
				return _G.getData(player)
			end
			return nil
		end)

		if success and player and data and data[statKey] ~= nil then
			table.insert(entries, { 
				Name = player.Name,
				Value = data[statKey],
				UserId = player.UserId
			})
		else
			-- Add default entry if data isn't available
			table.insert(entries, { 
				Name = player.Name,
				Value = 0,
				UserId = player.UserId
			})
		end
	end

	table.sort(entries, function(a, b)
		return a.Value > b.Value
	end)

	while #entries > 10 do
		table.remove(entries)
	end

	return entries
end

local function updateAllLeaderboards(leaderboard)
	local allData = {}
	for leaderboardName, statKey in pairs(leaderboard) do
		allData[leaderboardName] = buildLeaderboard(statKey)
	end

	LeaderboardUpdateEvent:FireAllClients(allData)
end

local lastUpdate = 0

-- Add delay before starting to ensure PlayerDataManager is loaded
wait(2)

RunService.Heartbeat:Connect(function()
	if tick() - lastUpdate >= updateInterval then
		lastUpdate = tick()

		-- Add try/catch to prevent errors from breaking the whole leaderboard
		pcall(function()
			updateAllLeaderboards(leaderboard)
		end)
	end
end)

-- Add a timestamp to show when the module was loaded
local currentTime = "2025-08-20 22:09:08"
local currentUser = "Hulk11121"
