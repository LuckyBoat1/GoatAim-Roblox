-- RefinerClient: displays rank requirement and production progress for nearby refiners.
-- Relies on server RefinerSystem + RemoteEvents.RefinerInfo

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Remotes = RS:WaitForChild("RemoteEvents")
local RefinerInfo = Remotes:WaitForChild("RefinerInfo")

-- Config: turn off world billboards above refiners
local SHOW_WORLD_BILLBOARDS = true

-- GUI container (only if showing billboards)
local gui
if SHOW_WORLD_BILLBOARDS then
	gui = Instance.new("ScreenGui")
	gui.Name = "RefinerUI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = player:WaitForChild("PlayerGui")
end

-- Track refiner data
local refiners = {} -- id -> data snapshot
local playerRank = 1

local function getBillboard(id)
	if not SHOW_WORLD_BILLBOARDS or not gui then return nil end
	return gui:FindFirstChild(id .. "_BB")
end

local function createBillboard(data)
	if not SHOW_WORLD_BILLBOARDS then return nil end
	local bb = Instance.new("BillboardGui")
	bb.Name = data.id .. "_BB"
	bb.Adornee = nil -- set later
	bb.Size = UDim2.fromOffset(160, 50)
	bb.ExtentsOffsetWorldSpace = Vector3.new(0, 4, 0)
	bb.AlwaysOnTop = true
	bb.Parent = gui
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1,1)
	frame.BackgroundTransparency = 0.3
	frame.BackgroundColor3 = Color3.fromRGB(10,15,12)
	frame.BorderSizePixel = 0
	frame.Parent = bb
	local corner = Instance.new("UICorner", frame); corner.CornerRadius = UDim.new(0,8)
	local stroke = Instance.new("UIStroke", frame); stroke.Thickness=2; stroke.Color=Color3.fromRGB(50,255,150); stroke.Transparency=0.3
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1,-10,0,18)
	title.Position = UDim2.new(0,5,0,4)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.Code
	title.Text = string.format("%s (%s)", data.id, data.tier)
	title.TextColor3 = Color3.fromRGB(50,255,150)
	title.TextSize = 14
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = frame
	local barBg = Instance.new("Frame")
	barBg.Size = UDim2.new(1,-10,0,10)
	barBg.Position = UDim2.new(0,5,0,28)
	barBg.BackgroundColor3 = Color3.fromRGB(25,35,30)
	barBg.BackgroundTransparency = 0.2
	barBg.BorderSizePixel = 0
	barBg.Parent = frame
	Instance.new("UICorner", barBg).CornerRadius = UDim.new(0,4)
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(0,0,1,0)
	fill.BackgroundColor3 = Color3.fromRGB(50,255,150)
	fill.BorderSizePixel = 0
	fill.Parent = barBg
	Instance.new("UICorner", fill).CornerRadius = UDim.new(0,4)

	-- Soft gradient inside the fill
	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new(Color3.fromRGB(50,255,150), Color3.fromRGB(0,170,255))
	grad.Rotation = 0
	grad.Parent = fill

	-- Subtle scan line animation across the bar
	local scan = Instance.new("Frame")
	scan.Name = "Scan"
	scan.Size = UDim2.new(0, 8, 1, 0)
	scan.Position = UDim2.new(0, -10, 0, 0)
	scan.BackgroundTransparency = 0.4
	scan.BackgroundColor3 = Color3.fromRGB(255,255,255)
	scan.BorderSizePixel = 0
	scan.Parent = barBg
	task.spawn(function()
		while scan.Parent do
			scan.Position = UDim2.new(0, -10, 0, 0)
			TweenService:Create(scan, TweenInfo.new(1.6, Enum.EasingStyle.Linear), {Position = UDim2.new(1, 10, 0, 0)}):Play()
			task.wait(1.7)
		end
	end)
	local lockIcon = Instance.new("TextLabel")
	lockIcon.Name = "Lock"
	lockIcon.Size = UDim2.new(0,18,0,18)
	lockIcon.Position = UDim2.new(1,-20,0,-4)
	lockIcon.BackgroundTransparency = 1
	lockIcon.Font = Enum.Font.Code
	lockIcon.Text = "🔒"
	lockIcon.TextSize = 16
	lockIcon.TextColor3 = Color3.fromRGB(180,180,180)
	lockIcon.Visible = false
	lockIcon.Parent = frame

	-- Percent label (top-right)
	local pct = Instance.new("TextLabel")
	pct.Name = "Pct"
	pct.Size = UDim2.new(0,36,0,16)
	pct.Position = UDim2.new(1,-40,0,4)
	pct.BackgroundTransparency = 1
	pct.Font = Enum.Font.GothamBold
	pct.Text = ""
	pct.TextColor3 = Color3.fromRGB(140,255,220)
	pct.TextSize = 12
	pct.TextXAlignment = Enum.TextXAlignment.Right
	pct.Parent = frame

	-- Time label (below bar)
	local timeLbl = Instance.new("TextLabel")
	timeLbl.Name = "Time"
	timeLbl.Size = UDim2.new(1,-10,0,14)
	timeLbl.Position = UDim2.new(0,5,1,-16)
	timeLbl.BackgroundTransparency = 1
	timeLbl.Font = Enum.Font.Gotham
	timeLbl.Text = ""
	timeLbl.TextColor3 = Color3.fromRGB(210,220,230)
	timeLbl.TextSize = 12
	timeLbl.TextXAlignment = Enum.TextXAlignment.Left
	timeLbl.Parent = frame
	local lbl = Instance.new("TextLabel")
	lbl.Name = "Lbl"
	lbl.Size = UDim2.new(1,0,1,0)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.Code
	lbl.Text = ""
	lbl.TextSize = 10
	lbl.TextColor3 = Color3.fromRGB(50,255,150)
	lbl.Parent = barBg
	return bb
end

local function updateBillboard(data)
	if not SHOW_WORLD_BILLBOARDS then return end
	local bb = getBillboard(data.id) or createBillboard(data)
	-- Find world instance by name fallback to attribute id
	local refinersFolder = workspace:FindFirstChild("Refiners")
	if refinersFolder then
		local inst = refinersFolder:FindFirstChild(data.id) or nil
		if not inst then
			for _, ch in ipairs(refinersFolder:GetChildren()) do
				if (ch:GetAttribute("RefinerId") or ch.Name) == data.id then
					inst = ch
					break
				end
			end
		end
		bb.Adornee = inst and (inst:IsA("BasePart") and inst or inst.PrimaryPart) or nil
	end
	local barBg = bb.Frame:FindFirstChildWhichIsA("Frame")
	local fill = barBg and barBg:FindFirstChild("Fill")
	local lbl = barBg and barBg:FindFirstChild("Lbl")
	local pct = bb.Frame:FindFirstChild("Pct")
	local timeLbl = bb.Frame:FindFirstChild("Time")
	local lockIcon = bb.Frame:FindFirstChild("Lock") or (bb.Frame:FindFirstChildWhichIsA("TextLabel") and bb.Frame.Lock)
	if not (fill and lbl) then return end
	local unlocked = data.manualUnlocked or false
	if not data.active then
		if pct then pct.Text = "" end
		if timeLbl then timeLbl.Text = "" end
		if not unlocked then
			if (data.req or 1) > playerRank then
				lbl.Text = string.format("Locked R%d", data.req)
			else
				lbl.Text = string.format("Buy ($%s)", data.price or 0)
			end
			TweenService:Create(fill, TweenInfo.new(0.25), {Size = UDim2.new(0,0,1,0), BackgroundColor3 = Color3.fromRGB(90,90,90)}):Play()
			barBg.BackgroundColor3 = Color3.fromRGB(35,35,35)
			fill.BackgroundTransparency = 0.5
			if lockIcon then lockIcon.Visible = true end
		elseif data.owned then
			if data.upgradeLevel and data.upgradeLevel >= 5 then
				lbl.Text = "Max Level"
			else
				lbl.Text = string.format("Upgrade ($%s)", data.price or 0)
			end
			TweenService:Create(fill, TweenInfo.new(0.25), {Size = UDim2.new(1,0,1,0), BackgroundColor3 = Color3.fromRGB(50,255,150)}):Play()
			barBg.BackgroundColor3 = Color3.fromRGB(25,35,30)
			fill.BackgroundTransparency = 0.2
			if lockIcon then lockIcon.Visible = false end
		else
			lbl.Text = string.format("Activate (%ds)", data.interval or 0)
			TweenService:Create(fill, TweenInfo.new(0.25), {Size = UDim2.new(0,0,1,0), BackgroundColor3 = Color3.fromRGB(50,255,150)}):Play()
			barBg.BackgroundColor3 = Color3.fromRGB(25,35,30)
			fill.BackgroundTransparency = 0.2
			if lockIcon then lockIcon.Visible = false end
		end
	else
		local frac = 0
		if data.interval > 0 then
			frac = math.clamp(data.timeAccum / data.interval, 0, 1)
		end
		TweenService:Create(fill, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(frac,0,1,0), BackgroundColor3 = Color3.fromRGB(50,255,150), BackgroundTransparency = 0}):Play()
		lbl.Text = string.format("%ds / %ds", math.floor(data.timeAccum), math.floor(data.interval))
		if pct then pct.Text = string.format("%d%%", math.floor(frac * 100 + 0.5)) end
		if timeLbl then
			local remain = math.max(0, math.floor((data.interval or 0) - (data.timeAccum or 0)))
			local h = math.floor(remain / 3600)
			local m = math.floor((remain % 3600) / 60)
			local s = remain % 60
			if h > 0 then
				timeLbl.Text = string.format("%dh %02dm %02ds left", h, m, s)
			else
				timeLbl.Text = string.format("%02dm %02ds left", m, s)
			end
		end
		barBg.BackgroundColor3 = Color3.fromRGB(25,35,30)
		if lockIcon then lockIcon.Visible = false end
	end
end

RefinerInfo.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then return end
	if payload.type == "snapshot" then
		for _, d in ipairs(payload.refiners or {}) do
			refiners[d.id] = d
			updateBillboard(d)
		end
		-- Accept optional rank field if server adds later (future proof)
		if payload.rank then playerRank = payload.rank end
	elseif payload.type == "produced" then
		-- Reset progress bar for produced refiner (server will also update in next snapshot)
		local d = refiners[payload.id]
		if d then d.timeAccum = 0 end
	end
end)

-- Smoothly advance local timers between snapshots for active refiners
RunService.Heartbeat:Connect(function(dt)
	for _, d in pairs(refiners) do
		if d.active then
			local old = d.timeAccum
			d.timeAccum = math.min(d.interval, d.timeAccum + dt)
			if math.floor(old) ~= math.floor(d.timeAccum) then
				updateBillboard(d)
			end
		end
	end
end)
