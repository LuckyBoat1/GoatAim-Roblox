-- BullTeleportUI.client.lua
-- Shows countdown when standing on platform

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for RemoteEvents
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local TeleportCountdownRE = RemoteEvents:WaitForChild("TeleportCountdown")
local GameTimerRE = RemoteEvents:WaitForChild("GameTimer", 5) -- Optional wait for now as it might be created later
local TrafficLightRE = RemoteEvents:WaitForChild("TrafficLightUpdate", 5)
local BullScoreUpdate = RemoteEvents:WaitForChild("BullScoreUpdate", 5)

-- Create UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BullTeleportUI"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 100
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui
----
-- Container for vertical layout
local container = Instance.new("Frame")
container.Name = "Container"
container.Size = UDim2.new(0, 936, 0, 312) -- 56% bigger total (720*1.3=936, 240*1.3=312)
container.Position = UDim2.new(0.5, -468, 0.5, -156) -- Recentered
container.BackgroundTransparency = 1
container.Visible = false
container.Parent = screenGui

-- Animated icon background
local iconFrame = Instance.new("Frame")
iconFrame.Name = "IconFrame"
iconFrame.Size = UDim2.new(0, 156, 0, 156) -- 56% bigger total (120*1.3=156)
iconFrame.Position = UDim2.new(0.5, -78, 0, 0) -- Recentered
iconFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- White base for gradient
iconFrame.BorderSizePixel = 0
iconFrame.Parent = container

local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius = UDim.new(1, 0)
iconCorner.Parent = iconFrame

-- Gradient for icon background
local iconGradient = Instance.new("UIGradient")
iconGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 60)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 20, 20))
}
iconGradient.Rotation = 135
iconGradient.Parent = iconFrame

-- Inner glow
local iconStroke = Instance.new("UIStroke")
iconStroke.Color = Color3.fromRGB(255, 100, 100)
iconStroke.Thickness = 4
iconStroke.Transparency = 0.5
iconStroke.Parent = iconFrame

-- Bull icon - get from ReplicatedStorage
local bullIcon = Instance.new("ImageLabel")
bullIcon.Size = UDim2.new(0.84, 0, 0.84, 0) -- 20% bigger (0.7 * 1.2 = 0.84)
bullIcon.Position = UDim2.new(0.08, 0, 0.08, 0) -- Centered with new size
bullIcon.BackgroundTransparency = 1
bullIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
bullIcon.ScaleType = Enum.ScaleType.Fit
bullIcon.Parent = iconFrame

-- Load image from ReplicatedStorage
local success, bullImage = pcall(function()
	return ReplicatedStorage:WaitForChild("Images"):WaitForChild("BullPounding", 5)
end)

if success and bullImage then
	bullIcon.Image = bullImage.Image
	print("✅ Loaded bull image from ReplicatedStorage")
else
	warn("⚠️ Could not find Images/BullPounding in ReplicatedStorage - using fallback")
	bullIcon.Image = "" -- No image
end

-- Title with shadow
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, 0, 0, 48) -- 20% bigger (40*1.2=48)
titleLabel.Position = UDim2.new(0, 0, 0, 138) -- Adjusted (115*1.2≈138)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 38 -- 20% bigger (32*1.2≈38)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Text = "BULL ARENA"
titleLabel.TextXAlignment = Enum.TextXAlignment.Center
titleLabel.Parent = container

local titleStroke = Instance.new("UIStroke")
titleStroke.Color = Color3.fromRGB(0, 0, 0)
titleStroke.Thickness = 3
titleStroke.Parent = titleLabel

-- Countdown with glow effect
local countdownLabel = Instance.new("TextLabel")
countdownLabel.Name = "CountdownLabel"
countdownLabel.Size = UDim2.new(1, 0, 0, 60) -- 20% bigger (50*1.2=60)
countdownLabel.Position = UDim2.new(0, 0, 0, 186) -- Adjusted (155*1.2≈186)
countdownLabel.BackgroundTransparency = 1
countdownLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
countdownLabel.TextSize = 58 -- 20% bigger (48*1.2≈58)
countdownLabel.Font = Enum.Font.GothamBold
countdownLabel.Text = "3"
countdownLabel.TextXAlignment = Enum.TextXAlignment.Center
countdownLabel.Parent = container

local countStroke = Instance.new("UIStroke")
countStroke.Color = Color3.fromRGB(200, 100, 0)
countStroke.Thickness = 4
countStroke.Parent = countdownLabel

print("✅ Bull Teleport UI initialized")

local TweenService = game:GetService("TweenService")

-- Track if player died and is in respawn cooldown (prevents bull health UI from reappearing)
local respawnCooldown = false

-- Game HUD Setup
local gameGui = Instance.new("ScreenGui")
gameGui.Name = "BullGameUI"
gameGui.ResetOnSpawn = false
gameGui.Enabled = false
gameGui.Parent = playerGui

-- Helper to load image safely (supports ImageLabel and Decal)
local function loadImage(name)
	local success, img = pcall(function()
		return ReplicatedStorage:WaitForChild("Images"):WaitForChild(name, 5)
	end)
	
	if success and img then
		if img:IsA("ImageLabel") or img:IsA("ImageButton") then
			return img.Image
		elseif img:IsA("Decal") then
			return img.Texture
		end
	end
	return ""
end

-- Score Widget (Top Left)
local scoreContainer = Instance.new("Frame")
scoreContainer.Name = "ScoreContainer"
scoreContainer.Size = UDim2.new(0, 350, 0, 115) -- Bigger container for bigger icon
-- Score Widget (Top Left)
local scoreContainer = Instance.new("Frame")
scoreContainer.Name = "ScoreContainer"
scoreContainer.Size = UDim2.new(0, 320, 0, 100) -- Container size
scoreContainer.Position = UDim2.new(1, -370, 0, -150) -- Start off screen (Right side)
scoreContainer.BackgroundTransparency = 1
scoreContainer.Parent = gameGui

-- Background Bar for Score (Layered behind icon)
local scoreBg = Instance.new("Frame")
scoreBg.Name = "ScoreBg"
scoreBg.Size = UDim2.new(1, -40, 0, 70) -- Bar width
scoreBg.Position = UDim2.new(0, 0, 0.5, -35) -- Centered vertically
scoreBg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
scoreBg.BorderSizePixel = 0
scoreBg.ZIndex = 1 -- Behind icon
scoreBg.Parent = scoreContainer

local scoreCorner = Instance.new("UICorner")
scoreCorner.CornerRadius = UDim.new(0, 10) -- Less rounded, more sturdy
scoreCorner.Parent = scoreBg

local scoreBgStroke = Instance.new("UIStroke")
scoreBgStroke.Thickness = 3
scoreBgStroke.Color = Color3.fromRGB(255, 180, 0) -- Gold Border
scoreBgStroke.Parent = scoreBg

local scoreBgGradient = Instance.new("UIGradient")
scoreBgGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 60, 60)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 10))
}
scoreBgGradient.Rotation = 90
scoreBgGradient.Parent = scoreBg

-- Accent Bar (Bottom Strip)
local scoreAccent = Instance.new("Frame")
scoreAccent.Name = "Accent"
scoreAccent.Size = UDim2.new(1, 0, 0, 6)
scoreAccent.Position = UDim2.new(0, 0, 1, -6)
scoreAccent.BackgroundColor3 = Color3.fromRGB(255, 180, 0) -- Gold
scoreAccent.BorderSizePixel = 0
scoreAccent.ZIndex = 2
scoreAccent.Parent = scoreBg

local scoreAccentCorner = Instance.new("UICorner")
scoreAccentCorner.CornerRadius = UDim.new(0, 10)
scoreAccentCorner.Parent = scoreAccent

-- Value Text
local scoreLabel = Instance.new("TextLabel")
scoreLabel.Name = "Value"
scoreLabel.Size = UDim2.new(1, -70, 1, 0) -- Full height
scoreLabel.Position = UDim2.new(0, 0, 0, 0) -- Centered
scoreLabel.BackgroundTransparency = 1
scoreLabel.Text = "0"
scoreLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
scoreLabel.TextSize = 48
scoreLabel.Font = Enum.Font.LuckiestGuy
scoreLabel.TextXAlignment = Enum.TextXAlignment.Right
scoreLabel.ZIndex = 2
scoreLabel.Parent = scoreBg

local scoreTextGradient = Instance.new("UIGradient")
scoreTextGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 220, 50)), -- Gold Text
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 150, 0))
}
scoreTextGradient.Rotation = 90
scoreTextGradient.Parent = scoreLabel

local scoreStroke = Instance.new("UIStroke")
scoreStroke.Thickness = 3
scoreStroke.Color = Color3.fromRGB(0, 0, 0)
scoreStroke.Parent = scoreLabel

-- Icon (Overlapping the bar)
local scoreIcon = Instance.new("ImageLabel")
scoreIcon.Name = "Icon"
scoreIcon.Size = UDim2.new(0, 150, 0, 150) -- Bigger
scoreIcon.Position = UDim2.new(1, -100, 0.5, -75) -- Moved right
scoreIcon.BackgroundTransparency = 1
scoreIcon.Image = loadImage("Score")
scoreIcon.ZIndex = 3 -- On top of bar
scoreIcon.Parent = scoreContainer

-- Time Widget (Top Right)
local timeContainer = Instance.new("Frame")
timeContainer.Name = "TimeContainer"
timeContainer.Size = UDim2.new(0, 320, 0, 100) -- Container size
timeContainer.Position = UDim2.new(1, -370, 0, -150) -- Start off screen
timeContainer.BackgroundTransparency = 1
timeContainer.Parent = gameGui

-- Background Bar for Time
local timeBg = Instance.new("Frame")
timeBg.Name = "TimeBg"
timeBg.Size = UDim2.new(1, -40, 0, 70) -- Bar width
timeBg.Position = UDim2.new(0, 0, 0.5, -35)
timeBg.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
timeBg.BorderSizePixel = 0
timeBg.ZIndex = 1
timeBg.Parent = timeContainer

local timeCorner = Instance.new("UICorner")
timeCorner.CornerRadius = UDim.new(0, 10)
timeCorner.Parent = timeBg

local timeBgStroke = Instance.new("UIStroke")
timeBgStroke.Thickness = 3
timeBgStroke.Color = Color3.fromRGB(0, 150, 255) -- Blue Border
timeBgStroke.Parent = timeBg

local timeBgGradient = Instance.new("UIGradient")
timeBgGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 60, 60)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 10))
}
timeBgGradient.Rotation = 90
timeBgGradient.Parent = timeBg

-- Accent Bar (Bottom Strip)
local timeAccent = Instance.new("Frame")
timeAccent.Name = "Accent"
timeAccent.Size = UDim2.new(1, 0, 0, 6)
timeAccent.Position = UDim2.new(0, 0, 1, -6)
timeAccent.BackgroundColor3 = Color3.fromRGB(0, 150, 255) -- Blue
timeAccent.BorderSizePixel = 0
timeAccent.ZIndex = 2
timeAccent.Parent = timeBg

local timeAccentCorner = Instance.new("UICorner")
timeAccentCorner.CornerRadius = UDim.new(0, 10)
timeAccentCorner.Parent = timeAccent

-- Value Text
local timeLabel = Instance.new("TextLabel")
timeLabel.Name = "Value"
timeLabel.Size = UDim2.new(1, -70, 1, 0) -- Full height
timeLabel.Position = UDim2.new(0, 0, 0, 0) -- Centered
timeLabel.BackgroundTransparency = 1
timeLabel.Text = "00:00"
timeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
timeLabel.TextSize = 48
timeLabel.Font = Enum.Font.LuckiestGuy
timeLabel.TextXAlignment = Enum.TextXAlignment.Right
timeLabel.ZIndex = 2
timeLabel.Parent = timeBg

local timeTextGradient = Instance.new("UIGradient")
timeTextGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 240, 255)), -- Light Blue Text
	ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 200, 255))
}
timeTextGradient.Rotation = 90
timeTextGradient.Parent = timeLabel

local timeStroke = Instance.new("UIStroke")
timeStroke.Thickness = 3
timeStroke.Color = Color3.fromRGB(0, 0, 0)
timeStroke.Parent = timeLabel

-- Icon (Overlapping the bar)
local timeIcon = Instance.new("ImageLabel")
timeIcon.Name = "Icon"
timeIcon.Size = UDim2.new(0, 160, 0, 160) -- Even bigger for Time
timeIcon.Position = UDim2.new(1, -100, 0.5, -90) -- Moved up by 10
timeIcon.BackgroundTransparency = 1
timeIcon.Image = loadImage("Time")
timeIcon.ZIndex = 3
timeIcon.Parent = timeContainer

-- Traffic Light (Under Score)
local lightContainer = Instance.new("Frame")
lightContainer.Name = "LightContainer"
lightContainer.Size = UDim2.new(0, 180, 0, 150) -- 20% bigger (150*1.2=180, 125*1.2=150)
lightContainer.Position = UDim2.new(1, -300, 0, -180) -- Start off screen, top-right
lightContainer.BackgroundTransparency = 1
lightContainer.ClipsDescendants = false -- Ensure glow isn't cut off
lightContainer.Parent = gameGui

-- Glow for Light
local lightGlow = Instance.new("ImageLabel")
lightGlow.Name = "Glow"
lightGlow.Size = UDim2.new(1.215, 0, 2.187, 0) -- Taller glow
lightGlow.Position = UDim2.new(0.5, 0, 0.4, 0)
lightGlow.AnchorPoint = Vector2.new(0.5, 0.5)
lightGlow.BackgroundTransparency = 1
lightGlow.ImageColor3 = Color3.fromRGB(255, 50, 50) -- Red glow
lightGlow.ImageTransparency = 0.2
lightGlow.ZIndex = 1 -- Behind light
lightGlow.Parent = lightContainer

-- Load glow image
task.spawn(function()
	local glowId = loadImage("Glow") -- Updated image name
	if glowId ~= "" then
		lightGlow.Image = glowId
	else
		warn("Failed to load glow image: Glow")
	end
end)

local lightIcon = Instance.new("ImageLabel")
lightIcon.Name = "Icon"
lightIcon.Size = UDim2.new(1, 0, 1, 0)
lightIcon.BackgroundTransparency = 1
local redLightId = loadImage("RedLight")
lightIcon.Image = redLightId -- Default to Red
lightIcon.ZIndex = 2 -- In front of glow
lightIcon.Parent = lightContainer

-- Handle glow color change
task.spawn(function()
	local greenLightId = loadImage("GreenLight")
	lightIcon:GetPropertyChangedSignal("Image"):Connect(function()
		if lightIcon.Image == greenLightId and greenLightId ~= "" then
			lightGlow.ImageColor3 = Color3.fromRGB(50, 255, 50) -- Green glow
		else
			lightGlow.ImageColor3 = Color3.fromRGB(255, 50, 50) -- Red glow
		end
	end)
end)

-- Function to show Game HUD
local function showGameHUD()
	gameGui.Enabled = true
	respawnCooldown = false -- Reset cooldown when teleported to bull arena
	print("Client: Respawn cooldown reset - player teleported to arena")
	
	-- Animate Score
	scoreContainer.Position = UDim2.new(1, -370, 0, -150)
	TweenService:Create(scoreContainer, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(1, -370, 0, 115)
	}):Play()
	
	-- Animate Time
	timeContainer.Position = UDim2.new(1, -370, 0, -150)
	TweenService:Create(timeContainer, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0.1), {
		Position = UDim2.new(1, -370, 0, 0)
	}):Play()
	
	-- Animate Light
	lightContainer.Position = UDim2.new(1, -300, 0, -180)
	TweenService:Create(lightContainer, TweenInfo.new(0.6, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out, 0, false, 0.2), {
		Position = UDim2.new(1, -300, 0, 230)
	}):Play()
end

-- Function to hide Game HUD (called on death)
local function hideGameHUD()
	gameGui.Enabled = false
	container.Visible = false
	print("Client: Game HUD hidden")
end

-- Animate frame entrance
local function showFrame()
	container.Visible = true
	
	-- Slide in from top
	container.Position = UDim2.new(0.5, -468, 0, -200)
	local slideIn = TweenService:Create(container, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -468, 0.5, -156)
	})
	slideIn:Play()
	
	-- Spin the icon
	iconFrame.Rotation = -180
	local spinTween = TweenService:Create(iconFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Rotation = 0
	})
	spinTween:Play()
	
	-- Pulse icon continuously
	task.spawn(function()
		while container.Visible do
			TweenService:Create(iconFrame, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Size = UDim2.new(0, 163, 0, 163),
				Position = UDim2.new(0.5, -81.5, 0, -3.5)
			}):Play()
			task.wait(0.8)
			TweenService:Create(iconFrame, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Size = UDim2.new(0, 156, 0, 156),
				Position = UDim2.new(0.5, -78, 0, 0)
			}):Play()
			task.wait(0.8)
		end
	end)
end

-- Animate frame exit
local function hideFrame()
	local slideOut = TweenService:Create(container, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, -468, 1, 0)
	})
	slideOut:Play()
	slideOut.Completed:Wait()
	container.Visible = false
end

-- Handle countdown updates
TeleportCountdownRE.OnClientEvent:Connect(function(timeLeft)
	if timeLeft > 0 then
		if not container.Visible then
			showFrame()
		end
		
		countdownLabel.Text = tostring(timeLeft)
		
		-- Completely recreate gradient to ensure colors update properly
		if iconFrame:FindFirstChild("UIGradient") then
			iconFrame:FindFirstChild("UIGradient"):Destroy()
		end
		
		local newGradient = Instance.new("UIGradient")
		newGradient.Rotation = 135
		
		-- Dramatic color shift and scale
		if timeLeft <= 1 then
			-- Green gradient with your hex colors
			newGradient.Color = ColorSequence.new{
				ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 127)), -- #00ff7f
				ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 170, 0))    -- #00aa00
			}
			iconStroke.Color = Color3.fromRGB(100, 255, 100)
			countdownLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
			countStroke.Color = Color3.fromRGB(50, 200, 50)
		elseif timeLeft <= 2 then
			-- Yellow gradient with your hex colors
			newGradient.Color = ColorSequence.new{
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 0)),  -- #ffff00
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 170, 0))   -- #ffaa00
			}
			iconStroke.Color = Color3.fromRGB(255, 255, 100)
			countdownLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
			countStroke.Color = Color3.fromRGB(200, 150, 0)
		else
			-- Red gradient for start
			newGradient.Color = ColorSequence.new{
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 60)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 20, 20))
			}
			iconStroke.Color = Color3.fromRGB(255, 100, 100)
			countdownLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
			countStroke.Color = Color3.fromRGB(200, 100, 0)
		end
		
		newGradient.Parent = iconFrame
		
		-- Number pop effect
		countdownLabel.TextSize = 38
		countdownLabel.Rotation = -15
		local popTween = TweenService:Create(countdownLabel, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			TextSize = 56,
			Rotation = 0
		})
		popTween:Play()
		task.wait(0.6)
		TweenService:Create(countdownLabel, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			TextSize = 48
		}):Play()
		
		print("⏱️ Countdown: " .. timeLeft)
	else
		hideFrame()
		showGameHUD()
	end
end)

local currentArena = nil
local currentAnimTrack = nil
local BULL_ANIMATION_ID = "rbxassetid://71635624642744"
local BULL_WALK_ANIMATION_ID = "rbxassetid://102385254834975" -- Bull walk animation

-- Bull Behavior Variables
local bullBehaviorConnection = nil
local bullDirectionLoop = nil
local currentBullTrack = nil
local bullMovers = {}
local isClientBehaviorActive = false

local function stopBullBehavior()
	isClientBehaviorActive = false
	if bullBehaviorConnection then 
		bullBehaviorConnection:Disconnect() 
		bullBehaviorConnection = nil 
	end
	if bullDirectionLoop then 
		task.cancel(bullDirectionLoop) 
		bullDirectionLoop = nil 
	end
	if currentBullTrack then 
		currentBullTrack:Stop() 
		currentBullTrack = nil 
	end
	-- Clean up physics movers
	for _, mover in ipairs(bullMovers) do
		if mover and mover.Parent then mover:Destroy() end
	end
	bullMovers = {}
end

local function startBullBehavior(arena)
	if isClientBehaviorActive then return end -- Already running
	isClientBehaviorActive = true
	
	local bull = arena:FindFirstChild("bull")
	if not bull then 
		isClientBehaviorActive = false
		return 
	end
	
	local rootPart = bull.PrimaryPart or bull:FindFirstChild("HumanoidRootPart") or bull:FindFirstChild("Shape")
	if not rootPart then 
		isClientBehaviorActive = false
		return 
	end

	-- Ensure RootPart is Anchored for CFrame movement
	-- rootPart.Anchored = true -- DISABLED: Server handles movement now

	-- Setup Animator
	local animator
	local humanoid = bull:FindFirstChildOfClass("Humanoid")
	if humanoid then
		animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
	else
		local animController = bull:FindFirstChild("AnimationController") or Instance.new("AnimationController", bull)
		animator = animController:FindFirstChild("Animator") or Instance.new("Animator", animController)
	end
	
	-- Play Animation
	local animation = Instance.new("Animation")
	animation.AnimationId = BULL_ANIMATION_ID
	currentBullTrack = animator:LoadAnimation(animation)
	currentBullTrack.Looped = true
	-- currentBullTrack:Play() -- DISABLED: Animation played on server
	-- Animation plays continuously (no AdjustSpeed(0))
	
	-- Helper function to spawn effect at a specific attachment
	-- scaleMultiplier: size multiplier (default 1)
	-- delayTime: how long to stay visible before fading (default 0.3)
	-- fadeTime: how long to fade out (default 0.7)
	-- followTime: how long to follow the leg (nil = forever, 0 = don't follow)
	local function spawnStepEffect(attName, scaleMultiplier, delayTime, fadeTime, followTime)
		scaleMultiplier = scaleMultiplier or 1
		delayTime = delayTime or 0.3
		fadeTime = fadeTime or 0.7
		-- followTime: nil means follow forever, 0 means don't follow
		print("Client: Spawning effect at " .. attName .. " (scale: " .. scaleMultiplier .. "x)")
		
		-- Find the attachment OR Bone in the bull rig (recursive search)
		local targetObject = bull:FindFirstChild(attName, true)
		
		local stepEffect = ReplicatedStorage:FindFirstChild("Effects") and ReplicatedStorage.Effects:FindFirstChild("Step")
		if stepEffect then
			local clone = stepEffect:Clone()
			clone.Parent = workspace
			
			local spawnPosition
			
			if targetObject and (targetObject:IsA("Attachment") or targetObject:IsA("Bone")) then
				spawnPosition = targetObject.WorldPosition
			else
				if not targetObject then
					-- Only warn if we were looking for a specific named step
					-- print("Client: Could not find Attachment or Bone named '" .. attName .. "'")
				end
				spawnPosition = rootPart.Position
			end

			-- Raycast down to find the floor
			local rayDirection = Vector3.new(0, -10, 0)
			local raycastParams = RaycastParams.new()
			raycastParams.FilterDescendantsInstances = {bull, clone}
			raycastParams.FilterType = Enum.RaycastFilterType.Exclude
			
			local rayResult = workspace:Raycast(spawnPosition + Vector3.new(0, 2, 0), rayDirection, raycastParams)
			local targetCFrame
			
			if rayResult then
				-- Align to floor normal
				local up = rayResult.Normal
				local forward = rootPart.CFrame.LookVector
				local right = forward:Cross(up)
				local newForward = up:Cross(right)
				
				targetCFrame = CFrame.fromMatrix(rayResult.Position, right, up, newForward)
			else
				targetCFrame = CFrame.new(spawnPosition) * rootPart.CFrame.Rotation
			end

			if clone:IsA("Model") then
				if clone.PrimaryPart then
					clone:SetPrimaryPartCFrame(targetCFrame)
				else
					clone:PivotTo(targetCFrame)
				end
			elseif clone:IsA("BasePart") then
				clone.CFrame = targetCFrame
			end
			
			-- Set up anchoring based on follow behavior
			for _, d in ipairs(clone:GetDescendants()) do
				if d:IsA("BasePart") then
					d.Anchored = true
					d.CanCollide = false
				end
			end
			if clone:IsA("BasePart") then
				clone.Anchored = true
				clone.CanCollide = false
			end

			-- Position the effect and set up following behavior
			local weldPart = clone:IsA("BasePart") and clone or (clone:IsA("Model") and clone.PrimaryPart)
			if not weldPart and clone:IsA("Model") then
				weldPart = clone:FindFirstChildWhichIsA("BasePart")
			end
			
			if weldPart and targetObject and followTime ~= 0 then
				-- Follow the leg (for walking, or temporarily for headbutt)
				weldPart.Anchored = true
				local initialRotation = targetCFrame.Rotation
				local followStartTime = tick()
				
				local followConnection
				followConnection = RunService.Heartbeat:Connect(function()
					if not clone or not clone.Parent then
						if followConnection then followConnection:Disconnect() end
						return
					end
					
					-- Check if we should stop following (followTime limit reached)
					if followTime and (tick() - followStartTime) >= followTime then
						followConnection:Disconnect()
						return
					end
					
					-- Follow target position but keep floor alignment rotation
					weldPart.CFrame = CFrame.new(targetObject.WorldPosition) * initialRotation
				end)
			else
				-- Don't follow - stay anchored at spawn position
				if weldPart then
					weldPart.Anchored = true
				end
			end
			
			for _, desc in ipairs(clone:GetDescendants()) do
				if desc:IsA("ParticleEmitter") then
					-- Lock particles to the moving part
					desc.LockedToPart = true

					-- Force particles to be affected by world lighting (darker)
					desc.LightInfluence = 1
					
					-- Scale particle size by 15x base, then apply scaleMultiplier
					local baseScale = 15 * scaleMultiplier
					local newKeypoints = {}
					for _, kp in ipairs(desc.Size.Keypoints) do
						table.insert(newKeypoints, NumberSequenceKeypoint.new(kp.Time, kp.Value * baseScale, kp.Envelope * baseScale))
					end
					desc.Size = NumberSequence.new(newKeypoints)
					
					-- Halve the particle lifetime
					desc.Lifetime = NumberRange.new(desc.Lifetime.Min / 2, desc.Lifetime.Max / 2)
					
					-- Disable auto-emission so we can control it manually
					desc.Enabled = false
					
					-- Manual Emission Counts based on name
					if string.find(desc.Name, "Rocks") then
						desc:Emit(2)
					elseif string.find(desc.Name, "Smoke") then
						desc:Emit(20)
					elseif string.find(desc.Name, "Dust1") then
						desc:Emit(5)
					elseif string.find(desc.Name, "Dust2") then
						desc:Emit(5)
					elseif string.find(desc.Name, "Ashe") then
						desc:Emit(15)
					elseif string.find(desc.Name, "Circle") or string.find(desc.Name, "Splash") then
						desc:Emit(2)
					else
						-- Default for others (like HIT)
						desc:Emit(2)
					end
				end
			end
			
			-- Fade out effect: stay visible for delayTime, then fade over fadeTime
			-- Rocks have custom timing: start at 0.3s, fade by 0.7s
			local rocksDelayTime = 0.3
			local rocksFadeTime = 0.4
			local startTime = tick()
			local fadeConnection
			fadeConnection = RunService.Heartbeat:Connect(function()
				local elapsed = tick() - startTime
				
				-- Fade transparency of all particles (with custom timing for Rocks)
				for _, desc in ipairs(clone:GetDescendants()) do
					if desc:IsA("ParticleEmitter") then
						local thisDelay, thisFade
						if string.find(desc.Name, "Rocks") then
							thisDelay = rocksDelayTime
							thisFade = rocksFadeTime
						else
							thisDelay = delayTime
							thisFade = fadeTime
						end
						
						-- Skip if still in delay period for this emitter
						if elapsed < thisDelay then
							continue
						end
						
						-- Calculate fade alpha (0 to 1) after delay
						local fadeElapsed = elapsed - thisDelay
						local alpha = math.clamp(fadeElapsed / thisFade, 0, 1)
						
						-- Modify the transparency sequence to fade out
						local newTransparency = {}
						for _, kp in ipairs(desc.Transparency.Keypoints) do
							-- Lerp original transparency toward 1 (fully transparent)
							local newValue = kp.Value + (1 - kp.Value) * alpha
							table.insert(newTransparency, NumberSequenceKeypoint.new(kp.Time, newValue))
						end
						desc.Transparency = NumberSequence.new(newTransparency)
					end
				end
				
				-- Clean up when all fades are complete (use the longest duration)
				local maxDuration = math.max(delayTime + fadeTime, rocksDelayTime + rocksFadeTime)
				if elapsed >= maxDuration then
					fadeConnection:Disconnect()
					clone:Destroy()
				end
			end)
		end
	end

	-- Listen for animation markers from SERVER-played animations
	-- We need to hook into tracks that are already playing (replicated from server)
	local stepIndex = 1
	local attachmentNames = {"Step1", "Step2", "Step3", "Step4"}
	local connectedTracks = {} -- Track which tracks we've already connected to
	
	-- Animation IDs for determining walk vs run
	local WALK_ANIM_ID = "71635624642744"
	local RUN_ANIM_ID = "89751156154012"
	local HEADBUTT_ANIM_ID = "120738414090672"
	
	local function connectToTrack(track)
		if connectedTracks[track] then return end
		connectedTracks[track] = true
		
		local animId = track.Animation and track.Animation.AnimationId or ""
		print("Client: Connecting to animation track: " .. tostring(animId))
		
		-- Determine if this is a walk or run animation
		local isRunning = string.find(animId, RUN_ANIM_ID) ~= nil
		local stepScale = isRunning and 1 or (5/15) -- Running: 15x, Walking: 5x (base is 15)
		local stepFollowTime = isRunning and 0 or nil -- Running: don't follow, Walking: follow forever
		
		-- Connect to Step marker for walking/running effects
		track:GetMarkerReachedSignal("Step"):Connect(function()
			print("Client: Step marker reached! (Running: " .. tostring(isRunning) .. ")")
			local attName = attachmentNames[stepIndex]
			spawnStepEffect(attName, stepScale, nil, nil, stepFollowTime)
			
			stepIndex = stepIndex + 1
			if stepIndex > #attachmentNames then stepIndex = 1 end
		end)
		
		-- Connect to Splash marker for headbutt effects
		track:GetMarkerReachedSignal("Splash"):Connect(function()
			print("Client: Splash marker reached!")
			-- Spawn all effects immediately at step attachment locations, no following
			-- Scale: 20/15 = 20x (base is 15x)
			spawnStepEffect("Step1", 20/15, 0.3, 1.7, 0) -- 20x, 0.3s stay, 1.7s fade, NO follow (0)
			spawnStepEffect("Step2", 20/15, 0.3, 1.7, 0)
			spawnStepEffect("Step3", 20/15, 0.3, 1.7, 0)
			spawnStepEffect("Step4", 20/15, 0.3, 1.7, 0)
		end)
	end
	
	-- Connect to any tracks that are already playing
	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		connectToTrack(track)
	end
	
	-- Listen for new animations being played (from server)
	animator.AnimationPlayed:Connect(function(track)
		print("Client: New animation started playing")
		connectToTrack(track)
	end)
	
	print("Client: Bull behavior started - Burst Movement (DISABLED - MOVED TO SERVER)")
	
	local isMoving = false
	
	-- Movement Loop
	-- local WALK_SPEED = 8
	-- bullBehaviorConnection = RunService.Heartbeat:Connect(function(dt)
	-- 	if rootPart and rootPart.Parent then
	-- 		if isMoving then
	-- 			-- Raycast forward to detect walls
	-- 			local rayOrigin = rootPart.Position
	-- 			local rayDirection = rootPart.CFrame.LookVector * 100 -- Check 100 studs ahead
	-- 			local raycastParams = RaycastParams.new()
	-- 			raycastParams.FilterDescendantsInstances = {bull, arena:FindFirstChild("ArenaPlatform")} -- Ignore self and floor
	-- 			raycastParams.FilterType = Enum.RaycastFilterType.Exclude
				
	-- 			local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
				
	-- 			if raycastResult then
	-- 				-- Hit a wall! Turn around immediately
	-- 				print("Client: Bull hit wall, turning...")
	-- 				local turnAngle = math.rad(math.random(120, 240)) -- Turn roughly 180 degrees
	-- 				rootPart.CFrame = rootPart.CFrame * CFrame.Angles(0, turnAngle, 0)
	-- 			else
	-- 				-- Path clear, move forward
	-- 				rootPart.CFrame = rootPart.CFrame + (rootPart.CFrame.LookVector * WALK_SPEED * dt)
	-- 			end
	-- 		end
	-- 	else
	-- 		stopBullBehavior()
	-- 	end
	-- end)
	
	-- Direction & Burst Loop
	-- bullDirectionLoop = task.spawn(function()
	-- 	while true do
	-- 		-- 1. Pick new direction (every ~5-15 seconds)
	-- 		local randomAngle = math.rad(math.random(0, 360))
	-- 		-- Set absolute rotation to face new direction
	-- 		rootPart.CFrame = CFrame.new(rootPart.Position) * CFrame.Angles(0, randomAngle, 0)
			
	-- 		local startTime = os.clock()
	-- 		local directionDuration = math.random(10, 20)
			
	-- 		while os.clock() - startTime < directionDuration do
	-- 			-- Stop (Pause)
	-- 			isMoving = false
	-- 			task.wait(0.001) -- Pause duration
				
	-- 			-- Move (Burst)
	-- 			isMoving = true
	-- 			task.wait(0.2) -- Burst duration
				
	-- 			if not currentBullTrack then break end
	-- 		end
	-- 	end
	-- end)
end

-- Handle Traffic Light Updates
local lightAnimToken = 0

if TrafficLightRE then
	TrafficLightRE.OnClientEvent:Connect(function(state)
		lightAnimToken = lightAnimToken + 1
		local currentToken = lightAnimToken
		
		print("🚦 Traffic Light Update: " .. state)
		
		local redLightId = loadImage("RedLight")
		local greenLightId = loadImage("GreenLight")
		
		-- Base Size/Pos (Standard)
		local baseSize = UDim2.new(0, 180, 0, 150)
		local basePos = UDim2.new(1, -300, 0, 230)
		
		-- Pop Size/Pos (1.2x centered)
		local popSize = UDim2.new(0, 216, 0, 180)
		local popPos = UDim2.new(1, -318, 0, 215)
		
		local flashColor = Color3.new(1, 1, 1)

		if state == "Green" then
			lightIcon.Image = greenLightId
			lightGlow.ImageColor3 = Color3.fromRGB(50, 255, 50)
			flashColor = Color3.fromRGB(50, 255, 50)
			
			-- Make Green Light narrower (48.5% width) and centered vertically (90% height) - 2% bigger horizontally
			lightIcon.Size = UDim2.new(0.485, 0, 0.9, 0)
			lightIcon.Position = UDim2.new(0.2575, 0, 0.05, 0)
			
		elseif state == "Red" then
			lightIcon.Image = redLightId
			lightGlow.ImageColor3 = Color3.fromRGB(255, 50, 50)
			flashColor = Color3.fromRGB(255, 50, 50)
			
			-- Make Red Light 5% smaller
			lightIcon.Size = UDim2.new(0.95, 0, 0.95, 0)
			lightIcon.Position = UDim2.new(0.025, 0, 0.025, 0)
		end
		
		-- Continuous Pulse Animation (In and Out) with Shake and Flash
		task.spawn(function()
			local loopCount = 0
			local glowId = loadImage("Glow") -- Load glow image for flash
			
			-- Create Flash Overlay (ImageLabel) if missing or wrong type
			local flashOverlay = lightIcon:FindFirstChild("FlashOverlay")
			if flashOverlay and not flashOverlay:IsA("ImageLabel") then
				flashOverlay:Destroy()
				flashOverlay = nil
			end
			
			if not flashOverlay then
				flashOverlay = Instance.new("ImageLabel")
				flashOverlay.Name = "FlashOverlay"
				flashOverlay.Size = UDim2.new(1.3, 0, 1.3, 0) -- Larger than icon to glow outward
				flashOverlay.Position = UDim2.new(0.5, 0, 0.5, 0)
				flashOverlay.AnchorPoint = Vector2.new(0.5, 0.5)
				flashOverlay.BackgroundTransparency = 1
				flashOverlay.Image = glowId
				flashOverlay.ImageColor3 = flashColor -- Use matched color
				flashOverlay.ImageTransparency = 1 -- Start invisible
				flashOverlay.ZIndex = 10
				flashOverlay.Parent = lightIcon
			else
				flashOverlay.ImageColor3 = flashColor -- Update color if exists
			end
			
			while lightAnimToken == currentToken do
				loopCount = loopCount + 1

				-- Pop In
				TweenService:Create(lightContainer, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
					Size = popSize,
					Position = popPos
				}):Play()
				
				-- Wait halfway (0.25s)
				task.wait(0.25)
				
				if lightAnimToken ~= currentToken then break end

				-- Flash Effect (Trigger halfway to biggest)
				flashOverlay.ImageTransparency = 0.8
				TweenService:Create(flashOverlay, TweenInfo.new(2.0), {ImageTransparency = 1}):Play()
				
				-- Wait remaining (0.25s)
				task.wait(0.25)
				
				if lightAnimToken ~= currentToken then break end
				
				-- Shake every 2 seconds (at the peak)
				if loopCount % 2 == 0 then
					-- Shake Effect (Spawned so it doesn't delay Pop Out)
					task.spawn(function()
						for i = 1, 2 do -- Shake twice
							TweenService:Create(lightContainer, TweenInfo.new(0.05), {Rotation = 5}):Play()
							task.wait(0.05)
							TweenService:Create(lightContainer, TweenInfo.new(0.05), {Rotation = -5}):Play()
							task.wait(0.05)
						end
						TweenService:Create(lightContainer, TweenInfo.new(0.05), {Rotation = 0}):Play()
					end)
				end

				-- Pop Out
				TweenService:Create(lightContainer, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
					Size = baseSize,
					Position = basePos
				}):Play()
				task.wait(0.5)
			end
		end)
	end)
end

-- Handle Game Timer updates
if GameTimerRE then
	GameTimerRE.OnClientEvent:Connect(function(timeLeft, arena)
		local minutes = math.floor(timeLeft / 60)
		local seconds = timeLeft % 60
		timeLabel.Text = string.format("%02d:%02d", minutes, seconds)
		
		-- Optional: Change color when time is low
		if timeLeft <= 10 then
			timeLabel.TextColor3 = Color3.fromRGB(255, 50, 50) -- Red warning
		else
			timeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		end

		-- Store arena and manage bull behavior
		if arena then
			currentArena = arena
			if timeLeft > 0 then
				startBullBehavior(arena)
			else
				stopBullBehavior()
			end
		end
	end)
end

-- Manual Animation Trigger (Press E)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.E then
		if currentArena then
			local bull = currentArena:FindFirstChild("bull")
			if bull then
				print("Client: E pressed - Playing animation manually")
				
				-- DEBUG: Check Rig Structure
				print("--- BULL RIG DIAGNOSTIC ---")
				for _, child in ipairs(bull:GetDescendants()) do
					if child:IsA("BasePart") then
						print(string.format("Part: %s | Anchored: %s | CanCollide: %s", child.Name, tostring(child.Anchored), tostring(child.CanCollide)))
						-- Attempt to unanchor everything except PrimaryPart/Root
						if child.Name ~= "HumanoidRootPart" and child ~= bull.PrimaryPart then
							child.Anchored = false
						end
					elseif child:IsA("Motor6D") then
						print(string.format("Motor6D: %s | Part0: %s | Part1: %s", child.Name, tostring(child.Part0), tostring(child.Part1)))
					elseif child:IsA("Bone") then
						print(string.format("Bone: %s", child.Name))
					end
				end
				print("---------------------------")
				
				-- Get Animator
				local animator
				local humanoid = bull:FindFirstChildOfClass("Humanoid")
				if humanoid then
					animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
				else
					local animController = bull:FindFirstChild("AnimationController") or Instance.new("AnimationController", bull)
					animator = animController:FindFirstChild("Animator") or Instance.new("Animator", animController)
				end

				-- Stop existing tracks
				for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
					track:Stop()
				end

				-- Play new track
				local animation = Instance.new("Animation")
				animation.AnimationId = BULL_ANIMATION_ID
				
				local track = animator:LoadAnimation(animation)
				track.Priority = Enum.AnimationPriority.Action
				track.Looped = false -- User requested to take off the loop
				track:Play()
				
				print("Client: Manual animation started. Length:", track.Length)

				-- MOVEMENT LOGIC: Pick random direction and move
				local rootPart = bull.PrimaryPart or bull:FindFirstChild("HumanoidRootPart") or bull:FindFirstChild("Torso") or bull:FindFirstChild("Shape")
				
				if rootPart then
					-- 1. Pick random angle (0-360 degrees)
					local randomAngle = math.rad(math.random(0, 360))
					
					-- 2. Rotate bull to face that direction immediately
					-- We keep the current position but change the rotation
					local currentPos = rootPart.Position
					rootPart.CFrame = CFrame.new(currentPos) * CFrame.Angles(0, randomAngle, 0)
					
					print("Client: Bull rotated to random angle: " .. math.deg(randomAngle))
					
					-- 2.5. Play walking animation when rotating
					local walkAnimation = Instance.new("Animation")
					walkAnimation.AnimationId = BULL_WALK_ANIMATION_ID
					local walkTrack = animator:LoadAnimation(walkAnimation)
					walkTrack.Priority = Enum.AnimationPriority.Movement
					walkTrack.Looped = true
					walkTrack:Play()
					print("Client: Walking animation started")
					
					-- 3. Move forward while animation plays
					local WALK_SPEED = 8 -- Studs per second
					local moveConnection
					
					moveConnection = RunService.Heartbeat:Connect(function(dt)
						if not track.IsPlaying then
							if moveConnection then
								moveConnection:Disconnect()
								moveConnection = nil
							end
							-- Stop walking animation when movement stops
							if walkTrack and walkTrack.IsPlaying then
								walkTrack:Stop()
								print("Client: Walking animation stopped")
							end
							return
						end
						
						-- Move forward relative to where it's facing
						rootPart.CFrame = rootPart.CFrame + (rootPart.CFrame.LookVector * WALK_SPEED * dt)
					end)
				else
					warn("Client: Could not find root part to move bull!")
				end

				-- Debug TimePosition to see if it resets
				task.spawn(function()
					local startTime = os.clock()
					while track.IsPlaying and os.clock() - startTime < 2 do
						print(string.format("Track Time: %.2f / %.2f | Speed: %.2f | Weight: %.2f", track.TimePosition, track.Length, track.Speed, track.WeightCurrent))
						task.wait(0.05)
					end
					print("Track stopped or timed out. Final Time:", track.TimePosition)
				end)
			else
				warn("Client: Bull not found in current arena")
			end
		else
			warn("Client: No active arena to play animation in")
		end
	end
end)

-- Listen for score updates
local BullScoreUpdate = RemoteEvents:WaitForChild("BullScoreUpdate", 5)
if BullScoreUpdate then
	BullScoreUpdate.OnClientEvent:Connect(function(newScore)
		if scoreLabel then
			scoreLabel.Text = tostring(newScore)
			
			-- Simple pop effect
			local originalSize = UDim2.new(1, -70, 1, 0)
			scoreLabel.Size = UDim2.new(1.2, -70, 1.2, 0)
			task.wait(0.05)
			scoreLabel.Size = originalSize
		end
	end)
else
	warn("BullTeleportUI: BullScoreUpdate RemoteEvent not found!")
end

-- Bull Health UI Logic
task.spawn(function()
	-- Initial Hide
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local bullHealthGui = playerGui:WaitForChild("BullHealth", 10)
	
	if bullHealthGui then
		bullHealthGui.Enabled = false
		print("Client: BullHealth UI found and hidden initially.")
	else
		warn("Client: BullHealth UI NOT found in PlayerGui after 10s!")
	end

	local currentBull = nil
	local healthConnection = nil
	
	-- Function to hide bull GUI (gets fresh references!)
	local function hideBullHealthUI()
		print("Client: Hiding Bull Health UI")
		-- IMPORTANT: Get fresh PlayerGui reference after respawn!
		local freshPlayerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
		if freshPlayerGui then
			local gui = freshPlayerGui:FindFirstChild("BullHealth")
			if gui then
				gui.Enabled = false
				print("Client: BullHealth hidden successfully")
			else
				print("Client: BullHealth GUI not found to hide")
			end
		end
		-- Also hide the game HUD (score, time, light widgets)
		hideGameHUD()
		if healthConnection then healthConnection:Disconnect() healthConnection = nil end
		currentBull = nil
	end
	
	-- Listen for respawn - ALWAYS hide bull GUI on respawn
	Players.LocalPlayer.CharacterAdded:Connect(function(character)
		print("Client: Player respawned - hiding bull GUI")
		
		-- Set cooldown to prevent loop from re-showing GUI
		respawnCooldown = true
		
		-- Wait for new GUI to be copied from StarterGui, then hide it
		task.wait(0.2) -- Slightly longer wait to ensure GUI is ready
		
		-- Refresh the playerGui reference for the main loop
		playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
		bullHealthGui = playerGui:FindFirstChild("BullHealth")
		if bullHealthGui then
			bullHealthGui.Enabled = false
			print("Client: Hid new BullHealth GUI after respawn")
		end
		currentBull = nil -- Reset bull tracking
		
		-- Keep cooldown active for a bit to let server clear target
		-- NOTE: Cooldown stays true until player is teleported to bull arena again
		-- This prevents the bull health UI from reappearing after death
		print("Client: Respawn cooldown active - will stay until next teleport")
		
		-- Also hide on death
		local humanoid = character:WaitForChild("Humanoid", 10)
		if humanoid then
			humanoid.Died:Connect(function()
				print("Client: Player died!")
				respawnCooldown = true -- Start cooldown early
				hideBullHealthUI()
			end)
		end
	end)
	
	-- Connect to current character if already spawned
	if Players.LocalPlayer.Character then
		local humanoid = Players.LocalPlayer.Character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.Died:Connect(function()
				print("Client: Player died!")
				respawnCooldown = true
				hideBullHealthUI()
			end)
		end
	end
	
	while true do
		task.wait(0.5)
		
		-- Skip if in respawn cooldown
		if respawnCooldown then
			continue
		end
		
		-- Re-get player reference in case of respawn
		local currentPlayer = Players.LocalPlayer
		
		-- 1. Find the Bull targeting this player
		local foundBull = nil
		for _, arena in ipairs(workspace:GetChildren()) do
			if arena.Name:match("BullArena") then
				local b = arena:FindFirstChild("bull")
				if b then
					local target = b:FindFirstChild("TargetPlayer")
					-- Check by UserId for consistency across respawns
					if target and target.Value and target.Value.UserId == currentPlayer.UserId then
						foundBull = b
						break
					end
				end
			end
		end
		
		-- 2. If bull changed or just found
		if foundBull ~= currentBull then
			if healthConnection then healthConnection:Disconnect() healthConnection = nil end
			
			-- Reset tracking
			currentBull = nil
			
			-- Refresh UI reference (gets new GUI after respawn)
			bullHealthGui = playerGui:FindFirstChild("BullHealth")
			
			if foundBull then
				print("Client: Found my bull: " .. foundBull:GetFullName())
				
				-- Wait for attributes to initialize (fallback to defaults if missing)
				local function getHealth() return foundBull:GetAttribute("Health") or 3000 end
				local function getMaxHealth() return foundBull:GetAttribute("MaxHealth") or 3000 end
				
				if bullHealthGui then
					currentBull = foundBull
					-- Try to find CanvasGroup, but fallback to Frame if not found (common structure issue)
					local canvas = bullHealthGui:FindFirstChild("CanvasGroup") or bullHealthGui:FindFirstChild("Frame")
					if not canvas then warn("Client: CanvasGroup/Frame not found in BullHealth") end
					
					-- Search recursively for TextLabel and Health bar if not found directly
					local textLabel = canvas and canvas:FindFirstChild("TextLabel")
					if not textLabel and canvas then textLabel = canvas:FindFirstChild("TextLabel", true) end
					
					local healthBar = canvas and canvas:FindFirstChild("Health")
					if not healthBar and canvas then healthBar = canvas:FindFirstChild("Health", true) end
					
					if textLabel then
						-- LOCK SIZES: Capture original size and force it to stay that way
						-- This prevents the UI from resizing/shifting when we change the text
						if textLabel.AutomaticSize ~= Enum.AutomaticSize.None then
							textLabel.AutomaticSize = Enum.AutomaticSize.None
							textLabel.Size = textLabel.Size -- Lock to current
						end
						
						-- Set nice font
						textLabel.Font = Enum.Font.LuckiestGuy
						
						if canvas and canvas.AutomaticSize ~= Enum.AutomaticSize.None then
							canvas.AutomaticSize = Enum.AutomaticSize.None
							canvas.Size = canvas.Size -- Lock to current
						end

						local function updateHealth()
							local hp = math.max(0, math.floor(getHealth()))
							local max = math.floor(getMaxHealth())
							textLabel.Text = hp .. " / " .. max
							
							-- Update Health Bar (assuming it's a fill bar)
							if healthBar then
								-- Only update the width (Scale X), preserve ALL other dimensions (Offsets and Y Scale)
								healthBar.Size = UDim2.new(hp/max, healthBar.Size.X.Offset, healthBar.Size.Y.Scale, healthBar.Size.Y.Offset)
							end
						end
						
						healthConnection = foundBull:GetAttributeChangedSignal("Health"):Connect(updateHealth)
						updateHealth() -- Initial update
						bullHealthGui.Enabled = true
						print("Client: BullHealth UI Enabled (Attribute Mode)")
					else
						warn("Client: TextLabel not found in BullHealth UI (Recursive search failed)")
						-- Debug print children
						if canvas then
							print("Children of Canvas/Frame:")
							for _, c in ipairs(canvas:GetChildren()) do print("- " .. c.Name) end
						end
					end
				else
					warn("Client: BullHealth UI missing when bull found.")
				end
			else
				-- Bull lost (game over or left), hide UI
				if bullHealthGui then
					bullHealthGui.Enabled = false
					print("Client: BullHealth UI Disabled (No bull)")
				end
			end
		end
	end
end)
