--[[
	AbyssPvP.server.lua
	
	Open-world PvP inside the Abyss zone.
	
	Players enter the Abyss via the SideMenu teleport button, which fires
	an AbyssTeleport RemoteEvent to register them on the server immediately.
	Exit is detected by distance from the Abyss center or character respawn.
	
	Damage: weapon rarity × headshot 1.5x multiplier.
	On kill: victim loses ALL skins and crates to the killer.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

--------------------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------------------
local ZONE_CHECK_INTERVAL = 1.0
local KILL_GOLD_REWARD    = 500
local HEADSHOT_MULTIPLIER = 1.5
local KILL_COOLDOWN       = 0.5
local ABYSS_EXIT_RADIUS   = 500 -- studs from abyss center → player "left"

--------------------------------------------------------------------------
-- REMOTE EVENTS
--------------------------------------------------------------------------
local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not RemoteEvents then
	RemoteEvents = Instance.new("Folder")
	RemoteEvents.Name = "RemoteEvents"
	RemoteEvents.Parent = ReplicatedStorage
end

local AbyssPvPEvent = RemoteEvents:WaitForChild("AbyssPvPEvent", 10)
if not AbyssPvPEvent then
	warn("[AbyssPvP] ❌ AbyssPvPEvent not found, creating fallback")
	AbyssPvPEvent = Instance.new("RemoteEvent")
	AbyssPvPEvent.Name = "AbyssPvPEvent"
	AbyssPvPEvent.Parent = RemoteEvents
end
warn("[AbyssPvP] ✅ AbyssPvPEvent ready:", AbyssPvPEvent:GetFullName())

local AbyssTeleportRE = RemoteEvents:WaitForChild("AbyssTeleport", 10)
if not AbyssTeleportRE then
	warn("[AbyssPvP] ❌ AbyssTeleport not found, creating fallback")
	AbyssTeleportRE = Instance.new("RemoteEvent")
	AbyssTeleportRE.Name = "AbyssTeleport"
	AbyssTeleportRE.Parent = RemoteEvents
end
warn("[AbyssPvP] ✅ AbyssTeleportRE ready:", AbyssTeleportRE:GetFullName())

--------------------------------------------------------------------------
-- ABYSS ZONE DETECTION (all hitbox parts)
--------------------------------------------------------------------------
local abyssCenter: Vector3? = nil
local abyssHitBoxParts: {BasePart} = {}

-- Buffer added to each part's bounds to cover gaps between the 4 parts.
local ABYSS_OBB_BUFFER = 12 -- studs of padding on X and Z edges
-- How many consecutive seconds outside ALL parts before exiting.
local ABYSS_EXIT_DELAY = 2.5

-- Returns true if `position` is inside ANY of the AbyssHitBox parts (with buffer).
-- Falls back to center+radius if no parts are found.
local function isInsideAbyss(position: Vector3): boolean
	if #abyssHitBoxParts > 0 then
		for _, part in ipairs(abyssHitBoxParts) do
			local localPos = part.CFrame:PointToObjectSpace(position)
			local half = part.Size / 2
			if math.abs(localPos.X) <= half.X + ABYSS_OBB_BUFFER
				and math.abs(localPos.Z) <= half.Z + ABYSS_OBB_BUFFER
				and localPos.Y >= -half.Y - 20
				and localPos.Y <= half.Y + 40 then
				return true
			end
		end
		return false
	end
	-- Fallback: center + radius
	if abyssCenter then
		return (position - abyssCenter).Magnitude <= ABYSS_EXIT_RADIUS
	end
	return true -- can't determine, assume still inside
end

-- Track when each player first went outside (nil = currently inside)
local playerOutsideSince: {[Player]: number} = {}

local function findAbyssCenter()
	-- Collect ALL BaseParts from the AbyssHitBox model
	abyssHitBoxParts = {}
	local hitbox = Workspace:FindFirstChild("AbyssHitBox", true)
	if hitbox then
		if hitbox:IsA("BasePart") then
			table.insert(abyssHitBoxParts, hitbox)
		else
			for _, child in ipairs(hitbox:GetDescendants()) do
				if child:IsA("BasePart") then
					table.insert(abyssHitBoxParts, child)
				end
			end
		end
		if #abyssHitBoxParts > 0 then
			-- Compute centroid for logging / fallback
			local sum = Vector3.zero
			for _, p in ipairs(abyssHitBoxParts) do sum = sum + p.Position end
			abyssCenter = sum / #abyssHitBoxParts
			print(("[AbyssPvP] Abyss zone: %d parts, centroid %s"):format(#abyssHitBoxParts, tostring(abyssCenter)))
			return
		end
	end
	-- Try AbyssSpawn attachment as fallback
	local attach = Workspace:FindFirstChild("AbyssSpawn", true)
	if attach and attach:IsA("Attachment") then
		abyssCenter = attach.WorldPosition
		print(("[AbyssPvP] Abyss center from AbyssSpawn: %s"):format(tostring(abyssCenter)))
		return
	end
	warn("[AbyssPvP] Could not find abyss center – will set on first teleport")
end

task.spawn(function()
	task.wait(3)
	findAbyssCenter()
	if not abyssCenter then
		task.wait(7)
		findAbyssCenter()
	end
end)

--------------------------------------------------------------------------
-- PLAYER TRACKING
--------------------------------------------------------------------------
local playersInAbyss: { [Player]: boolean } = {}
local playerEntryPos: { [Player]: Vector3 } = {}
local playerEntryTime: { [Player]: number } = {} -- tick() when they entered (grace period)
local lastKillTime: { [Player]: number } = {}
local ENTRY_GRACE_PERIOD = 5.0 -- seconds before distance-check can kick a player

-- Forward declaration so enterAbyss can reference exitAbyss in its Died callback.
local exitAbyss: (Player) -> ()

--------------------------------------------------------------------------
-- ENTER / EXIT
--------------------------------------------------------------------------
local function enterAbyss(plr: Player)
	if playersInAbyss[plr] then return end
	playersInAbyss[plr] = true
	playerEntryTime[plr] = tick() -- grace period starts now

	local char = plr.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root then
		playerEntryPos[plr] = root.Position
		if not abyssCenter then
			abyssCenter = root.Position
		end
	end

	-- Ensure all character parts are raycast-queryable so Abyss PvP hitscan works
	if char then
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanQuery = true
			end
		end
	end

	-- Hook the current character's Humanoid.Died so that PvE deaths (NPC hitbox
	-- killing the player without going through handleAbyssKill) still clean up
	-- the abyss state immediately.  exitAbyss has a guard so double-calls are safe.
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.Died:Connect(function()
			task.wait(0.05) -- tiny delay so other Died handlers run first
			if playersInAbyss[plr] then
				warn(("[AbyssPvP] PvE death detected for %s — auto-exiting abyss"):format(plr.Name))
				exitAbyss(plr)
			end
		end)
	end

	if _G.HealthManager and _G.HealthManager.EnableHealthMode then
		_G.HealthManager.EnableHealthMode(plr, "Abyss")
	end
	AbyssPvPEvent:FireClient(plr, "EnteredAbyss")

	-- DEBUG: loud log with all current Abyss players
	local names = {}
	for p, _ in playersInAbyss do
		if p.Parent then table.insert(names, p.Name) end
	end
	warn(("🌀🌀🌀 [AbyssPvP] %s ENTERED THE ABYSS | All Abyss players (%d): %s"):format(
		plr.Name, #names, table.concat(names, ", ")))
end

exitAbyss = function(plr: Player)
	if not playersInAbyss[plr] then return end
	playersInAbyss[plr] = nil
	playerEntryPos[plr] = nil
	playerEntryTime[plr] = nil
	playerOutsideSince[plr] = nil

	if _G.HealthManager and _G.HealthManager.DisableHealthMode then
		_G.HealthManager.DisableHealthMode(plr)
	end
	if _G.resetHealth then _G.resetHealth(plr) end
	AbyssPvPEvent:FireClient(plr, "LeftAbyss")

	-- DEBUG: loud log with remaining Abyss players
	local names = {}
	for p, _ in playersInAbyss do
		if p.Parent then table.insert(names, p.Name) end
	end
	warn(("🌀🌀🌀 [AbyssPvP] %s LEFT THE ABYSS | Remaining Abyss players (%d): %s"):format(
		plr.Name, #names, #names > 0 and table.concat(names, ", ") or "NONE"))
end

--------------------------------------------------------------------------
-- SERVER ENTRY via RemoteEvent (fired by SideMenu after teleport)
--------------------------------------------------------------------------
AbyssTeleportRE.OnServerEvent:Connect(function(plr)
	warn(("🔥🔥🔥 [AbyssPvP] Received AbyssTeleport from %s"):format(plr.Name))
	enterAbyss(plr)
end)

--------------------------------------------------------------------------
-- ZONE EXIT DETECTION (periodic distance check)
--------------------------------------------------------------------------
task.spawn(function()
	while true do
		task.wait(ZONE_CHECK_INTERVAL)
		for plr, _ in playersInAbyss do
			if not plr.Parent then
				playersInAbyss[plr] = nil
				playerEntryPos[plr] = nil
				continue
			end
			local char = plr.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if not root then continue end

			-- Grace period: don't kick players who just entered (position may not have replicated)
			local entryTime = playerEntryTime[plr]
			if entryTime and (tick() - entryTime) < ENTRY_GRACE_PERIOD then
				playerOutsideSince[plr] = nil -- reset outside timer during grace
				continue
			end

			if isInsideAbyss(root.Position) then
				-- Back inside — cancel any pending exit
				playerOutsideSince[plr] = nil
			else
				-- Outside — start / check delay timer
				if not playerOutsideSince[plr] then
					playerOutsideSince[plr] = tick()
				elseif tick() - playerOutsideSince[plr] >= ABYSS_EXIT_DELAY then
					playerOutsideSince[plr] = nil
					exitAbyss(plr)
				end
			end
		end
	end
end)

--------------------------------------------------------------------------
-- CHARACTER RESPAWN = exit Abyss
--------------------------------------------------------------------------
local function hookCharacterRespawn(plr)
	plr.CharacterAdded:Connect(function()
		-- If player was in Abyss and died, exit them.
		-- But DON'T exit if they just entered (teleport can trigger CharacterAdded in some cases).
		task.wait(1.0)
		if playersInAbyss[plr] then
			local entryTime = playerEntryTime[plr]
			if entryTime and (tick() - entryTime) < ENTRY_GRACE_PERIOD then
				warn("[AbyssPvP] Skipping respawn-exit for " .. plr.Name .. " (within grace period)")
				return
			end
			exitAbyss(plr)
		end
	end)
end
for _, plr in Players:GetPlayers() do hookCharacterRespawn(plr) end
Players.PlayerAdded:Connect(hookCharacterRespawn)

--------------------------------------------------------------------------
-- PVP DAMAGE
--------------------------------------------------------------------------
local handleAbyssKill -- forward declaration

local function getPlayerWeaponDamage(plr: Player): number
	local char = plr.Character
	if not char then return 10 end

	local tool = char:FindFirstChildOfClass("Tool")
	local skinId = tool and tool:GetAttribute("SkinId")

	if skinId then
		if _G.PVESystem and _G.PVESystem.getWeaponDamage then
			return _G.PVESystem.getWeaponDamage(plr)
		end
		local shared = ReplicatedStorage:FindFirstChild("Shared")
		local skinConfigModule = shared and shared:FindFirstChild("SkinConfig")
		if skinConfigModule then
			local ok, SkinConfig = pcall(require, skinConfigModule)
			if ok and SkinConfig and SkinConfig.GetDamage then
				return SkinConfig.GetDamage(skinId)
			end
		end
	end

	return 10
end

local function dealAbyssPvPDamage(shooter: Player, victim: Player, isHeadshot: boolean): boolean
	if not playersInAbyss[shooter] or not playersInAbyss[victim] then return false end
	if shooter == victim then return false end

	local victimChar = victim.Character
	if not victimChar then return false end
	local victimHum = victimChar:FindFirstChildOfClass("Humanoid")
	if not victimHum then return false end

	-- Use tracked health (not Humanoid.Health) since damage goes through _G.damagePlayer
	local currentHP = _G.getHealth and _G.getHealth(victim) or victimHum.Health
	if currentHP <= 0 then return false end

	if _G.PvpDuel then
		if _G.PvpDuel.isInDuel(victim) or _G.PvpDuel.isInDuel(shooter) then return false end
	end

	local baseDamage = getPlayerWeaponDamage(shooter)
	local finalDamage = isHeadshot and math.floor(baseDamage * HEADSHOT_MULTIPLIER) or baseDamage

	print(("[AbyssPvP] %s → %s | dmg=%d headshot=%s"):format(
		shooter.Name, victim.Name, finalDamage, tostring(isHeadshot)))

	-- ========== APPLY DAMAGE (triple fallback) ==========
	local damageApplied = false

	-- Path 1: HealthManager
	if not damageApplied and _G.HealthManager and _G.HealthManager.ApplyDamage then
		if _G.HealthManager.EnableHealthMode then
			if not (_G.HealthManager.IsInHealthMode and _G.HealthManager.IsInHealthMode(victim)) then
				_G.HealthManager.EnableHealthMode(victim, "Abyss")
			end
			if not (_G.HealthManager.IsInHealthMode and _G.HealthManager.IsInHealthMode(shooter)) then
				_G.HealthManager.EnableHealthMode(shooter, "Abyss")
			end
		end
		local ok = _G.HealthManager.ApplyDamage(victim, finalDamage, shooter, isHeadshot and "headshot" or "body")
		if ok then damageApplied = true end
	end

	-- Path 2: _G.damagePlayer directly
	if not damageApplied and _G.damagePlayer then
		local result = _G.damagePlayer(victim, finalDamage)
		if result then damageApplied = true end
	end

	-- Path 3: Humanoid directly (last resort)
	if not damageApplied then
		victimHum:TakeDamage(finalDamage)
		damageApplied = true
	end

	if damageApplied then
		-- Check death
		local victimHealth = _G.getHealth and _G.getHealth(victim) or victimHum.Health
		if victimHealth <= 0 then
			handleAbyssKill(shooter, victim)
		end
		AbyssPvPEvent:FireClient(shooter, "HitMarker", isHeadshot and "headshot" or "body", finalDamage)
		AbyssPvPEvent:FireClient(victim, "DamageTaken", shooter.Name, finalDamage, isHeadshot)
		print(("⚔️ [AbyssPvP] %s hit %s for %d (%s) – HP: %d"):format(
			shooter.Name, victim.Name, finalDamage, isHeadshot and "HEAD" or "body", victimHealth))
	end

	return damageApplied
end

--------------------------------------------------------------------------
-- KILL HANDLING
--------------------------------------------------------------------------

handleAbyssKill = function(killer: Player, victim: Player)
	local now = tick()
	if lastKillTime[killer] and (now - lastKillTime[killer]) < KILL_COOLDOWN then return end
	lastKillTime[killer] = now

	local killerData = _G.getData and _G.getData(killer)
	local victimData = _G.getData and _G.getData(victim)

	local skinsStolen, cratesStolen = 0, 0

	-- Safety: make sure killer and victim have separate data tables
	if killerData and victimData and killerData ~= victimData then
		-- Transfer skins (inventory only, NOT storage) — transfer counts
		if victimData.skins then
			if not killerData.skins then killerData.skins = {} end
			for skinId, qty in pairs(victimData.skins) do
				local amount = type(qty) == "number" and qty or 1
				killerData.skins[skinId] = (killerData.skins[skinId] or 0) + amount
				skinsStolen += amount
			end
			victimData.skins = {}
		end
		-- Transfer crates
		if victimData.boxes then
			if not killerData.boxes then killerData.boxes = {} end
			for crateType, count in pairs(victimData.boxes) do
				if type(count) == "number" and count > 0 then
					killerData.boxes[crateType] = (killerData.boxes[crateType] or 0) + count
					cratesStolen += count
				end
			end
			victimData.boxes = {}
		end
		-- Storage is a safe space — do NOT transfer storage items
	elseif killerData == victimData then
		warn("[AbyssPvP] ⚠️ Killer and victim share the same data table! Skipping transfer.")
	end

	-- Count killer's total skins after transfer for debug
	local killerSkinCount = 0
	if killerData and killerData.skins then
		for _, qty in pairs(killerData.skins) do
			killerSkinCount += (type(qty) == "number" and qty or 1)
		end
	end
	warn(("[AbyssPvP] Transfer complete: %s now has %d skins | Stole %d skins, %d crates from %s"):format(
		killer.Name, killerSkinCount, skinsStolen, cratesStolen, victim.Name))

	if killerData then
		killerData.battles = (killerData.battles or 0) + 1
		if _G.addMoney then _G.addMoney(killer, KILL_GOLD_REWARD) end
		if _G.QuestProgress then _G.QuestProgress(killer, "abyss_kills", 1) end
		AbyssPvPEvent:FireClient(killer, "Kill", victim.Name, KILL_GOLD_REWARD, skinsStolen, cratesStolen)
	end
	if victimData then
		-- NOTE: death stat is already incremented by HealthManager.handlePlayerDeath
		-- so we do NOT increment it here to avoid double-counting
		AbyssPvPEvent:FireClient(victim, "Killed", killer.Name, skinsStolen, cratesStolen)
	end

	for plr, _ in playersInAbyss do
		if plr ~= killer and plr ~= victim and plr.Parent then
			AbyssPvPEvent:FireClient(plr, "KillFeed", killer.Name, victim.Name)
		end
	end
	print(("🏆 [AbyssPvP] %s killed %s! +%d gold | %d skins, %d crates"):format(
		killer.Name, victim.Name, KILL_GOLD_REWARD, skinsStolen, cratesStolen))

	-- Remove victim from Abyss immediately (prevents further hits)
	exitAbyss(victim)

	-- Kill the character for visual death + natural respawn
	local vChar = victim.Character
	local vHum = vChar and vChar:FindFirstChildOfClass("Humanoid")
	if vHum then
		vHum.Health = 0
	end
end

--------------------------------------------------------------------------
-- CLEANUP
--------------------------------------------------------------------------
Players.PlayerRemoving:Connect(function(plr)
	playersInAbyss[plr] = nil
	playerEntryPos[plr] = nil
	playerEntryTime[plr] = nil
	lastKillTime[plr] = nil
end)

--------------------------------------------------------------------------
-- GLOBAL API (used by GameShooting.server.lua)
--------------------------------------------------------------------------
_G.AbyssPvP = {
	isInAbyss = function(plr: Player): boolean
		return playersInAbyss[plr] == true
	end,

	getAbyssPlayers = function(excludePlayer: Player?): { Player }
		local result = {}
		for plr, _ in playersInAbyss do
			if plr ~= excludePlayer and plr.Parent then
				table.insert(result, plr)
			end
		end
		return result
	end,

	dealDamage = function(shooter: Player, victim: Player, isHeadshot: boolean): boolean
		return dealAbyssPvPDamage(shooter, victim, isHeadshot)
	end,
}

warn("🔥🔥🔥 [AbyssPvP] Abyss PvP SERVER LOADED – listening for AbyssTeleport events")
