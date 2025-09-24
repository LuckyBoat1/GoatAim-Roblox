-- CrateOpener.client.luau: ZERO fallbacks - empty slots if no model

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Import configs
local CrateConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CrateConfig"))

-- Create main GUI
local gui = Instance.new("ScreenGui")
gui.Name = "CrateOpener"
gui.Parent = playerGui
gui.ResetOnSpawn = false

local main = Instance.new("Frame")
main.Name = "CrateOpeningFrame"
main.Size = UDim2.new(0.8, 0, 0.6, 0)
main.Position = UDim2.new(0.1, 0, 0.2, 0)
main.BackgroundColor3 = Color3.fromRGB(20, 25, 30)
main.BorderSizePixel = 0
main.Visible = false
main.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = main

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 50)
title.Position = UDim2.new(0, 0, 0, 10)
title.BackgroundTransparency = 1
title.Text = "Opening Crate..."
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 24
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Center
title.Parent = main

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 100, 0, 40)
closeButton.Position = UDim2.new(1, -110, 0, 10)
closeButton.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
closeButton.Text = "Close"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 18
closeButton.Font = Enum.Font.GothamBold
closeButton.Parent = main

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

-- Reel container
local reelContainer = Instance.new("Frame")
reelContainer.Name = "ReelContainer"
reelContainer.Size = UDim2.new(1, -40, 0, 140)
reelContainer.Position = UDim2.new(0, 20, 0, 80)
reelContainer.BackgroundColor3 = Color3.fromRGB(15, 20, 25)
reelContainer.BorderSizePixel = 0
reelContainer.Parent = main

local reelCorner = Instance.new("UICorner")
reelCorner.CornerRadius = UDim.new(0, 10)
reelCorner.Parent = reelContainer

-- Scrolling reel
local reel = Instance.new("Frame")
reel.Name = "Reel"
reel.Size = UDim2.new(0, 0, 1, 0)
reel.Position = UDim2.new(0, 0, 0, 0)
reel.BackgroundTransparency = 1
reel.Parent = reelContainer

-- Winner indicator
local winnerIndicator = Instance.new("Frame")
winnerIndicator.Name = "WinnerIndicator"
winnerIndicator.Size = UDim2.new(0, 4, 1, 0)
winnerIndicator.Position = UDim2.new(0.5, -2, 0, 0)
winnerIndicator.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
winnerIndicator.BorderSizePixel = 0
winnerIndicator.Parent = reelContainer

-- Helper functions from inventory
local function iterBaseParts(root)
	local t = {}
	if root:IsA("Model") then
		for _,d in ipairs(root:GetDescendants()) do if d:IsA("BasePart") then table.insert(t,d) end end
	elseif root:IsA("BasePart") then table.insert(t, root) end
	return t
end

local function getVisualSize(part)
	local size = part.Size
	local sm = part:FindFirstChildOfClass("SpecialMesh")
	if sm then size = Vector3.new(size.X*sm.Scale.X, size.Y*sm.Scale.Y, size.Z*sm.Scale.Z) end
	return size
end

-- Exact setupViewport from inventory
local function setupViewport(vp, source, opts)
	opts = opts or {}
	local fitFactor = opts.fitFactor or 1.6
	local minDist   = opts.minDist   or 12

	for _,c in ipairs(vp:GetChildren()) do c:Destroy() end
	local world = Instance.new("WorldModel"); world.Parent = vp
	local cam = Instance.new("Camera"); cam.FieldOfView=50; cam.Parent=vp; vp.CurrentCamera = cam

	local clone = source:Clone()
	clone.Parent = world

	if clone:IsA("Model") then
		if not clone.PrimaryPart then for _,bp in ipairs(iterBaseParts(clone)) do clone.PrimaryPart=bp; break end end
	end
	for _,bp in ipairs(iterBaseParts(clone)) do bp.Anchored=true; bp.CanCollide=false; bp.Massless=true end
	if clone:IsA("Model") and clone.PrimaryPart then
		clone:SetPrimaryPartCFrame(CFrame.new())
	elseif clone:IsA("BasePart") then
		clone.CFrame = CFrame.new()
	end

	-- Fit camera
	local min, max = Vector3.new(1e9,1e9,1e9), Vector3.new(-1e9,-1e9,-1e9)
	for _,bp in ipairs(iterBaseParts(clone)) do
		local s=getVisualSize(bp); local cf=bp.CFrame; local h=s*0.5
		local corners = {
			cf*CFrame.new(-h.X,-h.Y,-h.Z), cf*CFrame.new(h.X,-h.Y,-h.Z),
			cf*CFrame.new(-h.X,h.Y,-h.Z),  cf*CFrame.new(h.X,h.Y,-h.Z),
			cf*CFrame.new(-h.X,-h.Y,h.Z),  cf*CFrame.new(h.X,-h.Y,h.Z),
			cf*CFrame.new(-h.X,h.Y,h.Z),   cf*CFrame.new(h.X,h.Y,h.Z),
		}
		for _,c in ipairs(corners) do
			local p=c.Position
			min = Vector3.new(math.min(min.X,p.X), math.min(min.Y,p.Y), math.min(min.Z,p.Z))
			max = Vector3.new(math.max(max.X,p.X), math.max(max.Y,p.Y), math.max(max.Z,p.Z))
		end
	end
	local center=(min+max)/2
	local span = (max-min).Magnitude
	local dist = math.max(minDist, span*fitFactor)
	local camPos = center + Vector3.new(0,0,dist)
	cam.CFrame = CFrame.new(camPos, center)
	vp.Ambient = Color3.new(0.3,0.3,0.3)
	vp.LightDirection = Vector3.new(-1,-1,-1)

	return clone
end

-- Create item frame - EMPTY if no model found
local function createReelItem(itemData, index)
	local itemFrame = Instance.new("Frame")
	itemFrame.Name = "Item_" .. index
	itemFrame.Size = UDim2.new(0, 120, 1, -10)
	itemFrame.Position = UDim2.new(0, 0, 0, 5)
	itemFrame.BackgroundColor3 = Color3.fromRGB(30, 35, 40)
	itemFrame.BorderSizePixel = 0
	itemFrame.LayoutOrder = index
	itemFrame.Parent = reel

	local rarityStroke = Instance.new("UIStroke")
	rarityStroke.Color = CrateConfig.GetRarityColor(itemData.rarity or "common")
	rarityStroke.Thickness = 3
	rarityStroke.Parent = itemFrame

	local itemCorner = Instance.new("UICorner")
	itemCorner.CornerRadius = UDim.new(0, 8)
	itemCorner.Parent = itemFrame

	-- Check for model - if found, create viewport, if not found, leave COMPLETELY EMPTY
	local skinLib = ReplicatedStorage:FindFirstChild("SkinLibrary")
	if skinLib then
		local skinModel = skinLib:FindFirstChild(itemData.name)
		if skinModel then
			-- ONLY create viewport if model exists
			local viewport = Instance.new("ViewportFrame")
			viewport.Size = UDim2.fromScale(1,1)
			viewport.Position = UDim2.fromScale(0.5,0.5)
			viewport.AnchorPoint = Vector2.new(0.5,0.5)
			viewport.BackgroundTransparency = 1
			viewport.BorderSizePixel = 0
			viewport.Parent = itemFrame

			-- Setup viewport
			setupViewport(viewport, skinModel, {fitFactor = 1.6, minDist = 12})
		end
		-- If no model found, frame stays empty - NO TEXT, NO LABELS, NOTHING
	end
end

-- Generate reel items
local function generateReel(crateType, winningItem, totalItems)
	reel:ClearAllChildren()
	
	local reelLayout = Instance.new("UIListLayout")
	reelLayout.FillDirection = Enum.FillDirection.Horizontal
	reelLayout.SortOrder = Enum.SortOrder.LayoutOrder
	reelLayout.Padding = UDim.new(0, 10)
	reelLayout.Parent = reel
	
	local winningPosition = math.floor(totalItems * 0.6)
	
	for i = 1, totalItems do
		local itemData
		if i == winningPosition then
			itemData = winningItem
		else
			itemData = CrateConfig.RollCrate(crateType)
		end
		
		if itemData then
			createReelItem(itemData, i)
		end
	end
	
	-- Update reel size
	reel.Size = UDim2.new(0, totalItems * 130, 1, 0)
end

-- Animation function
local function animateReel()
	local containerWidth = reelContainer.AbsoluteSize.X
	local targetPosition = -(reel.AbsoluteSize.X * 0.6 - containerWidth * 0.5)
	
	local tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	local tween = TweenService:Create(reel, tweenInfo, {Position = UDim2.new(0, targetPosition, 0, 0)})
	
	tween:Play()
	
	return tween
end

-- Main opening function
local function openCrate(crateType)
	if main.Visible then return end
	
	main.Visible = true
	title.Text = "Opening " .. (CrateConfig.GetCrate(crateType) and CrateConfig.GetCrate(crateType).name or "Crate")
	
	reel.Position = UDim2.new(0, 100, 0, 0)
	
	local winningItem = CrateConfig.RollCrate(crateType)
	generateReel(crateType, winningItem, 9)
	
	wait(0.5)
	local tween = animateReel()
	
	tween.Completed:Connect(function()
		title.Text = "You won: " .. (winningItem and winningItem.name or "Unknown Item")
	end)
end

-- Close function
closeButton.MouseButton1Click:Connect(function()
	main.Visible = false
	reel:ClearAllChildren()
end)

-- Remote events
local openCrateEvent = ReplicatedStorage:FindFirstChild("OpenCrate")
if openCrateEvent then
	openCrateEvent.OnClientEvent:Connect(function(crateType)
		openCrate(crateType)
	end)
end

-- Test function
local function testOpen()
	openCrate("BRONZE")
end

-- Export functions
_G.CrateOpener = {
	openCrate = openCrate,
	testOpen = testOpen
}
