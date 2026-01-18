print("=== NPC SPAWNER & AI STARTED ===")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")

-- NPC Config
local NPC_FOLDER_NAME = "Npc"
local MODEL_NAME = "Spidy"
local NPC_COUNT = 2
local WALK_SPEED = 16
local ATTACK_DISTANCE = 50
local DAMAGE = 10
local IDLE_TIME = {1, 2}
local WALK_TIME = {3, 6}
local WALK_RADIUS = 300

-- Animation IDs
local ANIM_WALK = 102168601455331
local ANIM_IDLE = 138142046650605
local ANIM_ATTACK = 130278364981698

local NPCS = {}

-- FishSpawn model
local spawnModel = Workspace:FindFirstChild("SpidySpawn")
if not spawnModel then error("SpidySpawn model missing") end

-- Get all parts inside spawn model
local spawnParts = {}
for _, part in ipairs(spawnModel:GetDescendants()) do
	if part:IsA("BasePart") then
		table.insert(spawnParts, part)
	end
end
if #spawnParts == 0 then error("No parts found in FishSpawn model") end

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
if not folder then error("Npc folder missing") end
local template = folder:FindFirstChild(MODEL_NAME)
if not template then error(MODEL_NAME.." missing") end

for i = 1, NPC_COUNT do
	local spawnPart = spawnParts[math.random(1, #spawnParts)]
	local pos = getSpawnPosition(spawnPart)

	local npc = template:Clone()
	npc.Parent = Workspace
	
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

		local attackAnim = Instance.new("Animation")
		attackAnim.AnimationId = "rbxassetid://"..ANIM_ATTACK
		local attackTrack = animator:LoadAnimation(attackAnim)

		-- State tracking
		local state = "idle" -- "idle", "wander", "chase", "attack"
		local wanderTarget = nil
		local lastAttackTime = 0
		local wanderCooldown = 0

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
			
			local targetPlayer, dist = getNearestPlayer(npcPos, ATTACK_DISTANCE)
			
			-- PRIORITY 1: Player in range - ALWAYS chase/attack
			if targetPlayer and targetPlayer.Character then
				print("[NPC "..npc.Name.."] DETECTED: "..targetPlayer.Name.." at dist "..math.floor(dist))
				local hrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
				if hrp then
					local realDist = (npcPos - hrp.Position).Magnitude
					
					if realDist <= 5 then
						-- ATTACK
						if state ~= "attack" then
							state = "attack"
							idleTrack:Stop()
							walkTrack:Stop()
						end
						
						-- Face target
						humanoid:MoveTo(hrp.Position)
						
						-- Attack with cooldown
						if tick() - lastAttackTime >= 1 then
							attackTrack:Play()
							local plHum = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
							if plHum and plHum.Health > 0 then
								plHum:TakeDamage(DAMAGE)
							end
							lastAttackTime = tick()
						end
					else
						-- CHASE
						if state ~= "chase" then
							state = "chase"
							idleTrack:Stop()
							attackTrack:Stop()
							walkTrack:Play()
						end
						
						humanoid:MoveTo(hrp.Position)
					end
				end
			else
				-- NO PLAYER - idle or wander
				attackTrack:Stop()
				
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
