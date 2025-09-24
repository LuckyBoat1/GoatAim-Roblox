local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local leaderboard = game:GetService("Workspace"):WaitForChild("Leaderboard"):WaitForChild("ScoreBlock")
local leaderboardGui = leaderboard:WaitForChild("Leaderboard")

local cloneGui = leaderboardGui:Clone()
cloneGui.Parent = playerGui
cloneGui.Enabled = false