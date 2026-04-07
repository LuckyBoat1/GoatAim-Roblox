-- SupplyDropClient.client.luau
-- Hooks the ProximityPrompt on the Ruby Model and opens the EXISTING
-- Studio-built "SupplyDrop" ScreenGui in PlayerGui.
-- GUI hierarchy expected:
--   SupplyDrop (ScreenGui)
--     Frame
--       Claim    (Frame)  → ImageLabel (button bg), TextLabel (info)
--       Upgrade  (Frame)  → ImageLabel (button bg), TextLabel (info)
--       ImageLabel         (background decoration)

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
local SupplyDropRF = nil
task.spawn(function()
	if RemoteEvents then
		SupplyDropRF = RemoteEvents:WaitForChild("SupplyDropRF", 15)
	else
		warn("[SupplyDropClient] RemoteEvents folder not found!")
	end
end)

-- ── FIND THE EXISTING STUDIO GUI ──────────────────────────────────────────
local screenGui = playerGui:WaitForChild("SupplyDrop", 15)
if not screenGui then
	warn("[SupplyDropClient] ScreenGui 'SupplyDrop' not found in PlayerGui!")
	return
end

local panel        = screenGui:WaitForChild("Frame", 10)
local claimFrame   = panel and panel:WaitForChild("Claim", 10)
local upgradeFrame = panel and panel:WaitForChild("Upgrade", 10)

if not panel or not claimFrame or not upgradeFrame then
	warn("[SupplyDropClient] Missing Frame/Claim/Upgrade inside SupplyDrop GUI!")
	return
end

-- Grab the TextLabels (info display)
local claimText   = claimFrame:FindFirstChildWhichIsA("TextLabel")
local upgradeText = upgradeFrame:FindFirstChildWhichIsA("TextLabel")

-- Style the text labels — FredokaOne with stroke (matches HQ buttons)
local function styleLabel(lbl)
	if not lbl then return end
	lbl.Font                    = Enum.Font.FredokaOne
	lbl.TextSize                = 28
	lbl.TextWrapped             = true
	lbl.TextXAlignment          = Enum.TextXAlignment.Center
	lbl.TextYAlignment          = Enum.TextYAlignment.Center
	lbl.TextStrokeTransparency  = 0.8
	lbl.TextStrokeColor3        = Color3.fromRGB(0, 0, 0)
	lbl.TextColor3              = Color3.fromRGB(255, 255, 255)
end
styleLabel(claimText)
styleLabel(upgradeText)

-- Make sure the GUI starts hidden
screenGui.Enabled = false

-- ── CLICKABLE OVERLAYS ────────────────────────────────────────────────────
-- ImageLabels aren't clickable, so add invisible TextButtons on top.
local function makeClickOverlay(parent, name)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(1, 0, 1, 0)
	btn.BackgroundTransparency = 1
	btn.Text = ""
	btn.ZIndex = 10
	btn.Parent = parent
	return btn
end

local claimBtn   = makeClickOverlay(claimFrame, "ClaimBtn")
local upgradeBtn = makeClickOverlay(upgradeFrame, "UpgradeBtn")

-- ── HOVER + SHAKE (matches HQ Upgrades/Storage button style exactly) ─────
local function addHoverEffect(frame, btn)
	local origSize     = frame.Size
	local origRotation = frame.Rotation
	local textLabel    = frame:FindFirstChildWhichIsA("TextLabel")
	local imageLabel   = frame:FindFirstChildWhichIsA("ImageLabel")
	local origTextSize = textLabel and textLabel.TextSize or 28
	local origImgColor = imageLabel and imageLabel.ImageColor3 or Color3.fromRGB(255, 255, 255)
	local isHovering   = false

	btn.MouseEnter:Connect(function()
		isHovering = true
		-- Scale up
		TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(
				origSize.X.Scale * 1.05, origSize.X.Offset,
				origSize.Y.Scale * 1.05, origSize.Y.Offset)
		}):Play()
		-- Brighten image
		if imageLabel then
			TweenService:Create(imageLabel, TweenInfo.new(0.15), {
				ImageColor3 = Color3.fromRGB(
					math.min(255, origImgColor.R * 255 + 40),
					math.min(255, origImgColor.G * 255 + 40),
					math.min(255, origImgColor.B * 255 + 40))
			}):Play()
		end
		-- Text pop + yellow
		if textLabel then
			TweenService:Create(textLabel, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				TextSize   = origTextSize + 3,
				TextColor3 = Color3.fromRGB(255, 255, 150),
			}):Play()
		end
		-- Rotation shake
		task.spawn(function()
			TweenService:Create(frame, TweenInfo.new(0.06), { Rotation = origRotation + 6 }):Play()  task.wait(0.06)
			TweenService:Create(frame, TweenInfo.new(0.06), { Rotation = origRotation - 5 }):Play()  task.wait(0.06)
			TweenService:Create(frame, TweenInfo.new(0.06), { Rotation = origRotation + 4 }):Play()  task.wait(0.06)
			TweenService:Create(frame, TweenInfo.new(0.06), { Rotation = origRotation - 3 }):Play()  task.wait(0.06)
			TweenService:Create(frame, TweenInfo.new(0.06), { Rotation = origRotation + 2 }):Play()  task.wait(0.06)
			TweenService:Create(frame, TweenInfo.new(0.08), { Rotation = origRotation }):Play()
		end)
	end)

	btn.MouseLeave:Connect(function()
		isHovering = false
		-- Restore size and rotation
		TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size     = origSize,
			Rotation = origRotation,
		}):Play()
		-- Restore image
		if imageLabel then
			TweenService:Create(imageLabel, TweenInfo.new(0.15), { ImageColor3 = origImgColor }):Play()
		end
		-- Restore text
		if textLabel then
			TweenService:Create(textLabel, TweenInfo.new(0.15), {
				TextSize   = origTextSize,
				TextColor3 = Color3.fromRGB(255, 255, 255),
			}):Play()
		end
	end)

	-- Click: squish → bounce → settle (matches HQ)
	btn.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then return end
		TweenService:Create(frame, TweenInfo.new(0.08), {
			Size = UDim2.new(origSize.X.Scale * 0.95, origSize.X.Offset,
			               origSize.Y.Scale * 0.95, origSize.Y.Offset)
		}):Play()
		if imageLabel then
			TweenService:Create(imageLabel, TweenInfo.new(0.05), { ImageColor3 = Color3.fromRGB(255, 255, 255) }):Play()
		end
		task.delay(0.08, function()
			TweenService:Create(frame, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Size = UDim2.new(origSize.X.Scale * 1.08, origSize.X.Offset,
				               origSize.Y.Scale * 1.08, origSize.Y.Offset)
			}):Play()
			task.delay(0.15, function()
				local targetSize = isHovering
					and UDim2.new(origSize.X.Scale * 1.05, origSize.X.Offset, origSize.Y.Scale * 1.05, origSize.Y.Offset)
					or origSize
				TweenService:Create(frame, TweenInfo.new(0.1), { Size = targetSize }):Play()
				if imageLabel then
					TweenService:Create(imageLabel, TweenInfo.new(0.1), {
						ImageColor3 = isHovering
							and Color3.fromRGB(
								math.min(255, origImgColor.R * 255 + 40),
								math.min(255, origImgColor.G * 255 + 40),
								math.min(255, origImgColor.B * 255 + 40))
							or origImgColor
					}):Play()
				end
			end)
		end)
	end)
end

addHoverEffect(claimFrame, claimBtn)
addHoverEffect(upgradeFrame, upgradeBtn)

-- ── TIER COLORS ───────────────────────────────────────────────────────────
local TIER_COLORS = {
	Bronze  = Color3.fromRGB(205, 127,  50),
	Silver  = Color3.fromRGB(200, 200, 210),
	Gold    = Color3.fromRGB(255, 210,  30),
	Diamond = Color3.fromRGB( 80, 210, 255),
	Emerald = Color3.fromRGB( 50, 220, 100),
	Obsidian= Color3.fromRGB(170,  90, 255),
	Ruby    = Color3.fromRGB(255,  55,  80),
}

-- ── STATE ─────────────────────────────────────────────────────────────────
local currentData   = nil
local countdownConn = nil
local claimLocked   = false
local upgradeLocked = false

local function formatTime(seconds)
	seconds = math.max(0, math.floor(seconds))
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	local s = seconds % 60
	if h > 0 then
		return string.format("%dh %02dm %02ds", h, m, s)
	elseif m > 0 then
		return string.format("%dm %02ds", m, s)
	else
		return string.format("%ds", s)
	end
end

-- ── REFRESH UI FROM DATA ──────────────────────────────────────────────────
local function refreshUI(data)
	currentData = data
	if not data then return end

	-- ── Claim card ────────────────────────────────────────────────────────
	if claimText then
		if data.canClaim then
			claimText.Text   = "CLAIM"
			claimText.TextColor3 = Color3.fromRGB(80, 255, 120)   -- green = ready
			claimLocked      = false
		else
			claimText.Text   = formatTime(data.cooldownLeft)
			claimText.TextColor3 = Color3.fromRGB(255, 160, 60)   -- orange = on cooldown
			claimLocked      = true
		end
	end

	-- ── Upgrade card ──────────────────────────────────────────────────────
	if upgradeText then
		if data.isMaxTier then
			upgradeText.Text      = "MAX\nTIER"
			upgradeText.TextColor3 = Color3.fromRGB(180, 180, 180)  -- grey = locked
			upgradeLocked         = true
		else
			local canAfford  = (data.currentMoney or 0) >= (data.upgradeCost or math.huge)
			local tierName   = data.nextTierName or "?"
			local tierColor  = TIER_COLORS[tierName] or Color3.fromRGB(255, 255, 255)
			-- Dim the color when the player can't afford it
			local r, g, b    = tierColor.R, tierColor.G, tierColor.B
			if not canAfford then
				r, g, b = r * 0.45, g * 0.45, b * 0.45
			end
			upgradeText.Text       = string.format("%s\n%d", tierName, data.upgradeCost or 0)
			upgradeText.TextColor3 = Color3.new(r, g, b)
			upgradeLocked          = not canAfford
		end
	end
end

-- Live cooldown ticker
local function startCountdown(cooldownLeft)
	if countdownConn then countdownConn:Disconnect(); countdownConn = nil end
	if cooldownLeft <= 0 then return end

	local endClock = os.clock() + cooldownLeft

	countdownConn = RunService.Heartbeat:Connect(function()
		if not screenGui.Enabled then
			countdownConn:Disconnect(); countdownConn = nil; return
		end
		local remaining = endClock - os.clock()
		if remaining <= 0 then
			countdownConn:Disconnect(); countdownConn = nil
			task.spawn(function()
				local ok, data = pcall(function() return SupplyDropRF:InvokeServer("GetData") end)
				if ok and data and data.success then refreshUI(data) end
			end)
			return
		end
		if currentData and not currentData.canClaim and claimText then
			claimText.Text      = formatTime(remaining)
			claimText.TextColor3 = Color3.fromRGB(255, 160, 60)
		end
	end)
end

local function fetchAndRefresh()
	if not SupplyDropRF then
		warn("[SupplyDropClient] SupplyDropRF not ready yet")
		return
	end
	local ok, data = pcall(function() return SupplyDropRF:InvokeServer("GetData") end)
	if ok and data and data.success then
		refreshUI(data)
		if not data.canClaim and (data.cooldownLeft or 0) > 0 then
			startCountdown(data.cooldownLeft)
		end
	else
		warn("[SupplyDropClient] GetData failed:", ok, tostring(data))
	end
end

-- ── BUTTON HANDLERS ───────────────────────────────────────────────────────
claimBtn.MouseButton1Click:Connect(function()
	if claimLocked or not SupplyDropRF then return end
	claimLocked = true

	if claimText then claimText.Text = "..." end

	local ok, result = pcall(function() return SupplyDropRF:InvokeServer("Claim") end)
	if ok and result and result.success then
		local r = result.reward
		if r and r.type == "crate" then
			if claimText then claimText.Text = "📦 " .. (r.name or "Crate") .. "!" end
		elseif r and r.type == "skin" then
			if claimText then claimText.Text = "⚔️ " .. (r.name or "Skin") .. "!" end
		elseif r and r.jackpot then
			if claimText then claimText.Text = "🎉 JACKPOT! +" .. (r.amount or 0) .. " Gold!" end
		else
			if claimText then claimText.Text = "+" .. (r and r.amount or 0) .. " Gold!" end
		end
		task.wait(1.8)
		fetchAndRefresh()
	else
		local reason = (result and result.reason) or "error"
		if claimText then claimText.Text = tostring(reason) end
		claimLocked = false
		task.wait(2)
		fetchAndRefresh()
	end
end)

upgradeBtn.MouseButton1Click:Connect(function()
	if upgradeLocked or not SupplyDropRF then return end
	upgradeLocked = true

	if upgradeText then upgradeText.Text = "..." end

	local ok, result = pcall(function() return SupplyDropRF:InvokeServer("Upgrade") end)
	if ok and result and result.success then
		if upgradeText then upgradeText.Text = (result.newTierName or ("Tier " .. result.newTier)) .. "!" end
		task.wait(1.8)
		fetchAndRefresh()
	else
		local reason = (result and result.reason) or "error"
		if upgradeText then upgradeText.Text = tostring(reason) end
		upgradeLocked = false
		task.wait(2)
		fetchAndRefresh()
	end
end)

-- ── OPEN / CLOSE ──────────────────────────────────────────────────────────
local function openGui()
	screenGui.Enabled    = true
	_G.UIMouseEnabler    = true  -- tells FirstPersonForcer to unlock the mouse
	UserInputService.MouseBehavior    = Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = true
	fetchAndRefresh()
end

local function closeGui()
	if countdownConn then countdownConn:Disconnect(); countdownConn = nil end
	screenGui.Enabled = false
	_G.UIMouseEnabler  = false
end

-- Expose global so FirstPersonForcer can close us with Q
_G.MatrixSupplyDrop = {
	Open    = openGui,
	Close   = closeGui,
	IsOpen  = function() return screenGui.Enabled end,
}

-- Close on Escape
UserInputService.InputBegan:Connect(function(input, gameHandled)
	if gameHandled then return end
	if screenGui.Enabled and input.KeyCode == Enum.KeyCode.Escape then
		closeGui()
	end
end)

-- ── PROXIMITY PROMPT HOOKUP ────────────────────────────────────────────────
local function isInsideRubyModel(instance)
	local cur = instance.Parent
	while cur and cur ~= workspace do
		if string.find(cur.Name:lower(), "ruby") then return true end
		cur = cur.Parent
	end
	return false
end

local function hookPrompt(pp)
	pp.Triggered:Connect(function()
		if not screenGui.Enabled then
			openGui()
		end
	end)
end

local hooked = {}

local function tryHookAllPrompts()
	for _, desc in ipairs(workspace:GetDescendants()) do
		if desc:IsA("ProximityPrompt") and not hooked[desc] and isInsideRubyModel(desc) then
			hooked[desc] = true
			hookPrompt(desc)
		end
	end
end

task.spawn(function()
	task.wait(2)
	tryHookAllPrompts()

	workspace.DescendantAdded:Connect(function(desc)
		if desc:IsA("ProximityPrompt") and not hooked[desc] and isInsideRubyModel(desc) then
			hooked[desc] = true
			hookPrompt(desc)
		end
	end)
end)
