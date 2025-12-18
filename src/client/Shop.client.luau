local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Load Modules
local CrateConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CrateConfig"))
local SkinConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SkinConfig"))

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local GetPlayerData = RemoteEvents:WaitForChild("GetPlayerData")
local PlayerDataRF = RemoteEvents:WaitForChild("PlayerDataRF")

-- ============================================================================
-- THEME: NEON CYBER (The "Better" Menu Design)
-- ============================================================================
local THEME = {
	BG_TOP = Color3.fromRGB(20, 22, 35),
	BG_BOTTOM = Color3.fromRGB(10, 10, 15),
	
	CARD_BG = Color3.fromRGB(25, 28, 35),
	CARD_HOVER = Color3.fromRGB(35, 38, 45),
	
	ACCENT = Color3.fromRGB(0, 255, 200), -- Cyan Neon
	
	TEXT_MAIN = Color3.fromRGB(255, 255, 255),
	TEXT_DIM = Color3.fromRGB(140, 140, 160),
	
	-- Assets
	GLOW = "rbxassetid://1316045217",
	NOISE = "rbxassetid://12975626680",
}

-- ============================================================================
-- GUI SETUP (Restored Version 4 Layout)
-- ============================================================================
local gui = Instance.new("ScreenGui")
gui.Name = "ShopGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Enabled = false
gui.Parent = playerGui

-- Main Window
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 1000, 0, 650)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = THEME.BG_TOP
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = gui

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 16)

-- Main Gradient (Deep Space Vibe)
local mainGrad = Instance.new("UIGradient")
mainGrad.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, THEME.BG_TOP),
	ColorSequenceKeypoint.new(1, THEME.BG_BOTTOM)
}
mainGrad.Rotation = 45
mainGrad.Parent = mainFrame

-- Background Pattern (Subtle Tech)
local pattern = Instance.new("ImageLabel")
pattern.Size = UDim2.new(1, 0, 1, 0)
pattern.BackgroundTransparency = 1
pattern.Image = "rbxassetid://6071575925" -- Hexagon pattern
pattern.ImageTransparency = 0.95
pattern.ImageColor3 = THEME.ACCENT
pattern.ScaleType = Enum.ScaleType.Tile
pattern.TileSize = UDim2.new(0, 100, 0, 100)
pattern.Parent = mainFrame

-- ============================================================================
-- HEADER AREA (Top Navigation)
-- ============================================================================
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 100)
header.BackgroundTransparency = 1
header.Parent = mainFrame

-- Big Title with Gradient
local title = Instance.new("TextLabel")
title.Size = UDim2.new(0, 300, 1, 0)
title.Position = UDim2.new(0, 30, 0, 0)
title.BackgroundTransparency = 1
title.Text = "STORE"
title.Font = Enum.Font.FredokaOne
title.TextSize = 48
title.TextColor3 = Color3.new(1,1,1)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local titleGrad = Instance.new("UIGradient")
titleGrad.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 150, 150))
}
titleGrad.Rotation = 90
titleGrad.Parent = title

-- Currency Display
local currencyFrame = Instance.new("Frame")
currencyFrame.Size = UDim2.new(0, 150, 0, 40)
currencyFrame.Position = UDim2.new(1, -30, 0.5, 0)
currencyFrame.AnchorPoint = Vector2.new(1, 0.5)
currencyFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
currencyFrame.BackgroundTransparency = 0.5
currencyFrame.Parent = header
Instance.new("UICorner", currencyFrame).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", currencyFrame).Color = Color3.fromRGB(255, 200, 50)
Instance.new("UIStroke", currencyFrame).Thickness = 1

local cashIcon = Instance.new("TextLabel")
cashIcon.Size = UDim2.new(0, 30, 1, 0)
cashIcon.BackgroundTransparency = 1
cashIcon.Text = "$"
cashIcon.TextColor3 = Color3.fromRGB(255, 200, 50)
cashIcon.Font = Enum.Font.FredokaOne
cashIcon.TextSize = 20
cashIcon.Parent = currencyFrame

local cashText = Instance.new("TextLabel")
cashText.Size = UDim2.new(1, -40, 1, 0)
cashText.Position = UDim2.new(0, 30, 0, 0)
cashText.BackgroundTransparency = 1
cashText.Text = "12,500" -- Placeholder
cashText.TextColor3 = Color3.fromRGB(255, 255, 255)
cashText.Font = Enum.Font.GothamMedium
cashText.TextSize = 18
cashText.TextXAlignment = Enum.TextXAlignment.Left
cashText.Parent = currencyFrame

-- ============================================================================
-- TABS (Pill Style - Restored)
-- ============================================================================
local tabContainer = Instance.new("Frame")
tabContainer.Size = UDim2.new(0, 400, 0, 50)
tabContainer.Position = UDim2.new(0.5, 0, 0, 25)
tabContainer.AnchorPoint = Vector2.new(0.5, 0)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = header

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabLayout.Padding = UDim.new(0, 15)
tabLayout.Parent = tabContainer

local tabs = {}
local currentTab = nil

-- ============================================================================
-- CONTENT AREA
-- ============================================================================
local content = Instance.new("Frame")
content.Size = UDim2.new(1, 0, 1, -100)
content.Position = UDim2.new(0, 0, 0, 100)
content.BackgroundTransparency = 1
content.Parent = mainFrame

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -60, 1, -20)
scroll.Position = UDim2.new(0, 30, 0, 0)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = THEME.ACCENT
scroll.Parent = content

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.new(0, 220, 0, 300) -- Tall cards
grid.CellPadding = UDim2.new(0, 20, 0, 20)
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
grid.Parent = scroll

-- ============================================================================
-- CARD CREATION (The "Better" Cards from Version 5)
-- ============================================================================
local function createCard(name, rarityColor, price, modelKey, layoutOrder, modelName)
	local card = Instance.new("TextButton")
	card.Name = name
	card.BackgroundColor3 = THEME.CARD_BG
	card.BorderSizePixel = 0
	card.Text = ""
	card.AutoButtonColor = false
	card.LayoutOrder = layoutOrder
	card.ClipsDescendants = true
	card.Parent = scroll
	
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 16)
	
	-- 1. Animated Gradient Stroke
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Transparency = 0.5
	stroke.Color = THEME.CARD_HOVER
	stroke.Parent = card
	
	-- 2. Background Glow (Pulsing)
	local bgGlow = Instance.new("ImageLabel")
	bgGlow.Size = UDim2.new(1.4, 0, 1.4, 0)
	bgGlow.Position = UDim2.new(0.5, 0, 0.4, 0)
	bgGlow.AnchorPoint = Vector2.new(0.5, 0.5)
	bgGlow.BackgroundTransparency = 1
	bgGlow.Image = THEME.GLOW
	bgGlow.ImageColor3 = rarityColor
	bgGlow.ImageTransparency = 0.85
	bgGlow.Parent = card
	
	-- Pulse Animation
	task.spawn(function()
		while card.Parent do
			TweenService:Create(bgGlow, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {ImageTransparency = 0.7}):Play()
			task.wait(4)
		end
	end)
	
	-- 3. Viewport (3D Item)
	local viewport = Instance.new("ViewportFrame")
	viewport.Size = UDim2.new(0, 200, 0, 200)
	viewport.Position = UDim2.new(0.5, 0, 0.38, 0)
	viewport.AnchorPoint = Vector2.new(0.5, 0.5)
	viewport.BackgroundTransparency = 1
	viewport.Parent = card
	
	local camera = Instance.new("Camera")
	viewport.CurrentCamera = camera
	camera.Parent = viewport
	
	-- Model Logic
	local CrateModels = ReplicatedStorage:WaitForChild("Crates")
	-- Use explicit modelName if provided, otherwise fallback to key
	local targetModelName = modelName or modelKey
	local modelTemplate = CrateModels:FindFirstChild(targetModelName)
	
	if modelTemplate then
		local model = modelTemplate:Clone()
		model.Parent = viewport
		
		local cf, size
		if model:IsA("Model") then
			cf, size = model:GetBoundingBox()
		elseif model:IsA("BasePart") then
			cf = model.CFrame
			size = model.Size
		end
		
		if cf and size then
			-- Robust Centering: Set Pivot to Center, then Move to Origin
			if model:IsA("Model") then
				model.WorldPivot = cf
			end
			
			model:PivotTo(CFrame.new(0, 0, 0))
			
			if modelKey == "BASIC" or modelKey == "SAPPHIRE" then
				model:PivotTo(model:GetPivot() * CFrame.Angles(0, math.rad(90), 0))
			end
			
			local zoom = (modelKey == "OMEGA" or modelKey == "RUBY") and 1.2 or 1.0
			local dist = math.max(size.X, size.Y, size.Z) * zoom
			camera.CFrame = CFrame.new(Vector3.new(0, dist * 0.4, dist), Vector3.new(0, 0, 0))
			
			-- Float Only
			task.spawn(function()
				local t = 0
				while card.Parent do
					t = t + 0.02
					viewport.Position = UDim2.new(0.5, 0, 0.38 + (math.sin(t * 1.5) * 0.02), 0)
					RunService.Heartbeat:Wait()
				end
			end)
		end
	end
	
	-- 4. Info Area (Glass Panel)
	local info = Instance.new("Frame")
	info.Size = UDim2.new(1, 0, 0.32, 0)
	info.Position = UDim2.new(0, 0, 1, 0)
	info.AnchorPoint = Vector2.new(0, 1)
	info.BackgroundColor3 = Color3.fromRGB(15, 18, 22)
	info.BorderSizePixel = 0
	info.Parent = card
	
	-- Top Border of Info
	local infoLine = Instance.new("Frame")
	infoLine.Size = UDim2.new(1, 0, 0, 1)
	infoLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	infoLine.BackgroundTransparency = 0.9
	infoLine.BorderSizePixel = 0
	infoLine.Parent = info
	
	-- Rarity Gem (Visual Detail)
	local gem = Instance.new("Frame")
	gem.Size = UDim2.new(0, 8, 0, 8)
	gem.Position = UDim2.new(0, 15, 0, 15)
	gem.BackgroundColor3 = rarityColor
	gem.Parent = info
	Instance.new("UICorner", gem).CornerRadius = UDim.new(0, 2)
	
	local gemGlow = Instance.new("ImageLabel")
	gemGlow.Size = UDim2.new(3, 0, 3, 0)
	gemGlow.Position = UDim2.new(0.5, 0, 0.5, 0)
	gemGlow.AnchorPoint = Vector2.new(0.5, 0.5)
	gemGlow.BackgroundTransparency = 1
	gemGlow.Image = THEME.GLOW
	gemGlow.ImageColor3 = rarityColor
	gemGlow.ImageTransparency = 0.5
	gemGlow.Parent = gem
	
	-- Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -40, 0, 20)
	nameLabel.Position = UDim2.new(0, 30, 0, 9)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = string.upper(name)
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextSize = 14
	nameLabel.TextColor3 = THEME.TEXT_MAIN
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = info
	
	-- Buy Button (Gradient)
	local buyBtn = Instance.new("Frame")
	buyBtn.Size = UDim2.new(1, -30, 0, 36)
	buyBtn.Position = UDim2.new(0.5, 0, 0.85, 0)
	buyBtn.AnchorPoint = Vector2.new(0.5, 1)
	buyBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	buyBtn.Parent = info
	
	Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0, 8)
	
	local btnGrad = Instance.new("UIGradient")
	btnGrad.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, rarityColor),
		ColorSequenceKeypoint.new(1, Color3.new(rarityColor.R*0.6, rarityColor.G*0.6, rarityColor.B*0.6))
	}
	btnGrad.Parent = buyBtn
	
	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(1, 0, 1, 0)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Text = (price == 0) and "OPEN FREE" or "$ " .. price
	priceLabel.Font = Enum.Font.FredokaOne
	priceLabel.TextSize = 14
	priceLabel.TextColor3 = Color3.new(0.1, 0.1, 0.1)
	priceLabel.Parent = buyBtn
	
	-- 5. Sheen Effect (The "Premium" Shine)
	local sheen = Instance.new("Frame")
	sheen.Size = UDim2.new(0.5, 0, 2, 0)
	sheen.Position = UDim2.new(-1, 0, -0.5, 0)
	sheen.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	sheen.BackgroundTransparency = 1
	sheen.Rotation = 20
	sheen.ZIndex = 10
	sheen.Parent = card
	
	local sheenGrad = Instance.new("UIGradient")
	sheenGrad.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.8),
		NumberSequenceKeypoint.new(1, 1)
	}
	sheenGrad.Parent = sheen
	
	-- Hover Logic
	card.MouseEnter:Connect(function()
		TweenService:Create(card, TweenInfo.new(0.2), {BackgroundColor3 = THEME.CARD_HOVER}):Play()
		TweenService:Create(stroke, TweenInfo.new(0.2), {Transparency = 0, Color = rarityColor}):Play()
		TweenService:Create(bgGlow, TweenInfo.new(0.3), {ImageTransparency = 0.5, Size = UDim2.new(1.6, 0, 1.6, 0)}):Play()
		TweenService:Create(viewport, TweenInfo.new(0.3), {Size = UDim2.new(0, 220, 0, 220)}):Play()
		
		-- Play Sheen
		sheen.Position = UDim2.new(-1, 0, -0.5, 0)
		TweenService:Create(sheen, TweenInfo.new(0.6), {Position = UDim2.new(2, 0, -0.5, 0)}):Play()
	end)
	
	card.MouseLeave:Connect(function()
		TweenService:Create(card, TweenInfo.new(0.2), {BackgroundColor3 = THEME.CARD_BG}):Play()
		TweenService:Create(stroke, TweenInfo.new(0.2), {Transparency = 0.5, Color = THEME.CARD_HOVER}):Play()
		TweenService:Create(bgGlow, TweenInfo.new(0.3), {ImageTransparency = 0.85, Size = UDim2.new(1.4, 0, 1.4, 0)}):Play()
		TweenService:Create(viewport, TweenInfo.new(0.3), {Size = UDim2.new(0, 200, 0, 200)}):Play()
	end)
	
	card.MouseButton1Click:Connect(function()
		print("Buying " .. name)
		
		-- Debounce check (simple)
		if card:GetAttribute("Buying") then return end
		card:SetAttribute("Buying", true)
		
		-- Visual Feedback
		buyBtn.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
		priceLabel.Text = "..."
		
		task.spawn(function()
			local success, result = pcall(function()
				return PlayerDataRF:InvokeServer("BuyItem", {itemKey = modelKey})
			end)
			
			if success and result and result.success then
				-- Success!
				priceLabel.Text = "BOUGHT!"
				buyBtn.BackgroundColor3 = Color3.fromRGB(50, 255, 100)
				updateCurrency() -- Refresh money
				
				task.wait(1)
				priceLabel.Text = (price == 0) and "OPEN FREE" or "$ " .. price
				buyBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			else
				-- Fail
				priceLabel.Text = "FAILED"
				buyBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
				warn("Purchase failed:", result and result.error or "Unknown error")
				
				task.wait(1)
				priceLabel.Text = (price == 0) and "OPEN FREE" or "$ " .. price
				buyBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			end
			
			card:SetAttribute("Buying", nil)
		end)
	end)
end

-- ============================================================================
-- TAB LOGIC (Restored Pill Tabs)
-- ============================================================================
local function clearContent()
	for _, c in ipairs(scroll:GetChildren()) do
		if not c:IsA("UIGridLayout") then c:Destroy() end
	end
end

local function loadCrates()
	local CRATE_ORDER = {"BRONZE", "SILVER", "SAPPHIRE", "OMEGA", "RUBY"}
	for i, key in ipairs(CRATE_ORDER) do
		local data = CrateConfig.Crates[key]
		if data then
			createCard(data.name, data.color, data.openCost, key, i, data.modelName)
		end
	end
end

local function switchTab(name)
	if currentTab == name then return end
	currentTab = name
	
	for tName, btn in pairs(tabs) do
		local isSelected = (tName == name)
		local targetColor = isSelected and THEME.ACCENT or THEME.TEXT_DIM
		local targetStroke = isSelected and 1 or 0
		
		TweenService:Create(btn.TextLabel, TweenInfo.new(0.2), {TextColor3 = targetColor}):Play()
		TweenService:Create(btn.UIStroke, TweenInfo.new(0.2), {Transparency = isSelected and 0 or 1}):Play()
		TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundTransparency = isSelected and 0.8 or 1}):Play()
	end
	
	clearContent()
	if name == "CRATES" then loadCrates() end
end

local function createTab(name)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(0, 100, 0, 36)
	btn.BackgroundColor3 = THEME.ACCENT
	btn.BackgroundTransparency = 1
	btn.Text = ""
	btn.Parent = tabContainer
	
	Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0) -- Pill shape
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = THEME.ACCENT
	stroke.Thickness = 2
	stroke.Transparency = 1
	stroke.Parent = btn
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = name
	label.Font = Enum.Font.FredokaOne
	label.TextSize = 14
	label.TextColor3 = THEME.TEXT_DIM
	label.Parent = btn
	
	btn.MouseButton1Click:Connect(function() switchTab(name) end)
	tabs[name] = btn
end

createTab("CRATES")
createTab("WEAPONS")
createTab("BUNDLES")

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -20, 0, 20)
closeBtn.AnchorPoint = Vector2.new(1, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.Font = Enum.Font.FredokaOne
closeBtn.Parent = mainFrame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1, 0)

local function updateCurrency()
	task.spawn(function()
		local success, data = pcall(function()
			return GetPlayerData:InvokeServer()
		end)
		if success and data and data.money then
			-- Format with commas
			local formatted = tostring(data.money):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
			cashText.Text = formatted
		end
	end)
end

local function toggle()
	gui.Enabled = not gui.Enabled
	if gui.Enabled then
		updateCurrency()
		if not currentTab then switchTab("CRATES") end
		mainFrame.Size = UDim2.new(0, 0, 0, 0)
		TweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back), {Size = UDim2.new(0, 1000, 0, 650)}):Play()
	end
end

local function close()
	if gui.Enabled then
		gui.Enabled = false
	end
end

closeBtn.MouseButton1Click:Connect(toggle)
_G.MatrixShop = { Toggle = toggle, IsOpen = function() return gui.Enabled end, Close = close }

return _G.MatrixShop