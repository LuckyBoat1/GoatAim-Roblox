local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- SETTINGS
local S = {
	-- Appearance
	Color        = {0, 160, 0, 50, 255, 50},
	SizeW        = 0.5,  -- width as fraction of frame width
	SizeH        = 0.6,  -- height as fraction of frame height
	Texture      = "rbxassetid://16503468487",
	Transparency = 0.0,
	ZIndex       = 100,
	-- Rotation
	RotSpeed     = 1000,  -- degrees/sec (constant)
	-- Positions (fraction of frame: X, Y)
	Positions    = {
		{0.1, 0.6},    -- left edge, center
		{0.5, 0.6},  -- center, center
		{0.9, 0.6},    -- right edge, center
	},
	-- Flipbook
	Columns      = 8,
	Rows         = 8,
	CellSize     = 128,
	AnimSpeed    = 0.08,
	-- Render
	RenderBehind = true,  -- true = behind the frame, false = on top
	-- Target
	Gui          = "Stats",
	Frame        = "Coins",
}

local totalFrames = S.Columns * S.Rows
local pg = Players.LocalPlayer:WaitForChild("PlayerGui")

-- Resilient target finder: handles FloatingGui moving frames from ScreenGui to SurfaceGui
local target
while not target do
	for _, gui in ipairs(pg:GetChildren()) do
		if gui.Name == S.Gui then
			local f = gui:FindFirstChild(S.Frame)
			if f then target = f break end
		end
	end
	if not target then task.wait(0.1) end
end
target.ClipsDescendants = false

-- 3 fixed positions from settings
local icons = {}

for _, posData in ipairs(S.Positions) do
	local img = Instance.new("ImageLabel")
	img.Image = S.Texture
	img.BackgroundTransparency = 1
	img.BorderSizePixel = 0
	img.ZIndex = S.RenderBehind and -1 or S.ZIndex
	img.ScaleType = Enum.ScaleType.Crop
	img.ImageColor3 = Color3.fromRGB(
		math.random(S.Color[1], S.Color[4]),
		math.random(S.Color[2], S.Color[5]),
		math.random(S.Color[3], S.Color[6])
	)
	img.ImageTransparency = S.Transparency
	img.AnchorPoint = Vector2.new(0.5, 0.5)
	-- Static frame (no animation — same image the whole time)
	img.ImageRectOffset = Vector2.zero
	img.ImageRectSize = Vector2.new(S.CellSize, S.CellSize)
	img.Parent = target.Parent

	table.insert(icons, {
		img = img, xFrac = posData[1], yFrac = posData[2], rot = 0,
	})
end

local conn = RunService.RenderStepped:Connect(function(dt)
	if not target or not target.Parent then conn:Disconnect() return end
	local pos = target.AbsolutePosition
	local sz = target.AbsoluteSize
	local pw = sz.X * S.SizeW
	local ph = sz.Y * S.SizeH

	for _, ic in ipairs(icons) do
		if not ic.img or not ic.img.Parent then continue end

		ic.img.Size = UDim2.fromOffset(pw, ph)
		ic.img.Position = UDim2.fromOffset(
			pos.X + ic.xFrac * sz.X,
			pos.Y + ic.yFrac * sz.Y
		)

		-- Constant rotation
		ic.rot += S.RotSpeed * dt
		ic.img.Rotation = ic.rot
	end
end)

target.AncestryChanged:Connect(function(_, p)
	if not p then
		conn:Disconnect()
		for _, ic in ipairs(icons) do if ic.img then ic.img:Destroy() end end
	end
end)
