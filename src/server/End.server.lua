warn("[END NPC] Script starting...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")

-- Create or get RemoteEvents folder
local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteEvents then
	remoteEvents = Instance.new("Folder")
	remoteEvents.Name = "RemoteEvents"
	remoteEvents.Parent = ReplicatedStorage
end

-- Create or get SpawnEffect RemoteEvent
local spawnEffectEvent = remoteEvents:FindFirstChild("SpawnEffectEvent")
if not spawnEffectEvent then
	spawnEffectEvent = Instance.new("RemoteEvent")
	spawnEffectEvent.Name = "SpawnEffectEvent"
	spawnEffectEvent.Parent = remoteEvents
end

-- Import Animations module (with error handling)
local Animations
local sharedFolder = ReplicatedStorage:FindFirstChild("Shared")
if not sharedFolder then
	warn("[End NPC] Shared folder not found in ReplicatedStorage! Make sure Rojo is syncing correctly.")
	return
end
local animModule = sharedFolder:FindFirstChild("Animations")
if not animModule then
	warn("[End NPC] Animations module not found in ReplicatedStorage.Shared!")
	return
end

local success, err = pcall(function()
	Animations = require(animModule)
end)
if not success then
	warn("[End NPC] Failed to require Animations module: " .. tostring(err))
	return
end

print("[End NPC] ✅ Animations module loaded successfully")

-- NPC Config
local NPC_FOLDER_NAME = "Npc"
local MODEL_NAME = "End"
local NPC_COUNT = 1
local WALK_SPEED = 16
local AGGRO_RANGE = 50        -- How far the NPC can detect players
local PREFERRED_DISTANCE = 40 -- NPC tries to stay this far from player
local DISTANCE_TOLERANCE = 5  -- How much variance is allowed (35-45 studs)
local DAMAGE = 10
local IDLE_TIME = {1, 2}
local WALK_TIME = {3, 6}
local WALK_RADIUS = 100
--
-- Animation IDs (change these for different NPCs)
local ANIM_WALK = 97383942534616
local ANIM_IDLE = 78973476418857
local ANIM_ATTACK1 = Animations.HammerSmash       -- Attack 1: HammerSlam
local ANIM_ATTACK2 = Animations.LowMagic          -- Attack 2: LowMagic (with beam)
local ANIM_ATTACK3 = Animations.MagicCircle       -- Attack 3: MagicCircle (with beam)
local ANIM_ULT = Animations.GatherChargeBlast     -- Ult (1/10 chance)
local ANIM_FLIGHT = Animations.ForwardFlight      -- Flight animation

print("[End NPC] ✅ Animation IDs loaded")

local NPCS = {}

-- EndSpawn model (search recursively in case it's in a folder)
local spawnModel = Workspace:FindFirstChild("EndSpawn", true)
if not spawnModel then 
	warn("[End NPC] ❌ EndSpawn model not found in Workspace! Please create a model named 'EndSpawn' with parts inside.")
	return
end
print("[End NPC] ✅ Found EndSpawn model at: " .. spawnModel:GetFullName())

-- Get all parts inside spawn model
local spawnParts = {}
for _, part in ipairs(spawnModel:GetDescendants()) do
	if part:IsA("BasePart") then
		table.insert(spawnParts, part)
	end
end
if #spawnParts == 0 then 
	warn("[End NPC] ❌ No parts found inside EndSpawn model! Add some parts to spawn on.")
	return
end
print("[End NPC] ✅ Found " .. #spawnParts .. " spawn parts")

-- Helper: get random spawn point above terrain
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

-- Helper: move NPC along path
local function moveAlongPath(npc, humanoid, targetPos)
	if not npc.PrimaryPart then 
		warn("moveAlongPath: No PrimaryPart")
		return false 
	end
	
	print("Moving NPC to: "..tostring(targetPos))
	
	local path = PathfindingService:CreatePath({
		AgentRadius = 2,
		AgentHeight = 5,
		AgentCanJump = true,
		AgentJumpHeight = 10,
		AgentMaxSlope = 45,
	})
	
	local success, err = pcall(function()
		path:ComputeAsync(npc.PrimaryPart.Position, targetPos)
	end)
	
	if not success then
		warn("Path compute failed: "..tostring(err))
		return false
	end
	
	print("Path status: "..tostring(path.Status))
	
	if path.Status == Enum.PathStatus.Success then
		local waypoints = path:GetWaypoints()
		print("Got "..#waypoints.." waypoints")
		
		for i, waypoint in ipairs(waypoints) do
			if not npc.Parent then return false end
			
			if waypoint.Action == Enum.PathWaypointAction.Jump then
				humanoid.Jump = true
			end
			
			humanoid:MoveTo(waypoint.Position)
			
			local reached = humanoid.MoveToFinished:Wait()
			if not reached then
				warn("Failed to reach waypoint "..i)
				return false
			end
		end
		return true
	else
		-- Fallback: direct movement
		print("Path failed, using direct MoveTo")
		humanoid:MoveTo(targetPos)
		humanoid.MoveToFinished:Wait()
		return true
	end
end

-- Spawn NPCs
local folder = ReplicatedStorage:FindFirstChild(NPC_FOLDER_NAME)
if not folder then 
	error("Npc folder missing in ReplicatedStorage! Please create a folder named 'Npc' in ReplicatedStorage.") 
end
local template = folder:FindFirstChild(MODEL_NAME)
if not template then 
	error("'"..MODEL_NAME.."' model missing in Npc folder! Please add an 'End' model to ReplicatedStorage.Npc folder.") 
end

print("Found NPC template: "..MODEL_NAME)
print("Spawning "..NPC_COUNT.." NPCs...")

for i = 1, NPC_COUNT do
	local spawnPart = spawnParts[math.random(1, #spawnParts)]
	local pos = getSpawnPosition(spawnPart)
	
	print("Attempting to spawn NPC #"..i.." at position: "..tostring(pos))

	local npc = template:Clone()
	npc.Parent = Workspace
	
	print("NPC cloned and parented to Workspace")
	
	-- UNANCHOR ALL PARTS (this is usually the issue!)
	for _, part in ipairs(npc:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
		end
	end
	
	if npc.PrimaryPart then
		npc:SetPrimaryPartCFrame(CFrame.new(pos))
	else
		warn("NPC has no PrimaryPart!")
		npc:MoveTo(pos)
	end

	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = WALK_SPEED
		
		-- Make sure HumanoidRootPart exists
		local hrp = npc:FindFirstChild("HumanoidRootPart")
		if not hrp then
			warn("NPC missing HumanoidRootPart - movement won't work properly!")
		end
		
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = humanoid
		end

		npc:SetAttribute("SpawnX", pos.X)
		npc:SetAttribute("SpawnY", pos.Y)
		npc:SetAttribute("SpawnZ", pos.Z)
		table.insert(NPCS, npc)
		print("Spawned NPC #"..i.." at "..tostring(pos))
	else
		warn("NPC has no Humanoid!")
	end
end

print("Spawned "..#NPCS.." NPCs")

-- Helper: get nearest player (ignoring height mostly)
local function getNearestPlayer(npcPos, maxDist)
	local nearest = nil
	local nearestDist = maxDist
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
			local pHrp = p.Character.HumanoidRootPart
			-- Use full 3D distance for proper aggro
			local dist = (pHrp.Position - npcPos).Magnitude
			
			if dist <= nearestDist then
				nearest = p
				nearestDist = dist
			end
		end
	end
	return nearest, nearestDist
end

-- NPC AI Loop - CONSTANT DETECTION
for _, npc in ipairs(NPCS) do
	task.spawn(function()
		local humanoid = npc:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end
		
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if not animator then return end
		
		local spawnPos = Vector3.new(
			npc:GetAttribute("SpawnX"),
			npc:GetAttribute("SpawnY"),
			npc:GetAttribute("SpawnZ")
		)

		-- Load animations
		local idleAnim = Instance.new("Animation")
		idleAnim.AnimationId = "rbxassetid://"..ANIM_IDLE
		local idleTrack = animator:LoadAnimation(idleAnim)

		local walkAnim = Instance.new("Animation")
		walkAnim.AnimationId = "rbxassetid://"..ANIM_WALK
		local walkTrack = animator:LoadAnimation(walkAnim)

		-- Load Attack 1 animation
		local attack1Anim = Instance.new("Animation")
		attack1Anim.AnimationId = "rbxassetid://"..ANIM_ATTACK1
		local attack1Track = animator:LoadAnimation(attack1Anim)
		attack1Track.Looped = false
		print("[NPC] Loaded Attack1 with ID:", ANIM_ATTACK1, "Track:", attack1Track)

		-- Load Attack 2 animation (with beam)
		local attack2Anim = Instance.new("Animation")
		attack2Anim.AnimationId = "rbxassetid://"..ANIM_ATTACK2
		local attack2Track = animator:LoadAnimation(attack2Anim)
		attack2Track.Looped = false
		print("[NPC] Loaded Attack2 with ID:", ANIM_ATTACK2, "Track:", attack2Track)

		-- Load Attack 3 animation (with beam)
		local attack3Anim = Instance.new("Animation")
		attack3Anim.AnimationId = "rbxassetid://"..ANIM_ATTACK3
		local attack3Track = animator:LoadAnimation(attack3Anim)
		attack3Track.Looped = false
		print("[NPC] Loaded Attack3 with ID:", ANIM_ATTACK3, "Track:", attack3Track)

		-- Load Ult animation (1/10 chance)
		local ultAnim = Instance.new("Animation")
		ultAnim.AnimationId = "rbxassetid://"..ANIM_ULT
		local ultTrack = animator:LoadAnimation(ultAnim)
		ultTrack.Looped = false
		print("[NPC] Loaded Ult with ID:", ANIM_ULT, "Track:", ultTrack)

		-- Load Flight animation
		local flightAnim = Instance.new("Animation")
		flightAnim.AnimationId = "rbxassetid://"..ANIM_FLIGHT
		local flightTrack = animator:LoadAnimation(flightAnim)
		
		-- Flight playback function with slowdown after 0.65s
		-- Plays at normal speed for 0.65s, then slows down the remaining ~1s
		local function playFlight(extendedDuration)
			-- extendedDuration: how long (in seconds) to extend the remaining part of the animation
			-- Default to 3 seconds if not specified
			extendedDuration = extendedDuration or 3
			
			flightTrack:Play()
			flightTrack:AdjustSpeed(1) -- Normal speed at start
			
			task.delay(0.65, function()
				if flightTrack.IsPlaying then
					-- Calculate speed: remaining animation is ~1s, stretch it to extendedDuration
					local remainingOriginal = 1 -- approximately 1 second left
					local slowSpeed = remainingOriginal / extendedDuration
					flightTrack:AdjustSpeed(slowSpeed)
				end
			end)
		end

		-- Helper function to check if any attack animation is playing
		local function isAttacking()
			return attack1Track.IsPlaying or attack2Track.IsPlaying or attack3Track.IsPlaying or ultTrack.IsPlaying
		end

		-- State tracking
		local state = "idle" -- "idle", "wander", "chase", "attack"
		local wanderTarget = nil
		local lastAttackTime = 0
		local wanderCooldown = 0
		local isShooting = false -- NPC is frozen while shooting beam

		idleTrack:Play()

		-- MAIN LOOP - runs every frame, always checks for players
		local debugTimer = 0
		while npc.Parent and humanoid.Health > 0 do
			local npcPos = npc.PrimaryPart and npc.PrimaryPart.Position or spawnPos
			
			-- Debug: print every 2 seconds
			debugTimer = debugTimer + 0.1
			if debugTimer >= 2 then
				debugTimer = 0
				local playerCount = #Players:GetPlayers()
				print("[NPC "..npc.Name.."] State: "..state.." | Players: "..playerCount.." | Pos: "..tostring(npcPos))
			end
			
			local targetPlayer, dist = getNearestPlayer(npcPos, AGGRO_RANGE)
			
			-- FROZEN while shooting beam - don't move or rotate
			if isShooting then
				humanoid:MoveTo(npcPos) -- Stop in place
				task.wait(0.1)
				continue
			end
			
			-- PRIORITY 1: Player in aggro range - chase/attack
			if targetPlayer and targetPlayer.Character then
				if debugTimer == 0 then -- Only print on debug tick
					print("[NPC "..npc.Name.."] DETECTED: "..targetPlayer.Name.." at dist "..math.floor(dist).." | State: "..state)
				end
				local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
				if hrp then
					local realDist = (npcPos - hrp.Position).Magnitude
					local directionToPlayer = (hrp.Position - npcPos).Unit
					local directionAwayFromPlayer = -directionToPlayer
					
					-- Maintain preferred distance (40 studs)
					if realDist < PREFERRED_DISTANCE - DISTANCE_TOLERANCE then
						-- Too close! Back away
						if state ~= "chase" then
							state = "chase"
							idleTrack:Stop()
							walkTrack:Play()
							print("[NPC] Too close! Backing away. realDist:", math.floor(realDist))
						end
						local retreatPos = npcPos + directionAwayFromPlayer * 10
						humanoid:MoveTo(retreatPos)
						
					elseif realDist > PREFERRED_DISTANCE + DISTANCE_TOLERANCE then
						-- Too far! Move closer
						if state ~= "chase" then
							state = "chase"
							idleTrack:Stop()
							walkTrack:Play()
							print("[NPC] Too far! Moving closer. realDist:", math.floor(realDist))
						end
						humanoid:MoveTo(hrp.Position)
						
					else
						-- At good distance - ATTACK
						if state ~= "attack" then
							state = "attack"
							idleTrack:Stop()
							walkTrack:Stop()
							print("[NPC] In attack range! realDist:", math.floor(realDist))
						end
						
						-- Face target (but don't move)
						local lookAtPos = Vector3.new(hrp.Position.X, npcPos.Y, hrp.Position.Z)
						if npc.PrimaryPart then
							npc.PrimaryPart.CFrame = CFrame.lookAt(npcPos, lookAtPos)
						end
						--
						-- Attack only if not already playing an attack animation AND cooldown elapsed
						local ATTACK_COOLDOWN = 2 -- seconds between attacks
						local currentTime = tick()
						local attacking = isAttacking()
						local cooldownElapsed = (currentTime - lastAttackTime) >= ATTACK_COOLDOWN
						--
						-- Debug: show why we can't attack
						if debugTimer == 0 then
							print("[NPC ATTACK CHECK] isAttacking:", attacking, "| cooldownElapsed:", cooldownElapsed)
							print("[NPC ATTACK CHECK] a1:", attack1Track.IsPlaying, "a2:", attack2Track.IsPlaying, "a3:", attack3Track.IsPlaying, "ult:", ultTrack.IsPlaying)
						end
						
						if not attacking and cooldownElapsed then
							lastAttackTime = currentTime -- Update the cooldown timer
							-- Random attack selection
							-- Ult: 1/10 chance
							-- Attack 1, 2, 3: equal chances
							local roll = math.random(1, 10)
							print("[NPC ATTACK] Roll:", roll)
							
							if roll == 1 then
								-- ULT (1/10 chance)
								print("[NPC ATTACK] Playing ULT!")
								ultTrack:Play()
							else
								-- Pick between Attack 1, 2, 3 (equal chances)
								local attackRoll = math.random(1, 3)
								print("[NPC ATTACK] AttackRoll:", attackRoll)
								
								if attackRoll == 1 then
									-- Attack 1
									print("[NPC ATTACK] Playing Attack1!")
									attack1Track:Play()
								elseif attackRoll == 2 then
									-- Attack 2 (LowMagic - pause at 98% and spawn beam)
									attack2Track:Play()
									task.spawn(function()
										-- Wait until animation reaches 98%
										local animLength = attack2Track.Length
										local pauseTime = animLength * 0.98
										while attack2Track.IsPlaying and attack2Track.TimePosition < pauseTime do
											task.wait()
										end
										
										-- Pause the animation at 98%
										attack2Track:AdjustSpeed(0)
										
										-- FREEZE NPC while shooting
										isShooting = true
										
-- Spawn Beam effect at Effect attachment
												local effectAttachment = npc:FindFirstChild("Effect", true)
												print("[END DEBUG] Looking for Effect attachment, found:", effectAttachment and effectAttachment:GetFullName() or "NONE")
												
												if effectAttachment then
													-- Fire Beam effect on ALL clients (instant, no replication delay)
													spawnEffectEvent:FireAllClients("Beam", npc, "Effect", hrp.Position, 3)
													print("[END DEBUG] Fired Beam effect to all clients")
												else
													print("[END DEBUG] FAILED - no Effect attachment found")
												end
												
												-- Hold pause for 3 seconds
												task.wait(3)
										isShooting = false
										
										-- Resume and finish animation
										attack2Track:AdjustSpeed(1)
									end)
								else
									-- Attack 3 (MagicCircle - pause at 98% and spawn beam)
									attack3Track:Play()
									task.spawn(function()
										-- Wait until animation reaches 98%
										local animLength = attack3Track.Length
										local pauseTime = animLength * 0.98
										while attack3Track.IsPlaying and attack3Track.TimePosition < pauseTime do
											task.wait()
										end
										
										-- Pause the animation at 98%
										attack3Track:AdjustSpeed(0)
										
										-- FREEZE NPC while shooting
										isShooting = true
										
-- Spawn Beam effect at Effect attachment
												local effectAttachment = npc:FindFirstChild("Effect", true)
												print("[END DEBUG] Attack3 - Looking for Effect attachment, found:", effectAttachment and effectAttachment:GetFullName() or "NONE")
												
												if effectAttachment then
													-- Fire Beam effect on ALL clients (instant, no replication delay)
													spawnEffectEvent:FireAllClients("Beam", npc, "Effect", hrp.Position, 3)
													print("[END DEBUG] Attack3 - Fired Beam effect to all clients")
												else
													print("[END DEBUG] Attack3 - FAILED - no Effect attachment found")
												end
												
												-- Hold pause for 3 seconds
												task.wait(3)
										isShooting = false
										
										-- Resume and finish animation
										attack3Track:AdjustSpeed(1)
									end)
								end
							end
							
							local plHum = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
							if plHum and plHum.Health > 0 then
								plHum:TakeDamage(DAMAGE)
							end
						end
					end
				end
			else
				-- NO PLAYER - idle or wander
				-- Stop all attack animations
				attack1Track:Stop()
				attack2Track:Stop()
				attack3Track:Stop()
				ultTrack:Stop()
				
				if state == "chase" or state == "attack" then
					-- Just lost target, go back to idle
					state = "idle"
					walkTrack:Stop()
					idleTrack:Play()
					wanderCooldown = tick() + math.random(IDLE_TIME[1], IDLE_TIME[2])
				end
				
				if state == "idle" then
					if tick() >= wanderCooldown then
						-- Start wandering
						state = "wander"
						idleTrack:Stop()
						walkTrack:Play()
						
						local angle = math.random() * math.pi * 2
						local radius = math.random(10, WALK_RADIUS)
						wanderTarget = spawnPos + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
						
						-- Raycast to terrain
						local origin = wanderTarget + Vector3.new(0, 50, 0)
						local ray = Workspace:Raycast(origin, Vector3.new(0, -500, 0))
						if ray then
							wanderTarget = ray.Position + Vector3.new(0, 3, 0)
						end
						
						humanoid:MoveTo(wanderTarget)
					end
				elseif state == "wander" then
					-- Check if reached destination
					if wanderTarget then
						local distToTarget = (npcPos - wanderTarget).Magnitude
						if distToTarget < 5 then
							-- Reached destination, go idle
							state = "idle"
							walkTrack:Stop()
							idleTrack:Play()
							wanderCooldown = tick() + math.random(IDLE_TIME[1], IDLE_TIME[2])
						else
							-- Keep moving
							humanoid:MoveTo(wanderTarget)
						end
					end
				end
			end
			
			task.wait(0.1) -- 10 checks per second
		end
	end)
end