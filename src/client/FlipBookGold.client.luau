local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Texture pool: each entry has its own grid layout
local Textures = {
	{ Name = "circle",    Id = "rbxassetid://15011464541", Columns = 8, Rows = 8, CellSize = 128, SizeScale = 1.0, Speed = 0 },
	{ Name = "star",      Id = "rbxassetid://13448020277", Columns = 4, Rows = 4, CellSize = 256, SizeScale = 0.25, Speed = 30 },
	{ Name = "starbreak", Id = "rbxassetid://8733414465",  Columns = 4, Rows = 4, CellSize = 256, SizeScale = 0.25, Speed = 30 },
}

-- SETTINGS
local S = {
	-- Appearance
	ColorFrom    = {255, 170, 0},   -- #ffaa00
	ColorTo      = {255, 255, 0},   -- #ffff00
	Size         = {0.7, 1.1},
	Transparency = {0, 0},
	ZIndex       = 100,
	-- Emission
	EmitOffset   = -0.3,
	SpawnYOffset = 0,
	Lifetime     = 2,
	Rate         = {0.15, 0.6},
	Burst        = {1, 2},
	Speed        = 0.1,
	SpreadX      = 5,
	SpreadY      = 5,
	-- Flipbook
	AnimSpeed    = 0.06,
	-- Particles
	MaxCount     = 9,  -- 3 textures per burst, so 3 bursts worth
	-- Render
	RenderBehind = false,
	-- Target
	Gui          = "Stats",
	Frame        = "Gold",
}

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
local rng = Random.new()

local function rand(a, b) return rng:NextNumber(a, b) end
local function randInt(a, b) return rng:NextInteger(a, b) end

local function lerpChannel(from, to) return math.floor(from + math.random() * (to - from)) end

local function spawnOne(tex)
	local pos, sz = target.AbsolutePosition, target.AbsoluteSize
	local scale = rand(S.Size[1], S.Size[2]) * tex.SizeScale
	local px = sz.X * scale

	-- Random position within spawn zone (frame expanded by Spread)
	local zoneLeft  = pos.X - S.SpreadX
	local zoneRight = pos.X + sz.X + S.SpreadX - px
	local zoneTop   = pos.Y - S.SpreadY + S.SpawnYOffset
	local zoneBot   = pos.Y + sz.Y + S.SpreadY + S.SpawnYOffset - px
	local x = rand(zoneLeft, zoneRight)
	local y = rand(zoneTop, zoneBot)

	local totalFrames = tex.Columns * tex.Rows
	local f = randInt(0, totalFrames - 1)

	-- Lerp color from #ffaa00 to #ffff00
	local r = lerpChannel(S.ColorFrom[1], S.ColorTo[1])
	local g = lerpChannel(S.ColorFrom[2], S.ColorTo[2])
	local b = lerpChannel(S.ColorFrom[3], S.ColorTo[3])

	local img = Instance.new("ImageLabel")
	img.Image = tex.Id
	img.BackgroundTransparency = 1
	img.BorderSizePixel = 0
	img.ZIndex = S.RenderBehind and -1 or S.ZIndex
	img.ScaleType = Enum.ScaleType.Crop
	img.ImageColor3 = Color3.fromRGB(r, g, b)
	img.ImageTransparency = S.Transparency[1]
	img.Size = UDim2.fromOffset(px, px)
	img.Position = UDim2.fromOffset(x, y)
	img.ImageRectOffset = Vector2.new((f % tex.Columns) * tex.CellSize, math.floor(f / tex.Columns) * tex.CellSize)
	img.ImageRectSize = Vector2.new(tex.CellSize, tex.CellSize)
	img.Parent = target.Parent

	table.insert(puffs, {
		img = img, y = 0, x = x, spawnY = y, px = px,
		f = f, ft = 0, age = 0, tex = tex,
		totalFrames = totalFrames,
		speed = tex.Speed or 0,
	})
end

local function spawn()
	for _, tex in ipairs(Textures) do
		spawnOne(tex)
	end
end

local et, nd = 0, rand(S.Rate[1], S.Rate[2])
local starTimers = {}
for i, tex in ipairs(Textures) do
	if tex.Speed > 0 then
		starTimers[i] = { elapsed = 0, next = rand(S.Rate[1], S.Rate[2]) }
	end
end

local conn = RunService.RenderStepped:Connect(function(dt)
	if not target or not target.Parent then conn:Disconnect() return end
	local pos = target.AbsolutePosition

	-- Spawn stars individually (no burst)
	for i, timer in pairs(starTimers) do
		timer.elapsed += dt
		if timer.elapsed >= timer.next and #puffs < S.MaxCount then
			spawnOne(Textures[i])
			timer.elapsed = 0
			timer.next = rand(S.Rate[1], S.Rate[2])
		end
	end

	-- Spawn circles in bursts
	et += dt
	if et >= nd and #puffs < S.MaxCount then
		for _ = 1, math.min(math.random(S.Burst[1], S.Burst[2]), S.MaxCount - #puffs) do
			for _, tex in ipairs(Textures) do
				if tex.Speed == 0 then
					spawnOne(tex)
				end
			end
		end
		et, nd = 0, rand(S.Rate[1], S.Rate[2])
	end

	local i = 1
	while i <= #puffs do
		local p = puffs[i]
		if not p.img or not p.img.Parent then table.remove(puffs, i) continue end

		p.age += dt
		p.y += p.speed * dt
		local t = p.age / S.Lifetime
		p.img.ImageTransparency = S.Transparency[1] + t * (S.Transparency[2] - S.Transparency[1])
		p.img.Position = UDim2.fromOffset(p.x, p.spawnY - p.y)

		if p.y > p.px * 0.5 then
			p.img.ZIndex = S.ZIndex
		end

		p.ft += dt
		if p.ft >= S.AnimSpeed then
			p.ft -= S.AnimSpeed
			p.f = (p.f + 1) % p.totalFrames
			local tex = p.tex
			p.img.ImageRectOffset = Vector2.new((p.f % tex.Columns) * tex.CellSize, math.floor(p.f / tex.Columns) * tex.CellSize)
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
