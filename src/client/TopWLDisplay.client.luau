-- TopWLDisplay.client.luau
-- Populates the in-world TopWL SurfaceGui with W/L leaderboard data
-- ========================================================
-- ✏️ EASY EDIT: Change these to point to a different model / event
-- ========================================================
local MODEL_NAME = "TopWL"                           -- Workspace model name
local EVENT_NAME = "WLLeaderboardEvent"              -- Must match the server script
local UPDATE_EVENT_NAME = "UpdateTopWLEvent"         -- Must match the server script
local BROADCAST_KEY = "WLScore"                      -- Must match the server script
-- ========================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

warn("[TopWL] Script started")

local LeaderboardEvent = ReplicatedStorage:WaitForChild(EVENT_NAME, 15)
if not LeaderboardEvent then warn("[TopWL] ❌ WLLeaderboardEvent not found after 15s"); return end
warn("[TopWL] ✅ RemoteEvent found")

local gameFolder = workspace:WaitForChild("Game", 15)
if not gameFolder then warn("[TopWL] ❌ workspace.Game not found"); return end
local spawnArena = gameFolder:WaitForChild("SpawnArena", 15)
if not spawnArena then warn("[TopWL] ❌ Game.SpawnArena not found"); return end
local boardModel = spawnArena:WaitForChild(MODEL_NAME, 15)
if not boardModel then warn("[TopWL] ❌ SpawnArena." .. MODEL_NAME .. " not found"); return end
warn("[TopWL] ✅ Board model found")

local leaderboardGui = boardModel:WaitForChild("ScoreBlock", 10):WaitForChild("Leaderboard", 10)
local namesFolder = leaderboardGui:WaitForChild("Names")
local scoresFolder = leaderboardGui:WaitForChild("Score")
local photosFolder = leaderboardGui:WaitForChild("Photos")
warn("[TopWL] ✅ All GUI folders found")

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
	local entries = data and data[BROADCAST_KEY]
	if not entries or #entries == 0 then return end

	-- Tell server who the #1 player is (for the avatar rig)
	local topEvent = ReplicatedStorage:FindFirstChild(UPDATE_EVENT_NAME)
	if topEvent then
		topEvent:FireServer(entries[1].UserId)
	end

	updateDisplay(entries)
end)
