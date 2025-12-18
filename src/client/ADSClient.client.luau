
local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Rs = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- SkinConfig simple direct require (Studio-style)
local SkinConfig = require(Rs:WaitForChild("Shared"):WaitForChild("SkinConfig"))
local player = Players.LocalPlayer
local cam = workspace.CurrentCamera

-- Get/create ADS remote event for replicating arm positions
local remoteEvents = Rs:WaitForChild("RemoteEvents")
local adsRemote = remoteEvents:FindFirstChild("ADSToggle")
if not adsRemote then
	adsRemote = Instance.new("RemoteEvent")
	adsRemote.Name = "ADSToggle"
	adsRemote.Parent = remoteEvents
end

-- Optional: force third-person for testing so you can see the weapon
do
	local FORCE_THIRD_PERSON = false  -- DISABLED to allow first-person
	if FORCE_THIRD_PERSON then
		pcall(function()
			player.CameraMode = Enum.CameraMode.Classic
			player.CameraMinZoomDistance = 5
			player.CameraMaxZoomDistance = 20
		end)
	end
end

local currentTool = nil -- Tool
local hipGrip = nil -- CFrame
local baseAdsGrip = nil -- CFrame - The base ADS grip from config, never modified
local adjustedAdsGrip = nil -- CFrame - The final ADS grip with server adjustments applied
local hipFOV = nil -- number
local adsFOV = nil -- number
local aiming = false
local shoulderTweens = {} -- Store active shoulder tweens

local gripDriver = nil -- CFrameValue

-- Procedurally animate arms to ADS position
local function animateArmsToADS(character, isADS)
	if not character then 
		print("[ADSClient] ❌ No character provided")
		return 
	end
	
	print("[ADSClient] Character:", character.Name)
	print("[ADSClient] Character children:")
	for _, child in ipairs(character:GetChildren()) do
		print("  -", child.Name, "(" .. child.ClassName .. ")")
	end
	
	-- Find torso and shoulders
	local torso = character:FindFirstChild("Torso")
	local isR15 = false
	
	if not torso then
		torso = character:FindFirstChild("UpperTorso")
		isR15 = true
		print("[ADSClient] Using R15 rig - found UpperTorso")
	else
		print("[ADSClient] Using R6 rig - found Torso")
	end
	
	if not torso then 
		warn("[ADSClient] ❌ No torso or UpperTorso found!")
		return 
	end
	
	print("[ADSClient] Torso children:")
	for _, child in ipairs(torso:GetChildren()) do
		print("  -", child.Name, "(" .. child.ClassName .. ")")
	end
	
	local rightShoulder, leftShoulder
	
	if isR15 then
		-- R15: Shoulder Motor6Ds are in the arm parts, not the torso
		local rightUpperArm = character:FindFirstChild("RightUpperArm")
		local leftUpperArm = character:FindFirstChild("LeftUpperArm")
		
		if rightUpperArm then
			rightShoulder = rightUpperArm:FindFirstChild("RightShoulder")
			print("[ADSClient] Found RightUpperArm, looking for shoulder joint:", rightShoulder)
		end
		
		if leftUpperArm then
			leftShoulder = leftUpperArm:FindFirstChild("LeftShoulder")
			print("[ADSClient] Found LeftUpperArm, looking for shoulder joint:", leftShoulder)
		end
	else
		-- R6 joints are in the torso
		rightShoulder = torso:FindFirstChild("Right Shoulder")
		leftShoulder = torso:FindFirstChild("Left Shoulder")
	end
	
	if not rightShoulder or not leftShoulder then
		warn("[ADSClient] ⚠️ Shoulders not found!")
		warn("[ADSClient] Looking for:", isR15 and "RightShoulder/LeftShoulder" or "Right Shoulder/Left Shoulder")
		warn("[ADSClient] Right shoulder:", rightShoulder)
		warn("[ADSClient] Left shoulder:", leftShoulder)
		return
	end
	
	print("[ADSClient] Found shoulders - Right:", rightShoulder, "Left:", leftShoulder)
	
	-- Store original C0 values if not already stored (use CFrame values directly)
	local rightOriginalValue = rightShoulder:FindFirstChild("OriginalC0")
	if not rightOriginalValue then
		rightOriginalValue = Instance.new("CFrameValue")
		rightOriginalValue.Name = "OriginalC0"
		rightOriginalValue.Value = rightShoulder.C0
		rightOriginalValue.Parent = rightShoulder
		print("[ADSClient] Stored right shoulder original C0:", rightShoulder.C0)
	end
	
	local leftOriginalValue = leftShoulder:FindFirstChild("OriginalC0")
	if not leftOriginalValue then
		leftOriginalValue = Instance.new("CFrameValue")
		leftOriginalValue.Name = "OriginalC0"
		leftOriginalValue.Value = leftShoulder.C0
		leftOriginalValue.Parent = leftShoulder
		print("[ADSClient] Stored left shoulder original C0:", leftShoulder.C0)
	end
	
	-- Get original positions
	local rightOriginal = rightOriginalValue.Value
	local leftOriginal = leftOriginalValue.Value
	
	-- Cancel existing tweens
	for _, tween in pairs(shoulderTweens) do
		tween:Cancel()
	end
	shoulderTweens = {}
	
	if isADS then
		-- ADS position: Move RIGHT shoulder back to match weapon ADS movement
		-- Positive Z = moves BACK toward the body
		-- Left arm stays stationary (no movement)
		
		-- Right arm: move shoulder back 0.5 studs max (or it goes out of body)
		local rightADS = rightOriginal * CFrame.new(0, 0, 0.5)
		-- Left arm: NO CHANGE - keep original position
		local leftADS = leftOriginal
		
		print("[ADSClient] Calculated ADS positions:")
		print("  Right original:", rightOriginal)
		print("  Right ADS:", rightADS)
		print("  Left original:", leftOriginal)
		print("  Left ADS:", leftADS)
		
		-- Tween to ADS position
		local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		
		shoulderTweens.right = TweenService:Create(rightShoulder, tweenInfo, {C0 = rightADS})
		shoulderTweens.left = TweenService:Create(leftShoulder, tweenInfo, {C0 = leftADS})
		
		shoulderTweens.right:Play()
		shoulderTweens.left:Play()
		
		print("[ADSClient] ✅ Tweening arms to ADS position")
		print("  Current right C0:", rightShoulder.C0)
		print("  Current left C0:", leftShoulder.C0)
		
		-- Tell server to replicate to other players
		adsRemote:FireServer(true, rightADS, leftADS)
		print("[ADSClient] Fired to server")
	else
		-- Return to original position
		local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		
		shoulderTweens.right = TweenService:Create(rightShoulder, tweenInfo, {C0 = rightOriginal})
		shoulderTweens.left = TweenService:Create(leftShoulder, tweenInfo, {C0 = leftOriginal})
		
		shoulderTweens.right:Play()
		shoulderTweens.left:Play()
		
		print("[ADSClient] ✅ Tweening arms back to hip position")
		
		-- Tell server to reset for other players
		adsRemote:FireServer(false, rightOriginal, leftOriginal)
	end
end

local function tweenFOV(toFOV, dur)
	local start = cam.FieldOfView
	local t0 = tick()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local a = math.clamp((tick() - t0)/dur, 0, 1)
		local ease = 1 - (1-a)*(1-a)
		cam.FieldOfView = start + (toFOV - start)*ease
		if a >= 1 then conn:Disconnect() end
	end)
end

local function isADSAllowed(tool)
	local attr = tool:GetAttribute("ADSExcluded")
	if attr ~= nil then return attr == false end
	return SkinConfig.IsADSAllowed(tool.Name, tool:GetAttribute("SkinId"))
end

local function setupTool(tool)
	currentTool = tool
	
	print("=== [ADSClient] Setting up tool:", tool.Name, "===")
	print("[ADSClient] Tool ClassName:", tool.ClassName)
	print("[ADSClient] Tool has Handle?", tool:FindFirstChild("Handle") ~= nil)
	if tool:FindFirstChild("Handle") then
		print("[ADSClient] Handle ClassName:", tool.Handle.ClassName)
	end
	print("[ADSClient] Tool.RequiresHandle:", tool.RequiresHandle)
	
	-- Server handles all weapon positioning and rotation
	-- Client only handles ADS functionality
	
	baseAdsGrip = nil
	adjustedAdsGrip = nil
	hipFOV = cam.FieldOfView
	adsFOV = nil

	-- Get the original grip BEFORE server adjustments (if stored)
	local originalGrip = tool.Grip
	print("[ADSClient] Initial tool.Grip:", tool.Grip)
	
	if tool:GetAttribute("OriginalGripStored") then
		local ox = tool:GetAttribute("OriginalGripX") or 0
		local oy = tool:GetAttribute("OriginalGripY") or 0
		local oz = tool:GetAttribute("OriginalGripZ") or 0
		originalGrip = CFrame.new(ox, oy, oz)
		print("[ADSClient] Using stored original grip:", originalGrip)
	else
		print("[ADSClient] No stored original, using current tool.Grip")
	end

	if isADSAllowed(tool) then
		local adsFolder = tool:FindFirstChild("ADS")
		if adsFolder then
			local g = adsFolder:FindFirstChild("ADSGrip")
			if g and g:IsA("CFrameValue") then baseAdsGrip = g.Value end
			local f = adsFolder:FindFirstChild("ADSFOV")
			if f and f:IsA("NumberValue") then adsFOV = f.Value end
		end
		if not baseAdsGrip then
			baseAdsGrip = SkinConfig.GetADSGripForSkin(tool:GetAttribute("SkinId"), tool.Name)
		end
		if not adsFOV then
			adsFOV = SkinConfig.GetADSFOVForSkin(tool:GetAttribute("SkinId"), tool.Name)
		end
		print("[ADSClient] Base ADS grip from config:", baseAdsGrip)
	else
		baseAdsGrip = nil
	end
	
	-- Wait for server to finish applying rotations and adjustments (server waits 0.5s)
	task.wait(2)
	
	-- Now capture the hip grip AFTER server has applied all adjustments
	hipGrip = tool.Grip
	print("[ADSClient] Hip grip (after server adjustments):", hipGrip)
	
	-- Apply the ADS grip as a RELATIVE OFFSET from hip position
	-- baseAdsGrip defines how much to move the weapon (e.g., 0.2 studs back)
	if baseAdsGrip and originalGrip then
		-- The baseAdsGrip from config is a relative offset
		-- Multiply it with hipGrip to apply the offset in the weapon's local space
		adjustedAdsGrip = hipGrip * baseAdsGrip
		
		print("[ADSClient] === Grip Setup Complete ===")
		print("[ADSClient] Hip grip:", hipGrip)
		print("[ADSClient] Original grip:", originalGrip)
		print("[ADSClient] Base ADS offset:", baseAdsGrip)
		print("[ADSClient] Final ADS grip (hip * offset):", adjustedAdsGrip)
		print("[ADSClient] =====================================")
	else
		adjustedAdsGrip = baseAdsGrip
		print("[ADSClient] Using base ADS grip (no adjustments)")
	end
	
	aiming = false
end

local function teardownTool()
	-- DISABLED: Let server handle all grip positioning
	-- if currentTool and hipGrip then
	--	pcall(function() currentTool.Grip = hipGrip end)
	-- end
	currentTool, hipGrip, baseAdsGrip, adjustedAdsGrip, hipFOV, adsFOV = nil, nil, nil, nil, nil, nil
	aiming = false
end

local function beginADS()
	if not currentTool or not adjustedAdsGrip or aiming then return end
	aiming = true
	
	print("[ADSClient] ▶ ENTERING ADS")
	
	-- Animate arms to ADS position
	local character = player.Character
	if character then
		animateArmsToADS(character, true)
	end
	
	-- Change tool grip - this moves the weapon in your hand
	pcall(function()
		currentTool.Grip = adjustedAdsGrip
		print("[ADSClient] Set tool.Grip to ADS grip")
	end)
	
	-- Use Humanoid.CameraOffset for first-person ADS feel
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.CameraOffset = Vector3.new(0, -1, -1.5)
			print("[ADSClient] Camera offset applied - ADS view")
		end
	end
	
	tweenFOV(adsFOV or 55, 0.14)
end

local function endADS()
	if not currentTool or not hipGrip or not aiming then return end
	aiming = false
	
	print("[ADSClient] ◀ EXITING ADS")
	
	-- Animate arms back to hip position
	local character = player.Character
	if character then
		animateArmsToADS(character, false)
	end
	
	if character then
		-- Reset Humanoid.CameraOffset
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.CameraOffset = Vector3.new(0, 0, 0)
			print("[ADSClient] Camera offset reset")
		end
	end
	
	-- Reset tool.Grip to hip grip
	pcall(function()
		currentTool.Grip = hipGrip
		print("[ADSClient] Tool grip reset to hip")
	end)
	
	tweenFOV(hipFOV or cam.FieldOfView, 0.12)
end

local function bindInputs()
	ContextActionService:BindAction("ADS_Hold", function(_, state)
		if not currentTool or not adjustedAdsGrip then return Enum.ContextActionResult.Pass end
		if state == Enum.UserInputState.Begin then beginADS()
		elseif state == Enum.UserInputState.End then endADS() end
		return Enum.ContextActionResult.Sink
	end, true, Enum.UserInputType.MouseButton2, Enum.KeyCode.ButtonL2)

	ContextActionService:BindAction("ADS_ShiftHold", function(_, state)
		if not currentTool or not adjustedAdsGrip then return Enum.ContextActionResult.Pass end
		if state == Enum.UserInputState.Begin then beginADS()
		elseif state == Enum.UserInputState.End then endADS() end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.LeftShift)
end

local function ensureMobileButton()
	if not UserInputService.TouchEnabled then return end
	local gui = player:FindFirstChildOfClass("PlayerGui")
	if not gui then return end

	local hud = gui:FindFirstChild("ADS_UI") or Instance.new("ScreenGui")
	hud.Name = "ADS_UI"
	hud.ResetOnSpawn = false
	hud.Parent = gui

	local btn = hud:FindFirstChild("ADSButton") or Instance.new("TextButton")
	btn.Name = "ADSButton"
	btn.Size = UDim2.new(0, 60, 0, 60)
	btn.Position = UDim2.new(1, -80, 1, -80)
	btn.BackgroundColor3 = Color3.fromRGB(20,30,25)
	btn.Text = "ADS"
	btn.TextSize = 18
	btn.TextColor3 = Color3.fromRGB(20,250,120)
	btn.Parent = hud
	if not btn:FindFirstChildOfClass("UICorner") then
		local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,12); c.Parent = btn
		local s = Instance.new("UIStroke"); s.Color = Color3.fromRGB(20,250,120); s.Thickness = 2; s.Parent = btn
	end

	btn.MouseButton1Down:Connect(function() if currentTool and adjustedAdsGrip then beginADS() end end)
	btn.MouseButton1Up:Connect(function() if currentTool then endADS() end end)
end

local function hookCharacter(char)
	char.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			child.Equipped:Connect(function() setupTool(child) end)
			child.Unequipped:Connect(teardownTool)
		end
	end)
	for _, child in ipairs(char:GetChildren()) do
		if child:IsA("Tool") then
			child.Equipped:Connect(function() setupTool(child) end)
			child.Unequipped:Connect(teardownTool)
		end
	end
end

local playerObj = Players.LocalPlayer
playerObj.CharacterAdded:Connect(function(char)
	hookCharacter(char)
	ensureMobileButton()
end)
if playerObj.Character then
	hookCharacter(playerObj.Character)
	ensureMobileButton()
end

bindInputs()