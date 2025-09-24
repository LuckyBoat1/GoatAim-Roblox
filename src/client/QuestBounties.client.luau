-- QuestBounties.client.lua: Find bounties tab and UI
-- Part 4 of 4 for the Matrix Quest System

-- Wait for QuestCore to initialize
while not _G.MatrixQuest do
	task.wait(0.1)
end

local MatrixQuest = _G.MatrixQuest

-- Pull in required variables from MatrixQuest global
local tabFind = MatrixQuest.tabFind
local C3 = MatrixQuest.C3
local TweenService = MatrixQuest.TweenService
local clearChildren = MatrixQuest.clearChildren
local FONT_HEADING = MatrixQuest.FONT_HEADING
local FONT_TEXT = MatrixQuest.FONT_TEXT
local GREEN = MatrixQuest.GREEN
local BRIGHT_GREEN = MatrixQuest.BRIGHT_GREEN
local DIM_GREEN = MatrixQuest.DIM_GREEN
local rowBase = MatrixQuest.rowBase
local trackCountdown = MatrixQuest.trackCountdown
local tryHookRemotes = MatrixQuest.tryHookRemotes

local RF -- Will be assigned from tryHookRemotes

-- Find Bounties Tab UI
local findTop = Instance.new("Frame")
findTop.Size = UDim2.new(1,-10,0,36)
findTop.Position = UDim2.new(0,5,0,5)
findTop.BackgroundTransparency = 1
findTop.Parent = tabFind

local refreshBtn = Instance.new("TextButton")
refreshBtn.Size = UDim2.fromOffset(170,30)
refreshBtn.Position = UDim2.new(1,-180,0,3)
refreshBtn.BackgroundColor3 = C3(20,30,25)
refreshBtn.Text = ""
refreshBtn.Parent = findTop
Instance.new("UICorner", refreshBtn).CornerRadius = UDim.new(0,8)
local rbst = Instance.new("UIStroke", refreshBtn)
rbst.Color = GREEN
rbst.Thickness = 2
rbst.Transparency = 0.3

local refreshIcon = Instance.new("ImageLabel")
refreshIcon.Size = UDim2.fromOffset(18, 18)
refreshIcon.Position = UDim2.new(0, 12, 0.5, 0)
refreshIcon.AnchorPoint = Vector2.new(0, 0.5)
refreshIcon.BackgroundTransparency = 1
refreshIcon.Image = "rbxassetid://8337535591" -- Refresh icon
refreshIcon.ImageColor3 = BRIGHT_GREEN
refreshIcon.Parent = refreshBtn

local refreshText = Instance.new("TextLabel")
refreshText.BackgroundTransparency = 1
refreshText.Size = UDim2.new(1, -40, 1, 0)
refreshText.Position = UDim2.new(0, 36, 0, 0)
refreshText.Font = FONT_HEADING
refreshText.TextSize = 16
refreshText.TextColor3 = BRIGHT_GREEN
refreshText.Text = "Refresh Bounties"
refreshText.TextXAlignment = Enum.TextXAlignment.Left
refreshText.Parent = refreshBtn

local findListScroll = Instance.new("ScrollingFrame")
findListScroll.Size = UDim2.new(1,-10,1,-46)
findListScroll.Position = UDim2.new(0,5,0,46)
findListScroll.BackgroundTransparency = 1
findListScroll.ScrollBarThickness = 6
findListScroll.ScrollBarImageColor3 = GREEN
findListScroll.Parent = tabFind

local findLayout = Instance.new("UIListLayout")
findLayout.Padding = UDim.new(0,10)
findLayout.Parent = findListScroll

findLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	findListScroll.CanvasSize = UDim2.new(0,0,0, findLayout.AbsoluteContentSize.Y + 10)
end)

-- Create objective bars for bounty UI
local function addMiniObjectiveBars(row, objectives, progress)
	local container = Instance.new("Frame")
	container.BackgroundTransparency = 1
	container.Size = UDim2.new(1,-120,0, 22 * #objectives)
	container.Position = UDim2.new(0,10,1, -(26 + 22*#objectives))
	container.Parent = row

	for i,obj in ipairs(objectives) do
		local line = Instance.new("Frame")
		line.BackgroundTransparency = 1
		line.Size = UDim2.new(1,0,0,18)
		line.Position = UDim2.new(0,0,0,(i-1)*22)
		line.Parent = container

		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.new(0.42,-6,1,0)
		label.Position = UDim2.new(0,0,0,0)
		label.Font = FONT_TEXT
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextSize = 12
		label.TextColor3 = DIM_GREEN
		label.Text = obj.key
		label.Parent = line

		local bar = Instance.new("Frame")
		bar.Size = UDim2.new(0.58,0,0,8)
		bar.Position = UDim2.new(0.42,6,0.5,-4)
		bar.BackgroundColor3 = C3(6,9,8)
		bar.Parent = line
		Instance.new("UICorner", bar).CornerRadius = UDim.new(0,4)

		local fill = Instance.new("Frame")
		fill.Size = UDim2.new(0,0,1,0)
		fill.BackgroundColor3 = BRIGHT_GREEN
		fill.Parent = bar
		Instance.new("UICorner", fill).CornerRadius = UDim.new(0,4)

		local cur = (progress and progress[obj.key]) or 0
		local ratio = math.clamp(cur/(obj.count or 1), 0, 1)
		fill.Size = UDim2.new(ratio, 0, 1, 0)

		local txt = Instance.new("TextLabel")
		txt.BackgroundTransparency = 1
		txt.Size = UDim2.new(0,70,1,0)
		txt.Position = UDim2.new(1,6,0,0)
		txt.Font = FONT_TEXT
		txt.TextSize = 12
		txt.TextXAlignment = Enum.TextXAlignment.Left
		txt.TextColor3 = BRIGHT_GREEN
		txt.Text = string.format("%d/%d", cur, obj.count or 0)
		txt.Parent = line
	end
end

-- Render available bounties in Find tab
local function renderFind(state)
	clearChildren(findListScroll, true)

	if #(state.bounties or {}) == 0 then
		local placeholder = Instance.new("TextLabel")
		placeholder.BackgroundTransparency = 1
		placeholder.Size = UDim2.new(1, -10, 0, 40)
		placeholder.Position = UDim2.new(0, 5, 0, 6)
		placeholder.Font = FONT_HEADING
		placeholder.TextSize = 18
		placeholder.TextColor3 = BRIGHT_GREEN
		placeholder.TextXAlignment = Enum.TextXAlignment.Center
		placeholder.Text = "No bounties available. Try refreshing."
		placeholder.Parent = findListScroll
		return
	end

	for _, o in ipairs(state.bounties or {}) do
		local q = o.quest
		local row, btn = rowBase(findListScroll, q.name, q.desc, q.rarity, "Accept")
		addMiniObjectiveBars(row, q.objectives or {}, nil)

		-- Reward chip
		local reward = q.reward or {}
		local parts = {}
		if (reward.money or 0) > 0 then table.insert(parts, ("$%d"):format(reward.money)) end
		if (reward.coin or 0) > 0 then table.insert(parts, ("T%d"):format(reward.coin)) end
		if reward.boxTier and (reward.boxCount or 0) > 0 then table.insert(parts, ("%s x%d"):format(reward.boxTier, reward.boxCount or 1)) end

		local rlabel = Instance.new("TextLabel")
		rlabel.BackgroundTransparency = 1
		rlabel.Size = UDim2.fromOffset(220,16)
		rlabel.Position = UDim2.new(1,-230,0,50)
		rlabel.Font = FONT_HEADING
		rlabel.TextXAlignment = Enum.TextXAlignment.Right
		rlabel.TextSize = 12
		rlabel.TextColor3 = BRIGHT_GREEN
		rlabel.Text = "Reward: "..((#parts>0) and table.concat(parts, " + ") or "None")
		rlabel.Parent = row

		-- Timer
		if o.expiresAt and MatrixQuest.serverNowAtRender > 0 then
			local tl = Instance.new("TextLabel")
			tl.BackgroundTransparency = 1
			tl.Size = UDim2.new(0,140,0,16)
			tl.Position = UDim2.new(0,10,0,94)
			tl.Font = FONT_TEXT
			tl.TextXAlignment = Enum.TextXAlignment.Left
			tl.TextSize = 12
			tl.TextColor3 = BRIGHT_GREEN
			tl.Text = "Offer: --"
			tl.Parent = row
			trackCountdown(tl, o.expiresAt, "Offer")
		end

		btn.MouseButton1Click:Connect(function()
			tryHookRemotes()
			if RF then
				local ok, res = pcall(function() 
					return RF:InvokeServer("accept", {kind="bounty", offerId=o.offerId}) 
				end)
				if ok and res and res.ok then
					-- Show success feedback
					local originalColor = btn.BackgroundColor3
					local originalText = btn.Text
					btn.BackgroundColor3 = C3(20, 80, 40)
					btn.Text = "ACCEPTED!"
					task.delay(1, function()
						if btn and btn.Parent then
							btn.BackgroundColor3 = originalColor
							btn.Text = originalText
						end
					end)
				end
			end
			task.delay(0.2, function()
				if MatrixQuest.render then
					MatrixQuest.render()
				end
			end)
		end)
	end
end

-- Register render function with MatrixQuest
MatrixQuest.renderFind = renderFind

-- Refresh button click handler
refreshBtn.MouseButton1Click:Connect(function()
	tryHookRemotes()

	-- Show refresh animation regardless of remote existence
	local rotInfo = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	TweenService:Create(refreshIcon, rotInfo, {Rotation = 360}):Play()

	-- Attempt to reroll bounties
	if RF then 
		pcall(function() RF:InvokeServer("reroll") end)
	end

	-- Reset rotation and refresh UI after animation
	task.delay(0.4, function() 
		refreshIcon.Rotation = 0
		if MatrixQuest.render then
			MatrixQuest.render()
		end
	end)
end)

-- Update RF reference when tryHookRemotes is called
local originalTryHookRemotes = MatrixQuest.tryHookRemotes
MatrixQuest.tryHookRemotes = function()
	originalTryHookRemotes()
	RF = _G.RS and _G.RS:FindFirstChild("QuestRF")
end

-- Update the watermark timestamp
if MatrixQuest.watermark then
	MatrixQuest.watermark.Text = "VAULT ACCESS: 2025-08-19 00:49:48 (almoe930-dotcom)"
end

print("QuestBounties initialized!")