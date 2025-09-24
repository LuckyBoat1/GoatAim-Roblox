local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local scoreUpdate = ReplicatedStorage:WaitForChild("ScoreUpdate")
local startRunEvent = ReplicatedStorage:WaitForChild("StartRun")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ScoreGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui
screenGui.Enabled = false

local scoreLabel = Instance.new("TextLabel")
scoreLabel.Name = "ScoreLabel"
scoreLabel.Size = UDim2.new(0.4, 0, 0.12, 0)
scoreLabel.Position = UDim2.new(0.3, 0, 0.02, 0)
scoreLabel.Font = Enum.Font.FredokaOne
scoreLabel.BackgroundTransparency = 1
scoreLabel.TextScaled = true
scoreLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
scoreLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
scoreLabel.TextStrokeTransparency = 0.5
scoreLabel.ZIndex = 5
scoreLabel.Text = ""
scoreLabel.Visible = true
scoreLabel.Parent = screenGui

local streakLabel = Instance.new("TextLabel")
streakLabel.Name = "StreakLabel"
streakLabel.Size = UDim2.new(0.2, 0, 0.08, 0)
streakLabel.Position = UDim2.new(0.78, 0, 0.02, 0)
streakLabel.Font = Enum.Font.FredokaOne
streakLabel.BackgroundTransparency = 1
streakLabel.TextScaled = true
streakLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
streakLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
streakLabel.TextStrokeTransparency = 0.5
streakLabel.ZIndex = 5
streakLabel.Text = ""
streakLabel.Visible = true
streakLabel.Parent = screenGui

local ammoLabel = Instance.new("TextLabel")
ammoLabel.Name = "AmmoLabel"
ammoLabel.Size = UDim2.new(0.2, 0, 0.08, 0)
ammoLabel.Position = UDim2.new(0.02, 0, 0.02, 0) -- top-left corner with some padding
ammoLabel.Font = Enum.Font.FredokaOne
ammoLabel.BackgroundTransparency = 1
ammoLabel.TextScaled = true
ammoLabel.TextColor3 = Color3.fromRGB(255, 0, 0) -- red color
ammoLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
ammoLabel.TextStrokeTransparency = 0.5
ammoLabel.ZIndex = 5
ammoLabel.Text = ""
ammoLabel.Visible = false
ammoLabel.Parent = screenGui

startRunEvent.OnClientEvent:Connect(function(mode, ammo)
	screenGui.Enabled = true
	scoreLabel.Text = "Score: 0"
	
	if mode == "bullseye" then
		streakLabel.Visible = false
		ammoLabel.Visible = true
		ammoLabel.Text = "Ammo: " ..ammo
			
		
	else 
		streakLabel.Visible = true
		streakLabel.Text = "Streak: 0"
	end
	
end)
scoreUpdate.OnClientEvent:Connect(function(score, streak, ammo)
	if score == "end" then
		screenGui.Enabled = false
		return
	end
	scoreLabel.Text = "Score: " .. score
	if streakLabel.Visible then
		streakLabel.Text = "Streak: " .. streak
	end
	if ammoLabel.Visible then
		ammoLabel.Text = "Ammo: " ..ammo
	end
	
end)
