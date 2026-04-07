-- AccuracyLeaderboard.server.lua
-- Shows all-time top 10 from OrderedDataStore, always merged with live online player data.
-- PlayerDataManager writes to the ordered stores on every save (join, 30s autosave, leave).

local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local DataStoreService   = game:GetService("DataStoreService")
local Players            = game:GetService("Players")

local LeaderboardUpdateEvent = Instance.new("RemoteEvent")
LeaderboardUpdateEvent.Name   = "LeaderboardUpdateEvent"
LeaderboardUpdateEvent.Parent = ReplicatedStorage

-- Same OrderedDataStore names that PlayerDataManager writes to
local LB_ClassicScore  = DataStoreService:GetOrderedDataStore("LB_ClassicScore")
local LB_BullseyeScore = DataStoreService:GetOrderedDataStore("LB_BullseyeScore")

local MAX_ENTRIES     = 10
local UPDATE_INTERVAL = 60 -- seconds; respect DataStore rate limits

-- Fetch top entries from an OrderedDataStore → { [userId] = value }
local function fetchFromStore(store)
	local map = {}
	local ok, pages = pcall(function()
		return store:GetSortedAsync(false, MAX_ENTRIES)
	end)
	if not ok or not pages then return map end
	local ok2, page = pcall(function() return pages:GetCurrentPage() end)
	if not ok2 or not page then return map end
	for _, item in ipairs(page) do
		local uid = tonumber(item.key)
		if uid then map[uid] = item.value or 0 end
	end
	return map
end

-- Merge live online player stats into a userId->value map
local function mergeLivePlayers(map, statKey)
	for _, player in ipairs(Players:GetPlayers()) do
		if _G.getData then
			local ok, data = pcall(_G.getData, player)
			if ok and data then
				local v = data[statKey] or 0
				-- Take the higher of stored vs live (live is most current)
				if v > (map[player.UserId] or 0) then
					map[player.UserId] = v
				end
			end
		end
	end
	return map
end

-- Resolve display names (cache to avoid repeated async calls)
local nameCache = {}
local function getName(userId)
	if nameCache[userId] then return nameCache[userId] end
	-- Check if they're online first (free, synchronous)
	local plr = Players:GetPlayerByUserId(userId)
	if plr then nameCache[userId] = plr.Name; return plr.Name end
	-- Async lookup for offline players
	local ok, name = pcall(function() return Players:GetNameFromUserIdAsync(userId) end)
	local result = (ok and name) or ("User_" .. userId)
	nameCache[userId] = result
	return result
end

-- Build a sorted top-10 entry list from a userId->value map
local function buildEntries(map)
	local entries = {}
	for userId, value in pairs(map) do
		table.insert(entries, {
			Name   = getName(userId),
			UserId = userId,
			Value  = value,
		})
	end
	table.sort(entries, function(a, b) return a.Value > b.Value end)
	while #entries > MAX_ENTRIES do table.remove(entries) end
	return entries
end

local function updateAllLeaderboards()
	-- Fetch all-time data then layer live online players on top
	local classicMap  = fetchFromStore(LB_ClassicScore)
	local bullseyeMap = fetchFromStore(LB_BullseyeScore)

	classicMap  = mergeLivePlayers(classicMap,  "runHits")
	bullseyeMap = mergeLivePlayers(bullseyeMap, "bullseyeHigh")

	LeaderboardUpdateEvent:FireAllClients({
		ClassicScore = buildEntries(classicMap),
		BullsyeScore = buildEntries(bullseyeMap),
	})
end

-- Initial delay so PlayerDataManager and DataStores are ready
task.wait(5)
pcall(updateAllLeaderboards)

-- Periodic refresh
task.spawn(function()
	while true do
		task.wait(UPDATE_INTERVAL)
		pcall(updateAllLeaderboards)
	end
end)

-- Also re-broadcast whenever a player joins/leaves so the board updates immediately
Players.PlayerAdded:Connect(function()
	task.wait(3) -- let their data load first
	pcall(updateAllLeaderboards)
end)
Players.PlayerRemoving:Connect(function()
	task.wait(1)
	pcall(updateAllLeaderboards)
end)

warn("[AccuracyLeaderboard] ✅ Active — all-time DataStore + live online players")
