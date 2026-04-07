-- Emporium.client.luau
-- Tabs: Coins | Crates | Weapons
-- Icon click toggles the shop. All coin/crate/weapon setup runs async.
-- -------------------------------------------------------------------------

local Players              = game:GetService("Players")
local ReplicatedStorage    = game:GetService("ReplicatedStorage")
local RunService           = game:GetService("RunService")
local MarketplaceService   = game:GetService("MarketplaceService")

local Shared      = ReplicatedStorage:WaitForChild("Shared", 10)
local CrateConfig = nil
local SkinConfig  = nil
pcall(function() CrateConfig = require(Shared:WaitForChild("CrateConfig",  5)) end)
pcall(function() SkinConfig  = require(Shared:WaitForChild("SkinConfig",   5)) end)

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ── PRICES ────────────────────────────────────────────────────────────────
local COIN_PACKAGES = {
Stack = { coins = 100,  robux = 50  },
Car   = { coins = 500,  robux = 150 },
Yacht = { coins = 2500, robux = 500 },
}
local CRATE_PACKAGES = {
Silver   = { label = "Silver Crate",   configKey = "SILVER",   coinCost = 50   },
Sapphire = { label = "Sapphire Crate", configKey = "SAPPHIRE", coinCost = 250  },
Omega    = { label = "Omega Crate",    configKey = "OMEGA",    coinCost = 1000 },
}
-- Edit weaponName each day; nil = random weapon of that rarity
local WEAPON_SLOTS = {
["1"] = { rarity = "epic",      coinCost = 200, weaponName = nil },
["2"] = { rarity = "epic",      coinCost = 200, weaponName = nil },
["3"] = { rarity = "legendary", coinCost = 750, weaponName = nil },
}

-- ── WAIT FOR GUI ──────────────────────────────────────────────────────────
local emporiumGui = playerGui:WaitForChild("Emporium", 15)
if not emporiumGui then warn("[Emporium] ScreenGui not found"); return end
emporiumGui.Enabled = true

-- Add a responsive UIScale so the Emporium scales with screen size
do
	local Camera = game:GetService("Workspace").CurrentCamera
	local emporiumScale = emporiumGui:FindFirstChildOfClass("UIScale")
	if not emporiumScale then
		emporiumScale = Instance.new("UIScale")
		emporiumScale.Parent = emporiumGui
	end
	local function updateEmporiumScale()
		local vp = Camera.ViewportSize
		emporiumScale.Scale = math.min(vp.X / 1920, vp.Y / 1080)
	end
	updateEmporiumScale()
	Camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateEmporiumScale)
end

-- Print hierarchy for debugging
print("[Emporium] Hierarchy:")
for _, d in ipairs(emporiumGui:GetDescendants()) do
print(string.rep("  ", select(2, d:GetFullName():gsub("%.", "")) - 1)
.. d.ClassName .. ' "' .. d.Name .. '"')
end

local coinsFrame   = emporiumGui:FindFirstChild("Coins")
local cratesFrame  = emporiumGui:FindFirstChild("Crates")
local weaponsFrame = emporiumGui:FindFirstChild("Weapons")
local iconFrame    = emporiumGui:FindFirstChild("Icon")
local iconBasePos  = iconFrame and iconFrame.Position  -- rest position for bob animation

if not coinsFrame  then warn("[Emporium] 'Coins' frame not found");  return end
if not cratesFrame then warn("[Emporium] 'Crates' frame not found"); return end
if not weaponsFrame then warn("[Emporium] 'Weapons' frame not found") end

-- ── CONSTANTS ─────────────────────────────────────────────────────────────
local PRICE_FONT  = Enum.Font.FredokaOne
local PRICE_SIZE  = 28
local COIN_COLOR  = Color3.fromRGB(80, 255, 120)
local EPIC_COLOR  = Color3.fromRGB(163, 53, 238)
local LEG_COLOR   = Color3.fromRGB(255, 160, 0)

-- ── HELPERS ───────────────────────────────────────────────────────────────
local function ensureCorner(p, r)
local c = p:FindFirstChildOfClass("UICorner")
if not c then c = Instance.new("UICorner"); c.Parent = p end
c.CornerRadius = UDim.new(0, r or 10); return c
end

local function ensureStroke(p, col, thick, trans)
local s = p:FindFirstChildOfClass("UIStroke")
if not s then s = Instance.new("UIStroke"); s.Parent = p end
s.Color = col or Color3.new(1,1,1); s.Thickness = thick or 2
s.Transparency = trans or 0; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
return s
end

local function addOverlay(frame, cb, z)
if not frame then return end
local o = frame:FindFirstChild("_Ov"); if o then o:Destroy() end
local b = Instance.new("TextButton")
b.Name = "_Ov"; b.Size = UDim2.fromScale(1,1)
b.BackgroundTransparency = 1; b.Text = ""; b.ZIndex = z or 50
b.Parent = frame; b.MouseButton1Click:Connect(cb)
end

-- ── OPEN / CLOSE STATE ────────────────────────────────────────────────────
local isOpen = false
-- Hide everything on start
coinsFrame.Visible  = false
cratesFrame.Visible = false
if weaponsFrame then weaponsFrame.Visible = false end

local function setOpen(open)
isOpen = open
if open then
coinsFrame.Visible  = true
cratesFrame.Visible = false
if weaponsFrame then weaponsFrame.Visible = false end
else
coinsFrame.Visible  = false
cratesFrame.Visible = false
if weaponsFrame then weaponsFrame.Visible = false end
end
end

-- ── WIRE ICON — happens FIRST, before any slow work ───────────────────────
if iconFrame then
-- Destroy stale overlay
local old = iconFrame:FindFirstChild("IconClickZone")
if old then old:Destroy() end

local existingBtn = iconFrame:FindFirstChildWhichIsA("GuiButton")
if existingBtn then
existingBtn.MouseButton1Click:Connect(function() setOpen(not isOpen) end)
print("[Emporium] Wired existing button: " .. existingBtn.Name)
else
local btn = Instance.new("TextButton")
btn.Name = "IconClickZone"; btn.Size = UDim2.fromScale(1,1)
btn.BackgroundTransparency = 1; btn.Text = ""; btn.ZIndex = 9999
btn.Parent = iconFrame
btn.MouseButton1Click:Connect(function() setOpen(not isOpen) end)
print("[Emporium] Icon overlay placed on " .. iconFrame:GetFullName())
end
else
warn("[Emporium] Icon frame not found — cannot wire open button")
end

print("[Emporium] Icon wired. Remaining setup starting...")

-- ── NAV BUTTON STYLE ──────────────────────────────────────────────────────
local function styleNavBtn(frame, active, text, activeColor)
if not frame then return end
frame.BackgroundTransparency = 1
ensureCorner(frame, 14)
ensureStroke(frame, active and (activeColor or Color3.new(1,1,1)) or Color3.fromRGB(100,100,110),
active and 2.5 or 1.5, active and 0 or 0.45)
local lbl = frame:FindFirstChildWhichIsA("TextLabel", true)
if lbl then
lbl.Text = text; lbl.Font = PRICE_FONT; lbl.TextSize = PRICE_SIZE
lbl.TextColor3 = active and (activeColor or Color3.new(1,1,1)) or Color3.fromRGB(140,140,150)
end
end

-- ── TAB BUTTONS ───────────────────────────────────────────────────────────
local allPanels = { coinsFrame, cratesFrame }
if weaponsFrame then table.insert(allPanels, weaponsFrame) end

local navBtns = {}
for _, panel in ipairs(allPanels) do
navBtns[panel] = {
CoinsButton   = panel:FindFirstChild("CoinsButton"),
CratesButton  = panel:FindFirstChild("CratesButton"),
WeaponsButton = panel:FindFirstChild("WeaponsButton"),
}
end

local function refreshNav(activePanel)
	local tabFor = {
		CoinsButton   = coinsFrame,
		CratesButton  = cratesFrame,
		WeaponsButton = weaponsFrame,
	}
	local lblFor = {
		CoinsButton   = "💰 Coins",
		CratesButton  = "📦 Crates",
		WeaponsButton = "⚔️ Weapons",
	}
	-- Active text/stroke color per button
	local colorFor = {
		CoinsButton   = Color3.fromRGB(80, 220, 100),    -- green
		CratesButton  = Color3.fromRGB(80, 170, 255),    -- blue
		WeaponsButton = Color3.fromRGB(255, 80, 140),    -- reddish pink
	}
	for _, panel in ipairs(allPanels) do
		for btnName, tabFrame in pairs(tabFor) do
			styleNavBtn(navBtns[panel][btnName], tabFrame == activePanel, lblFor[btnName], colorFor[btnName])
		end
	end
end

local function showCoins()
coinsFrame.Visible  = true
cratesFrame.Visible = false
if weaponsFrame then weaponsFrame.Visible = false end
isOpen = true
refreshNav(coinsFrame)
end
local function showCrates()
coinsFrame.Visible  = false
cratesFrame.Visible = true
if weaponsFrame then weaponsFrame.Visible = false end
isOpen = true
refreshNav(cratesFrame)
end
local function showWeapons()
if not weaponsFrame then return end
coinsFrame.Visible  = false
cratesFrame.Visible = false
weaponsFrame.Visible = true
isOpen = true
refreshNav(weaponsFrame)
end

-- Override setOpen to also refresh nav when opening
setOpen = function(open)
isOpen = open
if open then showCoins() else
coinsFrame.Visible  = false
cratesFrame.Visible = false
if weaponsFrame then weaponsFrame.Visible = false end
end
end

-- Re-wire icon to use updated setOpen
if iconFrame then
local btn = iconFrame:FindFirstChild("IconClickZone")
if btn then
-- reconnect with updated setOpen (disconnect old via recreate)
btn:Destroy()
local newBtn = Instance.new("TextButton")
newBtn.Name = "IconClickZone"; newBtn.Size = UDim2.fromScale(1,1)
newBtn.BackgroundTransparency = 1; newBtn.Text = ""; newBtn.ZIndex = 9999
newBtn.Parent = iconFrame
newBtn.MouseButton1Click:Connect(function() setOpen(not isOpen) end)
end
end

-- Wire nav buttons in all panels
for _, panel in ipairs(allPanels) do
addOverlay(navBtns[panel].CoinsButton,   showCoins,   60)
addOverlay(navBtns[panel].CratesButton,  showCrates,  60)
addOverlay(navBtns[panel].WeaponsButton, showWeapons, 60)
end

-- ── HEAVY ASYNC SETUP ─────────────────────────────────────────────────────
task.spawn(function()

-- ── VIEWPORT BUILDER ──────────────────────────────────────────────────────
local function buildViewport(section, childName, folder, modelName, strokeSetup)
local old = section:FindFirstChild(childName)
if not old then return end
local sz, pos, anc, zi = old.Size, old.Position, old.AnchorPoint, old.ZIndex or 1
old:Destroy()

local vp = Instance.new("ViewportFrame")
vp.Name = childName; vp.Size = sz; vp.Position = pos
vp.AnchorPoint = anc; vp.ZIndex = zi
vp.BackgroundTransparency = 1; vp.BorderSizePixel = 0
vp.Parent = section
if strokeSetup then strokeSetup(vp) end

local cam = Instance.new("Camera")
vp.CurrentCamera = cam; cam.Parent = vp

if not folder then return vp end
local tpl = folder:FindFirstChild(modelName)
if not tpl then
warn("[Emporium] Model '" .. tostring(modelName) .. "' not in " .. folder.Name)
return vp
end

local wm = Instance.new("WorldModel"); wm.Parent = vp
local mdl = tpl:Clone(); mdl.Parent = wm

local cf, sz2
if mdl:IsA("Model") then cf, sz2 = mdl:GetBoundingBox()
elseif mdl:IsA("BasePart") then cf, sz2 = mdl.CFrame, mdl.Size end

if cf and sz2 then
mdl:PivotTo(CFrame.new(0, 0, 0))
local dist = math.max(sz2.X, sz2.Y, sz2.Z) * 0.65
cam.CFrame = CFrame.new(Vector3.new(0, dist*0.35, dist), Vector3.new(0,0,0))
task.spawn(function()
local t = 0
while vp.Parent do
t = t + task.wait(0.04)
mdl:PivotTo(CFrame.new(0, math.sin(t*1.2)*0.06, 0) * CFrame.Angles(0, t*0.7, 0))
end
end)
end
return vp
end

-- ── CRATE VIEWPORTS ───────────────────────────────────────────────────────
local crateModels = ReplicatedStorage:FindFirstChild("Crates")
if not crateModels then
	warn("[Emporium] ReplicatedStorage.Crates NOT FOUND")
else
	print("[Emporium] RS.Crates children:")
	for _, c in crateModels:GetChildren() do
		print("  " .. c.ClassName .. ' "' .. c.Name .. '"')
	end
end

for frameName, pkg in pairs(CRATE_PACKAGES) do
	local section = cratesFrame:FindFirstChild(frameName)
	if not section then warn("[Emporium] Crate section missing: " .. frameName); continue end
	print("[Emporium] Processing crate section: " .. frameName)
	for _, child in section:GetChildren() do
		print("  child: " .. child.ClassName .. ' "' .. child.Name .. '"')
	end

	local key = frameName:upper()
	local lbl = section:FindFirstChildWhichIsA("TextLabel", true)
if lbl then
local rarity = ""
if CrateConfig and CrateConfig.Crates then
local cd = CrateConfig.Crates[pkg.configKey]
if cd then rarity = cd.rarity or "" end
end
lbl.Text = string.format("%s\n[%s]  •  %d coins", pkg.label, rarity:upper(), pkg.coinCost)
lbl.Font = PRICE_FONT; lbl.TextSize = PRICE_SIZE
lbl.TextStrokeTransparency = 0.5
lbl.BackgroundTransparency = 1
lbl.ZIndex = 10
do local s = lbl:FindFirstChildOfClass("UIStroke"); if s then s:Destroy() end end
if key == "SILVER" then
lbl.TextColor3 = Color3.fromRGB(215,215,225)
elseif key == "SAPPHIRE" then
lbl.TextColor3 = Color3.fromRGB(100,200,255)
else
task.spawn(function()
local h = 0
while lbl and lbl.Parent do h=(h+0.005)%1; lbl.TextColor3=Color3.fromHSV(h,1,1); task.wait(0.03) end
end)
end
end

	-- Try uppercase, then title-case, then exact frameName for RS.Crates lookup
	local crateModelName = key
	if crateModels then
		if not crateModels:FindFirstChild(key) then
			if crateModels:FindFirstChild(frameName) then
				crateModelName = frameName  -- e.g. "Silver"
				print("[Emporium] Using title-case model name: " .. crateModelName)
			else
				warn("[Emporium] Could not find model '" .. key .. "' or '" .. frameName .. "' in RS.Crates")
			end
		end
	end

	-- Ensure placeholder so buildViewport doesn't bail out if Studio has no "Crate" child
	if not section:FindFirstChild("Crate") then
		local ph = Instance.new("Frame")
		ph.Name = "Crate"; ph.Size = UDim2.new(1, 0, 0.55, 0)
		ph.Position = UDim2.new(0, 0, 0.04, 0); ph.BackgroundTransparency = 1
		ph.ZIndex = (section.ZIndex or 1) + 1; ph.Parent = section
		print("[Emporium] Created Crate placeholder in " .. frameName)
	end

	buildViewport(section, "Crate", crateModels, crateModelName, function(vp)
local s
if key == "SILVER" then
s = ensureStroke(vp, Color3.fromRGB(200,200,215), 3, 0)
elseif key == "SAPPHIRE" then
s = ensureStroke(vp, Color3.fromRGB(80,160,255), 3, 0)
else
s = ensureStroke(vp, Color3.fromRGB(255,220,0), 4, 0)
task.spawn(function()
local h=0
while vp.Parent do h=(h+0.005)%1; s.Color=Color3.fromHSV(h,1,1); task.wait(0.03) end
end)
end
end)

local cn, cp = frameName, pkg.coinCost
addOverlay(section, function()
warn(string.format("[Emporium] Buy '%s' for %d coins (server pending)", cn, cp))
end, 55)
end

-- ── COIN SECTION SETUP ──────────────────────────────────────────────────
-- Direct prompt — Roblox shows its own confirmation UI.
local RemoteEvents    = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
local coinProductIdRF = RemoteEvents and RemoteEvents:FindFirstChild("CoinProductIdRF")

-- ── COIN LABELS ───────────────────────────────────────────────────────────
for frameName, pkg in pairs(COIN_PACKAGES) do
local f = coinsFrame:FindFirstChild(frameName)
if not f then warn("[Emporium] Coin frame missing: " .. frameName); continue end
local lbl = f:FindFirstChildWhichIsA("TextLabel", true)
if lbl then
lbl.Text = string.format("%d Coins  |  %d R$", pkg.coins, pkg.robux)
lbl.Font = PRICE_FONT; lbl.TextSize = PRICE_SIZE
lbl.TextColor3 = COIN_COLOR; lbl.TextStrokeTransparency = 0.6
lbl.BackgroundTransparency = 1
lbl.ZIndex = 10
do local s = lbl:FindFirstChildOfClass("UIStroke"); if s then s:Destroy() end end
end
local fn = frameName
addOverlay(f, function()
	if coinProductIdRF then
		local ok, productId = pcall(function()
			return coinProductIdRF:InvokeServer(fn)
		end)
		if ok and productId and productId ~= 0 then
			MarketplaceService:PromptProductPurchase(Players.LocalPlayer, productId)
		else
			warn("[Emporium] productId not configured for: " .. fn)
		end
	else
		warn("[Emporium] CoinProductIdRF not found")
	end
end, 55)
end
local function showCoinDialog(frameName, pkg)
	local dlg = Instance.new("ScreenGui")
	dlg.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
	dlg.ResetOnSpawn    = false
	dlg.IgnoreGuiInset  = true
	dlg.Parent          = playerGui

	-- ── Backdrop ─────────────────────────────────────────────────────────
	local backdrop = Instance.new("TextButton")
	backdrop.Size                 = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3     = Color3.new(0, 0, 0)
	backdrop.BackgroundTransparency = 0.5
	backdrop.BorderSizePixel      = 0
	backdrop.Text                 = ""
	backdrop.ZIndex               = 100
	backdrop.Parent               = dlg
	backdrop.MouseButton1Click:Connect(function() dlg:Destroy() end)

	local W, H = 400, 270

	-- ── Rotating gradient border frame ───────────────────────────────────
	local BORDER = 3
	local glowFrame = Instance.new("Frame")
	glowFrame.Size          = UDim2.new(0, W + BORDER*2, 0, H + BORDER*2)
	glowFrame.Position      = UDim2.fromScale(0.5, 0.5)
	glowFrame.AnchorPoint   = Vector2.new(0.5, 0.5)
	glowFrame.BackgroundColor3 = Color3.new(1, 1, 1)
	glowFrame.BorderSizePixel = 0
	glowFrame.ZIndex        = 101
	glowFrame.Parent        = dlg
	local glowCorner = Instance.new("UICorner")
	glowCorner.CornerRadius = UDim.new(0, 18)
	glowCorner.Parent = glowFrame

	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0,    Color3.fromRGB(255, 255, 255)), -- pure white
		ColorSequenceKeypoint.new(0.25, Color3.fromRGB(200, 200, 210)), -- silver
		ColorSequenceKeypoint.new(0.5,  Color3.fromRGB(140, 140, 152)), -- mid grey
		ColorSequenceKeypoint.new(0.75, Color3.fromRGB(200, 200, 210)), -- silver
		ColorSequenceKeypoint.new(1,    Color3.fromRGB(255, 255, 255)), -- pure white
	})
	grad.Rotation = 0
	grad.Parent   = glowFrame

	-- Spin the gradient
	task.spawn(function()
		local r = 0
		while glowFrame.Parent do
			r = (r + 1.4) % 360
			grad.Rotation = r
			task.wait(0.016)
		end
	end)

	-- ── Inner card (sits on top, hides the glow except at edges) ─────────
	local card = Instance.new("Frame")
	card.Size             = UDim2.new(0, W, 0, H)
	card.Position         = UDim2.fromScale(0.5, 0.5)
	card.AnchorPoint      = Vector2.new(0.5, 0.5)
	card.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
	card.BorderSizePixel  = 0
	card.ZIndex           = 102
	card.Parent           = dlg
	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 16)
	cardCorner.Parent = card

	-- Subtle inner gradient (top lighter, bottom darker)
	local innerGrad = Instance.new("UIGradient")
	innerGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0,   Color3.fromRGB(32, 32, 42)),
		ColorSequenceKeypoint.new(1,   Color3.fromRGB(12, 12, 18)),
	})
	innerGrad.Rotation = 90
	innerGrad.Parent   = card

	-- ── Icon strip at top ─────────────────────────────────────────────────
	local iconBar = Instance.new("Frame")
	iconBar.Size              = UDim2.new(1, 0, 0, 56)
	iconBar.Position          = UDim2.new(0, 0, 0, 0)
	iconBar.BackgroundColor3  = Color3.fromRGB(24, 24, 34)
	iconBar.BorderSizePixel   = 0
	iconBar.ZIndex            = 103
	iconBar.Parent            = card
	local ibCorner = Instance.new("UICorner")
	ibCorner.CornerRadius = UDim.new(0, 16)
	ibCorner.Parent = iconBar
	-- Square off bottom edge of icon bar
	local ibSquare = Instance.new("Frame")
	ibSquare.Size   = UDim2.new(1, 0, 0.5, 0)
	ibSquare.Position = UDim2.new(0, 0, 0.5, 0)
	ibSquare.BackgroundColor3 = Color3.fromRGB(24, 24, 34)
	ibSquare.BorderSizePixel = 0
	ibSquare.ZIndex = 103
	ibSquare.Parent = iconBar

	local coinIcon = Instance.new("TextLabel")
	coinIcon.Size                 = UDim2.new(0, 48, 0, 48)
	coinIcon.Position             = UDim2.new(0, 16, 0, 4)
	coinIcon.BackgroundTransparency = 1
	coinIcon.Text                 = "🪙"
	coinIcon.TextSize             = 36
	coinIcon.Font                 = Enum.Font.GothamBold
	coinIcon.ZIndex               = 104
	coinIcon.Parent               = iconBar

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size                 = UDim2.new(1, -78, 0, 56)
	titleLbl.Position             = UDim2.new(0, 68, 0, 0)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text                 = string.format("%d  Trump Coins", pkg.coins)
	titleLbl.Font                 = Enum.Font.GothamBlack
	titleLbl.TextSize             = 26
	titleLbl.TextColor3           = Color3.fromRGB(245, 245, 255)
	titleLbl.TextXAlignment       = Enum.TextXAlignment.Left
	titleLbl.TextYAlignment       = Enum.TextYAlignment.Center
	titleLbl.ZIndex               = 104
	titleLbl.Parent               = iconBar

	-- Silver shimmer on title text
	local titleStroke = Instance.new("UIStroke")
	titleStroke.Color         = Color3.fromRGB(180, 180, 195)
	titleStroke.Thickness     = 1
	titleStroke.Transparency  = 0.65
	titleStroke.Parent        = titleLbl

	-- ── Package label ──────────────────────────────────────────────────────
	local pkgLabel = Instance.new("TextLabel")
	pkgLabel.Size                 = UDim2.new(1, -32, 0, 28)
	pkgLabel.Position             = UDim2.new(0, 16, 0, 64)
	pkgLabel.BackgroundTransparency = 1
	pkgLabel.Text                 = frameName .. " Package   •   " .. pkg.coins .. " coins"
	pkgLabel.Font                 = Enum.Font.GothamMedium
	pkgLabel.TextSize             = 15
	pkgLabel.TextColor3           = Color3.fromRGB(155, 155, 170)
	pkgLabel.TextXAlignment       = Enum.TextXAlignment.Left
	pkgLabel.ZIndex               = 103
	pkgLabel.Parent               = card

	-- Thin separator line
	local sep = Instance.new("Frame")
	sep.Size             = UDim2.new(1, -32, 0, 1)
	sep.Position         = UDim2.new(0, 16, 0, 98)
	sep.BackgroundColor3 = Color3.fromRGB(55, 55, 68)
	sep.BorderSizePixel  = 0
	sep.ZIndex           = 103
	sep.Parent           = card

	-- ── Button factory ────────────────────────────────────────────────────
	local function makeBtn(text, subText, bgTop, bgBot, yPos, action)
		local btn = Instance.new("TextButton")
		btn.Size              = UDim2.new(1, -32, 0, 52)
		btn.Position          = UDim2.new(0, 16, 0, yPos)
		btn.BackgroundColor3  = bgTop
		btn.Text              = ""
		btn.BorderSizePixel   = 0
		btn.ZIndex            = 103
		btn.AutoButtonColor   = false
		btn.Parent            = card
		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 12)
		btnCorner.Parent = btn

		local btnGrad = Instance.new("UIGradient")
		btnGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, bgTop),
			ColorSequenceKeypoint.new(1, bgBot),
		})
		btnGrad.Rotation = 90
		btnGrad.Parent   = btn

		local mainTxt = Instance.new("TextLabel")
		mainTxt.Size                 = UDim2.new(1, -20, 0, 28)
		mainTxt.Position             = UDim2.new(0, 14, 0, 4)
		mainTxt.BackgroundTransparency = 1
		mainTxt.Text                 = text
		mainTxt.Font                 = Enum.Font.GothamBold
		mainTxt.TextSize             = 19
		mainTxt.TextColor3           = Color3.fromRGB(248, 248, 255)
		mainTxt.TextXAlignment       = Enum.TextXAlignment.Left
		mainTxt.ZIndex               = 104
		mainTxt.Parent               = btn

		if subText and subText ~= "" then
			local subTxt = Instance.new("TextLabel")
			subTxt.Size                 = UDim2.new(1, -20, 0, 18)
			subTxt.Position             = UDim2.new(0, 14, 0, 30)
			subTxt.BackgroundTransparency = 1
			subTxt.Text                 = subText
			subTxt.Font                 = Enum.Font.Gotham
			subTxt.TextSize             = 13
			subTxt.TextColor3           = Color3.fromRGB(200, 205, 220)
			subTxt.TextXAlignment       = Enum.TextXAlignment.Left
			subTxt.ZIndex               = 104
			subTxt.Parent               = btn
		end

		-- Hover effect
		btn.MouseEnter:Connect(function()
			local s = Instance.new("UIStroke")
			s.Name = "_hover"
			s.Color = Color3.fromRGB(220, 220, 240)
			s.Thickness = 1.5
			s.Transparency = 0.3
			s.Parent = btn
		end)
		btn.MouseLeave:Connect(function()
			local s = btn:FindFirstChild("_hover")
			if s then s:Destroy() end
		end)

		btn.MouseButton1Click:Connect(function()
			dlg:Destroy()
			action()
		end)
		return btn
	end

	-- ── Robux purchase button ─────────────────────────────────────────────
	makeBtn(
		string.format("⭐  Pay  %d R$  with Robux", pkg.robux),
		"Instant delivery after purchase",
		Color3.fromRGB(28, 90, 185),
		Color3.fromRGB(15, 55, 130),
		108,
		function()
			if coinProductIdRF then
				local ok, productId = pcall(function()
					return coinProductIdRF:InvokeServer(frameName)
				end)
				if ok and productId and productId ~= 0 then
					MarketplaceService:PromptProductPurchase(Players.LocalPlayer, productId)
				else
					warn("[Emporium] productId not configured for: " .. frameName)
				end
			else
				warn("[Emporium] CoinProductIdRF RemoteFunction not found")
			end
		end
	)

	-- ── Cancel button ─────────────────────────────────────────────────────
	makeBtn(
		"✕   Cancel",
		"",
		Color3.fromRGB(38, 38, 50),
		Color3.fromRGB(26, 26, 36),
		172,
		function() end
	)
end

-- ── COIN LABELS ───────────────────────────────────────────────────────────
for frameName, pkg in pairs(COIN_PACKAGES) do
local f = coinsFrame:FindFirstChild(frameName)
if not f then warn("[Emporium] Coin frame missing: " .. frameName); continue end
local lbl = f:FindFirstChildWhichIsA("TextLabel", true)
if lbl then
lbl.Text = string.format("%d Coins  |  %d R$", pkg.coins, pkg.robux)
lbl.Font = PRICE_FONT; lbl.TextSize = PRICE_SIZE
lbl.TextColor3 = COIN_COLOR; lbl.TextStrokeTransparency = 0.6
lbl.BackgroundTransparency = 1
lbl.ZIndex = 10
do local s = lbl:FindFirstChildOfClass("UIStroke"); if s then s:Destroy() end end
end
local fn, pk = frameName, pkg
addOverlay(f, function()
	showCoinDialog(fn, pk)
end, 55)
end

-- ── WEAPON SLOTS ──────────────────────────────────────────────────────────
if weaponsFrame then
local skinLib = ReplicatedStorage:FindFirstChild("SkinLibrary")

local function randomSkinByRarity(rarity)
if not SkinConfig or not SkinConfig.GetAllSkins then return nil end
local ok, skins = pcall(function() return SkinConfig.GetAllSkins() end)
if not ok or not skins then return nil end
local pool = {}
for _, e in ipairs(skins) do
if e.rarity == rarity then table.insert(pool, e.id) end
end
return #pool > 0 and pool[math.random(1, #pool)] or nil
end

	print("[Emporium] Weapons panel children:")
	for _, c in weaponsFrame:GetChildren() do
		print("  " .. c.ClassName .. ' "' .. c.Name .. '"')
	end

	for slotName, slot in pairs(WEAPON_SLOTS) do
		local section = weaponsFrame:FindFirstChild(slotName)
if not section then warn("[Emporium] Weapon slot '"..slotName.."' not found"); continue end

local wname = slot.weaponName or randomSkinByRarity(slot.rarity)
if not wname then warn("[Emporium] No weapon for rarity "..slot.rarity); continue end

-- Label
local lbl = section:FindFirstChildWhichIsA("TextLabel", true)
if lbl then
lbl.Text = string.format("%s\n[%s]  •  %d coins", wname, slot.rarity:upper(), slot.coinCost)
lbl.Font = PRICE_FONT; lbl.TextSize = PRICE_SIZE; lbl.TextStrokeTransparency = 0.5
lbl.BackgroundTransparency = 1
lbl.ZIndex = 10
do local s = lbl:FindFirstChildOfClass("UIStroke"); if s then s:Destroy() end end
if slot.rarity == "legendary" then
task.spawn(function()
local h = 0
while lbl and lbl.Parent do h=(h+0.005)%1; lbl.TextColor3=Color3.fromHSV(h,1,1); task.wait(0.03) end
end)
else
lbl.TextColor3 = EPIC_COLOR
end
end

-- Ensure placeholder for viewport
if not section:FindFirstChild("Weapon") then
local ph = Instance.new("Frame")
ph.Name = "Weapon"; ph.Size = UDim2.new(1,0,0.6,0)
ph.Position = UDim2.new(0,0,0.05,0); ph.BackgroundTransparency = 1
ph.ZIndex = (section.ZIndex or 1)+1; ph.Parent = section
end

buildViewport(section, "Weapon", skinLib, wname, function(vp)
if slot.rarity == "legendary" then
local s = ensureStroke(vp, LEG_COLOR, 4, 0)
task.spawn(function()
local h=0.1
while vp.Parent do h=(h+0.003)%0.18; s.Color=Color3.fromHSV(h,1,1); task.wait(0.03) end
end)
else
ensureStroke(vp, EPIC_COLOR, 3, 0)
end
end)

local sn, sw, sc = slotName, wname, slot.coinCost
addOverlay(section, function()
warn(string.format("[Emporium] Buy '%s' slot %s for %d coins (server pending)", sw, sn, sc))
end, 55)
end
end

print("[Emporium] Ready.")
end) -- end task.spawn

-- Bob the icon frame the same way as the Spawn button and Stats frames.
local _BOB_SPEED    = 1.4
local _BOB_AMP      = 0.025
RunService.Heartbeat:Connect(function()
	if not iconFrame or not iconFrame.Parent or not iconBasePos then return end
	local yOff = math.sin(os.clock() * _BOB_SPEED) * _BOB_AMP
	iconFrame.Position = UDim2.new(
		iconBasePos.X.Scale, iconBasePos.X.Offset,
		iconBasePos.Y.Scale + yOff, iconBasePos.Y.Offset
	)
end)