print("==================== SHOOTINGSERVER SCRIPT IS RUNNING ====================")
warn("==================== SHOOTINGSERVER SCRIPT IS RUNNING ====================")

local Players = game:GetService("Players")
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
local SkinConfig    = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SkinConfig"))

-- RemoteEvent so clients (not server) do the Emit() — server Emit() doesn't replicate
local BulletEffectEvent = ReplicatedStorage:FindFirstChild("BulletEffectEvent")
if not BulletEffectEvent then
	BulletEffectEvent = Instance.new("RemoteEvent")
	BulletEffectEvent.Name = "BulletEffectEvent"
	BulletEffectEvent.Parent = ReplicatedStorage
end

-- Resolve which bullet template to use for a given skin.
--
-- Priority order (most specific → most generic):
--   Mythic    → exact skin name           e.g. "Dragon Sniper"
--   Legendary → exact skin name           e.g. "Golden AK"
--   Epic      → weapon type               e.g. "Epic_Sniper", "Epic_Pistol"
--   Rare      → "Rare"  (shared template)
--   Common    → "Common" (shared template)
--
-- Falls back one step at a time until something is found in BulletsFolder.
-- Explicit per-skin overrides (maps skinId → exact model name in Bullets folder)
local SKIN_BULLET_OVERRIDE = {
	["Power"]       = "RedMatter",
	["Necromancer"] = "Darkness",
}

local function resolveBulletTemplate(skinId)
	if not BulletsFolder or not skinId then return nil end

	-- Check explicit overrides first
	local override = SKIN_BULLET_OVERRIDE[skinId]
	if override then
		local t = BulletsFolder:FindFirstChild(override)
		if t then return t, override end
	end

	local meta    = SkinConfig.GetSkinMeta(skinId)
	local rarity  = meta and meta.rarity  or "common"
	local weapon  = meta and meta.weapon  or "Unknown"

	local candidates = {}

	if rarity == "mythic" or rarity == "legendary" then
		table.insert(candidates, "RedMatter")
	elseif rarity == "epic" then
		table.insert(candidates, "Darkness")
	elseif rarity == "rare" then
		table.insert(candidates, "Rare")
	else
		table.insert(candidates, "Common")
	end

	for _, name in ipairs(candidates) do
		local t = BulletsFolder:FindFirstChild(name)
		if t then return t, name end
	end

	-- Last-resort: fall back down the rarity chain
	local fallbacks = { "Rare", "Common" }
	for _, name in ipairs(fallbacks) do
		local t = BulletsFolder:FindFirstChild(name)
		if t then return t, name end
	end

	return nil, nil
end

local function spawnBulletVisual(skinId, startPos, endPos)
	if not skinId then return end
	-- Tell every client to play the effect locally — ParticleEmitter:Emit() doesn't replicate from server
	BulletEffectEvent:FireAllClients(skinId, startPos, endPos)
end

-- Bullseye tracking uses bullseyeCurrent / bullseyeHigh fields in player data (set up in PlayerDataManager)
local function updateBullseye(player, ringNumber)
	if not _G.getData then return end
	local ok, d = pcall(_G.getData, player)
	if not ok or not d then return end
	local points = 7 - ringNumber -- ring1=6 .. ring6=1
	d.bullseyeCurrent = (d.bullseyeCurrent or 0) + points
	if d.bullseyeCurrent > (d.bullseyeHigh or 0) then
		d.bullseyeHigh = d.bullseyeCurrent
	end
end

local function _endBullseyeRound(player)
	if not _G.getData then return end
	local ok, d = pcall(_G.getData, player)
	if ok and d then d.bullseyeCurrent = 0 end
end

-- Add global bullseye hit function if not already defined
if not _G.onBullseyeHit then
	_G.onBullseyeHit = function(player, ringNumber)
		updateBullseye(player, ringNumber)
		if _G.checkRankUp then pcall(_G.checkRankUp, player) end
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
		_G.addMoney(player, 1)
		print("[ShootingServer] Added 1 money") -- DEBUG
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
		_G.notify(player, "Bull Hit! +1")
	end
end

-- Add onShot function if not already defined
if not _G.onShot then
	_G.onShot = function(player)
		if not _G.getData then return end
		local ok, d = pcall(_G.getData, player)
		if ok and d then
			d.sessionShots = (d.sessionShots or 0) + 1
		end
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

	-- ⚔️ PvP DUEL HITSCAN — instant click-based, no bullet travel needed
	if _G.PvpDuel and _G.PvpDuel.isInDuel(player) then
		local opponent = _G.PvpDuel.getOpponent(player)
		if opponent then
			local opChar = opponent.Character
			if opChar then
				-- Raycast directly from shooter toward mouse position, only hitting opponent
				local pvpParams = RaycastParams.new()
				local pvpFilter = { character }
				-- Exclude everything EXCEPT the opponent character
				-- We use Include mode with just the opponent
				pvpParams.FilterDescendantsInstances = { opChar }
				pvpParams.FilterType = Enum.RaycastFilterType.Include

				local pvpResult = Workspace:Raycast(origin, direction, pvpParams)

				-- Direct hit only — no proximity fallback
				local pvpIsHeadshot = false
				if pvpResult then
					-- Check if the IMPACT POINT is above the neck
					local opHead = opChar:FindFirstChild("Head")
					if opHead and pvpResult.Position then
						local neckY = opHead.Position.Y - (opHead.Size.Y * 0.5)
						pvpIsHeadshot = pvpResult.Position.Y >= neckY
					end
				end

				if pvpResult and pvpResult.Instance then
					local hitPartName = pvpResult.Instance.Name
					local handled = _G.PvpDuel.dealPvpHit(player, opponent, pvpIsHeadshot)
					if handled then
						print("[ShootingServer] ⚔️ PvP Hitscan:", player.Name, "→", opponent.Name,
							pvpIsHeadshot and "HEADSHOT!" or "body hit", "(part:", hitPartName, ")")
						-- Still spawn the visual bullet for feedback
						if skinId then
							spawnBulletVisual(skinId, origin, origin + direction)
						end
						return
					end
				end
			end
		end
	end

	-- 🌀 ABYSS OPEN-WORLD PVP — shoot any player in the Abyss zone
	if _G.AbyssPvP and _G.AbyssPvP.isInAbyss(player) then
		local abyssTargets = _G.AbyssPvP.getAbyssPlayers(player)
		print("[ShootingServer] 🌀 Abyss PvP: shooter", player.Name, "is in Abyss, targets:", #abyssTargets)
		if #abyssTargets > 0 then
			-- Build include filter with all other Abyss player characters
			local abyssChars = {}
			for _, target in abyssTargets do
				if target.Character then
					table.insert(abyssChars, target.Character)
				end
			end

			if #abyssChars > 0 then
				local abyssParams = RaycastParams.new()
				abyssParams.FilterDescendantsInstances = abyssChars
				abyssParams.FilterType = Enum.RaycastFilterType.Include

				-- Use Spherecast for easier hits (same as PvE)
				local abyssRadius = 1.0
				local abyssResult = Workspace:Spherecast(origin, abyssRadius, direction, abyssParams)
				
				-- Fallback to thin ray if spherecast missed
				if not abyssResult then
					abyssResult = Workspace:Raycast(origin, direction, abyssParams)
				end

				if abyssResult and abyssResult.Instance then
					-- Find which player was hit
					local hitChar = abyssResult.Instance:FindFirstAncestorOfClass("Model")
					local hitPlayer = hitChar and Players:GetPlayerFromCharacter(hitChar)

					if hitPlayer and _G.AbyssPvP.isInAbyss(hitPlayer) then
						-- Check headshot (Y-position above neck)
						local abyssHeadshot = false
						local hitHead = hitChar:FindFirstChild("Head")
						if hitHead and abyssResult.Position then
							local neckY = hitHead.Position.Y - (hitHead.Size.Y * 0.5)
							abyssHeadshot = abyssResult.Position.Y >= neckY
						end

						local handled = _G.AbyssPvP.dealDamage(player, hitPlayer, abyssHeadshot)
						if handled then
							print("[ShootingServer] 🌀 Abyss PvP:", player.Name, "→", hitPlayer.Name,
								abyssHeadshot and "HEADSHOT!" or "body hit",
								"(part:", abyssResult.Instance.Name, ")")
							if skinId then
								spawnBulletVisual(skinId, origin, origin + direction)
							end
							return
						else
							warn("[ShootingServer] 🌀 Abyss PvP: dealDamage returned false for", player.Name, "→", hitPlayer.Name)
						end
					else
						warn("[ShootingServer] 🌀 Abyss PvP: hit instance but no valid player. Instance:", abyssResult.Instance:GetFullName(),
							"hitPlayer:", hitPlayer and hitPlayer.Name or "nil",
							"inAbyss:", hitPlayer and tostring(_G.AbyssPvP.isInAbyss(hitPlayer)) or "N/A")
					end
				else
					print("[ShootingServer] 🌀 Abyss PvP: raycast missed all", #abyssChars, "target characters")
				end
			end
		end
	else
		-- Debug: why is player not in abyss?
		if not _G.AbyssPvP then
			if not player:GetAttribute("_abyssWarnLogged") then
				warn("[ShootingServer] _G.AbyssPvP is nil! AbyssPvP script may not have loaded yet.")
				player:SetAttribute("_abyssWarnLogged", true)
			end
		end
	end

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
		local gameFolder = workspace:FindFirstChild("Game")
		local bullArenaFolder = gameFolder and gameFolder:FindFirstChild("BullArena")
		local arena = workspace:FindFirstChild("BullArena_1") or bullArenaFolder
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

		if _G.onMiss then pcall(_G.onMiss, player) end
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

	-- 🟢 NPC Hit (PVE System)
	if _G.PVESystem and _G.PVESystem.findNPCFromHit then
		local npcModel = _G.PVESystem.findNPCFromHit(hitPart)
		if npcModel then
			print("[ShootingServer] NPC Hit:", npcModel.Name, "by", player.Name)

			local damage = _G.PVESystem.getWeaponDamage(player)
			-- Headshot detection: part name OR Y-position above the NPC's neck
			local partName = hitPart.Name:lower()
			local isHeadshot = partName:find("head") ~= nil
			if not isHeadshot then
				-- Fallback: check if hit position is at or above the NPC's neck line
				local npcHead = npcModel:FindFirstChild("Head")
				if npcHead and result.Position then
					local neckY = npcHead.Position.Y - (npcHead.Size.Y * 0.5)
					isHeadshot = result.Position.Y >= neckY
				end
			end
			if isHeadshot then
				local mult = 1.5 + math.random() * 0.5 -- between 1.5 and 2.0
				damage = math.floor(damage * mult)
				print(("[ShootingServer] 💥 NPC HEADSHOT! mult=%.2f final_dmg=%d"):format(mult, damage))
			end

			_G.PVESystem.damageNPC(npcModel, damage, player)
			if _G.recordTargetHit then pcall(_G.recordTargetHit, player) end
			if _G.onHit then pcall(_G.onHit, player) end
			if _G.checkRankUp then pcall(_G.checkRankUp, player) end
		else
			if _G.onMiss then pcall(_G.onMiss, player) end
		end
	end
end)


return true
