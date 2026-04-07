-- QButtonBillboard.client.luau
-- Stylish billboard on the QButton attachment for the crosshair toggle prompt
-- PC-only: Q key doesn't exist on mobile, so skip the billboard entirely.

local UserInputService = game:GetService("UserInputService")
if UserInputService.TouchEnabled then return end

local TweenService  = game:GetService("TweenService")

-- ── Find the attachment ────────────────────────────────────────────────────
local function findQButton()
	for _, obj in workspace:GetDescendants() do
		if obj:IsA("Attachment") and obj.Name == "QButton" then
			return obj
		end
	end
end

task.wait(1)
local attachment = findQButton()

if not attachment then
	warn("[QButtonBillboard] Could not find 'QButton' attachment in workspace")
	return
end

-- ── BillboardGui ───────────────────────────────────────────────────────────
local billboard = Instance.new("BillboardGui")
billboard.Name           = "QButtonBillboard"
billboard.Adornee        = attachment
billboard.AlwaysOnTop    = false
billboard.Size           = UDim2.fromOffset(270, 84)
billboard.StudsOffset    = Vector3.new(0, 3.5, 0)
billboard.MaxDistance    = 30
billboard.ResetOnSpawn   = false
billboard.LightInfluence = 0
billboard.Parent         = attachment

-- ── Outer glow halo (behind card) ─────────────────────────────────────────
local glow = Instance.new("Frame")
glow.Size                  = UDim2.new(1, 10, 1, 10)
glow.Position              = UDim2.new(0, -5, 0, -5)
glow.BackgroundColor3      = Color3.fromRGB(70, 120, 255)
glow.BackgroundTransparency = 0.72
glow.BorderSizePixel       = 0
glow.ZIndex                = 0
glow.Parent                = billboard
Instance.new("UICorner", glow).CornerRadius = UDim.new(0, 18)

-- ── Card ──────────────────────────────────────────────────────────────────
local card = Instance.new("Frame")
card.Size                  = UDim2.fromScale(1, 1)
card.BackgroundColor3      = Color3.fromRGB(6, 8, 20)
card.BackgroundTransparency = 0
card.BorderSizePixel       = 0
card.ZIndex                = 1
card.Parent                = billboard
Instance.new("UICorner", card).CornerRadius = UDim.new(0, 14)

-- Dark-to-dark-blue gradient
local grad = Instance.new("UIGradient")
grad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(8, 10, 28)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 22, 55)),
})
grad.Rotation = 120
grad.Parent = card

-- Border
local border = Instance.new("UIStroke")
border.Color        = Color3.fromRGB(100, 155, 255)
border.Transparency = 0.2
border.Thickness    = 1.8
border.Parent       = card

-- Padding
local pad = Instance.new("UIPadding")
pad.PaddingLeft   = UDim.new(0, 14)
pad.PaddingRight  = UDim.new(0, 12)
pad.PaddingTop    = UDim.new(0, 10)
pad.PaddingBottom = UDim.new(0, 10)
pad.Parent        = card

-- Horizontal layout
local layout = Instance.new("UIListLayout")
layout.FillDirection       = Enum.FillDirection.Horizontal
layout.VerticalAlignment   = Enum.VerticalAlignment.Center
layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
layout.Padding             = UDim.new(0, 12)
layout.Parent              = card

-- ── [Q] Key Badge ─────────────────────────────────────────────────────────
local badge = Instance.new("Frame")
badge.Size                  = UDim2.fromOffset(46, 46)
badge.BackgroundColor3      = Color3.fromRGB(65, 115, 255)
badge.BackgroundTransparency = 0
badge.BorderSizePixel       = 0
badge.LayoutOrder           = 1
badge.ZIndex                = 2
badge.Parent                = card
Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 10)

local badgeGrad = Instance.new("UIGradient")
badgeGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 175, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 95, 230)),
})
badgeGrad.Rotation = 140
badgeGrad.Parent = badge

local badgeBorder = Instance.new("UIStroke")
badgeBorder.Color        = Color3.fromRGB(190, 220, 255)
badgeBorder.Transparency = 0.4
badgeBorder.Thickness    = 1.5
badgeBorder.Parent       = badge

local keyLabel = Instance.new("TextLabel")
keyLabel.Size                  = UDim2.fromScale(1, 1)
keyLabel.BackgroundTransparency = 1
keyLabel.Text                  = "Q"
keyLabel.TextColor3            = Color3.fromRGB(255, 255, 255)
keyLabel.Font                  = Enum.Font.GothamBold
keyLabel.TextSize              = 24
keyLabel.TextXAlignment        = Enum.TextXAlignment.Center
keyLabel.TextYAlignment        = Enum.TextYAlignment.Center
keyLabel.TextStrokeTransparency = 0.55
keyLabel.TextStrokeColor3      = Color3.fromRGB(0, 20, 110)
keyLabel.ZIndex                = 3
keyLabel.Parent                = badge

-- ── Text column ───────────────────────────────────────────────────────────
local textFrame = Instance.new("Frame")
textFrame.Size                  = UDim2.new(1, -72, 1, 0)
textFrame.BackgroundTransparency = 1
textFrame.BorderSizePixel       = 0
textFrame.LayoutOrder           = 2
textFrame.ZIndex                = 2
textFrame.Parent                = card

local textLayout = Instance.new("UIListLayout")
textLayout.FillDirection      = Enum.FillDirection.Vertical
textLayout.VerticalAlignment  = Enum.VerticalAlignment.Center
textLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
textLayout.Padding            = UDim.new(0, 2)
textLayout.Parent             = textFrame

local topLine = Instance.new("TextLabel")
topLine.Size                  = UDim2.new(1, 0, 0, 22)
topLine.BackgroundTransparency = 1
topLine.Text                  = "Press Q to toggle"
topLine.TextColor3            = Color3.fromRGB(230, 240, 255)
topLine.Font                  = Enum.Font.GothamBold
topLine.TextSize              = 15
topLine.TextXAlignment        = Enum.TextXAlignment.Left
topLine.TextYAlignment        = Enum.TextYAlignment.Bottom
topLine.TextStrokeTransparency = 0.7
topLine.TextStrokeColor3      = Color3.fromRGB(0, 0, 0)
topLine.ZIndex                = 3
topLine.Parent                = textFrame

local subLine = Instance.new("TextLabel")
subLine.Size                  = UDim2.new(1, 0, 0, 18)
subLine.BackgroundTransparency = 1
subLine.Text                  = "🎯  Crosshair"
subLine.TextColor3            = Color3.fromRGB(115, 160, 255)
subLine.Font                  = Enum.Font.Gotham
subLine.TextSize              = 13
subLine.TextXAlignment        = Enum.TextXAlignment.Left
subLine.TextYAlignment        = Enum.TextYAlignment.Top
subLine.ZIndex                = 3
subLine.Parent                = textFrame

-- ── Pulse animation ───────────────────────────────────────────────────────
local function pulse()
	local gIn  = TweenService:Create(glow,  TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { BackgroundTransparency = 0.5 })
	local gOut = TweenService:Create(glow,  TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { BackgroundTransparency = 0.82 })
	local bIn  = TweenService:Create(badge, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { BackgroundColor3 = Color3.fromRGB(105, 160, 255) })
	local bOut = TweenService:Create(badge, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { BackgroundColor3 = Color3.fromRGB(50, 95, 230) })
	while billboard.Parent do
		gIn:Play(); bIn:Play()
		task.wait(1.4)
		gOut:Play(); bOut:Play()
		task.wait(1.4)
	end
end

task.spawn(pulse)

