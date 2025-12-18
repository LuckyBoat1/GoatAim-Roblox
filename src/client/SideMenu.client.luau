local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Constants (Premium Dark Arena Theme)
local THEME = {
	BG_DARK = Color3.fromRGB(12, 12, 18),
	BG_MID = Color3.fromRGB(22, 22, 32),
	BG_LIGHT = Color3.fromRGB(35, 35, 50),
	GOLD = Color3.fromRGB(255, 195, 70),
	GOLD_DARK = Color3.fromRGB(180, 130, 40),
	CRIMSON = Color3.fromRGB(220, 50, 70),
	EMBER = Color3.fromRGB(255, 100, 40),
	ABYSS = Color3.fromRGB(140, 60, 200),
	WHITE = Color3.fromRGB(255, 255, 255),
}

local BUTTON_COLORS = {
	{main = THEME.GOLD, dark = THEME.GOLD_DARK},
	{main = THEME.CRIMSON, dark = Color3.fromRGB(150, 30, 50)},
	{main = THEME.EMBER, dark = Color3.fromRGB(180, 60, 20)},
	{main = THEME.ABYSS, dark = Color3.fromRGB(90, 30, 140)},
}

-- Icons
local ICONS = {
	INVENTORY = "rbxthumb://type=Asset&id=104277052032419&w=420&h=420",
	QUESTS = "rbxthumb://type=Asset&id=96245622853577&w=420&h=420",
	SHOP = "rbxthumb://type=Asset&id=91509180731644&w=420&h=420",
	SETTINGS = "rbxassetid://8337535591"
}

-- Create GUI
local gui = Instance.new("ScreenGui")
gui.Name = "SideMenu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 100 -- Always on top of other menus
gui.Parent = playerGui

-- Outer glow layer (creates that premium floating effect)
local outerGlow = Instance.new("Frame")
outerGlow.Name = "OuterGlow"
outerGlow.Size = UDim2.new(0, 95, 0, 385)
outerGlow.Position = UDim2.new(0, 10, 0.5, 0)
outerGlow.AnchorPoint = Vector2.new(0, 0.5)
outerGlow.BackgroundColor3 = THEME.GOLD
outerGlow.BackgroundTransparency = 0.85
outerGlow.BorderSizePixel = 0
outerGlow.ZIndex = 0
outerGlow.Parent = gui
Instance.new("UICorner", outerGlow).CornerRadius = UDim.new(0, 22)

-- Pulse the outer glow
task.spawn(function()
	while outerGlow.Parent do
		TweenService:Create(outerGlow, TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			BackgroundTransparency = 0.75,
			Size = UDim2.new(0, 100, 0, 390)
		}):Play()
		task.wait(2.5)
		TweenService:Create(outerGlow, TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			BackgroundTransparency = 0.9,
			Size = UDim2.new(0, 95, 0, 385)
		}):Play()
		task.wait(2.5)
	end
end)

-- Main container with layered depth
local container = Instance.new("Frame")
container.Name = "Container"
container.Size = UDim2.new(0, 80, 0, 370)
container.Position = UDim2.new(0, 18, 0.5, 0)
container.AnchorPoint = Vector2.new(0, 0.5)
container.BackgroundColor3 = THEME.BG_DARK
container.BorderSizePixel = 0
container.ZIndex = 1
container.Parent = gui

Instance.new("UICorner", container).CornerRadius = UDim.new(0, 16)

-- Inner panel (creates depth)
local innerPanel = Instance.new("Frame")
innerPanel.Name = "InnerPanel"
innerPanel.Size = UDim2.new(1, -8, 1, -8)
innerPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
innerPanel.AnchorPoint = Vector2.new(0.5, 0.5)
innerPanel.BackgroundColor3 = THEME.BG_MID
innerPanel.BorderSizePixel = 0
innerPanel.ZIndex = 2
innerPanel.Parent = container

Instance.new("UICorner", innerPanel).CornerRadius = UDim.new(0, 12)

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

-- Animated accent line (top)
local topLine = Instance.new("Frame")
topLine.Name = "TopLine"
topLine.Size = UDim2.new(0.5, 0, 0, 2)
topLine.Position = UDim2.new(0.25, 0, 0, 12)
topLine.BackgroundColor3 = THEME.GOLD
topLine.BorderSizePixel = 0
topLine.ZIndex = 5
topLine.Parent = innerPanel
Instance.new("UICorner", topLine).CornerRadius = UDim.new(1, 0)

-- Top line glow
local topLineGlow = Instance.new("Frame")
topLineGlow.Size = UDim2.new(1, 6, 1, 6)
topLineGlow.Position = UDim2.new(0.5, 0, 0.5, 0)
topLineGlow.AnchorPoint = Vector2.new(0.5, 0.5)
topLineGlow.BackgroundColor3 = THEME.GOLD
topLineGlow.BackgroundTransparency = 0.6
topLineGlow.BorderSizePixel = 0
topLineGlow.ZIndex = 4
topLineGlow.Parent = topLine
Instance.new("UICorner", topLineGlow).CornerRadius = UDim.new(1, 0)

-- Animate top line
task.spawn(function()
	while topLine.Parent do
		TweenService:Create(topLine, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
			Size = UDim2.new(0.6, 0, 0, 2)
		}):Play()
		TweenService:Create(topLineGlow, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
			BackgroundTransparency = 0.4
		}):Play()
		task.wait(1.5)
		TweenService:Create(topLine, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
			Size = UDim2.new(0.4, 0, 0, 2)
		}):Play()
		TweenService:Create(topLineGlow, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
			BackgroundTransparency = 0.7
		}):Play()
		task.wait(1.5)
	end
end)

-- Bottom accent line
local botLine = topLine:Clone()
botLine.Name = "BotLine"
botLine.Position = UDim2.new(0.25, 0, 1, -14)
botLine.Parent = innerPanel

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
layout.Padding = UDim.new(0, 22)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = buttonContainer

-- Premium button creation
local function createButton(name, iconId, order, callback, customIconSize)
	local colors = BUTTON_COLORS[order] or BUTTON_COLORS[1]
	local mainColor = colors.main
	local darkColor = colors.dark
	
	-- Outer wrapper
	local wrapper = Instance.new("Frame")
	wrapper.Name = name
	wrapper.Size = UDim2.new(0, 56, 0, 56)
	wrapper.BackgroundTransparency = 1
	wrapper.LayoutOrder = order
	wrapper.ZIndex = 3
	wrapper.Parent = buttonContainer
	
	-- Glow layer (behind button)
	local glow = Instance.new("Frame")
	glow.Name = "Glow"
	glow.Size = UDim2.new(1, 20, 1, 20)
	glow.Position = UDim2.new(0.5, 0, 0.5, 0)
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.BackgroundColor3 = mainColor
	glow.BackgroundTransparency = 0.85
	glow.BorderSizePixel = 0
	glow.ZIndex = 2
	glow.Parent = wrapper
	Instance.new("UICorner", glow).CornerRadius = UDim.new(0, 18)
	
	-- Second glow layer for depth
	local glow2 = Instance.new("Frame")
	glow2.Name = "Glow2"
	glow2.Size = UDim2.new(1, 30, 1, 30)
	glow2.Position = UDim2.new(0.5, 0, 0.5, 0)
	glow2.AnchorPoint = Vector2.new(0.5, 0.5)
	glow2.BackgroundColor3 = mainColor
	glow2.BackgroundTransparency = 0.95
	glow2.BorderSizePixel = 0
	glow2.ZIndex = 1
	glow2.Parent = wrapper
	Instance.new("UICorner", glow2).CornerRadius = UDim.new(0, 22)
	
	-- Button base (dark layer)
	local btnBase = Instance.new("Frame")
	btnBase.Name = "ButtonBase"
	btnBase.Size = UDim2.new(1, 0, 1, 0)
	btnBase.Position = UDim2.new(0, 0, 0, 3)
	btnBase.BackgroundColor3 = darkColor
	btnBase.BorderSizePixel = 0
	btnBase.ZIndex = 3
	btnBase.Parent = wrapper
	Instance.new("UICorner", btnBase).CornerRadius = UDim.new(0, 14)
	
	-- Main button
	local btn = Instance.new("TextButton")
	btn.Name = "Button"
	btn.Size = UDim2.new(1, 0, 1, 0)
	btn.Position = UDim2.new(0, 0, 0, 0)
	btn.BackgroundColor3 = THEME.BG_LIGHT
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.BorderSizePixel = 0
	btn.ZIndex = 4
	btn.Parent = wrapper
	
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 14)
	
	-- Button gradient
	local btnGrad = Instance.new("UIGradient")
	btnGrad.Rotation = 135
	btnGrad.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(55, 55, 75)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(38, 38, 55)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(28, 28, 42))
	}
	btnGrad.Parent = btn
	
	-- Animated border stroke
	local btnStroke = Instance.new("UIStroke")
	btnStroke.Thickness = 2
	btnStroke.Transparency = 0.4
	btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	btnStroke.Parent = btn
	
	local strokeGrad = Instance.new("UIGradient")
	strokeGrad.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, mainColor),
		ColorSequenceKeypoint.new(0.5, darkColor),
		ColorSequenceKeypoint.new(1, mainColor)
	}
	strokeGrad.Parent = btnStroke
	
	-- Animate stroke rotation
	task.spawn(function()
		local rot = 0
		while strokeGrad.Parent do
			rot = (rot + 1.5) % 360
			strokeGrad.Rotation = rot
			RunService.Heartbeat:Wait()
		end
	end)
	
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
	iconGlow.Name = "IconGlow"
	iconGlow.Size = UDim2.new(0, size + 8, 0, size + 8)
	iconGlow.Position = UDim2.new(0.5, 0, 0.5, 0)
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
	icon.Position = UDim2.new(0.5, 0, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.BackgroundTransparency = 1
	icon.Image = iconId
	icon.ImageColor3 = Color3.new(1, 1, 1)
	icon.ScaleType = Enum.ScaleType.Fit
	icon.ZIndex = 6
	icon.Parent = btn
	
	-- Hover indicator dot
	local indicator = Instance.new("Frame")
	indicator.Name = "Indicator"
	indicator.Size = UDim2.new(0, 0, 0, 4)
	indicator.Position = UDim2.new(0.5, 0, 1, -8)
	indicator.AnchorPoint = Vector2.new(0.5, 0)
	indicator.BackgroundColor3 = mainColor
	indicator.BorderSizePixel = 0
	indicator.ZIndex = 6
	indicator.Parent = btn
	Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)
	
	-- Hover effects
	btn.MouseEnter:Connect(function()
		TweenService:Create(wrapper, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 64, 0, 64)
		}):Play()
		
		TweenService:Create(glow, TweenInfo.new(0.25), {
			BackgroundTransparency = 0.5,
			Size = UDim2.new(1, 28, 1, 28)
		}):Play()
		
		TweenService:Create(glow2, TweenInfo.new(0.25), {
			BackgroundTransparency = 0.8,
			Size = UDim2.new(1, 40, 1, 40)
		}):Play()
		
		TweenService:Create(btnStroke, TweenInfo.new(0.2), {
			Transparency = 0,
			Thickness = 2.5
		}):Play()
		
		TweenService:Create(iconGlow, TweenInfo.new(0.2), {
			ImageTransparency = 0.4
		}):Play()
		
		TweenService:Create(indicator, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 20, 0, 4)
		}):Play()
	end)
	
	btn.MouseLeave:Connect(function()
		TweenService:Create(wrapper, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
			Size = UDim2.new(0, 56, 0, 56)
		}):Play()
		
		TweenService:Create(glow, TweenInfo.new(0.2), {
			BackgroundTransparency = 0.85,
			Size = UDim2.new(1, 20, 1, 20)
		}):Play()
		
		TweenService:Create(glow2, TweenInfo.new(0.2), {
			BackgroundTransparency = 0.95,
			Size = UDim2.new(1, 30, 1, 30)
		}):Play()
		
		TweenService:Create(btnStroke, TweenInfo.new(0.2), {
			Transparency = 0.4,
			Thickness = 2
		}):Play()
		
		TweenService:Create(iconGlow, TweenInfo.new(0.2), {
			ImageTransparency = 0.7
		}):Play()
		
		TweenService:Create(indicator, TweenInfo.new(0.15), {
			Size = UDim2.new(0, 0, 0, 4)
		}):Play()
	end)
	
	btn.MouseButton1Down:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.06), {
			Position = UDim2.new(0, 0, 0, 3)
		}):Play()
		TweenService:Create(wrapper, TweenInfo.new(0.06), {
			Size = UDim2.new(0, 60, 0, 60)
		}):Play()
		TweenService:Create(glow, TweenInfo.new(0.06), {
			BackgroundTransparency = 0.3
		}):Play()
	end)
	
	btn.MouseButton1Up:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12, Enum.EasingStyle.Back), {
			Position = UDim2.new(0, 0, 0, 0)
		}):Play()
		TweenService:Create(wrapper, TweenInfo.new(0.15, Enum.EasingStyle.Back), {
			Size = UDim2.new(0, 64, 0, 64)
		}):Play()
		TweenService:Create(glow, TweenInfo.new(0.12), {
			BackgroundTransparency = 0.5
		}):Play()
	end)
	
	btn.MouseButton1Click:Connect(function()
		if callback then callback() end
	end)
	
	-- Staggered entrance
	wrapper.Size = UDim2.new(0, 0, 0, 0)
	glow.BackgroundTransparency = 1
	glow2.BackgroundTransparency = 1
	
	task.delay(0.3 + order * 0.12, function()
		TweenService:Create(wrapper, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 56, 0, 56)
		}):Play()
		TweenService:Create(glow, TweenInfo.new(0.5), {
			BackgroundTransparency = 0.85
		}):Play()
		TweenService:Create(glow2, TweenInfo.new(0.6), {
			BackgroundTransparency = 0.95
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
end, 51)

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
end, 46)

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
end, 46)

createButton("SettingsBtn", ICONS.SETTINGS, 4, function()
	print("Settings clicked")
end, 40)

-- Container entrance
container.Position = UDim2.new(0, -100, 0.5, 0)
outerGlow.Position = UDim2.new(0, -100, 0.5, 0)
outerGlow.BackgroundTransparency = 1

task.delay(0.1, function()
	TweenService:Create(container, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 18, 0.5, 0)
	}):Play()
	TweenService:Create(outerGlow, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 10, 0.5, 0)
	}):Play()
	task.wait(0.3)
	TweenService:Create(outerGlow, TweenInfo.new(0.8), {
		BackgroundTransparency = 0.85
	}):Play()
end)
