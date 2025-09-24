-- PlayerInteractClient.lua
-- Improved player interaction UI (Cyberpunk Neon Theme to match dash)
-- Single LocalScript (client-side). Secure actions must be validated on the server.

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

--// Local Player
local localPlayer = Players.LocalPlayer

--------------------------------------------------
-- CONFIG
--------------------------------------------------
local CONFIG = {
	InteractKey = Enum.KeyCode.M,
	InteractRange = 12,
	CheckInterval = 0.15,        -- seconds between proximity scans
	FadeTime = 0.18,
	MenuButtons = { "Profile", "Trade", "Duel" },
	Theme = {
		Neon = Color3.fromRGB(0,255,0),
		NeonDim = Color3.fromRGB(0,180,0),
		Panel = Color3.fromRGB(0,0,0),
		PanelTransparency = 0.25,
		Button = Color3.fromRGB(10,35,10),
		ButtonHover = Color3.fromRGB(20,60,20),
		Text = Color3.fromRGB(255,255,255)
	},
	Highlight = {
		FillTransparency = 1,
		OutlineTransparency = 0,
		OutlineColor = Color3.fromRGB(0,255,0)
	},
	MenuSize = UDim2.new(0, 260, 0, 230)
}

--------------------------------------------------
-- State
--------------------------------------------------
local currentTarget : Player? = nil
local menuOpen = false
local lastCheck = 0
local character, rootPart, humanoid
local highlight -- Highlight instance for target

--------------------------------------------------
-- Character Handling
--------------------------------------------------
local function bindCharacter()
	character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
	humanoid = character:WaitForChild("Humanoid")
	rootPart = character:WaitForChild("HumanoidRootPart")
end
bindCharacter()
localPlayer.CharacterAdded:Connect(bindCharacter)

--------------------------------------------------
-- UI CREATION
--------------------------------------------------
local playerGui = localPlayer:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "InteractUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Prompt Frame
local promptFrame = Instance.new("Frame")
promptFrame.Size = UDim2.new(0, 240, 0, 60)
promptFrame.Position = UDim2.new(0.5, -120, 0.85, 0)
promptFrame.BackgroundColor3 = CONFIG.Theme.Panel
promptFrame.BackgroundTransparency = CONFIG.Theme.PanelTransparency
promptFrame.BorderSizePixel = 0
promptFrame.Visible = false
promptFrame.Parent = screenGui

local promptCorner = Instance.new("UICorner")
promptCorner.CornerRadius = UDim.new(0, 10)
promptCorner.Parent = promptFrame

local promptStroke = Instance.new("UIStroke")
promptStroke.Thickness = 3
promptStroke.Color = CONFIG.Theme.Neon
promptStroke.Parent = promptFrame

local promptGradient = Instance.new("UIGradient")
promptGradient.Color = ColorSequence.new(
	ColorSequenceKeypoint.new(0, CONFIG.Theme.NeonDim),
	ColorSequenceKeypoint.new(0.5, CONFIG.Theme.Neon),
	ColorSequenceKeypoint.new(1, CONFIG.Theme.NeonDim)
)
promptGradient.Rotation = 0
promptGradient.Parent = promptFrame

local keyBox = Instance.new("Frame")
keyBox.Size = UDim2.new(0, 60, 1, 0)
keyBox.BackgroundColor3 = CONFIG.Theme.NeonDim
keyBox.BackgroundTransparency = 0.15
keyBox.BorderSizePixel = 0
keyBox.Parent = promptFrame

local keyCorner = Instance.new("UICorner")
keyCorner.CornerRadius = UDim.new(0,10)
keyCorner.Parent = keyBox

local keyStroke = Instance.new("UIStroke")
keyStroke.Thickness = 2
keyStroke.Color = CONFIG.Theme.Neon
keyStroke.Parent = keyBox

local keyLabel = Instance.new("TextLabel")
keyLabel.Size = UDim2.new(1,0,1,0)
keyLabel.BackgroundTransparency = 1
keyLabel.Text = (CONFIG.InteractKey.Name):upper()
keyLabel.Font = Enum.Font.GothamBold
keyLabel.TextScaled = true
keyLabel.TextColor3 = CONFIG.Theme.Text
keyLabel.Parent = keyBox

local promptText = Instance.new("TextLabel")
promptText.Size = UDim2.new(1, -70, 1, 0)
promptText.Position = UDim2.new(0, 70, 0, 0)
promptText.BackgroundTransparency = 1
promptText.Font = Enum.Font.GothamBold
promptText.TextScaled = true
promptText.TextWrapped = true
promptText.TextColor3 = CONFIG.Theme.Text
promptText.Text = "Interact"
promptText.Parent = promptFrame

-- Menu Frame
local menuFrame = Instance.new("Frame")
menuFrame.Size = CONFIG.MenuSize
menuFrame.Position = UDim2.new(0.5, -CONFIG.MenuSize.X.Offset/2, 0.5, -CONFIG.MenuSize.Y.Offset/2)
menuFrame.BackgroundColor3 = CONFIG.Theme.Panel
menuFrame.BackgroundTransparency = CONFIG.Theme.PanelTransparency
menuFrame.BorderSizePixel = 0
menuFrame.Visible = false
menuFrame.Parent = screenGui

local menuCorner = Instance.new("UICorner")
menuCorner.CornerRadius = UDim.new(0, 12)
menuCorner.Parent = menuFrame

local menuStroke = Instance.new("UIStroke")
menuStroke.Thickness = 3
menuStroke.Color = CONFIG.Theme.Neon
menuStroke.Parent = menuFrame

local menuGradient = Instance.new("UIGradient")
menuGradient.Color = ColorSequence.new(
	ColorSequenceKeypoint.new(0, CONFIG.Theme.Neon),
	ColorSequenceKeypoint.new(1, CONFIG.Theme.NeonDim)
)
menuGradient.Rotation = 90
menuGradient.Parent = menuFrame

local menuTitle = Instance.new("TextLabel")
menuTitle.Size = UDim2.new(1, -20, 0, 40)
menuTitle.Position = UDim2.new(0,10, 0, 5)
menuTitle.BackgroundTransparency = 1
menuTitle.Font = Enum.Font.GothamBlack
menuTitle.TextScaled = true
menuTitle.TextColor3 = CONFIG.Theme.Neon
menuTitle.Text = "PLAYER MENU"
menuTitle.Parent = menuFrame

local buttonHolder = Instance.new("Frame")
buttonHolder.Size = UDim2.new(1, -20, 1, -55)
buttonHolder.Position = UDim2.new(0,10,0,45)
buttonHolder.BackgroundTransparency = 1
buttonHolder.Parent = menuFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = buttonHolder

local function tween(obj, props, duration, style, direction)
	local info = TweenInfo.new(duration or CONFIG.FadeTime, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out)
	return TweenService:Create(obj, info, props)
end

-- Pulse effect (only active when prompt visible)
local pulseActive = false
local function startPulse()
	if pulseActive then return end
	pulseActive = true
	task.spawn(function()
		while pulseActive do
			tween(promptStroke, {Thickness = 6, Color = CONFIG.Theme.NeonDim}, 0.45, Enum.EasingStyle.Sine):Play()
			task.wait(0.45)
			tween(promptStroke, {Thickness = 3, Color = CONFIG.Theme.Neon}, 0.45, Enum.EasingStyle.Sine):Play()
			task.wait(0.45)
		end
	end)
end
local function stopPulse()
	pulseActive = false
	promptStroke.Thickness = 3
	promptStroke.Color = CONFIG.Theme.Neon
end

-- Menu Buttons
local buttons = {}
local function createMenuButtons()
	for _, child in ipairs(buttonHolder:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end
	table.clear(buttons)

	for i, labelText in ipairs(CONFIG.MenuButtons) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 50)
		btn.BackgroundColor3 = CONFIG.Theme.Button
		btn.Text = labelText
		btn.TextColor3 = CONFIG.Theme.Text
		btn.Font = Enum.Font.GothamBold
		btn.TextScaled = true
		btn.AutoButtonColor = false
		btn.LayoutOrder = i
		btn.Parent = buttonHolder

		local bCorner = Instance.new("UICorner")
		bCorner.CornerRadius = UDim.new(0, 8)
		bCorner.Parent = btn

		local bStroke = Instance.new("UIStroke")
		bStroke.Thickness = 2
		bStroke.Color = CONFIG.Theme.NeonDim
		bStroke.Parent = btn

		btn.MouseEnter:Connect(function()
			tween(btn, {BackgroundColor3 = CONFIG.Theme.ButtonHover}, 0.15):Play()
			tween(bStroke, {Color = CONFIG.Theme.Neon}, 0.15):Play()
		end)
		btn.MouseLeave:Connect(function()
			tween(btn, {BackgroundColor3 = CONFIG.Theme.Button}, 0.25):Play()
			tween(bStroke, {Color = CONFIG.Theme.NeonDim}, 0.25):Play()
		end)

		btn.MouseButton1Click:Connect(function()
			if currentTarget then
				print(("%s clicked for %s"):format(labelText, currentTarget.Name))
				-- TODO: Fire RemoteEvent for secure server logic
			end
		end)

		buttons[labelText] = btn
	end
end
createMenuButtons()

--------------------------------------------------
-- Utility: Fade In / Out
--------------------------------------------------
local function showFrame(frameObj)
	frameObj.Visible = true
	frameObj.BackgroundTransparency = 1
	frameObj.Size = UDim2.new(frameObj.Size.X.Scale, frameObj.Size.X.Offset,
		frameObj.Size.Y.Scale, frameObj.Size.Y.Offset) -- stable
	tween(frameObj, {BackgroundTransparency = CONFIG.Theme.PanelTransparency}, CONFIG.FadeTime):Play()
end
local function hideFrame(frameObj)
	if not frameObj.Visible then return end
	local tw = tween(frameObj, {BackgroundTransparency = 1}, CONFIG.FadeTime)
	tw:Play()
	tw.Completed:Wait()
	frameObj.Visible = false
end

--------------------------------------------------
-- Target Highlight
--------------------------------------------------
local function attachHighlight(targetPlayer : Player?)
	if highlight then highlight:Destroy(); highlight = nil end
	if not targetPlayer or not targetPlayer.Character then return end
	local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	highlight = Instance.new("Highlight")
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillTransparency = CONFIG.Highlight.FillTransparency
	highlight.OutlineTransparency = CONFIG.Highlight.OutlineTransparency
	highlight.OutlineColor = CONFIG.Highlight.OutlineColor
	highlight.Adornee = targetPlayer.Character
	highlight.Parent = targetPlayer.Character
end

local function clearHighlight()
	if highlight then
		highlight:Destroy()
		highlight = nil
	end
end

--------------------------------------------------
-- Proximity Detection
--------------------------------------------------
local function distanceToPlayer(other : Player)
	if not rootPart then return math.huge end
	local char = other.Character
	if not char then return math.huge end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.Health <= 0 then return math.huge end
	return (rootPart.Position - hrp.Position).Magnitude
end

local function findClosestPlayer()
	local closest : Player? = nil
	local minDist = CONFIG.InteractRange
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= localPlayer then
			local dist = distanceToPlayer(p)
			if dist <= minDist then
				minDist = dist
				closest = p
			end
		end
	end
	return closest, minDist
end

--------------------------------------------------
-- Prompt Handling
--------------------------------------------------
local function updatePrompt()
	if currentTarget then
		promptText.Text = "Interact: " .. currentTarget.Name
	else
		promptText.Text = "Interact"
	end
end

local function setTarget(newTarget : Player?)
	if newTarget == currentTarget then return end

	if newTarget then
		currentTarget = newTarget
		updatePrompt()
		attachHighlight(currentTarget)
		if not promptFrame.Visible then
			showFrame(promptFrame)
			startPulse()
		end
	else
		currentTarget = nil
		updatePrompt()
		clearHighlight()
		if promptFrame.Visible then
			hideFrame(promptFrame)
			stopPulse()
		end
		if menuOpen then
			menuOpen = false
			hideFrame(menuFrame)
		end
	end
end

--------------------------------------------------
-- Menu Handling
--------------------------------------------------
local function openMenu()
	if not currentTarget then return end
	menuTitle.Text = string.upper(currentTarget.Name)
	showFrame(menuFrame)
	menuOpen = true
end

local function closeMenu()
	if not menuOpen then return end
	menuOpen = false
	hideFrame(menuFrame)
end

local function toggleMenu()
	if menuOpen then
		closeMenu()
	else
		openMenu()
	end
end

--------------------------------------------------
-- Input (ContextActionService)
--------------------------------------------------
local ACTION_NAME = "InteractAction"

local function interactionAction(_, state, inputObj)
	if state == Enum.UserInputState.Begin then
		-- Ignore if typing in chat or textbox
		if UserInputService:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
		if currentTarget then
			toggleMenu()
		end
	end
	return Enum.ContextActionResult.Sink
end

ContextActionService:BindAction(ACTION_NAME, interactionAction, false, CONFIG.InteractKey)

--------------------------------------------------
-- Update Loop (throttled)
--------------------------------------------------
RunService.Heartbeat:Connect(function(dt)
	lastCheck += dt
	if lastCheck < CONFIG.CheckInterval then return end
	lastCheck = 0

	-- Character safety
	if not character or not rootPart or not humanoid or humanoid.Health <= 0 then
		setTarget(nil)
		return
	end

	local closest = findClosestPlayer()

	if closest then
		setTarget(closest)
	else
		setTarget(nil)
	end

	-- Auto-close menu if target lost or out of range
	if menuOpen and (not currentTarget) then
		closeMenu()
	end
end)

--------------------------------------------------
-- Cleanup on player removing target (listen for players leaving)
--------------------------------------------------
Players.PlayerRemoving:Connect(function(plr)
	if plr == currentTarget then
		setTarget(nil)
	end
end)

--------------------------------------------------
-- Initial UI State
--------------------------------------------------
promptFrame.Visible = false
menuFrame.Visible = false
stopPulse()