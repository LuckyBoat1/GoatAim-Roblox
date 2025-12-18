-- QuestCore.client.lua: Core UI setup, remotes, and main functions
-- Part 1 of 4 for the Super Colosseum Quest System

print("🚀 QuestCore script STARTING...")
warn("🚀 QuestCore script STARTING (warn)")

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

-- Fix for player being nil - wait until player is available
local player = Players.LocalPlayer
while not player do
	player = Players.LocalPlayer
	task.wait(0.1)
end
local playerGui = player:WaitForChild("PlayerGui")

-- Create global table for sharing across scripts
_G.MatrixQuest = _G.MatrixQuest or {}

-- Mouse enabler functions for UI interaction
local function enableQuestMouse()
	_G.UIMouseEnabler = true
	-- NUCLEAR OPTION - Force unlock everything
	task.spawn(function()
		for i = 1, 10 do -- Try multiple times
			pcall(function()
				player.CameraMode = Enum.CameraMode.Classic
				player.CameraMinZoomDistance = 0.5
				player.CameraMaxZoomDistance = 1000
				UserInputService.MouseIconEnabled = true
				UserInputService.MouseBehavior = Enum.MouseBehavior.Default
				UserInputService.MouseDeltaSensitivity = 1
				-- Multiple unlock attempts
				game:GetService("GuiService"):SetMenuIsOpen(false)
				game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
			end)
			task.wait(0.05)
		end
	end)
	warn("🖱️ QUEST MOUSE ENABLED - NUCLEAR UNLOCK")
end

local function disableQuestMouse()
	_G.UIMouseEnabler = false
	-- Don't lock anything - let it stay unlocked
	warn("�️ QUEST CLOSED - LEAVING MOUSE UNLOCKED")
end

-- Lazy remotes
local RF, RE
local function tryHookRemotes()
	RF = RF or RS:FindFirstChild("QuestRF")
	RE = RE or RS:FindFirstChild("QuestRE")
end
tryHookRemotes()
task.spawn(function() 
	for _=1,50 do 
		if RF and RE then break end 
		tryHookRemotes() 
		task.wait(0.2) 
	end 
	-- Create test remotes if they don't exist after waiting
	if not RF then
		print("Creating test QuestRF")
		local questRF = Instance.new("RemoteFunction")
		questRF.Name = "QuestRF"
		questRF.Parent = RS

		-- Add mock server response
		questRF.OnServerInvoke = function(player, action, args)
			if action == "get" then
				return {
					ok = true,
					now = os.time(),
					missionTrees = {
						{
							key = "TestTree",
							name = "Training Missions",
							color = Color3.fromRGB(80, 180, 255),
							icon = "rbxassetid://8227572486",
							nodes = {
								{id="test1", name="Target Practice", status="available", rarity="common", 
									desc="Hit 10 targets to complete this training mission."}
							},
							progress = 0
						}
					},
					bounties = {
						{
							offerId = "b1",
							quest = {
								name = "Rat Extermination",
								desc = "Clear out the basic enemies.",
								rarity = "common",
								objectives = {{key = "Rats", count = 10}},
								reward = {money = 100}
							},
							expiresAt = os.time() + 3600
						},
						{
							offerId = "b2",
							quest = {
								name = "Elite Hunt",
								desc = "Take down the elite guards.",
								rarity = "rare",
								objectives = {{key = "Elites", count = 3}},
								reward = {money = 500, coin=50}
							},
							expiresAt = os.time() + 7200
						},
						{
							offerId = "b3",
							quest = {
								name = "Annihilation Protocol",
								desc = "Destroy everything in the sector.",
								rarity = "annihilator",
								objectives = {{key = "Kills", count = 50}},
								reward = {money = 5000, boxTier="Annihilator Crate", boxCount=1}
							},
							expiresAt = os.time() + 1800
						},
						{
							offerId = "b4",
							quest = {
								name = "Legendary Duel",
								desc = "Win a duel against a high ranking player.",
								rarity = "legendary",
								objectives = {{key = "Wins", count = 1}},
								reward = {money = 2000, coin=200}
							},
							expiresAt = os.time() + 10000
						}
					},
					active = {},
					log = {}
				}
			elseif action == "reroll" then
				return {ok = true}
			elseif action == "accept" then
				return {ok = true, id = "accepted"}
			elseif action == "claim" then
				return {ok = true}
			end
			return {ok = false}
		end

		RF = questRF
	end

	if not RE then
		print("Creating test QuestRE")
		local questRE = Instance.new("RemoteEvent")
		questRE.Name = "QuestRE"
		questRE.Parent = RS

		RE = questRE
	end
end)

-- Theme and constants
local function C3(r,g,b) return Color3.fromRGB(r,g,b) end
-- CYBERPUNK NEON - Hot Pink/Magenta + Cyan on Dark Navy
local CYAN, BRIGHT_CYAN = C3(0,200,220), C3(50,230,250)             -- Electric cyan
local MAGENTA, BRIGHT_MAGENTA = C3(255,40,130), C3(255,80,170)      -- Hot pink/magenta
local BLUE, BRIGHT_BLUE = C3(40,80,160), C3(70,120,200)             -- Deep blue
local PINK, BRIGHT_PINK = C3(255,60,150), C3(255,100,180)           -- Pink accent
local DARK_BG = C3(10,12,20)                                         -- Near black navy
local PANEL_BG = C3(14,18,28)                                        -- Dark panel
local CARD_BG = C3(18,22,35)                                         -- Card background
local BAD_RED, BLACK = C3(255,50,70), C3(6,8,14)                    -- Red, near black
local ACCENT_GLOW = C3(0,220,240)                                    -- Cyan glow
-- Legacy aliases for compatibility  
local GREEN, BRIGHT_GREEN, DIM_GREEN = C3(50,220,180), C3(80,250,210), C3(40,180,150)
local YELLOW, BRIGHT_YELLOW = C3(255,220,80), C3(255,240,120)       -- Yellow
local ORANGE, BRIGHT_ORANGE = C3(255,140,60), C3(255,180,100)       -- Orange
local PURPLE, BRIGHT_PURPLE = C3(180,60,220), C3(210,100,250)       -- Purple

-- Base UI styling (Bold Cartoony Fonts)
local FONT_HEADING = Enum.Font.GothamBold
local FONT_TEXT = Enum.Font.GothamMedium
local CORNER_RADIUS_LARGE = UDim.new(0, 14)
local CORNER_RADIUS_MEDIUM = UDim.new(0, 10)
local CORNER_RADIUS_SMALL = UDim.new(0, 6)
local PANEL_COLOR = DARK_BG
local PANEL_SECONDARY_COLOR = PANEL_BG

-- Bounty Tiers Configuration - NEON CYBERPUNK
local bountyTiers = {
	common = { name="COMMON", color=C3(80, 100, 130), glow=C3(120, 150, 180) },
	uncommon = { name="RARE", color=C3(0, 180, 200), glow=C3(50, 220, 240) },
	rare = { name="SUPER RARE", color=C3(0, 160, 255), glow=C3(60, 200, 255) },
	epic = { name="EPIC", color=C3(180, 50, 220), glow=C3(220, 100, 255) },
	legendary = { name="LEGENDARY", color=C3(255, 200, 60), glow=C3(255, 230, 120) },
	
	-- Special Tiers - PINK + CYAN NEON
	warlord = { name="MYTHIC", color=C3(255, 40, 120), glow=C3(255, 90, 160) },
	marksman = { name="CHROMATIC", color=C3(255, 50, 180), glow=C3(255, 110, 210) },
	inferno = { name="STARR", color=C3(255, 130, 50), glow=C3(255, 180, 100) },
	apocalypse = { name="HYPERCHARGE", color=C3(140, 50, 255), glow=C3(180, 100, 255) },
	vendetta = { name="BRAWLER", color=C3(255, 60, 140), glow=C3(255, 120, 180) },
	mayhem = { name="TROPHY", color=C3(255, 200, 50), glow=C3(255, 230, 110) },
	rambo = { name="GADGET", color=C3(0, 200, 180), glow=C3(60, 240, 220) },
	annihilator = { name="STAR POWER", color=C3(255, 210, 70), glow=C3(255, 240, 140), strokeAlt=C3(255, 250, 200) },
	the_void = { name="ULTRA", color=C3(100, 40, 200), glow=C3(150, 90, 250) }
}

-- Reset if exists
if playerGui:FindFirstChild("MatrixQuests") then playerGui.MatrixQuests:Destroy() end
for _, v in ipairs(Lighting:GetChildren()) do if v.Name=="QuestBlur" then v:Destroy() end end
for _, v in ipairs(Lighting:GetChildren()) do if v.Name=="QuestBloom" then v:Destroy() end end

-- Root 
local gui = Instance.new("ScreenGui")
gui.Name = "MatrixQuests"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local blur = Instance.new("BlurEffect"); blur.Name="QuestBlur"; blur.Size=0; blur.Parent=Lighting
local bloom = Instance.new("BloomEffect"); bloom.Name="QuestBloom"; bloom.Intensity=0; bloom.Size=15; bloom.Threshold=0.95; bloom.Parent=Lighting

local backdrop = Instance.new("TextButton")
backdrop.Name="Backdrop"; backdrop.Size=UDim2.fromScale(1,1); backdrop.BackgroundColor3=BLACK
backdrop.BackgroundTransparency=1; backdrop.TextTransparency=1; backdrop.AutoButtonColor=false
backdrop.Visible=false; backdrop.Parent=gui

-- Main Panel with CYBERPUNK gradient
local main = Instance.new("Frame")
main.Name="MainPanel"; main.Size=UDim2.fromOffset(0,0); main.Position=UDim2.fromScale(0.5,0.5); main.AnchorPoint=Vector2.new(0.5,0.5)
main.BackgroundColor3=C3(10,12,20); main.BorderSizePixel=0; main.Visible=false; main.ClipsDescendants=true; main.Parent=gui
main.Active = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0,18)

-- Main panel gradient - DARK NAVY with subtle depth
local mainGrad = Instance.new("UIGradient")
mainGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, C3(20,24,38)),
	ColorSequenceKeypoint.new(0.5, C3(12,15,26)),
	ColorSequenceKeypoint.new(1, C3(8,10,18))
})
mainGrad.Rotation = 90
mainGrad.Parent = main

-- Stroke - CYAN NEON GLOW
local mainStroke = Instance.new("UIStroke", main); mainStroke.Color=C3(0,200,220); mainStroke.Thickness=2; mainStroke.Transparency=0.2

-- Header with clean dark gradient
local header = Instance.new("Frame"); header.Size=UDim2.new(1,0,0,62); header.BackgroundColor3=C3(14,18,28); header.BackgroundTransparency=0; header.Parent=main
Instance.new("UICorner", header).CornerRadius=UDim.new(0,14)

local headerGradient = Instance.new("UIGradient")
headerGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, C3(24,30,48)),
	ColorSequenceKeypoint.new(0.5, C3(16,20,34)),
	ColorSequenceKeypoint.new(1, C3(12,15,26))
})
headerGradient.Rotation = 90
headerGradient.Parent = header

-- Header bottom accent line - HOT MAGENTA
local headerAccent = Instance.new("Frame")
headerAccent.Size = UDim2.new(1, -30, 0, 2)
headerAccent.Position = UDim2.new(0, 15, 1, -1)
headerAccent.BackgroundColor3 = BRIGHT_MAGENTA
headerAccent.BackgroundTransparency = 0.3
headerAccent.Parent = header
Instance.new("UICorner", headerAccent).CornerRadius = UDim.new(0, 1)

-- Custom title icon
local titleIcon = Instance.new("ImageLabel")
titleIcon.Name = "TitleIcon"
titleIcon.Size = UDim2.fromOffset(26, 26)
titleIcon.Position = UDim2.new(0, 14, 0.5, 0)
titleIcon.AnchorPoint = Vector2.new(0, 0.5)
titleIcon.BackgroundTransparency = 1
titleIcon.Image = "rbxassetid://114095469091928"
titleIcon.ImageColor3 = Color3.new(1, 1, 1)
titleIcon.ScaleType = Enum.ScaleType.Fit
titleIcon.Parent = header

local title = Instance.new("TextLabel")
title.Size=UDim2.new(1,-20,1,0); title.Position=UDim2.new(0,48,0,0); title.BackgroundTransparency=1
title.Font=FONT_HEADING; title.Text="MISSION HQ"; title.TextSize=28; title.TextColor3=BRIGHT_CYAN; title.TextXAlignment=Enum.TextXAlignment.Left; title.Parent=header

-- Title stroke - DARK for contrast
local titleStroke = Instance.new("UIStroke")
titleStroke.Color = C3(0, 60, 80)
titleStroke.Thickness = 2
titleStroke.Parent = title

-- Header glow effect - CYAN
local titleGlow = Instance.new("ImageLabel")
titleGlow.Size = UDim2.new(1.2, 0, 1.2, 0)
titleGlow.Position = UDim2.new(0, -12, 0, -6)
titleGlow.BackgroundTransparency = 1
titleGlow.Image = "rbxassetid://1316045217" -- radial gradient
titleGlow.ImageColor3 = CYAN
titleGlow.ImageTransparency = 0.75
titleGlow.ZIndex = 0
titleGlow.Parent = title

-- Date/time watermark - MAGENTA
local watermark = Instance.new("TextLabel")
watermark.Size = UDim2.new(1, -40, 0, 20)
watermark.Position = UDim2.new(0, 20, 1, -30)
watermark.Font = FONT_TEXT
watermark.TextSize = 14
watermark.TextColor3 = MAGENTA
watermark.TextTransparency = 0.5
watermark.TextXAlignment = Enum.TextXAlignment.Right
watermark.BackgroundTransparency = 1
watermark.Text = "SUPER COLOSSEUM ★ BRAWL FOR GLORY!"
watermark.Parent = main

-- Header dot decoration - CYAN
local headerDots = Instance.new("ImageLabel")
headerDots.Size = UDim2.new(0, 120, 0, 30)
headerDots.Position = UDim2.new(1, -140, 0.5, 0)
headerDots.AnchorPoint = Vector2.new(0, 0.5)
headerDots.BackgroundTransparency = 1
headerDots.Image = "rbxassetid://6765455642" -- dot pattern
headerDots.ImageColor3 = CYAN
headerDots.ImageTransparency = 0.85
headerDots.Parent = header

-- Close button - MAGENTA NEON
local closeBtn = Instance.new("TextButton")
closeBtn.Size=UDim2.fromOffset(40,40); closeBtn.Position=UDim2.new(1,-18,0.5,0); closeBtn.AnchorPoint=Vector2.new(1,0.5)
closeBtn.BackgroundColor3=C3(180,40,100); closeBtn.Text=""; closeBtn.AutoButtonColor=false; closeBtn.Parent=header
Instance.new("UICorner", closeBtn).CornerRadius=UDim.new(0,10)

-- Close button gradient
local closeBtnGrad = Instance.new("UIGradient")
closeBtnGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, C3(255,90,160)),
	ColorSequenceKeypoint.new(0.5, C3(220,50,120)),
	ColorSequenceKeypoint.new(1, C3(160,30,90))
})
closeBtnGrad.Rotation = 90
closeBtnGrad.Parent = closeBtn

local closeBtnStroke = Instance.new("UIStroke"); closeBtnStroke.Color=C3(255,100,170); closeBtnStroke.Transparency=0.4; closeBtnStroke.Thickness=1.5; closeBtnStroke.Parent=closeBtn

-- Hover effect
closeBtn.MouseEnter:Connect(function()
	TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3=C3(220,60,130)}):Play()
end)
closeBtn.MouseLeave:Connect(function()
	TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3=C3(180,40,100)}):Play()
end)

-- X icon in close button
local closeX = Instance.new("TextLabel")
closeX.Size = UDim2.fromScale(1, 1)
closeX.BackgroundTransparency = 1
closeX.Font = FONT_HEADING
closeX.TextSize = 24
closeX.Text = "✕"
closeX.TextColor3 = Color3.new(1, 1, 1)
closeX.Parent = closeBtn
local closeXStroke = Instance.new("UIStroke"); closeXStroke.Color=C3(120,40,50); closeXStroke.Thickness=2; closeXStroke.Parent=closeX

-- Visual effects - Soft glow pulse
local energyPulse = Instance.new("Frame")
energyPulse.Size = UDim2.fromScale(1, 1)
energyPulse.BackgroundColor3 = BLUE
energyPulse.BackgroundTransparency = 0.98
energyPulse.BorderSizePixel = 0
energyPulse.ZIndex = 10
energyPulse.Parent = main

-- Subtle energy animation
task.spawn(function()
	while energyPulse and energyPulse.Parent do
		local intensity = 0.97 + (math.sin(tick() * 2) * 0.015)
		energyPulse.BackgroundTransparency = math.clamp(intensity, 0.95, 0.99)
		task.wait(0.03)
	end
end)

-- Content area - CLEAN DARK
local root = Instance.new("Frame")
root.Size=UDim2.new(1,-40,1,-84); root.Position=UDim2.new(0,20,0,74)
root.BackgroundColor3=C3(8,10,18); root.BackgroundTransparency=0.1; root.ClipsDescendants=true; root.Parent=main
Instance.new("UICorner", root).CornerRadius=CORNER_RADIUS_MEDIUM
local rootStroke = Instance.new("UIStroke", root); rootStroke.Color=C3(0,180,200); rootStroke.Transparency=0.6; rootStroke.Thickness=1

-- Ambient glow in corners - CYAN + MAGENTA NEON
local function addCornerGlow(parent, position, anchorPoint, color)
	local glow = Instance.new("ImageLabel")
	glow.Size = UDim2.fromOffset(180, 180)
	glow.Position = position
	glow.AnchorPoint = anchorPoint
	glow.BackgroundTransparency = 1
	glow.Image = "rbxassetid://1316045217" -- radial gradient
	glow.ImageColor3 = color
	glow.ImageTransparency = 0.9
	glow.ZIndex = 0
	glow.Parent = parent
	return glow
end

addCornerGlow(root, UDim2.fromScale(0, 0), Vector2.new(0, 0), CYAN)
addCornerGlow(root, UDim2.fromScale(1, 0), Vector2.new(1, 0), MAGENTA)
addCornerGlow(root, UDim2.fromScale(0, 1), Vector2.new(0, 1), MAGENTA)
addCornerGlow(root, UDim2.fromScale(1, 1), Vector2.new(1, 1), CYAN)

-- Active Missions strip - CLEAN DARK with CYAN accent
local bountyStrip = Instance.new("Frame")
bountyStrip.Name="BountyStrip"
bountyStrip.Size = UDim2.new(1,-20,0,115)
bountyStrip.Position = UDim2.new(0,10,0,10)
bountyStrip.BackgroundColor3 = C3(14,18,28)
bountyStrip.BackgroundTransparency = 0
bountyStrip.ClipsDescendants = false
bountyStrip.Parent = root
Instance.new("UICorner", bountyStrip).CornerRadius = UDim.new(0, 14)

-- Bounty strip gradient - SUBTLE DARK
local bsGradient = Instance.new("UIGradient")
bsGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, C3(22,28,42)),
	ColorSequenceKeypoint.new(0.5, C3(16,20,32)),
	ColorSequenceKeypoint.new(1, C3(12,15,24))
})
bsGradient.Rotation = 90
bsGradient.Parent = bountyStrip

-- Bounty strip stroke - CYAN
local bsStroke = Instance.new("UIStroke", bountyStrip); bsStroke.Color=C3(0,180,200); bsStroke.Transparency=0.5; bsStroke.Thickness=1

-- Top accent bar - HOT MAGENTA
local bsAccent = Instance.new("Frame")
bsAccent.Size = UDim2.new(0.35, 0, 0, 2)
bsAccent.Position = UDim2.new(0, 12, 0, 0)
bsAccent.BackgroundColor3 = BRIGHT_MAGENTA
bsAccent.Parent = bountyStrip
Instance.new("UICorner", bsAccent).CornerRadius = UDim.new(0, 1)

-- Custom bounty strip icon
local bsIcon = Instance.new("ImageLabel")
bsIcon.Name = "BountyIcon"
bsIcon.Size = UDim2.fromOffset(18, 18)
bsIcon.Position = UDim2.new(0, 14, 0, 11)
bsIcon.BackgroundTransparency = 1
bsIcon.Image = "rbxassetid://136589987585486"
bsIcon.ImageColor3 = Color3.new(1, 1, 1)
bsIcon.ScaleType = Enum.ScaleType.Fit
bsIcon.Parent = bountyStrip

local bsTitle = Instance.new("TextLabel")
bsTitle.BackgroundTransparency=1
bsTitle.Size=UDim2.new(1,-10,0,24)
bsTitle.Position=UDim2.new(0,38,0,8)
bsTitle.Font=FONT_HEADING
bsTitle.TextXAlignment=Enum.TextXAlignment.Left
bsTitle.TextSize=18
bsTitle.TextColor3=BRIGHT_CYAN
bsTitle.TextStrokeColor3 = C3(0, 60, 80)
bsTitle.TextStrokeTransparency = 0.3
bsTitle.Text="Active Missions"
bsTitle.Parent=bountyStrip

-- Render active bounties in top strip
local function renderBountyStrip(state)
	local activeBounties = {}
	for _, rec in ipairs(state.active or {}) do
		if rec.kind == "bounty" then 
			table.insert(activeBounties, rec) 
		end
	end
	
	bsTitle.Text = ("Active Missions (%d)"):format(#activeBounties)
	
	-- 1. Find or Create the Scroller (PERSISTENT)
	local scName = "BountyScroller_Final"
	local sc = bountyStrip:FindFirstChild(scName)
	local layout
	
	-- ALWAYS destroy and recreate to ensure clean state
	if sc then sc:Destroy() end
	
	-- Create Scroller
	sc = Instance.new("ScrollingFrame")
	sc.Name = scName
	sc.Size = UDim2.new(1, -16, 0, 78)
	sc.Position = UDim2.new(0, 8, 0, 28)
	sc.BackgroundTransparency = 1
	sc.BorderSizePixel = 0
	sc.ScrollBarThickness = 6
	sc.ScrollBarImageColor3 = GREEN
	sc.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
	sc.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
	sc.ScrollingDirection = Enum.ScrollingDirection.X
	sc.AutomaticCanvasSize = Enum.AutomaticSize.X
	sc.CanvasSize = UDim2.new(0, 0, 0, 0)
	sc.ClipsDescendants = true
	sc.Parent = bountyStrip
	
	-- Create Layout directly in Scroller
	layout = Instance.new("UIListLayout")
	layout.Name = "Layout"
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 10)
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Parent = sc
	
	-- Add padding
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 4)
	padding.Parent = sc
	
	-- 5. Create Cards
	local CARD_WIDTH = 240
	local CARD_HEIGHT = 68
	
	print("Rendering Bounty Strip. Active count:", #activeBounties)
	
	for i, q in ipairs(activeBounties) do
		print("Creating card", i, "for bounty:", q.name or q.id or "unknown")
		local rarity = (q.rarity or "common"):lower()
		local theme = bountyTiers[rarity] or bountyTiers.common or {
			color = C3(50,50,50), glow = C3(255,255,255), name="Unknown"
		}

		local card = Instance.new("Frame")
		card.Name = "BountyCard_" .. i
		card.LayoutOrder = i
		card.Size = UDim2.new(0, CARD_WIDTH, 0, CARD_HEIGHT)
		card.BackgroundColor3 = CARD_BG
		card.BackgroundTransparency = 0
		card.Visible = true
		card.ClipsDescendants = true
		card.Parent = sc
		
		print("Card", i, "created, parent:", card.Parent and card.Parent.Name or "NIL")
		
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
		
		-- Main stroke with gradient
		local st = Instance.new("UIStroke", card)
		st.Color = theme.glow
		st.Transparency = 0.1
		st.Thickness = 2

		local strokeGrad = Instance.new("UIGradient")
		strokeGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, theme.glow),
			ColorSequenceKeypoint.new(0.3, theme.strokeAlt or theme.color),
			ColorSequenceKeypoint.new(0.7, theme.strokeAlt or theme.color),
			ColorSequenceKeypoint.new(1, theme.glow)
		})
		strokeGrad.Rotation = 90
		strokeGrad.Parent = st

		-- Inner background gradient for depth (Brawl Stars style)
		local bgGrad = Instance.new("UIGradient")
		bgGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, theme.color:Lerp(C3(255,255,255), 0.1)),
			ColorSequenceKeypoint.new(0.5, CARD_BG),
			ColorSequenceKeypoint.new(1, theme.color:Lerp(C3(0,0,0), 0.3))
		})
		bgGrad.Rotation = 135
		bgGrad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.7),
			NumberSequenceKeypoint.new(0.5, 0.95),
			NumberSequenceKeypoint.new(1, 0.85)
		})
		bgGrad.Parent = card

		-- Accent stripe on left
		local accent = Instance.new("Frame")
		accent.Size = UDim2.new(0, 4, 1, -8)
		accent.Position = UDim2.new(0, 4, 0, 4)
		accent.BackgroundColor3 = theme.glow
		accent.BorderSizePixel = 0
		accent.Parent = card
		Instance.new("UICorner", accent).CornerRadius = UDim.new(0, 2)
		
		-- Accent glow
		local accentGlow = Instance.new("Frame")
		accentGlow.Size = UDim2.new(0, 8, 1, -8)
		accentGlow.Position = UDim2.new(0, 2, 0, 4)
		accentGlow.BackgroundColor3 = theme.glow
		accentGlow.BackgroundTransparency = 0.7
		accentGlow.BorderSizePixel = 0
		accentGlow.ZIndex = 0
		accentGlow.Parent = card
		Instance.new("UICorner", accentGlow).CornerRadius = UDim.new(0, 4)

		-- Rarity badge - CYBERPUNK NEON STYLE
		-- Badge outer glow
		local badgeGlow = Instance.new("Frame")
		badgeGlow.Size = UDim2.new(0, 68, 0, 22)
		badgeGlow.Position = UDim2.new(1, -70, 0, 2)
		badgeGlow.BackgroundColor3 = theme.glow
		badgeGlow.BackgroundTransparency = 0.8
		badgeGlow.ZIndex = 1
		badgeGlow.Parent = card
		Instance.new("UICorner", badgeGlow).CornerRadius = UDim.new(0, 6)
		
		local badge = Instance.new("Frame")
		badge.Size = UDim2.new(0, 62, 0, 18)
		badge.Position = UDim2.new(1, -67, 0, 4)
		badge.BackgroundColor3 = theme.glow
		badge.ZIndex = 2
		badge.Parent = card
		Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 5)
		
		-- Badge gradient
		local badgeGrad = Instance.new("UIGradient")
		badgeGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(0.3, theme.glow:Lerp(Color3.new(1,1,1), 0.15)),
			ColorSequenceKeypoint.new(0.7, theme.glow),
			ColorSequenceKeypoint.new(1, theme.glow:Lerp(Color3.new(0,0,0), 0.25))
		})
		badgeGrad.Rotation = 135
		badgeGrad.Parent = badge
		
		-- Badge border stroke
		local badgeStroke = Instance.new("UIStroke", badge)
		badgeStroke.Color = Color3.new(1, 1, 1)
		badgeStroke.Transparency = 0.6
		badgeStroke.Thickness = 1
		
		local badgeText = Instance.new("TextLabel")
		badgeText.Size = UDim2.fromScale(1, 1)
		badgeText.BackgroundTransparency = 1
		badgeText.Font = FONT_HEADING
		badgeText.TextSize = 10
		badgeText.TextColor3 = Color3.new(1, 1, 1)
		badgeText.Text = theme.name
		badgeText.ZIndex = 3
		badgeText.Parent = badge
		
		-- Badge text stroke
		local badgeTextStroke = Instance.new("UIStroke")
		badgeTextStroke.Color = C3(0, 0, 0)
		badgeTextStroke.Transparency = 0.2
		badgeTextStroke.Thickness = 1.5
		badgeTextStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
		badgeTextStroke.Parent = badgeText

		-- Name with CYBERPUNK GLOW text stroke
		local name = Instance.new("TextLabel")
		name.BackgroundTransparency = 1
		name.Size = UDim2.new(1, -80, 0, 22)
		name.Position = UDim2.new(0, 14, 0, 3)
		name.Font = FONT_HEADING
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.TextSize = 15
		name.TextColor3 = theme.glow
		name.Text = q.name or "Bounty"
		name.Parent = card
		
		-- Name text glow stroke
		local nameStroke = Instance.new("UIStroke")
		nameStroke.Color = theme.glow
		nameStroke.Transparency = 0.65
		nameStroke.Thickness = 1
		nameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
		nameStroke.Parent = name
		
		-- Name shadow stroke
		local nameShadow = Instance.new("UIStroke")
		nameShadow.Color = C3(0, 0, 0)
		nameShadow.Transparency = 0.3
		nameShadow.Thickness = 2
		nameShadow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		-- Note: Can't add 2 strokes, use the main one for effect

		-- Timer - CYBERPUNK NEON STYLE
		-- Timer outer glow
		local timerGlow = Instance.new("Frame")
		timerGlow.Size = UDim2.new(0, 78, 0, 22)
		timerGlow.Position = UDim2.new(0, 11, 0, 24)
		timerGlow.BackgroundColor3 = theme.glow
		timerGlow.BackgroundTransparency = 0.85
		timerGlow.ZIndex = 1
		timerGlow.Parent = card
		Instance.new("UICorner", timerGlow).CornerRadius = UDim.new(0, 6)
		
		local timerChip = Instance.new("Frame")
		timerChip.Size = UDim2.new(0, 74, 0, 18)
		timerChip.Position = UDim2.new(0, 13, 0, 26)
		timerChip.BackgroundColor3 = C3(15, 18, 28)
		timerChip.ZIndex = 2
		timerChip.Parent = card
		Instance.new("UICorner", timerChip).CornerRadius = UDim.new(0, 5)
		
		-- Timer gradient
		local timerGrad = Instance.new("UIGradient")
		timerGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, C3(28, 32, 48)),
			ColorSequenceKeypoint.new(0.5, C3(18, 22, 34)),
			ColorSequenceKeypoint.new(1, C3(12, 14, 22))
		})
		timerGrad.Rotation = 135
		timerGrad.Parent = timerChip
		
		local timerStroke = Instance.new("UIStroke", timerChip)
		timerStroke.Color = theme.glow
		timerStroke.Transparency = 0.3
		timerStroke.Thickness = 1.5

		local timer = Instance.new("TextLabel")
		timer.BackgroundTransparency = 1
		timer.Size = UDim2.fromScale(1, 1)
		timer.Font = FONT_HEADING
		timer.TextSize = 11
		timer.TextColor3 = theme.glow
		timer.Text = "⏱ --:--"
		timer.ZIndex = 3
		timer.Parent = timerChip
		
		-- Timer text glow stroke
		local timerTextStroke = Instance.new("UIStroke")
		timerTextStroke.Color = theme.glow
		timerTextStroke.Transparency = 0.7
		timerTextStroke.Thickness = 0.5
		timerTextStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
		timerTextStroke.Parent = timer

		-- Add countdown timer if expiry is set
		if q.expiresAt and state.now > 0 then 
			trackCountdown(timer, q.expiresAt, "")
		end

		-- Progress summary (safely handle if progress is not a table)
		local sum, n = 0, 0
		local progressData = q.progress
		if type(progressData) ~= "table" then progressData = {} end
		
		for _, obj in ipairs(q.objectives or {}) do
			local cur = (progressData[obj.key]) or 0
			sum += math.clamp(cur/(obj.count or 1), 0, 1)
			n += 1
		end

		local ratio = (n>0) and sum/n or 0
		
		-- Progress bar container with label - CYBERPUNK STYLE
		local progressContainer = Instance.new("Frame")
		progressContainer.Size = UDim2.new(0.55, 0, 0, 20)
		progressContainer.Position = UDim2.new(0, 13, 0, 46)
		progressContainer.BackgroundTransparency = 1
		progressContainer.ZIndex = 2
		progressContainer.Parent = card
		
		local progressLabel = Instance.new("TextLabel")
		progressLabel.Size = UDim2.new(1, 0, 0, 11)
		progressLabel.Position = UDim2.new(0, 0, 0, 0)
		progressLabel.BackgroundTransparency = 1
		progressLabel.Font = FONT_HEADING
		progressLabel.TextSize = 10
		progressLabel.TextXAlignment = Enum.TextXAlignment.Left
		progressLabel.TextColor3 = theme.glow
		progressLabel.TextTransparency = 0.2
		progressLabel.Text = string.format("Progress: %d%%", math.floor(ratio * 100))
		progressLabel.ZIndex = 3
		progressLabel.Parent = progressContainer
		
		-- Progress bar outer glow
		local barGlow = Instance.new("Frame")
		barGlow.Size = UDim2.new(1, 4, 0, 10)
		barGlow.Position = UDim2.new(0, -2, 0, 10)
		barGlow.BackgroundColor3 = theme.glow
		barGlow.BackgroundTransparency = 0.85
		barGlow.ZIndex = 2
		barGlow.Parent = progressContainer
		Instance.new("UICorner", barGlow).CornerRadius = UDim.new(0, 5)
		
		local bar = Instance.new("Frame")
		bar.Size = UDim2.new(1, 0, 0, 8)
		bar.Position = UDim2.new(0, 0, 0, 11)
		bar.BackgroundColor3 = C3(10, 14, 20)
		bar.ZIndex = 3
		bar.Parent = progressContainer
		Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 4)
		
		-- Bar background gradient
		local barBgGrad = Instance.new("UIGradient")
		barBgGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, C3(18, 22, 32)),
			ColorSequenceKeypoint.new(0.5, C3(10, 14, 20)),
			ColorSequenceKeypoint.new(1, C3(6, 8, 12))
		})
		barBgGrad.Rotation = 90
		barBgGrad.Parent = bar
		
		local barStroke = Instance.new("UIStroke", bar)
		barStroke.Color = theme.glow
		barStroke.Transparency = 0.5
		barStroke.Thickness = 1.5

		local fill = Instance.new("Frame")
		fill.Size = UDim2.new(ratio, 0, 1, 0)
		fill.BackgroundColor3 = theme.glow
		fill.ZIndex = 4
		fill.Parent = bar
		Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)
		
		-- Fill gradient for shiny effect
		local fillGrad = Instance.new("UIGradient")
		fillGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(0.5, theme.glow),
			ColorSequenceKeypoint.new(1, theme.color)
		})
		fillGrad.Rotation = 90
		fillGrad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(0.5, 0),
			NumberSequenceKeypoint.new(1, 0.2)
		})
		fillGrad.Parent = fill

		-- Premium styled button
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.fromOffset(75, 24)
		btn.Position = UDim2.new(1, -82, 0, 38)
		btn.BackgroundColor3 = q.completed and theme.glow or C3(25, 35, 30)
		btn.TextColor3 = q.completed and C3(0, 0, 0) or theme.glow
		btn.TextSize = 11
		btn.Font = FONT_HEADING
		btn.Text = q.completed and "✓ Claim" or "Abandon"
		btn.Parent = card
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
		local bst = Instance.new("UIStroke", btn)
		bst.Color = q.completed and theme.glow or theme.color
		bst.Transparency = q.completed and 0.2 or 0.5
		bst.Thickness = 1.5
		
		-- Button gradient for depth
		local btnGrad = Instance.new("UIGradient")
		btnGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(1, Color3.new(0.7, 0.7, 0.7))
		})
		btnGrad.Rotation = 90
		btnGrad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.85),
			NumberSequenceKeypoint.new(0.5, 0.95),
			NumberSequenceKeypoint.new(1, 0.9)
		})
		btnGrad.Parent = btn
		
		-- Hover effect
		btn.MouseEnter:Connect(function()
			btn.BackgroundColor3 = q.completed and theme.glow:Lerp(Color3.new(1,1,1), 0.2) or theme.color:Lerp(C3(25,35,30), 0.5)
			bst.Transparency = 0
		end)
		btn.MouseLeave:Connect(function()
			btn.BackgroundColor3 = q.completed and theme.glow or C3(25, 35, 30)
			bst.Transparency = q.completed and 0.2 or 0.5
		end)

		if q.completed then
			btn.MouseButton1Click:Connect(function()
				if RF then pcall(function() RF:InvokeServer("claim", {id=q.id}) end) end
				task.defer(render)
			end)
		else
			btn.MouseButton1Click:Connect(function()
				if RF then pcall(function() RF:InvokeServer("abandon", {id=q.id}) end) end
				task.defer(render)
			end)
		end
	end
	
	-- AutomaticCanvasSize handles sizing now
	print("Cards created:", #activeBounties, "Layout children:", #sc:GetChildren())
	
	-- If no active bounties, show a placeholder card
	if #activeBounties == 0 then
		local card = Instance.new("Frame")
		card.Size = UDim2.new(0, 280, 0, 66)
		card.BackgroundColor3 = C3(8,12,10)
		card.BackgroundTransparency = 0
		card.Parent = sc
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
		local st = Instance.new("UIStroke", card)
		st.Color = BLUE
		st.Transparency = 0.3
		st.Thickness = 2

		local placeholder = Instance.new("TextLabel")
		placeholder.BackgroundTransparency = 1
		placeholder.Size = UDim2.new(1, -16, 1, -12)
		placeholder.Position = UDim2.new(0, 8, 0, 6)
		placeholder.Font = FONT_TEXT
		placeholder.TextSize = 13
		placeholder.TextColor3 = C3(150, 180, 220)
		placeholder.TextWrapped = true
		placeholder.Text = "No active missions. Access the Contracts terminal to accept assignments."
		placeholder.Parent = card
	end
end

-- Tabs - CLEAN DARK with CYAN/MAGENTA accents
local tabBar = Instance.new("Frame")
tabBar.Size=UDim2.new(1,-20,0,48)
tabBar.Position=UDim2.new(0,10,0, bountyStrip.Position.Y.Offset + bountyStrip.Size.Y.Offset + 10)
tabBar.BackgroundColor3=C3(12,15,24)
tabBar.BackgroundTransparency=0
tabBar.Parent=root
Instance.new("UICorner", tabBar).CornerRadius=UDim.new(0,12)

-- Tab bar gradient - SUBTLE DARK
local tabBarGrad = Instance.new("UIGradient")
tabBarGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, C3(20,25,38)),
	ColorSequenceKeypoint.new(0.5, C3(14,18,30)),
	ColorSequenceKeypoint.new(1, C3(10,13,22))
})
tabBarGrad.Rotation = 90
tabBarGrad.Parent = tabBar
local tabBarStroke = Instance.new("UIStroke", tabBar); tabBarStroke.Color=C3(0,160,180); tabBarStroke.Thickness=1; tabBarStroke.Transparency=0.5

-- Tab buttons - CLEAN DARK
local function makeTabButton(text, order, icon)
	local btn = Instance.new("TextButton")
	btn.Size=UDim2.new(0,175,1,-10)
	btn.Position=UDim2.new(0, 8 + (order-1)*182, 0, 5)
	btn.BackgroundColor3=C3(18,22,35)
	btn.Text=""
	btn.AutoButtonColor=false
	btn.Parent=tabBar
	Instance.new("UICorner", btn).CornerRadius=UDim.new(0,10)
	
	-- Tab button gradient
	local btnGrad = Instance.new("UIGradient")
	btnGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, C3(28,34,52)),
		ColorSequenceKeypoint.new(0.5, C3(22,27,42)),
		ColorSequenceKeypoint.new(1, C3(16,20,32))
	})
	btnGrad.Rotation = 90
	btnGrad.Parent = btn
	
	-- Border - SUBTLE CYAN
	local st = Instance.new("UIStroke", btn); st.Color=C3(0,140,160); st.Thickness=1; st.Transparency=0.5

	-- Icon
	if icon then
		local iconImg = Instance.new("ImageLabel")
		iconImg.Size = UDim2.fromOffset(20, 20)
		iconImg.Position = UDim2.new(0, 12, 0.5, 0)
		iconImg.AnchorPoint = Vector2.new(0, 0.5)
		iconImg.BackgroundTransparency = 1
		iconImg.Image = icon
		iconImg.ImageColor3 = C3(120,160,180)
		iconImg.Parent = btn

		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(1, -44, 1, 0)
		label.Position = UDim2.new(0, 40, 0, 0)
		label.Font = FONT_HEADING
		label.TextSize = 15
		label.TextColor3 = C3(120,160,180)
		label.Text = text
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = btn
	else
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.Font = FONT_HEADING
		label.TextSize = 15
		label.TextColor3 = C3(120,160,180)
		label.Text = text
		label.Parent = btn
	end

	return btn
end

local tabMissionsBtn = makeTabButton("Operations", 1, "rbxassetid://136589987585486") -- Bounties icon
local tabLogBtn = makeTabButton("Mission Log", 2, "rbxassetid://8430438472") -- Scroll icon
local tabFindBtn = makeTabButton("Contracts", 3, "rbxassetid://8430292256") -- Search icon

local contentArea = Instance.new("Frame")
contentArea.Size=UDim2.new(1,-20,1, -(bountyStrip.Position.Y.Offset + bountyStrip.Size.Y.Offset + 6 + tabBar.Size.Y.Offset + 14))
contentArea.Position=UDim2.new(0,10,0, bountyStrip.Position.Y.Offset + bountyStrip.Size.Y.Offset + 10 + tabBar.Size.Y.Offset + 16)
contentArea.BackgroundTransparency=1
contentArea.Parent=root

local tabMissions = Instance.new("Frame"); tabMissions.Size=UDim2.fromScale(1,1); tabMissions.BackgroundTransparency=1; tabMissions.Parent=contentArea
local tabLog = Instance.new("Frame"); tabLog.Size=UDim2.fromScale(1,1); tabLog.BackgroundTransparency=1; tabLog.Parent=contentArea
local tabFind = Instance.new("Frame"); tabFind.Size=UDim2.fromScale(1,1); tabFind.BackgroundTransparency=1; tabFind.Parent=contentArea

-- Find Bounties Tab UI Setup
local findTop = Instance.new("Frame")
findTop.Size = UDim2.new(1,-10,0,36)
findTop.Position = UDim2.new(0,5,0,5)
findTop.BackgroundTransparency = 1
findTop.Parent = tabFind

local refreshBtn = Instance.new("TextButton")
refreshBtn.Size = UDim2.fromOffset(180,36)
refreshBtn.Position = UDim2.new(1,-190,0,0)
refreshBtn.BackgroundColor3 = C3(0,160,180)
refreshBtn.Text = ""
refreshBtn.AutoButtonColor = false
refreshBtn.Parent = findTop
Instance.new("UICorner", refreshBtn).CornerRadius = UDim.new(0,10)

-- Refresh button gradient - CYAN NEON
local refreshGrad = Instance.new("UIGradient")
refreshGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, C3(80,220,240)),
	ColorSequenceKeypoint.new(0.5, C3(40,190,210)),
	ColorSequenceKeypoint.new(1, C3(20,140,160))
})
refreshGrad.Rotation = 90
refreshGrad.Parent = refreshBtn

local rbst = Instance.new("UIStroke", refreshBtn)
rbst.Color = C3(60,200,220)
rbst.Thickness = 1.5
rbst.Transparency = 0.3

-- Hover effect
refreshBtn.MouseEnter:Connect(function()
	TweenService:Create(refreshBtn, TweenInfo.new(0.15), {BackgroundColor3=C3(40,190,210)}):Play()
end)
refreshBtn.MouseLeave:Connect(function()
	TweenService:Create(refreshBtn, TweenInfo.new(0.15), {BackgroundColor3=C3(0,160,180)}):Play()
end)

local refreshIcon = Instance.new("ImageLabel")
refreshIcon.Size = UDim2.fromOffset(20, 20)
refreshIcon.Position = UDim2.new(0, 14, 0.5, 0)
refreshIcon.AnchorPoint = Vector2.new(0, 0.5)
refreshIcon.BackgroundTransparency = 1
refreshIcon.Image = "rbxassetid://8337535591"
refreshIcon.ImageColor3 = C3(0, 50, 60)
refreshIcon.Parent = refreshBtn

local refreshText = Instance.new("TextLabel")
refreshText.BackgroundTransparency = 1
refreshText.Size = UDim2.new(1, -44, 1, 0)
refreshText.Position = UDim2.new(0, 40, 0, 0)
refreshText.Font = FONT_HEADING
refreshText.TextSize = 15
refreshText.TextColor3 = C3(20, 70, 45)
refreshText.Text = "⟳ NEW CONTRACTS"
refreshText.TextXAlignment = Enum.TextXAlignment.Left
refreshText.Parent = refreshBtn

local findListScroll = Instance.new("ScrollingFrame")
findListScroll.Size = UDim2.new(1,-20,1,-50)
findListScroll.Position = UDim2.new(0,10,0,46)
findListScroll.BackgroundTransparency = 1
findListScroll.ScrollBarThickness = 6
findListScroll.ScrollBarImageColor3 = GREEN
findListScroll.ClipsDescendants = false
findListScroll.Parent = tabFind

local findPadding = Instance.new("UIPadding", findListScroll)
findPadding.PaddingRight = UDim.new(0, 10)

local findLayout = Instance.new("UIListLayout")
findLayout.Padding = UDim.new(0,10)
findLayout.Parent = findListScroll

findLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	findListScroll.CanvasSize = UDim2.new(0,0,0, findLayout.AbsoluteContentSize.Y + 10)
end)

-- Countdown tracking for timers
local countdowns = {}
local serverNowAtRender, clientRenderTime = 0, 0
local function trackCountdown(label, expiresAt, prefix)
	table.insert(countdowns, {label=label, expiresAt=expiresAt, prefix=prefix or "Time"})
end

-- Utility function to clear children from a container
local function clearChildren(container, onlyFrames)
	for _, c in ipairs(container:GetChildren()) do
		if (not onlyFrames) or c:IsA("Frame") or c:IsA("ScrollingFrame") then c:Destroy() end
	end
end

-- Tab switching with animation (NO border change - just background)
local function showTab(which)
	tabMissions.Visible = (which == "missions")
	tabLog.Visible = (which == "log")
	tabFind.Visible = (which == "find")

	for _,b in ipairs({tabMissionsBtn, tabLogBtn, tabFindBtn}) do
		local sel = (b:FindFirstChild("TextLabel").Text:find("Operations") and which=="missions") or 
			(b:FindFirstChild("TextLabel").Text:find("Log") and which=="log") or 
			(b:FindFirstChild("TextLabel").Text:find("Contract") and which=="find")

		-- Background - MAGENTA tint when selected
		local targetColor = sel and C3(35,20,35) or C3(18,22,35)

		TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = targetColor}):Play()

		-- Icon and text - MAGENTA when selected, muted when not
		for _, child in pairs(b:GetChildren()) do
			if child:IsA("ImageLabel") then
				TweenService:Create(child, TweenInfo.new(0.15), {
					ImageColor3 = sel and BRIGHT_MAGENTA or C3(120,160,180)
				}):Play()
			elseif child:IsA("TextLabel") then
				TweenService:Create(child, TweenInfo.new(0.15), {
					TextColor3 = sel and BRIGHT_MAGENTA or C3(120,160,180)
				}):Play()
			end
		end
	end
end

tabMissionsBtn.MouseButton1Click:Connect(function() showTab("missions") end)
tabLogBtn.MouseButton1Click:Connect(function() showTab("log") end)
tabFindBtn.MouseButton1Click:Connect(function() showTab("find") end)

-- Helper color function for rarity
local function rarityColor(r)
	if r == "mythic" then return Color3.fromRGB(255, 85, 255)
	elseif r == "legendary" then return C3(255,160,60)
	elseif r == "epic" then return C3(160,100,255)
	elseif r == "rare" then return C3(60,180,255)
	else return C3(140,180,140) end
end

-- Format countdown time
local function fmtCountdown(sec)
	if not sec or sec <= 0 then return "Expired" end
	local m = math.floor(sec/60); local s = sec%60
	return string.format("%dm %02ds", m, s)
end

-- Format date string
local function DateString(ts)
	if not ts or ts<=0 then return "-" end
	local dt = DateTime.fromUnixTimestamp(ts):ToLocalTime()
	return dt:FormatUniversalTime("YYYY-MM-DD HH:mm:ss","en-us")
end

-- Update countdowns
RunService.Heartbeat:Connect(function()
	if #countdowns == 0 then return end
	local elapsed = os.clock() - (clientRenderTime or 0)
	local nowEst = (serverNowAtRender or 0) + math.floor(elapsed)

	for i=#countdowns,1,-1 do
		local rec = countdowns[i]
		if not (rec and rec.label and rec.label.Parent) then
			table.remove(countdowns, i)
		else
			local left = math.max(0, (rec.expiresAt or 0) - nowEst)
			rec.label.Text = (rec.prefix or "Time")..": "..fmtCountdown(left)
		end
	end
end)

-- Open/close with smooth animations
local isOpen, isBusy = false, false
local hiddenUIs = {}

local function setOtherUIsVisible(visible)
	local pg = Players.LocalPlayer:FindFirstChild("PlayerGui")
	if not pg then return end
	
	if not visible then
		-- Hide others (except SideMenu)
		hiddenUIs = {}
		for _, child in ipairs(pg:GetChildren()) do
			if child:IsA("ScreenGui") and child.Name ~= "MatrixQuests" and child.Name ~= "SideMenu" and child.Enabled then
				hiddenUIs[child] = true
				child.Enabled = false
			end
		end
	else
		-- Restore
		for ui, _ in pairs(hiddenUIs) do
			if ui and ui.Parent then
				ui.Enabled = true
			end
		end
		hiddenUIs = {}
	end
end

local function toggleUI()
	print("🎯 toggleUI() called! isOpen=", isOpen, "isBusy=", isBusy)
	if isBusy then 
		print("❌ toggleUI blocked - isBusy is true")
		return 
	end
	isBusy = true
	print("✅ toggleUI proceeding...")

	if not isOpen then
		print("Opening UI")
		_G.QuestUIOpen = true
		setOtherUIsVisible(false) -- Hide other UIs
		enableQuestMouse()
		backdrop.Visible = true
		main.Visible = true
		main.Size = UDim2.fromOffset(0,0)
		TweenService:Create(backdrop, TweenInfo.new(0.2), {BackgroundTransparency=0.5}):Play()
		TweenService:Create(blur, TweenInfo.new(0.2), {Size=12}):Play()
		TweenService:Create(bloom, TweenInfo.new(0.3), {Intensity=0.3}):Play()

		local t = TweenService:Create(main, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size=UDim2.fromOffset(1240,726)})
		t:Play()
		t.Completed:Connect(function()
			isOpen = true
			isBusy = false
			print("UI opened, showing missions tab")

			-- Force mission tab visible
			showTab("missions")

			-- Double check tabs are correctly set
			tabMissions.Visible = true
			tabLog.Visible = false
			tabFind.Visible = false

			-- Render with fresh data
			if _G.MatrixQuest.render then _G.MatrixQuest.render() end

			watermark.Text = "VAULT ACCESS: 2025-08-19 00:33:10 (almoe930-dotcom)"
		end)
	else
		print("Closing UI")
		_G.QuestUIOpen = false
		setOtherUIsVisible(true) -- Restore other UIs
		disableQuestMouse()
		TweenService:Create(backdrop, TweenInfo.new(0.15), {BackgroundTransparency=1}):Play()
		TweenService:Create(blur, TweenInfo.new(0.15), {Size=0}):Play()
		TweenService:Create(bloom, TweenInfo.new(0.2), {Intensity=0}):Play()

		local t = TweenService:Create(main, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size=UDim2.fromOffset(0,0)})
		t:Play()
		t.Completed:Connect(function()
			backdrop.Visible = false
			main.Visible = false
			isOpen = false
			isBusy = false
		end)
	end
end

closeBtn.MouseButton1Click:Connect(function() if isOpen then toggleUI() end end)
backdrop.MouseButton1Click:Connect(function() if isOpen then toggleUI() end end)

print("✅ QuestCore: Close/backdrop connected")

-- Keybind both with ContextActionService and fallback
ContextActionService:UnbindAction("ToggleMatrixQuests")
ContextActionService:BindAction(
	"ToggleMatrixQuests",
	function(actionName, inputState)
		print("🔑 P key detected via ContextActionService, state:", tostring(inputState))
		if inputState ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
		if UserInputService:GetFocusedTextBox() then 
			print("❌ Blocked - textbox focused")
			return Enum.ContextActionResult.Pass 
		end
		print("✅ Calling toggleUI from keybind")
		toggleUI()
		return Enum.ContextActionResult.Sink
	end,
	false,
	Enum.KeyCode.P
)

print("✅ QuestCore: P keybind registered!")

UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.P and not UserInputService:GetFocusedTextBox() then
		print("🔑 P key detected via InputBegan fallback")
		toggleUI()
	end
end)

-- CYBERPUNK Helper button - HOT MAGENTA NEON!
local hotBtn = Instance.new("TextButton")
hotBtn.Name = "OpenQuests"
hotBtn.Size = UDim2.fromOffset(155, 40)
hotBtn.Position = UDim2.new(0, 12, 0, GuiService:GetGuiInset().Y + 12)
hotBtn.BackgroundColor3 = MAGENTA
hotBtn.BackgroundTransparency = 0
hotBtn.Text = ""
hotBtn.AutoButtonColor = false
hotBtn.Parent = gui
Instance.new("UICorner", hotBtn).CornerRadius = UDim.new(0, 12)

-- Hot button gradient - HOT MAGENTA NEON
local hotBtnGrad = Instance.new("UIGradient")
hotBtnGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, C3(255,100,180)),
	ColorSequenceKeypoint.new(0.5, C3(255,50,140)),
	ColorSequenceKeypoint.new(1, C3(200,30,100))
})
hotBtnGrad.Rotation = 90
hotBtnGrad.Parent = hotBtn

local hbSt = Instance.new("UIStroke", hotBtn)
hbSt.Color = C3(255, 120, 180)
hbSt.Transparency = 0.3
hbSt.Thickness = 1.5

-- Hover effect
hotBtn.MouseEnter:Connect(function()
	TweenService:Create(hotBtn, TweenInfo.new(0.15), {BackgroundColor3=C3(255,70,160)}):Play()
end)
hotBtn.MouseLeave:Connect(function()
	TweenService:Create(hotBtn, TweenInfo.new(0.15), {BackgroundColor3=MAGENTA}):Play()
end)

local hotIcon = Instance.new("ImageLabel")
hotIcon.Size = UDim2.fromOffset(22, 22)
hotIcon.Position = UDim2.new(0, 14, 0.5, 0)
hotIcon.AnchorPoint = Vector2.new(0, 0.5)
hotIcon.BackgroundTransparency = 1
hotIcon.Image = "rbxassetid://114095469091928"
hotIcon.ImageColor3 = Color3.new(1,1,1)
hotIcon.Parent = hotBtn

local hotText = Instance.new("TextLabel")
hotText.BackgroundTransparency = 1
hotText.Size = UDim2.new(1, -44, 1, 0)
hotText.Position = UDim2.new(0, 42, 0, 0)
hotText.Font = FONT_HEADING
hotText.TextSize = 16
hotText.TextColor3 = Color3.new(1,1,1)
hotText.Text = "MISSIONS [P]"
hotText.TextXAlignment = Enum.TextXAlignment.Left
hotText.Parent = hotBtn
local hotTextStroke = Instance.new("UIStroke", hotText); hotTextStroke.Color=C3(100,20,60); hotTextStroke.Thickness=1.5; hotTextStroke.Transparency=0.2

hotBtn.MouseButton1Click:Connect(function()
	print("🔥 HOT BUTTON CLICKED!")
	toggleUI()
end)

print("✅ QuestCore: hotBtn click connected!")

-- PREMIUM BOUNTY CARD - Polished Brawl Stars Style!
local function rowBase(parent, name, desc, rarity, btnText)
	local theme = bountyTiers[rarity] or bountyTiers.common
	
	-- Main card container
	local row = Instance.new("Frame")
	row.Size=UDim2.new(1,-8,0,120)
	row.BackgroundColor3=C3(22,28,42)
	row.BackgroundTransparency=0
	row.Parent=parent
	Instance.new("UICorner", row).CornerRadius=UDim.new(0,14)
	
	-- Card gradient for depth - CYBERPUNK STYLE
	local cardGrad = Instance.new("UIGradient")
	cardGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, C3(38,48,72)),
		ColorSequenceKeypoint.new(0.3, C3(28,36,56)),
		ColorSequenceKeypoint.new(0.7, C3(22,28,44)),
		ColorSequenceKeypoint.new(1, C3(14,18,28))
	})
	cardGrad.Rotation = 135
	cardGrad.Parent = row
	
	-- Outer stroke with theme color
	local st = Instance.new("UIStroke", row); st.Color=theme.glow; st.Transparency=0.3; st.Thickness=2

	-- LEFT ACCENT BAR - CYBERPUNK NEON GLOW
	-- Second outer glow
	local accentGlow2 = Instance.new("Frame")
	accentGlow2.Size = UDim2.new(0, 18, 1, -6)
	accentGlow2.Position = UDim2.new(0, 2, 0, 3)
	accentGlow2.BackgroundColor3 = theme.glow
	accentGlow2.BackgroundTransparency = 0.9
	accentGlow2.ZIndex = 0
	accentGlow2.Parent = row
	Instance.new("UICorner", accentGlow2).CornerRadius = UDim.new(0, 8)
	
	-- First outer glow
	local accentGlow = Instance.new("Frame")
	accentGlow.Size = UDim2.new(0, 14, 1, -10)
	accentGlow.Position = UDim2.new(0, 4, 0, 5)
	accentGlow.BackgroundColor3 = theme.glow
	accentGlow.BackgroundTransparency = 0.7
	accentGlow.ZIndex = 1
	accentGlow.Parent = row
	Instance.new("UICorner", accentGlow).CornerRadius = UDim.new(0, 6)
	
	-- Main accent bar
	local accentBar = Instance.new("Frame")
	accentBar.Size = UDim2.new(0, 6, 1, -16)
	accentBar.Position = UDim2.new(0, 8, 0, 8)
	accentBar.BackgroundColor3 = theme.glow
	accentBar.ZIndex = 2
	accentBar.Parent = row
	Instance.new("UICorner", accentBar).CornerRadius = UDim.new(0, 3)
	
	-- Accent bar gradient for 3D effect
	local accentBarGrad = Instance.new("UIGradient")
	accentBarGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(0.3, theme.glow),
		ColorSequenceKeypoint.new(1, theme.glow:Lerp(Color3.new(0,0,0), 0.3))
	})
	accentBarGrad.Rotation = 0
	accentBarGrad.Parent = accentBar

	-- Tier badge - CYBERPUNK NEON
	-- Badge outer glow
	local pillGlow = Instance.new("Frame")
	pillGlow.Size = UDim2.fromOffset(108, 34)
	pillGlow.Position = UDim2.new(0, 18, 0, 6)
	pillGlow.BackgroundColor3 = theme.glow
	pillGlow.BackgroundTransparency = 0.85
	pillGlow.ZIndex = 2
	pillGlow.Parent = row
	Instance.new("UICorner", pillGlow).CornerRadius = UDim.new(0, 15)
	
	local pill = Instance.new("Frame")
	pill.Size=UDim2.fromOffset(100, 28)
	pill.Position=UDim2.new(0, 22, 0, 9)
	pill.BackgroundColor3 = theme.glow
	pill.ZIndex = 3
	pill.Parent = row
	Instance.new("UICorner", pill).CornerRadius=UDim.new(0,14)
	
	-- Badge gradient - premium look
	local pillGrad = Instance.new("UIGradient")
	pillGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
		ColorSequenceKeypoint.new(0.3, theme.glow:Lerp(Color3.new(1,1,1), 0.2)),
		ColorSequenceKeypoint.new(0.7, theme.glow),
		ColorSequenceKeypoint.new(1, theme.glow:Lerp(Color3.new(0,0,0), 0.3))
	})
	pillGrad.Rotation = 135
	pillGrad.Parent = pill
	
	local pillStroke = Instance.new("UIStroke", pill); pillStroke.Color=Color3.new(1,1,1); pillStroke.Transparency=0.6; pillStroke.Thickness=1.5

	local pillText = Instance.new("TextLabel")
	pillText.BackgroundTransparency=1
	pillText.Size=UDim2.fromScale(1,1)
	pillText.Font=FONT_HEADING
	pillText.TextSize=13
	pillText.TextColor3=Color3.new(1,1,1)
	pillText.Text = theme.name or string.upper(rarity or "common")
	pillText.ZIndex = 4
	pillText.Parent=pill
	local pillTextStroke = Instance.new("UIStroke", pillText); pillTextStroke.Color=C3(0,0,0); pillTextStroke.Transparency=0.2; pillTextStroke.Thickness=2

	-- Quest name with glow
	local nameL = Instance.new("TextLabel")
	nameL.BackgroundTransparency=1
	nameL.Size=UDim2.new(1,-140,0,26)
	nameL.Position=UDim2.new(0,130,0,8)
	nameL.Font=FONT_HEADING
	nameL.TextXAlignment=Enum.TextXAlignment.Left
	nameL.TextSize=19
	nameL.TextColor3=Color3.new(1,1,1)
	nameL.Text=name or ""
	nameL.Parent=row
	local nameStroke = Instance.new("UIStroke", nameL); nameStroke.Color=C3(0,0,0); nameStroke.Transparency=0.2; nameStroke.Thickness=2

	-- Description
	local descL = Instance.new("TextLabel")
	descL.BackgroundTransparency=1
	descL.Size=UDim2.new(1,-140,0,38)
	descL.Position=UDim2.new(0,130,0,36)
	descL.Font=FONT_TEXT
	descL.TextXAlignment=Enum.TextXAlignment.Left
	descL.TextWrapped=true
	descL.TextSize=13
	descL.TextColor3=C3(170,185,210)
	descL.Text=desc or ""
	descL.Parent=row

	-- ACCEPT button - CYBERPUNK NEON PREMIUM
	-- Button outer glow 2
	local btnGlow2 = Instance.new("Frame")
	btnGlow2.Size = UDim2.fromOffset(122, 46)
	btnGlow2.Position = UDim2.new(1, -126, 0, 4)
	btnGlow2.BackgroundColor3 = C3(80, 255, 160)
	btnGlow2.BackgroundTransparency = 0.9
	btnGlow2.ZIndex = 3
	btnGlow2.Parent = row
	Instance.new("UICorner", btnGlow2).CornerRadius = UDim.new(0, 14)
	
	-- Button outer glow
	local btnGlow = Instance.new("Frame")
	btnGlow.Size = UDim2.fromOffset(118, 42)
	btnGlow.Position = UDim2.new(1, -124, 0, 6)
	btnGlow.BackgroundColor3 = C3(80, 255, 160)
	btnGlow.BackgroundTransparency = 0.75
	btnGlow.ZIndex = 4
	btnGlow.Parent = row
	Instance.new("UICorner", btnGlow).CornerRadius = UDim.new(0, 12)
	
	local btn = Instance.new("TextButton")
	btn.Size=UDim2.fromOffset(112,36)
	btn.Position=UDim2.new(1,-121,0,9)
	btn.BackgroundColor3=C3(70,210,140)
	btn.TextColor3=Color3.new(1,1,1)
	btn.TextSize=16
	btn.Font=FONT_HEADING
	btn.Text=btnText or "ACCEPT"
	btn.AutoButtonColor=false
	btn.ZIndex = 5
	btn.Parent=row
	Instance.new("UICorner", btn).CornerRadius=UDim.new(0,10)
	
	-- Button gradient - cyberpunk style
	local btnGrad = Instance.new("UIGradient")
	btnGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, C3(130,255,190)),
		ColorSequenceKeypoint.new(0.3, C3(100,240,165)),
		ColorSequenceKeypoint.new(0.7, C3(70,210,140)),
		ColorSequenceKeypoint.new(1, C3(45,160,105))
	})
	btnGrad.Rotation = 135
	btnGrad.Parent = btn
	
	-- Button border stroke
	local bst=Instance.new("UIStroke", btn)
	bst.Color=Color3.new(1,1,1)
	bst.Transparency=0.5
	bst.Thickness=2
	
	-- Button text stroke
	local btnTextStroke = Instance.new("UIStroke")
	btnTextStroke.Color = C3(0,0,0)
	btnTextStroke.Transparency = 0.1
	btnTextStroke.Thickness = 2
	btnTextStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	btnTextStroke.Parent = btn
	
	-- Hover effects with glow
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3=C3(90,230,160)}):Play()
		TweenService:Create(btnGlow, TweenInfo.new(0.15), {BackgroundTransparency=0.55}):Play()
		TweenService:Create(btnGlow2, TweenInfo.new(0.15), {BackgroundTransparency=0.8}):Play()
		TweenService:Create(bst, TweenInfo.new(0.15), {Transparency=0.2}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3=C3(70,210,140)}):Play()
		TweenService:Create(btnGlow, TweenInfo.new(0.15), {BackgroundTransparency=0.75}):Play()
		TweenService:Create(btnGlow2, TweenInfo.new(0.15), {BackgroundTransparency=0.9}):Play()
		TweenService:Create(bst, TweenInfo.new(0.15), {Transparency=0.5}):Play()
	end)

	return row, btn
end

-- Create objective bars for bounty UI
local function addMiniObjectiveBars(row, objectives, progress, theme)
	local container = Instance.new("Frame")
	container.BackgroundTransparency = 1
	container.Size = UDim2.new(1,-120,0, 22 * #objectives)
	container.Position = UDim2.new(0,10,1, -(26 + 22*#objectives))
	container.Parent = row

	local barColor = theme.glow or BRIGHT_GREEN
	local textColor = theme.glow or DIM_GREEN

	for i,obj in ipairs(objectives) do
		local line = Instance.new("Frame")
		line.BackgroundTransparency = 1
		line.Size = UDim2.new(1,0,0,18)
		line.Position = UDim2.new(0,0,0,(i-1)*22)
		line.Parent = container

		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(0.42,-6,1,0)
		label.Position = UDim2.new(0,0,0,0)
		label.Font = FONT_TEXT
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextSize = 12
		label.TextColor3 = textColor
		label.Text = obj.key
		label.Parent = line

		local bar = Instance.new("Frame")
		bar.Size = UDim2.new(0.58,0,0,8)
		bar.Position = UDim2.new(0.42,6,0.5,-4)
		bar.BackgroundColor3 = C3(6,9,8)
		bar.Parent = line
		Instance.new("UICorner", bar).CornerRadius = UDim.new(0,4)

		local fill = Instance.new("Frame")
		fill.Size = UDim2.new(0,0,1,0)
		fill.BackgroundColor3 = barColor
		fill.Parent = bar
		Instance.new("UICorner", fill).CornerRadius = UDim.new(0,4)

		local cur = (progress and progress[obj.key]) or 0
		local ratio = math.clamp(cur/(obj.count or 1), 0, 1)
		fill.Size = UDim2.new(ratio, 0, 1, 0)

		local txt = Instance.new("TextLabel")
		txt.BackgroundTransparency = 1
		txt.Size = UDim2.new(0,70,1,0)
		txt.Position = UDim2.new(1,6,0,0)
		txt.Font = FONT_TEXT
		txt.TextSize = 12
		txt.TextXAlignment = Enum.TextXAlignment.Left
		txt.TextColor3 = barColor
		txt.Text = string.format("%d/%d", cur, obj.count or 0)
		txt.Parent = line
	end
end

-- Render available bounties in Find tab
local function renderFind(state)
	clearChildren(findListScroll, true)
	
	if #(state.bounties or {}) == 0 then
		local placeholder = Instance.new("TextLabel")
		placeholder.BackgroundTransparency = 1
		placeholder.Size = UDim2.new(1, -10, 0, 40)
		placeholder.Position = UDim2.new(0, 5, 0, 6)
		placeholder.Font = FONT_HEADING
		placeholder.TextSize = 18
		placeholder.TextColor3 = BRIGHT_YELLOW
		placeholder.TextXAlignment = Enum.TextXAlignment.Center
		placeholder.Text = "No contracts available. Try refreshing."
		placeholder.Parent = findListScroll
		return
	end

	for idx, o in ipairs(state.bounties or {}) do
		local q = o.quest
		local rarity = (q.rarity or "common"):lower()
		local theme = bountyTiers[rarity] or bountyTiers.common
		local reward = q.reward or {}
		
		-- ========== 🔥 LEGENDARY ULTRA-PREMIUM CARD 🔥 ==========
		-- Outer glow container
		local glowContainer = Instance.new("Frame")
		glowContainer.Name = "BountyOffer_" .. idx
		glowContainer.Size = UDim2.new(1, -20, 0, 110)
		glowContainer.BackgroundTransparency = 1
		glowContainer.ClipsDescendants = false
		glowContainer.Parent = findListScroll
		
		-- 5-layer MEGA glow system (all inactive so they don't block clicks)
		local glow5 = Instance.new("Frame")
		glow5.Size = UDim2.new(1, 24, 1, 24)
		glow5.Position = UDim2.new(0, -12, 0, -12)
		glow5.BackgroundColor3 = theme.glow
		glow5.BackgroundTransparency = 0.97
		glow5.ZIndex = 0
		glow5.Active = false
		glow5.Parent = glowContainer
		Instance.new("UICorner", glow5).CornerRadius = UDim.new(0, 24)
		
		local glow4 = Instance.new("Frame")
		glow4.Size = UDim2.new(1, 16, 1, 16)
		glow4.Position = UDim2.new(0, -8, 0, -8)
		glow4.BackgroundColor3 = theme.glow
		glow4.BackgroundTransparency = 0.94
		glow4.ZIndex = 0
		glow4.Active = false
		glow4.Parent = glowContainer
		Instance.new("UICorner", glow4).CornerRadius = UDim.new(0, 20)
		
		local glow3 = Instance.new("Frame")
		glow3.Size = UDim2.new(1, 10, 1, 10)
		glow3.Position = UDim2.new(0, -5, 0, -5)
		glow3.BackgroundColor3 = theme.glow
		glow3.BackgroundTransparency = 0.88
		glow3.ZIndex = 0
		glow3.Active = false
		glow3.Parent = glowContainer
		Instance.new("UICorner", glow3).CornerRadius = UDim.new(0, 17)
		
		local glow2 = Instance.new("Frame")
		glow2.Size = UDim2.new(1, 4, 1, 4)
		glow2.Position = UDim2.new(0, -2, 0, -2)
		glow2.BackgroundColor3 = theme.glow
		glow2.BackgroundTransparency = 0.75
		glow2.ZIndex = 0
		glow2.Active = false
		glow2.Parent = glowContainer
		Instance.new("UICorner", glow2).CornerRadius = UDim.new(0, 14)
		
		-- Main card
		local row = Instance.new("Frame")
		row.Name = "Card"
		row.Size = UDim2.new(1, 0, 1, 0)
		row.BackgroundColor3 = CARD_BG
		row.BorderSizePixel = 0
		row.ClipsDescendants = true
		row.Parent = glowContainer
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 14)
		
		-- Rich background gradient (Brawl Stars style)
		local bgGrad = Instance.new("UIGradient")
		bgGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, C3(70, 80, 110)),
			ColorSequenceKeypoint.new(0.3, C3(55, 62, 85)),
			ColorSequenceKeypoint.new(0.7, C3(45, 50, 70)),
			ColorSequenceKeypoint.new(1, C3(35, 40, 55))
		})
		bgGrad.Rotation = 135
		bgGrad.Parent = row
		
		-- Animated shimmer effect (sweeping highlight)
		local shimmer = Instance.new("Frame")
		shimmer.Size = UDim2.new(0.3, 0, 2, 0)
		shimmer.Position = UDim2.new(-0.3, 0, -0.5, 0)
		shimmer.BackgroundColor3 = Color3.new(1, 1, 1)
		shimmer.BackgroundTransparency = 0.92
		shimmer.Rotation = 15
		shimmer.BorderSizePixel = 0
		shimmer.ZIndex = 3
		shimmer.Parent = row
		
		local shimmerGrad = Instance.new("UIGradient")
		shimmerGrad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.4, 0.85),
			NumberSequenceKeypoint.new(0.5, 0.7),
			NumberSequenceKeypoint.new(0.6, 0.85),
			NumberSequenceKeypoint.new(1, 1)
		})
		shimmerGrad.Parent = shimmer
		
		-- Animate shimmer sweep
		task.spawn(function()
			task.wait(idx * 0.15)
			while shimmer and shimmer.Parent do
				shimmer.Position = UDim2.new(-0.3, 0, -0.5, 0)
				local tween = TweenService:Create(shimmer, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
					Position = UDim2.new(1.1, 0, -0.5, 0)
				})
				tween:Play()
				tween.Completed:Wait()
				task.wait(3 + math.random() * 2)
			end
		end)
		
		-- Top edge highlight
		local topEdge = Instance.new("Frame")
		topEdge.Size = UDim2.new(1, -24, 0, 1)
		topEdge.Position = UDim2.new(0, 12, 0, 0)
		topEdge.BackgroundColor3 = Color3.new(1, 1, 1)
		topEdge.BackgroundTransparency = 0.8
		topEdge.BorderSizePixel = 0
		topEdge.ZIndex = 5
		topEdge.Parent = row
		
		-- Colored top glow bar
		local topGlow = Instance.new("Frame")
		topGlow.Size = UDim2.new(0.6, 0, 0, 2)
		topGlow.Position = UDim2.new(0.2, 0, 0, 0)
		topGlow.BackgroundColor3 = theme.glow
		topGlow.BackgroundTransparency = 0.6
		topGlow.BorderSizePixel = 0
		topGlow.ZIndex = 6
		topGlow.Parent = row
		
		local topGlowGrad = Instance.new("UIGradient")
		topGlowGrad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.3, 0.4),
			NumberSequenceKeypoint.new(0.7, 0.4),
			NumberSequenceKeypoint.new(1, 1)
		})
		topGlowGrad.Parent = topGlow
		
		-- Left accent bar with animated pulse
		local accentGlow = Instance.new("Frame")
		accentGlow.Name = "AccentGlow"
		accentGlow.Size = UDim2.new(0, 12, 1, -20)
		accentGlow.Position = UDim2.new(0, -3, 0, 10)
		accentGlow.BackgroundColor3 = theme.glow
		accentGlow.BackgroundTransparency = 0.7
		accentGlow.BorderSizePixel = 0
		accentGlow.ZIndex = 1
		accentGlow.Parent = row
		Instance.new("UICorner", accentGlow).CornerRadius = UDim.new(0, 6)
		
		local sideAccent = Instance.new("Frame")
		sideAccent.Size = UDim2.new(0, 5, 1, -20)
		sideAccent.Position = UDim2.new(0, 0, 0, 10)
		sideAccent.BackgroundColor3 = theme.glow
		sideAccent.BorderSizePixel = 0
		sideAccent.ZIndex = 2
		sideAccent.Parent = row
		Instance.new("UICorner", sideAccent).CornerRadius = UDim.new(0, 3)
		
		-- Accent gradient for depth
		local accentGrad = Instance.new("UIGradient")
		accentGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(0.5, theme.glow),
			ColorSequenceKeypoint.new(1, Color3.new(0.5, 0.5, 0.5))
		})
		accentGrad.Rotation = 90
		accentGrad.Parent = sideAccent
		
		-- Pulse animation on accent
		task.spawn(function()
			task.wait(idx * 0.1)
			while accentGlow and accentGlow.Parent do
				TweenService:Create(accentGlow, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
					BackgroundTransparency = 0.5
				}):Play()
				task.wait(1.5)
				TweenService:Create(accentGlow, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
					BackgroundTransparency = 0.8
				}):Play()
				task.wait(1.5)
			end
		end)
		
		-- Main stroke
		local stroke = Instance.new("UIStroke", row)
		stroke.Thickness = 1.5
		stroke.Color = theme.glow
		stroke.Transparency = 0.3

		-- ===== CONTENT AREA =====
		local content = Instance.new("Frame")
		content.Size = UDim2.new(1, -28, 1, -16)
		content.Position = UDim2.new(0, 18, 0, 8)
		content.BackgroundTransparency = 1
		content.ZIndex = 4
		content.Parent = row

		-- Title glow behind text
		local titleGlow = Instance.new("TextLabel")
		titleGlow.BackgroundTransparency = 1
		titleGlow.Size = UDim2.new(0.5, 0, 0, 28)
		titleGlow.Position = UDim2.new(0, 0, 0, -2)
		titleGlow.Font = FONT_HEADING
		titleGlow.TextSize = 19
		titleGlow.TextColor3 = theme.glow
		titleGlow.TextTransparency = 0.7
		titleGlow.TextXAlignment = Enum.TextXAlignment.Left
		titleGlow.Text = q.name
		titleGlow.ZIndex = 4
		titleGlow.Parent = content
		
		-- Title shadow
		local titleShadow = Instance.new("TextLabel")
		titleShadow.BackgroundTransparency = 1
		titleShadow.Size = UDim2.new(0.5, 0, 0, 28)
		titleShadow.Position = UDim2.new(0, 2, 0, 2)
		titleShadow.Font = FONT_HEADING
		titleShadow.TextSize = 19
		titleShadow.TextColor3 = C3(0, 0, 0)
		titleShadow.TextTransparency = 0.5
		titleShadow.TextXAlignment = Enum.TextXAlignment.Left
		titleShadow.Text = q.name
		titleShadow.ZIndex = 5
		titleShadow.Parent = content
		
		-- Main title
		local title = Instance.new("TextLabel")
		title.BackgroundTransparency = 1
		title.Size = UDim2.new(0.5, 0, 0, 28)
		title.Position = UDim2.new(0, 0, 0, 0)
		title.Font = FONT_HEADING
		title.TextSize = 19
		title.TextColor3 = theme.glow
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Text = q.name
		title.ZIndex = 6
		title.Parent = content

		-- Description with better styling
		local desc = Instance.new("TextLabel")
		desc.BackgroundTransparency = 1
		desc.Size = UDim2.new(0.5, 0, 0, 20)
		desc.Position = UDim2.new(0, 0, 0, 30)
		desc.Font = FONT_TEXT
		desc.TextSize = 14
		desc.TextColor3 = C3(140, 145, 160)
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.TextTruncate = Enum.TextTruncate.AtEnd
		desc.Text = q.desc
		desc.ZIndex = 6
		desc.Parent = content

		-- ===== BADGE (top right, aligned with accept button) =====
		-- Parent to glowContainer so it aligns with button
		local badgeContainer = Instance.new("Frame")
		badgeContainer.Size = UDim2.new(0, 110, 0, 26)
		badgeContainer.Position = UDim2.new(1, -128, 0, 10)
		badgeContainer.BackgroundTransparency = 1
		badgeContainer.ZIndex = 20
		badgeContainer.Parent = glowContainer
		
		-- Badge outer glow
		local badgeGlow = Instance.new("Frame")
		badgeGlow.Size = UDim2.new(1, 8, 1, 8)
		badgeGlow.Position = UDim2.new(0, -4, 0, -4)
		badgeGlow.BackgroundColor3 = theme.glow
		badgeGlow.BackgroundTransparency = 0.8
		badgeGlow.ZIndex = 20
		badgeGlow.Active = false
		badgeGlow.Parent = badgeContainer
		Instance.new("UICorner", badgeGlow).CornerRadius = UDim.new(0, 10)
		
		-- Badge border - PREMIUM GRADIENT
		local badge = Instance.new("Frame")
		badge.Size = UDim2.new(1, 0, 1, 0)
		badge.BackgroundColor3 = theme.glow
		badge.ZIndex = 21
		badge.Parent = badgeContainer
		Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 8)
		
		-- Badge gradient for that cyberpunk glow
		local badgeGrad = Instance.new("UIGradient")
		badgeGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(0.5, theme.glow),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(theme.glow.R * 180, theme.glow.G * 180, theme.glow.B * 180))
		})
		badgeGrad.Rotation = 135
		badgeGrad.Parent = badge
		
		-- Badge inner with gradient
		local badgeInner = Instance.new("Frame")
		badgeInner.Size = UDim2.new(1, -4, 1, -4)
		badgeInner.Position = UDim2.new(0, 2, 0, 2)
		badgeInner.BackgroundColor3 = C3(12, 14, 22)
		badgeInner.ZIndex = 22
		badgeInner.Parent = badge
		Instance.new("UICorner", badgeInner).CornerRadius = UDim.new(0, 6)
		
		local badgeInnerGrad = Instance.new("UIGradient")
		badgeInnerGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, C3(28, 32, 48)),
			ColorSequenceKeypoint.new(0.5, C3(14, 16, 24)),
			ColorSequenceKeypoint.new(1, C3(8, 10, 16))
		})
		badgeInnerGrad.Rotation = 135
		badgeInnerGrad.Parent = badgeInner
		
		-- Badge text (centered) with glow
		local badgeText = Instance.new("TextLabel")
		badgeText.Size = UDim2.fromScale(1, 1)
		badgeText.BackgroundTransparency = 1
		badgeText.Font = FONT_HEADING
		badgeText.TextSize = 12
		badgeText.TextColor3 = theme.glow
		badgeText.Text = string.upper(theme.name)
		badgeText.ZIndex = 23
		badgeText.Parent = badgeInner
		
		-- Badge text stroke for pop
		local badgeTextStroke = Instance.new("UIStroke")
		badgeTextStroke.Color = theme.glow
		badgeTextStroke.Transparency = 0.7
		badgeTextStroke.Thickness = 1
		badgeTextStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
		badgeTextStroke.Parent = badgeText

		-- ===== BOTTOM ROW =====
		local bottomRow = Instance.new("Frame")
		bottomRow.Size = UDim2.new(1, 0, 0, 38)
		bottomRow.Position = UDim2.new(0, 0, 1, -38)
		bottomRow.BackgroundTransparency = 1
		bottomRow.ZIndex = 6
		bottomRow.Parent = content

		-- Timer chip - CYBERPUNK NEON STYLE
		-- Outer glow 2
		local timerGlow2 = Instance.new("Frame")
		timerGlow2.Size = UDim2.new(0, 120, 0, 48)
		timerGlow2.Position = UDim2.new(0, -6, 0, -7)
		timerGlow2.BackgroundColor3 = theme.glow
		timerGlow2.BackgroundTransparency = 0.92
		timerGlow2.ZIndex = 5
		timerGlow2.Active = false
		timerGlow2.Parent = bottomRow
		Instance.new("UICorner", timerGlow2).CornerRadius = UDim.new(0, 16)
		
		local timerGlow = Instance.new("Frame")
		timerGlow.Size = UDim2.new(0, 114, 0, 42)
		timerGlow.Position = UDim2.new(0, -3, 0, -4)
		timerGlow.BackgroundColor3 = theme.glow
		timerGlow.BackgroundTransparency = 0.8
		timerGlow.ZIndex = 6
		timerGlow.Active = false
		timerGlow.Parent = bottomRow
		Instance.new("UICorner", timerGlow).CornerRadius = UDim.new(0, 14)
		
		local timerChip = Instance.new("Frame")
		timerChip.Size = UDim2.new(0, 108, 0, 36)
		timerChip.Position = UDim2.new(0, 0, 0, -1)
		timerChip.BackgroundColor3 = C3(18, 22, 32)
		timerChip.ZIndex = 7
		timerChip.Parent = bottomRow
		Instance.new("UICorner", timerChip).CornerRadius = UDim.new(0, 10)
		
		local timerGrad = Instance.new("UIGradient")
		timerGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, C3(38, 44, 62)),
			ColorSequenceKeypoint.new(0.3, C3(28, 32, 46)),
			ColorSequenceKeypoint.new(0.7, C3(18, 22, 32)),
			ColorSequenceKeypoint.new(1, C3(10, 12, 18))
		})
		timerGrad.Rotation = 135
		timerGrad.Parent = timerChip
		
		local timerStroke = Instance.new("UIStroke", timerChip)
		timerStroke.Color = theme.glow
		timerStroke.Transparency = 0.2
		timerStroke.Thickness = 2
		
		local clockIcon = Instance.new("TextLabel")
		clockIcon.Size = UDim2.new(0, 26, 1, 0)
		clockIcon.Position = UDim2.new(0, 8, 0, 0)
		clockIcon.BackgroundTransparency = 1
		clockIcon.Font = FONT_TEXT
		clockIcon.TextSize = 16
		clockIcon.TextColor3 = theme.glow
		clockIcon.Text = "⏱"
		clockIcon.ZIndex = 8
		clockIcon.Parent = timerChip
		
		local timerText = Instance.new("TextLabel")
		timerText.Size = UDim2.new(1, -36, 1, 0)
		timerText.Position = UDim2.new(0, 34, 0, 0)
		timerText.BackgroundTransparency = 1
		timerText.Font = FONT_HEADING
		timerText.TextSize = 15
		timerText.TextColor3 = theme.glow
		timerText.TextXAlignment = Enum.TextXAlignment.Left
		timerText.Text = "59:00"
		timerText.ZIndex = 8
		timerText.Parent = timerChip
		
		-- Timer text glow
		local timerTextStroke = Instance.new("UIStroke")
		timerTextStroke.Color = theme.glow
		timerTextStroke.Transparency = 0.6
		timerTextStroke.Thickness = 1
		timerTextStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
		timerTextStroke.Parent = timerText
		
		if o.expiresAt and state.now > 0 then
			trackCountdown(timerText, o.expiresAt, "")
		end

		-- Money display - CYBERPUNK PREMIUM NEON
		local moneyGlow = Instance.new("Frame")
		moneyGlow.Size = UDim2.new(0, 102, 0, 44)
		moneyGlow.Position = UDim2.new(1, -220, 0, -5)
		moneyGlow.BackgroundColor3 = BRIGHT_GREEN
		moneyGlow.BackgroundTransparency = 0.75
		moneyGlow.ZIndex = 6
		moneyGlow.Active = false
		moneyGlow.Parent = bottomRow
		Instance.new("UICorner", moneyGlow).CornerRadius = UDim.new(0, 14)
		
		-- Second outer glow for more neon effect
		local moneyGlow2 = Instance.new("Frame")
		moneyGlow2.Size = UDim2.new(0, 110, 0, 50)
		moneyGlow2.Position = UDim2.new(1, -224, 0, -8)
		moneyGlow2.BackgroundColor3 = BRIGHT_GREEN
		moneyGlow2.BackgroundTransparency = 0.92
		moneyGlow2.ZIndex = 5
		moneyGlow2.Active = false
		moneyGlow2.Parent = bottomRow
		Instance.new("UICorner", moneyGlow2).CornerRadius = UDim.new(0, 18)
		
		local moneyFrame = Instance.new("Frame")
		moneyFrame.Size = UDim2.new(0, 92, 0, 36)
		moneyFrame.Position = UDim2.new(1, -215, 0, -1)
		moneyFrame.BackgroundColor3 = C3(15, 55, 30)
		moneyFrame.ZIndex = 7
		moneyFrame.Parent = bottomRow
		Instance.new("UICorner", moneyFrame).CornerRadius = UDim.new(0, 10)
		
		local moneyGradient = Instance.new("UIGradient")
		moneyGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, C3(40, 120, 70)),
			ColorSequenceKeypoint.new(0.3, C3(25, 80, 45)),
			ColorSequenceKeypoint.new(0.7, C3(15, 55, 30)),
			ColorSequenceKeypoint.new(1, C3(8, 35, 18))
		})
		moneyGradient.Rotation = 135
		moneyGradient.Parent = moneyFrame
		
		local moneyStroke = Instance.new("UIStroke", moneyFrame)
		moneyStroke.Color = BRIGHT_GREEN
		moneyStroke.Transparency = 0.1
		moneyStroke.Thickness = 2
		
		local moneyIcon = Instance.new("TextLabel")
		moneyIcon.Size = UDim2.new(0, 26, 1, 0)
		moneyIcon.Position = UDim2.new(0, 6, 0, 0)
		moneyIcon.BackgroundTransparency = 1
		moneyIcon.Font = FONT_HEADING
		moneyIcon.TextSize = 17
		moneyIcon.TextColor3 = BRIGHT_GREEN
		moneyIcon.Text = "💰"
		moneyIcon.ZIndex = 8
		moneyIcon.Parent = moneyFrame
		
		local moneyText = Instance.new("TextLabel")
		moneyText.Size = UDim2.new(1, -34, 1, 0)
		moneyText.Position = UDim2.new(0, 32, 0, 0)
		moneyText.BackgroundTransparency = 1
		moneyText.Font = FONT_HEADING
		moneyText.TextSize = 17
		moneyText.TextColor3 = BRIGHT_GREEN
		moneyText.TextXAlignment = Enum.TextXAlignment.Left
		moneyText.Text = "$" .. tostring(reward.money or 0)
		moneyText.ZIndex = 8
		moneyText.Parent = moneyFrame
		
		-- Money text glow stroke
		local moneyTextStroke = Instance.new("UIStroke")
		moneyTextStroke.Color = BRIGHT_GREEN
		moneyTextStroke.Transparency = 0.6
		moneyTextStroke.Thickness = 1
		moneyTextStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
		moneyTextStroke.Parent = moneyText

		-- ===== ACCEPT BUTTON - CYBERPUNK PREMIUM GRADIENT =====
		-- Button outer glow
		local btnGlow = Instance.new("Frame")
		btnGlow.Size = UDim2.new(0, 120, 0, 44)
		btnGlow.Position = UDim2.new(1, -125, 0, -5)
		btnGlow.BackgroundColor3 = theme.glow
		btnGlow.BackgroundTransparency = 0.75
		btnGlow.ZIndex = 9
		btnGlow.Active = false
		btnGlow.Parent = bottomRow
		Instance.new("UICorner", btnGlow).CornerRadius = UDim.new(0, 14)
		
		-- Second outer glow
		local btnGlow2 = Instance.new("Frame")
		btnGlow2.Size = UDim2.new(0, 128, 0, 50)
		btnGlow2.Position = UDim2.new(1, -129, 0, -8)
		btnGlow2.BackgroundColor3 = theme.glow
		btnGlow2.BackgroundTransparency = 0.92
		btnGlow2.ZIndex = 8
		btnGlow2.Active = false
		btnGlow2.Parent = bottomRow
		Instance.new("UICorner", btnGlow2).CornerRadius = UDim.new(0, 18)
		
		local btn = Instance.new("TextButton")
		btn.Name = "AcceptBtn"
		btn.Size = UDim2.new(0, 112, 0, 36)
		btn.Position = UDim2.new(1, -121, 0, -1)
		btn.BackgroundColor3 = theme.glow
		btn.Font = FONT_HEADING
		btn.TextSize = 15
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.Text = "ACCEPT"
		btn.AutoButtonColor = false
		btn.ZIndex = 10
		btn.Parent = bottomRow
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
		
		-- Premium gradient on button
		local btnGradient = Instance.new("UIGradient")
		local glowR, glowG, glowB = theme.glow.R, theme.glow.G, theme.glow.B
		btnGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(math.min(1, glowR * 1.4), math.min(1, glowG * 1.4), math.min(1, glowB * 1.4))),
			ColorSequenceKeypoint.new(0.3, Color3.new(glowR * 1.1, glowG * 1.1, glowB * 1.1)),
			ColorSequenceKeypoint.new(0.7, theme.glow),
			ColorSequenceKeypoint.new(1, Color3.new(glowR * 0.7, glowG * 0.7, glowB * 0.7))
		})
		btnGradient.Rotation = 135
		btnGradient.Parent = btn
		
		-- Button border stroke
		local btnBorderStroke = Instance.new("UIStroke")
		btnBorderStroke.Color = Color3.new(1, 1, 1)
		btnBorderStroke.Transparency = 0.6
		btnBorderStroke.Thickness = 1.5
		btnBorderStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		btnBorderStroke.Parent = btn
		
		-- Text stroke for pop
		local btnTextStroke = Instance.new("UIStroke")
		btnTextStroke.Color = C3(0, 0, 0)
		btnTextStroke.Transparency = 0.1
		btnTextStroke.Thickness = 2
		btnTextStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
		btnTextStroke.Parent = btn
		
		-- Hover effects on button
		btn.MouseEnter:Connect(function()
			TweenService:Create(btnGlow, TweenInfo.new(0.2), {BackgroundTransparency = 0.55}):Play()
			TweenService:Create(btnGlow2, TweenInfo.new(0.2), {BackgroundTransparency = 0.8}):Play()
			TweenService:Create(btnBorderStroke, TweenInfo.new(0.2), {Transparency = 0.3}):Play()
		end)
		btn.MouseLeave:Connect(function()
			TweenService:Create(btnGlow, TweenInfo.new(0.3), {BackgroundTransparency = 0.75}):Play()
			TweenService:Create(btnGlow2, TweenInfo.new(0.3), {BackgroundTransparency = 0.92}):Play()
			TweenService:Create(btnBorderStroke, TweenInfo.new(0.3), {Transparency = 0.6}):Play()
		end)
		
		print("Created accept button for bounty:", o.offerId)
		
		-- Card hover effect
		row.MouseEnter:Connect(function()
			TweenService:Create(stroke, TweenInfo.new(0.2), {Transparency = 0.1}):Play()
			TweenService:Create(glow2, TweenInfo.new(0.2), {BackgroundTransparency = 0.6}):Play()
			TweenService:Create(glow3, TweenInfo.new(0.2), {BackgroundTransparency = 0.8}):Play()
		end)
		row.MouseLeave:Connect(function()
			TweenService:Create(stroke, TweenInfo.new(0.3), {Transparency = 0.3}):Play()
			TweenService:Create(glow2, TweenInfo.new(0.3), {BackgroundTransparency = 0.75}):Play()
			TweenService:Create(glow3, TweenInfo.new(0.3), {BackgroundTransparency = 0.88}):Play()
		end)

		btn.MouseButton1Click:Connect(function()
			print("ACCEPT CLICKED for bounty:", o.offerId)
			local RS = game:GetService("ReplicatedStorage")
			local RF = RS:FindFirstChild("QuestRF")
			if RF then
				local ok, res = pcall(function() 
					return RF:InvokeServer("accept", {kind="bounty", offerId=o.offerId}) 
				end)
				if ok and res and res.ok then
					btn.BackgroundColor3 = BRIGHT_GREEN
					btn.TextColor3 = C3(10, 10, 10)
					btn.Text = "✓ DONE"
				end
			end
			task.delay(0.5, function()
				if render then render() end
			end)
		end)
	end
end

-- Main render function that will fetch data and call other render functions
local function render()
	-- Fetch state without blocking if RF missing
	if not RF then tryHookRemotes() end

	-- Create test mission data in case server returns nothing
	local st = {
		ok = true, 
		now = os.time(), 
		active = {}, 
		bounties = {
			{
				offerId = "test1",
				quest = {
					name = "Test Bounty",
					desc = "This is a test bounty",
					rarity = "rare",
					objectives = {
						{key = "TestObj", count = 10}
					},
					reward = {money = 500}
				}
			}
		}, 
		missionTrees = {
			{
				key = "TestTree", 
				name = "Test Mission Tree",
				color = C3(80, 180, 255),
				icon = "rbxassetid://8227572486",
				nodes = {
					{id="test1", name="Test Mission 1", status="available", rarity="common", desc="Test mission description"}
				},
				progress = 0
			}
		}, 
		missions = {}, 
		lockedNext = {}, 
		log = {}
	}

	-- Try to get real data from server
	if RF then
		local ok, srv = pcall(function() return RF:InvokeServer("get") end)
		print("Server quest data response:", ok, srv and srv.ok)
		if ok and srv and srv.ok then 
			st = srv
		end
	end

	serverNowAtRender = st.now or os.time()
	clientRenderTime = os.clock()
	countdowns = {}

	-- Call render functions from other modules
	renderBountyStrip(st) -- Call local function
	renderFind(st) -- Call local function
	if _G.MatrixQuest.renderMissionTrees then _G.MatrixQuest.renderMissionTrees(st) end
	if _G.MatrixQuest.renderLog then _G.MatrixQuest.renderLog(st) end

	-- Update watermark with correct timestamp and login
	watermark.Text = "VAULT ACCESS: 2025-08-19 00:33:10 (almoe930-dotcom)"
end

-- Hook QuestRE for updates
task.spawn(function()
	for _=1,50 do if RE then break end; tryHookRemotes(); task.wait(0.2) end
	if RE then
		print("Successfully hooked QuestRE remote event")
		RE.OnClientEvent:Connect(function(msg)
			if type(msg) ~= "table" then return end
			if msg.type == "progress" or msg.type=="completed" or msg.type=="accepted" or msg.type=="offersUpdated" or msg.type=="claimed" or msg.type=="pinned" then
				print("Received update:", msg.type)
				task.defer(render)
			end
		end)
	else
		print("Failed to hook QuestRE remote event")
	end
end)

-- Enhanced debug check
task.spawn(function()
	task.wait(1)
	print("UI check after 1 second:")
	print("RF remote exists:", RF ~= nil)
	print("RE remote exists:", RE ~= nil)

	-- Force the UI open after a delay (DISABLED - let player open manually)
	-- toggleUI()

	-- Refresh after a delay
	task.wait(2)
	if _G.MatrixQuest.render then _G.MatrixQuest.render() end
end)

-- Expose important functions and variables to other scripts
_G.MatrixQuest = {
	-- Services
	TweenService = TweenService,

	-- Variables
	gui = gui,
	main = main,
	tabMissions = tabMissions,
	tabLog = tabLog,
	tabFind = tabFind,
	bountyStrip = bountyStrip,
	bsScroll = bsScroll,
	bsTitle = bsTitle,
	watermark = watermark,

	-- Constants
	FONT_HEADING = FONT_HEADING,
	FONT_TEXT = FONT_TEXT,
	CORNER_RADIUS_LARGE = CORNER_RADIUS_LARGE,
	CORNER_RADIUS_MEDIUM = CORNER_RADIUS_MEDIUM,
	CORNER_RADIUS_SMALL = CORNER_RADIUS_SMALL,
	GREEN = GREEN,
	BRIGHT_GREEN = BRIGHT_GREEN,
	DIM_GREEN = DIM_GREEN,
	BAD_RED = BAD_RED,
	BLACK = BLACK,
	PANEL_COLOR = PANEL_COLOR,
	PANEL_SECONDARY_COLOR = PANEL_SECONDARY_COLOR,
	bountyTiers = bountyTiers,

	-- Functions
	C3 = C3,
	tryHookRemotes = tryHookRemotes,
	rarityColor = rarityColor,
	fmtCountdown = fmtCountdown,
	DateString = DateString,
	clearChildren = clearChildren,
	showTab = showTab,
	trackCountdown = trackCountdown,
	rowBase = rowBase,
	toggleUI = toggleUI,
	render = render,
	renderBountyStrip = renderBountyStrip,
	renderFind = renderFind,
	IsOpen = function() return isOpen end,
	Close = function() if isOpen then toggleUI() end end
}

print("QuestCore initialized!")