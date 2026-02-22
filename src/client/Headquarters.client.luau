-- Headquarters UI Controller
-- Handles the HQ menu with Upgrades, Storage, and PvP Stats

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Load modules for Storage item display
local SkinConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SkinConfig"))
local MythicEffects = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MythicEffects"))
local MythicAura = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MythicAura"))
local LegendaryAura = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("LegendaryAura"))
local EpicAura = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("EpicAura"))
local RareAura = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RareAura"))
local CommonAura = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CommonAura"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for HeadQuarters GUI
local headquartersGui = playerGui:WaitForChild("HeadQuarters", 10)
if not headquartersGui then
	warn("[Headquarters] HeadQuarters GUI not found in PlayerGui")
	return
end
--
local mainFrame = headquartersGui:WaitForChild("Main")

-- Storage panel inside HeadQuarters (added in Studio, separate from the button in Main)
local storagePanelFrame = headquartersGui:FindFirstChild("Storage")

-- Upgrades panel inside HeadQuarters (added in Studio with child frames for each upgrade)
local upgradesPanelFrame = headquartersGui:FindFirstChild("Upgrades")

-- Get frames from Main (use FindFirstChild to avoid infinite hangs if user moved frames)
local topFrame = mainFrame:WaitForChild("Top", 5) or mainFrame:FindFirstChild("Top")
local upgradesFrame = mainFrame:FindFirstChild("Upgrades") -- BUTTON in Main (may not exist)
local storageFrame = mainFrame:FindFirstChild("Storage")  -- BUTTON in Main (may not exist)
local middleFrame = mainFrame:WaitForChild("Middle", 5) or mainFrame:FindFirstChild("Middle")

-- Setup text labels
local function setupLabel(frame, text, fontSize)
	local textLabel = frame:FindFirstChild("TextLabel")
	if textLabel then
		textLabel.Text = text
		textLabel.Font = Enum.Font.FredokaOne
		textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		textLabel.TextSize = fontSize or 24
		textLabel.TextStrokeTransparency = 0.8
		textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	end
end

-- Setup all labels
if topFrame then setupLabel(topFrame, "HEADQUARTERS", 32) end
if upgradesFrame then setupLabel(upgradesFrame, "UPGRADES", 22) end
if storageFrame then setupLabel(storageFrame, "STORAGE", 22) end

-- Hover effect colors
local hoverColor = Color3.fromRGB(255, 100, 120)

-- Store original properties for restoration
local originalProps = {}

-- Create hover effects for clickable frames
local function addHoverEffect(frame)
	local imageLabel = frame:FindFirstChild("ImageLabel")
	local textLabel = frame:FindFirstChild("TextLabel")
	if not imageLabel then return end
	
	-- Store originals
	originalProps[frame] = {
		size = frame.Size,
		imageColor = imageLabel.ImageColor3,
		textSize = textLabel and textLabel.TextSize or 22,
		rotation = frame.Rotation
	}
	
	local orig = originalProps[frame]
	local isHovering = false
	
	frame.MouseEnter:Connect(function()
		isHovering = true
		
		-- Scale up frame
		TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(orig.size.X.Scale * 1.05, orig.size.X.Offset, orig.size.Y.Scale * 1.05, orig.size.Y.Offset)
		}):Play()
		
		-- Brighten image
		TweenService:Create(imageLabel, TweenInfo.new(0.15), {
			ImageColor3 = Color3.fromRGB(
				math.min(255, orig.imageColor.R * 255 + 40),
				math.min(255, orig.imageColor.G * 255 + 40),
				math.min(255, orig.imageColor.B * 255 + 40)
			)
		}):Play()
		
		-- Pop text
		if textLabel then
			TweenService:Create(textLabel, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				TextSize = orig.textSize + 3,
				TextColor3 = Color3.fromRGB(255, 255, 150)
			}):Play()
		end
		
		-- Subtle wobble (always ends at original rotation)
		task.spawn(function()
			TweenService:Create(frame, TweenInfo.new(0.08), { Rotation = orig.rotation + 2 }):Play()
			task.wait(0.08)
			TweenService:Create(frame, TweenInfo.new(0.08), { Rotation = orig.rotation - 2 }):Play()
			task.wait(0.08)
			TweenService:Create(frame, TweenInfo.new(0.08), { Rotation = orig.rotation + 1 }):Play()
			task.wait(0.08)
			TweenService:Create(frame, TweenInfo.new(0.08), { Rotation = orig.rotation - 1 }):Play()
			task.wait(0.08)
			TweenService:Create(frame, TweenInfo.new(0.08), { Rotation = orig.rotation }):Play()
		end)
	end)
	
	frame.MouseLeave:Connect(function()
		isHovering = false
		
		-- Restore frame size and ensure rotation is back to original
		TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = orig.size,
			Rotation = orig.rotation
		}):Play()
		
		-- Restore image color
		TweenService:Create(imageLabel, TweenInfo.new(0.15), {
			ImageColor3 = orig.imageColor
		}):Play()
		
		-- Restore text
		if textLabel then
			TweenService:Create(textLabel, TweenInfo.new(0.15), {
				TextSize = orig.textSize,
				TextColor3 = Color3.fromRGB(255, 255, 255)
			}):Play()
		end
	end)
	
	-- Click effect - bounce and flash
	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			-- Quick squish
			TweenService:Create(frame, TweenInfo.new(0.08), {
				Size = UDim2.new(orig.size.X.Scale * 0.95, orig.size.X.Offset, orig.size.Y.Scale * 0.95, orig.size.Y.Offset)
			}):Play()
			
			-- Flash white
			TweenService:Create(imageLabel, TweenInfo.new(0.05), {
				ImageColor3 = Color3.fromRGB(255, 255, 255)
			}):Play()
			
			task.delay(0.08, function()
				-- Bounce back bigger
				TweenService:Create(frame, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
					Size = UDim2.new(orig.size.X.Scale * 1.08, orig.size.X.Offset, orig.size.Y.Scale * 1.08, orig.size.Y.Offset)
				}):Play()
				
				task.delay(0.15, function()
					-- Settle to hover size if still hovering
					local targetSize = isHovering 
						and UDim2.new(orig.size.X.Scale * 1.05, orig.size.X.Offset, orig.size.Y.Scale * 1.05, orig.size.Y.Offset)
						or orig.size
					TweenService:Create(frame, TweenInfo.new(0.1), {
						Size = targetSize
					}):Play()
					
					TweenService:Create(imageLabel, TweenInfo.new(0.1), {
						ImageColor3 = isHovering 
							and Color3.fromRGB(
								math.min(255, orig.imageColor.R * 255 + 40),
								math.min(255, orig.imageColor.G * 255 + 40),
								math.min(255, orig.imageColor.B * 255 + 40)
							)
							or orig.imageColor
					}):Play()
				end)
			end)
			
			print("[Headquarters] Clicked:", frame.Name)
		end
	end)
end

-- Add hover effects to Upgrades and Storage (if buttons exist in Main)
if upgradesFrame then addHoverEffect(upgradesFrame) end
if storageFrame then addHoverEffect(storageFrame) end

-- Add subtle pulse to Top frame title
task.spawn(function()
	if not topFrame then return end
	local topText = topFrame:FindFirstChild("TextLabel")
	if topText then
		while topText and topText.Parent do
			TweenService:Create(topText, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				TextColor3 = Color3.fromRGB(255, 220, 150)
			}):Play()
			task.wait(1.5)
			TweenService:Create(topText, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				TextColor3 = Color3.fromRGB(255, 255, 255)
			}):Play()
			task.wait(1.5)
		end
	end
end)

-- State
local isOpen = false
local currentView = "main" -- "main", "storage", or "upgrades"

--------------------------------------------------------------------------
-- HQ STATS PANEL — built into the Middle frame
--------------------------------------------------------------------------
local GetPlayerDataRF = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
	and ReplicatedStorage.RemoteEvents:FindFirstChild("GetPlayerData")

-- PlayerDataRF handles actions (MoveToStorage, MoveFromStorage, HQUpgrade, etc.)
local PlayerDataRF = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
	and ReplicatedStorage.RemoteEvents:FindFirstChild("PlayerDataRF")

-- Format numbers with K/M notation
local function formatNumber(num)
	num = num or 0
	if num >= 1000000 then
		return string.format("%.1f", num / 1000000):gsub("%.0$", "") .. "M"
	elseif num >= 1000 then
		return string.format("%.1f", num / 1000):gsub("%.0$", "") .. "K"
	end
	return tostring(num)
end

-- Build the stats container inside the Middle frame
local statsContainer = Instance.new("Frame")
statsContainer.Name = "HQStatsPanel"
statsContainer.Size = UDim2.new(1, 0, 1, 0)
statsContainer.Position = UDim2.new(0, 0, 0, 0)
statsContainer.BackgroundTransparency = 1
statsContainer.Parent = middleFrame

-- Grid layout for stat cards (5 cards: 3 top + 2 bottom centered)
local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0.3, 0, 0.42, 0)
gridLayout.CellPadding = UDim2.new(0.025, 0, 0.04, 0)
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
gridLayout.VerticalAlignment = Enum.VerticalAlignment.Center
gridLayout.FillDirection = Enum.FillDirection.Horizontal
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.Parent = statsContainer

local statCards = {}

-- New stat card definitions: Health, Armor, Rank, Gold/sec, Crates/day
local statDefs = {
	{ key = "health",      label = "HEALTH",       icon = "❤️", color = Color3.fromRGB(220, 60, 60)  },
	{ key = "armor",       label = "ARMOR",        icon = "🛡️", color = Color3.fromRGB(80, 160, 255)  },
	{ key = "rank",        label = "RANK",         icon = "⭐", color = Color3.fromRGB(255, 200, 50)  },
	{ key = "goldPerSec",  label = "GOLD/SEC",     icon = "💰", color = Color3.fromRGB(80, 220, 120)  },
	{ key = "cratesPerDay",label = "CRATES/DAY",   icon = "📦", color = Color3.fromRGB(180, 130, 255) },
}

for i, def in ipairs(statDefs) do
	-- Card background
	local card = Instance.new("Frame")
	card.Name = "Card_" .. def.key
	card.LayoutOrder = i
	card.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	card.BackgroundTransparency = 0.15
	card.Parent = statsContainer

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0.15, 0)
	cardCorner.Parent = card

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = def.color
	cardStroke.Thickness = 2
	cardStroke.Transparency = 0.4
	cardStroke.Parent = card

	-- Accent gradient bar at top
	local accentBar = Instance.new("Frame")
	accentBar.Name = "Accent"
	accentBar.Size = UDim2.new(1, 0, 0.06, 0)
	accentBar.Position = UDim2.new(0, 0, 0, 0)
	accentBar.BackgroundColor3 = def.color
	accentBar.BorderSizePixel = 0
	accentBar.Parent = card

	local accentCorner = Instance.new("UICorner")
	accentCorner.CornerRadius = UDim.new(0.15, 0)
	accentCorner.Parent = accentBar

	local accentGrad = Instance.new("UIGradient")
	accentGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.7, 0),
		NumberSequenceKeypoint.new(1, 0.8),
	})
	accentGrad.Parent = accentBar

	-- Icon
	local iconLabel = Instance.new("TextLabel")
	iconLabel.Name = "Icon"
	iconLabel.Size = UDim2.new(0.35, 0, 0.45, 0)
	iconLabel.Position = UDim2.new(0.02, 0, 0.12, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = def.icon
	iconLabel.TextScaled = true
	iconLabel.Font = Enum.Font.Unknown
	iconLabel.Parent = card

	-- Value (big number)
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = "Value"
	valueLabel.Size = UDim2.new(0.6, 0, 0.5, 0)
	valueLabel.Position = UDim2.new(0.38, 0, 0.08, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = "0"
	valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	valueLabel.TextScaled = true
	valueLabel.Font = Enum.Font.FredokaOne
	valueLabel.TextXAlignment = Enum.TextXAlignment.Left
	valueLabel.TextStrokeTransparency = 0.7
	valueLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	valueLabel.Parent = card

	-- Sub-label
	local subLabel = Instance.new("TextLabel")
	subLabel.Name = "Label"
	subLabel.Size = UDim2.new(0.9, 0, 0.3, 0)
	subLabel.Position = UDim2.new(0.05, 0, 0.62, 0)
	subLabel.BackgroundTransparency = 1
	subLabel.Text = def.label
	subLabel.TextColor3 = def.color
	subLabel.TextScaled = true
	subLabel.Font = Enum.Font.GothamBold
	subLabel.TextXAlignment = Enum.TextXAlignment.Left
	subLabel.TextStrokeTransparency = 0.8
	subLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	subLabel.Parent = card

	local subConstraint = Instance.new("UITextSizeConstraint")
	subConstraint.MaxTextSize = 14
	subConstraint.Parent = subLabel

	statCards[def.key] = valueLabel
end

-- Cache of latest data for upgrade UI to reference
local cachedPlayerData = nil

-- Refresh stats from server
local function refreshHQStats()
	if not GetPlayerDataRF then return end
	local ok, data = pcall(function()
		return GetPlayerDataRF:InvokeServer()
	end)
	if ok and data then
		cachedPlayerData = data

		if statCards.health then statCards.health.Text = tostring(data.maxHealth or 100) end
		if statCards.armor then statCards.armor.Text = tostring(data.armor or 0) end
		if statCards.rank then statCards.rank.Text = tostring(data.rank or 1) end
		if statCards.goldPerSec then
			local gps = data.goldPerSecond or 0
			statCards.goldPerSec.Text = gps > 0 and string.format("+%s", formatNumber(gps)) or "0"
		end
		if statCards.cratesPerDay then
			local cpd = data.cratesPerDay or 0
			statCards.cratesPerDay.Text = cpd > 0 and string.format("%.1f", cpd) or "0"
		end
	end
end

--------------------------------------------------------------------------
-- UPGRADES SYSTEM — uses Studio Upgrades frame in CanvasGroup
--------------------------------------------------------------------------
local upgradeContentBuilt = false

-- Map Studio child frame names → upgrade keys (must match server HQUpgrade keys)
local STUDIO_FRAME_TO_KEY = {
	Health     = "health",
	Armor      = "armor",
	Gold       = "goldPerSecond",
	Refiner    = "refinerSpeed",
	PvpGold    = "pvpGoldBonus",
	AbyssGold  = "abyssGoldBonus",
	PveGold    = "pveGoldBonus",
	Playtime   = "playTimeBonus",
}

-- Upgrade definitions: label, icon, color, description, maxLevel
local UPGRADE_DEFS = {
	health        = { label = "MAX HEALTH",        icon = "❤️",  color = Color3.fromRGB(220, 60, 60),   desc = "+20 HP per level",             maxLevel = 5  },
	armor         = { label = "ARMOR",             icon = "🛡️",  color = Color3.fromRGB(80, 160, 255),  desc = "+10 armor per level",           maxLevel = 5  },
	goldPerSecond = { label = "GOLD INCOME",       icon = "💰",  color = Color3.fromRGB(80, 220, 120),  desc = "+2 gold/sec per level",         maxLevel = 10 },
	refinerSpeed  = { label = "REFINER SPEED",     icon = "⚡",  color = Color3.fromRGB(255, 200, 50),  desc = "+15% refiner speed per level",  maxLevel = 10 },
	pvpGoldBonus  = { label = "PVP GOLD",          icon = "⚔️",  color = Color3.fromRGB(255, 80, 80),   desc = "+10% PVP gold per level",       maxLevel = 10 },
	abyssGoldBonus= { label = "ABYSS GOLD",        icon = "🌀",  color = Color3.fromRGB(160, 50, 220),  desc = "+10% Abyss gold per level",     maxLevel = 10 },
	pveGoldBonus  = { label = "PVE GOLD",          icon = "🎯",  color = Color3.fromRGB(50, 180, 220),  desc = "+10% PvE gold per level",       maxLevel = 10 },
	playTimeBonus = { label = "PLAY TIME BONUS",   icon = "⏱️",  color = Color3.fromRGB(255, 160, 40),  desc = "+5% all gold per level",        maxLevel = 10 },
}

-- Upgrade cost tables (must match server)
local UPGRADE_COSTS = {
	health        = {1000, 3000, 7000, 15000, 30000},
	armor         = {2000, 5000, 10000, 20000, 40000},
	goldPerSecond = {500, 1500, 4000, 8000, 15000, 25000, 40000, 65000, 100000, 150000},
	refinerSpeed  = {2000, 5000, 12000, 25000, 50000, 80000, 120000, 175000, 250000, 400000},
	pvpGoldBonus  = {1000, 2500, 5000, 10000, 18000, 30000, 50000, 80000, 120000, 200000},
	abyssGoldBonus= {1000, 2500, 5000, 10000, 18000, 30000, 50000, 80000, 120000, 200000},
	pveGoldBonus  = {1000, 2500, 5000, 10000, 18000, 30000, 50000, 80000, 120000, 200000},
	playTimeBonus = {800, 2000, 4500, 9000, 16000, 28000, 45000, 70000, 110000, 180000},
}

-- Map server data field names → upgrade keys
local SERVER_LEVEL_KEYS = {
	health         = "healthUpgradeLevel",
	armor          = "armorUpgradeLevel",
	goldPerSecond  = "goldPerSecondLevel",
	refinerSpeed   = "refinerSpeedLevel",
	pvpGoldBonus   = "pvpGoldBonusLevel",
	abyssGoldBonus = "abyssGoldBonusLevel",
	pveGoldBonus   = "pveGoldBonusLevel",
	playTimeBonus  = "playTimeBonusLevel",
}

-- Upgrade node UI elements cache
local upgradeNodes = {} -- [key] = { textLabel, maxLevel, frame }
local upgradeBranchOriginals = {} -- [frame] = { size, pos, imageColor, bgColor, bgTransparency }

-- Floating effect for upgrade branch frames (no-op, handled by FloatingGui on whole ScreenGui)
local function addUpgradeBranchEffects(frame, defColor)
	-- FloatingGui wrapping the entire HeadQuarters ScreenGui handles the float
end

-- Set up a single Studio frame for upgrades (uses existing ImageLabel + TextLabel)
local function populateUpgradeFrame(studioFrame, key)
	local def = UPGRADE_DEFS[key]
	if not def then return end

	-- Find the existing TextLabel placed in Studio
	local textLabel = studioFrame:FindFirstChild("TextLabel")
	if not textLabel then
		warn("[Headquarters] No TextLabel found in upgrade frame: " .. studioFrame.Name)
		return
	end

	-- Configure the text label for upgrade info
	textLabel.Font = Enum.Font.FredokaOne
	textLabel.TextColor3 = def.color
	textLabel.TextScaled = true
	textLabel.TextWrapped = true
	textLabel.RichText = true
	textLabel.BackgroundTransparency = 1
	textLabel.TextStrokeTransparency = 0.5
	textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.TextYAlignment = Enum.TextYAlignment.Top

	-- Set initial text
	local costs = UPGRADE_COSTS[key]
	local firstCost = costs and costs[1] or 0
	textLabel.Text = string.format(
		"<font size=\"16\">%s</font>\n<font size=\"10\" color=\"#a0a5b4\">%s</font>\n\nLv. 0 / %d\n<font color=\"#ffc832\">$%s</font>  •  <font color=\"#ffffff\">TAP TO UPGRADE</font>",
		def.label, def.desc, def.maxLevel, formatNumber(firstCost)
	)

	-- Store references for refresh
	upgradeNodes[key] = {
		textLabel = textLabel,
		maxLevel = def.maxLevel,
		frame = studioFrame,
	}
end

-- Refresh all upgrade node displays from cached data
local function refreshUpgradeNodes()
	if not cachedPlayerData then return end
	local data = cachedPlayerData

	for key, def in pairs(UPGRADE_DEFS) do
		local nodeUI = upgradeNodes[key]
		if not nodeUI then continue end

		local serverKey = SERVER_LEVEL_KEYS[key]
		local currentLevel = serverKey and (data[serverKey] or 0) or 0
		local maxLevel = nodeUI.maxLevel
		local costs = UPGRADE_COSTS[key]
		local isMaxed = currentLevel >= maxLevel

		if isMaxed then
			nodeUI.textLabel.Text = string.format(
				"<font size=\"16\">%s</font>\n<font size=\"10\" color=\"#a0a5b4\">%s</font>\n\nLv. %d / %d\n<font color=\"#50dc78\">MAX LEVEL</font>",
				def.label, def.desc, currentLevel, maxLevel
			)
		else
			local nextCost = costs and costs[currentLevel + 1] or 0
			local canAfford = (data.money or 0) >= nextCost
			local costColor = canAfford and "#ffc832" or "#3c3c46"
			local actionText = canAfford
				and "<font color=\"#ffffff\">TAP TO UPGRADE</font>"
				or "<font color=\"#888888\">NOT ENOUGH GOLD</font>"

			nodeUI.textLabel.Text = string.format(
				"<font size=\"16\">%s</font>\n<font size=\"10\" color=\"#a0a5b4\">%s</font>\n\nLv. %d / %d\n<font color=\"%s\">$%s</font>  •  %s",
				def.label, def.desc, currentLevel, maxLevel, costColor, formatNumber(nextCost), actionText
			)
		end
	end
end

-- Build upgrade UI into the Studio Upgrades frame
local function buildUpgradeUI()
	if upgradeContentBuilt then return end
	if not upgradesPanelFrame then
		warn("[Headquarters] Upgrades panel frame not found in CanvasGroup")
		return
	end
	upgradeContentBuilt = true

	-- Iterate through each child frame in the Studio Upgrades panel
	for studioName, upgradeKey in pairs(STUDIO_FRAME_TO_KEY) do
		local studioFrame = upgradesPanelFrame:FindFirstChild(studioName)
		if not studioFrame then
			warn(string.format("[Headquarters] Upgrade frame '%s' not found in Upgrades panel", studioName))
			continue
		end

		populateUpgradeFrame(studioFrame, upgradeKey)

		-- Add hover/click effects to this branch frame
		local defColor = UPGRADE_DEFS[upgradeKey] and UPGRADE_DEFS[upgradeKey].color or Color3.fromRGB(255, 255, 255)
		addUpgradeBranchEffects(studioFrame, defColor)

		-- Wire click handler on the whole frame
		studioFrame.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1
				and input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end

			if not PlayerDataRF then warn("[Upgrades] PlayerDataRF not found") return end

			local nodeUI = upgradeNodes[upgradeKey]
			if not nodeUI then return end
			local def = UPGRADE_DEFS[upgradeKey]
			local serverKey = SERVER_LEVEL_KEYS[upgradeKey]
			local currentLevel = cachedPlayerData and cachedPlayerData[serverKey] or 0
			if currentLevel >= def.maxLevel then return end -- already maxed

			-- Quick flash effect on the frame
			local origColor = studioFrame.BackgroundColor3
			local origTransparency = studioFrame.BackgroundTransparency
			TweenService:Create(studioFrame, TweenInfo.new(0.05), {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.3,
			}):Play()

			local ok, result = pcall(function()
				return PlayerDataRF:InvokeServer("HQUpgrade", { upgradeKey = upgradeKey })
			end)

			if ok and result and result.success then
				-- Update cached data
				if cachedPlayerData then
					cachedPlayerData[serverKey] = result.level
					cachedPlayerData.money = result.newMoney
				end
				refreshUpgradeNodes()
				refreshHQStats()

				-- Success flash (green)
				TweenService:Create(studioFrame, TweenInfo.new(0.15), {
					BackgroundColor3 = Color3.fromRGB(80, 255, 120),
					BackgroundTransparency = 0.4,
				}):Play()
				task.delay(0.4, function()
					TweenService:Create(studioFrame, TweenInfo.new(0.2), {
						BackgroundColor3 = origColor,
						BackgroundTransparency = origTransparency,
					}):Play()
				end)

				print(string.format("[Upgrades] Upgraded %s to level %d", upgradeKey, result.level))
			else
				-- Fail flash (red)
				TweenService:Create(studioFrame, TweenInfo.new(0.1), {
					BackgroundColor3 = Color3.fromRGB(200, 40, 40),
					BackgroundTransparency = 0.3,
				}):Play()
				task.delay(0.4, function()
					TweenService:Create(studioFrame, TweenInfo.new(0.2), {
						BackgroundColor3 = origColor,
						BackgroundTransparency = origTransparency,
					}):Play()
				end)

				local reason = result and (result.reason or result.error) or "unknown"
				warn(string.format("[Upgrades] Failed to upgrade %s: %s", upgradeKey, tostring(reason)))
			end
		end)
	end

	print("[Headquarters] Upgrade UI built into Studio frames")
end

-- Open/close upgrade view (shows the Studio Upgrades frame, hides Main)
local function openUpgradeView()
	buildUpgradeUI()
	currentView = "upgrades"
	mainFrame.Visible = false
	if upgradesPanelFrame then upgradesPanelFrame.Visible = true end

	-- Refresh data and display
	refreshHQStats()
	refreshUpgradeNodes()
end

function closeUpgradeView()
	currentView = "main"
	if upgradesPanelFrame then upgradesPanelFrame.Visible = false end
	mainFrame.Visible = true
	refreshHQStats()
end

-- Wire the Upgrades button in Main to open upgrade view
if upgradesFrame then
	upgradesFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			task.delay(0.3, openUpgradeView) -- Wait for bounce animation
		end
	end)
end

--------------------------------------------------------------------------
-- STORAGE SYSTEM
--------------------------------------------------------------------------
local storageItemCleanups = {}
local inventoryItemCleanups = {}

local BLOOD_RED = Color3.fromRGB(220, 20, 40)

-- Helper: Get skin model from SkinLibrary
local function getStorageSkinInstance(name)
	local lib = ReplicatedStorage:FindFirstChild("SkinLibrary")
	if not lib then return nil end
	return lib:FindFirstChild(name, true)
end

-- Helper: Get skin rarity (1-5)
local function getStorageSkinRarity(skinName)
	if not SkinConfig then return 1 end
	local meta = SkinConfig.GetSkinMeta(skinName)
	if not meta then return 1 end
	local rarity = (meta.rarity or "common"):lower()
	local rarityMap = { common = 1, rare = 2, epic = 3, legendary = 4, mythic = 5 }
	return rarityMap[rarity] or 1
end

-- Simplified viewport setup for storage item display
local function storageSetupViewport(vp, source)
	for _, c in ipairs(vp:GetChildren()) do c:Destroy() end
	if not source then return nil end

	local world = Instance.new("WorldModel")
	world.Parent = vp

	local cam = Instance.new("Camera")
	cam.FieldOfView = 50
	vp.CurrentCamera = cam
	cam.Parent = vp

	-- Clone the source model
	local model
	local cloneOk = pcall(function()
		model = source:Clone()
	end)
	if not cloneOk or not model then return nil end
	model.Parent = world

	-- Calculate bounding box and position camera
	local cf, size
	local bbOk = pcall(function()
		if model:IsA("Model") then
			cf, size = model:GetBoundingBox()
		elseif model:IsA("BasePart") then
			cf = model.CFrame
			size = model.Size
		else
			cf = CFrame.new()
			size = Vector3.new(1, 1, 1)
		end
	end)
	if not bbOk then
		cf = CFrame.new()
		size = Vector3.new(1, 1, 1)
	end

	local maxDim = math.max(size.X, size.Y, size.Z)
	local dist = maxDim * 1.8
	if dist < 2 then dist = 2 end

	cam.CFrame = cf * CFrame.new(0, 0, dist)
	return model
end

-- Create a storage item slot (simplified createItemSlot for storage view)
local function createStorageSlot(parent, scrollParent, skinName, onClickCallback)
	local sourceInstance = getStorageSkinInstance(skinName)
	local rarityValue = getStorageSkinRarity(skinName)

	local rarityColors = {
		Color3.new(0.7, 0.7, 0.7),  -- Common
		Color3.new(0.2, 0.6, 1.0),  -- Rare
		Color3.new(0.6, 0.2, 1.0),  -- Epic
		Color3.new(1.0, 0.8, 0.0),  -- Legendary
		BLOOD_RED                    -- Mythic
	}
	local rarityColor = rarityColors[rarityValue] or Color3.new(0.7, 0.7, 0.7)

	-- Slot frame
	local slot = Instance.new("Frame")
	slot.Name = skinName
	slot.Size = UDim2.new(1, 0, 1, 0)
	slot.BackgroundTransparency = 1
	slot.BorderSizePixel = 0
	slot.ZIndex = 1
	slot.Parent = parent

	local corner = Instance.new("UICorner", slot)
	corner.CornerRadius = UDim.new(0, 10)

	local uiScale = Instance.new("UIScale")
	uiScale.Scale = 1.0
	uiScale.Parent = slot

	-- Viewport container
	local vpContainer = Instance.new("Frame")
	vpContainer.Size = UDim2.new(0, 81, 0, 81)
	vpContainer.Position = UDim2.new(0.5, 0, 0.38, 0)
	vpContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	vpContainer.BackgroundTransparency = 1
	vpContainer.BorderSizePixel = 0
	vpContainer.ZIndex = 2
	vpContainer.Parent = slot

	Instance.new("UICorner", vpContainer).CornerRadius = UDim.new(0, 8)

	-- ViewportFrame for 3D model
	local viewport = Instance.new("ViewportFrame")
	viewport.Size = UDim2.fromOffset(100, 88)
	viewport.Position = UDim2.fromScale(0.5, 0.5)
	viewport.AnchorPoint = Vector2.new(0.5, 0.5)
	viewport.BackgroundTransparency = 1
	viewport.BorderSizePixel = 0
	viewport.ZIndex = 3
	viewport.Parent = vpContainer

	local slotModel = storageSetupViewport(viewport, sourceInstance)

	if not sourceInstance then
		local placeholder = Instance.new("TextLabel")
		placeholder.Size = UDim2.fromScale(1, 1)
		placeholder.BackgroundTransparency = 1
		placeholder.Text = "?"
		placeholder.TextColor3 = Color3.new(0.7, 0.7, 0.7)
		placeholder.TextSize = 24
		placeholder.Font = Enum.Font.FredokaOne
		placeholder.ZIndex = 8
		placeholder.Parent = vpContainer
	end

	-- Process name (remove Meshes/ prefix, capitalize)
	local processedName = skinName
	if string.find(skinName, "Meshes/") then
		processedName = string.gsub(skinName, "Meshes/", "")
		processedName = string.gsub(processedName, "(%l)([%w_']*)", function(first, rest)
			return string.upper(first) .. rest
		end)
	end

	-- Name label with rarity color
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -6, 0, 19)
	nameLabel.Position = UDim2.new(0.5, 0, 1, -21)
	nameLabel.AnchorPoint = Vector2.new(0.5, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.Text = processedName
	nameLabel.TextScaled = true
	nameLabel.TextColor3 = rarityColor
	nameLabel.TextWrapped = true
	nameLabel.TextXAlignment = Enum.TextXAlignment.Center
	nameLabel.ZIndex = 10000
	nameLabel.Parent = slot

	local nameConstraint = Instance.new("UITextSizeConstraint")
	nameConstraint.MaxTextSize = 18
	nameConstraint.MinTextSize = 8
	nameConstraint.Parent = nameLabel

	-- Apply rarity effects
	local slotEffectsCleanup
	if rarityValue == 5 and MythicEffects then
		local _, cleanup = MythicEffects.ApplyMythicFrameEffects(slot)
		slotEffectsCleanup = cleanup
		if slotModel then
			local success, modelCleanup = MythicEffects.ApplyMythicModelEffects(slotModel)
			if success then
				local origCleanup = slotEffectsCleanup
				slotEffectsCleanup = function()
					if origCleanup then origCleanup() end
					if modelCleanup then modelCleanup() end
				end
			end
		end
		-- Manually apply MythicAura since ApplyMythicFrameEffects can't find GridView
		if MythicAura and scrollParent then
			local _, auraCleanup = MythicAura.ApplyMythicAuraEffect(slot, scrollParent)
			if auraCleanup then
				local origCleanup = slotEffectsCleanup
				slotEffectsCleanup = function()
					if origCleanup then origCleanup() end
					if auraCleanup then auraCleanup() end
				end
			end
		end
	end

	if rarityValue == 4 and LegendaryAura then
		local _, auraCleanup = LegendaryAura.ApplyLegendaryAuraEffect(slot, scrollParent)
		if auraCleanup then
			local origCleanup = slotEffectsCleanup
			slotEffectsCleanup = function()
				if origCleanup then origCleanup() end
				if auraCleanup then auraCleanup() end
			end
		end
	end

	if rarityValue == 3 and EpicAura then
		local _, auraCleanup = EpicAura.ApplyEpicAuraEffect(slot, scrollParent)
		if auraCleanup then
			local origCleanup = slotEffectsCleanup
			slotEffectsCleanup = function()
				if origCleanup then origCleanup() end
				if auraCleanup then auraCleanup() end
			end
		end
	end

	if rarityValue == 2 and RareAura then
		local _, auraCleanup = RareAura.ApplyRareAuraEffect(slot, scrollParent)
		if auraCleanup then
			local origCleanup = slotEffectsCleanup
			slotEffectsCleanup = function()
				if origCleanup then origCleanup() end
				if auraCleanup then auraCleanup() end
			end
		end
	end

	if rarityValue == 1 and CommonAura then
		local _, auraCleanup = CommonAura.ApplyCommonAuraEffect(slot, scrollParent)
		if auraCleanup then
			local origCleanup = slotEffectsCleanup
			slotEffectsCleanup = function()
				if origCleanup then origCleanup() end
				if auraCleanup then auraCleanup() end
			end
		end
	end

	-- Click button (covers entire slot)
	local clickBtn = Instance.new("TextButton")
	clickBtn.Size = UDim2.fromScale(1, 1)
	clickBtn.BackgroundTransparency = 1
	clickBtn.Text = ""
	clickBtn.ZIndex = 50
	clickBtn.AutoButtonColor = false
	clickBtn.Parent = slot

	clickBtn.MouseEnter:Connect(function()
		TweenService:Create(uiScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1.08 }):Play()
	end)

	clickBtn.MouseLeave:Connect(function()
		TweenService:Create(uiScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1.0 }):Play()
	end)

	clickBtn.MouseButton1Click:Connect(function()
		if onClickCallback then
			onClickCallback(skinName)
		end
	end)

	-- Cleanup effects when slot is destroyed
	slot.AncestryChanged:Connect(function(_, newParent)
		if not newParent and slotEffectsCleanup then
			slotEffectsCleanup()
			slotEffectsCleanup = nil
		end
	end)

	return slot, slotEffectsCleanup
end

-- Build the storage view UI in a SEPARATE ScreenGui (outside CanvasGroup to avoid pixelation)
local storageContentBuilt = false
local invScrollFrame, storScrollFrame
local storageOverlayGui -- separate ScreenGui for crisp rendering

local function buildStorageUI()
	if storageContentBuilt then return end
	storageContentBuilt = true

	-- Create a separate ScreenGui that renders outside the CanvasGroup
	storageOverlayGui = Instance.new("ScreenGui")
	storageOverlayGui.Name = "StorageOverlay"
	storageOverlayGui.ResetOnSpawn = false
	storageOverlayGui.IgnoreGuiInset = headquartersGui.IgnoreGuiInset
	storageOverlayGui.DisplayOrder = headquartersGui.DisplayOrder + 1
	storageOverlayGui.Enabled = false
	storageOverlayGui.Parent = playerGui

	-- Match the storage panel position/size from the CanvasGroup
	-- Use the storagePanelFrame as reference for positioning
	local overlayFrame = Instance.new("Frame")
	overlayFrame.Name = "StorageRoot"
	overlayFrame.BackgroundTransparency = 1
	overlayFrame.Parent = storageOverlayGui

	-- Position overlay centered on the Middle frame
	overlayFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	overlayFrame.Size = UDim2.new(0.575, 0, 0.55, 0)
	if middleFrame then
		local mPos = middleFrame.AbsolutePosition
		local mSize = middleFrame.AbsoluteSize
		local screenSize = storageOverlayGui.AbsoluteSize
		local cx = (mPos.X + mSize.X / 2) / screenSize.X
		local cy = (mPos.Y + mSize.Y / 2) / screenSize.Y
		overlayFrame.Position = UDim2.new(cx, 0, cy, 0)
	else
		overlayFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	end

	-- Content area (skip the top bar handled by Studio frame)
	local content = Instance.new("Frame")
	content.Name = "StorageContent"
	content.Size = UDim2.new(1, -20, 1, -60)
	content.Position = UDim2.new(0, 10, 0, 55)
	content.BackgroundTransparency = 1
	content.Parent = overlayFrame

	---------- LEFT PANEL: YOUR INVENTORY ----------
	local leftPanel = Instance.new("Frame")
	leftPanel.Name = "InventoryPanel"
	leftPanel.Size = UDim2.new(0.49, 0, 1, 0)
	leftPanel.Position = UDim2.new(0, 0, 0, 0)
	leftPanel.BackgroundColor3 = Color3.fromRGB(15, 18, 22)
	leftPanel.BackgroundTransparency = 0.3
	leftPanel.BorderSizePixel = 0
	leftPanel.Parent = content
	Instance.new("UICorner", leftPanel).CornerRadius = UDim.new(0, 12)

	local leftStroke = Instance.new("UIStroke", leftPanel)
	leftStroke.Color = Color3.fromRGB(80, 220, 120)
	leftStroke.Thickness = 1.5
	leftStroke.Transparency = 0.5

	-- Left header
	local leftHeader = Instance.new("Frame")
	leftHeader.Size = UDim2.new(1, 0, 0, 35)
	leftHeader.BackgroundColor3 = Color3.fromRGB(20, 25, 30)
	leftHeader.BackgroundTransparency = 0.2
	leftHeader.BorderSizePixel = 0
	leftHeader.Parent = leftPanel
	Instance.new("UICorner", leftHeader).CornerRadius = UDim.new(0, 12)

	local leftTitle = Instance.new("TextLabel")
	leftTitle.Size = UDim2.new(0.6, 0, 1, 0)
	leftTitle.Position = UDim2.new(0, 10, 0, 0)
	leftTitle.BackgroundTransparency = 1
	leftTitle.Text = "YOUR INVENTORY"
	leftTitle.TextColor3 = Color3.fromRGB(80, 220, 120)
	leftTitle.Font = Enum.Font.FredokaOne
	leftTitle.TextScaled = true
	leftTitle.TextXAlignment = Enum.TextXAlignment.Left
	leftTitle.Parent = leftHeader
	local leftTitleC = Instance.new("UITextSizeConstraint"); leftTitleC.MaxTextSize = 22; leftTitleC.Parent = leftTitle

	local leftHint = Instance.new("TextLabel")
	leftHint.Size = UDim2.new(0.4, -5, 1, 0)
	leftHint.Position = UDim2.new(0.6, 0, 0, 0)
	leftHint.BackgroundTransparency = 1
	leftHint.Text = "Click to Store →"
	leftHint.TextColor3 = Color3.fromRGB(120, 120, 120)
	leftHint.Font = Enum.Font.GothamBold
	leftHint.TextScaled = true
	leftHint.TextXAlignment = Enum.TextXAlignment.Right
	leftHint.Parent = leftHeader
	local leftHintC = Instance.new("UITextSizeConstraint"); leftHintC.MaxTextSize = 14; leftHintC.Parent = leftHint

	-- Left scroll frame
	invScrollFrame = Instance.new("ScrollingFrame")
	invScrollFrame.Name = "GridView"
	invScrollFrame.Size = UDim2.new(1, -10, 1, -45)
	invScrollFrame.Position = UDim2.new(0, 5, 0, 40)
	invScrollFrame.BackgroundTransparency = 1
	invScrollFrame.BorderSizePixel = 0
	invScrollFrame.ScrollBarThickness = 6
	invScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 220, 120)
	invScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	invScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	invScrollFrame.ClipsDescendants = true
	invScrollFrame.Parent = leftPanel

	local invGrid = Instance.new("UIGridLayout")
	invGrid.CellSize = UDim2.new(0.46, 0, 0, 138)
	invGrid.CellPadding = UDim2.new(0.04, 0, 0, 12)
	invGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	invGrid.SortOrder = Enum.SortOrder.LayoutOrder
	invGrid.Parent = invScrollFrame

	---------- RIGHT PANEL: IN STORAGE ----------
	local rightPanel = Instance.new("Frame")
	rightPanel.Name = "StoragePanel"
	rightPanel.Size = UDim2.new(0.49, 0, 1, 0)
	rightPanel.Position = UDim2.new(0.51, 0, 0, 0)
	rightPanel.BackgroundColor3 = Color3.fromRGB(22, 15, 18)
	rightPanel.BackgroundTransparency = 0.3
	rightPanel.BorderSizePixel = 0
	rightPanel.Parent = content
	Instance.new("UICorner", rightPanel).CornerRadius = UDim.new(0, 12)

	local rightStroke = Instance.new("UIStroke", rightPanel)
	rightStroke.Color = Color3.fromRGB(255, 160, 40)
	rightStroke.Thickness = 1.5
	rightStroke.Transparency = 0.5

	-- Right header
	local rightHeader = Instance.new("Frame")
	rightHeader.Size = UDim2.new(1, 0, 0, 35)
	rightHeader.BackgroundColor3 = Color3.fromRGB(30, 22, 15)
	rightHeader.BackgroundTransparency = 0.2
	rightHeader.BorderSizePixel = 0
	rightHeader.Parent = rightPanel
	Instance.new("UICorner", rightHeader).CornerRadius = UDim.new(0, 12)

	local rightTitle = Instance.new("TextLabel")
	rightTitle.Size = UDim2.new(0.6, 0, 1, 0)
	rightTitle.Position = UDim2.new(0, 10, 0, 0)
	rightTitle.BackgroundTransparency = 1
	rightTitle.Text = "IN STORAGE"
	rightTitle.TextColor3 = Color3.fromRGB(255, 160, 40)
	rightTitle.Font = Enum.Font.FredokaOne
	rightTitle.TextScaled = true
	rightTitle.TextXAlignment = Enum.TextXAlignment.Left
	rightTitle.Parent = rightHeader
	local rightTitleC = Instance.new("UITextSizeConstraint"); rightTitleC.MaxTextSize = 22; rightTitleC.Parent = rightTitle

	local rightHint = Instance.new("TextLabel")
	rightHint.Size = UDim2.new(0.4, -5, 1, 0)
	rightHint.Position = UDim2.new(0.6, 0, 0, 0)
	rightHint.BackgroundTransparency = 1
	rightHint.Text = "← Click to Retrieve"
	rightHint.TextColor3 = Color3.fromRGB(120, 120, 120)
	rightHint.Font = Enum.Font.GothamBold
	rightHint.TextScaled = true
	rightHint.TextXAlignment = Enum.TextXAlignment.Right
	rightHint.Parent = rightHeader
	local rightHintC = Instance.new("UITextSizeConstraint"); rightHintC.MaxTextSize = 14; rightHintC.Parent = rightHint

	-- Right scroll frame
	storScrollFrame = Instance.new("ScrollingFrame")
	storScrollFrame.Name = "GridView"
	storScrollFrame.Size = UDim2.new(1, -10, 1, -45)
	storScrollFrame.Position = UDim2.new(0, 5, 0, 40)
	storScrollFrame.BackgroundTransparency = 1
	storScrollFrame.BorderSizePixel = 0
	storScrollFrame.ScrollBarThickness = 6
	storScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 160, 40)
	storScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	storScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	storScrollFrame.ClipsDescendants = true
	storScrollFrame.Parent = rightPanel

	local storGrid = Instance.new("UIGridLayout")
	storGrid.CellSize = UDim2.new(0.46, 0, 0, 138)
	storGrid.CellPadding = UDim2.new(0.04, 0, 0, 12)
	storGrid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	storGrid.SortOrder = Enum.SortOrder.LayoutOrder
	storGrid.Parent = storScrollFrame

	-- Back button (top-left of storage overlay)
	local backBtn = Instance.new("TextButton")
	backBtn.Name = "BackButton"
	backBtn.Size = UDim2.new(0, 90, 0, 35)
	backBtn.Position = UDim2.new(0, 10, 0, 10)
	backBtn.BackgroundColor3 = Color3.fromRGB(30, 35, 40)
	backBtn.BackgroundTransparency = 0.2
	backBtn.Text = "< BACK"
	backBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	backBtn.Font = Enum.Font.FredokaOne
	backBtn.TextSize = 16
	backBtn.AutoButtonColor = true
	backBtn.ZIndex = 5
	backBtn.Parent = overlayFrame
	Instance.new("UICorner", backBtn).CornerRadius = UDim.new(0, 8)
	Instance.new("UIStroke", backBtn).Color = Color3.fromRGB(100, 100, 100)

	backBtn.MouseButton1Click:Connect(function()
		closeStorageView()
	end)

	-- Store All button (top-right of storage overlay)
	local storeAllBtn = Instance.new("TextButton")
	storeAllBtn.Name = "StoreAllButton"
	storeAllBtn.Size = UDim2.new(0, 120, 0, 35)
	storeAllBtn.Position = UDim2.new(1, -130, 0, 10)
	storeAllBtn.BackgroundColor3 = Color3.fromRGB(40, 25, 15)
	storeAllBtn.BackgroundTransparency = 0.2
	storeAllBtn.Text = "STORE ALL >>"
	storeAllBtn.TextColor3 = Color3.fromRGB(255, 160, 40)
	storeAllBtn.Font = Enum.Font.FredokaOne
	storeAllBtn.TextSize = 14
	storeAllBtn.AutoButtonColor = true
	storeAllBtn.ZIndex = 5
	storeAllBtn.Parent = overlayFrame
	Instance.new("UICorner", storeAllBtn).CornerRadius = UDim.new(0, 8)
	local storeAllStroke = Instance.new("UIStroke", storeAllBtn)
	storeAllStroke.Color = Color3.fromRGB(255, 160, 40)
	storeAllStroke.Transparency = 0.5

	storeAllBtn.MouseButton1Click:Connect(function()
		if not PlayerDataRF then return end
		-- Single bulk call to move all skins to storage
		local ok, result = pcall(function()
			return PlayerDataRF:InvokeServer("MoveAllToStorage", {})
		end)
		if ok and result and result.success then
			print(string.format("[Storage] Stored all: %d items moved", result.count or 0))
		else
			warn("[Storage] Store All failed:", result and result.error or "unknown")
		end
		refreshStorageView()
	end)

	print("[Headquarters] Storage UI built")
end

-- Clear items from a scroll frame (keep UIGridLayout)
local function clearGrid(scrollFrame, cleanupTable)
	if cleanupTable then
		for _, cleanup in ipairs(cleanupTable) do
			if cleanup then pcall(cleanup) end
		end
	end
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end

-- Populate both inventory and storage grids with current data
local function refreshStorageView()
	if not invScrollFrame or not storScrollFrame then return end
	if not GetPlayerDataRF then return end

	-- Fetch latest data
	local ok, data = pcall(function()
		return GetPlayerDataRF:InvokeServer()
	end)
	if not ok or not data then
		warn("[Headquarters] Failed to fetch player data for storage")
		return
	end

	local skins = data.skins or {}
	local storage = data.storage or {}

	-- Clear existing items
	clearGrid(invScrollFrame, inventoryItemCleanups)
	clearGrid(storScrollFrame, storageItemCleanups)
	inventoryItemCleanups = {}
	storageItemCleanups = {}

	-- Build sorted lists
	local invList = {}
	local storList = {}

	for skinId, qty in pairs(skins) do
		local count = (type(qty) == "number" and qty or 1)
		for i = 1, count do
			table.insert(invList, skinId)
		end
	end
	for skinId, qty in pairs(storage) do
		local count = (type(qty) == "number" and qty or 1)
		for i = 1, count do
			table.insert(storList, skinId)
		end
	end

	-- Sort by rarity (highest first), then alphabetically
	local function sortByRarity(a, b)
		local ra = getStorageSkinRarity(a)
		local rb = getStorageSkinRarity(b)
		if ra ~= rb then return ra > rb end
		return string.lower(a) < string.lower(b)
	end

	table.sort(invList, sortByRarity)
	table.sort(storList, sortByRarity)

	-- Populate inventory side (click = move to storage)
	for i, skinName in ipairs(invList) do
		local slot, cleanup = createStorageSlot(invScrollFrame, invScrollFrame, skinName, function(name)
			if not PlayerDataRF then warn("[Storage] PlayerDataRF not found") return end
			local moveOk, result = pcall(function()
				return PlayerDataRF:InvokeServer("MoveToStorage", { skinId = name })
			end)
			if moveOk and result and result.success then
				print("[Storage] Moved", name, "to storage")
				refreshStorageView()
			else
				warn("[Storage] Failed to move", name, ":", result and result.error or "unknown")
			end
		end)
		if slot then
			slot.LayoutOrder = i
			table.insert(inventoryItemCleanups, cleanup)
		end
	end

	-- Populate storage side (click = retrieve to inventory)
	for i, skinName in ipairs(storList) do
		local slot, cleanup = createStorageSlot(storScrollFrame, storScrollFrame, skinName, function(name)
			if not PlayerDataRF then warn("[Storage] PlayerDataRF not found") return end
			local moveOk, result = pcall(function()
				return PlayerDataRF:InvokeServer("MoveFromStorage", { skinId = name })
			end)
			if moveOk and result and result.success then
				print("[Storage] Retrieved", name, "from storage")
				refreshStorageView()
			else
				warn("[Storage] Failed to retrieve", name, ":", result and result.error or "unknown")
			end
		end)
		if slot then
			slot.LayoutOrder = i
			table.insert(storageItemCleanups, cleanup)
		end
	end

	print(string.format("[Storage] Loaded %d inventory items, %d storage items", #invList, #storList))
end

-- Open storage view (switch from Main to Storage overlay)
local function openStorageView()
	buildStorageUI()
	currentView = "storage"

	-- Hide Main (inside CanvasGroup), show overlay ScreenGui
	mainFrame.Visible = false
	if storagePanelFrame then storagePanelFrame.Visible = true end -- keep background/frame visible
	if storageOverlayGui then storageOverlayGui.Enabled = true end

	-- Populate items
	refreshStorageView()
end

-- Close storage view (back to Main)
function closeStorageView()
	currentView = "main"

	-- Hide overlay + storage background, show Main
	if storageOverlayGui then storageOverlayGui.Enabled = false end
	if storagePanelFrame then storagePanelFrame.Visible = false end
	mainFrame.Visible = true

	-- Refresh PvP stats when returning
	refreshHQStats()
end

-- Wire storage button in Main to open storage view
if storageFrame then
	storageFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			task.delay(0.3, openStorageView) -- Wait for bounce animation
		end
	end)
end

--------------------------------------------------------------------------
-- HIDE / SHOW STATS UI
--------------------------------------------------------------------------
local function hideStatsUI()
	-- Hide Stats ScreenGui in PlayerGui
	for _, gui in playerGui:GetChildren() do
		if gui.Name == "Stats" then
			gui.Enabled = false
		end
	end
	-- Hide FloatingGui Stats parts in workspace
	for _, obj in workspace:GetChildren() do
		if obj.Name == "FloatingGuiAdornee" and obj:IsA("BasePart") then
			for _, sg in obj:GetChildren() do
				if sg.Name == "Stats" then
					sg.Enabled = false
				end
			end
		end
	end
end

local function showStatsUI()
	for _, gui in playerGui:GetChildren() do
		if gui.Name == "Stats" then
			gui.Enabled = true
		end
	end
	for _, obj in workspace:GetChildren() do
		if obj.Name == "FloatingGuiAdornee" and obj:IsA("BasePart") then
			for _, sg in obj:GetChildren() do
				if sg.Name == "Stats" then
					sg.Enabled = true
				end
			end
		end
	end
end



--------------------------------------------------------------------------
-- Open / Close / Toggle
--------------------------------------------------------------------------
local function open()
	if isOpen then return end
	isOpen = true
	currentView = "main"

	hideStatsUI()

	-- Enable the HQ gui (pcall-guarded so stats re-show if GUI was destroyed)
	local ok, err = pcall(function()
		if headquartersGui then
			headquartersGui.Enabled = true
		end
		if mainFrame then mainFrame.Visible = true end
		if storagePanelFrame then storagePanelFrame.Visible = false end
		if storageOverlayGui then storageOverlayGui.Enabled = false end
		if upgradesPanelFrame then upgradesPanelFrame.Visible = false end
	end)
	if not ok then
		warn("[Headquarters] open() error:", err)
		isOpen = false
		showStatsUI()
		return
	end

	-- Refresh HQ stats when opening
	refreshHQStats()
end

local function close()
	if not isOpen then return end
	isOpen = false
	currentView = "main"

	-- Hide overlays immediately
	if storageOverlayGui then storageOverlayGui.Enabled = false end
	if upgradesPanelFrame then upgradesPanelFrame.Visible = false end

	task.wait(0.05)
	if not isOpen then
		-- Always re-show stats, even if HQ GUI errors (e.g. after respawn)
		local ok, err = pcall(function()
			if headquartersGui then
				headquartersGui.Enabled = false
			end
			if mainFrame then mainFrame.Visible = true end
			if storagePanelFrame then storagePanelFrame.Visible = false end
		end)
		if not ok then warn("[Headquarters] close() error:", err) end
		showStatsUI()
	end
end

local function toggle()
	if isOpen then
		close()
	else
		open()
	end
end

-- Expose API globally
_G.MatrixHeadquarters = {
	Open = open,
	Close = close,
	Toggle = toggle,
	IsOpen = function() return isOpen end
}

-- Start hidden
headquartersGui.Enabled = false
if storagePanelFrame then storagePanelFrame.Visible = false end
if storageOverlayGui then storageOverlayGui.Enabled = false end
if upgradesPanelFrame then upgradesPanelFrame.Visible = false end

print("[Headquarters] Controller initialized with Upgrades + Storage system")
