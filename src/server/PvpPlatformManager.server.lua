-- PvpPlatformManager.server.lua
-- Detects when 2 players stand on the PvpPlatform inside SpawnArena
-- Shows a "0/2", "1/2", "2/2" counter above the platform
-- When 2 players are on it, triggers a PvP duel via _G.PvpDuel.startDuel()

local Players = game:GetService("Players")

--------------------------------------------------------------------------
-- FIND THE PVP PLATFORM
--------------------------------------------------------------------------
local gameFolder = workspace:WaitForChild("Game", 30)
if not gameFolder then
	warn("❌ [PvpPlatform] Could not find 'Game' folder in Workspace!")
	return
end

local spawnArena = gameFolder:WaitForChild("SpawnArena", 30)
if not spawnArena then
	warn("❌ [PvpPlatform] Could not find 'SpawnArena' in Game folder!")
	return
end

local platform = spawnArena:FindFirstChild("PvpPlatform")
if not platform then
	warn("❌ [PvpPlatform] Could not find 'PvpPlatform' inside SpawnArena!")
	return
end

-- If PvpPlatform is a Model, get its main BasePart
if not platform:IsA("BasePart") then
	local mainPart = platform:FindFirstChildWhichIsA("BasePart")
	if mainPart then
		platform = mainPart
	else
		warn("❌ [PvpPlatform] PvpPlatform has no BasePart!")
		return
	end
end
platform.CanCollide = true

print("✅ [PvpPlatform] Found PvpPlatform inside SpawnArena at", platform:GetFullName())

--------------------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------------------
local PLATFORM_CHECK_INTERVAL = 0.5  -- how often to re-check who's on the platform
local MATCH_COOLDOWN = 5             -- seconds after a match starts before another can begin
local PROXIMITY_RANGE = 10           -- studs from platform center to count as "on"

--------------------------------------------------------------------------
-- COUNTER GUI — BillboardGui floating above the platform
--------------------------------------------------------------------------
local function createCounterGui()
	local existing = platform:FindFirstChild("PvpCounterGui")
	if existing then existing:Destroy() end

	local bb = Instance.new("BillboardGui")
	bb.Name = "PvpCounterGui"
	bb.Size = UDim2.new(0, 200, 0, 80)
	bb.StudsOffset = Vector3.new(0, 5, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 60
	bb.Adornee = platform
	bb.Parent = platform

	local frame = Instance.new("Frame")
	frame.Name = "Background"
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
	frame.BackgroundTransparency = 0.2
	frame.BorderSizePixel = 0
	frame.Parent = bb

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 65, 75)
	stroke.Thickness = 2
	stroke.Transparency = 0.3
	stroke.Parent = frame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, 0, 0.45, 0)
	titleLabel.Position = UDim2.new(0, 0, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "⚔️ PVP ARENA"
	titleLabel.TextColor3 = Color3.fromRGB(255, 65, 75)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Parent = frame

	local counterLabel = Instance.new("TextLabel")
	counterLabel.Name = "Counter"
	counterLabel.Size = UDim2.new(1, 0, 0.55, 0)
	counterLabel.Position = UDim2.new(0, 0, 0.45, 0)
	counterLabel.BackgroundTransparency = 1
	counterLabel.Text = "0/2"
	counterLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	counterLabel.TextScaled = true
	counterLabel.Font = Enum.Font.GothamBold
	counterLabel.Parent = frame

	return counterLabel
end

local counterLabel = createCounterGui()

--------------------------------------------------------------------------
-- STATE
--------------------------------------------------------------------------
local matchCooldownUntil = 0 -- tick() timestamp

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

	-- Distance-based proximity check (same as BullTeleporter)
	local distance = (rootPart.Position - platform.Position).Magnitude
	return distance <= PROXIMITY_RANGE
end

local function updateCounter(count: number)
	if not counterLabel then return end
	counterLabel.Text = tostring(count) .. "/2"

	if count >= 2 then
		counterLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
	else
		counterLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
end

--------------------------------------------------------------------------
-- MAIN LOOP — scan platform every PLATFORM_CHECK_INTERVAL seconds
--------------------------------------------------------------------------
task.spawn(function()
	-- Wait for _G.PvpDuel to be registered by duel.server.lua
	while not _G.PvpDuel do
		task.wait(0.5)
	end
	print("✅ [PvpPlatform] _G.PvpDuel API found — ready to start matches")

	while true do
		task.wait(PLATFORM_CHECK_INTERVAL)

		-- Gather eligible players on platform
		local onPlatform: { Player } = {}
		for _, player in ipairs(Players:GetPlayers()) do
			-- Skip players already in a duel
			if _G.PvpDuel.isInDuel(player) then continue end
			if isPlayerOnPlatform(player) then
				table.insert(onPlatform, player)
			end
		end

		updateCounter(#onPlatform)

		-- If 2+ players on platform and cooldown expired, start a match
		if #onPlatform >= 2 and tick() > matchCooldownUntil then
			local p1 = onPlatform[1]
			local p2 = onPlatform[2]

			local started = _G.PvpDuel.startDuel(p1, p2)
			if started then
				matchCooldownUntil = tick() + MATCH_COOLDOWN
				print(("⚔️ [PvpPlatform] Match started: %s vs %s"):format(p1.Name, p2.Name))
			end
		end
	end
end)

print("✅ [PvpPlatform] Server script loaded — waiting for SpawnArena.PvpPlatform")
