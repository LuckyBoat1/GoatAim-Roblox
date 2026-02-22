--[[
	StatsDisplay - Self-healing stats display
	
	No init/re-init pattern. Every 0.5 seconds we check:
	1. Is there a Stats ScreenGui that needs FloatingGui wrapping?
	2. Do all labels exist and have their effects (gradients, fonts)?
	3. If anything is missing, fix it immediately.
	
	Works for ALL players regardless of respawn, PvP, teleport, anything.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GetPlayerDataRF = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("GetPlayerData")
local FloatingGui = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("FloatingGui"))

--------------------------------------------------------------------------
-- DATA CACHE
--------------------------------------------------------------------------
local playerData = {
	Gold = 0,
	TrumpCoins = 0,
	ArenaWins = 0,
	ArenaLoses = 0,
	AbyssKill = 0,
	AbyssDeath = 0,
}

local function refreshPlayerData()
	task.spawn(function()
		local ok, data = pcall(function()
			return GetPlayerDataRF:InvokeServer()
		end)
		if ok and data then
			playerData.Gold = data.money or 0
			playerData.TrumpCoins = data.trumpCoin or 0
			playerData.ArenaWins = data.wins or 0
			playerData.ArenaLoses = data.losses or 0
			playerData.AbyssDeath = data.death or 0
			playerData.AbyssKill = data.battles or 0
		end
	end)
end

task.spawn(function()
	while true do
		refreshPlayerData()
		task.wait(2)
	end
end)

--------------------------------------------------------------------------
-- FORMAT HELPERS
--------------------------------------------------------------------------
local function formatNumber(num)
	local formatted = tostring(num)
	for i = #formatted - 2, 1, -3 do
		if i > 1 then
			formatted = formatted:sub(1, i) .. "," .. formatted:sub(i + 1)
		end
	end
	return formatted
end

local function formatCompactNumber(num)
	if num >= 1000000 then
		return string.format("%.1f", num / 1000000):gsub("%.0$", "") .. "M"
	elseif num >= 1000 then
		return string.format("%.1f", num / 1000):gsub("%.0$", "") .. "K"
	else
		return formatNumber(num)
	end
end

--------------------------------------------------------------------------
-- EFFECT APPLICATION — idempotent, safe to call repeatedly
-- Checks BOTH the marker attribute AND that the gradient child exists.
-- If either is missing, effects are fully re-applied.
--------------------------------------------------------------------------
local function hasGradient(label)
	if not label then return false end
	return label:FindFirstChildOfClass("UIGradient") ~= nil
end

local function applyGradient(label, colorSeq)
	if not label or not label.Parent then return end
	-- Check marker AND gradient presence — if both exist, skip
	if label:GetAttribute("StatsEffectsDone") and hasGradient(label) then return end

	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true

	-- Size constraint
	if not label:FindFirstChildOfClass("UITextSizeConstraint") then
		local c = Instance.new("UITextSizeConstraint")
		c.MaxTextSize = 32
		c.Parent = label
	end

	-- Remove old gradients, add new
	for _, g in label:GetChildren() do
		if g:IsA("UIGradient") then g:Destroy() end
	end
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 45
	gradient.Color = colorSeq
	gradient.Parent = label

	label:SetAttribute("StatsEffectsDone", true)
end

local function applyWLStyle(label)
	if not label or not label.Parent then return end
	if label:GetAttribute("StatsEffectsDone") and hasGradient(label) then return end

	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)

	if not label:FindFirstChildOfClass("UITextSizeConstraint") then
		local c = Instance.new("UITextSizeConstraint")
		c.MaxTextSize = 40
		c.Parent = label
	end

	for _, g in label:GetChildren() do
		if g:IsA("UIGradient") then g:Destroy() end
	end
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 45
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(33, 150, 243)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(244, 67, 54)),
	})
	gradient.Parent = label

	label:SetAttribute("StatsEffectsDone", true)
end

local function applyKillsStyle(label)
	if not label or not label.Parent then return end
	if label:GetAttribute("StatsEffectsDone") and hasGradient(label) then return end

	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true

	if not label:FindFirstChildOfClass("UITextSizeConstraint") then
		local c = Instance.new("UITextSizeConstraint")
		c.MaxTextSize = 36
		c.Parent = label
	end

	for _, g in label:GetChildren() do
		if g:IsA("UIGradient") then g:Destroy() end
	end
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 45
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(33, 150, 243)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(110, 227, 255)),
	})
	gradient.Parent = label

	label:SetAttribute("StatsEffectsDone", true)
end

local function applyDeathsStyle(label)
	if not label or not label.Parent then return end
	if label:GetAttribute("StatsEffectsDone") then return end
	-- Deaths doesn't use gradient, so no hasGradient check needed

	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.TextScaled = true

	if not label:FindFirstChildOfClass("UITextSizeConstraint") then
		local c = Instance.new("UITextSizeConstraint")
		c.MaxTextSize = 36
		c.Parent = label
	end

	label:SetAttribute("StatsEffectsDone", true)
end

--------------------------------------------------------------------------
-- LABEL FINDING — searches ANY Stats container in PlayerGui or workspace
--------------------------------------------------------------------------
local goldLabel, coinsLabel, wlLabel, killsLabel, deathsLabel

local function findLabelIn(container, frameName)
	local frame = container:FindFirstChild(frameName)
	if not frame then return nil end
	for _, child in frame:GetDescendants() do
		if child:IsA("TextLabel") then return child end
	end
	return nil
end

local function findStatsContainer()
	-- Search PlayerGui for any Stats GUI (ScreenGui or SurfaceGui) that has actual stat frames
	for _, gui in playerGui:GetChildren() do
		if gui.Name == "Stats" and (gui:FindFirstChild("Gold") or gui:FindFirstChild("Coins")) then
			return gui
		end
	end
	-- Search FloatingGui Parts in workspace
	for _, obj in workspace:GetChildren() do
		if obj.Name == "FloatingGuiAdornee" and obj:IsA("BasePart") then
			for _, sg in obj:GetChildren() do
				if sg:IsA("SurfaceGui") and sg.Name == "Stats" and (sg:FindFirstChild("Gold") or sg:FindFirstChild("Coins")) then
					return sg
				end
			end
		end
	end
	return nil
end

local function findAllLabels()
	local container = findStatsContainer()
	if not container then return false end

	goldLabel = findLabelIn(container, "Gold")
	coinsLabel = findLabelIn(container, "Coins") or findLabelIn(container, "TrumpCoins")
	wlLabel = findLabelIn(container, "W/L")
	killsLabel = findLabelIn(container, "Kills")
	deathsLabel = findLabelIn(container, "Deaths")
	return goldLabel ~= nil
end

--------------------------------------------------------------------------
-- FLOATING GUI MANAGEMENT
--------------------------------------------------------------------------
local statsFloat = nil

local function cleanupOldFloating(keepScreenGui)
	-- Remove old FloatingGui wrapper
	if statsFloat and not statsFloat.Removed then
		-- Grab reference to old ScreenGui BEFORE Remove restores it to PlayerGui
		local oldSG = statsFloat.ScreenGui
		pcall(function() statsFloat:Remove() end)
		-- Remove() moved old ScreenGui back to PlayerGui — destroy it
		-- so it doesn't get detected as a "fresh" ScreenGui next cycle (ping-pong bug)
		if oldSG and oldSG.Parent and oldSG ~= keepScreenGui then
			oldSG:Destroy()
		end
	end
	statsFloat = nil

	-- Remove stale ScreenGuis in ReplicatedFirst
	for _, obj in game.ReplicatedFirst:GetChildren() do
		if obj:IsA("ScreenGui") and obj.Name == "Stats" then
			obj:Destroy()
		end
	end
	-- Remove orphaned SurfaceGuis named Stats in PlayerGui
	for _, child in playerGui:GetChildren() do
		if child:IsA("SurfaceGui") and child.Name == "Stats" then
			child:Destroy()
		end
	end
	-- Remove ALL leftover Stats ScreenGuis in PlayerGui except the one we're keeping
	for _, child in playerGui:GetChildren() do
		if child:IsA("ScreenGui") and child.Name == "Stats" and child ~= keepScreenGui then
			child:Destroy()
		end
	end
	-- Remove orphaned FloatingGui parts
	for _, obj in workspace:GetChildren() do
		if obj.Name == "FloatingGuiAdornee" and obj:IsA("BasePart") then
			local hasStats = false
			for _, sg in obj:GetChildren() do
				if sg.Name == "Stats" then hasStats = true end
			end
			if hasStats or not obj:FindFirstChildOfClass("SurfaceGui") then
				obj:Destroy()
			end
		end
	end
end

local _debugTimer = 0

local function ensureFloatingGui()
	-- Debug: log the state every 5 seconds
	_debugTimer = _debugTimer + 0.5
	if _debugTimer % 5 < 0.6 then
		local childNames = {}
		for _, gui in playerGui:GetChildren() do
			if gui.Name == "Stats" then
				table.insert(childNames, gui.ClassName .. ":" .. gui.Name .. " Enabled=" .. tostring(gui.Enabled))
			end
		end
		print("[StatsDisplay DEBUG] statsFloat=", statsFloat and (statsFloat.Removed and "REMOVED" or "ACTIVE") or "nil",
			"| Stats children in PlayerGui:", #childNames > 0 and table.concat(childNames, ", ") or "NONE")
	end

	-- If we already have an active FloatingGui, nothing to do
	if statsFloat and not statsFloat.Removed then
		return
	end

	-- Look for an unwrapped Stats ScreenGui in PlayerGui
	for _, gui in playerGui:GetChildren() do
		if gui:IsA("ScreenGui") and gui.Name == "Stats" then
			print("[StatsDisplay] Found fresh Stats ScreenGui, wrapping with FloatingGui...")
			-- Found a fresh ScreenGui — clean up old stuff and wrap it
			-- Pass the gui we want to KEEP so cleanup doesn't destroy it
			cleanupOldFloating(gui)

			statsFloat = FloatingGui.new(gui, {
				Speed = 1,
				Distance = 0,
				Angle = 0,
				Offset = Vector2.new(0, 0),
			})
			print("[StatsDisplay] FloatingGui created for Stats ScreenGui")

			-- Labels moved into SurfaceGui now, re-find them
			findAllLabels()
			return
		end
	end
end

--------------------------------------------------------------------------
-- FORCE RE-APPLY EFFECTS AFTER DUEL ENDS
-- When PvpCountdownEvent fires "FightEnd", clear all effect markers
-- so the next heal cycle re-applies everything fresh.
--------------------------------------------------------------------------
local PvpCountdownEvent = ReplicatedStorage:FindFirstChild("PvpCountdownEvent")
if PvpCountdownEvent then
	PvpCountdownEvent.OnClientEvent:Connect(function(action)
		if action == "FightEnd" or action == "FightStart" then
			-- Clear markers so effects are re-applied
			for _, label in { goldLabel, coinsLabel, wlLabel, killsLabel, deathsLabel } do
				if label and label.Parent then
					label:SetAttribute("StatsEffectsDone", nil)
				end
			end
			-- Also re-find labels in case the container shifted
			task.delay(0.3, function()
				findAllLabels()
				for _, label in { goldLabel, coinsLabel, wlLabel, killsLabel, deathsLabel } do
					if label and label.Parent then
						label:SetAttribute("StatsEffectsDone", nil)
					end
				end
			end)
		end
	end)
end

--------------------------------------------------------------------------
-- MAIN LOOP — self-healing, runs every frame
--------------------------------------------------------------------------
local BOB_SPEED = 1.8
local BOB_AMPLITUDE = 0.008
local bobStart = tick()
local lastHealCheck = 0

RunService.RenderStepped:Connect(function()
	local now = tick()

	-- Every 0.5 seconds: self-healing check
	if now - lastHealCheck > 0.5 then
		lastHealCheck = now

		-- 1) Wrap any fresh Stats ScreenGui in FloatingGui
		ensureFloatingGui()

		-- 2) Re-find labels if stale
		if not goldLabel or not goldLabel.Parent then
			findAllLabels()
		end

		-- 3) Apply effects (skips instantly if already done via attribute check)
		applyGradient(goldLabel, ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 193, 7)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 84)),
		}))
		applyGradient(coinsLabel, ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(76, 175, 80)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(153, 252, 157)),
		}))
		applyWLStyle(wlLabel)
		applyKillsStyle(killsLabel)
		applyDeathsStyle(deathsLabel)
	end
--
	-- Bob animation
	if statsFloat and not statsFloat.Removed then
		local t = now - bobStart
		local yOff = math.sin(t * BOB_SPEED) * BOB_AMPLITUDE
		statsFloat:Change({ Offset = Vector2.new(0, yOff) })
	end

	-- Update text values
	if goldLabel and goldLabel.Parent then
		goldLabel.Text = formatCompactNumber(playerData.Gold)
	end
	if coinsLabel and coinsLabel.Parent then
		coinsLabel.Text = formatCompactNumber(playerData.TrumpCoins)
	end
	if wlLabel and wlLabel.Parent then
		wlLabel.Text = formatNumber(playerData.ArenaWins) .. " / " .. formatNumber(playerData.ArenaLoses)
	end
	if killsLabel and killsLabel.Parent then
		killsLabel.Text = formatNumber(playerData.AbyssKill)
	end
	if deathsLabel and deathsLabel.Parent then
		deathsLabel.Text = formatNumber(playerData.AbyssDeath)
	end
end)

print("[StatsDisplay] Self-healing stats display loaded!")

