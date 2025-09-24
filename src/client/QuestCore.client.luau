-- QuestCore.client.lua: Core UI setup, remotes, and main functions
-- Part 1 of 4 for the Matrix Quest System

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
							offerId = "test1",
							quest = {
								name = "Quick Hunt",
								desc = "Defeat 5 enemies in under 2 minutes",
								rarity = "rare",
								objectives = {
									{key = "Enemies", count = 5}
								},
								reward = {money = 500}
							}
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
local GREEN, BRIGHT_GREEN, DIM_GREEN = C3(20,250,120), C3(50,255,150), C3(10,160,80)
local BAD_RED, BLACK = C3(220,120,120), C3(6,8,10)

-- Base UI styling
local FONT_HEADING = Enum.Font.GothamBold
local FONT_TEXT = Enum.Font.Gotham
local CORNER_RADIUS_LARGE = UDim.new(0, 16)
local CORNER_RADIUS_MEDIUM = UDim.new(0, 10)
local CORNER_RADIUS_SMALL = UDim.new(0, 6)
local PANEL_COLOR = C3(8, 12, 10)
local PANEL_SECONDARY_COLOR = C3(14, 18, 16)

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

-- Main Panel
local main = Instance.new("Frame")
main.Name="MainPanel"; main.Size=UDim2.fromOffset(0,0); main.Position=UDim2.fromScale(0.5,0.5); main.AnchorPoint=Vector2.new(0.5,0.5)
main.BackgroundColor3=BLACK; main.BorderSizePixel=0; main.Visible=false; main.ClipsDescendants=true; main.Parent=gui
Instance.new("UICorner", main).CornerRadius = CORNER_RADIUS_LARGE
local mainStroke = Instance.new("UIStroke", main); mainStroke.Color=GREEN; mainStroke.Thickness=3; mainStroke.Transparency=0

-- Header
local header = Instance.new("Frame"); header.Size=UDim2.new(1,0,0,64); header.BackgroundColor3=C3(10,15,12); header.BackgroundTransparency=0.1; header.Parent=main
Instance.new("UICorner", header).CornerRadius=UDim.new(0,12)

local headerGradient = Instance.new("UIGradient")
headerGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, C3(18,28,22)),
	ColorSequenceKeypoint.new(1, C3(10,15,12))
})
headerGradient.Rotation = 90
headerGradient.Parent = header

local title = Instance.new("TextLabel")
title.Size=UDim2.new(1,-20,1,0); title.Position=UDim2.new(0,24,0,0); title.BackgroundTransparency=1
title.Font=FONT_HEADING; title.Text="VAULT QUESTS"; title.TextSize=26; title.TextColor3=BRIGHT_GREEN; title.TextXAlignment=Enum.TextXAlignment.Left; title.Parent=header

-- Header glow effect
local titleGlow = Instance.new("ImageLabel")
titleGlow.Size = UDim2.new(1.2, 0, 1.2, 0)
titleGlow.Position = UDim2.new(0, -12, 0, -6)
titleGlow.BackgroundTransparency = 1
titleGlow.Image = "rbxassetid://1316045217" -- radial gradient
titleGlow.ImageColor3 = GREEN
titleGlow.ImageTransparency = 0.8
titleGlow.ZIndex = 0
titleGlow.Parent = title

-- Date/time watermark
local watermark = Instance.new("TextLabel")
watermark.Size = UDim2.new(1, -40, 0, 20)
watermark.Position = UDim2.new(0, 20, 1, -30)
watermark.Font = FONT_TEXT
watermark.TextSize = 14
watermark.TextColor3 = GREEN
watermark.TextTransparency = 0.7
watermark.TextXAlignment = Enum.TextXAlignment.Right
watermark.BackgroundTransparency = 1
watermark.Text = "VAULT ACCESS: 2025-08-19 00:33:10 (almoe930-dotcom)"
watermark.Parent = main

-- Header dot decoration
local headerDots = Instance.new("ImageLabel")
headerDots.Size = UDim2.new(0, 120, 0, 30)
headerDots.Position = UDim2.new(1, -140, 0.5, 0)
headerDots.AnchorPoint = Vector2.new(0, 0.5)
headerDots.BackgroundTransparency = 1
headerDots.Image = "rbxassetid://6765455642" -- dot pattern
headerDots.ImageColor3 = GREEN
headerDots.ImageTransparency = 0.7
headerDots.Parent = header

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size=UDim2.fromOffset(40,40); closeBtn.Position=UDim2.new(1,-20,0.5,0); closeBtn.AnchorPoint=Vector2.new(1,0.5)
closeBtn.BackgroundColor3=C3(20,30,25); closeBtn.BackgroundTransparency=0.2; closeBtn.Text=""; closeBtn.Parent=header
Instance.new("UICorner", closeBtn).CornerRadius=UDim.new(0,8)
local closeBtnStroke = Instance.new("UIStroke"); closeBtnStroke.Color=GREEN; closeBtnStroke.Transparency=0.5; closeBtnStroke.Thickness=2; closeBtnStroke.Parent=closeBtn

-- X icon in close button
local closeX = Instance.new("TextLabel")
closeX.Size = UDim2.fromScale(1, 1)
closeX.BackgroundTransparency = 1
closeX.Font = FONT_HEADING
closeX.TextSize = 24
closeX.Text = "X"
closeX.TextColor3 = BRIGHT_GREEN
closeX.Parent = closeBtn

-- Visual effects
-- Scanlines
local scanlines = Instance.new("ImageLabel")
scanlines.Size=UDim2.fromScale(1,1); scanlines.BackgroundTransparency=1
scanlines.Image="rbxassetid://6104864792"; scanlines.ImageColor3=GREEN; scanlines.ImageTransparency=0.88
scanlines.ScaleType=Enum.ScaleType.Tile; scanlines.TileSize=UDim2.new(0,500,0,5); scanlines.ZIndex=10; scanlines.Parent=main

-- Random flicker effect
task.spawn(function()
	local flicker = Instance.new("Frame"); flicker.Size=UDim2.fromScale(1,1); flicker.BackgroundColor3=GREEN
	flicker.BackgroundTransparency=0.965; flicker.BorderSizePixel=0; flicker.ZIndex=20; flicker.Parent=main
	while flicker.Parent do
		local r = math.random()
		if r>0.992 then flicker.BackgroundTransparency=0.92; task.wait(0.05); flicker.BackgroundTransparency=0.965
		elseif r>0.985 then flicker.BackgroundTransparency=0.94; task.wait(0.02); flicker.BackgroundTransparency=0.965 end
		task.wait(0.1)
	end
end)

-- Content area
local root = Instance.new("Frame")
root.Size=UDim2.new(1,-40,1,-84); root.Position=UDim2.new(0,20,0,74)
root.BackgroundColor3=PANEL_COLOR; root.BackgroundTransparency=0.25; root.ClipsDescendants=true; root.Parent=main
Instance.new("UICorner", root).CornerRadius=CORNER_RADIUS_MEDIUM
local rootStroke = Instance.new("UIStroke", root); rootStroke.Color=GREEN; rootStroke.Transparency=0.4; rootStroke.Thickness=1

-- Ambient glow in corners
local function addCornerGlow(parent, position, anchorPoint)
	local glow = Instance.new("ImageLabel")
	glow.Size = UDim2.fromOffset(150, 150)
	glow.Position = position
	glow.AnchorPoint = anchorPoint
	glow.BackgroundTransparency = 1
	glow.Image = "rbxassetid://1316045217" -- radial gradient
	glow.ImageColor3 = GREEN
	glow.ImageTransparency = 0.85
	glow.ZIndex = 0
	glow.Parent = parent
	return glow
end

addCornerGlow(root, UDim2.fromScale(0, 0), Vector2.new(0, 0))
addCornerGlow(root, UDim2.fromScale(1, 0), Vector2.new(1, 0))
addCornerGlow(root, UDim2.fromScale(0, 1), Vector2.new(0, 1))
addCornerGlow(root, UDim2.fromScale(1, 1), Vector2.new(1, 1))

-- Bounty strip (top)
local bountyStrip = Instance.new("Frame")
bountyStrip.Name="BountyStrip"
bountyStrip.Size = UDim2.new(1,-20,0,96)
bountyStrip.Position = UDim2.new(0,10,0,10)
bountyStrip.BackgroundColor3 = PANEL_SECONDARY_COLOR
bountyStrip.BackgroundTransparency = 0
bountyStrip.Parent = root
Instance.new("UICorner", bountyStrip).CornerRadius=CORNER_RADIUS_MEDIUM
local bsStroke = Instance.new("UIStroke", bountyStrip); bsStroke.Color=BRIGHT_GREEN; bsStroke.Transparency=0.35; bsStroke.Thickness=2

-- Bounty strip gradient
local bsGradient = Instance.new("UIGradient")
bsGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, PANEL_SECONDARY_COLOR:Lerp(Color3.new(1,1,1), 0.05)),
	ColorSequenceKeypoint.new(1, PANEL_SECONDARY_COLOR:Lerp(Color3.new(0,0,0), 0.1))
})
bsGradient.Rotation = -90
bsGradient.Parent = bountyStrip

local bsTitle = Instance.new("TextLabel")
bsTitle.BackgroundTransparency=1
bsTitle.Size=UDim2.new(1,-10,0,22)
bsTitle.Position=UDim2.new(0,16,0,10)
bsTitle.Font=FONT_HEADING
bsTitle.TextXAlignment=Enum.TextXAlignment.Left
bsTitle.TextSize=18
bsTitle.TextColor3=BRIGHT_GREEN
bsTitle.Text="Active Bounties"
bsTitle.Parent=bountyStrip

-- Decorative line
local bsLine = Instance.new("Frame")
bsLine.Size = UDim2.new(0.3, 0, 0, 2)
bsLine.Position = UDim2.new(0, 16, 0, 38)
bsLine.BackgroundColor3 = GREEN
bsLine.BorderSizePixel = 0
bsLine.Parent = bountyStrip

local bsScroll = Instance.new("ScrollingFrame")
bsScroll.Size=UDim2.new(1,-16,0,56)
bsScroll.Position=UDim2.new(0,8,0,42)
bsScroll.BackgroundTransparency=1
bsScroll.ScrollBarThickness=4
bsScroll.ScrollBarImageColor3=GREEN
bsScroll.ScrollBarImageTransparency = 0.5
bsScroll.ClipsDescendants=true
bsScroll.Parent=bountyStrip

local bsLayout = Instance.new("UIListLayout")
bsLayout.FillDirection = Enum.FillDirection.Horizontal
bsLayout.Padding = UDim.new(0,12)
bsLayout.Parent = bsScroll
bsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	bsScroll.CanvasSize = UDim2.new(0, bsLayout.AbsoluteContentSize.X + 12, 0, 0)
end)

-- Tabs
local tabBar = Instance.new("Frame")
tabBar.Size=UDim2.new(1,-20,0,40)
tabBar.Position=UDim2.new(0,10,0, bountyStrip.Position.Y.Offset + bountyStrip.Size.Y.Offset + 10)
tabBar.BackgroundColor3=C3(10,15,12)
tabBar.BackgroundTransparency=0
tabBar.Parent=root
Instance.new("UICorner", tabBar).CornerRadius=CORNER_RADIUS_MEDIUM

-- Tab buttons with improved style
local function makeTabButton(text, order, icon)
	local btn = Instance.new("TextButton")
	btn.Size=UDim2.new(0,180,1,-10)
	btn.Position=UDim2.new(0, 10 + (order-1)*190, 0, 5)
	btn.BackgroundColor3=C3(14,18,16)
	btn.Text=""
	btn.Parent=tabBar
	Instance.new("UICorner", btn).CornerRadius=UDim.new(0,8)
	local st = Instance.new("UIStroke", btn); st.Color=GREEN; st.Thickness=2; st.Transparency=0.35

	-- Icon
	if icon then
		local iconImg = Instance.new("ImageLabel")
		iconImg.Size = UDim2.fromOffset(20, 20)
		iconImg.Position = UDim2.new(0, 12, 0.5, 0)
		iconImg.AnchorPoint = Vector2.new(0, 0.5)
		iconImg.BackgroundTransparency = 1
		iconImg.Image = icon
		iconImg.ImageColor3 = BRIGHT_GREEN
		iconImg.Parent = btn

		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(1, -44, 1, 0)
		label.Position = UDim2.new(0, 40, 0, 0)
		label.Font = FONT_HEADING
		label.TextSize = 16
		label.TextColor3 = BRIGHT_GREEN
		label.Text = text
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = btn
	else
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.Font = FONT_HEADING
		label.TextSize = 16
		label.TextColor3 = BRIGHT_GREEN
		label.Text = text
		label.Parent = btn
	end

	return btn
end

local tabMissionsBtn = makeTabButton("Army Missions", 1, "rbxassetid://8227317123") -- Military badge icon
local tabLogBtn = makeTabButton("Mission Log", 2, "rbxassetid://8430438472") -- Log icon
local tabFindBtn = makeTabButton("Find Bounties", 3, "rbxassetid://8430292256") -- Search icon

local contentArea = Instance.new("Frame")
contentArea.Size=UDim2.new(1,-20,1, -(bountyStrip.Position.Y.Offset + bountyStrip.Size.Y.Offset + 6 + tabBar.Size.Y.Offset + 14))
contentArea.Position=UDim2.new(0,10,0, bountyStrip.Position.Y.Offset + bountyStrip.Size.Y.Offset + 10 + tabBar.Size.Y.Offset + 16)
contentArea.BackgroundTransparency=1
contentArea.Parent=root

local tabMissions = Instance.new("Frame"); tabMissions.Size=UDim2.fromScale(1,1); tabMissions.BackgroundTransparency=1; tabMissions.Parent=contentArea
local tabLog = Instance.new("Frame"); tabLog.Size=UDim2.fromScale(1,1); tabLog.BackgroundTransparency=1; tabLog.Parent=contentArea
local tabFind = Instance.new("Frame"); tabFind.Size=UDim2.fromScale(1,1); tabFind.BackgroundTransparency=1; tabFind.Parent=contentArea

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

-- Tab switching with animation
local function showTab(which)
	tabMissions.Visible = (which == "missions")
	tabLog.Visible = (which == "log")
	tabFind.Visible = (which == "find")

	for _,b in ipairs({tabMissionsBtn, tabLogBtn, tabFindBtn}) do
		local sel = (b:FindFirstChild("TextLabel").Text:find("Army") and which=="missions") or 
			(b:FindFirstChild("TextLabel").Text:find("Log") and which=="log") or 
			(b:FindFirstChild("TextLabel").Text:find("Find") and which=="find")

		local targetColor = sel and C3(20,40,30) or C3(14,18,16)

		TweenService:Create(b, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()

		-- Also animate the icon and text if selected
		for _, child in pairs(b:GetChildren()) do
			if child:IsA("ImageLabel") then
				TweenService:Create(child, TweenInfo.new(0.2), {
					ImageTransparency = sel and 0 or 0.2,
					ImageColor3 = sel and C3(80,255,180) or BRIGHT_GREEN
				}):Play()
			elseif child:IsA("TextLabel") then
				TweenService:Create(child, TweenInfo.new(0.2), {
					TextTransparency = sel and 0 or 0.1,
					TextColor3 = sel and C3(80,255,180) or BRIGHT_GREEN
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
local function toggleUI()
	if isBusy then return end
	isBusy = true

	if not isOpen then
		print("Opening UI")
		_G.QuestUIOpen = true
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

-- Keybind both with ContextActionService and fallback
ContextActionService:UnbindAction("ToggleMatrixQuests")
ContextActionService:BindAction(
	"ToggleMatrixQuests",
	function(actionName, inputState)
		if inputState ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
		if UserInputService:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
		toggleUI()
		return Enum.ContextActionResult.Sink
	end,
	false,
	Enum.KeyCode.P
)

UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.P and not UserInputService:GetFocusedTextBox() then
		toggleUI()
	end
end)

-- Helper button
local hotBtn = Instance.new("TextButton")
hotBtn.Name = "OpenQuests"
hotBtn.Size = UDim2.fromOffset(120, 30)
hotBtn.Position = UDim2.new(0, 12, 0, GuiService:GetGuiInset().Y + 12)
hotBtn.BackgroundColor3 = C3(20,30,25)
hotBtn.BackgroundTransparency = 0.1
hotBtn.Text = ""
hotBtn.Parent = gui
Instance.new("UICorner", hotBtn).CornerRadius = UDim.new(0, 8)
local hbSt = Instance.new("UIStroke", hotBtn)
hbSt.Color = GREEN
hbSt.Transparency = 0.25
hbSt.Thickness = 2

local hotIcon = Instance.new("ImageLabel")
hotIcon.Size = UDim2.fromOffset(16, 16)
hotIcon.Position = UDim2.new(0, 10, 0.5, 0)
hotIcon.AnchorPoint = Vector2.new(0, 0.5)
hotIcon.BackgroundTransparency = 1
hotIcon.Image = "rbxassetid://8227317123" -- Mission icon
hotIcon.ImageColor3 = BRIGHT_GREEN
hotIcon.Parent = hotBtn

local hotText = Instance.new("TextLabel")
hotText.BackgroundTransparency = 1
hotText.Size = UDim2.new(1, -36, 1, 0)
hotText.Position = UDim2.new(0, 32, 0, 0)
hotText.Font = FONT_HEADING
hotText.TextSize = 14
hotText.TextColor3 = BRIGHT_GREEN
hotText.Text = "Quests (P)"
hotText.TextXAlignment = Enum.TextXAlignment.Left
hotText.Parent = hotBtn

hotBtn.MouseButton1Click:Connect(toggleUI)

-- Generic create bounty card base
local function rowBase(parent, name, desc, rarity, btnText)
	local row = Instance.new("Frame")
	row.Size=UDim2.new(1,-8,0,118)
	row.BackgroundColor3=C3(10,14,12)
	row.BackgroundTransparency=0
	row.Parent=parent
	Instance.new("UICorner", row).CornerRadius=CORNER_RADIUS_MEDIUM
	local st = Instance.new("UIStroke", row); st.Color=GREEN; st.Transparency=0.35

	local pill = Instance.new("Frame")
	pill.Size=UDim2.fromOffset(92, 22)
	pill.Position=UDim2.new(0, 10, 0, 8)
	pill.BackgroundColor3 = rarityColor(rarity)
	pill.BackgroundTransparency = 0.1
	pill.Parent = row
	Instance.new("UICorner", pill).CornerRadius=UDim.new(0,11)

	local pillText = Instance.new("TextLabel")
	pillText.BackgroundTransparency=1
	pillText.Size=UDim2.fromScale(1,1)
	pillText.Font=FONT_HEADING
	pillText.TextSize=12
	pillText.TextColor3=Color3.new(0,0,0)
	pillText.Text = string.upper(rarity or "common")
	pillText.Parent=pill

	local nameL = Instance.new("TextLabel")
	nameL.BackgroundTransparency=1
	nameL.Size=UDim2.new(1,-130,0,22)
	nameL.Position=UDim2.new(0,112,0,8)
	nameL.Font=FONT_HEADING
	nameL.TextXAlignment=Enum.TextXAlignment.Left
	nameL.TextSize=18
	nameL.TextColor3=BRIGHT_GREEN
	nameL.Text=name or ""
	nameL.Parent=row

	local descL = Instance.new("TextLabel")
	descL.BackgroundTransparency=1
	descL.Size=UDim2.new(1,-130,0,34)
	descL.Position=UDim2.new(0,112,0,34)
	descL.Font=FONT_TEXT
	descL.TextXAlignment=Enum.TextXAlignment.Left
	descL.TextWrapped=true
	descL.TextSize=14
	descL.TextColor3=DIM_GREEN
	descL.Text=desc or ""
	descL.Parent=row

	local btn = Instance.new("TextButton")
	btn.Size=UDim2.fromOffset(110,30)
	btn.Position=UDim2.new(1,-120,0,10)
	btn.BackgroundColor3=C3(20,30,25)
	btn.TextColor3=BRIGHT_GREEN
	btn.TextSize=16
	btn.Font=FONT_HEADING
	btn.Text=btnText or "Accept"
	btn.Parent=row
	Instance.new("UICorner", btn).CornerRadius=UDim.new(0,8)
	local bst=Instance.new("UIStroke", btn)
	bst.Color=GREEN
	bst.Transparency=0.3
	bst.Thickness=2

	return row, btn
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
			if #(srv.missionTrees or {}) > 0 or #(srv.bounties or {}) > 0 then
				st = srv
			end
		end
	end

	serverNowAtRender = st.now or os.time()
	clientRenderTime = os.clock()
	countdowns = {}

	-- Call render functions from other modules
	if _G.MatrixQuest.renderBountyStrip then _G.MatrixQuest.renderBountyStrip(st) end
	if _G.MatrixQuest.renderMissionTrees then _G.MatrixQuest.renderMissionTrees(st) end
	if _G.MatrixQuest.renderLog then _G.MatrixQuest.renderLog(st) end
	if _G.MatrixQuest.renderFind then _G.MatrixQuest.renderFind(st) end

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

	-- Force the UI open after a delay
	toggleUI()

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
	render = render
}

print("QuestCore initialized!")