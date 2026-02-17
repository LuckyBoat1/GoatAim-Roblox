-- Client-side effect spawner (instant, no replication delay)
-- Supports: Particle effects AND Beam effects (P0 -> P1 structure)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- Wait for RemoteEvent
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local spawnEffectEvent = remoteEvents:WaitForChild("SpawnEffectEvent")

local effectsFolder = ReplicatedStorage:WaitForChild("Effects")

-- Helper: Enable all particle emitters in a model
local function enableAllEmitters(model)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("ParticleEmitter") then
			descendant.Enabled = true
		end
	end
end

-- Helper: Disable all particle emitters in a model
local function disableAllEmitters(model)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("ParticleEmitter") then
			descendant.Enabled = false
		end
	end
end

-- Helper: Enable all beams in a model
local function enableAllBeams(model)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("Beam") then
			descendant.Enabled = true
		end
	end
end

-- Helper: Disable all beams in a model
local function disableAllBeams(model)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("Beam") then
			descendant.Enabled = false
		end
	end
end

-- Spawn a BEAM effect (P0 = source, P1 = target with Model effects)
-- Structure: Beam > P0 (Inner, Outer, Core) + P1 (Outer, Model)
-- IMPORTANT: Clone preserves all beam Attachment0/Attachment1 references automatically!
-- We just need to move P0 and P1 to the correct positions.
local function spawnBeamEffect(effectTemplate, sourceAttachment, targetPosition, duration)
	-- Clone the effect - this preserves ALL properties including beam connections
	local effectClone = effectTemplate:Clone()
	
	-- DEBUG: Print beam widths BEFORE any changes
	print("[EffectSpawner] ===== BEAM DEBUG =====")
	print("[EffectSpawner] Effect:", effectTemplate.Name)
	for _, desc in ipairs(effectClone:GetDescendants()) do
		if desc:IsA("Beam") then
			print("[EffectSpawner] Beam:", desc.Name, "Width0:", desc.Width0, "Width1:", desc.Width1, "Enabled:", desc.Enabled)
		end
	end
	
	-- Get P0 (source) and P1 (target)
	local P0 = effectClone:FindFirstChild("P0")
	local P1 = effectClone:FindFirstChild("P1")
	
	if not P0 or not P1 then
		warn("[EffectSpawner] Beam effect missing P0 or P1!")
		effectClone:Destroy()
		return
	end
	
	-- Disable everything initially
	disableAllBeams(effectClone)
	disableAllEmitters(effectClone)
	
	-- Get source position
	local sourcePos = sourceAttachment.WorldPosition
	
	-- Store ORIGINAL rotations from the template (preserves artist's setup)
	local originalP0Rotation = P0.CFrame.Rotation
	local originalP1Rotation = P1.CFrame.Rotation
	
	-- Move P0 to source position - KEEP original rotation
	P0.CFrame = CFrame.new(sourcePos) * originalP0Rotation
	
	-- Move P1 to target position - KEEP original rotation
	P1.CFrame = CFrame.new(targetPosition) * originalP1Rotation
	
	-- Parent to workspace AFTER positioning
	effectClone.Parent = workspace
	
	-- DEBUG: Print beam widths AFTER parenting
	print("[EffectSpawner] After parenting to workspace:")
	for _, desc in ipairs(effectClone:GetDescendants()) do
		if desc:IsA("Beam") then
			print("[EffectSpawner] Beam:", desc.Name, "Width0:", desc.Width0, "Width1:", desc.Width1)
		end
	end
	
	-- The Clone() already preserved all beam Attachment0/Attachment1 connections!
	-- Just verify beams are properly connected
	local beamCount = 0
	for _, descendant in ipairs(effectClone:GetDescendants()) do
		if descendant:IsA("Beam") then
			beamCount = beamCount + 1
			if descendant.Attachment0 and descendant.Attachment1 then
				print("[EffectSpawner] Beam", descendant.Name, "connected:", 
					descendant.Attachment0:GetFullName(), "->", descendant.Attachment1:GetFullName())
			else
				warn("[EffectSpawner] Beam", descendant.Name, "missing attachment! A0:", 
					descendant.Attachment0, "A1:", descendant.Attachment1)
			end
		end
	end
	print("[EffectSpawner] Total beams in effect:", beamCount)
	-- Enable everything NOW (synchronized start)
	enableAllBeams(effectClone)
	enableAllEmitters(effectClone)
	
	print("[EffectSpawner] Beam effect activated! Beams and particles enabled.")
	
	-- Update P0 position during the effect (follow source if it moves)
	-- IMPORTANT: Only update position, keep original rotation from template!
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not effectClone.Parent then
			connection:Disconnect()
			return
		end
		
		-- If source moves, update P0 position (keep original rotation unchanged)
		if sourceAttachment and sourceAttachment.Parent then
			local currentSourcePos = sourceAttachment.WorldPosition
			-- Only update position, preserve original rotation from template
			P0.CFrame = CFrame.new(currentSourcePos) * originalP0Rotation
		end
		
		-- P1 stays at target position (stationary)
	end)
	
	-- Cleanup after duration
	task.delay(duration, function()
		if connection then
			connection:Disconnect()
		end
		if effectClone and effectClone.Parent then
			-- Fade out beams
			disableAllBeams(effectClone)
			disableAllEmitters(effectClone)
			task.wait(0.5)
			effectClone:Destroy()
		end
	end)
	
	return effectClone
end

-- Spawn a TRAIL effect (Lightning trails that follow NPC)
-- Structure: Trail > Lightning > End, Start, Trail
local function spawnTrailEffect(effectTemplate, attachment, duration)
	-- Find the NPC's HumanoidRootPart to attach trails to
	local npc = attachment.Parent
	while npc and not npc:FindFirstChild("HumanoidRootPart") do
		npc = npc.Parent
	end
	
	if not npc then
		warn("[EffectSpawner] Trail effect: Could not find NPC with HumanoidRootPart")
		return
	end
	
	local hrp = npc:FindFirstChild("HumanoidRootPart")
	
	-- Find the Trail attachment on HRP
	local trailAttachment = hrp:FindFirstChild("Trail")
	if not trailAttachment then
		warn("[EffectSpawner] Trail effect: No 'Trail' attachment found on HumanoidRootPart")
		return
	end
	
	-- Clone the effect template exactly as-is
	local effectClone = effectTemplate:Clone()
	effectClone.Name = "TrailEffect_Active"
	
	-- Position parts at the Trail attachment position but keep original rotation, then weld
	for _, descendant in ipairs(effectClone:GetDescendants()) do
		if descendant:IsA("BasePart") then
			-- Keep original rotation, just move to attachment position
			local originalRotation = descendant.CFrame - descendant.CFrame.Position
			descendant.CFrame = CFrame.new(trailAttachment.WorldPosition) * originalRotation
			descendant.Anchored = false
			descendant.CanCollide = false
			
			-- Weld to HRP so it follows the NPC
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = hrp
			weld.Part1 = descendant
			weld.Parent = descendant
		end
	end
	
	-- Parent to NPC after positioning
	effectClone.Parent = npc
	
	-- Enable all trails and particle emitters
	for _, descendant in ipairs(effectClone:GetDescendants()) do
		if descendant:IsA("Trail") then
			descendant.Enabled = true
		elseif descendant:IsA("ParticleEmitter") then
			descendant.Enabled = true
		end
	end
	
	-- Cleanup after duration
	task.delay(duration, function()
		-- Disable trails first (let existing trail fade)
		for _, descendant in ipairs(effectClone:GetDescendants()) do
			if descendant:IsA("Trail") or descendant:IsA("ParticleEmitter") then
				descendant.Enabled = false
			end
		end
		
		-- Wait for trails to fade, then clean up
		task.wait(0.5)
		
		if effectClone and effectClone.Parent then
			effectClone:Destroy()
		end
	end)
	
	return effectClone
end

-- Spawn a PROJECTILE effect (flies from source toward target)
-- Structure: Can be nested (e.g., GreenBlast > GreenBlast > Attachment + Main > Parts)
local function spawnProjectileEffect(effectTemplate, sourceAttachment, targetPosition, speed, duration)
	local effectClone = effectTemplate:Clone()
	effectClone.Name = "ProjectileEffect_Active"
	
	local sourcePos = sourceAttachment.WorldPosition
	local direction = (targetPosition - sourcePos).Unit
	local distance = (targetPosition - sourcePos).Magnitude
	
	print("[EffectSpawner] Projectile: source =", sourcePos, "target =", targetPosition, "distance =", distance)
	
	-- Collect ALL parts in the effect
	local allParts = {}
	for _, desc in ipairs(effectClone:GetDescendants()) do
		if desc:IsA("BasePart") then
			table.insert(allParts, desc)
			desc.Anchored = true
			desc.CanCollide = false
		end
	end
	
	print("[EffectSpawner] Projectile found", #allParts, "parts")
	
	-- Enable ALL emitters (they might be deep in the hierarchy)
	local emitterCount = 0
	for _, descendant in ipairs(effectClone:GetDescendants()) do
		if descendant:IsA("ParticleEmitter") then
			descendant.Enabled = true
			emitterCount = emitterCount + 1
		end
	end
	print("[EffectSpawner] Projectile enabled", emitterCount, "emitters")
	
	-- Calculate offset from first part to store relative positions
	local basePart = allParts[1]
	local partOffsets = {}
	
	if basePart then
		local basePos = basePart.Position
		for _, part in ipairs(allParts) do
			partOffsets[part] = part.CFrame:ToObjectSpace(CFrame.new(basePos))
		end
	else
		-- No parts found - create one to hold emitters
		basePart = Instance.new("Part")
		basePart.Size = Vector3.new(1, 1, 1)
		basePart.Transparency = 1
		basePart.CanCollide = false
		basePart.Anchored = true
		basePart.Parent = effectClone
		table.insert(allParts, basePart)
		partOffsets[basePart] = CFrame.new()
	end
	
	-- Position at source initially
	local initialCFrame = CFrame.lookAt(sourcePos, targetPosition)
	for _, part in ipairs(allParts) do
		local offset = partOffsets[part]
		part.CFrame = initialCFrame * offset:Inverse()
	end
	
	effectClone.Parent = workspace
	
	-- Animate the projectile flying toward target
	local travelTime = distance / (speed or 80)
	local startTime = tick()
	
	print("[EffectSpawner] Projectile travel time:", travelTime, "seconds")
	
	task.spawn(function()
		while tick() - startTime < travelTime and effectClone.Parent do
			local elapsed = tick() - startTime
			local progress = math.min(elapsed / travelTime, 1)
			local currentPos = sourcePos:Lerp(targetPosition, progress)
			local currentCFrame = CFrame.lookAt(currentPos, targetPosition)
			
			-- Move ALL parts together
			for _, part in ipairs(allParts) do
				if part.Parent then
					local offset = partOffsets[part]
					part.CFrame = currentCFrame * offset:Inverse()
				end
			end
			task.wait()
		end
		
		-- Reached target - disable emitters
		for _, desc in ipairs(effectClone:GetDescendants()) do
			if desc:IsA("ParticleEmitter") then
				desc.Enabled = false
			end
		end
	end)
	
	-- Cleanup after duration
	Debris:AddItem(effectClone, duration)
	
	return effectClone
end

-- Spawn a SMASH effect (emits all particle emitters once at attachment location, raycasted to floor)
local function spawnSmashEffect(effectTemplate, attachment, duration, effectChild, emitCount, enableOnly, spawnOnFloor, scale, followAttachment)
	if not attachment then
		warn("[EffectSpawner] Smash effect: No attachment provided")
		return
	end
	
	print("[EffectSpawner] Smash effect starting, template:", effectTemplate.Name, "child:", effectChild or "ALL", "onFloor:", spawnOnFloor or false, "scale:", scale or 1, "follow:", followAttachment or false)
	
	local effectClone = effectTemplate:Clone()
	effectClone.Name = "SmashEffect_Active"
	
	-- Apply scale to all particle emitters if specified
	if scale and scale ~= 1 then
		for _, desc in ipairs(effectClone:GetDescendants()) do
			if desc:IsA("ParticleEmitter") then
				-- Scale size
				local sizeKeypoints = desc.Size.Keypoints
				local newKeypoints = {}
				for _, kp in ipairs(sizeKeypoints) do
					table.insert(newKeypoints, NumberSequenceKeypoint.new(kp.Time, kp.Value * scale, kp.Envelope * scale))
				end
				desc.Size = NumberSequence.new(newKeypoints)
			end
		end
	end
	
	-- If followAttachment is true, parent directly to the attachment so it follows animation
	if followAttachment then
		-- Clone all emitters from the effect and parent them to the NPC's attachment
		local emitterCount = 0
		for _, desc in ipairs(effectClone:GetDescendants()) do
			if desc:IsA("ParticleEmitter") then
				local emitterClone = desc:Clone()
				emitterClone.Parent = attachment
				
				if enableOnly then
					emitterClone.Enabled = true
					task.delay(duration, function()
						if emitterClone and emitterClone.Parent then
							emitterClone.Enabled = false
							task.delay(emitterClone.Lifetime.Max, function()
								if emitterClone then emitterClone:Destroy() end
							end)
						end
					end)
				else
					local count = emitCount or 1
					emitterClone:Emit(count)
					emitterClone.Enabled = false
					task.delay(duration, function()
						if emitterClone then emitterClone:Destroy() end
					end)
				end
				emitterCount = emitterCount + 1
				print("[EffectSpawner] Attached emitter to:", attachment:GetFullName())
			end
		end
		print("[EffectSpawner] Follow mode: attached", emitterCount, "emitters to attachment")
		effectClone:Destroy()
		return
	end
	
	-- If effectChild specified, only use that specific child
	local targetPart = nil
	if effectChild then
		targetPart = effectClone:FindFirstChild(effectChild, true)
		if not targetPart then
			warn("[EffectSpawner] Smash effect: Could not find child:", effectChild, "in effect. Available children:")
			for _, child in ipairs(effectClone:GetChildren()) do
				print("  -", child.Name)
			end
		else
			print("[EffectSpawner] Found target part:", targetPart.Name, "class:", targetPart.ClassName)
		end
	end
	
	-- Get spawn position from attachment
	local spawnPos = attachment.WorldPosition
	print("[EffectSpawner] Attachment position:", spawnPos)
	
	-- Determine final position (raycast to floor only if spawnOnFloor is true)
	local finalPos = spawnPos
	if spawnOnFloor then
		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		local localPlayer = game:GetService("Players").LocalPlayer
		local excludeList = {}
		if attachment.Parent then
			local npcModel = attachment:FindFirstAncestorWhichIsA("Model")
			if npcModel then
				table.insert(excludeList, npcModel)
			end
		end
		if localPlayer and localPlayer.Character then
			table.insert(excludeList, localPlayer.Character)
		end
		rayParams.FilterDescendantsInstances = excludeList
		
		local rayResult = workspace:Raycast(spawnPos + Vector3.new(0, 5, 0), Vector3.new(0, -50, 0), rayParams)
		if rayResult then
			finalPos = rayResult.Position
		end
		print("[EffectSpawner] Raycasted to floor:", finalPos)
	end
	
	-- If we have a specific child, only position and emit that one
	if targetPart then
		-- For Attachments, we need to create a host part and parent the attachment to it
		if targetPart:IsA("Attachment") then
			-- Create a transparent part to host the attachment at the correct position
			local hostPart = Instance.new("Part")
			hostPart.Name = effectChild .. "_EffectHost"
			hostPart.Size = Vector3.new(1, 1, 1)
			hostPart.CFrame = CFrame.new(finalPos)
			hostPart.Anchored = true
			hostPart.CanCollide = false
			hostPart.Transparency = 1
			hostPart.Parent = workspace
			
			-- Clone and parent the attachment to the host part
			local attachClone = targetPart:Clone()
			attachClone.Position = Vector3.new(0, 0, 0) -- Center on host part
			attachClone.Parent = hostPart
			
			-- Emit particle emitters inside the attachment
			local emitterCount = 0
			for _, child in ipairs(attachClone:GetChildren()) do
				if child:IsA("ParticleEmitter") then
					if enableOnly then
						-- Just enable the emitter, don't emit - will be disabled after duration
						child.Enabled = true
						print("[EffectSpawner] Enabled emitter:", child.Name)
						-- Disable after duration
						task.delay(duration, function()
							if child and child.Parent then
								child.Enabled = false
								print("[EffectSpawner] Disabled emitter after duration:", child.Name)
							end
						end)
					else
						-- Emit specified count (default 1)
						local count = emitCount or 1
						child:Emit(count)
						child.Enabled = false
						print("[EffectSpawner] Emitted", count, "from attachment child:", child.Name)
					end
					emitterCount = emitterCount + 1
				end
			end
			
			print("[EffectSpawner] Smash effect processed", emitterCount, "emitters from attachment:", effectChild, "at:", spawnPos)
			Debris:AddItem(hostPart, duration)
			effectClone:Destroy()
			return hostPart
		end
		
		-- If targetPart is a ParticleEmitter directly, create a host part for it
		if targetPart:IsA("ParticleEmitter") then
			-- Create a transparent part to host the emitter at the correct position (on floor, no rotation)
			local hostPart = Instance.new("Part")
			hostPart.Name = effectChild .. "_EffectHost"
			hostPart.Size = Vector3.new(1, 1, 1)
			hostPart.CFrame = CFrame.new(finalPos)
			hostPart.Anchored = true
			hostPart.CanCollide = false
			hostPart.Transparency = 1
			hostPart.Parent = workspace
			
			-- Create an attachment to hold the emitter
			local attachHost = Instance.new("Attachment")
			attachHost.Name = "EffectAttachment"
			attachHost.Parent = hostPart
			
			-- Clone and parent the emitter to the attachment
			local emitterClone = targetPart:Clone()
			emitterClone.Parent = attachHost
			
			if enableOnly then
				-- Just enable the emitter, don't emit - will be disabled after duration
				emitterClone.Enabled = true
				print("[EffectSpawner] Enabled emitter directly:", effectChild)
				-- Disable after duration
				task.delay(duration, function()
					if emitterClone and emitterClone.Parent then
						emitterClone.Enabled = false
						print("[EffectSpawner] Disabled emitter after duration:", effectChild)
					end
				end)
			else
				-- Emit specified count (default 1)
				local count = emitCount or 1
				emitterClone:Emit(count)
				emitterClone.Enabled = false
				print("[EffectSpawner] Emitted", count, "from emitter:", effectChild)
			end
			
			Debris:AddItem(hostPart, duration)
			effectClone:Destroy()
			return hostPart
		end
		
		-- Clone just this part to avoid destroying it with effectClone
		local partClone = targetPart:Clone()
		partClone.Name = effectChild .. "_Effect"
		
		if partClone:IsA("BasePart") then
			partClone.CFrame = CFrame.new(finalPos)
			partClone.Anchored = true
			partClone.CanCollide = false
			partClone.Transparency = 1
			print("[EffectSpawner] Positioned part at:", spawnPos)
		end
		
		partClone.Parent = workspace
		
		-- Emit particle emitters
		local emitterCount = 0
		for _, child in ipairs(partClone:GetChildren()) do
			if child:IsA("ParticleEmitter") then
				if enableOnly then
					child.Enabled = true
					print("[EffectSpawner] Enabled:", child.Name)
					-- Disable after duration
					task.delay(duration, function()
						if child and child.Parent then
							child.Enabled = false
							print("[EffectSpawner] Disabled after duration:", child.Name)
						end
					end)
				else
					local count = emitCount or 1
					child:Emit(count)
					child.Enabled = false
					print("[EffectSpawner] Emitted", count, "from:", child.Name)
				end
				emitterCount = emitterCount + 1
			end
		end
		
		print("[EffectSpawner] Smash effect processed", emitterCount, "emitters from child:", effectChild, "at:", spawnPos)
		Debris:AddItem(partClone, duration)
		effectClone:Destroy()
		return partClone
	end
	
	-- Determine position - only raycast to floor if spawnOnFloor is true
	local groundPos = spawnPos
	if spawnOnFloor then
		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		local localPlayer = game:GetService("Players").LocalPlayer
		local excludeList = {}
		if attachment.Parent then
			local npcModel = attachment:FindFirstAncestorWhichIsA("Model")
			if npcModel then
				table.insert(excludeList, npcModel)
			end
		end
		if localPlayer and localPlayer.Character then
			table.insert(excludeList, localPlayer.Character)
		end
		rayParams.FilterDescendantsInstances = excludeList
		
		local rayResult = workspace:Raycast(spawnPos + Vector3.new(0, 5, 0), Vector3.new(0, -50, 0), rayParams)
		if rayResult then
			groundPos = rayResult.Position
		end
	end
	
	spawnCFrame = CFrame.new(groundPos)
	
	-- Position ALL BaseParts at the ground location with no rotation
	for _, desc in ipairs(effectClone:GetDescendants()) do
		if desc:IsA("BasePart") then
			desc.CFrame = spawnCFrame
			desc.Anchored = true
			desc.CanCollide = false
			desc.Transparency = 1
		end
	end
	
	if effectClone:IsA("BasePart") then
		effectClone.CFrame = spawnCFrame
		effectClone.Anchored = true
		effectClone.CanCollide = false
		effectClone.Transparency = 1
	end
	
	effectClone.Parent = workspace
	
	-- Emit every particle emitter exactly once
	for _, desc in ipairs(effectClone:GetDescendants()) do
		if desc:IsA("ParticleEmitter") then
			desc:Emit(1)
			desc.Enabled = false
		end
	end
	
	print("[EffectSpawner] Smash effect emitted all particles once at ground:", groundPos)
	
	Debris:AddItem(effectClone, duration)
	
	return effectClone
end

-- Spawn a GROUND effect (spawns at distance in attack direction with random model children)
local function spawnGroundEffect(effectTemplate, npcModel, targetPosition, spawnDistance, duration)
	local hrp = npcModel:FindFirstChild("HumanoidRootPart")
	if not hrp then
		warn("[EffectSpawner] Ground effect: No HumanoidRootPart found")
		return
	end
	
	-- Calculate spawn position (in direction of target, or forward if no target)
	local npcPos = hrp.Position
	local direction
	if targetPosition then
		direction = (targetPosition - npcPos).Unit
	else
		-- No target, spawn in front of NPC
		direction = hrp.CFrame.LookVector
		print("[EffectSpawner] Ground effect: No target, using NPC forward direction")
	end
	local spawnPos = npcPos + direction * (spawnDistance or 50)
	
	print("[EffectSpawner] Ground effect spawn position:", spawnPos, "distance:", spawnDistance)
	
	-- Get ground level at spawn position
	local rayOrigin = spawnPos + Vector3.new(0, 50, 0)
	local rayDirection = Vector3.new(0, -100, 0)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	-- Exclude NPC and local player so boulders can spawn at their positions
	local localPlayer = game:GetService("Players").LocalPlayer
	local playerChar = localPlayer and localPlayer.Character
	local excludeList = {npcModel}
	if playerChar then
		table.insert(excludeList, playerChar)
	end
	rayParams.FilterDescendantsInstances = excludeList
	
	local rayResult = workspace:Raycast(rayOrigin, rayDirection, rayParams)
	if rayResult then
		spawnPos = rayResult.Position
	end
	
	-- Clone the effect - it has Models inside with MeshParts
	local effectClone = effectTemplate:Clone()
	effectClone.Name = "GroundEffect_Active"
	effectClone.Parent = workspace
	
	-- Get all Model children
	local models = {}
	for _, child in ipairs(effectClone:GetChildren()) do
		if child:IsA("Model") then
			table.insert(models, child)
		end
	end

	print("[EffectSpawner] Ground effect has", #models, "models to spawn (randomized)")

	local lateralSpread = 30 -- How wide the boulders spread perpendicular to direction
	local riseHeight = 8
	local riseTime = 0.3
	local staggerDelay = 0.075
	local fixedDistance = 80 -- Always travel this far regardless of player position
	
	-- Calculate direction towards target (FLATTENED to ground plane)
	local startPos = npcPos
	local endTarget = targetPosition or spawnPos
	-- Flatten direction to horizontal plane only (ignore Y difference)
	local flatDirection = Vector3.new(endTarget.X - npcPos.X, 0, endTarget.Z - npcPos.Z)
	local direction = flatDirection.Unit
	local totalDistance = fixedDistance -- Use fixed distance, not player distance
	
	-- Get perpendicular direction for lateral spread
	local perpendicular = Vector3.new(-direction.Z, 0, direction.X)

	for i, model in ipairs(models) do
		model.Parent = nil

		task.delay((i - 1) * staggerDelay, function()
			-- Calculate progress along the path (0 = NPC, 1 = target, >1 = overshoot)
			local progress = (i - 1) / math.max(#models - 1, 1)
			local distanceAlongPath = progress * totalDistance
			
			-- Position along the line from NPC to target (use npcPos X/Z, ignore Y for now)
			local pathPosXZ = Vector3.new(startPos.X, 0, startPos.Z) + direction * distanceAlongPath
			
			-- Add random lateral offset (perpendicular to direction)
			local lateralOffset = (math.random() * 2 - 1) * lateralSpread
			local modelPosXZ = pathPosXZ + perpendicular * lateralOffset
			
			-- Create fresh raycast params excluding player, NPC, and previously spawned boulders
			local boulderRayParams = RaycastParams.new()
			boulderRayParams.FilterType = Enum.RaycastFilterType.Exclude
			local currentPlayerChar = localPlayer and localPlayer.Character
			local boulderExcludeList = {npcModel, effectClone}
			if currentPlayerChar then
				table.insert(boulderExcludeList, currentPlayerChar)
			end
			boulderRayParams.FilterDescendantsInstances = boulderExcludeList
			
			-- Raycast from high up to find ground level
			local rayStart = Vector3.new(modelPosXZ.X, startPos.Y + 100, modelPosXZ.Z)
			local modelRayResult = workspace:Raycast(rayStart, Vector3.new(0, -200, 0), boulderRayParams)
			
			local modelPos
			if modelRayResult then
				modelPos = modelRayResult.Position
			else
				-- Fallback to NPC ground level if raycast fails
				modelPos = Vector3.new(modelPosXZ.X, startPos.Y, modelPosXZ.Z)
			end

			-- Random rotation for each boulder
			local randomRotation = CFrame.Angles(0, math.rad(math.random(0, 360)), 0)

			-- Start position (underground)
			local startPos = modelPos - Vector3.new(0, riseHeight, 0)
			local endPos = modelPos

			model:PivotTo(CFrame.new(startPos) * randomRotation)
			model.Parent = effectClone
			
			-- Emit any particle effects attached to this boulder
			for _, desc in ipairs(model:GetDescendants()) do
				if desc:IsA("ParticleEmitter") then
					local burstAmount = desc.Rate > 0 and math.ceil(desc.Rate) or 20
					desc:Emit(burstAmount)
					-- break4 emitter only emits once at the start, then stays disabled
					if desc.Name == "break4" then
						desc.Enabled = false
					else
						desc.Enabled = true
					end
				end
			end
			
			-- Disable break4 after a short delay to ensure it emitted
			task.delay(0.1, function()
				for _, desc in ipairs(model:GetDescendants()) do
					if desc:IsA("ParticleEmitter") and desc.Name == "break4" then
						desc.Enabled = false
					end
				end
			end)

			-- Animate rising out of ground
			local startTime = tick()
			local connection
			connection = RunService.Heartbeat:Connect(function()
				local elapsed = tick() - startTime
				local progress = math.min(elapsed / riseTime, 1)

				-- Ease out for natural feel
				local easedProgress = 1 - (1 - progress) ^ 2

				local currentPos = startPos:Lerp(endPos, easedProgress)
				model:PivotTo(CFrame.new(currentPos) * randomRotation)

				if progress >= 1 then
					connection:Disconnect()
				end
			end)
		end)
	end

	-- Cleanup after duration
	Debris:AddItem(effectClone, duration)

	return effectClone
end

-- Spawn a GROUND VFX effect (particles/emitters spawning along path from NPC to target)
local function spawnGroundVFX(effectTemplate, npcModel, targetPosition, spawnDistance, duration)
	local hrp = npcModel:FindFirstChild("HumanoidRootPart")
	if not hrp then
		warn("[EffectSpawner] Ground VFX: No HumanoidRootPart found")
		return
	end
	
	local npcPos = hrp.Position
	local localPlayer = game:GetService("Players").LocalPlayer
	
	-- Same path calculation as boulders - fixed distance
	local lateralSpread = 30
	local fixedDistance = 80
	local staggerDelay = 0.075
	local numEffects = 15 -- Number of effect points along the path
	
	local endTarget = targetPosition or (npcPos + hrp.CFrame.LookVector * (spawnDistance or 50))
	local flatDirection = Vector3.new(endTarget.X - npcPos.X, 0, endTarget.Z - npcPos.Z)
	local direction = flatDirection.Unit
	local totalDistance = fixedDistance -- Use fixed distance, not player distance
	local perpendicular = Vector3.new(-direction.Z, 0, direction.X)
	local startPos = npcPos
	
	print("[EffectSpawner] Ground VFX spawning along path, distance:", totalDistance)
	
	-- Spawn effects along the path
	for i = 1, numEffects do
		task.delay((i - 1) * staggerDelay, function()
			local progress = (i - 1) / math.max(numEffects - 1, 1)
			local distanceAlongPath = progress * totalDistance
			
			local pathPosXZ = Vector3.new(startPos.X, 0, startPos.Z) + direction * distanceAlongPath
			local lateralOffset = (math.random() * 2 - 1) * lateralSpread
			local effectPosXZ = pathPosXZ + perpendicular * lateralOffset
			
			-- Raycast to find ground
			local boulderRayParams = RaycastParams.new()
			boulderRayParams.FilterType = Enum.RaycastFilterType.Exclude
			local currentPlayerChar = localPlayer and localPlayer.Character
			local excludeList = {npcModel}
			if currentPlayerChar then
				table.insert(excludeList, currentPlayerChar)
			end
			boulderRayParams.FilterDescendantsInstances = excludeList
			
			local rayStart = Vector3.new(effectPosXZ.X, startPos.Y + 100, effectPosXZ.Z)
			local rayResult = workspace:Raycast(rayStart, Vector3.new(0, -200, 0), boulderRayParams)
			
			local spawnPos
			if rayResult then
				spawnPos = rayResult.Position
			else
				spawnPos = Vector3.new(effectPosXZ.X, startPos.Y, effectPosXZ.Z)
			end
			
			-- Clone the effect for this position
			local effectClone = effectTemplate:Clone()
			effectClone.Name = "GroundVFX_Active"
			
			-- Position the main part
			local mainPart = effectClone:FindFirstChildWhichIsA("BasePart")
			if mainPart then
				mainPart.CFrame = CFrame.new(spawnPos)
				mainPart.Anchored = true
				mainPart.CanCollide = false
				mainPart.Transparency = 1
			end
			
			effectClone.Parent = workspace
			
			-- Emit particles
			for _, desc in ipairs(effectClone:GetDescendants()) do
				if desc:IsA("ParticleEmitter") then
					desc:Emit(1)
					desc.Enabled = true
				end
			end
			
			-- Cleanup after duration
			task.delay(duration, function()
				for _, desc in ipairs(effectClone:GetDescendants()) do
					if desc:IsA("ParticleEmitter") then
						desc.Enabled = false
					end
				end
				task.wait(1)
				if effectClone and effectClone.Parent then
					effectClone:Destroy()
				end
			end)
		end)
	end
end

-- Spawn TREE effects (trees rising from ground toward player)
local function spawnTreeEffect(effectTemplate, npcModel, targetPosition, spawnDistance, duration, density, spawnDuration)
	print("[EffectSpawner] ===== TREE SPAWN STARTING =====")
	print("[EffectSpawner] Template:", effectTemplate.Name)
	print("[EffectSpawner] SpawnDuration:", spawnDuration or "not set")
	
	local hrp = npcModel:FindFirstChild("HumanoidRootPart")
	if not hrp then
		warn("[EffectSpawner] Tree spawn: No HumanoidRootPart found")
		return
	end
	
	local localPlayer = game:GetService("Players").LocalPlayer
	
	-- Get all tree models from the template
	local treeModels = {}
	for _, child in ipairs(effectTemplate:GetChildren()) do
		if child:IsA("Model") then
			table.insert(treeModels, child)
			print("[EffectSpawner] Found tree model:", child.Name)
		end
	end
	
	if #treeModels == 0 then
		warn("[EffectSpawner] Tree spawn: No tree models found in effect. Children are:")
		for _, child in ipairs(effectTemplate:GetChildren()) do
			print("  -", child.Name, child.ClassName)
		end
		return
	end
	
	print("[EffectSpawner] Tree spawn has", #treeModels, "tree types available")
	
	-- Spawn parameters
	local spawnRadius = 25            -- Radius around player where trees spawn
	local riseHeight = 50             -- How far below ground trees start (deep underground)
	local riseTime = 0.5
	local treesPerSecond = density or 1  -- Trees spawned per second
	local totalSpawnTime = spawnDuration or 5  -- How long to keep spawning trees
	
	print("[EffectSpawner] Spawning trees for", totalSpawnTime, "seconds at", treesPerSecond, "per second, radius:", spawnRadius)
	
	-- Create container for spawned trees
	local treeContainer = Instance.new("Folder")
	treeContainer.Name = "TreeEffect_Active"
	treeContainer.Parent = workspace
	
	-- Spawn trees continuously over spawnDuration
	local treeIndex = 0
	local spawnStartTime = tick()
	
	local function spawnSingleTree()
		treeIndex = treeIndex + 1
		local i = treeIndex
		
		-- Get current player position (spawn around player!)
		local currentPlayerChar = localPlayer and localPlayer.Character
		local playerHRP = currentPlayerChar and currentPlayerChar:FindFirstChild("HumanoidRootPart")
		if not playerHRP then return end
		
		local playerPos = playerHRP.Position
		
		-- Spawn in a random position around the player
		local angle = math.random() * math.pi * 2  -- Random angle 0-360 degrees
		local distance = math.random() * spawnRadius  -- Random distance within radius
		local offsetX = math.cos(angle) * distance
		local offsetZ = math.sin(angle) * distance
		
		local treePosXZ = Vector3.new(playerPos.X + offsetX, 0, playerPos.Z + offsetZ)
		
		-- Raycast to find ground
		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		local excludeList = {npcModel, treeContainer}
		if currentPlayerChar then
			table.insert(excludeList, currentPlayerChar)
		end
		rayParams.FilterDescendantsInstances = excludeList
		
		local rayStart = Vector3.new(treePosXZ.X, playerPos.Y + 100, treePosXZ.Z)
		local rayResult = workspace:Raycast(rayStart, Vector3.new(0, -200, 0), rayParams)
		
		local groundPos
		if rayResult then
			groundPos = rayResult.Position
		else
			groundPos = Vector3.new(treePosXZ.X, startPos.Y, treePosXZ.Z)
		end
		
		print("[EffectSpawner] Spawning tree", i, "at", groundPos)
		
		-- Pick a random tree model
		local randomTree = treeModels[math.random(1, #treeModels)]
		local treeClone = randomTree:Clone()
		treeClone.Name = "Tree_" .. i
		
		-- Random rotation
		local randomRotation = CFrame.Angles(0, math.rad(math.random(0, 360)), 0)
		
		-- Find Center attachment to know where the tree's center is
		local centerAttachment = treeClone:FindFirstChild("Center", true)
		local centerOffset = Vector3.new(0, 0, 0)
		if centerAttachment then
			-- Get how far the Center is from the model's pivot
			local pivotPos = treeClone:GetPivot().Position
			centerOffset = centerAttachment.WorldPosition - pivotPos
			print("[EffectSpawner] Tree has Center attachment, offset:", centerOffset)
		end
		
		-- Position tree so the Center attachment is at ground level when risen
		-- Start deep underground, rise up so Center reaches ground level (leaves hit player)
		local treeEndPos = groundPos - centerOffset  -- Adjust so Center ends at groundPos
		local treeStartPos = treeEndPos - Vector3.new(0, riseHeight, 0)  -- Start below that
		
		treeClone:PivotTo(CFrame.new(treeStartPos) * randomRotation)
		treeClone.Parent = treeContainer
		
		-- Animate rising out of ground
		local animStartTime = tick()
		local connection
		connection = RunService.Heartbeat:Connect(function()
			local elapsed = tick() - animStartTime
			local animProgress = math.min(elapsed / riseTime, 1)
			
			-- Ease out for natural feel
			local easedProgress = 1 - (1 - animProgress) ^ 2
			
			local currentPos = treeStartPos:Lerp(treeEndPos, easedProgress)
			treeClone:PivotTo(CFrame.new(currentPos) * randomRotation)
			
			if animProgress >= 1 then
				connection:Disconnect()
			end
		end)
	end
	
	-- Spawn trees continuously over the spawn duration
	task.spawn(function()
		local spawnInterval = 1 / treesPerSecond
		while tick() - spawnStartTime < totalSpawnTime do
			spawnSingleTree()
			task.wait(spawnInterval)
		end
		print("[EffectSpawner] Tree spawning complete. Total trees:", treeIndex)
	end)
	
	-- Cleanup after duration
	Debris:AddItem(treeContainer, duration)
	
	return treeContainer
end

-- Spawn a PARTICLE effect (original behavior)
local function spawnParticleEffect(effectTemplate, attachment, targetPosition, duration)
	-- Clone the effect
	local effectClone = effectTemplate:Clone()
	local effectName = effectTemplate.Name
	
	-- DEBUG: Print the structure of what we cloned
	print("[EffectSpawner] ====== CLONED EFFECT STRUCTURE ======")
	print("[EffectSpawner] Effect name:", effectName, "| Type:", effectClone.ClassName)
	for _, child in ipairs(effectClone:GetChildren()) do
		print("[EffectSpawner]   Child:", child.Name, "| Type:", child.ClassName)
		for _, subChild in ipairs(child:GetChildren()) do
			print("[EffectSpawner]     SubChild:", subChild.Name, "| Type:", subChild.ClassName)
		end
	end
	print("[EffectSpawner] =====================================")
	
	-- Check if this effect should follow the attachment
	-- Only GroundSlamEffectEnergy follows Floor - cracks stay where they spawn on the ground
	local shouldFollow = effectName == "GroundSlamEffectEnergy"
	
	-- Collect all emitters FIRST (before parenting)
	-- Separate Crack emitters (emit early) from other emitters
	local emitters = {}
	local crackEmitters = {}
	
	print("[EffectSpawner] Scanning for emitters in:", effectName)
	
	for _, child in ipairs(effectClone:GetDescendants()) do
		if child:IsA("ParticleEmitter") then
			child.Enabled = false -- Make sure they're off initially
			
			-- Check if this emitter is inside a "Crack" model (for GroundSlamEffect)
			local isCrackEmitter = false
			local parent = child.Parent
			while parent and parent ~= effectClone do
				if parent.Name == "Crack" or parent.Name == "Cracks" then
					isCrackEmitter = true
					break
				end
				parent = parent.Parent
			end
			
			if isCrackEmitter then
				table.insert(crackEmitters, child)
				print("[EffectSpawner] Found CRACK emitter:", child.Name, "in", child.Parent.Name)
			else
				table.insert(emitters, child)
				print("[EffectSpawner] Found emitter:", child.Name, "in", child.Parent.Name)
			end
		end
	end
	if effectClone:IsA("ParticleEmitter") then
		effectClone.Enabled = false
		table.insert(emitters, effectClone)
	end
	
	print("[EffectSpawner] Total emitters found - Crack:", #crackEmitters, "Other:", #emitters)
	
	-- Get the attachment position (use targetPosition if provided by server for accuracy)
	local attachPos = targetPosition or attachment.WorldPosition
	print("[EffectSpawner] SPAWNING", effectName, "at position:", attachPos, "(from server:", targetPosition ~= nil, ") attachment:", attachment:GetFullName())
	
	-- Track all parts for following
	local partsToFollow = {}
	local originalOffsets = {} -- Store offset from attachment for each part
	local attachmentsToFollow = {} -- Track attachments separately
	local attachmentOffsets = {}
	
	-- If the effect template is a Model or Folder, parent to workspace
	-- PRESERVE original rotations, only translate position
	if effectClone:IsA("BasePart") then
		-- Single part with emitters - keep original rotation, move to attachment position
		local originalRotation = effectClone.CFrame.Rotation
		effectClone.CFrame = CFrame.new(attachPos) * originalRotation
		effectClone.Anchored = true
		effectClone.CanCollide = false
		effectClone.Transparency = 1
		effectClone.Parent = workspace
		
		if shouldFollow then
			table.insert(partsToFollow, effectClone)
			originalOffsets[effectClone] = CFrame.new() * originalRotation
		end
		
		print("[EffectSpawner] Parented BasePart effect - preserved rotation")
	elseif effectClone:IsA("Model") then
		-- Special handling for MoreHit1 - clone perfectly, just move to attachment position
		if effectName == "MoreHit1" then
			-- Find the center/pivot of the model
			local primaryPart = effectClone.PrimaryPart or effectClone:FindFirstChildWhichIsA("BasePart")
			
			if primaryPart then
				-- Calculate offset needed to move model to attachment
				local originalPos = primaryPart.Position
				local offset = attachPos - originalPos
				
				-- Move all parts by the offset (preserves relative positions)
				for _, d in ipairs(effectClone:GetDescendants()) do
					if d:IsA("BasePart") then
						d.CFrame = d.CFrame + offset
						d.Anchored = true
						d.CanCollide = false
						d.Transparency = 1
					end
				end
			end
			
			effectClone.Parent = workspace
			print("[EffectSpawner] MoreHit1 - moved model to:", attachPos, "preserving internal structure")
		-- For GroundSlamEffect, use simple PivotTo like Bull step effect
		elseif effectName == "GroundSlamEffect" then
			-- Anchor all parts first
			for _, d in ipairs(effectClone:GetDescendants()) do
				if d:IsA("BasePart") then
					d.Anchored = true
					d.CanCollide = false
				end
			end
			
			-- Simple pivot to attachment position, 5 studs down
			local crackPosition = attachPos - Vector3.new(0, 4, 0)
			effectClone:PivotTo(CFrame.new(crackPosition))
			effectClone.Parent = workspace
			print("[EffectSpawner] GroundSlamEffect - PivotTo position:", crackPosition, "(5 studs down from", attachPos, ")")
		elseif effectName == "GroundSlamEffectEnergy" then
			-- GroundSlamEffectEnergy: Use Heartbeat following like Bull step effect
			-- Anchor all parts first
			for _, d in ipairs(effectClone:GetDescendants()) do
				if d:IsA("BasePart") then
					d.Anchored = true
					d.CanCollide = false
				end
			end
			
			-- Position at attachment
			effectClone:PivotTo(CFrame.new(attachPos))
			effectClone.Parent = workspace
			
			-- Find a part to follow with
			local weldPart = effectClone.PrimaryPart or effectClone:FindFirstChildWhichIsA("BasePart")
			
			if weldPart then
				local initialRotation = weldPart.CFrame.Rotation
				
				-- Follow attachment with Heartbeat (like Bull does)
				local followConnection
				local followStartTime = tick()
				followConnection = RunService.Heartbeat:Connect(function()
					if not effectClone or not effectClone.Parent then
						if followConnection then followConnection:Disconnect() end
						return
					end
					
					-- Stop following after duration
					if (tick() - followStartTime) >= duration then
						followConnection:Disconnect()
						return
					end
					
					-- Follow attachment position, keep rotation
					weldPart.CFrame = CFrame.new(attachment.WorldPosition) * initialRotation
				end)
				print("[EffectSpawner] GroundSlamEffectEnergy - Following with Heartbeat:", attachment:GetFullName())
			else
				print("[EffectSpawner] GroundSlamEffectEnergy - No weldPart found, won't follow")
			end
		else
			-- Original complex offset logic for other effects
			local primaryPart = effectClone.PrimaryPart or effectClone:FindFirstChildWhichIsA("BasePart", true)
			local originalPivot
			
			if primaryPart then
				originalPivot = primaryPart.Position
			else
				-- No parts found - try to find an attachment as pivot
				local firstAttachment = effectClone:FindFirstChildWhichIsA("Attachment", true)
				if firstAttachment then
					originalPivot = firstAttachment.WorldPosition
					print("[EffectSpawner] Using Attachment as pivot:", firstAttachment.Name)
				else
					originalPivot = Vector3.new(0, 0, 0)
				end
			end
			
			local offset = attachPos - originalPivot
			
			-- Move all parts by the offset (preserves relative positions and rotations)
			for _, descendant in ipairs(effectClone:GetDescendants()) do
				if descendant:IsA("BasePart") then
					local relativeOffset = descendant.Position - originalPivot
					descendant.CFrame = descendant.CFrame + offset
					descendant.Anchored = true
					descendant.CanCollide = false
					
					if shouldFollow then
						table.insert(partsToFollow, descendant)
						originalOffsets[descendant] = CFrame.new(relativeOffset) * descendant.CFrame.Rotation
					end
				end
			end
			
			-- Also move all attachments that are directly in Models (not in Parts)
			for _, descendant in ipairs(effectClone:GetDescendants()) do
				if descendant:IsA("Attachment") then
					-- Check if parent is a Model (not a Part) - these need manual positioning
					if descendant.Parent:IsA("Model") then
						local relativeOffset = descendant.WorldPosition - originalPivot
						descendant.WorldPosition = attachPos + relativeOffset
						
						if shouldFollow then
							table.insert(attachmentsToFollow, descendant)
							attachmentOffsets[descendant] = relativeOffset
						end
						print("[EffectSpawner] Moved orphan Attachment:", descendant.Name)
					elseif shouldFollow then
						-- For GroundSlamEffectEnergy: track ALL attachments for following
						local relativeOffset = descendant.WorldPosition - originalPivot
						table.insert(attachmentsToFollow, descendant)
						attachmentOffsets[descendant] = relativeOffset
						print("[EffectSpawner] Tracking Attachment for follow:", descendant.Name)
					end
				end
			end
			
			effectClone.Parent = workspace
			print("[EffectSpawner] Parented Model effect - preserved all rotations, parts:", #partsToFollow)
		end
	elseif effectClone:IsA("Folder") then
		-- Folder with parts - find first part as pivot
		local firstPart = effectClone:FindFirstChildWhichIsA("BasePart", true)
		if firstPart then
			local originalPivot = firstPart.Position
			local offset = attachPos - originalPivot
			
			-- Move all parts by the offset (preserves relative positions and rotations)
			for _, descendant in ipairs(effectClone:GetDescendants()) do
				if descendant:IsA("BasePart") then
					local relativeOffset = descendant.Position - originalPivot
					descendant.CFrame = descendant.CFrame + offset
					descendant.Anchored = true
					descendant.CanCollide = false
					
					if shouldFollow then
						table.insert(partsToFollow, descendant)
						originalOffsets[descendant] = CFrame.new(relativeOffset) * descendant.CFrame.Rotation
					end
				end
			end
		end
		effectClone.Parent = workspace
		print("[EffectSpawner] Parented Folder effect - preserved all rotations")
	else
		-- Fallback: try to parent to attachment (for standalone emitters)
		effectClone.Parent = attachment
		print("[EffectSpawner] Parented effect directly to attachment")
	end
	
	print("[EffectSpawner] Effect clone parented:", effectClone.Parent and effectClone.Parent:GetFullName() or "NONE")
	print("[EffectSpawner] Crack emitters (early):", #crackEmitters, "| Other emitters:", #emitters)
	if shouldFollow then
		print("[EffectSpawner] Effect will FOLLOW attachment - tracking", #partsToFollow, "parts,", #attachmentsToFollow, "attachments")
		
		-- Set LockedToPart = true on ALL emitters so particles follow their parent parts
		for _, emitter in ipairs(crackEmitters) do
			emitter.LockedToPart = true
		end
		for _, emitter in ipairs(emitters) do
			emitter.LockedToPart = true
		end
		print("[EffectSpawner] Set LockedToPart = true on all emitters")
	end
	
	-- Enable CRACK emitters FIRST (they emit early) and burst immediately
	for _, emitter in ipairs(crackEmitters) do
		emitter.Enabled = true
		-- Burst particles immediately so they appear instantly
		emitter:Emit(2)
		print("[EffectSpawner] Enabled + Emit CRACK emitter:", emitter.Name)
	end
	
	-- Disable ALL emitters after delay (at end of animation + 0.5s pause)
	if #crackEmitters > 0 or #emitters > 0 then
		task.delay(1.25, function()
			-- Disable crack emitters
			for _, emitter in ipairs(crackEmitters) do
				if emitter and emitter.Parent then
					emitter.Enabled = false
				end
			end
			-- Disable other emitters
			for _, emitter in ipairs(emitters) do
				if emitter and emitter.Parent then
					emitter.Enabled = false
				end
			end
			print("[EffectSpawner] Disabled ALL emitters after 0.4s")
		end)
	end
	
	-- Special handling for MoreHit1 - burst emit once instead of enabling
	if effectName == "MoreHit1" then
		print("[EffectSpawner] MoreHit1 detected - burst emitting once for each emitter")
		for _, emitter in ipairs(emitters) do
			emitter:Emit(1) -- Emit 1 particle from each emitter
			print("[EffectSpawner] Burst emit 1 from:", emitter.Name)
		end
		-- Don't enable them, just let the burst particles play out
	-- Enable other emitters after a tiny delay (or immediately if no crack emitters)
	elseif #crackEmitters > 0 then
		task.delay(0.1, function()
			for _, emitter in ipairs(emitters) do
				emitter.Enabled = true
			end
		end)
	else
		for _, emitter in ipairs(emitters) do
			emitter.Enabled = true
			-- Speed up GroundSlamEffectEnergy by 10x
			if effectName == "GroundSlamEffectEnergy" then
				emitter.Rate = emitter.Rate * 20
			end
		end
	end
	
	-- If should follow, update position every frame
	if shouldFollow and (#partsToFollow > 0 or #attachmentsToFollow > 0) then
		task.spawn(function()
			local startTime = tick()
			while tick() - startTime < duration and effectClone.Parent do
				local currentAttachPos = attachment.WorldPosition
				
				-- Update parts
				for _, part in ipairs(partsToFollow) do
					if part.Parent then
						local offsetCFrame = originalOffsets[part]
						part.CFrame = CFrame.new(currentAttachPos) * offsetCFrame
					end
				end
				
				-- Update attachments
				for _, att in ipairs(attachmentsToFollow) do
					if att.Parent then
						local relOffset = attachmentOffsets[att]
						att.WorldPosition = currentAttachPos + relOffset
					end
				end
				
				task.wait()
			end
		end)
	end
	-- Cleanup after duration
	Debris:AddItem(effectClone, duration)
	
	return effectClone
end

-- Main event handler
spawnEffectEvent.OnClientEvent:Connect(function(effectName, npcModel, attachmentName, targetPosition, duration, extraData)
	print("[EffectSpawner] ========== RECEIVED EVENT ==========")
	print("[EffectSpawner] Effect:", effectName)
	print("[EffectSpawner] NPC:", npcModel and npcModel.Name or "NIL")
	print("[EffectSpawner] Attachment name:", attachmentName)
	print("[EffectSpawner] Target:", targetPosition)
	print("[EffectSpawner] Duration:", duration)
	print("[EffectSpawner] ExtraData:", extraData and "YES" or "NO")
	
	duration = duration or 5
	
	-- Extract extra data
	local effectType = extraData and extraData.effectType or nil
	local speed = extraData and extraData.speed or 80
	local spawnDistance = extraData and extraData.spawnDistance or 50
	local bodyPart = extraData and extraData.bodyPart or nil
	local scale = extraData and extraData.scale or nil
	local lockToPart = extraData and extraData.lockToPart or nil
	
	-- Get the effect template
	local effectTemplate = effectsFolder:FindFirstChild(effectName)
	if not effectTemplate then
		warn("[EffectSpawner] Could not find effect:", effectName, "in Effects folder")
		-- List what's in the Effects folder
		print("[EffectSpawner] Available effects:")
		for _, child in ipairs(effectsFolder:GetChildren()) do
			print("  -", child.Name)
		end
		return
	end
	print("[EffectSpawner] Found effect template:", effectTemplate.Name)
	
	-- Helper function to find attachment (respects bodyPart if specified)
	local function findAttachment()
		if bodyPart and npcModel then
			local part = npcModel:FindFirstChild(bodyPart)
			if part then
				local att = part:FindFirstChild(attachmentName)
				if att then
					print("[EffectSpawner] Found attachment on bodyPart:", bodyPart, "->", att:GetFullName())
					return att
				end
			end
			warn("[EffectSpawner] Could not find attachment:", attachmentName, "on bodyPart:", bodyPart)
		end
		-- Fallback: search entire model
		return npcModel and npcModel:FindFirstChild(attachmentName, true)
	end
	
	-- Handle special effect types first
	if effectType == "projectile" then
		-- Projectile: flies from source toward target
		local attachment = findAttachment()
		if not attachment then
			warn("[EffectSpawner] Projectile: Could not find attachment:", attachmentName)
			return
		end
		print("[EffectSpawner] Spawning PROJECTILE effect:", effectName)
		spawnProjectileEffect(effectTemplate, attachment, targetPosition, speed, duration)
		return
	elseif effectType == "smash" then
		-- Smash: emit all particles once at attachment location
		local attachment = findAttachment()
		if not attachment then
			warn("[EffectSpawner] Smash: Could not find attachment:", attachmentName)
			return
		end
		local effectChild = extraData and extraData.effectChild or nil
		local emitCount = extraData and extraData.emitCount or nil
		local enableOnly = extraData and extraData.enableOnly or nil
		local spawnOnFloor = extraData and extraData.spawnOnFloor or nil
		local followAttachment = extraData and extraData.followAttachment or nil
		print("[EffectSpawner] Spawning SMASH effect:", effectName, "child:", effectChild or "ALL", "emitCount:", emitCount or 1, "enableOnly:", enableOnly or false, "onFloor:", spawnOnFloor or false, "follow:", followAttachment or false)
		spawnSmashEffect(effectTemplate, attachment, duration, effectChild, emitCount, enableOnly, spawnOnFloor, scale, followAttachment)
		return
	elseif effectType == "groundSpawn" then
		-- Ground spawn: models spawned at distance
		print("[EffectSpawner] Spawning GROUND SPAWN effect:", effectName)
		spawnGroundEffect(effectTemplate, npcModel, targetPosition, spawnDistance, duration)
		return
	elseif effectType == "groundVFX" then
		-- Ground VFX: particles spawned at distance
		print("[EffectSpawner] Spawning GROUND VFX effect:", effectName)
		spawnGroundVFX(effectTemplate, npcModel, targetPosition, spawnDistance, duration)
		return
	elseif effectType == "treeSpawn" then
		-- Tree spawn: trees rising from ground
		local density = extraData and extraData.density or 1
		local spawnDuration = extraData and extraData.spawnDuration or 5
		print("[EffectSpawner] Spawning TREE effect:", effectName, "density:", density, "spawnDuration:", spawnDuration)
		spawnTreeEffect(effectTemplate, npcModel, targetPosition, spawnDistance, duration, density, spawnDuration)
		return
	end
	
	-- Standard effect types - need attachment
	local attachment = findAttachment()
	if not attachment then
		warn("[EffectSpawner] Could not find attachment:", attachmentName, "on", npcModel and npcModel.Name or "NIL")
		-- List what's actually in the NPC
		if npcModel then
			print("[EffectSpawner] NPC children:")
			for _, child in ipairs(npcModel:GetDescendants()) do
				if child:IsA("Attachment") then
					print("  - Attachment:", child.Name, "at", child:GetFullName())
				end
			end
		end
		return
	end
	print("[EffectSpawner] Found attachment:", attachment:GetFullName())
	
	-- Check if this is a TRAIL effect (has Trail objects inside)
	local isTrailEffect = effectTemplate:FindFirstChild("Trail", true) ~= nil and effectName == "Trail"
	
	-- Check if this is a BEAM effect (has P0 and P1 structure)
	local isBeamEffect = effectTemplate:FindFirstChild("P0") and effectTemplate:FindFirstChild("P1")
	
	if isTrailEffect then
		-- Trail effect: attach trails to NPC
		print("[EffectSpawner] Spawning TRAIL effect:", effectName)
		spawnTrailEffect(effectTemplate, attachment, duration)
	elseif isBeamEffect then
		-- Beam effect: P0 at source, P1 at target
		print("[EffectSpawner] Spawning BEAM effect:", effectName)
		spawnBeamEffect(effectTemplate, attachment, targetPosition, duration)
	else
		-- Particle effect: attach to NPC and face target
		print("[EffectSpawner] Spawning PARTICLE effect:", effectName)
		spawnParticleEffect(effectTemplate, attachment, targetPosition, duration)
	end
end)

print("[EffectSpawner] Client effect spawner ready (Beams + Particles + Trails + Projectiles + Ground Effects)")
