-- ArcadePvp.server.lua
-- Arcade PvP mode: same as normal PvP but with buff pickups in the arena.
-- Uses ArcadePvpPlatform for detection (same pattern as PvpPlatformManager).
-- Delegates the core duel to _G.PvpDuel.startDuel() but hooks into the arena
-- phase to spawn floating buff orbs at the Attachment positions (BuffTop1/Bot1
-- for player 1, BuffTop2/Bot2 for player 2).  One random attachment per side.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--------------------------------------------------------------------------
-- REMOTE EVENTS
--------------------------------------------------------------------------
local ArcadeBuffEvent = ReplicatedStorage:FindFirstChild("ArcadeBuffEvent")
if not ArcadeBuffEvent then
	ArcadeBuffEvent = Instance.new("RemoteEvent")
	ArcadeBuffEvent.Name = "ArcadeBuffEvent"
	ArcadeBuffEvent.Parent = ReplicatedStorage
end

--------------------------------------------------------------------------
-- FIND PLATFORM
--------------------------------------------------------------------------
local gameFolder = workspace:WaitForChild("Game", 30)
if not gameFolder then warn("❌ [ArcadePvp] No 'Game' folder!"); return end

local spawnArena = gameFolder:WaitForChild("SpawnArena", 30)
if not spawnArena then warn("❌ [ArcadePvp] No 'SpawnArena'!"); return end

local platform = spawnArena:FindFirstChild("ArcadePvpPlatform")
if not platform then warn("❌ [ArcadePvp] No 'ArcadePvpPlatform' in SpawnArena!"); return end

if not platform:IsA("BasePart") then
	local bp = platform:FindFirstChildWhichIsA("BasePart")
	if bp then platform = bp else warn("❌ [ArcadePvp] Platform has no BasePart!"); return end
end
platform.CanCollide = true

--------------------------------------------------------------------------
-- FIND ARENA & BUFF ATTACHMENTS (non-blocking — buffs are optional)
-- Pvp folder is at workspace root, not inside Game
--------------------------------------------------------------------------
local pvpArena = workspace:FindFirstChild("Pvp")
if pvpArena then
	print("✅ [ArcadePvp] Found Pvp arena at", pvpArena:GetFullName())
else
	warn("⚠️ [ArcadePvp] No 'Pvp' arena in workspace — buffs won't spawn but platform will still work")
end

-- Attachments for buff spawn positions (may be nil)
local buffTop1 = pvpArena and pvpArena:FindFirstChild("BuffTop1", true)
local buffBot1 = pvpArena and pvpArena:FindFirstChild("BuffBot1", true)
local buffTop2 = pvpArena and pvpArena:FindFirstChild("BuffTop2", true)
local buffBot2 = pvpArena and pvpArena:FindFirstChild("BuffBot2", true)

if not (buffTop1 and buffBot1 and buffTop2 and buffBot2) then
	warn("⚠️ [ArcadePvp] Some buff attachments missing — buffs may not spawn on all sides")
end

print("✅ [ArcadePvp] Platform & arena found")

--------------------------------------------------------------------------
-- BUFF DEFINITIONS
--------------------------------------------------------------------------
export type BuffDef = {
	Name: string,
	Icon: string,      -- emoji/icon for client UI
	Color: Color3,     -- orb color
	Duration: number,  -- how long the buff lasts (seconds)
}

local BUFF_POOL: { BuffDef } = {
	{
		Name = "Speed Boost",
		Icon = "⚡",
		Color = Color3.fromRGB(0, 170, 255),
		Duration = 12,
	},
	{
		Name = "Triple Dash",
		Icon = "💨",
		Color = Color3.fromRGB(180, 80, 255),
		Duration = 15,
	},
	{
		Name = "2-Hit Kill",
		Icon = "💀",
		Color = Color3.fromRGB(255, 50, 50),
		Duration = 10,
	},
	{
		Name = "Super Jump",
		Icon = "🦘",
		Color = Color3.fromRGB(50, 255, 100),
		Duration = 12,
	},
	{
		Name = "Regeneration",
		Icon = "💚",
		Color = Color3.fromRGB(0, 255, 130),
		Duration = 10,
	},
	{
		Name = "Ghost Mode",
		Icon = "👻",
		Color = Color3.fromRGB(200, 200, 255),
		Duration = 8,
	},
}

--------------------------------------------------------------------------
-- ACTIVE BUFF TRACKING
--------------------------------------------------------------------------
local activeBuffs: { [Player]: { Name: string, EndTick: number, CleanupFn: (() -> ())? } } = {}

local function clearBuff(plr: Player)
	local buff = activeBuffs[plr]
	if not buff then return end
	if buff.CleanupFn then
		pcall(buff.CleanupFn)
	end
	activeBuffs[plr] = nil
	ArcadeBuffEvent:FireClient(plr, "BuffRemoved")
	print(("🧹 [ArcadePvp] Buff '%s' removed from %s"):format(buff.Name, plr.Name))
end

local function applyBuff(plr: Player, buffDef: BuffDef)
	-- Remove any existing buff first
	clearBuff(plr)

	local char = plr.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return end

	local cleanupFn: (() -> ())? = nil

	if buffDef.Name == "Speed Boost" then
		local origSpeed = hum.WalkSpeed
		hum.WalkSpeed = origSpeed * 1.6
		cleanupFn = function()
			if hum and hum.Parent then hum.WalkSpeed = origSpeed end
		end

	elseif buffDef.Name == "Triple Dash" then
		-- Store dash count attribute for the dash client script to read
		char:SetAttribute("ArcadeDashCount", 3)
		cleanupFn = function()
			if char and char.Parent then char:SetAttribute("ArcadeDashCount", nil) end
		end

	elseif buffDef.Name == "2-Hit Kill" then
		-- Reduce opponent kill threshold; set attribute for dealPvpHit to read
		char:SetAttribute("ArcadePvpHearts", 2)
		cleanupFn = function()
			if char and char.Parent then char:SetAttribute("ArcadePvpHearts", nil) end
		end

	elseif buffDef.Name == "Super Jump" then
		local origJump = hum.JumpPower
		hum.JumpPower = origJump * 2
		cleanupFn = function()
			if hum and hum.Parent then hum.JumpPower = origJump end
		end

	elseif buffDef.Name == "Regeneration" then
		local regenThread = task.spawn(function()
			while hum and hum.Parent and hum.Health > 0 do
				local hearts = char:GetAttribute("PvpHearts") or 0
				local maxHearts = 3
				if hearts < maxHearts then
					char:SetAttribute("PvpHearts", hearts + 1)
					-- Notify client of hearts update
					local PvpCountdownEvent = ReplicatedStorage:FindFirstChild("PvpCountdownEvent")
					if PvpCountdownEvent then
						PvpCountdownEvent:FireClient(plr, "HeartsUpdate", hearts + 1)
					end
					print(("💚 [ArcadePvp] Regen: %s healed to %d hearts"):format(plr.Name, hearts + 1))
				end
				task.wait(4) -- heal 1 heart every 4s
			end
		end)
		cleanupFn = function()
			pcall(function() task.cancel(regenThread) end)
		end

	elseif buffDef.Name == "Ghost Mode" then
		-- Make player semi-transparent
		for _, part in char:GetDescendants() do
			if part:IsA("BasePart") then
				part:SetAttribute("PreGhostTransparency", part.Transparency)
				part.Transparency = 0.6
			end
		end
		cleanupFn = function()
			if char and char.Parent then
				for _, part in char:GetDescendants() do
					if part:IsA("BasePart") then
						local orig = part:GetAttribute("PreGhostTransparency")
						if orig ~= nil then
							part.Transparency = orig
							part:SetAttribute("PreGhostTransparency", nil)
						end
					end
				end
			end
		end
	end

	activeBuffs[plr] = {
		Name = buffDef.Name,
		EndTick = tick() + buffDef.Duration,
		CleanupFn = cleanupFn,
	}

	-- Tell client to show buff UI
	ArcadeBuffEvent:FireClient(plr, "BuffApplied", {
		Name = buffDef.Name,
		Icon = buffDef.Icon,
		Duration = buffDef.Duration,
		Color = { buffDef.Color.R, buffDef.Color.G, buffDef.Color.B },
	})

	print(("✨ [ArcadePvp] %s got buff '%s' (%ds)"):format(plr.Name, buffDef.Name, buffDef.Duration))

	-- Auto-expire
	task.delay(buffDef.Duration, function()
		if activeBuffs[plr] and activeBuffs[plr].EndTick <= tick() + 0.5 then
			clearBuff(plr)
		end
	end)
end

--------------------------------------------------------------------------
-- SPAWN FLOATING BUFF ORB at an Attachment or Part position
--------------------------------------------------------------------------
local function getWorldPosition(obj: Instance): Vector3?
	if obj:IsA("Attachment") then
		return obj.WorldPosition
	elseif obj:IsA("BasePart") then
		return obj.Position
	end
	return nil
end

local function spawnBuffOrb(positionObj: Instance, buffDef: BuffDef, forPlayer: Player): Part?
	local worldPos = getWorldPosition(positionObj)
	if not worldPos then return nil end

	local orb = Instance.new("Part")
	orb.Name = "ArcadeBuffOrb"
	orb.Shape = Enum.PartType.Ball
	orb.Size = Vector3.new(3, 3, 3)
	orb.Position = worldPos + Vector3.new(0, 3, 0)
	orb.Anchored = true
	orb.CanCollide = false
	orb.Material = Enum.Material.Neon
	orb.Color = buffDef.Color
	orb.Transparency = 0.2
	orb.Parent = workspace

	-- Billboard label showing buff name
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 120, 0, 40)
	bb.StudsOffset = Vector3.new(0, 3, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 40
	bb.Adornee = orb
	bb.Parent = orb

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = buffDef.Icon .. " " .. buffDef.Name
	label.TextColor3 = buffDef.Color
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = bb

	-- Floating bob animation
	local startY = orb.Position.Y
	local bobConn: RBXScriptConnection
	local elapsed = 0
	bobConn = RunService.Heartbeat:Connect(function(dt)
		if not orb or not orb.Parent then
			bobConn:Disconnect()
			return
		end
		elapsed += dt
		orb.Position = Vector3.new(orb.Position.X, startY + math.sin(elapsed * 2) * 0.5, orb.Position.Z)
	end)

	-- Touch detection — only the designated player can pick it up
	local touchConn: RBXScriptConnection
	touchConn = orb.Touched:Connect(function(hit)
		local char = hit.Parent
		if not char then return end
		local plr = Players:GetPlayerFromCharacter(char)
		if plr ~= forPlayer then return end

		-- Cleanup orb
		touchConn:Disconnect()
		bobConn:Disconnect()
		orb:Destroy()

		-- Apply buff
		applyBuff(plr, buffDef)
	end)

	-- Auto-destroy after 20s if not picked up
	task.delay(20, function()
		if orb and orb.Parent then
			touchConn:Disconnect()
			bobConn:Disconnect()
			orb:Destroy()
		end
	end)

	return orb
end

--------------------------------------------------------------------------
-- SPAWN BUFFS FOR A MATCH
--------------------------------------------------------------------------
local function spawnMatchBuffs(player1: Player, player2: Player)
	-- Pick one random attachment per team side
	local team1Spots = {}
	if buffTop1 then table.insert(team1Spots, buffTop1) end
	if buffBot1 then table.insert(team1Spots, buffBot1) end

	local team2Spots = {}
	if buffTop2 then table.insert(team2Spots, buffTop2) end
	if buffBot2 then table.insert(team2Spots, buffBot2) end

	if #team1Spots == 0 or #team2Spots == 0 then
		warn("⚠️ [ArcadePvp] Not enough buff spots to spawn buffs")
		return
	end

	-- Random spot for each team
	local spot1 = team1Spots[math.random(1, #team1Spots)]
	local spot2 = team2Spots[math.random(1, #team2Spots)]

	-- Random buff for each (can be different)
	local buff1 = BUFF_POOL[math.random(1, #BUFF_POOL)]
	local buff2 = BUFF_POOL[math.random(1, #BUFF_POOL)]

	-- Delay buff spawn so players have time to land after teleport
	task.delay(6, function()
		-- Verify both still in duel
		if not _G.PvpDuel or not _G.PvpDuel.isInDuel(player1) or not _G.PvpDuel.isInDuel(player2) then
			return
		end
		spawnBuffOrb(spot1, buff1, player1)
		spawnBuffOrb(spot2, buff2, player2)
		print(("🎁 [ArcadePvp] Buffs spawned — %s: %s | %s: %s"):format(
			player1.Name, buff1.Name, player2.Name, buff2.Name))
	end)
end

--------------------------------------------------------------------------
-- SURFACE GUI — text on top of the platform + floating BillboardGui above
--------------------------------------------------------------------------
local function createPlatformGui()
	-- Remove old GUIs if they exist
	local existingSurface = platform:FindFirstChild("ArcadePvpSurfaceGui")
	if existingSurface then existingSurface:Destroy() end
	local existingBB = platform:FindFirstChild("ArcadePvpCounterGui")
	if existingBB then existingBB:Destroy() end

	-- ===== SURFACE GUI (on top face of platform) =====
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "ArcadePvpSurfaceGui"
	surfaceGui.Face = Enum.NormalId.Top
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 50
	surfaceGui.Parent = platform

	local surfaceFrame = Instance.new("Frame")
	surfaceFrame.Size = UDim2.new(1, 0, 1, 0)
	surfaceFrame.BackgroundTransparency = 1
	surfaceFrame.Parent = surfaceGui

	local surfaceTitle = Instance.new("TextLabel")
	surfaceTitle.Name = "Title"
	surfaceTitle.Size = UDim2.new(0.9, 0, 0.35, 0)
	surfaceTitle.Position = UDim2.new(0.05, 0, 0.1, 0)
	surfaceTitle.BackgroundTransparency = 1
	surfaceTitle.Text = "🕹️ ARCADE PVP"
	surfaceTitle.TextColor3 = Color3.fromRGB(180, 80, 255)
	surfaceTitle.TextScaled = true
	surfaceTitle.Font = Enum.Font.GothamBold
	surfaceTitle.Parent = surfaceFrame

	local surfaceCounter = Instance.new("TextLabel")
	surfaceCounter.Name = "Counter"
	surfaceCounter.Size = UDim2.new(0.9, 0, 0.35, 0)
	surfaceCounter.Position = UDim2.new(0.05, 0, 0.5, 0)
	surfaceCounter.BackgroundTransparency = 1
	surfaceCounter.Text = "0/2"
	surfaceCounter.TextColor3 = Color3.fromRGB(255, 255, 255)
	surfaceCounter.TextScaled = true
	surfaceCounter.Font = Enum.Font.GothamBold
	surfaceCounter.Parent = surfaceFrame

	-- ===== BILLBOARD GUI (floating above platform for distance visibility) =====
	local bb = Instance.new("BillboardGui")
	bb.Name = "ArcadePvpCounterGui"
	bb.Size = UDim2.new(0, 200, 0, 80)
	bb.StudsOffset = Vector3.new(0, 5, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 60
	bb.Adornee = platform
	bb.Parent = platform

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
	frame.BackgroundTransparency = 0.2
	frame.BorderSizePixel = 0
	frame.Parent = bb

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(180, 80, 255)
	stroke.Thickness = 2
	stroke.Transparency = 0.3
	stroke.Parent = frame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0.45, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "🕹️ ARCADE PVP"
	titleLabel.TextColor3 = Color3.fromRGB(180, 80, 255)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Parent = frame

	local bbCounterLabel = Instance.new("TextLabel")
	bbCounterLabel.Name = "Counter"
	bbCounterLabel.Size = UDim2.new(1, 0, 0.55, 0)
	bbCounterLabel.Position = UDim2.new(0, 0, 0.45, 0)
	bbCounterLabel.BackgroundTransparency = 1
	bbCounterLabel.Text = "0/2"
	bbCounterLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	bbCounterLabel.TextScaled = true
	bbCounterLabel.Font = Enum.Font.GothamBold
	bbCounterLabel.Parent = frame

	-- Return both counter labels so we can update them together
	return surfaceCounter, bbCounterLabel
end

local surfaceCounterLabel, bbCounterLabel = createPlatformGui()

--------------------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------------------
local PLATFORM_CHECK_INTERVAL = 0.5
local MATCH_COOLDOWN = 5
local PROXIMITY_RANGE = 10

--------------------------------------------------------------------------
-- STATE
--------------------------------------------------------------------------
local matchCooldownUntil = 0
local arcadeMatches: { [Player]: boolean } = {} -- track who is in an arcade match

--------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------
local function isPlayerOnPlatform(player: Player): boolean
	local char = player.Character
	if not char then return false end
	local rootPart = char:FindFirstChild("HumanoidRootPart")
	if not rootPart then return false end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return false end
	return (rootPart.Position - platform.Position).Magnitude <= PROXIMITY_RANGE
end

local function updateCounter(count: number)
	local text = tostring(count) .. "/2"
	local color = count >= 2
		and Color3.fromRGB(0, 255, 100)
		or Color3.fromRGB(255, 255, 255)

	if surfaceCounterLabel then
		surfaceCounterLabel.Text = text
		surfaceCounterLabel.TextColor3 = color
	end
	if bbCounterLabel then
		bbCounterLabel.Text = text
		bbCounterLabel.TextColor3 = color
	end
end

--------------------------------------------------------------------------
-- ARCADE MATCH: start duel + spawn buffs
--------------------------------------------------------------------------
local function startArcadeMatch(p1: Player, p2: Player)
	if not _G.PvpDuel then return false end

	-- Mark as arcade participants
	arcadeMatches[p1] = true
	arcadeMatches[p2] = true

	local started = _G.PvpDuel.startDuel(p1, p2)
	if not started then
		arcadeMatches[p1] = nil
		arcadeMatches[p2] = nil
		return false
	end

	-- Spawn buffs after teleport + invincibility
	spawnMatchBuffs(p1, p2)

	-- Cleanup arcade state when duel ends (poll)
	task.spawn(function()
		while _G.PvpDuel.isInDuel(p1) and _G.PvpDuel.isInDuel(p2) do
			task.wait(1)
		end
		-- Duel ended — clean up buffs
		clearBuff(p1)
		clearBuff(p2)
		arcadeMatches[p1] = nil
		arcadeMatches[p2] = nil
		print(("🏁 [ArcadePvp] Arcade match ended: %s vs %s"):format(p1.Name, p2.Name))
	end)

	return true
end

--------------------------------------------------------------------------
-- MAIN LOOP
--------------------------------------------------------------------------
task.spawn(function()
	while not _G.PvpDuel do task.wait(0.5) end
	print("✅ [ArcadePvp] _G.PvpDuel API found — ready")

	while true do
		task.wait(PLATFORM_CHECK_INTERVAL)

		local onPlatform: { Player } = {}
		for _, player in ipairs(Players:GetPlayers()) do
			if _G.PvpDuel.isInDuel(player) then continue end
			if isPlayerOnPlatform(player) then
				table.insert(onPlatform, player)
			end
		end

		updateCounter(#onPlatform)

		if #onPlatform >= 2 and tick() > matchCooldownUntil then
			local ok = startArcadeMatch(onPlatform[1], onPlatform[2])
			if ok then
				matchCooldownUntil = tick() + MATCH_COOLDOWN
				print(("🕹️ [ArcadePvp] Arcade match started: %s vs %s"):format(
					onPlatform[1].Name, onPlatform[2].Name))
			end
		end
	end
end)

-- Cleanup on leave
Players.PlayerRemoving:Connect(function(plr)
	clearBuff(plr)
	arcadeMatches[plr] = nil
end)

print("✅ [ArcadePvp] Server script loaded")
