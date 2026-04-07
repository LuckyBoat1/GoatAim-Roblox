-- BossMagmor.server.lua
-- Magmor Boss Arena Manager
-- Clones the BullArena template, removes the bull, spawns Magmor at its position.
-- Reuses the same RemoteEvents as the Bull arena so the client BullTeleportUI / BullGameUI
-- display identically (same countdown screen, same game timer, same traffic light).

--print("=" .. string.rep("=", 60))
--print("🔮 BOSS MAGMOR MANAGER - SCRIPT START")
--print("=" .. string.rep("=", 60))

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

-- ── Configuration ────────────────────────────────────────────────────────────
local MAX_ARENAS      = 5
local ARENA_SPACING   = 12000   -- Different from bull arenas (10000) to avoid overlap
local ARENA_HEIGHT    = 500
local GAME_DURATION   = 600     -- 10 minutes
local COUNTDOWN_TIME  = 3       -- seconds to stand on platform
local PROXIMITY_RANGE = 10      -- studs from MagmorPlatform
local MAGMOR_MAX_HP   = 5000
local ARENA_MIN_Y     = 300     -- if player Y drops below this they left the arena

-- ── RemoteEvents (same as Bull so client UI is identical) ────────────────────
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 30)
if not RemoteEvents then error("[BossMagmor] RemoteEvents folder not found!") end

local function ensureRE(name)
	local re = RemoteEvents:FindFirstChild(name)
	if not re then
		re = Instance.new("RemoteEvent")
		re.Name   = name
		re.Parent = RemoteEvents
	end
	return re
end

local TeleportCountdownRE  = RemoteEvents:WaitForChild("TeleportCountdown", 30)
local GameTimerRE          = ensureRE("GameTimer")
local TrafficLightRE       = ensureRE("TrafficLightUpdate")
local MagmorScoreRE        = ensureRE("MagmorScoreUpdate")

if not TeleportCountdownRE then
	error("[BossMagmor] TeleportCountdown RE not found - BullTeleporter may not have run yet!")
end

-- ── MagmorPlatform ───────────────────────────────────────────────────────────
local gameFolder = workspace:WaitForChild("Game", 30)
if not gameFolder then error("[BossMagmor] Game folder not found!") end

local spawnArena = gameFolder:WaitForChild("SpawnArena", 30)
if not spawnArena then error("[BossMagmor] SpawnArena folder not found!") end

local magmorPlatform = spawnArena:WaitForChild("MagmorPlatform", 30)
if not magmorPlatform then error("[BossMagmor] MagmorPlatform not found in SpawnArena!") end

-- If it's a Model, use its main BasePart
if not magmorPlatform:IsA("BasePart") then
	local part = magmorPlatform:FindFirstChildWhichIsA("BasePart")
	if part then magmorPlatform = part else error("[BossMagmor] MagmorPlatform has no BasePart!") end
end
magmorPlatform.CanCollide = true
--print("[BossMagmor] MagmorPlatform resolved to: " .. magmorPlatform:GetFullName())
--print("[BossMagmor] MagmorPlatform position: " .. tostring(magmorPlatform.Position))

-- ── Helpers ──────────────────────────────────────────────────────────────────
local function anchorModel(model)
	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("BasePart") then desc.Anchored = true end
	end
end

local function getPos(obj)
	if not obj then return nil end
	if obj:IsA("BasePart") then return obj.Position end
	if obj:IsA("Model") then
		if obj.PrimaryPart then return obj.PrimaryPart.Position end
		local bp = obj:FindFirstChildWhichIsA("BasePart", true)
		return bp and bp.Position
	end
end

local function moveArenaTo(arenaModel, targetPos)
	local platform = arenaModel:FindFirstChild("ArenaPlatform")
	local currentPos = platform and getPos(platform)
	if not currentPos then
		arenaModel:PivotTo(CFrame.new(targetPos))
		return
	end
	arenaModel:PivotTo(arenaModel:GetPivot() + (targetPos - currentPos))
end

-- ── Arena state (shared between init task and proximity loop) ────────────────
local arenaPool    = {}
local playerArenas = {}
local nextIdx      = 1
local initReady    = false  -- flipped to true once NPC + arenas are built

-- These are set during background init
local magmorNPCTemplate = nil
local bullArena1        = nil
local MAGMOR_SPAWN_OFFSET = Vector3.new(0, 6, 20)

local function spawnMagmorInArena(arenaClone)
	local platform = arenaClone:FindFirstChild("ArenaPlatform")
	local platformPos = getPos(platform) or arenaClone:GetPivot().Position

	local bull = arenaClone:FindFirstChild("bull")
	if bull then bull:Destroy() end

	local magmorSpawnPos = platformPos + MAGMOR_SPAWN_OFFSET
	local magmir = magmorNPCTemplate:Clone()
	magmir.Name = "Magmor"

	for _, desc in ipairs(magmir:GetDescendants()) do
		if desc:IsA("BasePart") then desc.Anchored = true end
	end
	if magmir:IsA("BasePart") then magmir.Anchored = true end

	magmir:SetAttribute("MaxHealth", MAGMOR_MAX_HP)
	magmir:SetAttribute("Health",    MAGMOR_MAX_HP)

	if magmir:IsA("Model") then
		if magmir.PrimaryPart then
			magmir:SetPrimaryPartCFrame(CFrame.new(magmorSpawnPos))
		else
			magmir:PivotTo(CFrame.new(magmorSpawnPos))
		end
	elseif magmir:IsA("BasePart") then
		magmir.Position = magmorSpawnPos
	end

	magmir.Parent = arenaClone
	return magmir
end

local function buildArena(idx)
	local clone = bullArena1:Clone()
	clone.Name = "MagmorArena_" .. idx
	anchorModel(clone)

	local angle = (2 * math.pi / MAX_ARENAS) * (idx - 1)
	local x = math.round(math.cos(angle) * ARENA_SPACING)
	local z = math.round(math.sin(angle) * ARENA_SPACING)
	moveArenaTo(clone, Vector3.new(x, ARENA_HEIGHT, z))

	clone.Parent = workspace

	local magmir   = spawnMagmorInArena(clone)
	local platform = clone:FindFirstChild("ArenaPlatform")

	--print("[BossMagmor] Created " .. clone.Name .. " at (" .. x .. ", " .. ARENA_HEIGHT .. ", " .. z .. ")")

	return {
		arena     = clone,
		magmor    = magmir,
		platform  = platform,
		occupied  = false,
		player    = nil,
	}
end

local function createNewArena()
	if nextIdx > MAX_ARENAS then
		warn("[BossMagmor] Max Magmor arenas (" .. MAX_ARENAS .. ") reached!")
		return nil
	end
	local data = buildArena(nextIdx)
	table.insert(arenaPool, data)
	nextIdx += 1
	return data
end

local function getAvailableArena(player)
	for _, data in ipairs(arenaPool) do
		if not data.occupied then
			data.occupied = true
			data.player   = player
			playerArenas[player.UserId] = data
			return data
		end
	end
	local newData = createNewArena()
	if newData then
		newData.occupied = true
		newData.player   = player
		playerArenas[player.UserId] = newData
		return newData
	end
	return nil
end

-- ── Reset Magmor and free arena slot ─────────────────────────────────────────
local function freeMagmorArena(player)
	local data = playerArenas[player.UserId]
	if data then
		if data.magmor and data.magmor.Parent then
			data.magmor:SetAttribute("Health", data.magmor:GetAttribute("MaxHealth") or MAGMOR_MAX_HP)
		end
		data.occupied = false
		data.player   = nil
		playerArenas[player.UserId] = nil
		--print("[BossMagmor] Freed arena for " .. player.Name)
	end
end

-- ── Give rewards at session end ───────────────────────────────────────────────
local function rewardPlayer(player, score, reason)
	local gold = 0
	if score >= 5   then gold += 100   end
	if score >= 38  then gold += 400   end
	if score >= 75  then gold += 500   end
	if score >= 150 then gold += 50000 end  -- Boss jackpot

	local exp = 10 + score

	if _G.addMoney then _G.addMoney(player, gold) end
	if _G.addExp   then _G.addExp(player, exp)    end

	local msg
	if reason == "timeout" then
		msg = string.format("⏱ Magmor session ended! +%d gold, +%d EXP", gold, exp)
	else
		msg = string.format("🔮 Left Magmor arena. +%d gold, +%d EXP", gold, exp)
	end
	if _G.notify then _G.notify(player, msg) end

	freeMagmorArena(player)
end

-- ── Teleport player to arena ──────────────────────────────────────────────────
local function teleportPlayer(player, data)
	local char = player.Character
	if not char then
		char = player.CharacterAdded:Wait()
	end
	if not char then return false end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		hrp = char:WaitForChild("HumanoidRootPart", 5)
	end
	if not hrp then return false end

	local spawnPos
	local platform = data.platform
	if platform then
		local pp = getPos(platform)
		spawnPos = pp and (pp + Vector3.new(0, 5, 0))
	end
	-- Fallback: use arena pivot if platform has no position
	if not spawnPos then
		local arenaPivot = data.arena and data.arena:GetPivot()
		if arenaPivot then
			spawnPos = arenaPivot.Position + Vector3.new(0, 5, 0)
		end
	end
	if not spawnPos then
		warn("[BossMagmor] No spawn pos for " .. data.arena.Name)
		return false
	end

	hrp.CFrame = CFrame.new(spawnPos)
	--print("[BossMagmor] Teleported " .. player.Name .. " to " .. tostring(spawnPos))
	return true
end

-- ── Session loop (traffic light + game timer + position monitor) ──────────────
local function runSession(player, data)
	if _G.getData then
		local d = _G.getData(player)
		if d then d.magmorScore = d.magmorScore or 0 ; d.magmorScore = 0 end
	end
	MagmorScoreRE:FireClient(player, 0)

	local lightActive = true

	task.spawn(function()
		while lightActive and data.occupied and data.player == player do
			TrafficLightRE:FireClient(player, "Green")
			task.wait(math.random(3, 6))
			if not lightActive then break end
			TrafficLightRE:FireClient(player, "Red")
			task.wait(math.random(3, 5))
		end
	end)

	task.spawn(function()
		local timeLeft = GAME_DURATION
		while timeLeft >= 0 and data.occupied and data.player == player do
			GameTimerRE:FireClient(player, timeLeft, data.arena)
			if timeLeft == 0 then
				lightActive = false
				local score = 0
				if _G.getData then
					local d = _G.getData(player)
					if d then score = d.magmorScore or 0 end
				end
				rewardPlayer(player, score, "timeout")
				return
			end
			task.wait(1)
			timeLeft -= 1
		end
	end)

	task.spawn(function()
		while data.occupied and data.player == player do
			task.wait(1)
			local char = player.Character
			local hrp  = char and char:FindFirstChild("HumanoidRootPart")
			if hrp and hrp.Position.Y < ARENA_MIN_Y then
				lightActive = false
				local score = 0
				if _G.getData then
					local d = _G.getData(player)
					if d then score = d.magmorScore or 0 end
				end
				rewardPlayer(player, score, "left_arena")
				return
			end
		end
	end)
end

-- ── Global API ───────────────────────────────────────────────────────────────
_G.RequestMagmorArena = function(player)
	-- Wait for background init to finish (up to 60s)
	if not initReady then
		warn("[BossMagmor] Arenas still loading - waiting for init...")
		for i = 1, 120 do
			if initReady then break end
			task.wait(0.5)
		end
	end

	if not initReady then
		warn("[BossMagmor] Arenas failed to initialize after waiting")
		return nil
	end

	local data = getAvailableArena(player)
	if not data then
		warn("[BossMagmor] No Magmor arena available for " .. player.Name)
		return nil
	end

	if not teleportPlayer(player, data) then
		data.occupied = false
		data.player   = nil
		playerArenas[player.UserId] = nil
		return nil
	end

	--print("[BossMagmor] " .. player.Name .. " entered " .. data.arena.Name)
	runSession(player, data)
	return data
end

_G.FreeMagmorArena   = freeMagmorArena
_G.GetPlayerMagmorArena = function(player) return playerArenas[player.UserId] end

-- ── Cleanup on player leave ───────────────────────────────────────────────────
Players.PlayerRemoving:Connect(function(player)
	freeMagmorArena(player)
end)

-- ── Platform proximity detection — starts IMMEDIATELY (no init dependency) ────
local playersOnPlatform = {}

--print("[BossMagmor] ✅ Proximity loop STARTED for MagmorPlatform")

task.spawn(function()
	while true do
		task.wait(0.5)
		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			if char then
				local hrp = char:FindFirstChild("HumanoidRootPart")
				if hrp then
					local dist = (hrp.Position - magmorPlatform.Position).Magnitude

					if dist <= PROXIMITY_RANGE then
						if not playersOnPlatform[player.UserId] then
							-- Skip if player is already in a Magmor arena
							if playerArenas[player.UserId] then continue end
							-- Skip if player is already in a Bull arena
							if _G.GetPlayerArena and _G.GetPlayerArena(player) then continue end

							playersOnPlatform[player.UserId] = true
							--print("[BossMagmor] " .. player.Name .. " near MagmorPlatform - starting countdown")

							task.spawn(function()
								-- Countdown
								for i = COUNTDOWN_TIME, 1, -1 do
									local hrp2 = char:FindFirstChild("HumanoidRootPart")
									if not hrp2 or (hrp2.Position - magmorPlatform.Position).Magnitude > PROXIMITY_RANGE then
										--print("[BossMagmor] " .. player.Name .. " moved away during countdown")
										TeleportCountdownRE:FireClient(player, 0)
										playersOnPlatform[player.UserId] = nil
										return
									end
									--print("[BossMagmor] Countdown " .. i .. " for " .. player.Name)
									TeleportCountdownRE:FireClient(player, i)
									task.wait(1)
								end

								TeleportCountdownRE:FireClient(player, 0)

								-- Teleport to Magmor arena
								if _G.RequestMagmorArena then
									--print("[BossMagmor] Requesting Magmor arena for " .. player.Name)
									local arenaData = _G.RequestMagmorArena(player)
									if arenaData then
										--print("[BossMagmor] " .. player.Name .. " teleported to Magmor arena!")
									else
										warn("[BossMagmor] Failed to teleport " .. player.Name .. " - no arenas available")
									end
								else
									warn("[BossMagmor] _G.RequestMagmorArena not available!")
								end

								-- Always clear so player can re-enter if teleport/arena fails
								playersOnPlatform[player.UserId] = nil
							end)
						end
					else
						-- Player walked away
						if playersOnPlatform[player.UserId] then
							playersOnPlatform[player.UserId] = nil
							TeleportCountdownRE:FireClient(player, 0)
						end
					end
				end
			end
		end
	end
end)

-- Override FreeMagmorArena to also clear platform tracking
local orig_FreeMagmorArena = _G.FreeMagmorArena
_G.FreeMagmorArena = function(player)
	orig_FreeMagmorArena(player)
	playersOnPlatform[player.UserId] = nil
end

-- ── Background init: NPC template + BullArena + arena pool ───────────────────
-- Runs in background so the proximity loop above is NOT blocked by slow WaitForChild
task.spawn(function()
	--print("[BossMagmor] Background init starting (NPC + arena pool)...")

	-- Find NPC folder
	local npcFolder
	for _, name in ipairs({ "NPC", "npc", "NPCs", "Npcs", "npcs" }) do
		npcFolder = ReplicatedStorage:FindFirstChild(name)
		if npcFolder then --[[print("[BossMagmor] Found NPC folder: '" .. name .. "'")]] break end
	end
	if not npcFolder then
		-- Print what IS in ReplicatedStorage so we can debug
		--print("[BossMagmor] NPC folder not found instantly. ReplicatedStorage children:")
		--for _, child in ipairs(ReplicatedStorage:GetChildren()) do
		--	print("  - " .. child.Name .. " (" .. child.ClassName .. ")")
		--end
		for _, name in ipairs({ "NPC", "npc", "NPCs", "Npcs" }) do
			npcFolder = ReplicatedStorage:WaitForChild(name, 8)
			if npcFolder then --[[print("[BossMagmor] Found NPC folder (waited): '" .. name .. "'")]] break end
		end
	end
	if not npcFolder then
	--warn("[BossMagmor] ✅ NPC folder not found in ReplicatedStorage! Arenas will NOT be built.")
		--warn("[BossMagmor] Countdown/proximity still works but teleport will fail until this is fixed.")
		return
	end

	magmorNPCTemplate = npcFolder:FindFirstChild("Magmor") or npcFolder:WaitForChild("Magmor", 30)
	if not magmorNPCTemplate then
		warn("[BossMagmor] ⚠️ Magmor model not found in " .. npcFolder:GetFullName() .. "!")
		warn("[BossMagmor] Children of NPC folder:")
		for _, child in ipairs(npcFolder:GetChildren()) do
			warn("  - " .. child.Name .. " (" .. child.ClassName .. ")")
		end
		return
	end
	--print("[BossMagmor] Found Magmor NPC template ✅")

	-- Wait for BullArenaManager to place BullArena_1
	--print("[BossMagmor] Waiting for BullArena_1 (from BullArenaManager)...")
	task.wait(5)
	bullArena1 = workspace:FindFirstChild("BullArena_1")
	if not bullArena1 then
		bullArena1 = workspace:WaitForChild("BullArena_1", 60)
	end
	if not bullArena1 then
		warn("[BossMagmor] ⚠️ BullArena_1 not in workspace after 65s - retrying once...")
		task.wait(10)
		bullArena1 = workspace:FindFirstChild("BullArena_1")
	end
	if not bullArena1 then
		warn("[BossMagmor] ⚠️ BullArena_1 still not found - ensure BullArenaManager runs first!")
		return
	end
	--print("[BossMagmor] Found BullArena_1 ✅")

	-- Capture bull offset
	do
		local bull     = bullArena1:FindFirstChild("bull")
		local platform = bullArena1:FindFirstChild("ArenaPlatform")
		if bull and platform then
			local bp = getPos(bull)
			local pp = getPos(platform)
			if bp and pp then
				MAGMOR_SPAWN_OFFSET = bp - pp
				--print("[BossMagmor] Bull offset from ArenaPlatform: " .. tostring(MAGMOR_SPAWN_OFFSET))
			end
		else
			--print("[BossMagmor] Could not find bull/platform in BullArena_1, using default offset")
		end
	end

	-- Build initial arenas
	--print("[BossMagmor] Building initial arena pool...")
	for i = 1, 2 do
		table.insert(arenaPool, buildArena(i))
	end
	nextIdx = 3
	--print("[BossMagmor] " .. #arenaPool .. " Magmor arenas ready.")

	initReady = true

	--print("=" .. string.rep("=", 60))
	--print("✅ BOSS MAGMOR MANAGER READY - Arenas built, proximity active")
	--print("=" .. string.rep("=", 60))
end)
