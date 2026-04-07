-- _KillsWL_Leaderboards.server.lua
-- All-time Top Kills + Top W/L leaderboards.
-- Reads LB_KillsScore / LB_WinsScore OrderedDataStores (same as Playtime does).
-- Merges DataStore data with live online player data every 2s.

warn("[KillsWL] *** COMBINED LEADERBOARD SCRIPT STARTED ***")

local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local DataStoreService   = game:GetService("DataStoreService")
local Players            = game:GetService("Players")

local MAX_ENTRIES        = 10
local DS_REFRESH_INTERVAL = 60   -- seconds between DataStore reads
local BROADCAST_INTERVAL  = 2    -- seconds between client broadcasts

--------------------------------------------------------------------------
-- REMOTE EVENTS
--------------------------------------------------------------------------
local function getOrCreate(name)
	local e = ReplicatedStorage:FindFirstChild(name)
	if not e then
		e = Instance.new("RemoteEvent")
		e.Name   = name
		e.Parent = ReplicatedStorage
	end
	return e
end

local KillsEvent    = getOrCreate("KillsLeaderboardEvent")
local KillsAvatarEv = getOrCreate("UpdateTopKillsEvent")
local WLEvent       = getOrCreate("WLLeaderboardEvent")
local WLAvatarEv    = getOrCreate("UpdateTopWLEvent")

warn("[KillsWL] ✅ Remote events ready")

--------------------------------------------------------------------------
-- DATA STORES
--------------------------------------------------------------------------
local LB_KillsScore = DataStoreService:GetOrderedDataStore("LB_KillsScore")
local LB_WinsScore  = DataStoreService:GetOrderedDataStore("LB_WinsScore")

--------------------------------------------------------------------------
-- NAME CACHE
--------------------------------------------------------------------------
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
-- CACHED MAPS (userId -> value from DataStore)
--------------------------------------------------------------------------
local cachedKills = {}  -- userId -> kills
local cachedWins  = {}  -- userId -> wins

local function refreshDS(label, store, cache)
	local ok, pages = pcall(function()
		return store:GetSortedAsync(false, MAX_ENTRIES)
	end)
	if not ok then
		warn("[KillsWL] ❌ DataStore read FAILED for " .. label .. ": " .. tostring(pages))
		warn("[KillsWL] ⚠️  Make sure 'Enable Studio Access to API Services' is ON in Game Settings → Security")
		return
	end
	if not pages then
		warn("[KillsWL] ❌ DataStore returned nil pages for " .. label)
		return
	end
	local ok2, page = pcall(function() return pages:GetCurrentPage() end)
	if not ok2 or not page then
		warn("[KillsWL] ❌ GetCurrentPage failed for " .. label .. ": " .. tostring(page))
		return
	end
	local fresh = {}
	for _, item in ipairs(page) do
		local uid = tonumber(item.key)
		if uid then fresh[uid] = item.value or 0 end
	end
	local count = 0
	for _ in pairs(fresh) do count += 1 end
	warn("[KillsWL] 📊 " .. label .. " DataStore loaded " .. count .. " entries")
	-- Copy into cache
	for k in pairs(cache) do cache[k] = nil end
	for k, v in pairs(fresh) do cache[k] = v end
	-- Pre-resolve names
	task.spawn(function()
		for uid in pairs(fresh) do
			if not nameCache[uid] then
				local plr = Players:GetPlayerByUserId(uid)
				if plr then
					nameCache[uid] = plr.Name
				else
					local ok3, n = pcall(function() return Players:GetNameFromUserIdAsync(uid) end)
					if ok3 and n then nameCache[uid] = n end
				end
			end
		end
	end)
end

local function refreshAll()
	refreshDS("LB_KillsScore", LB_KillsScore, cachedKills)
	refreshDS("LB_WinsScore",  LB_WinsScore,  cachedWins)
end

--------------------------------------------------------------------------
-- BOARD LABEL WRITER
--------------------------------------------------------------------------
local function writeBoard(boardName, entries)
	local gameFolder = workspace:FindFirstChild("Game")
	if not gameFolder then return end
	local spawnArena = gameFolder:FindFirstChild("SpawnArena")
	if not spawnArena then return end
	local boardModel = spawnArena:FindFirstChild(boardName)
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

--------------------------------------------------------------------------
-- BUILD FUNCTIONS (merge DataStore + live online players)
--------------------------------------------------------------------------
local function buildKills()
	-- Start with cached DataStore top-10
	local merged = {}
	for uid, v in pairs(cachedKills) do merged[uid] = v end

	local dsCount = 0
	for _ in pairs(merged) do dsCount += 1 end
	if dsCount == 0 then
		warn("[KillsWL] ⚠️  cachedKills is EMPTY — DataStore may not have data yet or API access is off")
	end

	-- Override/update with live online values (always include online players, even with 0)
	for _, player in ipairs(Players:GetPlayers()) do
		local live = 0
		if _G.getData then
			local ok, data = pcall(_G.getData, player)
			if ok and data then live = data["battles"] or 0 end
		end
		if merged[player.UserId] == nil or live > merged[player.UserId] then
			merged[player.UserId] = live
		end
	end

	local entries = {}
	for uid, value in pairs(merged) do
		table.insert(entries, {
			Name      = getName(uid),
			UserId    = uid,
			Value     = value,
			Formatted = tostring(value),
		})
	end
	table.sort(entries, function(a, b) return a.Value > b.Value end)
	while #entries > MAX_ENTRIES do table.remove(entries) end
	return entries
end

local function buildWL()
	-- Start with cached DataStore top-10 (sorted by wins)
	local merged = {}
	for uid, v in pairs(cachedWins) do merged[uid] = v end

	local dsCount = 0
	for _ in pairs(merged) do dsCount += 1 end
	if dsCount == 0 then
		warn("[KillsWL] ⚠️  cachedWins is EMPTY — DataStore may not have data yet or API access is off")
	end

	-- Override/update with live online values (always include online players, even with 0 wins)
	for _, player in ipairs(Players:GetPlayers()) do
		local liveWins = 0
		if _G.getData then
			local ok, data = pcall(_G.getData, player)
			if ok and data then liveWins = data["wins"] or 0 end
		end
		if merged[player.UserId] == nil or liveWins > merged[player.UserId] then
			merged[player.UserId] = liveWins
		end
	end

	-- Build entries; for online players we can show losses too
	local liveData = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if _G.getData then
			local ok, data = pcall(_G.getData, player)
			if ok and data then
				liveData[player.UserId] = data
			end
		end
	end

	local entries = {}
	for uid, wins in pairs(merged) do
		local formatted
		local ld = liveData[uid]
		if ld then
			local losses = ld["losses"] or 0
			formatted = wins .. " / " .. losses
		else
			formatted = tostring(wins)
		end
		table.insert(entries, {
			Name      = getName(uid),
			UserId    = uid,
			Value     = wins,
			Formatted = formatted,
		})
	end
	table.sort(entries, function(a, b) return a.Value > b.Value end)
	while #entries > MAX_ENTRIES do table.remove(entries) end
	return entries
end

--------------------------------------------------------------------------
-- BROADCAST
--------------------------------------------------------------------------
local function broadcastKills()
	local entries = buildKills()
	if #entries == 0 then return end
	writeBoard("TopKills", entries)
	KillsEvent:FireAllClients({ KillsScore = entries })
end

local function broadcastWL()
	local entries = buildWL()
	if #entries == 0 then return end
	writeBoard("TopWL", entries)
	WLEvent:FireAllClients({ WLScore = entries })
end

--------------------------------------------------------------------------
-- STARTUP + LOOPS
--------------------------------------------------------------------------
task.wait(5)
refreshAll()
pcall(broadcastKills)
pcall(broadcastWL)

-- Slow loop: refresh DataStore
task.spawn(function()
	while true do
		task.wait(DS_REFRESH_INTERVAL)
		refreshAll()
	end
end)

-- Fast loop: re-broadcast with live player updates
task.spawn(function()
	while true do
		task.wait(BROADCAST_INTERVAL)
		pcall(broadcastKills)
		pcall(broadcastWL)
	end
end)

-- Re-broadcast when players join/leave
Players.PlayerAdded:Connect(function()
	task.wait(3)
	pcall(broadcastKills)
	pcall(broadcastWL)
end)
Players.PlayerRemoving:Connect(function()
	task.wait(1)
	pcall(broadcastKills)
	pcall(broadcastWL)
end)

warn("[KillsWL] ✅ All-time leaderboards active — DataStore + live online players")
