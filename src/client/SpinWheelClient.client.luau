-- SpinWheelClient.client.luau
-- Premium daily spin-the-wheel GUI with full animations and effects.

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local SpinWheelRF = nil
task.spawn(function()
	local re = ReplicatedStorage:WaitForChild("RemoteEvents", 15)
	if re then SpinWheelRF = re:WaitForChild("SpinWheelRF", 15) end
end)

-- ── CONSTANTS ─────────────────────────────────────────────────────────────
local N          = 8
local SEG_ARC    = 360 / N
local WHEEL_PX   = 340
local SPIN_SECS  = 5.5
local FULL_SPINS = 8

local ACCENT     = Color3.fromRGB(255, 55, 130)   -- hot pink
local ACCENT2    = Color3.fromRGB(130, 40, 255)    -- purple
local GOLD       = Color3.fromRGB(255, 210, 30)
local PANEL_BG   = Color3.fromRGB(14, 10, 28)

local SEG_COLORS = {
	Color3.fromRGB(255, 165, 40),   -- 1 orange   500 Gold
	Color3.fromRGB(55,  135, 255),  -- 2 blue     Crate
	Color3.fromRGB(175, 85,  255),  -- 3 purple   Skin
	Color3.fromRGB(255, 215, 0),    -- 4 gold     1000 Gold
	Color3.fromRGB(40,  205, 105),  -- 5 green    2x Crate
	Color3.fromRGB(75,  225, 225),  -- 6 cyan     2500 Gold
	Color3.fromRGB(255, 75,  75),   -- 7 red      Rare Skin
	Color3.fromRGB(255, 50,  135),  -- 8 pink     5000 Gold
}

local SEG_ICONS = { "💰", "📦", "🎨", "💰", "📦📦", "💰", "⚔️", "💎" }

local DEFAULT_LABELS = {
	"500 Gold", "Crate", "Skin", "1000 Gold",
	"2x Crate", "2500 Gold", "Rare Skin", "5000 Gold",
}

-- ── HELPERS ───────────────────────────────────────────────────────────────
local function corner(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = typeof(r) == "number" and UDim.new(0, r) or r
	c.Parent = parent
	return c
end

local function stroke(parent, color, thickness, trans)
	local s = Instance.new("UIStroke")
	s.Color        = color
	s.Thickness    = thickness or 2
	s.Transparency = trans or 0
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function gradient(parent, c0, c1, rot)
	local g = Instance.new("UIGradient")
	g.Color    = ColorSequence.new{ ColorSequenceKeypoint.new(0, c0), ColorSequenceKeypoint.new(1, c1) }
	g.Rotation = rot or 90
	g.Parent   = parent
	return g
end

local function formatTime(secs)
	secs = math.max(0, math.floor(secs))
	local h = math.floor(secs / 3600)
	local m = math.floor((secs % 3600) / 60)
	local s = secs % 60
	if h > 0 then return string.format("%dh %02dm %02ds", h, m, s)
	elseif m > 0 then return string.format("%dm %02ds", m, s)
	else return string.format("%ds", s) end
end

local function lerpColor(a, b, t)
	return Color3.new(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
end

-- ── SCREEN GUI ────────────────────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name            = "SpinWheelGui"
screenGui.ResetOnSpawn    = false
screenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset  = true
screenGui.Enabled         = false
screenGui.Parent          = playerGui

-- Dim overlay with vignette
local overlay = Instance.new("Frame")
overlay.Size                   = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 0.35
overlay.BorderSizePixel        = 0
overlay.ZIndex                 = 10
overlay.Parent                 = screenGui

-- ── OUTER GLOW (behind panel) ─────────────────────────────────────────────
local outerGlow = Instance.new("Frame")
outerGlow.Size                   = UDim2.new(0, 500, 0, 660)
outerGlow.AnchorPoint            = Vector2.new(0.5, 0.5)
outerGlow.Position               = UDim2.new(0.5, 0, 0.5, 0)
outerGlow.BackgroundColor3       = ACCENT
outerGlow.BackgroundTransparency = 0.88
outerGlow.BorderSizePixel        = 0
outerGlow.ZIndex                 = 10
outerGlow.Parent                 = screenGui
corner(outerGlow, 28)

-- ── MAIN PANEL (460 × 580) ───────────────────────────────────────────────
local panel = Instance.new("Frame")
panel.Size                   = UDim2.new(0, 460, 0, 620)
panel.AnchorPoint            = Vector2.new(0.5, 0.5)
panel.Position               = UDim2.new(0.5, 0, 0.5, 0)
panel.BackgroundColor3       = PANEL_BG
panel.BackgroundTransparency = 0
panel.BorderSizePixel        = 0
panel.ClipsDescendants       = true
panel.ZIndex                 = 11
panel.Parent                 = screenGui
corner(panel, 20)
stroke(panel, ACCENT, 2.5)

-- Panel scale (for open/close animations)
local panelScale = Instance.new("UIScale")
panelScale.Scale  = 0.85
panelScale.Parent = panel

-- Inner gradient
gradient(panel, Color3.fromRGB(45, 18, 65), Color3.fromRGB(12, 8, 22), 150)

-- Top accent bar
local topBar = Instance.new("Frame")
topBar.Size              = UDim2.new(1, 0, 0, 3)
topBar.BackgroundColor3  = ACCENT
topBar.BorderSizePixel   = 0
topBar.ZIndex            = 15
topBar.Parent            = panel
gradient(topBar, ACCENT, ACCENT2, 0)

-- ── TITLE ─────────────────────────────────────────────────────────────────
local titleLabel = Instance.new("TextLabel")
titleLabel.Size                   = UDim2.new(1, -80, 0, 44)
titleLabel.Position               = UDim2.new(0, 30, 0, 10)
titleLabel.BackgroundTransparency = 1
titleLabel.Text                   = "🎰  SPIN THE WHEEL"
titleLabel.Font                   = Enum.Font.FredokaOne
titleLabel.TextSize               = 30
titleLabel.TextColor3             = Color3.fromRGB(255, 255, 255)
titleLabel.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
titleLabel.TextStrokeTransparency = 0.4
titleLabel.TextXAlignment         = Enum.TextXAlignment.Center
titleLabel.ZIndex                 = 12
titleLabel.Parent                 = panel

-- Subtitle
local subtitleLabel = Instance.new("TextLabel")
subtitleLabel.Size                   = UDim2.new(1, -80, 0, 18)
subtitleLabel.Position               = UDim2.new(0, 30, 0, 48)
subtitleLabel.BackgroundTransparency = 1
subtitleLabel.Text                   = "Try your luck once per day!"
subtitleLabel.Font                   = Enum.Font.Gotham
subtitleLabel.TextSize               = 12
subtitleLabel.TextColor3             = Color3.fromRGB(180, 140, 200)
subtitleLabel.TextStrokeTransparency = 1
subtitleLabel.TextXAlignment         = Enum.TextXAlignment.Center
subtitleLabel.ZIndex                 = 12
subtitleLabel.Parent                 = panel

-- ── CLOSE BUTTON ──────────────────────────────────────────────────────────
local closeBtn = Instance.new("TextButton")
closeBtn.Size              = UDim2.new(0, 34, 0, 34)
closeBtn.AnchorPoint       = Vector2.new(1, 0)
closeBtn.Position          = UDim2.new(1, -12, 0, 12)
closeBtn.BackgroundColor3  = Color3.fromRGB(60, 30, 50)
closeBtn.BorderSizePixel   = 0
closeBtn.Text              = "✕"
closeBtn.Font              = Enum.Font.GothamBold
closeBtn.TextSize          = 16
closeBtn.TextColor3        = Color3.fromRGB(255, 100, 120)
closeBtn.AutoButtonColor   = false
closeBtn.ZIndex            = 14
closeBtn.Parent            = panel
corner(closeBtn, 17)
stroke(closeBtn, Color3.fromRGB(255, 80, 100), 1.5, 0.3)

-- ── WHEEL AREA ────────────────────────────────────────────────────────────
local RING_GAP   = 16           -- px between outer ring and inner wheel
local RING_SIZE  = WHEEL_PX + RING_GAP * 2  -- outer ring diameter

local wheelArea = Instance.new("Frame")
wheelArea.Size                   = UDim2.new(0, RING_SIZE + 20, 0, RING_SIZE + 20)
wheelArea.AnchorPoint            = Vector2.new(0.5, 0)
wheelArea.Position               = UDim2.new(0.5, 0, 0, 66)
wheelArea.BackgroundTransparency = 1
wheelArea.ClipsDescendants       = false
wheelArea.ZIndex                 = 12
wheelArea.Parent                 = panel

-- Outer decorative ring
local outerRing = Instance.new("Frame")
outerRing.Size              = UDim2.new(0, RING_SIZE, 0, RING_SIZE)
outerRing.AnchorPoint       = Vector2.new(0.5, 0.5)
outerRing.Position          = UDim2.new(0.5, 0, 0.5, 0)
outerRing.BackgroundColor3  = Color3.fromRGB(25, 12, 42)
outerRing.BorderSizePixel   = 0
outerRing.ZIndex            = 12
outerRing.Parent            = wheelArea
corner(outerRing, UDim.new(0.5, 0))
stroke(outerRing, ACCENT, 3)

-- Tick notches positioned around the perimeter using sin/cos
do
	local tickCount   = 24
	local ringRadius  = RING_SIZE / 2
	for i = 0, tickCount - 1 do
		local a   = math.rad(i * (360 / tickCount))
		local big = (i % 3 == 0)
		local tx  = math.sin(a) * (ringRadius - 6)
		local ty  = -math.cos(a) * (ringRadius - 6)
		local tick = Instance.new("Frame")
		tick.Size             = big and UDim2.new(0, 4, 0, 10) or UDim2.new(0, 3, 0, 6)
		tick.AnchorPoint      = Vector2.new(0.5, 0.5)
		tick.Position         = UDim2.new(0.5, tx, 0.5, ty)
		tick.Rotation         = math.deg(a)
		tick.BackgroundColor3 = big and GOLD or ACCENT
		tick.BorderSizePixel  = 0
		tick.ZIndex           = 13
		tick.Parent           = outerRing
		corner(tick, 2)
	end
end

-- Wheel background circle (centered inside outer ring)
local wheelBg = Instance.new("Frame")
wheelBg.Size              = UDim2.new(0, WHEEL_PX, 0, WHEEL_PX)
wheelBg.AnchorPoint       = Vector2.new(0.5, 0.5)
wheelBg.Position          = UDim2.new(0.5, 0, 0.5, 0)
wheelBg.BackgroundColor3  = Color3.fromRGB(18, 12, 32)
wheelBg.BorderSizePixel   = 0
wheelBg.ZIndex            = 13
wheelBg.ClipsDescendants  = true
wheelBg.Parent            = wheelArea
corner(wheelBg, UDim.new(0.5, 0))
stroke(wheelBg, Color3.fromRGB(80, 40, 120), 2)

-- Inner rotating frame (same size as wheelBg, pivots from center)
local innerWheel = Instance.new("Frame")
innerWheel.Size                   = UDim2.new(1, 0, 1, 0)
innerWheel.AnchorPoint            = Vector2.new(0.5, 0.5)
innerWheel.Position               = UDim2.new(0.5, 0, 0.5, 0)
innerWheel.BackgroundTransparency = 1
innerWheel.ZIndex                 = 14
innerWheel.Parent                 = wheelBg

-- Center hub (parented to wheelBg so it does NOT rotate with segments)
local hub = Instance.new("Frame")
hub.Size              = UDim2.new(0, 38, 0, 38)
hub.AnchorPoint       = Vector2.new(0.5, 0.5)
hub.Position          = UDim2.new(0.5, 0, 0.5, 0)
hub.BackgroundColor3  = ACCENT
hub.BorderSizePixel   = 0
hub.ZIndex            = 22
hub.Parent            = wheelBg
corner(hub, UDim.new(0.5, 0))
stroke(hub, GOLD, 3)
gradient(hub, ACCENT, ACCENT2, 135)

local hubInner = Instance.new("Frame")
hubInner.Size              = UDim2.new(0, 16, 0, 16)
hubInner.AnchorPoint       = Vector2.new(0.5, 0.5)
hubInner.Position          = UDim2.new(0.5, 0, 0.5, 0)
hubInner.BackgroundColor3  = GOLD
hubInner.BorderSizePixel   = 0
hubInner.ZIndex            = 23
hubInner.Parent            = hub
corner(hubInner, UDim.new(0.5, 0))

-- ── POINTER (fixed golden arrow above the wheel) ─────────────────────────
local pointerShadow = Instance.new("TextLabel")
pointerShadow.Size                   = UDim2.new(0, 40, 0, 40)
pointerShadow.AnchorPoint            = Vector2.new(0.5, 1)
pointerShadow.Position               = UDim2.new(0.5, 2, 0.5, -(WHEEL_PX / 2) + 12)
pointerShadow.BackgroundTransparency = 1
pointerShadow.Text                   = "▼"
pointerShadow.Font                   = Enum.Font.GothamBold
pointerShadow.TextSize               = 40
pointerShadow.TextColor3             = Color3.fromRGB(0, 0, 0)
pointerShadow.TextTransparency       = 0.5
pointerShadow.ZIndex                 = 29
pointerShadow.Parent                 = wheelArea

local pointer = Instance.new("TextLabel")
pointer.Size                   = UDim2.new(0, 40, 0, 40)
pointer.AnchorPoint            = Vector2.new(0.5, 1)
pointer.Position               = UDim2.new(0.5, 0, 0.5, -(WHEEL_PX / 2) + 10)
pointer.BackgroundTransparency = 1
pointer.Text                   = "▼"
pointer.Font                   = Enum.Font.GothamBold
pointer.TextSize               = 40
pointer.TextColor3             = GOLD
pointer.TextStrokeColor3       = Color3.fromRGB(180, 120, 0)
pointer.TextStrokeTransparency = 0.2
pointer.ZIndex                 = 30
pointer.Parent                 = wheelArea

-- ── SEGMENT BUILDING ──────────────────────────────────────────────────────
local pillRefs = {}

local function buildSegments(labels)
	for _, c in ipairs(innerWheel:GetChildren()) do c:Destroy() end
	pillRefs = {}

	local halfW = WHEEL_PX / 2

	for i = 1, N do
		local angle = (i - 1) * SEG_ARC
		local rad   = math.rad(angle)
		local color = SEG_COLORS[i] or Color3.fromRGB(180, 180, 180)
		local lbl   = (labels and labels[i]) or DEFAULT_LABELS[i] or "?"
		local icon  = SEG_ICONS[i] or ""

		-- Prize pill placed at ~38% of radius from center (further out)
		local rx = math.sin(rad)
		local ry = -math.cos(rad)

		local pill = Instance.new("Frame")
		pill.Size              = UDim2.new(0, 100, 0, 42)
		pill.AnchorPoint       = Vector2.new(0.5, 0.5)
		pill.Position          = UDim2.new(0.5 + rx * 0.38, 0, 0.5 + ry * 0.38, 0)
		pill.BackgroundColor3  = color
		pill.BorderSizePixel   = 0
		pill.ZIndex            = 16
		pill.Parent            = innerWheel
		corner(pill, 12)
		stroke(pill, Color3.fromRGB(255, 255, 255), 1.5, 0.5)

		-- Inner gradient on pill for depth
		gradient(pill, Color3.new(1, 1, 1), lerpColor(color, Color3.new(0, 0, 0), 0.3), 90)

		-- Icon label (top portion of pill)
		local iconLbl = Instance.new("TextLabel")
		iconLbl.Size                   = UDim2.new(1, 0, 0, 18)
		iconLbl.Position               = UDim2.new(0, 0, 0, 1)
		iconLbl.BackgroundTransparency = 1
		iconLbl.Text                   = icon
		iconLbl.Font                   = Enum.Font.GothamBold
		iconLbl.TextSize               = 13
		iconLbl.TextColor3             = Color3.fromRGB(255, 255, 255)
		iconLbl.ZIndex                 = 17
		iconLbl.Parent                 = pill

		-- Prize text (bottom portion of pill)
		local text = Instance.new("TextLabel")
		text.Size                   = UDim2.new(1, -6, 0, 20)
		text.Position               = UDim2.new(0, 3, 0, 18)
		text.BackgroundTransparency = 1
		text.Text                   = lbl
		text.Font                   = Enum.Font.FredokaOne
		text.TextSize               = 12
		text.TextScaled             = false
		text.TextWrapped            = false
		text.TextColor3             = Color3.fromRGB(255, 255, 255)
		text.TextStrokeTransparency = 0.3
		text.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
		text.TextXAlignment         = Enum.TextXAlignment.Center
		text.TextYAlignment         = Enum.TextYAlignment.Center
		text.ZIndex                 = 17
		text.Parent                 = pill

		pillRefs[i] = pill
	end
end

buildSegments(nil)

-- ── RESULT AREA ───────────────────────────────────────────────────────────
-- Result glow bg (hidden until win)
local resultGlow = Instance.new("Frame")
resultGlow.Size                   = UDim2.new(0, 320, 0, 50)
resultGlow.AnchorPoint            = Vector2.new(0.5, 0)
resultGlow.Position               = UDim2.new(0.5, 0, 0, 462)
resultGlow.BackgroundColor3       = ACCENT
resultGlow.BackgroundTransparency = 1
resultGlow.BorderSizePixel        = 0
resultGlow.ZIndex                 = 12
resultGlow.Parent                 = panel
corner(resultGlow, 14)

local resultText = Instance.new("TextLabel")
resultText.Size                   = UDim2.new(1, -40, 0, 44)
resultText.AnchorPoint            = Vector2.new(0.5, 0)
resultText.Position               = UDim2.new(0.5, 0, 0, 465)
resultText.BackgroundTransparency = 1
resultText.Text                   = ""
resultText.Font                   = Enum.Font.FredokaOne
resultText.TextSize               = 24
resultText.TextColor3             = GOLD
resultText.TextStrokeTransparency = 0.3
resultText.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
resultText.TextXAlignment         = Enum.TextXAlignment.Center
resultText.ZIndex                 = 13
resultText.Parent                 = panel

-- Result scale for pop animation
local resultScale = Instance.new("UIScale")
resultScale.Scale  = 0
resultScale.Parent = resultText

-- ── SPIN BUTTON ───────────────────────────────────────────────────────────
local spinBtn = Instance.new("TextButton")
spinBtn.Size              = UDim2.new(0, 200, 0, 54)
spinBtn.AnchorPoint       = Vector2.new(0.5, 0)
spinBtn.Position          = UDim2.new(0.5, 0, 0, 518)
spinBtn.BackgroundColor3  = ACCENT
spinBtn.BorderSizePixel   = 0
spinBtn.Text              = "🎰  SPIN!"
spinBtn.Font              = Enum.Font.FredokaOne
spinBtn.TextSize          = 26
spinBtn.TextColor3        = Color3.fromRGB(255, 255, 255)
spinBtn.TextStrokeColor3  = Color3.fromRGB(0, 0, 0)
spinBtn.TextStrokeTransparency = 0.5
spinBtn.AutoButtonColor   = false
spinBtn.ZIndex            = 12
spinBtn.Parent            = panel
corner(spinBtn, 14)
stroke(spinBtn, Color3.fromRGB(255, 140, 190), 2)
gradient(spinBtn, ACCENT, ACCENT2, 0)

local spinBtnScale = Instance.new("UIScale")
spinBtnScale.Scale  = 1
spinBtnScale.Parent = spinBtn

-- Cooldown label
local cooldownLabel = Instance.new("TextLabel")
cooldownLabel.Size                   = UDim2.new(1, -40, 0, 26)
cooldownLabel.AnchorPoint            = Vector2.new(0.5, 0)
cooldownLabel.Position               = UDim2.new(0.5, 0, 0, 578)
cooldownLabel.BackgroundTransparency = 1
cooldownLabel.Text                   = ""
cooldownLabel.Font                   = Enum.Font.GothamBold
cooldownLabel.TextSize               = 13
cooldownLabel.TextColor3             = Color3.fromRGB(200, 160, 180)
cooldownLabel.TextStrokeTransparency = 0.8
cooldownLabel.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
cooldownLabel.TextXAlignment         = Enum.TextXAlignment.Center
cooldownLabel.ZIndex                 = 12
cooldownLabel.Parent                 = panel

-- ── STATE ─────────────────────────────────────────────────────────────────
local isSpinning    = false
local countdownConn = nil
local canSpinNow    = false

local function setCanSpin(yes)
	canSpinNow = yes
	if yes then
		spinBtn.BackgroundColor3 = ACCENT
		spinBtn.AutoButtonColor  = false
		spinBtn.Text             = "🎰  SPIN!"
		spinBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
		cooldownLabel.Text       = "✨ Daily reward ready!"
		cooldownLabel.TextColor3 = Color3.fromRGB(80, 255, 130)
		-- Remove old gradient, add back the active one
		for _, ch in ipairs(spinBtn:GetChildren()) do
			if ch:IsA("UIGradient") then ch:Destroy() end
		end
		gradient(spinBtn, ACCENT, ACCENT2, 0)
	else
		spinBtn.BackgroundColor3 = Color3.fromRGB(50, 35, 65)
		spinBtn.AutoButtonColor  = false
		spinBtn.Text             = "⏳  Come back later"
		spinBtn.TextColor3       = Color3.fromRGB(140, 120, 150)
		cooldownLabel.TextColor3 = Color3.fromRGB(200, 160, 180)
		for _, ch in ipairs(spinBtn:GetChildren()) do
			if ch:IsA("UIGradient") then ch:Destroy() end
		end
		gradient(spinBtn, Color3.fromRGB(50, 35, 65), Color3.fromRGB(35, 25, 50), 0)
	end
end

local function startCooldownTicker(secsLeft)
	if countdownConn then countdownConn:Disconnect(); countdownConn = nil end
	if secsLeft <= 0 then setCanSpin(true); return end
	local endClock = os.clock() + secsLeft
	setCanSpin(false)
	countdownConn = RunService.Heartbeat:Connect(function()
		if not screenGui.Enabled then return end
		local rem = endClock - os.clock()
		if rem <= 0 then
			countdownConn:Disconnect(); countdownConn = nil
			setCanSpin(true)
			return
		end
		cooldownLabel.Text = "Next spin in: " .. formatTime(rem)
	end)
end

-- ── CELEBRATION PARTICLES ─────────────────────────────────────────────────
local function burstConfetti()
	for _ = 1, 20 do
		task.spawn(function()
			local conf = Instance.new("Frame")
			conf.Size              = UDim2.new(0, math.random(6, 12), 0, math.random(6, 12))
			conf.AnchorPoint       = Vector2.new(0.5, 0.5)
			conf.Position          = UDim2.new(0.5, 0, 0.5, -50)
			conf.BackgroundColor3  = SEG_COLORS[math.random(1, #SEG_COLORS)]
			conf.BorderSizePixel   = 0
			conf.Rotation          = math.random(0, 360)
			conf.ZIndex            = 50
			conf.Parent            = panel
			corner(conf, 3)

			local dx = math.random(-180, 180)
			local dy = math.random(-200, -40)
			TweenService:Create(conf, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = UDim2.new(0.5, dx, 0.5, dy),
				Rotation = math.random(-360, 360),
			}):Play()
			task.wait(0.4)
			TweenService:Create(conf, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.new(0.5, dx, 1, 60),
				BackgroundTransparency = 1,
			}):Play()
			task.wait(0.7)
			conf:Destroy()
		end)
	end
end

-- ── SPIN ANIMATION ────────────────────────────────────────────────────────
local function highlightWinner(winnerIdx)
	for i, pill in ipairs(pillRefs) do
		if i == winnerIdx then
			-- Winner pops out
			TweenService:Create(pill, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, 114, 0, 48),
			}):Play()
			local s = pill:FindFirstChildWhichIsA("UIStroke")
			if s then
				TweenService:Create(s, TweenInfo.new(0.2), { Transparency = 0, Thickness = 2.5, Color = GOLD }):Play()
			end
			-- Pulse the winner 3 times
			task.spawn(function()
				for _ = 1, 3 do
					TweenService:Create(pill, TweenInfo.new(0.15), { BackgroundTransparency = 0.3 }):Play()
					task.wait(0.15)
					TweenService:Create(pill, TweenInfo.new(0.15), { BackgroundTransparency = 0 }):Play()
					task.wait(0.15)
				end
			end)
		else
			TweenService:Create(pill, TweenInfo.new(0.3), {
				BackgroundTransparency = 0.6,
				Size = UDim2.new(0, 92, 0, 38),
			}):Play()
		end
	end
end

local function resetHighlights()
	for _, pill in ipairs(pillRefs) do
		pill.BackgroundTransparency = 0
		pill.Size = UDim2.new(0, 100, 0, 42)
		local s = pill:FindFirstChildWhichIsA("UIStroke")
		if s then s.Transparency = 0.5; s.Thickness = 1.5; s.Color = Color3.fromRGB(255, 255, 255) end
	end
end

local function spinToWinner(winnerIdx)
	local targetNorm = (-(winnerIdx - 1) * SEG_ARC) % 360
	local curNorm    = innerWheel.Rotation % 360
	if curNorm < 0 then curNorm += 360 end

	local delta = (targetNorm - curNorm) % 360
	if delta < 5 then delta += 360 end

	local finalRot = innerWheel.Rotation + FULL_SPINS * 360 + delta

	-- Pointer wobble during spin
	task.spawn(function()
		local startTime = os.clock()
		while os.clock() - startTime < SPIN_SECS - 0.3 do
			local wobble = math.random(-4, 4)
			TweenService:Create(pointer, TweenInfo.new(0.06), { Rotation = wobble }):Play()
			task.wait(0.06)
		end
		-- Settle pointer
		TweenService:Create(pointer, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Rotation = 0 }):Play()
	end)

	local tween = TweenService:Create(innerWheel,
		TweenInfo.new(SPIN_SECS, Enum.EasingStyle.Quintic, Enum.EasingDirection.Out),
		{ Rotation = finalRot }
	)
	tween:Play()
	tween.Completed:Wait()
end

-- ── SPIN BUTTON HANDLER ───────────────────────────────────────────────────
spinBtn.MouseButton1Click:Connect(function()
	if isSpinning or not SpinWheelRF or not canSpinNow then return end

	isSpinning = true
	resetHighlights()
	resultText.Text  = ""
	resultScale.Scale = 0
	resultGlow.BackgroundTransparency = 1
	spinBtn.Text = "⏳  Spinning…"

	-- Squish button
	TweenService:Create(spinBtnScale, TweenInfo.new(0.1), { Scale = 0.92 }):Play()
	task.wait(0.1)
	TweenService:Create(spinBtnScale, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()

	local ok, result = pcall(function() return SpinWheelRF:InvokeServer("Spin") end)
	if ok and result and result.success then
		spinToWinner(result.winnerIndex)
		highlightWinner(result.winnerIndex)
		burstConfetti()

		local prize = result.prize
		if prize.type == "gold" then
			resultText.Text       = "🏆  +" .. prize.amount .. " Gold!"
			resultText.TextColor3 = GOLD
			resultGlow.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
		elseif prize.type == "crate" then
			local qty = prize.qty or 1
			resultText.Text       = qty > 1 and ("📦  " .. qty .. "x Crates!") or "📦  Supply Crate!"
			resultText.TextColor3 = Color3.fromRGB(80, 190, 255)
			resultGlow.BackgroundColor3 = Color3.fromRGB(60, 140, 255)
		elseif prize.type == "skin" then
			resultText.Text       = "⚔️  " .. (prize.name or "Skin") .. "!"
			resultText.TextColor3 = Color3.fromRGB(210, 110, 255)
			resultGlow.BackgroundColor3 = Color3.fromRGB(170, 80, 255)
		end

		-- Result pop-in animation
		TweenService:Create(resultScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1.1 }):Play()
		TweenService:Create(resultGlow, TweenInfo.new(0.3), { BackgroundTransparency = 0.85 }):Play()
		task.wait(0.4)
		TweenService:Create(resultScale, TweenInfo.new(0.2), { Scale = 1 }):Play()

		startCooldownTicker(result.cooldown or 86400)
	else
		local reason = (result and result.reason) or "error"
		if reason == "cooldown" and result then
			startCooldownTicker(result.cooldownLeft or 86400)
		end
		resultText.Text       = tostring(reason)
		resultText.TextColor3 = Color3.fromRGB(255, 80, 80)
		TweenService:Create(resultScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		spinBtn.Text = "🎰  SPIN!"
	end

	isSpinning = false
end)

-- ── HOVER EFFECTS ─────────────────────────────────────────────────────────
-- Spin button: HQ-style rotation shake + scale
local spinOrigRot = spinBtn.Rotation
spinBtn.MouseEnter:Connect(function()
	if not canSpinNow or isSpinning then return end
	TweenService:Create(spinBtnScale, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1.06 }):Play()
	TweenService:Create(spinBtn, TweenInfo.new(0.12), { TextSize = 28 }):Play()
	-- Rotation shake
	task.spawn(function()
		TweenService:Create(spinBtn, TweenInfo.new(0.05), { Rotation = spinOrigRot + 4 }):Play();  task.wait(0.05)
		TweenService:Create(spinBtn, TweenInfo.new(0.05), { Rotation = spinOrigRot - 3 }):Play();  task.wait(0.05)
		TweenService:Create(spinBtn, TweenInfo.new(0.05), { Rotation = spinOrigRot + 2 }):Play();  task.wait(0.05)
		TweenService:Create(spinBtn, TweenInfo.new(0.06), { Rotation = spinOrigRot }):Play()
	end)
end)
spinBtn.MouseLeave:Connect(function()
	TweenService:Create(spinBtnScale, TweenInfo.new(0.15), { Scale = 1 }):Play()
	TweenService:Create(spinBtn, TweenInfo.new(0.1), { Rotation = spinOrigRot, TextSize = 26 }):Play()
end)

-- Close button: glow on hover
closeBtn.MouseEnter:Connect(function()
	TweenService:Create(closeBtn, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 38, 0, 38),
		BackgroundColor3 = Color3.fromRGB(255, 55, 80),
	}):Play()
end)
closeBtn.MouseLeave:Connect(function()
	TweenService:Create(closeBtn, TweenInfo.new(0.1), {
		Size = UDim2.new(0, 34, 0, 34),
		BackgroundColor3 = Color3.fromRGB(60, 30, 50),
	}):Play()
end)

-- ── SPIN BUTTON PULSE (when available) ────────────────────────────────────
task.spawn(function()
	local btnStroke = spinBtn:FindFirstChildWhichIsA("UIStroke")
	while spinBtn and spinBtn.Parent do
		if canSpinNow and not isSpinning and btnStroke then
			TweenService:Create(btnStroke, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Transparency = 0.5
			}):Play()
			task.wait(0.8)
			TweenService:Create(btnStroke, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Transparency = 0
			}):Play()
			task.wait(0.8)
		else
			task.wait(0.5)
		end
	end
end)

-- ── OPEN / CLOSE ──────────────────────────────────────────────────────────
local function fetchAndRefresh()
	if not SpinWheelRF then return end
	local ok, data = pcall(function() return SpinWheelRF:InvokeServer("GetData") end)
	if ok and data and data.success then
		if data.labels then buildSegments(data.labels) end
		if data.canSpin then
			setCanSpin(true)
		else
			startCooldownTicker(data.cooldownLeft)
		end
	end
end

local function openGui()
	if isSpinning then return end
	resetHighlights()
	resultText.Text     = ""
	resultScale.Scale   = 0
	resultGlow.BackgroundTransparency = 1
	screenGui.Enabled   = true
	_G.UIMouseEnabler   = true
	UserInputService.MouseBehavior    = Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = true

	-- Panel entrance animation
	panelScale.Scale = 0.85
	outerGlow.BackgroundTransparency = 1
	overlay.BackgroundTransparency   = 1
	TweenService:Create(panelScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	TweenService:Create(outerGlow, TweenInfo.new(0.4), { BackgroundTransparency = 0.88 }):Play()
	TweenService:Create(overlay, TweenInfo.new(0.25), { BackgroundTransparency = 0.35 }):Play()

	fetchAndRefresh()
end

local function closeGui()
	if isSpinning then return end
	-- Panel exit animation
	TweenService:Create(panelScale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.85 }):Play()
	TweenService:Create(outerGlow, TweenInfo.new(0.15), { BackgroundTransparency = 1 }):Play()
	TweenService:Create(overlay, TweenInfo.new(0.15), { BackgroundTransparency = 1 }):Play()
	task.delay(0.2, function()
		screenGui.Enabled = false
	end)
	_G.UIMouseEnabler = false
	if countdownConn then countdownConn:Disconnect(); countdownConn = nil end
end

closeBtn.MouseButton1Click:Connect(closeGui)

UserInputService.InputBegan:Connect(function(input, gameHandled)
	if gameHandled then return end
	if screenGui.Enabled and input.KeyCode == Enum.KeyCode.Escape then
		closeGui()
	end
end)

-- ── GLOBAL API ────────────────────────────────────────────────────────────
_G.MatrixSpinWheel = {
	Open   = openGui,
	Close  = closeGui,
	IsOpen = function() return screenGui.Enabled end,
}

-- ── HUD BUTTON ────────────────────────────────────────────────────────────
local hudGui = Instance.new("ScreenGui")
hudGui.Name           = "SpinWheelHUD"
hudGui.ResetOnSpawn   = false
hudGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
hudGui.Parent         = playerGui

local hudFrame = Instance.new("Frame")
hudFrame.Size              = UDim2.new(0, 130, 0, 42)
hudFrame.AnchorPoint       = Vector2.new(1, 0)
hudFrame.Position          = UDim2.new(1, -12, 0, 84)
hudFrame.BackgroundColor3  = Color3.fromRGB(18, 12, 32)
hudFrame.BorderSizePixel   = 0
hudFrame.ZIndex            = 5
hudFrame.Parent            = hudGui
corner(hudFrame, 12)
stroke(hudFrame, ACCENT, 2)
gradient(hudFrame, Color3.fromRGB(35, 15, 55), Color3.fromRGB(14, 10, 28), 90)

local openBtn = Instance.new("TextButton")
openBtn.Size              = UDim2.new(1, 0, 1, 0)
openBtn.BackgroundTransparency = 1
openBtn.Text              = "🎰  Spin"
openBtn.Font              = Enum.Font.FredokaOne
openBtn.TextSize          = 19
openBtn.TextColor3        = Color3.fromRGB(255, 255, 255)
openBtn.TextStrokeColor3  = Color3.fromRGB(0, 0, 0)
openBtn.TextStrokeTransparency = 0.6
openBtn.ZIndex            = 6
openBtn.Parent            = hudFrame

-- HQ-style hover on HUD button
local hudOrigRot = hudFrame.Rotation
local hudOrigSize = hudFrame.Size
hudFrame.Active = true

openBtn.MouseEnter:Connect(function()
	TweenService:Create(hudFrame, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 140, 0, 46)
	}):Play()
	TweenService:Create(openBtn, TweenInfo.new(0.1), {
		TextSize = 21,
		TextColor3 = Color3.fromRGB(255, 255, 150)
	}):Play()
	-- Rotation shake
	task.spawn(function()
		TweenService:Create(hudFrame, TweenInfo.new(0.05), { Rotation = hudOrigRot + 5 }):Play();  task.wait(0.05)
		TweenService:Create(hudFrame, TweenInfo.new(0.05), { Rotation = hudOrigRot - 4 }):Play();  task.wait(0.05)
		TweenService:Create(hudFrame, TweenInfo.new(0.05), { Rotation = hudOrigRot + 3 }):Play();  task.wait(0.05)
		TweenService:Create(hudFrame, TweenInfo.new(0.05), { Rotation = hudOrigRot - 2 }):Play();  task.wait(0.05)
		TweenService:Create(hudFrame, TweenInfo.new(0.06), { Rotation = hudOrigRot }):Play()
	end)
end)

openBtn.MouseLeave:Connect(function()
	TweenService:Create(hudFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = hudOrigSize,
		Rotation = hudOrigRot,
	}):Play()
	TweenService:Create(openBtn, TweenInfo.new(0.1), {
		TextSize = 19,
		TextColor3 = Color3.fromRGB(255, 255, 255)
	}):Play()
end)

openBtn.MouseButton1Click:Connect(function()
	if not screenGui.Enabled then
		-- Click squish → bounce
		TweenService:Create(hudFrame, TweenInfo.new(0.06), {
			Size = UDim2.new(0, 122, 0, 39)
		}):Play()
		task.delay(0.06, function()
			TweenService:Create(hudFrame, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Size = hudOrigSize
			}):Play()
		end)
		openGui()
	end
end)

-- Pulse the HUD button stroke to draw attention
task.spawn(function()
	local hudStroke = hudFrame:FindFirstChildWhichIsA("UIStroke")
	if not hudStroke then return end
	while hudFrame and hudFrame.Parent do
		TweenService:Create(hudStroke, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			Transparency = 0.5
		}):Play()
		task.wait(1.2)
		TweenService:Create(hudStroke, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			Transparency = 0
		}):Play()
		task.wait(1.2)
	end
end)
