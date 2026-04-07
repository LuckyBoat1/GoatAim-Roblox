-- TopKillsDisplay.client.luau
-- Populates the in-world TopKills SurfaceGui with Abyss kills leaderboard data
local MODEL_NAME = "TopKills"
local EVENT_NAME = "KillsLeaderboardEvent"
local UPDATE_EVENT_NAME = "UpdateTopKillsEvent"
local BROADCAST_KEY = "KillsScore"

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--warn("[TopKills] Script started")

-- Find RemoteEvent (timeout 15s so we can see if it's missing)
local LeaderboardEvent = ReplicatedStorage:WaitForChild(EVENT_NAME, 15)
if not LeaderboardEvent then
	warn("[TopKills] ❌ RemoteEvent '" .. EVENT_NAME .. "' not found after 15s — server script may have errored")
	return
end
--warn("[TopKills] ✅ RemoteEvent found")

-- Find board model inside Game > SpawnArena folder
local gameFolder = workspace:WaitForChild("Game", 15)
if not gameFolder then
	warn("[TopKills] ❌ workspace.Game not found after 15s")
	return
end
local spawnArena = gameFolder:WaitForChild("SpawnArena", 15)
if not spawnArena then
	warn("[TopKills] ❌ Game.SpawnArena not found after 15s")
	return
end
local boardModel = spawnArena:WaitForChild(MODEL_NAME, 15)
if not boardModel then
	warn("[TopKills] ❌ SpawnArena model '" .. MODEL_NAME .. "' not found — check Studio name")
	return
end
--warn("[TopKills] ✅ Board model found")

local scoreBlock = boardModel:WaitForChild("ScoreBlock", 10)
if not scoreBlock then warn("[TopKills] ❌ No ScoreBlock inside " .. MODEL_NAME); return end
local leaderboardGui = scoreBlock:WaitForChild("Leaderboard", 10)
if not leaderboardGui then warn("[TopKills] ❌ No Leaderboard SurfaceGui inside ScoreBlock"); return end

local namesFolder  = leaderboardGui:WaitForChild("Names",  10)
local scoresFolder = leaderboardGui:WaitForChild("Score",  10)
local photosFolder = leaderboardGui:WaitForChild("Photos", 10)

if not namesFolder  then warn("[TopKills] ❌ No Names folder");  return end
if not scoresFolder then warn("[TopKills] ❌ No Score folder");  return end
if not photosFolder then warn("[TopKills] ❌ No Photos folder"); return end
--warn("[TopKills] ✅ All GUI folders found — listening for events")

-- Thumbnail cache so we don't re-fetch every 2s
local thumbnailCache = {}

local function getThumbnail(userId)
	if thumbnailCache[userId] then
		return thumbnailCache[userId]
	end
	local success, thumbnail = pcall(function()
		return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
	end)
	if success then
		thumbnailCache[userId] = thumbnail
		return thumbnail
	end
	return "rbxassetid://0"
end

-- Clear GUI entries
local function clearEntries()
	for _, label in pairs(namesFolder:GetChildren()) do
		if label:IsA("TextLabel") then label.Text = "" end
	end
	for _, label in pairs(scoresFolder:GetChildren()) do
		if label:IsA("TextLabel") then label.Text = "" end
	end
	for _, img in pairs(photosFolder:GetChildren()) do
		if img:IsA("ImageLabel") then img.Image = "" end
	end
end

-- Update the SurfaceGui with leaderboard data
local function updateDisplay(leaderboardData)
	clearEntries()

	for i, entry in ipairs(leaderboardData) do
		local nameLabel = namesFolder:FindFirstChild("Name" .. i)
		local scoreLabel = scoresFolder:FindFirstChild("Score" .. i)
		local photoLabel = photosFolder:FindFirstChild("Photo" .. i)

		if nameLabel then nameLabel.Text = entry.Name end
		if scoreLabel then scoreLabel.Text = entry.Formatted or tostring(entry.Value) end
		if photoLabel then photoLabel.Image = getThumbnail(entry.UserId) end
	end
end

-- Listen for updates from server
LeaderboardEvent.OnClientEvent:Connect(function(data)
	--warn("[TopKills] OnClientEvent fired, data keys:")
	--if data then
	--	for k, v in pairs(data) do warn("  key='" .. tostring(k) .. "' count=" .. tostring(type(v) == "table" and #v or v)) end
	--else
	--	warn("  data is nil")
	--end
	local entries = data and data[BROADCAST_KEY]
	if not entries or #entries == 0 then return end
	--warn("[TopKills] Updating display with " .. #entries .. " entries")

	-- Tell server who the #1 player is (for the avatar rig)
	local topEvent = ReplicatedStorage:FindFirstChild(UPDATE_EVENT_NAME)
	if topEvent then
		topEvent:FireServer(entries[1].UserId)
	end

	updateDisplay(entries)
end)
