local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Rs = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

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
container.Size = UDim2.new(0, 97, 0, 474)
container.Position = UDim2.new(0, 19, 0.5, 25)
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
innerPanel.Size = UDim2.new(1, -6, 1, -6)
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
buttonContainer.Size = UDim2.new(1, 0, 1, -50)
buttonContainer.Position = UDim2.new(0, 0, 0.5, 0)
buttonContainer.AnchorPoint = Vector2.new(0, 0.5)
buttonContainer.BackgroundTransparency = 1
buttonContainer.ZIndex = 3
buttonContainer.Parent = innerPanel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 4)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = buttonContainer

-- Premium button creation
local function createButton(name, iconId, order, callback, customIconSize, iconYOffset)
	local colors = BUTTON_COLORS[order] or BUTTON_COLORS[1]
	local mainColor = colors.main
	local darkColor = colors.dark
	
	-- Outer wrapper (colored border with rotating gradient)
	local wrapper = Instance.new("Frame")
	wrapper.Name = name
	wrapper.Size = UDim2.new(0, 89, 0, 89)
	wrapper.BackgroundColor3 = Color3.new(1, 1, 1) -- white so gradient colors are pure
	wrapper.BackgroundTransparency = 0
	wrapper.BorderSizePixel = 0
	wrapper.LayoutOrder = order
	wrapper.ZIndex = 3
	wrapper.Parent = buttonContainer
	
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
	btn.Size = UDim2.new(1, -6, 1, -6)
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
	local size = customIconSize or 36
	local yOff = iconYOffset or 0
	iconGlow.Name = "IconGlow"
	iconGlow.Size = UDim2.new(0, size + 8, 0, size + 8)
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
	icon.Size = UDim2.new(0, size, 0, size)
	icon.Position = UDim2.new(0.5, 0, 0.5, yOff)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.BackgroundTransparency = 1
	icon.Image = iconId
	icon.ImageColor3 = Color3.new(1, 1, 1)
	icon.ScaleType = Enum.ScaleType.Fit
	icon.ZIndex = 6
	icon.Parent = btn
	
	-- Hover effects
	btn.MouseEnter:Connect(function()
		TweenService:Create(wrapper, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 95, 0, 95)
		}):Play()
		
		TweenService:Create(iconGlow, TweenInfo.new(0.2), {
			ImageTransparency = 0.4
		}):Play()
	end)
	
	btn.MouseLeave:Connect(function()
		TweenService:Create(wrapper, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
			Size = UDim2.new(0, 89, 0, 89)
		}):Play()
		
		TweenService:Create(iconGlow, TweenInfo.new(0.15), {
			ImageTransparency = 0.7
		}):Play()
	end)
	
	btn.MouseButton1Down:Connect(function()
		TweenService:Create(wrapper, TweenInfo.new(0.06), {
			Size = UDim2.new(0, 85, 0, 85)
		}):Play()
	end)
	
	btn.MouseButton1Up:Connect(function()
		TweenService:Create(wrapper, TweenInfo.new(0.12, Enum.EasingStyle.Back), {
			Size = UDim2.new(0, 95, 0, 95)
		}):Play()
	end)
	
	btn.MouseButton1Click:Connect(function()
		if callback then callback() end
	end)
	
	-- Staggered entrance
	wrapper.Size = UDim2.new(0, 0, 0, 0)
	
	task.delay(0.3 + order * 0.1, function()
		TweenService:Create(wrapper, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 89, 0, 89)
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
end, 85)

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
end, 141)

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
end, 143, 2)

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
end, 141, 3)

createButton("AbyssBtn", ICONS.ABYSS, 5, function()
	closeAllMenus()
	-- Find AbyssSpawn attachment in workspace
	local function findAbyssSpawn(parent)
		for _, child in parent:GetChildren() do
			if child:IsA("Attachment") and child.Name == "AbyssSpawn" then
				return child
			end
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
				print("[SideMenu] Teleported to Abyss")
				-- Notify server so AbyssPvP can register the player immediately
				local remotes = Rs:WaitForChild("RemoteEvents", 10)
				if not remotes then
					warn("[SideMenu] ❌ RemoteEvents folder NOT FOUND in ReplicatedStorage!")
				else
					local abyssTeleportRE = remotes:WaitForChild("AbyssTeleport", 10)
					if abyssTeleportRE then
						warn("[SideMenu] ✅ Firing AbyssTeleport to server!")
						abyssTeleportRE:FireServer()
					else
						warn("[SideMenu] ❌ AbyssTeleport RemoteEvent NOT FOUND in RemoteEvents!")
						-- List what IS in RemoteEvents for debugging
						for _, child in remotes:GetChildren() do
							warn("  -> RemoteEvents child:", child.Name, child.ClassName)
						end
					end
				end
			end
		end
	else
		warn("[SideMenu] AbyssSpawn attachment not found in workspace")
	end
end, 141, 2)

-- Container entrance
container.Position = UDim2.new(0, -110, 0.5, 25)

task.delay(0.1, function()
	TweenService:Create(container, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 19, 0.5, 25)
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