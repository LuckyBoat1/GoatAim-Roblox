local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

-- SETTINGS
local S = {
	-- Appearance
	Color        = Color3.fromRGB(0, 255, 127), -- #00ff7f
	Size         = {2, 2.5},
	Texture      = "rbxassetid://11862032588",
	Transparency = {0, 0.01},
	ZIndex       = 100,
	-- Emission
	EmitOffset   = 0,
	Lifetime     = 1,
	Rate         = {0.08, 0.3},
	Burst        = {1, 1},
	Speed        = 0.00001,
	Spread       = 0,
	-- Flipbook
	Columns      = 4,
	Rows         = 4,
	CellSize     = 256,
	AnimSpeed    = 0.08,
	-- Particles
	MaxCount     = 1,
}

local totalFrames = S.Columns * S.Rows
local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
local puffs = {}
local hoveredButton: Frame? = nil
local lastBurstButton: Frame? = nil -- track so we only burst once per hover

-- Overlay ScreenGui so particles render on top of buttons without affecting layout
local overlay = Instance.new("ScreenGui")
overlay.Name = "FlipBookSideMenuOverlay"
overlay.DisplayOrder = 200
overlay.IgnoreGuiInset = false
overlay.ResetOnSpawn = false
overlay.Parent = pg

local guiInset = GuiService:GetGuiInset() -- top bar offset
local function rand(a, b) return a + math.random() * (b - a) end

local function spawnAt(target: GuiObject)
	local pos, sz = target.AbsolutePosition, target.AbsoluteSize
	local scale = rand(S.Size[1], S.Size[2])
	local px = sz.X * scale
	-- Center on the button, offset by GuiInset since AbsolutePosition is screen-space
	local cx = pos.X + sz.X / 2
	local cy = pos.Y + sz.Y / 2 - guiInset.Y
	local f = math.random(0, totalFrames - 1)

	local img = Instance.new("ImageLabel")
	img.Image = S.Texture
	img.BackgroundTransparency = 1
	img.BorderSizePixel = 0
	img.ZIndex = S.ZIndex
	img.ScaleType = Enum.ScaleType.Crop
	img.ImageColor3 = S.Color
	img.ImageTransparency = S.Transparency[1]
	img.AnchorPoint = Vector2.new(0.5, 0.5)
	img.Size = UDim2.fromOffset(px, px)
	img.Position = UDim2.fromOffset(cx, cy)
	img.ImageRectOffset = Vector2.new((f % S.Columns) * S.CellSize, math.floor(f / S.Columns) * S.CellSize)
	img.ImageRectSize = Vector2.new(S.CellSize, S.CellSize)
	img.Rotation = 100
	img.Parent = overlay

	table.insert(puffs, {
		img = img, y = 0, cx = cx, cy = cy, px = px,
		f = f, ft = 0, age = 0, hd = (math.random() * 2 - 1) * S.Spread,
	})
end

-- Find the SideMenu ScreenGui and hook into each button
local function hookButtons()
	local sideMenuGui = pg:WaitForChild("SideMenu", 30)
	if not sideMenuGui then warn("FlipBookSideMenu: SideMenu GUI not found") return end

	local container = sideMenuGui:FindFirstChild("Container")
	if not container then warn("FlipBookSideMenu: Container not found") return end

	local innerPanel = container:FindFirstChild("InnerPanel")
	if not innerPanel then warn("FlipBookSideMenu: InnerPanel not found") return end

	local buttonContainer = innerPanel:FindFirstChild("ButtonContainer")
	if not buttonContainer then warn("FlipBookSideMenu: ButtonContainer not found") return end

	local function hookButton(wrapper: Frame)
		local btn = wrapper:FindFirstChild("Button")
		if not btn then return end

		btn.MouseEnter:Connect(function()
			hoveredButton = wrapper
		end)

		btn.MouseLeave:Connect(function()
			if hoveredButton == wrapper then
				hoveredButton = nil
			end
		end)
	end

	-- Hook existing buttons
	for _, child in buttonContainer:GetChildren() do
		if child:IsA("Frame") then
			hookButton(child)
		end
	end

	-- Hook any future buttons
	buttonContainer.ChildAdded:Connect(function(child)
		if child:IsA("Frame") then
			task.wait() -- let children populate
			hookButton(child)
		end
	end)
end

task.spawn(hookButtons)

-- Main render loop
local et, nd = 0, rand(S.Rate[1], S.Rate[2])

local conn = RunService.RenderStepped:Connect(function(dt)
	-- Spawn a single burst when hovering a new button
	if hoveredButton and hoveredButton.Parent then
		if hoveredButton ~= lastBurstButton then
			lastBurstButton = hoveredButton
			for _ = 1, math.random(S.Burst[1], S.Burst[2]) do
				spawnAt(hoveredButton)
			end
		end
	else
		lastBurstButton = nil
	end

	-- Update existing particles (float up + fade like stats GUI)
	local i = 1
	while i <= #puffs do
		local p = puffs[i]
		if not p.img or not p.img.Parent then table.remove(puffs, i) continue end

		p.y += S.Speed * dt
		p.age += dt
		local t = p.age / S.Lifetime
		p.img.ImageTransparency = S.Transparency[1] + t * (S.Transparency[2] - S.Transparency[1])
		p.img.Position = UDim2.fromOffset(p.cx + p.hd * (p.y / math.max(S.Speed, 0.001)), p.cy - p.y)

		p.ft += dt
		if p.ft >= S.AnimSpeed then
			p.ft -= S.AnimSpeed
			p.f = (p.f + 1) % totalFrames
			p.img.ImageRectOffset = Vector2.new((p.f % S.Columns) * S.CellSize, math.floor(p.f / S.Columns) * S.CellSize)
		end

		if t >= 1 then p.img:Destroy(); table.remove(puffs, i) else i += 1 end
	end
end)
