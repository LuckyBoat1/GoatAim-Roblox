local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- SETTINGS
local S = {
	-- Appearance
	Color        = {{255, 0, 0}, {0, 0, 255}},
	Size         = {0.35, 0.55},
	Texture      = "rbxassetid://15011447462",
	Transparency = {0.2, 1.0},
	ZIndex       = 100,
	-- Emission
	EmitOffset   = 0,
	Lifetime     = 45,
	Rate         = {0.08, 0.25},
	Burst        = {3, 6},
	Speed        = 10,
	Spread       = 5,
	-- Flipbook
	Columns      = 4,
	Rows         = 4,
	CellSize     = 256,
	AnimSpeed    = 0.08,
	-- Particles
	MaxCount     = 24,
	-- Burst duration (seconds of emitting after trigger)
	BurstDuration = 0.8,
}

local totalFrames = S.Columns * S.Rows
local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
local puffs = {}
local activeTarget = nil   -- the frame particles burst from (set per trigger)
local burstEnd = 0         -- tick() when we stop emitting new particles
local running = false       -- is the RenderStepped loop active?
local conn = nil

local function rand(a, b) return a + math.random() * (b - a) end

local function spawnParticle()
	if not activeTarget or not activeTarget.Parent then return end
	local pos, sz = activeTarget.AbsolutePosition, activeTarget.AbsoluteSize
	local scale = rand(S.Size[1], S.Size[2])
	local px = sz.X * scale
	local x = pos.X + math.random() * (sz.X - px)
	local f = math.random(0, totalFrames - 1)

	local img = Instance.new("ImageLabel")
	img.Image = S.Texture
	img.BackgroundTransparency = 1
	img.BorderSizePixel = 0
	img.ZIndex = S.ZIndex
	img.ScaleType = Enum.ScaleType.Crop
	img.ImageColor3 = Color3.new(1, 1, 1)

	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
		ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 0, 0)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),
		ColorSequenceKeypoint.new(0.75, Color3.fromRGB(0, 200, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 255))
	})
	grad.Parent = img
	img.ImageTransparency = S.Transparency[1]
	img.Size = UDim2.fromOffset(px, px)
	img.Position = UDim2.fromOffset(x, pos.Y + px * S.EmitOffset)
	img.ImageRectOffset = Vector2.new((f % S.Columns) * S.CellSize, math.floor(f / S.Columns) * S.CellSize)
	img.ImageRectSize = Vector2.new(S.CellSize, S.CellSize)
	img.Parent = activeTarget.Parent

	table.insert(puffs, {
		img = img, y = 0, x = x, px = px,
		f = f, ft = 0, hd = (math.random() * 2 - 1) * S.Spread
	})
end

local et, nd = 0, 0

local function onRenderStepped(dt)
	if not activeTarget or not activeTarget.Parent then
		-- Clean up everything if target is gone
		for _, v in puffs do if v.img then v.img:Destroy() end end
		table.clear(puffs)
		if conn then conn:Disconnect(); conn = nil end
		running = false
		return
	end

	local now = tick()
	local pos = activeTarget.AbsolutePosition

	-- Emit new particles while within burst window
	if now < burstEnd and #puffs < S.MaxCount then
		et += dt
		if et >= nd then
			for _ = 1, math.min(math.random(S.Burst[1], S.Burst[2]), S.MaxCount - #puffs) do
				spawnParticle()
			end
			et, nd = 0, rand(S.Rate[1], S.Rate[2])
		end
	end

	-- Animate existing particles
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

	-- If burst window ended and all particles gone, stop the loop
	if now >= burstEnd and #puffs == 0 then
		if conn then conn:Disconnect(); conn = nil end
		running = false
	end
end

-- GLOBAL TRIGGER: call _G.PlayUpgradeFlipBook(frame) from Headquarters
_G.PlayUpgradeFlipBook = function(targetFrame)
	if not targetFrame then return end
	activeTarget = targetFrame
	burstEnd = tick() + S.BurstDuration
	et, nd = 0, 0 -- emit immediately

	if not running then
		running = true
		conn = RunService.RenderStepped:Connect(onRenderStepped)
	end
end

print("[FlipBookUpgrades] Loaded — call _G.PlayUpgradeFlipBook(frame) to trigger")
