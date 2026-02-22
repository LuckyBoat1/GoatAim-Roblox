-- interaction.client.luau
-- Floating BillboardGui that appears above nearby players
-- Always faces the camera, bobs in the air, glowing animated strokes
-- Options: Duel (top), Trade (bottom) — fully clickable

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

--// Player
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

--// Remote (non-blocking so the billboard system starts immediately)
local DuelEvent = ReplicatedStorage:FindFirstChild("DuelEvent")
if not DuelEvent then
	task.spawn(function()
		DuelEvent = ReplicatedStorage:WaitForChild("DuelEvent", 30)
		if DuelEvent then
			print("✅ [Interaction] DuelEvent found")
		else
			warn("⚠️ [Interaction] DuelEvent never appeared — duel button won't work")
		end
	end)
end

--// Config
local INTERACT_RANGE = 16 -- studs
local CHECK_INTERVAL = 0.12 -- seconds between proximity scans
local BOB_SPEED = 1.8 -- how fast it floats up/down
local BOB_AMPLITUDE = 0.25 -- studs of vertical bob
local BILLBOARD_OFFSET = Vector3.new(0, 5, 0) -- above head

-- BillboardGui pixel dimensions (bigger = sharper text)
local BB_WIDTH = 340
local BB_HEIGHT = 220
local BB_STUDS_W = 8
local BB_STUDS_H = 5.2

--// Theme colors (electric cyan)
local C = {
	BgMain = Color3.fromRGB(8, 10, 22),
	BgHeader = Color3.fromRGB(12, 14, 30),
	StrokeOuter = Color3.fromRGB(0, 200, 255),
	StrokeOuterDim = Color3.fromRGB(0, 70, 120),
	StrokeOuterBright = Color3.fromRGB(120, 235, 255),
	DuelBg = Color3.fromRGB(30, 10, 12),
	DuelAccent = Color3.fromRGB(255, 65, 75),
	DuelGlow = Color3.fromRGB(255, 120, 120),
	DuelStroke = Color3.fromRGB(255, 50, 60),
	TradeBg = Color3.fromRGB(10, 14, 34),
	TradeAccent = Color3.fromRGB(60, 170, 255),
	TradeGlow = Color3.fromRGB(120, 200, 255),
	TradeStroke = Color3.fromRGB(50, 150, 255),
	White = Color3.fromRGB(255, 255, 255),
	WhiteSoft = Color3.fromRGB(230, 235, 245),
	WhiteDim = Color3.fromRGB(160, 165, 180),
	NameGlow = Color3.fromRGB(0, 210, 255),
	Separator = Color3.fromRGB(30, 40, 65),
}

--------------------------------------------------------------------------
-- STATE
--------------------------------------------------------------------------
local activeBillboards: { [Player]: { gui: BillboardGui, connections: { RBXScriptConnection } } } = {}
local character, rootPart, humanoid
local lastCheck = 0

local function bindCharacter()
	character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
	humanoid = character:WaitForChild("Humanoid")
	rootPart = character:WaitForChild("HumanoidRootPart")
	print("✅ [Interaction] Character bound:", character.Name, "RootPart:", rootPart ~= nil)
end
bindCharacter()
localPlayer.CharacterAdded:Connect(bindCharacter)

--------------------------------------------------------------------------
-- UTILITY: Smooth tween helper
--------------------------------------------------------------------------
local function tw(obj, info, props)
	local t = TweenService:Create(obj, info, props)
	t:Play()
	return t
end

--------------------------------------------------------------------------
-- BUILD BILLBOARD GUI FOR A TARGET PLAYER
--------------------------------------------------------------------------
local function createBillboard(targetPlayer: Player, targetChar: Model): BillboardGui
	local hrp = targetChar:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end

	local connections: { RBXScriptConnection } = {}

	-- BillboardGui
	local bb = Instance.new("BillboardGui")
	bb.Name = "InteractBillboard"
	bb.Adornee = hrp
	bb.StudsOffset = BILLBOARD_OFFSET
	bb.Size = UDim2.new(BB_STUDS_W, 0, BB_STUDS_H, 0)
	bb.AlwaysOnTop = true
	bb.ResetOnSpawn = false
	bb.LightInfluence = 0
	bb.MaxDistance = INTERACT_RANGE + 4
	bb.ClipsDescendants = false
	bb.Active = true
	bb.Parent = playerGui

	-- Root (transparent container for glow layers + panel)
	local root = Instance.new("Frame")
	root.Name = "Root"
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Position = UDim2.new(0.5, 0, 0.46, 0)
	root.Size = UDim2.new(0.92, 0, 0.9, 0)
	root.BackgroundTransparency = 1
	root.Parent = bb

	------------------------------------------------------------
	-- GLOW LAYERS (colored frames behind the panel for bloom)
	------------------------------------------------------------
	local glowOuter = Instance.new("Frame")
	glowOuter.Name = "GlowOuter"
	glowOuter.AnchorPoint = Vector2.new(0.5, 0.5)
	glowOuter.Position = UDim2.new(0.5, 0, 0.5, 0)
	glowOuter.Size = UDim2.new(1, 14, 1, 14)
	glowOuter.BackgroundColor3 = C.StrokeOuter
	glowOuter.BackgroundTransparency = 0.88
	glowOuter.BorderSizePixel = 0
	glowOuter.ZIndex = 1
	glowOuter.Parent = root
	Instance.new("UICorner", glowOuter).CornerRadius = UDim.new(0, 22)

	local glowMid = Instance.new("Frame")
	glowMid.Name = "GlowMid"
	glowMid.AnchorPoint = Vector2.new(0.5, 0.5)
	glowMid.Position = UDim2.new(0.5, 0, 0.5, 0)
	glowMid.Size = UDim2.new(1, 6, 1, 6)
	glowMid.BackgroundColor3 = C.StrokeOuter
	glowMid.BackgroundTransparency = 0.82
	glowMid.BorderSizePixel = 0
	glowMid.ZIndex = 1
	glowMid.Parent = root
	Instance.new("UICorner", glowMid).CornerRadius = UDim.new(0, 20)

	------------------------------------------------------------
	-- MAIN PANEL
	------------------------------------------------------------
	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.new(0.5, 0, 0.5, 0)
	panel.Size = UDim2.new(1, 0, 1, 0)
	panel.BackgroundColor3 = C.BgMain
	panel.BackgroundTransparency = 0.04
	panel.BorderSizePixel = 0
	panel.ZIndex = 2
	panel.ClipsDescendants = true
	panel.Parent = root
	Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 16)

	-- Panel gradient
	local panelGrad = Instance.new("UIGradient")
	panelGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 38)),
		ColorSequenceKeypoint.new(0.4, Color3.fromRGB(12, 12, 24)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(6, 6, 14)),
	})
	panelGrad.Rotation = 180
	panelGrad.Parent = panel

	-- Rotating border stroke with gradient
	local mainStroke = Instance.new("UIStroke")
	mainStroke.Name = "MainStroke"
	mainStroke.Thickness = 3
	mainStroke.Color = Color3.fromRGB(255, 255, 255)
	mainStroke.Transparency = 0
	mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	mainStroke.Parent = panel

	local strokeGrad = Instance.new("UIGradient")
	strokeGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 200, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 40, 50)),
	})
	strokeGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 0),
	})
	strokeGrad.Rotation = 0
	strokeGrad.Parent = mainStroke

	-- Spin the stroke gradient continuously
	local function spinStroke()
		while bb.Parent do
			local t = tw(strokeGrad, TweenInfo.new(5, Enum.EasingStyle.Linear), {
				Rotation = strokeGrad.Rotation + 360,
			})
			t.Completed:Wait()
		end
	end
	task.spawn(spinStroke)

	------------------------------------------------------------
	-- ANIMATED SCAN LINE (horizontal bar that slides down)
	------------------------------------------------------------
	local scanLine = Instance.new("Frame")
	scanLine.Name = "ScanLine"
	scanLine.Size = UDim2.new(1, 0, 0, 3)
	scanLine.Position = UDim2.new(0, 0, 0, 0)
	scanLine.BackgroundColor3 = C.StrokeOuter
	scanLine.BackgroundTransparency = 0.6
	scanLine.BorderSizePixel = 0
	scanLine.ZIndex = 10
	scanLine.Parent = panel

	local scanGrad = Instance.new("UIGradient")
	scanGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.3, 0),
		NumberSequenceKeypoint.new(0.7, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	scanGrad.Parent = scanLine

	-- Animate scan line looping
	task.spawn(function()
		while bb.Parent do
			scanLine.Position = UDim2.new(0, 0, -0.02, 0)
			scanLine.BackgroundTransparency = 0.55
			local t = tw(scanLine, TweenInfo.new(2.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Position = UDim2.new(0, 0, 1, -3),
			})
			tw(scanLine, TweenInfo.new(2.2, Enum.EasingStyle.Sine), {
				BackgroundTransparency = 0.85,
			})
			t.Completed:Wait()
			task.wait(0.4)
		end
	end)

	------------------------------------------------------------
	-- HEADER
	------------------------------------------------------------
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0.26, 0)
	header.Position = UDim2.new(0, 0, 0, 0)
	header.BackgroundColor3 = Color3.fromRGB(0, 30, 50)
	header.BackgroundTransparency = 0.75
	header.BorderSizePixel = 0
	header.ZIndex = 3
	header.ClipsDescendants = true
	header.Parent = panel
	Instance.new("UICorner", header).CornerRadius = UDim.new(0, 16)

	-- Header gradient
	local hGrad = Instance.new("UIGradient")
	hGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 50, 80)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 12, 25)),
	})
	hGrad.Rotation = 180
	hGrad.Parent = header

	-- Player name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "PlayerName"
	nameLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	nameLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
	nameLabel.Size = UDim2.new(0.88, 0, 0.7, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBlack
	nameLabel.TextScaled = true
	nameLabel.TextColor3 = C.NameGlow
	nameLabel.Text = string.upper(targetPlayer.DisplayName)
	nameLabel.ZIndex = 5
	nameLabel.Parent = header

	-- Name text stroke for readability
	nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 25, 50)
	nameLabel.TextStrokeTransparency = 0.6

	------------------------------------------------------------
	-- SEPARATOR with animated width
	------------------------------------------------------------
	local sep = Instance.new("Frame")
	sep.Name = "Sep"
	sep.AnchorPoint = Vector2.new(0.5, 0)
	sep.Position = UDim2.new(0.5, 0, 0.26, 0)
	sep.Size = UDim2.new(0.9, 0, 0, 2)
	sep.BackgroundColor3 = C.StrokeOuter
	sep.BackgroundTransparency = 0.4
	sep.BorderSizePixel = 0
	sep.ZIndex = 5
	sep.Parent = panel

	local sepGrad = Instance.new("UIGradient")
	sepGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.15, 0),
		NumberSequenceKeypoint.new(0.85, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	sepGrad.Parent = sep

	------------------------------------------------------------
	-- BUTTON AREA
	------------------------------------------------------------
	local btnArea = Instance.new("Frame")
	btnArea.Name = "Buttons"
	btnArea.Size = UDim2.new(1, -14, 0.68, -6)
	btnArea.Position = UDim2.new(0, 7, 0.29, 3)
	btnArea.BackgroundTransparency = 1
	btnArea.ZIndex = 3
	btnArea.Parent = panel

	local btnLayout = Instance.new("UIListLayout")
	btnLayout.Padding = UDim.new(0.055, 0)
	btnLayout.FillDirection = Enum.FillDirection.Vertical
	btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	btnLayout.SortOrder = Enum.SortOrder.LayoutOrder
	btnLayout.Parent = btnArea

	------------------------------------------------------------
	-- BUTTON FACTORY (strokes animated via Color tween, not gradient)
	------------------------------------------------------------
	local btnStrokes = {} -- store for animation

	local function makeButton(config: {
		name: string,
		label: string,
		icon: string,
		subtitle: string,
		bgColor: Color3,
		accentColor: Color3,
		glowColor: Color3,
		strokeColor: Color3,
		order: number,
		callback: () -> (),
	})
		local btn = Instance.new("TextButton")
		btn.Name = config.name
		btn.Size = UDim2.new(1, 0, 0.45, 0)
		btn.BackgroundColor3 = config.bgColor
		btn.BackgroundTransparency = 0.15
		btn.AutoButtonColor = false
		btn.Text = ""
		btn.BorderSizePixel = 0
		btn.LayoutOrder = config.order
		btn.ZIndex = 4
		btn.Parent = btnArea
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)

		-- Button gradient
		local btnGrad = Instance.new("UIGradient")
		btnGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, config.bgColor:Lerp(C.White, 0.1)),
			ColorSequenceKeypoint.new(0.5, config.bgColor),
			ColorSequenceKeypoint.new(1, config.bgColor:Lerp(Color3.new(0,0,0), 0.15)),
		})
		btnGrad.Rotation = 180
		btnGrad.Parent = btn

		-- Stroke (animated color, no gradient)
		local btnStroke = Instance.new("UIStroke")
		btnStroke.Name = "Stroke"
		btnStroke.Thickness = 2
		btnStroke.Color = config.strokeColor
		btnStroke.Transparency = 0.25
		btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		btnStroke.Parent = btn
		table.insert(btnStrokes, { stroke = btnStroke, color = config.strokeColor, glow = config.glowColor })

		-- Left accent bar
		local bar = Instance.new("Frame")
		bar.Name = "Bar"
		bar.Size = UDim2.new(0, 4, 0.55, 0)
		bar.AnchorPoint = Vector2.new(0, 0.5)
		bar.Position = UDim2.new(0, 7, 0.5, 0)
		bar.BackgroundColor3 = config.accentColor
		bar.BackgroundTransparency = 0
		bar.BorderSizePixel = 0
		bar.ZIndex = 6
		bar.Parent = btn
		Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

		-- Icon
		local icon = Instance.new("TextLabel")
		icon.Name = "Icon"
		icon.AnchorPoint = Vector2.new(0, 0.5)
		icon.Position = UDim2.new(0, 18, 0.5, 0)
		icon.Size = UDim2.new(0, 26, 0, 26)
		icon.BackgroundTransparency = 1
		icon.Font = Enum.Font.GothamBold
		icon.Text = config.icon
		icon.TextScaled = true
		icon.TextColor3 = config.accentColor
		icon.ZIndex = 6
		icon.Parent = btn

		-- Label
		local label = Instance.new("TextLabel")
		label.Name = "Label"
		label.AnchorPoint = Vector2.new(0, 0.5)
		label.Position = UDim2.new(0, 50, 0.3, 0)
		label.Size = UDim2.new(1, -72, 0.4, 0)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBlack
		label.TextScaled = true
		label.TextColor3 = C.WhiteSoft
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Text = config.label
		label.TextStrokeTransparency = 0.85
		label.TextStrokeColor3 = config.strokeColor
		label.ZIndex = 6
		label.Parent = btn

		-- Subtitle
		local sub = Instance.new("TextLabel")
		sub.Name = "Sub"
		sub.AnchorPoint = Vector2.new(0, 0.5)
		sub.Position = UDim2.new(0, 50, 0.72, 0)
		sub.Size = UDim2.new(1, -72, 0.26, 0)
		sub.BackgroundTransparency = 1
		sub.Font = Enum.Font.Gotham
		sub.TextScaled = true
		sub.TextColor3 = C.WhiteDim
		sub.TextXAlignment = Enum.TextXAlignment.Left
		sub.Text = config.subtitle
		sub.ZIndex = 6
		sub.Parent = btn

		-- Arrow
		local arrow = Instance.new("TextLabel")
		arrow.Name = "Arrow"
		arrow.AnchorPoint = Vector2.new(1, 0.5)
		arrow.Position = UDim2.new(1, -8, 0.5, 0)
		arrow.Size = UDim2.new(0, 20, 0, 22)
		arrow.BackgroundTransparency = 1
		arrow.Font = Enum.Font.GothamBold
		arrow.Text = "›"
		arrow.TextScaled = true
		arrow.TextColor3 = config.strokeColor
		arrow.TextTransparency = 0.2
		arrow.ZIndex = 6
		arrow.Parent = btn

		-- Hover overlay
		local hover = Instance.new("Frame")
		hover.Name = "Hover"
		hover.Size = UDim2.new(1, 0, 1, 0)
		hover.BackgroundColor3 = config.accentColor
		hover.BackgroundTransparency = 1
		hover.BorderSizePixel = 0
		hover.ZIndex = 5
		hover.Parent = btn
		Instance.new("UICorner", hover).CornerRadius = UDim.new(0, 12)

		btn.MouseEnter:Connect(function()
			tw(hover, TweenInfo.new(0.18), { BackgroundTransparency = 0.82 })
			tw(btnStroke, TweenInfo.new(0.18), { Transparency = 0, Thickness = 3.5, Color = config.glowColor })
			tw(bar, TweenInfo.new(0.12), { Size = UDim2.new(0, 5, 0.7, 0), BackgroundColor3 = config.glowColor })
			tw(arrow, TweenInfo.new(0.12), { TextColor3 = C.White, TextTransparency = 0 })
			tw(label, TweenInfo.new(0.12), { TextColor3 = config.glowColor })
		end)

		btn.MouseLeave:Connect(function()
			tw(hover, TweenInfo.new(0.25), { BackgroundTransparency = 1 })
			tw(btnStroke, TweenInfo.new(0.25), { Transparency = 0.25, Thickness = 2, Color = config.strokeColor })
			tw(bar, TweenInfo.new(0.2), { Size = UDim2.new(0, 4, 0.55, 0), BackgroundColor3 = config.accentColor })
			tw(arrow, TweenInfo.new(0.2), { TextColor3 = config.strokeColor, TextTransparency = 0.2 })
			tw(label, TweenInfo.new(0.2), { TextColor3 = C.WhiteSoft })
		end)

		btn.MouseButton1Click:Connect(config.callback)
	end

	------------------------------------------------------------
	-- CREATE BUTTONS
	------------------------------------------------------------
	makeButton({
		name = "DuelBtn",
		label = "DUEL",
		icon = "⚔️",
		subtitle = "Challenge to 1v1",
		bgColor = C.DuelBg,
		accentColor = C.DuelAccent,
		glowColor = C.DuelGlow,
		strokeColor = C.DuelStroke,
		order = 1,
		callback = function()
			if DuelEvent then
				DuelEvent:FireServer("RequestDuel", targetPlayer)
			end
		end,
	})

	makeButton({
		name = "TradeBtn",
		label = "TRADE",
		icon = "💰",
		subtitle = "Open trade window",
		bgColor = C.TradeBg,
		accentColor = C.TradeAccent,
		glowColor = C.TradeGlow,
		strokeColor = C.TradeStroke,
		order = 2,
		callback = function()
			warn("[Interaction] Trade with " .. targetPlayer.Name .. " — not yet implemented")
		end,
	})

	------------------------------------------------------------
	-- POINTER (arrow pointing at player)
	------------------------------------------------------------
	local pointer = Instance.new("Frame")
	pointer.Name = "Pointer"
	pointer.AnchorPoint = Vector2.new(0.5, 0)
	pointer.Position = UDim2.new(0.5, 0, 1, -1)
	pointer.Size = UDim2.new(0, 14, 0, 14)
	pointer.Rotation = 45
	pointer.BackgroundColor3 = C.BgMain
	pointer.BackgroundTransparency = 0.04
	pointer.BorderSizePixel = 0
	pointer.ZIndex = 2
	pointer.Parent = panel

	local pointerStroke = Instance.new("UIStroke")
	pointerStroke.Thickness = 3
	pointerStroke.Color = C.StrokeOuter
	pointerStroke.Transparency = 0.05
	pointerStroke.Parent = pointer

	------------------------------------------------------------
	-- HEARTBEAT ANIMATION LOOP
	------------------------------------------------------------
	local startTime = tick()

	-- Color cycle arrays for the main stroke
	local strokeColors = { C.StrokeOuter, C.StrokeOuterBright, C.StrokeOuter, C.StrokeOuterDim }

	table.insert(connections, RunService.Heartbeat:Connect(function()
		local t = tick() - startTime
		local pulse01 = (math.sin(t * 2.5) + 1) / 2 -- 0→1 smoothly

		-- BOB up and down
		local bobOffset = math.sin(t * BOB_SPEED) * BOB_AMPLITUDE
		bb.StudsOffset = BILLBOARD_OFFSET + Vector3.new(0, bobOffset, 0)

		-- MAIN STROKE: color pulse
		local colorT = (math.sin(t * 1.8) + 1) / 2

		-- POINTER stroke matches orbit color
		pointerStroke.Color = C.StrokeOuterDim:Lerp(C.StrokeOuterBright, colorT)
		pointerStroke.Thickness = 2.5 + pulse01 * 0.5

		-- GLOW LAYERS pulse
		glowOuter.BackgroundTransparency = 0.84 + (1 - pulse01) * 0.1
		glowMid.BackgroundTransparency = 0.76 + (1 - pulse01) * 0.12
		glowOuter.BackgroundColor3 = mainStroke.Color
		glowMid.BackgroundColor3 = mainStroke.Color

		-- NAME pulse
		nameLabel.TextColor3 = C.NameGlow:Lerp(C.StrokeOuterBright, pulse01 * 0.5)

		-- SEPARATOR breathe
		sep.BackgroundTransparency = 0.3 + (1 - pulse01) * 0.3

		-- BUTTON STROKES: color cycle
		for i, bs in ipairs(btnStrokes) do
			local btnColorT = (math.sin(t * 2 + i * 1.5) + 1) / 2
			-- Only animate if not hovered (check transparency to detect hover state)
			if bs.stroke.Transparency > 0.1 then
				bs.stroke.Color = bs.color:Lerp(bs.glow, btnColorT)
			end
		end
	end))

	------------------------------------------------------------
	-- ENTRANCE ANIMATION
	------------------------------------------------------------
	root.Size = UDim2.new(0.5, 0, 0.45, 0)
	panel.BackgroundTransparency = 1
	mainStroke.Transparency = 1
	glowOuter.BackgroundTransparency = 1
	glowMid.BackgroundTransparency = 1

	tw(root, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0.92, 0, 0.9, 0),
	})
	tw(panel, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {
		BackgroundTransparency = 0.04,
	})
	tw(mainStroke, TweenInfo.new(0.5), {
		Transparency = 0,
	})
	task.delay(0.15, function()
		tw(glowOuter, TweenInfo.new(0.4), { BackgroundTransparency = 0.88 })
		tw(glowMid, TweenInfo.new(0.4), { BackgroundTransparency = 0.82 })
	end)

	return bb, connections
end

--------------------------------------------------------------------------
-- BILLBOARD LIFECYCLE: Show/hide based on proximity
--------------------------------------------------------------------------
local function showBillboard(targetPlayer: Player)
	if activeBillboards[targetPlayer] then return end
	local targetChar = targetPlayer.Character
	if not targetChar then return end
	local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
	if not targetHRP then return end
	local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
	if not targetHum or targetHum.Health <= 0 then return end

	print("🎯 [Interaction] Showing billboard for", targetPlayer.Name)
	local gui, conns = createBillboard(targetPlayer, targetChar)
	if gui then
		activeBillboards[targetPlayer] = { gui = gui, connections = conns }
		print("✅ [Interaction] Billboard created for", targetPlayer.Name)
	else
		warn("⚠️ [Interaction] createBillboard returned nil for", targetPlayer.Name)
	end
end

local function hideBillboard(targetPlayer: Player)
	local data = activeBillboards[targetPlayer]
	if not data then return end

	-- Fade out
	local root = data.gui:FindFirstChild("Root")
	if root then
		local panel = root:FindFirstChild("Panel")
		if panel then
			local stroke = panel:FindFirstChild("MainStroke")
			if stroke then
				tw(stroke, TweenInfo.new(0.15), { Transparency = 1 })
			end
			tw(panel, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				BackgroundTransparency = 1,
			})
		end
		-- Shrink glow layers
		local glowOuter = root:FindFirstChild("GlowOuter")
		local glowMid = root:FindFirstChild("GlowMid")
		if glowOuter then tw(glowOuter, TweenInfo.new(0.2), { BackgroundTransparency = 1 }) end
		if glowMid then tw(glowMid, TweenInfo.new(0.2), { BackgroundTransparency = 1 }) end

		tw(root, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Size = UDim2.new(0.4, 0, 0.35, 0),
		})
	end

	-- Disconnect animations
	for _, conn in ipairs(data.connections) do
		conn:Disconnect()
	end

	-- Destroy after fade
	task.delay(0.25, function()
		if data.gui and data.gui.Parent then
			data.gui:Destroy()
		end
	end)

	activeBillboards[targetPlayer] = nil
end

--------------------------------------------------------------------------
-- PROXIMITY SCANNER
--------------------------------------------------------------------------
RunService.Heartbeat:Connect(function(dt)
	lastCheck += dt
	if lastCheck < CHECK_INTERVAL then return end
	lastCheck = 0

	if not character or not rootPart or not humanoid or humanoid.Health <= 0 then
		-- Hide all if we're dead
		for plr, _ in pairs(activeBillboards) do
			hideBillboard(plr)
		end
		return
	end

	local myPos = rootPart.Position
	local nearbyPlayers: { [Player]: boolean } = {}
	local playerCount = 0

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr == localPlayer then continue end
		playerCount += 1

		local char = plr.Character
		if not char then continue end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum or hum.Health <= 0 then continue end

		local dist = (myPos - hrp.Position).Magnitude
		if dist <= INTERACT_RANGE then
			nearbyPlayers[plr] = true
			showBillboard(plr)
		end
	end

	-- Remove billboards for players no longer in range
	for plr, _ in pairs(activeBillboards) do
		if not nearbyPlayers[plr] then
			hideBillboard(plr)
		end
	end
end)

-- Cleanup when players leave
Players.PlayerRemoving:Connect(function(plr)
	hideBillboard(plr)
end)

--------------------------------------------------------------------------
-- DUEL INVITE POPUP (received from server)
--------------------------------------------------------------------------
local function createDuelPopup(fromPlayer: Player)
	local popup = Instance.new("ScreenGui")
	popup.Name = "DuelInvite"
	popup.ResetOnSpawn = false
	popup.DisplayOrder = 15
	popup.Parent = playerGui

	local bg = Instance.new("Frame")
	bg.AnchorPoint = Vector2.new(0.5, 0)
	bg.Position = UDim2.new(0.5, 0, 0, -130)
	bg.Size = UDim2.new(0, 400, 0, 120)
	bg.BackgroundColor3 = C.BgMain
	bg.BackgroundTransparency = 0.1
	bg.BorderSizePixel = 0
	bg.Parent = popup

	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0, 14)
	bgCorner.Parent = bg

	local bgStroke = Instance.new("UIStroke")
	bgStroke.Thickness = 2.5
	bgStroke.Color = C.DuelAccent
	bgStroke.Transparency = 0.2
	bgStroke.Parent = bg

	local bgStrokeGrad = Instance.new("UIGradient")
	bgStrokeGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, C.DuelGlow),
		ColorSequenceKeypoint.new(0.5, C.DuelStroke),
		ColorSequenceKeypoint.new(1, C.DuelGlow),
	})
	bgStrokeGrad.Rotation = 0
	bgStrokeGrad.Parent = bgStroke

	local msgLabel = Instance.new("TextLabel")
	msgLabel.Size = UDim2.new(1, -20, 0, 44)
	msgLabel.Position = UDim2.new(0, 10, 0, 8)
	msgLabel.BackgroundTransparency = 1
	msgLabel.Font = Enum.Font.GothamBold
	msgLabel.TextScaled = true
	msgLabel.TextColor3 = C.White
	msgLabel.Text = "⚔️  " .. fromPlayer.Name .. " challenges you!"
	msgLabel.Parent = bg

	-- Accept
	local acceptBtn = Instance.new("TextButton")
	acceptBtn.Size = UDim2.new(0.44, 0, 0, 44)
	acceptBtn.Position = UDim2.new(0.03, 0, 0, 60)
	acceptBtn.BackgroundColor3 = Color3.fromRGB(20, 160, 50)
	acceptBtn.BackgroundTransparency = 0.15
	acceptBtn.Font = Enum.Font.GothamBold
	acceptBtn.TextScaled = true
	acceptBtn.Text = "✓  ACCEPT"
	acceptBtn.TextColor3 = C.White
	acceptBtn.AutoButtonColor = false
	acceptBtn.BorderSizePixel = 0
	acceptBtn.Parent = bg
	Instance.new("UICorner", acceptBtn).CornerRadius = UDim.new(0, 10)

	local acceptStroke = Instance.new("UIStroke")
	acceptStroke.Thickness = 1.5
	acceptStroke.Color = Color3.fromRGB(50, 255, 100)
	acceptStroke.Transparency = 0.4
	acceptStroke.Parent = acceptBtn

	-- Decline
	local declineBtn = Instance.new("TextButton")
	declineBtn.Size = UDim2.new(0.44, 0, 0, 44)
	declineBtn.Position = UDim2.new(0.53, 0, 0, 60)
	declineBtn.BackgroundColor3 = Color3.fromRGB(160, 20, 20)
	declineBtn.BackgroundTransparency = 0.15
	declineBtn.Font = Enum.Font.GothamBold
	declineBtn.TextScaled = true
	declineBtn.Text = "✕  DECLINE"
	declineBtn.TextColor3 = C.White
	declineBtn.AutoButtonColor = false
	declineBtn.BorderSizePixel = 0
	declineBtn.Parent = bg
	Instance.new("UICorner", declineBtn).CornerRadius = UDim.new(0, 10)

	local declineStroke = Instance.new("UIStroke")
	declineStroke.Thickness = 1.5
	declineStroke.Color = Color3.fromRGB(255, 80, 80)
	declineStroke.Transparency = 0.4
	declineStroke.Parent = declineBtn

	-- Hover effects
	for _, b in ipairs({ acceptBtn, declineBtn }) do
		local origTrans = b.BackgroundTransparency
		b.MouseEnter:Connect(function()
			tw(b, TweenInfo.new(0.15), { BackgroundTransparency = 0 })
		end)
		b.MouseLeave:Connect(function()
			tw(b, TweenInfo.new(0.2), { BackgroundTransparency = origTrans })
		end)
	end

	-- Slide in from top
	tw(bg, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0, 20),
	})

	-- Rotate popup stroke
	local popupConn
	local popupStart = tick()
	popupConn = RunService.Heartbeat:Connect(function()
		bgStrokeGrad.Rotation = ((tick() - popupStart) * 80) % 360
	end)

	local function dismiss()
		if popupConn then popupConn:Disconnect() end
		tw(bg, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, 0, 0, -150),
		})
		task.delay(0.3, function()
			popup:Destroy()
		end)
	end

	acceptBtn.MouseButton1Click:Connect(function()
		if DuelEvent then
			DuelEvent:FireServer("AcceptDuel", fromPlayer)
		end
		dismiss()
	end)

	declineBtn.MouseButton1Click:Connect(function()
		if DuelEvent then
			DuelEvent:FireServer("DeclineDuel", fromPlayer)
		end
		dismiss()
	end)

	-- Auto-dismiss after 15s
	task.delay(15, function()
		if popup.Parent then
			if DuelEvent then
				DuelEvent:FireServer("DeclineDuel", fromPlayer)
			end
			dismiss()
		end
	end)
end

--------------------------------------------------------------------------
-- NOTIFICATION BANNER
--------------------------------------------------------------------------
local function showNotification(text: string, color: Color3?)
	local notifColor = color or C.StrokeOuter

	local notif = Instance.new("ScreenGui")
	notif.Name = "InteractNotif"
	notif.ResetOnSpawn = false
	notif.DisplayOrder = 12
	notif.Parent = playerGui

	local bar = Instance.new("Frame")
	bar.AnchorPoint = Vector2.new(0.5, 0)
	bar.Position = UDim2.new(0.5, 0, 0, -60)
	bar.Size = UDim2.new(0, 420, 0, 50)
	bar.BackgroundColor3 = C.BgMain
	bar.BackgroundTransparency = 0.1
	bar.BorderSizePixel = 0
	bar.Parent = notif

	Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 12)

	local barStroke = Instance.new("UIStroke")
	barStroke.Thickness = 2
	barStroke.Color = notifColor
	barStroke.Transparency = 0.3
	barStroke.Parent = bar

	local barLabel = Instance.new("TextLabel")
	barLabel.Size = UDim2.new(1, -20, 1, 0)
	barLabel.Position = UDim2.new(0, 10, 0, 0)
	barLabel.BackgroundTransparency = 1
	barLabel.Font = Enum.Font.GothamBold
	barLabel.TextScaled = true
	barLabel.TextColor3 = C.White
	barLabel.Text = text
	barLabel.Parent = bar

	tw(bar, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0, 16),
	})

	task.delay(3.5, function()
		tw(bar, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
			Position = UDim2.new(0.5, 0, 0, -70),
		})
		task.delay(0.3, function()
			notif:Destroy()
		end)
	end)
end

--------------------------------------------------------------------------
-- LISTEN FOR SERVER EVENTS
--------------------------------------------------------------------------
if DuelEvent then
	DuelEvent.OnClientEvent:Connect(function(action, fromPlayer)
		if action == "Invite" then
			createDuelPopup(fromPlayer)
		elseif action == "Declined" then
			showNotification(fromPlayer.Name .. " declined your duel.", C.DuelAccent)
		elseif action == "Message" then
			showNotification("⚔️ Teleporting to arena...", C.StrokeOuter)
		end
	end)
end

print("✅ [Interaction] Billboard system loaded — walk near a player to interact")
