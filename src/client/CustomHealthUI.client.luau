-- CustomHealthUI.client.luau
-- Connects HealthManager to your custom health bar GUI

print("🔵 [CustomHealthUI] Script is loading...")

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

print("🔵 [CustomHealthUI] Services loaded")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("🔵 [CustomHealthUI] PlayerGui found, searching for Health GUI...")

-- Wait for your Health GUI (it gets copied from StarterGui to PlayerGui when player joins)
local healthGui = playerGui:WaitForChild("Health", 10)
if not healthGui then
	warn("[CustomHealthUI] ❌ Health ScreenGui not found in PlayerGui!")
	return
end

local frame = healthGui:FindFirstChild("Frame")
if not frame then
	warn("[CustomHealthUI] ❌ Frame not found in Health!")
	return
end

local canvasGroup = frame:FindFirstChild("CanvasGroup")
if not canvasGroup then
	warn("[CustomHealthUI] ❌ CanvasGroup not found in Frame!")
	return
end

local healthText = canvasGroup:FindFirstChild("TextLabel")
if not healthText then
	warn("[CustomHealthUI] ❌ TextLabel not found in CanvasGroup!")
	return
end

local healthBar = canvasGroup:FindFirstChild("Health")
if not healthBar then
	warn("[CustomHealthUI] ❌ Health ImageLabel not found in CanvasGroup!")
	return
end

print("[CustomHealthUI] ✅ Found all GUI elements successfully")

-- Set nice font for health text
healthText.Font = Enum.Font.LuckiestGuy
healthText.FontFace = Font.fromEnum(Enum.Font.LuckiestGuy)
-- Set initial text so it doesn't show "Label"
healthText.Text = "100 / 100"

-- Store original health bar size to preserve offsets
local originalHealthBarSize = healthBar.Size

-- Remote events
local RemoteEvents = RS:WaitForChild("RemoteEvents")
local HealthUpdateRE = RemoteEvents:WaitForChild("HealthUpdate")

-- Update the health bar
local function updateHealthBar(health, maxHealth, animated)
	health = math.clamp(health or 0, 0, maxHealth or 100)
	maxHealth = math.max(maxHealth or 100, 1)
	
	local healthPercent = health / maxHealth
	
	-- Update text
	healthText.Text = string.format("%d / %d", math.floor(health), math.floor(maxHealth))
	
	-- Scale based on original size, preserving Y completely
	local targetSize = UDim2.new(
		originalHealthBarSize.X.Scale * healthPercent, 
		originalHealthBarSize.X.Offset * healthPercent,
		originalHealthBarSize.Y.Scale, 
		originalHealthBarSize.Y.Offset
	)
	
	if animated then
		local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local tween = TweenService:Create(healthBar, tweenInfo, {Size = targetSize})
		tween:Play()
	else
		healthBar.Size = targetSize
	end
end

-- Listen for health updates from server
HealthUpdateRE.OnClientEvent:Connect(function(data)
	if not data then return end
	
	-- Check if health mode was enabled/disabled
	if data.enabled ~= nil then
		healthGui.Enabled = data.enabled
		if not data.enabled then
			return
		end
	end
	
	-- Update health if provided
	if data.health and data.maxHealth then
		updateHealthBar(data.health, data.maxHealth, true)
	end
end)

-- Also listen to actual Humanoid health changes (for direct damage like bull stomps)
local function connectToHumanoid()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid", 10)
	
	if humanoid then
		-- Initial update
		updateHealthBar(humanoid.Health, humanoid.MaxHealth, false)
		
		-- Listen for health changes
		humanoid.HealthChanged:Connect(function(newHealth)
			updateHealthBar(newHealth, humanoid.MaxHealth, true)
		end)
		
		print("[CustomHealthUI] ✅ Connected to Humanoid health")
	end
end

-- Function to refresh GUI references after respawn
local function refreshGUIReferences()
	-- Wait for new GUI to be ready
	task.wait(0.5)
	
	-- Get fresh references
	local newHealthGui = playerGui:FindFirstChild("Health")
	if not newHealthGui then return end
	
	local newFrame = newHealthGui:FindFirstChild("Frame")
	if not newFrame then return end
	
	local newCanvasGroup = newFrame:FindFirstChild("CanvasGroup")
	if not newCanvasGroup then return end
	
	local newHealthText = newCanvasGroup:FindFirstChild("TextLabel")
	local newHealthBar = newCanvasGroup:FindFirstChild("Health")
	
	if newHealthText and newHealthBar then
		-- Update our references
		healthGui = newHealthGui
		healthText = newHealthText
		healthBar = newHealthBar
		originalHealthBarSize = healthBar.Size
		
		-- Set font
		healthText.Font = Enum.Font.LuckiestGuy
		healthText.FontFace = Font.fromEnum(Enum.Font.LuckiestGuy)
		
		print("[CustomHealthUI] ✅ GUI references refreshed after respawn")
	end
end

-- Connect to current character
connectToHumanoid()

-- Reconnect when player respawns
player.CharacterAdded:Connect(function()
	refreshGUIReferences() -- Get new GUI references first
	connectToHumanoid() -- Then connect to new humanoid
end)

print("[CustomHealthUI] ✅ Custom health UI connected")
