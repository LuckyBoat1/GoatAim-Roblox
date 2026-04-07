-- TopPlayTimeDisplay.client.luau
-- Populates the in-world Leaderboard2 SurfaceGui with playtime leaderboard data

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--warn("[TopPlayTime] Script started")

local PlaytimeLeaderboardEvent = ReplicatedStorage:WaitForChild("PlaytimeLeaderboardEvent", 15)
if not PlaytimeLeaderboardEvent then
	warn("[TopPlayTime] ❌ PlaytimeLeaderboardEvent not found after 15s")
	return
end
--warn("[TopPlayTime] ✅ RemoteEvent found")

local gameFolder = workspace:WaitForChild("Game", 15)
if not gameFolder then
	warn("[TopPlayTime] ❌ workspace.Game not found after 15s")
	return
end
local spawnArena = gameFolder:WaitForChild("SpawnArena", 15)
if not spawnArena then
	warn("[TopPlayTime] ❌ Game.SpawnArena not found after 15s")
	return
end
local boardModel = spawnArena:WaitForChild("Leaderboard2", 15)
if not boardModel then
	warn("[TopPlayTime] ❌ SpawnArena.Leaderboard2 not found — check Studio name")
	return
end
--warn("[TopPlayTime] ✅ Board model found")

local scoreBlock = boardModel:WaitForChild("ScoreBlock", 10)
if not scoreBlock then warn("[TopPlayTime] ❌ No ScoreBlock"); return end
local leaderboardGui = scoreBlock:WaitForChild("Leaderboard", 10)
if not leaderboardGui then warn("[TopPlayTime] ❌ No Leaderboard SurfaceGui"); return end

local namesFolder  = leaderboardGui:WaitForChild("Names",  10)
local scoresFolder = leaderboardGui:WaitForChild("Score",  10)
local photosFolder = leaderboardGui:WaitForChild("Photos", 10)

if not namesFolder  then warn("[TopPlayTime] ❌ No Names folder");  return end
if not scoresFolder then warn("[TopPlayTime] ❌ No Score folder");  return end
if not photosFolder then warn("[TopPlayTime] ❌ No Photos folder"); return end
--warn("[TopPlayTime] ✅ All GUI folders found — listening for events")

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
PlaytimeLeaderboardEvent.OnClientEvent:Connect(function(data)
	--warn("[TopPlayTime] OnClientEvent fired")
	local playtimeData = data and data.PlaytimeScore
	if not playtimeData or #playtimeData == 0 then
		return
	end
	--warn("[TopPlayTime] Updating display with " .. #playtimeData .. " entries")

	local topEvent = ReplicatedStorage:FindFirstChild("UpdateTopPlayTimeEvent")
	if topEvent then
		topEvent:FireServer(playtimeData[1].UserId)
	end

	updateDisplay(playtimeData)
end)
