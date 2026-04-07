--[[
StatsDisplay.client.luau
Finds the Stats ScreenGui, updates all TextLabels by mapping
parent-frame names to stat values, and adds a gentle float bob
by wrapping everything in a container Frame.
Self-healing: re-searches every 0.5s if labels lost.
]]

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ── REMOTE (async — never blocks the script) ─────────────────────────────
local GetPlayerDataRF = nil   -- filled in by the task below

-- ── DATA CACHE ────────────────────────────────────────────────────────────
local cache = {
	Gold        = 0,
	TrumpCoins  = 0,
	ArenaWins   = 0,
	ArenaLoses  = 0,
	AbyssKill   = 0,
	AbyssDeath  = 0,
}

task.spawn(function()
	-- Resolve the remote without blocking the main thread
	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 30)
	if remoteEvents then
		GetPlayerDataRF = remoteEvents:WaitForChild("GetPlayerData", 30)
		if GetPlayerDataRF then
			print("[StatsDisplay] GetPlayerData remote found!")
		else
			warn("[StatsDisplay] GetPlayerData not found — listing RemoteEvents:")
			for _, c in remoteEvents:GetChildren() do
				print("  " .. c.ClassName .. ' "' .. c.Name .. '"')
			end
		end
	else
		warn("[StatsDisplay] RemoteEvents folder not found after 30s")
	end

	-- Poll for data once remote is available
	while true do
		if GetPlayerDataRF then
			task.spawn(function()
				local ok, data = pcall(function()
					return GetPlayerDataRF:InvokeServer()
				end)
				if ok and data then
					cache.Gold       = data.money     or data.gold    or 0
					cache.TrumpCoins = data.trumpCoin  or data.coins   or 0
					cache.ArenaWins  = data.wins       or 0
					cache.ArenaLoses = data.losses     or 0
					cache.AbyssKill  = data.battles    or data.kills   or 0
					cache.AbyssDeath = data.death      or data.deaths  or 0
				end
			end)
		end
		task.wait(2)
	end
end)

-- ── FORMAT ────────────────────────────────────────────────────────────────
local function fmt(n)
n = math.floor(n or 0)
if n >= 1e6 then return string.format("%.1fM", n / 1e6):gsub("%.0M", "M") end
if n >= 1e3 then return string.format("%.1fK", n / 1e3):gsub("%.0K", "K") end
local s = tostring(n)
return s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

-- ── LABEL MAPPING ─────────────────────────────────────────────────────────
-- Maps possible parent-frame names (lowercase) → which cache key to use
-- Also handles text-value functions for combined stats like W/L
local LABEL_MAP = {
gold        = function() return fmt(cache.Gold)       end,
trumpcoin   = function() return fmt(cache.TrumpCoins) end,
trumpcoins  = function() return fmt(cache.TrumpCoins) end,
coins       = function() return fmt(cache.TrumpCoins) end,
["w/l"]     = function() return fmt(cache.ArenaWins) .. " / " .. fmt(cache.ArenaLoses) end,
wl          = function() return fmt(cache.ArenaWins) .. " / " .. fmt(cache.ArenaLoses) end,
arenawins   = function() return fmt(cache.ArenaWins)  end,
arenaloses  = function() return fmt(cache.ArenaLoses) end,
kills       = function() return fmt(cache.AbyssKill)  end,
abysskill   = function() return fmt(cache.AbyssKill)  end,
deaths      = function() return fmt(cache.AbyssDeath) end,
abyssdeath  = function() return fmt(cache.AbyssDeath) end,
}

local function getUpdater(frameName)
return LABEL_MAP[frameName:lower()]
end

-- ── STYLE APPLICATION (from backup — idempotent, checks attribute + gradient) ───────
local function hasGradient(label)
	return label:FindFirstChildOfClass("UIGradient") ~= nil
end

local function applyGradient(label, colorSeq, maxSize)
	if not label or not label.Parent then return end
	if label:GetAttribute("StatsEffectsDone") and hasGradient(label) then return end
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	if not label:FindFirstChildOfClass("UITextSizeConstraint") then
		local c = Instance.new("UITextSizeConstraint")
		c.MaxTextSize = maxSize or 32
		c.Parent = label
	end
	for _, g in label:GetChildren() do
		if g:IsA("UIGradient") then g:Destroy() end
	end
	local grad = Instance.new("UIGradient")
	grad.Rotation = 45
	grad.Color = colorSeq
	grad.Parent = label
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
	local grad = Instance.new("UIGradient")
	grad.Rotation = 45
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0,   Color3.fromRGB(33,  150, 243)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1,   Color3.fromRGB(244, 67,  54)),
	})
	grad.Parent = label
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
	local grad = Instance.new("UIGradient")
	grad.Rotation = 45
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(33,  150, 243)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(110, 227, 255)),
	})
	grad.Parent = label
	label:SetAttribute("StatsEffectsDone", true)
end

local function applyDeathsStyle(label)
	if not label or not label.Parent then return end
	if label:GetAttribute("StatsEffectsDone") then return end
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

-- Maps frame name (lowercase) → style function
local STYLE_MAP = {
	gold       = function(l) applyGradient(l, ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 193, 7)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 84)),
	}), 32) end,
	coins      = function(l) applyGradient(l, ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(76,  175, 80)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(153, 252, 157)),
	}), 32) end,
	trumpcoin  = function(l) applyGradient(l, ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(76,  175, 80)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(153, 252, 157)),
	}), 32) end,
	trumpcoins = function(l) applyGradient(l, ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(76,  175, 80)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(153, 252, 157)),
	}), 32) end,
	["w/l"]    = applyWLStyle,
	wl         = applyWLStyle,
	arenawins  = applyWLStyle,
	arenaloses = applyWLStyle,
	kills      = applyKillsStyle,
	abysskill  = applyKillsStyle,
	deaths     = applyDeathsStyle,
	abyssdeath = applyDeathsStyle,
}
-- Returns array of { updater=fn, label=TextLabel, name=string }
local function findLabelEntries(statsGui)
local entries = {}
-- Walk every Frame/ImageLabel/etc that is a descendant
for _, frame in statsGui:GetDescendants() do
if frame:IsA("Frame") or frame:IsA("ImageLabel") then
local updater = getUpdater(frame.Name)
if updater then
-- Find first TextLabel inside this frame
for _, child in frame:GetDescendants() do
if child:IsA("TextLabel") then
table.insert(entries, {
updater = updater,
label   = child,
name    = frame.Name,
})
break
end
end
end
end
end
return entries
end

-- ── FIND THE STATS GUI ────────────────────────────────────────────────────
local function findStatsGui()
	-- Accept any ScreenGui whose name contains "stats" (case-insensitive)
	for _, gui in playerGui:GetChildren() do
		if gui:IsA("ScreenGui") and gui.Name:lower():find("stats") then
			return gui
		end
	end
	return nil
end

-- ── UNCONDITIONAL STARTUP DUMP ────────────────────────────────────────────
task.defer(function()
	task.wait(4) -- wait for GUIs to fully load
	print("[StatsDisplay] === STARTUP DUMP ===")
	print("[StatsDisplay] All PlayerGui children:")
	for _, gui in playerGui:GetChildren() do
		print("  " .. gui.ClassName .. ' "' .. gui.Name .. '"')
		if gui.Name:lower():find("stats") then
			print("  >> FOUND STATS GUI, dumping descendants:")
			for _, d in gui:GetDescendants() do
				if d:IsA("TextLabel") or d:IsA("Frame") or d:IsA("ImageLabel") then
					print("    " .. d.ClassName .. ' "' .. d.Name .. '"  parent="' .. d.Parent.Name .. '"')
				end
			end
		end
	end
	print("[StatsDisplay] === END DUMP ===")
end)

-- ── BOB SETUP ─────────────────────────────────────────────────────────────
-- Wraps all top-level children of the Stats ScreenGui into a single Frame
-- so we can animate its Position for a float effect.
local BOB_SPEED = 1.4
local BOB_AMP   = 0.025   -- fraction of screen height (~27px on 1080p)

local function setupBob(statsGui)
local existing = statsGui:FindFirstChild("_BobContainer")
if existing then return existing end

-- Create container that fills the ScreenGui
local container = Instance.new("Frame")
container.Name                   = "_BobContainer"
container.Size                   = UDim2.fromScale(1, 1)
container.Position               = UDim2.fromScale(0, 0)
container.BackgroundTransparency = 1
container.ZIndex                 = 1
container.Parent                 = statsGui

-- Re-parent all existing children into the container
for _, child in statsGui:GetChildren() do
if child ~= container then
child.Parent = container
end
end

return container
end

-- ── MAIN ──────────────────────────────────────────────────────────────────
local statsGui     = nil
local entries      = {}
local bobContainer = nil
local bobT         = 0
local lastHeal     = 0

-- Dump the Stats hierarchy once for diagnostics
local function dumpStats(gui)
print("[StatsDisplay] Dumping Stats descendants:")
for _, d in gui:GetDescendants() do
if d:IsA("TextLabel") or d:IsA("Frame") then
print("  " .. d.ClassName .. " name='" .. d.Name .. "'  parent='" .. d.Parent.Name .. "'")
end
end
end

RunService.RenderStepped:Connect(function(dt)
bobT = bobT + dt

-- HEAL CHECK every 0.5s
local now = tick()
if now - lastHeal > 0.5 then
lastHeal = now

-- Find Stats GUI
if not statsGui or not statsGui.Parent then
statsGui     = findStatsGui()
entries      = {}
bobContainer = nil
if statsGui then
print("[StatsDisplay] Found Stats ScreenGui — scanning labels...")
dumpStats(statsGui)
entries      = findLabelEntries(statsGui)
bobContainer = setupBob(statsGui)
print(string.format("[StatsDisplay] Found %d label entries", #entries))
for _, e in entries do
print("  label: '" .. e.name .. "' -> " .. e.label:GetFullName())
end
end
end

-- Re-scan if any labels lost
if statsGui and #entries == 0 then
entries = findLabelEntries(statsGui)
end

-- Update text and apply styles
for _, e in entries do
if e.label and e.label.Parent then
local styleFn = STYLE_MAP[e.name:lower()]
if styleFn then styleFn(e.label) end
e.label.Text = e.updater()
end
end
end

-- Bob animation on container
if bobContainer and bobContainer.Parent then
local yOff = math.sin(bobT * BOB_SPEED) * BOB_AMP
bobContainer.Position = UDim2.new(0, 0, yOff, 0)
end
end)

print("[StatsDisplay] Loaded.")