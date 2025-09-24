-- CrateOpener_WORKING.client.luau: Simple crate opening with guaranteed animation

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Import configs
local CrateConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CrateConfig"))

-- Create main GUI with enhanced background effects and screen distortion
local gui = Instance.new("ScreenGui")
gui.Name = "CrateOpener"
gui.Parent = playerGui
gui.ResetOnSpawn = false

-- Add background blur effect with animated distortion
local backgroundBlur = Instance.new("Frame")
backgroundBlur.Name = "BackgroundBlur"
backgroundBlur.Size = UDim2.new(1, 0, 1, 0)
backgroundBlur.Position = UDim2.new(0, 0, 0, 0)
backgroundBlur.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
backgroundBlur.BackgroundTransparency = 0.3
backgroundBlur.BorderSizePixel = 0
backgroundBlur.Visible = false
backgroundBlur.Parent = gui

-- Animated background vignette effect
local vignette = Instance.new("Frame")
vignette.Name = "Vignette"
vignette.Size = UDim2.new(1.2, 0, 1.2, 0)
vignette.Position = UDim2.new(-0.1, 0, -0.1, 0)
vignette.BackgroundTransparency = 1
vignette.BorderSizePixel = 0
vignette.Visible = false
vignette.Parent = gui

local vignetteGradient = Instance.new("UIGradient")
vignetteGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
	ColorSequenceKeypoint.new(0.7, Color3.fromRGB(0, 0, 0)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
}
vignetteGradient.Transparency = NumberSequence.new{
	NumberSequenceKeypoint.new(0, 0.3),
	NumberSequenceKeypoint.new(0.7, 0.9),
	NumberSequenceKeypoint.new(1, 1)
}
vignetteGradient.Parent = vignette

-- Holographic scan lines (disabled - was causing screen artifacts)
local scanLines = Instance.new("Frame")
scanLines.Name = "ScanLines"
scanLines.Size = UDim2.new(1, 0, 1, 0)
scanLines.Position = UDim2.new(0, 0, 0, 0)
scanLines.BackgroundTransparency = 1
scanLines.BorderSizePixel = 0
scanLines.Visible = false
scanLines.Parent = gui

-- Scan lines disabled to prevent visual artifacts

-- Animated background particles with multiple types
local particleFrame = Instance.new("Frame")
particleFrame.Name = "ParticleBackground"
particleFrame.Size = UDim2.new(1, 0, 1, 0)
particleFrame.Position = UDim2.new(0, 0, 0, 0)
particleFrame.BackgroundTransparency = 1
particleFrame.BorderSizePixel = 0
particleFrame.Visible = false
particleFrame.Parent = gui

-- Create floating particles with multiple colors and effects
local function _createParticle()
	local particleTypes = {
		{color = Color3.fromRGB(255, 215, 0), size = {2, 6}}, -- Gold
		{color = Color3.fromRGB(100, 255, 100), size = {1, 4}}, -- Green
		{color = Color3.fromRGB(255, 100, 255), size = {2, 5}}, -- Purple
		{color = Color3.fromRGB(100, 200, 255), size = {1, 3}}, -- Blue
	}
	
	local particleType = particleTypes[math.random(1, #particleTypes)]
	local particle = Instance.new("Frame")
	particle.Size = UDim2.new(0, math.random(particleType.size[1], particleType.size[2]), 0, math.random(particleType.size[1], particleType.size[2]))
	particle.Position = UDim2.new(math.random(), 0, 1.1, 0)
	particle.BackgroundColor3 = particleType.color
	particle.BackgroundTransparency = math.random(20, 80) / 100
	particle.BorderSizePixel = 0
	particle.Parent = particleFrame
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = particle
	
	-- Add particle glow
	local glow = Instance.new("Frame")
	glow.Size = UDim2.new(2, 0, 2, 0)
	glow.Position = UDim2.new(-0.5, 0, -0.5, 0)
	glow.BackgroundColor3 = particleType.color
	glow.BackgroundTransparency = 0.9
	glow.BorderSizePixel = 0
	glow.ZIndex = -1
	glow.Parent = particle
	
	local glowCorner = Instance.new("UICorner")
	glowCorner.CornerRadius = UDim.new(1, 0)
	glowCorner.Parent = glow
	
	-- Float animation with rotation
	local floatInfo = TweenInfo.new(
		math.random(3, 7),
		Enum.EasingStyle.Sine,
		Enum.EasingDirection.InOut
	)
	
	local floatTween = TweenService:Create(particle, floatInfo, {
		Position = UDim2.new(math.random(), 0, -0.1, 0),
		BackgroundTransparency = 1,
		Rotation = math.random(-360, 360)
	})
	
	floatTween:Play()
	floatTween.Completed:Connect(function()
		particle:Destroy()
	end)
end

-- Main frame with dramatic entrance and screen shake (enhanced color scheme)
local main = Instance.new("Frame")
main.Name = "CrateOpeningFrame"
main.Size = UDim2.new(0.85, 0, 0.7, 0)
main.Position = UDim2.new(0.075, 0, 0.15, 0)
main.BackgroundColor3 = Color3.fromRGB(45, 35, 35) -- Dark red-gray base
main.BorderSizePixel = 0
main.Visible = false
main.Parent = gui

-- Screen shake function for dramatic effects
local function createScreenShake(intensity, duration)
	local originalPosition = main.Position
	local shakeConnection
	local elapsed = 0
	
	shakeConnection = RunService.Heartbeat:Connect(function(dt)
		elapsed = elapsed + dt
		if elapsed >= duration then
			main.Position = originalPosition
			shakeConnection:Disconnect()
			return
		end
		
		local shakeX = math.random(-intensity, intensity) / 1000
		local shakeY = math.random(-intensity, intensity) / 1000
		main.Position = originalPosition + UDim2.new(0, shakeX, 0, shakeY)
	end)
end

-- Lightning effect function
local function createLightning()
	local lightning = Instance.new("Frame")
	lightning.Size = UDim2.new(0, 3, 1, 0)
	lightning.Position = UDim2.new(math.random(), 0, 0, 0)
	lightning.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	lightning.BackgroundTransparency = 0.2
	lightning.BorderSizePixel = 0
	lightning.ZIndex = 20
	lightning.Parent = main
	
	-- Lightning flash
	local flash = TweenService:Create(lightning, 
		TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{BackgroundTransparency = 1}
	)
	flash:Play()
	flash.Completed:Connect(function()
		lightning:Destroy()
	end)
end

-- Energy wave effect
local function createEnergyWave()
	local wave = Instance.new("Frame")
	wave.Size = UDim2.new(0, 10, 0, 10)
	wave.Position = UDim2.new(0.5, -5, 0.5, -5)
	wave.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
	wave.BackgroundTransparency = 0.5
	wave.BorderSizePixel = 0
	wave.ZIndex = 15
	wave.Parent = main
	
	local waveCorner = Instance.new("UICorner")
	waveCorner.CornerRadius = UDim.new(1, 0)
	waveCorner.Parent = wave
	
	-- Wave expansion
	local expandTween = TweenService:Create(wave,
		TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Size = UDim2.new(2, 0, 2, 0),
			Position = UDim2.new(-0.5, 0, -0.5, 0),
			BackgroundTransparency = 1
		}
	)
	expandTween:Play()
	expandTween.Completed:Connect(function()
		wave:Destroy()
	end)
end

-- Add multiple visual layers to main frame with holographic effects
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 20)
corner.Parent = main

-- Holographic rainbow border that cycles colors
local holoBorder = Instance.new("UIStroke")
holoBorder.Color = Color3.fromRGB(255, 0, 0)
holoBorder.Thickness = 5
holoBorder.Transparency = 0.1
holoBorder.Parent = main

-- Rainbow color cycling for holographic effect
local function _cycleRainbowColors()
	local colors = {
		Color3.fromRGB(255, 0, 0),   -- Red
		Color3.fromRGB(255, 127, 0), -- Orange
		Color3.fromRGB(255, 255, 0), -- Yellow
		Color3.fromRGB(0, 255, 0),   -- Green
		Color3.fromRGB(0, 0, 255),   -- Blue
		Color3.fromRGB(75, 0, 130),  -- Indigo
		Color3.fromRGB(148, 0, 211)  -- Violet
	}
	
	local colorIndex = 1
	return RunService.Heartbeat:Connect(function()
		local nextIndex = (colorIndex % #colors) + 1
		local tween = TweenService:Create(holoBorder, 
			TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), 
			{Color = colors[nextIndex]}
		)
		tween:Play()
		colorIndex = nextIndex
		task.wait(0.3)
	end)
end

-- Multiple outer glow layers for depth (enhanced red-themed colors)
local outerGlow1 = Instance.new("Frame")
outerGlow1.Size = UDim2.new(1, 60, 1, 60)
outerGlow1.Position = UDim2.new(0, -30, 0, -30)
outerGlow1.BackgroundColor3 = Color3.fromRGB(255, 100, 100) -- Red glow
outerGlow1.BackgroundTransparency = 0.8
outerGlow1.BorderSizePixel = 0
outerGlow1.ZIndex = -3
outerGlow1.Parent = main

local outerGlow2 = Instance.new("Frame")
outerGlow2.Size = UDim2.new(1, 40, 1, 40)
outerGlow2.Position = UDim2.new(0, -20, 0, -20)
outerGlow2.BackgroundColor3 = Color3.fromRGB(255, 150, 150) -- Light red glow
outerGlow2.BackgroundTransparency = 0.7
outerGlow2.BorderSizePixel = 0
outerGlow2.ZIndex = -2
outerGlow2.Parent = main

local outerGlow3 = Instance.new("Frame")
outerGlow3.Size = UDim2.new(1, 20, 1, 20)
outerGlow3.Position = UDim2.new(0, -10, 0, -10)
outerGlow3.BackgroundColor3 = Color3.fromRGB(255, 200, 200) -- Very light red
outerGlow3.BackgroundTransparency = 0.6
outerGlow3.BorderSizePixel = 0
outerGlow3.ZIndex = -1
outerGlow3.Parent = main

-- Apply rounded corners to all glow layers
for _, glow in pairs({outerGlow1, outerGlow2, outerGlow3}) do
	local glowCorner = Instance.new("UICorner")
	glowCorner.CornerRadius = UDim.new(0, 30)
	glowCorner.Parent = glow
end

-- Enhanced holographic gradient background with red tones
local mainGradient = Instance.new("UIGradient")
mainGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 40, 40)),   -- Dark red-gray
	ColorSequenceKeypoint.new(0.3, Color3.fromRGB(45, 35, 35)), -- Base color
	ColorSequenceKeypoint.new(0.7, Color3.fromRGB(50, 30, 30)), -- Darker red
	ColorSequenceKeypoint.new(1, Color3.fromRGB(65, 45, 45))    -- Lighter red-gray
}
mainGradient.Rotation = 45
mainGradient.Parent = main

-- Animated gradient rotation with sparkle effect
local gradientRotation = 45
local _gradientConnection = RunService.Heartbeat:Connect(function()
	gradientRotation = gradientRotation + 0.8 -- Faster rotation
	if gradientRotation >= 360 then gradientRotation = 0 end
	mainGradient.Rotation = gradientRotation
	
	-- Add random sparkle effect (functions defined later)
	if math.random() < 0.02 then -- 2% chance per frame
		-- Will be connected when functions are available
	end
	
	if math.random() < 0.01 then -- 1% chance per frame
		-- Will be connected when functions are available
	end
end)

-- Multi-layer pulsing animations with enhanced timings
local glowPulse1 = TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local glowPulse2 = TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local glowPulse3 = TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)

local _pulseGlow1 = TweenService:Create(outerGlow1, glowPulse1, {BackgroundTransparency = 0.95})
local _pulseGlow2 = TweenService:Create(outerGlow2, glowPulse2, {BackgroundTransparency = 0.9})
local _pulseGlow3 = TweenService:Create(outerGlow3, glowPulse3, {BackgroundTransparency = 0.85})

-- Enhanced title with multiple effects
local titleContainer = Instance.new("Frame")
titleContainer.Name = "TitleContainer"
titleContainer.Size = UDim2.new(1, 0, 0, 80)
titleContainer.Position = UDim2.new(0, 0, 0, 10)
titleContainer.BackgroundTransparency = 1
titleContainer.Parent = main

-- Title background glow
local titleGlow = Instance.new("Frame")
titleGlow.Size = UDim2.new(0.6, 0, 1, 0)
titleGlow.Position = UDim2.new(0.2, 0, 0, 0)
titleGlow.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
titleGlow.BackgroundTransparency = 0.8
titleGlow.BorderSizePixel = 0
titleGlow.Parent = titleContainer

local titleGlowCorner = Instance.new("UICorner")
titleGlowCorner.CornerRadius = UDim.new(0, 15)
titleGlowCorner.Parent = titleGlow

-- Main title text with premium red-themed styling
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 1, 0)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text = "★ PREMIUM WEAPON CRATE ★"
title.TextColor3 = Color3.fromRGB(255, 220, 220) -- Light red-white
title.TextSize = 34
title.Font = Enum.Font.GothamBold
title.TextStrokeTransparency = 0
title.TextStrokeColor3 = Color3.fromRGB(150, 30, 30) -- Dark red stroke
title.Parent = titleContainer

-- Title shadow with red tint
local titleShadow = Instance.new("TextLabel")
titleShadow.Name = "TitleShadow"
titleShadow.Size = title.Size
titleShadow.Position = UDim2.new(0, 3, 0, 3)
titleShadow.BackgroundTransparency = 1
titleShadow.Text = title.Text
titleShadow.TextColor3 = Color3.fromRGB(80, 20, 20) -- Dark red shadow
titleShadow.TextSize = title.TextSize
titleShadow.Font = title.Font
titleShadow.TextTransparency = 0.4
titleShadow.ZIndex = -1
titleShadow.Parent = titleContainer

-- Enhanced title pulsing animation with red theme
local titlePulse = TweenInfo.new(
	1.2, -- Faster pulse
	Enum.EasingStyle.Sine,
	Enum.EasingDirection.InOut,
	-1,
	true
)

-- PREMIUM EFFECT FUNCTIONS (defined early for use throughout)

-- Premium screen flash effect for crate opening
local function _createScreenFlash()
	local flash = Instance.new("Frame")
	flash.Name = "ScreenFlash"
	flash.Size = UDim2.new(1, 0, 1, 0)
	flash.Position = UDim2.new(0, 0, 0, 0)
	flash.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	flash.BackgroundTransparency = 1
	flash.BorderSizePixel = 0
	flash.ZIndex = 999
	flash.Parent = gui
	
	-- Intense flash sequence
	spawn(function()
		flash.BackgroundTransparency = 0.3 -- Bright flash
		wait(0.05)
		flash.BackgroundTransparency = 0.8
		wait(0.1)
		flash.BackgroundTransparency = 0.95
		wait(0.2)
		flash.BackgroundTransparency = 1
		wait(0.1)
		flash:Destroy()
	end)
end

-- Camera shake effect for dramatic impact
local function _createScreenShake(intensity)
	intensity = intensity or 10
	local camera = workspace.CurrentCamera
	local originalCFrame = camera.CFrame
	
	spawn(function()
		local shakeTime = 0
		local maxShakeTime = 0.8
		
		while shakeTime < maxShakeTime do
			shakeTime = shakeTime + 0.03
			
			local progress = shakeTime / maxShakeTime
			local shakeIntensity = intensity * (1 - progress) -- Decay over time
			local randomX = (math.random() - 0.5) * shakeIntensity
			local randomY = (math.random() - 0.5) * shakeIntensity
			local randomZ = (math.random() - 0.5) * shakeIntensity
			
			camera.CFrame = originalCFrame * CFrame.new(randomX, randomY, randomZ)
			wait(0.03)
		end
		
		camera.CFrame = originalCFrame -- Reset
	end)
end

-- Lightning effect across the screen
local function _createLightning()
	local lightning = Instance.new("Frame")
	lightning.Name = "Lightning"
	lightning.Size = UDim2.new(1, 0, 0, 4)
	lightning.Position = UDim2.new(0, 0, math.random(), 0)
	lightning.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	lightning.BackgroundTransparency = 0.2
	lightning.BorderSizePixel = 0
	lightning.ZIndex = 800
	lightning.Parent = gui
	
	-- Random lightning segments
	for i = 1, 8 do
		local segment = Instance.new("Frame")
		segment.Size = UDim2.new(0.15, 0, 0, math.random(2, 8))
		segment.Position = UDim2.new(i * 0.12, math.random(-20, 20), 0, math.random(-10, 10))
		segment.BackgroundColor3 = Color3.fromRGB(200, 220, 255)
		segment.BackgroundTransparency = 0.1
		segment.BorderSizePixel = 0
		segment.Rotation = math.random(-15, 15)
		segment.Parent = lightning
	end
	
	-- Fade out lightning
	spawn(function()
		wait(0.3)
		lightning:Destroy()
	end)
end

-- Energy wave expansion effect
local function _createEnergyWave()
	local wave = Instance.new("Frame")
	wave.Name = "EnergyWave"
	wave.Size = UDim2.new(0, 50, 0, 50)
	wave.Position = UDim2.new(0.5, -25, 0.5, -25)
	wave.BackgroundTransparency = 1
	wave.BorderSizePixel = 0
	wave.ZIndex = 700
	wave.Parent = gui
	
	local waveRing = Instance.new("UIStroke")
	waveRing.Color = Color3.fromRGB(255, 100, 100)
	waveRing.Thickness = 6
	waveRing.Transparency = 0.3
	waveRing.Parent = wave
	
	local waveCorner = Instance.new("UICorner")
	waveCorner.CornerRadius = UDim.new(1, 0)
	waveCorner.Parent = wave
	
	-- Expand and fade
	local expandTween = TweenService:Create(wave, 
		TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
		{
			Size = UDim2.new(3, 0, 3, 0),
			Position = UDim2.new(-1, 0, -1, 0)
		}
	)
	
	local fadeTween = TweenService:Create(waveRing, 
		TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
		{Transparency = 1}
	)
	
	expandTween:Play()
	fadeTween:Play()
	
	expandTween.Completed:Connect(function()
		wave:Destroy()
	end)
end

-- Rainbow particle burst effect
local function _createParticleBurst(center)
	center = center or UDim2.new(0.5, 0, 0.5, 0)
	
	for i = 1, 20 do
		local particle = Instance.new("Frame")
		particle.Size = UDim2.new(0, math.random(4, 12), 0, math.random(4, 12))
		particle.Position = center
		particle.BackgroundColor3 = Color3.fromHSV(math.random(), 1, 1)
		particle.BackgroundTransparency = 0.2
		particle.BorderSizePixel = 0
		particle.ZIndex = 600
		particle.Parent = gui
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = particle
		
		-- Random movement
		local angle = math.random() * math.pi * 2
		local distance = math.random(100, 300)
		local endX = center.X.Scale + math.cos(angle) * (distance / 1000)
		local endY = center.Y.Scale + math.sin(angle) * (distance / 1000)
		
		local moveTween = TweenService:Create(particle, 
			TweenInfo.new(math.random(1, 2), Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
			{
				Position = UDim2.new(endX, 0, endY, 0),
				Size = UDim2.new(0, 2, 0, 2),
				BackgroundTransparency = 1
			}
		)
		
		moveTween:Play()
		moveTween.Completed:Connect(function()
			particle:Destroy()
		end)
	end
end

local _titleGlowTween = TweenService:Create(titleGlow, titlePulse, {
	BackgroundTransparency = 0.95
})

-- Animation reel container with spectacular effects
local reelContainer = Instance.new("Frame")
reelContainer.Name = "ReelContainer"
reelContainer.Size = UDim2.new(0.92, 0, 0.45, 0)
reelContainer.Position = UDim2.new(0.04, 0, 0.25, 0)
reelContainer.BackgroundColor3 = Color3.fromRGB(5, 10, 15)
reelContainer.BackgroundTransparency = 0
reelContainer.BorderSizePixel = 0
reelContainer.ClipsDescendants = true
reelContainer.Visible = true
reelContainer.Parent = main

-- Multiple border layers for depth
local outerBorder = Instance.new("UIStroke")
outerBorder.Color = Color3.fromRGB(150, 200, 255)
outerBorder.Thickness = 4
outerBorder.Transparency = 0.2
outerBorder.Parent = reelContainer

local innerBorder = Instance.new("UIStroke")
innerBorder.Color = Color3.fromRGB(255, 255, 255)
innerBorder.Thickness = 2
innerBorder.Transparency = 0.6
innerBorder.Parent = reelContainer

local containerCorner = Instance.new("UICorner")
containerCorner.CornerRadius = UDim.new(0, 18)
containerCorner.Parent = reelContainer

-- Animated gradient background
local reelGradient = Instance.new("UIGradient")
reelGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 15, 25)),
	ColorSequenceKeypoint.new(0.3, Color3.fromRGB(5, 8, 12)),
	ColorSequenceKeypoint.new(0.7, Color3.fromRGB(5, 8, 12)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 15, 25))
}
reelGradient.Rotation = 0
reelGradient.Parent = reelContainer

-- Container shadow
local containerShadow = Instance.new("Frame")
containerShadow.Size = UDim2.new(1, 10, 1, 10)
containerShadow.Position = UDim2.new(0, -5, 0, 5)
containerShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
containerShadow.BackgroundTransparency = 0.7
containerShadow.BorderSizePixel = 0
containerShadow.ZIndex = -1
containerShadow.Parent = reelContainer

local shadowCorner = Instance.new("UICorner")
shadowCorner.CornerRadius = UDim.new(0, 18)
shadowCorner.Parent = containerShadow

-- Animated border pulse
local borderPulse = TweenInfo.new(
	1.8,
	Enum.EasingStyle.Sine,
	Enum.EasingDirection.InOut,
	-1,
	true
)

local _borderPulseTween = TweenService:Create(outerBorder, borderPulse, {
	Transparency = 0.7,
	Color = Color3.fromRGB(100, 255, 200)
})

-- Spectacular center selector with multiple layers
local selectorContainer = Instance.new("Frame")
selectorContainer.Name = "SelectorContainer"
selectorContainer.Size = UDim2.new(0, 50, 1, 0)
selectorContainer.Position = UDim2.new(0.5, -25, 0, 0)
selectorContainer.BackgroundTransparency = 1
selectorContainer.ZIndex = 15
selectorContainer.Parent = reelContainer

-- Outer glow (largest)
local selectorOuterGlow = Instance.new("Frame")
selectorOuterGlow.Size = UDim2.new(0, 35, 1, 0)
selectorOuterGlow.Position = UDim2.new(0.5, -17.5, 0, 0)
selectorOuterGlow.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
selectorOuterGlow.BackgroundTransparency = 0.8
selectorOuterGlow.BorderSizePixel = 0
selectorOuterGlow.ZIndex = 12
selectorOuterGlow.Parent = selectorContainer

-- Middle glow
local selectorMiddleGlow = Instance.new("Frame")
selectorMiddleGlow.Size = UDim2.new(0, 20, 1, 0)
selectorMiddleGlow.Position = UDim2.new(0.5, -10, 0, 0)
selectorMiddleGlow.BackgroundColor3 = Color3.fromRGB(255, 255, 100)
selectorMiddleGlow.BackgroundTransparency = 0.6
selectorMiddleGlow.BorderSizePixel = 0
selectorMiddleGlow.ZIndex = 13
selectorMiddleGlow.Parent = selectorContainer

-- Inner glow
local selectorInnerGlow = Instance.new("Frame")
selectorInnerGlow.Size = UDim2.new(0, 12, 1, 0)
selectorInnerGlow.Position = UDim2.new(0.5, -6, 0, 0)
selectorInnerGlow.BackgroundColor3 = Color3.fromRGB(255, 255, 200)
selectorInnerGlow.BackgroundTransparency = 0.4
selectorInnerGlow.BorderSizePixel = 0
selectorInnerGlow.ZIndex = 14
selectorInnerGlow.Parent = selectorContainer

-- Main selector line
local selector = Instance.new("Frame")
selector.Name = "Selector"
selector.Size = UDim2.new(0, 6, 1, 0)
selector.Position = UDim2.new(0.5, -3, 0, 0)
selector.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
selector.BorderSizePixel = 0
selector.ZIndex = 15
selector.Parent = selectorContainer

-- Animated particles around selector
local function _createSelectorParticle()
	local particle = Instance.new("Frame")
	particle.Size = UDim2.new(0, 3, 0, 3)
	particle.Position = UDim2.new(0.5, math.random(-15, 15), math.random(), 0)
	particle.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
	particle.BackgroundTransparency = 0.3
	particle.BorderSizePixel = 0
	particle.ZIndex = 11
	particle.Parent = selectorContainer
	
	local particleCorner = Instance.new("UICorner")
	particleCorner.CornerRadius = UDim.new(1, 0)
	particleCorner.Parent = particle
	
	-- Float and fade animation
	local floatInfo = TweenInfo.new(
		math.random(1, 3),
		Enum.EasingStyle.Sine,
		Enum.EasingDirection.Out
	)
	
	local floatTween = TweenService:Create(particle, floatInfo, {
		Position = UDim2.new(0.5, math.random(-25, 25), math.random() - 0.2, 0),
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 1, 0, 1)
	})
	
	floatTween:Play()
	floatTween.Completed:Connect(function()
		particle:Destroy()
	end)
end

-- Multi-layer pulsing animations
local selectorPulse = TweenInfo.new(
	0.8,
	Enum.EasingStyle.Sine,
	Enum.EasingDirection.InOut,
	-1,
	true
)

local _outerPulse = TweenService:Create(selectorOuterGlow, selectorPulse, {
	BackgroundTransparency = 0.95
})

local _middlePulse = TweenService:Create(selectorMiddleGlow, selectorPulse, {
	BackgroundTransparency = 0.85
})

local _innerPulse = TweenService:Create(selectorInnerGlow, selectorPulse, {
	BackgroundTransparency = 0.7
})

-- Reel frame (moves during animation) - fixed size calculation
local reel = Instance.new("Frame")
reel.Name = "Reel"
reel.Size = UDim2.new(0, 50 * 168, 1, 0) -- 50 items * 168px each
reel.Position = UDim2.new(0, 0, 0, 0)
reel.BackgroundTransparency = 1
reel.Visible = true
reel.Parent = reelContainer

-- Add layout for reel items (tighter spacing)
local reelLayout = Instance.new("UIListLayout")
reelLayout.FillDirection = Enum.FillDirection.Horizontal
reelLayout.SortOrder = Enum.SortOrder.LayoutOrder
reelLayout.Padding = UDim.new(0, 8)
reelLayout.Parent = reel

-- Enhanced close button with premium styling
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 120, 0, 50)
closeBtn.Position = UDim2.new(1, -130, 0, 10)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "✕ CLOSE"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.TextStrokeTransparency = 0.5
closeBtn.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
closeBtn.BorderSizePixel = 0
closeBtn.Parent = main

-- Close button styling
local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 12)
closeBtnCorner.Parent = closeBtn

local closeBtnStroke = Instance.new("UIStroke")
closeBtnStroke.Color = Color3.fromRGB(255, 100, 100)
closeBtnStroke.Thickness = 2
closeBtnStroke.Transparency = 0.3
closeBtnStroke.Parent = closeBtn

local closeBtnGradient = Instance.new("UIGradient")
closeBtnGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 70, 70)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 40, 40))
}
closeBtnGradient.Rotation = 90
closeBtnGradient.Parent = closeBtn

-- Close button hover effects
local closeBtnGlow = Instance.new("Frame")
closeBtnGlow.Size = UDim2.new(1, 8, 1, 8)
closeBtnGlow.Position = UDim2.new(0, -4, 0, -4)
closeBtnGlow.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
closeBtnGlow.BackgroundTransparency = 0.8
closeBtnGlow.BorderSizePixel = 0
closeBtnGlow.ZIndex = -1
closeBtnGlow.Parent = closeBtn

local closeGlowCorner = Instance.new("UICorner")
closeGlowCorner.CornerRadius = UDim.new(0, 16)
closeGlowCorner.Parent = closeBtnGlow

-- Variables
local isOpening = false
local wonItem = nil
local _currentCrateType = nil

-- Helper functions from inventory for viewports
local function iterBaseParts(root)
	local t = {}
	if root:IsA("Model") then
		for _,d in ipairs(root:GetDescendants()) do if d:IsA("BasePart") then table.insert(t,d) end end
	elseif root:IsA("BasePart") then table.insert(t, root) end
	return t
end

local function getVisualSize(part)
	local size = part.Size
	local sm = part:FindFirstChildOfClass("SpecialMesh")
	if sm then size = Vector3.new(size.X*sm.Scale.X, size.Y*sm.Scale.Y, size.Z*sm.Scale.Z) end
	return size
end

-- Exact setupViewport from inventory (enhanced with spinning and much closer zoom)
local function setupViewport(vp, source, opts)
	opts = opts or {}
	local fitFactor = opts.fitFactor or 0.6 -- Much closer zoom
	local minDist   = opts.minDist   or 5   -- Very close minimum distance

	for _,c in ipairs(vp:GetChildren()) do c:Destroy() end
	local world = Instance.new("WorldModel"); world.Parent = vp
	local cam = Instance.new("Camera"); cam.FieldOfView=70; cam.Parent=vp; vp.CurrentCamera = cam -- Even wider field of view

	if not source or not (source:IsA("Model") or source:IsA("BasePart")) then
		return nil
	end

	local clone = source:Clone()
	clone.Parent = world

	if clone:IsA("Model") then
		if not clone.PrimaryPart then for _,bp in ipairs(iterBaseParts(clone)) do clone.PrimaryPart=bp; break end end
	end
	for _,bp in ipairs(iterBaseParts(clone)) do bp.Anchored=true; bp.CanCollide=false; bp.Massless=true end
	if clone:IsA("Model") and clone.PrimaryPart then
		clone:SetPrimaryPartCFrame(CFrame.new())
	elseif clone:IsA("BasePart") then
		clone.CFrame = CFrame.new()
	end

	-- Fit camera
	local min, max = Vector3.new(1e9,1e9,1e9), Vector3.new(-1e9,-1e9,-1e9)
	for _,bp in ipairs(iterBaseParts(clone)) do
		local s=getVisualSize(bp); local cf=bp.CFrame; local h=s*0.5
		local corners = {
			cf*CFrame.new(-h.X,-h.Y,-h.Z), cf*CFrame.new(h.X,-h.Y,-h.Z),
			cf*CFrame.new(-h.X,h.Y,-h.Z),  cf*CFrame.new(h.X,h.Y,-h.Z),
			cf*CFrame.new(-h.X,-h.Y,h.Z),  cf*CFrame.new(h.X,-h.Y,h.Z),
			cf*CFrame.new(-h.X,h.Y,h.Z),   cf*CFrame.new(h.X,h.Y,h.Z),
		}
		for _,c in ipairs(corners) do
			local p=c.Position
			min = Vector3.new(math.min(min.X,p.X), math.min(min.Y,p.Y), math.min(min.Z,p.Z))
			max = Vector3.new(math.max(max.X,p.X), math.max(max.Y,p.Y), math.max(max.Z,p.Z))
		end
	end
	local center=(min+max)/2
	local span = (max-min).Magnitude
	local dist = math.max(minDist, span*fitFactor)
	local camPos = center + Vector3.new(0,0,dist)
	cam.CFrame = CFrame.new(camPos, center)
	vp.Ambient = Color3.new(0.7,0.7,0.7) -- Very bright lighting
	vp.LightDirection = Vector3.new(-1,-1,-1)
	vp.LightColor = Color3.new(1, 1, 1) -- Bright white light

	-- Add spinning animation to the model - ensure it works with RunService
	local connection
	if clone:IsA("Model") and clone.PrimaryPart then
		local startTime = tick()
		connection = game:GetService("RunService").Heartbeat:Connect(function()
			local elapsed = tick() - startTime
			local rotation = (elapsed * 90) % 360 -- 90 degrees per second (4 second full rotation)
			clone:SetPrimaryPartCFrame(CFrame.new() * CFrame.Angles(0, math.rad(rotation), 0))
		end)
	elseif clone:IsA("BasePart") then
		local startTime = tick()
		connection = game:GetService("RunService").Heartbeat:Connect(function()
			local elapsed = tick() - startTime
			local rotation = (elapsed * 90) % 360 -- 90 degrees per second (4 second full rotation)
			clone.CFrame = CFrame.new() * CFrame.Angles(0, math.rad(rotation), 0)
		end)
	end

	return clone, connection
end

-- Create reel item with viewport (enhanced styling and spinning items)
local function createReelItem(itemData, index)
	local itemFrame = Instance.new("Frame")
	itemFrame.Name = "Item_" .. index
	itemFrame.Size = UDim2.new(0, 190, 1, -20) -- Wider for name display
	itemFrame.Position = UDim2.new(0, 0, 0, 10)
	itemFrame.BackgroundColor3 = Color3.fromRGB(25, 30, 35)
	itemFrame.BorderSizePixel = 0
	itemFrame.LayoutOrder = index
	itemFrame.Visible = true
	itemFrame.Parent = reel

	-- Enhanced rarity border with gradient
	local rarityStroke = Instance.new("UIStroke")
	rarityStroke.Color = CrateConfig.GetRarityColor(itemData.rarity or "common")
	rarityStroke.Thickness = 4
	rarityStroke.Transparency = 0.1
	rarityStroke.Parent = itemFrame

	local itemCorner = Instance.new("UICorner")
	itemCorner.CornerRadius = UDim.new(0, 12)
	itemCorner.Parent = itemFrame

	-- Add inner glow effect
	local innerGlow = Instance.new("Frame")
	innerGlow.Size = UDim2.new(1, -6, 1, -6)
	innerGlow.Position = UDim2.new(0, 3, 0, 3)
	innerGlow.BackgroundColor3 = CrateConfig.GetRarityColor(itemData.rarity or "common")
	innerGlow.BackgroundTransparency = 0.85
	innerGlow.BorderSizePixel = 0
	innerGlow.ZIndex = -1
	innerGlow.Parent = itemFrame
	
	local glowCorner = Instance.new("UICorner")
	glowCorner.CornerRadius = UDim.new(0, 10)
	glowCorner.Parent = innerGlow

	-- Try to create viewport with 3D model (enhanced with spinning)
	local skinLib = ReplicatedStorage:FindFirstChild("SkinLibrary")
	if skinLib then
		local skinModel = skinLib:FindFirstChild(itemData.name)
		if skinModel then
			-- Create viewport for 3D model (70% of frame)
			local viewport = Instance.new("ViewportFrame")
			viewport.Size = UDim2.new(1, -10, 0.65, 0) -- 65% height for 3D model
			viewport.Position = UDim2.new(0, 5, 0, 5)
			viewport.BackgroundTransparency = 1
			viewport.BorderSizePixel = 0
			viewport.Parent = itemFrame

			-- Setup viewport with spinning 3D model and very close zoom
			local _clone, _connection = setupViewport(viewport, skinModel, {fitFactor = 0.6, minDist = 5})
			
			-- Add subtle background effect to viewport
			local viewportBg = Instance.new("Frame")
			viewportBg.Size = UDim2.new(1, 0, 1, 0)
			viewportBg.Position = UDim2.new(0, 0, 0, 0)
			viewportBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			viewportBg.BackgroundTransparency = 0.7
			viewportBg.BorderSizePixel = 0
			viewportBg.ZIndex = -2
			viewportBg.Parent = viewport
			
			local bgCorner = Instance.new("UICorner")
			bgCorner.CornerRadius = UDim.new(0, 8)
			bgCorner.Parent = viewportBg

			-- Item name container (35% of frame at bottom)
			local nameContainer = Instance.new("Frame")
			nameContainer.Size = UDim2.new(1, -10, 0.3, -5)
			nameContainer.Position = UDim2.new(0, 5, 0.7, 0)
			nameContainer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			nameContainer.BackgroundTransparency = 0.4
			nameContainer.BorderSizePixel = 0
			nameContainer.Parent = itemFrame

			local nameCorner = Instance.new("UICorner")
			nameCorner.CornerRadius = UDim.new(0, 6)
			nameCorner.Parent = nameContainer

			-- Rarity indicator bar
			local rarityBar = Instance.new("Frame")
			rarityBar.Size = UDim2.new(1, 0, 0, 3)
			rarityBar.Position = UDim2.new(0, 0, 0, 0)
			rarityBar.BackgroundColor3 = CrateConfig.GetRarityColor(itemData.rarity or "common")
			rarityBar.BorderSizePixel = 0
			rarityBar.Parent = nameContainer

			-- Item name label with premium styling
			local itemNameLabel = Instance.new("TextLabel")
			itemNameLabel.Size = UDim2.new(1, -8, 1, -8)
			itemNameLabel.Position = UDim2.new(0, 4, 0, 4)
			itemNameLabel.BackgroundTransparency = 1
			itemNameLabel.Text = itemData.name or "Unknown"
			itemNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			itemNameLabel.TextSize = 11
			itemNameLabel.Font = Enum.Font.GothamBold
			itemNameLabel.TextScaled = true
			itemNameLabel.TextStrokeTransparency = 0.2
			itemNameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
			itemNameLabel.TextWrapped = true
			itemNameLabel.Parent = nameContainer

			-- Name glow effect
			local nameShadow = Instance.new("TextLabel")
			nameShadow.Size = itemNameLabel.Size
			nameShadow.Position = UDim2.new(0, 1, 0, 1)
			nameShadow.BackgroundTransparency = 1
			nameShadow.Text = itemNameLabel.Text
			nameShadow.TextColor3 = CrateConfig.GetRarityColor(itemData.rarity or "common")
			nameShadow.TextSize = itemNameLabel.TextSize
			nameShadow.Font = itemNameLabel.Font
			nameShadow.TextScaled = true
			nameShadow.TextTransparency = 0.7
			nameShadow.TextWrapped = true
			nameShadow.ZIndex = -1
			nameShadow.Parent = nameContainer
		else
			-- Fallback: Enhanced text label if no model found
			local itemLabel = Instance.new("TextLabel")
			itemLabel.Size = UDim2.new(0.9, 0, 0.9, 0)
			itemLabel.Position = UDim2.new(0.05, 0, 0.05, 0)
			itemLabel.BackgroundTransparency = 1
			itemLabel.Text = itemData.name or "Unknown"
			itemLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			itemLabel.TextScaled = true
			itemLabel.Font = Enum.Font.GothamBold
			itemLabel.TextStrokeTransparency = 0.5
			itemLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
			itemLabel.Parent = itemFrame
		end
	else
		-- Fallback: Enhanced text label if no SkinLibrary
		local itemLabel = Instance.new("TextLabel")
		itemLabel.Size = UDim2.new(0.9, 0, 0.9, 0)
		itemLabel.Position = UDim2.new(0.05, 0, 0.05, 0)
		itemLabel.BackgroundTransparency = 1
		itemLabel.Text = itemData.name or "Unknown"
		itemLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		itemLabel.TextScaled = true
		itemLabel.Font = Enum.Font.GothamBold
		itemLabel.TextStrokeTransparency = 0.5
		itemLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		itemLabel.Parent = itemFrame
	end
	
	return itemFrame
end

-- Generate reel items (only use real skins from SkinLibrary)
local function generateReelItems(crateType, winningItem, winningPosition)
	print("generateReelItems called with:", crateType, winningItem, winningPosition)
	
	-- Clear existing items
	for _, child in pairs(reel:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	-- Get valid skins from SkinLibrary
	local validSkins = {}
	local skinLib = ReplicatedStorage:FindFirstChild("SkinLibrary")
	if skinLib then
		for _, skinModel in pairs(skinLib:GetChildren()) do
			if skinModel:IsA("Model") or skinModel:IsA("BasePart") then
				table.insert(validSkins, {
					type = "skin",
					name = skinModel.Name,
					rarity = "common" -- You can set rarity based on skin name patterns if needed
				})
			end
		end
	end
	
	print("Found", #validSkins, "valid skins in SkinLibrary")
	
	-- Ensure we have valid skins
	if #validSkins == 0 then
		warn("No valid skins found in SkinLibrary!")
		return
	end
	
	-- Validate winning item exists in SkinLibrary
	local _winningItemValid = false
	if winningItem and skinLib then
		local winningModel = skinLib:FindFirstChild(winningItem.name)
		if winningModel then
			_winningItemValid = true
		else
			-- Replace with random valid skin if winning item is fake
			winningItem = validSkins[math.random(1, #validSkins)]
			print("Winning item was fake, replaced with:", winningItem.name)
		end
	else
		-- No winning item, pick random valid one
		winningItem = validSkins[math.random(1, #validSkins)]
	end
	
	local totalItems = 50
	
	-- Generate items (only from valid skins)
	for i = 1, totalItems do
		local itemData
		if i == winningPosition then
			itemData = winningItem
		else
			-- Pick random valid skin
			itemData = validSkins[math.random(1, #validSkins)]
		end
		
		createReelItem(itemData, i)
		if i <= 5 then -- Debug first few items
			print("Created item", i, ":", itemData.name)
		end
	end
	
	print("Generated", totalItems, "total items")
end

-- Animation function with ULTIMATE ROLLING EFFECTS
local function animateReel(winningPosition)
	print("animateReel called with winning position:", winningPosition)
	
	-- ROLLING PHASE EFFECTS - Update title
	title.Text = "🔥 ROLLING LEGENDARY WEAPONS 🔥"
	titleShadow.Text = title.Text
	
	-- Screen shake and effects for rolling start
	_createScreenShake(8)
	_createEnergyWave()
	_createParticleBurst(UDim2.new(0.5, 0, 0.3, 0))
	
	local itemWidth = 198 -- Item width + padding (190 + 8)
	local containerWidth = reelContainer.AbsoluteSize.X
	local centerOffset = containerWidth / 2
	
	print("Container width:", containerWidth, "Item width:", itemWidth)
	
	-- Calculate final position to center winning item
	local finalX = -(winningPosition * itemWidth - centerOffset + itemWidth/2)
	
	print("Final X position will be:", finalX)
	
	-- Start position (from far left for dramatic entrance)
	reel.Position = UDim2.new(0, -500, 0, 0)
	
	-- SPECTACULAR ROLLING EFFECTS DURING ANIMATION
	spawn(function()
		for i = 1, 8 do -- Multiple effects during roll
			wait(i * 0.5)
			_createScreenFlash()
			_createParticleBurst(UDim2.new(0.5, 0, 0.4, 0))
			
			if i % 2 == 0 then
				_createLightning()
			end
			
			if i % 3 == 0 then
				_createScreenShake(5)
			end
		end
	end)
	
	-- Multi-stage animation for more realistic rolling
	local initialInfo = TweenInfo.new(
		3.2, -- Enhanced duration for more effects
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)
	
	-- First phase: Fast roll to near the target
	local nearTarget = finalX + itemWidth * 2 -- Overshoot a bit
	local initialTween = TweenService:Create(reel, initialInfo, {
		Position = UDim2.new(0, nearTarget, 0, 0)
	})
	
	print("Starting initial tween to position:", nearTarget)
	initialTween:Play()
	
	initialTween.Completed:Connect(function()
		print("Initial tween completed, starting final tween to:", finalX)
		
		-- Second phase: Slow down and settle on target
		local finalInfo = TweenInfo.new(
			1.8, -- Longer for more anticipation
			Enum.EasingStyle.Quart,
			Enum.EasingDirection.Out
		)
		
		local finalTween = TweenService:Create(reel, finalInfo, {
			Position = UDim2.new(0, finalX, 0, 0)
		})
		
		finalTween:Play()
		
		finalTween.Completed:Connect(function()
			print("Final tween completed!")
			
			-- ULTIMATE REVEAL SEQUENCE WITH MAXIMUM EFFECTS
			_createScreenFlash() -- Bright flash
			_createScreenShake(20) -- Strongest shake
			_createParticleBurst() -- Rainbow explosion
			_createEnergyWave() -- Energy blast
			_createLightning() -- Lightning strike
			
			-- Multiple energy waves for epic reveal
			spawn(function()
				for i = 1, 4 do
					wait(i * 0.2)
					_createEnergyWave()
				end
			end)
			
			-- Victory particle storm
			spawn(function()
				for i = 1, 10 do
					wait(i * 0.1)
					_createParticleBurst(UDim2.new(0.5, 0, 0.4, 0))
				end
			end)
			
			-- Final title update
			title.Text = "🏆 LEGENDARY WEAPON UNLOCKED! 🏆"
			titleShadow.Text = title.Text
			
			-- Enhanced final title effects
			local finalTitleTween = TweenService:Create(title, 
				TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), 
				{
					TextSize = 38,
					TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold
				}
			)
			finalTitleTween:Play()
			
			-- Highlight winning item with SPECTACULAR glow
			local winningFrame = reel:FindFirstChild("Item_" .. winningPosition)
			if winningFrame then
				print("Found winning frame, adding ULTIMATE glow effect")
				
				-- Multiple enhanced glow layers
				local outerGlow = Instance.new("Frame")
				outerGlow.Size = UDim2.new(1, 30, 1, 30) -- Bigger glow
				outerGlow.Position = UDim2.new(0.5, -15, 0.5, -15)
				outerGlow.AnchorPoint = Vector2.new(0.5, 0.5)
				outerGlow.BackgroundColor3 = Color3.fromRGB(255, 215, 0) -- Gold glow
				outerGlow.BackgroundTransparency = 0.5
				outerGlow.BorderSizePixel = 0
				outerGlow.ZIndex = -1
				outerGlow.Parent = winningFrame
				
				local middleGlow = Instance.new("Frame")
				middleGlow.Size = UDim2.new(1, 20, 1, 20)
				middleGlow.Position = UDim2.new(0.5, -10, 0.5, -10)
				middleGlow.AnchorPoint = Vector2.new(0.5, 0.5)
				middleGlow.BackgroundColor3 = Color3.fromRGB(255, 255, 100) -- Bright yellow
				middleGlow.BackgroundTransparency = 0.3
				middleGlow.BorderSizePixel = 0
				middleGlow.ZIndex = -1
				middleGlow.Parent = winningFrame
				
				local innerGlow = Instance.new("Frame")
				innerGlow.Size = UDim2.new(1, 8, 1, 8)
				innerGlow.Position = UDim2.new(0.5, -4, 0.5, -4)
				innerGlow.AnchorPoint = Vector2.new(0.5, 0.5)
				innerGlow.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Pure white core
				innerGlow.BackgroundTransparency = 0.2
				innerGlow.BorderSizePixel = 0
				innerGlow.ZIndex = -1
				innerGlow.Parent = winningFrame
				
				-- Rounded corners for all glows
				for _, glow in pairs({outerGlow, middleGlow, innerGlow}) do
					local corner = Instance.new("UICorner")
					corner.CornerRadius = UDim.new(0, 20)
					corner.Parent = glow
				end
				
				-- INTENSE pulsing animation for the glow
				local pulseInfo = TweenInfo.new(
					0.6, -- Faster pulse
					Enum.EasingStyle.Sine,
					Enum.EasingDirection.InOut,
					-1, -- Repeat infinitely
					true -- Reverse
				)
				
				local outerPulse = TweenService:Create(outerGlow, pulseInfo, {
					BackgroundTransparency = 0.8,
					Size = UDim2.new(1, 40, 1, 40)
				})
				local middlePulse = TweenService:Create(middleGlow, pulseInfo, {
					BackgroundTransparency = 0.7
				})
				local innerPulse = TweenService:Create(innerGlow, pulseInfo, {
					BackgroundTransparency = 0.5
				})
				
				outerPulse:Play()
				middlePulse:Play()
				innerPulse:Play()
			else
				print("Could not find winning frame with name:", "Item_" .. winningPosition)
			end
			
			print("Won item:", wonItem.name)
		end)
	end)
end

-- Open crate function with all premium effects
function _G.OpenCrate(crateType)
	if isOpening then return end
	
	_currentCrateType = crateType
	local crate = CrateConfig.GetCrate(crateType)
	if not crate then
		warn("Invalid crate type: " .. tostring(crateType))
		return
	end
	
	isOpening = true
	
	-- Get valid skins from SkinLibrary first
	local validSkins = {}
	local skinLib = ReplicatedStorage:FindFirstChild("SkinLibrary")
	if skinLib then
		for _, skinModel in pairs(skinLib:GetChildren()) do
			if skinModel:IsA("Model") or skinModel:IsA("BasePart") then
				table.insert(validSkins, {
					type = "skin",
					name = skinModel.Name,
					rarity = "common"
				})
			end
		end
	end
	
	-- Ensure we have valid skins
	if #validSkins == 0 then
		warn("No valid skins found in SkinLibrary! Cannot open crate.")
		isOpening = false
		return
	end
	
	-- Roll for winning item, but validate it exists
	wonItem = CrateConfig.RollCrate(crateType)
	if not wonItem or not skinLib or not skinLib:FindFirstChild(wonItem.name) then
		-- Pick random valid skin if rolled item is fake
		wonItem = validSkins[math.random(1, #validSkins)]
		print("Rolled item was fake, using valid skin:", wonItem.name)
	end
	
	-- Set up UI with SPECTACULAR ENTRANCE EFFECTS
	title.Text = "★ OPENING " .. string.upper(crate.name) .. " ★"
	titleShadow.Text = title.Text
	
	-- ULTIMATE ENTRANCE SEQUENCE WITH ALL EFFECTS
	_createScreenFlash() -- Intense screen flash
	_createScreenShake(15) -- Strong camera shake
	_createParticleBurst() -- Rainbow particle explosion
	
	-- Multiple energy waves for dramatic effect
	spawn(function()
		wait(0.2)
		_createEnergyWave()
		wait(0.3)
		_createEnergyWave()
		wait(0.5)
		_createEnergyWave()
	end)
	
	-- Lightning storm effect
	spawn(function()
		for i = 1, 5 do
			wait(i * 0.1)
			_createLightning()
		end
	end)
	
	-- Dramatic entrance animation
	backgroundBlur.Visible = true
	particleFrame.Visible = true
	main.Visible = true
	
	-- Start background particle system
	local particleTimer = 0
	local particleConnection = RunService.Heartbeat:Connect(function(dt)
		particleTimer = particleTimer + dt
		if particleTimer >= 0.1 then -- Create particle every 0.1 seconds
			particleTimer = 0
			_createParticle()
		end
	end)
	
	-- Start selector particle effects
	local selectorParticleTimer = 0
	local selectorParticleConnection = RunService.Heartbeat:Connect(function(dt)
		selectorParticleTimer = selectorParticleTimer + dt
		if selectorParticleTimer >= 0.3 then -- Create selector particle every 0.3 seconds
			selectorParticleTimer = 0
			_createSelectorParticle()
		end
	end)
	
	-- Start all pulsing animations
	_pulseGlow1:Play()
	_pulseGlow2:Play()
	_pulseGlow3:Play()
	_titleGlowTween:Play()
	_borderPulseTween:Play()
	_outerPulse:Play()
	_middlePulse:Play()
	_innerPulse:Play()
	
	-- Start holographic effects
	local _rainbowConnection = _cycleRainbowColors()
	
	-- Start special effects (scan lines disabled to prevent visual artifacts)
	vignette.Visible = true
	-- scanLines.Visible = true  -- Disabled - was causing weird lines on screen
	
	-- Dramatic entrance tween for main frame
	main.Size = UDim2.new(0.4, 0, 0.3, 0)
	main.Position = UDim2.new(0.3, 0, 0.35, 0)
	
	local entranceInfo = TweenInfo.new(
		0.8,
		Enum.EasingStyle.Back,
		Enum.EasingDirection.Out
	)
	
	local entranceTween = TweenService:Create(main, entranceInfo, {
		Size = UDim2.new(0.85, 0, 0.7, 0),
		Position = UDim2.new(0.075, 0, 0.15, 0)
	})
	entranceTween:Play()
	
	-- Store connections for cleanup
	_G.CrateOpenerConnections = {
		particleConnection = particleConnection,
		selectorParticleConnection = selectorParticleConnection
	}
	
	-- Enable mouse
	_G.UIMouseEnabler = true
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	player.CameraMode = Enum.CameraMode.Classic
	
	-- Generate reel and animate
	local winningPosition = math.random(20, 30)
	generateReelItems(crateType, wonItem, winningPosition)
	
	-- Start animation
	task.wait(0.1)
	animateReel(winningPosition)
end

-- Enhanced close function with cleanup
local function closeCrateOpener()
	-- Dramatic exit animation
	local exitInfo = TweenInfo.new(
		0.5,
		Enum.EasingStyle.Back,
		Enum.EasingDirection.In
	)
	
	local exitTween = TweenService:Create(main, exitInfo, {
		Size = UDim2.new(0.1, 0, 0.1, 0),
		Position = UDim2.new(0.45, 0, 0.45, 0)
	})
	
	exitTween:Play()
	exitTween.Completed:Connect(function()
		main.Visible = false
		backgroundBlur.Visible = false
		particleFrame.Visible = false
		
		-- Reset main frame size for next opening
		main.Size = UDim2.new(0.85, 0, 0.7, 0)
		main.Position = UDim2.new(0.075, 0, 0.15, 0)
	end)
	
	-- Clean up connections
	if _G.CrateOpenerConnections then
		if _G.CrateOpenerConnections.particleConnection then
			_G.CrateOpenerConnections.particleConnection:Disconnect()
		end
		if _G.CrateOpenerConnections.selectorParticleConnection then
			_G.CrateOpenerConnections.selectorParticleConnection:Disconnect()
		end
		_G.CrateOpenerConnections = nil
	end
	
	-- Clean up particles
	for _, particle in pairs(particleFrame:GetChildren()) do
		if particle:IsA("Frame") then
			particle:Destroy()
		end
	end
	
	for _, particle in pairs(selectorContainer:GetChildren()) do
		if particle.Name ~= "Selector" and particle:IsA("Frame") then
			particle:Destroy()
		end
	end
	
	isOpening = false
	wonItem = nil
	_currentCrateType = nil
	_G.UIMouseEnabler = false
end

-- Button connections
closeBtn.MouseButton1Click:Connect(closeCrateOpener)

print("Simple CrateOpener loaded!")
