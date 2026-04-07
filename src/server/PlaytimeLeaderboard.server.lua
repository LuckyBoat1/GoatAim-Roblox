-- PlaytimeLeaderboard.server.lua
-- Shows all-time top 10 from OrderedDataStore, always merged with live online player data.
-- Cached every 60s from DataStore; live session time applied every 2s for online players.

local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local DataStoreService   = game:GetService("DataStoreService")
local Players            = game:GetService("Players")

--------------------------------------------------------------------------
-- REMOTE EVENTS
--------------------------------------------------------------------------
local PlaytimeLeaderboardEvent = ReplicatedStorage:FindFirstChild("PlaytimeLeaderboardEvent")
if not PlaytimeLeaderboardEvent then
	PlaytimeLeaderboardEvent = Instance.new("RemoteEvent")
	PlaytimeLeaderboardEvent.Name = "PlaytimeLeaderboardEvent"
	PlaytimeLeaderboardEvent.Parent = ReplicatedStorage
end

local UpdateTopPlayTimeEvent = ReplicatedStorage:FindFirstChild("UpdateTopPlayTimeEvent")
if not UpdateTopPlayTimeEvent then
	UpdateTopPlayTimeEvent = Instance.new("RemoteEvent")
	UpdateTopPlayTimeEvent.Name = "UpdateTopPlayTimeEvent"
	UpdateTopPlayTimeEvent.Parent = ReplicatedStorage
end

--------------------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------------------
local DS_REFRESH_INTERVAL = 60  -- seconds between DataStore reads
local BROADCAST_INTERVAL  = 2   -- seconds between client broadcasts
local MAX_ENTRIES         = 10

local LB_PlaytimeScore = DataStoreService:GetOrderedDataStore("LB_PlaytimeScore")

--------------------------------------------------------------------------
-- SESSION TRACKING
--------------------------------------------------------------------------
local joinTimes: { [number]: number } = {}

for _, plr in ipairs(Players:GetPlayers()) do
	joinTimes[plr.UserId] = tick()
end
Players.PlayerAdded:Connect(function(plr)
	joinTimes[plr.UserId] = tick()
end)
Players.PlayerRemoving:Connect(function(plr)
	joinTimes[plr.UserId] = nil
end)

--------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------
local function formatTime(totalSeconds: number): string
	totalSeconds = math.floor(totalSeconds)
	local hours   = math.floor(totalSeconds / 3600)
	local minutes = math.floor((totalSeconds % 3600) / 60)
	local seconds = totalSeconds % 60
	if hours > 0 then
		return string.format("%dh %02dm %02ds", hours, minutes, seconds)
	elseif minutes > 0 then
		return string.format("%dm %02ds", minutes, seconds)
	else
		return string.format("%ds", seconds)
	end
end

local nameCache = {}
local function getName(userId)
	if nameCache[userId] then return nameCache[userId] end
	local plr = Players:GetPlayerByUserId(userId)
	if plr then nameCache[userId] = plr.Name; return plr.Name end
	local ok, name = pcall(function() return Players:GetNameFromUserIdAsync(userId) end)
	local result = (ok and name) or ("User_" .. userId)
	nameCache[userId] = result
	return result
end

--------------------------------------------------------------------------
-- CACHED BASE MAP: userId -> savedPlaytime (from DataStore)
--------------------------------------------------------------------------
local cachedMap: { [number]: number } = {} -- userId -> saved seconds

local function refreshFromDataStore()
	local ok, pages = pcall(function()
		return LB_PlaytimeScore:GetSortedAsync(false, MAX_ENTRIES)
	end)
	if not ok or not pages then
		warn("[PlaytimeLeaderboard] DataStore read failed")
		return
	end
	local ok2, page = pcall(function() return pages:GetCurrentPage() end)
	if not ok2 or not page then return end

	local fresh = {}
	for _, item in ipairs(page) do
		local uid = tonumber(item.key)
		if uid then fresh[uid] = item.value or 0 end
	end
	cachedMap = fresh
	-- Pre-resolve names in background
	task.spawn(function()
		for uid in pairs(fresh) do
			if not nameCache[uid] then
				local plr = Players:GetPlayerByUserId(uid)
				if plr then
					nameCache[uid] = plr.Name
				else
					local ok, name = pcall(function() return Players:GetNameFromUserIdAsync(uid) end)
					if ok and name then nameCache[uid] = name end
				end
			end
		end
	end)
end

--------------------------------------------------------------------------
-- Direct board label updater (server-side so replication beats the model's internal script)
local function updateBoardLabels(entries)
	local gameFolder = workspace:FindFirstChild("Game")
	if not gameFolder then return end
	local spawnArena = gameFolder:FindFirstChild("SpawnArena")
	if not spawnArena then return end
	local boardModel = spawnArena:FindFirstChild("Leaderboard2")
	if not boardModel then return end
	local scoreBlock = boardModel:FindFirstChild("ScoreBlock")
	if not scoreBlock then return end
	local gui = scoreBlock:FindFirstChild("Leaderboard")
	if not gui then return end
	local namesFolder  = gui:FindFirstChild("Names")
	local scoresFolder = gui:FindFirstChild("Score")
	if not namesFolder or not scoresFolder then return end

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

-- BUILD & BROADCAST
--------------------------------------------------------------------------
local function broadcast()
	-- Start with cached DataStore data
	local merged: { [number]: number } = {}
	for uid, saved in pairs(cachedMap) do
		merged[uid] = saved
	end

	-- Merge in live online players (saved totalPlaytime + current session)
	for _, player in ipairs(Players:GetPlayers()) do
		local saved = 0
		if _G.getData then
			local ok, data = pcall(_G.getData, player)
			if ok and data then saved = data.totalPlaytime or 0 end
		end
		local sessionStart = joinTimes[player.UserId]
		local live = sessionStart and math.floor(tick() - sessionStart) or 0
		local total = saved + live
		-- Take the higher of DataStore or live value
		if total > (merged[player.UserId] or 0) then
			merged[player.UserId] = total
		end
	end

	-- Build sorted entries
	local entries = {}
	for uid, total in pairs(merged) do
		table.insert(entries, {
			Name      = getName(uid),
			UserId    = uid,
			Value     = total,
			Formatted = formatTime(total),
		})
	end
	table.sort(entries, function(a, b) return a.Value > b.Value end)
	while #entries > MAX_ENTRIES do table.remove(entries) end

	if #entries == 0 then return end
	updateBoardLabels(entries)
	PlaytimeLeaderboardEvent:FireAllClients({ PlaytimeScore = entries })
end

--------------------------------------------------------------------------
-- MAIN LOOPS
--------------------------------------------------------------------------
task.wait(5)

-- ONE-TIME: Dump board structure so we know exact label names
task.spawn(function()
	task.wait(2) -- let workspace fully load
	local gameFolder = workspace:FindFirstChild("Game")
	if not gameFolder then warn("[PlaytimeLB] ❌ workspace.Game not found"); return end
	local spawnArena = gameFolder:FindFirstChild("SpawnArena")
	if not spawnArena then
		warn("[PlaytimeLB] ❌ Game.SpawnArena not found. Game children:")
		for _, c in ipairs(gameFolder:GetChildren()) do warn("  > " .. c.Name) end
		return
	end
	local boardModel = spawnArena:FindFirstChild("Leaderboard2")
	if not boardModel then
		warn("[PlaytimeLB] ❌ SpawnArena.Leaderboard2 not found. SpawnArena children:")
		for _, c in ipairs(spawnArena:GetChildren()) do
			warn("  > " .. c.Name .. " [" .. c.ClassName .. "]")
		end
		return
	end
	warn("[PlaytimeLB] ✅ Found Leaderboard2. ALL descendants:")
	for _, d in ipairs(boardModel:GetDescendants()) do
		warn("  " .. d.ClassName .. " '" .. d.Name .. "' parent='" .. d.Parent.Name .. "'")
	end
end)

pcall(refreshFromDataStore)
pcall(broadcast)

-- Slow loop: re-read DataStore
task.spawn(function()
	while true do
		task.wait(DS_REFRESH_INTERVAL)
		pcall(refreshFromDataStore)
	end
end)

-- Fast loop: re-broadcast with updated live times
task.spawn(function()
	while true do
		task.wait(BROADCAST_INTERVAL)
		pcall(broadcast)
	end
end)

-- Update when players join/leave
Players.PlayerAdded:Connect(function()
	task.wait(3)
	pcall(broadcast)
end)
Players.PlayerRemoving:Connect(function()
	task.wait(1)
	pcall(broadcast)
end)

warn("[PlaytimeLeaderboard] ✅ Active — all-time DataStore + live online players")
