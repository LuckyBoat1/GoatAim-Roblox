-- QuestLog.client.lua: Mission log UI and bounty strip rendering
-- Part 3 of 4 for the Matrix Quest System

-- Wait for QuestCore to initialize
while not _G.MatrixQuest do
	task.wait(0.1)
end

local MatrixQuest = _G.MatrixQuest

-- Pull in required variables from MatrixQuest global
local tabLog = MatrixQuest.tabLog
local C3 = MatrixQuest.C3
local clearChildren = MatrixQuest.clearChildren
local FONT_HEADING = MatrixQuest.FONT_HEADING
local FONT_TEXT = MatrixQuest.FONT_TEXT
local GREEN = MatrixQuest.GREEN
local BRIGHT_GREEN = MatrixQuest.BRIGHT_GREEN
local _DIM_GREEN = MatrixQuest.DIM_GREEN
local CORNER_RADIUS_MEDIUM = MatrixQuest.CORNER_RADIUS_MEDIUM
local trackCountdown = MatrixQuest.trackCountdown
local DateString = MatrixQuest.DateString
local tryHookRemotes = MatrixQuest.tryHookRemotes

local RF -- Will be assigned from tryHookRemotes

-- Mission Log
local logScroll = Instance.new("ScrollingFrame")
logScroll.Size = UDim2.new(1,-10,1,-10)
logScroll.Position = UDim2.new(0,5,0,5)
logScroll.BackgroundTransparency = 1
logScroll.ScrollBarThickness = 6
logScroll.ScrollBarImageColor3 = GREEN
logScroll.Parent = tabLog

local logLayout = Instance.new("UIListLayout")
logLayout.Padding = UDim.new(0,10)
logLayout.Parent = logScroll

logLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	logScroll.CanvasSize = UDim2.new(0,0,0, logLayout.AbsoluteContentSize.Y + 10)
end)

-- Render mission log
local function renderLog(state)
	clearChildren(logScroll, true)

	if #(state.log or {}) == 0 then
		local placeholder = Instance.new("TextLabel")
		placeholder.BackgroundTransparency = 1
		placeholder.Size = UDim2.new(1, -10, 0, 40)
		placeholder.Position = UDim2.new(0, 5, 0, 6)
		placeholder.Font = FONT_HEADING
		placeholder.TextSize = 18
		placeholder.TextColor3 = BRIGHT_GREEN
		placeholder.TextXAlignment = Enum.TextXAlignment.Center
		placeholder.Text = "No completed missions in log yet."
		placeholder.Parent = logScroll
		return
	end

	for _, entry in ipairs(state.log or {}) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1,0,0,68)
		row.BackgroundColor3 = C3(10,14,12)
		row.BackgroundTransparency = 0
		row.Parent = logScroll
		Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)
		local stx = Instance.new("UIStroke", row)
		stx.Color = GREEN
		stx.Transparency = 0.35
		stx.Thickness = 1

		-- Type icon
		local icon = Instance.new("ImageLabel")
		icon.Size = UDim2.fromOffset(32, 32)
		icon.Position = UDim2.new(0, 12, 0, 18)
		icon.BackgroundTransparency = 1
		icon.Image = entry.kind == "bounty" and "rbxassetid://8566295173" or "rbxassetid://8566089991" -- Trophy or medal
		icon.ImageColor3 = entry.kind == "bounty" and C3(255,210,120) or C3(120,210,255)
		icon.Parent = row

		local name = Instance.new("TextLabel")
		name.BackgroundTransparency = 1
		name.Size = UDim2.new(1, -64, 0, 20)
		name.Position = UDim2.new(0, 54, 0, 8)
		name.Font = FONT_HEADING
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.TextSize = 16
		name.TextColor3 = BRIGHT_GREEN
		name.Text = (entry.kind == "bounty" and "[Bounty] " or "[Mission] ")..(entry.name or "")
		name.Parent = row

		local dateLabel = Instance.new("TextLabel")
		dateLabel.BackgroundTransparency = 1
		dateLabel.Size = UDim2.new(0, 250, 0, 18)
		dateLabel.Position = UDim2.new(0, 54, 0, 30)
		dateLabel.Font = FONT_TEXT
		dateLabel.TextXAlignment = Enum.TextXAlignment.Left
		dateLabel.TextSize = 12
		dateLabel.TextColor3 = C3(180, 190, 170)
		dateLabel.Text = "Completed: " .. DateString(entry.at)
		dateLabel.Parent = row

		-- Reward section
		local reward = entry.reward or {}
		local rewardText = ""

		if (reward.money or 0) > 0 then rewardText = rewardText .. ("$%d"):format(reward.money) end
		if (reward.coin or 0) > 0 then
			if rewardText ~= "" then rewardText = rewardText .. " + " end
			rewardText = rewardText .. ("T%d"):format(reward.coin)
		end
		if reward.boxTier and (reward.boxCount or 0) > 0 then
			if rewardText ~= "" then rewardText = rewardText .. " + " end
			rewardText = rewardText .. ("%s x%d"):format(reward.boxTier, reward.boxCount or 1)
		end

		if rewardText ~= "" then
			local rewardLabel = Instance.new("TextLabel")
			rewardLabel.BackgroundTransparency = 1
			rewardLabel.Size = UDim2.new(0, 300, 0, 18)
			rewardLabel.Position = UDim2.new(0, 54, 0, 48)
			rewardLabel.Font = FONT_TEXT
			rewardLabel.TextXAlignment = Enum.TextXAlignment.Left
			rewardLabel.TextSize = 12
			rewardLabel.TextColor3 = C3(200, 240, 180)
			rewardLabel.Text = "Reward: " .. rewardText
			rewardLabel.Parent = row
		end

		-- Show drops if any
		if entry.drops and #entry.drops > 0 then
			local dropsLabel = Instance.new("TextLabel")
			dropsLabel.BackgroundTransparency = 1
			dropsLabel.Size = UDim2.new(1, -64, 0, 18)
			dropsLabel.Position = UDim2.new(0, 300, 0, 48)
			dropsLabel.Font = FONT_TEXT
			dropsLabel.TextXAlignment = Enum.TextXAlignment.Left
			dropsLabel.TextSize = 12
			dropsLabel.TextColor3 = C3(255, 220, 150)

			local dropTexts = {}
			for _, d in ipairs(entry.drops) do
				table.insert(dropTexts, ("%s[%s]%s"):format(
					d.skinId, 
					d.rarity or "common", 
					d.dupe and " (dupe)" or ""
					))
			end

			dropsLabel.Text = "Drops: " .. table.concat(dropTexts, ", ")
			dropsLabel.Parent = row
		end
	end
end

-- Register render functions with MatrixQuest
MatrixQuest.renderLog = renderLog

-- Update RF reference when tryHookRemotes is called
local originalTryHookRemotes = MatrixQuest.tryHookRemotes
MatrixQuest.tryHookRemotes = function()
	originalTryHookRemotes()
	local RS = game:GetService("ReplicatedStorage")
	RF = RS and RS:FindFirstChild("QuestRF")
end

-- Update the watermark timestamp
if MatrixQuest.watermark then
	MatrixQuest.watermark.Text = "VAULT ACCESS: 2025-08-19 00:47:46 (almoe930-dotcom)"
end

print("QuestLog initialized!")