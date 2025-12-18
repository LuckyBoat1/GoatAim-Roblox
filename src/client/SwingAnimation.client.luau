-- SwingAnimation.client.luau
-- Handles client-side swing animations for blades and spears

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Rs = game:GetService("ReplicatedStorage")

-- SkinConfig simple direct require (Studio-style)
local SkinConfig = require(Rs:WaitForChild("Shared"):WaitForChild("SkinConfig"))
local player = Players.LocalPlayer

-- Get/create Swing remote event for replicating arm positions
local remoteEvents = Rs:WaitForChild("RemoteEvents")
local swingRemote = remoteEvents:FindFirstChild("SwingAnimation")
if not swingRemote then
	swingRemote = Instance.new("RemoteEvent")
	swingRemote.Name = "SwingAnimation"
	swingRemote.Parent = remoteEvents
end

local currentTool = nil -- Tool
local isSwinging = false
local canSwing = true
local swingCooldown = 0.5 -- Time between swings in seconds
local shoulderTweens = {} -- Store active shoulder tweens

-- Store TRUE original positions (saved only on equip, never overwritten during swings)
local trueOriginalGrip = nil
local trueOriginalRightC0 = nil
local trueOriginalLeftC0 = nil

-- Weapons that should have swing animations (Blade, Spear, Axe, and melee weapon types)
local function shouldHaveSwingAnimation(skinName)
	if not skinName then return false end
	
	local skinMeta = SkinConfig.GetSkinMeta(skinName)
	if not skinMeta then return false end
	
	-- List of weapon types that should swing
	local swingWeaponTypes = {
		"Blade",
		"Spear",
		"Axe",
		"GreatAxe",
		"HandAxe",
		"Sword",
		"Greatsword",
		"Hammer",
		"Mace",
		"Club",
		"Halberd",
		"Staff",
		"Machete",
		"Shiv",
		"Cutlass",
		"Banner",
		"Bone"
	}
	
	local weaponType = skinMeta.weapon
	
	-- Check if weapon type is in the swing list
	for _, swingType in ipairs(swingWeaponTypes) do
		if weaponType == swingType then
			return true
		end
	end
	
	-- Also check for Melee type with "spear" or "axe" in the name
	if weaponType == "Melee" and (
		string.find(string.lower(skinName), "spear") or
		string.find(string.lower(skinName), "axe")
	) then
		return true
	end
	
	return false
end

-- Check if swing path would hit anything
local function checkSwingCollision(tool, character)
	if not tool or not character then return false end
	
	local handle = tool:FindFirstChild("Handle")
	if not handle then return false end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return false end
	
	-- Raycast parameters
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {character, tool}
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.IgnoreWater = true
	
	-- Check multiple points along the swing path
	local lookVector = humanoidRootPart.CFrame.LookVector
	local rightVector = humanoidRootPart.CFrame.RightVector
	local downVector = Vector3.new(0, -1, 0)
	
	-- Get weapon handle size for better detection
	local handleSize = handle.Size
	local maxDimension = math.max(handleSize.X, handleSize.Y, handleSize.Z)
	
	-- Check from handle position in multiple directions
	local checkPoints = {
		-- Forward swing path
		handle.Position + (lookVector * 2) + (downVector * 1.5),
		-- Forward and right (side swing)
		handle.Position + (lookVector * 1.5) + (rightVector * 1) + (downVector * 1),
		-- Forward and down (downward swing)
		handle.Position + (lookVector * 1) + (downVector * 2),
		-- Just forward (direct path)
		handle.Position + (lookVector * 2.5),
		-- Forward and slightly up (to catch ceiling/walls)
		handle.Position + (lookVector * 1.5) + Vector3.new(0, 0.5, 0),
	}
	
	-- Cast rays to all check points
	for _, checkPoint in ipairs(checkPoints) do
		local direction = checkPoint - handle.Position
		local result = workspace:Raycast(handle.Position, direction, rayParams)
		
		if result then
			-- Check if hit is close (within weapon swing range)
			local distance = (result.Position - handle.Position).Magnitude
			if distance < (maxDimension + 2) then
				return true
			end
		end
	end
	
	return false
end

-- Animate swing by rotating the tool grip (like ADS does)
local function animateSwing(tool, character, swinging)
	if not tool then 
		print("[SwingAnimation] ❌ No tool provided")
		return 
	end
	
	-- Cancel any existing tweens
	for _, tween in pairs(shoulderTweens) do
		if tween then
			tween:Cancel()
		end
	end
	shoulderTweens = {}
	
	-- Use the TRUE original positions (never changes during swings)
	local originalGrip = trueOriginalGrip or tool.Grip
	
	-- Find shoulders for R15
	local rightShoulder = nil
	local leftShoulder = nil
	local originalRightC0 = trueOriginalRightC0
	local originalLeftC0 = trueOriginalLeftC0
	
	if character then
		local rightUpperArm = character:FindFirstChild("RightUpperArm")
		local leftUpperArm = character:FindFirstChild("LeftUpperArm")
		
		if rightUpperArm then
			rightShoulder = rightUpperArm:FindFirstChild("RightShoulder")
		end
		if leftUpperArm then
			leftShoulder = leftUpperArm:FindFirstChild("LeftShoulder")
		end
	end
	
	if swinging then
		-- PRE-SWING COLLISION CHECK - REMOVED to prevent blocking swings near walls
		-- local wouldHitBeforeSwing = checkSwingCollision(tool, character)
		-- if wouldHitBeforeSwing then
		-- 	print("[SwingAnimation] ⚠️ Obstacle detected - swing blocked")
		-- 	isSwinging = false
		-- 	return
		-- end
		
		-- Swing animation: rotate the tool forward and down
		-- This will make the arm swing down with the weapon
		local swingGrip = originalGrip * CFrame.Angles(math.rad(40), math.rad(30), math.rad(0))
		
		-- Tween info for swing (quick motion)
		local tweenInfo = TweenInfo.new(
			0.15, -- Duration
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out,
			0, -- Repeat count
			false, -- Reverse
			0 -- Delay
		)
		
		-- Create and play tween for tool
		local swingTween = TweenService:Create(tool, tweenInfo, {Grip = swingGrip})
		shoulderTweens.swing = swingTween
		swingTween:Play()
		
		-- Check for collision during swing - REMOVED
		-- task.delay(0.05, function() -- Check early in the swing
		-- 	if not isSwinging then return end
		-- 	local wouldHit = checkSwingCollision(tool, character)
		-- 	if wouldHit then
		-- 		print("[SwingAnimation] ⚠️ Obstacle hit mid-swing - canceling and returning")
		-- 		-- Cancel all tweens immediately
		-- 		for _, tween in pairs(shoulderTweens) do
		-- 			if tween then tween:Cancel() end
		-- 		end
		-- 		shoulderTweens = {}
				
		-- 		-- Immediately reset to TRUE original positions
		-- 		if trueOriginalGrip then
		-- 			tool.Grip = trueOriginalGrip
		-- 		end
		-- 		if rightShoulder and trueOriginalRightC0 then
		-- 			rightShoulder.C0 = trueOriginalRightC0
		-- 		end
		-- 		if leftShoulder and trueOriginalLeftC0 then
		-- 			leftShoulder.C0 = trueOriginalLeftC0
		-- 		end
				
		-- 		isSwinging = false
		-- 		return
		-- 	end
		-- end)
		
		-- Also animate the shoulders if found (R15)
		if rightShoulder then
			local swingRightC0 = originalRightC0 * CFrame.Angles(math.rad(-45), 0, 0) -- Swing arm down (negative = down)
			local rightTween = TweenService:Create(rightShoulder, tweenInfo, {C0 = swingRightC0})
			shoulderTweens.rightShoulder = rightTween
			rightTween:Play()
			
			-- Return shoulder to original position
			task.delay(0.15, function()
				if not isSwinging then return end
				local returnTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0)
				local returnTween = TweenService:Create(rightShoulder, returnTweenInfo, {C0 = originalRightC0})
				returnTween:Play()
			end)
		end
		
		if leftShoulder then
			local swingLeftC0 = originalLeftC0 * CFrame.Angles(math.rad(-20), 0, 0) -- Slight support movement (negative = down)
			local leftTween = TweenService:Create(leftShoulder, tweenInfo, {C0 = swingLeftC0})
			shoulderTweens.leftShoulder = leftTween
			leftTween:Play()
			
			-- Return shoulder to original position
			task.delay(0.15, function()
				if not isSwinging then return end
				local returnTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, false, 0)
				local returnTween = TweenService:Create(leftShoulder, returnTweenInfo, {C0 = originalLeftC0})
				returnTween:Play()
			end)
		end
		
		print("[SwingAnimation] 💨 Swinging down...")
		
		-- After swing completes, return to idle
		task.delay(0.15, function()
			if not isSwinging then return end -- Don't reset if already reset
			
			local returnTweenInfo = TweenInfo.new(
				0.2, -- Slightly slower return
				Enum.EasingStyle.Quad,
				Enum.EasingDirection.InOut,
				0,
				false,
				0
			)
			
			local returnTween = TweenService:Create(tool, returnTweenInfo, {Grip = originalGrip})
			returnTween:Play()
			
			print("[SwingAnimation] ↩️ Returning to idle position...")
			
			isSwinging = false
		end)
	else
		-- Return to idle position
		local returnTweenInfo = TweenInfo.new(
			0.2,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.InOut,
			0,
			false,
			0
		)
		
		local returnTween = TweenService:Create(tool, returnTweenInfo, {Grip = originalGrip})
		shoulderTweens.returnTween = returnTween
		returnTween:Play()
	end
end

-- Handle tool equipped
local function onToolEquipped(tool)
	currentTool = tool
	
	-- Get the SkinId attribute from the tool (this is what determines the weapon type)
	local skinId = tool:GetAttribute("SkinId")
	print("[SwingAnimation] 🔍 Tool equipped - Tool Name:", tool.Name, "| SkinId:", skinId)
	
	if not skinId then
		print("[SwingAnimation] ❌ No SkinId attribute found on tool")
		return
	end
	
	local skinMeta = SkinConfig.GetSkinMeta(skinId)
	if skinMeta then
		print("[SwingAnimation] 📋 SkinMeta found - Weapon:", skinMeta.weapon, "Rarity:", skinMeta.rarity)
	else
		print("[SwingAnimation] ❌ No SkinMeta found for SkinId:", skinId)
	end
	
	if not shouldHaveSwingAnimation(skinId) then
		print("[SwingAnimation] Tool with skin", skinId, "doesn't use swing animation")
		return
	end
	
	-- CRITICAL: Wait for server-side grip adjustments to complete
	-- Server now waits only 0.01s before applying weapon rotations/grips (equip.server.lua)
	-- Need additional time for server changes to replicate to client
	task.wait(0.3) -- Reduced from 2s to 0.3s to avoid capturing mid-swing state
	
	-- Ensure we don't capture the grip while a swing is in progress
	while isSwinging do
		task.wait(0.1)
		if currentTool ~= tool then return end -- Tool changed while waiting
	end
	
	-- Check if tool is still equipped after wait
	if currentTool ~= tool then return end
	
	-- Capture TRUE original positions ONCE on equip (AFTER grip adjustments)
	trueOriginalGrip = tool.Grip
	print("[SwingAnimation] 📌 Captured true original grip (after adjustments)")
	
	-- Get character and capture shoulder positions
	local character = player.Character or player.CharacterAdded:Wait()
	local rightShoulder = character:FindFirstChild("RightUpperArm") and character.RightUpperArm:FindFirstChild("RightShoulder")
	local leftShoulder = character:FindFirstChild("LeftUpperArm") and character.LeftUpperArm:FindFirstChild("LeftShoulder")
	
	if rightShoulder then
		trueOriginalRightC0 = rightShoulder.C0
		print("[SwingAnimation] 📌 Captured true original right shoulder C0")
	end
	if leftShoulder then
		trueOriginalLeftC0 = leftShoulder.C0
		print("[SwingAnimation] 📌 Captured true original left shoulder C0")
	end
	
	print("[SwingAnimation] ✅ Tool equipped with skin:", skinId, "- swing animation enabled")
end

-- Handle tool unequipped
local function onToolUnequipped()
	if currentTool then
		print("[SwingAnimation] Tool unequipped:", currentTool.Name)
		currentTool = nil
		isSwinging = false
		
		-- Clear true original positions
		trueOriginalGrip = nil
		trueOriginalRightC0 = nil
		trueOriginalLeftC0 = nil
		print("[SwingAnimation] 🧹 Cleared true original positions")
	end
end

-- Handle mouse click for swing
local function onMouseClick()
	print("[SwingAnimation] 🖱️ Mouse clicked")
	print("[SwingAnimation] Current tool:", currentTool)
	print("[SwingAnimation] Can swing:", canSwing)
	print("[SwingAnimation] Is swinging:", isSwinging)
	
	if not currentTool then 
		print("[SwingAnimation] ❌ No tool equipped")
		return 
	end
	if isSwinging then 
		print("[SwingAnimation] ❌ Already swinging")
		return 
	end
	
	-- Get the SkinId attribute from the tool
	local skinId = currentTool:GetAttribute("SkinId")
	print("[SwingAnimation] Tool SkinId:", skinId)
	
	if not skinId then
		print("[SwingAnimation] ❌ No SkinId found on tool")
		return
	end
	
	if not shouldHaveSwingAnimation(skinId) then 
		print("[SwingAnimation] ❌", skinId, "shouldn't have swing animation")
		return 
	end
	
	-- Get character
	local character = player.Character
	if not character then
		print("[SwingAnimation] ❌ No character found")
		return
	end
	
	-- Start swing animation (collision check happens during swing)
	isSwinging = true
	
	animateSwing(currentTool, character, true)
	
	print("[SwingAnimation] 🗡️ Swing animation triggered for", skinId)
	
	-- Cooldown before next swing
	task.delay(swingCooldown, function()
		-- Cooldown complete
	end)
end

-- Listen for character
local function onCharacterAdded(character)
	print("[SwingAnimation] Character added:", character.Name)
	
	-- Listen for tools being equipped
	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			onToolEquipped(child)
		end
	end)
	
	-- Listen for tools being unequipped
	character.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") and child == currentTool then
			onToolUnequipped()
		end
	end)
	
	-- Check if a tool is already equipped
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") then
			onToolEquipped(child)
		end
	end
end

-- Listen for mouse clicks
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		onMouseClick()
	end
end)

-- Initialize
if player.Character then
	onCharacterAdded(player.Character)
end

player.CharacterAdded:Connect(onCharacterAdded)

print("[SwingAnimation] Swing animation client initialized")
