
local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Rs = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

------------------------------------------------------------------------
-- SHOOT JOYSTICK — module-level state so UIS is connected ONCE only.
-- Active=false on the frame so the left movement joystick isn't blocked.
------------------------------------------------------------------------
local _shootBtn         = nil   -- Frame reference; updated each respawn
local _shootActiveInput = nil
local _shootStartPos    = nil
local JOYSTICK_TRAVEL   = 34

local function _resetShootKnob()
	if _shootBtn and _shootBtn.Parent then
		local k = _shootBtn:FindFirstChild("Knob")
		if k then k.Position = UDim2.new(0.5, 0, 0.5, 0) end
	end
	_shootActiveInput = nil
	_shootStartPos    = nil
end

-- Module-level UIS: fires for Active=false frames. Active=false is required so
-- the camera can pan (aim) while the finger rests on the shoot button.
-- We do NOT check gameProcessed here — our explicit bounds check is the guard.
-- gameProcessed can be true from other UI elements in the same area, which would
-- silently block the joystick from activating if we filtered on it.
UserInputService.InputBegan:Connect(function(input, _gameProcessed)
	if input.UserInputType ~= Enum.UserInputType.Touch then return end
	if not _shootBtn or not _shootBtn.Parent then return end
	if _shootActiveInput then return end  -- already tracking a touch
	local abs = _shootBtn.AbsolutePosition
	local siz = _shootBtn.AbsoluteSize
	if siz.X == 0 then return end
	local x, y = input.Position.X, input.Position.Y
	if x >= abs.X and x <= abs.X + siz.X and y >= abs.Y and y <= abs.Y + siz.Y then
		_shootActiveInput = input
		_shootStartPos    = Vector2.new(x, y)
		-- Fire the shot immediately on tap
		if _G.MobileTryShoot then
			_G.MobileTryShoot()
		else
			task.spawn(function()
				local deadline = tick() + 1
				repeat task.wait(0.05) until _G.MobileTryShoot or tick() > deadline
				if _G.MobileTryShoot then _G.MobileTryShoot() end
			end)
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input == _shootActiveInput then _resetShootKnob() end
end)

-- RenderStepped polls the active touch position every frame so the knob never
-- lags or misses updates even when two touches are active simultaneously.
RunService.RenderStepped:Connect(function()
	if not _shootActiveInput or not _shootBtn or not _shootBtn.Parent then return end
	if _shootActiveInput.UserInputState == Enum.UserInputState.End then
		_resetShootKnob()
		return
	end
	local k = _shootBtn:FindFirstChild("Knob")
	if not k then return end
	local delta = Vector2.new(_shootActiveInput.Position.X, _shootActiveInput.Position.Y) - _shootStartPos
	local dist  = delta.Magnitude
	if dist > JOYSTICK_TRAVEL then delta = delta * (JOYSTICK_TRAVEL / dist) end
	k.Position = UDim2.new(0.5, delta.X, 0.5, delta.Y)
end)

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
	end, false, Enum.UserInputType.MouseButton2, Enum.KeyCode.ButtonL2)
	-- false = no auto-generated Roblox mobile button; we use our own custom ADS button.
	-- Shift key removed from ADS — Shift is reserved for dash only
end

local function ensureMobileButton()
	if not UserInputService.TouchEnabled then return end
	local gui = player:FindFirstChildOfClass("PlayerGui")
	if not gui then return end

	-- Hide the default Roblox jump button and place our shoot button in its spot
	task.spawn(function()
		local touchGui = gui:WaitForChild("TouchGui", 10)
		if not touchGui then return end
		local function destroyJump(g)
			for _, obj in ipairs(g:GetDescendants()) do
				if obj.Name == "JumpButton" then
					obj.Visible = false
					obj.Size = UDim2.new(0, 0, 0, 0)
				end
			end
		end
		destroyJump(touchGui)
		touchGui.DescendantAdded:Connect(function(obj)
			if obj.Name == "JumpButton" then
				task.defer(function()
					if obj and obj.Parent then
						obj.Visible = false
						obj.Size = UDim2.new(0, 0, 0, 0)
					end
				end)
			end
		end)
	end)

	local hud = gui:FindFirstChild("ADS_UI") or Instance.new("ScreenGui")
	hud.Name = "ADS_UI"
	hud.ResetOnSpawn = false
	hud.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	hud.DisplayOrder = 10
	hud.Parent = gui

	-- Clear any previous shoot button
	local old = hud:FindFirstChild("ShootButton")
	if old then old:Destroy() end

	-- ── Shoot Joystick — original image background + blue stick only ──
	local BTN_SIZE   = 220  -- transparent hit area (bigger than image for easier touch)
	local IMG_SIZE   = 170  -- visible image size (unchanged appearance)
	local KNOB_SIZE  = 52   -- blue knob diameter (moves with finger)
	local MAX_TRAVEL = 34   -- max knob offset from center

	-- Outer container: Active=false so the camera pan system receives the touch
	-- and can pan/aim while the finger rests on the shoot area. Hit-detection
	-- for firing is handled by the module-level UserInputService connection above.
	local btn = Instance.new("Frame")
	btn.Name                 = "ShootButton"
	btn.AnchorPoint          = Vector2.new(1, 1)
	btn.Size                 = UDim2.new(0, BTN_SIZE, 0, BTN_SIZE)
	btn.Position             = UDim2.new(1, 30, 1, 30)
	btn.BackgroundTransparency = 1
	btn.BorderSizePixel      = 0
	btn.Active               = false  -- must stay false so camera pan (aim) works
	btn.Parent               = hud

	-- Background image: centered in the frame (frame center = original image corner position)
	do
		local img = Instance.new("ImageLabel")
		img.Size                  = UDim2.new(0, IMG_SIZE, 0, IMG_SIZE)
		img.AnchorPoint           = Vector2.new(0.5, 0.5)
		img.Position              = UDim2.new(0.5, 0, 0.5, 0)
		img.BackgroundTransparency = 1
		img.Image                 = "rbxassetid://107599983524020"
		img.ScaleType             = Enum.ScaleType.Fit
		img.ZIndex                = 1
		img.Parent                = btn
	end

	-- Blue knob only (moves with finger, no red base)
	local knob = Instance.new("Frame")
	knob.Name                 = "Knob"
	knob.AnchorPoint          = Vector2.new(0.5, 0.5)
	knob.Size                 = UDim2.new(0, KNOB_SIZE, 0, KNOB_SIZE)
	knob.Position             = UDim2.new(0.5, 0, 0.5, 0)
	knob.BackgroundColor3     = Color3.fromRGB(40, 110, 230)
	knob.BackgroundTransparency = 0.55
	knob.BorderSizePixel      = 0
	knob.ZIndex               = 3
	knob.Parent               = btn
	do
		Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
		local s = Instance.new("UIStroke", knob)
		s.Color = Color3.fromRGB(120, 180, 255)
		s.Thickness = 2
	end

	-- _shootBtn reference updated here; module-level UIS connections handle touch detection.
	_shootBtn = btn

	-- ── ADS Toggle Button — bottom-left of the shoot button ──────────────
	local ADS_BTN_SIZE = 90   -- diameter of the button

	local old_ads = hud:FindFirstChild("ADSToggleButton")
	if old_ads then old_ads:Destroy() end

	local adsBtn = Instance.new("ImageButton")
	adsBtn.Name                 = "ADSToggleButton"
	adsBtn.AnchorPoint          = Vector2.new(1, 1)
	-- Sits in the upper-left quadrant of the shoot button area, 80 px above the bottom edge.
	-- BTN_SIZE=220: 30 - 220 + 70 = -120 (X), Y = -80 (above the screen-bottom).
	adsBtn.Size                 = UDim2.new(0, ADS_BTN_SIZE, 0, ADS_BTN_SIZE)
	adsBtn.Position             = UDim2.new(1, 30 - BTN_SIZE + 70, 1, -80)
	adsBtn.BackgroundTransparency = 1
	adsBtn.BorderSizePixel      = 0
	adsBtn.Image                = "rbxassetid://80229905853399"
	adsBtn.ScaleType            = Enum.ScaleType.Fit
	adsBtn.ZIndex               = 5
	adsBtn.Parent               = hud

	-- Tint to indicate ADS state
	local function updateAdsBtnTint(active)
		adsBtn.ImageColor3 = active and Color3.fromRGB(80, 210, 120) or Color3.fromRGB(255, 255, 255)
		adsBtn.ImageTransparency = active and 0 or 0.15
	end
	updateAdsBtnTint(false)

	adsBtn.Activated:Connect(function()
		if aiming then
			endADS()
			updateAdsBtnTint(false)
		else
			beginADS()
			updateAdsBtnTint(true)
		end
	end)

	-- Reset tint visually when ADS drops naturally (e.g. tool unequipped).
	-- Guard against the button being destroyed on the next respawn.
	local prevAiming = false
	RunService.RenderStepped:Connect(function()
		if not adsBtn or not adsBtn.Parent then return end
		if aiming ~= prevAiming then
			prevAiming = aiming
			updateAdsBtnTint(aiming)
		end
	end)
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