--[[
	NPCHealthBars.client.luau
	Creates beautiful animated health bars above NPC heads
	Supports both Humanoid-based and Attribute-based health systems
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

print("[NPCHealthBars] Initializing...")

-- Configuration
local CONFIG = {
	-- Health bar dimensions
	BAR_WIDTH = 120,
	BAR_HEIGHT = 14,
	
	-- Positioning
	STUDS_OFFSET = Vector3.new(0, 3.5, 0), -- Above head
	MAX_DISTANCE = 100, -- Hide bars beyond this distance
	
	-- Animation
	HEALTH_TWEEN_TIME = 0.3,
	DAMAGE_FLASH_TIME = 0.15,
	
	-- Colors
	HEALTH_HIGH = Color3.fromRGB(76, 209, 55),      -- Green
	HEALTH_MID = Color3.fromRGB(251, 197, 49),       -- Yellow
	HEALTH_LOW = Color3.fromRGB(232, 65, 24),        -- Red
	HEALTH_CRITICAL = Color3.fromRGB(180, 30, 30),   -- Dark Red
	
	BACKGROUND_COLOR = Color3.fromRGB(30, 30, 30),
	BORDER_COLOR = Color3.fromRGB(60, 60, 60),
	DAMAGE_FLASH_COLOR = Color3.fromRGB(255, 255, 255),
	
	-- Name display
	SHOW_NAME = true,
	NAME_TEXT_SIZE = 14,
	NAME_COLOR = Color3.fromRGB(255, 255, 255),
}

-- Track active health bars
local healthBars = {}

-- Known NPC model names (Simple NPCs + Boss NPCs from NPCConfig)
local NPC_NAMES = {
	-- Simple NPCs
	"Spidy", "TorsoGhost", "Skelly", "Robo", "RedPiggy",
	"MamaGhost", "BabyGhost", "FishTank",
	-- Boss NPCs from NPCConfig
	"End", "Beginning", "WorldBreaker", "TheWeepingKing", "TwoFace", "Dice",
	-- Bull
	"bull", "Bull"
}

-- Check if model is an NPC
local function isNPC(model)
	if not model or not model:IsA("Model") then return false end
	
	-- Skip player characters
	local player = Players:GetPlayerFromCharacter(model)
	if player then return false end
	
	-- Must have a Humanoid or Health attribute to be an NPC
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local hasAttributeHealth = model:GetAttribute("Health") ~= nil
	
	if not humanoid and not hasAttributeHealth then
		return false
	end
	
	-- Check by name (case-insensitive)
	local modelNameLower = model.Name:lower()
	for _, npcName in ipairs(NPC_NAMES) do
		if modelNameLower == npcName:lower() or modelNameLower:match("^" .. npcName:lower()) then
			print("[NPCHealthBars] Detected NPC by name:", model.Name)
			return true
		end
	end
	
	-- Check for NPC attributes (set by NPC spawners)
	if model:GetAttribute("SpawnX") or model:GetAttribute("IsNPC") then
		print("[NPCHealthBars] Detected NPC by attribute:", model.Name)
		return true
	end
	
	-- Any model with a Humanoid directly in Workspace (not player) is likely an NPC
	if humanoid and model.Parent == Workspace then
		print("[NPCHealthBars] Detected NPC (Humanoid in Workspace):", model.Name)
		return true
	end
	
	return false
end

-- Get health color based on percentage
local function getHealthColor(percent)
	if percent > 0.6 then
		return CONFIG.HEALTH_HIGH
	elseif percent > 0.3 then
		-- Lerp between yellow and green
		local t = (percent - 0.3) / 0.3
		return CONFIG.HEALTH_MID:Lerp(CONFIG.HEALTH_HIGH, t)
	elseif percent > 0.15 then
		-- Lerp between red and yellow
		local t = (percent - 0.15) / 0.15
		return CONFIG.HEALTH_LOW:Lerp(CONFIG.HEALTH_MID, t)
	else
		return CONFIG.HEALTH_CRITICAL
	end
end

-- Create health bar UI for an NPC
local function createHealthBar(npcModel)
	if healthBars[npcModel] then return end
	
	-- Find head or primary part to attach to
	local attachPart = npcModel:FindFirstChild("Head") 
		or npcModel.PrimaryPart 
		or npcModel:FindFirstChildWhichIsA("BasePart")
	
	if not attachPart then
		warn("[NPCHealthBars] No part to attach health bar for:", npcModel.Name)
		return
	end
	
	-- Get health source
	local humanoid = npcModel:FindFirstChildOfClass("Humanoid")
	local hasAttributeHealth = npcModel:GetAttribute("Health") ~= nil
	
	if not humanoid and not hasAttributeHealth then
		return -- No health system found
	end
	
	-- Create BillboardGui
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "NPCHealthBar"
	billboard.Size = UDim2.new(0, CONFIG.BAR_WIDTH + 10, 0, CONFIG.BAR_HEIGHT + 30)
	billboard.StudsOffset = CONFIG.STUDS_OFFSET
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.MaxDistance = CONFIG.MAX_DISTANCE
	billboard.Adornee = attachPart
	billboard.Parent = attachPart
	
	-- Main container
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundTransparency = 1
	container.Parent = billboard
	
	-- NPC Name Label
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0, 16)
	nameLabel.Position = UDim2.new(0, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = npcModel.Name
	nameLabel.TextColor3 = CONFIG.NAME_COLOR
	nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	nameLabel.TextStrokeTransparency = 0.3
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = CONFIG.NAME_TEXT_SIZE
	nameLabel.TextScaled = false
	nameLabel.Visible = CONFIG.SHOW_NAME
	nameLabel.Parent = container
	
	-- Health bar container (with shadow)
	local barShadow = Instance.new("Frame")
	barShadow.Name = "BarShadow"
	barShadow.Size = UDim2.new(0, CONFIG.BAR_WIDTH + 4, 0, CONFIG.BAR_HEIGHT + 4)
	barShadow.Position = UDim2.new(0.5, -CONFIG.BAR_WIDTH/2 - 2, 0, 16)
	barShadow.BackgroundColor3 = Color3.new(0, 0, 0)
	barShadow.BackgroundTransparency = 0.5
	barShadow.BorderSizePixel = 0
	barShadow.Parent = container
	
	local shadowCorner = Instance.new("UICorner")
	shadowCorner.CornerRadius = UDim.new(0, 6)
	shadowCorner.Parent = barShadow
	
	-- Health bar background
	local barBackground = Instance.new("Frame")
	barBackground.Name = "BarBackground"
	barBackground.Size = UDim2.new(0, CONFIG.BAR_WIDTH, 0, CONFIG.BAR_HEIGHT)
	barBackground.Position = UDim2.new(0.5, -CONFIG.BAR_WIDTH/2, 0, 18)
	barBackground.BackgroundColor3 = CONFIG.BACKGROUND_COLOR
	barBackground.BorderSizePixel = 0
	barBackground.Parent = container
	
	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0, 4)
	bgCorner.Parent = barBackground
	
	-- Border/outline
	local border = Instance.new("UIStroke")
	border.Color = CONFIG.BORDER_COLOR
	border.Thickness = 2
	border.Parent = barBackground
	
	-- Damage flash layer (behind health bar)
	local damageFlash = Instance.new("Frame")
	damageFlash.Name = "DamageFlash"
	damageFlash.Size = UDim2.new(1, -4, 1, -4)
	damageFlash.Position = UDim2.new(0, 2, 0, 2)
	damageFlash.BackgroundColor3 = CONFIG.DAMAGE_FLASH_COLOR
	damageFlash.BackgroundTransparency = 1
	damageFlash.BorderSizePixel = 0
	damageFlash.ZIndex = 1
	damageFlash.Parent = barBackground
	
	local flashCorner = Instance.new("UICorner")
	flashCorner.CornerRadius = UDim.new(0, 3)
	flashCorner.Parent = damageFlash
	
	-- Health bar fill
	local healthFill = Instance.new("Frame")
	healthFill.Name = "HealthFill"
	healthFill.Size = UDim2.new(1, -4, 1, -4)
	healthFill.Position = UDim2.new(0, 2, 0, 2)
	healthFill.BackgroundColor3 = CONFIG.HEALTH_HIGH
	healthFill.BorderSizePixel = 0
	healthFill.ZIndex = 2
	healthFill.Parent = barBackground
	
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 3)
	fillCorner.Parent = healthFill
	
	-- Gradient overlay for shine effect
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(0.5, Color3.new(0.85, 0.85, 0.85)),
		ColorSequenceKeypoint.new(1, Color3.new(0.7, 0.7, 0.7)),
	})
	gradient.Rotation = 90
	gradient.Parent = healthFill
	
	-- Health text
	local healthText = Instance.new("TextLabel")
	healthText.Name = "HealthText"
	healthText.Size = UDim2.new(1, 0, 1, 0)
	healthText.BackgroundTransparency = 1
	healthText.Text = "100%"
	healthText.TextColor3 = Color3.new(1, 1, 1)
	healthText.TextStrokeColor3 = Color3.new(0, 0, 0)
	healthText.TextStrokeTransparency = 0.5
	healthText.Font = Enum.Font.GothamBold
	healthText.TextSize = 10
	healthText.ZIndex = 3
	healthText.Parent = barBackground
	
	-- Store reference
	local healthBarData = {
		billboard = billboard,
		healthFill = healthFill,
		healthText = healthText,
		damageFlash = damageFlash,
		nameLabel = nameLabel,
		npcModel = npcModel,
		humanoid = humanoid,
		lastHealth = humanoid and humanoid.Health or npcModel:GetAttribute("Health") or 100,
		maxHealth = humanoid and humanoid.MaxHealth or npcModel:GetAttribute("MaxHealth") or 100,
	}
	
	healthBars[npcModel] = healthBarData
	
	-- Connect to health changes
	if humanoid then
		humanoid.HealthChanged:Connect(function(newHealth)
			updateHealthBar(healthBarData, newHealth, humanoid.MaxHealth)
		end)
		
		humanoid.Died:Connect(function()
			removeHealthBar(npcModel)
		end)
	end
	
	-- For attribute-based health, we'll poll in the update loop
	
	print("[NPCHealthBars] Created health bar for:", npcModel.Name)
	return healthBarData
end

-- Update health bar visuals
function updateHealthBar(data, currentHealth, maxHealth)
	if not data or not data.billboard.Parent then return end
	
	local percent = math.clamp(currentHealth / maxHealth, 0, 1)
	local targetSize = UDim2.new(percent, -4, 1, -4)
	local targetColor = getHealthColor(percent)
	
	-- Check if damage was taken
	if currentHealth < data.lastHealth then
		-- Flash effect
		data.damageFlash.BackgroundTransparency = 0.3
		TweenService:Create(data.damageFlash, TweenInfo.new(CONFIG.DAMAGE_FLASH_TIME), {
			BackgroundTransparency = 1
		}):Play()
	end
	
	data.lastHealth = currentHealth
	
	-- Animate health bar
	TweenService:Create(data.healthFill, TweenInfo.new(CONFIG.HEALTH_TWEEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = targetSize,
		BackgroundColor3 = targetColor
	}):Play()
	
	-- Update text
	data.healthText.Text = math.floor(currentHealth) .. " / " .. math.floor(maxHealth)
end

-- Remove health bar
function removeHealthBar(npcModel)
	local data = healthBars[npcModel]
	if data then
		if data.billboard then
			data.billboard:Destroy()
		end
		healthBars[npcModel] = nil
		print("[NPCHealthBars] Removed health bar for:", npcModel.Name)
	end
end

-- Scan for NPCs and create health bars
local function scanForNPCs()
	print("[NPCHealthBars] Scanning workspace for NPCs...")
	local foundCount = 0
	
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("Model") then
			-- Debug: Check models with humanoids
			local hum = obj:FindFirstChildOfClass("Humanoid")
			if hum and not Players:GetPlayerFromCharacter(obj) then
				print("[NPCHealthBars] Found model with Humanoid:", obj.Name, "Parent:", obj.Parent and obj.Parent.Name or "nil")
			end
			
			if isNPC(obj) and not healthBars[obj] then
				createHealthBar(obj)
				foundCount = foundCount + 1
			end
		end
	end
	
	print("[NPCHealthBars] Scan complete. Found", foundCount, "NPCs")
end

-- Initial scan (with delay to let NPCs spawn)
task.wait(2)
scanForNPCs()

-- Re-scan periodically to catch late-spawning NPCs
task.spawn(function()
	while true do
		task.wait(5) -- Check every 5 seconds
		for _, obj in ipairs(Workspace:GetChildren()) do
			if obj:IsA("Model") and isNPC(obj) and not healthBars[obj] then
				createHealthBar(obj)
			end
		end
	end
end)

-- Watch for new NPCs
Workspace.DescendantAdded:Connect(function(descendant)
	if descendant:IsA("Model") then
		task.wait(0.5) -- Wait for model to fully load and get attributes
		if isNPC(descendant) then
			createHealthBar(descendant)
		end
	end
end)

-- Watch for removed NPCs
Workspace.DescendantRemoving:Connect(function(descendant)
	if descendant:IsA("Model") and healthBars[descendant] then
		removeHealthBar(descendant)
	end
end)

-- Update loop for attribute-based health and distance checks
RunService.Heartbeat:Connect(function()
	local playerPos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	local playerPosition = playerPos and playerPos.Position
	
	for npcModel, data in pairs(healthBars) do
		if not npcModel.Parent then
			removeHealthBar(npcModel)
			continue
		end
		
		-- Update attribute-based health
		if not data.humanoid then
			local currentHealth = npcModel:GetAttribute("Health") or 0
			local maxHealth = npcModel:GetAttribute("MaxHealth") or 100
			
			if currentHealth ~= data.lastHealth then
				updateHealthBar(data, currentHealth, maxHealth)
			end
			
			-- Remove if dead
			if currentHealth <= 0 then
				task.delay(1, function()
					removeHealthBar(npcModel)
				end)
			end
		end
		
		-- Distance-based visibility (optional enhancement)
		if playerPosition and data.billboard then
			local npcPart = npcModel.PrimaryPart or npcModel:FindFirstChildWhichIsA("BasePart")
			if npcPart then
				local distance = (npcPart.Position - playerPosition).Magnitude
				data.billboard.Enabled = distance <= CONFIG.MAX_DISTANCE
			end
		end
	end
end)

print("[NPCHealthBars] Ready! Tracking", #NPC_NAMES, "NPC types")
