--[[
	DamageVFX.client.luau
	EPIC damage numbers with natural particle physics and RED color scheme!
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

print("[DamageVFX] Initializing EPIC effects...")
--
-- Configuration - ULTIMATE DARK RED SCHEME
local CONFIG = {
	-- Timing
	FLOAT_DURATION = 1.5,
	FADE_START = 0.6,
	
	-- Movement
	FLOAT_HEIGHT = 5,
	RANDOM_OFFSET = 1.2,
	
	-- ULTIMATE DARK BLOOD RED
	WEAK_COLOR = Color3.fromRGB(80, 20, 25),         -- Very dark muted red
	DEFAULT_COLOR = Color3.fromRGB(120, 10, 15),     -- Dark blood red
	CRIT_COLOR = Color3.fromRGB(160, 5, 10),         -- Deep crimson
	MEGA_COLOR = Color3.fromRGB(70, 0, 5),           -- Almost black blood
	HEAL_COLOR = Color3.fromRGB(50, 255, 100),       -- Green (keep for heals)
	
	-- Thresholds
	CRIT_THRESHOLD = 50,
	MEGA_THRESHOLD = 100,
	WEAK_THRESHOLD = 5,
	
	-- Font
	FONT = Enum.Font.GothamBlack,
	BASE_TEXT_SIZE = 16,
	MAX_TEXT_SIZE = 40,
	
	-- Glow - SUBTLE LAYERS, TIGHT SPREAD
	GLOW_LAYERS = 3,
	GLOW_EXPANSION = 2,
	
	-- Particles - MORE
	SPARK_COUNT = 24,
	STAR_COUNT = 12,
	RING_COUNT = 4,
	
	-- Physics
	GRAVITY = 400,
	AIR_RESISTANCE = 0.98,
	
	-- Screen shake
	SHAKE_INTENSITY = 8,
	SHAKE_DURATION = 0.25,
	
	-- Pool
	POOL_SIZE = 20,
}

-- Screen shake state
local shakeConnection = nil

-- Envelope functions
local Envelope = {}

function Envelope.Elastic(t, damping)
	damping = damping or 0.3
	if t < 0.1 then
		return (t / 0.1) * 1.3
	else
		local decay = math.exp(-(t - 0.1) * 2.5)
		local oscillation = math.cos((t - 0.1) * 12 * math.pi) * damping
		return (1 + oscillation * decay) * math.max(0, 1 - (t - 0.1) * 0.7)
	end
end

function Envelope.Punch(t, intensity)
	intensity = intensity or 1
	if t < 0.1 then
		return (t / 0.1) * (1 + intensity * 0.5)
	elseif t < 0.3 then
		return 1 + intensity * 0.5
	else
		local decay = (t - 0.3) / 0.7
		return (1 + intensity * 0.5) * (1 - decay * decay)
	end
end

function Envelope.Bounce(t, bounces)
	bounces = bounces or 3
	if t < 0.15 then
		return (t / 0.15) ^ 1.5 * 1.4
	else
		local adjustedT = (t - 0.15) / 0.85
		local bounce = math.abs(math.sin(adjustedT * math.pi * bounces))
		local decay = 1 - adjustedT
		return decay * (0.6 + 0.4 * bounce)
	end
end

-- Object pool
local indicatorPool = {}
local activeIndicators = {}

-- HSV to RGB
local function hsvToRgb(h, s, v)
	local i = math.floor(h * 6)
	local f = h * 6 - i
	local p = v * (1 - s)
	local q = v * (1 - f * s)
	local t = v * (1 - (1 - f) * s)
	i = i % 6
	if i == 0 then return Color3.new(v, t, p)
	elseif i == 1 then return Color3.new(q, v, p)
	elseif i == 2 then return Color3.new(p, v, t)
	elseif i == 3 then return Color3.new(p, q, v)
	elseif i == 4 then return Color3.new(t, p, v)
	else return Color3.new(v, p, q) end
end

-- SCREEN SHAKE
local function doScreenShake(intensity, duration)
	local startTime = tick()
	
	if shakeConnection then
		shakeConnection:Disconnect()
	end
	
	shakeConnection = RunService.RenderStepped:Connect(function()
		local elapsed = tick() - startTime
		if elapsed > duration then
			shakeConnection:Disconnect()
			shakeConnection = nil
			return
		end
		
		local progress = elapsed / duration
		local decay = 1 - progress
		local shakeX = (math.random() - 0.5) * 2 * intensity * decay
		local shakeY = (math.random() - 0.5) * 2 * intensity * decay
		
		Camera.CFrame = Camera.CFrame * CFrame.new(shakeX * 0.05, shakeY * 0.05, 0)
	end)
end

-- Create spark with physics data
local function createSpark(parent, color, size)
	local spark = Instance.new("Frame")
	spark.Size = UDim2.new(0, size, 0, size)
	spark.Position = UDim2.new(0.5, 0, 0.5, 0)
	spark.AnchorPoint = Vector2.new(0.5, 0.5)
	spark.BackgroundColor3 = color
	spark.BorderSizePixel = 0
	spark.ZIndex = 10
	spark.Parent = parent
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = spark
	
	-- Inner bright core
	local inner = Instance.new("Frame")
	inner.Size = UDim2.new(0.5, 0, 0.5, 0)
	inner.Position = UDim2.new(0.5, 0, 0.5, 0)
	inner.AnchorPoint = Vector2.new(0.5, 0.5)
	inner.BackgroundColor3 = Color3.new(1, 1, 1)
	inner.BorderSizePixel = 0
	inner.Parent = spark
	
	local innerCorner = Instance.new("UICorner")
	innerCorner.CornerRadius = UDim.new(1, 0)
	innerCorner.Parent = inner
	
	return spark
end

-- Create star
local function createStar(parent, color, size)
	local star = Instance.new("TextLabel")
	star.Size = UDim2.new(0, size * 2, 0, size * 2)
	star.Position = UDim2.new(0.5, 0, 0.5, 0)
	star.AnchorPoint = Vector2.new(0.5, 0.5)
	star.BackgroundTransparency = 1
	star.Text = "★"
	star.TextColor3 = color
	star.TextSize = size
	star.Font = Enum.Font.GothamBold
	star.ZIndex = 10
	star.Parent = parent
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(1, 0.8, 0.6)
	stroke.Thickness = 2
	stroke.Transparency = 0.3
	stroke.Parent = star
	
	return star
end

-- Create impact ring
local function createRing(parent, color, startSize)
	local ring = Instance.new("Frame")
	ring.Size = UDim2.new(0, startSize, 0, startSize)
	ring.Position = UDim2.new(0.5, 0, 0.5, 0)
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.BackgroundTransparency = 1
	ring.ZIndex = 5
	ring.Parent = parent
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = 6
	stroke.Transparency = 0
	stroke.Parent = ring
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = ring
	
	return ring, stroke
end

-- Create flash
local function createFlash(parent, color)
	local flash = Instance.new("Frame")
	flash.Size = UDim2.new(2.5, 0, 2.5, 0)
	flash.Position = UDim2.new(0.5, 0, 0.5, 0)
	flash.AnchorPoint = Vector2.new(0.5, 0.5)
	flash.BackgroundColor3 = color
	flash.BackgroundTransparency = 0.6
	flash.BorderSizePixel = 0
	flash.ZIndex = 0
	flash.Parent = parent
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = flash
	
	return flash
end

-- Create rising ember
local function createEmber(parent, color)
	local ember = Instance.new("Frame")
	ember.Size = UDim2.new(0, 6, 0, 6)
	ember.Position = UDim2.new(0.5, 0, 0.5, 0)
	ember.AnchorPoint = Vector2.new(0.5, 0.5)
	ember.BackgroundColor3 = color
	ember.BorderSizePixel = 0
	ember.ZIndex = 12
	ember.Parent = parent
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = ember
	
	return ember
end

-- Create slash mark
local function createSlash(parent, color, length, angle)
	local slash = Instance.new("Frame")
	slash.Size = UDim2.new(0, length, 0, 3)
	slash.Position = UDim2.new(0.5, 0, 0.5, 0)
	slash.AnchorPoint = Vector2.new(0.5, 0.5)
	slash.BackgroundColor3 = color
	slash.BorderSizePixel = 0
	slash.Rotation = angle
	slash.ZIndex = 4
	slash.Parent = parent
	
	local gradient = Instance.new("UIGradient")
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.3, 0),
		NumberSequenceKeypoint.new(0.7, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	gradient.Parent = slash
	
	return slash
end

-- Create impact cross burst
local function createImpactBurst(parent, color)
	local burst = Instance.new("Frame")
	burst.Size = UDim2.new(0, 80, 0, 80)
	burst.Position = UDim2.new(0.5, 0, 0.5, 0)
	burst.AnchorPoint = Vector2.new(0.5, 0.5)
	burst.BackgroundTransparency = 1
	burst.ZIndex = 3
	burst.Parent = parent
	
	-- Create X pattern
	for i = 1, 4 do
		local line = Instance.new("Frame")
		line.Size = UDim2.new(0, 60, 0, 4)
		line.Position = UDim2.new(0.5, 0, 0.5, 0)
		line.AnchorPoint = Vector2.new(0.5, 0.5)
		line.BackgroundColor3 = color
		line.BorderSizePixel = 0
		line.Rotation = 45 + (i - 1) * 90
		line.Parent = burst
		
		local grad = Instance.new("UIGradient")
		grad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.4, 0),
			NumberSequenceKeypoint.new(0.6, 0),
			NumberSequenceKeypoint.new(1, 1),
		})
		grad.Parent = line
	end
	
	return burst
end

local function createIndicator()
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "DamageIndicator"
	billboard.Size = UDim2.new(0, 400, 0, 200)
	billboard.StudsOffset = Vector3.new(0, 0, 0)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.MaxDistance = 3000
	
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundTransparency = 1
	container.Parent = billboard
	
	-- Effects container
	local effects = Instance.new("Frame")
	effects.Name = "Effects"
	effects.Size = UDim2.new(1, 0, 1, 0)
	effects.BackgroundTransparency = 1
	effects.ZIndex = 0
	effects.Parent = container
	
	-- ULTIMATE DARK RED GLOW - 7 LAYERS for maximum impact
	local glowColors = {
		Color3.fromRGB(40, 0, 0),         -- Layer 7 - Near black outer
		Color3.fromRGB(60, 0, 0),         -- Layer 6 - Very dark red
		Color3.fromRGB(90, 0, 0),         -- Layer 5 - Dark blood red
		Color3.fromRGB(130, 0, 5),        -- Layer 4 - Blood red
		Color3.fromRGB(180, 0, 10),       -- Layer 3 - Deep red
		Color3.fromRGB(220, 10, 20),      -- Layer 2 - Crimson
		Color3.fromRGB(255, 40, 50),      -- Layer 1 - Bright red core
	}
	
	for i = CONFIG.GLOW_LAYERS, 1, -1 do
		local glow = Instance.new("TextLabel")
		glow.Name = "Glow" .. i
		local expansion = CONFIG.GLOW_EXPANSION * i
		glow.Size = UDim2.new(1, expansion * 2, 1, expansion * 2)
		glow.Position = UDim2.new(0.5, 0, 0.5, 0)
		glow.AnchorPoint = Vector2.new(0.5, 0.5)
		glow.BackgroundTransparency = 1
		glow.Text = ""
		glow.TextColor3 = glowColors[i] or Color3.fromRGB(150, 0, 0)
		glow.TextTransparency = 0.1 + (i * 0.08)
		glow.Font = CONFIG.FONT
		glow.TextSize = CONFIG.BASE_TEXT_SIZE
		glow.ZIndex = i
		glow.Parent = container
	end
	
	-- DOUBLE SHADOW for extra depth
	local shadow2 = Instance.new("TextLabel")
	shadow2.Name = "Shadow2"
	shadow2.Size = UDim2.new(1, 0, 1, 0)
	shadow2.Position = UDim2.new(0.5, 2, 0.5, 2)
	shadow2.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow2.BackgroundTransparency = 1
	shadow2.Text = ""
	shadow2.TextColor3 = Color3.new(0, 0, 0)
	shadow2.TextTransparency = 0.3
	shadow2.Font = CONFIG.FONT
	shadow2.TextSize = CONFIG.BASE_TEXT_SIZE
	shadow2.ZIndex = CONFIG.GLOW_LAYERS + 1
	shadow2.Parent = container
	
	local shadow = Instance.new("TextLabel")
	shadow.Name = "Shadow"
	shadow.Size = UDim2.new(1, 0, 1, 0)
	shadow.Position = UDim2.new(0.5, 1, 0.5, 1)
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.BackgroundTransparency = 1
	shadow.Text = ""
	shadow.TextColor3 = Color3.new(0, 0, 0)
	shadow.TextTransparency = 0
	shadow.Font = CONFIG.FONT
	shadow.TextSize = CONFIG.BASE_TEXT_SIZE
	shadow.ZIndex = CONFIG.GLOW_LAYERS + 2
	shadow.Parent = container
	
	-- INNER BRIGHT CORE - makes text pop
	local innerCore = Instance.new("TextLabel")
	innerCore.Name = "InnerCore"
	innerCore.Size = UDim2.new(1, 0, 1, 0)
	innerCore.Position = UDim2.new(0.5, 0, 0.5, 0)
	innerCore.AnchorPoint = Vector2.new(0.5, 0.5)
	innerCore.BackgroundTransparency = 1
	innerCore.Text = ""
	innerCore.TextColor3 = Color3.fromRGB(255, 180, 180) -- Bright inner highlight
	innerCore.TextTransparency = 0.5
	innerCore.Font = CONFIG.FONT
	innerCore.TextSize = CONFIG.BASE_TEXT_SIZE
	innerCore.ZIndex = CONFIG.GLOW_LAYERS + 4
	innerCore.Parent = container
	
	-- Main text - DARK CRIMSON with bright highlights
	local label = Instance.new("TextLabel")
	label.Name = "DamageLabel"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.Position = UDim2.new(0.5, 0, 0.5, 0)
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.BackgroundTransparency = 1
	label.Text = ""
	label.TextColor3 = Color3.fromRGB(200, 40, 50) -- Darker crimson core
	label.Font = CONFIG.FONT
	label.TextSize = CONFIG.BASE_TEXT_SIZE
	label.ZIndex = CONFIG.GLOW_LAYERS + 3
	label.Parent = container
	
	-- Double stroke for depth
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(10, 0, 0) -- Near black outline
	stroke.Thickness = 2
	stroke.Parent = label
	
	-- Second stroke on inner core
	local innerStroke = Instance.new("UIStroke")
	innerStroke.Color = Color3.fromRGB(80, 0, 10)
	innerStroke.Thickness = 1
	innerStroke.Transparency = 0.5
	innerStroke.Parent = innerCore
	
	return billboard
end

local function initializePool()
	for i = 1, CONFIG.POOL_SIZE do
		local indicator = createIndicator()
		indicator.Enabled = false
		table.insert(indicatorPool, indicator)
	end
end

local function getIndicator()
	local indicator = table.remove(indicatorPool)
	if indicator then
		activeIndicators[indicator] = true
		return indicator
	end
	local newIndicator = createIndicator()
	activeIndicators[newIndicator] = true
	return newIndicator
end

local function returnIndicator(indicator)
	if activeIndicators[indicator] then
		activeIndicators[indicator] = nil
		indicator.Enabled = false
		indicator.Parent = nil
		local effects = indicator:FindFirstChild("Container")
		if effects then
			effects = effects:FindFirstChild("Effects")
			if effects then
				for _, child in ipairs(effects:GetChildren()) do
					child:Destroy()
				end
			end
		end
		table.insert(indicatorPool, indicator)
	end
end

-- RED COLOR SCHEME
local function getDamageColor(damage, isCrit, isHeal)
	if isHeal then return CONFIG.HEAL_COLOR end
	if damage >= CONFIG.MEGA_THRESHOLD then return CONFIG.MEGA_COLOR end
	if isCrit or damage >= CONFIG.CRIT_THRESHOLD then return CONFIG.CRIT_COLOR end
	if damage <= CONFIG.WEAK_THRESHOLD then return CONFIG.WEAK_COLOR end
	-- Gradient from light to red
	local t = math.clamp((damage - CONFIG.WEAK_THRESHOLD) / (CONFIG.CRIT_THRESHOLD - CONFIG.WEAK_THRESHOLD), 0, 1)
	return CONFIG.WEAK_COLOR:Lerp(CONFIG.CRIT_COLOR, t)
end

local function getTextSize(damage, isCrit)
	local scale = math.log10(damage + 1) / math.log10(150)
	scale = math.clamp(scale, 0, 1)
	local size = CONFIG.BASE_TEXT_SIZE + (CONFIG.MAX_TEXT_SIZE - CONFIG.BASE_TEXT_SIZE) * scale
	if isCrit or damage >= CONFIG.CRIT_THRESHOLD then size = size * 1.2 end
	if damage >= CONFIG.MEGA_THRESHOLD then size = size * 1.15 end
	return math.floor(size)
end

local function getEnvelopeType(damage, isCrit)
	if damage >= CONFIG.MEGA_THRESHOLD then return "bounce", 4
	elseif isCrit or damage >= CONFIG.CRIT_THRESHOLD then return "elastic", 0.5
	else return "punch", 0.8 end
end

-- EPIC PARTICLE EFFECTS
local function spawnNaturalEffects(container, color, damage, isCrit)
	local effects = container:FindFirstChild("Effects")
	if not effects then return end
	
	local isMega = damage >= CONFIG.MEGA_THRESHOLD
	local isBig = isCrit or damage >= CONFIG.CRIT_THRESHOLD
	
	-- IMPACT BURST (X pattern) for big hits
	if isBig then
		local burst = createImpactBurst(effects, Color3.fromRGB(255, 80, 80))
		spawn(function()
			local startTime = tick()
			local duration = 0.3
			while tick() - startTime < duration do
				local t = (tick() - startTime) / duration
				local scale = 1 + t * 2
				burst.Size = UDim2.new(0, 80 * scale, 0, 80 * scale)
				for _, line in ipairs(burst:GetChildren()) do
					if line:IsA("Frame") then
						line.BackgroundTransparency = t
					end
				end
				RunService.RenderStepped:Wait()
			end
			burst:Destroy()
		end)
	end
	
	-- SLASH MARKS for crits
	if isBig then
		local slashCount = isMega and 4 or 2
		for i = 1, slashCount do
			local angle = (math.random() - 0.5) * 60 + (i % 2 == 0 and 45 or -45)
			local slash = createSlash(effects, Color3.fromRGB(255, 60, 60), isMega and 100 or 70, angle)
			local offsetX = (math.random() - 0.5) * 40
			local offsetY = (math.random() - 0.5) * 30
			slash.Position = UDim2.new(0.5, offsetX, 0.5, offsetY)
			
			spawn(function()
				local startTime = tick()
				local duration = 0.25
				while tick() - startTime < duration do
					local t = (tick() - startTime) / duration
					slash.BackgroundTransparency = t
					slash.Size = UDim2.new(0, (isMega and 100 or 70) * (1 + t * 0.5), 0, 3 * (1 - t * 0.5))
					RunService.RenderStepped:Wait()
				end
				slash:Destroy()
			end)
		end
	end
	
	-- RISING EMBERS - float up continuously
	local emberCount = isMega and 16 or (isBig and 10 or 5)
	for i = 1, emberCount do
		task.delay(math.random() * 0.3, function()
			local ember = createEmber(effects, Color3.fromRGB(255, math.random(40, 100), math.random(20, 60)))
			local startX = (math.random() - 0.5) * 80
			local startY = (math.random() - 0.5) * 40
			ember.Position = UDim2.new(0.5, startX, 0.5, startY)
			ember.Size = UDim2.new(0, 4 + math.random() * 4, 0, 4 + math.random() * 4)
			
			local lifetime = 0.8 + math.random() * 0.6
			local startTime = tick()
			local floatSpeed = -80 - math.random() * 60
			local wobbleFreq = 4 + math.random() * 4
			local wobbleAmp = 15 + math.random() * 15
			
			while tick() - startTime < lifetime do
				local t = (tick() - startTime) / lifetime
				local elapsed = tick() - startTime
				
				local wobble = math.sin(elapsed * wobbleFreq) * wobbleAmp * (1 - t)
				local y = startY + floatSpeed * t
				
				ember.Position = UDim2.new(0.5, startX + wobble, 0.5, y)
				ember.BackgroundTransparency = t ^ 0.5
				ember.Size = UDim2.new(0, (4 + math.random() * 4) * (1 - t * 0.5), 0, (4 + math.random() * 4) * (1 - t * 0.5))
				
				-- Flicker color
				local flicker = math.random() > 0.7
				if flicker then
					ember.BackgroundColor3 = Color3.fromRGB(255, math.random(80, 150), math.random(40, 80))
				end
				
				RunService.RenderStepped:Wait()
			end
			ember:Destroy()
		end)
	end
	
	-- Impact rings with slight delay
	local ringCount = isMega and CONFIG.RING_COUNT or (isBig and 2 or 1)
	for r = 1, ringCount do
		task.delay((r - 1) * 0.06, function()
			local ring, ringStroke = createRing(effects, color, 15)
			local ringSize = isMega and 280 or (isBig and 180 or 100)
			
			local startTime = tick()
			local duration = 0.45 + r * 0.05
			local conn
			conn = RunService.RenderStepped:Connect(function()
				local t = (tick() - startTime) / duration
				if t >= 1 then
					conn:Disconnect()
					ring:Destroy()
					return
				end
				-- Ease out for natural deceleration
				local easeT = 1 - (1 - t) ^ 2.5
				local size = 15 + (ringSize - 15) * easeT
				ring.Size = UDim2.new(0, size, 0, size)
				ringStroke.Transparency = t ^ 0.7
				ringStroke.Thickness = 6 * (1 - t * 0.8)
			end)
		end)
	end
	
	-- NATURAL SPARKS with real physics
	local sparkCount = isMega and CONFIG.SPARK_COUNT * 2 or (isBig and CONFIG.SPARK_COUNT or 8)
	for i = 1, sparkCount do
		-- Random angle with slight upward bias
		local angle = math.random() * math.pi * 2
		local upwardBias = -math.pi * 0.3 -- bias upward
		angle = angle * 0.7 + upwardBias
		
		-- Random initial velocity
		local baseSpeed = isMega and 280 or (isBig and 200 or 140)
		local speed = baseSpeed * (0.6 + math.random() * 0.8)
		
		local sparkSize = isMega and 16 or (isBig and 12 or 8)
		sparkSize = sparkSize * (0.7 + math.random() * 0.6)
		
		local spark = createSpark(effects, color, sparkSize)
		
		-- Physics simulation
		spawn(function()
			local vx = math.cos(angle) * speed
			local vy = math.sin(angle) * speed
			local x, y = 0, 0
			local lifetime = 0.5 + math.random() * 0.4
			local startTime = tick()
			local drag = CONFIG.AIR_RESISTANCE - math.random() * 0.03
			local gravity = CONFIG.GRAVITY * (0.8 + math.random() * 0.4)
			local spin = (math.random() - 0.5) * 500
			
			while tick() - startTime < lifetime do
				local dt = RunService.RenderStepped:Wait()
				local t = (tick() - startTime) / lifetime
				
				-- Apply physics
				vy = vy + gravity * dt
				vx = vx * drag
				vy = vy * drag
				
				x = x + vx * dt
				y = y + vy * dt
				
				-- Update position
				spark.Position = UDim2.new(0.5, x, 0.5, y)
				
				-- Shrink and fade naturally
				local scale = (1 - t ^ 1.5)
				spark.Size = UDim2.new(0, sparkSize * scale, 0, sparkSize * scale)
				spark.BackgroundTransparency = t ^ 0.8
				spark.Rotation = spin * t
				
				-- Color fade to darker
				local fadeColor = color:Lerp(Color3.new(0.2, 0, 0), t * 0.5)
				spark.BackgroundColor3 = fadeColor
			end
			spark:Destroy()
		end)
	end
	
	-- FLOATING STARS with natural motion
	if isBig then
		local starCount = isMega and CONFIG.STAR_COUNT * 2 or CONFIG.STAR_COUNT
		for i = 1, starCount do
			local starSize = isMega and 38 or 28
			starSize = starSize + math.random() * 15
			local star = createStar(effects, color, starSize)
			
			-- Random starting position around center
			local startX = (math.random() - 0.5) * 80
			local startY = (math.random() - 0.5) * 50
			star.Position = UDim2.new(0.5, startX, 0.5, startY)
			
			spawn(function()
				local lifetime = 0.9 + math.random() * 0.5
				local startTime = tick()
				
				-- Natural floating motion parameters
				local floatSpeed = -50 - math.random() * 40
				local driftX = (math.random() - 0.5) * 30
				local wobbleFreq = 3 + math.random() * 3
				local wobbleAmp = 15 + math.random() * 10
				local rotSpeed = (math.random() - 0.5) * 300
				local phaseOffset = math.random() * math.pi * 2
				
				-- Slight initial velocity
				local vx = driftX
				local vy = floatSpeed
				local x, y = startX, startY
				
				while tick() - startTime < lifetime do
					local dt = RunService.RenderStepped:Wait()
					local t = (tick() - startTime) / lifetime
					local elapsed = tick() - startTime
					
					-- Gentle deceleration
					vx = vx * 0.98
					vy = vy * 0.995 + floatSpeed * 0.01
					
					-- Wobble motion
					local wobble = math.sin(elapsed * wobbleFreq + phaseOffset) * wobbleAmp * (1 - t)
					
					x = x + vx * dt + wobble * dt
					y = y + vy * dt
					
					star.Position = UDim2.new(0.5, x, 0.5, y)
					star.Rotation = elapsed * rotSpeed
					
					-- Fade out smoothly
					local fadeT = t ^ 1.5
					star.TextTransparency = fadeT
					star.TextSize = starSize * (1 - t * 0.25)
					
					-- Subtle color shift
					if isMega then
						local hue = (elapsed * 0.5) % 0.15 -- Stay in red-orange range
						star.TextColor3 = Color3.fromHSV(hue, 0.9, 1)
					end
				end
				star:Destroy()
			end)
		end
	end
	
	-- Screen shake
	if isBig then
		local intensity = isMega and CONFIG.SHAKE_INTENSITY * 1.5 or CONFIG.SHAKE_INTENSITY
		local duration = isMega and CONFIG.SHAKE_DURATION * 1.5 or CONFIG.SHAKE_DURATION
		doScreenShake(intensity, duration)
	end
end

-- Main animation
local function showDamageNumber(position, damage, isCrit, isHeal)
	local indicator = getIndicator()
	if not indicator then return end
	
	local container = indicator:FindFirstChild("Container")
	if not container then return end
	
	local color = getDamageColor(damage, isCrit, isHeal)
	local glowColor = color
	local h, s, v = Color3.toHSV(color)
	glowColor = Color3.fromHSV(h, math.min(s * 1.2, 1), math.min(v * 1.3, 1))
	
	local baseTextSize = getTextSize(damage, isCrit)
	local displayText = isHeal and ("+" .. tostring(damage)) or tostring(damage)
	local envelopeType, envelopeParam = getEnvelopeType(damage, isCrit)
	
	local isMega = damage >= CONFIG.MEGA_THRESHOLD
	local isBig = isCrit or damage >= CONFIG.CRIT_THRESHOLD
	
	-- Random offset
	local spreadMult = 1 + (damage / 100) * 0.3
	local offsetX = (math.random() - 0.5) * CONFIG.RANDOM_OFFSET * 2 * spreadMult
	local offsetZ = (math.random() - 0.5) * CONFIG.RANDOM_OFFSET * 2 * spreadMult
	local startOffset = Vector3.new(offsetX, 0.5, offsetZ)
	
	-- Setup elements
	local label = container:FindFirstChild("DamageLabel")
	local shadow = container:FindFirstChild("Shadow")
	local shadow2 = container:FindFirstChild("Shadow2")
	local innerCore = container:FindFirstChild("InnerCore")
	local stroke = label and label:FindFirstChild("UIStroke")
	
	if not label then return end
	
	-- SLAM ENTRANCE - start bigger
	local slamScale = isMega and 1.8 or (isBig and 1.5 or 1.3)
	local initialSize = baseTextSize * slamScale
	
	label.Text = displayText
	label.TextColor3 = Color3.fromRGB(200, 40, 50) -- Darker crimson core
	label.TextSize = initialSize
	label.TextTransparency = 0
	label.Rotation = 0
	
	if innerCore then
		innerCore.Text = displayText
		innerCore.TextSize = initialSize
		innerCore.TextTransparency = 0.4
		innerCore.TextColor3 = Color3.fromRGB(255, 180, 180)
	end
	
	if shadow then
		shadow.Text = displayText
		shadow.TextSize = initialSize
		shadow.TextTransparency = 0
	end
	
	if shadow2 then
		shadow2.Text = displayText
		shadow2.TextSize = initialSize
		shadow2.TextTransparency = 0.3
	end
	
	if stroke then
		stroke.Transparency = 0
		stroke.Thickness = math.clamp(baseTextSize / 10, 1, 2)
		stroke.Color = Color3.fromRGB(15, 0, 0) -- Near black stroke
	end
	
	-- ULTIMATE DARK RED GLOW - 7 LAYERS
	local glowColors = {
		Color3.fromRGB(40, 0, 0),         -- Layer 7 - Near black outer
		Color3.fromRGB(60, 0, 0),         -- Layer 6 - Very dark red
		Color3.fromRGB(90, 0, 0),         -- Layer 5 - Dark blood red
		Color3.fromRGB(130, 0, 5),        -- Layer 4 - Blood red
		Color3.fromRGB(180, 0, 10),       -- Layer 3 - Deep red
		Color3.fromRGB(220, 10, 20),      -- Layer 2 - Crimson
		Color3.fromRGB(255, 40, 50),      -- Layer 1 - Bright red core
	}
	
	for i = 1, CONFIG.GLOW_LAYERS do
		local glow = container:FindFirstChild("Glow" .. i)
		if glow then
			glow.Text = displayText
			glow.TextColor3 = glowColors[i] or Color3.fromRGB(150, 0, 0)
			glow.TextSize = baseTextSize + (CONFIG.GLOW_EXPANSION * i)
			glow.TextTransparency = 0.1 + (i * 0.08)
		end
	end
	
	local containerSize = math.max(300, baseTextSize * 7)
	indicator.Size = UDim2.new(0, containerSize, 0, containerSize * 0.6)
	
	local attachment = Instance.new("Attachment")
	attachment.WorldPosition = position + startOffset
	attachment.Parent = Workspace.Terrain
	
	indicator.Adornee = attachment
	indicator.StudsOffset = Vector3.new(0, 0, 0)
	indicator.Enabled = true
	indicator.Parent = Workspace
	
	-- SPAWN NATURAL EFFECTS
	spawnNaturalEffects(container, color, damage, isCrit)
	
	-- Animation
	local startTime = tick()
	local connection
	local floatHeight = CONFIG.FLOAT_HEIGHT * (1 + damage / 150)
	local duration = CONFIG.FLOAT_DURATION * (1 + damage / 300)
	local initialRotation = (math.random() - 0.5) * 20
	
	connection = RunService.RenderStepped:Connect(function()
		local elapsed = tick() - startTime
		local progress = elapsed / duration
		
		if progress >= 1 then
			connection:Disconnect()
			returnIndicator(indicator)
			attachment:Destroy()
			return
		end
		
		-- Float upward with natural deceleration
		local floatProgress = 1 - (1 - progress) ^ 2.5
		local currentHeight = floatHeight * floatProgress
		attachment.WorldPosition = position + startOffset + Vector3.new(0, currentHeight, 0)
		
		-- Scale with SLAM entrance
		local scale
		if envelopeType == "elastic" then
			scale = Envelope.Elastic(progress, envelopeParam)
		elseif envelopeType == "bounce" then
			scale = Envelope.Bounce(progress, envelopeParam)
		else
			scale = Envelope.Punch(progress, envelopeParam)
		end
		
		-- Slam down from big to normal in first 0.15s
		local slamProgress = math.min(progress / 0.1, 1)
		local slamEase = 1 - (1 - slamProgress) ^ 3
		local slamMult = slamScale - (slamScale - 1) * slamEase
		
		local currentSize = math.max(1, baseTextSize * scale * slamMult)
		label.TextSize = currentSize
		if shadow then shadow.TextSize = currentSize end
		if shadow2 then shadow2.TextSize = currentSize end
		if innerCore then innerCore.TextSize = currentSize end
		
		for i = 1, CONFIG.GLOW_LAYERS do
			local glow = container:FindFirstChild("Glow" .. i)
			if glow then
				glow.TextSize = currentSize + (CONFIG.GLOW_EXPANSION * i)
			end
		end
		
		-- Natural rotation wobble with damping
		local rotDecay = (1 - progress) ^ 1.5
		label.Rotation = initialRotation * rotDecay * math.cos(elapsed * 10)
		if shadow then shadow.Rotation = label.Rotation end
		if shadow2 then shadow2.Rotation = label.Rotation end
		if innerCore then innerCore.Rotation = label.Rotation end
		for i = 1, CONFIG.GLOW_LAYERS do
			local glow = container:FindFirstChild("Glow" .. i)
			if glow then glow.Rotation = label.Rotation end
		end
		
		-- ULTIMATE DARK RED PULSING with inner core highlight
		local pulse = (math.sin(elapsed * 10) + 1) / 2
		local flicker = (math.sin(elapsed * 22) + 1) / 2 * 0.15
		
		-- Core pulses between dark crimson and brighter red
		local coreColor = Color3.fromRGB(200, 40, 50):Lerp(Color3.fromRGB(240, 70, 80), pulse * 0.6 + flicker)
		label.TextColor3 = coreColor
		
		-- Inner core bright highlight pulses
		if innerCore then
			local innerPulse = (math.sin(elapsed * 14) + 1) / 2
			innerCore.TextColor3 = Color3.fromRGB(255, 180, 180):Lerp(Color3.fromRGB(255, 220, 220), innerPulse * 0.5)
			innerCore.TextTransparency = 0.35 + innerPulse * 0.15
		end
		
		-- 7 LAYER GLOW - all dark reds
		local glowColors = {
			Color3.fromRGB(40, 0, 0),
			Color3.fromRGB(60, 0, 0),
			Color3.fromRGB(90, 0, 0),
			Color3.fromRGB(130, 0, 5),
			Color3.fromRGB(180, 0, 10),
			Color3.fromRGB(220, 10, 20),
			Color3.fromRGB(255, 40, 50),
		}
		
		for i = 1, CONFIG.GLOW_LAYERS do
			local glow = container:FindFirstChild("Glow" .. i)
			if glow then
				local layerPulse = pulse * (1 - (i / CONFIG.GLOW_LAYERS) * 0.4)
				local brighterColor = glowColors[i]:Lerp(Color3.fromRGB(255, 60, 70), layerPulse * 0.35)
				glow.TextColor3 = brighterColor
				
				local baseAlpha = 0.1 + (i * 0.08)
				glow.TextTransparency = baseAlpha - layerPulse * 0.08
			end
		end
		
		-- Extra intensity for mega/crit
		if isMega then
			local intensePulse = (math.sin(elapsed * 16) + 1) / 2
			label.TextColor3 = coreColor:Lerp(Color3.fromRGB(255, 100, 110), intensePulse * 0.5)
			if innerCore then
				innerCore.TextColor3 = Color3.fromRGB(255, 240, 240)
				innerCore.TextTransparency = 0.2 + intensePulse * 0.2
			end
		end
		
		-- Fade out
		local fadeStart = CONFIG.FADE_START + (damage / 400)
		fadeStart = math.min(fadeStart, 0.7)
		
		if progress > fadeStart then
			local fadeProgress = (progress - fadeStart) / (1 - fadeStart)
			fadeProgress = fadeProgress ^ 1.5 -- Smooth fade
			
			label.TextTransparency = fadeProgress
			if shadow then shadow.TextTransparency = fadeProgress end
			if shadow2 then shadow2.TextTransparency = 0.3 + fadeProgress * 0.7 end
			if innerCore then innerCore.TextTransparency = 0.4 + fadeProgress * 0.6 end
			if stroke then stroke.Transparency = fadeProgress end
			
			for i = 1, CONFIG.GLOW_LAYERS do
				local glow = container:FindFirstChild("Glow" .. i)
				if glow then
					local baseAlpha = 0.1 + (i * 0.08)
					glow.TextTransparency = baseAlpha + (1 - baseAlpha) * fadeProgress
				end
			end
		end
		
		-- Natural wobble for big hits
		if isBig then
			local wobbleDecay = (1 - progress) ^ 2
			local wobbleX = math.sin(elapsed * 20) * wobbleDecay * 0.5
			local wobbleY = math.sin(elapsed * 15) * wobbleDecay * 0.35
			indicator.StudsOffset = Vector3.new(wobbleX, wobbleY, 0)
		end
	end)
end

-- Remote event
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
local DamageIndicatorEvent = RemoteEvents and RemoteEvents:WaitForChild("DamageIndicator", 10)

if DamageIndicatorEvent then
	DamageIndicatorEvent.OnClientEvent:Connect(function(position, damage, isCrit, isHeal)
		showDamageNumber(position, damage, isCrit, isHeal)
	end)
	print("[DamageVFX] Connected to DamageIndicator event")
else
	warn("[DamageVFX] DamageIndicator event not found!")
end

_G.ShowDamageNumber = function(position, damage, isCrit, isHeal)
	showDamageNumber(position, damage, isCrit or false, isHeal or false)
end

-- Abyss PvP damage numbers
do
	local AbyssPvPEvent = RemoteEvents and RemoteEvents:FindFirstChild("AbyssPvPEvent")
	if not AbyssPvPEvent then
		-- Event may not exist yet — wait briefly
		task.spawn(function()
			AbyssPvPEvent = RemoteEvents and RemoteEvents:WaitForChild("AbyssPvPEvent", 15)
			if AbyssPvPEvent then
				warn("[DamageVFX] Connected to AbyssPvPEvent (delayed)")
			end
		end)
	end
	if AbyssPvPEvent then
		warn("[DamageVFX] Connected to AbyssPvPEvent")
	end
	-- Wire up once the event is available (may have been assigned above)
	task.spawn(function()
		if not AbyssPvPEvent then
			AbyssPvPEvent = RemoteEvents and RemoteEvents:WaitForChild("AbyssPvPEvent", 20)
		end
		if not AbyssPvPEvent then
			warn("[DamageVFX] AbyssPvPEvent not found — Abyss damage numbers disabled")
			return
		end
		AbyssPvPEvent.OnClientEvent:Connect(function(action, arg1, arg2, arg3)
			-- arg layout:
			-- HitMarker  : hitType ("headshot"/"body"), damage
			-- DamageTaken: shooterName, damage, isHeadshot
			local function getLocalPos()
				local char = LocalPlayer.Character
				local hrp  = char and char:FindFirstChild("HumanoidRootPart")
				return hrp and (hrp.Position + Vector3.new(0, 4, 0)) or Vector3.new(0, 0, 0)
			end

			if action == "HitMarker" then
				-- We (shooter) dealt damage — show it near the crosshair by finding the
				-- closest other character within camera look direction.
				local damage   = tonumber(arg2) or 0
				local isCrit   = (arg1 == "headshot")
				if damage <= 0 then return end
				-- Try to find the hit player's character via a short raycast
				local cam      = Workspace.CurrentCamera
				local origin   = cam.CFrame.Position
				local dir      = cam.CFrame.LookVector * 300
				local params   = RaycastParams.new()
				local char     = LocalPlayer.Character
				if char then params.FilterDescendantsInstances = {char} end
				params.FilterType = Enum.RaycastFilterType.Exclude
				local result   = Workspace:Raycast(origin, dir, params)
				local pos      = result and result.Position or (origin + dir * 0.4)
				showDamageNumber(pos, damage, isCrit, false)

			elseif action == "DamageTaken" then
				-- We (victim) took damage — show above our own head
				local damage = tonumber(arg2) or 0
				if damage <= 0 then return end
				showDamageNumber(getLocalPos(), damage, (arg3 == true), false)
			end
		end)
	end)
end

_G.TestDamageVFX = function()
	local char = LocalPlayer.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		local pos = char.HumanoidRootPart.Position + Vector3.new(0, 3, 0)
		showDamageNumber(pos, 12, false, false)
		task.wait(0.4)
		showDamageNumber(pos + Vector3.new(2, 0, 0), 45, false, false)
		task.wait(0.4)
		showDamageNumber(pos + Vector3.new(-2, 0, 0), 75, true, false)
		task.wait(0.4)
		showDamageNumber(pos + Vector3.new(0, 0, 2), 180, true, false)
	end
end

initializePool()
print("[DamageVFX] EPIC effects ready! Use _G.TestDamageVFX() to test")