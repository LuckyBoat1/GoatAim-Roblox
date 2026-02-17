--[[
	StatsDisplay - Link player stats to UI TextLabels
	
	Displays: Gold, Coins, W/L, Kills, Deaths
	Links to PlayerDataManager for real-time stat updates
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Get GetPlayerData remote function
local GetPlayerDataRF = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("GetPlayerData")

-- Cache for player data
local playerData = {
	Gold = 0,
	TrumpCoins = 0,
	ArenaWins = 0,
	ArenaLoses = 0,
	AbyssKill = 0,
	AbyssDeath = 0,
}

-- Find the Stats screen GUI
local screenGui = playerGui:WaitForChild("Stats")
local statLabels = {}

-- Find existing TextLabels in the Stats GUI - search more aggressively
local goldLabel
local coinsLabel
local wlLabel
local killsLabel
local deathsLabel

-- Function to find label in frame
local function findLabelInFrame(frameName)
	local frame = screenGui:FindFirstChild(frameName)
	if not frame then return nil end
	-- Get first TextLabel in this frame, no matter how nested
	for _, child in ipairs(frame:GetDescendants()) do
		if child:IsA("TextLabel") then
			return child
		end
	end
	return frame:FindFirstChild("TextLabel")
end

goldLabel = findLabelInFrame("Gold")
coinsLabel = findLabelInFrame("Coins") or findLabelInFrame("TrumpCoins")
wlLabel = findLabelInFrame("W/L")
killsLabel = findLabelInFrame("Kills")
deathsLabel = findLabelInFrame("Deaths")

print("[StatsDisplay] === LABEL SEARCH RESULTS ===")
print("[StatsDisplay] Gold:", goldLabel and goldLabel.Name or "NOT FOUND")
print("[StatsDisplay] Coins:", coinsLabel and coinsLabel.Name or "NOT FOUND")
print("[StatsDisplay] W/L:", wlLabel and wlLabel.Name or "NOT FOUND")
print("[StatsDisplay] Kills:", killsLabel and killsLabel.Name or "NOT FOUND")
print("[StatsDisplay] Deaths:", deathsLabel and deathsLabel.Name or "NOT FOUND")

-- Style all labels: font, color, and double size
local function styleLabel(label, baseColor)
	if label then
		label.Font = Enum.Font.GothamBold
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextScaled = true
		local constraint = label:FindFirstChildOfClass("UITextSizeConstraint") or Instance.new("UITextSizeConstraint")
		constraint.MaxTextSize = 32
		constraint.Parent = label
		
		-- Remove existing gradient if any
		local existingGradient = label:FindFirstChild("UIGradient")
		if existingGradient then existingGradient:Destroy() end
		
		-- Add gradient effect
		local gradient = Instance.new("UIGradient")
		gradient.Rotation = 45
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, baseColor),
			ColorSequenceKeypoint.new(1, Color3.new(
				math.min(baseColor.R + 0.3, 1),
				math.min(baseColor.G + 0.3, 1),
				math.min(baseColor.B + 0.3, 1)
			))
		})
		gradient.Parent = label
	end
end

-- Apply colors: Gold (gold), Coins (green), W/L (blue/red), Kills (blue), Deaths (black)
styleLabel(goldLabel, Color3.fromRGB(255, 193, 7))
styleLabel(coinsLabel, Color3.fromRGB(76, 175, 80))
if wlLabel then
	wlLabel.Font = Enum.Font.GothamBold
	wlLabel.TextScaled = true
	wlLabel.TextColor3 = Color3.new(1, 1, 1)
	local wlConstraint = wlLabel:FindFirstChildOfClass("UITextSizeConstraint") or Instance.new("UITextSizeConstraint")
	wlConstraint.MaxTextSize = 40
	wlConstraint.Parent = wlLabel
	
	-- Remove existing gradient if any
	local existingGradient = wlLabel:FindFirstChild("UIGradient")
	if existingGradient then existingGradient:Destroy() end
	
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 45
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(33, 150, 243)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(244, 67, 54))
	})
	gradient.Parent = wlLabel
end
if killsLabel then
	killsLabel.Font = Enum.Font.GothamBold
	killsLabel.TextColor3 = Color3.new(1, 1, 1)
	killsLabel.TextScaled = true
	local killsConstraint = killsLabel:FindFirstChildOfClass("UITextSizeConstraint") or Instance.new("UITextSizeConstraint")
	killsConstraint.MaxTextSize = 36
	killsConstraint.Parent = killsLabel
	
	-- Remove existing gradient if any
	local existingGradient = killsLabel:FindFirstChild("UIGradient")
	if existingGradient then existingGradient:Destroy() end
	
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 45
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(33, 150, 243)),
		ColorSequenceKeypoint.new(1, Color3.new(
			math.min(0.129 + 0.3, 1),
			math.min(0.588 + 0.3, 1),
			math.min(0.953 + 0.3, 1)
		))
	})
	gradient.Parent = killsLabel
end
if deathsLabel then
	deathsLabel.Font = Enum.Font.GothamBold
	deathsLabel.TextColor3 = Color3.new(1, 1, 1)
	deathsLabel.TextStrokeTransparency = 0
	deathsLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	deathsLabel.TextScaled = true
	local deathsConstraint = deathsLabel:FindFirstChildOfClass("UITextSizeConstraint") or Instance.new("UITextSizeConstraint")
	deathsConstraint.MaxTextSize = 36
	deathsConstraint.Parent = deathsLabel
end

-- Function to refresh player data from server
local function refreshPlayerData()
	task.spawn(function()
		local ok, data = pcall(function()
			return GetPlayerDataRF:InvokeServer()
		end)
		
		if ok and data then
			-- Map server data to display names - use exact field names from server
			playerData.Gold = data.money or 0
			playerData.TrumpCoins = data.trumpCoin or 0  -- Server sends 'trumpCoin' (singular)
			playerData.ArenaWins = data.wins or 0
			playerData.ArenaLoses = data.losses or 0
			playerData.AbyssDeath = data.death or 0
			playerData.AbyssKill = data.battles or 0
			print("[StatsDisplay] Updated data from server - TrumpCoins:", playerData.TrumpCoins, "Gold:", playerData.Gold)
		else
			print("[StatsDisplay] Failed to get player data:", tostring(data))
		end
	end)
end

-- Refresh data every 2 seconds
task.spawn(function()
	while true do
		refreshPlayerData()
		task.wait(2)
	end
end)

-- Get initial data
refreshPlayerData()


-- Format large numbers with commas
local function formatNumber(num)
	local formatted = tostring(num)
	local k = 0
	for i = #formatted - 2, 1, -3 do
		if i > 1 then
			formatted = formatted:sub(1, i) .. "," .. formatted:sub(i + 1)
		end
	end
	return formatted
end

-- Format numbers with K/M notation for Gold and Coins
local function formatCompactNumber(num)
	if num >= 1000000 then
		return string.format("%.1f", num / 1000000):gsub("%.0$", "") .. "M"
	elseif num >= 1000 then
		return string.format("%.1f", num / 1000):gsub("%.0$", "") .. "K"
	else
		return formatNumber(num)
	end
end

local TweenService = game:GetService("TweenService")
local FloatingGui = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("FloatingGui"))

-- Convert Stats GUI into a FloatingGui (3D SurfaceGui for buttery smooth movement)
local statsFloat = FloatingGui.new(screenGui, {
	Speed = 1,       -- snappy follow (we want it locked to camera)
	Distance = 0,
	Angle = 0,
	Offset = Vector2.new(0, 0),
})
--
-- Bob the GUI up and down by oscillating the Y offset
local BOB_SPEED     = 1.8   -- oscillations speed
local BOB_AMPLITUDE = 0.008 -- how far it bobs (fraction of screen height)
local bobStart = tick()

RunService.Heartbeat:Connect(function()
	local t = tick() - bobStart
	local yOff = math.sin(t * BOB_SPEED) * BOB_AMPLITUDE
	statsFloat:Change({
		Offset = Vector2.new(0, yOff)
	})
end)

-- Update stats every frame
RunService.RenderStepped:Connect(function(dt)
	if goldLabel then 
		goldLabel.Text = formatCompactNumber(playerData.Gold)
	else
		print("[StatsDisplay] Warning: goldLabel not found")
	end
	if coinsLabel then 
		coinsLabel.Text = formatCompactNumber(playerData.TrumpCoins)
	else
		print("[StatsDisplay] Warning: coinsLabel not found, TrumpCoins value is:", playerData.TrumpCoins)
	end
	if wlLabel then wlLabel.Text = formatNumber(playerData.ArenaWins) .. " / " .. formatNumber(playerData.ArenaLoses) end
	if killsLabel then killsLabel.Text = formatNumber(playerData.AbyssKill) end
	if deathsLabel then deathsLabel.Text = formatNumber(playerData.AbyssDeath) end
end)

print("[StatsDisplay] Professional stats display loaded!")

