-- GoldIncome.client.luau
-- Floating "+N" gold numbers that pop up whenever gold is earned.
-- Colors match FlipBookGold: #ffaa00 → #ffff00 warm gold gradient.
-- Sources: passive tick (every 1s), kill/reward lump sums (via _G.addMoney).

local Players    = game:GetService("Players")
local RS         = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris     = game:GetService("Debris")

local player = Players.LocalPlayer
local pg     = player:WaitForChild("PlayerGui")

-- Wait for the RemoteEvent created by PlayerDataManager
local RemoteEvents = RS:WaitForChild("RemoteEvents", 20)
if not RemoteEvents then
	warn("[GoldIncome] RemoteEvents folder not found — exiting")
	return
end

local GoldChangedRE = RemoteEvents:WaitForChild("GoldChanged", 20)
if not GoldChangedRE then
	warn("[GoldIncome] GoldChanged remote not found — exiting")
	return
end

-- ── Overlay ScreenGui ────────────────────────────────────────────────────────
local overlay = Instance.new("ScreenGui")
overlay.Name             = "GoldIncomeOverlay"
overlay.ResetOnSpawn     = false
overlay.DisplayOrder     = 200
overlay.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
overlay.IgnoreGuiInset   = true
overlay.Parent           = pg

-- ── Gold gradient ────────────────────────────────────────────────────────────
-- Same constants as FlipBookGold: ColorFrom={255,170,0}, ColorTo={255,255,0}
local COLOR_FROM = Color3.fromRGB(255, 170, 0)
local COLOR_TO   = Color3.fromRGB(255, 255, 0)

local function goldColor()
	return COLOR_FROM:Lerp(COLOR_TO, math.random())
end

-- ── Find Stats > Gold frame ──────────────────────────────────────────────────
-- Primary: exact match "Stats" > direct child "Gold" (same as FlipBookGold)
-- Fallback: case-insensitive ScreenGui name + descendant search
local cachedTarget = nil

local function findGoldFrame()
	if cachedTarget and cachedTarget.Parent then return cachedTarget end
	-- Primary (matches FlipBookGold exactly)
	for _, gui in ipairs(pg:GetChildren()) do
		if gui.Name == "Stats" then
			local f = gui:FindFirstChild("Gold")
			if f then cachedTarget = f; return f end
		end
	end
	-- Fallback
	for _, gui in ipairs(pg:GetChildren()) do
		if gui:IsA("ScreenGui") and gui.Name:lower():find("stats") then
			for _, desc in ipairs(gui:GetDescendants()) do
				if (desc:IsA("Frame") or desc:IsA("ImageLabel")) and desc.Name:lower() == "gold" then
					cachedTarget = desc; return desc
				end
			end
		end
	end
	return nil
end

-- ── Spawn one floating label ─────────────────────────────────────────────────
-- source: "tick" = passive per-second gold | "reward" = kill/lump sum
local function spawnFloat(amount, source)
	local isReward  = (source == "reward")
	local fontSize  = isReward and 64 or 48
	local floatDist = isReward and 80 or 55
	local lifetime  = isReward and 1.9 or 1.4
	local driftX    = math.random(-20, 20)

	-- Spawn position: below the Gold frame (lower on screen = higher Y in pixels)
	local spawnX, spawnY
	local target = findGoldFrame()
	if target and target.AbsoluteSize.X > 0 then
		local pos = target.AbsolutePosition
		local sz  = target.AbsoluteSize
		spawnX = pos.X + sz.X * 0.5 + math.random(-math.floor(sz.X * 0.3), math.floor(sz.X * 0.3))
		spawnY = pos.Y + sz.Y + 40  -- sit just below the gold bar
	else
		-- Hard fallback: near bottom of screen
		local vp = workspace.CurrentCamera.ViewportSize
		spawnX = vp.X * 0.5
		spawnY = vp.Y * 0.90
	end

	local label = Instance.new("TextLabel")
	label.Name                   = "GoldFloat"
	label.Text                   = "+" .. tostring(amount)
	label.Font                   = Enum.Font.GothamBold
	label.TextSize               = fontSize
	label.TextColor3             = goldColor()
	label.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
	label.TextStrokeTransparency = 0.3
	label.TextTransparency       = 0
	label.BackgroundTransparency = 1
	label.Size                   = UDim2.fromOffset(260, 80)
	label.AnchorPoint            = Vector2.new(0.5, 0.5)
	label.Position               = UDim2.fromOffset(spawnX, spawnY)
	label.ZIndex                 = 12
	label.Parent                 = overlay

	-- Tween: float up + fade out
	TweenService:Create(label, TweenInfo.new(lifetime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position              = UDim2.fromOffset(spawnX + driftX, spawnY - floatDist),
		TextTransparency      = 1,
		TextStrokeTransparency = 1,
	}):Play()

	Debris:AddItem(label, lifetime + 0.05)
end

-- ── Throttle tick events so they don't spam when gold is 0 ───────────────────
GoldChangedRE.OnClientEvent:Connect(function(amount, source)
	if not amount or amount <= 0 then return end
	-- Don't show floating labels for passive per-second income (too spammy)
	if (source or "tick") == "tick" then return end
	spawnFloat(math.round(amount), source or "tick")
end)
