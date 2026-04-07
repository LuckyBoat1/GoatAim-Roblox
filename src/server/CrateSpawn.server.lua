--[[
	CrateSpawn.server.lua
	Spawns REAL crate models (cloned from RS.Crates) at spawn-point positions
	inside workspace.Game.Abyss.Crates.
	Each crate gets an invisible touch-detection Part added by code
	(because the models only have 1 MeshPart which can't detect touch alone).
	Players walk into a crate to pick it up (granted via _G.GrantBox).
]]

warn("[CrateSpawn] ========== SCRIPT STARTING ==========")

------------------------------------------------------------------------
-- MASTER ON/OFF SWITCH
------------------------------------------------------------------------
local ENABLED = true  -- Set to false to disable crate world spawning
------------------------------------------------------------------------

if not ENABLED then
	warn("[CrateSpawn] DISABLED — set ENABLED = true to re-enable crate world spawning")
	return
end
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

------------------------------------------------------------------------
-- REMOTE EVENT: notify client when a crate is granted
------------------------------------------------------------------------
local RemoteEvents = RS:FindFirstChild("RemoteEvents") or (function()
	local f = Instance.new("Folder")
	f.Name = "RemoteEvents"
	f.Parent = RS
	return f
end)()
local CrateGrantedRE = RemoteEvents:FindFirstChild("CrateGranted") or (function()
	local re = Instance.new("RemoteEvent")
	re.Name = "CrateGranted"
	re.Parent = RemoteEvents
	return re
end)()

local CratePickupFXRE = RemoteEvents:FindFirstChild("CratePickupFX") or (function()
	local re = Instance.new("RemoteEvent")
	re.Name = "CratePickupFX"
	re.Parent = RemoteEvents
	return re
end)()

------------------------------------------------------------------------
-- SETTINGS
------------------------------------------------------------------------
local SETTINGS = {
	CratesPerWave  = 10,
	Interval       = 600,        -- seconds between waves (set to 120 for production)

	Weights = {
		BRONZE   = 40,
		SILVER   = 25,
		SAPPHIRE = 18,
		OMEGA    = 12,
		RUBY     = 5,
	},

	FloatHeight     = 3,       -- studs above ground
	SpinSpeed       = 60,      -- degrees/sec (Minecraft is ~45-60)
	PickupCooldown  = 0.3,
	GroundRayDist   = 500,

	-- Size of the invisible touch-detection box added around each crate
	TouchPartSize   = Vector3.new(6, 6, 6),

	-- Proximity pickup radius (studs) — player walks within this to collect
	PickupRadius    = 12,
	-- How often to check proximity (seconds)
	PickupCheckRate = 0.1,

	-- === MINECRAFT-STYLE ANIMATION ===
	-- Bobbing (up/down float like MC items)
	BobHeight       = 0.4,     -- studs of vertical bob
	BobSpeed        = 1.2,     -- cycles per second

	-- Magnetic fly-to-player on pickup
	FlyTime         = 0.35,    -- seconds to fly to player
	FlyArcHeight    = 2,       -- studs upward arc during fly
	ShrinkTo        = 0.15,    -- final scale (fraction of original)

	-- Magnet pull zone (items drift toward player before full collect)
	MagnetRadius    = 65,      -- start drifting at this range
	MagnetSpeed     = 20,      -- studs/sec drift speed

	-- Pop sound on pickup
	PickupSoundId   = "rbxassetid://5065880665",  -- pop/plop sound
}

------------------------------------------------------------------------
-- CRATE LABEL INFO (for billboard)
------------------------------------------------------------------------
local CRATE_INFO = {
	BRONZE   = { color = Color3.fromRGB(205, 127, 50),  name = "Bronze Crate" },
	SILVER   = { color = Color3.fromRGB(192, 192, 192), name = "Silver Crate" },
	SAPPHIRE = { color = Color3.fromRGB(65, 105, 225),  name = "Sapphire Crate" },
	OMEGA    = { color = Color3.fromRGB(255, 128, 0),   name = "Omega Crate" },
	RUBY     = { color = Color3.fromRGB(220, 20, 60),   name = "Ruby Crate" },
}

------------------------------------------------------------------------
-- LOCATE CRATE TEMPLATES IN RS.Crates
------------------------------------------------------------------------
warn("[CrateSpawn] Waiting for RS.Crates ...")
local cratesFolder = RS:WaitForChild("Crates", 30)
if not cratesFolder then warn("[CrateSpawn] FAIL: RS.Crates missing") return end

local crateTemplates = {} -- { [crateType] = Instance }
for crateType, _ in pairs(SETTINGS.Weights) do
	local modelName = crateType:sub(1, 1) .. crateType:sub(2):lower() -- BRONZE -> Bronze
	local found = cratesFolder:FindFirstChild(modelName)
	if found then
		crateTemplates[crateType] = found
		local parts = 0
		for _, d in ipairs(found:GetDescendants()) do
			if d:IsA("BasePart") then parts += 1 end
		end
		if found:IsA("BasePart") then parts += 1 end
		warn(string.format("[CrateSpawn] Template %s -> %s (%s) %d parts", crateType, found.Name, found.ClassName, parts))
	else
		warn(string.format("[CrateSpawn] WARNING: No template for %s (looked for '%s')", crateType, modelName))
	end
end

------------------------------------------------------------------------
-- SPAWN POINTS — populated once workspace finishes loading (see MAIN LOOP)
------------------------------------------------------------------------
local spawnPoints = {}
local spawnContainer = nil  -- set in MAIN LOOP once workspace is ready

------------------------------------------------------------------------
-- WEIGHTED RANDOM PICKER
------------------------------------------------------------------------
local pool = {}
do
	local cum = 0
	for crateType, w in pairs(SETTINGS.Weights) do
		cum = cum + w
		table.insert(pool, { t = crateType, cw = cum })
	end
end
local totalW = pool[#pool].cw

local function pickType()
	local r = math.random() * totalW
	for _, e in ipairs(pool) do
		if r <= e.cw then return e.t end
	end
	return pool[#pool].t
end

------------------------------------------------------------------------
-- ACTIVE CRATES
------------------------------------------------------------------------
local activeCrates = {}  -- list of Model wrappers in workspace
local crateBaseY = {}    -- [crate] = original Y position (for bobbing)
local crateSpawnTime = {} -- [crate] = os.clock() when spawned (for bob phase)
local flyingCrates = {}  -- crates currently in fly-to-player animation (excluded from proximity)
local cooldowns = {}

local crateHolder = Instance.new("Folder")
crateHolder.Name = "SpawnedCrates"
crateHolder.Parent = workspace

------------------------------------------------------------------------
-- MINECRAFT-STYLE PICKUP ANIMATION
-- Item flies toward player in an arc, shrinks, pops, then grants.
------------------------------------------------------------------------
local function playPickupAnimation(player, crateModel, crateType)
	-- Remove from active list immediately so proximity loop ignores it
	local idx = table.find(activeCrates, crateModel)
	if idx then table.remove(activeCrates, idx) end
	flyingCrates[crateModel] = true

	-- Capture world position before the model is destroyed
	local startPos
	if crateModel:IsA("Model") and crateModel.PrimaryPart then
		startPos = crateModel.PrimaryPart.Position
	elseif crateModel:IsA("BasePart") then
		startPos = crateModel.Position
	else
		startPos = crateModel:GetPivot().Position
	end

	if _G.GrantBox then
		_G.GrantBox(player, crateType, 1)
		warn(string.format("[CrateSpawn] %s picked up a %s crate!", player.Name, crateType))
		CrateGrantedRE:FireClient(player, crateType, 1)
		CratePickupFXRE:FireClient(player, startPos, crateType)
	else
		warn("[CrateSpawn] _G.GrantBox not available — " .. player.Name .. " missed a " .. crateType)
	end

	-- Destroy the server model; client handles the visual
	flyingCrates[crateModel] = nil
	if crateModel and crateModel.Parent then
		crateModel:Destroy()
	end
end

------------------------------------------------------------------------
-- PICKUP HANDLER (called by proximity check OR touch fallback)
------------------------------------------------------------------------
local function collectCrate(player, crateModel, crateType)
	local now = tick()
	if cooldowns[player.UserId] and (now - cooldowns[player.UserId]) < SETTINGS.PickupCooldown then
		return
	end
	cooldowns[player.UserId] = now

	if not crateModel.Parent then return end
	if crateModel:GetAttribute("Collected") then return end
	crateModel:SetAttribute("Collected", true)

	-- Fire Minecraft-style animation in a separate thread
	task.spawn(playPickupAnimation, player, crateModel, crateType)
end

-- Touch fallback
local function onTouched(hit, crateModel, crateType)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player then return end
	collectCrate(player, crateModel, crateType)
end

------------------------------------------------------------------------
-- GROUND RAYCAST
------------------------------------------------------------------------
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function findGround(origin)
	local res = workspace:Raycast(origin, Vector3.new(0, -SETTINGS.GroundRayDist, 0), rayParams)
	if res then return res.Position end
	local up = workspace:Raycast(origin, Vector3.new(0, SETTINGS.GroundRayDist, 0), rayParams)
	if up then
		local down = workspace:Raycast(up.Position + Vector3.new(0, 1, 0),
			Vector3.new(0, -SETTINGS.GroundRayDist * 2, 0), rayParams)
		if down then return down.Position end
	end
	return nil
end

------------------------------------------------------------------------
-- BUILD A CRATE — clone real model + add invisible touch Part
------------------------------------------------------------------------
local function buildCrate(crateType, position)
	local template = crateTemplates[crateType]
	local info = CRATE_INFO[crateType]
	if not info then return nil end

	-- Create a wrapper Model that holds everything
	local wrapper = Instance.new("Model")
	wrapper.Name = crateType .. "_Crate"

	-- Clone the real visual if we have a template
	if template then
		local visual = template:Clone()
		visual.Name = "Visual"
		-- Anchor all parts, disable collide, disable touch on the mesh
		-- (touch will be handled by our added Part)
		for _, part in ipairs(visual:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
				part.CanCollide = false
				part.CanQuery = false
				part.CanTouch = false  -- mesh doesn't need touch
			end
		end
		if visual:IsA("BasePart") then
			visual.Anchored = true
			visual.CanCollide = false
			visual.CanQuery = false
			visual.CanTouch = false
		end
		visual.Parent = wrapper
	end

	-- Add an invisible touch-detection Part (this is the key fix!)
	local touchPart = Instance.new("Part")
	touchPart.Name = "TouchDetector"
	touchPart.Size = SETTINGS.TouchPartSize
	touchPart.Transparency = 1   -- invisible
	touchPart.Anchored = true
	touchPart.CanCollide = false
	touchPart.CanQuery = false
	touchPart.CanTouch = true    -- THIS detects touch
	touchPart.CFrame = CFrame.new(position)
	touchPart.Parent = wrapper

	-- Set as PrimaryPart so we can PivotTo easily
	wrapper.PrimaryPart = touchPart

	-- Now position the visual mesh centered on the touchPart
	if template then
		local visual = wrapper:FindFirstChild("Visual")
		if visual then
			-- Find the first BasePart in the visual to calculate offset
			local firstPart
			if visual:IsA("BasePart") then
				firstPart = visual
			elseif visual:IsA("Model") and visual.PrimaryPart then
				firstPart = visual.PrimaryPart
			else
				firstPart = visual:FindFirstChildWhichIsA("BasePart", true)
			end
			if firstPart then
				local moveOffset = position - firstPart.Position
				if visual:IsA("Model") then
					visual:PivotTo(visual:GetPivot() + moveOffset)
				elseif visual:IsA("BasePart") then
					visual.CFrame = visual.CFrame + moveOffset
				else
					-- Folder or other container
					for _, p in ipairs(visual:GetDescendants()) do
						if p:IsA("BasePart") then
							p.CFrame = p.CFrame + moveOffset
						end
					end
				end
			end
		end
	end

	-- Billboard label
	local bb = Instance.new("BillboardGui")
	bb.Name = "CrateLabel"
	bb.Size = UDim2.fromOffset(200, 50)
	bb.StudsOffset = Vector3.new(0, 4, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 80
	bb.Adornee = touchPart
	bb.Parent = touchPart

	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.fromScale(1, 1)
	txt.BackgroundTransparency = 1
	txt.Text = "📦 " .. info.name
	txt.TextColor3 = info.color
	txt.TextStrokeTransparency = 0.3
	txt.TextStrokeColor3 = Color3.new(0, 0, 0)
	txt.Font = Enum.Font.FredokaOne
	txt.TextScaled = true
	txt.Parent = bb

	-- Tag
	wrapper:SetAttribute("CrateType", crateType)

	-- Connect touch on the invisible Part
	wrapper:SetAttribute("CrateType", crateType) -- needed by proximity pickup loop

	touchPart.Touched:Connect(function(hit)
		onTouched(hit, wrapper, crateType)
	end)

	return wrapper
end

------------------------------------------------------------------------
-- SPAWN / DESPAWN
------------------------------------------------------------------------
local function despawnAll()
	for _, c in ipairs(activeCrates) do
		if c and c.Parent then c:Destroy() end
	end
	activeCrates = {}
	crateBaseY = {}
	crateSpawnTime = {}
	for k in pairs(flyingCrates) do flyingCrates[k] = nil end
	for _, child in ipairs(crateHolder:GetChildren()) do
		child:Destroy()
	end
end

local function spawnWave()
	despawnAll()

	local filter = { crateHolder, spawnContainer }
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character then table.insert(filter, plr.Character) end
	end
	rayParams.FilterDescendantsInstances = filter

	local spawned = 0
	local noGround = 0
	local noTemplate = 0

	for i = 1, SETTINGS.CratesPerWave do
		local sp = spawnPoints[math.random(1, #spawnPoints)]
		local crateType = pickType()

		if not crateTemplates[crateType] then
			noTemplate = noTemplate + 1
			continue
		end

		local groundPos = findGround(sp.Position)
		if not groundPos then
			groundPos = sp.Position
			noGround = noGround + 1
		end

		local jitter = Vector3.new(
			(math.random() - 0.5) * 4,
			0,
			(math.random() - 0.5) * 4
		)
		local finalPos = groundPos + Vector3.new(0, SETTINGS.FloatHeight, 0) + jitter

		local crate = buildCrate(crateType, finalPos)
		if not crate then continue end

		crate.Parent = crateHolder
		table.insert(activeCrates, crate)
		crateBaseY[crate] = finalPos.Y
		crateSpawnTime[crate] = os.clock() + math.random() * 3 -- random phase offset
		spawned = spawned + 1
	end

	warn(string.format("[CrateSpawn] Spawned %d crates across %d points (next wave in %ds)",
		spawned, #spawnPoints, SETTINGS.Interval))
	if noGround > 0 then
		warn(string.format("[CrateSpawn] %d had no ground (used raw spawn pos)", noGround))
	end
	if noTemplate > 0 then
		warn(string.format("[CrateSpawn] %d skipped (no template)", noTemplate))
	end
end

------------------------------------------------------------------------
-- GLOBAL: SpawnDropCrate — used by PVESystem for boss drops
-- Spawns a crate at a world position using the same pickup/bob/spin system
------------------------------------------------------------------------
_G.SpawnDropCrate = function(position, crateType)
	-- Normalise to uppercase so callers can pass "Bronze", "BRONZE", etc.
	crateType = tostring(crateType):upper()
	if not CRATE_INFO[crateType] then
		warn("[CrateSpawn] SpawnDropCrate: unknown crateType:", crateType, "— valid types:", table.concat({"BRONZE","SILVER","SAPPHIRE","OMEGA","RUBY"}, ", "))
		return
	end
	local floatPos = position + Vector3.new(0, SETTINGS.FloatHeight, 0)
	local crate = buildCrate(crateType, floatPos)
	if not crate then
		warn("[CrateSpawn] SpawnDropCrate: buildCrate returned nil for", crateType)
		return
	end
	crate.Parent = crateHolder
	table.insert(activeCrates, crate)
	crateBaseY[crate] = floatPos.Y
	crateSpawnTime[crate] = os.clock() + math.random() * 3
	-- Auto-despawn after 90 seconds if nobody picks it up
	task.delay(90, function()
		if crate and crate.Parent and not crate:GetAttribute("Collected") then
			local idx = table.find(activeCrates, crate)
			if idx then table.remove(activeCrates, idx) end
			crate:Destroy()
		end
	end)
	return crate
end

------------------------------------------------------------------------
-- SPIN + BOB ANIMATION — Minecraft-style idle float
------------------------------------------------------------------------
RunService.Heartbeat:Connect(function(dt)
	local now = os.clock()
	local spinAngle = math.rad(SETTINGS.SpinSpeed * dt)

	for _, crate in ipairs(activeCrates) do
		if crate and crate.Parent and crate:IsA("Model") and crate.PrimaryPart then
			local pivot = crate:GetPivot()
			local baseY = crateBaseY[crate] or pivot.Position.Y
			local phase = crateSpawnTime[crate] or 0

			-- Sine-wave bob (Minecraft item float)
			local bobOffset = math.sin((now - phase) * SETTINGS.BobSpeed * math.pi * 2) * SETTINGS.BobHeight
			local targetY = baseY + bobOffset
			local currentPos = pivot.Position
			local newPos = Vector3.new(currentPos.X, targetY, currentPos.Z)

			-- Spin + new Y position
			local rot = (pivot - pivot.Position).Rotation * CFrame.Angles(0, spinAngle, 0)
			crate:PivotTo(CFrame.new(newPos) * rot)
		end
	end
end)

------------------------------------------------------------------------
-- PROXIMITY PICKUP + MAGNET DRIFT LOOP
-- Items within MagnetRadius drift toward player (Minecraft magnet).
-- Items within PickupRadius get collected with fly animation.
------------------------------------------------------------------------
task.spawn(function()
	local pickupR = SETTINGS.PickupRadius
	local pickupRSq = pickupR * pickupR
	local magnetR = SETTINGS.MagnetRadius
	local magnetRSq = magnetR * magnetR

	while true do
		local dt = task.wait(SETTINGS.PickupCheckRate)
		local players = Players:GetPlayers()

		-- Iterate backwards since collectCrate can remove entries
		for i = #activeCrates, 1, -1 do
			local crate = activeCrates[i]
			if not crate or not crate.Parent then continue end
			if crate:GetAttribute("Collected") then continue end
			if flyingCrates[crate] then continue end

			local cratePos
			if crate:IsA("Model") and crate.PrimaryPart then
				cratePos = crate.PrimaryPart.Position
			elseif crate:IsA("BasePart") then
				cratePos = crate.Position
			else
				continue
			end

			-- Find closest player
			local closestPlr = nil
			local closestDistSq = math.huge
			local closestRoot = nil

			for _, plr in ipairs(players) do
				local char = plr.Character
				if not char then continue end
				local root = char:FindFirstChild("HumanoidRootPart")
				if not root then continue end

				local delta = root.Position - cratePos
				local dSq = delta.X * delta.X + delta.Y * delta.Y + delta.Z * delta.Z
				if dSq < closestDistSq then
					closestDistSq = dSq
					closestPlr = plr
					closestRoot = root
				end
			end

			if not closestPlr then continue end

			-- COLLECT: within pickup radius
			if closestDistSq <= pickupRSq then
				local crateType = crate:GetAttribute("CrateType")
				if crateType then
					collectCrate(closestPlr, crate, crateType)
				end
			-- MAGNET: within magnet radius — drift toward player
			elseif closestDistSq <= magnetRSq and closestRoot then
				local dir = (closestRoot.Position - cratePos).Unit
				local drift = dir * SETTINGS.MagnetSpeed * dt
				-- Move the base position so bob stays relative
				if crate:IsA("Model") and crate.PrimaryPart then
					local pivot = crate:GetPivot()
					local newPos = pivot.Position + Vector3.new(drift.X, 0, drift.Z)
					crateBaseY[crate] = (crateBaseY[crate] or pivot.Position.Y)
					crate:PivotTo(CFrame.new(newPos) * (pivot - pivot.Position).Rotation)
				end
			end
		end
	end
end)

------------------------------------------------------------------------
-- MAIN LOOP
-- Run in task.spawn so WaitForChild doesn't block globals or loops.
-- Tries several common spawn-container paths; if none found, uses
-- player spawn locations as fallback so waves always work.
------------------------------------------------------------------------
warn("[CrateSpawn] Globals ready. Locating spawn points...")
task.spawn(function()
	-- Helper: recursively collect BaseParts from a container
	local function collectParts(container)
		local found = {}
		for _, obj in ipairs(container:GetDescendants()) do
			if obj:IsA("BasePart") then table.insert(found, obj) end
		end
		return found
	end

	-- Helper: try to reach a nested path, returning the final instance or nil
	local function tryPath(...)
		local node = workspace
		for _, name in ipairs({...}) do
			node = node:FindFirstChild(name)
			if not node then return nil end
		end
		return node
	end

	-- Try common paths where a map might store crate spawn pads
	local candidates = {
		tryPath("Game", "Abyss", "Crates"),
		tryPath("Game", "Crates"),
		tryPath("Map", "Crates"),
		tryPath("Crates"),
		tryPath("SpawnPoints"),
		tryPath("Game", "SpawnPoints"),
	}

	for _, container in ipairs(candidates) do
		if container then
			local parts = collectParts(container)
			if #parts > 0 then
				spawnContainer = container
				for _, p in ipairs(parts) do table.insert(spawnPoints, p) end
				warn(string.format("[CrateSpawn] Using spawn container '%s' — %d points", container:GetFullName(), #spawnPoints))
				break
			end
		end
	end

	-- Fallback: use SpawnLocation parts in workspace
	if #spawnPoints == 0 then
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("SpawnLocation") or (obj:IsA("BasePart") and obj.Name == "SpawnLocation") then
				table.insert(spawnPoints, obj)
			end
		end
		if #spawnPoints > 0 then
			warn(string.format("[CrateSpawn] Using %d SpawnLocation(s) as fallback spawn points", #spawnPoints))
		end
	end

	-- Last resort: generate a grid of virtual spawn points around origin
	if #spawnPoints == 0 then
		warn("[CrateSpawn] No spawn container found — generating spread points around world origin")
		local spread = 150
		local gridSize = 8
		for gx = 1, gridSize do
			for gz = 1, gridSize do
				local x = (gx / gridSize - 0.5) * spread * 2
				local z = (gz / gridSize - 0.5) * spread * 2
				-- Create a tiny invisible anchor Part as a virtual spawn point
				local anchor = Instance.new("Part")
				anchor.Anchored = true
				anchor.CanCollide = false
				anchor.CanQuery = false
				anchor.CanTouch = false
				anchor.Transparency = 1
				anchor.Size = Vector3.new(1, 1, 1)
				anchor.CFrame = CFrame.new(x, 100, z) -- high so raycast finds ground
				anchor.Name = "VirtualSpawnPoint"
				anchor.Parent = crateHolder
				table.insert(spawnPoints, anchor)
			end
		end
		warn(string.format("[CrateSpawn] Generated %d virtual spawn points", #spawnPoints))
	end

	warn("[CrateSpawn] Starting first wave NOW")
	spawnWave()
	while true do
		task.wait(SETTINGS.Interval)
		spawnWave()
	end
end)
