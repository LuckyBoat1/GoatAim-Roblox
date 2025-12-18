print("==================== SHOOTINGSERVER SCRIPT IS RUNNING ====================")
warn("==================== SHOOTINGSERVER SCRIPT IS RUNNING ====================")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

print("[ShootingServer] Script loading...")
local shootEvent = ReplicatedStorage:FindFirstChild("ShootEvent")
if not shootEvent then
	warn("[ShootingServer] ShootEvent not found, creating it...")
	shootEvent = Instance.new("RemoteEvent")
	shootEvent.Name = "ShootEvent"
	shootEvent.Parent = ReplicatedStorage
end
print("[ShootingServer] ShootEvent found, setting up...")

local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not RemoteEvents then
	RemoteEvents = Instance.new("Folder")
	RemoteEvents.Name = "RemoteEvents"
	RemoteEvents.Parent = ReplicatedStorage
end

local BullScoreUpdate = RemoteEvents:FindFirstChild("BullScoreUpdate")
if not BullScoreUpdate then
	BullScoreUpdate = Instance.new("RemoteEvent")
	BullScoreUpdate.Name = "BullScoreUpdate"
	BullScoreUpdate.Parent = RemoteEvents
end

-- Bullet system
local BulletsFolder = ReplicatedStorage:FindFirstChild("Bullets")
local WEAPON_BULLETS = {
	["necromancer"] = "Darkness",
	["power"] = "RedMatter",
}

local function spawnBulletVisual(skinId, startPos, endPos)
	print("[ShootingServer] spawnBulletVisual called - skinId:", skinId)
	
	if not BulletsFolder then 
		warn("[ShootingServer] BulletsFolder not found!")
		return 
	end
	
	if not skinId then 
		warn("[ShootingServer] No skinId provided!")
		return 
	end
	
	print("[ShootingServer] Looking up bullet for skinId:", skinId, "->", string.lower(skinId))
	local bulletName = WEAPON_BULLETS[string.lower(skinId)]
	
	-- Fallback for Power if not found (case sensitivity check)
	if not bulletName and string.lower(skinId) == "power" then
		bulletName = "RedMatter"
	end
	
	if not bulletName then 
		warn("[ShootingServer] No bullet mapped for skin:", skinId)
		return 
	end
	
	print("[ShootingServer] Searching for bullet:", bulletName)
	local bulletTemplate = BulletsFolder:FindFirstChild(bulletName)
	if not bulletTemplate then 
		warn("[ShootingServer] Bullet not found in BulletsFolder:", bulletName)
		return 
	end
	
	local bullet = bulletTemplate:Clone()
	
	-- Scale the bullet by 4x (applies to geometry and particles)
	if bullet:IsA("Model") then
		bullet:ScaleTo(bullet:GetScale() * 4)
	end
	
	-- Find or set PrimaryPart if not already set
	if not bullet.PrimaryPart then
		-- Try to find a part named "Main" or just use the first BasePart
		local mainPart = bullet:FindFirstChild("Main") or bullet:FindFirstChildWhichIsA("BasePart", true)
		if mainPart then
			bullet.PrimaryPart = mainPart
			print("[ShootingServer] Auto-set PrimaryPart to:", mainPart.Name)
		else
			warn("[ShootingServer] No BasePart found in bullet model!")
			bullet:Destroy()
			return
		end
	end
	
	bullet:SetPrimaryPartCFrame(CFrame.lookAt(startPos, endPos))
	
	local projectilesFolder = workspace:FindFirstChild("Projectiles")
	if not projectilesFolder then
		projectilesFolder = Instance.new("Folder")
		projectilesFolder.Name = "Projectiles"
		projectilesFolder.Parent = workspace
	end
	bullet.Parent = projectilesFolder
	
	-- Set all parts to non-collidable and anchored
	for _, part in ipairs(bullet:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.Anchored = true
		end
	end
	
	-- Enable all particle emitters
	for _, child in ipairs(bullet:GetDescendants()) do
		if child:IsA("ParticleEmitter") then
			child.Rate = child.Rate * 5 -- Multiply rate by 5X
			child:Emit(2)
			child.Enabled = true
			print("[ShootingServer] Enabled particle:", child.Name)
		end
	end
	
	-- Ensure the bullet is visible
	-- bullet.Parent = workspace -- REMOVED: Kept in Projectiles folder
	-- print("[ShootingServer] Bullet parented to workspace")
	
	-- Use CFrame-based movement instead of physics
	local primaryPart = bullet.PrimaryPart
	if primaryPart then
		local direction = (endPos - startPos).Unit
		local speed = 1000 -- studs/second (Increased to 1000)
		local distance = (endPos - startPos).Magnitude
		local travelTime = math.min(distance / speed, 5) -- Cap at 5 seconds flight time
		
		print("[ShootingServer] Bullet will travel for", travelTime, "seconds at speed", speed)
		
		-- Move bullet with CFrame animation
		task.spawn(function()
			local startTime = tick()
			while tick() - startTime < travelTime do
				if not bullet.Parent then break end
				
				local elapsed = tick() - startTime
				local progress = elapsed / travelTime
				local currentPos = startPos + (direction * speed * elapsed)
				
				bullet:SetPrimaryPartCFrame(CFrame.new(currentPos) * CFrame.Angles(0, 0, 0))
				task.wait()
			end
			
			if bullet.Parent then
				print("[ShootingServer] Destroying bullet after", travelTime, "seconds")
				bullet:Destroy()
			end
		end)
	else
		warn("[ShootingServer] Bullet has no PrimaryPart!")
		bullet:Destroy()
	end
	
	print("[ShootingServer] Spawned", bulletName, "bullet for", skinId, "at position", startPos)
	return bullet
end

-- Bullseye tracking uses bullseyeCurrent / bullseyeHigh fields in player data (set up in PlayerDataManager)
local function updateBullseye(player, ringNumber)
	local d = _G.getData(player)
	if not d then return end
	local points = 7 - ringNumber -- ring1=6 .. ring6=1
	d.bullseyeCurrent = (d.bullseyeCurrent or 0) + points
	if d.bullseyeCurrent > (d.bullseyeHigh or 0) then
		d.bullseyeHigh = d.bullseyeCurrent
	end
end

local function _endBullseyeRound(player)
	local d = _G.getData(player)
	if d then d.bullseyeCurrent = 0 end
end

-- Add global bullseye hit function if not already defined
if not _G.onBullseyeHit then
	_G.onBullseyeHit = function(player, ringNumber)
		updateBullseye(player, ringNumber)
		_G.checkRankUp(player)
	end
end

-- Add global bullseye miss function if not already defined
if not _G.onBullseyeMiss then
	_G.onBullseyeMiss = function(player) end
end

-- Global bull hit function (Always define to ensure updates)
_G.onBullHit = function(player)
	print("[ShootingServer] _G.onBullHit called for", player.Name) -- DEBUG
	
	-- Add Money
	if _G.addMoney then
		_G.addMoney(player, 100)
		print("[ShootingServer] Added 100 money") -- DEBUG
	else
		warn("[ShootingServer] _G.addMoney is NIL!")
	end
	
	-- Add Score
	if _G.getData then
		local d = _G.getData(player)
		if d then
			d.bullseyeScore = (d.bullseyeScore or 0) + 1
			print("[ShootingServer] Score updated to:", d.bullseyeScore) -- DEBUG
			
			if BullScoreUpdate then
				BullScoreUpdate:FireClient(player, d.bullseyeScore)
			end
		end
	else
		warn("[ShootingServer] _G.getData is NIL!")
	end

	-- Notify
	if _G.notify then
		_G.notify(player, "Bull Hit! +100")
	end
end

-- Add onShot function if not already defined
if not _G.onShot then
	_G.onShot = function(player)
		local d = _G.getData(player)
		d.sessionShots = (d.sessionShots or 0) + 1
	end
end

-- Add onMiss function if not already defined
if not _G.onMiss then
	_G.onMiss = function(player)
		-- Optional: Add miss tracking logic here
	end
end

shootEvent.OnServerEvent:Connect(function(player, mouseHitPosition)
	-- Track the shot in player data first (regardless of hit/miss)
	pcall(function()
		if _G.onShot then
			_G.onShot(player)
		end
	end)

	if not player or not mouseHitPosition then return end

	local character = player.Character
	if not character then return end

	local head = character:FindFirstChild("Head")
	if not head then return end

	-- Get player's equipped weapon/skin
	local tool = character:FindFirstChildOfClass("Tool")
	local skinId = tool and tool:GetAttribute("SkinId")
	
	print("[ShootingServer] DEBUG: Player", player.Name, "fired.")
	print("[ShootingServer] DEBUG: Tool:", tool and tool.Name or "NIL")
	print("[ShootingServer] DEBUG: SkinId:", skinId or "NIL")

	local origin = head.Position
	local directionVector = mouseHitPosition - origin
	local distance = directionVector.Magnitude
	-- Extend the ray slightly past the target to prevent floating point misses
	local direction = directionVector.Unit * (math.max(distance, 100) + 2)

	-- Spawn custom bullet visual if weapon has one
	local visualBullet
	if skinId then
		visualBullet = spawnBulletVisual(skinId, origin, origin + direction)
	end

	local rayParams = RaycastParams.new()
	local filterList = { character }
	
	-- Exclude all projectiles
	local projectilesFolder = workspace:FindFirstChild("Projectiles")
	if projectilesFolder then
		table.insert(filterList, projectilesFolder)
	end
	
	rayParams.FilterDescendantsInstances = filterList
	-- Blacklist is deprecated; use Exclude to ignore the character
	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	-- Use Spherecast for thicker bullet (easier to hit)
	local radius = 1.0 
	local result = Workspace:Spherecast(origin, radius, direction, rayParams)

	-- Fallback: If Spherecast missed, check if the player clicked ON or NEAR a Bullseye
	-- This compensates for lag or fast-moving targets where the ray might miss
	if not result then
		local overlapParams = OverlapParams.new()
		overlapParams.FilterDescendantsInstances = filterList
		overlapParams.FilterType = Enum.RaycastFilterType.Exclude
		
		-- Check a small radius around the clicked point
		local hitPoint = origin + directionVector
		local parts = Workspace:GetPartBoundsInRadius(hitPoint, 4.0, overlapParams)
		
		for _, part in ipairs(parts) do
			if part:FindFirstAncestor("Bullseye") then
				-- Create a fake RaycastResult
				result = {
					Instance = part,
					Position = part.Position,
					Normal = Vector3.new(0, 1, 0),
					Material = Enum.Material.Plastic
				}
				print("[ShootingServer] Hit via Proximity Fallback! Part:", part.Name)
				break
			end
		end
	end

	if not result or not result.Instance then
		print("[ShootingServer] Raycast Missed! Distance:", distance)
		
		-- DEBUG: Analyze why we missed the bull
		local arena = workspace:FindFirstChild("BullArena_1") or workspace:FindFirstChild("BullArena")
		if arena then
			local bull = arena:FindFirstChild("bull")
			if bull then
				print("[ShootingServer] DEBUG: Bull found in", arena.Name)
				local head = bull:FindFirstChild("Head") or bull.PrimaryPart or bull:FindFirstChildWhichIsA("BasePart")
				if head then
					local distToBull = (head.Position - origin).Magnitude
					print("[ShootingServer] DEBUG: Distance to Bull:", distToBull)
					
					-- Check if ray passed close to bull
					local closestPoint = origin + directionVector.Unit * math.min(distToBull, distance)
					local missMargin = (closestPoint - head.Position).Magnitude
					print("[ShootingServer] DEBUG: Ray passed within", missMargin, "studs of Bull center")
					
					-- Check properties
					for _, part in ipairs(bull:GetDescendants()) do
						if part:IsA("BasePart") then
							print(string.format("[ShootingServer] DEBUG: Part %s | CanQuery: %s | CanCollide: %s | Group: %s | Trans: %.2f",
								part.Name, tostring(part.CanQuery), tostring(part.CanCollide), part.CollisionGroup, part.Transparency))
						end
					end
				end
			else
				print("[ShootingServer] DEBUG: Bull NOT found in arena")
			end
		end

		_G.onMiss(player)
		return
	end

	local hitPart = result.Instance
	print("[ShootingServer] Hit:", hitPart:GetFullName()) -- DEBUG

	local bullseyeModel = hitPart:FindFirstAncestor("Bullseye")

	-- 🟢 Bullseye Mode
	if bullseyeModel then
		print("[ShootingServer] Bullseye Model Found:", bullseyeModel.Name) -- DEBUG
		local playerId = bullseyeModel:GetAttribute("PlayerId")
		print("[ShootingServer] Owner:", playerId, "Shooter:", player.UserId) -- DEBUG

		if playerId == player.UserId then
			local ringName = hitPart.Parent.Name
			print("[ShootingServer] Ring Parent Name:", ringName) -- DEBUG
			print("[ShootingServer] HitPart Name:", hitPart.Name) -- DEBUG

			local ringNumber = tonumber(string.match(ringName, "%d+")) or 6
			print("[ShootingServer] Calculated RingNumber:", ringNumber) -- DEBUG
			
			_G.onBullseyeHit(player, ringNumber)
		else
			print("[ShootingServer] Bullseye owner mismatch") -- DEBUG
			_G.onBullseyeMiss(player)
		end
		return
	end

	-- 🟢 Bull Hit
	local bullModel = hitPart:FindFirstAncestor("bull") or hitPart:FindFirstAncestor("Bull")
	
	-- Fallback: If hitPart is the Shape inside the inner model, find the main "bull" model
	if not bullModel and hitPart.Name:match("Bull") and hitPart.Name:match("Shape") then
		local p = hitPart.Parent
		while p and p ~= workspace do
			if p.Name == "bull" or p.Name == "Bull" then
				bullModel = p
				break
			end
			p = p.Parent
		end
	end

	if bullModel then
		print("[ShootingServer] Bull Hit by", player.Name)
		
		-- Apply Damage via Attributes (No Humanoid)
		local currentHealth = bullModel:GetAttribute("Health")
		if currentHealth then
			local newHealth = math.max(0, currentHealth - 1)
			bullModel:SetAttribute("Health", newHealth)
			-- print("[ShootingServer] Bull Health:", newHealth)
		else
			-- Fallback for legacy Humanoid support (just in case)
			local humanoid = bullModel:FindFirstChild("Humanoid")
			if humanoid then
				humanoid:TakeDamage(10)
			else
				warn("[ShootingServer] Bull hit but no Health attribute or Humanoid found!")
			end
		end

		_G.onBullHit(player)
		return
	end

	-- 🟢 Normal Mode
	if hitPart:GetAttribute("PlayerId") == player.UserId then
		hitPart:Destroy()
		_G.recordTargetHit(player)
		if _G.onHit then _G.onHit(player) end
		_G.checkRankUp(player)
	else
		if _G.onMiss then _G.onMiss(player) end
	end
end)


return true
