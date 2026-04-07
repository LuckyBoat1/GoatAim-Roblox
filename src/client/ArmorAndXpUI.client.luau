-- ArmorAndXpUI.client.luau
-- Armor bar: lerps display fraction toward target every frame via Heartbeat — buttery smooth.
-- XP bar: polls GetPlayerData every 1s.

local Players     = game:GetService("Players")
local RS          = game:GetService("ReplicatedStorage")
local RunService  = game:GetService("RunService")

local player = Players.LocalPlayer
local pg     = player:WaitForChild("PlayerGui")

-- ── Remote for fetching XP/level data ────────────────────────────────────────
local RemoteEvents  = RS:WaitForChild("RemoteEvents", 20)
local GetPlayerData = RemoteEvents and RemoteEvents:WaitForChild("GetPlayerData", 20)

if not GetPlayerData then
	warn("[ArmorAndXpUI] GetPlayerData remote not found")
	return
end

-- ── EXP threshold helper ──────────────────────────────────────────────────────
local function expForLevel(lvl)
	return 100 * lvl
end

-- ── Bar fill helpers ──────────────────────────────────────────────────────────
-- Instant set (XP bar, initial state)
local function setBarFill(innerImage, innerBg, fraction)
	fraction = math.clamp(fraction, 0, 1)
	innerImage.Size     = UDim2.new(fraction * innerBg.Size.X.Scale, fraction * innerBg.Size.X.Offset,
	                                innerBg.Size.Y.Scale, innerBg.Size.Y.Offset)
	innerImage.Position = innerBg.Position
end

-- Direct fraction write without recomputing bg bounds (used inside heartbeat)
local function applyFraction(innerImage, innerBg, fraction)
	innerImage.Size = UDim2.new(fraction * innerBg.Size.X.Scale, fraction * innerBg.Size.X.Offset,
	                            innerBg.Size.Y.Scale, innerBg.Size.Y.Offset)
end

-- ── Create value TextLabel ────────────────────────────────────────────────────
local function createLabel(parent, name)
	local existing = parent:FindFirstChild(name)
	if existing then return existing end
	local label = Instance.new("TextLabel")
	label.Name                   = name
	label.Size                   = UDim2.new(1, 0, 1, 0)
	label.Position               = UDim2.new(0, 0, 0, 0)
	label.BackgroundTransparency = 1
	label.TextColor3             = Color3.new(1, 1, 1)
	label.TextStrokeColor3       = Color3.new(0, 0, 0)
	label.TextStrokeTransparency = 0.3
	label.Font                   = Enum.Font.GothamBold
	label.TextScaled             = false
	label.TextSize               = 14
	label.ZIndex                 = 10
	label.Text                   = ""
	label.Parent                 = parent
	return label
end

-- ── Setup ─────────────────────────────────────────────────────────────────────
local function setupBars()
	local gui = pg:WaitForChild("ArmorAndXp", 30)
	if not gui then return nil end
	if gui:IsA("ScreenGui") then gui.ResetOnSpawn = false end

	local armorBar = gui:FindFirstChild("Armor")
	local xpBar
	for _, child in ipairs(gui:GetChildren()) do
		if child ~= armorBar and (child:IsA("CanvasGroup") or child:IsA("Frame")) then
			xpBar = child; break
		end
	end
	if not armorBar or not xpBar then return nil end
	xpBar.Name = "Xp"

	local armorInner = armorBar:FindFirstChild("Inner")
	local armorBg    = armorBar:FindFirstChild("InnerBackground")
	local xpInner    = xpBar:FindFirstChild("Inner")
	local xpBg       = xpBar:FindFirstChild("InnerBackground")
	if not armorInner or not armorBg or not xpInner or not xpBg then return nil end

	local armorLabel = createLabel(armorBar, "ValueLabel")
	local xpLabel    = createLabel(xpBar,    "ValueLabel")

	armorInner.Position = armorBg.Position

	return { gui=gui, armorInner=armorInner, armorBg=armorBg,
	         xpInner=xpInner, xpBg=xpBg, armorLabel=armorLabel, xpLabel=xpLabel }
end

local refs = setupBars()

player.CharacterAdded:Connect(function()
	task.wait(1)
	if not refs or not refs.gui or not refs.gui.Parent then
		refs = setupBars()
	end
end)

-- ── Per-frame smooth armor — spring physics ───────────────────────────────────
-- A damped spring simulation: display accelerates toward the target organically.
-- No discrete steps, no mechanical feel — just fluid motion.
local STIFFNESS  = 6    -- spring pull strength (higher = snappier pull)
local DAMPING    = 5    -- damping (2*sqrt(6)≈4.9 → critically damped, zero overshoot)

local displayArmor = 0
local targetArmor  = 0
local maxArmorVal  = 1
local armorVel     = 0   -- current velocity of displayArmor

local function onArmorChanged()
	if not refs or not refs.gui or not refs.gui.Parent then
		refs = setupBars()
	end
	local armor    = player:GetAttribute("Armor") or 0
	local maxArmor = math.max(1, player:GetAttribute("MaxArmor") or 1)
	targetArmor = armor
	maxArmorVal = maxArmor
	if refs then
		refs.armorLabel.Text = string.format("Armor: %d / %d", armor, maxArmor)
	end
end

player:GetAttributeChangedSignal("Armor"):Connect(onArmorChanged)
player:GetAttributeChangedSignal("MaxArmor"):Connect(onArmorChanged)

RunService.Heartbeat:Connect(function(dt)
	if not refs or not refs.armorInner or not refs.armorBg then return end
	-- Spring: force = stiffness * error - damping * velocity
	local err  = targetArmor - displayArmor
	armorVel     = armorVel + (err * STIFFNESS - armorVel * DAMPING) * dt
	displayArmor = math.clamp(displayArmor + armorVel * dt, 0, maxArmorVal)
	applyFraction(refs.armorInner, refs.armorBg, displayArmor / maxArmorVal)
end)

-- ── XP bar + initial armor fallback: poll every 1s ───────────────────────────
while true do
	if not refs or not refs.gui or not refs.gui.Parent then
		refs = setupBars()
	end

	if refs then
		local ok, data = pcall(function() return GetPlayerData:InvokeServer() end)
		if ok and data then
			-- Armor fallback (before first attribute fires)
			if not player:GetAttribute("Armor") then
				local armor    = data.armor or 0
				local maxArmor = math.max(1, (data.armorUpgradeLevel or 0) * 10)
				targetArmor  = armor
				displayArmor = armor
				maxArmorVal  = maxArmor
				armorVel     = 0
				setBarFill(refs.armorInner, refs.armorBg, armor / maxArmor)
				refs.armorLabel.Text = string.format("Armor: %d / %d", armor, maxArmor)
			end

			-- XP bar
			local totalExp  = data.exp or 0
			local lvl       = data.lvl or 1
			local expNeeded = expForLevel(lvl)
			local xpFrac    = (expNeeded > 0) and (totalExp / expNeeded) or 0
			setBarFill(refs.xpInner, refs.xpBg, xpFrac)
			refs.xpLabel.Text = string.format("Xp: %d / %d  (Lvl %d)", totalExp, expNeeded, lvl)
		end
	end

	task.wait(1)
end


-- ── Remote for fetching XP/level data ────────────────────────────────────────
local RemoteEvents  = RS:WaitForChild("RemoteEvents", 20)
local GetPlayerData = RemoteEvents and RemoteEvents:WaitForChild("GetPlayerData", 20)

if not GetPlayerData then
	warn("[ArmorAndXpUI] GetPlayerData remote not found")
	return
end

-- ── EXP thresholds per level (EXP needed to go from lvl N to N+1) ────────────
local function expForLevel(lvl)
	return 100 * lvl
end

-- Tween info for the armor bar glide
local ARMOR_TWEEN_INFO = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- ── Bar fill helpers ─────────────────────────────────────────────────────────
-- Instant set (used for XP and initial state)
local function setBarFill(innerImage, innerBg, fraction)
	fraction = math.clamp(fraction, 0, 1)
	local maxX   = innerBg.Size.X.Scale
	local maxXOff = innerBg.Size.X.Offset
	innerImage.Size     = UDim2.new(fraction * maxX, fraction * maxXOff, innerBg.Size.Y.Scale, innerBg.Size.Y.Offset)
	innerImage.Position = innerBg.Position
end

-- Smooth tween set (used for armor bar)
local armorTween = nil
local function tweenBarFill(innerImage, innerBg, fraction)
	fraction = math.clamp(fraction, 0, 1)
	local maxX    = innerBg.Size.X.Scale
	local maxXOff = innerBg.Size.X.Offset
	local targetSize = UDim2.new(fraction * maxX, fraction * maxXOff, innerBg.Size.Y.Scale, innerBg.Size.Y.Offset)
	if armorTween then armorTween:Cancel() end
	armorTween = TweenService:Create(innerImage, ARMOR_TWEEN_INFO, { Size = targetSize })
	armorTween:Play()
end

-- ── Create value TextLabel ───────────────────────────────────────────────────
local function createLabel(parent, name)
	local existing = parent:FindFirstChild(name)
	if existing then return existing end

	local label = Instance.new("TextLabel")
	label.Name                 = name
	label.Size                 = UDim2.new(1, 0, 1, 0)
	label.Position             = UDim2.new(0, 0, 0, 0)
	label.BackgroundTransparency = 1
	label.TextColor3           = Color3.new(1, 1, 1)
	label.TextStrokeColor3     = Color3.new(0, 0, 0)
	label.TextStrokeTransparency = 0.3
	label.Font                 = Enum.Font.GothamBold
	label.TextScaled           = false
	label.TextSize             = 14
	label.ZIndex               = 10
	label.Text                 = ""
	label.Parent               = parent
	return label
end

-- ── Setup function: finds & wires up the GUI (called on spawn) ───────────────
local function setupBars()
	local gui = pg:WaitForChild("ArmorAndXp", 30)
	if not gui then return nil end

	-- Force ResetOnSpawn off so it survives future respawns
	if gui:IsA("ScreenGui") then
		gui.ResetOnSpawn = false
	end

	local armorBar = gui:FindFirstChild("Armor")
	local xpBar = nil
	for _, child in ipairs(gui:GetChildren()) do
		if child ~= armorBar and (child:IsA("CanvasGroup") or child:IsA("Frame")) then
			xpBar = child
			break
		end
	end
	if not armorBar or not xpBar then return nil end

	xpBar.Name = "Xp"

	local armorInner = armorBar:FindFirstChild("Inner")
	local armorBg    = armorBar:FindFirstChild("InnerBackground")
	local xpInner    = xpBar:FindFirstChild("Inner")
	local xpBg       = xpBar:FindFirstChild("InnerBackground")
	if not armorInner or not xpInner or not armorBg or not xpBg then return nil end

	local armorLabel = createLabel(armorBar, "ValueLabel")
	local xpLabel    = createLabel(xpBar,    "ValueLabel")

	return {
		gui = gui,
		armorInner = armorInner,
		armorBg    = armorBg,
		xpInner    = xpInner,
		xpBg       = xpBg,
		armorLabel = armorLabel,
		xpLabel    = xpLabel,
	}
end

-- ── Initial setup ────────────────────────────────────────────────────────────
local refs = setupBars()

-- Re-setup after respawn if GUI was lost
player.CharacterAdded:Connect(function()
	task.wait(1) -- wait for PlayerGui to repopulate
	if not refs or not refs.gui or not refs.gui.Parent then
		refs = setupBars()
	end
end)

-- ── Armor bar: attribute-driven, smoothly tweened ────────────────────────────
local function updateArmorBar()
	if not refs then return end
	local armor    = player:GetAttribute("Armor") or 0
	local maxArmor = math.max(1, player:GetAttribute("MaxArmor") or 1)
	tweenBarFill(refs.armorInner, refs.armorBg, armor / maxArmor)
	refs.armorLabel.Text = string.format("Armor: %d / %d", armor, maxArmor)
end

player:GetAttributeChangedSignal("Armor"):Connect(function()
	if not refs or not refs.gui or not refs.gui.Parent then
		refs = setupBars()
	end
	updateArmorBar()
end)

player:GetAttributeChangedSignal("MaxArmor"):Connect(function()
	if not refs or not refs.gui or not refs.gui.Parent then
		refs = setupBars()
	end
	updateArmorBar()
end)

-- ── XP bar + initial armor: poll every 1s ────────────────────────────────────
while true do
	-- Re-acquire refs if GUI was destroyed (e.g. respawn with ResetOnSpawn)
	if not refs or not refs.gui or not refs.gui.Parent then
		refs = setupBars()
	end

	if refs then
		local ok, data = pcall(function() return GetPlayerData:InvokeServer() end)
		if ok and data then
			-- ── Armor bar (initial / fallback if attribute not yet set) ──────
			if not player:GetAttribute("Armor") then
				local armor    = data.armor or 0
				local maxArmor = math.max(1, (data.armorUpgradeLevel or 0) * 10)
				setBarFill(refs.armorInner, refs.armorBg, armor / maxArmor)
				refs.armorLabel.Text = string.format("Armor: %d / %d", armor, maxArmor)
			end

			-- ── XP bar ───────────────────────────────────────────────────
			local totalExp  = data.exp or 0
			local lvl       = data.lvl or 1
			local expNeeded = expForLevel(lvl)
			local xpFrac    = (expNeeded > 0) and (totalExp / expNeeded) or 0
			setBarFill(refs.xpInner, refs.xpBg, xpFrac)
			refs.xpLabel.Text = string.format("Xp: %d / %d  (Lvl %d)", totalExp, expNeeded, lvl)
		end
	end

	task.wait(1)
end
