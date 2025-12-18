local RunService = game:GetService("RunService")
local bull = script.Parent

-- Prevent running in ServerScriptService (only run when cloned into Bull)
if not bull:IsA("Model") then
	return
end

print("[BullBehavior] Script started on", bull:GetFullName())

-- 2. Find RootPart (with Fallback)
local rootPart = bull:FindFirstChild("HumanoidRootPart")
if not rootPart then
	warn("[BullBehavior] ⚠️ HumanoidRootPart not found! Searching for fallback...")
	-- Try to find the PrimaryPart
	if bull.PrimaryPart then
		rootPart = bull.PrimaryPart
		print("[BullBehavior] Using PrimaryPart as root:", rootPart.Name)
	else
		-- Find ANY BasePart to use as root
		rootPart = bull:FindFirstChildWhichIsA("BasePart", true)
		if rootPart then
			print("[BullBehavior] Using first found part as root:", rootPart.Name)
		else
			error("[BullBehavior] ❌ CRITICAL: No parts found in Bull to move!")
		end
	end
end

-- 1. Anchor RootPart for smooth CFrame movement
-- We anchor the root to prevent physics interference, but keep limbs unanchored for animation if needed (though Motor6D handles them)
for _, desc in ipairs(bull:GetDescendants()) do
	if desc:IsA("BasePart") then
		desc.Anchored = false
		desc.CanCollide = false -- Disable all collisions to prevent snagging
	end
end
if rootPart then
	rootPart.Anchored = true
	rootPart.CanCollide = true -- Enable root collision to prevent falling through floor if logic fails
end
print("[BullBehavior] ✅ Anchored RootPart, Unanchored Limbs, Disabled Collisions")

-- Capture initial Y level to prevent sinking/flying
local initialY = rootPart.Position.Y
print("[BullBehavior] 🔒 Locked Y Level to:", initialY)

-- Set Network Ownership (Not needed if Anchored, but good practice if we ever unanchor)
if rootPart:IsA("BasePart") and not rootPart.Anchored and rootPart:CanSetNetworkOwnership() then
	rootPart:SetNetworkOwner(nil)
end

-- Ensure AnimationController exists for Animation
local animController = bull:FindFirstChild("AnimationController")
if not animController then
	animController = Instance.new("AnimationController")
	animController.Name = "AnimationController"
	animController.Parent = bull
end

-- Setup Health Attributes (No Humanoid)
bull:SetAttribute("MaxHealth", 3000)
bull:SetAttribute("Health", 3000)
print("[BullBehavior] ✅ Health Attributes Initialized: 3000/3000")

local arena = bull.Parent

local ANIMATION_ID = "rbxassetid://71635624642744"
local RUN_ANIMATION_ID = "rbxassetid://89751156154012"
local CHARGE_ANIMATION_ID = "rbxassetid://117848803109655"
local UP_ANIMATION_ID = "rbxassetid://94030278906722"
local HEADBUTT_ANIMATION_ID = "rbxassetid://120738414090672"
local WALK_SPEED = 24 -- Increased to 24

-- Load Animation
local walkAnim = Instance.new("Animation")
walkAnim.AnimationId = ANIMATION_ID
local runAnim = Instance.new("Animation")
runAnim.AnimationId = RUN_ANIMATION_ID
local chargeAnim = Instance.new("Animation")
chargeAnim.AnimationId = CHARGE_ANIMATION_ID
local upAnim = Instance.new("Animation")
upAnim.AnimationId = UP_ANIMATION_ID
local headbuttAnim = Instance.new("Animation")
headbuttAnim.AnimationId = HEADBUTT_ANIMATION_ID

local animator = animController:FindFirstChild("Animator")
if not animator then
	animator = Instance.new("Animator")
	animator.Parent = animController
end

local track
local runTrack
local chargeTrack
local upTrack
local headbuttTrack
if animator then
	track = animator:LoadAnimation(walkAnim)
	track.Looped = true
	
	runTrack = animator:LoadAnimation(runAnim)
	runTrack.Looped = true
	
	chargeTrack = animator:LoadAnimation(chargeAnim)
	chargeTrack.Looped = true
	
	upTrack = animator:LoadAnimation(upAnim)
	upTrack.Looped = true

	headbuttTrack = animator:LoadAnimation(headbuttAnim)
	headbuttTrack.Priority = Enum.AnimationPriority.Action
	headbuttTrack.Looped = false
end

-- ==========================================
-- STEP DAMAGE SYSTEM
-- ==========================================
local Players = game:GetService("Players")
local STEP_DAMAGE = 10
local DAMAGE_RADIUS = 45 -- Studs from bull center
local STEP_INTERVAL = 0.4 -- How often to check for damage when bull is moving/attacking

local lastDamageTime = {}
local isHeadbuttActive = false -- Track if headbutt is active for damage zone

-- Create visual damage zone (red circle on ground)
local damageZone = Instance.new("Part")
damageZone.Name = "DamageZone"
damageZone.Shape = Enum.PartType.Cylinder
damageZone.Size = Vector3.new(0.2, DAMAGE_RADIUS * 2, DAMAGE_RADIUS * 2) -- Very thin, Diameter, Diameter
damageZone.Anchored = true
damageZone.CanCollide = false
damageZone.CastShadow = false
damageZone.Material = Enum.Material.Neon
damageZone.Color = Color3.fromRGB(255, 0, 0)
damageZone.Transparency = 1 -- Hidden by default
damageZone.Parent = bull

-- Raycast params to find floor
local damageRaycastParams = RaycastParams.new()
damageRaycastParams.FilterDescendantsInstances = {bull}
damageRaycastParams.FilterType = Enum.RaycastFilterType.Exclude

-- Find or create center attachment for tracking bull's animated center
local centerAttachment = nil

-- Look for an attachment named "CenterAttachment" or "RootAttachment" on the bull
local function findCenterAttachment()
	-- First check for custom CenterAttachment
	centerAttachment = bull:FindFirstChild("CenterAttachment", true)
	if centerAttachment then
		print("[BullBehavior] ✅ Found CenterAttachment for damage zone tracking")
		return
	end
	
	-- Try RootAttachment on HumanoidRootPart
	if rootPart then
		centerAttachment = rootPart:FindFirstChild("RootAttachment")
		if centerAttachment then
			print("[BullBehavior] ✅ Using RootAttachment for damage zone tracking")
			return
		end
	end
	
	-- Look for any attachment on the body/torso
	for _, part in ipairs(bull:GetDescendants()) do
		if part:IsA("Attachment") and (part.Name:find("Root") or part.Name:find("Body") or part.Name:find("Torso")) then
			centerAttachment = part
			print("[BullBehavior] ✅ Using " .. part.Name .. " for damage zone tracking")
			return
		end
	end
	
	print("[BullBehavior] ⚠️ No center attachment found, will use rootPart position")
end

findCenterAttachment()

-- Get the position to place the damage zone under
local function getBullCenter()
	if centerAttachment then
		return centerAttachment.WorldPosition
	end
	return rootPart.Position
end

-- Position the zone flat on the ground directly under the bull's visual center
local function updateDamageZonePosition()
	if rootPart and damageZone and isHeadbuttActive then
		-- Get the center position (from attachment or rootPart)
		local bullCenter = getBullCenter()
		local rayOrigin = bullCenter + Vector3.new(0, 5, 0)
		local rayDirection = Vector3.new(0, -50, 0)
		local rayResult = workspace:Raycast(rayOrigin, rayDirection, damageRaycastParams)
		
		local floorY = initialY - 10 -- fallback
		
		if rayResult then
			floorY = rayResult.Position.Y + 0.1 -- Slightly above floor to prevent z-fighting
		end
		
		-- Position directly under bull's center, on floor, rotated flat
		damageZone.CFrame = CFrame.new(bullCenter.X, floorY, bullCenter.Z) * CFrame.Angles(0, 0, math.rad(90))
	end
end

-- Show/hide damage zone (only during headbutt)
local function showDamageZone(show)
	isHeadbuttActive = show
	if damageZone then
		damageZone.Transparency = show and 0 or 1
	end
end

-- Damage players in radius
local function damagePlayersInRadius()
	if not isHeadbuttActive then return end
	
	local bullCenter = getBullCenter() -- Use the attachment position, same as the circle
	
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			local humanoid = player.Character:FindFirstChild("Humanoid")
			local hrp = player.Character:FindFirstChild("HumanoidRootPart")
			
			if humanoid and hrp and humanoid.Health > 0 then
				local distance = (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(bullCenter.X, 0, bullCenter.Z)).Magnitude
				
				if distance <= DAMAGE_RADIUS then
					humanoid:TakeDamage(STEP_DAMAGE)
					print("[BullBehavior] 💥 Step damage! " .. player.Name .. " took " .. STEP_DAMAGE .. " damage (dist: " .. math.floor(distance) .. ")")
				end
			end
		end
	end
end

-- Time-based damage check (since animation markers don't fire on server)
local lastStepCheck = 0
local function checkStepDamage()
	if not isHeadbuttActive then return end
	
	local now = tick()
	if now - lastStepCheck >= STEP_INTERVAL then
		lastStepCheck = now
		
		-- Only damage during headbutt animation
		if headbuttTrack and headbuttTrack.IsPlaying then
			damagePlayersInRadius()
		end
	end
end

print("[BullBehavior] ✅ Step Damage System Initialized (Radius: " .. DAMAGE_RADIUS .. ", Damage: " .. STEP_DAMAGE .. ")")
-- ==========================================

local isGameActive = false -- Controlled by TrafficLightState
local isBursting = false   -- Controlled by internal loop

local moveConnection
local logicThread

local WANDER_ROTATION_DURATION = 2.0 -- Same speed as aggro rotation
local targetWanderRotation = nil
local wanderRotationStartTime = 0
local isWanderRotating = false

local function startLogic()
	print("[BullBehavior] Starting Logic Loop")
	if logicThread then task.cancel(logicThread) end
	
	logicThread = task.spawn(function()
		while isGameActive do
			-- 1. Pick new direction (smooth rotation instead of instant)
			local randomAngle = math.rad(math.random(0, 360))
			targetWanderRotation = CFrame.Angles(0, randomAngle, 0)
			wanderRotationStartTime = os.clock()
			isWanderRotating = true
			
			local startTime = os.clock()
			local directionDuration = math.random(10, 20)
			
			-- Continuous movement (no pausing)
			-- isBursting = true -- Removed to prevent any logic pauses
			
			while os.clock() - startTime < directionDuration do
				if not isGameActive then break end
				task.wait(0.1)
			end
			isWanderRotating = false
		end
		print("[BullBehavior] Logic Loop Ended")
	end)
end

local function updateMovement(dt)
	if isGameActive and rootPart and not isAttacking then
		-- Smooth rotation during wandering
		if isWanderRotating and targetWanderRotation then
			local rotationElapsed = os.clock() - wanderRotationStartTime
			local alpha = math.min(rotationElapsed / WANDER_ROTATION_DURATION, 1)
			local currentRotation = rootPart.CFrame.Rotation
			local targetRot = CFrame.new(rootPart.Position) * targetWanderRotation
			rootPart.CFrame = CFrame.new(rootPart.Position) * currentRotation:Lerp(targetRot.Rotation, alpha * 0.1)
			if alpha >= 1 then
				isWanderRotating = false
			end
		end
		
		-- Wall Check
		local rayOrigin = rootPart.Position
		local lookVec = rootPart.CFrame.LookVector
		-- Flatten look vector to ensure we check horizontally (ignore floor/ceiling)
		local flatLook = Vector3.new(lookVec.X, 0, lookVec.Z).Unit
		local rightVec = rootPart.CFrame.RightVector
		local flatRight = Vector3.new(rightVec.X, 0, rightVec.Z).Unit

		-- Whiskers: Center, Left, Right to prevent corner clipping
		local detectionDistance = 40
		local sideDetectionAngle = 0.5 -- Roughly 26 degrees
		
		local rays = {
			flatLook * detectionDistance, -- Center
			(flatLook - flatRight * sideDetectionAngle).Unit * detectionDistance, -- Left
			(flatLook + flatRight * sideDetectionAngle).Unit * detectionDistance  -- Right
		}
		
		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = {bull, arena:FindFirstChild("ArenaPlatform")}
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		
		local hitWall = false
		for _, rayDir in ipairs(rays) do
			local result = workspace:Raycast(rayOrigin, rayDir, raycastParams)
			if result then
				hitWall = true
				break
			end
		end

		if hitWall then
			-- Turn
			-- print("[BullBehavior] Wall hit! Turning...")
			local turnAngle = math.rad(math.random(150, 210)) -- Turn roughly 180 degrees (sharper bounce)
			rootPart.CFrame = rootPart.CFrame * CFrame.Angles(0, turnAngle, 0)
		end
		
		-- Always move forward (even if we just turned)
		-- Calculate new position with Y-lock
		local currentPos = rootPart.Position
		local forward = rootPart.CFrame.LookVector
		local flatForward = Vector3.new(forward.X, 0, forward.Z).Unit -- Ensure horizontal movement only
		
		local newPos = currentPos + (flatForward * WALK_SPEED * dt)
		newPos = Vector3.new(newPos.X, initialY, newPos.Z) -- Force Y level
		
		rootPart.CFrame = CFrame.new(newPos) * rootPart.CFrame.Rotation
	end
end

local isAttacking = false
local attackThread
local attackMoveConnection
local lastAttackStart = 0 -- Track when attack started

local function stopAttack()
	isAttacking = false
	showDamageZone(false) -- Hide damage zone when attack ends
	if attackThread then task.cancel(attackThread) attackThread = nil end
	if attackMoveConnection then attackMoveConnection:Disconnect() attackMoveConnection = nil end
	if upTrack then upTrack:Stop() end
	if chargeTrack then chargeTrack:Stop() end
	if runTrack then runTrack:Stop() end
	if headbuttTrack then headbuttTrack:Stop() end
end

local function startAttack()
	stopAttack()
	isAttacking = true
	lastAttackStart = os.clock()
	
	-- Stop Wandering Logic
	if logicThread then task.cancel(logicThread) logicThread = nil end
	if moveConnection then moveConnection:Disconnect() moveConnection = nil end
	if track then track:Stop() end
	
	print("[BullBehavior] ⚔️ STARTING ATTACK SEQUENCE")
	
	attackThread = task.spawn(function()
		local targetVal = bull:FindFirstChild("TargetPlayer")
		local targetPlayer = targetVal and targetVal.Value
		
		if not targetPlayer then
			warn("[BullBehavior] ❌ TargetPlayer Value is missing or nil!")
			isAttacking = false
			return
		end
		
		if not targetPlayer.Character then
			warn("[BullBehavior] ❌ TargetPlayer has no Character!")
			isAttacking = false
			return
		end
		
		local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
		if not targetRoot then 
			warn("[BullBehavior] ❌ TargetPlayer has no RootPart!")
			return 
		end
		
		print("[BullBehavior] 🎯 Target identified: " .. targetPlayer.Name)
		
		-- 1. Face Player
		local lookAt = CFrame.lookAt(rootPart.Position, Vector3.new(targetRoot.Position.X, rootPart.Position.Y, targetRoot.Position.Z))
		rootPart.CFrame = lookAt
		
		-- 2. Up Animation - REMOVED (now plays during aiming phase instead to avoid double-play)
		
		if not isAttacking then return end -- Check if cancelled
		
		-- 3. Charge Animation (REMOVED)
		-- if chargeTrack then
		-- 	print("[BullBehavior] Playing CHARGE animation (Length: " .. tostring(chargeTrack.Length) .. ")")
		-- 	chargeTrack:Play()
		-- 	if chargeTrack.Length > 0 then
		-- 		task.wait(chargeTrack.Length)
		-- 	else
		-- 		task.wait(1) -- Fallback duration
		-- 	end
		-- 	chargeTrack:Stop()
		-- else
		-- 	warn("[BullBehavior] ⚠️ CHARGE animation track missing!")
		-- 	task.wait(1)
		-- end
		
		if not isAttacking then return end
		
		-- 4. Run & Chase (don't start run animation yet - wait until aiming is done)
		print("[BullBehavior] 🏃 CHAAAAARGE!")
		-- Run animation will start after aiming phase
		
		local lastHeadbuttTime = 0
		local chargeCycleStart = os.clock()
		local lockedTarget = nil
		local hasReachedTarget = false
		local stopPosition = nil -- Store the position where we stopped to prevent sliding
		local isFirstCharge = true -- Flag for the initial 2s aim delay
		local randomLookRotation = nil -- For random thrashing
		local nextThrashTime = 0
		local isRotating = false -- Track if we're currently rotating
		local rotationStartTime = 0
		local ROTATION_DURATION = 0.4 -- Quick rotation before headbutting
		local isWaitingForHeadbutt = false -- Track if we're waiting for headbutt to finish
		local ENTER_THRASH_DISTANCE = 40 -- Enter thrashing mode when this close
		local EXIT_THRASH_DISTANCE = 60 -- Only exit thrashing to charge again if beyond this
		
		attackMoveConnection = RunService.Heartbeat:Connect(function(dt)
			if not isAttacking or not targetRoot then return end
			
			-- Update damage zone position and check for damage
			updateDamageZonePosition()
			checkStepDamage()
			
			local now = os.clock()
			local timeInCycle = now - chargeCycleStart
			
			-- Determine Cycle Duration
			local cycleDuration = isFirstCharge and 7 or 5
			local aimDuration = isFirstCharge and 2 or 0
			
			-- Reset Cycle - but NOT if we're mid-animation (rotating or headbutting)
			if timeInCycle > cycleDuration and not isWaitingForHeadbutt and not isRotating then
				chargeCycleStart = now
				timeInCycle = 0
				lockedTarget = nil
				hasReachedTarget = false
				stopPosition = nil
				randomLookRotation = nil
				isFirstCharge = false -- Subsequent charges are instant
				print("[BullBehavior] 🔄 Starting new Charge Cycle (Instant)")
			end
			
			local currentPos = rootPart.Position
			
			if timeInCycle < aimDuration then
				-- PHASE 1: AIMING (Only for first charge)
				-- Track player rotationally, but don't move
				local targetPos = targetRoot.Position
				local lookAt = CFrame.lookAt(currentPos, Vector3.new(targetPos.X, currentPos.Y, targetPos.Z))
				rootPart.CFrame = rootPart.CFrame:Lerp(lookAt, 0.2) -- Smooth turn
				
				-- Stop Running
				if runTrack and runTrack.IsPlaying then runTrack:Stop(0.2) end
				
				-- Play "Up" animation (Roar) while aiming
				if upTrack and not upTrack.IsPlaying then upTrack:Play(0.1) end
				if headbuttTrack and headbuttTrack.IsPlaying then headbuttTrack:Stop(0.1) end

			else
				-- PHASE 2: CHARGING
				-- Lock target if not locked
				if not lockedTarget then
					lockedTarget = targetRoot.Position
					print("[BullBehavior] 🔒 Target Locked! Charging!")
					if upTrack then upTrack:Stop(0.1) end -- Stop roaring
				end
				
				local distToTarget = (Vector3.new(lockedTarget.X, currentPos.Y, lockedTarget.Z) - currentPos).Magnitude
				
				-- Sticky radius: enter thrashing at 40 studs, only exit at 60+ studs
				local shouldCharge = not hasReachedTarget and distToTarget > ENTER_THRASH_DISTANCE
				-- Don't exit thrash while any animation is playing (rotating or headbutting)
				local shouldExitThrash = hasReachedTarget and distToTarget > EXIT_THRASH_DISTANCE and not isWaitingForHeadbutt and not isRotating
				
				if shouldCharge or shouldExitThrash then
					-- CHARGE! (or resume charging if player ran away)
					if shouldExitThrash then
						hasReachedTarget = false
						stopPosition = nil
						isRotating = false
						isWaitingForHeadbutt = false
						if track and track.IsPlaying then track:Stop(0.1) end
						if headbuttTrack and headbuttTrack.IsPlaying then headbuttTrack:Stop(0.1) end
						print("[BullBehavior] 🏃 Player escaped! Resuming charge!")
					end
					
					local direction = (Vector3.new(lockedTarget.X, currentPos.Y, lockedTarget.Z) - currentPos).Unit
					
					if runTrack and not runTrack.IsPlaying then runTrack:Play(0.1, 1, 2) end
					
					local newPos = currentPos + (direction * WALK_SPEED * 4 * dt)
					newPos = Vector3.new(newPos.X, initialY, newPos.Z)
					rootPart.CFrame = CFrame.new(newPos, newPos + direction)
				else
					-- STOPPED (Reached target or staying in thrash zone)
					if not hasReachedTarget then
						hasReachedTarget = true
						stopPosition = currentPos -- Capture position ONCE to prevent sliding
						print("[BullBehavior] 🛑 Reached Target - Thrashing Area")
						nextThrashTime = 0 -- Start thrashing immediately
					end
					
					if runTrack then runTrack:Stop(0) end
					
					-- Random Thrashing Logic with proper animation sequencing
					-- State machine: idle -> rotating (walk anim) -> headbutting -> idle
					
					if isWaitingForHeadbutt then
						-- Wait for headbutt animation to finish completely
						if not headbuttTrack or not headbuttTrack.IsPlaying then
							isWaitingForHeadbutt = false
							showDamageZone(false) -- Hide damage zone when headbutt ends
							nextThrashTime = os.clock() + 0.5 -- Short delay before next rotation
							print("[BullBehavior] 🐂 Headbutt finished, ready for next rotation")
						end
					elseif isRotating then
						-- Currently rotating - check if rotation is complete
						local rotationElapsed = os.clock() - rotationStartTime
						if rotationElapsed >= ROTATION_DURATION then
							-- Rotation complete, stop walk and start headbutt
							isRotating = false
							if track and track.IsPlaying then track:Stop(0.1) end
							
							-- Play headbutt animation
							if headbuttTrack and not headbuttTrack.IsPlaying then
								headbuttTrack:Play(0.1)
								headbuttTrack:AdjustSpeed(1.1) -- 10% faster
								showDamageZone(true) -- Show damage zone when headbutt starts
								isWaitingForHeadbutt = true
								print("[BullBehavior] 🐂 Starting headbutt animation")
							end
						end
						-- Continue rotating during rotation phase (lerp happens below)
					elseif os.clock() > nextThrashTime then
						-- Start new rotation
						isRotating = true
						rotationStartTime = os.clock()
						
						-- Pick new random direction
						local currentY = rootPart.CFrame.Rotation
						local turnAmount = math.rad(math.random(60, 120) * (math.random() > 0.5 and 1 or -1))
						randomLookRotation = currentY * CFrame.Angles(0, turnAmount, 0)
						
						-- Play walk animation while rotating
						if track and not track.IsPlaying then
							track:Play(0.1, 1, 2)
							print("[BullBehavior] 🚶 Walking animation started for rotation")
						end
						-- Stop headbutt if somehow still playing
						if headbuttTrack and headbuttTrack.IsPlaying then headbuttTrack:Stop(0.1) end
					end

					-- Anti-Slide: Lock to stopPosition with Random Rotation
					if stopPosition and randomLookRotation then
						-- Lock Position, Lerp Rotation to random direction
						-- Use faster lerp when actively rotating, slower when headbutting/idle
						local lerpSpeed = isRotating and 0.15 or 0.02
						rootPart.CFrame = CFrame.new(stopPosition) * rootPart.CFrame.Rotation:Lerp(randomLookRotation, lerpSpeed)
						rootPart.Velocity = Vector3.zero
						rootPart.RotVelocity = Vector3.zero
					end
				end
			end
		end)
	end)
end

bull:GetAttributeChangedSignal("TrafficLightState"):Connect(function()
	local state = bull:GetAttribute("TrafficLightState")
	print("[BullBehavior] State changed to:", state)
	
	if state == "Green" then
		-- Check if we need to maintain aggro
		if isAttacking then
			print("[BullBehavior] 🛑 Light is Green, but extending aggro for 15s")
			
			task.delay(15, function()
				-- Re-check state after delay
				if bull:GetAttribute("TrafficLightState") == "Green" then
					print("[BullBehavior] 🟢 Aggro extension expired, returning to Green state")
					stopAttack()
					
					-- Start Wandering
					isGameActive = true
					if track and not track.IsPlaying then 
						track:Play(0.1, 1, 2) 
					end
					if not moveConnection then
						moveConnection = RunService.Heartbeat:Connect(updateMovement)
					end
					startLogic()
				end
			end)
			return -- Don't stop immediately
		end

		-- Stop Attack
		stopAttack()
		
		-- Start Wandering
		isGameActive = true
		if track and not track.IsPlaying then 
			track:Play(0.1, 1, 2) 
		end
		if not moveConnection then
			moveConnection = RunService.Heartbeat:Connect(updateMovement)
		end
		startLogic()
		
	elseif state == "Red" then
		-- Continue Wandering (Do nothing)
		-- The Bull now wanders during Red Light too.
		-- Attack is triggered ONLY if damaged (see HealthChanged below).
		isGameActive = true
		if not logicThread and not isAttacking then
			startLogic()
		end
	end
end)

-- Health Changed Listener for Attack Trigger
local lastHealth = bull:GetAttribute("Health") or 3000
bull:GetAttributeChangedSignal("Health"):Connect(function()
	local health = bull:GetAttribute("Health")
	-- print("[BullBehavior] Health Changed: " .. lastHealth .. " -> " .. health)
	if health < lastHealth then
		-- Damage taken
		local state = bull:GetAttribute("TrafficLightState")
		print("[BullBehavior] Damage taken! Health: " .. health .. " State: " .. tostring(state) .. " Attacking: " .. tostring(isAttacking))
		
		if state == "Red" and not isAttacking then
			print("[BullBehavior] 😡 RED LIGHT VIOLATION! ATTACKING!")
			startAttack()
			
			-- Signal ArenaManager to set 20s aggro timer (first hit)
			bull:SetAttribute("AttackTriggered", true)
		elseif state == "Red" and isAttacking then
			-- Already attacking during red - signal for +5s extension
			print("[BullBehavior] 😡 Hit again while attacking! Signaling +5s extension")
			bull:SetAttribute("AttackTriggered", true)
		elseif state ~= "Red" then
			print("[BullBehavior] Ignored damage (State is " .. tostring(state) .. ")")
		end
		
		-- Heal back to full to prevent death
		if health <= 0 then
			print("[BullBehavior] ⚠️ Bull died! Reviving...")
			bull:SetAttribute("Health", bull:GetAttribute("MaxHealth"))
			lastHealth = bull:GetAttribute("MaxHealth")
		end
		return
	end
	lastHealth = health
end)

-- Initial check
local currentState = bull:GetAttribute("TrafficLightState")
print("[BullBehavior] Initial State:", currentState)
if currentState == "Green" then
	isGameActive = true
	if track and not track.IsPlaying then 
		track:Play(0.1, 1, 2) 
	end
	if not moveConnection then
		moveConnection = RunService.Heartbeat:Connect(updateMovement)
	end
	startLogic()
elseif currentState == "Red" then
	-- startAttack() -- DISABLED: Wait for hit
end

-- Aggro timeout monitor - checks if aggro time has expired and stops attack
task.spawn(function()
	while bull and bull.Parent do
		task.wait(0.5)
		
		if isAttacking then
			local aggroEndTime = bull:GetAttribute("AggroEndTime") or 0
			if aggroEndTime > 0 and os.time() >= aggroEndTime then
				print("[BullBehavior] ⏰ Aggro timer expired! Stopping attack and returning to wander.")
				stopAttack()
				bull:SetAttribute("AggroEndTime", 0)
				
				-- Return to wandering
				isGameActive = true
				if track and not track.IsPlaying then 
					track:Play(0.1, 1, 2) 
				end
				if not moveConnection then
					moveConnection = RunService.Heartbeat:Connect(updateMovement)
				end
				startLogic()
			end
		end
	end
end)

-- Reset function - called when arena is freed to reset bull to initial state
local function resetBull()
	print("[BullBehavior] 🔄 Resetting bull to initial state")
	
	-- Stop all attacks and animations
	stopAttack()
	if logicThread then task.cancel(logicThread) logicThread = nil end
	if moveConnection then moveConnection:Disconnect() moveConnection = nil end
	if track then track:Stop() end
	
	-- Reset state
	isGameActive = false
	isAttacking = false
	bull:SetAttribute("AggroEndTime", 0)
	bull:SetAttribute("AttackTriggered", false)
	bull:SetAttribute("Health", bull:GetAttribute("MaxHealth") or 3000)
	
	print("[BullBehavior] ✅ Bull reset complete")
end

-- Listen for reset signal from ArenaManager
bull:GetAttributeChangedSignal("ResetBull"):Connect(function()
	if bull:GetAttribute("ResetBull") then
		resetBull()
		bull:SetAttribute("ResetBull", false)
	end
end)
