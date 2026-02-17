-- GameSpeed.client.luau
-- Buttons on bottom right to change game speed (for testing/development)
-- Controls ALL animations in the game (players + NPCs)
-- Also has attack selection buttons for End NPC testing

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local currentSpeed = 1
local selectedAttack = 0 -- 0 = random, 1-3 = attack 1-3, 4 = ULT

-- Wait for RemoteEvents
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
local forceAttackEvent = remoteEvents and remoteEvents:WaitForChild("ForceAttackEvent", 5)

-- Create GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GameSpeedGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- ===== ATTACK SELECTION (top row) =====
local attackContainer = Instance.new("Frame")
attackContainer.Name = "AttackButtons"
attackContainer.Size = UDim2.new(0, 220, 0, 40)
attackContainer.Position = UDim2.new(1, -230, 1, -100)
attackContainer.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
attackContainer.BackgroundTransparency = 0.3
attackContainer.BorderSizePixel = 0
attackContainer.Parent = screenGui

local attackCorner = Instance.new("UICorner")
attackCorner.CornerRadius = UDim.new(0, 8)
attackCorner.Parent = attackContainer

local attackLayout = Instance.new("UIListLayout")
attackLayout.FillDirection = Enum.FillDirection.Horizontal
attackLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
attackLayout.VerticalAlignment = Enum.VerticalAlignment.Center
attackLayout.Padding = UDim.new(0, 4)
attackLayout.Parent = attackContainer

-- Attack options: Random, A1, A2, A3, ULT
local attacks = {
	{id = 0, label = "RND"},
	{id = 1, label = "A1"},
	{id = 2, label = "A2"},
	{id = 3, label = "A3"},
	{id = 4, label = "ULT"},
}
local attackButtons = {}

local function setAttack(attackId)
	selectedAttack = attackId
	
	-- Update button colors
	for id, btn in pairs(attackButtons) do
		if id == attackId then
			btn.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			btn.BackgroundColor3 = Color3.fromRGB(80, 40, 40)
			btn.TextColor3 = Color3.fromRGB(200, 150, 150)
		end
	end
	
	-- Tell server which attack to force
	if forceAttackEvent then
		forceAttackEvent:FireServer(attackId)
		print("[GameSpeed] Force attack set to:", attackId == 0 and "RANDOM" or attackId)
	end
end

-- Create attack buttons
for _, attack in ipairs(attacks) do
	local btn = Instance.new("TextButton")
	btn.Name = "Attack" .. attack.id
	btn.Size = UDim2.new(0, 38, 0, 30)
	btn.BackgroundColor3 = attack.id == 0 and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(80, 40, 40)
	btn.TextColor3 = attack.id == 0 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 150, 150)
	btn.Text = attack.label
	btn.TextSize = 12
	btn.Font = Enum.Font.GothamBold
	btn.BorderSizePixel = 0
	btn.Parent = attackContainer
	
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = btn
	
	btn.MouseButton1Click:Connect(function()
		setAttack(attack.id)
	end)
	
	attackButtons[attack.id] = btn
end

-- ===== SPEED BUTTONS (bottom row) =====
-- Container frame (bottom right)
local container = Instance.new("Frame")
container.Name = "SpeedButtons"
container.Size = UDim2.new(0, 200, 0, 40)
container.Position = UDim2.new(1, -210, 1, -50)
container.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
container.BackgroundTransparency = 0.3
container.BorderSizePixel = 0
container.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = container

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Padding = UDim.new(0, 4)
layout.Parent = container

-- Speed options
local speeds = {0.5, 1, 2, 5, 10}
local buttons = {}

-- Function to adjust all animation tracks for a humanoid
local function adjustAllAnimations(humanoid, speed)
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if animator then
		for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
			track:AdjustSpeed(speed)
		end
	end
end

-- Function to set game speed for ALL characters
local function setGameSpeed(multiplier)
	currentSpeed = multiplier
	
	-- Update button colors
	for speed, btn in pairs(buttons) do
		if speed == multiplier then
			btn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
			btn.TextColor3 = Color3.fromRGB(200, 200, 200)
		end
	end
	
	-- Adjust ALL humanoids in workspace (players + NPCs)
	for _, descendant in ipairs(Workspace:GetDescendants()) do
		if descendant:IsA("Humanoid") then
			adjustAllAnimations(descendant, multiplier)
		end
	end
	
	print("[GameSpeed] Set to " .. multiplier .. "x (all characters)")
end

-- Create buttons
for _, speed in ipairs(speeds) do
	local btn = Instance.new("TextButton")
	btn.Name = "Speed" .. speed
	btn.Size = UDim2.new(0, 35, 0, 30)
	btn.BackgroundColor3 = speed == 1 and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(60, 60, 60)
	btn.TextColor3 = speed == 1 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
	btn.Text = speed .. "x"
	btn.TextSize = 14
	btn.Font = Enum.Font.GothamBold
	btn.BorderSizePixel = 0
	btn.Parent = container
	
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = btn
	
	btn.MouseButton1Click:Connect(function()
		setGameSpeed(speed)
	end)
	
	buttons[speed] = btn
end

-- Continuously apply speed to all playing animations
RunService.Heartbeat:Connect(function()
	if currentSpeed ~= 1 then
		for _, descendant in ipairs(Workspace:GetDescendants()) do
			if descendant:IsA("Humanoid") then
				local animator = descendant:FindFirstChildOfClass("Animator")
				if animator then
					for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
						-- Only adjust if not already at target speed
						if math.abs(track.Speed - currentSpeed) > 0.01 and track.Speed > 0 then
							track:AdjustSpeed(currentSpeed)
						end
					end
				end
			end
		end
	end
end)

print("[GameSpeed] GUI Ready! Controls ALL animations (players + NPCs)")
