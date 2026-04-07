-- KillsLeaderboard.server.lua
-- DISABLED: logic moved to _KillsWL_Leaderboards.server.lua
-- This file is kept to avoid breaking Studio's file reference.
return
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local EVENT_NAME        = "KillsLeaderboardEvent"
local UPDATE_EVENT_NAME = "UpdateTopKillsEvent"
local BROADCAST_KEY     = "KillsScore"
local DATA_KEY          = "battles"
local UPDATE_INTERVAL   = 2
local MAX_ENTRIES       = 10

local LeaderboardEvent = ReplicatedStorage:FindFirstChild(EVENT_NAME)
if not LeaderboardEvent then
LeaderboardEvent = Instance.new("RemoteEvent")
LeaderboardEvent.Name = EVENT_NAME
LeaderboardEvent.Parent = ReplicatedStorage
end

local UpdateAvatarEvent = ReplicatedStorage:FindFirstChild(UPDATE_EVENT_NAME)
if not UpdateAvatarEvent then
UpdateAvatarEvent = Instance.new("RemoteEvent")
UpdateAvatarEvent.Name = UPDATE_EVENT_NAME
UpdateAvatarEvent.Parent = ReplicatedStorage
end

local _boardDebugDone = false
local function updateBoardLabels(entries)
	local gameFolder = workspace:FindFirstChild("Game")
	if not gameFolder then
		if not _boardDebugDone then warn("[KillsLB] ❌ workspace.Game not found") end
		_boardDebugDone = true; return
	end
	local spawnArena = gameFolder:FindFirstChild("SpawnArena")
	if not spawnArena then
		if not _boardDebugDone then
			warn("[KillsLB] ❌ Game.SpawnArena not found. Game children:")
			for _, c in ipairs(gameFolder:GetChildren()) do warn("  - " .. c.Name) end
		end
		_boardDebugDone = true; return
	end
	local boardModel = spawnArena:FindFirstChild("TopKills")
	if not boardModel then
		if not _boardDebugDone then
			warn("[KillsLB] ❌ SpawnArena.TopKills not found. Children:")
			for _, c in ipairs(spawnArena:GetChildren()) do warn("  - " .. c.Name .. " [" .. c.ClassName .. "]") end
		end
		_boardDebugDone = true; return
	end
	local scoreBlock = boardModel:FindFirstChild("ScoreBlock")
	if not scoreBlock then
		if not _boardDebugDone then
			warn("[KillsLB] ❌ TopKills.ScoreBlock not found. Children:")
			for _, c in ipairs(boardModel:GetChildren()) do warn("  - " .. c.Name) end
		end
		_boardDebugDone = true; return
	end
	local gui = scoreBlock:FindFirstChild("Leaderboard")
	if not gui then
		if not _boardDebugDone then
			warn("[KillsLB] ❌ ScoreBlock.Leaderboard not found. Children:")
			for _, c in ipairs(scoreBlock:GetChildren()) do warn("  - " .. c.Name .. " [" .. c.ClassName .. "]") end
		end
		_boardDebugDone = true; return
	end
	local namesFolder  = gui:FindFirstChild("Names")
	local scoresFolder = gui:FindFirstChild("Score")
	if not namesFolder or not scoresFolder then
		if not _boardDebugDone then
			warn("[KillsLB] ❌ Names/Score folders missing. GUI children:")
			for _, c in ipairs(gui:GetChildren()) do warn("  - " .. c.Name) end
		end
		_boardDebugDone = true; return
	end
	if not _boardDebugDone then
		warn("[KillsLB] ✅ Board structure found. Names children:")
		for _, c in ipairs(namesFolder:GetChildren()) do warn("  - " .. c.Name) end
		warn("[KillsLB] ✅ Score children:")
		for _, c in ipairs(scoresFolder:GetChildren()) do warn("  - " .. c.Name) end
	end
	_boardDebugDone = true

	for i = 1, MAX_ENTRIES do
		local nameLabel  = namesFolder:FindFirstChild("Name"  .. i)
		local scoreLabel = scoresFolder:FindFirstChild("Score" .. i)
		if entries[i] then
			if nameLabel  then nameLabel.Text  = entries[i].Name      end
			if scoreLabel then scoreLabel.Text = entries[i].Formatted  end
		else
			if nameLabel  then nameLabel.Text  = "---" end
			if scoreLabel then scoreLabel.Text = "---" end
		end
	end
end

local function buildLeaderboard()
	local entries = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local value = 0
		if _G.getData then
			local ok, data = pcall(_G.getData, player)
			if ok and data then value = data[DATA_KEY] or 0 end
		end
		table.insert(entries, {
			Name      = player.Name,
			UserId    = player.UserId,
			Value     = value,
			Formatted = tostring(value),
		})
	end
	table.sort(entries, function(a, b) return a.Value > b.Value end)
	while #entries > MAX_ENTRIES do table.remove(entries) end
	return entries
end

local function broadcast()
	local entries = buildLeaderboard()
	if #entries == 0 then return end
	updateBoardLabels(entries)
	LeaderboardEvent:FireAllClients({ [BROADCAST_KEY] = entries })
end

task.wait(3)
local lastUpdate = 0
RunService.Heartbeat:Connect(function()
	if tick() - lastUpdate >= UPDATE_INTERVAL then
		lastUpdate = tick()
		pcall(broadcast)
	end
end)

print("✅ [KillsLeaderboard] Loaded")
