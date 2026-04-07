-- magmorGui.server.lua
-- Creates the BillboardGui above MagmorPlatform in the SpawnArena.
-- Matches the style of BullTeleporter's BullArenaGui.

local gameFolder = workspace:WaitForChild("Game", 30)
if not gameFolder then
	error("[magmorGui] Game folder not found in Workspace!")
end

local spawnArena = gameFolder:WaitForChild("SpawnArena", 30)
if not spawnArena then
	error("[magmorGui] SpawnArena folder not found in Game!")
end

local magmorPlatform = spawnArena:WaitForChild("MagmorPlatform", 30)
if not magmorPlatform then
	error("[magmorGui] MagmorPlatform not found in SpawnArena!")
end

-- Resolve to the BasePart if MagmorPlatform is a Model
local adornee = magmorPlatform
if not adornee:IsA("BasePart") then
	local part = adornee:FindFirstChildWhichIsA("BasePart")
	if part then adornee = part else
		error("[magmorGui] MagmorPlatform has no BasePart!")
	end
end

-- Remove stale GUI if it already exists (e.g. after server restart in Studio)
local existing = adornee:FindFirstChild("MagmorGui")
if existing then existing:Destroy() end

-- ── BillboardGui ─────────────────────────────────────────────────────────────
local bb = Instance.new("BillboardGui")
bb.Name          = "MagmorGui"
bb.Size          = UDim2.new(0, 220, 0, 90)
bb.StudsOffset   = Vector3.new(0, 8, 0)
bb.AlwaysOnTop   = true
bb.MaxDistance   = 60
bb.Adornee       = adornee
bb.Parent        = adornee

-- Background frame
local frame = Instance.new("Frame")
frame.Size                 = UDim2.new(1, 0, 1, 0)
frame.BackgroundColor3     = Color3.fromRGB(20, 5, 30)
frame.BackgroundTransparency = 0.2
frame.BorderSizePixel      = 0
frame.Parent               = bb
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

local stroke = Instance.new("UIStroke")
stroke.Color       = Color3.fromRGB(180, 0, 255)
stroke.Thickness   = 2
stroke.Transparency = 0.2
stroke.Parent      = frame

-- Title label
local titleLabel = Instance.new("TextLabel")
titleLabel.Name                  = "Title"
titleLabel.Size                  = UDim2.new(1, 0, 0.55, 0)
titleLabel.Position              = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text                  = "🔮 MAGMOR BOSS"
titleLabel.TextColor3            = Color3.fromRGB(200, 80, 255)
titleLabel.TextScaled            = true
titleLabel.Font                  = Enum.Font.GothamBold
titleLabel.TextStrokeTransparency = 0.4
titleLabel.TextStrokeColor3      = Color3.fromRGB(0, 0, 0)
titleLabel.Parent                = frame

-- Subtitle label
local subLabel = Instance.new("TextLabel")
subLabel.Name                  = "Sub"
subLabel.Size                  = UDim2.new(1, 0, 0.45, 0)
subLabel.Position              = UDim2.new(0, 0, 0.55, 0)
subLabel.BackgroundTransparency = 1
subLabel.Text                  = "Stand to Enter"
subLabel.TextColor3            = Color3.fromRGB(220, 180, 255)
subLabel.TextScaled            = true
subLabel.Font                  = Enum.Font.GothamBold
subLabel.TextStrokeTransparency = 0.6
subLabel.TextStrokeColor3      = Color3.fromRGB(0, 0, 0)
subLabel.Parent                = frame

print("[magmorGui] BillboardGui created on MagmorPlatform ✅")
