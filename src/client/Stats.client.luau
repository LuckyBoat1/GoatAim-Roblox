local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LeaderboardUpdateEvent = ReplicatedStorage:WaitForChild("LeaderboardUpdateEvent")
local UpdateTopPlayerEvent = ReplicatedStorage:WaitForChild("UpdateTopPlayerEvent")

-- GUI references
local leaderboardGui = workspace:WaitForChild("Leaderboard"):WaitForChild("ScoreBlock"):WaitForChild("Leaderboard")
local namesFolder = leaderboardGui:WaitForChild("Names")
local scoresFolder = leaderboardGui:WaitForChild("Score")
local photosFolder = leaderboardGui:WaitForChild("Photos")

-- Clear GUI entries
local function clearEntities()
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

-- Update GUI
local function createUi(leaderboardData)
	clearEntities()
	for i, entry in ipairs(leaderboardData) do
		local nameLabel = namesFolder:FindFirstChild("Name"..i)
		local scoreLabel = scoresFolder:FindFirstChild("Score"..i)
		local photoLabel = photosFolder:FindFirstChild("Photo"..i)

		if nameLabel then nameLabel.Text = entry.Name end
		if scoreLabel then scoreLabel.Text = tostring(entry.Value) end
		if photoLabel then
			local success, thumbnail = pcall(function()
				return Players:GetUserThumbnailAsync(entry.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
			end)
			if success then
				photoLabel.Image = thumbnail
			else
				photoLabel.Image = "rbxassetid://0"
			end
		end
	end
end

-- When leaderboard updates
LeaderboardUpdateEvent.OnClientEvent:Connect(function(allLeaderboards)
	local leaderboardData = allLeaderboards["ClassicScore"]
	if not leaderboardData or #leaderboardData == 0 then return end

	-- Tell server who the top player is
	UpdateTopPlayerEvent:FireServer(leaderboardData[1].UserId)

	-- Update GUI
	createUi(leaderboardData)
end)
