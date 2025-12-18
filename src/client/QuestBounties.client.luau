-- QuestBounties.client.lua: Find bounties tab and UI
-- MERGED INTO QUESTCORE.CLIENT.LUA
return -- Exit immediately
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
local function addMiniObjectiveBars(row, objectives, progress, theme)
	local container = Instance.new("Frame")
	container.BackgroundTransparency = 1
	container.Size = UDim2.new(1,-120,0, 22 * #objectives)
	container.Position = UDim2.new(0,10,1, -(26 + 22*#objectives))
	container.Parent = row

	local barColor = theme.glow or BRIGHT_GREEN
	local textColor = theme.glow or DIM_GREEN

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
		label.TextColor3 = textColor
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
		fill.BackgroundColor3 = barColor
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
		txt.TextColor3 = barColor
		txt.Text = string.format("%d/%d", cur, obj.count or 0)
		txt.Parent = line
	end
end

-- Render available bounties in Find tab
local function renderFind(state)
	clearChildren(findListScroll, true)
	
	print("QuestBounties: renderFind called. Bounties count: " .. #(state.bounties or {}))

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
		local rarity = (q.rarity or "common"):lower()
		local theme = MatrixQuest.bountyTiers[rarity] or MatrixQuest.bountyTiers.common
		
		-- Custom Row Creation for Theming
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -10, 0, 110)
		row.BackgroundColor3 = theme.strokeAlt and C3(255, 255, 255) or C3(10, 12, 15)
		row.BorderSizePixel = 0
		row.Parent = findListScroll
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 12)

		-- Stroke & Gradient
		local stroke = Instance.new("UIStroke", row)
		stroke.Thickness = 2
		stroke.Color = theme.glow
		
		local strokeGrad = Instance.new("UIGradient")
		strokeGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, theme.glow),
			ColorSequenceKeypoint.new(0.5, theme.strokeAlt or theme.color),
			ColorSequenceKeypoint.new(1, theme.glow)
		})
		strokeGrad.Rotation = 45
		strokeGrad.Parent = stroke

		-- Background Gradient
		local bgGrad = Instance.new("UIGradient")
		bgGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, theme.color),
			ColorSequenceKeypoint.new(1, theme.strokeAlt or C3(10, 12, 15))
		})
		bgGrad.Rotation = 45
		bgGrad.Transparency = NumberSequence.new(0.85)
		bgGrad.Parent = row

		-- Title
		local title = Instance.new("TextLabel")
		title.BackgroundTransparency = 1
		title.Size = UDim2.new(1, -20, 0, 24)
		title.Position = UDim2.new(0, 10, 0, 8)
		title.Font = FONT_HEADING
		title.TextSize = 18
		title.TextColor3 = theme.glow
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Text = string.upper(q.name) .. " [" .. theme.name .. "]"
		title.Parent = row

		-- Description
		local desc = Instance.new("TextLabel")
		desc.BackgroundTransparency = 1
		desc.Size = UDim2.new(1, -20, 0, 36)
		desc.Position = UDim2.new(0, 10, 0, 32)
		desc.Font = FONT_TEXT
		desc.TextSize = 14
		desc.TextColor3 = C3(200, 200, 200)
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.TextYAlignment = Enum.TextYAlignment.Top
		desc.TextWrapped = true
		desc.Text = q.desc
		desc.Parent = row

		-- Accept Button
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.fromOffset(100, 30)
		btn.Position = UDim2.new(1, -110, 0, 10)
		btn.BackgroundColor3 = C3(20, 30, 25)
		btn.Font = FONT_HEADING
		btn.TextSize = 14
		btn.TextColor3 = theme.glow
		btn.Text = "ACCEPT"
		btn.Parent = row
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
		
		local btnStroke = Instance.new("UIStroke", btn)
		btnStroke.Color = theme.glow
		btnStroke.Thickness = 1.5
		btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

		addMiniObjectiveBars(row, q.objectives or {}, nil, theme)

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
		rlabel.TextColor3 = theme.glow
		rlabel.Text = "Reward: "..((#parts>0) and table.concat(parts, " + ") or "None")
		rlabel.Parent = row

		-- Timer
		if o.expiresAt and state.now > 0 then
			local tl = Instance.new("TextLabel")
			tl.BackgroundTransparency = 1
			tl.Size = UDim2.new(0,140,0,16)
			tl.Position = UDim2.new(0,10,0,94)
			tl.Font = FONT_TEXT
			tl.TextXAlignment = Enum.TextXAlignment.Left
			tl.TextSize = 12
			tl.TextColor3 = theme.glow
			tl.Text = "Offer: --"
			tl.Parent = row
			trackCountdown(tl, o.expiresAt, "Offer")
		end

		btn.MouseButton1Click:Connect(function()
			-- Force update RF directly to ensure we have it
			local RS = game:GetService("ReplicatedStorage")
			RF = RS:FindFirstChild("QuestRF")
			
			if RF then
				local ok, res = pcall(function() 
					return RF:InvokeServer("accept", {kind="bounty", offerId=o.offerId}) 
				end)
				if ok and res and res.ok then
					-- Show success feedback
					local originalColor = btn.BackgroundColor3
					local originalText = btn.Text
					btn.BackgroundColor3 = theme.color
					btn.Text = "ACCEPTED!"
					task.delay(1, function()
						if btn and btn.Parent then
							btn.BackgroundColor3 = originalColor
							btn.Text = originalText
						end
					end)
				end
			end
			task.delay(0.5, function()
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
	local RS = game:GetService("ReplicatedStorage")
	RF = RS and RS:FindFirstChild("QuestRF")
end

-- Update the watermark timestamp
if MatrixQuest.watermark then
	MatrixQuest.watermark.Text = "VAULT ACCESS: 2025-08-19 00:49:48 (almoe930-dotcom)"
end

print("QuestBounties initialized!")