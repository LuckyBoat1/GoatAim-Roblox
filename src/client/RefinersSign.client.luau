-- INVISIBLE LOCATION SIGNS
-- Place this script in ServerScriptService
-- Created: 2025-08-20 19:23:18 by Hulk11121

-- STEP 1: Create Parts named "LocationSign" in the workspace where you want signs
-- STEP 2: Put this script in ServerScriptService
-- STEP 3: The parts will be made invisible and replaced with text

local SIGN_CONFIG = {
	-- The name of parts to look for in the workspace
	SIGN_PART_NAME = "LocationSign",

	-- Default text settings
	DEFAULT_TEXT = "Refiners",
	TEXT_COLOR = Color3.fromRGB(255, 255, 255),
	TEXT_SIZE = 24,
	FONT = Enum.Font.GothamBold,

	-- Sign appearance
	BACKGROUND_COLOR = Color3.fromRGB(30, 60, 120),
	BORDER_COLOR = Color3.fromRGB(80, 140, 255),
	SIZE = Vector2.new(200, 60),  -- Width, Height in pixels
	CORNER_RADIUS = 0.2,

	-- Sign will be visible from this many studs away
	MAX_DISTANCE = 100,

	-- IMPORTANT: Whether to make the part invisible
	MAKE_PART_INVISIBLE = true,
}

-- Function to create a sign on a part and make it invisible
local function createSignOnPart(part)
	-- Skip if already has a sign
	if part:FindFirstChild("SignBillboard") then
		return
	end

	-- Check if this part has custom text
	local text = part:GetAttribute("SignText") or SIGN_CONFIG.DEFAULT_TEXT

	-- Make the part invisible but keep it solid for collisions if needed
	if SIGN_CONFIG.MAKE_PART_INVISIBLE then
		part.Transparency = 1
	end

	-- Create billboard GUI
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "SignBillboard"
	billboard.Size = UDim2.fromOffset(SIGN_CONFIG.SIZE.X, SIGN_CONFIG.SIZE.Y)
	billboard.StudsOffset = Vector3.new(0, part.Size.Y/2 + 1, 0) -- Position above part
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = SIGN_CONFIG.MAX_DISTANCE
	billboard.Parent = part

	-- Create background frame
	local background = Instance.new("Frame")
	background.Size = UDim2.fromScale(1, 1)
	background.BackgroundColor3 = SIGN_CONFIG.BACKGROUND_COLOR
	background.BorderSizePixel = 0
	background.Parent = billboard

	-- Add corner rounding
	local corner = Instance.new("UICorner", background)
	corner.CornerRadius = UDim.new(SIGN_CONFIG.CORNER_RADIUS, 0)

	-- Add border
	local stroke = Instance.new("UIStroke", background)
	stroke.Color = SIGN_CONFIG.BORDER_COLOR
	stroke.Thickness = 3
	stroke.Transparency = 0.1

	-- Add gradient effect
	local gradient = Instance.new("UIGradient", background)
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.5, SIGN_CONFIG.BACKGROUND_COLOR),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(
			math.floor(SIGN_CONFIG.BACKGROUND_COLOR.R * 0.7 * 255),
			math.floor(SIGN_CONFIG.BACKGROUND_COLOR.G * 0.7 * 255),
			math.floor(SIGN_CONFIG.BACKGROUND_COLOR.B * 0.7 * 255)
			))
	})
	gradient.Rotation = 45

	-- Add text
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.fromScale(0.9, 0.9)
	textLabel.Position = UDim2.fromScale(0.5, 0.5)
	textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	textLabel.BackgroundTransparency = 1
	textLabel.Font = SIGN_CONFIG.FONT
	textLabel.TextSize = SIGN_CONFIG.TEXT_SIZE
	textLabel.TextColor3 = SIGN_CONFIG.TEXT_COLOR
	textLabel.Text = text
	textLabel.TextScaled = true
	textLabel.Parent = background

	-- Add shine effect
	local shine = Instance.new("Frame")
	shine.Size = UDim2.fromScale(2, 0.1)
	shine.Position = UDim2.fromScale(-1, 0.5)
	shine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	shine.BackgroundTransparency = 0.7
	shine.ZIndex = 5
	shine.Rotation = 15
	shine.Parent = background

	local shineGradient = Instance.new("UIGradient", shine)
	shineGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.4, 0.7),
		NumberSequenceKeypoint.new(0.5, 0.5),
		NumberSequenceKeypoint.new(0.6, 0.7),
		NumberSequenceKeypoint.new(1, 1)
	})

	-- Animate the shine effect
	spawn(function()
		local startTime = tick()
		while wait(0.03) do
			local elapsed = tick() - startTime
			shine.Position = UDim2.fromScale(-1 + (elapsed % 3)/1.5, 0.5)
		end
	end)

	-- Add a function to change the text later if needed
	part.SetSignText = function(newText)
		textLabel.Text = newText
		part:SetAttribute("SignText", newText)
	end

	print("✅ Created invisible sign for: " .. part.Name .. " [Text: " .. text .. "]")
end

-- Find all existing sign parts and add text
local function setupExistingSigns()
	local count = 0
	for _, part in pairs(workspace:GetDescendants()) do
		if part:IsA("BasePart") and part.Name == SIGN_CONFIG.SIGN_PART_NAME then
			createSignOnPart(part)
			count = count + 1
		end
	end

	print("🔍 Found and setup " .. count .. " location signs in workspace")
end

-- Watch for new sign parts added later
local function watchForNewSigns()
	workspace.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") and descendant.Name == SIGN_CONFIG.SIGN_PART_NAME then
			wait(0.1) -- Give time for attributes to replicate
			createSignOnPart(descendant)
		end
	end)
end

-- Run the setup
setupExistingSigns()
watchForNewSigns()

print("✅ Invisible Location Signs script running - Parts named '" .. SIGN_CONFIG.SIGN_PART_NAME .. "' will be invisible with text labels")
print("📋 To customize a sign, set the SignText attribute on the part")
print("📋 Created: 2025-08-20 19:23:18 by Hulk11121")