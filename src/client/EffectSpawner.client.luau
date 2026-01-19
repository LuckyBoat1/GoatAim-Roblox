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
local function spawnBeamEffect(effectTemplate, sourceAttachment, targetPosition, duration)
	local effectClone = effectTemplate:Clone()
	
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
	
	-- PRESERVE ALL ORIGINAL ROTATIONS - move the ENTIRE effect as a unit
	-- This keeps all attachments, beams, and parts exactly as designed
	
	local sourcePos = sourceAttachment.WorldPosition
	
	-- Get original positions from template
	local originalP0Pos = P0.Position
	local originalP1Pos = P1.Position
	local originalDirection = (originalP1Pos - originalP0Pos).Unit
	local originalDistance = (originalP1Pos - originalP0Pos).Magnitude
	
	-- Calculate new direction from source to target
	local newDirection = (targetPosition - sourcePos).Unit
	local newDistance = (targetPosition - sourcePos).Magnitude
	
	-- Calculate the rotation to align original direction with new direction
	local rotationCFrame = CFrame.new()
	local dotProduct = originalDirection:Dot(newDirection)
	
	if dotProduct < 0.9999 then
		local axis = originalDirection:Cross(newDirection)
		if axis.Magnitude > 0.0001 then
			axis = axis.Unit
			local angle = math.acos(math.clamp(dotProduct, -1, 1))
			rotationCFrame = CFrame.fromAxisAngle(axis, angle)
		elseif dotProduct < 0 then
			-- Opposite directions
			local perpAxis = Vector3.new(1, 0, 0)
			if math.abs(originalDirection:Dot(perpAxis)) > 0.9 then
				perpAxis = Vector3.new(0, 1, 0)
			end
			rotationCFrame = CFrame.fromAxisAngle(perpAxis, math.pi)
		end
	end
	
	-- Calculate scale factor for distance
	local scaleFactor = newDistance / originalDistance
	
	-- Store ALL original WorldCFrames before modifying anything
	local originalCFrames = {}
	local originalWorldCFrames = {} -- For attachments, store WorldCFrame
	
	for _, descendant in ipairs(effectClone:GetDescendants()) do
		if descendant:IsA("BasePart") then
			originalCFrames[descendant] = descendant.CFrame
		elseif descendant:IsA("Attachment") then
			originalWorldCFrames[descendant] = descendant.WorldCFrame
		end
	end
	originalCFrames[P0] = P0.CFrame
	originalCFrames[P1] = P1.CFrame
	
	-- Calculate pivot point (P0's original position)
	local pivotPoint = originalP0Pos
	
	-- Transform ALL parts: rotate around pivot, then translate to source
	for part, originalCFrame in pairs(originalCFrames) do
		if part:IsA("BasePart") then
			-- Get position relative to pivot
			local relativePos = originalCFrame.Position - pivotPoint
			
			-- Scale the relative position (to handle different distances)
			local scaledRelativePos = relativePos * scaleFactor
			
			-- Rotate the relative position
			local rotatedRelativePos = rotationCFrame:VectorToWorldSpace(scaledRelativePos)
			
			-- Calculate new position
			local newPos = sourcePos + rotatedRelativePos
			
			-- Apply rotation to orientation
			local newRotation = rotationCFrame * originalCFrame.Rotation
			
			-- Set new CFrame
			part.CFrame = CFrame.new(newPos) * newRotation
		end
	end
	
	-- Transform ALL attachments using their WorldCFrame
	-- This handles attachments inside Folders properly
	for attachment, originalWorldCFrame in pairs(originalWorldCFrames) do
		-- Get position relative to pivot
		local relativePos = originalWorldCFrame.Position - pivotPoint
		
		-- Scale the relative position
		local scaledRelativePos = relativePos * scaleFactor
		
		-- Rotate the relative position
		local rotatedRelativePos = rotationCFrame:VectorToWorldSpace(scaledRelativePos)
		
		-- Calculate new world position
		local newWorldPos = sourcePos + rotatedRelativePos
		
		-- Apply rotation to orientation
		local newWorldRotation = rotationCFrame * originalWorldCFrame.Rotation
		
		-- Set new WorldCFrame
		attachment.WorldCFrame = CFrame.new(newWorldPos) * newWorldRotation
	end
	
	-- Handle P1 > Model > Part structure for target effects
	local targetModel = P1:FindFirstChild("Model")
	if targetModel then
		print("[EffectSpawner] Found target Model in P1")
	end
	
	-- Parent to workspace
	effectClone.Parent = workspace
	
	-- Connect beams: P0 attachments connect to P1 attachments
	-- Inner folder in P0
	local P0Inner = P0:FindFirstChild("Inner")
	local P0Outer = P0:FindFirstChild("Outer")
	local P0Core = P0:FindFirstChild("Core") -- Core part with beams
	local P1Outer = P1:FindFirstChild("Outer")
	
	-- Helper function to connect beams from a folder to P1.Outer
	local function connectBeamsFromFolder(folder)
		if not folder or not P1Outer then return end
		
		for _, child in ipairs(folder:GetChildren()) do
			if child:IsA("Attachment") then
				for _, beam in ipairs(child:GetChildren()) do
					if beam:IsA("Beam") then
						-- Find matching attachment in P1.Outer by name
						local targetAtt = P1Outer:FindFirstChild(child.Name)
						if targetAtt and targetAtt:IsA("Attachment") then
							beam.Attachment1 = targetAtt
							print("[EffectSpawner] Connected beam from", child.Name, "to P1.Outer")
						else
							-- If no matching name, connect to first available attachment
							for _, p1Att in ipairs(P1Outer:GetChildren()) do
								if p1Att:IsA("Attachment") then
									beam.Attachment1 = p1Att
									print("[EffectSpawner] Connected beam to first P1.Outer attachment")
									break
								end
							end
						end
					end
				end
			end
		end
	end
	
	-- Connect Inner beams
	connectBeamsFromFolder(P0Inner)
	
	-- Connect Outer beams  
	connectBeamsFromFolder(P0Outer)
	
	-- Connect Core beams (if Core is a Part with attachments)
	if P0Core and P0Core:IsA("BasePart") then
		for _, child in ipairs(P0Core:GetChildren()) do
			if child:IsA("Attachment") then
				for _, beam in ipairs(child:GetChildren()) do
					if beam:IsA("Beam") and P1Outer then
						-- Connect to first P1.Outer attachment
						for _, p1Att in ipairs(P1Outer:GetChildren()) do
							if p1Att:IsA("Attachment") then
								beam.Attachment1 = p1Att
								print("[EffectSpawner] Connected Core beam to P1.Outer")
								break
							end
						end
					end
				end
			end
		end
	end
	
	-- Enable everything NOW (synchronized start)
	enableAllBeams(effectClone)
	enableAllEmitters(effectClone)
	
	print("[EffectSpawner] Beam effect activated! Beams and particles enabled.")
	
	-- Store the relative transform for updates
	local storedP1RelativeCFrame = P0.CFrame:ToObjectSpace(P1.CFrame)
	local storedP0Rotation = P0.CFrame.Rotation
	
	-- Update positions during the effect (follow source if it moves)
	-- IMPORTANT: Preserve original rotations to keep the 3D tube shape!
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not effectClone.Parent then
			connection:Disconnect()
			return
		end
		
		-- If source moves, recalculate positions maintaining the structure
		if sourceAttachment and sourceAttachment.Parent then
			local currentSourcePos = sourceAttachment.WorldPosition
			local currentTargetPos = P1.Position -- P1 position is our target
			
			-- Recalculate direction and rotation
			local currentDir = (currentTargetPos - currentSourcePos)
			if currentDir.Magnitude > 0.1 then
				currentDir = currentDir.Unit
				
				-- Calculate rotation to align original direction with current direction
				local currentRotation = CFrame.new()
				if originalDirection:Dot(currentDir) < 0.9999 then
					local axis = originalDirection:Cross(currentDir)
					if axis.Magnitude > 0.0001 then
						axis = axis.Unit
						local angle = math.acos(math.clamp(originalDirection:Dot(currentDir), -1, 1))
						currentRotation = CFrame.fromAxisAngle(axis, angle)
					end
				end
				
				-- Update P0 position and rotation
				P0.CFrame = CFrame.new(currentSourcePos) * currentRotation * storedP0Rotation
			end
		end
		
		-- P1 stays at target position facing source (already set, stationary)
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

-- Spawn a PARTICLE effect (original behavior)
local function spawnParticleEffect(effectTemplate, attachment, targetPosition, duration)
	-- Rotate attachment to face target ONCE and lock it
	local lockedCFrame
	if targetPosition then
		local startPos = attachment.WorldPosition
		lockedCFrame = CFrame.lookAt(startPos, targetPosition)
		attachment.WorldCFrame = lockedCFrame
	end
	
	-- Clone and parent the effect
	local effectClone = effectTemplate:Clone()
	
	-- Collect all emitters FIRST (before parenting)
	local emitters = {}
	for _, child in ipairs(effectClone:GetDescendants()) do
		if child:IsA("ParticleEmitter") then
			child.Enabled = false -- Make sure they're off initially
			table.insert(emitters, child)
		end
	end
	if effectClone:IsA("ParticleEmitter") then
		effectClone.Enabled = false
		table.insert(emitters, effectClone)
	end
	
	-- Parent AFTER collecting (so they don't start emitting early)
	effectClone.Parent = attachment
	
	-- Enable ALL emitters at the exact same moment
	for _, emitter in ipairs(emitters) do
		emitter.Enabled = true
	end
	
	-- Keep attachment locked in place during the effect (prevents spiral gaps)
	if lockedCFrame then
		task.spawn(function()
			local startTime = tick()
			while tick() - startTime < duration and effectClone.Parent do
				attachment.WorldCFrame = lockedCFrame
				task.wait()
			end
		end)
	end
	
	-- Cleanup after duration
	Debris:AddItem(effectClone, duration)
	
	return effectClone
end

-- Main event handler
spawnEffectEvent.OnClientEvent:Connect(function(effectName, npcModel, attachmentName, targetPosition, duration)
	duration = duration or 5
	
	-- Find the attachment on the NPC
	local attachment = npcModel and npcModel:FindFirstChild(attachmentName, true)
	if not attachment then
		warn("[EffectSpawner] Could not find attachment:", attachmentName, "on", npcModel)
		return
	end
	
	-- Get the effect template
	local effectTemplate = effectsFolder:FindFirstChild(effectName)
	if not effectTemplate then
		warn("[EffectSpawner] Could not find effect:", effectName)
		return
	end
	
	-- Check if this is a BEAM effect (has P0 and P1 structure)
	local isBeamEffect = effectTemplate:FindFirstChild("P0") and effectTemplate:FindFirstChild("P1")
	
	if isBeamEffect then
		-- Beam effect: P0 at source, P1 at target
		print("[EffectSpawner] Spawning BEAM effect:", effectName)
		spawnBeamEffect(effectTemplate, attachment, targetPosition, duration)
	else
		-- Particle effect: attach to NPC and face target
		print("[EffectSpawner] Spawning PARTICLE effect:", effectName)
		spawnParticleEffect(effectTemplate, attachment, targetPosition, duration)
	end
end)

print("[EffectSpawner] Client effect spawner ready (Beams + Particles)")
