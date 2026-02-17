--[[
	NPCController - Shared AI and attack logic for all NPCs
	
	USAGE in NPC script:
	```lua
	local NPCController = require(ReplicatedStorage.Shared.NPCController)
	local NPCConfig = require(ReplicatedStorage.Shared.NPCConfig)
	
	NPCController.init("End")  -- Just pass the config name!
	```
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")

local NPCController = {}

-- Cached references
local remoteEvents
local spawnEffectEvent
local forceAttackEvent
local NPCConfig

-- Debug settings
local DEBUG_ATTACK_SELECT = true
local forcedAttack = 0

-- Initialize remote events
local function setupRemoteEvents()
	remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteEvents then
		remoteEvents = Instance.new("Folder")
		remoteEvents.Name = "RemoteEvents"
		remoteEvents.Parent = ReplicatedStorage
	end
	
	spawnEffectEvent = remoteEvents:FindFirstChild("SpawnEffectEvent")
	if not spawnEffectEvent then
		spawnEffectEvent = Instance.new("RemoteEvent")
		spawnEffectEvent.Name = "SpawnEffectEvent"
		spawnEffectEvent.Parent = remoteEvents
	end
	
	forceAttackEvent = remoteEvents:FindFirstChild("ForceAttackEvent")
	if not forceAttackEvent then
		forceAttackEvent = Instance.new("RemoteEvent")
		forceAttackEvent.Name = "ForceAttackEvent"
		forceAttackEvent.Parent = remoteEvents
	end
	
	forceAttackEvent.OnServerEvent:Connect(function(player, attackId)
		if DEBUG_ATTACK_SELECT then
			forcedAttack = attackId
			print("[NPC DEBUG] Force attack set to:", forcedAttack == 0 and "RANDOM" or forcedAttack)
		end
	end)
end

-- Get spawn position with raycast to terrain
local function getSpawnPosition(part)
	local offsetX = math.random(-5, 5)
	local offsetZ = math.random(-5, 5)
	local pos = part.Position + Vector3.new(offsetX, 0, offsetZ)
	local origin = pos + Vector3.new(0, 50, 0)
	local ray = Workspace:Raycast(origin, Vector3.new(0, -500, 0))
	if ray then
		return ray.Position + Vector3.new(0, 3, 0)
	else
		return pos + Vector3.new(0, 3, 0)
	end
end

-- Get nearest player within range
local function getNearestPlayer(npcPos, maxDist)
	local nearest = nil
	local nearestDist = maxDist
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
			local pHrp = p.Character.HumanoidRootPart
			local dist = (pHrp.Position - npcPos).Magnitude
			if dist <= nearestDist then
				nearest = p
				nearestDist = dist
			end
		end
	end
	return nearest, nearestDist
end

-- Load an animation track
local function loadAnimation(animator, animId)
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://" .. animId
	local track = animator:LoadAnimation(anim)
	track.Looped = false
	return track
end

-- ============================================================
-- HITBOX AND DAMAGE SYSTEM
-- ============================================================

local activeHitboxes = {}
local effectsFolder = ReplicatedStorage:WaitForChild("Effects")

-- Create a Hitbox2 at the specified location for damage
local function createHitbox(npc, hitboxAttachmentName, damage, duration)
	local hitbox2Model = effectsFolder:FindFirstChild("Hitbox2")
	if not hitbox2Model then
		warn("[NPCController] Hitbox2 template not found in Effects folder")
		return
	end
	
	-- Find the attachment on the NPC where the hitbox should spawn
	local attachment = npc:FindFirstChild(hitboxAttachmentName, true)
	if not attachment then
		-- Fallback to HumanoidRootPart if attachment not found
		attachment = npc:FindFirstChild("HumanoidRootPart")
		print("[NPCController] Attachment '" .. hitboxAttachmentName .. "' not found, using HumanoidRootPart instead")
	end
	
	if not attachment then
		warn("[NPCController] Neither attachment nor HumanoidRootPart found on NPC:", npc.Name)
		return
	end
	
	-- Clone the hitbox
	local hitboxClone = hitbox2Model:Clone()
	hitboxClone.Parent = Workspace
	
	print("[NPCController] Created hitbox for", npc.Name, "damage:", damage, "duration:", duration)
	
	-- Find the actual hitbox part (should be named "Hitbox2")
	local hitboxPart = hitboxClone:FindFirstChild("Hitbox2")
	if not hitboxPart then
		hitboxPart = hitboxClone:FindFirstChildWhichIsA("BasePart")
	end
	
	if not hitboxPart then
		warn("[NPCController] No hitbox part found in Hitbox2 model!")
		hitboxClone:Destroy()
		return
	end
	
	-- Position the hitbox at the attachment
	local attachPos = attachment:IsA("Attachment") and attachment.WorldPosition or attachment.Position
	hitboxPart.CFrame = CFrame.new(attachPos)
	
	-- Make hitbox intangible with the world, only detect touches
	hitboxPart.CanCollide = false
	hitboxPart.Massless = true
	
	-- Track the hitbox
	activeHitboxes[hitboxClone] = {
		npc = npc,
		damage = damage,
		hitPlayers = {},
		hitboxPart = hitboxPart,
	}
	
	-- Handle collisions with players
	local function handleCollision(hit)
		if not hit then return end
		
		-- Find player character and humanoid
		local humanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if player then
				humanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
			end
		end
		
		if not humanoid or humanoid:FindFirstAncestorOfClass("Model") == npc then
			return -- Not a player, or is the NPC itself
		end
		
		-- Check if we already hit this player with this hitbox
		local hitboxData = activeHitboxes[hitboxClone]
		if hitboxData and hitboxData.hitPlayers[humanoid.Parent] then
			return -- Already damaged this player with this hitbox
		end
		
		-- Apply damage
		if hitboxData then
			if _G.damagePlayer then
				_G.damagePlayer(Players:GetPlayerFromCharacter(humanoid.Parent), damage)
				print("[NPCController] Hitbox HIT player:", humanoid.Parent.Name, "for", damage, "damage")
			else
				-- Fallback: use humanoid:TakeDamage
				humanoid:TakeDamage(damage)
				print("[NPCController] Hitbox HIT player:", humanoid.Parent.Name, "for", damage, "damage (fallback)")
			end
			
			hitboxData.hitPlayers[humanoid.Parent] = true
		end
	end
	
	-- Detect touches
	hitboxPart.Touched:Connect(handleCollision)
	
	-- Clean up after duration
	task.delay(duration or 0.5, function()
		if hitboxClone and hitboxClone.Parent then
			hitboxClone:Destroy()
			activeHitboxes[hitboxClone] = nil
		end
	end)
	
	return hitboxClone
end

-- Spawn effect helper
local function spawnEffect(effectConfig, npc, targetHRP)
	print("[NPCController] ===== spawnEffect called =====")
	print("[NPCController] Effect:", effectConfig.effectName, "Type:", effectConfig.effectType or "standard")
	print("[NPCController] Attachment:", effectConfig.attachment, "NPC:", npc.Name)
	
	local attachment = nil
	
	-- If bodyPart is specified, look in that specific body part
	if effectConfig.bodyPart then
		local bodyPart = npc:FindFirstChild(effectConfig.bodyPart)
		if bodyPart then
			attachment = bodyPart:FindFirstChild(effectConfig.attachment)
		end
		if not attachment then
			warn("[NPCController] Attachment not found:", effectConfig.attachment, "in body part:", effectConfig.bodyPart)
			return
		end
	else
		-- Default: search entire NPC
		attachment = npc:FindFirstChild(effectConfig.attachment, true)
		if not attachment then
			warn("[NPCController] Attachment not found:", effectConfig.attachment)
			return
		end
	end
	
	-- Get position - Parts use Position, Attachments use WorldPosition
	local attachmentPos = attachment:IsA("Attachment") and attachment.WorldPosition or attachment.Position
	print("[NPCController] Found attachment:", effectConfig.attachment, "at:", attachment:GetFullName(), "WorldPos:", attachmentPos)
	
	local targetPos = nil
	if effectConfig.targetPlayer and targetHRP then
		targetPos = targetHRP.Position
	elseif effectConfig.useExactPosition then
		targetPos = attachmentPos
		print("[NPCController] Using exact position:", targetPos)
	elseif effectConfig.effectType == "groundSpawn" or effectConfig.effectType == "groundVFX" then
		-- Ground effects need a target position to know direction - use player position
		if targetHRP then
			targetPos = targetHRP.Position
			print("[NPCController] Ground effect targeting player at:", targetPos)
		end
	end
	
	-- Build extra data for special effect types
	local extraData = nil
	if effectConfig.effectType or effectConfig.effectChild or effectConfig.emitCount or effectConfig.enableOnly or effectConfig.spawnOnFloor or effectConfig.density or effectConfig.spawnDuration or effectConfig.bodyPart or effectConfig.scale or effectConfig.lockToPart or effectConfig.followAttachment then
		extraData = {
			effectType = effectConfig.effectType,
			speed = effectConfig.speed,
			spawnDistance = effectConfig.spawnDistance,
			effectChild = effectConfig.effectChild,
			emitCount = effectConfig.emitCount,
			enableOnly = effectConfig.enableOnly,
			spawnOnFloor = effectConfig.spawnOnFloor,
			density = effectConfig.density,
			spawnDuration = effectConfig.spawnDuration,
			bodyPart = effectConfig.bodyPart,
			scale = effectConfig.scale,
			lockToPart = effectConfig.lockToPart,
			followAttachment = effectConfig.followAttachment,
		}
		print("[NPCController] ExtraData: type =", extraData.effectType, "bodyPart =", extraData.bodyPart, "scale =", extraData.scale, "follow =", extraData.followAttachment)
	end
	
	print("[NPCController] FIRING SpawnEffect event:", effectConfig.effectName, "to all clients")
	spawnEffectEvent:FireAllClients(
		effectConfig.effectName,
		npc,
		effectConfig.attachment,
		targetPos,
		effectConfig.duration or 2,
		extraData
	)
end

-- Execute a melee attack
local function executeMeleeAttack(npc, config, attackConfig, tracks, targetHRP, setFrozen)
	print("[NPCController] ========== MELEE ATTACK STARTING ==========")
	print("[NPCController] NPC:", npc.Name, "Attack animation:", attackConfig.animation)
	print("[NPCController] Effects count:", attackConfig.effects and #attackConfig.effects or 0)
	
	local hrp = npc:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	
	local meleeRange = attackConfig.meleeRange or 20  -- Must be within this range to attack
	
	-- Spawn "start" effects immediately when attack begins (or with delay)
	for _, effect in ipairs(attackConfig.effects or {}) do
		if effect.trigger == "start" then
			local function spawnEffectWithHitbox()
				spawnEffect(effect, npc, targetHRP)
				
				-- Create hitbox if damage is configured
				if effect.damage and effect.hitboxAttachment then
					task.spawn(function()
						createHitbox(npc, effect.hitboxAttachment, effect.damage, effect.hitboxDuration or 0.5)
					end)
				end
			end
			
			if effect.delay and effect.delay > 0 then
				print("[NPCController] Scheduling START effect:", effect.effectName, "with delay:", effect.delay)
				local delayedEffect = effect
				local delayedNpc = npc
				local delayedTarget = targetHRP
				task.delay(effect.delay, function()
					print("[NPCController] Triggering DELAYED effect:", delayedEffect.effectName)
					spawnEffectWithHitbox()
				end)
			else
				print("[NPCController] Triggering START effect:", effect.effectName, "effectType:", effect.effectType or "default")
				spawnEffectWithHitbox()
			end
		end
	end
	
	-- Skip dash loop if noDash is set (just play animation in place)
	if not attackConfig.noDash then
		-- Check if we need to reposition to a specific distance
		local repositionDistance = attackConfig.repositionDistance
		
		if repositionDistance then
			-- Reposition mode: dash to exact distance from player (can be toward OR away)
			local npcPos = hrp.Position
			local playerPos = targetHRP.Position
			local currentDist = (playerPos - npcPos).Magnitude
			local tolerance = 5 -- How close to target distance is "good enough"
			
			-- Only reposition if not already at the right distance
			if math.abs(currentDist - repositionDistance) > tolerance then
				local directionFromPlayer = (npcPos - playerPos).Unit
				-- Calculate target XZ position
				local targetXZ = playerPos + directionFromPlayer * repositionDistance
				
				-- Raycast to find ground at target position
				local rayOrigin = Vector3.new(targetXZ.X, npcPos.Y + 50, targetXZ.Z)
				local rayResult = Workspace:Raycast(rayOrigin, Vector3.new(0, -100, 0))
				local groundY = npcPos.Y -- Default to current height
				if rayResult then
					groundY = rayResult.Position.Y + 3 -- 3 studs above ground
				end
				local dashTargetPos = Vector3.new(targetXZ.X, groundY, targetXZ.Z)
				
				-- Face the direction we're moving (toward dash target)
				local moveDirection = (dashTargetPos - npcPos).Unit
				local facingAngle = math.atan2(moveDirection.X, moveDirection.Z) + math.pi
				
				-- Anchor HRP to prevent Humanoid fighting the movement
				local wasAnchored = hrp.Anchored
				hrp.Anchored = true
				npc:PivotTo(CFrame.new(npcPos) * CFrame.Angles(0, facingAngle, 0))
				
				local dashTrack = tracks.forwardDash
				if dashTrack then
					dashTrack:Play()
					
					local dashDuration = dashTrack.Length or 0.5
					local startTime = tick()
					local startPos = npcPos
					
					-- Spawn "dash" effects
					for _, effect in ipairs(attackConfig.effects or {}) do
						if effect.trigger == "dash" then
							local effectWithDuration = {
								effectName = effect.effectName,
								attachment = effect.attachment,
								duration = effect.duration or dashDuration,
								targetPlayer = effect.targetPlayer,
								useExactPosition = effect.useExactPosition,
							}
							spawnEffect(effectWithDuration, npc, targetHRP)
						end
					end
					
					-- Smooth movement during dash
					local dashTimeout = dashDuration + 1
					while dashTrack.IsPlaying and (tick() - startTime) < dashTimeout do
						local elapsed = tick() - startTime
						local alpha = math.min(elapsed / dashDuration, 1)
						alpha = math.sin(alpha * math.pi / 2)
						local newPos = startPos:Lerp(dashTargetPos, alpha)
						npc:PivotTo(CFrame.new(newPos) * CFrame.Angles(0, facingAngle, 0))
						task.wait()
					end
					
					-- Ensure we're at the final position
					npc:PivotTo(CFrame.new(dashTargetPos) * CFrame.Angles(0, facingAngle, 0))
				end
				
				-- Face player after repositioning
				local finalPos = hrp.Position
				local finalDir = (targetHRP.Position - finalPos).Unit
				local finalAngle = math.atan2(finalDir.X, finalDir.Z) + math.pi
				npc:PivotTo(CFrame.new(finalPos) * CFrame.Angles(0, finalAngle, 0))
				
				-- Restore anchor state
				hrp.Anchored = wasAnchored
			end
		else
			-- Normal dash mode: keep dashing until within melee range
			while true do
				local npcPos = hrp.Position
				local playerPos = targetHRP.Position
				
				-- Calculate direction on XZ plane only (no vertical component)
				local directionXZ = Vector3.new(playerPos.X - npcPos.X, 0, playerPos.Z - npcPos.Z)
				local horizontalDist = directionXZ.Magnitude
				
				if horizontalDist < 0.1 then
					break -- Too close horizontally
				end
				
				local directionToPlayer = directionXZ.Unit
				local currentDist = (playerPos - npcPos).Magnitude
				local targetDist = attackConfig.targetDistance or 10
				local dashDistance = math.max(0, horizontalDist - targetDist)
				local dashMaxDist = attackConfig.dashMaxDistance or 50
				dashDistance = math.min(dashDistance, dashMaxDist)
				
				-- Check if within melee range to attack
				if currentDist <= meleeRange then
					break
				end
				
				-- Not close enough, must dash
				if not attackConfig.dashAnimation then
					break
				end
				
				local dashTrack = tracks.forwardDash
				if not dashTrack then
					break
				end
				
				-- Face the player
				local facingAngle = math.atan2(directionToPlayer.X, directionToPlayer.Z) + math.pi
				hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, facingAngle, 0)
				
				dashTrack:Play()
				
				local dashDuration = dashTrack.Length or 0.5
				local startTime = tick()
				
				-- Calculate dash target - horizontal movement only
				local startPos = npcPos
				local dashTargetPos = Vector3.new(
					npcPos.X + directionToPlayer.X * dashDistance,
					npcPos.Y,
					npcPos.Z + directionToPlayer.Z * dashDistance
				)
				
				-- Spawn "dash" effects
				for _, effect in ipairs(attackConfig.effects or {}) do
					if effect.trigger == "dash" then
						local effectWithDuration = {
							effectName = effect.effectName,
							attachment = effect.attachment,
							duration = effect.duration or dashDuration,
							targetPlayer = effect.targetPlayer,
							useExactPosition = effect.useExactPosition,
						}
						spawnEffect(effectWithDuration, npc, targetHRP)
					end
				end
				
				-- Smooth movement during dash using CFrame (not PivotTo)
				while dashTrack.IsPlaying and (tick() - startTime) < (dashDuration + 1) do
					local elapsed = tick() - startTime
					local alpha = math.min(elapsed / dashDuration, 1)
					alpha = math.sin(alpha * math.pi / 2) -- Ease out
					local newX = startPos.X + (dashTargetPos.X - startPos.X) * alpha
					local newZ = startPos.Z + (dashTargetPos.Z - startPos.Z) * alpha
					-- Keep current Y from physics (let humanoid handle ground)
					hrp.CFrame = CFrame.new(newX, hrp.Position.Y, newZ) * CFrame.Angles(0, facingAngle, 0)
					task.wait()
				end
				
				-- Check distance again after dash
				local newDist = (targetHRP.Position - hrp.Position).Magnitude
				if newDist <= meleeRange then
					break
				end
				
				task.wait(0.1)
			end
		end
	end
	
	-- Now perform the attack
	local npcPos = hrp.Position
	local playerPos = targetHRP.Position
	local directionToPlayer = (playerPos - npcPos).Unit
	
	-- Face player
	local facingAngle = math.atan2(directionToPlayer.X, directionToPlayer.Z) + math.pi
	npc:PivotTo(CFrame.new(npcPos) * CFrame.Angles(0, facingAngle, 0))
	
	-- Play attack animation
	local attackTrack = tracks.attacks[attackConfig.animation]
	if not attackTrack then 
		return 
	end
	
	attackTrack:Play()
	
	-- Move NPC to final position after animation with root motion
	if attackConfig.moveToAnimationEnd then
		task.spawn(function()
			local torso = npc:FindFirstChild("Torso") or npc:FindFirstChild("UpperTorso")
			if not torso then return end
			
			local animLength = attackTrack.Length
			
			-- Wait until we're at the very last moment of animation
			while attackTrack.IsPlaying and attackTrack.TimePosition < animLength - 0.05 do
				task.wait()
			end
			
			-- Capture position NOW before snap
			local finalPos = torso.Position
			
			-- Stop the animation manually and teleport immediately
			attackTrack:Stop(0)
			
			if hrp and hrp.Parent then
				local currentRotation = hrp.CFrame.Rotation
				npc:PivotTo(CFrame.new(finalPos.X, hrp.Position.Y, finalPos.Z) * currentRotation)
			end
		end)
	end
	
	-- Handle "chase while attacking" - move toward player while playing attack animation
	if attackConfig.chaseWhileAttacking then
		local stopChasing = false
		local chaseSpeed = attackConfig.chaseSpeed or config.walkSpeed or 16
		
		-- Listen for stop event
		if attackConfig.stopChaseOnEvent then
			local stopConnection
			stopConnection = attackTrack:GetMarkerReachedSignal(attackConfig.stopChaseOnEvent):Connect(function()
				stopChasing = true
				stopConnection:Disconnect()
			end)
		end
		
		-- Spawn "dash" effects (trail while chasing)
		for _, effect in ipairs(attackConfig.effects or {}) do
			if effect.trigger == "dash" then
				spawnEffect(effect, npc, targetHRP)
			end
		end
		
		-- Chase while animation plays until stop event
		task.spawn(function()
			while attackTrack.IsPlaying and not stopChasing do
				local currentPos = hrp.Position
				local playerPos = targetHRP.Position
				local directionToPlayer = (playerPos - currentPos).Unit
				local distToPlayer = (playerPos - currentPos).Magnitude
				
				-- Face player
				local facingAngle = math.atan2(directionToPlayer.X, directionToPlayer.Z) + math.pi
				
				-- Move toward player if not too close
				if distToPlayer > (attackConfig.targetDistance or 5) then
					local moveStep = directionToPlayer * chaseSpeed * 0.03  -- ~30fps movement
					local newPos = currentPos + moveStep
					npc:PivotTo(CFrame.new(newPos) * CFrame.Angles(0, facingAngle, 0))
				else
					-- Just face player when close enough
					npc:PivotTo(CFrame.new(currentPos) * CFrame.Angles(0, facingAngle, 0))
				end
				
				task.wait()
			end
		end)
	end
	
	-- Lock Y position during animation to prevent flying from root motion
	if attackConfig.lockYPosition then
		local startY = hrp.Position.Y
		task.spawn(function()
			while attackTrack.IsPlaying do
				local currentPos = hrp.Position
				if math.abs(currentPos.Y - startY) > 1 then
					-- Reset Y position if it deviates too much
					local currentRotation = hrp.CFrame.Rotation
					npc:PivotTo(CFrame.new(currentPos.X, startY, currentPos.Z) * currentRotation)
				end
				task.wait()
			end
		end)
	end
	
	-- Animation speed adjustment
	if attackConfig.animSpeedStart then
		attackTrack:AdjustSpeed(attackConfig.animSpeedStart)
		task.delay(attackConfig.animSpeedDelay or 0.5, function()
			if attackTrack.IsPlaying then
				attackTrack:AdjustSpeed(attackConfig.animSpeedNormal or 1)
			end
		end)
	end
	
	-- Handle "event" triggered effects (animation keyframe markers)
	-- Group effects by event name, then create ONE listener per event
	local effectsByEvent = {}
	for _, effect in ipairs(attackConfig.effects or {}) do
		if effect.trigger == "event" and effect.eventName then
			local eventName = effect.eventName
			if not effectsByEvent[eventName] then
				effectsByEvent[eventName] = {}
			end
			table.insert(effectsByEvent[eventName], effect)
		end
	end
	
	-- Create a random generator for this attack with proper seed
	local rng = Random.new(tick() * 1000 + math.random(1, 10000))
	
	-- Create one listener per unique event name
	for eventName, effectsList in pairs(effectsByEvent) do
		local eventCount = 0
		local triggeredEffects = {} -- Track which effects have triggered (by their occurrence)
		
		print("[NPCController] Setting up event listener for:", eventName, "with", #effectsList, "effects")
		
		local connection
		connection = attackTrack:GetMarkerReachedSignal(eventName):Connect(function()
			eventCount = eventCount + 1
			print("[NPCController] EVENT FIRED:", eventName, "occurrence:", eventCount)
			
			-- Check if this event uses random effects (first effect has randomEffects array)
			local firstEffect = effectsList[1]
			if firstEffect and firstEffect.randomEffects then
				-- Pick a random effect name from the list
				local randomIndex = rng:NextInteger(1, #firstEffect.randomEffects)
				local randomEffectName = firstEffect.randomEffects[randomIndex]
				print("[NPCController] Random effect selected:", randomEffectName, "index:", randomIndex, "from", #firstEffect.randomEffects, "options")
				
				-- Create a copy of the effect config with the random effect name
				local randomEffect = {}
				for k, v in pairs(firstEffect) do
					randomEffect[k] = v
				end
				randomEffect.effectName = randomEffectName
				randomEffect.randomEffects = nil -- Clear so it doesn't confuse the spawner
				
				spawnEffect(randomEffect, npc, targetHRP)
				return
			end
			
			-- Check each effect to see if it should trigger on this occurrence
			for _, effect in ipairs(effectsList) do
				local targetOccurrence = effect.eventOccurrence
				local effectKey = (effect.effectChild or effect.effectName) .. "_" .. (targetOccurrence or "any")
				
				-- Helper to spawn effect and create hitbox if needed
				local function spawnEffectWithHitbox()
					spawnEffect(effect, npc, targetHRP)
					
					-- Create hitbox if damage is configured
					if effect.damage and effect.hitboxAttachment then
						task.spawn(function()
							createHitbox(npc, effect.hitboxAttachment, effect.damage, effect.hitboxDuration or 0.5)
						end)
					end
				end
				
				-- If triggerEveryTime is set, always trigger (no tracking)
				if effect.triggerEveryTime then
					print("[NPCController] Spawning effect:", effect.effectName, "child:", effect.effectChild or "none", "(every time)")
					spawnEffectWithHitbox()
				-- If no specific occurrence, trigger every time (but only once per effect)
				-- If specific occurrence, only trigger on that exact occurrence
				elseif targetOccurrence == nil and not triggeredEffects[effectKey] then
					print("[NPCController] Spawning effect:", effect.effectName, "child:", effect.effectChild or "none", "(any occurrence)")
					spawnEffectWithHitbox()
					triggeredEffects[effectKey] = true
				elseif targetOccurrence == eventCount then
					print("[NPCController] Spawning effect:", effect.effectName, "child:", effect.effectChild or "none", "(occurrence", eventCount, ")")
					spawnEffectWithHitbox()
					triggeredEffects[effectKey] = true
				end
			end
		end)
	end
	
	-- Handle "time" triggered effects (percentage of animation)
	for _, effect in ipairs(attackConfig.effects or {}) do
		if effect.trigger == "time" and effect.triggerTime then
			task.spawn(function()
				local animLength = attackTrack.Length
				local triggerAt = animLength * effect.triggerTime
				while attackTrack.IsPlaying and attackTrack.TimePosition < triggerAt do
					task.wait()
				end
				if attackTrack.IsPlaying then
					spawnEffect(effect, npc, targetHRP)
					
					-- Create hitbox if damage is configured
					if effect.damage and effect.hitboxAttachment then
						task.spawn(function()
							createHitbox(npc, effect.hitboxAttachment, effect.damage, effect.hitboxDuration or 0.5)
						end)
					end
				end
			end)
		end
	end
	
	-- Handle pause on event (for melee attacks that need to freeze, like combo into beam)
	if attackConfig.pauseOnEvent then
		local connection
		connection = attackTrack:GetMarkerReachedSignal(attackConfig.pauseOnEvent):Connect(function()
			attackTrack:AdjustSpeed(0)
			setFrozen(true)
			
			connection:Disconnect()
			
			task.wait(attackConfig.freezeDuration or 3)
			setFrozen(false)
			attackTrack:AdjustSpeed(1)
		end)
	end
end

-- Execute a ranged attack
local function executeRangedAttack(npc, config, attackConfig, tracks, targetHRP, setFrozen)
	local attackTrack = tracks.attacks[attackConfig.animation]
	if not attackTrack then return end
	
	attackTrack:Play()
	
	-- Apply animation speed if specified
	if attackConfig.animSpeed then
		attackTrack:AdjustSpeed(attackConfig.animSpeed)
		print("[NPCController] Ranged: Animation speed set to:", attackConfig.animSpeed)
	end
	
	-- Handle "start" effects (with optional delay)
	for _, effect in ipairs(attackConfig.effects or {}) do
		if effect.trigger == "start" then
			if effect.delay and effect.delay > 0 then
				print("[NPCController] Ranged: Scheduling START effect:", effect.effectName, "with delay:", effect.delay)
				local delayedEffect = effect
				local delayedNpc = npc
				local delayedTarget = targetHRP
				task.delay(effect.delay, function()
					print("[NPCController] Ranged: Triggering DELAYED effect:", delayedEffect.effectName)
					spawnEffect(delayedEffect, delayedNpc, delayedTarget)
				end)
			else
				print("[NPCController] Ranged: Triggering START effect:", effect.effectName)
				spawnEffect(effect, npc, targetHRP)
			end
		end
	end
	
	-- Handle "event" triggered effects (for any ranged attack)
	-- Group effects by event name, then create ONE listener per event
	local effectsByEvent = {}
	for _, effect in ipairs(attackConfig.effects or {}) do
		if effect.trigger == "event" and effect.eventName then
			local eventName = effect.eventName
			if not effectsByEvent[eventName] then
				effectsByEvent[eventName] = {}
			end
			table.insert(effectsByEvent[eventName], effect)
		end
	end
	
	-- Create one listener per unique event name
	for eventName, effectsList in pairs(effectsByEvent) do
		local eventCount = 0
		local triggeredEffects = {}
		
		local connection
		connection = attackTrack:GetMarkerReachedSignal(eventName):Connect(function()
			eventCount = eventCount + 1
			
			for _, effect in ipairs(effectsList) do
				local targetOccurrence = effect.eventOccurrence
				local effectKey = (effect.effectChild or effect.effectName) .. "_" .. (targetOccurrence or "any")
				
				-- Helper to spawn effect and create hitbox if needed
				local function spawnEffectWithHitbox()
					spawnEffect(effect, npc, targetHRP)
					
					-- Create hitbox if damage is configured
					if effect.damage and effect.hitboxAttachment then
						task.spawn(function()
							createHitbox(npc, effect.hitboxAttachment, effect.damage, effect.hitboxDuration or 0.5)
						end)
					end
				end
				
				if targetOccurrence == nil and not triggeredEffects[effectKey] then
					spawnEffectWithHitbox()
					triggeredEffects[effectKey] = true
				elseif targetOccurrence == eventCount then
					spawnEffectWithHitbox()
					triggeredEffects[effectKey] = true
				end
			end
		end)
	end
	
	-- Handle "time" triggered effects (percentage of animation)
	for _, effect in ipairs(attackConfig.effects or {}) do
		if effect.trigger == "time" and effect.triggerTime then
			task.spawn(function()
				local animLength = attackTrack.Length
				local triggerAt = animLength * effect.triggerTime
				while attackTrack.IsPlaying and attackTrack.TimePosition < triggerAt do
					task.wait()
				end
				if attackTrack.IsPlaying then
					spawnEffect(effect, npc, targetHRP)
					
					-- Create hitbox if damage is configured
					if effect.damage and effect.hitboxAttachment then
						task.spawn(function()
							createHitbox(npc, effect.hitboxAttachment, effect.damage, effect.hitboxDuration or 0.5)
						end)
					end
				end
			end)
		end
	end
	
	-- Handle pause on event
	if attackConfig.pauseOnEvent then
		local connection
		connection = attackTrack:GetMarkerReachedSignal(attackConfig.pauseOnEvent):Connect(function()
			attackTrack:AdjustSpeed(0)
			setFrozen(true)
			
			connection:Disconnect()
			
			task.wait(attackConfig.freezeDuration or 3)
			setFrozen(false)
			attackTrack:AdjustSpeed(1)
		end)
	-- Handle pause at percent
	elseif attackConfig.pauseAtPercent then
		task.spawn(function()
			local animLength = attackTrack.Length
			local pauseTime = animLength * attackConfig.pauseAtPercent
			
			while attackTrack.IsPlaying and attackTrack.TimePosition < pauseTime do
				task.wait()
			end
			
			attackTrack:AdjustSpeed(0)
			setFrozen(true)
			
			-- Spawn effects on pause
			for _, effect in ipairs(attackConfig.effects or {}) do
				if effect.trigger == "pause" then
					spawnEffect(effect, npc, targetHRP)
				end
			end
			
			task.wait(attackConfig.freezeDuration or 3)
			setFrozen(false)
			attackTrack:AdjustSpeed(1)
		end)
	end
end

-- Main NPC AI loop
local function runNPCAI(npc, config, tracks)
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	
	local spawnPos = Vector3.new(
		npc:GetAttribute("SpawnX"),
		npc:GetAttribute("SpawnY"),
		npc:GetAttribute("SpawnZ")
	)
	
	local state = "idle"
	local wanderTarget = nil
	local lastAttackTime = 0
	local wanderCooldown = 0
	local isFrozen = false
	
	-- Stuck detection variables
	local wanderStartTime = 0
	local lastWanderPos = nil
	local stuckCheckTime = 0
	local WANDER_TIMEOUT = 8 -- Max seconds to try reaching wander target
	local STUCK_CHECK_INTERVAL = 1 -- How often to check if stuck
	local STUCK_DISTANCE_THRESHOLD = 1 -- If moved less than this in interval, considered stuck
	
	local function setFrozen(frozen)
		isFrozen = frozen
	end
	
	-- Check if any attack is playing
	local function isAttacking()
		for _, track in pairs(tracks.attacks) do
			if track.IsPlaying then return true end
		end
		if tracks.forwardDash and tracks.forwardDash.IsPlaying then return true end
		return false
	end
	
	tracks.idle:Play()
	
	-- Main loop
	while npc.Parent and humanoid.Health > 0 do
		local npcPos = npc.PrimaryPart and npc.PrimaryPart.Position or spawnPos
		local targetPlayer, dist = getNearestPlayer(npcPos, config.aggroRange)
		
		-- Frozen state - don't move
		if isFrozen then
			humanoid:MoveTo(npcPos)
			task.wait(0.1)
			continue
		end
		
		-- Player in range
		if targetPlayer and targetPlayer.Character then
			local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				if state ~= "attack" then
					state = "attack"
					tracks.idle:Stop()
					tracks.walk:Stop()
				end
				
				-- Face target
				local lookAtPos = Vector3.new(hrp.Position.X, npcPos.Y, hrp.Position.Z)
				if npc.PrimaryPart then
					npc.PrimaryPart.CFrame = CFrame.lookAt(npcPos, lookAtPos)
				end
				
				-- Attack if ready
				local currentTime = tick()
				local cooldownElapsed = (currentTime - lastAttackTime) >= config.attackCooldown
				
				if not isAttacking() and cooldownElapsed then
					-- Select attack
					local attackRoll
					local isUlt = false
					
					if DEBUG_ATTACK_SELECT and forcedAttack == 4 then
						isUlt = true
					elseif DEBUG_ATTACK_SELECT and forcedAttack > 0 and forcedAttack <= 3 then
						attackRoll = forcedAttack
					else
						-- Check for ult (1/10 chance)
						if config.attacks[4] and config.attacks[4].isUlt then
							isUlt = math.random(1, 10) == 1
						end
						if not isUlt then
							attackRoll = math.random(1, 3)
						end
					end
					
					local attackConfig = isUlt and config.attacks[4] or config.attacks[attackRoll]
					if attackConfig then
						local success, err = pcall(function()
							if attackConfig.type == "melee" then
								executeMeleeAttack(npc, config, attackConfig, tracks, hrp, setFrozen)
							else
								executeRangedAttack(npc, config, attackConfig, tracks, hrp, setFrozen)
							end
						end)
						
						if not success then
							warn("[NPCController] Attack error:", err)
						end
						
						-- Wait for attack animation to finish
						local attackTrack = tracks.attacks[attackConfig.animation]
						if attackTrack then
							while attackTrack.IsPlaying do
								task.wait(0.1)
							end
						end
						
						-- Set cooldown AFTER attack finishes
						lastAttackTime = tick()
						
						-- Deal damage via fallback (hitbox system is secondary)
						local plHum = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
						if plHum and plHum.Health > 0 then
							-- Get damage from effect config if available, otherwise use base NPC damage
							local effectDamage = nil
							for _, effect in ipairs(attackConfig.effects or {}) do
								if effect.damage then
									effectDamage = effect.damage
									break
								end
							end
							
							local finalDamage = effectDamage or config.damage
							plHum:TakeDamage(finalDamage)
							print("[NPCController] Applied fallback damage:", finalDamage, "to player:", targetPlayer.Name)
						end
					end
				end
			end
		else
			-- No player - idle/wander
			for _, track in pairs(tracks.attacks) do
				track:Stop()
			end
			
			if state == "chase" or state == "attack" then
				state = "idle"
				tracks.walk:Stop()
				tracks.idle:Play()
				wanderCooldown = tick() + math.random(config.idleTime[1], config.idleTime[2])
			end
			
			if state == "idle" then
				if tick() >= wanderCooldown then
					state = "wander"
					tracks.idle:Stop()
					tracks.walk:Play()
					
					local angle = math.random() * math.pi * 2
					local radius = math.random(10, config.walkRadius)
					wanderTarget = spawnPos + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
					
					local origin = wanderTarget + Vector3.new(0, 50, 0)
					local ray = Workspace:Raycast(origin, Vector3.new(0, -500, 0))
					if ray then
						wanderTarget = ray.Position + Vector3.new(0, 3, 0)
					end
					
					-- Initialize stuck detection
					wanderStartTime = tick()
					lastWanderPos = npcPos
					stuckCheckTime = tick()
					
					humanoid:MoveTo(wanderTarget)
				end
			elseif state == "wander" then
				if wanderTarget then
					local distToTarget = (npcPos - wanderTarget).Magnitude
					local currentTime = tick()
					
					-- Check if reached target
					if distToTarget < 5 then
						state = "idle"
						tracks.walk:Stop()
						tracks.idle:Play()
						wanderCooldown = tick() + math.random(config.idleTime[1], config.idleTime[2])
					-- Check if timed out (took too long)
					elseif (currentTime - wanderStartTime) > WANDER_TIMEOUT then
						-- Give up and go back to idle
						state = "idle"
						tracks.walk:Stop()
						tracks.idle:Play()
						wanderCooldown = tick() + math.random(config.idleTime[1], config.idleTime[2])
						wanderTarget = nil
					-- Check if stuck (not making progress)
					elseif (currentTime - stuckCheckTime) >= STUCK_CHECK_INTERVAL then
						local distanceMoved = lastWanderPos and (npcPos - lastWanderPos).Magnitude or 999
						
						if distanceMoved < STUCK_DISTANCE_THRESHOLD then
							-- NPC is stuck, pick a new random direction
							local angle = math.random() * math.pi * 2
							local radius = math.random(10, math.min(30, config.walkRadius))
							wanderTarget = npcPos + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
							
							-- Raycast to find ground
							local origin = wanderTarget + Vector3.new(0, 50, 0)
							local ray = Workspace:Raycast(origin, Vector3.new(0, -500, 0))
							if ray then
								wanderTarget = ray.Position + Vector3.new(0, 3, 0)
							end
							
							-- Reset stuck timer but keep overall timeout
							wanderStartTime = tick()
						end
						
						-- Update stuck check
						lastWanderPos = npcPos
						stuckCheckTime = currentTime
						humanoid:MoveTo(wanderTarget)
					else
						humanoid:MoveTo(wanderTarget)
					end
				end
			end
		end
		
		task.wait(0.1)
	end
end

-- Main init function
function NPCController.init(configName)
	setupRemoteEvents()
	
	-- Load config
	local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
	NPCConfig = require(sharedFolder:WaitForChild("NPCConfig"))
	
	local config = NPCConfig[configName]
	if not config then
		error("[NPCController] Config not found: " .. configName)
	end
	
	print("[NPCController] Initializing NPC:", configName)
	
	-- Find spawn model
	local spawnModel = Workspace:FindFirstChild(config.spawnName, true)
	if not spawnModel then
		warn("[NPCController] Spawn model not found:", config.spawnName)
		return
	end
	
	-- Get spawn parts
	local spawnParts = {}
	for _, part in ipairs(spawnModel:GetDescendants()) do
		if part:IsA("BasePart") then
			table.insert(spawnParts, part)
		end
	end
	if #spawnParts == 0 then
		warn("[NPCController] No spawn parts found in:", config.spawnName)
		return
	end
	
	-- Find NPC template
	local npcFolder = ReplicatedStorage:FindFirstChild("Npc")
	if not npcFolder then
		error("[NPCController] Npc folder missing in ReplicatedStorage")
	end
	local template = npcFolder:FindFirstChild(config.modelName)
	if not template then
		error("[NPCController] Model not found: " .. config.modelName)
	end
	
	print("[NPCController] Spawning", config.npcCount, "NPCs...")
	
	-- Spawn NPCs
	for i = 1, config.npcCount do
		local spawnPart = spawnParts[math.random(1, #spawnParts)]
		local pos = getSpawnPosition(spawnPart)
		
		local npc = template:Clone()
		npc.Parent = Workspace
		
		-- Unanchor all parts
		for _, part in ipairs(npc:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = false
			end
		end
		
		if npc.PrimaryPart then
			npc:SetPrimaryPartCFrame(CFrame.new(pos))
		else
			npc:MoveTo(pos)
		end
		
		local humanoid = npc:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = config.walkSpeed
			
			-- Set health from config (default 100 if not specified)
			local health = config.health or 100
			humanoid.MaxHealth = health
			humanoid.Health = health
			print("[NPCController] Set", config.modelName, "health to", health)
			
			-- Hide default Roblox health bar (we use custom one)
			humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			
			local animator = humanoid:FindFirstChildOfClass("Animator")
			if not animator then
				animator = Instance.new("Animator")
				animator.Parent = humanoid
			end
			
			npc:SetAttribute("SpawnX", pos.X)
			npc:SetAttribute("SpawnY", pos.Y)
			npc:SetAttribute("SpawnZ", pos.Z)
			
			-- Load all animation tracks
			local tracks = {
				idle = loadAnimation(animator, config.animIdle),
				walk = loadAnimation(animator, config.animWalk),
				attacks = {},
			}
			tracks.idle.Looped = true
			tracks.walk.Looped = true
			
			-- Load dash animations
			if config.animForwardDash then
				tracks.forwardDash = loadAnimation(animator, config.animForwardDash)
			end
			if config.animLeftDash then
				tracks.leftDash = loadAnimation(animator, config.animLeftDash)
			end
			if config.animRightDash then
				tracks.rightDash = loadAnimation(animator, config.animRightDash)
			end
			
			-- Load attack animations
			for _, attackConfig in pairs(config.attacks) do
				if attackConfig.animation and not tracks.attacks[attackConfig.animation] then
					tracks.attacks[attackConfig.animation] = loadAnimation(animator, attackConfig.animation)
				end
			end
			
			-- Start AI loop
			task.spawn(function()
				runNPCAI(npc, config, tracks)
			end)
			
			print("[NPCController] Spawned NPC #" .. i)
		end
	end
end

return NPCController
--