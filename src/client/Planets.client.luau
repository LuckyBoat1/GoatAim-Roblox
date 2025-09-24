while not _G.MatrixQuest do task.wait(0.05) end
local MQ = _G.MatrixQuest
local C3, TweenService, clearChildren, FONT_HEADING, FONT_TEXT = MQ.C3, MQ.TweenService, MQ.clearChildren, MQ.FONT_HEADING, MQ.FONT_TEXT
local tabMissions, RunService, UserInputService = MQ.tabMissions, game:GetService("RunService"), game:GetService("UserInputService")

-- Model check
local planetFolder = game.ReplicatedStorage:FindFirstChild("Planets")
if not planetFolder then error("Missing Planets folder!") end

-- Config
local CONFIG = {
	STAR_COUNT = 85, STAR_DRIFT_SPEED = 0.002, STAR_MAX_DRIFT = 12,
	SUN_SCALE = 0.352, BLACKHOLE_SCALE = 0.75, PLANET_HOVER_SCALE = 1.15, -- Sun slightly smaller (<10% more)
	PLANET_HOVER_TWEEN = 0.2, TOOLTIP_OFFSET = Vector2.new(16, 14),
	FIREBALL_INTERVAL = 15, ASTEROID_COUNT = 8, DEPTH_EFFECT_STRENGTH = 0.8,
	LIGHT_BRIGHTNESS = 550, CAMERA_DISTANCE = 0.10, CAMERA_Y_OFFSET = 0.1,
	AUTO_SCALE_MODELS = true, CAMERA_FOV = 20, VIEWPORT_PADDING = 1.0,
	BLACKHOLE_POSITION = UDim2.fromOffset(-5, -5), -- Absolute position in top left
	SUN_ROTATION_SPEED = 0.2, BLACKHOLE_ROTATION_SPEED = 0.3,
	ORBIT_BASE_SPEED = 0.092, -- 15% faster than 0.08 rad/s
	PLANET_SIZE_SCALE = 0.9, -- 10% smaller planets
	ORBIT_RADIUS_SCALE = 1.2, -- More separation from Nova Core
	ORBIT_SPEED_EXP = 0.0, -- Uniform orbit speed for all radii
	ORBIT_REF_ORBIT = 0.40, -- Reference orbit used to normalize speed curve
	ORBIT_EDGE_MARGIN = 10, -- Extra pixels to keep planets fully on-screen
	BINARY_SPIN_SPEED = 0.7, -- Mutual spin speed for paired planets
	BLACKHOLE_CAMERA_DISTANCE_MULTIPLIER = 0.2, -- Keep zoomed in
	VIEWPORT_INIT_RETRIES = 3, -- Number of times to retry initializing viewports
	VIEWPORT_RETRY_DELAY = 0.2, -- Seconds to wait between retries
	BLACKHOLE_ABSOLUTE_SIZE = 172 -- +5% larger than 164
}

-- Planet data with sizes doubled
local planets = {
	-- Right-side binary pair: start vertically separated and pushed to the far right
		{ id="annihilator", name="ANNIHILATOR", baseColor=C3(120,110,100), glow=C3(190,180,160), emoji="💀", modelName="1", orbit=0.16, size=135, speed=1.00, status="active", orbitTilt=0.05, extraLighting=true, cluster="right", clusterCenter=0.88, clusterOrbit=0.03, binary=true, clusterPhase=math.pi/2, orbitSpeedMul=1.10,
			rightEdgeMotion = "verticalOsc", verticalRange = {0, 1}, verticalPhase = math.pi/2 }, -- top right to middle right oscillation
	{ id="rambo", name="RAMBO", baseColor=C3(180,160,120), glow=C3(255,220,180), emoji="🔫", modelName="4", orbit=0.33, size=148, speed=0.81, status="active", orbitTilt=-0.08, extraLighting=true }, -- base orbit speed
	{ id="mayhem", name="MAYHEM", baseColor=C3(80,120,180), glow=C3(120,180,255), emoji="🌍", modelName="6", orbit=0.36, size=161, speed=0.67, status="active", orbitTilt=0.03 }, -- same orbit speed as others
	{ id="warlord", name="WARLORD", baseColor=C3(140,80,60), glow=C3(200,120,100), emoji="⚔️", modelName="2", orbit=0.34, size=142, speed=0.58, status="active", orbitTilt=-0.04 }, -- slightly smaller
	{ id="marksman", name="MARKSMAN", baseColor=C3(180,150,120), glow=C3(255,200,150), emoji="🎯", modelName="Planet_Earth", orbit=0.38, size=167, speed=0.34, status="active", orbitTilt=0.07 }, -- a little closer to Nova
		{ id="inferno", name="INFERNO", baseColor=C3(200,180,140), glow=C3(255,230,180), emoji="🔥", modelName="5", orbit=0.52, size=310, speed=0.22, status="active", orbitTilt=-0.06, extraLighting=true, cluster="right", clusterCenter=0.88, clusterOrbit=0.03, binary=true, clusterPhase=-math.pi/2, orbitSpeedMul=1.10,
			rightEdgeMotion = "verticalOsc", verticalRange = {-1, 1}, verticalPhase = -math.pi/2 }, -- bottom → middle → top oscillation
	{ id="apocalypse", name="APOCALYPSE", baseColor=C3(100,150,160), glow=C3(140,200,255), emoji="☄️", modelName="7", orbit=0.40, size=150, speed=0.17, status="active", orbitTilt=0.02 }, -- bigger container
	{ id="vendetta", name="VENDETTA", baseColor=C3(60,80,160), glow=C3(100,140,255), emoji="⚡", modelName="3", orbit=0.37, size=160, speed=0.14, status="active", orbitTilt=-0.05 }, -- closer than Apocalypse
}

-- Mission data
local missionsById = {
	annihilator = { title="ANNIHILATOR Challenges", desc="Prove your destructive capabilities in the ultimate combat trials." },
	rambo = { title="RAMBO Operations", desc="Execute high-intensity warfare scenarios with precision and brutality." },
	mayhem = { title="MAYHEM Protocol", desc="Unleash chaos and destruction across multiple combat zones." },
	warlord = { title="WARLORD Command", desc="Lead devastating assault operations and dominate the battlefield." },
	marksman = { title="MARKSMAN Trials", desc="Demonstrate elite precision and accuracy in long-range engagements." },
	inferno = { title="INFERNO Protocol", desc="Bring fire and destruction to enemy positions with explosive force." },
	apocalypse = { title="APOCALYPSE Event", desc="Participate in world-ending scenarios and survive the ultimate test." },
	vendetta = { title="VENDETTA Campaign", desc="Execute personal vengeance missions against high-value targets." },
}

-- Clear previous UI and set up helper functions
clearChildren(tabMissions, true)
local function tween(obj, ti, props) local t = TweenService:Create(obj, ti, props); t:Play(); return t end
local function makeCircle(parent, size, color, z)
	local f = Instance.new("Frame")
	f.Size, f.BackgroundColor3, f.BackgroundTransparency = size, color, 0
	f.BorderSizePixel, f.ZIndex, f.Parent = 0, z or 1, parent
	local corner = Instance.new("UICorner", f)
	corner.CornerRadius = UDim.new(1, 0)
	return f
end

-- Reliable 3D model function with improved initialization
local function create3DPlanet(parent, modelName, size, z, objectInfo, customRotSpeed)
	-- Create ViewportFrame
	local viewport = Instance.new("ViewportFrame")
	viewport.Size = size
	viewport.BackgroundTransparency = 1
	viewport.AnchorPoint = Vector2.new(0.5, 0.5)
	viewport.Position = UDim2.fromScale(0.5, 0.5)
	viewport.LightColor = Color3.new(1, 1, 1)
	viewport.LightDirection = Vector3.new(-0.5, -1, -0.5)
	viewport.BorderSizePixel = 0
	viewport.ZIndex = z or 1
	viewport.Parent = parent

	-- Print model status for debugging
	print("Loading model: " .. modelName .. " (exists: " .. tostring(planetFolder:FindFirstChild(modelName) ~= nil) .. ")")

	Instance.new("UICorner", viewport).CornerRadius = UDim.new(1, 0)

	-- Get and check model
	local modelObj = planetFolder:FindFirstChild(modelName)
	if not modelObj then 
		print("❌ Model not found: " .. modelName)
		return viewport 
	end

	-- Clone model and add to viewport
	local model = modelObj:Clone()
	model.Parent = viewport

	-- Setup camera with more reliable settings
	local camera = Instance.new("Camera")
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = CONFIG.CAMERA_FOV
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	-- Process model parts
	local allParts = {}
	local maxSize = 0

	if model:IsA("Model") then
		for _, part in pairs(model:GetDescendants()) do
			if part:IsA("BasePart") then
				table.insert(allParts, part)
				part.Anchored = true
			end
		end

		if #allParts > 0 then
			if not model.PrimaryPart then model.PrimaryPart = allParts[1] end

			pcall(function()
				local cf, size = model:GetBoundingBox()
				maxSize = math.max(size.X, size.Y, size.Z)

				if model.PrimaryPart then
					model:SetPrimaryPartCFrame(CFrame.new(0, 0, 0))
				else
					for _, part in ipairs(allParts) do
						part.CFrame = part.CFrame * CFrame.new(-cf.Position)
					end
				end
			end)
		end
	elseif model:IsA("BasePart") then
		table.insert(allParts, model)
		model.CFrame = CFrame.new(0, 0, 0)
		model.Anchored = true
		maxSize = math.max(model.Size.X, model.Size.Y, model.Size.Z)
	end

	if maxSize == 0 then maxSize = 2 end

	-- Camera positioning with improved reliability
	local targetSize = maxSize * CONFIG.VIEWPORT_PADDING
	local fov = math.rad(camera.FieldOfView)
	local distance = (targetSize / 2) / math.tan(fov / 2)

	-- Special adjustments for BlackHole - zoom out significantly more
	if modelName == "BlackHole" then 
		distance = distance * CONFIG.BLACKHOLE_CAMERA_DISTANCE_MULTIPLIER
	end

	if modelName == "Sun" then 
		distance = distance * 0.7
	end

	local cameraPos = Vector3.new(distance * 0.8, distance * CONFIG.CAMERA_Y_OFFSET, distance * 0.8)
	camera.CFrame = CFrame.new(cameraPos, Vector3.new(0, 0, 0))

	-- Add basic lighting only - no visual enhancements
	local lightBrightness = CONFIG.LIGHT_BRIGHTNESS

	-- Enhanced lighting setup for better visibility
	local lightPositions = {
		{pos = Vector3.new(distance, distance, distance), brightness = 1.0},
		{pos = Vector3.new(-distance, distance, -distance), brightness = 0.8},
		{pos = Vector3.new(0, -distance, 0), brightness = 0.6},
		{pos = Vector3.new(distance/2, distance/2, -distance), brightness = 0.7}, -- Additional light
		{pos = Vector3.new(-distance/2, -distance/2, distance), brightness = 0.5} -- Additional light
	}

	for _, lightInfo in ipairs(lightPositions) do
		local lightPart = Instance.new("Part")
		lightPart.Size = Vector3.new(0.1, 0.1, 0.1)
		lightPart.Transparency = 1
		lightPart.CanCollide = false
		lightPart.Anchored = true
		lightPart.Position = lightInfo.pos
		lightPart.Parent = viewport

		local light = Instance.new("PointLight")
		light.Brightness = lightBrightness * lightInfo.brightness
		light.Range = distance * 15
		light.Color = Color3.new(1, 1, 1)
		light.Parent = lightPart
	end

	-- Reliable viewport initialization - prevents "sometimes working" issues
	spawn(function()
		for i = 1, CONFIG.VIEWPORT_INIT_RETRIES do
			task.wait(CONFIG.VIEWPORT_RETRY_DELAY * i) -- Increasing wait times

			-- Only proceed if viewport still exists
			if not viewport.Parent then break end

			-- Force camera update
			if camera then
				local newDistance = distance * (1 + (i * 0.1))
				local newPos = Vector3.new(newDistance * 0.8, newDistance * CONFIG.CAMERA_Y_OFFSET, newDistance * 0.8)
				camera.CFrame = CFrame.new(newPos, Vector3.new(0, 0, 0))
			end

			-- Nudge viewport size to force redraw
			viewport.Size = UDim2.new(viewport.Size.X.Scale, viewport.Size.X.Offset + 1, 
				viewport.Size.Y.Scale, viewport.Size.Y.Offset + 1)
			task.wait()
			viewport.Size = size

			print("Viewport refresh attempt " .. i .. " for " .. modelName)
		end
	end)

	-- Add rotation animation with safeguards
	spawn(function()
		local rotSpeed = customRotSpeed or 0.5
		if objectInfo and objectInfo.id == "inferno" then rotSpeed = 0.3 end

		while viewport.Parent do
			pcall(function()
				if model:IsA("Model") and model.PrimaryPart then
					model:SetPrimaryPartCFrame(model.PrimaryPart.CFrame * CFrame.Angles(0, math.rad(rotSpeed), 0))
				elseif model:IsA("BasePart") then
					model.CFrame = model.CFrame * CFrame.Angles(0, math.rad(rotSpeed), 0)
				end
			end)
			RunService.Heartbeat:Wait()
		end
	end)

	return viewport
end

-- Create UI structure
local rootBg = Instance.new("Frame")
rootBg.Name, rootBg.Size, rootBg.BackgroundColor3 = "SolarRoot", UDim2.fromScale(1,1), C3(2,4,8)
rootBg.BorderSizePixel, rootBg.ClipsDescendants, rootBg.Parent = 0, true, tabMissions

-- Create stars
local stars, starsFolder = {}, Instance.new("Folder")
starsFolder.Name, starsFolder.Parent = "Stars", rootBg

local nebula = Instance.new("Frame")
nebula.Size, nebula.Position = UDim2.fromScale(1.5, 1.5), UDim2.fromScale(-0.25, -0.25)
nebula.BackgroundColor3, nebula.BackgroundTransparency = C3(30,15,45), 0.96
nebula.BorderSizePixel, nebula.ZIndex, nebula.Parent = 0, 0, rootBg

local nebulaGrad = Instance.new("UIGradient", nebula)
nebulaGrad.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, C3(60,30,90)),
	ColorSequenceKeypoint.new(0.5, C3(90,45,135)),
	ColorSequenceKeypoint.new(1, C3(30,15,60))
}
nebulaGrad.Rotation = 45

for i=1, CONFIG.STAR_COUNT do
	local s = Instance.new("Frame")
	local sz = math.random(1,3)
	s.Size = UDim2.fromOffset(sz, sz)
	s.Position = UDim2.new(math.random(), 0, math.random(), 0)
	local brightness = math.random(180,255)
	local tint = math.random(0.8, 1.2)
	s.BackgroundColor3 = C3(
		math.min(255, brightness * tint),
		math.min(255, brightness),
		math.min(255, brightness * (2-tint))
	)
	s.BackgroundTransparency = math.random(40,85)/100
	s.BorderSizePixel, s.ZIndex, s.Parent = 0, 1, starsFolder
	Instance.new("UICorner", s).CornerRadius = UDim.new(1,0)

	if math.random() < 0.5 then
		local glow = makeCircle(s, UDim2.fromScale(5, 5), s.BackgroundColor3, 0)
		glow.Position = UDim2.fromScale(-2, -2)
		glow.BackgroundTransparency = 0.94
	end

	stars[i] = {
		ref = s,
		basePos = s.Position,
		phase = math.random() * math.pi * 2,
		speed = (math.random() * 0.5 + 0.5) * CONFIG.STAR_DRIFT_SPEED,
		twinkle = math.random() * 5
	}
end

-- Effects system
local effects = Instance.new("Folder")
effects.Name, effects.Parent = "Effects", rootBg

local function makeStar(parent, size, color, z)
	local star = Instance.new("TextLabel")
	star.Size, star.BackgroundTransparency = size, 1
	star.BorderSizePixel, star.ZIndex, star.Parent = 0, z or 1, parent
	star.Text, star.TextScaled = "⭐", true
	star.TextColor3, star.Font = color, Enum.Font.SourceSans
	return star
end

-- FIXED SHOOTING STAR FUNCTION - trail properly centered behind star
local function createFireball()
	local startSide = math.random(1, 4)
	local startPos, endPos, angle
	if startSide == 1 then
		startPos = UDim2.new(math.random(20,80)/100, 0, -0.1, 0)
		endPos = UDim2.new(math.random(10,90)/100, 0, 1.1, 0)
		angle = math.random(80, 100)
	elseif startSide == 2 then
		startPos = UDim2.new(1.1, 0, math.random(10,90)/100, 0)
		endPos = UDim2.new(-0.1, 0, math.random(20,80)/100, 0)
		angle = math.random(170, 190)
	elseif startSide == 3 then
		startPos = UDim2.new(math.random(20,80)/100, 0, 1.1, 0)
		endPos = UDim2.new(math.random(10,90)/100, 0, -0.1, 0)
		angle = math.random(260, 280)
	else
		startPos = UDim2.new(-0.1, 0, math.random(10,90)/100, 0)
		endPos = UDim2.new(1.1, 0, math.random(20,80)/100, 0)
		angle = math.random(350, 370)
	end

	-- Create the fireball container to properly position everything
	local fireballContainer = Instance.new("Frame")
	fireballContainer.Size = UDim2.fromOffset(40, 40)  -- Larger container to hold everything
	fireballContainer.Position = startPos
	fireballContainer.BackgroundTransparency = 1
	fireballContainer.ZIndex = 8
	fireballContainer.Parent = effects
	fireballContainer.Rotation = angle

	-- Add the trails first (behind the star)
	for i = 1, 12 do
		local trail = makeCircle(fireballContainer, UDim2.fromOffset(8 - i/2, 8 - i/2), C3(255, 120 + i*8, 0), 7)
		trail.AnchorPoint = Vector2.new(0.5, 0.5)  -- Center the circle
		trail.Position = UDim2.fromScale(0.5, 0.5)  -- Position at container center
		trail.BackgroundTransparency = 0.3 + i*0.04

		local trailGrad = Instance.new("UIGradient", trail)
		trailGrad.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, C3(255, 220 - i*10, 0)),
			ColorSequenceKeypoint.new(1, C3(255, 80 + i*8, 0))
		}

		tween(trail, TweenInfo.new(0.06 + i*0.01, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{BackgroundTransparency = 0.6 + i*0.03, Size = UDim2.fromOffset(7 - i/2, 7 - i/2)})
	end

	-- Add the star on top of the trails
	local fireball = makeStar(fireballContainer, UDim2.fromOffset(16, 16), C3(255,255,200), 8)
	fireball.AnchorPoint = Vector2.new(0.5, 0.5)  -- Center the star
	fireball.Position = UDim2.fromScale(0.5, 0.5)  -- Position at container center
	fireball.TextTransparency = 0.1

	local glow = Instance.new("UIStroke", fireball)
	glow.Color, glow.Thickness, glow.Transparency = C3(255,200,0), 3, 0.3

	local duration = math.random(1,2.2)
	TweenService:Create(fireballContainer, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Position = endPos}):Play()
	TweenService:Create(fireball, TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {TextTransparency = 1}):Play()
	TweenService:Create(glow, TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {Transparency = 1}):Play()

	delay(duration, function() 
		if fireballContainer then fireballContainer:Destroy() end 
	end)
end

local asteroids = {}
local function createAsteroid()
	local a = makeCircle(effects, UDim2.fromOffset(math.random(10,18), math.random(10,18)), 
		C3(math.random(80,120), math.random(70,100), math.random(60,90)), 2)
	a.Position, a.BackgroundTransparency, a.Rotation = UDim2.new(math.random(), 0, math.random(), 0), 0.4, math.random(0, 360)

	local drift = TweenService:Create(a,
		TweenInfo.new(math.random(15,30), Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
		{Position = UDim2.new(a.Position.X.Scale + math.random(-0.2, 0.2), 0, a.Position.Y.Scale + math.random(-0.2, 0.2), 0)}
	)
	drift:Play()

	local rotate = TweenService:Create(a,
		TweenInfo.new(math.random(8,20), Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
		{Rotation = a.Rotation + 360}
	)
	rotate:Play()

	asteroids[#asteroids + 1] = {obj = a, drift = drift, rotate = rotate}
end

for i = 1, CONFIG.ASTEROID_COUNT do createAsteroid() end

-- Main area
local area = Instance.new("Frame")
area.Name, area.Size = "Area", UDim2.fromScale(1,1)
area.BackgroundTransparency, area.BorderSizePixel = 1, 0
area.ZIndex, area.Parent = 10, rootBg

repeat task.wait() until area.AbsoluteSize.X > 4 and area.AbsoluteSize.Y > 4

-- Setup for center position reference
local center = Vector2.new(0.40, 0.54) -- moved a bit more left
local sunScaleBase = math.min(area.AbsoluteSize.X, area.AbsoluteSize.Y)
local sunCoreSize = math.floor(CONFIG.SUN_SCALE * sunScaleBase)

-- Tooltip
local tooltip = Instance.new("Frame")
tooltip.Size, tooltip.BackgroundColor3 = UDim2.fromOffset(220, 90), C3(8,15,25)
tooltip.BackgroundTransparency, tooltip.BorderSizePixel = 0.1, 0
tooltip.ZIndex, tooltip.Visible, tooltip.Parent = 200, false, area
Instance.new("UICorner", tooltip).CornerRadius = UDim.new(0.3, 0)

local tooltipTitle = Instance.new("TextLabel")
tooltipTitle.Size, tooltipTitle.Position = UDim2.new(1,-16,0,26), UDim2.new(0,8,0,8)
tooltipTitle.BackgroundTransparency, tooltipTitle.BorderSizePixel = 1, 0
tooltipTitle.Font, tooltipTitle.TextSize = FONT_HEADING, 15
tooltipTitle.TextColor3, tooltipTitle.TextXAlignment = C3(220,240,255), Enum.TextXAlignment.Left
tooltipTitle.ZIndex, tooltipTitle.Text, tooltipTitle.Parent = 201, "", tooltip

local tooltipDesc = Instance.new("TextLabel")
tooltipDesc.Size, tooltipDesc.Position = UDim2.new(1,-16,0,50), UDim2.new(0,8,0,34)
tooltipDesc.BackgroundTransparency, tooltipDesc.BorderSizePixel = 1, 0
tooltipDesc.Font, tooltipDesc.TextSize = FONT_TEXT, 12
tooltipDesc.TextColor3, tooltipDesc.TextWrapped = C3(170,200,230), true
tooltipDesc.TextXAlignment, tooltipDesc.TextYAlignment = Enum.TextXAlignment.Left, Enum.TextYAlignment.Top
tooltipDesc.ZIndex, tooltipDesc.Text, tooltipDesc.Parent = 201, "", tooltip

-- Layers for z-indexing
local behindSunLayer = Instance.new("Frame")
behindSunLayer.Name, behindSunLayer.Size = "BehindSunLayer", UDim2.fromScale(1, 1)
behindSunLayer.BackgroundTransparency, behindSunLayer.ZIndex = 1, 20
behindSunLayer.Parent = area

local sunLayer = Instance.new("Frame")
sunLayer.Name, sunLayer.Size = "SunLayer", UDim2.fromScale(1, 1)
sunLayer.BackgroundTransparency, sunLayer.ZIndex = 1, 25
sunLayer.Parent = area

local frontSunLayer = Instance.new("Frame")
frontSunLayer.Name, frontSunLayer.Size = "FrontSunLayer", UDim2.fromScale(1, 1)
frontSunLayer.BackgroundTransparency, frontSunLayer.ZIndex = 1, 30
frontSunLayer.Parent = area

-- Create Sun viewport with fallback to ensure visibility
local sunContainer = Instance.new("Frame")
sunContainer.Name = "SunContainer"
sunContainer.Size = UDim2.fromOffset(sunCoreSize, sunCoreSize)
sunContainer.AnchorPoint = Vector2.new(0.5, 0.5)
sunContainer.Position = UDim2.fromScale(center.X, center.Y)
sunContainer.BackgroundTransparency = 1
sunContainer.ZIndex = 25
sunContainer.Parent = sunLayer

-- Create simple sun backup visual that will be seen if model fails to load
local sunBackupVisual = makeCircle(sunContainer, UDim2.fromScale(0.95, 0.95), C3(255, 160, 30), 25)
sunBackupVisual.AnchorPoint = Vector2.new(0.5, 0.5)
sunBackupVisual.Position = UDim2.fromScale(0.5, 0.5)
sunBackupVisual.BackgroundTransparency = 0.1
local sunBackupGradient = Instance.new("UIGradient", sunBackupVisual)
sunBackupGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, C3(255, 200, 80)),
	ColorSequenceKeypoint.new(0.6, C3(255, 140, 20)),
	ColorSequenceKeypoint.new(1, C3(200, 60, 0))
}
sunBackupGradient.Rotation = 45

-- Add Sun label
local sunLabel = Instance.new("TextLabel")
sunLabel.Text = "Nova Core"
sunLabel.Size = UDim2.new(0, sunCoreSize + 60, 0, 20)
sunLabel.Position = UDim2.fromScale(center.X, center.Y + 0.15)
sunLabel.AnchorPoint = Vector2.new(0.5, 0)
sunLabel.BackgroundTransparency = 1
sunLabel.TextColor3 = C3(255, 200, 100)
sunLabel.Font = FONT_HEADING
sunLabel.TextSize = 16
sunLabel.ZIndex = 26
sunLabel.Parent = area

-- Create 3D Sun viewport
local sunInfo = {
	baseColor = C3(255, 150, 0),
	lightColor = C3(255, 220, 180)
}

-- Sun viewport creation - just the pure model
local sunViewport = create3DPlanet(sunContainer, "Sun", UDim2.fromScale(1, 1), 26, sunInfo, CONFIG.SUN_ROTATION_SPEED)

-- Force reliable Sun initialization with additional safeguards
spawn(function()
	for i = 1, 5 do -- Try multiple times
		task.wait(0.1 * i) -- Wait longer each time

		if not sunContainer.Parent then break end -- Stop if UI is destroyed

		-- Try to make Sun visible by resetting camera and model
		pcall(function()
			local camera = sunViewport.CurrentCamera
			if camera then
				local model = sunViewport:FindFirstChildOfClass("Model") or sunViewport:FindFirstChildOfClass("Part")
				if model then
					-- Reset model position
					if model:IsA("Model") and model.PrimaryPart then
						model:SetPrimaryPartCFrame(CFrame.new(0, 0, 0))
					elseif model:IsA("BasePart") then
						model.CFrame = CFrame.new(0, 0, 0)
					end

					-- Reset camera
					local distance = camera.CFrame.Position.Magnitude
					camera.CFrame = CFrame.new(Vector3.new(distance * 0.8, distance * 0.1, distance * 0.8), Vector3.new(0, 0, 0))

					-- Force viewport refresh
					sunViewport.Size = UDim2.fromScale(1.01, 1.01)
					task.wait(0.03)
					sunViewport.Size = UDim2.fromScale(1, 1)

					-- Hide backup if model is visible
					sunBackupVisual.BackgroundTransparency = 0.95
				end
			end
		end)
	end
end)

-- Create BlackHole viewport with fallback to ensure visibility
local blackholeContainer = Instance.new("Frame")
blackholeContainer.Name = "BlackHoleContainer"
-- FIXED: Use absolute size instead of relative to prevent size changes
blackholeContainer.Size = UDim2.fromOffset(CONFIG.BLACKHOLE_ABSOLUTE_SIZE, CONFIG.BLACKHOLE_ABSOLUTE_SIZE)
blackholeContainer.Position = CONFIG.BLACKHOLE_POSITION
blackholeContainer.BackgroundTransparency = 1
blackholeContainer.ZIndex = 40
blackholeContainer.Parent = area

-- Create simple blackhole backup visual that will be seen if model fails to load
local blackholeBackupVisual = makeCircle(blackholeContainer, UDim2.fromScale(0.95, 0.95), C3(20, 10, 40), 41)
blackholeBackupVisual.AnchorPoint = Vector2.new(0.5, 0.5)
blackholeBackupVisual.Position = UDim2.fromScale(0.5, 0.5)
blackholeBackupVisual.BackgroundTransparency = 0.1
local blackholeBackupGradient = Instance.new("UIGradient", blackholeBackupVisual)
blackholeBackupGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, C3(0, 0, 0)),
	ColorSequenceKeypoint.new(0.7, C3(20, 10, 40)),
	ColorSequenceKeypoint.new(1, C3(60, 20, 100))
}
blackholeBackupGradient.Rotation = 60

-- Blackhole info - minimal
local blackholeInfo = {
	baseColor = C3(20, 10, 40),
	lightColor = C3(140, 80, 255)
}

-- BlackHole viewport creation - just the pure model
local blackholeViewport = create3DPlanet(blackholeContainer, "BlackHole", UDim2.fromScale(1, 1), 42, blackholeInfo, CONFIG.BLACKHOLE_ROTATION_SPEED)
blackholeViewport.AnchorPoint = Vector2.new(0.5, 0.5)
blackholeViewport.Position = UDim2.fromScale(0.5, 0.5)

-- Force reliable BlackHole initialization with additional safeguards
spawn(function()
	for i = 1, 5 do -- Try multiple times
		task.wait(0.1 * i) -- Wait longer each time

		if not blackholeContainer.Parent then break end -- Stop if UI is destroyed

		-- Force the position to be correct
		blackholeContainer.Position = CONFIG.BLACKHOLE_POSITION

		-- Try to make BlackHole visible by resetting camera and model
		pcall(function()
			local camera = blackholeViewport.CurrentCamera
			if camera then
				local model = blackholeViewport:FindFirstChildOfClass("Model") or blackholeViewport:FindFirstChildOfClass("Part")
				if model then
					-- Reset model position
					if model:IsA("Model") and model.PrimaryPart then
						model:SetPrimaryPartCFrame(CFrame.new(0, 0, 0))
					elseif model:IsA("BasePart") then
						model.CFrame = CFrame.new(0, 0, 0)
					end

					-- Reset camera with increased distance to zoom out more
					local distance = camera.CFrame.Position.Magnitude * (1 + (i * 0.2)) -- Increase distance each time
					camera.CFrame = CFrame.new(Vector3.new(distance * 0.8, distance * 0.1, distance * 0.8), Vector3.new(0, 0, 0))

					-- Force viewport refresh
					blackholeViewport.Size = UDim2.fromScale(1.01, 1.01)
					task.wait(0.03)
					blackholeViewport.Size = UDim2.fromScale(1, 1)

					-- Hide backup if model is visible
					blackholeBackupVisual.BackgroundTransparency = 0.95
				end
			end
		end)
	end
end)

-- Add a label for BlackHole
local blackholeLabel = Instance.new("TextLabel")
blackholeLabel.Text = "THE VOID"
blackholeLabel.Size = UDim2.new(0, CONFIG.BLACKHOLE_ABSOLUTE_SIZE + 60, 0, 20)
blackholeLabel.Position = UDim2.fromOffset(CONFIG.BLACKHOLE_POSITION.X.Offset - 30, CONFIG.BLACKHOLE_POSITION.Y.Offset + CONFIG.BLACKHOLE_ABSOLUTE_SIZE + 10)
blackholeLabel.BackgroundTransparency = 1
blackholeLabel.TextColor3 = C3(140, 80, 200)
blackholeLabel.Font = FONT_HEADING
blackholeLabel.TextSize = 16
blackholeLabel.ZIndex = 44
blackholeLabel.Parent = area

-- Force positioning of BlackHole - important for fixing the position bug
spawn(function()
	-- Try multiple times to ensure position is applied correctly
	for i = 1, 5 do
		task.wait(0.1 * i)
		-- Make sure BlackHole is correctly positioned
		blackholeContainer.Position = CONFIG.BLACKHOLE_POSITION
		-- FIXED: Ensure size remains constant regardless of screen size
		blackholeContainer.Size = UDim2.fromOffset(CONFIG.BLACKHOLE_ABSOLUTE_SIZE, CONFIG.BLACKHOLE_ABSOLUTE_SIZE)
	end
end)

-- Print debug info to help diagnose viewport issues
print("------ SOLAR SYSTEM DEBUG INFO ------")
print("Sun model exists: " .. tostring(planetFolder:FindFirstChild("Sun") ~= nil))
print("BlackHole model exists: " .. tostring(planetFolder:FindFirstChild("BlackHole") ~= nil))
print("Sun container size: " .. tostring(sunCoreSize))
print("BlackHole container size: " .. tostring(CONFIG.BLACKHOLE_ABSOLUTE_SIZE))
print("BlackHole position: " .. tostring(CONFIG.BLACKHOLE_POSITION))
print("------------------------------------")

-- Planet setup
local planetObjs, planetLabels, planetAngles, planetData = {}, {}, {}, {}

local function createPlanetUI(p, index)
	local front = Instance.new("Frame")
	front.Name, front.Size = p.id .. "_front", UDim2.fromOffset(math.floor(p.size * CONFIG.PLANET_SIZE_SCALE), math.floor(p.size * CONFIG.PLANET_SIZE_SCALE))
	front.BackgroundTransparency, front.BorderSizePixel = 1, 0
	front.ZIndex, front.Parent = 30, frontSunLayer
	Instance.new("UICorner", front).CornerRadius = UDim.new(1, 0)

	local back = Instance.new("Frame")
	back.Name, back.Size = p.id .. "_back", UDim2.fromOffset(math.floor(p.size * CONFIG.PLANET_SIZE_SCALE), math.floor(p.size * CONFIG.PLANET_SIZE_SCALE))
	back.BackgroundTransparency, back.BorderSizePixel = 1, 0
	back.ZIndex, back.Parent = 20, behindSunLayer
	Instance.new("UICorner", back).CornerRadius = UDim.new(1, 0)

	local frontPlanet = create3DPlanet(front, p.modelName, UDim2.fromScale(1,1), 31, p)
	local backPlanet = create3DPlanet(back, p.modelName, UDim2.fromScale(1,1), 21, p)

	local label = Instance.new("TextLabel")
	label.Size, label.BackgroundTransparency = UDim2.new(0, math.floor(p.size * CONFIG.PLANET_SIZE_SCALE) + 36, 0, 18), 1
	label.BorderSizePixel, label.Font = 0, FONT_HEADING
	label.TextSize, label.TextColor3 = 13, C3(220,230,255)
	label.TextTransparency, label.Text = 0.2, p.name
	label.ZIndex, label.Parent = 40, area

	return {
		front = {container = front, planet = frontPlanet},
		back = {container = back, planet = backPlanet},
		label = label,
		current = nil
	}
end

-- Precompute evenly spaced starting angles for non-cluster planets to avoid touching at start
local nonClusterIndices = {}
for idx, p in ipairs(planets) do
	if not p.cluster then table.insert(nonClusterIndices, idx) end
end
local uniformStep = (#nonClusterIndices > 0) and ((2*math.pi)/#nonClusterIndices) or 0
local baseOffset = math.rad(10)
local nonClusterCounter = 0

-- Create planets
for i, planet in ipairs(planets) do
	local planetObj = createPlanetUI(planet, i)
	planetObj.front.container.Visible = false
	planetObj.back.container.Visible = false

	planetObjs[i] = planetObj
	planetLabels[i] = planetObj.label
	-- Seed initial angle: binary pair gets custom seeds; others evenly spaced so they don't touch
	local angleInit
	if planet.id == "inferno" then
		angleInit = 0 -- rightmost for cluster base
	elseif planet.id == "annihilator" then
		angleInit = math.rad(32) -- slight separation from inferno path at start
	else
		nonClusterCounter += 1
		angleInit = baseOffset + (nonClusterCounter - 1) * uniformStep
	end
	planetAngles[i] = angleInit
	planetData[i] = {
		info = planet,
		obj = planetObj,
		hovered = false,
		radius = planet.orbit * CONFIG.ORBIT_RADIUS_SCALE * math.min(area.AbsoluteSize.X, area.AbsoluteSize.Y),
		behindSun = false,
		angle = planetAngles[i],
		tilt = planet.orbitTilt or 0,
	}

	local function setupInteraction(container)
		container.MouseEnter:Connect(function()
			local d = planetData[i]
			d.hovered = true
			tween(planetObj.front.container, TweenInfo.new(CONFIG.PLANET_HOVER_TWEEN, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
				{Size = UDim2.fromOffset(math.floor(planet.size * CONFIG.PLANET_SIZE_SCALE * CONFIG.PLANET_HOVER_SCALE), math.floor(planet.size * CONFIG.PLANET_SIZE_SCALE * CONFIG.PLANET_HOVER_SCALE))})
			tween(planetObj.back.container, TweenInfo.new(CONFIG.PLANET_HOVER_TWEEN, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
				{Size = UDim2.fromOffset(math.floor(planet.size * CONFIG.PLANET_SIZE_SCALE * CONFIG.PLANET_HOVER_SCALE), math.floor(planet.size * CONFIG.PLANET_SIZE_SCALE * CONFIG.PLANET_HOVER_SCALE))})
			tooltip.Visible = true
			tooltipTitle.Text = planet.name
			local mission = missionsById[planet.id]
			tooltipDesc.Text = mission and mission.title or "Challenge available"
		end)

		container.MouseLeave:Connect(function()
			local d = planetData[i]
			d.hovered = false
			tween(planetObj.front.container, TweenInfo.new(CONFIG.PLANET_HOVER_TWEEN, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
				{Size = UDim2.fromOffset(math.floor(planet.size * CONFIG.PLANET_SIZE_SCALE), math.floor(planet.size * CONFIG.PLANET_SIZE_SCALE))})
			tween(planetObj.back.container, TweenInfo.new(CONFIG.PLANET_HOVER_TWEEN, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
				{Size = UDim2.fromOffset(math.floor(planet.size * CONFIG.PLANET_SIZE_SCALE), math.floor(planet.size * CONFIG.PLANET_SIZE_SCALE))})
			tooltip.Visible = false
		end)

		container.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				local overlay = Instance.new("Frame")
				overlay.Size, overlay.BackgroundColor3 = UDim2.fromScale(1,1), C3(0,2,5)
				overlay.BackgroundTransparency, overlay.BorderSizePixel = 1, 0
				overlay.ZIndex, overlay.Parent = 100, tabMissions

				local holo = Instance.new("Frame")
				holo.Size, holo.AnchorPoint = UDim2.fromOffset(0,0), Vector2.new(0.5,0.5)
				holo.Position, holo.BackgroundColor3 = UDim2.new(0.5,0,0.5,0), planet.baseColor:lerp(C3(0,0,0), 0.4)
				holo.BackgroundTransparency, holo.BorderSizePixel = 0.08, 0
				holo.ZIndex, holo.Parent = 110, overlay
				Instance.new("UICorner", holo).CornerRadius = UDim.new(0.25, 0)

				local holoBorder = Instance.new("UIStroke", holo)
				holoBorder.Color, holoBorder.Thickness = planet.glow, 2
				holoBorder.Transparency = 0.2

				local icon = create3DPlanet(holo, planet.modelName, UDim2.fromOffset(70,70), 130, planet)
				icon.Position = UDim2.new(0,25,0,25)

				local title = Instance.new("TextLabel")
				title.Size, title.Position = UDim2.new(1,-110,0,32), UDim2.new(0,105,0,25)
				title.BackgroundTransparency, title.BorderSizePixel = 1, 0
				title.Font, title.TextSize = FONT_HEADING, 19
				title.TextColor3, title.TextTransparency = planet.glow, 0.05
				title.TextXAlignment, title.ZIndex = Enum.TextXAlignment.Left, 140
				title.Text = missionsById[planet.id] and missionsById[planet.id].title or planet.name
				title.Parent = holo

				local desc = Instance.new("TextLabel")
				desc.Size, desc.Position = UDim2.new(1,-50,0,90), UDim2.new(0,25,0,70)
				desc.BackgroundTransparency, desc.BorderSizePixel = 1, 0
				desc.Font, desc.TextSize = FONT_TEXT, 14
				desc.TextColor3, desc.TextTransparency = C3(190,220,250), 0.05
				desc.TextWrapped, desc.TextYAlignment = true, Enum.TextYAlignment.Top
				desc.ZIndex = 141
				desc.Text = missionsById[planet.id] and missionsById[planet.id].desc or "Challenge objectives ready for deployment."
				desc.Parent = holo

				local closeBtn = Instance.new("TextButton")
				closeBtn.Size, closeBtn.Position = UDim2.fromOffset(80,32), UDim2.new(1,-95,0,15)
				closeBtn.BackgroundColor3, closeBtn.BackgroundTransparency = planet.glow, 0.15
				closeBtn.BorderSizePixel, closeBtn.AutoButtonColor = 0, true
				closeBtn.Font, closeBtn.Text = FONT_HEADING, "CLOSE"
				closeBtn.TextColor3, closeBtn.TextSize = C3(5,10,20), 14
				closeBtn.ZIndex, closeBtn.Parent = 150, holo
				Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0.4, 0)

				tween(overlay, TweenInfo.new(0.3), {BackgroundTransparency = 0.25})
				tween(holo, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), 
					{Size = UDim2.fromOffset(480, 240)})

				closeBtn.MouseButton1Click:Connect(function()
					tween(overlay, TweenInfo.new(0.22), {BackgroundTransparency = 1})
					tween(holo, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.In),
						{Size = UDim2.fromOffset(0,0)})
					task.delay(0.2, function() if overlay then overlay:Destroy() end end)
				end)
			end
		end)
	end

	setupInteraction(planetObj.front.container)
	setupInteraction(planetObj.back.container)
end

-- Animation system
local connections, fireballTimer = {}, 0

local function updateLayout()
	local abs = area.AbsoluteSize
	local scale = math.min(abs.X, abs.Y)

	-- Update sun size
	sunCoreSize = math.floor(CONFIG.SUN_SCALE * scale)
	sunContainer.Size = UDim2.fromOffset(sunCoreSize, sunCoreSize)
	sunLabel.Size = UDim2.new(0, sunCoreSize + 60, 0, 20)
	sunLabel.Position = UDim2.fromScale(center.X, center.Y + 0.15)

	-- FIXED: Don't change blackhole size during layout updates
	blackholeContainer.Position = CONFIG.BLACKHOLE_POSITION
	blackholeContainer.Size = UDim2.fromOffset(CONFIG.BLACKHOLE_ABSOLUTE_SIZE, CONFIG.BLACKHOLE_ABSOLUTE_SIZE)

	-- Update blackhole label position
	blackholeLabel.Position = UDim2.fromOffset(CONFIG.BLACKHOLE_POSITION.X.Offset - 30, CONFIG.BLACKHOLE_POSITION.Y.Offset + CONFIG.BLACKHOLE_ABSOLUTE_SIZE + 10)
	blackholeLabel.Size = UDim2.new(0, CONFIG.BLACKHOLE_ABSOLUTE_SIZE + 60, 0, 20)

	-- Update planet orbit radii
	for i, planet in ipairs(planets) do
		local radius = math.floor(planet.orbit * CONFIG.ORBIT_RADIUS_SCALE * scale)
		if planetData[i] then planetData[i].radius = radius end
	end
end

connections[#connections+1] = area:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateLayout)

connections[#connections+1] = RunService.RenderStepped:Connect(function(dt)
	local abs = area.AbsoluteSize
	local _scale = math.min(abs.X, abs.Y)

	-- Star animation
	for i, s in ipairs(stars) do
		s.phase = s.phase + dt * s.speed
		s.twinkle = s.twinkle + dt * 3
		local dx = math.sin(s.phase*2) * CONFIG.STAR_MAX_DRIFT
		local dy = math.cos(s.phase*1.8) * CONFIG.STAR_MAX_DRIFT
		s.ref.Position = UDim2.new(s.basePos.X.Scale, dx, s.basePos.Y.Scale, dy)
		s.ref.BackgroundTransparency = 0.4 + ((math.sin(s.twinkle) + 1) / 2) * 0.5
	end

	-- Planet animation
	for i, planet in ipairs(planets) do
		local data = planetData[i]
		-- Radius-based orbit speed: inner faster, outer slower
		-- speed = base * (refRadius / radius)^exp
		local orbitRadius = data.radius
		local ref = CONFIG.ORBIT_REF_ORBIT * math.min(abs.X, abs.Y) * CONFIG.ORBIT_RADIUS_SCALE
	local speedMul = planet.orbitSpeedMul or 1
		if CONFIG.ORBIT_SPEED_EXP ~= 0 then
			if orbitRadius > 0 and ref > 0 then
				speedMul = (ref / orbitRadius) ^ CONFIG.ORBIT_SPEED_EXP
			end
		end
		data.angle = data.angle + dt * CONFIG.ORBIT_BASE_SPEED * speedMul
		local angle = data.angle
		-- Compute depth scale and current visual size first
		local isBehind = math.cos(angle) < 0
		local depthScale = isBehind and
			(1 - (CONFIG.DEPTH_EFFECT_STRENGTH * 0.15)) or
			(1 + (CONFIG.DEPTH_EFFECT_STRENGTH * 0.05))

		local baseSize = planet.size * CONFIG.PLANET_SIZE_SCALE
		local targetSize = data.hovered 
			and baseSize * CONFIG.PLANET_HOVER_SCALE * depthScale
			or baseSize * depthScale

		-- Shrink effective radius so the planet stays within the area bounds
		local radius = math.max(0, orbitRadius - (targetSize * 0.5) - CONFIG.ORBIT_EDGE_MARGIN)

		-- Right-side cluster: make Inferno and Annihilator move straight up/down at the right edge (no orbit)
		local px, py
		if planet.cluster == "right" then
			-- Determine the far-right x position (Inferno) and a fixed offset left (Annihilator)
			local maxBinarySize = 0
			for _, p in ipairs(planets) do
				if p.cluster == "right" then
					local s = p.size * CONFIG.PLANET_SIZE_SCALE
					if s > maxBinarySize then maxBinarySize = s end
				end
			end
			local halfMax = (maxBinarySize * 0.5) + CONFIG.ORBIT_EDGE_MARGIN
			local minX = math.min(halfMax, abs.X - halfMax)
			local maxX = math.max(halfMax, abs.X - halfMax)
			local infernoX = math.clamp(abs.X - halfMax, minX, maxX)
			local offsetX = (maxBinarySize * 0.6) + 12 -- gap so they never touch
			px = (planet.id == "inferno") and infernoX or (infernoX - offsetX)

			-- Pure vertical oscillation using full available height
			local pivotYBase = center.Y * abs.Y
			local verticalPadding = math.max(halfMax, 24)
			local usableHalfHeight = math.max(0, (abs.Y/2) - verticalPadding)
			local vPhase = planet.verticalPhase or ((planet.id == "inferno") and -math.pi/2 or math.pi/2)
			py = pivotYBase + math.sin(angle + vPhase) * usableHalfHeight
		else
			local verticalOffset = math.sin(angle) * data.tilt * radius
			px = center.X * abs.X + math.cos(angle) * radius
			py = center.Y * abs.Y + math.sin(angle) * radius + verticalOffset
		end

		if data.behindSun ~= isBehind then
			data.behindSun = isBehind
			local frontObj, backObj = data.obj.front, data.obj.back

			if isBehind then
				frontObj.container.Visible = false
				backObj.container.Visible = true
				data.obj.current = backObj.container
			else
				frontObj.container.Visible = true
				backObj.container.Visible = false
				data.obj.current = frontObj.container
			end
		end

		local activeContainer = data.obj.current
		if activeContainer then
			activeContainer.Size = UDim2.fromOffset(targetSize, targetSize)
			activeContainer.Position = UDim2.fromOffset(px - targetSize/2, py - targetSize/2)
		end

		local inactiveContainer = data.behindSun and data.obj.front.container or data.obj.back.container
		if inactiveContainer then
			inactiveContainer.Size = UDim2.fromOffset(targetSize, targetSize)
			inactiveContainer.Position = UDim2.fromOffset(px - targetSize/2, py - targetSize/2)
		end

	local label = data.obj.label
	local labelXMin = 6
	local labelXMax = math.max(6, abs.X - 6 - label.Size.X.Offset)
	local labelX = math.clamp(px - label.Size.X.Offset/2, labelXMin, labelXMax)
	local labelYMin = 6
	local labelYMax = math.max(6, abs.Y - 6 - label.Size.Y.Offset)
	local labelY = math.clamp(py + targetSize/2 + 8, labelYMin, labelYMax)
	label.Position = UDim2.fromOffset(labelX, labelY)
	label.TextTransparency = data.behindSun and 0.5 or 0.2
	-- Hide label if it overlaps the sun disk
	local sunCx = center.X * abs.X
	local sunCy = center.Y * abs.Y
	local sunR = sunCoreSize * 0.5
	local labelRect = Rect.new(labelX, labelY, labelX + label.Size.X.Offset, labelY + label.Size.Y.Offset)
	local closestX = math.clamp(sunCx, labelRect.Min.X, labelRect.Max.X)
	local closestY = math.clamp(sunCy, labelRect.Min.Y, labelRect.Max.Y)
	local dx, dy = sunCx - closestX, sunCy - closestY
	local distSq = dx*dx + dy*dy
	local overlapsSun = distSq <= (sunR * sunR)
	label.Visible = not overlapsSun
	end


	-- Fireball timer
	fireballTimer = fireballTimer + dt
	if fireballTimer >= CONFIG.FIREBALL_INTERVAL then
		fireballTimer = 0
		createFireball()
	end

	-- Tooltip positioning
	if tooltip.Visible then
		local mousePos = UserInputService:GetMouseLocation()
		local localPos = Vector2.new(mousePos.X - area.AbsolutePosition.X, mousePos.Y - area.AbsolutePosition.Y)
		tooltip.Position = UDim2.fromOffset(
			math.min(localPos.X + CONFIG.TOOLTIP_OFFSET.X, abs.X - tooltip.Size.X.Offset - 10),
			math.min(localPos.Y + CONFIG.TOOLTIP_OFFSET.Y, abs.Y - tooltip.Size.Y.Offset - 10)
		)
	end

	-- Animate backup visuals in case they're shown
	sunBackupGradient.Rotation = (sunBackupGradient.Rotation + 0.1) % 360
	blackholeBackupGradient.Rotation = (blackholeBackupGradient.Rotation + 0.2) % 360

	-- FIXED: Ensure blackhole size remains constant during animation
	blackholeContainer.Size = UDim2.fromOffset(CONFIG.BLACKHOLE_ABSOLUTE_SIZE, CONFIG.BLACKHOLE_ABSOLUTE_SIZE)
end)

-- API
local SolarSystemUI = {}

function SolarSystemUI.Destroy()
	for _, c in ipairs(connections) do
		if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
	end
	table.clear(connections)
	if rootBg and rootBg.Parent then rootBg:Destroy() end
	print("Solar System UI destroyed")
end

function SolarSystemUI.GetPlanetStatus(id)
	for _, planet in ipairs(planets) do
		if planet.id == id then return planet.status end
	end
	return nil
end

function SolarSystemUI.InspectModel(id)
	for i, planet in ipairs(planets) do
		if planet.id == id then
			print("--- MODEL INSPECTION: " .. planet.name .. " ---")
			print("Using model: " .. planet.modelName)

			if planetFolder then
				local model = planetFolder:FindFirstChild(planet.modelName)
				if model then
					print("✅ Model exists: Yes")
					if model:IsA("Model") then
						print("Model type: Model")
						print("Parts count: " .. #model:GetDescendants())
						local hasParts = false
						for _, part in pairs(model:GetDescendants()) do
							if part:IsA("BasePart") then
								hasParts = true
								print("  - Part: " .. part.Name .. ", Size: " .. tostring(part.Size) .. ", Color: " .. tostring(part.Color))
							end
						end
						if not hasParts then print("⚠️ NO PARTS FOUND IN MODEL - THIS IS THE ISSUE") end
					else
						print("Model type: " .. model.ClassName)
						if model:IsA("BasePart") then
							print("Size: " .. tostring(model.Size))
							print("Color: " .. tostring(model.Color))
						end
					end
				else print("❌ Model does not exist") end
			end
			break
		end
	end
end

-- Inspect Sun and BlackHole models
function SolarSystemUI.InspectCosmicObjects()
	print("--- COSMIC OBJECTS INSPECTION ---")

	local sunModel = planetFolder:FindFirstChild("Sun")
	print("Sun model exists: " .. (sunModel and "✅ Yes" or "❌ No"))

	local blackholeModel = planetFolder:FindFirstChild("BlackHole")
	print("BlackHole model exists: " .. (blackholeModel and "✅ Yes" or "❌ No"))

	return {sun = sunModel ~= nil, blackhole = blackholeModel ~= nil}
end

-- Force refresh function for scripts to call if needed
function SolarSystemUI.ForceRefresh()
	-- Reset viewport cameras and refresh displays
	pcall(function()
		-- Refresh Sun viewport
		if sunViewport and sunViewport.CurrentCamera then
			local distance = sunViewport.CurrentCamera.CFrame.Position.Magnitude
			sunViewport.CurrentCamera.CFrame = CFrame.new(
				Vector3.new(distance * 0.8, distance * 0.1, distance * 0.8), 
				Vector3.new(0, 0, 0)
			)
		end

		-- Refresh BlackHole viewport
		if blackholeViewport and blackholeViewport.CurrentCamera then
			local distance = blackholeViewport.CurrentCamera.CFrame.Position.Magnitude
			blackholeViewport.CurrentCamera.CFrame = CFrame.new(
				Vector3.new(distance * 0.8, distance * 0.1, distance * 0.8), 
				Vector3.new(0, 0, 0)
			)
			-- Force position reset for BlackHole
			blackholeContainer.Position = CONFIG.BLACKHOLE_POSITION
			-- Ensure consistent size
			blackholeContainer.Size = UDim2.fromOffset(CONFIG.BLACKHOLE_ABSOLUTE_SIZE, CONFIG.BLACKHOLE_ABSOLUTE_SIZE)
		end
	end)

	print("Solar System UI refresh forced")
end

-- Expose global references for other modules
SolarSystemUI.RootBg = rootBg
SolarSystemUI.Area = area
SolarSystemUI.SunLayer = sunLayer
SolarSystemUI.Center = center
SolarSystemUI.SunCoreSize = sunCoreSize
SolarSystemUI.SunContainer = sunContainer
SolarSystemUI.BlackHoleContainer = blackholeContainer

tabMissions.AncestryChanged:Connect(function()
	if not tabMissions.Parent then SolarSystemUI.Destroy() end
end)

print("✅ SOLAR SYSTEM WITH FIXED SHOOTING STARS AND CONSISTENT BLACKHOLE SIZE")
print("🌠 Shooting star trails now properly centered behind stars")
print("🕳️ THE VOID now uses fixed absolute size (220px) that won't change with screen size")
print("📅 Last update: 2025-08-20 17:04:19 by Hulk11121")

return SolarSystemUI