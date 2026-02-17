local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- SETTINGS
local S = {
	-- Appearance
	Color        = {120, 120, 130, 160, 160, 170},
	Size         = {0.35, 0.55},
	Texture      = "rbxassetid://8733226116",
	Transparency = {0.2, 1.0},
	ZIndex       = 100,
	-- Emission
	EmitOffset   = -0.3,
	Lifetime     = 90,
	Rate         = {0.15, 0.6},
	Burst        = {1, 3},
	Speed        = 25,
	Spread       = 5,
	-- Flipbook
	Columns      = 4,
	Rows         = 4,
	CellSize     = 256,
	AnimSpeed    = 0.08,
	-- Particles
	MaxCount     = 6,
	-- Render
	RenderBehind = false,  -- true = behind the frame, false = on top
	-- Target
	Gui          = "Stats",
	Frame        = "Deaths",
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
local puffs = {}

local function rand(a, b) return a + math.random() * (b - a) end

local function spawn()
	local pos, sz = target.AbsolutePosition, target.AbsoluteSize
	local scale = rand(S.Size[1], S.Size[2])
	local px = sz.X * scale
	local x = pos.X + math.random() * (sz.X - px)
	local f = math.random(0, totalFrames - 1)

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
	img.ImageTransparency = S.Transparency[1]
	img.Size = UDim2.fromOffset(px, px)
	img.Position = UDim2.fromOffset(x, pos.Y + px * S.EmitOffset)
	img.ImageRectOffset = Vector2.new((f % S.Columns) * S.CellSize, math.floor(f / S.Columns) * S.CellSize)
	img.ImageRectSize = Vector2.new(S.CellSize, S.CellSize)
	img.Parent = target.Parent

	table.insert(puffs, {
		img = img, y = 0, x = x, px = px,
		f = f, ft = 0, hd = (math.random() * 2 - 1) * S.Spread
	})
end

local et, nd = 0, rand(S.Rate[1], S.Rate[2])

local conn = RunService.RenderStepped:Connect(function(dt)
	if not target or not target.Parent then conn:Disconnect() return end
	local pos = target.AbsolutePosition

	et += dt
	if et >= nd and #puffs < S.MaxCount then
		for _ = 1, math.min(math.random(S.Burst[1], S.Burst[2]), S.MaxCount - #puffs) do spawn() end
		et, nd = 0, rand(S.Rate[1], S.Rate[2])
	end

	local i = 1
	while i <= #puffs do
		local p = puffs[i]
		if not p.img or not p.img.Parent then table.remove(puffs, i) continue end

		p.y += S.Speed * dt
		local t = p.y / S.Lifetime
		p.img.ImageTransparency = S.Transparency[1] + t * (S.Transparency[2] - S.Transparency[1])
		p.img.Position = UDim2.fromOffset(p.x + p.hd * (p.y / S.Speed), pos.Y + p.px * S.EmitOffset - p.y)

		if p.y > p.px * 0.5 then
			p.img.ZIndex = S.ZIndex
		end

		p.ft += dt
		if p.ft >= S.AnimSpeed then
			p.ft -= S.AnimSpeed
			p.f = (p.f + 1) % totalFrames
			p.img.ImageRectOffset = Vector2.new((p.f % S.Columns) * S.CellSize, math.floor(p.f / S.Columns) * S.CellSize)
		end

		if t >= 1 then p.img:Destroy(); table.remove(puffs, i) else i += 1 end
	end
end)

target.AncestryChanged:Connect(function(_, p)
	if not p then
		conn:Disconnect()
		for _, v in puffs do if v.img then v.img:Destroy() end end
		table.clear(puffs)
	end
end)
