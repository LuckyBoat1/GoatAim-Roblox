-- PvpCountdownUI.client.lua
-- High-quality countdown GUI for PvP duels (styled like BullTeleportUI)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for RemoteEvent
local PvpCountdownEvent = ReplicatedStorage:WaitForChild("PvpCountdownEvent")

--------------------------------------------------------------------------
-- HIDE / SHOW OTHER GUIS DURING COUNTDOWN
--------------------------------------------------------------------------
local guisHidden = false -- flag to know if we hid GUIs

local function hideOtherGuis()
	guisHidden = true
	-- Hide any Stats GUI in PlayerGui — could be ScreenGui OR SurfaceGui (FloatingGui)
	for _, gui in playerGui:GetChildren() do
		if gui.Name == "Stats" and (gui:IsA("ScreenGui") or gui:IsA("SurfaceGui")) and gui.Enabled then
			gui.Enabled = false
		end
	end
	-- FloatingGui Part lives in workspace, check there too
	for _, obj in workspace:GetChildren() do
		if obj.Name == "FloatingGuiAdornee" and obj:IsA("Part") then
			for _, sg in obj:GetChildren() do
				if sg:IsA("SurfaceGui") and sg.Name == "Stats" and sg.Enabled then
					sg.Enabled = false
				end
			end
		end
	end
	-- Also hide the Roblox coregui leaderboard
	pcall(function()
		game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
	end)
end

local function showOtherGuis()
	guisHidden = false
	-- Re-enable any Stats GUI in PlayerGui — ScreenGui or SurfaceGui
	for _, gui in playerGui:GetChildren() do
		if gui.Name == "Stats" and (gui:IsA("ScreenGui") or gui:IsA("SurfaceGui")) then
			gui.Enabled = true
		end
	end
	-- FloatingGui Part lives in workspace
	for _, obj in workspace:GetChildren() do
		if obj.Name == "FloatingGuiAdornee" and obj:IsA("Part") then
			for _, sg in obj:GetChildren() do
				if sg:IsA("SurfaceGui") and sg.Name == "Stats" then
					sg.Enabled = true
				end
			end
		end
	end
	pcall(function()
		game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
	end)
end

--------------------------------------------------------------------------
-- CREATE UI
--------------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PvpCountdownUI"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 110
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Container (centered, holds icon + labels)
local container = Instance.new("Frame")
container.Name = "Container"
container.Size = UDim2.new(0, 936, 0, 312)
container.Position = UDim2.new(0.5, -468, 0.5, -156)
container.BackgroundTransparency = 1
container.Visible = false
container.Parent = screenGui

-- ═══════════════════════════════════════════════════  ICON  ═══════════
-- Animated icon background (circle)
local iconFrame = Instance.new("Frame")
iconFrame.Name = "IconFrame"
iconFrame.Size = UDim2.new(0, 156, 0, 156)
iconFrame.Position = UDim2.new(0.5, -78, 0, 0)
iconFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
iconFrame.BorderSizePixel = 0
iconFrame.Parent = container

local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius = UDim.new(1, 0)
iconCorner.Parent = iconFrame

-- Purple-to-dark-purple gradient (PvP accent)
local iconGradient = Instance.new("UIGradient")
iconGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 60, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 20, 160))
}
iconGradient.Rotation = 135
iconGradient.Parent = iconFrame

-- Inner glow stroke
local iconStroke = Instance.new("UIStroke")
iconStroke.Color = Color3.fromRGB(200, 120, 255)
iconStroke.Thickness = 4
iconStroke.Transparency = 0.3
iconStroke.Parent = iconFrame

-- Outer glow (soft ring behind icon)
local outerGlow = Instance.new("Frame")
outerGlow.Name = "OuterGlow"
outerGlow.Size = UDim2.new(0, 180, 0, 180)
outerGlow.Position = UDim2.new(0.5, -90, 0, -12)
outerGlow.BackgroundColor3 = Color3.fromRGB(180, 60, 255)
outerGlow.BackgroundTransparency = 0.7
outerGlow.BorderSizePixel = 0
outerGlow.ZIndex = 0
outerGlow.Parent = container

local outerGlowCorner = Instance.new("UICorner")
outerGlowCorner.CornerRadius = UDim.new(1, 0)
outerGlowCorner.Parent = outerGlow

-- Swords icon (⚔) built with TextLabel since we don't have a custom image
local swordsLabel = Instance.new("TextLabel")
swordsLabel.Name = "SwordsIcon"
swordsLabel.Size = UDim2.new(0.84, 0, 0.84, 0)
swordsLabel.Position = UDim2.new(0.08, 0, 0.08, 0)
swordsLabel.BackgroundTransparency = 1
swordsLabel.Text = "⚔"
swordsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
swordsLabel.TextSize = 72
swordsLabel.Font = Enum.Font.GothamBold
swordsLabel.TextScaled = false
swordsLabel.Parent = iconFrame

-- ═══════════════════════════════════  TITLE  ═══════════════════════════
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, 0, 0, 48)
titleLabel.Position = UDim2.new(0, 0, 0, 138)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 38
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Text = "PVP ARENA"
titleLabel.TextXAlignment = Enum.TextXAlignment.Center
titleLabel.Parent = container

local titleStroke = Instance.new("UIStroke")
titleStroke.Thickness = 3
titleStroke.Color = Color3.fromRGB(0, 0, 0)
titleStroke.Parent = titleLabel

-- Title gradient (white → light purple)
local titleGradient = Instance.new("UIGradient")
titleGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 200, 255))
}
titleGradient.Rotation = 90
titleGradient.Parent = titleLabel

-- ═══════════════════════════════════  OPPONENT NAME  ═══════════════════
local opponentLabel = Instance.new("TextLabel")
opponentLabel.Name = "OpponentLabel"
opponentLabel.Size = UDim2.new(1, 0, 0, 30)
opponentLabel.Position = UDim2.new(0, 0, 0, 186)
opponentLabel.BackgroundTransparency = 1
opponentLabel.TextColor3 = Color3.fromRGB(255, 200, 200)
opponentLabel.TextSize = 22
opponentLabel.Font = Enum.Font.GothamMedium
opponentLabel.Text = ""
opponentLabel.TextXAlignment = Enum.TextXAlignment.Center
opponentLabel.TextTransparency = 0.2
opponentLabel.Parent = container

local opponentStroke = Instance.new("UIStroke")
opponentStroke.Thickness = 2
opponentStroke.Color = Color3.fromRGB(0, 0, 0)
opponentStroke.Parent = opponentLabel

-- ═══════════════════════════════════  COUNTDOWN  ═══════════════════════
local countdownLabel = Instance.new("TextLabel")
countdownLabel.Name = "CountdownLabel"
countdownLabel.Size = UDim2.new(1, 0, 0, 80)
countdownLabel.Position = UDim2.new(0, 0, 0, 218)
countdownLabel.BackgroundTransparency = 1
countdownLabel.TextColor3 = Color3.fromRGB(255, 220, 100) -- Gold
countdownLabel.TextSize = 58
countdownLabel.Font = Enum.Font.GothamBold
countdownLabel.Text = ""
countdownLabel.TextXAlignment = Enum.TextXAlignment.Center
countdownLabel.Parent = container

local countStroke = Instance.new("UIStroke")
countStroke.Thickness = 4
countStroke.Color = Color3.fromRGB(200, 100, 0) -- Orange glow
countStroke.Parent = countdownLabel

-- Decorative accent line under title
local accentLine = Instance.new("Frame")
accentLine.Name = "AccentLine"
accentLine.Size = UDim2.new(0, 300, 0, 3)
accentLine.Position = UDim2.new(0.5, -150, 0, 183)
accentLine.BackgroundColor3 = Color3.fromRGB(180, 60, 255)
accentLine.BorderSizePixel = 0
accentLine.Parent = container

local accentCorner = Instance.new("UICorner")
accentCorner.CornerRadius = UDim.new(0, 2)
accentCorner.Parent = accentLine

local accentGradient = Instance.new("UIGradient")
accentGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 60, 255)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 180, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 60, 255))
}
accentGradient.Parent = accentLine

--------------------------------------------------------------------------
-- FIGHT TIMER UI (premium Bull-quality design)
--------------------------------------------------------------------------
local fightDuration = 60 -- will be set by FightStart event

-- Outer wrapper (transparent, holds bar + overlapping icon)
local timerContainer = Instance.new("Frame")
timerContainer.Name = "TimerContainer"
timerContainer.Size = UDim2.new(0, 420, 0, 110)
timerContainer.Position = UDim2.new(0.5, -210, 0, -150) -- starts off-screen
timerContainer.BackgroundTransparency = 1
timerContainer.Visible = false
timerContainer.Parent = screenGui

-- Dark background bar (layered, like Bull score/time bars)
local timerBg = Instance.new("Frame")
timerBg.Name = "TimerBg"
timerBg.Size = UDim2.new(1, -50, 0, 70)
timerBg.Position = UDim2.new(0, 0, 0.5, -35)
timerBg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
timerBg.BorderSizePixel = 0
timerBg.ZIndex = 1
timerBg.Parent = timerContainer

local timerBgCorner = Instance.new("UICorner")
timerBgCorner.CornerRadius = UDim.new(0, 10)
timerBgCorner.Parent = timerBg

-- Dark gradient overlay on bg
local timerBgGradient = Instance.new("UIGradient")
timerBgGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 40, 80)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 15))
}
timerBgGradient.Rotation = 90
timerBgGradient.Parent = timerBg

-- Colored border stroke
local timerBgStroke = Instance.new("UIStroke")
timerBgStroke.Thickness = 3
timerBgStroke.Color = Color3.fromRGB(180, 60, 255)
timerBgStroke.Parent = timerBg

-- Bottom accent strip
local timerAccent = Instance.new("Frame")
timerAccent.Name = "Accent"
timerAccent.Size = UDim2.new(1, 0, 0, 6)
timerAccent.Position = UDim2.new(0, 0, 1, -6)
timerAccent.BackgroundColor3 = Color3.fromRGB(180, 60, 255)
timerAccent.BorderSizePixel = 0
timerAccent.ZIndex = 2
timerAccent.Parent = timerBg

local timerAccentCorner = Instance.new("UICorner")
timerAccentCorner.CornerRadius = UDim.new(0, 10)
timerAccentCorner.Parent = timerAccent

-- Progress bar background (inside the dark bar)
local timerBarBg = Instance.new("Frame")
timerBarBg.Name = "BarBg"
timerBarBg.Size = UDim2.new(1, -24, 0, 14)
timerBarBg.Position = UDim2.new(0, 12, 0, 48)
timerBarBg.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
timerBarBg.BorderSizePixel = 0
timerBarBg.ZIndex = 2
timerBarBg.Parent = timerBg

local barBgCorner = Instance.new("UICorner")
barBgCorner.CornerRadius = UDim.new(0, 7)
barBgCorner.Parent = timerBarBg

-- Progress bar fill
local timerBarFill = Instance.new("Frame")
timerBarFill.Name = "BarFill"
timerBarFill.Size = UDim2.new(1, 0, 1, 0)
timerBarFill.Position = UDim2.new(0, 0, 0, 0)
timerBarFill.BackgroundColor3 = Color3.fromRGB(180, 60, 255)
timerBarFill.BorderSizePixel = 0
timerBarFill.ZIndex = 3
timerBarFill.Parent = timerBarBg

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 7)
fillCorner.Parent = timerBarFill

local fillGradient = Instance.new("UIGradient")
fillGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(160, 40, 255)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 100, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 40, 255))
}
fillGradient.Rotation = 0
fillGradient.Parent = timerBarFill

-- Bar glow (shimmer line on fill)
local barShimmer = Instance.new("Frame")
barShimmer.Name = "Shimmer"
barShimmer.Size = UDim2.new(1, 0, 0.4, 0)
barShimmer.Position = UDim2.new(0, 0, 0, 0)
barShimmer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
barShimmer.BackgroundTransparency = 0.7
barShimmer.BorderSizePixel = 0
barShimmer.ZIndex = 4
barShimmer.Parent = timerBarFill

local shimmerCorner = Instance.new("UICorner")
shimmerCorner.CornerRadius = UDim.new(0, 7)
shimmerCorner.Parent = barShimmer

-- Time text (LuckiestGuy like Bull, big and bold)
local timerLabel = Instance.new("TextLabel")
timerLabel.Name = "TimeLabel"
timerLabel.Size = UDim2.new(1, -80, 0, 48)
timerLabel.Position = UDim2.new(0, 10, 0, -2)
timerLabel.BackgroundTransparency = 1
timerLabel.Text = "1:00"
timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
timerLabel.TextSize = 48
timerLabel.Font = Enum.Font.LuckiestGuy
timerLabel.TextXAlignment = Enum.TextXAlignment.Right
timerLabel.ZIndex = 2
timerLabel.Parent = timerBg

local timerTextGradient = Instance.new("UIGradient")
timerTextGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 180, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 100, 255))
}
timerTextGradient.Rotation = 90
timerTextGradient.Parent = timerLabel

local timerLabelStroke = Instance.new("UIStroke")
timerLabelStroke.Thickness = 3
timerLabelStroke.Color = Color3.fromRGB(0, 0, 0)
timerLabelStroke.Parent = timerLabel

-- "PVP" sub-label above the time
local pvpSubLabel = Instance.new("TextLabel")
pvpSubLabel.Name = "PVPLabel"
pvpSubLabel.Size = UDim2.new(0, 100, 0, 20)
pvpSubLabel.Position = UDim2.new(0, 14, 0, 2)
pvpSubLabel.BackgroundTransparency = 1
pvpSubLabel.Text = "PVP DUEL"
pvpSubLabel.TextColor3 = Color3.fromRGB(180, 140, 255)
pvpSubLabel.TextSize = 14
pvpSubLabel.Font = Enum.Font.LuckiestGuy
pvpSubLabel.TextXAlignment = Enum.TextXAlignment.Left
pvpSubLabel.ZIndex = 2
pvpSubLabel.Parent = timerBg

local pvpSubStroke = Instance.new("UIStroke")
pvpSubStroke.Thickness = 1
pvpSubStroke.Color = Color3.fromRGB(0, 0, 0)
pvpSubStroke.Parent = pvpSubLabel

-- Overlapping swords icon (big, to the right — same pattern as Bull icon overlap)
local timerIconFrame = Instance.new("Frame")
timerIconFrame.Name = "IconFrame"
timerIconFrame.Size = UDim2.new(0, 100, 0, 100)
timerIconFrame.Position = UDim2.new(1, -75, 0.5, -50)
timerIconFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
timerIconFrame.BorderSizePixel = 0
timerIconFrame.ZIndex = 5
timerIconFrame.Parent = timerContainer

local timerIconCorner = Instance.new("UICorner")
timerIconCorner.CornerRadius = UDim.new(1, 0) -- circle
timerIconCorner.Parent = timerIconFrame

local timerIconGrad = Instance.new("UIGradient")
timerIconGrad.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 60, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 20, 140))
}
timerIconGrad.Rotation = 135
timerIconGrad.Parent = timerIconFrame

local timerIconStroke = Instance.new("UIStroke")
timerIconStroke.Thickness = 3
timerIconStroke.Color = Color3.fromRGB(220, 150, 255)
timerIconStroke.Transparency = 0.3
timerIconStroke.Parent = timerIconFrame

-- Swords emoji inside the circle
local timerSwords = Instance.new("TextLabel")
timerSwords.Name = "SwordsIcon"
timerSwords.Size = UDim2.new(0.85, 0, 0.85, 0)
timerSwords.Position = UDim2.new(0.075, 0, 0.075, 0)
timerSwords.BackgroundTransparency = 1
timerSwords.Text = "\u{2694}"
timerSwords.TextColor3 = Color3.fromRGB(255, 255, 255)
timerSwords.TextSize = 48
timerSwords.Font = Enum.Font.GothamBold
timerSwords.ZIndex = 6
timerSwords.Parent = timerIconFrame

--------------------------------------------------------------------------
-- HEARTS UI (below the timer bar — your health)
--------------------------------------------------------------------------
local MAX_HEARTS = 3
local heartLabels = {}

local heartsContainer = Instance.new("Frame")
heartsContainer.Name = "HeartsContainer"
heartsContainer.Size = UDim2.new(0, 200, 0, 50)
heartsContainer.Position = UDim2.new(0.5, -100, 0, 95) -- below timer
heartsContainer.BackgroundTransparency = 1
heartsContainer.Visible = false
heartsContainer.Parent = screenGui

-- "YOUR HEALTH" label
local heartsTitle = Instance.new("TextLabel")
heartsTitle.Name = "HeartsTitle"
heartsTitle.Size = UDim2.new(1, 0, 0, 16)
heartsTitle.Position = UDim2.new(0, 0, 0, -14)
heartsTitle.BackgroundTransparency = 1
heartsTitle.Text = "YOUR HEALTH"
heartsTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
heartsTitle.TextSize = 12
heartsTitle.Font = Enum.Font.GothamBold
heartsTitle.Parent = heartsContainer

local heartsTitleStroke = Instance.new("UIStroke")
heartsTitleStroke.Thickness = 1
heartsTitleStroke.Color = Color3.fromRGB(0, 0, 0)
heartsTitleStroke.Parent = heartsTitle

for i = 1, MAX_HEARTS do
	local heart = Instance.new("TextLabel")
	heart.Name = "Heart" .. i
	heart.Size = UDim2.new(0, 50, 0, 50)
	heart.Position = UDim2.new(0, (i - 1) * 60 + 20, 0, 0)
	heart.BackgroundTransparency = 1
	heart.Text = "\u{2764}" -- ❤
	heart.TextColor3 = Color3.fromRGB(255, 50, 70)
	heart.TextSize = 40
	heart.Font = Enum.Font.GothamBold
	heart.ZIndex = 2
	heart.Parent = heartsContainer

	local heartStroke = Instance.new("UIStroke")
	heartStroke.Thickness = 2
	heartStroke.Color = Color3.fromRGB(120, 0, 0)
	heartStroke.Parent = heart

	heartLabels[i] = heart
end

-- Hit marker effect (center of screen — brief crosshair flash)
local function showHitMarker(hitType)
	local marker = Instance.new("TextLabel")
	marker.Size = UDim2.new(0, 100, 0, 100)
	marker.Position = UDim2.new(0.5, -50, 0.5, -50)
	marker.BackgroundTransparency = 1
	marker.ZIndex = 15
	marker.Parent = screenGui

	if hitType == "headshot" then
		marker.Text = "\u{1F3AF}" -- 🎯
		marker.TextColor3 = Color3.fromRGB(255, 50, 50)
		marker.TextSize = 60
	else
		marker.Text = "+"
		marker.TextColor3 = Color3.fromRGB(255, 255, 255)
		marker.TextSize = 50
	end
	marker.Font = Enum.Font.GothamBold

	local markerStroke = Instance.new("UIStroke")
	markerStroke.Thickness = 2
	markerStroke.Color = Color3.fromRGB(0, 0, 0)
	markerStroke.Parent = marker

	-- Pop in
	marker.TextSize = hitType == "headshot" and 30 or 25
	TweenService:Create(marker, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		TextSize = hitType == "headshot" and 60 or 50
	}):Play()

	task.delay(0.3, function()
		TweenService:Create(marker, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			TextTransparency = 1
		}):Play()
		TweenService:Create(markerStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Transparency = 1
		}):Play()
		task.delay(0.3, function()
			marker:Destroy()
		end)
	end)
end

-- Update hearts display with animation
local function updateHearts(currentHearts)
	for i = 1, MAX_HEARTS do
		local heart = heartLabels[i]
		if i <= currentHearts then
			-- Full heart
			heart.Text = "\u{2764}" -- ❤
			heart.TextColor3 = Color3.fromRGB(255, 50, 70)
			heart.TextTransparency = 0
		else
			-- Lost heart — animate break
			if heart.TextTransparency < 0.5 then
				-- This heart was just lost — play break animation
				heart.TextColor3 = Color3.fromRGB(80, 80, 80)
				heart.TextSize = 50
				TweenService:Create(heart, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
					TextSize = 55,
					Rotation = 15
				}):Play()
				task.delay(0.15, function()
					TweenService:Create(heart, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
						TextSize = 40,
						Rotation = 0,
						TextTransparency = 0.5
					}):Play()
				end)
			end
			-- Empty/broken heart
			heart.Text = "\u{1F5A4}" -- 🖤
			heart.TextTransparency = 0.5
		end
	end
end

--------------------------------------------------------------------------
-- ANIMATION FUNCTIONS
--------------------------------------------------------------------------

-- Slide the container in from the top with icon spin + pulse
local function showFrame()
	container.Visible = true

	-- Slide in from top
	container.Position = UDim2.new(0.5, -468, 0, -200)
	TweenService:Create(container, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -468, 0.5, -156)
	}):Play()

	-- Spin the icon in
	iconFrame.Rotation = -180
	TweenService:Create(iconFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Rotation = 0
	}):Play()

	-- Outer glow pulse
	outerGlow.BackgroundTransparency = 0.9
	TweenService:Create(outerGlow, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.7
	}):Play()

	-- Accent line expand from 0
	accentLine.Size = UDim2.new(0, 0, 0, 3)
	TweenService:Create(accentLine, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.2), {
		Size = UDim2.new(0, 300, 0, 3)
	}):Play()

	-- Continuous icon pulse
	task.spawn(function()
		while container.Visible do
			TweenService:Create(iconFrame, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Size = UDim2.new(0, 166, 0, 166),
				Position = UDim2.new(0.5, -83, 0, -5)
			}):Play()
			TweenService:Create(outerGlow, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				BackgroundTransparency = 0.5,
				Size = UDim2.new(0, 195, 0, 195),
				Position = UDim2.new(0.5, -97.5, 0, -19.5)
			}):Play()
			task.wait(0.8)
			if not container.Visible then break end
			TweenService:Create(iconFrame, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Size = UDim2.new(0, 156, 0, 156),
				Position = UDim2.new(0.5, -78, 0, 0)
			}):Play()
			TweenService:Create(outerGlow, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				BackgroundTransparency = 0.7,
				Size = UDim2.new(0, 180, 0, 180),
				Position = UDim2.new(0.5, -90, 0, -12)
			}):Play()
			task.wait(0.8)
		end
	end)
end

-- Slide downwards out of view
local function hideFrame()
	-- Shrink accent line
	TweenService:Create(accentLine, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 0, 0, 3)
	}):Play()

	local slideOut = TweenService:Create(container, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, -468, 1, 0)
	})
	slideOut:Play()
	slideOut.Completed:Wait()
	container.Visible = false
end

-- Show fight timer bar (slides down from top with icon spin)
local function showFightTimer()
	hideOtherGuis() -- keep Stats hidden during fight
	timerContainer.Visible = true
	heartsContainer.Visible = true
	timerContainer.Position = UDim2.new(0.5, -210, 0, -150)
	TweenService:Create(timerContainer, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -210, 0, 20)
	}):Play()

	-- Spin the icon in
	timerIconFrame.Rotation = -180
	TweenService:Create(timerIconFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Rotation = 0
	}):Play()

	-- Continuous icon pulse while visible
	task.spawn(function()
		while timerContainer.Visible do
			TweenService:Create(timerIconFrame, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Size = UDim2.new(0, 108, 0, 108),
				Position = UDim2.new(1, -79, 0.5, -54)
			}):Play()
			task.wait(0.8)
			if not timerContainer.Visible then break end
			TweenService:Create(timerIconFrame, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Size = UDim2.new(0, 100, 0, 100),
				Position = UDim2.new(1, -75, 0.5, -50)
			}):Play()
			task.wait(0.8)
		end
	end)
end

-- Hide fight timer bar (slides up)
local function hideFightTimer()
	local slideUp = TweenService:Create(timerContainer, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, -210, 0, -150)
	})
	slideUp:Play()
	slideUp.Completed:Wait()
	timerContainer.Visible = false
	heartsContainer.Visible = false
	showOtherGuis() -- restore Stats

	-- Reset hearts for next duel
	for i = 1, MAX_HEARTS do
		heartLabels[i].Text = "\u{2764}"
		heartLabels[i].TextColor3 = Color3.fromRGB(255, 50, 70)
		heartLabels[i].TextTransparency = 0
		heartLabels[i].TextSize = 40
		heartLabels[i].Rotation = 0
	end
end

-- Update the fight timer display
local function updateFightTimer(timeLeft)
	local minutes = math.floor(timeLeft / 60)
	local seconds = timeLeft % 60
	timerLabel.Text = string.format("%d:%02d", minutes, seconds)

	-- Bar fill ratio (smooth tween)
	local ratio = math.clamp(timeLeft / fightDuration, 0, 1)
	TweenService:Create(timerBarFill, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(ratio, 0, 1, 0)
	}):Play()

	-- Color shifts: > 30s = purple, 10-30 = yellow/orange, <10 = red + pulse
	if timeLeft <= 10 then
		-- RED — URGENT
		timerBarFill.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
		timerBgStroke.Color = Color3.fromRGB(255, 60, 60)
		timerAccent.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
		fillGradient.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 40, 40)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 120, 80)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 40, 40))
		}
		timerTextGradient.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 120, 120)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 60, 60))
		}
		timerIconGrad.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 60)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(140, 20, 20))
		}
		timerIconStroke.Color = Color3.fromRGB(255, 100, 100)

		-- Urgent pop on the number
		timerLabel.TextSize = 38
		TweenService:Create(timerLabel, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			TextSize = 52
		}):Play()
		task.delay(0.25, function()
			TweenService:Create(timerLabel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				TextSize = 48
			}):Play()
		end)

	elseif timeLeft <= 30 then
		-- YELLOW/ORANGE — WARNING
		timerBarFill.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
		timerBgStroke.Color = Color3.fromRGB(255, 180, 0)
		timerAccent.BackgroundColor3 = Color3.fromRGB(255, 180, 0)
		fillGradient.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 160, 0)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 80)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 160, 0))
		}
		timerTextGradient.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 230, 80)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 160, 0))
		}
		timerIconGrad.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 120, 0))
		}
		timerIconStroke.Color = Color3.fromRGB(255, 220, 100)
	else
		-- PURPLE — NORMAL
		timerBarFill.BackgroundColor3 = Color3.fromRGB(180, 60, 255)
		timerBgStroke.Color = Color3.fromRGB(180, 60, 255)
		timerAccent.BackgroundColor3 = Color3.fromRGB(180, 60, 255)
		fillGradient.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(160, 40, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 100, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 40, 255))
		}
		timerTextGradient.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 180, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 100, 255))
		}
		timerIconGrad.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 60, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 20, 140))
		}
		timerIconStroke.Color = Color3.fromRGB(220, 150, 255)
	end
end

--------------------------------------------------------------------------
-- "FIGHT!" FLASH
--------------------------------------------------------------------------
local function showFightFlash()
	-- Brief full-screen "FIGHT!" text that fades out
	local fightLabel = Instance.new("TextLabel")
	fightLabel.Size = UDim2.new(1, 0, 1, 0)
	fightLabel.Position = UDim2.new(0, 0, 0, 0)
	fightLabel.BackgroundTransparency = 1
	fightLabel.Text = "FIGHT!"
	fightLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
	fightLabel.TextSize = 120
	fightLabel.Font = Enum.Font.GothamBold
	fightLabel.TextTransparency = 0
	fightLabel.ZIndex = 10
	fightLabel.Parent = screenGui

	local fightStroke = Instance.new("UIStroke")
	fightStroke.Thickness = 5
	fightStroke.Color = Color3.fromRGB(0, 0, 0)
	fightStroke.Parent = fightLabel

	local fightGradient = Instance.new("UIGradient")
	fightGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 100)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 100)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 100))
	}
	fightGradient.Rotation = 90
	fightGradient.Parent = fightLabel

	-- Scale pop
	fightLabel.TextSize = 40
	TweenService:Create(fightLabel, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		TextSize = 120
	}):Play()

	task.delay(0.8, function()
		TweenService:Create(fightLabel, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			TextTransparency = 1
		}):Play()
		TweenService:Create(fightStroke, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Transparency = 1
		}):Play()
		task.delay(0.5, function()
			fightLabel:Destroy()
		end)
	end)
end

--------------------------------------------------------------------------
-- HANDLE EVENTS
--------------------------------------------------------------------------
PvpCountdownEvent.OnClientEvent:Connect(function(action, data)
	if action == "Show" then
		-- data = opponent name
		opponentLabel.Text = "VS " .. tostring(data)
		countdownLabel.Text = ""
		hideOtherGuis()
		showFrame()

	elseif action == "Countdown" then
		local timeLeft = data

		if timeLeft > 0 then
			if not container.Visible then
				showFrame()
			end

			countdownLabel.Text = tostring(timeLeft)

			-- Recreate gradient to ensure color update
			if iconFrame:FindFirstChild("UIGradient") then
				iconFrame:FindFirstChild("UIGradient"):Destroy()
			end

			local newGradient = Instance.new("UIGradient")
			newGradient.Rotation = 135

			-- Color shift: 3 = red → 2 = yellow → 1 = green (traffic light pattern)
			if timeLeft <= 1 then
				-- GREEN — GO
				newGradient.Color = ColorSequence.new{
					ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 127)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 170, 0))
				}
				iconStroke.Color = Color3.fromRGB(100, 255, 100)
				countdownLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
				countStroke.Color = Color3.fromRGB(50, 200, 50)
				outerGlow.BackgroundColor3 = Color3.fromRGB(50, 255, 50)

			elseif timeLeft <= 2 then
				-- YELLOW — READY
				newGradient.Color = ColorSequence.new{
					ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 0)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 170, 0))
				}
				iconStroke.Color = Color3.fromRGB(255, 255, 100)
				countdownLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
				countStroke.Color = Color3.fromRGB(200, 150, 0)
				outerGlow.BackgroundColor3 = Color3.fromRGB(255, 200, 50)

			else
				-- RED/PURPLE — count starting
				newGradient.Color = ColorSequence.new{
					ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 60)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 20, 20))
				}
				iconStroke.Color = Color3.fromRGB(255, 100, 100)
				countdownLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
				countStroke.Color = Color3.fromRGB(200, 100, 0)
				outerGlow.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
			end

			newGradient.Parent = iconFrame

			-- Number POP effect (size burst + rotation snap)
			countdownLabel.TextSize = 38
			countdownLabel.Rotation = -15
			TweenService:Create(countdownLabel, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				TextSize = 56,
				Rotation = 0
			}):Play()
			task.wait(0.6)
			TweenService:Create(countdownLabel, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				TextSize = 48
			}):Play()

		else
			-- timeLeft == 0 → hide and show FIGHT flash
			hideFrame()
			showFightFlash()
			-- Don't restore Stats here — fight timer will keep them hidden
		end

	elseif action == "FightStart" then
		-- data = total fight duration
		fightDuration = data or 60
		updateHearts(MAX_HEARTS) -- reset hearts display
		showFightTimer()

	elseif action == "FightTimer" then
		-- data = seconds remaining
		updateFightTimer(data)

	elseif action == "HeartsUpdate" then
		-- data = current hearts count (our health)
		updateHearts(data)

	elseif action == "OpponentHeartsUpdate" then
		-- data = opponent's remaining hearts (could show, but not needed now)
		-- Reserved for future opponent health display

	elseif action == "HitMarker" then
		-- data = "headshot" or "body"
		showHitMarker(data)

	elseif action == "FightEnd" then
		-- data = reason string (e.g. "Time's up — Draw!")
		hideFightTimer()

		-- Show result message briefly
		if data and data ~= "" then
			local resultLabel = Instance.new("TextLabel")
			resultLabel.Size = UDim2.new(1, 0, 0, 80)
			resultLabel.Position = UDim2.new(0, 0, 0.35, 0)
			resultLabel.BackgroundTransparency = 1
			resultLabel.Text = tostring(data)
			resultLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
			resultLabel.TextSize = 48
			resultLabel.Font = Enum.Font.GothamBold
			resultLabel.TextTransparency = 0
			resultLabel.ZIndex = 10
			resultLabel.Parent = screenGui

			local resultStroke = Instance.new("UIStroke")
			resultStroke.Thickness = 4
			resultStroke.Color = Color3.fromRGB(0, 0, 0)
			resultStroke.Parent = resultLabel

			-- Pop in
			resultLabel.TextSize = 20
			TweenService:Create(resultLabel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				TextSize = 48
			}):Play()

			task.delay(2, function()
				TweenService:Create(resultLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					TextTransparency = 1
				}):Play()
				TweenService:Create(resultStroke, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					Transparency = 1
				}):Play()
				task.delay(0.6, function()
					resultLabel:Destroy()
				end)
			end)
		end
	end
end)

print("✅ [PvpCountdownUI] Loaded")
