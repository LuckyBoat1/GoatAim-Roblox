-- ArcadePvpBuffUI.client.luau
-- Shows an active buff frame on the player's screen when they pick up
-- a buff orb in Arcade PvP.  A UIStroke around the frame acts as a
-- radial-style timer that fades/shrinks as the buff expires.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ArcadeBuffEvent = ReplicatedStorage:WaitForChild("ArcadeBuffEvent")

--------------------------------------------------------------------------
-- BUFF DISPLAY FRAME (created once, reused)
--------------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ArcadeBuffUI"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 10
screenGui.Parent = playerGui

-- Main container (bottom-center area, above hotbar)
local container = Instance.new("Frame")
container.Name = "BuffContainer"
container.Size = UDim2.new(0, 120, 0, 120)
container.Position = UDim2.new(0.5, -60, 0, 20) -- top center
container.AnchorPoint = Vector2.new(0, 0)
container.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
container.BackgroundTransparency = 0.3
container.BorderSizePixel = 0
container.Visible = false
container.Parent = screenGui

local containerCorner = Instance.new("UICorner")
containerCorner.CornerRadius = UDim.new(0, 16)
containerCorner.Parent = container

-- Stroke that acts as the timer — its transparency increases as time runs out
local timerStroke = Instance.new("UIStroke")
timerStroke.Name = "TimerStroke"
timerStroke.Color = Color3.fromRGB(255, 255, 255)
timerStroke.Thickness = 4
timerStroke.Transparency = 0
timerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
timerStroke.Parent = container

-- Icon label (emoji)
local iconLabel = Instance.new("TextLabel")
iconLabel.Name = "Icon"
iconLabel.Size = UDim2.new(1, 0, 0.55, 0)
iconLabel.Position = UDim2.new(0, 0, 0, 0)
iconLabel.BackgroundTransparency = 1
iconLabel.Text = ""
iconLabel.TextScaled = true
iconLabel.Font = Enum.Font.GothamBold
iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
iconLabel.Parent = container

-- Buff name label
local nameLabel = Instance.new("TextLabel")
nameLabel.Name = "BuffName"
nameLabel.Size = UDim2.new(1, -8, 0, 0.2)
nameLabel.Position = UDim2.new(0, 4, 0.55, 0)
nameLabel.BackgroundTransparency = 1
nameLabel.Text = ""
nameLabel.TextScaled = true
nameLabel.Font = Enum.Font.GothamBold
nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
nameLabel.Parent = container

-- Timer text
local timerLabel = Instance.new("TextLabel")
timerLabel.Name = "Timer"
timerLabel.Size = UDim2.new(1, 0, 0.2, 0)
timerLabel.Position = UDim2.new(0, 0, 0.78, 0)
timerLabel.BackgroundTransparency = 1
timerLabel.Text = ""
timerLabel.TextScaled = true
timerLabel.Font = Enum.Font.GothamBold
timerLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
timerLabel.Parent = container

--------------------------------------------------------------------------
-- STATE
--------------------------------------------------------------------------
local activeBuff: {
	Name: string,
	Icon: string,
	Duration: number,
	StartTick: number,
	Color: Color3,
}? = nil

local timerConnection: RBXScriptConnection? = nil

--------------------------------------------------------------------------
-- SHOW / HIDE
--------------------------------------------------------------------------
local function showBuff(info)
	-- info = { Name, Icon, Duration, Color = {R, G, B} }
	local buffColor = Color3.new(info.Color[1], info.Color[2], info.Color[3])

	activeBuff = {
		Name = info.Name,
		Icon = info.Icon,
		Duration = info.Duration,
		StartTick = tick(),
		Color = buffColor,
	}

	-- Set visuals
	iconLabel.Text = info.Icon
	nameLabel.Text = info.Name
	nameLabel.TextColor3 = buffColor
	timerStroke.Color = buffColor
	timerStroke.Thickness = 4
	timerStroke.Transparency = 0
	container.Visible = true

	-- Disconnect old timer if any
	if timerConnection then timerConnection:Disconnect() end

	-- Animate stroke as timer
	timerConnection = RunService.Heartbeat:Connect(function()
		if not activeBuff then
			container.Visible = false
			if timerConnection then timerConnection:Disconnect(); timerConnection = nil end
			return
		end

		local elapsed = tick() - activeBuff.StartTick
		local remaining = math.max(0, activeBuff.Duration - elapsed)
		local fraction = remaining / activeBuff.Duration -- 1 = full, 0 = done

		-- Timer text
		timerLabel.Text = string.format("%.1fs", remaining)

		-- Stroke fades out as time depletes (transparency goes from 0 → 1)
		timerStroke.Transparency = 1 - fraction

		-- Stroke thickness shrinks
		timerStroke.Thickness = math.max(1, 4 * fraction)

		-- Pulse the container slightly when low
		if remaining <= 3 then
			local pulse = 0.3 + 0.1 * math.sin(tick() * 8)
			container.BackgroundTransparency = pulse
		else
			container.BackgroundTransparency = 0.3
		end

		if remaining <= 0 then
			container.Visible = false
			activeBuff = nil
			if timerConnection then timerConnection:Disconnect(); timerConnection = nil end
		end
	end)
end

local function hideBuff()
	activeBuff = nil
	container.Visible = false
	if timerConnection then timerConnection:Disconnect(); timerConnection = nil end
end

--------------------------------------------------------------------------
-- EVENT LISTENER
--------------------------------------------------------------------------
ArcadeBuffEvent.OnClientEvent:Connect(function(action: string, data: any?)
	if action == "BuffApplied" and data then
		showBuff(data)
	elseif action == "BuffRemoved" then
		hideBuff()
	end
end)
