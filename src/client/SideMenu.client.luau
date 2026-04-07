local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Rs = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local isMobile = UserInputService.TouchEnabled

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--------------------------------------------------------------------------
-- ARENA / DUEL STATE — blocks Abyss teleport while in a match
-- PvpCountdownEvent lives directly in ReplicatedStorage (not RemoteEvents)
--------------------------------------------------------------------------
local inArenaDuel   = false
local _abyssLockOverlay = nil  -- set after button is created
local _abyssLockedAt: number? = nil  -- tick() when lock was set

local function setAbyssLocked(locked)
	inArenaDuel = locked
	if locked then
		_abyssLockedAt = _abyssLockedAt or tick()
	else
		_abyssLockedAt = nil
	end
	if _abyssLockOverlay then
		_abyssLockOverlay.Visible = locked
	end
end

task.spawn(function()
	local pce = Rs:WaitForChild("PvpCountdownEvent", 30)
	if not pce then return end
	pce.OnClientEvent:Connect(function(action)
		if action == "Show" or action == "FightStart" then
			setAbyssLocked(true)
		elseif action == "FightEnd" then
			setAbyssLocked(false)
		end
	end)
end)

-- Dead-man's-switch: if FightEnd is somehow lost, auto-unlock after 90 s.
task.spawn(function()
	local ABYSS_LOCK_MAX = 90
	while true do
		task.wait(5)
		if inArenaDuel and _abyssLockedAt and (tick() - _abyssLockedAt) >= ABYSS_LOCK_MAX then
			warn("[SideMenu] Dead-man's-switch: abyss lock stuck for 90 s, force-unlocking")
			setAbyssLocked(false)
		end
	end
end)

--------------------------------------------------------------------------
-- SKY SWAP helpers (client-local, only affects this player)
--------------------------------------------------------------------------
local _defaultSky = nil
local _abyssSky   = nil
local _skyStash   = nil
local _inAbyssSky = false

local function initSkies()
	_defaultSky = Lighting:FindFirstChild("Sky")
	_abyssSky   = Lighting:FindFirstChild("SkyAbyss")
	if not _defaultSky or not _abyssSky then return end
	_skyStash = Instance.new("Folder")
	_skyStash.Name   = "_SkyStash"
	_skyStash.Parent = Rs
	-- Park SkyAbyss out of Lighting until needed
	_abyssSky.Parent = _skyStash
end

local function activateAbyssSky()
	if _inAbyssSky or not _defaultSky or not _abyssSky then return end
	_inAbyssSky = true
	_defaultSky.Parent = _skyStash
	_abyssSky.Parent   = Lighting
end
_G.activateAbyssSky = activateAbyssSky  -- exposed for AbyssSky.client.luau

_G.RestoreDefaultSky = function()
	-- Re-attempt finding sky objects in case initSkies() ran before they existed
	if not _defaultSky then _defaultSky = Lighting:FindFirstChild("Sky") end
	if not _abyssSky and _skyStash then _abyssSky = _skyStash:FindFirstChildOfClass("Sky") end
	if not _abyssSky then _abyssSky = Lighting:FindFirstChild("AbyssSky") end

	_inAbyssSky = false
	-- Always move abyss sky out of Lighting and default sky back in
	if _abyssSky and _abyssSky.Parent == Lighting then
		_abyssSky.Parent = _skyStash or Rs
	end
	if _defaultSky and _defaultSky.Parent ~= Lighting then
		_defaultSky.Parent = Lighting
	end
end

task.spawn(initSkies)

-- Constants (Premium Dark Arena Theme)
local THEME = {
	BG_DARK = Color3.fromRGB(12, 12, 18),
	BG_MID = Color3.fromRGB(22, 22, 32),
	BG_LIGHT = Color3.fromRGB(35, 35, 50),
	GOLD = Color3.fromRGB(0, 0, 0),
	GOLD_DARK = Color3.fromRGB(0, 0, 0),
	CRIMSON = Color3.fromRGB(220, 50, 70),
	EMBER = Color3.fromRGB(255, 100, 40),
	ABYSS = Color3.fromRGB(140, 60, 200),
	BLUE = Color3.fromRGB(50, 120, 220),
	BLUE_DARK = Color3.fromRGB(30, 70, 150),
	GREEN = Color3.fromRGB(50, 200, 90),
	GREEN_DARK = Color3.fromRGB(30, 130, 55),
	WHITE = Color3.fromRGB(255, 255, 255),
}

local BUTTON_COLORS = {
	{main = THEME.GREEN, dark = THEME.GREEN_DARK}, -- Inventory (green)
	{main = THEME.BLUE, dark = THEME.BLUE_DARK}, -- Quests (blue)
	{main = THEME.CRIMSON, dark = Color3.fromRGB(150, 30, 50)}, -- Shop (red)
	{main = THEME.EMBER, dark = Color3.fromRGB(180, 60, 20)}, -- Headquarters (orange)
	{main = THEME.ABYSS, dark = Color3.fromRGB(90, 30, 140)}, -- Abyss teleport
}

-- Icons
local ICONS = {
	INVENTORY = "rbxthumb://type=Asset&id=104277052032419&w=420&h=420",
	QUESTS = "rbxassetid://109374124083924",
	SHOP = "rbxassetid://71043629499874",
	HEADQUARTERS = "rbxassetid://73736302943571", -- Building/base icon
	ABYSS = "rbxassetid://121736679613445", -- Skull/void icon
}
--
-- Create GUI
local gui = Instance.new("ScreenGui")
gui.Name = "SideMenu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 100 -- Always on top of other menus
gui.Parent = playerGui

-- Main container with layered depth
local container = Instance.new("Frame")
container.Name = "Container"
-- Width = 6.5% of screen (scale). Height is auto-fitted to the buttons below — see fitContainerToButtons.
-- On mobile the container is wider so the buttons and name tabs are large enough to read.
container.Size = UDim2.new(isMobile and 0.0572 or 0.052, 0, 0, 10) -- height filled by fitContainerToButtons
container.Position = UDim2.new(0.01, 0, isMobile and 0.60 or 0.57, 0)
container.AnchorPoint = Vector2.new(0, 0.5)
container.BackgroundColor3 = THEME.BG_DARK
container.BorderSizePixel = 0
container.ZIndex = 1
container.Parent = gui

Instance.new("UICorner", container).CornerRadius = UDim.new(0, 14)

-- Clean thin gold stroke on container
local containerStroke = Instance.new("UIStroke")
containerStroke.Thickness = 3
containerStroke.Color = THEME.GOLD_DARK
containerStroke.Transparency = 0.3
containerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
containerStroke.Parent = container

-- Inner panel
local innerPanel = Instance.new("Frame")
innerPanel.Name = "InnerPanel"
innerPanel.Size = UDim2.new(0.97, 0, 0.97, 0)
innerPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
innerPanel.AnchorPoint = Vector2.new(0.5, 0.5)
innerPanel.BackgroundColor3 = THEME.BG_MID
innerPanel.BorderSizePixel = 0
innerPanel.ZIndex = 2
innerPanel.Parent = container

Instance.new("UICorner", innerPanel).CornerRadius = UDim.new(0, 11)

-- Gradient overlay for premium feel
local innerGrad = Instance.new("UIGradient")
innerGrad.Rotation = 180
innerGrad.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 55)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(25, 25, 38)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 18, 28))
}
innerGrad.Parent = innerPanel

-- Subtle inner stroke
local innerStroke = Instance.new("UIStroke")
innerStroke.Thickness = 1
innerStroke.Color = Color3.fromRGB(60, 60, 80)
innerStroke.Transparency = 0.5
innerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
innerStroke.Parent = innerPanel

-- Button container
local buttonContainer = Instance.new("Frame")
buttonContainer.Name = "ButtonContainer"
buttonContainer.Size = UDim2.new(1, 0, 1, 0)  -- fill innerPanel; buttons scale inside
buttonContainer.Position = UDim2.new(0, 0, 0.5, 0)
buttonContainer.AnchorPoint = Vector2.new(0, 0.5)
buttonContainer.BackgroundTransparency = 1
buttonContainer.ZIndex = 3
buttonContainer.Parent = innerPanel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0.015, 0)  -- ~1.5% of container height between buttons
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = buttonContainer

-- Auto-fit: whenever the UIListLayout recomputes button stack height, resize the
-- container to exactly wrap it.  12% of container width is added as top+bottom breathing room.
-- This fires on every screen resize too (because button px-size changes -> layout changes).
local VERT_PAD_RATIO = 0.12
local CONTAINER_W = isMobile and 0.0572 or 0.052
local function fitContainerToButtons()
	local contentH = layout.AbsoluteContentSize.Y
	local padPx    = container.AbsoluteSize.X * VERT_PAD_RATIO
	container.Size = UDim2.new(CONTAINER_W, 0, 0, contentH + padPx)
end
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(fitContainerToButtons)
local function createButton(name, iconId, order, callback, customIconSize, iconYOffset)
	local colors = BUTTON_COLORS[order] or BUTTON_COLORS[1]
	local mainColor = colors.main
	local darkColor = colors.dark
	
	-- Scale constants (relative to buttonContainer width)
	local BTN_N = UDim2.new(0.88, 0, 0, 0)  -- normal
	local BTN_H = UDim2.new(0.94, 0, 0, 0)  -- hovered / released
	local BTN_P = UDim2.new(0.81, 0, 0, 0)  -- pressed

	-- Icon scale relative to button face (89 was old pixel baseline)
	local rawSize = customIconSize or 36
	local rawGlow = rawSize + 8
	local iconSc  = math.clamp(rawSize / 89, 0.28, 3.0)
	local glowSc  = math.clamp(rawGlow / 89, 0.33, 3.1)
	local yOff    = iconYOffset or 0

	-- Outer wrapper (colored border with rotating gradient)
	local wrapper = Instance.new("Frame")
	wrapper.Name = name
	wrapper.Size = BTN_N  -- scale width; aspect constraint keeps it square
	wrapper.BackgroundColor3 = Color3.new(1, 1, 1) -- white so gradient colors are pure
	wrapper.BackgroundTransparency = 0
	wrapper.BorderSizePixel = 0
	wrapper.LayoutOrder = order
	wrapper.ZIndex = 3
	wrapper.Parent = buttonContainer

	-- Keep the wrapper square on any screen size
	local arc = Instance.new("UIAspectRatioConstraint")
	arc.AspectRatio = 1
	arc.AspectType = Enum.AspectType.ScaleWithParentSize
	arc.DominantAxis = Enum.DominantAxis.Width
	arc.Parent = wrapper
	
	Instance.new("UICorner", wrapper).CornerRadius = UDim.new(0, 14)
	
	-- Rotating gradient on wrapper (the visible colored border)
	local borderGrad = Instance.new("UIGradient")
	borderGrad.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, mainColor),
		ColorSequenceKeypoint.new(0.3, darkColor),
		ColorSequenceKeypoint.new(0.7, mainColor),
		ColorSequenceKeypoint.new(1, darkColor)
	}
	borderGrad.Parent = wrapper
	
	-- Animate border rotation
	task.spawn(function()
		local rot = 0
		while borderGrad.Parent do
			rot = (rot + 2) % 360
			borderGrad.Rotation = rot
			RunService.Heartbeat:Wait()
		end
	end)
	
	-- Main button (inset inside wrapper so color border shows)
	local btn = Instance.new("TextButton")
	btn.Name = "Button"
	btn.Size = UDim2.new(0.94, 0, 0.94, 0)
	btn.Position = UDim2.new(0.5, 0, 0.5, 0)
	btn.AnchorPoint = Vector2.new(0.5, 0.5)
	btn.BackgroundColor3 = THEME.BG_LIGHT
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.BorderSizePixel = 0
	btn.ZIndex = 4
	btn.Parent = wrapper
	
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
	
	-- Button gradient
	local btnGrad = Instance.new("UIGradient")
	btnGrad.Rotation = 135
	btnGrad.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 68)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(32, 32, 48)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(22, 22, 35))
	}
	btnGrad.Parent = btn
	
	

	
	-- Shine highlight
	local shine = Instance.new("Frame")
	shine.Name = "Shine"
	shine.Size = UDim2.new(0.8, 0, 0.35, 0)
	shine.Position = UDim2.new(0.1, 0, 0, 0)
	shine.BackgroundTransparency = 1
	shine.BorderSizePixel = 0
	shine.ZIndex = 5
	shine.Parent = btn
	
	local shineGrad = Instance.new("UIGradient")
	shineGrad.Rotation = 90
	shineGrad.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.7),
		NumberSequenceKeypoint.new(1, 1)
	}
	shineGrad.Color = ColorSequence.new(Color3.new(1, 1, 1))
	shineGrad.Parent = shine
	
	Instance.new("UICorner", shine).CornerRadius = UDim.new(0, 14)
	shine.BackgroundColor3 = Color3.new(1, 1, 1)
	shine.BackgroundTransparency = 0.85
	
	-- Icon glow
	local iconGlow = Instance.new("ImageLabel")
	iconGlow.Name = "IconGlow"
	iconGlow.Size = UDim2.fromScale(glowSc, glowSc)
	iconGlow.Position = UDim2.new(0.5, 0, 0.5, yOff)
	iconGlow.AnchorPoint = Vector2.new(0.5, 0.5)
	iconGlow.BackgroundTransparency = 1
	iconGlow.Image = iconId
	iconGlow.ImageColor3 = mainColor
	iconGlow.ImageTransparency = 0.7
	iconGlow.ScaleType = Enum.ScaleType.Fit
	iconGlow.ZIndex = 5
	iconGlow.Parent = btn
	
	-- Main icon
	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.fromScale(iconSc, iconSc)
	icon.Position = UDim2.new(0.5, 0, 0.5, yOff)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.BackgroundTransparency = 1
	icon.Image = iconId
	icon.ImageColor3 = Color3.new(1, 1, 1)
	icon.ScaleType = Enum.ScaleType.Fit
	icon.ZIndex = 6
	icon.Parent = btn
			-- Vertical name tab — floats to the right of the button, colored to match gradient
		local shortName = name:gsub("Btn", ""):upper()
		if shortName == "HEADQUARTERS" then shortName = "HQ" end

		-- On mobile all name tabs are the same width (including HQ)
		local tabWidthScale = isMobile and 1.0 or 0.65
		local nameTab = Instance.new("Frame")
		nameTab.Name = "NameTab"
		nameTab.Size = UDim2.new(tabWidthScale, 0, 1, 0)
		nameTab.Position = UDim2.new(1.0, 5, 0.5, 0)
		nameTab.AnchorPoint = Vector2.new(0, 0.5)
		nameTab.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
		nameTab.BackgroundTransparency = 0.15
		nameTab.BorderSizePixel = 0
		nameTab.ClipsDescendants = true   -- prevent text overflowing outside the tab
		nameTab.Active = false            -- don't intercept touches; btn (TextButton) handles input
		nameTab.ZIndex = 6
		nameTab.Parent = wrapper
		Instance.new("UICorner", nameTab).CornerRadius = UDim.new(0, 7)
		local tabStroke = Instance.new("UIStroke")
		tabStroke.Thickness = 1.5
		tabStroke.Color = mainColor
		tabStroke.Transparency = 0.25
		tabStroke.Parent = nameTab

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "NameLabel"
		nameLabel.Size = UDim2.new(1, 0, 1, 0)
		nameLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
		nameLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = shortName
		nameLabel.TextColor3 = mainColor
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextScaled = true
		nameLabel.Rotation = -90
		nameLabel.ZIndex = 7
		nameLabel.Parent = nameTab
		nameLabel.Font = Enum.Font.GothamBlack
		local tsc = Instance.new("UITextSizeConstraint")
		if isMobile then
			tsc.MaxTextSize = 60  -- same cap for all tabs including HQ; TextScaled fills the tab
		else
			tsc.MaxTextSize = 36
		end
		tsc.Parent = nameLabel
	-- Hover effects (all sizes are scale-relative to buttonContainer)
	btn.MouseEnter:Connect(function()
		TweenService:Create(wrapper, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = BTN_H
		}):Play()
		
		TweenService:Create(iconGlow, TweenInfo.new(0.2), {
			ImageTransparency = 0.4
		}):Play()
	end)
	
	btn.MouseLeave:Connect(function()
		TweenService:Create(wrapper, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
			Size = BTN_N
		}):Play()
		
		TweenService:Create(iconGlow, TweenInfo.new(0.15), {
			ImageTransparency = 0.7
		}):Play()
	end)
	
	btn.MouseButton1Down:Connect(function()
		TweenService:Create(wrapper, TweenInfo.new(0.06), {
			Size = BTN_P
		}):Play()
	end)
	
	btn.MouseButton1Up:Connect(function()
		TweenService:Create(wrapper, TweenInfo.new(0.12, Enum.EasingStyle.Back), {
			Size = BTN_H
		}):Play()
	end)
	
	btn.MouseButton1Click:Connect(function()
		if callback then callback() end
	end)
	
	-- Staggered entrance: pop in from zero scale to normal scale
	wrapper.Size = UDim2.new(0, 0, 0, 0)
	
	task.delay(0.3 + order * 0.1, function()
		TweenService:Create(wrapper, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = BTN_N
		}):Play()
	end)
	
	return wrapper
end

-- Helper to close all menus
local function closeAllMenus()
	if _G.MatrixInventory and _G.MatrixInventory.IsOpen and _G.MatrixInventory.IsOpen() then
		_G.MatrixInventory.Close()
	end
	if _G.MatrixQuest and _G.MatrixQuest.IsOpen and _G.MatrixQuest.IsOpen() then
		_G.MatrixQuest.Close()
	end
	if _G.MatrixShop and _G.MatrixShop.IsOpen and _G.MatrixShop.IsOpen() then
		_G.MatrixShop.Close()
	end
	if _G.MatrixHeadquarters and _G.MatrixHeadquarters.IsOpen and _G.MatrixHeadquarters.IsOpen() then
		_G.MatrixHeadquarters.Close()
	end
end

-- Create buttons
createButton("InventoryBtn", ICONS.INVENTORY, 1, function()
	if _G.MatrixInventory and _G.MatrixInventory.ToggleInventory then
		local wasOpen = _G.MatrixInventory.IsOpen and _G.MatrixInventory.IsOpen()
		closeAllMenus()
		if not wasOpen then
			_G.MatrixInventory.ToggleInventory()
		end
	else
		warn("Inventory API not found in _G.MatrixInventory")
	end
end, 102)

createButton("QuestsBtn", ICONS.QUESTS, 2, function()
	if _G.MatrixQuest and _G.MatrixQuest.toggleUI then
		local wasOpen = _G.MatrixQuest.IsOpen and _G.MatrixQuest.IsOpen()
		closeAllMenus()
		if not wasOpen then
			_G.MatrixQuest.toggleUI()
		end
	else
		warn("Quest API not found in _G.MatrixQuest")
	end
end, 155)

createButton("ShopBtn", ICONS.SHOP, 3, function()
	if _G.MatrixShop and _G.MatrixShop.Toggle then
		local wasOpen = _G.MatrixShop.IsOpen and _G.MatrixShop.IsOpen()
		closeAllMenus()
		if not wasOpen then
			_G.MatrixShop.Toggle()
		end
	else
		warn("Shop API not found in _G.MatrixShop")
	end
end, 206, 2)

createButton("HeadquartersBtn", ICONS.HEADQUARTERS, 4, function()
	if _G.MatrixHeadquarters and _G.MatrixHeadquarters.Toggle then
		local wasOpen = _G.MatrixHeadquarters.IsOpen and _G.MatrixHeadquarters.IsOpen()
		closeAllMenus()
		if not wasOpen then
			_G.MatrixHeadquarters.Toggle()
		end
	else
		warn("Headquarters API not found in _G.MatrixHeadquarters")
	end
end, 170, 3)

local abyssWrapper = createButton("AbyssBtn", ICONS.ABYSS, 5, function()
	if inArenaDuel then return end  -- silently blocked; overlay makes it obvious
	closeAllMenus()

	local function findAbyssSpawn(parent)
		for _, child in parent:GetChildren() do
			if child:IsA("Attachment") and child.Name == "AbyssSpawn" then return child end
			local found = findAbyssSpawn(child)
			if found then return found end
		end
		return nil
	end

	local attach = findAbyssSpawn(workspace)
	if attach then
		local char = player.Character
		if char then
			local root = char:FindFirstChild("HumanoidRootPart")
			if root then
				root.CFrame = CFrame.new(attach.WorldPosition) + Vector3.new(0, 3, 0)
				activateAbyssSky()
				local remotes = Rs:WaitForChild("RemoteEvents", 10)
				if remotes then
					local abyssTeleportRE = remotes:WaitForChild("AbyssTeleport", 10)
					if abyssTeleportRE then abyssTeleportRE:FireServer() end
				end
			end
		end
	else
		warn("[SideMenu] AbyssSpawn attachment not found in workspace")
	end
end, 170, 2)

-- Build the lock overlay on the Abyss button (mirrors SpawnButton's combat overlay)
do
	local innerBtn = abyssWrapper:FindFirstChild("Button")
	if innerBtn then
		-- Dark translucent cover
		local overlay = Instance.new("Frame")
		overlay.Name        = "LockOverlay"
		overlay.Size        = UDim2.fromScale(1, 1)
		overlay.Position    = UDim2.fromScale(0, 0)
		overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		overlay.BackgroundTransparency = 0.45
		overlay.BorderSizePixel = 0
		overlay.ZIndex      = 20
		overlay.Visible     = false
		overlay.Parent      = innerBtn
		Instance.new("UICorner", overlay).CornerRadius = UDim.new(0, 10)

		-- Lock icon (same padlock rbxasset Roblox uses)
		local lockImg = Instance.new("ImageLabel")
		lockImg.Size             = UDim2.fromScale(0.55, 0.55)
		lockImg.Position         = UDim2.new(0.5, 0, 0.5, 0)
		lockImg.AnchorPoint      = Vector2.new(0.5, 0.5)
		lockImg.BackgroundTransparency = 1
		lockImg.Image            = "rbxassetid://6031094678"  -- standard Roblox lock icon
		lockImg.ImageColor3      = Color3.fromRGB(255, 70, 70)
		lockImg.ScaleType        = Enum.ScaleType.Fit
		lockImg.ZIndex           = 21
		lockImg.Parent           = overlay

		_abyssLockOverlay = overlay
	end
end

-- Trigger an initial fit now that all 5 buttons exist
task.defer(fitContainerToButtons)

-- Container entrance: slide in from off-screen left (all scale, no offsets)
local REST_Y = isMobile and 0.60 or 0.57
container.Position = UDim2.new(-0.1, 0, REST_Y, 0)

task.delay(0.1, function()
	TweenService:Create(container, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.01, 0, REST_Y, 0)
	}):Play()
end)

-- === ZINDEX OVERRIDES ===
-- Edit these numbers to change layering. Higher = renders on top.
for _, wrapper in buttonContainer:GetChildren() do
	if wrapper:IsA("Frame") then
		wrapper.ZIndex = 5           -- colored border frame (gradient)
		local btn = wrapper:FindFirstChild("Button")
		if btn then
			btn.ZIndex = 3           -- dark button face
			local shine = btn:FindFirstChild("Shine")
			if shine then shine.ZIndex = 7 end
		end
		local iconGlow = wrapper:FindFirstChild("IconGlow")
		if iconGlow then iconGlow.ZIndex = 5 end  -- icon glow (behind border)
		local icon = wrapper:FindFirstChild("Icon")
		if icon then icon.ZIndex = 4 end           -- icon image (behind border)
	end
end
--