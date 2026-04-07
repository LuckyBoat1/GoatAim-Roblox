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
local SkinConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SkinConfig"))
local MythicEffects = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MythicEffects"))
local LegendaryAura = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("LegendaryAura"))
local EpicAura = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("EpicAura"))
local RareAura = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RareAura"))
local CommonAura = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CommonAura"))
local PlayerDataRF = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("PlayerDataRF")

-- Helper: convert rarity string to number (1=common, 2=rare, 3=epic, 4=legendary, 5=mythic)
local function getRarityValue(rarityStr)
	local rarityMap = {common=1, rare=2, epic=3, legendary=4, mythic=5}
	return rarityMap[(rarityStr or "common"):lower()] or 1
end

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

-- Won weapon name label (below reel, hidden until reveal)
local wonNameLabel = Instance.new("TextLabel")
wonNameLabel.Name = "WonNameLabel"
wonNameLabel.Size = UDim2.new(0.6, 0, 0, 50)
wonNameLabel.Position = UDim2.new(0.2, 0, 0.72, 0)
wonNameLabel.AnchorPoint = Vector2.new(0, 0)
wonNameLabel.BackgroundTransparency = 1
wonNameLabel.Text = ""
wonNameLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
wonNameLabel.TextSize = 32
wonNameLabel.Font = Enum.Font.FredokaOne
wonNameLabel.TextScaled = true
wonNameLabel.TextStrokeTransparency = 0
wonNameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
wonNameLabel.TextXAlignment = Enum.TextXAlignment.Center
wonNameLabel.Visible = false
wonNameLabel.ZIndex = 20
wonNameLabel.Parent = main

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

-- Viewport rotation lookup (matching Inventory setupViewport exactly, priority-resolved)
local VIEWPORT_ITEM_ROTATIONS = {
	-- test4: CFrame.Angles(90, 0, 270)
	["FN2000"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(270)),
	["Compact Nine"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(270)),
	["Alpine"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(270)),
	["Black kite"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(270)),
	-- test5: CFrame.Angles(180, 0, 90)
	["AS-VAL"] = CFrame.Angles(math.rad(180), math.rad(0), math.rad(90)),
	-- test44: CFrame.Angles(90, -90, 90)
	["Ocean Wave"] = CFrame.Angles(math.rad(90), math.rad(-90), math.rad(90)),
	["Frozen Fang"] = CFrame.Angles(math.rad(90), math.rad(-90), math.rad(90)),
	["Frost Fury"] = CFrame.Angles(math.rad(90), math.rad(-90), math.rad(90)),
	["Patriot"] = CFrame.Angles(math.rad(90), math.rad(-90), math.rad(90)),
	-- test45: CFrame.Angles(0, 90, 0)
	["Quick Exit"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	-- test46: CFrame.Angles(0, -90, 0)
	["Carpenter"] = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	-- test47: CFrame.Angles(0, 0, 270)
	["Flame"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(270)),
	-- test48: CFrame.Angles(0, -90, 0)
	["Bull Rush"] = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["Grand Strike"] = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	-- test49: CFrame.Angles(180, 0, 180)
	["Holy Fire"] = CFrame.Angles(math.rad(180), math.rad(0), math.rad(180)),
	-- test50: CFrame.Angles(0, 90, 0)
	["Viper Tooth"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Rainbow Bite"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	-- test7: CFrame.Angles(0, 0, 270) — also gets CFrame.new(0,1,0) offset (see TEST7_OFFSET_ITEMS)
	["Blizzard"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(270)),
	["Power"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(270)),
	["Ego"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(270)),
	-- test8: CFrame.Angles(0, -90, 0)
	["Blood&Bones"] = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["Cyborg"] = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["Death"] = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["Leviathan"] = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["Sun"] = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["Monster"] = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["Heat"] = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	-- test15: CFrame.Angles(90, 0, 270)
	["Thunder Bolt"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(270)),
	["Swiss Guard"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(270)),
	["Short Barrel"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(270)),
	["Pocket Blast"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(270)),
	["Makarov"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(270)),
	["L85"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(270)),
	["Soviet Classic"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(270)),
	["Elite Marksman"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(270)),
	-- test16: CFrame.Angles(90, 0, 90)
	["Pocket Mag"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(90)),
	["Tactical Boom"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(90)),
	["Marksman"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(90)),
	["Fort"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(90)),
	-- test17: CFrame.Angles(0, 0, 90)
	["Just give me my money"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	-- test18: CFrame.Angles(360, 0, -90)
	["Rocket Rain"] = CFrame.Angles(math.rad(360), math.rad(0), math.rad(-90)),
	-- test19: CFrame.Angles(-90, 0, 90)
	["Emergency Surgery"] = CFrame.Angles(math.rad(-90), math.rad(0), math.rad(90)),
	-- test20: CFrame.Angles(0, 0, 360)
	["Gangster"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(360)),
	-- Chaser: CFrame.Angles(90, 180, 90)
	["Chaser"] = CFrame.Angles(math.rad(90), math.rad(180), math.rad(90)),
	-- test21: CFrame.Angles(0, 90, 0) — blade skins
	["Retro Pixel"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Sphere Strike"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Default"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Warning Strike"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Mac Attack"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Chroma"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Prism Edge"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Cash"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Sharp"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Whity"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Sight"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Jaz"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Somber"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Cool"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Poison"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Shade"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Sugar Swag"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Walking Stick"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Butcher"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["SAPPHIRE"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["RUBY"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Sapphire"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Ruby"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	-- test22: CFrame.Angles(0, 0, -90)
	["Knife"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(-90)),
	-- test23: CFrame.Angles(0, 0, 360)
	["MP5"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(360)),
	-- test24: CFrame.Angles(-90, 0, 90)
	["Med Saw"] = CFrame.Angles(math.rad(-90), math.rad(0), math.rad(90)),
	-- test26: CFrame.Angles(90, 0, 90)
	["Classic Shot"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(90)),
	-- test27: CFrame.Angles(0, 0, -90)
	["Tactical Three"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(-90)),
	-- test28: CFrame.Angles(180, 0, 180)
	["Prototype X"] = CFrame.Angles(math.rad(180), math.rad(0), math.rad(180)),
	-- test29: CFrame.Angles(360, 180, 30)
	["Imperial"] = CFrame.Angles(math.rad(360), math.rad(180), math.rad(30)),
	-- test30: CFrame.Angles(360, 0, 90)
	["Heavy Storm"] = CFrame.Angles(math.rad(360), math.rad(0), math.rad(90)),
	-- test31: CFrame.Angles(0, -90, 0)
	["Sharp Point"] = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	-- test33: CFrame.Angles(0, 0, 270)
	["Whisper"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(270)),
	-- test34: CFrame.Angles(90, 0, -90)
	["Serpent"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(-90)),
	-- test35: CFrame.Angles(90, 0, 90)
	["Stinger"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(90)),
	-- test36: CFrame.Angles(90, 0, 90)
	["Rapid Shot"] = CFrame.Angles(math.rad(90), math.rad(0), math.rad(90)),
	-- test39: CFrame.Angles(0, 90, 0)
	["UltraZooka"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Pow"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["casoh"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Back Blast"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Bye"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Astroid"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Biggie"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Medievel Sword"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Bulky"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Grenade"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Sky Rocket"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Classic Jumper"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Freedom"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Wild Shot"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Classic Rocket"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Panic Button"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Pretty Gun"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Backup"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Rocket Launcher"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Quick Shot"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Guard"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Controller"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	["Side Arm"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(0)),
	-- test40: CFrame.Angles(0, 0, 90)
	["Cannon Ball"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	-- test41: CFrame.Angles(0, 0, 90)
	["trump"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Power Shot"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Cyan"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Sweet Strike"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Ginger Man"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Lime Shot"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Knife Box 2 Kit"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Light Beam"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Classic Gun"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Scarlet Shot"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Ocean Hunter"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Winter Crystal"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	-- test42: CFrame.Angles(0, 180, 90)
	["Raven"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Blueberry"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Snow Blaster!"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Shark Bite"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Frozen Touch"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Black Matter"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Happy Hour"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Forever Edge"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Infinite Power"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Cookie Cutter"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Spooky Edge"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Ghost Blade"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Golden Sweet"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Midnight"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Sunset Vision"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Halloween King"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Mystic Vision"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Crimson Ghost"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Blood Vision"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Buzz Cut"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Vision Blade"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Horror"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Sweet Tooth"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Cyber Strike"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	["Golden Vision"] = CFrame.Angles(math.rad(0), math.rad(180), math.rad(90)),
	-- test43: CFrame.Angles(0, 90, 180)
	["Work"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(180)),
	["Crystal Cold"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(180)),
	["Pixel"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(180)),
	["Web Weaver"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(180)),
	["Holiday Cheer"] = CFrame.Angles(math.rad(0), math.rad(90), math.rad(180)),
	-- leftRotation: CFrame.Angles(0, 0, 90)
	["Fire Touch"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Alpha Sapphire"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Copper"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Apple"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Bubble"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["BlackIron Revolver"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Cheese"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Zone"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Cube Squared"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Spoon"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Dreams of Gold"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Engraved Revolver"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Fabulous Revolver"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Neon Revolver"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Gold Revolver"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["HyperRed Revolver"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Infiltrator Revolver"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["MS Revolver"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["McDonald Revolver"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Atomic Shot"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["All Seeing"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["First Shot"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Moon Hunter"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Warp Shot"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Spectrum Six"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Thorn Blossom"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Fate Shot"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Desert Wind"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Glitter Blast"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["MVP"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Double Tap"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Laser Beam"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Liberty Six"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	["Tech Six"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
	-- testItems (test1): CFrame.Angles(0, -90, 0)
	["AK-Chaos"] = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["Sea Bone"] = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["AK-Jungle"] = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	-- test2Items: CFrame.Angles(0, -90, 0)
	["Handgun"] = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["Pyranna"] = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["Fishing Rod"] = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["Light Rifle"] = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["Hardscope"] = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["Arrow Launcher"] = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["Diamond Six"] = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["Law Bringer"] = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["Signal Blast"] = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["Wild West"] = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["Hot Shot"] = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["Stranger"] = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["Life Drain"] = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["Machine Snipe"] = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["Heavy Spin"] = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["Overheater"] = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["Fast Heal"] = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["Silent Scope"] = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	["Vacuum"] = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0)),
	-- specialY: CFrame.Angles(360, 0, 0)
	["LMG AE"] = CFrame.Angles(math.rad(360), math.rad(0), math.rad(0)),
	-- specialXZ: CFrame.Angles(0, 0, 360)
	["Enfield Bren"] = CFrame.Angles(math.rad(0), math.rad(0), math.rad(360)),
}

-- Items that get a CFrame.new(0,1,0) offset before rotation (test7 items in Inventory)
local TEST7_OFFSET_ITEMS = { ["Blizzard"] = true, ["Power"] = true, ["Ego"] = true }

-- Per-item FOV overrides matching Inventory (default 60; spear 12; goblin 65)
local VIEWPORT_ITEM_FOV = {
	["Tactical Boom"] = 65, ["Chaser"] = 60, ["Rainbow Bite"] = 65, ["Viper Tooth"] = 65,
	["Flame"] = 84, ["Ego"] = 35, ["Power"] = 35, ["Blizzard"] = 35, ["Flash"] = 43,
	["UltraZooka"] = 65, ["Hotdog"] = 65, ["Skull Basher"] = 65, ["Bye"] = 65,
	["Pow"] = 55, ["Back Blast"] = 55, ["Caveman"] = 70, ["Caveman Gone Wrong"] = 70,
	["Balanced"] = 55, ["Shovel"] = 65, ["Sky Rocket"] = 65, ["Royal Guard"] = 65,
	["Handgun"] = 55, ["Quick Shot"] = 55, ["Pretty Gun"] = 40,
	["Holy Fire"] = 65, ["Solar Staff"] = 65, ["Side Arm"] = 45, ["Lash"] = 65,
	["casoh"] = 65, ["Blood Rush"] = 65, ["Highland"] = 65, ["Astroid"] = 65,
	["Doom"] = 65, ["Twin Boom"] = 65, ["Hook"] = 65, ["Wolf Cry"] = 65,
	["Grenade"] = 65, ["Classic Jumper"] = 65, ["Cannon Ball"] = 65,
	["Wild Shot"] = 65, ["Mid"] = 65, ["Classic Rocket"] = 65,
	["Panic Button"] = 65, ["Red Jewel"] = 65, ["Fire Strike"] = 65,
	["Bone Slicer"] = 65, ["War"] = 65,
	["Ginger Man"] = 35, ["Lime Shot"] = 35, ["Classic Gun"] = 35, ["Scarlet Shot"] = 35,
	["Pixel"] = 8,
	["Blueberry"] = 25, ["Work"] = 25, ["Frozen Fang"] = 25,
	["Sunset Vision"] = 25, ["Mystic Vision"] = 25, ["Blood Vision"] = 25,
	["Vision Blade"] = 25, ["Golden Vision"] = 25,
	["Ocean Hunter"] = 50, ["Ocean Wave"] = 30, ["Cyber Strike"] = 35,
	["Spooky Edge"] = 45, ["Ghost Blade"] = 45, ["Crimson Ghost"] = 45,
	["Crystal Cold"] = 38, ["Winter Crystal"] = 38, ["Holiday Cheer"] = 38,
	["Frost Fury"] = 45, ["Carpenter"] = 42, ["Patriot"] = 42,
	["Midnight"] = 50, ["Halloween King"] = 50, ["Buzz Cut"] = 45,
	["Web Weaver"] = 40, ["Ultimate Frost"] = 45, ["Horror"] = 50,
	["Shark Bite"] = 33, ["Black Matter"] = 33, ["Happy Hour"] = 33, ["Cookie Cutter"] = 33,
	["Forever Edge"] = 53, ["Infinite Power"] = 53,
	["Snow Blaster!"] = 28, ["Golden Sweet"] = 28, ["Sweet Tooth"] = 28,
	["Raven"] = 40, ["Frozen Touch"] = 40,
}

-- setupViewport matching Inventory exactly (rotations, FOV, camera) + 50% zoom
local function setupViewport(vp, source, opts)
	opts = opts or {}

	-- Detect item type (matching Inventory logic)
	local sourceName = source and source.Name or ""
	local skinMeta = SkinConfig and SkinConfig.GetSkinMeta and SkinConfig.GetSkinMeta(sourceName) or nil

	local isMeshesSource = string.sub(sourceName, 1, 6) == "Meshes" or sourceName == "beginner's protector" or sourceName == "beginner's protector 2"
	local isWepsItem = false
	local isOtherMeshesItem = false
	if isMeshesSource then
		for _, wp in ipairs({"weps1", "weps2"}) do
			if string.find(sourceName, wp) then isWepsItem = true; break end
		end
		if not isWepsItem then isOtherMeshesItem = true end
	end

	local isGoblinItem = (string.find(sourceName, "Goblin_") ~= nil) or (skinMeta and skinMeta.isGoblin)

	-- Renamed spear items (formerly Meshes/...)
	if skinMeta and skinMeta.weapon == "Spear" and not isGoblinItem then
		isOtherMeshesItem = true
	end

	-- Camera defaults (matching Inventory)
	local fitFactor = 1.6
	local minDist = 12
	if isOtherMeshesItem then minDist = 0 end

	for _,c in ipairs(vp:GetChildren()) do c:Destroy() end
	local world = Instance.new("WorldModel"); world.Parent = vp
	local cam = Instance.new("Camera")

	-- FOV per item type (matching Inventory exactly)
	if isOtherMeshesItem then
		cam.FieldOfView = 12
	elseif isGoblinItem then
		cam.FieldOfView = 65
	else
		cam.FieldOfView = VIEWPORT_ITEM_FOV[sourceName] or 60
	end
	cam.Parent = vp; vp.CurrentCamera = cam

	if not source or not (source:IsA("Model") or source:IsA("BasePart")) then
		return nil
	end

	local clone = source:Clone()
	clone.Parent = world

	if clone:IsA("Model") then
		if not clone.PrimaryPart then for _,bp in ipairs(iterBaseParts(clone)) do clone.PrimaryPart=bp; break end end
	end
	for _,bp in ipairs(iterBaseParts(clone)) do bp.Anchored=true; bp.CanCollide=false; bp.Massless=true end

	-- Apply rotation (matching Inventory setupViewport exactly)
	local itemRotation = VIEWPORT_ITEM_ROTATIONS[sourceName]
	if itemRotation then
		-- Specific item rotation: applied relative to model's current CFrame (like Inventory)
		local offset = TEST7_OFFSET_ITEMS[sourceName] and CFrame.new(0, 1, 0) or CFrame.new()
		if clone:IsA("Model") and clone.PrimaryPart then
			clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * offset * itemRotation)
		elseif clone:IsA("BasePart") then
			clone.CFrame = clone.CFrame * offset * itemRotation
		end
	elseif isGoblinItem then
		-- Goblin fallback: 180° Z rotation (relative to current CFrame)
		local goblinRotation = CFrame.Angles(math.rad(0), math.rad(0), math.rad(180))
		if clone:IsA("Model") and clone.PrimaryPart then
			clone:SetPrimaryPartCFrame(clone.PrimaryPart.CFrame * goblinRotation)
		elseif clone:IsA("BasePart") then
			clone.CFrame = clone.CFrame * goblinRotation
		end
	elseif isOtherMeshesItem then
		-- Spear fallback: 90° X rotation (reset to origin, like Inventory)
		if clone:IsA("Model") and clone.PrimaryPart then
			clone:SetPrimaryPartCFrame(CFrame.new() * CFrame.Angles(math.rad(90), 0, 0))
		elseif clone:IsA("BasePart") then
			clone.CFrame = CFrame.new() * CFrame.Angles(math.rad(90), 0, 0)
		end
	else
		-- No rotation (reset to origin)
		if clone:IsA("Model") and clone.PrimaryPart then
			clone:SetPrimaryPartCFrame(CFrame.new())
		elseif clone:IsA("BasePart") then
			clone.CFrame = CFrame.new()
		end
	end

	-- Fit camera (matching Inventory)
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

	-- Camera distance and target (matching Inventory + 50% zoom)
	local dist, camTarget
	if isOtherMeshesItem then
		dist = span * fitFactor * 2 * 0.375 -- Spear distance (75% closer)
		camTarget = Vector3.new(center.X, max.Y - 4, center.Z) -- Look near top like Inventory small viewport
	else
		dist = math.max(minDist, span * fitFactor) * 0.375 -- Normal distance (75% closer)
		camTarget = center
	end

	local camPos = center + Vector3.new(0, 0, dist)
	cam.CFrame = CFrame.new(camPos, camTarget)

	vp.Ambient = Color3.new(0.7, 0.7, 0.7)
	vp.LightDirection = Vector3.new(-1,-1,-1)
	vp.LightColor = Color3.new(1, 1, 1)

	-- Legendary brightness boost (matching Inventory)
	local skinData = SkinConfig and SkinConfig.GetSkinMeta and SkinConfig.GetSkinMeta(sourceName)
	if skinData and skinData.rarity == "legendary" then
		vp.Ambient = Color3.new(0.9, 0.9, 0.9)
		vp.LightColor = Color3.new(0.9, 0.9, 0.9)
	end

	return clone
end

-- Create reel item with viewport (styled like Inventory slots)
local function createReelItem(itemData, index)
	local rarityColor = CrateConfig.GetRarityColor(itemData.rarity or "common")

	local itemFrame = Instance.new("Frame")
	itemFrame.Name = "Item_" .. index
	itemFrame.Size = UDim2.new(0, 190, 1, -20)
	itemFrame.Position = UDim2.new(0, 0, 0, 10)
	itemFrame.BackgroundColor3 = Color3.fromRGB(15, 20, 18)
	itemFrame.BackgroundTransparency = 0.15
	itemFrame.BorderSizePixel = 0
	itemFrame.LayoutOrder = index
	itemFrame.Visible = true
	itemFrame.Parent = reel

	local itemCorner = Instance.new("UICorner")
	itemCorner.CornerRadius = UDim.new(0, 12)
	itemCorner.Parent = itemFrame

	-- Rarity border stroke
	local rarityStroke = Instance.new("UIStroke")
	rarityStroke.Color = rarityColor
	rarityStroke.Thickness = 2
	rarityStroke.Transparency = 0.3
	rarityStroke.Parent = itemFrame

	-- Viewport container (matching Inventory viewportContainer)
	local viewportContainer = Instance.new("Frame")
	viewportContainer.Size = UDim2.new(0, 115, 0, 115)
	viewportContainer.Position = UDim2.new(0.5, 0, 0.41, 0)
	viewportContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	viewportContainer.BackgroundTransparency = 1
	viewportContainer.BorderSizePixel = 0
	viewportContainer.ZIndex = 2
	viewportContainer.Parent = itemFrame

	local vcCorner = Instance.new("UICorner")
	vcCorner.CornerRadius = UDim.new(0, 8)
	vcCorner.Parent = viewportContainer

	-- Viewport for 3D model (matching Inventory viewport size)
	local viewport = Instance.new("ViewportFrame")
	viewport.Size = UDim2.fromOffset(160, 135)
	viewport.Position = UDim2.fromScale(0.5, 0.5)
	viewport.AnchorPoint = Vector2.new(0.5, 0.5)
	viewport.BackgroundTransparency = 1
	viewport.BorderSizePixel = 0
	viewport.ZIndex = 3
	viewport.Parent = viewportContainer

	local skinLib = ReplicatedStorage:FindFirstChild("SkinLibrary")
	if skinLib then
		local skinModel = skinLib:FindFirstChild(itemData.name, true) -- recursive, matches Inventory
		if skinModel then
			setupViewport(viewport, skinModel)
		end
	end

	-- Name label (matching Inventory nameLabel style)
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -10, 0, 25)
	nameLabel.Position = UDim2.new(0.5, 0, 1, -45)
	nameLabel.AnchorPoint = Vector2.new(0.5, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.Text = itemData.name or "Unknown"
	nameLabel.TextSize = 21
	nameLabel.TextColor3 = rarityColor
	nameLabel.TextWrapped = true
	nameLabel.TextXAlignment = Enum.TextXAlignment.Center
	nameLabel.ZIndex = 10
	nameLabel.Parent = itemFrame

	-- Apply rarity aura effects (matching Inventory frames)
	local rarityValue = getRarityValue(itemData.rarity)
	if rarityValue == 5 and MythicEffects then
		MythicEffects.ApplyMythicFrameEffects(itemFrame)
	elseif rarityValue == 4 and LegendaryAura then
		LegendaryAura.ApplyLegendaryAuraEffect(itemFrame, reel)
	elseif rarityValue == 3 and EpicAura then
		EpicAura.ApplyEpicAuraEffect(itemFrame, reel)
	elseif rarityValue == 2 and RareAura then
		RareAura.ApplyRareAuraEffect(itemFrame, reel)
	elseif rarityValue == 1 and CommonAura then
		CommonAura.ApplyCommonAuraEffect(itemFrame, reel)
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
	
	-- Get the rarity this crate drops
	local crateRarity = CrateConfig.GetCrateRarity(crateType)
	
	-- Full pool from SkinConfig (used for rolling the winner server-side)
	local allSkins = CrateConfig.GetSkinsForRarity(crateRarity)

	-- Visual pool: only skins that have a model in SkinLibrary (so every reel slot shows a 3D weapon)
	local skinLib = ReplicatedStorage:FindFirstChild("SkinLibrary")
	local visualSkins = {}
	for _, entry in ipairs(allSkins) do
		if skinLib and skinLib:FindFirstChild(entry.name, true) then
			table.insert(visualSkins, entry)
		end
	end

	-- Fall back to full pool if no models found at all
	if #visualSkins == 0 then
		visualSkins = allSkins
	end

	print(string.format("[CrateOpener] %s pool: %d total, %d with models (visual)", crateRarity, #allSkins, #visualSkins))

	if #visualSkins == 0 then
		warn("No skins found for", crateType, "- cannot generate reel")
		return
	end

	-- For display: if the winning item has no model, show a substitute in the winning slot visually
	-- (the actual skin was already granted server-side before this runs)
	local winningDisplay = winningItem
	if winningItem and skinLib and not skinLib:FindFirstChild(winningItem.name, true) then
		winningDisplay = visualSkins[math.random(1, #visualSkins)]
		warn("[CrateOpener] Won skin has no model:", winningItem.name, "→ displaying", winningDisplay.name, "in reel")
	end
	if not winningDisplay then
		winningDisplay = visualSkins[math.random(1, #visualSkins)]
	end
	
	local totalItems = 50
	
	-- Generate items: winning slot uses winningDisplay, all others random from visualSkins
	for i = 1, totalItems do
		local itemData
		if i == winningPosition then
			itemData = winningDisplay
		else
			itemData = visualSkins[math.random(1, #visualSkins)]
		end
		
		createReelItem(itemData, i)
		if i <= 5 then
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
	-- Item N (1-indexed) starts at x = (N-1)*itemWidth, center is at (N-1)*itemWidth + itemWidth/2
	local finalX = -((winningPosition - 1) * itemWidth + itemWidth/2 - centerOffset)
	
	print("Final X position will be:", finalX)
	
	-- Start position (from far left for dramatic entrance)
	reel.Position = UDim2.new(0, -500, 0, 0)
	
	-- SPECTACULAR ROLLING EFFECTS DURING ANIMATION (no lightning)
	spawn(function()
		for i = 1, 8 do -- Multiple effects during roll
			wait(i * 0.5)
			_createScreenFlash()
			_createParticleBurst(UDim2.new(0.5, 0, 0.4, 0))
			
			if i % 3 == 0 then
				_createScreenShake(5)
			end
		end
	end)
	
	-- Single smooth animation - no 2-phase stop/start
	local smoothInfo = TweenInfo.new(
		5.0, -- Total duration for the full roll
		Enum.EasingStyle.Quint,
		Enum.EasingDirection.Out
	)
	
	local smoothTween = TweenService:Create(reel, smoothInfo, {
		Position = UDim2.new(0, finalX, 0, 0)
	})
	
	print("Starting smooth tween to position:", finalX)
	smoothTween:Play()
	
	smoothTween.Completed:Connect(function()
		print("Smooth tween completed!")
		
		-- ULTIMATE REVEAL SEQUENCE WITH MAXIMUM EFFECTS (no lightning)
		_createScreenFlash() -- Bright flash
		_createScreenShake(20) -- Strongest shake
		_createParticleBurst() -- Rainbow explosion
		_createEnergyWave() -- Energy blast
		
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

		-- Show won weapon name below the reel
		if wonItem then
			local rarityColor = CrateConfig.GetRarityColor(wonItem.rarity or "common")
			wonNameLabel.Text = wonItem.name
			wonNameLabel.TextColor3 = rarityColor
			wonNameLabel.Visible = true
		end
		
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
		
		print("Won item:", wonItem and wonItem.name or "(nil - already closed)")

		-- Skin was already granted right after roll. Nothing to do here.
		-- (Kept as a no-op block so future debugging is easy to add)
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
	
	-- Get the rarity this crate drops
	local crateRarity = CrateConfig.GetCrateRarity(crateType)
	
	-- Get valid skins from SkinConfig pool (full configured list, not limited to SkinLibrary models)
	local validSkins = CrateConfig.GetSkinsForRarity(crateRarity)

	-- Ensure we have valid skins
	if #validSkins == 0 then
		warn("No valid skins found in SkinConfig pool for rarity:", crateRarity)
		isOpening = false
		return
	end

	-- Roll for winning item from full SkinConfig pool
	wonItem = CrateConfig.RollCrate(crateType)
	if not wonItem then
		wonItem = validSkins[math.random(1, #validSkins)]
		print("RollCrate returned nil, picked fallback:", wonItem.name)
	end

	-- ⚑ GRANT IMMEDIATELY after rolling — synchronous so the skin is saved
	-- before the animation even starts, and certainly before close can race it.
	local _grantedItem = wonItem -- capture in local so UI cleanup can't nil it
	do
		local ok, grantResult = pcall(function()
			return PlayerDataRF:InvokeServer("AddCrateItem", {
				name = _grantedItem.name,
				rarity = _grantedItem.rarity or "common"
			})
		end)
		if ok and grantResult and grantResult.success then
			-- Server may have substituted a different valid skin; update wonItem so UI shows correct name
			if grantResult.grantedName and grantResult.grantedName ~= _grantedItem.name then
				warn("[CrateOpener] Server substituted skin:", _grantedItem.name, "->", grantResult.grantedName)
				wonItem = { name = grantResult.grantedName, rarity = _grantedItem.rarity, type = "skin" }
			end
			print("[CrateOpener] ✅ Skin granted:", grantResult.grantedName or _grantedItem.name)
		else
			warn("[CrateOpener] ❌ Failed to grant skin:", _grantedItem.name)
		end
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
	
	-- Wait for entrance tween to finish so container has final size
	entranceTween.Completed:Wait()
	task.wait(0.05) -- Let layout engine update
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
	
	wonNameLabel.Visible = false
	wonNameLabel.Text = ""
	isOpening = false
	wonItem = nil
	_currentCrateType = nil
	_G.UIMouseEnabler = false
	-- Refresh the inventory grid so the newly won skin appears immediately
	if _G.MatrixInventory and _G.MatrixInventory.Refresh then
		task.spawn(_G.MatrixInventory.Refresh)
	end
end

-- Button connections
closeBtn.MouseButton1Click:Connect(closeCrateOpener)

print("Simple CrateOpener loaded!")
