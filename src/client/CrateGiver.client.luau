-- CrateGiver.client.luau
-- Dev tool: floating GUI to grant yourself crates with one click.
--
-- ╔══════════════════════════════════════════════════════════╗
-- ║  SETTINGS                                                ║
-- ╠══════════════════════════════════════════════════════════╣
-- ║  ENABLED         – set false to completely hide the GUI  ║
-- ║  DEFAULT_QTY     – how many crates each click gives      ║
-- ║  START_VISIBLE   – whether panel starts open or closed   ║
-- ║  POSITION        – starting screen-corner position       ║
-- ╚══════════════════════════════════════════════════════════╝
local ENABLED       = false
local DEFAULT_QTY   = 1          -- crates granted per click
local START_VISIBLE = true       -- true = panel open on join; false = collapsed
local POSITION      = UDim2.new(0, 12, 0.5, -160)  -- left-centre of screen

if not ENABLED then return end

-- ── Services & refs ───────────────────────────────────────────────────────────

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents  = ReplicatedStorage:WaitForChild("RemoteEvents", 15)
local CrateGiverRE  = RemoteEvents and RemoteEvents:WaitForChild("CrateGiverRE", 15)

if not CrateGiverRE then
	warn("[CrateGiver] CrateGiverRE not found — server script may not be running")
	return
end

-- ── Crate definitions (order = display order) ─────────────────────────────────

local CRATES = {
	{ key = "BRONZE",   label = "Bronze",   color = Color3.fromRGB(205, 127,  50) },
	{ key = "SILVER",   label = "Silver",   color = Color3.fromRGB(192, 192, 192) },
	{ key = "SAPPHIRE", label = "Sapphire", color = Color3.fromRGB( 65, 105, 225) },
	{ key = "OMEGA",    label = "Omega",    color = Color3.fromRGB(255, 128,   0) },
	{ key = "RUBY",     label = "Ruby",     color = Color3.fromRGB(220,  20,  60) },
}

-- ── Colours ───────────────────────────────────────────────────────────────────

local BG        = Color3.fromRGB( 18,  18,  25)
local PANEL_BG  = Color3.fromRGB( 26,  26,  36)
local TEXT_COL  = Color3.fromRGB(220, 220, 220)
local HEADER_BG = Color3.fromRGB( 38,  38,  55)
local CLOSE_COL = Color3.fromRGB(200,  50,  50)
local FONT      = Enum.Font.GothamBold

-- ── Build GUI ─────────────────────────────────────────────────────────────────

-- Destroy any stale copy from hot-reloads
if playerGui:FindFirstChild("CrateGiverGui") then
	playerGui.CrateGiverGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "CrateGiverGui"
screenGui.ResetOnSpawn   = false
screenGui.DisplayOrder   = 999
screenGui.IgnoreGuiInset = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent         = playerGui

-- ── Toggle button (always visible) ───────────────────────────────────────────

local toggleBtn = Instance.new("TextButton")
toggleBtn.Name               = "ToggleBtn"
toggleBtn.Size               = UDim2.fromOffset(36, 36)
toggleBtn.Position           = POSITION
toggleBtn.BackgroundColor3   = HEADER_BG
toggleBtn.Text               = "📦"
toggleBtn.TextSize           = 20
toggleBtn.Font               = FONT
toggleBtn.TextColor3         = TEXT_COL
toggleBtn.AutoButtonColor    = false
toggleBtn.ZIndex             = 10
toggleBtn.Parent             = screenGui
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 8)

local function addStroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color     = color or Color3.new(1,1,1)
	s.Thickness = thickness or 1.5
	s.Parent    = parent
end
addStroke(toggleBtn, HEADER_BG)

-- ── Main panel ────────────────────────────────────────────────────────────────

local PANEL_WIDTH  = 190
local PANEL_HEIGHT = 50 + (#CRATES * 46) + 12  -- header + buttons + padding

local panel = Instance.new("Frame")
panel.Name             = "Panel"
panel.Size             = UDim2.fromOffset(PANEL_WIDTH, PANEL_HEIGHT)
-- Anchored just to the right of the toggle button
panel.Position         = UDim2.new(
	POSITION.X.Scale, POSITION.X.Offset + 44,
	POSITION.Y.Scale, POSITION.Y.Offset
)
panel.BackgroundColor3 = PANEL_BG
panel.BorderSizePixel  = 0
panel.Visible          = START_VISIBLE
panel.ZIndex           = 9
panel.Parent           = screenGui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)
addStroke(panel, Color3.fromRGB(60, 60, 80), 1.5)

-- Drop shadow
local shadow = Instance.new("Frame")
shadow.Size               = UDim2.new(1, 6, 1, 6)
shadow.Position           = UDim2.fromOffset(3, 3)
shadow.BackgroundColor3   = Color3.new(0, 0, 0)
shadow.BackgroundTransparency = 0.6
shadow.BorderSizePixel    = 0
shadow.ZIndex             = 8
shadow.Parent             = panel
Instance.new("UICorner", shadow).CornerRadius = UDim.new(0, 12)

-- Header bar
local header = Instance.new("Frame")
header.Name             = "Header"
header.Size             = UDim2.new(1, 0, 0, 44)
header.BackgroundColor3 = HEADER_BG
header.BorderSizePixel  = 0
header.ZIndex           = 10
header.Parent           = panel
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 10)

-- Make bottom corners of header square (it sits on top of panel)
local headerFill = Instance.new("Frame")
headerFill.Size               = UDim2.new(1, 0, 0.5, 0)
headerFill.Position           = UDim2.fromScale(0, 0.5)
headerFill.BackgroundColor3   = HEADER_BG
headerFill.BorderSizePixel    = 0
headerFill.ZIndex             = 10
headerFill.Parent             = header

local headerLabel = Instance.new("TextLabel")
headerLabel.Size               = UDim2.new(1, -36, 1, 0)
headerLabel.Position           = UDim2.fromOffset(10, 0)
headerLabel.BackgroundTransparency = 1
headerLabel.Text               = "📦  Crate Giver"
headerLabel.Font               = FONT
headerLabel.TextSize           = 14
headerLabel.TextColor3         = TEXT_COL
headerLabel.TextXAlignment     = Enum.TextXAlignment.Left
headerLabel.ZIndex             = 11
headerLabel.Parent             = header

-- Close (X) button inside header
local closeBtn = Instance.new("TextButton")
closeBtn.Size             = UDim2.fromOffset(24, 24)
closeBtn.Position         = UDim2.new(1, -30, 0.5, -12)
closeBtn.BackgroundColor3 = CLOSE_COL
closeBtn.Text             = "✕"
closeBtn.TextSize         = 13
closeBtn.Font             = FONT
closeBtn.TextColor3       = Color3.new(1, 1, 1)
closeBtn.AutoButtonColor  = false
closeBtn.ZIndex           = 12
closeBtn.Parent           = header
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

-- Qty display / selector row
local qtyRow = Instance.new("Frame")
qtyRow.Name             = "QtyRow"
qtyRow.Size             = UDim2.new(1, -16, 0, 30)
qtyRow.Position         = UDim2.new(0, 8, 0, 48)
qtyRow.BackgroundTransparency = 1
qtyRow.ZIndex           = 10
qtyRow.Parent           = panel

local qtyLabel = Instance.new("TextLabel")
qtyLabel.Size               = UDim2.new(0, 60, 1, 0)
qtyLabel.BackgroundTransparency = 1
qtyLabel.Text               = "Qty:"
qtyLabel.Font               = FONT
qtyLabel.TextSize           = 13
qtyLabel.TextColor3         = Color3.fromRGB(160, 160, 180)
qtyLabel.TextXAlignment     = Enum.TextXAlignment.Left
qtyLabel.ZIndex             = 11
qtyLabel.Parent             = qtyRow

local function makeQtyBtn(sign, posX)
	local b = Instance.new("TextButton")
	b.Size             = UDim2.fromOffset(24, 24)
	b.Position         = UDim2.new(0, posX, 0.5, -12)
	b.BackgroundColor3 = HEADER_BG
	b.Text             = sign
	b.TextSize         = 16
	b.Font             = FONT
	b.TextColor3       = TEXT_COL
	b.AutoButtonColor  = false
	b.ZIndex           = 12
	b.Parent           = qtyRow
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
	return b
end

local qtyMinus = makeQtyBtn("−", 58)
local qtyValue = Instance.new("TextLabel")
qtyValue.Size               = UDim2.fromOffset(36, 24)
qtyValue.Position           = UDim2.new(0, 85, 0.5, -12)
qtyValue.BackgroundColor3   = BG
qtyValue.Text               = tostring(DEFAULT_QTY)
qtyValue.Font               = FONT
qtyValue.TextSize           = 14
qtyValue.TextColor3         = TEXT_COL
qtyValue.TextXAlignment     = Enum.TextXAlignment.Center
qtyValue.ZIndex             = 12
qtyValue.Parent             = qtyRow
Instance.new("UICorner", qtyValue).CornerRadius = UDim.new(0, 6)

local qtyPlus = makeQtyBtn("+", 124)

local currentQty = DEFAULT_QTY
local function setQty(n)
	currentQty = math.clamp(n, 1, 50)
	qtyValue.Text = tostring(currentQty)
end
qtyMinus.MouseButton1Click:Connect(function() setQty(currentQty - 1) end)
qtyPlus.MouseButton1Click:Connect(function()  setQty(currentQty + 1) end)

-- ── Crate buttons ─────────────────────────────────────────────────────────────

local feedbackLabel = Instance.new("TextLabel")  -- filled in after buttons

local function flashFeedback(text, success)
	feedbackLabel.Text       = text
	feedbackLabel.TextColor3 = success
		and Color3.fromRGB(80, 220, 100)
		or  Color3.fromRGB(220, 80, 80)
	feedbackLabel.BackgroundTransparency = 0.4
	TweenService:Create(feedbackLabel, TweenInfo.new(1.5, Enum.EasingStyle.Linear), {
		BackgroundTransparency = 1,
		TextTransparency = 1,
	}):Play()
	task.delay(1.6, function()
		feedbackLabel.TextTransparency = 0
		feedbackLabel.Text = ""
	end)
end

local BUTTON_START_Y = 82  -- px from top of panel

for i, crate in ipairs(CRATES) do
	local btn = Instance.new("TextButton")
	btn.Name             = crate.key .. "Btn"
	btn.Size             = UDim2.new(1, -16, 0, 38)
	btn.Position         = UDim2.new(0, 8, 0, BUTTON_START_Y + (i - 1) * 44)
	btn.BackgroundColor3 = crate.color
	btn.BackgroundTransparency = 0.25
	btn.Text             = crate.label .. " Crate"
	btn.Font             = FONT
	btn.TextSize         = 14
	btn.TextColor3       = Color3.new(1, 1, 1)
	btn.AutoButtonColor  = false
	btn.ZIndex           = 10
	btn.Parent           = panel
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	addStroke(btn, crate.color, 1.5)

	-- Hover effects
	local uiScale = Instance.new("UIScale")
	uiScale.Scale  = 1.0
	uiScale.Parent = btn

	btn.MouseEnter:Connect(function()
		btn.BackgroundTransparency = 0.10
		TweenService:Create(uiScale, TweenInfo.new(0.15, Enum.EasingStyle.Back), { Scale = 1.04 }):Play()
	end)
	btn.MouseLeave:Connect(function()
		btn.BackgroundTransparency = 0.25
		TweenService:Create(uiScale, TweenInfo.new(0.15, Enum.EasingStyle.Back), { Scale = 1.0 }):Play()
	end)

	btn.MouseButton1Click:Connect(function()
		CrateGiverRE:FireServer(crate.key, currentQty)
		flashFeedback(string.format("✓ Gave %d× %s", currentQty, crate.label), true)
		TweenService:Create(uiScale, TweenInfo.new(0.1, Enum.EasingStyle.Bounce), { Scale = 0.94 }):Play()
		task.delay(0.1, function()
			TweenService:Create(uiScale, TweenInfo.new(0.15, Enum.EasingStyle.Back), { Scale = 1.0 }):Play()
		end)
	end)
end

-- Feedback label (floats below the last button)
feedbackLabel.Size               = UDim2.new(1, -16, 0, 20)
feedbackLabel.Position           = UDim2.new(0, 8, 0, BUTTON_START_Y + #CRATES * 44 + 4)
feedbackLabel.BackgroundColor3   = Color3.fromRGB(0, 0, 0)
feedbackLabel.BackgroundTransparency = 1
feedbackLabel.Text               = ""
feedbackLabel.Font               = Enum.Font.Gotham
feedbackLabel.TextSize           = 12
feedbackLabel.TextColor3         = Color3.fromRGB(80, 220, 100)
feedbackLabel.TextXAlignment     = Enum.TextXAlignment.Center
feedbackLabel.ZIndex             = 11
feedbackLabel.Parent             = panel
Instance.new("UICorner", feedbackLabel).CornerRadius = UDim.new(0, 4)

-- ── Toggle logic ──────────────────────────────────────────────────────────────

local panelVisible = START_VISIBLE

local function setPanelVisible(v)
	panelVisible = v
	if v then
		panel.Visible = true
		TweenService:Create(panel, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(PANEL_WIDTH, PANEL_HEIGHT)
		}):Play()
		toggleBtn.Text = "✕"
	else
		TweenService:Create(panel, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = UDim2.fromOffset(PANEL_WIDTH, 0)
		}):Play()
		task.delay(0.15, function() panel.Visible = false end)
		toggleBtn.Text = "📦"
	end
end

toggleBtn.MouseButton1Click:Connect(function() setPanelVisible(not panelVisible) end)
closeBtn.MouseButton1Click:Connect(function()  setPanelVisible(false) end)

-- Apply initial state without animation
panel.Visible = START_VISIBLE
toggleBtn.Text = START_VISIBLE and "✕" or "📦"

-- ── Drag — click and drag the toggle button to reposition both elements ───────

local dragging = false
local dragStart, startPos

toggleBtn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging  = true
		dragStart = input.Position
		startPos  = toggleBtn.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		local newPos = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
		toggleBtn.Position = newPos
		panel.Position = UDim2.new(
			newPos.X.Scale, newPos.X.Offset + 44,
			newPos.Y.Scale, newPos.Y.Offset
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)

print("[CrateGiver] GUI loaded — ENABLED =", ENABLED, "| start visible =", START_VISIBLE)
